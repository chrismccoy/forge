# Known pitfalls

Most of these cost a debugging cycle; the rest guard against losing data or money. None
is hypothetical.

- **`webServer` starts before `globalSetup`.** If the seed runs in `globalSetup`, the app
  boots against a database that does not exist yet and the run dies before the first test.
  Run the seed as part of the server command itself — the launcher below runs the seed,
  then the server — and skip `globalSetup` altogether.

- **The app's own `.env` leaks into the run.** `dotenv` does not overwrite a variable that
  is already set, so anything you leave out of `appEnv` is whatever the app's `.env`
  happens to say. Name every variable a spec depends on, including the feature switches,
  explicitly.

- **A real key can reach the app by a name you did not override.** The SDK reads its own
  default variables (an `OPENAI_API_KEY` / `OPENAI_BASE_URL` pair, for instance) as well as
  whatever the app passes it, and both the developer's shell and the app's `.env` may set
  them. If the base URL slips through, the suite makes real, paid calls and still passes.
  So the app's environment is built from a short allow list rather than a copy of
  `process.env`, and the SDK's default key and base-URL variables are set to fake values
  explicitly — a set variable is one `dotenv` will not fill from `.env`.

- **`webServer.env` does not replace the environment; it adds to it.** Playwright starts
  each server with `{ ...process.env, ...webServer.env }`, so an allow list passed there
  filters nothing and every variable in the developer's shell still reaches the app. The
  app therefore starts through a small launcher (see *Configuration*) that spawns the seed
  and the server with exactly the environment it is handed. Confirm the merge in the
  installed version (`node_modules/playwright/lib/plugins/webServerPlugin.js`) and note
  what you find in the report. Keep the launcher either way: if a later release stops
  merging, it costs nothing.

- **A reused server skips the seed.** With `reuseExistingServer: true`, Playwright sees
  something already answering on the port and never runs the command — so the seed never
  runs and the suite meets whatever the last run left behind. The app server is never
  reused; if the port is busy, the run fails loudly instead.

- **Rate limits will stop the suite.** A spec that signs in per test will pass the login
  limiter in the first few files and then fail everywhere for a reason that has nothing to
  do with the journey. Lift the limits in the run's environment. The Playwright server
  cannot test a limit it has lifted, so cover the limiters with the project's existing
  test runner instead: mount the app (or just the limited route) in-process with the
  limit set low, and assert that the request after the limit is refused. If the limit is
  not configurable yet, add the variable the same way as the data paths.

- **The SDK retries a 500.** If the fake upstream is armed to fail once and the client
  retries, the retry succeeds and the failure journey never happens. Use a status the
  client does not retry — 400 — for "the service refused this".

- **A hidden control cannot be clicked.** Tailwind toggle switches are usually an
  `sr-only` checkbox behind a styled label, and a plain `check()` lands on the decoration
  and times out. Use `setChecked(value, { force: true })`.

- **Clicking a control in a side column scrolls the canvas away.** A stroke aimed at an
  element whose box is off screen fires no pointer events at all and paints nothing, with
  no error. Any helper that drives the mouse should call `scrollIntoViewIfNeeded()` before
  it measures the element.

- **Dragging inside a crop box moves it rather than redrawing it.** If the box starts as
  the whole image, the only way to make it smaller is to drag one of its handles.

- **Two fixtures that share a name are one fixture.** If two seeded records carry the same
  prompt, title or filename, every `.first()` in the suite silently picks whichever the
  ordering happens to put first — and a crop or an edit that inherits its source's text
  creates the same ambiguity halfway through the run. Give every fixture distinct text,
  and where a derived record copies it, pin the locator with a second attribute such as
  the size.

- **A mask canvas is often the negative of what was painted.** Check the compositing
  before writing the assertion: if the overlay is filled and the strokes punch holes in it,
  a "painted" pixel is a transparent one.

- **A value in an `<input>` is not text on the page.** `getByText` will not find a
  category or collection name that lives in a rename box. Locate the row by
  `input[name="name"][value="…"]`.

- **A grid card may not print the text a list row does.** Find a card by an attribute the
  markup already carries — the prompt on its "show" button, for instance — rather than by
  text that only one of the two views renders.

- **A form that redirects on success shows no summary.** Check where the controller sends
  a clean submission before asserting on a report page that only appears when something
  was refused.

- **Assert the behaviour, not the README.** If the docs say a preference is kept in
  `localStorage` and the code keeps it in a settings row, test the settings row. Note the
  discrepancy for the human.

