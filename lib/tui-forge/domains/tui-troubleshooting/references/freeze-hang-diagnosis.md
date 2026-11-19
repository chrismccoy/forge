# Freeze and Hang Diagnosis

A "frozen terminal" is often not a single bug. It can mean the process is alive but not rendering, input is disabled, stdin is paused, the terminal is in raw mode after exit, or alternate screen cleanup failed. Start by separating **process hang**, **render hang**, **input hang**, and **terminal-state leak**.

## Contents

- Fast triage
- Raw mode without restore
- Stdin paused/resumed mismatch
- Blocking I/O on the main thread
- Deadlock in the event loop
- Infinite render loop
- Missing first render
- Alternate screen without cleanup
- Mouse mode stuck on
- Bracketed paste not restored
- Focus event mode stuck
- Waiting for input that never comes
- TTY detection failure
- Node.js-specific failures
- Python-specific failures
- Rust-specific failures
- Go-specific failures
- SSH, tmux, and screen
- Windows-specific failures

## Fast triage

- Does Ctrl-C terminate the process? If yes, inspect cleanup and signal handling. If no, suspect event-loop blockage, native deadlock, or child process wait.
- Does typing appear? If no, echo may be off due to raw mode or the app is still running in alternate screen.
- Does CPU spike? If yes, suspect infinite render/update loop. If no, suspect blocked I/O, awaiting input, paused stdin, or async deadlock.
- Is the screen blank immediately? Suspect alternate screen entered before first flushed render.
- Is the shell broken after exit? Suspect raw mode, cursor, mouse, bracketed paste, focus, color, or alternate-screen cleanup leak.

## Raw mode without restore

**Symptom.** After a crash or Ctrl-C, typed characters do not echo, Enter does not behave normally, Ctrl-C may print `^C` oddly, and the user thinks the terminal froze.

**Root cause.** Raw mode disables canonical input processing and echo. If the program exits before `setRawMode(false)`, `disable_raw_mode()`, `noraw()`, `endwin()`, or equivalent cleanup, the shell inherits a hostile terminal state.

**Diagnostics.** Run `stty -a` in another shell attached to the same terminal if possible, or recover with `stty sane`. Inspect all early returns, exceptions, promise rejections, panics, and signal paths after raw mode is enabled.

**Fix pattern.** Install cleanup before enabling raw mode and make it idempotent.

