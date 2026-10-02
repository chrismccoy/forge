# GO facts
Covers: Go services (net/http, chi, Gin, echo, Fiber, gRPC), cobra CLIs, database/sql, pgx, Kafka clients, SQLite drivers, container/cloud deploys
Verified: 2026-09-29 against official documentation. Re-verify facts older than 12 months.

## HTTP servers and clients

### GO-01 net/http has no timeouts by default
- Trap: `http.ListenAndServe` and `http.DefaultClient` are production-ready as-is.
- Reality: Zero `Server` Read/ReadHeader/Write/Idle timeouts mean no timeout, and `http.ListenAndServe` sets only Addr and Handler. `Client.Timeout` zero means no timeout; `DefaultClient` (used by Get/Head/Post) sets none.
- Detect: `http.ListenAndServe(`, `http.Get(`, `http.DefaultClient`, calls to webhooks or third-party APIs with no timeout stated.
- Fix: Use an explicit `http.Server` with ReadHeaderTimeout/ReadTimeout/WriteTimeout/IdleTimeout and an `http.Client{Timeout: ...}` or context deadlines.
- Source: net/http package - https://pkg.go.dev/net/http

### GO-02 Response bodies must be read and closed
- Trap: Outbound calls only need the status code; the body can be ignored.
- Reality: The caller must close the body. If it is not read to EOF and closed, the Transport may not reuse the keep-alive connection, so connections pile up.
- Detect: Webhook dispatchers, health/link checkers or API pollers with no body draining/closing.
- Fix: `defer resp.Body.Close()` and drain unread bodies with `io.Copy(io.Discard, resp.Body)`.
- Source: net/http Client.Do - https://pkg.go.dev/net/http#Client.Do

### GO-03 Graceful shutdown does not cover WebSockets or SSE hijacks
- Trap: `Server.Shutdown` drains everything, and `ListenAndServe` returning means it is done.
- Reality: On Shutdown, ListenAndServe returns `ErrServerClosed` immediately; the program must wait for Shutdown itself to return. Shutdown waits indefinitely unless its context has a deadline, and it neither closes nor waits for hijacked connections such as WebSockets.
- Detect: WebSocket gateways, long-lived streams, "graceful shutdown" with no deadline or connection tracking.
- Fix: Call Shutdown with a deadline context, wait for it in main, and close WebSockets via `RegisterOnShutdown` or own tracking.
- Source: net/http Server.Shutdown - https://pkg.go.dev/net/http#Server.Shutdown

### GO-04 Request context ends when the handler returns
- Trap: Background work started in a handler can keep using `r.Context()`.
- Reality: For incoming server requests the context is canceled when the client connection closes, the HTTP/2 request is canceled, or ServeHTTP returns. `context.WithoutCancel` (Go 1.21+) keeps values without the cancellation.
- Detect: Fire-and-forget audit writes, webhook sends or publishes started from handlers with the request context.
- Fix: Use `context.WithoutCancel(r.Context())` plus a timeout, or hand off to a worker with a server-lifetime context.
- Source: net/http Request.Context; context package - https://pkg.go.dev/net/http#Request.Context

### GO-05 Handler panics are recovered, goroutine panics kill the process
- Trap: net/http recovers panics, so all panics are contained.
- Reality: net/http recovers a panic in ServeHTTP and aborts only that request. A panic in any other goroutine with no `recover` terminates the whole program.
- Detect: Consumers, workers or `go func()` in handlers with no recovery or supervision.
- Fix: Recover and log at the top of each long-lived goroutine, or state that the orchestrator restarts the crashed process.
- Source: net/http Handler; The Go Programming Language Specification, Handling panics - https://go.dev/ref/spec#Handling_panics

### GO-06 Go 1.22 ServeMux patterns depend on go.mod
- Trap: `mux.HandleFunc("GET /items/{id}", ...)` works in any Go project.
- Reality: Method and wildcard patterns (`POST /x`, `/items/{id}`, `/files/{path...}`, `{$}`, `r.PathValue`) arrived in Go 1.22 and are controlled by GODEBUG `httpmuxgo121`. GODEBUG defaults follow the go.mod `go` line, so a module declaring go 1.21 or older keeps the old matching. `GET` also matches `HEAD`.
- Detect: Stdlib routing with wildcards and an older `go` directive.
- Fix: Set the go.mod `go` line to 1.22+ and do not set `httpmuxgo121=1`.
- Source: Go 1.22 Release Notes; Go, Backwards Compatibility, and GODEBUG - https://go.dev/doc/go1.22

