# Scene File API

`record.js` runs a scene file: an ES module whose default export describes the video. The scene file must not import anything. Everything it needs is passed to each scene. Keep the scene file in the workspace: it loads as an ES module only through the workspace's `package.json` (`"type": "module"`).

## Contents

1. Scene file format
2. Scene context
3. `demo` helpers
4. Locators
5. Patterns
6. Scripts, flags and outputs
7. Troubleshooting

## 1. Scene file format

```js
// <plugin-slug>.scenes.js. The @type line gives editors hints from record.js's JSDoc.
/** @type {import('./record.js').SceneConfig} */
export default {
  name: 'my-plugin-demo', // video file name: output/my-plugin-demo.mp4 (default "demo"). Use '<plugin-slug>-demo'.
  // viewport and outputSize need even numbers (H.264 requires it).
  viewport: { width: 1920, height: 1080 }, // browser size (default 1920×1080)
  outputSize: { width: 1920, height: 1080 }, // final video size, upscaled from viewport (default: viewport)
  timeout: 20_000, // default timeout for each Playwright action and demo.waitFor, ms
  pace: 1, // pause multiplier: 1 = normal, 1.5 = slower, 0.5 = faster
  scenes: [
    {
      name: 'settings',
      async run({ page, demo, log, base, url }) {
        await demo.open('admin.php?page=my-plugin-settings');
        // ...
      },
    },
  ],
};
```

Every scene needs a `name` (lower-case letters, digits and hyphens) and an async `run` function. The video `name` follows the same rule. Keep inputs (search terms, titles) as constants at the top of the file, so they are easy to change before recording again. Scenes run in order in one browser tab, so a scene starts where the previous one ended.

## 2. Scene context

| Name | Type | Description |
| --- | --- | --- |
| `page` | Playwright `Page` | Full Playwright API for anything the helpers do not cover. |
| `demo` | object | Viewer-friendly actions with logging (see below). |
| `log(message)` | function | Prints a line with the video timestamp and scene name. |
| `base` | string | Site URL without a trailing slash, from `WP_URL`. |
| `url(path)` | function | Turns an admin path into a full URL, the same way `demo.open` does. |

## 3. `demo` helpers

All helpers log what they do. Pauses scale with `pace` and are removed by `--fast`.

| Helper | What it does |
| --- | --- |
| `demo.open(path, { write = false })` | Navigates. Refuses URLs that match data-changing patterns (`post-new.php`, nonces, `action=` other than `edit`, parameter names or values such as `delete` or `trash`) unless `write: true` is passed in an approved writing scene. `path` can be `admin.php?page=x` (resolved under `/wp-admin/`), `/wp-admin/edit.php`, a site path such as `wp-login.php`, or a full URL. For front-end pages, pass a full URL such as `` `${base}/sample-page/` ``: every other relative path is treated as an admin path. |
| `demo.click(locator, label?)` | Glides the cursor to the element, clicks and pauses. `label` is the text for the log; default is the locator's string form. |
| `demo.type(locator, text, { label?, delay = 70, replace = false, secret = false })` | Clicks the field, then types each character. `replace: true` selects the existing value first, so the typing overwrites it. `secret: true` logs `type [secret, not logged]` instead of the text. Use `\n` for new lines in text areas. |
| `demo.select(locator, value, label?)` | Chooses an option in a `<select>`. |
| `demo.hover(locator, label?, ms = 1200)` | Moves the cursor to an element and holds there. Use it to point at a result. |
| `demo.glide(locator)` | Moves the cursor only, without logging. |
| `demo.scroll(dy, steps = 30)` | Smooth wheel scroll by `dy` pixels; negative scrolls up. |
| `demo.waitFor(locator, what, { timeout, state = 'visible' })` | Logs `waiting for <what> (up to Ns)` and then waits. Use for every wait longer than a second, so a stalled run shows what it is waiting for. |
| `demo.pause(ms)` | Holds still, so viewers can read. |