```js
import fs from 'node:fs';
import os from 'node:os'; // CommonJS: const fs = require('node:fs'), os = require('node:os');

let cleaned = false;
let kittyPushed = false; // set true after writing '\x1b[>1u' (Kitty keyboard flags)
let inPaste = false;     // inside a bracketed paste (?2004): pasted bytes are data, not keys
function cleanup() {
  if (cleaned) return;
  cleaned = true;
  // Reverse of setup: pop Kitty flags; disable focus, paste, mouse; reset SGR; show cursor; leave alt screen; then cooked mode.
  // writeSync, not stdout.write: TTY writes can be asynchronous (Windows), and process.exit() drops pending async writes.
  try {
    fs.writeSync(process.stdout.fd, (kittyPushed ? '\x1b[<u' : '') +
      '\x1b[?1004l\x1b[?2004l\x1b[?1006l\x1b[?1003l\x1b[?1002l\x1b[?1000l\x1b[0m\x1b[?25h\x1b[?1049l');
    if (process.stdin.isTTY) process.stdin.setRawMode(false);
  } catch { /* terminal already gone (hangup): nothing left to restore */ }
}
process.stdin.on('data', chunk => {
  // Raw mode turns off ISIG: Ctrl-C arrives as byte 0x03 and never raises SIGINT.
  // Kitty keyboard flags change Ctrl-C to CSI 99;5u (see domains/input-handling/references/key-mouse-protocols.md).
  // chunk is a string after setEncoding('utf8'), a Buffer otherwise; normalize before checking.
  // latin1 maps each byte to one char: use it only to spot control bytes here; decode real text input as UTF-8.
  const s = typeof chunk === 'string' ? chunk : chunk.toString('latin1');
  // Skip bytes inside a bracketed paste, so a pasted 0x03 does not quit.
  // Sketch: assumes paste markers are not split across chunks; a real parser buffers partial sequences.
  let keys = '';
  for (const part of s.split(/(\x1b\[20[01]~)/)) {
    if (part === '\x1b[200~') inPaste = true;
    else if (part === '\x1b[201~') inPaste = false;
    else if (!inPaste) keys += part;
  }
  if (keys.includes('\x03') || keys.includes('\x1b[99;5u')) { cleanup(); process.exit(130); }
  // ...normal input handling...
});
// A real terminal close often shows up as stdin 'end' before SIGHUP is delivered; treat it as a hangup.
process.stdin.once('end', () => { cleanup(); process.exit(128 + os.constants.signals.SIGHUP); });
// A stdin read or an async stdout/stderr write can also fail with EIO when the terminal closes;
// without a listener node exits 1. Only EIO means hangup; other stream errors (EPIPE) exit 1.
for (const s of [process.stdin, process.stdout, process.stderr]) {
  s.on('error', err => { cleanup(); process.exit(err?.code === 'EIO' ? 128 + os.constants.signals.SIGHUP : 1); });
}
process.once('exit', cleanup);
// Covers only an external `kill -INT`, not Ctrl-C typed in raw mode.
process.once('SIGINT', () => { cleanup(); process.exit(130); });
// 'exit' handlers do not run on death by signal, so restore explicitly for SIGTERM/SIGHUP/SIGQUIT too.
// SIGQUIT (external `kill -QUIT`; exits 131): Windows never delivers it to a listener (libuv emulates
// only SIGINT, SIGBREAK, SIGHUP and SIGWINCH; the constant exists from Node 20.3), so add it only elsewhere.
const fatal = ['SIGTERM', 'SIGHUP', ...(process.platform === 'win32' ? [] : ['SIGQUIT'])];
for (const sig of fatal) process.once(sig, () => { cleanup(); process.exit(128 + os.constants.signals[sig]); });
// A synchronous write (fs.writeSync in a render loop) throws EIO instead: report it as a hangup too.
process.once('uncaughtException', err => {
  cleanup();
  if (err?.code === 'EIO') process.exit(128 + os.constants.signals.SIGHUP);
  console.error(err);
  process.exit(1);
});
process.once('unhandledRejection', err => { cleanup(); console.error(err); process.exit(1); });
```

On Windows, TTY writes can be asynchronous, and `process.exit()` does not wait for pending asynchronous writes. Write teardown bytes with `fs.writeSync(process.stdout.fd, ...)` as above, or set `process.exitCode` and let the event loop drain instead of calling `process.exit()`.

**Prevention.** Use framework lifecycle guards, `try/finally`, Rust RAII guards, Go `defer`, Python `curses.wrapper`, or a single terminal-session object that restores modes in reverse order.

## Stdin paused/resumed mismatch

**Symptom.** The screen may draw once or remain blank, but no keypresses arrive. The process is alive and waiting. This is common in Node apps launched by `npm run tui`.

**Root cause.** `process.stdin.pause()` removes the stream from flowing mode. Enabling raw mode does not necessarily resume `data` events. If code pauses stdin before raw mode, then waits for key events without `resume()` or a `readable` loop, input never reaches the handler.

**Diagnostics.** Search for `stdin.pause()`, `setRawMode`, `on('data')`, `readline`, `unref`, and `resume`. Add temporary file logging around startup: "before raw", "after raw", "after resume", "data event". Do not log to the TUI screen.

**Fix pattern.** Configure stdin in one place and resume before waiting. This snippet only sets up input; pair it with the cleanup and Ctrl-C handler above, since alone it never exits on Ctrl-C.

```js
if (!process.stdin.isTTY) throw new Error('TUI requires a TTY');
process.stdin.setEncoding('utf8'); // data chunks are now strings, not Buffers
process.stdin.setRawMode(true);
process.stdin.resume();
process.stdin.ref();
process.stdin.on('data', key => dispatchKey(key)); // key: string; Ctrl-C is '\x03'
renderInitialFrame();
```

**Prevention.** Avoid mixing `readline`, raw `data` listeners, and framework input managers. If a status check temporarily stops input, explicitly restore the prior stream state.

## Blocking I/O on the main thread

**Symptom.** The app appears frozen on startup or after an action; no spinner advances; resize and input are ignored. CPU may be low if blocked on disk/network, or high if doing sync computation.

