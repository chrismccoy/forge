# TUI Forge - terminal UI expertise

Complete terminal UI expertise packaged as one router procedure. This file holds the operating protocol and the routing table. Deep knowledge lives in domain guides that load only when a task needs them.

**Paths:** every path in this procedure, including paths listed inside guides (`domains/<domain>/references/...`), is relative to `${CLAUDE_PLUGIN_ROOT}/lib/tui-forge`, the folder that contains this procedure file, not to the file that mentions it.

## How to use this procedure

1. Classify the request with the routing table and tie-breaks below. Most tasks hit 1–2 domains. Broad tasks (a new app, a full audit) hit more.
2. Read each matched `domains/<domain>/GUIDE.md`. Each guide is a compact summary (about 350–1,250 words) and ends with a list of its reference files and when to read each.
3. Read a domain's `references/*.md` only when the guide points there or the task needs that depth. Do not bulk-load every reference.
4. For a new app, a full audit, or a production readiness review, read `core/expert-playbook.md` first. It gives the cross-domain picture, a "Deeper:" pointer per section, an audit map covering all 11 domains, and the production checklist.
5. When exact framework APIs or version-specific behavior matter, fetch current official docs (WebFetch/WebSearch). Guides give patterns and gotchas, not API signatures pinned to a version.
6. For a large audit across many domains, consider delegating to a general-purpose subagent told to follow this procedure (`${CLAUDE_PLUGIN_ROOT}/lib/tui-forge/SKILL.md`), so the main context keeps only the findings.

## Routing table

| User intent / signals | Read |
|--|--|
| Architecture, product shape, choosing between frameworks, full-screen vs inline vs prompt, "should this be a TUI" | `domains/tui-fundamentals/GUIDE.md` |
| Named framework: Ratatui, Crossterm, Termion, Cursive, Textual, Rich, prompt_toolkit, curses, Urwid, asciimatics, Bubble Tea, Bubbles, Lip Gloss, Huh, tview/tcell, termui, gocui, Ink, Blessed, Inquirer/Prompts, Terminal.Gui, Spectre.Console, notcurses, FTXUI, Zig libvaxis, SwiftTUI; porting or migration between frameworks | `domains/framework-recipes/GUIDE.md` |
| ANSI/VT/ECMA-48, CSI/OSC/DCS/SGR, terminfo, capability detection, OSC 8/52, Kitty/iTerm2/sixel protocols, Windows VT, hosting a child PTY or embedded terminal pane (VT parsing) | `domains/terminal-standards/GUIDE.md` |
| Render loop, layout, flicker, diffing, frame pacing, resize, alternate screen lifecycle, scrollback, performance, high CPU, slow over SSH, progress displays, dashboard performance, print/log output corrupting the screen, synchronized output (DEC 2026), inline progress bars and spinners, signal handling (SIGTERM/SIGHUP/SIGQUIT), cleanup on kill or terminal close | `domains/rendering-layout-performance/GUIDE.md` |
| Making it beautiful: hierarchy, spacing, typography, borders, palettes, charts, icons, animation, prompt/form styling, design critique | `domains/tui-visual-design/GUIDE.md` |
| Raw/cbreak mode, REPL/shell input (history, completion; add `framework-recipes` for prompt_toolkit), key parsing, Esc vs Alt, slow Esc / escape delay, Ctrl-C, shortcuts, mouse, bracketed paste, focus, forms/text input, text editing, keybinding design, Ctrl-Z suspend, handing the terminal to `$EDITOR` or a child process, IME/composition input (CJK) | `domains/input-handling/GUIDE.md` |
| wcwidth, grapheme clusters, emoji, CJK, BiDi, misaligned columns, truecolor/256 fallback, NO_COLOR, escape codes leaking into pipes, files, or CI logs, contrast, accessibility, screen readers, keyboard-only use, reduced motion, plain/ASCII modes | `domains/unicode-color-accessibility/GUIDE.md` |
| Writing tests: snapshots, golden files, PTY automation, running/observing/capturing a TUI headlessly to verify its output, virtual terminal assertions, ConPTY tests, Pilot, flaky CI, recording demo GIFs (VHS) | `domains/tui-testing-debugging/GUIDE.md` |
| Something is broken: freeze, hang, blank screen, no input, raw mode stuck, terminal left corrupted, garbled output, stdin paused | `domains/tui-troubleshooting/GUIDE.md` |
| Emulator/OS differences (iTerm2, Kitty, WezTerm, Alacritty, Windows Terminal vs conhost, WSL, containers), tmux/screen/Zellij passthrough, SSH latency, feature matrices | `domains/platform-compatibility/GUIDE.md` |
| Widgets (forms, tables, trees, command palettes), MVU/Elm state, async messages, config/XDG, escape-injection security, packaging and release | `domains/widgets-state-security-distribution/GUIDE.md` |
| New app end-to-end, full audit, production readiness review, "make me a TUI for X" | `core/expert-playbook.md`, then the domains it points to |

