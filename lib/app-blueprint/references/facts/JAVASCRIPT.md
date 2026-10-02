# JAVASCRIPT facts
Covers: Express, Fastify, React and Vue SPAs (Vite), Node.js services, workers and CLIs, npm packages, BullMQ, Socket.IO, Electron
Verified: 2026-09-29 against official documentation. Re-verify facts older than 12 months.

## Express and Fastify

### JS-01 Express 4 vs 5
- Trap: `async` handlers on Express 4 with no try/catch; v4 route syntax (`/*`, `:id?`, regex) on v5.
- Reality: npm `latest` is v5 since 2025-03-31; v4 is in maintenance (EOL no sooner than 2026-10-01). v4 ignores rejected promises (request hangs, process may die, JS-07); v5 routes them to error middleware. v5 wildcards need names (`/*splat`), `:ext?` becomes `{.:ext}`, regex characters are gone, `req.body` is `undefined` without a parser, `req.query` is read-only.
- Detect: no Express major; async handlers on v4; `app.get('*')`.
- Fix: Use v5; on v4 `.catch(next)` every async handler.
- Source: Migrating to Express 5 - https://expressjs.com/en/guide/migrating-5.html ; Express 5.1 LTS - https://expressjs.com/en/blog/2025-03-31-v5-1-latest-release/

### JS-02 Webhook routes need the raw body
- Trap: `app.use(express.json())` globally, then verify a Stripe/GitHub signature (SVC-04).
- Reality: The JSON parser consumes the stream, and re-serialized JSON does not match the signed bytes. `express.raw()` defaults to `type: 'application/octet-stream'`, so it skips JSON webhooks. Fastify parsers are per scope (`addContentTypeParser`, `parseAs: 'buffer'`).
- Detect: global JSON parser plus signature checks; `JSON.stringify(req.body)` in HMAC code.
- Fix: `express.raw({ type: 'application/json' })` on the webhook route, before `express.json()`; in Fastify a buffer parser in the webhook plugin.
- Source: Express API - https://expressjs.com/en/5x/api.html ; Content-Type Parser - https://fastify.dev/docs/latest/Reference/ContentTypeParser/

### JS-03 Proxies and sessions
- Trap: Behind a load balancer `req.ip` is the client and `secure` cookies work; default session store in production.
- Reality: Express `trust proxy` and Fastify `trustProxy` default off: `req.ip` is the proxy (one rate-limit bucket for all) and `req.protocol` is `http`, so express-session omits `secure` cookies. `true` trusts spoofable `X-Forwarded-For`. The default MemoryStore leaks memory and is single-process.
- Detect: IP rate limits, `cookie.secure` or IP logs with no proxy setting; express-session with no store.
- Fix: Set trust proxy to the hop count; use a Redis or Postgres session store.
- Source: Express behind proxies - https://expressjs.com/en/guide/behind-proxies.html ; express-session - https://expressjs.com/en/resources/middleware/session.html

### JS-04 Fastify plugins are encapsulated
- Trap: A plugin registers auth hooks, decorators or DB clients for the whole app.
- Reality: Each `register` makes a child context; its decorators, hooks and parsers are invisible to parent and siblings unless wrapped in `fastify-plugin` (which frees only that plugin).
- Detect: `app.register(authPlugin)`, then other routes expect `request.user` or `app.db`.
- Fix: Wrap shared plugins with `fastify-plugin`; register routes inside the scope whose hooks must apply.
- Source: Encapsulation - https://fastify.dev/docs/latest/Reference/Encapsulation/

### JS-05 Fastify response schemas filter output
- Trap: A response schema only documents or validates the reply.
- Reality: fast-json-stringify drops properties not declared in the schema and throws if a `required` one is missing.
- Detect: response schemas plus later-added or free-form fields.
- Fix: Declare every returned field; use the filter to hide secrets.
- Source: fast-json-stringify - https://github.com/fastify/fast-json-stringify

### JS-06 Fastify listens on localhost only
- Trap: `fastify.listen({ port })` in a container or on Fly/Render.
- Reality: The default host is `localhost`; Docker-mapped ports and platform proxies cannot reach it.
- Detect: Dockerfile or PaaS deploy with no `host` in `listen`.
- Fix: `listen({ port: Number(process.env.PORT), host: '0.0.0.0' })`.
- Source: Server - https://fastify.dev/docs/latest/Reference/Server/