**Root cause.** Synchronous file reads, child process waits, DNS/network calls, JSON parsing, compression, database calls, or CPU-heavy layout block the UI thread before the render loop can flush.

**Diagnostics.** Add timestamped file logs before and after suspicious calls. In Node, inspect `readFileSync`, `execFileSync`, `spawnSync`, sync globbing, and large JSON parsing. In Python, inspect blocking calls inside Textual/curses callbacks. In Go/Rust, inspect locks and synchronous commands on the UI goroutine/thread.

**Fix pattern.** Draw first, then move work off the UI path.

```js
enterTerminal();
render({status: 'Checking project...'});
await flushOutput();
void checkProjectAsync()
  .then(result => update({result}))
  .catch(err => update({error: String(err?.message ?? err)}))
  .finally(scheduleRender);
```

**Prevention.** Treat first paint as a service-level objective. Put long work in workers, tasks, goroutines, commands, or async jobs that publish messages back to the UI.

## Deadlock in the event loop

**Symptom.** The UI waits forever after a particular action. CPU is usually idle. Logs show operation A waiting for operation B while B waits for A, or a render callback that never fires.

**Root cause.** Two async operations wait on each other, a promise is never resolved, a channel is never closed, or a lock is held while scheduling a callback that needs the same lock.

**Diagnostics.** Add timeouts around awaited operations. Dump pending promises/tasks where the runtime supports it. In Go, inspect goroutine dumps. In Rust, use tracing spans around async channels and locks.

**Fix pattern.** Never wait inside a handler that owns the UI loop. Move the wait and its timeout into a command that runs off the loop and returns a one-way message; `Update` only records the result.

```go
type resultMsg struct{ value Result }
type timeoutMsg struct{}

// Create the channel buffered: resultCh := make(chan Result, 1). After a timeout nobody receives,
// so a send on an unbuffered channel would block the producer goroutine forever.
func waitForResult(resultCh <-chan Result) tea.Cmd {
	return func() tea.Msg {
		select {
		case r := <-resultCh:
			return resultMsg{r}
		case <-time.After(10 * time.Second):
			return timeoutMsg{}
		}
	}
}

func (m model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case resultMsg:
		m.result = msg.value
	case timeoutMsg:
		m.err = errors.New("operation timed out") // err is an error field, as in the Bubble Tea skeleton
	}
	return m, nil
}

// Start the wait with: return m, waitForResult(ch)
```

**Prevention.** Keep update/reducer functions nonblocking. Never hold locks while sending UI messages or invoking render callbacks.

## Infinite render loop

**Symptom.** CPU spikes, fans spin, terminal may appear blank or flicker, and input is delayed. The process is alive but not making progress.

**Root cause.** Rendering mutates state, state mutation schedules render, and render mutates state again. Timers may schedule new ticks without coalescing.

**Diagnostics.** Count frames per second and state updates. Log render reasons to a file. If render counts climb without input or data changes, find state writes during view/layout/render.

**Fix pattern.** Make render pure and coalesce redraws.

```ts
let renderScheduled = false;
function scheduleRender() {
  if (renderScheduled) return;
  renderScheduled = true;
  setImmediate(() => {
    renderScheduled = false;
    draw(view(model));
  });
}
```

**Prevention.** Separate model, update, and view. Use immutable view input or lint rules/tests that forbid state mutation during render.

## Missing first render

**Symptom.** The terminal switches to a blank alternate screen and seems frozen until an async operation completes, or forever if that operation hangs.

**Root cause.** The app enters raw mode and alternate screen, then starts a status check or awaits input before writing and flushing an initial frame.

**Diagnostics.** Capture raw output. If the capture shows `CSI ? 1049 h` and maybe cursor-hide sequences but no clear/draw/frame bytes afterward, first render is missing. Add file logs around `enter`, `render`, and `flush`.

**Fix pattern.** Render a loading frame synchronously immediately after terminal setup.

```js
enableRawMode();
enterAlternateScreen();
process.stdin.resume();
render({screen: 'startup', message: 'Loading...'});
await new Promise(resolve => process.stdout.write('', resolve));
startAsyncChecks();
```

