# RUST facts
Covers: Rust on tokio (axum, hyper, tonic, actix-web), sqlx, reqwest/rustls, serde, clap CLIs, Tauri, WASM, musl and embedded builds
Verified: 2026-09-29 against official documentation. Re-verify facts older than 12 months.

## Async runtime (tokio)

### RS-01 Blocking or CPU-heavy work stalls tokio workers
- Trap: Sync libraries (file I/O, native bindings, rayon, argon2) can run directly in async handlers.
- Reality: Blocking or long compute without yielding stops the executor from driving other futures. `spawn_blocking` moves work to a blocking pool (default limit 512 threads, then queued). Started `spawn_blocking` tasks cannot be aborted, and runtime shutdown waits for them.
- Detect: Hashing, parsing, media/geo processing or native bindings in handlers or consumer loops.
- Fix: `spawn_blocking` for blocking I/O; a semaphore or rayon pool for many CPU jobs; `shutdown_timeout` to bound shutdown.
- Source: tokio::task::spawn_blocking - https://docs.rs/tokio/latest/tokio/task/fn.spawn_blocking.html

### RS-02 Sync-in-async bridges panic inside the runtime
- Trap: A CLI or service can call `Runtime::block_on` or `reqwest::blocking` from anywhere.
- Reality: `Runtime::block_on` panics when called within an async execution context. `reqwest::blocking` must not run inside an async runtime or it panics when it tries to block.
- Detect: Mixed sync and async layers, "blocking client" inside a tokio service, nested runtimes.
- Fix: Stay async end to end, or run blocking clients inside `spawn_blocking`/plain threads.
- Source: tokio::runtime::Runtime; reqwest::blocking - https://docs.rs/tokio/latest/tokio/runtime/struct.Runtime.html

### RS-03 Mutex guards across `.await`
- Trap: Async code needs `tokio::sync::Mutex` everywhere, or a std guard may be held while awaiting.
- Reality: Tokio recommends the std (or parking_lot) mutex for plain data; the async mutex only adds holding the lock across `.await` and costs more. A std `MutexGuard` is not `Send`, so a future holding it across `.await` cannot be passed to `tokio::spawn`; where it compiles it easily deadlocks.
- Detect: Locked caches, order books or session maps in async code; "lock, call API, unlock".
- Fix: Lock std mutexes in short scopes that end before any `.await`; use tokio's Mutex only for resources held across awaits.
- Source: tokio::sync::Mutex; Tokio tutorial, Shared state - https://docs.rs/tokio/latest/tokio/sync/struct.Mutex.html

### RS-04 Panics in spawned tasks are silent by default
- Trap: A panicking background task crashes the service, so the orchestrator restarts it.
- Reality: Tokio catches task panics; awaiting the `JoinHandle` yields a `JoinError` with `is_panic()`. A dropped handle detaches the task, so the panic is lost and the runtime runs on (changing that needs `tokio_unstable`). With profile `panic = "abort"` any panic ends the process.
- Detect: Consumers, schedulers or dispatchers started with `tokio::spawn` and never joined or monitored.
- Fix: Keep handles in a `JoinSet` or supervisor, handle `JoinError`, or choose `panic = "abort"` deliberately.
- Source: tokio::task::JoinHandle; tokio runtime Builder; Cargo profiles - https://docs.rs/tokio/latest/tokio/task/struct.JoinHandle.html

### RS-05 `select!` drops the losing branches
- Trap: Any future can sit in a `select!` loop next to a timeout or shutdown signal.
- Reality: `select!` drops unfinished branches. Cancel-safe: mpsc/broadcast `recv`, `accept`, `read`, `write`. Not cancel-safe (data loss): `read_exact`, `read_to_end`, `read_to_string`, `write_all`; `Mutex::lock`, `RwLock`, `Semaphore::acquire`, `Notify::notified` lose their queue place.
- Detect: Framed protocol readers raced against timers or shutdown in a loop.
- Fix: Put only cancel-safe calls in looping `select!`, or pin the future outside the loop and poll it by `&mut`.
- Source: tokio::select! - https://docs.rs/tokio/latest/tokio/macro.select.html

