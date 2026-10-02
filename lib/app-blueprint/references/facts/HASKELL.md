# HASKELL facts
Covers: GHC and its runtime, Servant, Warp, Yesod, IHP, Hasql and hasql-pool, Persistent/Esqueleto/Beam, Conduit, STM, Aeson, text/bytestring/containers, Stack, Cabal, Nix
Verified: 2026-09-29 against official documentation. Re-verify facts older than 12 months.

## Runtime and deploy

### HS-01 Multicore needs -threaded and -N
- Trap: A GHC binary uses all cores, and `+RTS -N` can be added at deploy time.
- Reality: Parallel execution requires linking with `-threaded`; without `-N` the program runs on one capability. The default `-rtsopts=some` only accepts `-?` and `--info` at runtime, so `+RTS -N` and `GHCRTS` fail unless the binary was linked with `-rtsopts`. `-N` alone uses every processor on the machine; `-maxN<x>` caps it.
- Detect: concurrency or throughput claims with no `ghc-options`, "+RTS -N" in a Dockerfile CMD without `-rtsopts`.
- Fix: Link with `-threaded -rtsopts "-with-rtsopts=-N"` (or `-maxN<x>` sized to the container's CPU quota).
- Source: Using Concurrent Haskell - https://downloads.haskell.org/ghc/latest/docs/users_guide/using-concurrent.html ; Linking options (-rtsopts) - https://downloads.haskell.org/ghc/latest/docs/users_guide/phases.html

### HS-02 The heap is unbounded by default
- Trap: The GHC heap respects the container memory limit.
- Reality: `-M` (maximum heap) is unlimited by default; the heap grows with demand until the OS or container kills the process.
- Detect: memory-limited containers with no RTS heap settings.
- Fix: Set `-with-rtsopts=-M<size>` below the container limit so the program fails with a heap overflow you can observe.
- Source: Running a compiled program (RTS options) - https://downloads.haskell.org/ghc/latest/docs/users_guide/runtime_control.html

### HS-03 Forked threads die silently and with main
- Trap: Background workers started with `forkIO` report failures and finish before shutdown.
- Reality: Exceptions in a `forkIO` thread are not rethrown in the parent, and when the main thread exits all other threads stop with it. Without `-threaded`, a foreign call blocks every Haskell thread.
- Detect: `forkIO` workers with no supervision, graceful shutdown that does not wait for workers.
- Fix: Use the async package (`withAsync`, `link`, `wait`) and wait for workers before main returns.
- Source: Control.Concurrent - https://hackage-content.haskell.org/package/base-4.22.0.0/docs/Control-Concurrent.html

## Laziness and memory

### HS-04 Lazy accumulators leak space
- Trap: Counters and caches in IORefs or Maps stay small.
- Reality: `modifyIORef` does not apply the function strictly, so thunks pile up; the docs' million-increment example "will likely produce a stack overflow". `Data.Map` values are lazy unless `Data.Map.Strict` functions are used.
- Detect: metrics counters, in-memory caches or state in `IORef`/`TVar`/`Map` updated in a loop, no mention of strictness.
- Fix: Use `modifyIORef'`/`atomicModifyIORef'`, `Data.Map.Strict`, and strict fields in long-lived state.
- Source: Data.IORef - https://hackage-content.haskell.org/package/base-4.22.0.0/docs/Data-IORef.html ; Data.Map.Lazy - https://hackage-content.haskell.org/package/containers/docs/Data-Map-Lazy.html

### HS-05 Lazy IO holds handles open
- Trap: `readFile`/`hGetContents` read the file and release it.
- Reality: They read lazily and keep a semi-closed handle until the whole content is consumed, so writing the same file usually fails and handles leak under load. Strict `readFile'`/`hGetContents'` exist since base-4.15.
- Detect: lazy `String` IO for uploads, logs or config reloads; many files opened in a loop.
- Fix: Use strict `ByteString`/`Text` reads, or a streaming library (Conduit, Streamly) for large data.
- Source: System.IO - https://hackage-content.haskell.org/package/base-4.22.0.0/docs/System-IO.html

### HS-06 String is a linked list
- Trap: `String` is fine for request bodies, JSON and text processing.
- Reality: `String` is a list of `Char`; `Data.Text` is a packed Unicode type (UTF-8 internally since text-2.0) with a lazy variant for streaming. Since text-1.3 fusion is not implicit.
- Detect: `String` in API types, parsers or DB rows on a hot path.
- Fix: Use `Text` for text and `ByteString` for bytes; convert only at the edges.
- Source: Data.Text - https://hackage-content.haskell.org/package/text-2.1.4/docs/Data-Text.html

## Data access (Hasql)

### HS-07 hasql-pool defaults to 3 connections
- Trap: The pool size fits the load without configuration, and errors keep the connection.
- Reality: hasql-pool defaults are size 3, acquisitionTimeout 10 s, agingTimeout 1 day, idlenessTimeout 10 min. `acquire` opens no connections. A session failing with `ClientError` drops the connection and frees the slot; exhaustion returns `AcquisitionTimeoutUsageError`.
- Detect: Hasql services with concurrency targets but no pool size, no handling of `UsageError`.
- Fix: Size the pool from expected concurrency and the database's connection budget, and map acquisition timeouts to 503s.
- Source: Hasql.Pool.Config.Defaults - https://hackage-content.haskell.org/package/hasql-pool-1.5.0.1/docs/Hasql-Pool-Config-Defaults.html ; Hasql.Pool - https://hackage-content.haskell.org/package/hasql-pool-1.5.0.1/docs/Hasql-Pool.html

### HS-08 Hasql prepares statements by default
- Trap: Hasql works behind any connection pooler unchanged.
- Reality: hasql 2.x enables prepared statements by default; the docs say to disable them with `noPreparedStatements` for pgbouncer compatibility.
- Detect: Hasql plus a transaction-mode pooler with no prepared-statement setting.
- Fix: Disable prepared statements in the connection settings when a transaction pooler sits in between.
- Source: hasql - https://hackage.haskell.org/package/hasql

### HS-09 hasql-transaction retries the whole block
- Trap: IO or external calls inside a Transaction run once.
- Reality: hasql-transaction is "a composable abstraction over retryable transactions" that retries on conflicts, behaving like STM, so its body can run several times.
- Detect: HTTP calls, queue publishes or logging with side effects inside a Transaction.
- Fix: Keep Transactions to database statements only; do side effects after commit (or via an outbox table).
- Source: Hasql.Transaction - https://hackage-content.haskell.org/package/hasql-transaction-1.2.3.1/docs/Hasql-Transaction.html

## Builds

### HS-10 Reproducibility depends on the tool
- Trap: Any Stack or Cabal build is reproducible.
- Reality: Without a freeze file or `index-state`, the Cabal solver picks the latest versions in the package index. A Stack snapshot pins Haskell packages only; Stack's Nix integration (off by default outside NixOS) adds pinned non-Haskell system libraries.
- Detect: "reproducible builds" with Cabal and no `cabal.project.freeze`/`index-state`, C library dependencies (libpq, zlib) left to the base image.
- Fix: Commit a freeze file and index-state (Cabal) or a snapshot (Stack), and pin system libraries with Nix or a fixed base image.
- Source: cabal commands (freeze) - https://cabal.readthedocs.io/en/stable/cabal-commands.html ; Nix integration (Stack) - https://docs.haskellstack.org/en/latest/topics/nix_integration/