**Prevention.** Add a PTY test that asserts visible content appears within a short timeout after startup.

## Alternate screen without cleanup

**Symptom.** After the app exits, the shell scrollback is gone or the terminal remains blank until `reset` or a new tab.

**Root cause.** The app sent `CSI ? 1049 h` but did not send `CSI ? 1049 l` on every exit path.

**Diagnostics.** Capture output and look for enter without matching leave. Reproduce by forcing an exception immediately after terminal entry.

**Fix pattern.** Put alternate-screen leave in the same idempotent cleanup guard as raw-mode restore.

```rust
// Minimal guard. The full skeleton (idempotent restore shared with the panic hook) is in
// domains/framework-recipes/references/rust-python-go.md.
// Pair with the panic hook under "Rust-specific failures" below; Drop alone loses the panic message.
fn restore() {
    // Reverse of setup: disable paste and mouse, reset colors, show cursor, leave alt screen, then leave raw mode.
    // Running this twice is harmless. execute! stops at the first failing command, so
    // DisableMouseCapture gets its own call last: on Windows it uses the console API and
    // fails ("Initial console modes not set") if mouse capture was never enabled.
    // In a Ratatui app, write these paths as ratatui::crossterm::... so only one crossterm version links.
    let _ = crossterm::execute!(
        std::io::stdout(),
        crossterm::event::DisableBracketedPaste,
        crossterm::style::ResetColor,
        crossterm::cursor::Show,
        crossterm::terminal::LeaveAlternateScreen
    );
    let _ = crossterm::execute!(std::io::stdout(), crossterm::event::DisableMouseCapture);
    let _ = crossterm::terminal::disable_raw_mode();
}

struct TerminalGuard;
impl Drop for TerminalGuard {
    fn drop(&mut self) { restore(); }
}
```

Drop never runs when SIGTERM or SIGHUP kills the process, so `kill <pid>` leaves the terminal broken. Catch those signals on a thread (`signal_hook::iterator::Signals`, Unix-only, so gate it with `#[cfg(unix)]`; on Windows use `signal_hook::flag::register_usize` for SIGINT/SIGTERM), record the signal in a flag the loop checks, and exit with 128+signal only after the guard drops. `ratatui::init()` does not handle these signals either; pair it with the same thread and call `ratatui::restore()` from it.

The same thread must double as a watchdog: after a real terminal close, crossterm's Unix reader spins inside `event::poll` and never returns to the flag check, so the process burns 100% CPU until `kill -9`. Why, and the canonical guard, signal thread, and watchdog (idempotent restore shared with the panic hook, `#[cfg(unix)]`/`#[cfg(windows)]` split): `domains/framework-recipes/references/rust-python-go.md`, "Guard and event loop skeleton".

**Prevention.** Test panic/exception paths. Never scatter enter/leave calls across unrelated modules.

## Mouse mode stuck on

**Symptom.** Mouse clicks insert escape sequences, select text poorly, or are swallowed by the terminal after the app exits.

**Root cause.** Mouse reporting was enabled (`?1000`, `?1002`, `?1003`, `?1006`) and not disabled.

**Diagnostics.** Click in the shell and look for sequences like `\x1b[<...M`. Inspect cleanup for all enabled mouse modes.

**Fix pattern.** Disable every mouse mode the app enables.

```sh
printf '\033[?1000l\033[?1002l\033[?1003l\033[?1006l\033[?1015l\033[?1005l'
```

**Prevention.** Centralize terminal feature toggles and store which modes were enabled.

## Bracketed paste not restored

**Symptom.** Pasted text appears wrapped in odd markers such as `^[[200~` and `^[[201~`.

**Root cause.** Bracketed paste was enabled with `CSI ? 2004 h` and not disabled.

**Diagnostics.** Paste into the shell after app exit. Look for paste markers. Capture final output for missing `CSI ? 2004 l`.

**Fix pattern.** Always send `\x1b[?2004l` during cleanup.

**Prevention.** Enable bracketed paste only when an input widget benefits from it, and test exit cleanup.

## Focus event mode stuck

**Symptom.** Switching terminal tabs or focus sends visible escape sequences or triggers unexpected input.

**Root cause.** Focus reporting (`CSI ? 1004 h`) remains enabled.

