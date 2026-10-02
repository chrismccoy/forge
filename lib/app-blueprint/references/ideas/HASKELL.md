# Haskell Blueprint Types — Copy-Paste Input Sets

Copy a fenced block into the prompt as-is, or swap individual fields.

## 1. Ledgerly — double-entry accounting API

```text
APP_DESCRIPTION: A double-entry bookkeeping API for small businesses. It records journal entries, enforces balanced transactions at the type level, produces trial balances and P&L statements, and exposes an audit trail with immutable append-only postings. Every monetary amount is modeled as a fixed-point Decimal to avoid rounding drift.
TECH_STACK: GHC + Servant + Persistent + PostgreSQL, Warp behind nginx, Stack build, deployed as a Docker image on Fly.io
APP_TYPE: API service
LANGUAGE: Haskell
SCALE: 4,000 tenants, 20M postings, 300 req/s peak
```

## 2. Parsec — config language parser CLI

```text
APP_DESCRIPTION: A CLI that parses and validates a typed configuration DSL for infrastructure teams. It reports precise error spans, resolves imports and variable interpolation, and can emit normalized JSON or YAML for downstream tooling. The grammar is defined with a Megaparsec combinator parser and round-trips losslessly.
TECH_STACK: GHC + Megaparsec + optparse-applicative + Aeson, distributed as a static binary via Cabal and Nix, released on GitHub
APP_TYPE: CLI
LANGUAGE: Haskell
SCALE: single user, 5,000-line config files, <50 ms parse
```

## 3. Streamweld — Kafka ETL pipeline

```text
APP_DESCRIPTION: A streaming ETL pipeline that consumes clickstream events from Kafka, deduplicates and enriches them against a reference dataset, then writes partitioned Parquet to object storage. Backpressure and bounded memory are handled with a Conduit streaming graph so multi-gigabyte batches never load fully into memory.
TECH_STACK: GHC + Conduit + hw-kafka-client + amazonka-s3, PostgreSQL for reference data, Stack build, running on ECS Fargate
APP_TYPE: data pipeline
LANGUAGE: Haskell
SCALE: 500M events/day, 12 partitions, 8 workers
```

## 4. Typeboard — type-safe admin dashboard

```text
APP_DESCRIPTION: An internal admin web app for a logistics company that manages shipments, drivers, and routing exceptions. Forms and routes are type-checked end to end so a renamed database column breaks the build rather than production. Operators get live shipment status and can reassign loads with an audit log.
TECH_STACK: IHP framework on GHC + PostgreSQL + Auto-refresh, HSX views, Nix-managed toolchain, deployed to a self-hosted VM
APP_TYPE: web app
LANGUAGE: Haskell
SCALE: 200 internal users, 60k shipments/month
```

## 5. Quantify — options pricing API

```text
APP_DESCRIPTION: A pricing microservice for an options desk. It values European and American contracts via binomial trees and Black-Scholes closed forms, computes Greeks, and exposes a batch endpoint for portfolio revaluation. Numeric routines use strict unboxed vectors and are property-tested against analytic identities.
TECH_STACK: GHC + Servant + vector + hmatrix, Redis via hedis for quote caching, Stack build, Kubernetes on AWS EKS
APP_TYPE: API service
LANGUAGE: Haskell
SCALE: 50k instruments, 2,000 revaluations/s
```

## 6. Grepline — structured log query CLI

```text
APP_DESCRIPTION: A command-line tool that queries structured JSON logs with a small typed expression language. It supports field predicates, time-window filters, aggregation, and tailing a live file, printing colorized aligned output. The query language is compiled once and applied over a streaming reader for constant memory.
TECH_STACK: GHC + Streamly + Megaparsec + optparse-applicative + Aeson, single static binary via Nix, published to Homebrew tap
APP_TYPE: CLI
LANGUAGE: Haskell
SCALE: single user, 2 GB log files, streaming scan
```

## 7. Merkle — content-addressed blob store API

```text
APP_DESCRIPTION: A content-addressed storage API where objects are keyed by their BLAKE3 hash and organized in a Merkle DAG. It deduplicates identical blobs, supports range reads, and garbage-collects unreachable nodes. Immutable references make the store safe for concurrent writers using STM-guarded indices.
TECH_STACK: GHC + Scotty + STM + Hasql + PostgreSQL, blobs on S3-compatible storage, Cabal build, deployed on Hetzner
APP_TYPE: API service
LANGUAGE: Haskell
SCALE: 40M objects, 8 TB, 400 req/s
```

## 8. Cadence — actuarial reserve pipeline

```text
APP_DESCRIPTION: A nightly actuarial pipeline that projects insurance claim reserves using development triangles and chain-ladder methods. It ingests policy and claim extracts, runs bootstrap simulations for reserve variability, and materializes results for reporting. Correctness of the money math is guarded by newtype units and exhaustive pattern matching.
TECH_STACK: GHC + Conduit + Persistent + PostgreSQL, statistics + vector for simulation, Stack build, orchestrated by cron on an on-prem cluster
APP_TYPE: data pipeline
LANGUAGE: Haskell
SCALE: 3M policies, 10k bootstrap runs, 4-hour window
```

## 9. Routeful — GraphQL gateway service

```text
APP_DESCRIPTION: A GraphQL gateway that federates several internal REST and gRPC services behind one typed schema. It validates queries against the schema at request time, batches downstream calls with dataloaders, and enforces per-field authorization. Resolvers are pure where possible and effects are isolated in a small effect layer.
TECH_STACK: GHC + morpheus-graphql + Warp + http-client, Redis via hedis for caching, Cabal build, deployed on Google Cloud Run
APP_TYPE: API service
LANGUAGE: Haskell
SCALE: 30 federated types, 1,500 queries/s
```

## 10. Formaline — form-driven survey web app

```text
APP_DESCRIPTION: A web app for building and running longitudinal research surveys. Researchers compose branching questionnaires, respondents fill them across sessions with resumable state, and exports feed downstream analysis. Question schemas are validated so an invalid branch condition cannot be published.
TECH_STACK: Yesod on GHC + Persistent + PostgreSQL + Hamlet templates, deployed behind Warp on a DigitalOcean droplet, Stack build
APP_TYPE: web app
LANGUAGE: Haskell
SCALE: 12k respondents, 40 active studies
```

## 11. Verano — property-based test runner CLI

```text
APP_DESCRIPTION: A CLI that discovers and runs property-based test suites for Haskell projects, shrinking counterexamples and persisting failing seeds for reproducibility. It prints a compact coverage summary of generated value distributions and can gate CI on minimum coverage. Test discovery walks the module tree via GHC's package database.
TECH_STACK: GHC + Hedgehog + optparse-applicative + ansi-terminal, Cabal build, released as a Hackage package and CI action
APP_TYPE: CLI
LANGUAGE: Haskell
SCALE: single user, 2,000 properties, 100k cases/run
```

## 12. Interpol — expression evaluator API

