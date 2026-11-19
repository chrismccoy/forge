# Rust, Python, and Go Framework Recipes

Contents: Rust Ratatui + Crossterm (guard and event loop skeleton, Termion, Cursive) · Python Textual, Rich, prompt_toolkit, curses · Go Bubble Tea, Lip Gloss, Bubbles, tview, tcell (Bubble Tea skeleton, tview/tcell, Urwid/asciimatics/termui/gocui) · Cross-ecosystem migration hints

## Rust Ratatui + Crossterm

Use Ratatui when immediate-mode widgets, precise layout, and Rust performance are beneficial. Common architecture: application state, event source, update function, draw function, terminal guard. Keep rendering deterministic and snapshot buffers for tests. Crossterm is the usual backend choice for Windows/macOS/Linux coverage.

### Guard and event loop skeleton

```rust
use std::{
    io,
    process::{Command, ExitStatus},
    sync::{atomic::{AtomicBool, AtomicUsize, Ordering}, Arc, Once},
    time::{Duration, Instant},
};
use signal_hook::consts::signal::{SIGINT, SIGTERM}; // signal-hook 0.3
#[cfg(unix)]
use signal_hook::consts::signal::{SIGHUP, SIGQUIT}; // Unix-only; Windows has neither
use std::io::IsTerminal; // Rust 1.70+; used on every platform (run() records STDIN_TTY/STDOUT_TTY; tty_gone on Unix)
use ratatui::crossterm::{
    cursor::{Hide, Show},
    event::{
        self, DisableBracketedPaste, DisableMouseCapture, EnableBracketedPaste,
        EnableMouseCapture, Event, KeyCode, KeyEventKind, KeyModifiers,
    },
    execute,
    style::ResetColor,
    terminal::{disable_raw_mode, enable_raw_mode, EnterAlternateScreen, LeaveAlternateScreen},
};
use ratatui::{backend::CrosstermBackend, layout::Rect, Terminal};

// Set once raw mode is on; cleared by the first restore so hook + Drop never double-restore.
static ACTIVE: AtomicBool = AtomicBool::new(false);
static HOOK: Once = Once::new();
// Set while suspend_for() runs a child, so a Ctrl-C or Ctrl-\ typed into the child does not end this process.
static IN_CHILD: AtomicBool = AtomicBool::new(false);
// Whether stdin and stdout were terminals at startup. crossterm falls back to /dev/tty for piped
// stdin, so "no longer a terminal" means a hangup only for a stream that was one to begin with.
static STDIN_TTY: AtomicBool = AtomicBool::new(false);
static STDOUT_TTY: AtomicBool = AtomicBool::new(false);

// True once a stream that was a terminal at startup stops being one (isatty fails on a hung-up tty).
#[cfg(unix)] // the only callers are Unix-only
fn tty_gone() -> bool {
    (STDIN_TTY.load(Ordering::SeqCst) && !io::stdin().is_terminal())
        || (STDOUT_TTY.load(Ordering::SeqCst) && !io::stdout().is_terminal())
}

fn restore_terminal() {
    if !ACTIVE.swap(false, Ordering::SeqCst) { return; } // idempotent
    // Exact reverse of setup: protocols off, SGR reset, cursor on, leave alt screen, raw off.
    // execute! stops at the first error. On Windows DisableMouseCapture goes through the console API
    // and fails if capture was never enabled (e.g. setup failed early), so it runs last, on its own.
    let _ = execute!(io::stdout(), DisableBracketedPaste, ResetColor, Show, LeaveAlternateScreen);
    let _ = execute!(io::stdout(), DisableMouseCapture);
    let _ = disable_raw_mode();
}

struct TerminalGuard;
impl TerminalGuard {
    fn enter() -> io::Result<Self> {
        // Install once: restore before the default hook prints, so the panic message lands on the main screen.
        HOOK.call_once(|| {
            let default_hook = std::panic::take_hook();
            std::panic::set_hook(Box::new(move |info| {
                restore_terminal();
                default_hook(info);
            }));
        });
        enable_raw_mode()?;
        ACTIVE.store(true, Ordering::SeqCst);
        // Build the guard before any further fallible step: if execute! fails, Drop still restores.
        let guard = Self;
        execute!(io::stdout(), EnterAlternateScreen, Hide, EnableMouseCapture, EnableBracketedPaste)?;
        Ok(guard)
    }
}
impl Drop for TerminalGuard {
    fn drop(&mut self) { restore_terminal(); }
}

// Hand the terminal to a child ($EDITOR, pager, shell). restore_terminal() clears ACTIVE, so this
// sets it again on the way back; without that the guard's Drop and the panic hook do nothing later.
// Outer error: the TUI could not be re-entered (fatal, propagate with `?`).
// Inner result: the child itself (spawn failure or exit status; show it, keep running).
// The caller follows with `terminal.resize(...)` to force a full redraw at the current size.
fn suspend_for(cmd: &mut Command) -> io::Result<io::Result<ExitStatus>> {
    // Set before teardown: once raw mode is off, a Ctrl-C typed for the child raises SIGINT.
    IN_CHILD.store(true, Ordering::SeqCst);
    restore_terminal();
    let status = cmd.status(); // inherits stdin/stdout/stderr
    // Grace: a Ctrl-C sent to the process group as the child dies can reach the signal
    // thread just after status() returns; keep ignoring it briefly.
    std::thread::sleep(Duration::from_millis(50));
    IN_CHILD.store(false, Ordering::SeqCst);
    enable_raw_mode()?;
    ACTIVE.store(true, Ordering::SeqCst);
    execute!(io::stdout(), EnterAlternateScreen, Hide, EnableMouseCapture, EnableBracketedPaste)?;
    Ok(status)
}

// $VISUAL, then $EDITOR, then a default. Either variable may hold arguments ("code --wait",
// "emacsclient -t"), which Command::new does not split, so hand the string to a shell.
fn editor_command(path: &str) -> Command {
    let pick = |k: &str| std::env::var(k).ok().filter(|v| !v.trim().is_empty());
    let default = if cfg!(windows) { "notepad" } else { "vi" };
    let editor = pick("VISUAL").or_else(|| pick("EDITOR")).unwrap_or_else(|| default.into());
    // The path travels as "$1", never spliced into the command string. `exec` replaces the shell
    // (dash forks otherwise), so a signal that kills it cannot leave the editor running.
    #[cfg(unix)]
    let c = {
        let mut c = Command::new("sh");
        c.arg("-c").arg(format!("exec {editor} \"$1\"")).arg("sh").arg(path);
        c
    };
    // cmd.exe does its own parsing; raw_arg skips Rust's MSVC-style quoting. With /S, cmd strips
    // exactly the outer quote pair, so a quoted editor path with spaces survives. App-chosen paths only.
    #[cfg(windows)]
    let c = {
        use std::os::windows::process::CommandExt;
        let mut c = Command::new("cmd");
        c.arg("/S").arg("/C").raw_arg(format!("\"{editor} \"{path}\"\""));
        c
    };
    c
}

// An I/O error after the terminal is gone (read or write EIO that beats SIGHUP to this
// process) is a hangup: report 129, not 1. Errors with the terminal still present propagate unchanged.
fn hangup_or(e: io::Error) -> io::Result<i32> {
    #[cfg(unix)]
    if tty_gone() { return Ok(128 + SIGHUP); }
    Err(e)
}

// Returns the process exit status: 0 for q, 130 for the Ctrl-C key, 128+n for signal n.
fn run(mut app: App) -> io::Result<i32> {
    STDIN_TTY.store(io::stdin().is_terminal(), Ordering::SeqCst);
    STDOUT_TTY.store(io::stdout().is_terminal(), Ordering::SeqCst);
    // `kill <pid>` (SIGTERM), a closed terminal (SIGHUP), or an external SIGINT would end
    // the process without running Drop. Record the signal instead and leave the loop.
    let sig = Arc::new(AtomicUsize::new(0));
    #[cfg(unix)]
    {
        // signal_hook::iterator is Unix-only (default `iterator` feature).
        let mut signals = signal_hook::iterator::Signals::new([SIGTERM, SIGHUP, SIGINT, SIGQUIT])?;
        let flag = Arc::clone(&sig);
        std::thread::spawn(move || {
            for s in signals.forever() {
                // Ctrl-C / Ctrl-\ typed into a suspend_for() child reach the whole foreground
                // process group; ignore them here, as system(3) does, and let the child decide.
                if (s == SIGINT || s == SIGQUIT) && IN_CHILD.load(Ordering::SeqCst) { continue; }
                flag.store(s as usize, Ordering::SeqCst);
                // SIGTERM/SIGHUP during a child: wait for it, so it is never orphaned in the
                // foreground group (a hangup usually reaches the child too: via the shell, or as soon
                // as it touches the dead tty).
                while IN_CHILD.load(Ordering::SeqCst) {
                    std::thread::sleep(Duration::from_millis(50));
                }
                // Normal path: the loop sees the flag within ~100 ms, the guard restores, main exits.
                // Watchdog: after a real hangup crossterm's reader can spin inside event::poll and
                // never return to the flag check, so restore and exit from here after a grace period.
                std::thread::sleep(Duration::from_secs(1));
                restore_terminal(); // idempotent: a no-op if the guard already restored
                std::process::exit(128 + s);
            }
        });
        // Hangup without SIGHUP: if the session leader ignores or does not forward SIGHUP, a closed
        // terminal sends no signal and the idle reader spins forever. Check once a second whether
        // stdin and stdout are still terminals; skip while a child owns the terminal.
        {
            let flag = Arc::clone(&sig);
            std::thread::spawn(move || loop {
                std::thread::sleep(Duration::from_secs(1));
                if IN_CHILD.load(Ordering::SeqCst) || !tty_gone() { continue; }
                // Same path as a signal: the loop exits normally if it can; otherwise restore here.
                let _ = flag.compare_exchange(0, SIGHUP as usize, Ordering::SeqCst, Ordering::SeqCst);
                std::thread::sleep(Duration::from_secs(1));
                restore_terminal();
                std::process::exit(128 + flag.load(Ordering::SeqCst) as i32);
            });
        }
    }
    #[cfg(windows)]
    for s in [SIGTERM, SIGINT] {
        signal_hook::flag::register_usize(s, Arc::clone(&sig), s as usize)?;
    }
    let _guard = TerminalGuard::enter()?;
    let backend = CrosstermBackend::new(io::stdout());
    let mut terminal = Terminal::new(backend)?;
    let mut last_tick = Instant::now();

    loop {
        let caught = sig.load(Ordering::Relaxed);
        if caught != 0 { return Ok(128 + caught as i32); } // _guard drops here and restores
        if let Err(e) = terminal.draw(|f| ui(f, &app)) { return hangup_or(e); }
        let timeout = Duration::from_millis(100).saturating_sub(last_tick.elapsed());
        let ready = match event::poll(timeout) { Ok(r) => r, Err(e) => return hangup_or(e) };
        if ready {
            let ev = match event::read() { Ok(ev) => ev, Err(e) => return hangup_or(e) };
            match ev {
                // Windows reports Press and Release; handle Press only or every key fires twice.
                Event::Key(k) if k.kind != KeyEventKind::Press => {}
                // Raw mode disables ISIG, so Ctrl-C arrives as a key event, not SIGINT.
                Event::Key(k) if k.code == KeyCode::Char('c') && k.modifiers.contains(KeyModifiers::CONTROL) => return Ok(130),
                Event::Key(k) if k.code == KeyCode::Char('q') => break,
                Event::Key(k) if k.code == KeyCode::Char('e') => {
                    let res = suspend_for(&mut editor_command("notes.txt"));
                    // Windows: the flag handler cannot tell a child's console Ctrl-C apart; drop it.
                    #[cfg(windows)]
                    let _ = sig.compare_exchange(SIGINT as usize, 0, Ordering::SeqCst, Ordering::SeqCst);
                    // A signal during the child (e.g. the terminal closed) wins over a re-entry error.
                    let caught = sig.load(Ordering::SeqCst);
                    if caught != 0 { return Ok(128 + caught as i32); }
                    // Outer error: the TUI could not be re-entered, so stop. If the terminal closed while
                    // the child ran, re-entry fails before the shell's SIGHUP reaches this process (seen
                    // under `bash -i`); hangup_or reports that as 129, not 1.
                    let res = match res { Ok(r) => r, Err(e) => return hangup_or(e) };
                    match res {
                        Ok(st) if !st.success() => app.update(Msg::Status(format!("editor: {st}"))),
                        Ok(_) => {}
                        Err(e) => app.update(Msg::Status(format!("cannot start editor: {e}"))),
                    }
                    // Full redraw at the current size; resize() resets the back buffer without the
                    // cursor query that clear() sends on ratatui-core 0.1.1+ (see Notes).
                    let s = match terminal.size() { Ok(s) => s, Err(e) => return hangup_or(e) };
                    if let Err(e) = terminal.resize(Rect::new(0, 0, s.width, s.height)) { return hangup_or(e); }
                }
                Event::Key(k) => app.update(Msg::Key(k)),
                Event::Resize(w, h) => app.update(Msg::Resize(w, h)),
                Event::Mouse(m) => app.update(Msg::Mouse(m)),
                Event::Paste(s) => app.update(Msg::Paste(s)),
                _ => {}
            }
        }
        if last_tick.elapsed() >= Duration::from_millis(100) {
            app.update(Msg::Tick);
            last_tick = Instant::now();
        }
    }
    Ok(0)
}

fn main() -> io::Result<()> {
    let code = run(App::default())?; // the guard has already restored the terminal
    if code != 0 {
        std::process::exit(code); // 130 = Ctrl-C, 128+n = death by signal n
    }
    Ok(())
}
```