**Diagnostics.** Focus/unfocus the terminal after exit and watch for `CSI I` / `CSI O` behavior.

**Fix pattern.** Send `\x1b[?1004l` on cleanup.

**Prevention.** Treat focus reporting as optional progressive enhancement, not default startup behavior.

## Waiting for input that never comes

**Symptom.** The UI says "press any key" or waits after startup, but input does nothing. Sometimes Enter works while arrow keys do not, or arrow keys work while line input does not.

**Root cause.** Code switched stdin to raw mode but waits for cooked line input, or left cooked mode while expecting raw key bytes. Framework input managers can also conflict with direct stdin readers.

**Diagnostics.** Inspect whether `readline`, curses, prompt_toolkit, Ink, Blessed, Bubble Tea, or another framework already owns input. Log raw byte events to a file.

**Fix pattern.** Pick one input abstraction. For raw mode, parse bytes/events. For line mode, do not enable raw mode.

**Prevention.** Document ownership of stdin and prohibit direct stdin access outside the input module.

## TTY detection failure

**Symptom.** The TUI hangs in CI or when input/output is piped, or refuses to run inside an environment that actually has a usable TTY.

**Root cause.** Code assumes `stdin`/`stdout` are TTYs when they are not, or uses the wrong stream for capability checks.

**Diagnostics.** Print or log `stdin.isTTY`, `stdout.isTTY`, `TERM`, `CI`, and `NO_COLOR`. Test `cmd | app`, `app > file`, and `app < file`.

**Fix pattern.** Gate TUI mode and provide plain output.

```js
function main() {
  const interactive = process.stdin.isTTY && process.stdout.isTTY && process.env.TERM !== 'dumb';
  if (!interactive) return runPlainMode();
  return runTuiMode();
}
main();
```

**Prevention.** Cover non-TTY stdin and stdout separately in CI tests.

## Node.js-specific failures

**Symptom.** `npm run tui` blanks the terminal, never handles keys, exits too soon, or leaves raw mode stuck.

**Root cause.** Common causes include `setRawMode(true)` without exit cleanup, `stdin.pause()` before raw mode without `resume()`, `readline` competing with raw listeners, or `stdin.unref()` allowing premature process exit.

**Diagnostics.** Search for `setRawMode`, `pause`, `resume`, `ref`, `unref`, `readline.createInterface`, `process.exit`, `SIGINT`, `uncaughtException`, and `unhandledRejection`. Add file logs rather than `console.log`.

**Fix pattern.** One owner for stdin, cleanup before raw mode, resume stdin, render before async checks, and avoid `process.exit` until cleanup has run.

```js
async function main() {
  const session = createTerminalSession();
  try {
    session.enter();       // installs cleanup, raw, alt, stdin.resume()
    session.renderLoading();
    await session.flush();
    await startApp();
  } finally {
    session.leave();
  }
}
```

**Prevention.** Add a node-pty startup test that expects a nonblank frame and accepts `q` within one second.

## Python-specific failures

**Symptom.** curses apps leave the terminal broken after exceptions, fail to repaint, or Textual apps hang when mixed with custom asyncio loops.

**Root cause.** `curses.initscr()` without `curses.endwin()` in exception paths, `curses.raw()` without `curses.noraw()`, bypassing `curses.wrapper`, blocking work in the event loop, or not using Textual's run API correctly.

**Diagnostics.** Search for direct `initscr`, `raw`, `cbreak`, `noecho`, and custom event-loop code. Force an exception after initialization.

**Fix pattern.** Use safe wrappers and workers.

