# TUI Framework Selection Reference

## Selection decision tree

1. **Is the output primarily read-only?** Use rich output libraries before a full-screen app: Rich or Spectre.Console for tables, progress, markdown, trees, logs, and status panels.
2. **Is the interaction mostly questions and answers?** Use prompt libraries: prompt_toolkit, Inquirer-style libraries, Spectre prompts, or Huh (Go, from Charm) forms.
3. **Does the user need persistent navigation, panes, tables, editors, or live state?** Use a full-screen framework.
4. **Does the app need complete control over cell rendering?** Use a low-level cell engine such as tcell, Crossterm/Ratatui backend abstractions, or ncurses.
5. **Must automation be equally supported?** Ship CLI commands and machine-readable output beside the TUI.

## Ecosystem notes

### Rust

Ratatui is the default for modern Rust TUIs. It is immediate-mode: the app redraws the whole logical frame while the backend optimizes terminal writes. Pair with Crossterm for practical cross-platform support. Cursive is the retained-mode alternative: built-in views, dialogs, and focus for form-heavy tools. Avoid scattering terminal setup across modules; use one terminal manager and an event loop that can shut down cleanly.

### Python

Textual is best for substantial applications: CSS-like styling, widgets, reactive state, workers, and test tooling. Rich is best for non-full-screen presentation. prompt_toolkit is best for shells, completions, multiline input, key bindings, and terminal prompt sophistication. curses is appropriate for small dependency-light classic TUIs, but demands careful cleanup and platform testing. Urwid is a mature widget toolkit for keyboard-first classic TUIs; asciimatics suits animation and effects.

### Go

Bubble Tea is a good default when the Elm architecture fits: `Model`, `Update`, `View`, commands, and messages. Lip Gloss handles styling and layout. Bubbles provides common components. tview gives higher-level widgets over tcell. tcell is the lower-level portable cell abstraction for custom rendering. termui (dashboards) and gocui (simple panes) fit small internal tools; verify maintenance first.

### Node and TypeScript

Ink is strongest when React mental models and component tests matter. Blessed offers a DOM-like widget tree but is effectively unmaintained, and its fork neo-blessed is barely maintained either. For new work, prefer Ink; adopt a Blessed fork only after checking its recent commit and release activity. Verify resize, mouse, and Windows behavior for the exact versions targeted.

### .NET

Terminal.Gui is suited to full-screen keyboard-first apps with views and layout; v1 and v2 APIs differ, so pin the major version. Spectre.Console is suited to rich command-line output, prompts, progress, status, and command app composition.

## Avoid direct ANSI when

- The app needs robust input parsing.
- The app needs resize handling, mouse, paste, or raw mode.
- The app must behave correctly on Windows.
- The app needs deterministic tests.
- The app needs complex layout or focus.

Direct ANSI is acceptable for tiny controlled surfaces, status lines, progress indicators, or library internals that already have capability fallbacks.

## Framework maintenance checks

Before selecting or upgrading any TUI framework, record:

| Check | What to verify |
|--|--|
| Release health | Recent releases, issue response, supported language/runtime versions. |
| Terminal cleanup | Raw mode, alternate screen, cursor, mouse, paste, focus, keyboard modes restored after errors. |
| Resize | First render dimensions, live resize events, tiny terminal behavior, wrapping correctness. |
| Unicode | Grapheme clusters, double-width cells, emoji, combining marks, ambiguous width policy. |
| Input | Ctrl-C/Esc/q, paste, Alt/Esc ambiguity, mouse wheel, focus, configurable keybindings. |
| Windows | Native console, Windows Terminal, ConPTY, code page/UTF-8, CI feasibility. |
| Testing | Snapshot utilities, fake terminal, PTY examples, deterministic clocks/timers. |
| Non-TTY | Plain output, prompt fallback, JSON mode, no-color behavior. |
| Packaging | Binary size, native dependencies, terminfo files, license, supply-chain posture. |

Build a one-screen spike that exercises resize, CJK/emoji text, paste, Ctrl-C cleanup, non-TTY output, and Windows/Unix smoke tests before committing to a less-proven framework.

## Framework selection gotchas

- A framework with beautiful screenshots may still lack robust input parsing or testing support.
- A low-level library gives control but also makes the app responsible for Unicode, focus, layout, and cleanup.
- Framework maintenance, Windows support, and resize behavior matter more than demo appeal.
- Always validate the exact framework version against the target OS and terminal matrix.
- Avoid mixing ownership layers: do not let a direct ANSI progress bar write while a full-screen framework owns the terminal.
