# TUI Testing and Debugging with Snapshots, PTYs, Virtual Terminals, and ConPTY

Use this guide when a TUI needs reliable tests or when an interactive terminal bug must be reproduced outside a human terminal session.

## Four-layer test strategy

1. **Pure state tests.** Test reducers, update functions, focus transitions, validation, sorting, filtering, and command scheduling without a terminal.
2. **Component/render snapshots.** Render widgets at fixed width, height, theme, color level, locale, and time. Compare stable text or cell grids.
3. **Virtual terminal tests.** Feed ANSI output into a terminal emulator and assert final cells, cursor, styles, scrollback, and cleanup.
4. **PTY integration tests.** Spawn the real program, send keys/paste/resize, and assert visible behavior and exit status.

## Snapshot stabilization

Freeze or normalize:

- Terminal size.
- Theme and color support.
- Time, random IDs, network data, spinners, cursor blink.
- Unicode mode and ambiguous-width assumptions.
- File paths when tests run cross-platform.
- Progress rates and async scheduling.

Prefer semantic assertions for behavior and snapshots for stable visual contracts.

## Debugging workflow

1. Reproduce with the smallest terminal size and input sequence.
2. Capture raw input and output bytes when protocol behavior is suspected.
3. Separate stdout, stderr, logs, and alternate-screen output.
4. Disable animations and color to isolate layout from style.
5. Test outside and inside tmux/screen/SSH if relevant.
6. On Windows, test through ConPTY when Windows support is claimed.

## Observe without a human terminal

Never launch a full-screen TUI in a foreground agent or CI shell: it blocks on input, and its escape output garbles the transcript. Drive it headlessly:

- **Framework harness first:** when the framework ships one (Textual `run_test`/Pilot, Ratatui `TestBackend`, Bubble Tea `teatest`, `ink-testing-library`), use it before a real terminal: it is faster and deterministic. See `domains/tui-testing-debugging/references/test-strategy.md`.
- **tmux** (screen text after each step). Use a private socket and a throwaway config in a temp directory, so the user's own sessions and `~/.tmux.conf` are never touched and nothing is left behind:
  ```sh
  # Save as a script and run it with sh: fail() exits the script.
  export LC_ALL=C.UTF-8              # UTF-8 in the pane (macOS: en_US.UTF-8); C/POSIX
                                     # locales make apps fall back to ASCII glyphs
  D="$(mktemp -d /tmp/tui.XXXXXX)"; S="tui-check"
  TT=tmux-256color; infocmp "$TT" >/dev/null 2>&1 || TT=screen-256color
  printf 'set -wg remain-on-exit on\nset -g default-terminal %s\n' "$TT" > "$D/conf"
  # Short /tmp path: a socket path over ~104-108 bytes (sun_path limit) fails
  # with "File name too long" under a long $TMPDIR.
  # remain-on-exit keeps the pane after exit/crash; default-terminal pins TERM
  # (falls back when the host lacks tmux-256color terminfo, e.g. stock macOS)
  T() { tmux -u -S "$D/sock" -f "$D/conf" "$@"; }   # -u: UTF-8 client
  poll() {  # run a check every 0.1 s until it succeeds; give up after ~5 s
    i=0
    until "$@"; do i=$((i + 1)); [ "$i" -ge 50 ] && return 1; sleep 0.1; done
  }
  has_text() { T capture-pane -t "$S" -p | grep -qF -- "$1"; }  # fixed string: [x], ., ^ match literally
  has_re() { T capture-pane -t "$S" -p | grep -qE -- "$1"; }    # extended regex, when a pattern is meant
  is_dead() { [ "$(T display-message -p -t "$S" '#{pane_dead}')" = 1 ]; }
  fail() {  # show the current screen, clean up, stop
    echo "failed: $1" >&2; T capture-pane -t "$S" -p >&2
    T kill-server; rm -rf "$D"; exit 1
  }
  T new-session -d -s "$S" -x 80 -y 24 'app --flag'
  poll has_text 'Ready' || fail 'first frame'
  T send-keys -t "$S" Down Enter     # key names, or -l for literal text
  poll has_text 'Expected text' || fail 'expected text'
  T capture-pane -t "$S" -p > "$D/frame1.txt"   # plain text; add -e to keep SGR
  cp "$D/frame1.txt" ./frame1.txt               # copy artifacts out before cleanup
  T send-keys -t "$S" q
  poll is_dead || fail 'app exit'
  T display-message -p -t "$S" '#{pane_dead} #{pane_dead_status} #{pane_dead_signal}'
  T kill-server; rm -rf "$D"         # private socket only; removes socket and config
  ```
  Never `capture-pane` straight after `send-keys`: poll for expected text, or the capture may show the previous frame. `remain-on-exit` keeps a crashed app's last screen (panic text) on the pane; `pane_dead` is `1` after exit and exactly one of `pane_dead_status` (normal exit) and `pane_dead_signal` (death by signal) is set. If both are empty after `pane_dead` is `1`, the tmux release does not support them.