```python
import curses
import os
import signal
import sys

def app(stdscr):
    curses.curs_set(0)
    stdscr.addstr(0, 0, "Loading... (q quits)")
    stdscr.refresh()
    stdscr.timeout(100)  # getch returns -1 every 100 ms; do nonblocking work between polls
    tty_in = os.isatty(0)
    while True:
        ch = stdscr.getch()
        if ch == ord("q"):
            return
        if ch == -1 and tty_in and not os.isatty(0):
            # A hung-up tty returns -1 at once, not after 100 ms. If SIGHUP never arrives
            # (the session leader ignores or does not forward it), treat it as one (Unix only).
            on_signal(signal.SIGHUP, None)

def exit_with(code):
    # Mirrors the canonical exit_with in rust-python-go.md (prompt_toolkit section).
    # Skip CPython's final flush if the terminal is gone (EIO), so a hangup still exits 129.
    try:
        sys.stdout.flush()
    except OSError:
        os._exit(code)
    sys.exit(code)

caught = 0

def on_signal(signum, frame):
    global caught
    caught = signum
    sys.exit(128 + signum)

# wrapper restores on return and exceptions, not on SIGHUP, SIGQUIT (Ctrl-\ in cbreak mode; exits 131),
# or SIGTERM without ncurses' own handler.
# Turn those signals into SystemExit so wrapper's finally runs endwin().
for name in ("SIGTERM", "SIGHUP", "SIGQUIT"):  # SIGHUP/SIGQUIT do not exist on Windows (windows-curses)
    if hasattr(signal, name):
        signal.signal(getattr(signal, name), on_signal)

try:
    curses.wrapper(app)
except KeyboardInterrupt:  # Ctrl-C: wrapper has already restored the terminal
    exit_with(130)
except SystemExit as e:
    exit_with(e.code if isinstance(e.code, int) else 1)
except curses.error:
    # After a real terminal close, wrapper's own cleanup (nocbreak) fails with ERR and
    # replaces the SystemExit; the terminal is gone, so exit with the signal status.
    if caught:
        os._exit(128 + caught)
    raise
exit_with(0)
```

The `exit_with` guard and why Python otherwise exits 120 after a real terminal close: see the prompt_toolkit section of `domains/framework-recipes/references/rust-python-go.md`.

**Prevention.** Keep blocking work out of Textual message handlers; use workers and `call_from_thread`/message posting as appropriate.

## Rust-specific failures

**Symptom.** Ratatui/Crossterm app leaves raw mode or alternate screen on panic, or nothing draws after terminal setup.

**Root cause.** Terminal guard is dropped too early, panic occurs before cleanup, stdout is not flushed, or backend/session ownership is split.

**Diagnostics.** Search for `enable_raw_mode`, `EnterAlternateScreen`, `LeaveAlternateScreen`, `disable_raw_mode`, `Drop`, and `panic::set_hook`. Force a panic after entry.

**Fix pattern.** Restore the terminal inside the panic hook, before the default hook prints. Do not rely on `catch_unwind` alone: the default hook runs at the panic site, so it prints the message into the alternate screen. `restore_terminal` then leaves the alternate screen and wipes it, and `resume_unwind` does not re-run the hook. The panic message is lost.

```rust
// Ratatui 0.28.1+: init() installs a hook that restores before printing.
fn main() -> std::io::Result<()> {
    let mut terminal = ratatui::init();
    let result = run(&mut terminal); // run(&mut DefaultTerminal) -> std::io::Result<()>
    ratatui::restore();
    result
}
```

Manual equivalent, for code that does not use `ratatui::init()`:

```rust
// Wrap the default hook once at startup.
let default_hook = std::panic::take_hook();
std::panic::set_hook(Box::new(move |info| {
    let _ = restore_terminal(); // leave alt screen, show cursor, disable raw mode
    default_hook(info);         // message now prints to the normal screen
}));
```

Full skeleton with RAII guard, mouse/paste modes, and teardown order: `domains/framework-recipes/references/rust-python-go.md`.

**Prevention.** Integration-test cleanup after a controlled panic in a PTY.

## Go-specific failures

**Symptom.** Bubble Tea freezes during an external command or tcell apps do not restore the screen after panic.

**Root cause.** Blocking commands run in the update loop, an external command runs directly instead of through `tea.ExecProcess` (which releases and restores the terminal), goroutines deadlock on channels, or `screen.Fini()` is not deferred/recovered.

**Diagnostics.** Capture goroutine dumps. Inspect Bubble Tea commands and channel sends. Force panic after `screen.Init()`.

**Fix pattern.** Use commands/goroutines that return messages, and defer cleanup.

