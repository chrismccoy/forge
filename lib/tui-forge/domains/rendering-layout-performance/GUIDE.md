# TUI Rendering, Layout, Performance, and Alternate Screen Lifecycle

Use this guide when a TUI draws incorrectly, flickers, wastes CPU, mishandles resize, corrupts scrollback, or needs a robust rendering architecture.

## Rendering principles

1. **Render from state.** Make the view a pure projection of current state and terminal dimensions.
2. **Batch writes.** Build a frame, diff or queue updates, then flush once. Avoid many small writes.
3. **Minimize terminal control churn.** Repeated style resets, cursor moves, and full clears are expensive and visible over remote links.
4. **Throttle high-frequency sources.** Coalesce logs, metrics, mouse motion, resize storms, and progress updates.
5. **Define frame ownership.** A full-screen renderer owns the screen while active; background output goes elsewhere.
6. **Use synchronized output when supported.** Wrap each frame in DEC mode 2026: BSU `CSI ? 2026 h` before the frame, ESU `CSI ? 2026 l` after it, so the terminal shows the frame atomically instead of tearing. Terminals that do not know the mode ignore it, so emitting it unconditionally is safe. Query support with DECRQM only when the app changes strategy without it (for example, keeps its own diffing); reply decoding is in the `?2026` row of `domains/terminal-standards/references/escape-sequence-field-guide.md`. Send ESU on every exit path, including errors: most terminals time out a pending update, but the screen stalls until then. Which frameworks emit it for the app: see "Synchronized output by framework" in `domains/rendering-layout-performance/references/render-loop-patterns.md`.

Inline progress bars and spinners in a normal (non-full-screen) CLI follow different rules: redraw one line with `\r`, write to stderr, and fall back to periodic log lines when not a TTY. See `domains/rendering-layout-performance/references/inline-progress.md`.

## Layout rules

- Compute layout from `width` and `height` every frame or on every resize event.
- Establish minimum usable dimensions and render a clear small-screen message below that threshold.
- Prefer constraints, flex, grid, splits, or framework layout primitives over magic coordinates.
- Keep focus, selection, viewport offset, and cursor position in UI state.
- Test narrow, wide, tall, tiny, and odd terminal sizes.

## Alternate screen lifecycle

This section is the canonical setup/teardown order for the whole procedure. Other guides point here.

Use alternate screen for full-screen apps so users return to the original scrollback after exit. Do not use it for single progress bars, command output users expect to copy, non-interactive reports, or errors that must remain in scrollback. Inline progress regions are often better for package managers, build tools, and CI-friendly logs.

**Setup order**

1. Verify stdin/stdout are TTYs or the framework has an explicit terminal handle.
2. Register cleanup (panic, exception, signal, cancellation handlers) before enabling any mode.
3. Enable raw/cbreak mode.
4. Enter alternate screen (`\033[?1049h`) if this is a full-screen TUI.
5. Hide cursor (`\033[?25l`) only if the renderer controls cursor restoration.
6. Enable mouse, bracketed paste, focus, keyboard protocols (Kitty push, modifyOtherKeys), and grapheme cluster mode (`\033[?2027h`, only after a DECRQM reply of 1 or 2) only when needed.
7. Start the event loop.

**Teardown order** (reverse of setup, plus ending synchronized output and stopping workers first)

1. End any open synchronized update (`\033[?2026l`), so a crash mid-frame does not leave the screen stalled.
2. Stop workers or detach their output from the terminal.
3. Pop keyboard protocols (`\033[<u`) and reset modifyOtherKeys (`\033[>4m`).
4. Disable focus (`\033[?1004l`), bracketed paste (`\033[?2004l`), mouse (`\033[?1006l\033[?1003l\033[?1002l\033[?1000l`), and grapheme cluster mode if enabled (`\033[?2027l`).
5. Reset SGR attributes (`\033[0m`) and the scroll region (`\033[r`).
6. Show cursor (`\033[?25h`) and restore cursor style, title, or palette if modified.
7. Leave alternate screen (`\033[?1049l`).
8. Disable raw/cbreak mode.
9. Flush final output and restore logging.

