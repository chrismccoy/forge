# CLOJURE facts
Covers: Clojure (JVM), core.async, Ring, Reitit, Aleph, Pedestal, next.jdbc, HikariCP, Malli, Integrant, ClojureScript (Reagent, re-frame), Babashka, tools.cli, GraalVM native-image
Verified: 2026-09-29 against official documentation. Re-verify facts older than 12 months.

## Concurrency (core.async)

### CLJ-01 go blocks must not block
- Trap: A go block is a lightweight thread, so JDBC calls, HTTP requests or `<!!` inside it are fine.
- Reality: go blocks "should not (either directly or indirectly) perform operations that may block indefinitely", which can exhaust the fixed go pool (8 threads by default, `clojure.core.async.pool-size`) and stop all go processing. `<!!`/`>!!` are not for use in go blocks. core.async 1.9 runs go blocks on virtual threads on Java 21+ but keeps the same rule ("blocking I/O not allowed").
- Detect: database or HTTP calls inside `go`/`go-loop`, `<!!` inside go, "virtual threads make blocking in go safe".
- Fix: Run blocking work in `thread` or `io-thread` (virtual thread when available) and park with `<!`/`>!` inside go.
- Source: clojure.core.async API - https://clojure.github.io/core.async/clojure.core.async.html ; core.async and Virtual Threads - https://clojure.org/news/2025/10/01/async_virtual_threads

### CLJ-02 Channels cap pending puts at 1024
- Trap: An unbuffered channel queues producers indefinitely when the consumer is slow.
- Reality: Beyond the buffer, a channel accepts at most 1024 pending puts (and 1024 pending takes); the next one throws "No more than 1024 pending puts are allowed on a single channel". `dropping-buffer` drops new values when full; `sliding-buffer` drops the oldest.
- Detect: `put!` from callbacks or request handlers into unbuffered channels, no back-pressure design.
- Fix: Use `>!`/`>!!` for back-pressure, size buffers deliberately, or choose a dropping/sliding buffer when loss is acceptable.
- Source: core.async source (impl/channels.clj, MAX-QUEUE-SIZE) - https://github.com/clojure/core.async/blob/master/src/main/clojure/clojure/core/async/impl/channels.clj

## HTTP (Ring, Reitit)

### CLJ-03 Middleware runs bottom to top
- Trap: Middleware listed first in `->` runs first on the request.
- Reality: With `(-> handler (wrap-a) (wrap-b))`, the last wrapper is outermost; middleware "runs from bottom to top", and one that returns a response short-circuits the rest.
- Detect: auth before session/params in a `->` chain, `wrap-keyword-params` listed after `wrap-params`.
- Fix: Write the order from innermost to outermost and test that auth sees parsed sessions and params.
- Source: Concepts (Ring wiki) - https://github.com/ring-clojure/ring/wiki/Concepts

### CLJ-04 Ring sessions default to memory
- Trap: `wrap-session` persists sessions across restarts and instances.
- Reality: The default `:store` is `memory-store`, an atom in the process; sessions vanish on restart and are not shared between instances.
- Detect: multi-instance deploys (ECS, Kubernetes, Cloud Run) with `wrap-session` and no store.
- Fix: Use a shared store (database, Redis) or the signed cookie store.
- Source: ring.middleware.session - https://ring-clojure.github.io/ring/ring.middleware.session.html

### CLJ-05 Reitit route data does not validate by itself
- Trap: Declaring `:parameters` and `:responses` on a route validates and coerces requests.
- Reality: Coercion only runs when `:coercion` is set and the coercion middleware (`coerce-request-middleware`, `coerce-response-middleware`, `coerce-exceptions-middleware`) is mounted.
- Detect: Malli/spec schemas in route data with no coercion middleware in the router options.
- Fix: Add `:coercion` and the coercion middleware to the router `:data`, and test that invalid input returns 400.
- Source: Ring coercion (reitit) - https://cljdoc.org/d/metosin/reitit/CURRENT/doc/ring/coercion

## Data access (next.jdbc)

### CLJ-06 Rows come back with qualified keys
- Trap: `execute!` returns maps like `{:id 1 :email ...}`.
- Reality: The default builder returns table-qualified keywords such as `:users/id`. `as-unqualified-maps` and `as-unqualified-lower-maps` produce plain keys.
- Detect: code or JSON contracts assuming unqualified keys, no `:builder-fn` choice.
- Fix: Pick a builder deliberately and convert keys at the API boundary.
- Source: Getting Started (next.jdbc) - https://github.com/seancorfield/next-jdbc/blob/develop/doc/getting-started.md

### CLJ-07 get-datasource does not pool
- Trap: `jdbc/get-datasource` gives a connection pool.
- Reality: It opens a new connection per operation. Pooling needs `next.jdbc.connection/->pool` with HikariCP or c3p0; HikariCP expects `:username` rather than `:user`.
- Detect: production services using `get-datasource` directly, Hikari config with `:user`.
- Fix: Build a HikariCP pool with `->pool` at startup (in Integrant/Component) and close it on shutdown.
- Source: Getting Started (next.jdbc) - https://github.com/seancorfield/next-jdbc/blob/develop/doc/getting-started.md

### CLJ-08 plan results must be consumed inside the reduction
- Trap: `plan` returns rows to use later.
- Reality: `plan` returns a reducible that runs when reduced and closes the connection when the reduction ends; rows must be consumed inside it.
- Detect: `plan` results stored or returned lazily to callers.
- Fix: Reduce or `into` inside the call, or use `execute!` for materialized results.
- Source: Getting Started (next.jdbc) - https://github.com/seancorfield/next-jdbc/blob/develop/doc/getting-started.md

## Builds and packaging

### CLJ-09 Advanced compilation needs externs
- Trap: A ClojureScript build that works in development works the same under `:advanced`.
- Reality: Closure advanced compilation renames names, which breaks property access on foreign JS libraries unless externs are supplied. Externs inference (`:infer-externs`, `*warn-on-infer*`, `^js` hints) needs ClojureScript 1.10.238+. Functions called from JS need `^:export`.
- Detect: npm/JS interop, production-only bugs, no mention of externs or `^js` hints.
- Fix: Enable externs inference with `^js` hints, test the `:advanced` build in CI, and use `:pseudo-names` to debug.
- Source: Externs guide - https://clojurescript.org/guides/externs ; Advanced Compilation - https://clojurescript.org/reference/advanced-compilation

### CLJ-10 Native CLIs need GraalVM constraints
- Trap: A JVM Clojure CLI starts fast, or it can be turned into a native binary unchanged.
- Reality: Native images are used for fast startup, but they need build-time class initialization (clj-easy/graal-build-time), no runtime `eval`, and reflection removed by type hints or declared in reflect-config.json; direct linking helps.
- Detect: tools.cli CLIs promising instant startup on the JVM, native-image plans with `eval` or reflective interop.
- Fix: Use Babashka for scripts, or plan native-image with `*warn-on-reflection*`, graal-build-time and SCI instead of eval.
- Source: graal-docs (clj-easy) - https://github.com/clj-easy/graal-docs