```go
// Signals bypass deferred cleanup: turn SIGINT/SIGTERM/SIGHUP/SIGQUIT into an event so the loop returns and Fini runs.
// Go's default SIGQUIT action dumps goroutines and exits 2 with the tty still raw, so catch it too.
// Register before Init so a signal during startup is queued, not fatal; post it once the screen exists.
sigs := make(chan os.Signal, 1)
signal.Notify(sigs, syscall.SIGINT, syscall.SIGTERM, syscall.SIGHUP, syscall.SIGQUIT)
defer signal.Stop(sigs)

screen, err := tcell.NewScreen()
if err != nil {
	return err
}
if err := screen.Init(); err != nil {
	return err
}
defer func() {
	r := recover()
	screen.Fini()
	if r != nil {
		panic(r)
	}
}()

go func() {
	screen.PostEvent(tcell.NewEventInterrupt(<-sigs))
}()

// A closed terminal sends no signal when the session leader ignores or does not forward SIGHUP,
// and PollEvent then never returns. Poll once a second whether stdin/stdout are still terminals.
inTTY, outTTY := term.IsTerminal(int(os.Stdin.Fd())), term.IsTerminal(int(os.Stdout.Fd()))
go func() {
	for {
		time.Sleep(time.Second)
		if (inTTY && !term.IsTerminal(int(os.Stdin.Fd()))) || (outTTY && !term.IsTerminal(int(os.Stdout.Fd()))) {
			screen.PostEvent(tcell.NewEventInterrupt(syscall.SIGHUP))
			return
		}
	}
}()

for {
	switch ev := screen.PollEvent().(type) {
	case *tcell.EventInterrupt:
		if sig, ok := ev.Data().(syscall.Signal); ok {
			return signalError{sig} // caller exits 128+sig after Fini has run
		}
		return nil
	case *tcell.EventKey:
		if ev.Key() == tcell.KeyCtrlC {
			return signalError{syscall.SIGINT} // typed Ctrl-C exits 130, like an external SIGINT
		}
		if ev.Key() == tcell.KeyRune && ev.Rune() == 'q' {
			return nil
		}
	case nil:
		return nil // screen finalized
	}
}
```

The snippet assumes imports `os`, `os/signal`, `syscall`, `time`, `golang.org/x/term` (already a tcell dependency), and `github.com/gdamore/tcell/v2`, inside a `func run() error`. tcell opens `/dev/tty` itself, so with both stdin and stdout redirected the poll cannot see the hangup. `signalError` carries the signal out so `main` (which also imports `errors` and `fmt`) can exit with the conventional 128+signal code:

```go
type signalError struct{ sig syscall.Signal }

func (e signalError) Error() string { return e.sig.String() }

func main() {
	if err := run(); err != nil {
		var se signalError
		if errors.As(err, &se) {
			os.Exit(128 + int(se.sig))
		}
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
```

**Prevention.** Keep Bubble Tea `Update` fast and return commands for long work.

## SSH, tmux, and screen

**Symptom.** Works locally but hangs, misreads keys, ignores mouse, or fails to resize over SSH/tmux/screen/Zellij.

**Root cause.** Different `TERM`, terminfo, mouse support, focus support, truecolor behavior, alternate-screen policy, escape timing, or resize propagation.

**Diagnostics.** Log `$TERM`, `$TMUX`, `$STY`, `$ZELLIJ`, `$SSH_TTY`, `tput colors`, `stty size`, and resize events. Test outside the multiplexer and inside it.

**Fix pattern.** Feature-detect and gracefully degrade. Treat mouse/focus/truecolor as optional. Handle SIGWINCH/resize events.

**Prevention.** Include tmux and SSH scenarios in compatibility tests for any production TUI.

## Windows-specific failures

**Symptom.** ANSI sequences print literally, input differs, output appears delayed, or tests pass on Unix but hang under Windows Terminal/ConPTY.

**Root cause.** Virtual terminal processing is disabled in classic console hosts, ConPTY buffers output differently, Ctrl-C handling differs, or Unix PTY assumptions leak into Windows code.

**Diagnostics.** Identify host: Windows Terminal, VS Code terminal, classic conhost, Git Bash, WSL, or ConPTY test harness. Check whether the library enables VT mode. Test through the claimed support path.

**Fix pattern.** Use cross-platform libraries that enable Windows VT and abstract ConPTY where possible. Flush after frame writes and avoid relying on Unix-only signal/PTY behavior.

**Prevention.** Run Windows integration tests if Windows support is advertised, not just Unix PTY tests.
