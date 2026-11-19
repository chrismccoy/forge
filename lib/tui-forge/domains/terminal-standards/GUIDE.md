# Terminal Standards, Escape Sequences, and Capability Negotiation

Use this guide when code emits or parses terminal control sequences, depends on terminal features, or must behave across emulators, multiplexers, and Windows console hosts.

## Standards hierarchy

Think in layers:

1. **Baseline:** printable text, carriage return, newline, backspace, tab.
2. **ECMA-48 / ANSI / ISO 6429:** CSI controls and SGR attributes.
3. **DEC VT lineage:** cursor movement, alternate keypad modes, device status patterns, private modes.
4. **xterm conventions:** alternate screen, mouse modes, focus events, bracketed paste, OSC extensions.
5. **Modern emulator extensions:** Kitty keyboard/graphics, iTerm2 images, sixel, OSC 8 hyperlinks, OSC 52 clipboard, theme queries.
6. **Platform host behavior:** Windows virtual terminal processing, ConPTY, tmux/screen filtering, SSH latency.

Each layer further down this stack demands more detection, fallbacks, and cleanup.

## Safer defaults

- Prefer framework abstractions and terminfo/capability libraries over hard-coded control sequences.
- Reset styles deliberately; do not rely on terminal defaults after complex SGR output.
- Treat unknown responses, missing responses, and blocked queries as normal.
- Never require clipboard, images, focus events, or extended keyboard protocols for core functionality.
- When enabling a mode, register a cleanup path before continuing.

## Common sequences and caveats

| Feature | Typical sequence | Caveat |
|--|--|--|
| Alternate screen | `CSI ? 1049 h` / `CSI ? 1049 l` | May be disabled or mediated by multiplexers. Cleanup is mandatory. |
| SGR reset | `CSI 0 m` | Reset before exit and after errors. |
| Truecolor | `CSI 38;2;R;G;B m` / `CSI 48;2;R;G;B m` | Downsample to 256/16/no-color when needed. |
| Bracketed paste | `CSI ? 2004 h` / `CSI ? 2004 l` | Parse paste boundaries; disable on exit. |
| SGR mouse | `CSI ? 1006 h` plus tracking modes | Requires parser and coordinate validation. Input report formats: `domains/input-handling/references/key-mouse-protocols.md`. |
| Focus events | `CSI ? 1004 h` | Treat as advisory; may not arrive. |
| OSC 8 links | `OSC 8 ; ; URI ST` | Provide visible URL fallback. |
| OSC 52 clipboard | `OSC 52 ; c ; <base64> ST` | Often blocked by terminals, multiplexers, SSH policies, or security settings. |
| DCS passthrough | `DCS ... ST` | Used by multiplexers and some protocols; highly environment-dependent. |
| Terminal title | `OSC 0/2` | Avoid changing titles unexpectedly; to restore, push with `CSI 22;0 t` before setting and pop with `CSI 23;0 t` on exit (XTWINOPS; support varies). |
| Palette queries/changes | OSC 4/10/11 variants | Useful but fragmented; restore changes and time out queries. |

See `domains/terminal-standards/references/escape-sequence-field-guide.md` for detailed tables.

## Capability negotiation checklist

- Is stdout a TTY? If not, avoid cursor controls and interactive modes by default.
- Is `TERM` meaningful? Handle `dumb`, empty, and unknown values.
- Is the app inside tmux/screen? Assume some protocols are filtered or need passthrough.
- Is Windows VT processing enabled for classic console APIs?
- Does the library expose color level detection? Prefer it over ad hoc environment parsing.
- Are user overrides available: `--color=auto|always|never`, `--truecolor`, `--plain`, `--no-tui`, `--ascii`, `--no-mouse`?
- Are query timeouts bounded so the app does not hang waiting for terminal replies?

Combine weak signals; no single variable is authoritative. Sources: TTY checks on stdin/stdout/stderr; `TERM`, `COLORTERM`, `TERM_PROGRAM`, `WT_SESSION`, `TMUX`, `STY`, `SSH_TTY`; library feature detection; terminfo; bounded queries.