- **Raw bytes:** run the recorder inside the detached session, never in the foreground shell (recipe: `domains/tui-testing-debugging/references/debugging-playbook.md`): `T new-session -d -s "$S" -x 80 -y 24 "script -q -e -c 'app --flag' '$D/out.typescript'"` (util-linux; FreeBSD/macOS: `T new-session -d -s "$S" -x 80 -y 24 "script -q '$D/out.typescript' app --flag"`, which exits with the app's status by default; a death by signal shows as the bare signal number, e.g. 15, not 143. Current FreeBSD/macOS accept `-e` as a no-op; older macOS rejects it). If the app's command line contains quotes, write it to `$D/run.sh` and record `sh $D/run.sh` instead (playbook). Keep artifacts in `$D` and copy them out before cleanup. Then `cat -v` or `xxd` the copy. `T pipe-pane -t "$S" -O "cat >> '$D/out.raw'"` also works but misses bytes written before it attaches.
- **Leaked-mode check:** with the raw-bytes recorder, verify that every mode the app enabled was disabled again before exit (script and rules: `domains/tui-testing-debugging/references/debugging-playbook.md`, section "Check for leaked modes").
- **Windows (no tmux):** spawn the app on a ConPTY with `node-pty` (Node) or `pywinpty` (Python) and feed its output into `@xterm/headless` or `pyte`; poll the virtual screen the same way.
- **No tmux:** drive the app with `pexpect` (`pexpect.spawn('app', dimensions=(24, 80))`, `send`, `expect`) and feed everything read into a `pyte.Screen(80, 24)` through `pyte.ByteStream`.
- **Cell assertions:** feed captured bytes into `pyte` (Python) or `@xterm/headless` (Node) and assert cells, cursor, and modes.

Byte capture, replay, and annotation: `domains/tui-testing-debugging/references/debugging-playbook.md`.

## CI rules

- Do not assume CI has a real TTY.
- Use PTY wrappers where integration tests require terminal behavior.
- Mark terminal-emulator-specific tests explicitly.
- Keep snapshots deterministic and reviewable.
- Capture logs and final terminal frames as artifacts on failure.

## Failure modes

| Symptom | Likely cause | Fix |
|--|--|--|
| Snapshot flake | time, spinner, random data, terminal width | freeze inputs and normalize output |
| Works manually, fails in CI | no TTY or different TERM | create PTY or use non-TUI mode |
| Windows tests fail only | Unix PTY assumptions | test via ConPTY and account for line endings |
| Raw bytes differ but screen same | testing sequences not final cells | assert virtual terminal state |
| Debug logs corrupt UI | logs write to controlled screen | route logs to file or panel |

## Reference files

- `domains/tui-testing-debugging/references/test-strategy.md` - Test layers, tools, and assertions by ecosystem. Read when choosing a test stack, writing snapshot, PTY, or virtual-terminal tests, or recording a demo GIF with VHS.
- `domains/tui-testing-debugging/references/debugging-playbook.md` - Byte capture, terminal reset, CI, Windows, and flake triage. Read when capturing raw output, checking for leaked modes, or fixing flaky or Windows-only test failures.
