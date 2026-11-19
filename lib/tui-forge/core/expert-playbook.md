# TUI Expert Playbook

Cross-domain primer. Read it for broad, end-to-end TUI work (new app design, full audits, production readiness reviews) that spans several domains. Each section is a short summary plus a pointer; the guides hold the detail.

## Framework Selection

Pick the abstraction first (widget framework, cell library, prompt library, or direct ANSI), then the library: Ratatui + Crossterm, Textual, Bubble Tea, Ink, Terminal.Gui, or ncurses are the usual defaults. For legacy picks (Blessed and others), see `domains/tui-fundamentals/references/framework-selection.md`. Whatever the framework, model state explicitly and let the backend diff and flush.

Deeper: `domains/tui-fundamentals/GUIDE.md` (canonical selection matrix and decision tree) and `domains/framework-recipes/GUIDE.md` (per-framework recipes, gotchas, porting).

## Terminal Standards and Escape Sequences

Restrict raw output to well-supported ECMA-48/VT100/xterm sequences, and treat bracketed paste, SGR mouse, Kitty keyboard/graphics, sixel, OSC 8, and OSC 52 as detected progressive enhancements with fallbacks. On Windows, enable virtual terminal processing and account for ConPTY.

Deeper: `domains/terminal-standards/GUIDE.md` (protocols, capability negotiation) and `domains/platform-compatibility/GUIDE.md` (emulator/OS/multiplexer differences).

## Rendering and Performance

Separate model, update, and view; diff frames, batch writes, and flush once per frame. Treat resize as an event, define a minimum size with a small-screen message, and keep blocking work off the UI thread.

Deeper: `domains/rendering-layout-performance/GUIDE.md`.

## Layout and Visual Design

Design around cells, keep primary actions and status visible, and use semantic color roles that degrade to 16-color, no-color, and ASCII modes. Check contrast before relying on yellow, blue, or dim text.

Deeper: `domains/tui-visual-design/GUIDE.md`.

## Input, Focus, and Interaction

Enter raw mode only on a TTY, keep exits (q, Esc, Ctrl-C) consistent, and give every interactive element a visible focus state and keyboard path. Avoid shortcuts that collide with terminal or multiplexer bindings unless configurable.

Deeper: `domains/input-handling/GUIDE.md`.

## Unicode and Text Correctness

Measure display cells with a maintained width library, and move, delete, and wrap by grapheme cluster. Keep BiDi text in logical order and test CJK, combining marks, emoji sequences, and pasted Unicode.

Deeper: `domains/unicode-color-accessibility/GUIDE.md`.

## Accessibility and Inclusive Operation

Keep everything keyboard-operable, never encode meaning by color alone, and ship a plain/`--json` mode for screen readers and scripts. Honor `NO_COLOR`, `TERM=dumb`, and non-TTY streams.

Deeper: `domains/unicode-color-accessibility/GUIDE.md`.

## Security, State, Configuration, and Distribution

Never write untrusted text (filenames, logs, API data, pasted content) to the terminal raw: strip or escape C0/C1 controls, CSI, OSC, and DCS first. Treat OSC 52 clipboard writes and hyperlinks from data as untrusted. Keep state in an explicit model updated by messages; run long work off the UI thread and post results back. Store config, state, and cache in XDG paths on Unix and platform-appropriate paths on Windows; make keybindings and themes configurable, and honor telemetry opt-outs such as `DO_NOT_TRACK`. Ship static binaries or standard package channels, and document a `--no-tui`/plain path.

Deeper: `domains/widgets-state-security-distribution/GUIDE.md`.

## Failure Diagnosis

Treat freezes, blank screens, dead input, and a broken terminal after exit as lifecycle failures first: check for a missed mode restore, blocked stdin, paused streams, a UI-thread deadlock, or output written outside the renderer. Recover a broken shell with the canonical recovery line under "Recovery commands for users" in `domains/tui-troubleshooting/GUIDE.md` (`reset` is the heavier fallback).

Deeper: `domains/tui-troubleshooting/GUIDE.md`.

## Testing and Validation

Layer tests from pure state updates through fixed-size snapshots and virtual-terminal assertions to PTY integration tests. Mask nondeterminism and test real ConPTY when claiming Windows support.

Deeper: `domains/tui-testing-debugging/GUIDE.md`.

## Audit Map

For a full audit or production readiness review, check each area against its guide:

| Audit area | Guide |
|--|--|
| Product shape, CLI/TUI split, architecture | `domains/tui-fundamentals/GUIDE.md` |
| Framework usage and idioms | `domains/framework-recipes/GUIDE.md` |
| Escape sequences and capability detection | `domains/terminal-standards/GUIDE.md` |
| Render loop, resize, alternate screen cleanup | `domains/rendering-layout-performance/GUIDE.md` |
| Visual hierarchy, color, polish | `domains/tui-visual-design/GUIDE.md` |
| Keys, focus, mouse, paste | `domains/input-handling/GUIDE.md` |
| Unicode width, color fallback, accessibility | `domains/unicode-color-accessibility/GUIDE.md` |
| Test coverage and harness | `domains/tui-testing-debugging/GUIDE.md` |
| Lifecycle robustness: freeze, hang, terminal restore | `domains/tui-troubleshooting/GUIDE.md` |
| Emulators, OS, tmux/screen/Zellij, SSH | `domains/platform-compatibility/GUIDE.md` |
| Widgets, state, config, security, packaging | `domains/widgets-state-security-distribution/GUIDE.md` |

## Production Checklist

Before shipping or updating a TUI, confirm:

- Terminal state is restored after normal quit, errors/exceptions, panics, failed partial initialization, Ctrl-C, Ctrl-\ / SIGQUIT, SIGTERM, SIGHUP/terminal close (including stdin EOF and read/write EIO), return from a `$EDITOR`/child handoff, and test failures.
- Non-interactive alternatives exist for prompts and destructive confirmations.
- Resize, tiny terminals, SSH latency, tmux/screen, and Windows Terminal are tested.
- Color behavior honors TTY detection and environment preferences.
- Text measurement handles ANSI, CJK, emoji, combining marks, and grapheme clusters.
- Untrusted text is sanitized before terminal output (no raw CSI/OSC/DCS from data, filenames, logs, or paste).
- Long work is asynchronous and cancellable.
- Logs do not corrupt the screen; debug output goes to a file or alternate sink.
- Exit codes are documented and meaningful.
- Config paths, packaging channels, and the plain/`--no-tui` path are documented.
- Help text includes examples, keybindings, and recovery instructions.
- Accessibility fallback is documented and discoverable.

## Sources

Sources: ECMA-48, VT100/VT220, xterm ctlseqs, terminfo/ncurses, Microsoft VT/ConPTY docs, Kitty/iTerm2 protocols, NO_COLOR/CLICOLOR, XDG, WCAG 2.2, Unicode UAX 9/11/14/29, and official docs for each framework named above. Fetch current official docs when exact APIs matter.
