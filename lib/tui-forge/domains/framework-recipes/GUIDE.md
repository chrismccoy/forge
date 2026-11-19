# Framework Ecosystem Recipes

Use this guide when the user names a specific terminal UI framework or needs practical ecosystem guidance. Fetch current official docs when exact API syntax or version-specific behavior matters.

**Choosing a framework?** The canonical selection matrix is in `domains/tui-fundamentals/GUIDE.md`. The decision tree, maintenance checks, and selection gotchas are in `domains/tui-fundamentals/references/framework-selection.md`. This guide covers how to use a framework once chosen.

## Rust recipes (Ratatui + Crossterm, Cursive)

- Keep terminal setup/cleanup in one guard, and install a panic hook that restores the terminal *before* the default hook prints (or use `ratatui::init()` / `ratatui::restore()`, which do not enable mouse or bracketed paste and do not handle SIGTERM/SIGHUP; see `domains/framework-recipes/references/rust-python-go.md`).
- On Crossterm, handle only `KeyEventKind::Press`. Windows also reports Release, so unfiltered loops act on every key twice.
- Mouse and paste events arrive only after `EnableMouseCapture` / `EnableBracketedPaste`; disable both on exit.
- Raw mode disables ISIG: handle Ctrl-C as a key event.
- Render from immutable state; use constraints and layout primitives instead of absolute coordinates.

## Python recipes (Textual, Rich, prompt_toolkit, curses, Urwid, asciimatics)

- For curses, use wrapper/finally cleanup and remember coordinates are y,x.
- For Textual, inject loaders so tests can mock them, separate app state from workers, and assert final state after `app.workers.wait_for_complete()`, not transient text.
- For Rich, avoid full-screen complexity when rich scrollback output solves the problem; use `Console(record=True, width=80, color_system=None)` in tests.
- For prompt_toolkit, wrap background logging in `patch_stdout()`.
- Urwid (classic keyboard-first widgets) and asciimatics (animation, effects) are older choices: check maintenance and Python-version support first; notes in `domains/framework-recipes/references/rust-python-go.md`.

## Go recipes (Bubble Tea, Bubbles, Lip Gloss, Huh, tview, tcell, termui, gocui)

- Keep `Update` pure and nonblocking; send long work through `tea.Cmd` functions that return messages.
- Define error messages as structs (`type errMsg struct{ err error }`), not interface aliases.
- Pin the Bubble Tea major version: v1 and v2 differ in key messages, `View()` return type, and alt-screen setup.
- Do not mix direct ANSI writes with tcell screen ownership.
- Test `Update` and `View` separately before PTY tests.
- Use Huh (Charm) for forms and prompts inside or beside Bubble Tea. termui (dashboard widgets) and gocui (simple pane layouts) suit small internal tools; verify maintenance, resize, and Unicode behavior first.

## Node and TypeScript recipes (Ink, Blessed, prompt libraries)

- For short forms, prefer a prompt library (`@inquirer/prompts`, `@clack/prompts`, `prompts`, `enquirer`) over a full-screen app.
- Ink handles Ctrl-C itself by default (`exitOnCtrlC: true`). Pass `exitOnCtrlC: false` when the app must run cleanup, and handle Ctrl-C in `useInput`.
- Blessed is unmaintained; see `domains/tui-fundamentals/references/framework-selection.md`.
- Verify resize, mouse, and Windows behavior for the exact library version.
- Keep side effects out of render functions; use PTY integration tests for flows that depend on terminal behavior.

## .NET recipes (Terminal.Gui, Spectre.Console)

- Pin Terminal.Gui v1 or v2: v2 is instance-based (`Application.Create()` per current v2 docs; verify against the pinned release) and not source-compatible with v1's static `Application.Init()` / `Shutdown()`. Guarantee shutdown in `finally` or host lifetime management.
- Abstract console I/O for tests; fix `AnsiConsole.Profile.Width` for snapshots.
- Provide non-interactive command equivalents for automation.

## C/C++, Zig, and Swift recipes (ncurses, notcurses, FTXUI, libvaxis, SwiftTUI)

- Low-level frameworks demand explicit cleanup (`atexit` plus flag-only signal handlers), Unicode measurement, and capability fallback tests.
- Avoid image/graphics features as hard requirements unless the deployment terminal is controlled.

## Reference files

- `domains/framework-recipes/references/rust-python-go.md` - Read when writing or reviewing code for Ratatui/Crossterm, Cursive, Textual, Rich, prompt_toolkit, curses, Urwid, asciimatics, Bubble Tea (v1 vs v2), tview/tcell, termui, or gocui. Includes a guard + event-loop skeleton, a runnable Textual worker test, a Bubble Tea Model/Update/View skeleton, and cross-ecosystem migration and porting hints.
- `domains/framework-recipes/references/node-dotnet.md` - Read when building with Ink (component, resize, Ctrl-C cleanup, test), Blessed or prompt libraries, Terminal.Gui, or Spectre.Console.
- `domains/framework-recipes/references/low-level-and-emerging.md` - Read when using ncurses (signal-safe wrapper), notcurses, FTXUI, Zig libvaxis, SwiftTUI, or evaluating a niche toolkit; it includes the low-level ownership checklist.