### GO-07 Fiber is not net/http
- Trap: Fiber takes net/http middleware and `fiber.Ctx` values can be kept.
- Reality: Fiber is built on fasthttp. Values returned from `fiber.Ctx` are not immutable by default and are reused across requests; references kept after the handler returns get overwritten.
- Detect: Fiber with goroutines or caches holding `c.Params`, `c.Body()` or headers; plans to reuse net/http middleware.
- Fix: Copy values before keeping them or set `fiber.Config{Immutable: true}`; plan for Fiber-specific middleware.
- Source: Fiber documentation - https://docs.gofiber.io/

## Concurrency

### GO-08 Maps are not safe for concurrent writes
- Trap: A plain `map` cache or session table is fine in a server.
- Reality: Map access is unsafe when any goroutine writes and can crash the program; read-only sharing is safe. `sync.Map` suits patterns like static caches, not general use.
- Detect: In-memory maps for rate limits, sessions, live counts or caches in a server.
- Fix: Guard with `sync.Mutex`/`sync.RWMutex`, or use `sync.Map` only for write-once, read-many keys.
- Source: Go FAQ, Why are map operations not defined to be atomic - https://go.dev/doc/faq#atomic_maps

### GO-09 Uncalled CancelFuncs and missing contexts leak goroutines
- Trap: `context.WithTimeout` is enough on its own; the cancel func is optional.
- Reality: Failing to call the CancelFunc leaks the child context until the parent is canceled; `go vet` checks this. Goroutines blocked on channels or I/O with no context never exit.
- Detect: Fan-out checkers, consumers or pollers with no stop path; contexts stored in structs.
- Fix: `defer cancel()` right after creation, pass ctx as the first parameter (not in structs), and select on `ctx.Done()` in every loop.
- Source: context package - https://pkg.go.dev/context

### GO-10 Loop variables are per-iteration only from Go 1.22
- Trap: Closures capturing a `for` variable behave the same in every Go version.
- Reality: Go 1.22 made each iteration create new loop variables, gated by the go.mod `go` line (or per-file build constraints). Older go lines keep the shared-variable behavior.
- Detect: go.mod `go 1.21` or older with goroutines launched in loops.
- Fix: Declare go 1.22+ in go.mod; under older lines copy the variable inside the loop.
- Source: Go 1.22 Release Notes - https://go.dev/doc/go1.22

### GO-11 GOMAXPROCS respects container CPU limits only from Go 1.25
- Trap: Go automatically sizes itself to the container.
- Reality: Go 1.25+ on Linux caps default GOMAXPROCS at the cgroup CPU limit (not requests) and tracks changes. Manual GOMAXPROCS disables it; the GODEBUG defaults follow the go.mod `go` line.
- Detect: Container deploys with CPU requests but no limits, hard-coded GOMAXPROCS, or an old go line.
- Fix: Build with a go line of 1.25 or later and set CPU limits when you want Go to size to them.
- Source: Go 1.25 Release Notes - https://go.dev/doc/go1.25

## Databases (drivers and pools)

### GO-12 database/sql pools are unbounded and Rows hold connections
- Trap: `*sql.DB` pool defaults are safe and results release themselves.
- Reality: MaxOpenConns defaults to 0 (unlimited), MaxIdleConns to 2, no max lifetime. `sql.Open` may not connect. A `Tx` pins a connection until Commit/Rollback; unclosed `Rows` hold one too.
- Detect: No pool sizing against the DB connection limit across replicas; no `rows.Close()`/`rows.Err()`; transactions around network calls.
- Fix: Set MaxOpenConns, MaxIdleConns and ConnMaxLifetime, `Ping` at startup, and always close Rows and end transactions.
- Source: database/sql package - https://pkg.go.dev/database/sql

