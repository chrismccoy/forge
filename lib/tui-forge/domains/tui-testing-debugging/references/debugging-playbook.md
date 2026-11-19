# TUI Debugging Playbook

## Capture useful evidence

Use the evidence checklist and collection commands in `domains/tui-troubleshooting/references/diagnostic-playbook.md` (section "Setup: collect environment facts").

Capture the session itself without a human terminal. Never run the app in the agent's foreground shell. Reuse the headless recipe in `domains/tui-testing-debugging/GUIDE.md` (section "Observe without a human terminal"): keep its setup lines and helpers (`D`, `S`, `TT`, `T`, `poll`, `has_text`, `has_re`, `is_dead`, `fail`) unchanged, add `leak_check` (below) to them, and replace its session lines with these to record raw bytes:

```sh
# util-linux (Linux): records all output; -e returns the child's exit status
T new-session -d -s "$S" -x 80 -y 24 "script -q -e -c 'app --flag' '$D/out.typescript'"
# FreeBSD/macOS: file first, then the command (OpenBSD: script -c 'app --flag' file; no -q/-e, always exits 0, so pane_dead_status loses the app's status; have the app log it)
#   T new-session -d -s "$S" -x 80 -y 24 "script -q '$D/out.typescript' app --flag"
# Command contains quotes? Write it to a file instead of nesting a third level of quotes:
#   printf '%s\n' "exec app --title \"it's here\"" > "$D/run.sh"
#   then use  -c 'sh $D/run.sh'  (FreeBSD/macOS: ... '$D/out.typescript' sh '$D/run.sh')
poll has_text 'Ready' || fail 'first frame'      # keys sent earlier are lost or echoed
T send-keys -t "$S" Tab Enter
poll has_text 'Expected text' || fail 'expected text'
T capture-pane -t "$S" -p -e > "$D/frame1.ansi"  # -e keeps SGR
T send-keys -t "$S" q
poll is_dead || fail 'app exit'                  # let teardown bytes reach the file
cp "$D/out.typescript" "$D/frame1.ansi" .       # copy artifacts out before cleanup
leak_check out.typescript || fail 'leaked modes' # defined below; fail cleans up
T kill-server; rm -rf "$D"                       # private socket only
cat -v out.typescript | tail -n 60  # ^[ marks ESC; tail keeps the transcript short
xxd -g 1 out.typescript | tail -n 40  # exact bytes, one per column, for annotation
```

Wait for the first frame before sending keys, and wait for the pane to die before `kill-server`: killing early sends SIGHUP before teardown, so a correct app looks like it leaks modes.

The typescript may include `Script started`/`Script done` header lines (util-linux adds them; FreeBSD/macOS `script -q` omits them). Strip them only if present before replaying bytes.

### Check for leaked modes

Define `leak_check` with the other helpers and call it after `poll is_dead`, as in the recipe above; standalone, define it and run `leak_check out.typescript; echo $?` on a copied file. It replays the typescript's mode changes in order and reports only modes still on at the end, so apps that never turn on paste, mouse, or the alternate screen (`ratatui::init()`, curses, inline UIs) pass. Combined parameters (`?1000;1006h`), application cursor keys (`?1h`), color-palette and in-band resize reports (`?2031h`, `?2048h`), autowrap left off (`?7l`), modifyOtherKeys (`>4;Nm` on; `>4m`, `>4;0m`, `>4n`, and `>m` reset it), Kitty keyboard push/pop depth, and the Kitty set form (`=flags;mode u`) are tracked. Kitty keeps one stack per screen and clears the alternate screen's stack only on a reset (RIS `ESC c` or DECSTR `CSI ! p`), not on a screen switch, so flags left there reach the next full-screen program (`less`, `vim`); the check reports flags left on either stack. Pop before leaving the alternate screen. A pop that empties a stack resets all its flags, including ones set with `=`. Modes 47, 1047, and 1049 count as one alternate-screen state, so entering with one and leaving with another is clean. RIS clears every tracked mode, including `?7l`; DECSTR clears only what all terminals reset (cursor shown) plus the Kitty stacks, since xterm's DECSTR leaves mouse, paste, and the alternate screen on; DECSTR's effect on autowrap differs by terminal (the VT510 turns it off), so it leaves `?7l` reported. Text in the transcript that looks like a sequence but has no ESC (`[?1049h` in log output) is ignored. It needs only POSIX `tr` and `awk` (works with busybox). Status 0 means a clean teardown; leaked modes go to stderr.