Notes:

- Signals: crossterm and Ratatui install no SIGTERM/SIGHUP handlers, so without `signal-hook` a plain `kill <pid>` leaves raw mode and the alternate screen on. The 100 ms poll timeout bounds how long the loop takes to notice a recorded signal. A real hangup (terminal window closed) is the exception: the tty then reads 0 bytes forever, and crossterm's Unix reader (0.28/0.29) loops inside `event::poll` without honoring its timeout, so the flag check never runs and the process spins at 100% CPU. The Unix signal thread above is the watchdog for that case: it waits one second for the normal path, then restores (writes to a dead tty fail silently) and exits 128+n. Do not rely on `terminal.draw` failing with an I/O error; the loop never gets back to it. When a draw, poll, or read does fail first (EIO before SIGHUP arrives), `hangup_or` reports 129 instead of 1 once stdin or stdout, having been a terminal at startup, no longer is one (`tty_gone`). The watchdog also runs on the normal signal path, so keep post-loop cleanup (saving state, flushing logs) under its one-second grace, or raise the grace. If SIGHUP never reaches the process (its session leader ignores or does not forward SIGHUP, e.g. a `disown -h` job or a `trap '' HUP` shell; the app's own handler overrides an inherited ignore, so the app itself never ignores it), no signal starts the watchdog; the second Unix thread covers that case by checking `tty_gone()` once a second, then taking the same flag-then-watchdog path and exiting 129 (skipped while `suspend_for()` runs a child). Checking stdout too covers piped stdin, where crossterm reads `/dev/tty`.
- Mouse and paste events only arrive after `EnableMouseCapture` / `EnableBracketedPaste`. Omit both (and their disables) when the app does not use them.
- Panic ordering: a guard's `Drop` runs during unwinding, *after* the default panic hook has already printed into the alternate screen, so the message is wiped when the screen is left. Installing a hook that restores first (as above) keeps the message visible. `color_eyre` hooks need the same wrapping.
- The skeleton imports crossterm through ratatui's re-export (`ratatui::crossterm`, present since ratatui 0.27). Use it instead of a separate `crossterm` dependency, so the build does not link two crossterm versions whose types do not match.
- Ratatui 0.28.1+ ships `ratatui::init()` / `ratatui::restore()`: `init()` enables raw mode, enters the alternate screen, and installs a restoring panic hook. It does not enable mouse capture or bracketed paste; enable those separately and disable them before `restore()`. Ratatui 0.30 adds `ratatui::run(|terminal| ...)`, which is `init()`, the closure, then `restore()`: the same limits apply (no mouse, no paste, no SIGTERM/SIGHUP handling, and `init()` panics if setup fails), so keep the manual guard when the app needs any of those.
- Child handoff: `suspend_for()` is the only safe way to run `$EDITOR` from this skeleton. Calling `restore_terminal()` alone disarms the guard for the rest of the run, because it clears `ACTIVE` and nothing sets it again. While the child runs, the signal thread ignores SIGINT/SIGQUIT (the child owns Ctrl-C and Ctrl-\) and defers SIGTERM/SIGHUP until the child exits; a `kill <app pid>` therefore takes effect when the editor closes. A missing editor under `sh -c` is not a spawn error: it returns exit status 127, which the status-line arm reports. If the terminal closes while the editor runs, re-entry fails before the hangup signal arrives under some shells; `hangup_or` on the re-entry result reports 129 instead of 1.
- Redraw after the handoff with `terminal.resize(Rect::new(0, 0, s.width, s.height))`, not `terminal.clear()`. Ratatui 0.30.1+ requires ratatui-core 0.1.1+. Ratatui 0.30.0 accepts any ratatui-core 0.1.x, so it also gets 0.1.1+ whenever the lockfile is generated fresh or `cargo update` moves ratatui-core. With ratatui-core 0.1.1+, `clear()` first calls `get_cursor_position()`, a cursor-position query (DSR) that crossterm waits up to 2 s for. On a terminal that never answers, `clear()` fails before it resets the back buffer, so logging the error and continuing leaves the re-entered alternate screen blank. ratatui-core 0.1.0 and ratatui 0.29 and earlier do not query. `resize()` sends no cursor query for a fullscreen viewport and resets the back buffer on every version from ratatui 0.29 through ratatui-core 0.1.2.
- Keep `ui(frame, &app)` pure. Background threads send messages over channels; they do not draw.
- Snapshot custom widgets with fixed `Rect`, fixed theme, and stable data.
- Common pitfalls: failing to restore terminal modes after panic, drawing from background threads, over-redrawing on every tick, handling key Release events as presses, and measuring Unicode incorrectly in custom widgets.