```text
APP_DESCRIPTION: An API that evaluates user-supplied spreadsheet-style formulas safely in a sandbox. It parses expressions, type-checks them against a declared cell schema, and evaluates with bounded recursion and no side effects. Malicious or divergent inputs are rejected before evaluation by a totality-aware checker.
TECH_STACK: GHC + Servant + Megaparsec + containers, Hasql + PostgreSQL for saved sheets, Nix build, deployed on Fly.io
APP_TYPE: API service
LANGUAGE: Haskell
SCALE: 8k saved sheets, 1,000 evals/s
```

## 13. Sifter — deduplication data pipeline

```text
APP_DESCRIPTION: A batch pipeline that deduplicates and clusters contact records from many CRM exports. It normalizes names and addresses, computes locality-sensitive hashes for candidate blocking, and scores pairs for a merge decision. Streaming Conduit stages keep memory bounded over tens of millions of rows.
TECH_STACK: GHC + Conduit + text-icu + PostgreSQL via Persistent, Stack build, scheduled on Apache Airflow calling a container
APP_TYPE: data pipeline
LANGUAGE: Haskell
SCALE: 60M records, 200M candidate pairs
```

## 14. Sentinel — feature flag API service

```text
APP_DESCRIPTION: A feature-flag and experiment-assignment API. It evaluates targeting rules against user attributes, assigns deterministic experiment buckets, and streams flag changes to SDKs over server-sent events. Rule evaluation is pure and covered by golden tests so flips are predictable across regions.
TECH_STACK: GHC + Servant + STM + hedis Redis + PostgreSQL, Warp, Cabal build, deployed on Kubernetes across three regions
APP_TYPE: API service
LANGUAGE: Haskell
SCALE: 2M users, 1,200 flags, 5,000 evals/s
```

## 15. Lambdoc — literate docs generator CLI

```text
APP_DESCRIPTION: A CLI that generates API documentation from Haskell source by extracting Haddock comments, type signatures, and example blocks, then rendering a static site. It cross-links types to definitions and runs doctest examples to keep docs honest. Output is fully static HTML with a search index.
TECH_STACK: GHC + haskell-src-exts + pandoc + lucid, optparse-applicative CLI, Nix build, published as a Hackage tool
APP_TYPE: CLI
LANGUAGE: Haskell
SCALE: single user, 500-module projects
```

## 16. Chainlink — blockchain indexer service

```text
APP_DESCRIPTION: An indexer that follows an EVM chain, decodes contract events against supplied ABIs, and exposes a queryable API of decoded activity. It handles chain reorganizations by rolling back affected blocks and re-applying, keeping the index consistent. Decoders are generated from ABI JSON at startup.
TECH_STACK: GHC + Servant + web3 JSON-RPC client + Hasql + PostgreSQL, Streamly for block streaming, Stack build, deployed on bare-metal
APP_TYPE: API service
LANGUAGE: Haskell
SCALE: 18M blocks indexed, 4 contracts, 600 req/s
```

## 17. Cobbler — static site build pipeline

```text
APP_DESCRIPTION: A build pipeline that turns a Markdown content repository into a static website with incremental rebuilds. It tracks dependencies between templates, snippets, and pages so only affected outputs are regenerated. The dependency graph is expressed as a Shake ruleset for reliable minimal rebuilds.
TECH_STACK: GHC + Shake + pandoc + lucid, Nix-pinned toolchain, output deployed to Cloudflare Pages via CI
APP_TYPE: data pipeline
LANGUAGE: Haskell
SCALE: 3,000 pages, sub-second incremental builds
```

## 18. Warden — auth and session API

```text
APP_DESCRIPTION: An authentication service issuing signed session tokens and handling password, TOTP, and WebAuthn flows. It rate-limits attempts, rotates signing keys, and exposes JWKS for downstream verification. All token claims are modeled as records so malformed tokens are rejected during decoding.
TECH_STACK: GHC + Servant + jose + Hasql + PostgreSQL + hedis Redis, Warp, Cabal build, deployed on AWS ECS
APP_TYPE: API service
LANGUAGE: Haskell
SCALE: 5M accounts, 8,000 logins/min
```

## 19. Tessellate — geospatial tiling pipeline

```text
APP_DESCRIPTION: A pipeline that ingests raw GPS trace batches, snaps points to a road network, and aggregates them into map vector tiles by zoom level. It partitions work by tile quadkey and writes protobuf tiles to object storage. Heavy numeric snapping runs over unboxed vectors for throughput.
TECH_STACK: GHC + Conduit + vector + proto-lens, PostGIS on PostgreSQL, Stack build, run as a Nomad batch job
APP_TYPE: data pipeline
LANGUAGE: Haskell
SCALE: 200M points/day, 14 zoom levels
```

## 20. Scholar — citation graph web app

```text
APP_DESCRIPTION: A web app that lets researchers explore a citation graph, follow reference chains, and save reading lists. It renders interactive neighborhoods of papers and computes influence scores on demand. Graph queries are cached and served from a typed data layer with pure ranking functions.
TECH_STACK: Yesod on GHC + Esqueleto + PostgreSQL, Warp, Stack build, deployed on a Linode instance behind Caddy
APP_TYPE: web app
LANGUAGE: Haskell
SCALE: 8M papers, 90M citation edges
```

## 21. Regexly — pattern testing CLI

```text
APP_DESCRIPTION: A CLI for authoring and testing regular expressions against sample corpora with instant match highlighting. It explains each captured group, times alternatives, and warns about catastrophic backtracking risks. Patterns are compiled to a safe automaton before running against files.
TECH_STACK: GHC + regex-tdfa + optparse-applicative + ansi-terminal, Cabal build, distributed via Homebrew and static release
APP_TYPE: CLI
LANGUAGE: Haskell
SCALE: single user, 500 MB corpora
```

## 22. Almanac — scheduling and calendar API

```text
APP_DESCRIPTION: A scheduling API that computes recurring event expansions, resolves timezone rules, and detects conflicts across shared calendars. Recurrence rules follow the iCalendar spec and are expanded lazily so far-future queries stay cheap. All time arithmetic uses explicit zoned types to prevent offset bugs.
TECH_STACK: GHC + Servant + time + Persistent + PostgreSQL, hedis Redis, Stack build, deployed on Fly.io
APP_TYPE: API service
LANGUAGE: Haskell
SCALE: 300k calendars, 2M events, 900 req/s
```

## 23. Distillery — data validation pipeline

```text
APP_DESCRIPTION: A validation pipeline that runs incoming vendor data feeds through a declarative schema of constraints and produces a quality report with row-level errors. Valid rows flow to a warehouse while rejects go to a quarantine table with reasons. Constraints are composable validators that accumulate all failures rather than short-circuiting.
TECH_STACK: GHC + Conduit + validation + Beam + PostgreSQL, Stack build, scheduled via Dagster invoking a container
APP_TYPE: data pipeline
LANGUAGE: Haskell
SCALE: 40 feeds, 25M rows/day
```

## 24. Notion — note-taking web app

