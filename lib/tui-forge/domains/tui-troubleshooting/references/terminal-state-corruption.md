# Terminal State Corruption

Terminal state corruption is any failure where the process may still run, but the terminal display or interaction contract is damaged: garbled escape sequences, wrong colors, hidden cursor, incorrect cursor position, stuck scroll region, partial frames, mouse/paste/focus modes leaking, or debug output interleaving with the alternate screen.

## Baseline recovery sequence

For Unix-like terminals: run steps 1–3 of "Recovery commands for users" in `domains/tui-troubleshooting/GUIDE.md` (`stty sane; printf '\033[?2004l'`, then the mode-reset line, then Ctrl-L or `printf '\033[H\033[2J'`; plain `clear` and `tput clear` also wipe scrollback).

## Recovery line explained

The mode reset line in `domains/tui-troubleshooting/GUIDE.md` (section "Recovery commands for users") follows teardown order: ends any open synchronized-output frame (`?2026l`; a crash between begin and end can leave the screen frozen until the terminal times out), empties the Kitty keyboard stack (`CSI < 99 u`; a pop that empties the stack resets all flags), resets xterm modifyOtherKeys (`CSI > 4 m`), disables focus reporting (`?1004`), bracketed paste (`?2004`), and all mouse modes and encodings (`?1016`, `?1015`, `?1006`, `?1005`, `?1003`, `?1002`, `?1001`, `?1000`, `?9`), disables grapheme cluster mode (`?2027`; DEC private mode 2027), re-enables autowrap (`?7h`; some renderers turn it off per frame), resets cursor keys and keypad to normal mode (`?1l`, `ESC >`), selects ASCII into G0 and G1 and shifts G0 in (`ESC ( B`, `ESC ) B`, SI `0x0f`; a crash during ncurses line drawing otherwise leaves `lqqqk` letters instead of box lines), restores the default cursor shape (`CSI 0 SP q`; a console without DECSCUSR, such as the Linux VT, may ignore it or show a stray `q`, which is harmless), resets SGR (`CSI 0 m`) and the scroll region (`CSI r`), turns off insert mode (`CSI 4 l`), shows the cursor, leaves the alternate screen, empties the main screen's Kitty stack too (the main and alternate screens keep separate stacks), briefly re-enters and leaves the alternate screen to empty its stack as well (`?1049h`, `CSI < 99 u`, `?1049l`; kitty clears that stack only on a reset (RIS `ESC c` or DECSTR `CSI ! p`), not on a screen switch, so flags an app left there reach the next full-screen program; entering wipes only the stale alternate screen, and leaving returns the main screen's text and cursor unchanged; a terminal without mode 1049 ignores it and repeats a harmless pop), then turns off origin mode (`?6l`) and repeats the scroll region, SGR, and G0/G1/SI reset, and ends with a newline. The repeat matters: leaving the alternate screen restores the cursor state saved on entry (DECRC), which can re-apply a dirty SGR, character set, or origin mode, and some terminals keep a separate scroll region per screen.

## Incomplete escape sequences from interrupted writes

**Symptom.** Literal fragments like `^[`, `[38;2`, `?1049h`, or color codes appear on screen. The cursor may jump unexpectedly after the next write.

**Root cause.** The process writes an escape sequence in pieces and is interrupted, crashes, or another writer interleaves bytes between the pieces. Terminals parse byte streams, not logical write calls.

**Diagnostics.** Capture raw output bytes with a PTY recorder such as `script`, or headlessly with the tmux capture recipe in `domains/tui-testing-debugging/GUIDE.md` ("Observe without a human terminal"). Look for partial CSI/OSC/DCS sequences or interleaving between sequence bytes.

**Fix pattern.** Compose complete frames and control sequences into a buffer and flush once.

```ts
const frame = [];
frame.push('\x1b[?25l');
frame.push(renderCells(cells));
frame.push('\x1b[?25h');
process.stdout.write(frame.join(''));
```

**Prevention.** Use a renderer/backend that batches writes. Avoid writing escape sequences from signal handlers or multiple modules.

## Interleaved output from multiple threads or tasks

**Symptom.** Status logs appear inside bordered panels, frames contain half of two different renders, or escape sequences print literally.

**Root cause.** Multiple threads, goroutines, async tasks, subprocesses, or logging frameworks write to stdout/stderr while the TUI owns the screen.