### RS-06 Runtime flavors differ between main and tests
- Trap: `#[tokio::test]` exercises the same scheduler as production.
- Reality: `#[tokio::main]` defaults to the multi-threaded runtime with one worker per CPU (needs feature `rt-multi-thread`). `#[tokio::test]` defaults to a single-threaded runtime per test.
- Detect: Concurrency, deadlock or `Send` behavior "covered by tests".
- Fix: Use `#[tokio::test(flavor = "multi_thread")]` for concurrency tests.
- Source: tokio::main; tokio::test - https://docs.rs/tokio/latest/tokio/attr.main.html

### RS-07 Tokio on WASM is a small subset
- Trap: Shared tokio code runs unchanged in the browser/WASM build.
- Reality: Without `tokio_unstable`, WASM supports only features sync, macros, io-util, rt and time; any other feature (including `full`) fails to compile. Timers panic on WASM targets without timer support.
- Detect: WASM builds sharing crates that enable tokio `full`.
- Fix: Keep runtime-specific code behind target cfgs and use the browser event loop in the WASM build.
- Source: tokio crate docs, WASM support - https://docs.rs/tokio/latest/tokio/

## Web layer (axum)

### RS-08 axum 0.8 path syntax and extractor order
- Trap: Routes like `/users/:id` and `/*path`, and handler arguments in any order.
- Reality: axum 0.8 uses `/{id}` and `/{*rest}`; old syntax panics at startup. Extractors run left to right; only one may consume the body and it must be the last argument (`Json`, `Form`, `String`, `Bytes`), otherwise it does not compile.
- Detect: Colon routes in axum 0.8 blueprints; `State`/`Path` placed after `Json`.
- Fix: Use brace syntax and put the body extractor last.
- Source: axum CHANGELOG 0.8.0; axum::extract - https://docs.rs/axum/latest/axum/extract/index.html

### RS-09 axum rejects bodies over 2 MB by default
- Trap: Upload and ingestion endpoints accept any size through `Bytes`/`Json`.
- Reality: `Bytes` and extractors built on it (`String`, `Json`, `Form`) reject bodies over 2 MB by default. Streaming the body directly bypasses the limit.
- Detect: File, PDF, batch or bundle uploads with no body-size decision.
- Fix: Set `DefaultBodyLimit::max(n)` per route, or disable it and add `RequestBodyLimitLayer`; stream very large uploads.
- Source: axum DefaultBodyLimit - https://docs.rs/axum/latest/axum/extract/struct.DefaultBodyLimit.html

## Database (sqlx)

### RS-10 sqlx `query!` needs a database or `.sqlx` at build time
- Trap: `cargo build` in CI or Docker works like any crate.
- Reality: `query!`/`query_as!` need `DATABASE_URL` at build time pointing to a database of the same kind and schema. Offline mode uses `cargo sqlx prepare` to write `.sqlx`, which must be committed; `cargo sqlx prepare --check` fails when stale. A present `DATABASE_URL` takes precedence; `SQLX_OFFLINE=true` forces offline.
- Detect: `query!` with no CI database, no `.sqlx` directory, or offline Docker builds.
- Fix: Commit `.sqlx`, run `cargo sqlx prepare --check` in CI, and set `SQLX_OFFLINE=true` in image builds.
- Source: sqlx README; sqlx-cli README - https://github.com/launchbadge/sqlx

### RS-11 sqlx 0.9 breaking changes
- Trap: sqlx 0.8 code and feature flags carry over.
- Reality: sqlx 0.9.0 (2026-05): `query*()` takes `impl SqlSafeStr` (only `&'static str` and `AssertSqlSafe`), so `format!` SQL needs a wrapper. Combined runtime+TLS features like `runtime-tokio-native-tls` are gone. MSRV 1.94. Pool defaults suit light duty.
- Detect: Dynamic SQL strings, old feature names, pool size unspecified.
- Fix: Bind parameters, wrap vetted dynamic SQL in `AssertSqlSafe`, use separate runtime and TLS features, and size the pool per replica.
- Source: sqlx CHANGELOG; sqlx PoolOptions - https://docs.rs/sqlx/latest/sqlx/pool/struct.PoolOptions.html

## Language and toolchain