```text
APP_DESCRIPTION: A collaborative note-taking web app with nested documents, backlinks, and full-text search. Edits are merged with a conflict-free replicated data type so concurrent writers converge without a central lock. The document tree is persisted as an event log and projected into read models.
TECH_STACK: IHP on GHC + PostgreSQL, WebSockets for live sync, HSX views, Nix build, deployed to a managed VM
APP_TYPE: web app
LANGUAGE: Haskell
SCALE: 40k users, 1.2M documents
```

## 25. Typewright — schema migration CLI

```text
APP_DESCRIPTION: A CLI that diffs a declarative database schema against a live database and generates ordered, reversible migration scripts. It detects unsafe operations, wraps changes in transactions, and records applied versions. The diff engine models schema objects as algebraic data types for exhaustive comparison.
TECH_STACK: GHC + postgresql-simple + optparse-applicative + prettyprinter, Cabal build, released on Hackage and as a binary
APP_TYPE: CLI
LANGUAGE: Haskell
SCALE: single user, 400-table schemas
```

## 26. Broker — message queue API service

```text
APP_DESCRIPTION: A lightweight message broker exposing publish, subscribe, and acknowledge over HTTP and WebSockets with at-least-once delivery. It persists undelivered messages, retries with backoff, and enforces per-topic ordering. In-flight state is coordinated with STM transactions for lock-free concurrency.
TECH_STACK: GHC + Warp + STM + Hasql + PostgreSQL, Cabal build, deployed on Kubernetes with a persistent volume
APP_TYPE: API service
LANGUAGE: Haskell
SCALE: 2,000 topics, 20k messages/s
```

## 27. Prospect — mining telemetry pipeline

```text
APP_DESCRIPTION: A pipeline that ingests sensor telemetry from industrial mining equipment, aligns readings to a common clock, and computes rolling health indicators for predictive maintenance. Out-of-order and gappy sensor streams are windowed and interpolated deterministically. Anomaly thresholds are configurable per machine class.
TECH_STACK: GHC + Streamly + vector + TimescaleDB on PostgreSQL, Stack build, running on an edge gateway plus cloud tier
APP_TYPE: data pipeline
LANGUAGE: Haskell
SCALE: 5,000 sensors, 1 Hz, 90-day retention
```

## 28. Curator — media metadata API

```text
APP_DESCRIPTION: An API that manages a media asset catalog, extracting and normalizing metadata, generating perceptual hashes for near-duplicate detection, and serving faceted search. It reconciles conflicting metadata sources with a deterministic precedence rule. Search facets are computed from typed indices.
TECH_STACK: GHC + Servant + Beam + PostgreSQL, hedis Redis for facets, Nix build, deployed on Google Cloud Run
APP_TYPE: API service
LANGUAGE: Haskell
SCALE: 6M assets, 700 req/s
```

## 29. Verity — formal spec checker CLI

```text
APP_DESCRIPTION: A CLI that checks small protocol specifications written in a state-machine DSL for safety and liveness properties via bounded model checking. It reports the shortest violating trace and can export the transition system for external tools. The DSL is parsed and elaborated into an explicit state graph.
TECH_STACK: GHC + Megaparsec + containers + sbv, optparse-applicative, Cabal build, distributed via Nix and Hackage
APP_TYPE: CLI
LANGUAGE: Haskell
SCALE: single user, 10M-state models
```

## 30. Emporium — inventory management API

```text
APP_DESCRIPTION: An inventory API for a multi-warehouse retailer that tracks stock levels, reservations, and transfers with strict consistency. Reservations decrement available stock atomically and expire if unconfirmed. Quantities carry unit-of-measure types so a case can never be added to a pallet by mistake.
TECH_STACK: GHC + Servant + Esqueleto + PostgreSQL, hedis Redis, Stack build, deployed on AWS ECS Fargate
APP_TYPE: API service
LANGUAGE: Haskell
SCALE: 50 warehouses, 400k SKUs, 1,000 req/s
```

## 31. Refract — image processing pipeline

```text
APP_DESCRIPTION: A batch pipeline that ingests uploaded photos, generates responsive derivatives, strips sensitive EXIF data, and packs them into a CDN-ready manifest. Work is fanned out across a bounded worker pool and results are recorded idempotently. Pixel operations run over strict arrays for speed.
TECH_STACK: GHC + Conduit + JuicyPixels + amazonka-s3, PostgreSQL for job state, Stack build, run on ECS with SQS triggers
APP_TYPE: data pipeline
LANGUAGE: Haskell
SCALE: 2M images/day, 5 derivatives each
```

## 32. Beacon — status page web app

```text
APP_DESCRIPTION: A public status and incident web app where operators post updates and subscribers see live service health. It aggregates probe results into component status, renders historical uptime, and sends notifications on state changes. Component state transitions are modeled as a typed state machine.
TECH_STACK: Yesod on GHC + Persistent + PostgreSQL, Warp with WebSockets, Stack build, deployed on Render
APP_TYPE: web app
LANGUAGE: Haskell
SCALE: 500 monitored components, 30k subscribers
```

## 33. Ledgerline — invoicing CLI

```text
APP_DESCRIPTION: A CLI for freelancers that generates invoices from a plain-text time-tracking log, applies tax rules, and renders branded PDFs. It computes totals with exact decimal arithmetic and can reconcile against paid amounts. The time log grammar is parsed with precise error reporting.
TECH_STACK: GHC + Megaparsec + optparse-applicative + hpdf, local SQLite via sqlite-simple, Cabal build, released via Homebrew
APP_TYPE: CLI
LANGUAGE: Haskell
SCALE: single user, 2,000 invoices/year
```

## 34. Synapse — recommendation API service

```text
APP_DESCRIPTION: A recommendation API that serves item suggestions from precomputed similarity models with real-time filtering by availability and user context. Model lookups are pure vector operations and business rules layer on top. It supports A/B routing of different ranking strategies behind one endpoint.
TECH_STACK: GHC + Servant + vector + hedis Redis + PostgreSQL, Nix build, deployed on Kubernetes with horizontal autoscaling
APP_TYPE: API service
LANGUAGE: Haskell
SCALE: 3M items, 4,000 req/s, p99 25 ms
```

## 35. Threshold — fraud scoring pipeline

```text
APP_DESCRIPTION: A pipeline that scores transaction batches for fraud using rule ensembles and velocity features computed over sliding windows. It joins each transaction against account history, applies weighted rules, and flags cases for review. Feature computation is deterministic and replayable for audits.
TECH_STACK: GHC + Streamly + Beam + PostgreSQL, hedis Redis for velocity state, Stack build, orchestrated by Airflow
APP_TYPE: data pipeline
LANGUAGE: Haskell
SCALE: 80M transactions/day, 200 rules
```

## 36. Cartogram — mapping tiles API