**Diagnostics.** Redirect logs to a file and see if the corruption disappears. Search for `console.log`, `print`, `println!`, `fmt.Println`, `log`, `stderr`, child process inherited stdio, and progress libraries.

**Fix pattern.** Make the UI renderer the only writer to the controlled terminal. Route diagnostics to a file or in-app log panel.

```js
// Per-user path (not a shared temp name): another user cannot pre-create or read it.
// A failed log must never crash the UI: any setup error leaves debug() a no-op.
let debug = (_message) => {};
try {
  const dir = path.join(process.env.XDG_STATE_HOME || path.join(os.homedir(), '.local', 'state'), 'app');
  fs.mkdirSync(dir, {recursive: true, mode: 0o700});  // throws on EACCES, EROFS, ENOTDIR
  const log = fs.createWriteStream(path.join(dir, 'tui.log'), {flags: 'a', mode: 0o600});
  log.on('error', () => { debug = () => {}; });      // open/write errors arrive async
  debug = (message) => { log.write(`${new Date().toISOString()} ${message}\n`); };
} catch {}
```

**Prevention.** During TUI mode, configure logging sinks before entering alternate screen. Spawn child processes with `stdio: 'pipe'` or suspend/restore the TUI around interactive children.

## Scroll region not reset

**Symptom.** Shell output after exit scrolls only within part of the terminal, or the prompt appears trapped in a pane-like region.

**Root cause.** The app used DECSTBM (`CSI top ; bottom r`) to set a scroll region and did not reset it with `CSI r`.

**Diagnostics.** Inspect raw output for `r` scroll-region sequences. After exit, run commands with many lines and see whether only a subsection scrolls.

**Fix pattern.** Include `\x1b[r` in cleanup and before full-screen layout changes that assume the whole screen.

**Prevention.** Prefer framework viewport widgets that own scroll regions and reset them. Add cleanup assertions in virtual terminal tests.

## Cursor position not restored

**Symptom.** The prompt appears in the middle of the screen, later output overwrites UI remnants, or cursor is hidden after exit.

**Root cause.** Cursor hide/show, save/restore, alternate-screen, or manual cursor movement sequences are unbalanced.

**Diagnostics.** Look for `?25l` without `?25h`, save without restore, or crash paths after cursor hide.

**Fix pattern.** Cleanup must always show the cursor and place it at a safe position, usually after leaving alternate screen.

```sh
printf '\033[?25h\033[0m\n'
```

**Prevention.** Hide cursor only during drawing, or manage it via a terminal session guard.

## Color attributes not reset

**Symptom.** The shell prompt or later command output remains red, dim, bold, inverse, underlined, or has a background color.

**Root cause.** The app set SGR attributes and did not send `SGR 0` (`CSI 0 m`) on frame boundaries and cleanup.

**Diagnostics.** Inspect final output bytes for missing `\x1b[0m`. Reproduce with a forced exception after rendering colored text.

**Fix pattern.** End every frame and cleanup path with reset.

```rust
use std::io::{self, Write};

let mut stdout = io::stdout();
// In a Ratatui app, use ratatui::crossterm::... so only one crossterm version links.
crossterm::queue!(stdout, crossterm::style::ResetColor, crossterm::style::SetAttribute(crossterm::style::Attribute::Reset))?;
stdout.flush()?; // queue! only buffers; nothing reaches the terminal until flush (or use execute!)
```

**Prevention.** Use style scopes or cell renderers that emit resets when attributes change and at frame end.

## Letters instead of box lines

**Symptom.** After the app exits or crashes, shell output shows letters such as `lqqqk`, `x`, and `mqqqj` where text should be, or box borders render as those letters inside the app.

**Root cause.** The app switched a character set to DEC Special Graphics (`ESC ( 0`, or SO with G1 designated) for line drawing, which ncurses does for ACS characters on some terminals, and exited before switching back. Later ASCII text is then mapped through the line-drawing table.

**Diagnostics.** Search captured output for `\x1b(0` or `\x0e` (SO) without a matching `\x1b(B` or `\x0f` (SI) after it.