One documented exception: the Crossterm skeleton in `domains/framework-recipes/references/rust-python-go.md` disables mouse capture after leaving the alternate screen, in its own call, because on Windows `DisableMouseCapture` fails when capture was never enabled and would abort the rest of the batch.

**Signals and terminal close**

- In async-signal contexts (C, raw signal handlers), keep handlers flag-only: set a flag and let the main loop restore the terminal. Event-loop listeners (Node `process.on`, asyncio `add_signal_handler`, Go `signal.Notify`) may restore directly, and Python `signal.signal` handlers (main thread) may raise `SystemExit` so `finally` blocks restore. Then exit with 128 + the signal number (130 SIGINT, 131 SIGQUIT, 143 SIGTERM, 129 SIGHUP), or re-raise with the default action, as the ncurses wrapper does.
- For a stream that was a terminal at startup, treat end-of-file on it in raw mode, a read EIO, or a write EIO as a hangup: restore what still works and exit 129.
- Where the input reader can spin after a hangup (Crossterm), add a signal-triggered watchdog that restores and exits after a short grace period; see the Rust skeleton.
- If SIGHUP may never arrive (its session leader ignores or does not forward SIGHUP, e.g. a `disown -h` job or a `trap '' HUP` shell), poll once a second whether stdin or stdout (whichever was a terminal at startup) still is one and treat the change as a hangup; the Rust, Bubble Tea, tcell, ncurses, and Python curses samples do this.
- While a child or `$EDITOR` owns the terminal, ignore SIGINT and SIGQUIT in the parent with a no-op handler or a flag check, never `SIG_IGN` (the child inherits it across exec). Defer SIGTERM and SIGHUP until the child exits.
- Recipes: "Guard and event loop skeleton", "prompt_toolkit shell/prompt pattern", and "Bubble Tea Model/Update/View/Cmd skeleton" in `domains/framework-recipes/references/rust-python-go.md`; "Ink component, resize, and testing pattern" in `domains/framework-recipes/references/node-dotnet.md`; the "ncurses" wrapper in `domains/framework-recipes/references/low-level-and-emerging.md`; the Node, Python, and tcell snippets in `domains/tui-troubleshooting/references/freeze-hang-diagnosis.md`; "Child-process handoff" in `domains/input-handling/references/key-mouse-protocols.md`.

**Crash recovery.** Cleanup must tolerate partially initialized state and repeated calls. Document recovery for users: the canonical recovery line in `domains/tui-troubleshooting/GUIDE.md`, `reset`, `stty sane`, reopening the tab, or `--no-tui`.

## Performance checklist

- UI loop does not block on network, disk, child processes, or API calls.
- Long operations publish progress through messages/channels/tasks.
- Render rate is capped to useful human perception, especially for dashboards.
- Resize events are coalesced before expensive recalculation.
- Tables and lists virtualize or page large datasets.
- Logging does not write to stdout/stderr while the TUI owns the screen.
- Remote terminals and SSH latency are part of testing if supported.

## Failure modes

| Symptom | Likely cause | Fix |
|--|--|--|
| Flicker | clearing entire screen or flushing repeatedly | diff/batch writes, avoid full clears |
| Flicker in Ink apps | output taller than the terminal: Ink cannot move the cursor above the viewport, so it clears and redraws everything | keep the rendered tree within `rows`; window or page long lists |
| High CPU while idle | unconditional redraw loop | render on events or capped tick |
| Corrupted shell after crash | missing cleanup on panic/exception | central terminal guard and finally/defer/drop cleanup |
| Layout overlap | absolute coordinates or stale dimensions | recompute constraints after resize |
| Logs appear inside UI | stdout/stderr logging while alternate screen active | file sink, in-app log panel, or buffered logs |

## Reference files

- `domains/rendering-layout-performance/references/render-loop-patterns.md` - Frame buffers, dirty regions, throttling, and event loops. Read when designing or fixing a render loop.
- `domains/rendering-layout-performance/references/inline-progress.md` - Inline progress bars and spinners without a full-screen UI: `\r` redraw, stderr, TTY gating, throttling, non-TTY fallback, libraries. Read when adding progress output to a CLI or script.