```text
APP_DESCRIPTION: An API that serves precomputed vector map tiles and performs on-the-fly point-in-polygon lookups for administrative boundaries. Spatial indices accelerate lookups and tile bytes are cached aggressively. Geometry predicates are pure functions tested against reference fixtures.
TECH_STACK: GHC + Scotty + PostGIS on PostgreSQL, hedis Redis, Cabal build, deployed on Hetzner behind a CDN
APP_TYPE: API service
LANGUAGE: Haskell
SCALE: 30M tiles cached, 2,500 req/s
```

## 37. Compiler — toy language transpiler CLI

```text
APP_DESCRIPTION: A CLI that compiles a small statically typed teaching language to JavaScript, with lexing, parsing, type inference, and code generation stages. It emits readable source maps and precise type errors with suggested fixes. Type inference is a Hindley-Milner engine with clear diagnostics.
TECH_STACK: GHC + Megaparsec + unification-fd + prettyprinter, optparse-applicative, Cabal build, published on Hackage
APP_TYPE: CLI
LANGUAGE: Haskell
SCALE: single user, 20k-line programs
```

## 38. Custodian — secrets management API

```text
APP_DESCRIPTION: A secrets API that stores encrypted values, issues short-lived leases, and audits every access. Encryption keys are wrapped by a master key and rotated on schedule, with envelope decryption on read. Lease lifetimes and access policies are modeled as explicit types checked at request time.
TECH_STACK: GHC + Servant + cryptonite + Hasql + PostgreSQL, hedis Redis for leases, Nix build, deployed on Kubernetes
APP_TYPE: API service
LANGUAGE: Haskell
SCALE: 200k secrets, 1,500 req/s
```

## 39. Harvest — web scraping pipeline

```text
APP_DESCRIPTION: A polite scraping pipeline that crawls a set of catalog sites, extracts structured product data, and normalizes it into a unified schema. It respects robots rules, throttles per host, and retries transient failures with backoff. Extraction selectors are typed and versioned so site changes fail loudly.
TECH_STACK: GHC + http-conduit + tagsoup + Conduit + PostgreSQL, Stack build, scheduled on a cron worker
APP_TYPE: data pipeline
LANGUAGE: Haskell
SCALE: 500 sites, 2M pages/day
```

## 40. Portal — customer support web app

```text
APP_DESCRIPTION: A customer support web app with ticket queues, canned replies, and SLA timers. Agents claim tickets, thread conversations, and escalate based on typed priority rules. SLA breach detection runs on a background scheduler and surfaces at-risk tickets prominently.
TECH_STACK: IHP on GHC + PostgreSQL, Auto-refresh for live queues, Nix build, deployed on a managed container platform
APP_TYPE: web app
LANGUAGE: Haskell
SCALE: 300 agents, 5,000 tickets/day
```

## 41. Tinker — build tool orchestrator CLI

```text
APP_DESCRIPTION: A CLI that orchestrates monorepo builds by computing an affected-target graph from file changes and running only necessary tasks in dependency order. It caches task outputs by content hash and parallelizes independent work. The task graph is a Shake ruleset with content-addressed caching.
TECH_STACK: GHC + Shake + optparse-applicative + async, Nix build, distributed as a static binary
APP_TYPE: CLI
LANGUAGE: Haskell
SCALE: single user, 800-package monorepos
```

## 42. Oracle — pricing feed API service

```text
APP_DESCRIPTION: An API that aggregates market data from several exchange feeds, computes a consolidated mid-price, and serves it with staleness guarantees. Feed handlers run concurrently and a pure aggregator combines the latest quotes. Downstream consumers get a signed price with a freshness timestamp.
TECH_STACK: GHC + Warp + STM + websockets client + hedis Redis, Cabal build, deployed on bare-metal near an exchange
APP_TYPE: API service
LANGUAGE: Haskell
SCALE: 200 symbols, 50k updates/s
```

## 43. Foundry — data warehouse loader pipeline

```text
APP_DESCRIPTION: A loader pipeline that reads change-data-capture streams from operational databases and applies them to a columnar warehouse with exactly-once semantics. It batches by table, orders by log sequence, and handles schema evolution gracefully. Idempotency keys prevent double application on retries.
TECH_STACK: GHC + Conduit + Beam + PostgreSQL source + ClickHouse sink, Stack build, run on Kubernetes CronJobs
APP_TYPE: data pipeline
LANGUAGE: Haskell
SCALE: 60 tables, 150M changes/day
```

## 44. Almond — nutrition tracking web app

```text
APP_DESCRIPTION: A nutrition tracking web app where users log meals, and the system computes macro and micronutrient totals against goals. It looks up foods from a curated database and supports custom recipes with scaled servings. All nutrient math uses typed quantities to avoid unit mix-ups.
TECH_STACK: Yesod on GHC + Persistent + PostgreSQL, Warp, Stack build, deployed on Fly.io
APP_TYPE: web app
LANGUAGE: Haskell
SCALE: 60k users, 2M logged meals
```

## 45. Diffy — JSON diff and patch CLI

```text
APP_DESCRIPTION: A CLI that computes structural diffs between JSON documents, emits RFC-style patches, and can apply or invert them. It renders human-readable colorized diffs and supports array move detection. The diff algorithm operates over a typed JSON tree with stable ordering.
TECH_STACK: GHC + Aeson + optparse-applicative + prettyprinter, Cabal build, released on Homebrew and Hackage
APP_TYPE: CLI
LANGUAGE: Haskell
SCALE: single user, 50 MB documents
```

## 46. Sentry — rate limiting API service

```text
APP_DESCRIPTION: An API gateway component that enforces per-key rate limits using token-bucket and sliding-window algorithms with distributed counters. It returns standard rate-limit headers and supports burst allowances. Counter updates are atomic across nodes via Redis scripts.
TECH_STACK: GHC + Warp + hedis Redis + STM, Cabal build, deployed as a sidecar on Kubernetes
APP_TYPE: API service
LANGUAGE: Haskell
SCALE: 500k keys, 30k req/s
```

## 47. Reactor — event sourcing API

```text
APP_DESCRIPTION: An event-sourced API for an order management domain that appends commands to an event log and projects read models. Aggregates enforce invariants when handling commands and reject illegal transitions. Projections rebuild deterministically from the log for auditability and recovery.
TECH_STACK: GHC + Servant + eventstore + Hasql + PostgreSQL projections, Stack build, deployed on AWS ECS
APP_TYPE: API service
LANGUAGE: Haskell
SCALE: 5M orders, 40M events, 800 req/s
```

## 48. Percolate — analytics rollup pipeline

```text
APP_DESCRIPTION: A pipeline that computes daily and hourly analytics rollups from a raw events table into pre-aggregated summary tables for a dashboard. It handles late-arriving events by recomputing affected windows. Aggregation logic is expressed as composable pure folds over streams.
TECH_STACK: GHC + Streamly + Esqueleto + PostgreSQL, Stack build, scheduled by cron in a container
APP_TYPE: data pipeline
LANGUAGE: Haskell
SCALE: 300M events/day, 40 metrics
```

## 49. Vellum — e-book conversion CLI