### RS-12 `async fn` in traits has limits
- Trap: Since Rust 1.75 `async fn` in traits replaces `#[async_trait]` everywhere.
- Reality: Stable since 1.75, but such traits are not dyn-compatible, and callers cannot add a `Send` bound to the returned future (public traits trigger the `async_fn_in_trait` lint), so spawning generic users on tokio fails with "future cannot be sent between threads safely".
- Detect: `dyn Repository`/plugin registries with async methods; generic services spawned on multi-thread runtimes.
- Fix: Use `-> impl Future<Output = T> + Send` or `trait_variant::make` for Send, and `#[async_trait]` or manual boxing for dynamic dispatch.
- Source: Announcing async fn and return-position impl Trait in traits - https://blog.rust-lang.org/2023/12/21/async-fn-rpit-in-traits/

### RS-13 Edition 2024 and MSRV
- Trap: Moving to `edition = "2024"` is a formatting change, and any toolchain builds it.
- Reality: Edition 2024 needs Rust 1.85+. `std::env::set_var`/`remove_var` become unsafe (unsound with other threads), `if let` temporaries (e.g. lock guards) drop before `else`, RPIT captures all lifetimes, and `resolver = "3"` prefers deps matching `package.rust-version` (virtual workspaces must set it).
- Detect: `set_var` after threads start; no `rust-version`; old toolchain pins.
- Fix: Declare `rust-version`, pin the toolchain, and pass configuration explicitly instead of mutating the environment.
- Source: Rust Edition Guide, Rust 2024 - https://doc.rust-lang.org/edition-guide/rust-2024/index.html

### RS-14 Integer overflow wraps silently in release builds
- Trap: Rust always panics on overflow.
- Reality: Overflow panics when debug assertions are on; the release profile defaults to `overflow-checks = false`, so values wrap in two's complement.
- Detect: Money, counters, sequence numbers, sensor math or buffer offsets in plain `+`/`*`.
- Fix: Use `checked_*`/`saturating_*` where overflow matters, or set `overflow-checks = true` in `[profile.release]`.
- Source: Rust Reference, Integer overflow; Cargo profiles - https://doc.rust-lang.org/cargo/reference/profiles.html

### RS-15 serde accepts unknown fields and tags enums externally
- Trap: Deserializing into a struct rejects unexpected input, and enums map to `{"type": ...}` JSON.
- Reality: Unknown fields are ignored by default for self-describing formats; `#[serde(deny_unknown_fields)]` errors instead but does not work with `flatten`. Missing fields need `#[serde(default)]`. Enums default to the externally tagged form `{"Variant": {...}}`.
- Detect: Strict API or webhook contracts, versioned payloads, `type`-tagged JSON events.
- Fix: State `deny_unknown_fields`, `default`, `rename_all` and `tag = "type"` explicitly.
- Source: serde container and field attributes; Enum representations - https://serde.rs/container-attrs.html

## Build and deploy

### RS-16 Static binaries: musl, OpenSSL and TLS crypto providers
- Trap: A musl target gives a static binary whatever the dependencies, and rustls needs no C toolchain.
- Reality: musl targets link the C runtime statically by default, but `openssl-sys` needs OpenSSL headers and libraries unless the `vendored` feature builds it (needs a C compiler, perl, make). reqwest 0.13 defaults to rustls, and rustls defaults to the aws-lc-rs provider, which has build dependencies such as cmake; `ring` is the alternative. Applications should install one process-default `CryptoProvider` early.
- Detect: "single static binary" or scratch images with OpenSSL or aws-lc-rs in cross builds.
- Fix: Choose the TLS stack explicitly (rustls+ring, rustls+aws-lc-rs with cmake, or vendored OpenSSL) and inspect the binary's linkage.
- Source: Rust Reference, Linkage; openssl crate; rustls crate; reqwest CHANGELOG - https://doc.rust-lang.org/reference/linkage.html

### RS-17 `no_std` binaries need a panic handler
- Trap: Firmware crates build like normal binaries once `#![no_std]` is added.
- Reality: Linking a `no_std` binary, dylib, cdylib or staticlib requires your own `#[panic_handler]`.
- Detect: Embedded or bare-metal targets with no panic strategy stated.
- Fix: Pick a panic handler crate or define `#[panic_handler]`, and set `panic = "abort"` for the target profile.
- Source: Rust Reference, Panic - https://doc.rust-lang.org/reference/panic.html