```sh
leak_check() {  # $1 = typescript; prints leaked modes to stderr; status 1 if any
  [ -s "$1" ] || { echo "no typescript at $1" >&2; return 1; }
  # newlines become CR so only ESC starts a record; record 1 (bytes before the first ESC) is skipped
  LC_ALL=C tr -d '\000' < "$1" | LC_ALL=C tr '\n\033' '\r\n' | LC_ALL=C awk '
    BEGIN { alt = 0 }                          # 0 = main screen, 1 = alternate screen
    NR == 1 { next }
    function mode(p, v,   n, i, a, k) { n = split(p, a, ";")
                                     for (i = 1; i <= n; i++) { k = a[i]
                                       if (k == "47" || k == "1047") k = "1049"  # one alternate-screen state
                                       m[k] = v }
                                     alt = (m["1049"] == 1) }
    function bits(x, y, op,   r, b) {    # bitwise or/andnot on the 5 Kitty flag bits (POSIX awk)
      r = 0; for (b = 16; b >= 1; b /= 2) {
        if (op == "or" ? (x >= b || y >= b) : (x >= b && y < b)) r += b
        if (x >= b) x -= b; if (y >= b) y -= b }
      return r }
    /^c/                 { split("", m); split("", depth); split("", base); mok = 0; alt = 0; next }  # RIS: full reset
    /^\[!p/              { m["25"] = 1; split("", depth); split("", base); next }  # DECSTR: cursor shown; kitty empties both key stacks
    /^\[\?[0-9;]+[hl]/ { match($0, /^\[\?[0-9;]+[hl]/)
                         mode(substr($0, 3, RLENGTH - 3), substr($0, RLENGTH, 1) == "h"); next }
    /^\[>4(;[0-9]*)?m/  { match($0, /^\[>4(;[0-9]*)?m/)  # modifyOtherKeys: >4;Nm on, >4m, >4;m, >4;0m reset
                           mok = (substr($0, 5, RLENGTH - 5) + 0 > 0); next }
    /^\[>4n/ || /^\[>m/  { mok = 0; next }       # XTMODKEYS disable (>4n) and reset-all (>m)
    /^\[>[0-9]*u/        { depth[alt]++; next }  # Kitty push; each screen has its own stack
    /^\[<[0-9]*u/        { match($0, /^\[<[0-9]*u/); k = substr($0, 3, RLENGTH - 3)
                           k = (k == "" ? 1 : k + 0); if (k > depth[alt]) base[alt] = 0  # emptying pop resets all flags
                           depth[alt] -= k; if (depth[alt] < 0) depth[alt] = 0; next }
    /^\[=[0-9]*(;[0-9]*)?u/ { if (depth[alt] > 0) next  # set form edits the pushed entry; a pop drops it
                           match($0, /^\[=[0-9]*(;[0-9]*)?u/); split(substr($0, 3, RLENGTH - 3), q, ";")
                           f = q[1] + 0; md = (q[2] == "" ? 1 : q[2] + 0)
                           base[alt] = (md == 2 ? bits(base[alt], f, "or") : md == 3 ? bits(base[alt], f, "andnot") : f); next }
    END {
      n = split("1049 1 2004 9 1000 1001 1002 1003 1005 1006 1015 1016 1004 2026 2027 2031 2048", on, " ")
      for (i = 1; i <= n; i++) if (m[on[i]] == 1) { print "leaked: ?" on[i] "h"; bad = 1 }
      if (("25" in m) && m["25"] == 0) { print "leaked: ?25l (cursor hidden)"; bad = 1 }
      if (("7" in m) && m["7"] == 0)   { print "leaked: ?7l (autowrap off)"; bad = 1 }
      if (mok) { print "leaked: modifyOtherKeys (>4;Nm)"; bad = 1 }
      if (depth[0] > 0) { print "leaked: Kitty keyboard flags (" depth[0] " pushed)"; bad = 1 }
      if (base[0] > 0)  { print "leaked: Kitty keyboard flags (=" base[0] "u set, never cleared)"; bad = 1 }
      if (depth[1] > 0 || base[1] > 0) { print "leaked: Kitty keyboard flags left on the alternate-screen stack"; bad = 1 }
      exit bad
    }' >&2
}
```

Limits: 8-bit C1 controls (`0x9b` CSI) are not parsed, and neither are C0 controls embedded inside a sequence (`ESC [ ? 20 CR 27 h`). Charset designations (G0/G1 left on line drawing), the scroll region (DECSTBM), and SGR left non-default are not tracked. The Kitty set form treats mode 0 and modes 4 and up as mode 1 (kitty ignores them), and flags of 128 or more are not masked the way kitty masks them. A modifyOtherKeys sequence with extra parameters (`>4;2;1m`) and DEC modes written with leading zeros (`?01049h`) are skipped, so their leaks are missed. A push left on a stack counts as a leak even when its flags are 0 (`CSI > u`), the Kitty stack's 8-entry cap is not modeled, and a mode the app enabled before recording started is invisible. A plain app killed with SIGKILL leaves every mode on, and the check reports it; under tmux, the server restores the outer terminal, and Neovim's separate UI process resets the modes the killed one set. Also not modeled: xterm's DECSTR resets modifyOtherKeys and `?1` too, but the check still reports them after DECSTR. Only the bare `CSI ! p` form counts as DECSTR; a parameterized `CSI 0 ! p` is skipped, so modes it resets are still reported. Leading zeros (`>04;2m`) and colon subparameters in XTMODKEYS forms are skipped. Keypad application mode (`ESC =`) and XTSAVE/XTRESTORE (`CSI ? … s`/`r`) are not tracked. Mouse modes 9 and 1000–1003 are tracked separately, though xterm treats them as one setting: `?1000h` then `?1002l` turns xterm's mouse off but is still reported. `?1h` may be reported when the recorded command is an interactive shell whose line editor turns it on; record the app itself.