### GO-13 pgx.Conn is not concurrency-safe
- Trap: Share one `*pgx.Conn` across handlers.
- Reality: `*pgx.Conn` is a single connection and not safe for concurrent use; `pgxpool` is the concurrency-safe pool. pgxpool MaxConns defaults to the greater of 4 or `runtime.NumCPU()`.
- Detect: pgx without pgxpool in a server; replicas × pool size never checked against the DB limit.
- Fix: Use `pgxpool.New` and set `pool_max_conns` deliberately.
- Source: pgx v5 and pgxpool packages - https://pkg.go.dev/github.com/jackc/pgx/v5/pgxpool

## Build and deploy

### GO-14 Cross-compiling disables cgo
- Trap: `GOOS=linux GOARCH=arm64 go build` works for any dependency set.
- Reality: cgo is off by default when cross-compiling or with no C compiler. mattn/go-sqlite3 needs `CGO_ENABLED=1` and gcc; confluent-kafka-go (librdkafka) cannot build with `CGO_ENABLED=0` and needs `-tags musl` on Alpine. `modernc.org/sqlite` is cgo-free.
- Detect: "single static binary", Alpine/scratch images or multi-arch releases plus SQLite, librdkafka, libvips, GDAL or FFmpeg bindings.
- Fix: Pick pure-Go drivers, or plan a C cross toolchain per target and state `CGO_ENABLED`, tags and libc.
- Source: cgo command; confluent-kafka-go README - https://pkg.go.dev/cmd/cgo

### GO-15 go:embed skips dotfiles and underscore files
- Trap: `//go:embed dist` ships the whole built frontend.
- Reality: Directory patterns exclude names starting with `.` or `_` unless prefixed `all:`. Patterns cannot contain `..`; only package-level variables.
- Detect: Embedded UIs whose bundler emits `_app/`, `_next/` or dotfiles.
- Fix: Use `//go:embed all:dist` and keep embedded assets under the package directory.
- Source: embed package - https://pkg.go.dev/embed

### GO-16 Only the two newest Go releases get fixes
- Trap: Pin any recent Go version indefinitely.
- Reality: Each major release is supported until two newer ones exist. As of 2026-09: Go 1.27 (2026-08-19) and 1.26; Go 1.25 gets no more security fixes.
- Detect: Dockerfiles or CI pinned to go1.25 or older, "LTS Go" claims.
- Fix: Target the current or previous release and budget an upgrade every six months.
- Source: Go Release History - https://go.dev/doc/devel/release

## Data handling and logging

### GO-17 encoding/json v1 defaults differ from v2
- Trap: Nil slices marshal as `[]`, JSON field matching is exact, and unknown fields are rejected.
- Reality: v1 `encoding/json` marshals nil slices/maps as `null`, matches keys case-insensitively and ignores unknown keys unless `DisallowUnknownFields`. Go 1.27 adds `encoding/json/v2` (nil slice `[]`, case-sensitive, rejects duplicate names); v1 is unchanged.
- Detect: APIs promising `[]`, strict input validation, or v2 behavior assumed with `encoding/json`.
- Fix: Initialize slices, use DisallowUnknownFields for strict input, or adopt `encoding/json/v2` explicitly on Go 1.27+.
- Source: encoding/json package; Go 1.27 Release Notes - https://pkg.go.dev/encoding/json

### GO-18 time.Time == compares monotonic readings
- Trap: `t1 == t2` checks for the same instant.
- Reality: `==` also compares Location and monotonic reading; use `Equal`. Marshaling, `In`, `UTC`, `Local`, `Round` and `Truncate` strip the monotonic reading.
- Detect: Time equality in dedup/idempotency logic, `time.Time` map keys, timers from persisted times.
- Fix: Use `t.Equal(u)`, keys from `t.UTC().UnixNano()`, and in-process `time.Since` for elapsed time.
- Source: time package, Monotonic Clocks - https://pkg.go.dev/time

### GO-19 log/slog default handler drops Debug and is not JSON
- Trap: `slog.Info` emits JSON and Debug logs appear by default.
- Reality: The default handler writes text via the `log` package at minimum level Info, so Debug is dropped. `SetDefault` also routes `log.Print` through the new handler.
- Detect: Log pipelines expecting JSON with no handler configured; debug audit trails.
- Fix: `slog.SetDefault(slog.New(slog.NewJSONHandler(os.Stdout, opts)))` in main, with a LevelVar for runtime level changes.
- Source: log/slog package - https://pkg.go.dev/log/slog
