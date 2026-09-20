# The test rig

The Playwright config, the ports module, the launcher, the fake upstream, the seed data,
and the npm scripts. Read `pitfalls.md` first - most of what follows only makes sense
against it.

## Configuration

```js
// playwright.config.js — CommonJS shown; convert if the repo is ESM.
"use strict";

const path = require("path");
const { defineConfig, devices } = require("@playwright/test");
// Shared with the helpers, so a spec and the config can never disagree about a port.
const { appPort, stubPort, baseURL, stubURL } = require("./tests/e2e/support/ports");

const ROOT = __dirname;
const E2E_DIR = path.join(ROOT, "var", "e2e");

// Only what a Node process needs to start. Never spread process.env: the developer's
// shell may hold real API keys under names this file does not override. Playwright
// merges process.env into webServer.env regardless, so this list only takes effect
// because the app is started through tests/e2e/launch-app.js (below).
const INHERIT = [
  "PATH", "HOME", "LANG", "TMPDIR",                                     // POSIX
  "PATHEXT", "ComSpec", "SystemRoot", "USERPROFILE", "TEMP", "TMP",     // Windows
];
const baseEnv = Object.fromEntries(
  INHERIT.filter((key) => process.env[key] !== undefined).map((key) => [key, process.env[key]]),
);

// Every variable name below is a placeholder. Replace each with the name the app
// actually reads (see its config module and .env.example), and drop any it lacks.
const appEnv = {
  ...baseEnv,
  NODE_ENV: "test",
  PORT: appPort,

  // Credentials, throwaway. Never values used anywhere real.
  ADMIN_USERNAME: "admin",
  ADMIN_PASSWORD: "e2e-password",
  SESSION_SECRET: "e2e-session-secret-value-at-least-32-chars",

  // The throwaway install.
  APP_DB: path.join(E2E_DIR, "e2e.db"),
  APP_UPLOADS: path.join(E2E_DIR, "uploads"),

  // The fake upstream. Match the path suffix to what the SDK expects: some SDKs add
  // `/v1` themselves, and a doubled `/v1/v1/…` makes every stub route answer 404.
  UPSTREAM_API_KEY: "e2e-test-key",
  UPSTREAM_BASE_URL: `${stubURL}/v1`,
  // The SDK's own default names, set so neither the shell nor .env can supply them.
  SDK_DEFAULT_API_KEY: "e2e-test-key",
  SDK_DEFAULT_BASE_URL: `${stubURL}/v1`,

  // Everything the developer's .env might otherwise decide.
  // Check what an empty allow list means in this app (everyone, or no one) and pick
  // the value that lets 127.0.0.1 in.
  ALLOWED_IPS: "",
  FEATURE_FLAG_A: "true",

  // The suite works far faster than a person; the limits are not what it tests.
  // One entry per limiter the app has (login, API, uploads, …), not just this one.
  RATE_LIMIT_LOGIN_MAX: "100000",
};

module.exports = defineConfig({
  testDir: path.join(ROOT, "tests", "e2e"),
  // Playwright's default also collects *.test.js. Name the suffix explicitly, and pick
  // one the existing runner does not collect (see *Scripts*).
  testMatch: "**/*.spec.js",
  timeout: 45_000,
  expect: { timeout: 10_000 },

  // One database file and one stub process are shared, so the specs run in order.
  fullyParallel: false,
  workers: 1,
  // No retries: a retry runs against a database the failed attempt already changed,
  // so it cannot tell a flake from a real failure.
  retries: 0,
  forbidOnly: Boolean(process.env.CI),
  reporter: process.env.CI ? [["list"], ["html", { open: "never" }]] : [["list"]],

  use: {
    baseURL,
    trace: "retain-on-failure",
    screenshot: "only-on-failure",
    actionTimeout: 10_000,
    permissions: ["clipboard-read", "clipboard-write"],
  },

  projects: [
    { name: "chromium", use: { ...devices["Desktop Chrome"] } },
    // Needs Google Chrome itself: `npx playwright install chrome` (the bundled
    // Chromium comes from `npx playwright install chromium`).
    { name: "chrome", use: { ...devices["Desktop Chrome"], channel: "chrome" } },
    // Never run both projects in one invocation: the database is seeded once per run,
    // so the second project would meet data the first one changed (and the 99- file
    // destroyed). The npm scripts select one project each; each run re-seeds.
  ],

  webServer: [
    {
      command: "node tests/e2e/stub-server.js",
      url: `${stubURL}/__stub/health`,
      env: { ...baseEnv, E2E_STUB_PORT: stubPort },
      cwd: ROOT,
      // Never reuse: a stub left over from another checkout may answer with an old shape.
      reuseExistingServer: false,
      timeout: 30_000,
      stdout: "pipe",
      stderr: "pipe",
    },
    {
      // The launcher runs the seed, then the server, because Playwright starts its
      // servers before globalSetup and the app will not boot without its database.
      // It also gives both exactly appEnv, which webServer.env alone cannot do.
      command: "node tests/e2e/launch-app.js",
      url: `${baseURL}/health`,
      env: { E2E_APP_ENV: JSON.stringify(appEnv) },
      cwd: ROOT,
      // Never reuse: a reused server means the seed above did not run.
      reuseExistingServer: false,
      timeout: 60_000,
      stdout: "pipe",
      stderr: "pipe",
    },
  ],
});
```