Override precedence, highest first (first match wins):

1. Explicit CLI flags: `--color=auto|always|never`, `--plain`, `--tui`, `--no-tui`, `--ascii`. `--color=auto` (the default) falls through to steps 2–6. `--truecolor` opts in to 24-bit color where detection fails; it sets the level only when color is enabled.
2. `NO_COLOR` (set and non-empty) turns color off.
3. Force variables (these apply even when output is not a TTY):
   - `CLICOLOR_FORCE` (set, non-empty, not `0`) forces color.
   - `FORCE_COLOR` is a separate Node-ecosystem convention (chalk/supports-color), not an alias: `0` or `false` disables color. `1`, `2`, `3` request basic, 256-color, or truecolor. Current supports-color (11, also vendored in chalk 6) treats a number as an exact level; older releases used it as a hint that detection could override. `true` or empty enables color at the detected level (at least basic).
4. `TERM=dumb` turns off color and cursor control.
5. `CLICOLOR=0` turns color off; otherwise color follows TTY detection.
6. TTY, CI, and terminal detection (non-TTY output or `CI` set to a non-empty value other than `0`/`false`, case-insensitive, means plain output), then conservative defaults.

This follows no-color.org and the bixense CLICOLOR spec: `NO_COLOR` overrides the force variables, explicit flags override both, and empty `NO_COLOR`/`CLICOLOR_FORCE` count as unset (supports-color treats an empty `FORCE_COLOR` as "force"). Some libraries let `FORCE_COLOR` win over `NO_COLOR`, and chalk/supports-color does not read `NO_COLOR` at all, so check `NO_COLOR` before configuring chalk (for example, set `chalk.level = 0`). Document the order the app uses.

On Windows, enable VT processing explicitly with `SetConsoleMode` (`ENABLE_VIRTUAL_TERMINAL_PROCESSING` on output, `ENABLE_VIRTUAL_TERMINAL_INPUT` on input), check every return value, fall back to plain output on failure, and restore the saved modes at teardown. Copy the checked C snippet from "Windows VT enable" in `domains/terminal-standards/references/escape-sequence-field-guide.md`.

Inside tmux or screen, `TERM` and feature claims describe the multiplexer, not the outer terminal. Test alternate screen, mouse, paste, clipboard, focus, and truecolor under each multiplexer version the app claims to support. On Windows, classic console hosts need virtual terminal processing enabled; ConPTY buffering and process hosting differ from Unix PTYs, which matters for tests and for embedding child TUIs.

Hosting a child PTY (a terminal pane inside the TUI) means writing a terminal emulator. Use an existing VT parser (`pyte` in Python, the `vt100` crate in Rust, `@xterm/headless` in Node, libvterm in C) instead of hand-parsing, and spawn the child with a PTY library (`portable-pty` in Rust, `ptyprocess` in Python, `node-pty` in Node, `forkpty` in C, ConPTY on Windows); Ratatui has `tui-term`, a vt100-backed widget. Feed it the child's output, draw its cell grid into the pane, re-encode input for the modes the child enabled (application cursor keys, bracketed paste, mouse, Kitty keyboard) instead of passing raw bytes through, set the PTY size on every pane resize, and answer the child's queries (DA, DSR); a child waiting on an unanswered query can hang.

## Cleanup contract

If enabling raw mode, alternate screen, mouse tracking, bracketed paste, focus events, cursor hiding, or keyboard protocols, verify cleanup on normal quit, errors/exceptions, panics, failed partial initialization, Ctrl-C, Ctrl-\ / SIGQUIT, SIGTERM, SIGHUP/terminal close (including stdin EOF and read/write EIO), return from a `$EDITOR`/child handoff, and test failures.

## Reference files

- `domains/terminal-standards/references/escape-sequence-field-guide.md` - ANSI/VT/xterm controls, DEC modes, OSC/DCS tables, tmux passthrough, query timeouts, and the Windows VT-enable snippet. Read before emitting or parsing raw sequences.
