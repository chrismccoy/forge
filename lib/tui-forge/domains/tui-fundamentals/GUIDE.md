# TUI Fundamentals, Architecture, and Framework Selection

Use this guide when the task is about the shape of the terminal product: what kind of TUI to build, which abstraction to use, how to organize state, or whether a full-screen terminal UI is the right answer.

## First decision: is a TUI appropriate?

Prefer a rich TUI when users need continuous visual feedback, multi-step navigation, keyboard-driven exploration, selection among many items, or a dashboard-like control surface. Prefer a line-oriented CLI, prompts, or plain output when the flow is short, scriptable, primarily automation-focused, or likely to be used by screen readers and CI systems.

A production terminal product often ships both:

- A scriptable CLI surface for automation, accessibility, logs, and non-TTY use.
- An optional TUI for exploration, monitoring, bulk selection, or guided workflows.

## Architecture rules

1. **Separate model, update, and view.** Never let business state print directly to the terminal. Rendering consumes state; input produces events; update logic transforms state.
2. **Treat terminal size as input.** Layout must be recomputed from width and height on every resize. Never bake in one terminal size.
3. **Own terminal lifecycle in one place.** Centralize raw mode, alternate screen, mouse, focus, keyboard protocols, and cleanup.
4. **Make every action keyboard-operable.** Mouse support is an enhancement, not the primary navigation model.
5. **Design for degradation.** Define clear behavior for `TERM=dumb`, non-TTY output, missing color, Windows console differences, tmux/screen, SSH, and CI.
6. **Avoid hidden global terminal writes.** Logs, progress, and background task output must not corrupt the screen.

### Recommended layers

1. **Domain model:** application data and business rules, independent of terminal concerns.
2. **UI model:** selected row, focused control, modal state, viewport offsets, pending edits, theme, terminal size.
3. **Event decoder:** turns raw terminal/framework events into semantic app actions.
4. **Update/reducer:** transforms the UI model and schedules side effects.
5. **Renderer/view:** converts state into widgets or a cell buffer.
6. **Terminal manager:** owns raw mode, alternate screen, protocol enablement, cleanup, panic/exception hooks, and signal handling.

### Event loop

- Read input, timers, worker messages, and resize notifications through one channel/queue when possible.
- Coalesce repeated resize, mouse move, and high-frequency data updates.
- Throttle dashboards to the perceptual rate users need, not the data arrival rate.
- Never block the UI loop on network, disk, process, or API work.

### Logging while the screen is active

Never write logs to stdout/stderr while a full-screen UI owns the terminal. Instead:

- Write logs to a file and expose the path in debug help.
- Render logs inside a dedicated scrollback panel.
- Buffer logs while the alternate screen is active and flush after exit.
- Provide `--debug-log path` and `--no-tui` modes.

## Framework selection quick matrix

| Need | Strong default |
|--|--|
| Rust full-screen app with precise rendering | Ratatui + Crossterm |
| Rust form/dialog-heavy tool with built-in focus | Cursive |
| Python product-grade app with widgets, CSS, async workers | Textual |
| Python rich output, progress, tables, markdown, logs | Rich |
| Python REPL, shell, completions, complex prompt input | prompt_toolkit |
| Classic dependency-light Unix TUI | curses/ncurses |
| Go Elm-style app with composable commands | Bubble Tea + Bubbles + Lip Gloss |
| Go forms and prompts in a CLI flow | Huh |
| Go batteries-included forms/tables/tree views | tview over tcell |
| Go portable low-level cell engine | tcell |
| React-style terminal components in Node | Ink |
| Node prompts and wizards in a CLI flow | @inquirer/prompts or @clack/prompts |
| Node DOM-like full-screen widgets | Blessed (unmaintained; see `domains/tui-fundamentals/references/framework-selection.md`) |
| .NET full-screen views | Terminal.Gui (pin v1 or v2; APIs differ) |
| .NET rich CLI output and prompts | Spectre.Console |
| C/C++ classic portable TUI | ncurses |
| C++ composable components | FTXUI |
| Zig | libvaxis |

Read `domains/tui-fundamentals/references/framework-selection.md` before committing to a framework in a new project.

## Product design checklist

- Define the primary user journey in one sentence.
- Decide whether the app is full-screen, inline, prompt-based, or hybrid.
- List required environments: Windows Terminal, classic conhost, macOS Terminal, iTerm2, GNOME Terminal, Alacritty, SSH, tmux/screen, CI, and logs.
- Define minimum terminal dimensions and the small-screen fallback.
- Define exit keys, destructive confirmation rules, and recovery instructions.
- Define non-interactive equivalents for every essential action.
- Decide how help is exposed: footer hints, `?`, command palette, `--help`, docs.
- Write the distribution contract: supported OSes and terminal emulators, required terminal features and fallbacks, non-interactive usage, exit codes, keybindings, display recovery steps, and environment variables honored for color, accessibility, telemetry, config, and terminal detection.

## Failure modes

- Building a full-screen UI for a workflow better served by a scriptable CLI.
- Choosing a low-level escape-sequence approach when a framework already solves layout, input, cleanup, and testing.
- Mixing business logic with terminal writes, making tests brittle and rendering inconsistent.
- Ignoring screen-reader users, CI, pipes, and `TERM=dumb` until late.
- Assuming color, Unicode icons, Nerd Fonts, or mouse support are always available.

## Reference files

- `domains/tui-fundamentals/references/framework-selection.md` - Read before committing to or upgrading a framework: decision tree, per-ecosystem notes, when to avoid direct ANSI, maintenance checks, the pre-commit spike, and selection gotchas. For per-framework code recipes after choosing, see `domains/framework-recipes/GUIDE.md`.
