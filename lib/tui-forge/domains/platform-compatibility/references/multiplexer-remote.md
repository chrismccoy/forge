# Multiplexer and Remote Terminal Reference

## tmux

- tmux often advertises a tmux-specific `TERM`, so outer terminal features may need tmux configuration to pass through.
- Truecolor ("colors look wrong in tmux") needs explicit config. Canonical recipe (other files point here):

  ```tmux
  # ~/.tmux.conf
  set -g default-terminal "tmux-256color"
  # tmux 3.2+: tell tmux the outer terminal supports RGB (replace xterm-256color with the outer $TERM)
  set -as terminal-features ",xterm-256color:RGB"
  # older tmux: use the Tc extension instead
  # set -as terminal-overrides ",xterm-256color:Tc"
  ```

  Apply it without killing anything: run `tmux source-file ~/.tmux.conf` (`default-terminal` affects only panes created afterwards), then detach and reattach so the client's `terminal-features` are re-read. Check from inside a pane with `tmux display -p '#{client_termfeatures}'`: the list must contain `RGB`. Alternatively, `tmux info | grep setrgbf` must show a string, not `[missing]`. Do not grep `tmux info` for `RGB` or `Tc`: the `RGB` feature adds the `setrgbf`/`setrgbb` strings, not those flags, so both show `[missing]` unless the terminfo entry itself defines them, even when truecolor works. tmux also adds `RGB` by itself when the attaching client has `COLORTERM=truecolor` or `COLORTERM=24bit`. Use `tmux kill-server` only as a last resort: it ends every tmux session and every process running inside them.

  Many apps detect truecolor from `COLORTERM`, which older tmux releases may not set inside panes. tmux 3.6 and later set `COLORTERM=truecolor` in every pane even when the client lacks RGB (3.6 CHANGES: "Set and check COLORTERM as a hint for RGB colour"), so it proves nothing there; check `client_termfeatures` as above. On older tmux, check with `echo "${COLORTERM-}"` in a pane. If it is empty and `client_termfeatures` shows `RGB`, add `set-environment -g COLORTERM truecolor` (or list `COLORTERM` in `update-environment` to copy it from the attaching client). Without `RGB`, setting it makes apps send truecolor the outer terminal cannot show. Over SSH, `COLORTERM=truecolor` is not forwarded unless the client sends it (`SendEnv COLORTERM`) and the server accepts it (`AcceptEnv COLORTERM`). If the host lacks `tmux-256color` terminfo, fall back to `screen-256color`.
- OSC 52 clipboard access is configurable and often intentionally restricted.
- DCS passthrough can carry some sequences to the outer terminal, but behavior is version- and configuration-dependent (tmux 3.3+ requires `allow-passthrough on`). Byte format, settings, and the `set-clipboard` alternative: `domains/terminal-standards/references/escape-sequence-field-guide.md` (Tmux DCS passthrough).
- Mouse events are mediated by tmux; test panes, copy mode, alternate screen, wheel scrolling, and drag behavior.

## GNU screen

- screen is more conservative and may filter or transform modern sequences.
- Expect weaker support for OSC/DCS extensions, focus events, truecolor configuration, and advanced keyboard protocols.
- Provide 16/256-color and no-clipboard fallbacks.

## Zellij

- Zellij has its own pane, keybinding, and mode model. It may intercept shortcuts and mediate copy, mouse, and layout behavior.
- Test app shortcuts against Zellij defaults. Avoid assuming Ctrl/Alt chords are available.

## Passthrough policy

Use passthrough only for optional enhancement. Never make core workflows depend on terminal images, clipboard writes, focus notifications, or private keyboard protocols surviving a multiplexer chain. If a feature is attempted, detect failure or timeout and continue visibly.

## SSH and remote sessions

- Remote `TERM` describes what the remote side believes the terminal is; it may not reflect the local emulator accurately, especially through jump hosts or multiplexers.
- Resize propagation can be delayed or lost; treat `SIGWINCH`/resize events as hints, tolerate stale dimensions, and re-query size on redraw.
- Clipboard and image protocols cross a trust boundary. Many environments block them for good reason.
- Agent forwarding is unrelated to terminal rendering but is a security-sensitive remote feature. Do not require it for UI behavior; clearly separate authentication failures from terminal capability failures.

## Latency and bandwidth tactics

- Render on state change, not busy loops.
- Batch writes and flush once per frame.
- Prefer dirty-region/cell-diff updates over full clears.
- Avoid high-frequency mouse hover effects over SSH unless throttled.
- Cap dashboard updates to the rate users can read.
- Offer `--reduced-motion`, `--low-bandwidth`, or reduced refresh options.

## Remote-safe UX

- Keep keyboard navigation complete; mouse may be disabled by SSH clients, multiplexers, or user preference.
- Avoid local-only assumptions such as opening local files, using local clipboard, or rendering local images from remote paths.
- Preserve useful scrollback in non-full-screen mode for logs and long-running commands.
- Provide recovery instructions that work remotely: quit keys, the recovery line in `domains/tui-troubleshooting/GUIDE.md` (section "Recovery commands for users"), `reset`, `stty sane`, and `--no-tui`.
