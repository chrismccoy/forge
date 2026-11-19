# Key, Mouse, Paste, and Focus Protocol Bytes

Byte-level reference for input protocols. `CSI` is `ESC [` (0x1b 0x5b). Prefer a framework parser; use these tables to verify a parser, write tests, or debug a raw byte capture.

Contents: Kitty keyboard protocol · xterm modifyOtherKeys · Mouse tracking · Bracketed paste · Focus events · Suspend and resume (Ctrl-Z) · Child-process handoff · Input failure modes

## Kitty keyboard protocol

Progressive enhancement flags (combine by adding):

| Bit | Value | Meaning |
|--|--|--|
| 0b1 | 1 | Disambiguate escape codes (Esc, Alt, Ctrl combinations become unambiguous) |
| 0b10 | 2 | Report event types (press, repeat, release) |
| 0b100 | 4 | Report alternate keys (shifted and base-layout keys) |
| 0b1000 | 8 | Report all keys as escape codes (including plain text keys) |
| 0b10000 | 16 | Report associated text |

| Action | Sequence | Notes |
|--|--|--|
| Push flags | `CSI > flags u` | Pushes onto the terminal's stack; omitted flags default to 0. |
| Pop flags | `CSI < number u` | Pops `number` entries; default 1. Emit on every exit path. |
| Query flags | `CSI ? u` | Reply `CSI ? flags u`. No reply means unsupported; bound the wait. |
| Set flags in place | `CSI = flags ; mode u` | mode 1 = replace (default), 2 = set bits, 3 = reset bits. |

Start with flag 1 only. It fixes the Esc/Alt ambiguity without changing plain-text input. It does change Ctrl combinations: Ctrl-C arrives as `CSI 99;5u` and Ctrl-Z as `CSI 122;5u`, not `0x03` / `0x1a` (Enter, Tab, and Backspace keep their legacy bytes). Map both forms. Push it after entering the alternate screen, and pop it before leaving. The screen buffers keep separate flag stacks, so a pop on the wrong screen leaves the protocol active.

## xterm modifyOtherKeys

| Action | Sequence | Notes |
|--|--|--|
| Enable level 2 | `CSI > 4 ; 2 m` | All modifiers apply; e.g. Shift-Tab sends `CSI 27;2;9~` instead of `CSI Z`. |
| Reset | `CSI > 4 m` | Omitted value resets to the terminal's initial setting. Emit during cleanup. |

## Mouse tracking

Enable one tracking mode plus SGR encoding. `?1006` alone only selects the encoding and produces no events.

| Mode | Set / reset | Reports |
|--|--|--|
| Normal tracking | `CSI ? 1000 h` / `l` | Press and release |
| Button-event tracking | `CSI ? 1002 h` / `l` | Press, release, and motion while a button is held (drag) |
| Any-event tracking | `CSI ? 1003 h` / `l` | All motion, including hover; noisy |
| SGR encoding | `CSI ? 1006 h` / `l` | Decimal coordinates with no 223-column limit; distinct press/release; preferred |
| UTF-8 encoding | `CSI ? 1005 h` / `l` | Legacy; coordinates stop at 2015 |
| URXVT encoding | `CSI ? 1015 h` / `l` | Legacy; decimal, but `CSI Cb ; Cx ; Cy M` is ambiguous with `CSI Ps M` (delete lines) |

SGR report format: `CSI < Cb ; Cx ; Cy M` for press, `CSI < Cb ; Cx ; Cy m` for release. `Cx` and `Cy` are 1-based columns and rows.

`Cb` bits:

| Value | Meaning |
|--|--|
| 0 / 1 / 2 | Left / middle / right button |
| +4 | Shift held |
| +8 | Meta (Alt) held |
| +16 | Ctrl held |
| +32 | Motion event |
| 64 / 65 | Wheel up / wheel down (no release events) |
| 66 / 67 | Wheel left / wheel right (horizontal scroll; no release events) |
| +128 | Buttons 8–11 |

Example: `CSI < 0 ; 10 ; 5 M` is a left press at column 10, row 5. `CSI < 20 ; 10 ; 5 M` is the same click with Shift+Ctrl held (0 + 4 + 16). Many terminals reserve Shift-click for native selection and never report it.

## Bracketed paste

Enable with `CSI ? 2004 h`, disable with `CSI ? 2004 l`. Pasted text arrives framed as `CSI 200~` + text + `CSI 201~`. Buffer until the end marker, and end the paste at the first `CSI 201~`. Pasted text containing its own `CSI 201~` therefore ends the paste early, and the bytes after it arrive as keystrokes. Some terminals strip such control bytes from pasted content, but many do not, and the app cannot tell the two apart. Treat bytes after a paste as untrusted input. Never auto-execute pasted text, and confirm multi-line pastes before acting.

## Focus events