```text
APP_DESCRIPTION: A CLI that converts Markdown and reStructuredText manuscripts into validated EPUB and PDF, managing chapters, footnotes, and a table of contents. It checks internal links and image references before packaging. The document model is a typed AST transformed through rendering passes.
TECH_STACK: GHC + pandoc + Megaparsec + zip-archive, optparse-applicative, Nix build, distributed as a binary
APP_TYPE: CLI
LANGUAGE: Haskell
SCALE: single user, 600-page books
```

## 50. Gatekeeper — API key management service

```text
APP_DESCRIPTION: A service that issues, scopes, and revokes API keys, tracks usage quotas, and exposes an introspection endpoint for gateways. Keys are hashed at rest and scopes are enforced as typed capability sets. Quota accounting is eventually consistent with a fast in-memory tier.
TECH_STACK: GHC + Servant + Hasql + PostgreSQL + hedis Redis, Nix build, deployed on Google Cloud Run
APP_TYPE: API service
LANGUAGE: Haskell
SCALE: 400k keys, 2,000 req/s
```

## 51. Loom — dependency resolver CLI

```text
APP_DESCRIPTION: A CLI that resolves package version constraints for a language ecosystem, producing a lockfile that satisfies all bounds or explaining the conflict. It models resolution as a constraint problem and searches deterministically. Conflicts are reported with the minimal unsatisfiable set.
TECH_STACK: GHC + containers + sbv + optparse-applicative, Cabal build, released on Hackage
APP_TYPE: CLI
LANGUAGE: Haskell
SCALE: single user, 5,000-package graphs
```

## 52. Envoy — webhook delivery API

```text
APP_DESCRIPTION: A webhook delivery service that accepts events, signs payloads, and delivers them to subscriber endpoints with retries and exponential backoff. It tracks delivery attempts, supports replay, and circuit-breaks failing endpoints. Delivery state is coordinated so an event is never lost or double-sent.
TECH_STACK: GHC + Servant + http-client + Hasql + PostgreSQL + hedis Redis, Stack build, deployed on Kubernetes
APP_TYPE: API service
LANGUAGE: Haskell
SCALE: 20k endpoints, 5M deliveries/day
```

## 53. Alchemy — CSV transformation pipeline

```text
APP_DESCRIPTION: A pipeline that ingests messy CSV exports, applies a declarative mapping to a canonical schema, and loads cleaned data into a warehouse. It coerces types safely, reports unparseable rows, and preserves provenance. Transformations are pure column functions composed into a stream.
TECH_STACK: GHC + cassava + Conduit + Beam + PostgreSQL, Stack build, run on a scheduled container
APP_TYPE: data pipeline
LANGUAGE: Haskell
SCALE: 100 sources, 40M rows/day
```

## 54. Kanban — project board web app

```text
APP_DESCRIPTION: A project management web app with drag-and-drop boards, swimlanes, and work-in-progress limits. Card moves are validated against column rules and history is retained. Live updates propagate to all viewers so boards stay in sync during standups.
TECH_STACK: IHP on GHC + PostgreSQL, WebSockets for sync, HSX views, Nix build, deployed on a managed VM
APP_TYPE: web app
LANGUAGE: Haskell
SCALE: 8k teams, 500k cards
```

## 55. Prism — GraphQL schema linter CLI

```text
APP_DESCRIPTION: A CLI that lints GraphQL schemas for naming conventions, deprecation hygiene, and breaking changes against a baseline. It fails CI on incompatible changes and suggests safe alternatives. Schema comparison walks a typed representation to classify each change.
TECH_STACK: GHC + graphql-parser + optparse-applicative + Aeson, Cabal build, distributed as a CI action and binary
APP_TYPE: CLI
LANGUAGE: Haskell
SCALE: single user, 1,000-type schemas
```

## 56. Aperture — telemetry ingestion API

```text
APP_DESCRIPTION: A high-throughput ingestion API that accepts metrics and traces over gRPC and HTTP, batches them, and writes to a time-series backend. It applies sampling and cardinality guards to protect the store. Incoming spans are validated and enriched with resource attributes.
TECH_STACK: GHC + Warp + proto-lens + Conduit + TimescaleDB, Cabal build, deployed on Kubernetes with autoscaling
APP_TYPE: API service
LANGUAGE: Haskell
SCALE: 1M spans/s peak, 30-day retention
```

## 57. Reckon — tax calculation API

```text
APP_DESCRIPTION: A tax calculation API that determines sales and VAT amounts by jurisdiction, product category, and exemption rules. Rate tables are versioned by effective date so historical calculations are reproducible. Money is exact decimal and rounding follows explicit per-jurisdiction rules.
TECH_STACK: GHC + Servant + Persistent + PostgreSQL, hedis Redis for rate cache, Stack build, deployed on Fly.io
APP_TYPE: API service
LANGUAGE: Haskell
SCALE: 12k jurisdictions, 3,000 req/s
```

## 58. Cascade — DAG job scheduler pipeline

```text
APP_DESCRIPTION: A pipeline orchestrator that runs a directed acyclic graph of jobs with declared dependencies, retries, and resource limits. It schedules ready jobs onto workers and records run history for reproducibility. The DAG is validated for cycles and typing before any job starts.
TECH_STACK: GHC + async + STM + Hasql + PostgreSQL, Stack build, deployed on Nomad
APP_TYPE: data pipeline
LANGUAGE: Haskell
SCALE: 2,000 jobs/run, 50 workers
```

## 59. Booking — reservations web app

```text
APP_DESCRIPTION: A reservations web app for clinics that manages provider calendars, patient bookings, and waitlists. It prevents double-booking with transactional slot holds and sends reminders. Available slots are computed from provider rules and existing appointments on demand.
TECH_STACK: Yesod on GHC + Esqueleto + PostgreSQL, Warp, Stack build, deployed on a DigitalOcean droplet
APP_TYPE: web app
LANGUAGE: Haskell
SCALE: 1,500 providers, 400k bookings/year
```

## 60. Sculpt — code formatter CLI

```text
APP_DESCRIPTION: A CLI code formatter for a configuration language that parses source, applies canonical layout rules, and rewrites files idempotently. It preserves comments and can check formatting in CI without writing. Formatting is a pure function from AST to layout, guaranteeing stable output.
TECH_STACK: GHC + Megaparsec + prettyprinter + optparse-applicative, Cabal build, released on Hackage and Homebrew
APP_TYPE: CLI
LANGUAGE: Haskell
SCALE: single user, 100k-line codebases
```

## 61. Nexus — service registry API

```text
APP_DESCRIPTION: A service discovery API where instances register with health metadata and clients query healthy endpoints by service name. It expires stale registrations and streams changes to watchers. The registry state is held in STM for consistent concurrent reads and writes.
TECH_STACK: GHC + Servant + STM + hedis Redis, Cabal build, deployed as a cluster on Kubernetes
APP_TYPE: API service
LANGUAGE: Haskell
SCALE: 50k instances, 10k queries/s
```