## Reset corrupted terminals

Use the canonical recovery sequence in `domains/tui-troubleshooting/GUIDE.md` (section "Recovery commands for users"). Reopening the tab or using the app's documented `--no-tui` mode also works. Verify cleanup in tests so users rarely need these.

## Byte-level debugging

When escape sequences are suspected, inspect raw bytes separately from rendered output. Capture hex dumps of input and output streams, annotate ESC/CSI/OSC/DCS boundaries, and compare against a virtual terminal's final cell grid. A virtual terminal assertion may show the screen is correct even when byte sequences vary. Conversely, byte captures can reveal missing cleanup sequences, unbalanced SGR, unsafe OSC output, or pasted data being parsed as commands.

Hex dump annotation example from `xxd -g 1` (`^[` marks ESC, byte `1b`):

```text
00000000: 1b 5b 3f 31 30 34 39 68 1b 5b 3f 32 35 6c 1b 5b  .[?1049h.[?25l.[
          ^[ [  ?  1  0  4  9  h  ^[ [  ?  2  5  l  ^[ [
          enter alt screen        hide cursor       (SGR continues)
00000010: 33 31 6d 45 72 72 6f 72 1b 5b 30 6d              31mError.[0m
          3  1  m  E  r  r  o  r  ^[ [  0  m
          SGR red, then "Error"   SGR reset
```

`hexdump -C` shows the same bytes with no colon after the offset, an extra space after the eighth byte, and the text column inside `|...|`.

Annotate boundaries first, then interpret parameters. For input bugs, preserve timing and partial reads because parsers often fail when an escape sequence is split across reads.

## Byte capture and replay harness shape

Include bytes and context in every capture:

```json
{
  "width": 80,
  "height": 24,
  "env": {"TERM": "xterm-256color", "TMUX": ""},
  "events": [
    {"t_ms": 0, "kind": "spawn"},
    {"t_ms": 30, "kind": "stdin", "bytes_hex": "1b5b3230307e70617374651b5b3230317e"},
    {"t_ms": 60, "kind": "resize", "width": 100, "height": 30},
    {"t_ms": 90, "kind": "stdout", "bytes_hex": "1b5b3f32356c", "truncated": true}
  ]
}
```

`bytes_hex` holds complete, valid hex. When a capture stores only a prefix, mark the event `"truncated": true` so replay tools skip byte-exact checks for it.

Replay modes:

1. Feed input events into the update loop with a fake clock to isolate state bugs.
2. Spawn the binary under a PTY and replay stdin/resize timing to reproduce integration bugs.
3. Feed captured stdout into a virtual terminal to assert final cells and terminal modes.

Keep sensitive data out of recordings. Redact tokens before saving, and render escape bytes visibly when sharing logs.

## Common failure signatures

| Symptom | Likely cause | First check |
|--|--|--|
| Shell stays invisible cursor | Missing `CSI ? 25 h` on exit | Cleanup guard and panic path. |
| User shell remains raw | Raw/cbreak mode not restored | `stty -a`; finally/defer/Drop order. |
| Pasted text executes commands | Bracketed paste disabled or ignored | Input parser and paste mode enable/disable. |
| Garbled title/clipboard | Untrusted OSC emitted | Sanitization and OSC 52/8 gates. |
| Misaligned table after emoji | Width by code point/byte | Grapheme + cell-width library. |
| Works locally, slow over SSH | Too many small writes/full clears | Batch writes, diff frames, throttle ticks. |
| Resize crashes or overlaps | Cached absolute layout | Recompute layout from new dimensions. |

## Windows and ConPTY

Windows terminal behavior depends on host, ConPTY, virtual terminal processing, code page/UTF-8 handling, and the child process model. If a project claims Windows support, test the actual executable through Windows terminal paths, not only Unix PTY simulations.

ConPTY debugging checklist:

- Confirm output VT processing is enabled when using low-level console APIs.
- Confirm UTF-8 mode or framework Unicode conversion behavior.
- Test Ctrl-C, process termination, and child cleanup.
- Compare Windows Terminal and classic conhost if both are supported.
- Capture stdout/stderr bytes around resize and shutdown; ConPTY can coalesce or transform output differently from Unix PTYs.