**Fix pattern.** Send `ESC ( B` and SI (`\033(B\017`) on every cleanup path. The canonical recovery line in `domains/tui-troubleshooting/GUIDE.md` (section "Recovery commands for users") includes both, and `reset` also fixes it. Prefer UTF-8 box-drawing characters over ACS where the terminal supports UTF-8.

**Prevention.** Let the library's `endwin()` or teardown run on every exit path, including signals.

## Unicode width mismatch causing misalignment

**Symptom.** Borders break, columns drift, cursor lands inside characters, emoji overwrite neighboring cells, or CJK text shifts layout.

**Root cause.** Code measures bytes, code points, or grapheme count instead of display cell width. Terminals also differ on emoji and ambiguous East Asian width.

**Diagnostics.** Test strings with combining marks, emoji ZWJ sequences, CJK, and ambiguous-width characters. Compare expected cell grid to actual terminal output.

**Fix pattern.** Use maintained width/grapheme libraries and truncate by cell width, not string length. For per-language libraries, terminal disagreement on emoji widths, and grapheme cluster mode (DEC 2027), see `domains/unicode-color-accessibility/references/text-measurement.md`.

```python
# Pseudocode: iterate grapheme clusters and accumulate wcwidth cells.
cells = 0
out = []
for cluster in graphemes(text):
    w = display_width(cluster)
    if cells + w > limit:
        break
    out.append(cluster)
    cells += w
```

**Prevention.** Snapshot with fixed Unicode policy. Provide ASCII mode for limited fonts and remote environments.

## Race conditions between resize and render

**Symptom.** Partial frames, panics from out-of-bounds coordinates, stale panels after resizing, or a blank screen until another keypress.

**Root cause.** Resize updates terminal dimensions while a render is using old dimensions, or SIGWINCH/resize events are handled outside the UI loop.

**Diagnostics.** Log terminal size at event receipt, layout calculation, and render flush. Stress-test rapid resizing in a PTY or manually.

**Fix pattern.** Treat resize as a normal UI event. Coalesce resize/render and recompute layout from current dimensions.

```go
case tea.WindowSizeMsg:
	m.width = msg.Width
	m.height = msg.Height
	return m, nil
```

**Prevention.** Do not cache absolute layout coordinates across frames unless they are invalidated by resize.

## Background process writing to the same terminal

**Symptom.** A compiler, test runner, shell command, or subprocess output appears through the UI and corrupts frames.

**Root cause.** Child process inherits stdout/stderr while the TUI remains active.

**Diagnostics.** Inspect process spawn options. Temporarily redirect child stdio and compare behavior.

**Fix pattern.** Pipe child output into the app model, or suspend the TUI before handing control to an interactive child.

```js
const child = spawn(cmd, args, {stdio: ['ignore', 'pipe', 'pipe']});
// setEncoding decodes UTF-8 across chunk boundaries; per-chunk toString() splits multi-byte characters.
child.stdout.setEncoding('utf8');
child.stdout.on('data', s => appendLog(sanitize(s)));
// Drain stderr too: an unread pipe fills its buffer (about 64 KiB) and blocks the child forever.
child.stderr.setEncoding('utf8');
child.stderr.on('data', s => appendLog(sanitize(s)));
```

Child output is untrusted: `sanitize` strips control and escape sequences per the policy in `domains/widgets-state-security-distribution/references/state-config-distribution-security.md`.

**Prevention.** Make child-process stdio policy explicit in the TUI architecture.

## Debug print statements corrupting alternate screen

**Symptom.** `console.log`/`print` debugging appears at random positions, breaks borders, or forces scrolling inside the alternate screen.

**Root cause.** Line-oriented debugging writes to the same terminal surface as the full-screen renderer.

**Diagnostics.** Grep for print/log statements and disable them. Confirm corruption disappears.

**Fix pattern.** Use file logging, structured in-app logs, or a debug overlay rendered by the UI.

**Prevention.** Provide a debug logger from day one and forbid direct stdout/stderr writes during TUI mode.

## Partial renders and flicker

**Triage.** Frames visibly draw top-to-bottom, borders flicker, or stale text remains after shorter text. The terminal itself is not corrupted: this is a render-loop defect, not a lifecycle failure. Confirm by capturing raw output and checking for multiple flushes per frame or missing clears/padding. Fixes (offscreen buffer, diffing, padding, single flush, synchronized output) live in `domains/rendering-layout-performance/GUIDE.md`.