## 62. Foliage — genomics variant pipeline

```text
APP_DESCRIPTION: A bioinformatics pipeline that reads aligned sequencing files, calls variants against a reference, annotates them, and emits a filtered report. It streams large files region by region to bound memory and parallelizes across contigs. Coordinate arithmetic uses typed intervals to avoid off-by-one errors.
TECH_STACK: GHC + Conduit + bytestring + vector, PostgreSQL for annotations, Stack build, run on an HPC scheduler
APP_TYPE: data pipeline
LANGUAGE: Haskell
SCALE: 500 samples, 30x coverage each
```

## 63. Wallet — crypto custody API

```text
APP_DESCRIPTION: A custody API that manages hierarchical deterministic wallets, derives addresses, and constructs signed transactions for approval. Private keys stay in a hardware-backed signer and only signature requests cross the boundary. Derivation paths and amounts are typed to prevent malformed transactions.
TECH_STACK: GHC + Servant + cryptonite + Hasql + PostgreSQL, Nix build, deployed on hardened bare-metal
APP_TYPE: API service
LANGUAGE: Haskell
SCALE: 200k wallets, 500 signs/min
```

## 64. Lantern — search indexing pipeline

```text
APP_DESCRIPTION: A pipeline that consumes document updates, tokenizes and analyzes text, and builds an inverted index served to a search API. It handles deletes and updates incrementally and merges segments in the background. Analysis stages are pure and configurable per field.
TECH_STACK: GHC + Streamly + text-icu + Hasql + PostgreSQL, Stack build, run on Kubernetes with a persistent index volume
APP_TYPE: data pipeline
LANGUAGE: Haskell
SCALE: 20M documents, 5k updates/s
```

## 65. Atrium — real estate listings web app

```text
APP_DESCRIPTION: A real estate web app where agents post listings and buyers search by geography, price, and features with saved alerts. It renders map-based results and computes commute estimates. Search filters are typed and translated to spatial and range queries safely.
TECH_STACK: IHP on GHC + PostGIS on PostgreSQL, Nix build, deployed on a managed container platform
APP_TYPE: web app
LANGUAGE: Haskell
SCALE: 300k listings, 40k daily searches
```

## 66. Bytecode — WASM assembler CLI

```text
APP_DESCRIPTION: A CLI that assembles a textual stack-machine language into WebAssembly modules, validating types and stack balance before emitting bytes. It reports precise errors for stack underflow and type mismatch. The validator models the stack as a typed abstract interpreter.
TECH_STACK: GHC + Megaparsec + bytestring + optparse-applicative, Cabal build, published on Hackage
APP_TYPE: CLI
LANGUAGE: Haskell
SCALE: single user, 10k-instruction modules
```

## 67. Quorum — distributed lock API

```text
APP_DESCRIPTION: A distributed locking API providing fenced leases so clients can coordinate exclusive access to resources. Leases carry monotonic tokens to prevent stale holders from acting. Lock acquisition and renewal are atomic operations with configurable timeouts.
TECH_STACK: GHC + Warp + hedis Redis + STM, Cabal build, deployed on Kubernetes across zones
APP_TYPE: API service
LANGUAGE: Haskell
SCALE: 100k locks, 8,000 acquisitions/s
```

## 68. Tributary — IoT data pipeline

```text
APP_DESCRIPTION: A pipeline that ingests MQTT messages from smart-building sensors, normalizes units, and computes occupancy and energy metrics per zone. It buffers bursts, deduplicates by device sequence, and writes to a time-series store. Unit conversions are enforced by typed quantities.
TECH_STACK: GHC + net-mqtt + Streamly + TimescaleDB on PostgreSQL, Stack build, run on an edge gateway
APP_TYPE: data pipeline
LANGUAGE: Haskell
SCALE: 10k devices, 5 msg/s each
```

## 69. Ballot — voting platform web app

```text
APP_DESCRIPTION: A web app for running organizational elections with ranked-choice ballots, eligibility checks, and transparent tallying. Votes are recorded immutably and tallies are recomputable from the ballot log. The counting algorithm is a pure, tested implementation of instant-runoff rounds.
TECH_STACK: Yesod on GHC + Persistent + PostgreSQL, Warp, Stack build, deployed on Render
APP_TYPE: web app
LANGUAGE: Haskell
SCALE: 200 elections/year, 100k voters each
```

## 70. Splice — audio metadata CLI

```text
APP_DESCRIPTION: A CLI that batch-edits audio file tags, normalizes track metadata against an online database, and renames files by a template. It parses container formats to read and write tags safely and previews changes before applying. Rename templates are parsed into a typed format string.
TECH_STACK: GHC + Megaparsec + bytestring + optparse-applicative, local SQLite cache, Cabal build, released via Homebrew
APP_TYPE: CLI
LANGUAGE: Haskell
SCALE: single user, 50k-track libraries
```

## 71. Cipher — encryption gateway API

```text
APP_DESCRIPTION: An encryption gateway that transparently encrypts fields before storage and decrypts on retrieval based on per-field policy. It manages key versions, supports deterministic encryption for searchable fields, and audits access. Field policies are typed and validated at startup.
TECH_STACK: GHC + Servant + cryptonite + Hasql + PostgreSQL, Nix build, deployed on Kubernetes
APP_TYPE: API service
LANGUAGE: Haskell
SCALE: 300 protected fields, 4,000 req/s
```

## 72. Sediment — backup snapshot pipeline

```text
APP_DESCRIPTION: A backup pipeline that takes incremental content-addressed snapshots of file trees, deduplicates chunks, and uploads them encrypted to object storage. It prunes old snapshots by retention policy and verifies integrity on read. Chunk boundaries use content-defined chunking for stable dedup.
TECH_STACK: GHC + Conduit + cryptonite + amazonka-s3, SQLite index, Stack build, run as a scheduled agent
APP_TYPE: data pipeline
LANGUAGE: Haskell
SCALE: 5M chunks, 2 TB protected
```

## 73. Concord — contract review API

```text
APP_DESCRIPTION: An API that parses legal contract clauses into a structured model and checks them against a policy rulebook, flagging risky or missing terms. It highlights clause locations and suggests standard language. Clause classification runs over a typed document representation.
TECH_STACK: GHC + Servant + Megaparsec + Persistent + PostgreSQL, Stack build, deployed on AWS ECS
APP_TYPE: API service
LANGUAGE: Haskell
SCALE: 200k contracts, 600 req/s
```

## 74. Estuary — data lake compaction pipeline

```text
APP_DESCRIPTION: A maintenance pipeline that compacts small files in a data lake into optimally sized columnar files, rewrites partition layouts, and updates the table catalog atomically. It runs during low-traffic windows and validates row counts before swapping. Compaction planning is a pure function over file statistics.
TECH_STACK: GHC + Conduit + parquet + amazonka-s3, PostgreSQL catalog, Stack build, run on Kubernetes CronJobs
APP_TYPE: data pipeline
LANGUAGE: Haskell
SCALE: 2M files compacted, 50 TB lake
```