For actions the helpers do not cover (key presses, drag and drop, file upload), use `page` or the locator directly, and call `log()` first.

## 4. Locators

Use the first option that works, in this order:

1. **Role and accessible name:** `page.getByRole('button', { name: 'Test key' })`. Readable and survives markup changes.
2. **Label:** `page.getByLabel('API key')` for form fields with a `<label>` or `aria-label`.
3. **ID from the source:** `page.locator('#ytbi_test_key')`. Stable when the plugin defines it. Prefer it when the visible text is translated or changes with state.
4. **Plugin classes and data attributes:** `page.locator('#results .card[data-state="idle"]')` for repeated items.
5. **Never** use generated class names, `nth-child` chains or WordPress layout classes that change between versions.

Scope locators to the area they belong to:

- Admin menu: `page.locator('#adminmenu').getByRole('link', { name: 'Settings' })`. There can be several "Settings" links on one page.
- Dialogs: `const dialog = page.locator('#my-dialog'); dialog.getByRole('button', { name: 'Done' })`.
- One item in a list: keep a locator to the item (for example by `data-id`) and find its buttons inside it.

`inspect-page.js` prints a suggested locator for every visible control.

## 5. Patterns

**Wait for an async result and show it.**

```js
await demo.click(page.getByRole('button', { name: 'Test key' }), 'Test key');
const result = page.locator('#test_result').filter({ hasText: /\S/ });
await demo.waitFor(result, 'key test result');
log(`key test result: ${(await result.innerText()).trim()}`);
await demo.pause(2000);
```

**Wait until a control is enabled** (for example after a bootstrap request):

```js
// `disabled: false` makes the locator match only once the button is enabled.
const search = page.getByRole('button', { name: 'Search', disabled: false });
await demo.waitFor(search, 'Search to be enabled');
```

**Pick an item that is still unused**, so a re-run does not stall on an item finished in an earlier run:

