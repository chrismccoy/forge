# Escape Sequence Field Guide

Contents: Naming and byte forms; Practical CSI table; SGR rules and reset edge cases; DEC private modes and alternate screen variants; OSC and DCS tables (incl. Tmux DCS passthrough); Query timeout cautions; Terminfo and termcap examples; Cursor and screen rules; Keyboard protocols; Graphics and hyperlinks (incl. Graphics protocols); Windows VT enable.

## Naming and byte forms

| Name | 7-bit form | 8-bit C1 form | Typical use | Notes |
|--|--|--|--|--|
| `ESC` | `0x1b` | n/a | Introduces many control sequences | Show as `^[` in debug views. |
| `CSI` | `ESC [` | `0x9b` | Cursor, erase, SGR, mode set/reset, reports | Emit 7-bit form for broad UTF-8 compatibility. |
| `OSC` | `ESC ]` | `0x9d` | Title, hyperlinks, clipboard, palette queries | Terminate with BEL or ST. Treat payload as sensitive. |
| `DCS` | `ESC P` | `0x90` | Device control, sixel, tmux passthrough | Must be terminated by ST; never leave open. |
| `ST` | `ESC \` (bytes 0x1b 0x5c) | `0x9c` | String terminator for OSC/DCS/APC/PM | Prefer ST for OSC 8 and nested/passthrough cases. |
| `SGR` | `CSI ... m` | `0x9b ... m` | Rendition attributes and colors | Reset deliberately at style boundaries. |

Prefer 7-bit escape forms in application output. Many terminals accept 8-bit C1 controls, but UTF-8 byte streams, log processors, PTYs, and security filters commonly assume the `ESC`-prefixed form.

## Practical CSI table

| Intent | Sequence | Example | Caution |
|--|--|--|--|
| Move cursor | `CSI {row};{col} H` or `f` | `ESC[10;1H` | 1-based coordinates; only in controlled regions. |
| Relative moves | `CSI n A/B/C/D` | `ESC[3A` | Do not move outside the app-owned area. |
| Clear screen | `CSI 2 J` | `ESC[2J` | Does not necessarily clear scrollback. |
| Clear scrollback + screen | `CSI 3 J` plus `CSI 2 J` | `ESC[3JESC[2J` | User-hostile outside full-screen apps. |
| Clear line | `CSI 2 K` | `ESC[2K` | Useful for inline progress; pair with carriage return. |
| Hide/show cursor | `CSI ? 25 l` / `CSI ? 25 h` | `ESC[?25l` | Restore on every exit path. |
| Save/restore cursor | `ESC 7`/`ESC 8` (prefer) or `CSI s`/`CSI u` | `ESC7...ESC8` | Prefer `ESC 7`/`ESC 8` (see notes below). Alt-screen 1049 includes cursor save/restore. |
| Set title | `OSC 0 ; title ST` | `ESC]0;app ESC \` | Sanitize title. To restore it, push the old title with `CSI 22 ; 0 t` before setting and pop it with `CSI 23 ; 0 t` on exit (XTWINOPS; xterm, VTE, kitty, and others; support varies, so treat it as best effort). |
| Device status report | `CSI 6 n` | terminal replies `CSI row;col R` | Bound with timeout; handle no or malformed reply. The reply has the same shape as a modified F3 key (`CSI 1;5R`): treat `CSI r;c R` as a cursor report only while a query is outstanding, otherwise as a key. Where supported, DECXCPR (`CSI ? 6 n`, reply `CSI ? r;c R`, some terminals append `;page`) removes the ambiguity. |
| Primary DA query | `CSI c` | terminal replies e.g. `CSI ? 1;2 c` | Fingerprinting is unreliable; do not block startup. |

Save/restore notes:

- `CSI s` means DECSLRM (set left/right margins) when margin mode `?69` is on, so it does not save the cursor there.
- Do not confuse output `CSI u` (restore cursor) with Kitty keyboard input reports `CSI <code> ; <mods> u`, which arrive on stdin. On output, terminals distinguish plain `CSI u` from the Kitty control forms `CSI > u`, `CSI < u`, `CSI = u` and `CSI ? u`.

## SGR rules and reset edge cases

| Intent | SGR | Notes |
|--|--|--|
| Reset all | `0` | Clears colors and most attributes; safest style boundary. |
| Bold / faint off | `22` | Turns off both bold and faint; there is no universal separate bold-only off. |
| Italic off | `23` | Italic support is mixed. |
| Underline off | `24` | Clears single/double underline in most terminals. |
| Blink off | `25` | Avoid blink for accessibility. |
| Inverse off | `27` | Needed if using selected rows with inverse video. |
| Foreground default | `39` | Prefer over `0` when only ending foreground color. |
| Background default | `49` | Prefer over `0` when only ending background color. |
| 16 colors | `30-37`, `90-97`, `40-47`, `100-107` | Theme-defined RGB; contrast is not guaranteed. |
| 256 colors | `38;5;n`, `48;5;n` | Indexes 16-231 are color cube; 232-255 grayscale. |
| Truecolor | `38;2;R;G;B`, `48;2;R;G;B` | Semicolon form is most widely emitted. ITU T.416 also defines a colon form (`38:2::R:G:B`, with an optional color-space ID between the colons, and `38:5:N`); parsers and virtual terminals must accept both forms. |

Implementation pattern:

```text
render(style, text): SGR(style) + sanitize(text) + SGR(reset_to_parent_or_0)
```

Do not concatenate independently styled fragments without knowing the active parent style. If a bold red label is followed by red normal text, use `22` instead of `0` when preserving the foreground matters. If style nesting is hard, emit `0` then reapply the parent style at every boundary.

## DEC private modes and alternate screen variants

DEC private modes use `CSI ? number h` to set and `CSI ? number l` to reset.

| Mode | Set | Reset | Use |
|--|--|--|--|
| Cursor visible | `?25h` | `?25l` | Usually hide during draw, show on exit. |
| Application cursor keys | `?1h` | `?1l` | Changes arrow-key encoding; let the framework manage it. |
| Bracketed paste | `?2004h` | `?2004l` | Required for editors/shells that distinguish paste. |
| Normal mouse tracking | `?1000h` | `?1000l` | Press/release reports; base tracking mode that `?1006` encodes. |
| SGR mouse | `?1006h` | `?1006l` | Prefer over legacy mouse encodings. |
| Button event mouse | `?1002h` | `?1002l` | Press/release/drag; can be noisy. |
| Any event mouse | `?1003h` | `?1003l` | Very noisy; avoid unless needed. |
| Focus events | `?1004h` | `?1004l` | Advisory focus in/out events. |
| Synchronized output | `?2026h` | `?2026l` | Wrap each frame (begin before drawing, end after) so the terminal paints it atomically; reduces tearing and flicker. Canonical DECRQM decoding (other files point here): query `CSI ? 2026 $ p`; reply `CSI ? 2026 ; Ps $ y`. Ps 1 = set and 2 = reset both mean supported; 3 = permanently set means always synchronized; 0 = not recognized and 4 = permanently reset both mean unsupported; no reply within the timeout means unsupported. Harmless when ignored. |
| Alternate screen old | `?47h` | `?47l` | Historical xterm alt buffer; avoid new code. |
| Alternate screen no cursor save | `?1047h` | `?1047l` | Switch buffers; no cursor save/restore. |
| Save/restore cursor only | `?1048h` | `?1048l` | Not an alt buffer by itself. |
| Alternate screen with cursor save | `?1049h` | `?1049l` | Preferred full-screen TUI sequence. |

For full-screen apps, use a guard that follows the canonical setup and teardown order in `domains/rendering-layout-performance/GUIDE.md` (raw mode, then `?1049h`, then input modes; the reverse on exit). Multiplexers or user settings may inhibit alternate screen; the app must still quit cleanly.

## OSC and DCS tables

| OSC | Form | Use | Security posture |
|--|--|--|--|
| `0` / `2` title | `OSC 0;title ST` | Window/tab title | Escape or strip controls from title. |
| `8` hyperlink | `OSC 8;params;uri ST label OSC 8;; ST` | Clickable links | Show URI or provide reveal action; sanitize label and URI. |
| `52` clipboard | `OSC 52;c;base64 ST` | Clipboard copy | Require explicit user action; many terminals block. |
| `10/11/12` palette queries | `OSC 10;? ST` etc. | Foreground/background/cursor color | Optional; use short timeout and fallback theme. |
| Emulator-specific | varies | Images, notifications, marks | Progressive enhancement only. |

OSC termination:

- BEL termination: `ESC ] 0;title BEL` is common for titles and older tools.
- ST termination: `ESC ] 8;;https://example.invalid ESC \ label ESC ] 8;; ESC \` is safer for nested contexts and avoids accidental BEL bytes in payload handling.
- When parsing, accept both BEL and ST. When emitting OSC 8 or long structured payloads, prefer ST.

DCS examples:

| DCS | Example | Notes |
|--|--|--|
| tmux passthrough | `ESC P tmux ; ESC ESC ] 52 ; c ; BASE64 ESC ESC \ ESC \` | Outer DCS wraps the inner sequence; see the passthrough section below. |
| sixel | `ESC P q ... ESC \` | Graphics support is fragmented; provide text fallback. |
| terminfo-style queries | terminal-specific | Do not depend on replies unless bounded and validated. |

### Tmux DCS passthrough

Canonical explanation; other files point here. Every ESC inside the payload is doubled, including the inner ST's ESC:

```text
# Inner OSC: ESC ] 52 ; c ; BASE64 ST
# tmux DCS wrapper doubles ESC bytes inside the payload.
ESC P tmux ; ESC ESC ] 52 ; c ; BASE64 ESC ESC \ ESC \
```

tmux 3.3 and later ignore DCS passthrough unless the user sets `set -g allow-passthrough on` (default `off`). For OSC 52 specifically, tmux can also forward clipboard writes itself via `set -g set-clipboard on`; prefer that over passthrough when available.

In code, prefer a library that understands tmux passthrough. If hand-rolling, unit-test the exact bytes and provide a `--clipboard=always|ask|never` switch (gating: `domains/widgets-state-security-distribution/references/state-config-distribution-security.md`).

## Query timeout cautions

Terminal queries are optional. Never block startup indefinitely waiting for `CSI 6 n`, OSC palette responses, Kitty keyboard negotiation, or DA replies.

Recommended pattern:

1. Start with conservative defaults from flags, TTY detection, terminfo, and environment hints.
2. Send a query only after entering a mode where the app can read terminal input without stealing user keystrokes.
3. Wait tens to a few hundred milliseconds depending on context; make timeout configurable for remote links only if necessary.
4. Accept malformed, missing, delayed, or interleaved replies without crashing.
5. Cache the capability decision for the session; do not query every frame.

Delayed replies can arrive after the timeout and look like user input. Input parsers must route recognized reports separately and ignore stale replies where possible.

## Terminfo and termcap examples

Terminfo describes the terminal named by `TERM`, which may be a multiplexer such as `screen-256color` or `tmux-256color`, not the outer emulator.

Useful capabilities:

| Capability | Meaning | Example use |
|--|--|--|
| `cup` | cursor position | Move to row/col with parameterized sequence. |
| `clear` | clear screen | Initial draw in controlled full-screen apps. |
| `el` / `ed` | clear to end of line/display | Inline status and damage cleanup. |
| `smcup` / `rmcup` | enter/leave cursor-addressing mode | Often maps to alternate screen. |
| `civis` / `cnorm` | hide/show cursor | Restore with `cnorm`. |
| `setaf` / `setab` | set ANSI foreground/background | Use for 8/16/256-color paths. |
| `colors` | color count | Pick no/16/256-color palette. |
| `sitm` / `ritm` | italic enter/exit | May be absent even when emulator supports italic. |

Shell checks during debugging:

```sh
infocmp "$TERM" | less
printf '%s\n' "TERM=$TERM COLORTERM=${COLORTERM-} TMUX=${TMUX-}"
tput colors
(trap 'tput rmcup' EXIT; trap 'exit 130' INT; trap 'exit 143' TERM
  trap 'exit 129' HUP                         # dash/busybox skip EXIT on untrapped signals
  tput smcup; printf 'alternate\n'; sleep 1)  # rmcup runs even on Ctrl-C
```

Use terminfo through framework APIs where possible. Hard-coded xterm sequences are acceptable only for controlled, documented targets or progressive enhancements with fallbacks.

## Cursor and screen rules

- Cursor movement is safe only when stdout is an interactive terminal under the app's control.
- Avoid absolute cursor positioning in normal scrollback unless implementing a known inline progress region.
- Hide cursor only when a restore path exists.
- Alternate screen is appropriate for full-screen TUIs, not for short commands where users expect scrollback.
- Logs must not contain raw control sequences from untrusted data; render escapes visibly in debug output.

## Keyboard protocols

Legacy terminal keyboard encoding is ambiguous: Esc can mean Escape or Alt-prefix; Ctrl combinations collide with control bytes; function keys vary. Modern protocols can disambiguate, but must be optional. If enabling Kitty keyboard protocol or xterm modified-key modes, push mode on entry, pop it on exit, and preserve ordinary shortcuts as fallbacks. Input byte formats (Kitty `CSI … u` reports, modifyOtherKeys, SGR mouse, bracketed paste, focus) and parser rules live in `domains/input-handling/references/key-mouse-protocols.md`.

## Graphics and hyperlinks

OSC 8 hyperlinks, sixel, Kitty graphics, and iTerm2 images improve UX in capable terminals but are not universal. Provide text fallbacks. Do not put critical state only in an image or hyperlink. Detection and byte forms for images are in the Graphics protocols section below.

### Graphics protocols

**Sixel detection.** Send primary DA (`CSI c`). A VT220-class or later reply looks like `CSI ? 62 ; 4 ; 22 c`: the first parameter (62–65) is the terminal class, and the rest list features. Parameter `4` in the feature list after the class means sixel graphics. Do not match a leading `4`: `CSI ? 4 ; 6 c` is a VT132 identity, not sixel. Sixel data itself is a DCS string: `ESC P q <sixel data> ESC \`.

**Kitty graphics.** Every command is an APC string: `ESC _ G <control keys> ; <base64 payload> ESC \`.

- Detect: send a query followed by DA1 as a sentinel, then wait with a bounded timeout:
  `ESC _ G i=31,s=1,v=1,a=q,t=d,f=24 ; AAAA ESC \ ESC [ c`
  A reply `ESC _ G i=31 ; OK ESC \` before the DA1 reply means supported. A DA1 reply with no graphics reply means unsupported.
- Transmit and display a PNG in one step: `a=T,f=100` with the base64 PNG as payload (`f=24` is raw RGB, as in the query).
- Chunk large payloads: base64-encode, split into chunks of at most 4096 bytes, each chunk except the last a multiple of 4 bytes. The first chunk carries all control keys plus `m=1`; later chunks carry only `m` (and optionally `q`): `m=1` for every chunk except the last, `m=0` on the last.
- Delete: `a=d` alone, or `a=d,d=a`, removes all visible placements. `a=d,d=i,i=<id>` removes one image's placements. Lowercase `d` values keep the stored image data for reuse; uppercase (`d=A`, `d=I`) also free it when nothing else references it.

**iTerm2 inline images.** `ESC ] 1337 ; File=inline=1;size=<bytes>[;width=..;height=..;preserveAspectRatio=0|1] : <base64 file> BEL`. ST (`ESC \`) may replace BEL. `inline=1` displays the image; the default `0` downloads the file instead. Under tmux integration, iTerm2 3.5+ offers a split form (`MultipartFile`, `FilePart`, `FileEnd`) because tmux limits sequence length.

**Practical rules.**

- Inside tmux, wrap graphics sequences in DCS passthrough (see Tmux DCS passthrough above, including `allow-passthrough on`); tmux does not track image positions, so images can be left behind or misplaced on redraw.
- Bound every detection wait, and cache the result for the session.
- Delete placed images on exit and before leaving the alternate screen (Kitty `a=d`), so they do not persist on the main screen.
- Always keep a text fallback (a table, sparkline, or "image omitted" line). Never put critical state only in an image.

## Windows VT enable

Enable VT processing explicitly on Windows and check every return value:

```c
HANDLE hOut = GetStdHandle(STD_OUTPUT_HANDLE);
HANDLE hIn = GetStdHandle(STD_INPUT_HANDLE);
DWORD origOut = 0, origIn = 0;
BOOL haveOut = FALSE, haveIn = FALSE;  /* original modes saved, so restore them */
BOOL vtOut = FALSE, vtIn = FALSE;
DWORD extra = 0;
#ifdef FULLSCREEN_RENDERER  /* opt-in: LF stops returning to column 0 (see below) */
extra = DISABLE_NEWLINE_AUTO_RETURN; /* 0x0008 */
#endif
if (hOut != INVALID_HANDLE_VALUE && GetConsoleMode(hOut, &origOut)) {
    haveOut = TRUE;
    vtOut = SetConsoleMode(hOut, origOut | ENABLE_VIRTUAL_TERMINAL_PROCESSING /* 0x0004 */ | extra);
    if (!vtOut && extra != 0)  /* down-level host may reject 0x0008: step down and retry */
        vtOut = SetConsoleMode(hOut, origOut | ENABLE_VIRTUAL_TERMINAL_PROCESSING);
}
/* !vtOut: not a console, or no VT support: fall back to plain output */
if (hIn != INVALID_HANDLE_VALUE && GetConsoleMode(hIn, &origIn)) {
    haveIn = TRUE;
    vtIn = SetConsoleMode(hIn, origIn | ENABLE_VIRTUAL_TERMINAL_INPUT /* 0x0200 */);
}
/* !vtIn: read console input records instead of VT key sequences */

/* ... run the UI ... */

/* Teardown, on every exit path: emit the VT resets first, then restore the saved modes. */
if (haveIn) SetConsoleMode(hIn, origIn);
if (haveOut) SetConsoleMode(hOut, origOut);
```

`DISABLE_NEWLINE_AUTO_RETURN` makes LF move down without returning to column 0, so the snippet sets it only when `FULLSCREEN_RENDERER` is defined. Full-screen renderers that position the cursor explicitly want it; line-oriented or colored CLI output must leave it off, or emit `\r\n` everywhere. This follows Microsoft's recommended sample: a failed `SetConsoleMode` with `GetLastError() == ERROR_INVALID_PARAMETER` signals a down-level host, so retry with fewer flags. The snippet saves the original modes and restores them at teardown.