### Termion

Termion is a Unix-only Rust terminal backend (no Windows support); prefer Crossterm when portability matters.

### Cursive

Cursive is a retained-mode Rust TUI library: a tree of views (dialogs, menus, `SelectView`, `EditView`, layers) with callbacks, focus traversal, and themes built in, over pluggable backends (crossterm, ncurses, pancurses, termion). Choose it over Ratatui for form- and dialog-heavy tools where built-in focus and widgets matter more than custom rendering; choose Ratatui for dashboards and custom-drawn layouts. Cursive owns the event loop (`siv.run()`) and restores the terminal when the `Cursive` runner is dropped; use the crossterm backend for Windows support, and avoid `std::process::exit` inside callbacks (call `siv.quit()` so cleanup runs). Cursive has no suspend hook; to run `$EDITOR`, record the request in user data, call `siv.quit()`, run the child after `siv.run()` returns (the runner's backend is dropped there, which restores the terminal), then call `siv.run()` again. The view tree survives because `run()` only borrows the `Cursive` root.

## Python Textual, Rich, prompt_toolkit, curses

### Textual worker and test pattern

Textual is for widget-rich apps with reactive state, CSS-like styling, workers, and built-in testing affordances. Avoid blocking workers on the UI thread.

```python
# Verified against Textual 3.7 and 8.2 (as of 2026-11, recheck on newer releases). Pin `textual` in test dependencies.
# Run with pytest + pytest-asyncio: mark tests with @pytest.mark.asyncio,
# or set `asyncio_mode = "auto"` under [tool.pytest.ini_options].
from collections.abc import Awaitable, Callable

import pytest
from textual.app import App, ComposeResult
from textual.reactive import reactive
from textual.widgets import Button, Static
from textual.worker import get_current_worker

class FetchApp(App):
    # init=False: skip running the watcher during compose (harmless either way on 3.7/8.2).
    status: reactive[str] = reactive("Idle", init=False)

    def __init__(self, loader: Callable[[], Awaitable[str]]) -> None:
        super().__init__()
        self.loader = loader  # injected so tests can mock network work

    def compose(self) -> ComposeResult:
        yield Button("Load", id="load")
        yield Static("Idle", id="status")

    def watch_status(self, value: str) -> None:
        self.query_one("#status", Static).update(value)

    def on_button_pressed(self, event: Button.Pressed) -> None:
        self.run_worker(self.fetch_data(), name="fetch", exclusive=True)

    async def fetch_data(self) -> None:
        worker = get_current_worker()
        self.status = "Loading..."
        result = await self.loader()
        if not worker.is_cancelled:
            self.status = result

@pytest.mark.asyncio
async def test_load_updates_status():
    async def fake_loader() -> str:
        return "Loaded 3 items"

    app = FetchApp(loader=fake_loader)
    async with app.run_test(size=(80, 24)) as pilot:
        await pilot.click("#load")
        await app.workers.wait_for_complete()  # async WorkerManager API
        await pilot.pause()                    # let watchers/refresh messages drain
        # Assert app state, not widget internals: Static.renderable was replaced
        # by `content`/`visual` in newer releases.
        assert app.status == "Loaded 3 items"
```

Test with fixed size and deterministic workers; inject and mock network loaders and clocks. Assert final state after `app.workers.wait_for_complete()`, never transient states such as "Loading" that race the worker. Use `run_test`/Pilot for interactions and pure unit tests for non-UI state.

### Rich

Rich is best for rich scrollback output, tables, trees, markdown, tracebacks, progress, and logging. Prefer it over a full-screen TUI when output can remain command-oriented. Use `Console(record=True, width=80, color_system=None)` for stable tests and avoid live displays when piping to non-TTY output.

### prompt_toolkit shell/prompt pattern

Use prompt_toolkit for shells, REPLs, completers, history, multiline editing, and sophisticated keybindings.

```python
from __future__ import annotations  # `list[str] | str` below; needed on Python 3.9 and earlier

import asyncio
import errno
import os
import signal
import subprocess
import sys

from prompt_toolkit import PromptSession
from prompt_toolkit.application import run_in_terminal
from prompt_toolkit.completion import WordCompleter
from prompt_toolkit.key_binding import KeyBindings
from prompt_toolkit.patch_stdout import patch_stdout

kb = KeyBindings()

@kb.add("c-c")
def _(event):
    event.app.exit(exception=KeyboardInterrupt)

session = PromptSession(
    completer=WordCompleter(["open", "close", "status", "quit"]),
    key_bindings=kb,
    # enable_history_search=True would disable complete-while-typing (completions only on Tab).
)

in_child = False  # set while a child owns the terminal; on_signal ignores Ctrl-C/Ctrl-\ then

def editor_argv(path: str) -> list[str] | str:
    # $VISUAL, then $EDITOR, then a default; either may hold arguments ("code --wait").
    editor = os.environ.get("VISUAL") or os.environ.get("EDITOR") or ("notepad" if sys.platform == "win32" else "vi")
    if sys.platform == "win32":
        return f'{editor} "{path}"'  # a string, run through cmd.exe (shell=True); app-chosen paths only
    return ["sh", "-c", f'exec {editor} "$1"', "sh", path]  # path stays "$1"; exec: editor replaces sh

async def run_editor(path: str) -> int:
    global in_child
    argv = editor_argv(path)
    # Without the loop handlers (Windows): a no-op Python handler, not SIG_IGN. SIG_IGN would be
    # inherited across exec, so the child could not be interrupted either.
    old = signal.signal(signal.SIGINT, lambda *_: None) if sys.platform == "win32" else None
    in_child = True
    try:
        # run_in_terminal suspends a running prompt (cooked mode) around the call; between
        # prompts it simply runs it.
        done = await run_in_terminal(lambda: subprocess.run(argv, shell=isinstance(argv, str)))
        # The loop reads a signal queued while the child ran only after this point: yield to it
        # while still ignoring, or the Ctrl-C that ended the child would cancel the REPL.
        await asyncio.sleep(0.05)
    finally:
        in_child = False
        if old is not None:
            signal.signal(signal.SIGINT, old)
    if done.returncode:
        print(f"editor exited with {done.returncode}")  # 127: editor not found
    return done.returncode

async def dispatch_command(line: str) -> None:
    # Replace with real command handling; keep long work async so the prompt stays responsive.
    if line.strip() == "edit":
        await run_editor("notes.txt")
        return
    print(f"ran: {line.strip()}")

async def repl() -> int:
    # SIGTERM/SIGHUP/SIGINT would end the process without restoring the tty. Record the
    # signal and cancel the task instead, so prompt_async unwinds and restores terminal modes.
    # A signal during dispatch_command (cooked mode, so Ctrl-C there raises SIGINT) exits the
    # whole REPL by design; cancel only the dispatch task instead to keep the REPL alive.
    loop = asyncio.get_running_loop()
    task = asyncio.current_task()
    caught = 0

    def on_signal(sig: int) -> None:
        nonlocal caught
        # Ctrl-C / Ctrl-\ typed into a child reach the whole foreground process group.
        if in_child and sig in (signal.SIGINT, signal.SIGQUIT):
            return
        caught = sig
        task.cancel()

    handled = []
    if sys.platform != "win32":  # add_signal_handler raises NotImplementedError on Windows
        for sig in (signal.SIGTERM, signal.SIGHUP, signal.SIGINT, signal.SIGQUIT):
            loop.add_signal_handler(sig, on_signal, sig)
            handled.append(sig)
    try:
        with patch_stdout():
            while True:
                try:  # covers dispatch too, so a signal mid-command also exits cleanly
                    # handle_sigint=False: by default prompt_async installs its own SIGINT
                    # handler and removes it on return, which would silently drop ours.
                    line = await session.prompt_async("app> ", handle_sigint=False)
                    if line.strip() in {"quit", "exit"}:
                        break
                    await dispatch_command(line)
                except EOFError:  # Ctrl-D
                    break
                except KeyboardInterrupt:  # Ctrl-C key binding
                    caught = signal.SIGINT
                    break
                except asyncio.CancelledError:
                    if not caught:
                        raise  # cancelled by something else: propagate
                    break
                except OSError as e:
                    # The terminal closed but no SIGHUP arrived (the session leader ignores or
                    # does not forward it): prompt_toolkit's redraw or teardown flush hits EIO.
                    if e.errno != errno.EIO:
                        raise
                    caught = signal.SIGHUP
                    break
    finally:
        for sig in handled:
            loop.remove_signal_handler(sig)
    # patch_stdout has exited and the terminal is restored; report death by signal as 128+n.
    return 128 + caught if caught else 0

def exit_with(code: int) -> None:
    # After a real terminal close the tty returns EIO, and CPython's final stdout flush
    # would turn the exit status into 120. Flush here; if the terminal is gone, skip
    # interpreter shutdown so the 128+signal status survives.
    try:
        sys.stdout.flush()
    except OSError:
        os._exit(code)
    sys.exit(code)

if __name__ == "__main__":
    exit_with(asyncio.run(repl()))
```

Python exit status after a hangup: the `except OSError` arm maps a write EIO (terminal closed, SIGHUP never delivered) to 129. Without the `exit_with` guard, a real terminal close (not `kill -HUP`) exits 120 instead of 129, because the final stdout flush fails with EIO. Nothing leaks either way (the terminal is already gone); the guard only keeps the status meaningful. The same pattern applies to any Python TUI that reports 128+signal.

Full-screen `Application` with its own `<sigint>` binding: Python's C-level handler still writes Ctrl-C typed into the child to the loop's wakeup fd, so the binding fires once after `run_in_terminal` returns. Gate it the same way as `on_signal` above: set a flag before the handoff, keep it set for about 50 ms after the child exits, and return early from the binding while it is set (verified on prompt_toolkit 3.0.36–3.0.53):

```python
in_child = False

@kb.add("<sigint>")
def _(event):
    if in_child:
        return  # Ctrl-C typed into the child, replayed after it returns
    event.app.exit(result="sigint")

@kb.add("e")
def _(event):
    async def edit() -> None:
        global in_child
        in_child = True
        try:
            await run_in_terminal(lambda: run_child(editor_argv("notes.txt")))
            await asyncio.sleep(0.05)  # the queued <sigint> arrives while still gated
        finally:
            in_child = False
    event.app.create_background_task(edit())
```

The gate covers only `<sigint>` (a real SIGINT). In raw mode the Ctrl-C key arrives as `c-c`, so the app still needs its own `c-c` binding to quit on the key.

`run_child` is the no-op-handler wrapper in "Child-process handoff" (`domains/input-handling/references/key-mouse-protocols.md`); `editor_argv` is from the snippet above.

Use `patch_stdout` when background tasks log while prompting. Provide non-interactive flags for automation and avoid full-screen mode for simple command entry.

### curses

Use curses when dependency footprint and classic terminal portability matter. Use cleanup wrappers, handle resize, and remember coordinate ordering is row,column (`y, x`). Keep domain state outside curses windows so it can be tested without a terminal.

## Go Bubble Tea, Lip Gloss, Bubbles, tview, tcell

### Bubble Tea Model/Update/View/Cmd skeleton

Bubble Tea is best for message-driven apps. The skeleton below (imports `errors`, `fmt`, `io`, `os`, `os/exec`, `os/signal`, `sync/atomic`, `syscall`, `time`, `tea`, and `github.com/charmbracelet/x/term`) is the **v1 API, v1.3.0 or later** (`github.com/charmbracelet/bubbletea`; `tea.Interrupt` and `tea.ErrInterrupted` do not exist before v1.3.0). v2 (`charm.land/bubbletea/v2`) changes it: match `tea.KeyPressMsg` (`tea.KeyMsg` becomes an interface covering presses and releases), `View()` returns `tea.View`, and alt screen is set via `v.AltScreen = true` instead of `tea.WithAltScreen()`. Pin the major version and check the upgrade guide before copying. Keep `Update` deterministic and move side effects into commands. Compose with Bubbles for controls, Lip Gloss for visual style, and Huh (Go, also Charm) for forms and prompts.

```go
type model struct {
	width, height int
	loading       bool
	items         []string
	err           error
}

type loadedMsg []string
type errMsg struct{ err error } // a struct, not `type errMsg error`: an interface-typed case would match any error value
type editorDoneMsg struct{ err error }

// Set while a child owns the terminal. WithoutSignalHandler (below) also drops Bubble Tea's own
// "ignore signals during exec", so the signal goroutine must skip a Ctrl-C typed into the child.
var inExec atomic.Bool

// execChild sets inExec for exactly the child's lifetime: Bubble Tea calls Run after releasing
// the terminal, so Update stays free of side effects and a quit before the exec leaves it unset.
// ReleaseTerminal restores cooked mode as its last step and Run follows with no I/O in between,
// so the window before the flag is set is microseconds of in-process code, not a tty write.
type execChild struct{ *exec.Cmd }

func (c execChild) Run() error {
	inExec.Store(true)
	defer func() {
		time.Sleep(50 * time.Millisecond) // a Ctrl-C sent as the child died may still be in flight
		inExec.Store(false)
	}()
	return c.Cmd.Run()
}
func (c execChild) SetStdin(r io.Reader) {
	if c.Stdin == nil {
		c.Stdin = r
	}
}
func (c execChild) SetStdout(w io.Writer) {
	if c.Stdout == nil {
		c.Stdout = w
	}
}
func (c execChild) SetStderr(w io.Writer) {
	if c.Stderr == nil {
		c.Stderr = w
	}
}

// Unix-only: on Windows `sh` is missing and the editor reports a spawn error. A Windows build
// needs cmd.exe with a raw command line (syscall.SysProcAttr.CmdLine) in a _windows.go file.
func editCmd(path string) tea.Cmd {
	editor := os.Getenv("VISUAL")
	if editor == "" {
		editor = os.Getenv("EDITOR")
	}
	if editor == "" {
		editor = "vi"
	}
	// $EDITOR may hold arguments ("code --wait"); let sh split it. The path stays "$1";
	// `exec` replaces the shell, so the editor is the direct child.
	c := exec.Command("sh", "-c", "exec "+editor+` "$1"`, "sh", path)
	return tea.Exec(execChild{c}, func(err error) tea.Msg {
		return editorDoneMsg{err} // exit status 127: editor not found
	})
}

func initialModel() model { return model{loading: true} }

func fetchCmd() tea.Cmd {
	return func() tea.Msg {
		items, err := fetchItems()
		if err != nil {
			return errMsg{err}
		}
		return loadedMsg(items)
	}
}

func (m model) Init() tea.Cmd { return fetchCmd() }

func (m model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.WindowSizeMsg:
		m.width, m.height = msg.Width, msg.Height
	case tea.KeyMsg:
		switch msg.String() {
		case "q":
			return m, tea.Quit
		case "ctrl+c": // raw mode: Ctrl-C is a key, not SIGINT
			return m, tea.Interrupt // v1.3+: Run returns tea.ErrInterrupted
		case "e":
			return m, editCmd("notes.txt")
		case "r":
			m.loading = true
			return m, fetchCmd()
		}
	case editorDoneMsg:
		m.err = msg.err // nil on success; show a failed or missing editor
	case loadedMsg:
		m.loading = false
		m.items = []string(msg)
	case errMsg:
		m.loading = false
		m.err = msg.err
	}
	return m, nil
}

func (m model) View() string {
	if m.width < 40 || m.height < 10 {
		return "Terminal too small. Press q to quit.\n"
	}
	if m.loading {
		return "Loading...\n"
	}
	if m.err != nil {
		return "Error: " + m.err.Error() + "\n"
	}
	return renderList(m.items, m.width, m.height)
}

func main() {
	// Bubble Tea v1's own handler restores on SIGINT/SIGTERM (SIGTERM: Run returns nil;
	// SIGINT: Run returns tea.ErrInterrupted from v1.3, nil before). It does not handle SIGHUP
	// (terminal closed), so Go's default action kills the process without restoring. Handle them here: quit through the program so it
	// restores the terminal, then exit with the conventional 128+signal status.
	p := tea.NewProgram(initialModel(), tea.WithAltScreen(), tea.WithoutSignalHandler())
	var caught atomic.Int32
	sigs := make(chan os.Signal, 1)
	signal.Notify(sigs, syscall.SIGINT, syscall.SIGTERM, syscall.SIGHUP, syscall.SIGQUIT)
	go func() {
		for s := range sigs {
			// Ctrl-C / Ctrl-\ typed into an exec'd child reach the whole foreground process group.
			if (s == syscall.SIGINT || s == syscall.SIGQUIT) && inExec.Load() {
				continue
			}
			// SIGTERM/SIGHUP during a child: the quit is processed once the child exits.
			caught.Store(int32(s.(syscall.Signal)))
			p.Quit()
			return
		}
	}()
	// term: github.com/charmbracelet/x/term, already a Bubble Tea v1 dependency. Record which streams
	// are terminals first: Bubble Tea opens /dev/tty itself when stdin is piped, so a stream that is
	// not a terminal after Run means a hangup only if it was one before.
	ttyIn, ttyOut := term.IsTerminal(os.Stdin.Fd()), term.IsTerminal(os.Stdout.Fd())
	ttyGone := func() bool {
		return (ttyIn && !term.IsTerminal(os.Stdin.Fd())) || (ttyOut && !term.IsTerminal(os.Stdout.Fd()))
	}
	if ttyIn || ttyOut {
		// Hangup without SIGHUP (the session leader ignores or does not forward it): v1 swallows io.EOF and
		// write errors, so an idle Run never returns. Poll once a second; skip while a child runs.
		go func() {
			for {
				time.Sleep(time.Second)
				if !inExec.Load() && ttyGone() {
					caught.CompareAndSwap(0, int32(syscall.SIGHUP))
					p.Quit()
					return
				}
			}
		}()
	}
	_, err := p.Run() // the terminal is restored once Run returns
	switch {
	case caught.Load() != 0:
		os.Exit(128 + int(caught.Load()))
	case errors.Is(err, tea.ErrInterrupted):
		os.Exit(130) // Ctrl-C key
	case err != nil && ttyGone():
		os.Exit(129) // terminal closed: Run failed (EIO) before SIGHUP arrived
	case err != nil:
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
```

Startup window: Bubble Tea v1's package `init` calls Lip Gloss/termenv `HasDarkBackground` before `main` runs, so before any app signal handler exists. termenv clears ECHO and ICANON (ISIG stays on, so Ctrl-C still kills the process) and queries the background color (OSC 11) and cursor position (DSR), waiting up to 5 s (`OSCTimeout`) if the terminal never answers. A signal in that window can leave the tty at `-echo -icanon`; app code cannot close this gap. If it happens, `stty sane` in the shell recovers it.

Hangup without SIGHUP: if its session leader ignores or does not forward SIGHUP, e.g. a `disown -h` job or a `trap '' HUP` shell, a closed terminal never ends an idle v1 program: its input reader swallows `io.EOF` and the renderer ignores write errors, so `Run` never returns. The polling goroutine in `main` covers that case: once stdin or stdout stops being a terminal (having been one at startup) it records SIGHUP and quits, so the program restores and exits 129. Checking stdout too covers piped stdin, where Bubble Tea reads `/dev/tty`.

In v1, use `tea.WithAltScreen()` for full-screen apps only. Consider `tea.WithMouseCellMotion()` or mouse modes only when required. Test `Update` directly and snapshot `View` with fixed width/height.

### tview and tcell

`tview` is best for quick widget-heavy apps such as forms, tables, trees, and pages. It inherits tcell portability. Keep data transformations outside widget callbacks and test resize/mouse/focus paths manually.

`tcell` is best for lower-level cell control without building on curses. Use its abstractions for Unicode width, mouse, paste, and truecolor where possible. Do not mix direct ANSI writes with tcell screen ownership.

### Urwid, asciimatics, termui, and gocui notes

- **Urwid**: mature Python widget toolkit with solid list/pile/columns patterns. Check Python version support, maintenance cadence, and Unicode behavior before choosing it for a new product. Strong for keyboard-first classic TUIs, less ideal for modern CSS-like styling.
- **asciimatics**: useful for terminal animation, forms, and visual effects. Be careful with CPU usage, frame rate, and accessibility; animations need reduced-motion and non-TTY fallbacks.
- **termui**: convenient Go dashboard widgets, but verify maintenance and resize behavior. Prefer Bubble Tea/tcell for apps requiring deep interaction and long-term support.
- **gocui**: small Go library for simple pane-based layouts. Validate maintenance, Unicode width, mouse, and Windows expectations; it can be enough for internal tools but may require custom widget work.

## Cross-ecosystem migration hints

- Elm-style state maps naturally between Bubble Tea and reducer-style Rust/Python designs.
- Widget-tree frameworks need lifecycle and focus management; immediate-mode frameworks need deterministic render functions.
- Rich output libraries are not substitutes for full-screen input frameworks, and full-screen frameworks are often overkill for reports.
- A framework with built-in tests and terminal cleanup is often more valuable than one with impressive screenshots.