## 75. Studio — no-code form builder web app

```text
APP_DESCRIPTION: A web app where non-technical users build data-entry forms with validation and conditional logic, then share them publicly. Submissions are stored against a generated schema and exportable. Form definitions are validated so an impossible validation rule cannot be saved.
TECH_STACK: IHP on GHC + PostgreSQL, Nix build, deployed on a managed container host
APP_TYPE: web app
LANGUAGE: Haskell
SCALE: 25k forms, 3M submissions
```

## 76. Yardstick — benchmark harness CLI

```text
APP_DESCRIPTION: A CLI that runs micro-benchmarks, computes statistically robust timing estimates, and compares runs to detect regressions. It controls for variance with resampling and reports confidence intervals. Regression thresholds are configurable and gate CI builds.
TECH_STACK: GHC + criterion + statistics + optparse-applicative, Cabal build, published on Hackage
APP_TYPE: CLI
LANGUAGE: Haskell
SCALE: single user, 500 benchmarks/run
```

## 77. Relay — chat backend API

```text
APP_DESCRIPTION: A chat backend serving channels, direct messages, and presence over WebSockets with message history and read receipts. Fan-out to connected clients is coordinated concurrently and history is paginated from durable storage. Message ordering per channel is guaranteed by monotonic sequence numbers.
TECH_STACK: GHC + Warp + websockets + STM + Hasql + PostgreSQL, Stack build, deployed on Kubernetes
APP_TYPE: API service
LANGUAGE: Haskell
SCALE: 500k connections, 40k messages/s
```

## 78. Ledger — reconciliation pipeline

```text
APP_DESCRIPTION: A financial reconciliation pipeline that matches internal transaction records against bank statements, classifies breaks, and produces an exception report. Matching runs multiple strategies in priority order and records why each pair matched. Amounts are exact decimals and matching is fully deterministic for audit.
TECH_STACK: GHC + Conduit + Beam + PostgreSQL, Stack build, scheduled via Airflow
APP_TYPE: data pipeline
LANGUAGE: Haskell
SCALE: 30M transactions/month, 12 sources
```

## 79. Compass — API documentation web app

```text
APP_DESCRIPTION: A web app that renders interactive API reference and a try-it console from OpenAPI specifications. It validates specs on upload, generates code samples, and keeps versions browsable. The spec is parsed into a typed model that drives both navigation and request forms.
TECH_STACK: Yesod on GHC + Aeson + PostgreSQL, Warp, Stack build, deployed on Fly.io
APP_TYPE: web app
LANGUAGE: Haskell
SCALE: 5k specs, 20k daily readers
```

## 80. Sandbox — expression fuzzer CLI

```text
APP_DESCRIPTION: A CLI that fuzzes parsers and interpreters by generating structured random inputs from a grammar, minimizing any crashing input to a small reproducer. It records seeds and coverage-guided corpora across runs. Input generation is driven by typed generators for well-formed-ish inputs.
TECH_STACK: GHC + Hedgehog + containers + optparse-applicative, Cabal build, distributed as a binary
APP_TYPE: CLI
LANGUAGE: Haskell
SCALE: single user, 1M inputs/run
```

## 81. Meridian — currency conversion API

```text
APP_DESCRIPTION: A currency conversion API that maintains rate tables from multiple providers, computes cross-rates, and applies configurable spreads per client. Historical rates are queryable by timestamp for reproducible conversions. Money and rates are typed so mixing currencies is a compile error.
TECH_STACK: GHC + Servant + Persistent + PostgreSQL + hedis Redis, Stack build, deployed on Google Cloud Run
APP_TYPE: API service
LANGUAGE: Haskell
SCALE: 180 currencies, 5,000 req/s
```

## 82. Weft — text mining pipeline

```text
APP_DESCRIPTION: A text mining pipeline that ingests news articles, extracts entities and topics, and links mentions to a knowledge base. It streams documents through tokenization, tagging, and linking stages with bounded memory. Entity linking scores candidates with pure ranking functions for repeatability.
TECH_STACK: GHC + Streamly + text-icu + Hasql + PostgreSQL, Stack build, run on Kubernetes CronJobs
APP_TYPE: data pipeline
LANGUAGE: Haskell
SCALE: 5M articles/day, 200k entities
```

## 83. Atlas — knowledge base web app

```text
APP_DESCRIPTION: An internal knowledge base web app with versioned articles, structured categories, and typed cross-references between pages. Editors preview rendered Markdown and reviewers approve changes. Broken internal links are detected at save time and block publishing.
TECH_STACK: IHP on GHC + PostgreSQL, Nix build, deployed on a self-hosted VM behind Caddy
APP_TYPE: web app
LANGUAGE: Haskell
SCALE: 40k articles, 2k editors
```

## 84. Ripcord — cron expression CLI

```text
APP_DESCRIPTION: A CLI that parses, explains, and simulates cron and interval schedules, printing the next N fire times in a chosen timezone. It validates field ranges and detects schedules that never fire. Schedule evaluation is pure over an explicit calendar model.
TECH_STACK: GHC + Megaparsec + time + optparse-applicative, Cabal build, released via Homebrew and Hackage
APP_TYPE: CLI
LANGUAGE: Haskell
SCALE: single user, arbitrary schedules
```

## 85. Beacon2 — geofencing API service

```text
APP_DESCRIPTION: A geofencing API that evaluates device locations against a set of polygons and emits enter and exit events with debouncing. Spatial indices make lookups fast and hysteresis prevents flapping at boundaries. Point-in-polygon tests are pure and validated against fixtures.
TECH_STACK: GHC + Servant + PostGIS on PostgreSQL + hedis Redis, Stack build, deployed on Kubernetes
APP_TYPE: API service
LANGUAGE: Haskell
SCALE: 50k fences, 20k location updates/s
```

## 86. Sluice — clickstream sessionization pipeline

```text
APP_DESCRIPTION: A pipeline that sessionizes raw web events into user sessions with configurable inactivity gaps, computing per-session metrics like depth and duration. Late events reopen recent sessions within a grace window. Sessionization folds are pure and replayable for backfills.
TECH_STACK: GHC + Streamly + Beam + PostgreSQL, Stack build, orchestrated by Dagster
APP_TYPE: data pipeline
LANGUAGE: Haskell
SCALE: 400M events/day, 30-minute gap
```

## 87. Quill — blogging platform web app

```text
APP_DESCRIPTION: A multi-author blogging web app with Markdown editing, scheduled publishing, and a typed tagging taxonomy. Drafts move through a review workflow and published posts render to cached static pages. Tag relationships are validated to prevent cycles in the taxonomy.
TECH_STACK: Yesod on GHC + Persistent + PostgreSQL, Warp, Stack build, deployed on a Linode instance
APP_TYPE: web app
LANGUAGE: Haskell
SCALE: 10k authors, 300k posts
```

## 88. Tincture — color palette CLI

