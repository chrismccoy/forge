# Platform, Emulator, Multiplexer, and Remote Compatibility

Use this guide when a TUI must behave across operating systems, terminal emulators, multiplexers, SSH sessions, containers, CI, or embedded pseudo-terminal hosts.

## Compatibility mindset

Terminal capability is a chain: application library, OS console or PTY, shell, multiplexer, SSH transport, terminal emulator, font, theme, and user settings. A feature is reliable only if each link preserves it. Treat every advanced protocol as optional unless the app owns the whole environment.

## Support matrix to define

For production TUIs, document and test:

- OS: Linux, macOS, Windows Terminal, classic conhost if supported, WSL, containers.
- Terminal emulators: Terminal.app, iTerm2, Kitty, Ghostty, Alacritty, WezTerm, foot, GNOME Terminal/VTE, Konsole, Windows Terminal.
- Multiplexers: tmux, GNU screen, Zellij.
- Remote: SSH, mosh-like links, serial/slow links, jump hosts, agent forwarding policy.
- Shell and locale: UTF-8 locale, code page on Windows, `TERM` and terminfo availability.
- Constraints: minimum size, color level, Unicode/ASCII mode, mouse/paste support.

## Platform rules

- On Windows, distinguish Windows Terminal/ConPTY from legacy console hosts. Enable virtual terminal processing when using low-level console APIs, prefer UTF-8, and test child-process hosting through ConPTY when relevant.
- On Unix-like systems, handle PTY semantics, `SIGWINCH`, termios raw/cbreak restoration, process signals, and locale-dependent encoding.
- On macOS, Terminal.app and iTerm2 differ in proprietary protocols, option-key behavior, clipboard/image features, and default color/theme settings.

## Multiplexer rules

- tmux/screen/Zellij can rewrite `TERM`, filter OSC/DCS, transform mouse events, mediate alternate screen, and require passthrough wrappers for clipboard, images, truecolor, or keyboard protocols.
- Always test inside and outside the multiplexer versions the app claims to support.
- Truecolor in tmux (wrong or washed-out colors only inside tmux): see the recipe in `domains/platform-compatibility/references/multiplexer-remote.md`.
- Prefer text fallbacks over hard dependencies on OSC 52, OSC 8, Kitty graphics, iTerm2 images, focus events, or extended keyboard protocols.

## Remote rules

- Minimize write volume and cursor churn over SSH.
- Coalesce resize storms and high-frequency metrics.
- Do not assume clipboard, local file paths, image protocols, or agent forwarding are present or allowed.
- Provide low-bandwidth, no-mouse, reduced-motion, plain, and batch modes.

## Reference files

- `domains/platform-compatibility/references/emulator-platform-matrix.md` - OS, emulator, PTY, and feature compatibility guidance. Read when a feature works in one emulator or OS but not another, or before relying on a protocol.
- `domains/platform-compatibility/references/multiplexer-remote.md` - tmux/screen/Zellij, SSH, latency, passthrough, and resize practices. Read when behavior changes inside a multiplexer or over SSH.
