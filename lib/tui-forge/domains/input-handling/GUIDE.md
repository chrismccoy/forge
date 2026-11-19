# TUI Input Handling, Raw Mode, Keyboard, Mouse, Paste, and Focus

Use this guide when a TUI reads keys, handles shortcuts, supports mouse, edits text, manages focus, or needs safe paste behavior.

## Input contract

- Only enter raw or cbreak mode for interactive TTY sessions.
- Provide non-interactive alternatives for scripts, pipes, and CI.
- Keep input decoding separate from application actions.
- Make every action reachable by keyboard.
- Treat mouse support as optional progressive enhancement.
- Preserve expected terminal shortcuts unless the user can rebind them.

## Raw mode rules

Raw mode disables line discipline and signals. With ISIG off, Ctrl-C arrives as byte `0x03` instead of raising SIGINT, so map it explicitly to cleanup and exit (code 130). With the Kitty keyboard protocol on, Ctrl-C and Ctrl-Z arrive as `CSI 99;5u` / `CSI 122;5u`; map both forms (details: `domains/input-handling/references/key-mouse-protocols.md`). A SIGINT handler only covers an external `kill -INT`. Centralize raw mode and restore it reliably; follow the setup/teardown order in `domains/rendering-layout-performance/GUIDE.md` (Alternate screen lifecycle). Verify Ctrl-C, Ctrl-Z/suspend where supported, EOF, resize, terminal close, and fatal exceptions. Never echo passwords or tokens.

## Keyboard protocols and ambiguity

Esc may be a key, an Alt prefix, or the start of a control sequence. Ctrl combinations collapse onto control bytes, and function keys vary. Prefer framework parsers. xterm `modifyOtherKeys` and the Kitty keyboard protocol distinguish modifiers, key releases, text vs physical keys, and Esc/Alt more reliably. Enable them only with safe negotiation, keep legacy fallbacks, and pop them during cleanup.

### Esc is slow

A lone Esc byte is indistinguishable from the start of an escape sequence, so parsers wait for a timeout before reporting Esc. Shorten the wait at every layer that buffers:

| Layer | Setting |
|--|--|
| tmux | `set -sg escape-time 10` in `~/.tmux.conf`. Default was 500 ms before tmux 3.5; 3.5 lowered it to 10 ms. |
| ncurses (C) | `ESCDELAY=25` environment variable, or `set_escdelay(25)` |
| Python curses | `curses.set_escdelay(25)` (Python 3.9+) |
| prompt_toolkit | set `app.ttimeoutlen` (seconds, flushes a lone Esc) and `app.timeoutlen` (multi-key binding wait) on the `Application` instance |
| vim inside the session | `set ttimeoutlen=10` |

The structural fix is the Kitty keyboard protocol (flag 1, disambiguate): Esc arrives as an unambiguous sequence and no timeout is needed. Ctrl combinations change too (see the raw-mode rule above). Keep the timeout path for terminals without it.

## Keybinding design

Layer shortcuts in this hierarchy:

1. Global lifecycle keys: help, quit, cancel, command palette.
2. Navigation keys: arrows, Tab, Shift-Tab, PageUp/PageDown, Home/End.
3. Focused-widget keys: editor movement, list selection, table sorting.
4. Mode-specific keys: vim-style normal/insert, search, multi-select.
5. Destructive actions: require confirmation and visible labels; require stronger confirmation for irreversible work.

Rules:

- Use `q`, Esc, or Ctrl-C for quit/cancel only when consistent with workflow risk.
- Support both mnemonic shortcuts and navigational keys where possible.
- Avoid stealing shortcuts used by shells, terminals, editors, OSes, and multiplexers unless configurable: Ctrl-C, Ctrl-D, Ctrl-Z, Ctrl-S, Ctrl-Q, Ctrl-L, Ctrl-R, Ctrl-A/E, Ctrl-U/K/W, Ctrl-Left/Right, Cmd/Ctrl-C/V, tmux prefix combinations, and terminal search keys.
- Show a footer for primary actions, context-specific help for the focused widget, and a full help overlay or command palette. Help states how to exit, how to recover from display corruption, and how to run non-interactively.

## Text input behavior

Move left/right by grapheme, support word movement, deletion, and selection where supported, insert paste as literal text, keep history in command prompts, mask secrets, and show validation errors near the field. Never measure cursor position by bytes. Key handling inside a field belongs here; form state and validation belong in `domains/widgets-state-security-distribution/GUIDE.md`.