```js
const card = page.locator('#results .card[data-state="idle"]').first();
const id = await card.getAttribute('data-id');
const target = page.locator(`#results .card[data-id="${id}"]`); // stays valid after the state changes
log(`picked item ${id}`);
```

**Fields that may be hidden by plugin settings.** Guard them, and log the skip so the final report can mention it:

```js
const tags = dialog.locator('.tags');
if (await tags.isVisible()) {
  await demo.type(tags, ', demo', { label: 'tags field' });
} else {
  log('tags field hidden, skipped');
}
```

**Wait for an endpoint instead of the DOM**, when the page gives no clear signal:

```js
const done = page.waitForResponse((r) => r.url().includes('/wp-json/myplugin/v1/import') && r.ok(), {
  timeout: 60_000,
});
await demo.click(page.getByRole('button', { name: 'Import selected' }), 'Import selected');
log('waiting for import request (up to 60s)');
await done;
```

Start `waitForResponse` before the click, or a fast response can be missed.

**Combine a locator with a state:** `await demo.waitFor(target.and(page.locator('[data-state="done"]')), 'import to finish', { timeout: 60_000 })`.

**Long jobs.** Give `demo.waitFor` a timeout that fits the job. Do not raise the global `timeout` for one slow step.

**Admin notices after a reload.** WordPress shows notices such as "Settings saved." at the top of `.wrap`. Wait for `page.locator('.notice')` with the expected text.

## 6. Scripts, flags and outputs

Run every script from the workspace. Quote paths as described in `setup.md` section 1.

### `record.js`

```sh
node --env-file=.env record.js <scenes file> [flags]
```

| Flag | Effect |
| --- | --- |
| `--fast` | No video, no pauses, instant mouse moves. Use it to check selectors in seconds. Side effects still happen. `--split` is ignored. |
| `--only a,b` | Run only these scenes; names are comma-separated without spaces. Needs `--fast`, or `--out <dir>` for a partial recording, so a partial video never replaces the full one. Fails with a plain message on an unknown name. A scene that continues another one fails when run alone. |
| `--split` | Also cut one MP4 per scene into `<out>/scenes/NN-<scene>.mp4`, with 0.3 s padding. `NN` is the scene's position in the scene file, also with `--only`. |
| `--verbose` | Forward browser console messages and page errors to the log, and print stack traces on failure. The browser console can contain the plugin's localized config, including nonces or keys. |
| `--out dir` | Output directory (default `output`). |

Scene names must match `^[a-z0-9][a-z0-9-]*$`, because they become file names.

Outputs:

- `<out>/<name>.mp4`, where `<name>` is the scene file's `name`. It starts at the first page load, so it has no blank frames.
- `<out>/scenes.json`: each scene's start and end, in ms from the start of the MP4.
- `<out>/raw/*.webm`: the raw recording, which starts with a blank page.
- `<out>/failure.png`: on failure only. Secret-looking field values are blanked first, as in `inspect-page.js`.

Each run deletes `failure.png` first. Each recording run (not `--fast`) also deletes the previous MP4, `scenes.json`, `raw/`, `scenes/` and contact sheets named `contact-sheet.png` or `sheet-NN.png`, so a failed run leaves nothing stale. The clips are cut from the raw WebM, so they are compressed once.

Log format: `[mm:ss.s] <scene> <message>`. The time is the offset into the MP4, so a log line points to the moment in the video. Lines before recording starts show `--:--.-`; lines before the first page has loaded show `00:00.0`.

### `check-env.js`

```sh
node --env-file=.env check-env.js [--site]
```

Prints one `ok` or `FAIL` line each for `node`, `.env`, `ffmpeg`, `chromium` (it starts the browser), `site` (the HTTP status of the login page; only 200 passes) and, without `--site`, `login` (logs in once, as `record.js` does). The `.env` line names the keys that are set or missing, never their values. A `note` line, which does not fail the run, says when `.env` is readable by other users. With `--site`, only `WP_URL` is required. Exits with 1 when any check fails. A failed `site` line says what to add to `.env` for status 401 and 404 and for certificate errors.

### `scan-plugin.js`

```sh
node scan-plugin.js "<plugin dir>" [--include-tests] [--include-build]
```

Scans `.php`, `.js`, `.jsx`, `.ts`, `.tsx` and `.json` files. Skips symlinks, `vendor/`, `node_modules/`, `.git/`, `languages/`, `dist/`, `tests/`, `test/`, `build/`, `*.min.js`, and JS or TS files with a line longer than 1,000 characters (minified code); files skipped as minified are listed at the end. PHP files are never skipped for long lines, because plugins often pass `add_menu_page()` a long inline base64 icon. The plugin header is read the way WordPress reads it, from root files first. `--include-tests` scans `tests/` and `test/`, which can hold sample API responses and golden HTML. `--include-build` scans `build/`, for plugins whose `block.json` files exist only there. The output sections are described in `plugin-analysis.md`.

### `inspect-page.js`

```sh
node --env-file=.env inspect-page.js [--menu] [--out dir] ['admin path' ...]
```

| Flag | Effect |
| --- | --- |
| `--menu` | Print every admin menu entry with its URL, including submenus. Counters such as update badges are removed. |
| `--out dir` | Where to save files (default `output/inspect`). |

For each admin path it prints the URL with its HTTP status, the page heading, visible notices, and every visible control with its type, text, ID, name and a suggested locator. Suggestions use `getByRole` for buttons, links and tabs, `getByLabel` for labelled fields, `getByPlaceholder` or `getByTitle` when a field has only that text, and an escaped `#id` otherwise.

It saves `<out>/<path-slug>-<hash>.aria.yml` (accessibility snapshot) and `<out>/<path-slug>-<hash>.png` (full-page screenshot). The short hash keeps paths that differ only in punctuation apart. Long pages make tall screenshots that are scaled down when viewed; read the `.aria.yml` file for text.

Before saving, it replaces the values of password fields and fields whose ID, name or label looks like a key, token, secret, password, licence or credential with `[redacted]`. This changes only the browser tab, never the site. Secrets shown as plain text elsewhere on the page are not redacted.

It skips URLs that match common data-changing patterns, using the same rule as `demo.open` (see `isUnsafeUrl` in `wp.js`). This is a heuristic, not a guarantee.

When WordPress refuses a page (HTTP 400 or above, or its "Sorry, you are not allowed to access this page." error page), it prints a `Refused:` line and saves nothing for that path. `demo.open` fails with the same message.

### `contact-sheet.js`

```sh
node contact-sheet.js <video> [output.png] [cols] [rows] [tileWidth]
```

The video is required; columns, rows and tile width must be whole numbers above 0. Defaults: `output/contact-sheet.png`, 3 columns, 3 rows, 512 px tiles (about 1536 px wide). Frames are spaced evenly over the whole video. For reading text in one scene, use `2 2 960` on that scene's clip.

### Environment variables

| Variable | Effect |
| --- | --- |
| `WP_URL`, `WP_USER`, `WP_PASS` | Site and login. Required (only `WP_URL` for `check-env.js --site`). Put values in single quotes: unquoted, Node.js cuts a value at `#`. |
| `WP_LOGIN_PATH` | Login page path when a security plugin moves it, for example `my-login`. Default `wp-login.php`. |
| `WP_HTTP_USER`, `WP_HTTP_PASS` | HTTP basic auth in front of the site, common on staging sites. |
| `WP_IGNORE_HTTPS_ERRORS=1` | Accept self-signed certificates. Only for local development sites. |

Every login adds a session token to the user's account (WordPress user meta). This is normal WordPress behaviour and expires on its own, but it means no run is completely free of writes.

## 7. Troubleshooting

| Symptom | Cause and fix |
| --- | --- |
| `Login failed: <WordPress error>` | Wrong credentials. Ask the user to check `WP_USER` and `WP_PASS` in `.env`, and that the values are in single quotes (unquoted, a password is cut at `#`). |
| `WordPress login form not found at /...` | The login page is elsewhere or is not the WordPress form. Set `WP_LOGIN_PATH`, or check `WP_URL`. |
| `Login failed (no redirect to /wp-admin/)` | Two-factor authentication, a CAPTCHA, a redirect plugin, or a custom login page that is not the WordPress form. Use a demo account without 2FA, or set `WP_LOGIN_PATH`. |
| `Login stopped at the "Administration email verification" screen` | See `plugin-analysis.md` section 9. |
| `WordPress refused <path> (HTTP ...)` | The plugin is inactive (its page slug does not exist), or the user lacks the capability. Check `plugins.php` with `inspect-page.js`. Never activate the plugin; ask the user. |
| `Refusing to open <url>` | The URL matches a data-changing pattern. Use a page URL from the admin menu, or pass `{ write: true }` in an approved writing scene. |
| `Scene name "..."` or `Video name "..." must use only lower-case letters...` | Rename it, for example `import-video`. |
| `viewport ... must have even width and height` | Use even numbers, such as 1280×720. |
| `--only records a partial video` | Add `--fast`, or `--out <dir>` to keep the partial video apart from the full one. |
| `FAILED: locator.scrollIntoViewIfNeeded: Timeout ...` (or another locator action) after `click X`, `hover X` or `type X` | The locator matched nothing. Run `inspect-page.js` on that screen and compare. Look at `failure.png`. |
| `strict mode violation: ... resolved to N elements` | The locator matches several elements. Scope it (menu, dialog, item) or add `.first()` when any match will do. |
| Waits forever for a result | The UI needs a precondition: an API key, a bootstrap request, a non-empty list. Run with `--verbose` to see browser errors. |
| Cursor missing in the video | A page replaced `document.documentElement`. Rare; reload with `demo.open`. |
| Video picture fills only part of the frame | `deviceScaleFactor` was set. Use `viewport` plus `outputSize` instead. |
