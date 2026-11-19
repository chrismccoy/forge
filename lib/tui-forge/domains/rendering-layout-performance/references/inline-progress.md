# Inline Progress Bars and Spinners

Rules for progress output in a normal CLI or script that does not take over the screen. For full-screen dashboards, use the render loop in `domains/rendering-layout-performance/references/render-loop-patterns.md` instead.

## Rules

1. **Write progress to stderr.** Keep stdout for results so `cmd > out.txt` and pipes stay clean.
2. **Gate on a TTY.** Draw the live bar only when stderr is a TTY and `TERM` is not `dumb`. Honor `--no-progress`, `--quiet`, and CI detection (`CI` set to a non-empty value other than `0`/`false`, any case).
3. **Redraw one line.** Emit `\r` (carriage return) plus `CSI 2K` (`\x1b[2K`, erase whole line), then the new bar. Never print a newline per update.
4. **Keep the bar narrower than the terminal.** Read the width each redraw, or on resize; a bar that wraps breaks `\r` redraw and leaves a trail of lines.
5. **Throttle to about 10 Hz.** Redraw at most every 100 ms, plus one final redraw at 100%. Faster redraws waste CPU and flicker over SSH.
6. **Hide the cursor while drawing, and always restore it.** Emit `CSI ? 25 l` before and `CSI ? 25 h` after, in a `finally`/`defer`/cleanup handler so Ctrl-C and exceptions restore it too.
7. **Finish cleanly.** Clear the bar (`\r\x1b[2K`) or leave a final completed line, then end with a newline so the shell prompt starts on a fresh line.
8. **Non-TTY fallback.** When not a TTY, print a plain line every N percent or every few seconds (`progress: 40/100`), never `\r` sequences. Logs and CI stay readable.
9. **Spinners.** Use the same `\r` + `CSI 2K` redraw at 8–12 frames per second. Offer an ASCII frame set (`| / - \`) next to Braille or Unicode frames. Stop spinning in reduced-motion and non-TTY modes.

## Multiple bars

Draw N lines once, leaving the cursor on the last bar line (no trailing newline). On each update, move up N-1 lines with `CSI <N-1> A` (skip it when N is 1), then redraw each line with `\r\x1b[2K`, writing `\n` between lines so the cursor ends back on the last bar line. Any other output written while the bars are active corrupts them, so route logs through the progress manager (it clears the bars, prints the log line, then redraws). Prefer a library for multi-bar output.

## Example (Python, standard library only)

Tested in a real PTY (live redraw; cursor restored on normal exit, Ctrl-C, Ctrl-\, SIGTERM, and SIGHUP; a real terminal close exits 129) and through a pipe (plain lines). Python's default SIGTERM/SIGHUP/SIGQUIT action kills the process without running `finally`, so the example converts those signals into `SystemExit`.

```python
import errno, os, signal, sys, time

def _exit_on_signal(signum, frame):
    sys.exit(128 + signum)          # raises SystemExit, so `finally` blocks run

for _name in ("SIGTERM", "SIGHUP", "SIGQUIT"):  # SIGHUP/SIGQUIT do not exist on Windows
    if hasattr(signal, _name):
        signal.signal(getattr(signal, _name), _exit_on_signal)

def progress(total, work):
    out = sys.stderr
    tty = (out.isatty() and os.environ.get("TERM") != "dumb"
           and os.environ.get("CI", "").lower() in ("", "0", "false"))  # rule 2: no live bar in CI
    last = 0.0
    if tty:
        out.write("\x1b[?25l")                                  # hide cursor
    try:
        for done in range(1, total + 1):
            work(done)
            now = time.monotonic()
            if tty and (now - last >= 0.1 or done == total):    # ~10 Hz
                last = now
                width = 30
                filled = width * done // total
                bar = "#" * filled + "-" * (width - filled)
                out.write(f"\r\x1b[2K[{bar}] {done}/{total}")
                out.flush()
            elif not tty and (done % max(1, total // 10) == 0 or done == total):
                out.write(f"progress: {done}/{total}\n")        # periodic plain lines
                out.flush()
    finally:
        if tty:
            try:
                out.write("\r\x1b[2K\x1b[?25h")                 # clear line, show cursor
                out.flush()
            except OSError:                                     # terminal already gone (hangup)
                pass
    print(f"done: {total} items")                                # result goes to stdout

def exit_with(code):
    # Mirrors the canonical exit_with in rust-python-go.md: skip the final flush if the
    # terminal is gone (EIO), so a real hangup exits 129 instead of 120. The bar writes to
    # stderr, so check both streams.
    try:
        sys.stdout.flush()
        sys.stderr.flush()
    except OSError:
        os._exit(code)
    sys.exit(code)

if __name__ == "__main__":
    try:
        progress(100, lambda i: time.sleep(0.05))
    except KeyboardInterrupt:
        exit_with(130)
    except SystemExit as e:
        exit_with(e.code if isinstance(e.code, int) else 1)
    except OSError as e:
        if e.errno != errno.EIO:
            raise
        exit_with(128 + 1)  # write EIO: the terminal closed without SIGHUP reaching us
    exit_with(0)
```

The fixed 30-cell bar keeps the example short; production code also sizes the bar from `shutil.get_terminal_size()`.

## Libraries

Prefer a maintained library; each handles TTY detection, throttling, and cleanup:

| Ecosystem | Libraries |
|--|--|
| Python | `tqdm`, `rich.progress` |
| Rust | `indicatif` |
| Go | `mpb`, `bubbles/progress` (inside Bubble Tea), `schollz/progressbar` |
| Node | `ora` (spinners), `cli-progress` |
| .NET | Spectre.Console `Progress` / `Status` |

Check each library's non-TTY behavior. Several print nothing, or print a final line only, when stderr is not a terminal.