### Tie-breaks

- **Testing vs troubleshooting:** building a test harness, reproducing a bug in automation, or capturing bytes goes to `tui-testing-debugging`. Diagnosing the root cause of a live failure (stuck, frozen, garbled terminal) goes to `tui-troubleshooting`.
- **Drawing defects:** flicker, overlap, tearing, high CPU, and log or print output interleaving with a live UI go to `rendering-layout-performance`. Use troubleshooting only when the terminal is stuck or left broken, or escape fragments appear in the shell after exit.
- **Leaked modes after exit:** paste markers (`^[[200~`), mouse escape codes, or focus sequences showing up in the shell after the app exits go to `tui-troubleshooting` (a mode was never restored), not `input-handling`. Markers inside the running app's input go to `input-handling` (paste parsing).
- **Colors wrong only in one emulator (e.g. Terminal.app) or only inside tmux/screen/SSH:** go to `platform-compatibility` (emulator gaps in `domains/platform-compatibility/references/emulator-platform-matrix.md`; tmux truecolor recipe in `domains/platform-compatibility/references/multiplexer-remote.md`).
- **Color:** palette aesthetics go to `tui-visual-design`. Fallback, environment variables (`NO_COLOR`), and contrast go to `unicode-color-accessibility`. Byte-level SGR goes to `terminal-standards`.
- **Styling a named framework:** use `tui-visual-design` plus `domains/tui-visual-design/references/framework-styling.md`. Questions about APIs, structure, and porting go to `framework-recipes`.
- **Input-protocol bytes:** parsing keyboard, mouse, paste, or focus reports (Kitty keyboard, modifyOtherKeys, SGR mouse) goes to `input-handling` plus `domains/input-handling/references/key-mouse-protocols.md`.
- **One key vs all input:** one key not handled ("Ctrl-C doesn't quit", Esc slow, Esc slow only inside tmux) goes to `input-handling` (its tmux `escape-time` fix). The app ignoring all input or hanging goes to `tui-troubleshooting`.
- **Escape codes printed literally on Windows:** `platform-compatibility`, plus `terminal-standards` for the VT-enable snippet.
- **Works in one terminal but not another:** environment-specific differences go to `platform-compatibility`, unless the terminal is left stuck, frozen, or garbled (then `tui-troubleshooting`).
- **Protocols vs emulators:** emitting or parsing output-side protocols (OSC 8/52, graphics, titles, DEC modes, capability queries) goes to `terminal-standards` (synchronized output and the alternate-screen lifecycle: `rendering-layout-performance`); input reports follow the Input-protocol bytes rule above. "Does emulator X support Y" goes to `platform-compatibility`.
- **Tables, forms, charts:** appearance goes to `tui-visual-design`. Behavior, state, and validation go to `widgets-state-security-distribution`. Key handling inside a field (editing, cursor, paste, shortcuts) goes to `input-handling`.
- **Progress bars and spinners:** implementation (redraw, throttling, TTY gating) goes to `rendering-layout-performance`. Visual styling of bars and spinner glyphs goes to `tui-visual-design`.
- **Signals and terminal close:** writing cleanup for SIGTERM/SIGHUP/SIGQUIT or a closed terminal goes to `rendering-layout-performance` (plus `framework-recipes` for code). A terminal already left broken by a kill or close goes to `tui-troubleshooting`. Signals during an `$EDITOR`/child handoff go to `input-handling` (its "Handing the terminal to $EDITOR or a child process" section; per-framework detail in "Child-process handoff" of `domains/input-handling/references/key-mouse-protocols.md`).
- **Framework choice:** choosing between frameworks goes to `tui-fundamentals`. Add `framework-recipes` for each named candidate.