IME (CJK) input: the terminal emulator runs the composition and draws the preedit text at the terminal's cursor; the app receives only the committed text, often several characters in one read. Park the real cursor at the field's caret (even if it is drawn hidden) so the preedit and candidate window appear in the right place, and insert committed text as a string, never as one key per byte.

## Focus model

Every interactive element needs:

- A stable identity.
- Focus eligibility rules.
- A visible focus indicator that does not rely on color alone.
- Tab/Shift-Tab or arrow navigation when appropriate.
- Clear behavior for disabled, hidden, modal, and nested controls.
- Mouse click behavior that updates focus before activating actions.

Terminal focus in/out events can pause spinners, suppress notifications, or mark stale views, but never make correctness depend on them. Terminals and multiplexers may omit or filter them.

## Paste, mouse, and resize

- **Bracketed paste:** enable it for shells, editors, search boxes, command palettes, and multiline inputs. Parse start/end markers, treat pasted text as data, never execute it automatically, and apply length limits and validation after the paste completes.
- **Mouse:** enable a tracking mode (`?1000` click, `?1002` drag, `?1003` any-motion) plus `?1006` SGR encoding. `?1006` alone only selects the encoding and produces no events. Prefer SGR; legacy encodings have coordinate limits or ambiguous reports (see `domains/input-handling/references/key-mouse-protocols.md`). Handle button, release, drag, wheel, modifiers, and coordinates. Validate coordinates against the current layout, and ignore stale events after resize. Throttle wheel, motion, drag, and hover side effects.
- **Drag, drop, touch:** drag is motion with a button held; drops may arrive as pasted paths or proprietary sequences; touchpads may map gestures to wheel events. Treat all as optional, validate dropped paths as untrusted, and keep keyboard alternatives.
- **Resize:** resize is an input event. It invalidates layout, viewport measurements, mouse hit boxes, wrapped text, table widths, and snapshot expectations. Coalesce resize storms and render a minimum-size fallback.

## Handing the terminal to $EDITOR or a child process

Never run a child inside the alternate screen or raw mode.

- **Sequence:** do a full teardown (canonical order), spawn the child with inherited stdin/stdout/stderr and wait, run setup again, re-query the size, and force a full redraw.
- **Signals:** the terminal sends Ctrl-C to the whole foreground process group (if the child keeps ISIG on, as pagers and shells do). While the child runs, ignore SIGINT and SIGQUIT in the parent (as `system(3)` does), even without a custom handler: the default action kills the parent. Use a no-op handler or a flag check, never `SIG_IGN`: an ignored disposition is inherited across exec, so the child could not be interrupted.
- **Editor command:** `$EDITOR` is a shell command. Resolve `$VISUAL`, then `$EDITOR`, then `vi`, and run the result through `sh -c 'exec <editor> "$1"' sh file` so `code --wait` works; show spawn failures.
- **Framework hooks:** prefer Bubble Tea `tea.ExecProcess(cmd, callback)`, Textual `with app.suspend():`, or prompt_toolkit `run_in_terminal(func)`, but none fully handles signals: Bubble Tea misses SIGQUIT, drops SIGTERM during exec, and has a SIGINT race, Textual misses both, and prompt_toolkit misses SIGQUIT, plus SIGINT with `PromptSession` or an app `<sigint>` binding.

Per-framework recipes (Ratatui, Bubble Tea, Textual, prompt_toolkit, Ink, curses, Cursive, tcell/tview, Terminal.Gui) and their signal fixes: "Child-process handoff" in `domains/input-handling/references/key-mouse-protocols.md`.

## Failure modes

Symptom, cause, and fix table (delayed Esc, Ctrl-C, paste, mouse, focus): "Input failure modes" in `domains/input-handling/references/key-mouse-protocols.md`.

## Reference files

- `domains/input-handling/references/key-mouse-protocols.md` - Byte-level tables for Kitty keyboard flags, modifyOtherKeys, mouse tracking and SGR report bits, bracketed paste, focus events, Ctrl-Z suspend/resume, and per-framework child-process handoff, plus the input failure-modes table. Read when writing or debugging a parser, decoding a raw byte capture, implementing suspend, or handing the terminal to `$EDITOR`.