Enable with `CSI ? 1004 h`, disable with `CSI ? 1004 l`. The terminal sends `CSI I` on focus in and `CSI O` on focus out. These events are advisory: multiplexers may filter them, and nothing correct may depend on them.

## Suspend and resume (Ctrl-Z) in raw mode

With ISIG off, Ctrl-Z arrives as byte `0x1a` (or `CSI 122;5u` under the Kitty keyboard protocol) and the kernel does not stop the process. To support suspend:

1. On Ctrl-Z, run the full teardown (pop keyboard protocols, disable focus/paste/mouse, show cursor, leave alt screen, restore cooked mode).
2. Stop the process with `raise(SIGTSTP)` (or `kill(getpid(), SIGTSTP)`); the shell regains the terminal. If the app installed its own `SIGTSTP` handler, reset it to `SIG_DFL` first, or `raise` re-enters the handler instead of stopping; reinstall the handler on `SIGCONT`.
3. On `SIGCONT`, re-enter raw mode, the alt screen, and every input mode in setup order. Re-query the size, because the terminal may have been resized while stopped, then do a full redraw.

Handle `SIGTSTP` sent from outside (`kill -TSTP`) with the same teardown. Many frameworks already provide this; prefer them. Bubble Tea: `tea.Suspend` (v0.26+, including every v1 and v2 release). Textual: bind `ctrl+z` to the `suspend_process` action (`App.action_suspend_process`); `with app.suspend():` is for handing the terminal to an external program, not for Ctrl-Z. ncurses: `endwin()` before stopping, `refresh()` after resuming. Windows has no SIGTSTP; disable or hide the suspend binding there.

## Child-process handoff

General rule (from `domains/input-handling/GUIDE.md`): full teardown, run the child with inherited stdio, full setup, re-query the size, full redraw. The terminal sends Ctrl-C and Ctrl-\ to the whole foreground process group, so the parent receives SIGINT/SIGQUIT too while the child runs (when the child leaves ISIG on, as shells, pagers, and `code --wait` do; vim and nano in raw mode generate no signals, which is why the bug seems editor-specific). Every app must ignore SIGINT and SIGQUIT during the child (as `system(3)` does), whether or not it installed its own handler: the default action kills the parent, and a custom handler quits the app when the child returns. Framework hooks do not do this for SIGQUIT, and most do not do it for SIGINT.

Run `$EDITOR` through the shell, because the variable may hold arguments (`code --wait`, `emacsclient -t`):

```python
import os, subprocess
editor = os.environ.get("VISUAL") or os.environ.get("EDITOR") or "vi"
rc = subprocess.call(["sh", "-c", "exec " + editor + ' "$1"', "sh", path])  # 127: editor not found
```

Per framework:

- **Ratatui/Crossterm:** `suspend_for()` in `domains/framework-recipes/references/rust-python-go.md`. It tears down, runs the child, re-enters, and re-arms the guard's `ACTIVE` flag (otherwise `Drop` and the panic hook go inert), and its signal thread skips SIGINT and SIGQUIT while the child runs. Then redraw with `let s = terminal.size()?; terminal.resize(Rect::new(0, 0, s.width, s.height))?;` (the skeleton routes both errors through `hangup_or`, so a hangup reports 129), not `terminal.clear()`, which sends a cursor-position query on ratatui-core 0.1.1+ (see the Notes there).
- **Bubble Tea:** `tea.ExecProcess(cmd, callback)`.
  - SIGINT race: the built-in signal handler ignores SIGINT and SIGTERM while the terminal is released, but `RestoreTerminal` clears that flag the moment the child is reaped, so a Ctrl-C typed into the child can still quit the app (rare normally, frequent when pinned to one CPU; seen on v1.3.0 and v1.3.10). Close the window with an `ExecCommand` wrapper whose `Run` sleeps about 50 ms after the child exits, as the skeleton's `execChild` does.
  - SIGTERM during exec is dropped, not deferred: the app keeps running after the child returns.
  - SIGQUIT is never subscribed, so a Ctrl-\ typed into the child kills the app (exit 2; an external `kill -QUIT` while the TUI runs also leaves the tty raw). Subscribe once before `p.Run()`: `signal.Notify(make(chan os.Signal, 1), syscall.SIGQUIT)`. That makes an external `kill -QUIT` do nothing for the whole run; to honor it, drain the channel and call `p.Quit()` when no child runs.
  - An app that passes `tea.WithoutSignalHandler()` and handles signals itself must skip SIGINT and SIGQUIT during exec. The Go skeleton in `domains/framework-recipes/references/rust-python-go.md` does all of this.