```js
// tests/e2e/support/ports.js — the one place ports and URLs are decided. Required by
// the config and by the helpers (resetStub, stubRequests, …).
"use strict";

const appPort = process.env.E2E_PORT ?? "3200";      // away from the dev server
const stubPort = process.env.E2E_STUB_PORT ?? "3199";

module.exports = {
  appPort,
  stubPort,
  baseURL: `http://127.0.0.1:${appPort}`,
  stubURL: `http://127.0.0.1:${stubPort}`,
};
```

The launcher is what makes the allow list real:

```js
// tests/e2e/launch-app.js — Playwright merges process.env into webServer.env, so the
// only way to give the seed and the app an exact environment is to spawn them with one.
"use strict";

const path = require("path");
const { spawn, spawnSync } = require("child_process");

const ROOT = path.join(__dirname, "..", "..");
if (!process.env.E2E_APP_ENV) {
  console.error("launch-app.js: E2E_APP_ENV is not set; start it through playwright test.");
  process.exit(2);
}
const env = JSON.parse(process.env.E2E_APP_ENV);

const seed = spawnSync(process.execPath, ["scripts/seed-e2e.js"], {
  cwd: ROOT, env, stdio: "inherit",
});
if (seed.status !== 0) process.exit(seed.status ?? 1);

