# Helpers and assertion techniques

## Appendix A: the shared helpers module

One module, `tests/e2e/support/app.js`, holding at least:

- `signIn(page, options?)` and `signOut(page)` driving the real forms. No cached
  `storageState` unless logging in is slow — a cache is one more thing to invalidate.
- `field(scope, name)` — `[name="…"]:not([type="hidden"])`, so a checkbox paired with a
  hidden `false` partner still resolves to one element
- `uniqueName(prefix)` / `uniqueSlug()`
- `paint(page, locator, points)` — scroll into view, then press, move through the points
  in fractions of the element's box, release
- `dragHandle` / `dragBox` for resizable regions
- `resetStub`, `armStubFailure`, `stubRequests`, taking the stub's URL from
  `support/ports.js`
- `downloadTo(page, action)` wrapping `waitForEvent("download")`
- a finder for whatever the app's main card or row is, keyed on a stable attribute

## Appendix B: assertion techniques by journey type

- **Canvas work:** read pixels back with `page.evaluate` and `getImageData`, counting what
  changed. Never screenshot comparisons — no snapshot files to churn when a colour moves.
- **"Without a reload":** set a value on `window`, do the thing, check the value survived.
- **Public pages:** open them in `browser.newContext()` so there is no session, and assert
  both what a stranger sees and what they do not.
- **Zips:** if the app already depends on a zip library, require it in the spec and list
  the entries; otherwise check the first two bytes are `PK`.
- **Drag and drop of files:** build a `DataTransfer` inside `page.evaluate` and dispatch
  `drop` on the element that actually carries the listener — often an inner zone rather
  than the outer field.
- **Clipboard:** grant `clipboard-read`/`clipboard-write` in `use.permissions` and read it
  back with `navigator.clipboard.readText()`.