- **Ink:** `handOff()` in `domains/framework-recipes/references/node-dotnet.md`. Call `waitUntilExit()` before `unmount()` (the reverse hangs on Ink 4), and ignore SIGINT and SIGQUIT while the child runs.
- **Python:** Textual and curses: use `run_child()` below. prompt_toolkit `PromptSession`: use `run_editor()` in `domains/framework-recipes/references/rust-python-go.md` (its loop handlers skip SIGINT/SIGQUIT while `in_child`). Full-screen prompt_toolkit `Application`: `run_child()` inside `run_in_terminal`.
  - Textual `with app.suspend():` installs no SIGINT handling, so `asyncio.Runner`'s SIGINT handler cancels the main task and a Ctrl-C typed into the child quits the app. Ctrl-\ kills it (131).
  - Full-screen prompt_toolkit `Application` with `run_in_terminal(func)` survives Ctrl-C unless the app binds `<sigint>` itself, but Ctrl-\ kills it and leaves IXON off (echo, canonical mode and ISIG are restored). An app `<sigint>` binding fires once after the child returns, even with `run_child`, because Ctrl-C typed into the child is replayed through the loop's wakeup fd. Gate the binding with an `in_child` flag kept set for about 50 ms after the child exits; see the prompt_toolkit section of `domains/framework-recipes/references/rust-python-go.md`.
  - `PromptSession` prompts and curses: the default SIGINT handling ends the parent (KeyboardInterrupt or exit 130).

  Call `run_child(argv)` inside `app.suspend()` or the `run_in_terminal` function:

  ```python
  import signal, subprocess
  def run_child(argv):
      sigs = [s for s in (signal.SIGINT, getattr(signal, "SIGQUIT", None)) if s is not None]
      old = {s: signal.signal(s, lambda *_: None) for s in sigs}
      try:
          return subprocess.call(argv, shell=isinstance(argv, str))  # Windows: editor command string
      finally:
          for s, h in old.items():
              signal.signal(s, h)
  ```

  The no-op handlers are caught handlers, so `exec` resets them to the default action in the child, and Ctrl-C and Ctrl-\ still stop it. `SIG_IGN` would be inherited, and `preexec_fn` is unsafe in threaded apps (Textual runs threads). Call `run_child` from the main thread: `signal.signal` raises `ValueError` elsewhere. From a Textual thread worker (`@work(thread=True)`), hand the whole `with self.app.suspend(): run_child(argv)` block to the main thread with `self.app.call_from_thread(fn)`. For curses, call `curses.def_prog_mode(); curses.endwin()` before `run_child`, then `stdscr.refresh()` after. Windows has no SIGQUIT, so `run_child` swaps only the SIGINT handler there, and a command string (as `editor_argv` returns on Windows) runs through the shell.
- **tcell:** `screen.Suspend()`, run the child, `screen.Resume()`. **tview:** `app.Suspend(func)`. tcell subscribes only to SIGWINCH, so Go's default action for SIGINT and SIGQUIT kills the app. Call `signal.Notify(ch, syscall.SIGINT, syscall.SIGQUIT)` before suspending and drain `ch` while suspended. An app that already notifies these signals must skip them during the child. Do not use `signal.Ignore`: `SIG_IGN` is inherited across exec, so the child cannot be interrupted either.
- **Cursive:** no suspend hook. Record the request, call `siv.quit()`, run the child once `siv.run()` returns, then call `siv.run()` again. Rust's default SIGINT and SIGQUIT actions kill the app, so ignore both around the child: register them with `signal-hook` (a no-op flag, not `SIG_IGN`) and discard what arrives.
- **Terminal.Gui v1:** no handoff API (`Driver.Suspend()` is Ctrl-Z only, and a no-op on Windows). Call `Application.RequestStop()` on the top-level. After `Run` returns: `Application.Shutdown()`, run the child, `Application.Init()`, rebuild the views (`Shutdown` disposes every toplevel), then `Run` again. Ctrl-C (and Ctrl-\ on Unix, as `ControlBreak`) in the child also raises `Console.CancelKeyPress` in the parent; set `e.Cancel = true` while the child runs, or .NET ends the process.

## Input failure modes

| Symptom | Likely cause | Fix |
|--|--|--|
| Esc feels delayed | parser or tmux waiting to distinguish Alt prefix | lower escape timeouts (see "Esc is slow" in `domains/input-handling/GUIDE.md`) or negotiate the Kitty keyboard protocol |
| Ctrl-C does not exit | raw mode delivers a byte or Kitty sequence, not SIGINT | map both forms to cleanup and exit (raw-mode rules in `domains/input-handling/GUIDE.md`) |
| Ctrl-C in `$EDITOR` quits the app | parent receives the foreground-group SIGINT/SIGQUIT | ignore both during the child ("Child-process handoff" above) |
| Paste triggers actions | no bracketed paste or paste treated as keystrokes | enable paste protocol and route as text |
| Mouse clicks wrong row | stale layout after resize or scroll | validate coordinates against current viewport |
| Focus disappears | no focused fallback after removing widget | compute next eligible focus target |