## Node.js runtime

### JS-07 Unhandled rejections and exceptions kill the process
- Trap: Floating promises are harmless; an `uncaughtException` handler that logs and continues keeps the server up.
- Reality: Since Node 15 the default `--unhandled-rejections=throw` ends the process. After `uncaughtException` the app is in an undefined state; docs say only clean up and exit.
- Detect: fire-and-forget `async` calls; log-and-continue handlers; no restart policy.
- Fix: Await or `.catch` every promise; log and exit on fatal errors; run under a supervisor that restarts.
- Source: CLI --unhandled-rejections - https://nodejs.org/api/cli.html ; Process - https://nodejs.org/api/process.html

### JS-08 CPU work blocks every request
- Trap: Image, PDF, big-JSON or hashing work inline in the web or job process.
- Reality: One event loop runs all JavaScript; sync APIs, big `JSON.parse` and catastrophic regexes stall all clients. fs, dns.lookup, pbkdf2/scrypt and zlib share a 4-thread pool (`UV_THREADPOOL_SIZE`).
- Detect: `*Sync` calls or heavy parsing in handlers; user-supplied regexes.
- Fix: CPU work in `worker_threads` or a job worker; bound input sizes.
- Source: Don't Block the Event Loop - https://nodejs.org/en/learn/asynchronous-work/dont-block-the-event-loop

### JS-09 pipe() leaks on error; respect backpressure
- Trap: `src.pipe(transform).pipe(dest)` for ETL, uploads or CSV exports.
- Reality: `pipe()` neither closes the destination nor forwards errors when a source fails. Ignoring `write()` returning `false` buffers without bound.
- Detect: `.pipe` chains; `write()` loops without `drain`.
- Fix: `await pipeline(...)` from `node:stream/promises`; wait for `drain`.
- Source: Stream - https://nodejs.org/api/stream.html

### JS-10 Node release lines and end of life
- Trap: New work on Node 18 or 20; odd-numbered releases in production.
- Reality: 18 ended 2025-04-30, 20 ended 2026-04-30. 22 is maintenance to 2027-04-30; 24 enters maintenance 2026-10-20 (EOL 2028-04-30); 26 becomes LTS 2026-10-28. Odd releases through 25 never become LTS; from 27, one major a year and every major becomes LTS.
- Detect: `node:18`/`node:20` images, engines or Lambda runtimes.
- Fix: Target 24 or 26; pin the image major.
- Source: Node.js releases - https://nodejs.org/en/about/previous-releases ; schedule - https://github.com/nodejs/Release

## Browser SPAs (React, Vue)

### JS-11 Vite env values are public and build-time
- Trap: API keys in `VITE_*`; one built image configured per environment at runtime.
- Reality: Only `VITE_` variables reach client code; they are replaced at build and shipped in public JS (as TS-02).
- Detect: `VITE_*SECRET`/`KEY`; "build once, deploy everywhere" SPAs.
- Fix: Secrets stay behind your API; build per environment or fetch runtime config.
- Source: Env Variables and Modes - https://vite.dev/guide/env-and-mode

### JS-12 StrictMode runs effects twice in development
- Trap: A `useEffect` that POSTs, charges or subscribes "runs once on mount".
- Reality: In development only, StrictMode runs an extra setup+cleanup cycle for every effect.
- Detect: mutations or analytics fired from mount effects.
- Fix: Mutate from event handlers; give effects cleanup and idempotent requests.
- Source: StrictMode - https://react.dev/reference/react/StrictMode

## Modules and npm packages

### JS-13 ESM and CommonJS
- Trap: ESM-only packages (chalk 5+) cannot be `require`d; `__dirname` works in ESM.
- Reality: `.js` is CommonJS unless `"type": "module"`. `require(esm)` works on 20.19+/22.12+ but throws `ERR_REQUIRE_ASYNC_MODULE` on top-level `await` (Lambda: TS-16). ESM has no `__dirname`/`require` (use `import.meta.dirname`, 20.11+) and needs file extensions.
- Detect: mixed `require`/`import` with no `type`; ESM-only deps on old Node.
- Fix: Pick one module system per package; state the minimum Node.
- Source: Modules - https://nodejs.org/api/modules.html ; ESM - https://nodejs.org/api/esm.html

