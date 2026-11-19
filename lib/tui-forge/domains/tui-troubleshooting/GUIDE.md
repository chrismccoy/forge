# TUI Troubleshooting: Freezes, Hangs, Blank Screens, and Terminal State Corruption

Use this guide when the user reports that a TUI "froze", "hung", "blanked the terminal", "stopped accepting input", "left the terminal broken", or says it "works in one terminal but not another" while the terminal is left stuck, frozen, or garbled (otherwise use `platform-compatibility`). Treat these reports as terminal lifecycle failures until proven otherwise.

## First response rule

Do not give a shallow checklist. Establish the failure class, inspect startup and cleanup order, and look for a concrete lifecycle bug:

1. Does the app enter raw mode, alternate screen, mouse, focus, or bracketed paste?
2. Is every mode restored on normal quit, errors/exceptions (including rejected promises), panics, failed partial initialization, Ctrl-C, Ctrl-\ / SIGQUIT, SIGTERM, SIGHUP/terminal close (including stdin EOF and read/write EIO), return from a `$EDITOR`/child handoff, and test failures?
3. Is stdin flowing after terminal setup?
4. Does the app render and flush at least one frame before waiting on async work or input?
5. Can logs, stderr, background tasks, or child processes write into the same terminal surface?
6. Does the bug reproduce only in tmux, SSH, Windows/ConPTY, CI, or a non-TTY pipe?

## High-probability freeze causes

Prioritize these before exotic terminal protocol issues:

- **Raw mode without restore.** Echo is disabled and line editing is gone, making the shell look frozen after a crash or early return.
- **Paused stdin never resumed.** In Node, `process.stdin.pause()` followed by raw mode without `resume()` prevents `data` events; the UI may wait forever.
- **Missing first render.** The app enters alternate screen/raw mode, starts an async status check, and never flushes an initial frame, so users see a blank screen.
- **Blocking startup work.** Synchronous file/network/process calls run before the first draw and starve the event loop or render loop.
- **Input mode mismatch.** The code waits for line-oriented input while stdin is raw, or waits for raw key events while stdin is cooked or paused.
- **Cleanup mode leak.** Alternate screen, mouse reporting, focus events, or bracketed paste remain enabled after exit.

## Minimal diagnostic posture

Ask for or inspect:

- Language/framework and terminal library.
- Startup sequence from process start through first render.
- Cleanup/guard/finally/defer/Drop/atexit/signal handlers.
- Whether stdin/stdout/stderr are TTYs.
- Whether failure occurs locally, over SSH, in tmux/screen/Zellij, on Windows, or in CI.
- Raw terminal symptoms: echo off, cursor hidden, blank alternate screen, paste wrappers, mouse clicks swallowed, garbled sequences.

## Recovery commands for users

When a terminal is stuck, give the user this canonical recovery before deeper debugging. Other files in this procedure point here instead of repeating it.

Run the recovery only after the process is gone. If the app is still running, stop it first:

- Try the app's own exit keys (`q`, `Esc`).
- Ctrl-C, Ctrl-Z and Ctrl-\ work only if the app left ISIG on (cbreak/curses); in raw mode they arrive as plain bytes. A job stopped with Ctrl-Z still needs `kill %1` before recovery.
- From another terminal, run `kill <pid>` (find it with `pgrep -f <app>`); escalate to `kill -9 <pid>` only if it ignores SIGTERM.

Echo is off while the terminal is stuck, so typed commands are invisible. Run them in this order. Step 1 is short enough to type blind; step 2 is not, so paste it, or skip to `reset` (or `tput reset`), the practical blind-typing option. Ship an `app --reset-terminal` flag that prints the step 2 line, so users have a short command to type:

1. `stty sane; printf '\033[?2004l'` — restores cooked mode and echo, so the next command is visible, and turns off a leaked bracketed paste so pasting step 2 cannot wrap it in `^[[200~`. If Enter does nothing, press Ctrl-J instead (a raw newline). Older shells without bracketed-paste support (bash before 5.1) insert those markers literally while `?2004` is on, so run step 1 before pasting.
2. The mode reset line:

   ```sh
   printf '\033[?2026l\033[<99u\033[>4m\033[?1004l\033[?2004l\033[?1016l\033[?1015l\033[?1006l\033[?1005l\033[?1003l\033[?1002l\033[?1001l\033[?1000l\033[?9l\033[?2027l\033[?7h\033[?1l\033>\033(B\033)B\017\033[0 q\033[0m\033[r\033[4l\033[?25h\033[?1049l\033[<99u\033[?1049h\033[<99u\033[?1049l\033[?6l\033[r\033[0m\033(B\033)B\017\n'
   ```

3. Ctrl-L, or `printf '\033[H\033[2J'` — `CSI r` homes the cursor and leaving the alternate screen restores a saved cursor, so the prompt may land at the top-left over old text. Plain `clear` and `tput clear` also wipe the scrollback (E3, `\e[3J`). `clear -x` keeps it only on ncurses 20170819 or later (6.1+); ncurses builds from 20130622 to 20170818 (late 5.9 patches, 6.0) silently ignore `-x` and still wipe it. busybox `clear` ignores `-x` but never touches scrollback. Use the `printf` form wherever scrollback must survive.

The `printf` resets every mode TUIs commonly leave on, in teardown order, then repeats the resets that leaving the alternate screen can undo. Byte-by-byte explanation: `domains/tui-troubleshooting/references/terminal-state-corruption.md` (section "Recovery line explained").

If keys still produce garbage (a leaked Kitty flag sends Ctrl-J as `CSI 106;5u`, so the Ctrl-J fallback fails), open a new tab or use the terminal's Reset menu.

If the screen is still wrong, run `reset` as the heavier fallback. It sends RIS (`\033c`), which clears the scrollback too in xterm and in many other terminals.

On Windows (PowerShell 7 in Windows Terminal), send the same reset with `` `e `` escapes. Write through `[Console]::Out`, not `Write-Host`: with `NO_COLOR` set or `$PSStyle.OutputRendering` at `PlainText`, `Write-Host` strips most of these sequences.

```powershell
[Console]::Out.Write("`e[?2026l`e[<99u`e[>4m`e[?1004l`e[?2004l`e[?1016l`e[?1015l`e[?1006l`e[?1005l`e[?1003l`e[?1002l`e[?1001l`e[?1000l`e[?9l`e[?2027l`e[?7h`e[?1l`e>`e(B`e)B$([char]15)`e[0 q`e[0m`e[r`e[4l`e[?25h`e[?1049l`e[<99u`e[?1049h`e[<99u`e[?1049l`e[?6l`e[r`e[0m`e(B`e)B$([char]15)`n")
```

Windows PowerShell 5.1 lacks `` `e ``; use `$([char]27)` instead (`$([char]15)` already works in both). Closing the tab is sometimes the fastest recovery when a child process left ConPTY in a bad state.

## Fix pattern to prefer

Give every TUI one lifecycle owner:

1. Verify TTY or choose non-TUI mode.
2. Install cleanup guards first.
3. Enter raw mode, then the alternate screen, then optional mouse/paste/focus modes, following the canonical lifecycle order in `domains/rendering-layout-performance/GUIDE.md`.
4. Make sure the input stream is flowing (Node: `process.stdin.resume()` and `ref()`) if raw key events are needed.
5. Render and flush an initial frame immediately.
6. Start async work after the first frame.
7. Route logs away from the controlled terminal surface.
8. Restore modes in reverse order exactly once.

## Reference files

- `domains/tui-troubleshooting/references/freeze-hang-diagnosis.md` - Root causes, symptoms, diagnostics, fix sketches, and prevention patterns for startup and runtime hangs. Read when the app freezes, ignores input, or will not exit.
- `domains/tui-troubleshooting/references/terminal-state-corruption.md` - Garbled display, wrong colors, cursor bugs, partial renders, interleaved writes, and resize/render races. Read when the screen or the shell after exit looks wrong.
- `domains/tui-troubleshooting/references/diagnostic-playbook.md` - Decision trees with concrete commands for freezes, stuck terminal state, no input, SSH/tmux, Windows, and garbled output. Read when the cause is unknown and a step-by-step triage is needed.
