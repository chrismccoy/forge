---
name: screenshot-forge
description: This skill should be used when the user asks to "screenshot a URL", "take a screenshot of this site", "screenshot localhost:3000", "show how this page looks on mobile and tablet", "grab a full-page screenshot", "make a device mockup of this site", or "screenshot every URL in this file", or otherwise wants PNG captures of web pages at desktop, tablet and/or mobile sizes, optionally in device frames. Not for capturing the local screen or app windows, or for writing Playwright tests.
---

# Screenshot Forge

The files named below live in `${CLAUDE_PLUGIN_ROOT}/lib/screenshot-forge/`.

Capture PNG screenshots of web pages at desktop, tablet and mobile sizes with `scripts/capture.mjs`, optionally in device frames. It wraps `npx playwright screenshot` (pinned to `1.64.1`) and needs only Node.js 20+.

## Rules

- Never run `sudo`; give such commands to the user.
- Get user approval before bypassing a sandbox for network access.
- Never guess a URL from earlier conversation without confirming it.
- Keep temporary files out of the user's project: use the session scratchpad or the OS temp directory.
- Default devices (`Pixel 7`, `Galaxy Tab S4`) use Chromium. Before the first capture with any other browser, warn in one line, then proceed unless the user objects. That covers iPhone, iPad, Desktop Safari, legacy WebKit devices and Desktop Firefox. The warning: about 100 MB download, and usually `sudo` for system libraries on Linux; suggest `Pixel 7` or `Galaxy Tab S4` instead (see `references/devices.md`).

## Intake

**URLs.** Take them from the arguments or the request.
- If none is given, ask in plain text: "Which URL should I capture? You can also give a path to a text file with one URL per line."
- For a file, pass `--list FILE`. For several typed URLs, write them one per line to a temporary file and pass `--list`; keep that file until step 5 is done.

**Called with no URL:** after the URL, ask one AskUserQuestion call (or plain text) with two questions:
- "Which viewports should I capture?" (multi-select: Desktop, Tablet, Mobile). Pass the selection as `--only desktop,tablet,mobile`; with nothing selected, keep the default.
- "Would you like device frames?" (see **Frame choice**). This settles frames; skip workflow step 5.

**Otherwise ask nothing.** Defaults: desktop and mobile, first screen, light mode, `Pixel 7`, `./screenshots`. Map phrasing to flags:

| Request says | Flags |
|---|---|
| "mobile" | `--only mobile` |
| "desktop" | `--only desktop` |
| "tablet only" | `--only tablet` |
| "tablet", "all", "every device", "desktop, tablet and mobile" | `--tablet` |
| "whole page" | `-f` |
| "dark mode" | `--dark` |
| "on iPhone" | `--only mobile -m "iPhone 15"` |
| "on iPad" | `--only tablet --tablet-device "iPad (gen 7)"` |
| "device frame", "mockup", "on a laptop" | `--frame` |
| "all devices together", "combined mockup" | `--combo` (add `--combo-layout row` for "side by side") |
| "all" or "everything" with frames, e.g. "all devices and mockups" | `--tablet --combo` |

Any frame phrase settles frames; skip workflow step 5.

### Frame choice

Ask "Would you like device frames?" with AskUserQuestion, or in plain text without it. Plain screenshots are always written; frames are extra files. Options:
- "No frames": nothing.
- "Device frames": `--frame` (laptop, tablet, phone).
- "Frames + combined, overlapping": `--combo` (frames plus all devices in one image, laptop behind).
- "Frames + combined, side by side": `--combo --combo-layout row`.

Offer the combined options only when desktop plus tablet or mobile are, or will be, captured. If one is chosen and that turns out false, use `--frame`.

## Workflow

1. Run:

   ```bash
   node ${CLAUDE_PLUGIN_ROOT}/lib/screenshot-forge/scripts/capture.mjs <url | --list urls.txt> [options]
   ```

   A URL takes 5–10 s; a failing one over 60 s; the first run may download a browser. Run lists of more than 10 URLs in the background; when it finishes, continue with step 2 using its stdout, stderr and exit code.
2. Read the result. Stdout has one absolute path per PNG written, including frames.
   - Exit `0` means all succeeded.
   - Exit `1` means something failed, or Playwright could not run; read stderr before blaming a URL.
   - Exit `2` means nothing ran (bad input or unknown device).
3. View the PNGs with the Read tool, checking for the real page:
   - Lists: view the first 5 URLs only, and say the rest were not checked.
   - Full-page images (`-full.png`) can be too tall to view. Rerun without `-f`, only for the URLs being viewed, with `-o` set to a scratchpad folder, and view those. Do not report them.
   - Blank or half-loaded: rerun that URL once with a higher `-w` (e.g. `5000`), or `-s` with a main-content selector.
   - Cookie wall, login or bot challenge: tell the user; the script cannot dismiss them.
4. Report absolute paths. For a list, report:
   - the output directory and a count
   - every failed URL with its error
   - every `Skipping` line
5. **Offer frames.** Only when intake did not settle them and a capture succeeded:
   - Ask **Frame choice**.
   - Rerun the exact same command with `--frames-only` plus the chosen flags. It reuses the captures and takes seconds.
   - `[frame] no <view> capture` for an already-failed URL is expected; do not report it again.
   - View `<name>-combo.png`, or else one `-framed.png`, then report the new paths.

## References

Load only when needed:
- **`references/options.md`**: every flag, filenames, lists, frames, exit codes, examples. Read it for flags not in the table above.
- **`references/devices.md`**: browser per device, download sizes, Linux libraries. Read it for any non-default device.
- **`references/troubleshooting.md`**: errors and fixes. Read it on a non-zero exit, or when an image looks wrong.