const app = spawn(process.execPath, ["server.js"], { cwd: ROOT, env, stdio: "inherit" });
for (const signal of ["SIGINT", "SIGTERM"]) {
  process.on(signal, () => app.kill(signal));
}
app.on("exit", (code, signal) => process.exit(code ?? (signal ? 1 : 0)));
```

Give it a test with the existing runner. The launcher always starts the real seed and
server, so copy `launch-app.js` into a temporary directory as `tests/e2e/launch-app.js`,
next to a stand-in `scripts/seed-e2e.js` that exits 0 and a stand-in `server.js` that
prints its environment and exits. (The launcher finds its root from its own location,
so the copy runs the stand-ins.) Run it with a variable set in the parent process that
is not in `E2E_APP_ENV`, and assert the output shows the listed variables and not that
one. Add a case where the stand-in seed exits non-zero and assert the stand-in server
never starts.

If the app has no cheap readiness route, add one: a `GET /health` returning
`{"ok":true}`, mounted before the IP allow list and before the session check, saying
nothing about the install. It is a real feature, not a test hook — a reverse proxy wants
it too.

## Fake upstream

Build it as a module exporting `createStub({ fixturesDir })` that returns `{ handler,
requests, reset, failNext }`, and a thin `stub-server.js` that listens. Test the stub
itself with the project's existing test runner: if it answers with the wrong shape, every
journey fails for a reason that is not the app's.

Give it control routes the specs drive it with:

- `POST /__stub/fail-next` — arm one failure, optionally aimed at a single upstream model
  or endpoint, so a partial-failure journey can be tested
- `GET /__stub/requests` — the log, which is what makes negative assertions possible
  ("this action asked the upstream for nothing at all")
- `POST /__stub/reset` — clear both, called in `beforeEach` by any spec that uses them
- `GET /__stub/health` — the readiness URL

**Record the upstream's real response shape rather than inventing it.** Write a hand-run
script that makes the cheapest possible calls with a real key and saves each reply as an
*envelope* — status, headers and body, with the payload bytes replaced by a placeholder —
so nothing but the shape is committed. The nesting inside something like a `usage` block
is exactly what a hand-built stub gets subtly wrong, and what the application reads. Ask
the human before spending their money, and never print or commit the key.

## Seed data

Two files: constants, and the script that inserts them.

```
tests/e2e/support/seed.js   // what the fixtures are, imported by the seed AND the specs
scripts/seed-e2e.js         // wipe, rebuild schema, insert, copy fixture files
```

A spec must never repeat a seeded literal — it imports the constant, so a fixture that
changes fails in one place instead of drifting. Timestamps come from one clock captured at
the top of the seed, so "three days ago" does not move mid-run.

Seed enough that the interesting states already exist: something favourited, something
shared, something in a collection, something in the trash, a record with variables in its
text, a record with a note, prices or settings that make derived figures render.

Because the install is wiped and rebuilt at the start of every run, early specs may assert
exact counts. Later ones cannot: by then earlier specs have added records. Write those
assertions about specific records, or about a delta the spec measures itself. Any spec
that mutates seeded data puts it back, and anything genuinely destructive runs last in its
own file with a comment saying why.

Order is set by file name. With one worker and `fullyParallel: false`, Playwright runs spec
files in alphabetical order, so give every spec a two-digit prefix — `01-smoke.spec.js`,
`02-auth.spec.js`, … — and put the destructive file at `99-…`. Do not rely on the order in
which the files were written.

## Scripts

```json
"test:e2e": "playwright test --project=chromium",
"test:e2e:chrome": "playwright test --project=chrome",
"test:e2e:headed": "playwright test --project=chromium --headed",
"test:e2e:ui": "playwright test --ui",
"seed:e2e": "node scripts/seed-e2e.js"
```

Each script selects exactly one project, so every run gets its own fresh seed (see the
comment on `projects` in the config). `test:e2e:ui` is the exception: pick one project in
the UI. UI mode also starts the servers, and so seeds, only once per session: a second
run inside the UI meets the data the first one changed, so restart the UI to re-seed.
Never run `seed:e2e` while a suite is running — it deletes the database file under the
live server.

`seed:e2e` runs outside Playwright's environment, which is why the seed has its own
`var/e2e` defaults and its own path guard.

Leave the existing `test` script exactly as it is, and make sure neither runner can
collect the other's files. Neither side is safe by default: Playwright's default
`testMatch` collects `*.test.js` as well as `*.spec.js`, and Jest and Vitest both collect
`*.spec.js`. So:

- Read the existing runner's actual file pattern (its config, or its default if it has
  none) before choosing a suffix. If it does not match `*.spec.js`, use that; otherwise
  use one it does not match, such as `*.e2e.js`, and set Playwright's `testMatch` to it.
- Keep the tests you write for the existing runner — the path guard, the launcher, the
  stub, the rate limits — out of `tests/e2e/`, in the directory that runner already
  collects from.
- After step 2, run the existing suite and confirm its test count did not change except
  by the tests you added for it.

Add `var/`, `test-results/` and `playwright-report/` to `.gitignore`.

