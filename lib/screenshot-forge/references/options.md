# Script options and output rules

Run `node ${CLAUDE_PLUGIN_ROOT}/lib/screenshot-forge/scripts/capture.mjs --help` for the same list in the terminal.

## Options

| Option | Default | Purpose |
|---|---|---|
| `-l, --list FILE` | none | Read URLs from a text file, one per line. Use instead of a URL. |
| `-c, --concurrency N` | `2` | URLs captured at once with `--list` |
| `-o, --out DIR` | `./screenshots` | Output directory, created if missing |
| `-n, --name NAME` | slug of the URL | Filename prefix: `<name>-desktop.png`, `<name>-mobile.png`. Single URL only. Each run of `/ \ : * ? " < > |` becomes one `_`, and leading dots become one `_`. |
| `-f, --full-page` | off | Capture the full scrollable page, not only the first screen. Files end in `-full.png`. |
| `-d, --desktop WxH` | `1440x900` | Desktop viewport size |
| `-m, --device NAME` | `Pixel 7` | Playwright device descriptor for the mobile capture. Case-sensitive; an unknown name exits `2`. See `devices.md`. |
| `-w, --wait MS` | `2000` | Fixed wait after load, for lazy images and animations |
| `-s, --selector SEL` | none | Wait until this CSS selector appears |
| `--dark` | off | Emulate `prefers-color-scheme: dark` |
| `--tablet` | off | Also capture a tablet view: `<name>-tablet.png` |
| `--tablet-device NAME` | `Galaxy Tab S4` | Playwright device for the tablet. Case-sensitive. |
| `--only LIST` | `desktop,mobile` | Comma list of the views to capture, from `desktop`, `tablet` and `mobile` |
| `--frame` | off | Also write transparent PNGs in device frames. See "Device frames". |
| `--combo` | off | Also write one image of every captured device together. Implies `--frame`. Needs desktop plus tablet or mobile. |
| `--combo-layout L` | `overlap` | `overlap`: laptop behind, tablet front-left, phone front-right. `row`: side by side, nothing hidden. |
| `--frames-only` | off | Skip capturing; frame the PNGs an earlier run wrote |

## Device frames

`--frame` writes extra transparent PNGs next to the captures, rendered at 2× from `assets/frame.html`:

| File | Contents | Written when |
|---|---|---|
| `<name>-desktop-framed.png` | Desktop capture in a generic laptop with a browser bar (three dots, page host) | Desktop captured |
| `<name>-tablet-framed.png` | Tablet capture in a generic portrait tablet with a status bar | Tablet captured |
| `<name>-mobile-framed.png` | Mobile capture in a generic phone with a status bar | Mobile captured |
| `<name>-combo.png` | Every captured device together, in the `--combo-layout` | `--combo` given, desktop plus tablet or mobile captured |

- Frames always show the first screen. Full-page captures are cropped to the viewport height.
- The phone and tablet frames take the device's width. In the combined image they are drawn at a fixed small size.
- Phone and tablet status bars take the colour of the top of each screenshot, so dark sites get dark bars automatically.
- `--frames-only` adds frames to an earlier run without capturing again; it takes a few seconds. Repeat that run's URL or `--list`, `--out`, `--name`, `-f`, `-d`, `-m`, `--tablet`, `--tablet-device` and `--only`, so it finds the same files. A missing capture is reported as `[frame] no <view> capture for <url>` and gives exit `1`.
- Frames render in Chromium: system Chrome when present, otherwise the bundled Chromium.

## URLs and filenames

- Only `http://` and `https://` URLs are accepted. Other schemes (`file://`, `ftp://`) and malformed entries are rejected:
  - A single URL: exit `2`.
  - In a list: `Skipping <entry>: not a valid http(s) URL`. The rest still run, and the exit code is `1`. If no entry is valid, the run stops with `No valid URLs` and exit `2`.
- A URL without a scheme gets `https://` prepended.
  - Local and LAN hosts get `http://` instead: `localhost`, `127.x.x.x`, `0.0.0.0`, `[::1]`, `10.x.x.x`, `172.16–31.x.x`, `192.168.x.x`, `*.local` and `host.docker.internal`.
  - For any other dev server without TLS, pass `http://` explicitly.
- The default slug keeps the host, path and query string, and drops the `#fragment`. For example, `https://a.com/docs?id=1` becomes `a.com_docs_id_1`.
- Slugs longer than 150 characters are cut short and end with an 8-character hash of the URL.
- Existing files with the same name are overwritten. Pass `--name` to keep several captures of one URL.

## Lists

- Blank lines and lines starting with `#` are skipped. Windows line endings and a byte-order mark are handled.
- URLs that give the same filename, ignoring case, are captured once. If two different URLs collide, the later one is skipped with `Skipping <url>: same filename as <url>` on stderr.
- If one URL fails, the rest are still captured. The exit code is then `1`, and stderr names each failed URL.

## Output contract

- Stdout: one absolute path per PNG written, including framed images, and nothing else.
- Stderr: install progress, warnings and failures. Each capture failure is the last 5 log lines, prefixed with `[desktop]`, `[tablet]` or `[mobile]` and the URL. Frame problems start with `[frame]`.
- Exit codes:
  - `0`: all captures succeeded.
  - `1`: at least one capture or frame failed, a list entry was invalid, or Playwright could not run or install.
  - `2`: nothing ran, because of bad arguments, an invalid URL, a list with no valid URLs, an unknown device, or an unreadable list or output directory.

## Examples

```bash
# Default: desktop 1440x900 and Pixel 7, first screen only
node ${CLAUDE_PLUGIN_ROOT}/lib/screenshot-forge/scripts/capture.mjs https://example.org

# Full-page captures in dark mode, saved to a chosen folder
node ${CLAUDE_PLUGIN_ROOT}/lib/screenshot-forge/scripts/capture.mjs example.org/pricing -f --dark -o ~/shots

# Tablet-sized desktop and a different phone
node ${CLAUDE_PLUGIN_ROOT}/lib/screenshot-forge/scripts/capture.mjs example.org -d 1024x768 -m "Galaxy S9+"

# All three views, framed, plus the side-by-side combined image
node ${CLAUDE_PLUGIN_ROOT}/lib/screenshot-forge/scripts/capture.mjs example.org --tablet --combo --combo-layout row

# Every URL in a file, mobile only, 4 at a time
node ${CLAUDE_PLUGIN_ROOT}/lib/screenshot-forge/scripts/capture.mjs --list urls.txt --only mobile -c 4

# Capture, then add device frames afterwards without capturing again
node ${CLAUDE_PLUGIN_ROOT}/lib/screenshot-forge/scripts/capture.mjs example.org
node ${CLAUDE_PLUGIN_ROOT}/lib/screenshot-forge/scripts/capture.mjs example.org --frames-only --combo

# Single-page app: wait for the main content to mount
node ${CLAUDE_PLUGIN_ROOT}/lib/screenshot-forge/scripts/capture.mjs https://app.example.org -s "#root main" -w 4000
```