### JS-14 exports and the dual-package hazard
- Trap: Adding `exports` is a non-breaking tidy-up; shipping CJS and ESM builds is always safe.
- Reality: With `exports`, every unlisted subpath (even `pkg/package.json`) throws `ERR_PACKAGE_PATH_NOT_EXPORTED`, a breaking change. A dual package can load twice (once per format), splitting singletons and breaking `instanceof`.
- Detect: deep imports; `import`/`require` conditions to separate stateful builds.
- Fix: List every public subpath and bump the major; ship ESM-only or keep state in one format.
- Source: Packages - https://nodejs.org/api/packages.html ; Dual package hazard - https://nodejs.org/docs/latest-v16.x/api/packages.html#dual-package-hazard

### JS-15 Publishing to npm
- Trap: `npm publish` ships `dist/`; `engines` blocks old Node; a long-lived `NPM_TOKEN` in CI.
- Reality: Without `files` or `.npmignore`, `.gitignore` applies, so a git-ignored `dist/` is left out. `engines` only warns unless `engine-strict`. Classic tokens were revoked Dec 2025; granular write tokens last at most 90 days. Trusted publishing (OIDC; npm 11.5.1+, Node 22.14+, hosted runners) needs no token and adds provenance on GitHub/GitLab.
- Detect: no `files`; CI publishing with a stored token.
- Fix: Whitelist `files`; check `npm pack --dry-run`; use trusted publishing.
- Source: package.json - https://docs.npmjs.com/cli/v11/configuring-npm/package-json ; Trusted publishing - https://docs.npmjs.com/trusted-publishers ; Classic tokens revoked - https://github.blog/changelog/2025-12-09-npm-classic-tokens-revoked-session-based-auth-and-cli-token-management-now-available/

### JS-16 CLIs: shebang, bin and exit codes
- Trap: `bin` points at a plain JS file; `process.exit(1)` after printing results.
- Reality: `bin` files must start with `#!/usr/bin/env node` or run without Node. `process.exit()` quits with I/O pending, so piped stdout/stderr can be cut off.
- Detect: CLI output meant for pipes; `process.exit` after writes.
- Fix: Add the shebang; set `process.exitCode` and let the process end.
- Source: package.json bin - https://docs.npmjs.com/cli/v11/configuring-npm/package-json ; process.exit - https://nodejs.org/api/process.html

## Jobs, realtime and desktop

### JS-17 BullMQ Redis requirements
- Trap: BullMQ on the shared cache Redis with `allkeys-lru` (DATA-13); a job runs exactly once.
- Reality: BullMQ needs `maxmemory-policy noeviction`; workers need `maxRetriesPerRequest: null`. A worker blocking the event loop (JS-08) misses lock renewal, so the job stalls and is re-run or failed. Delivery is at-least-once (DATA-07).
- Detect: one Redis for cache and queues; CPU-heavy or non-idempotent jobs.
- Fix: Separate Redis with noeviction and AOF; CPU work off the loop; idempotent jobs.
- Source: Going to production - https://docs.bullmq.io/guide/going-to-production ; Stalled jobs - https://docs.bullmq.io/guide/workers/stalled-jobs

### JS-18 Socket.IO on several instances
- Trap: Scaling Socket.IO horizontally like a stateless API.
- Reality: With HTTP long-polling on (the default), every request of a session must reach the same instance (sticky sessions). Broadcasts reach only local clients without an adapter (e.g. Redis).
- Detect: several instances or autoscaling with Socket.IO.
- Fix: Sticky load balancing or WebSocket-only transport, plus an adapter.
- Source: Using multiple nodes - https://socket.io/docs/v4/using-multiple-nodes/

### JS-19 Electron renderer security and native modules
- Trap: The renderer calls `fs` or SQLite directly; `better-sqlite3` installs as in Node.
- Reality: `nodeIntegration` is off (since 5), `contextIsolation` on (12), renderers sandboxed (20); expose narrow APIs via `contextBridge` and validate IPC senders. Native modules need a rebuild for Electron's ABI (`@electron/rebuild`) or fail with `NODE_MODULE_VERSION`.
- Detect: Node APIs in UI code; `nodeIntegration: true`; native deps with no rebuild step.
- Fix: DB and file access in main via IPC; rebuild natives in the build (Forge does).
- Source: Security - https://www.electronjs.org/docs/latest/tutorial/security ; Native modules - https://www.electronjs.org/docs/latest/tutorial/using-native-node-modules