```text
APP_DESCRIPTION: A CLI that generates accessible color palettes from a seed color, checking contrast ratios and simulating color-vision deficiencies. It exports palettes as CSS variables, JSON, or design tokens. Color math is done in a perceptual space with pure conversion functions.
TECH_STACK: GHC + colour + optparse-applicative + Aeson, Cabal build, distributed as a binary
APP_TYPE: CLI
LANGUAGE: Haskell
SCALE: single user, 20-color palettes
```

## 89. Verdict — policy evaluation API

```text
APP_DESCRIPTION: An authorization API that evaluates access requests against a declarative policy language over subjects, resources, and context. Decisions are explainable, returning which rules matched. The policy language is parsed and compiled into a decision function checked for totality.
TECH_STACK: GHC + Servant + Megaparsec + Hasql + PostgreSQL, hedis Redis, Nix build, deployed on Kubernetes
APP_TYPE: API service
LANGUAGE: Haskell
SCALE: 5k policies, 15k decisions/s
```

## 90. Foundry2 — model training data pipeline

```text
APP_DESCRIPTION: A pipeline that assembles machine-learning training datasets by joining feature tables, applying point-in-time correctness, and materializing versioned snapshots. It prevents label leakage by enforcing temporal joins and records dataset lineage. Feature transforms are pure and versioned for reproducibility.
TECH_STACK: GHC + Conduit + Beam + PostgreSQL + parquet on S3, Stack build, run on Kubernetes CronJobs
APP_TYPE: data pipeline
LANGUAGE: Haskell
SCALE: 200 features, 100M rows/snapshot
```

## 91. Praxis — habit tracker web app

```text
APP_DESCRIPTION: A habit-tracking web app where users define habits, log completions, and view streaks and heatmaps. Reminders fire on schedules and progress is summarized weekly. Streak computation is a pure fold over the completion log for consistent results across views.
TECH_STACK: IHP on GHC + PostgreSQL, Nix build, deployed on a managed container platform
APP_TYPE: web app
LANGUAGE: Haskell
SCALE: 80k users, 10M completions
```

## 92. Transom — protocol codec CLI

```text
APP_DESCRIPTION: A CLI that encodes and decodes binary protocol messages from a schema definition, useful for debugging network captures. It pretty-prints decoded fields, validates against the schema, and can synthesize sample messages. Codecs are derived from a typed schema to keep encode and decode in lockstep.
TECH_STACK: GHC + binary + Megaparsec + optparse-applicative, Cabal build, published on Hackage
APP_TYPE: CLI
LANGUAGE: Haskell
SCALE: single user, 500-field schemas
```

## 93. Custos — audit log API service

```text
APP_DESCRIPTION: An append-only audit log API that records tamper-evident events with hash chaining and supports verifiable range queries. Each entry links to its predecessor so any modification is detectable. Verification of the chain is a pure computation clients can run independently.
TECH_STACK: GHC + Servant + cryptonite + Hasql + PostgreSQL, Nix build, deployed on Kubernetes
APP_TYPE: API service
LANGUAGE: Haskell
SCALE: 500M events, 3,000 writes/s
```

## 94. Tallow — expense report pipeline

```text
APP_DESCRIPTION: A pipeline that ingests corporate card transactions, categorizes them against policy, matches receipts, and flags out-of-policy spend for review. It enriches transactions with merchant data and computes per-department rollups. Categorization rules are pure and versioned for consistent audits.
TECH_STACK: GHC + Conduit + Beam + PostgreSQL, Stack build, scheduled on Airflow
APP_TYPE: data pipeline
LANGUAGE: Haskell
SCALE: 2M transactions/month, 60 departments
```

## 95. Loomis — freight quoting API

```text
APP_DESCRIPTION: A freight quoting API that prices shipments from dimensions, weight, lanes, and carrier tariffs, returning ranked options. Tariff tables are versioned by effective date and dimensional weight is computed by carrier rules. All rates and weights are typed to prevent unit errors.
TECH_STACK: GHC + Servant + Persistent + PostgreSQL + hedis Redis, Stack build, deployed on AWS ECS
APP_TYPE: API service
LANGUAGE: Haskell
SCALE: 5k lanes, 40 carriers, 2,000 quotes/s
```

## 96. Hedgerow — portfolio risk pipeline

```text
APP_DESCRIPTION: A nightly pipeline that computes portfolio risk metrics like value-at-risk and exposure by running historical and Monte Carlo simulations over positions. It aggregates by desk and asset class and materializes reports. Simulation math runs over unboxed vectors and is property-tested against analytic bounds.
TECH_STACK: GHC + Conduit + vector + hmatrix + PostgreSQL, Stack build, run on an on-prem grid
APP_TYPE: data pipeline
LANGUAGE: Haskell
SCALE: 50k positions, 100k simulation paths
```

## 97. Vanguard — order matching engine API

```text
APP_DESCRIPTION: A limit-order matching engine exposing order submission, cancellation, and market data over a low-latency API. It maintains price-time priority order books and produces a deterministic trade tape. The book is held in memory with STM and every match is reproducible from the input sequence.
TECH_STACK: GHC + Warp + STM + vector, PostgreSQL for durable journal, Cabal build, deployed on tuned bare-metal
APP_TYPE: API service
LANGUAGE: Haskell
SCALE: 500 instruments, 100k orders/s
```

## 98. Marginal — pricing rules web app

```text
APP_DESCRIPTION: A web app for revenue teams to author and simulate pricing rules against historical orders before publishing. Rules are validated, versioned, and previewed with projected margin impact. The rule engine is a pure evaluator so simulations exactly match production behavior.
TECH_STACK: Yesod on GHC + Esqueleto + PostgreSQL, Warp, Stack build, deployed on Render
APP_TYPE: web app
LANGUAGE: Haskell
SCALE: 3k rules, 5M historical orders
```

## 99. Threnody — SQL query linter CLI

```text
APP_DESCRIPTION: A CLI that parses SQL, lints for anti-patterns and dialect issues, and suggests safer rewrites. It flags missing indexes hints, dangerous deletes without predicates, and non-portable syntax. The SQL is parsed into a typed AST that lint rules pattern-match over.
TECH_STACK: GHC + Megaparsec + prettyprinter + optparse-applicative, Cabal build, published on Hackage and as a binary
APP_TYPE: CLI
LANGUAGE: Haskell
SCALE: single user, 5,000-query repositories
```

## 100. Continuum — schema registry API

```text
APP_DESCRIPTION: A schema registry API that stores versioned data schemas, checks compatibility on registration, and serves schemas to producers and consumers. Compatibility modes are enforced so a breaking change is rejected before it reaches the wire. Schema comparison walks a typed representation to classify changes.
TECH_STACK: GHC + Servant + Aeson + Hasql + PostgreSQL + hedis Redis, Nix build, deployed on Kubernetes
APP_TYPE: API service
LANGUAGE: Haskell
SCALE: 10k schemas, 50k versions, 4,000 req/s
```
