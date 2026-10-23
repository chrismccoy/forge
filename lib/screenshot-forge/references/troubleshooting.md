# Troubleshooting

| Symptom | Cause and fix |
|---|---|
| `net::ERR_NAME_NOT_RESOLVED` | No network, a sandboxed shell, or a wrong hostname. Get network access with user approval, then check the URL. |
| `Timeout 60000ms exceeded` | The page never finished loading, or `--selector` never matched. Check the selector, and check that the site is up. |
| Blank or half-loaded image | Content renders on the client after load. Raise `--wait`, or pass `--selector` for an element that appears late. |
| Cookie banner or bot challenge in the image | The site served it to a fresh browser. Tell the user, because the script does not dismiss overlays. |
| `Host system is missing dependencies` | Browser system libraries are missing. See "Linux system libraries" in `devices.md`. |
| `Cannot create output directory` (exit 2) | The `--out` path is not writable. Choose another directory. |
| `Browser install failed` | The bundled browser download failed. Check network access, and free disk space in Playwright's browser folder: `~/.cache/ms-playwright` (Linux), `~/Library/Caches/ms-playwright` (macOS), `%LOCALAPPDATA%\ms-playwright` (Windows). |
| `Unknown device '<name>'` (exit 2) | The name is not a Playwright device. Names are case-sensitive: `iPhone 15`, not `iphone 15`. See `devices.md`. |
| `Cannot run playwright@1.64.1` | npx could not fetch or start Playwright. Check network access (the sandbox may block it), then the npm cache: `npm cache verify`. |
| `[frame] no <view> capture for <url>` | `--frames-only` did not find the earlier capture. Rerun with exactly the same URL or `--list`, `--out`, `--name`, `-f`, `-d`, `-m`, `--tablet`, `--tablet-device` and `--only` as the capture run. |
| `[frame] ... failed` | Frame rendering failed for one image. Check that the capture PNG is valid, then rerun with `--frames-only`. |
| `[frame] rendering failed` | Chromium could not start for framing. The captures are fine. See `Browser install failed` above, then rerun with `--frames-only`. |
| `Not a valid http(s) URL` / `Skipping <entry>: not a valid http(s) URL` | The entry has spaces, another scheme (`file://`, `ftp://`) or is not a URL. Fix the entry. |
| `Cannot find npm's npx-cli.js` (Windows) | Node.js was installed without npm. Ask the user to reinstall Node.js with npm included. |
| `Skipping <url>: same filename as <url>` | Two list entries map to one filename, usually `http://` and `https://` of one page. Only the first was captured. |