### Common combinations

- **Build a new TUI:** `core/expert-playbook.md` → tui-fundamentals → framework-recipes → rendering-layout-performance → input-handling → tui-visual-design → tui-testing-debugging, then the Production Checklist (which pulls in unicode-color-accessibility, widgets-state-security-distribution, and platform-compatibility).
- **"It froze / broke my terminal":** tui-troubleshooting first. Add input-handling or platform-compatibility as the evidence points there.
- **Polish an existing UI:** tui-visual-design + unicode-color-accessibility.
- **Accessibility audit:** unicode-color-accessibility + input-handling + tui-visual-design.
- **Slow over SSH:** rendering-layout-performance + platform-compatibility.
- **Add tests to an existing app:** tui-testing-debugging + framework-recipes (for framework test hooks).
- **Release / ship:** widgets-state-security-distribution + platform-compatibility + tui-testing-debugging.
- **Raw escape output:** terminal-standards + platform-compatibility + widgets-state-security-distribution (sanitize untrusted text).

## Operating protocol

Apply on every TUI task, whichever domain it hits:

1. **Identify the environment.** Language, framework, target terminals, OS matrix, SSH/tmux/screen expectations, and whether the UI is full-screen, inline, or prompt-oriented.
2. **Choose the right abstraction.** Widget framework for product UIs. Low-level cell library for custom renderers. Prompt library for forms. Direct ANSI only for tiny controlled surfaces.
3. **Preserve terminal state.** Enter raw mode, alternate screen, mouse, focus, bracketed paste, and extended keyboard modes only when needed. Restore every mode on normal quit, errors/exceptions, panics, failed partial initialization, Ctrl-C, Ctrl-\ / SIGQUIT, SIGTERM, SIGHUP/terminal close (including stdin EOF and read/write EIO), a `$EDITOR`/child handoff (restore before it, re-enter after), and test failures.
4. **Render deterministically.** Keep state separate from rendering. Diff frames or batch writes to avoid flicker. Handle resize, and treat terminal size as an input to layout.
5. **Treat text as Unicode.** Measure display cells, not bytes or code points. Move the cursor by grapheme cluster. Expect CJK, combining marks, emoji, ambiguous width, and terminals with different width tables.
6. **Design for accessibility.** Never encode meaning by color alone. Provide non-TUI or plain fallbacks for screen readers. Honor color preferences (`NO_COLOR`). Keep every action keyboard-operable.
7. **Test like a terminal.** Unit-test state transitions, snapshot rendered frames, drive interactive flows through a PTY, and use a virtual terminal when raw sequences need assertion. Never run a full-screen TUI in a foreground agent shell; drive it headlessly (see "Observe without a human terminal" in `domains/tui-testing-debugging/GUIDE.md`).

Before shipping or updating a TUI, run the Production Checklist in `core/expert-playbook.md`.

## Contents

- `core/expert-playbook.md`: cross-domain primer covering a framework-selection pointer, standards, rendering, layout, input, Unicode, accessibility, security/state/distribution, failure diagnosis, testing, an audit map, and the production checklist.
- `domains/<domain>/GUIDE.md`: 11 focused domain guides (see routing table).
- `domains/<domain>/references/`: 25 deep-dive reference files, listed at the end of each guide.
