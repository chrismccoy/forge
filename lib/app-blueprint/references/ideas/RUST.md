# Rust Blueprint Types — Copy-Paste Input Sets

Copy a fenced block into the prompt as-is, or swap individual fields.

## 1. StockPulse — marketplace inventory sync API

```text
APP_DESCRIPTION: A high-throughput inventory-sync API service for merchants selling across multiple marketplaces. It receives stock deltas from warehouse systems, resolves per-channel allocation rules, and pushes near-real-time quantity updates to marketplace APIs to prevent overselling.
TECH_STACK: Rust (axum) + PostgreSQL + Redis + Kafka + marketplace API connectors, deployed on AWS EKS
APP_TYPE: API service
LANGUAGE: Rust
SCALE: ~4,000 stock-delta req/sec peak, 1,200 merchants, ~50 GB data
```

## 2. lockbox — local password vault CLI

```text
APP_DESCRIPTION: A local-first password vault CLI for developers. It stores credentials and TOTP seeds in an age-encrypted local file, supports fuzzy search and clipboard copy with auto-clear, generates passwords by policy, and syncs the encrypted vault via the user's own git remote — no server component.
TECH_STACK: Rust CLI (clap) + age encryption + local encrypted file store + optional git sync, distributed via cargo/Homebrew
APP_TYPE: CLI
LANGUAGE: Rust
SCALE: single user, <10 MB vault data
```

## 3. PitWire — race telemetry pipeline

```text
APP_DESCRIPTION: A data pipeline for club motorsport teams that processes live car telemetry. It ingests high-frequency CAN-bus channels (RPM, throttle, brake pressure, tire temps) over trackside radio, decodes and time-aligns channels, computes lap and sector deltas in real time, and stores sessions for post-race analysis.
TECH_STACK: Rust + tokio + UDP ingestion + Apache Parquet session storage + TimescaleDB for live views
APP_TYPE: data pipeline
LANGUAGE: Rust
SCALE: 2 cars × 400 channels at 100 Hz (~80k points/sec), ~5 GB per race weekend
```

## 4. InvoiceMiner — PDF invoice parsing API

```text
APP_DESCRIPTION: An API service for accounting platforms that extracts structured data from PDF invoices. Clients upload supplier invoices; the service parses layout and tables, extracts header fields (supplier, dates, totals, tax) and line items, validates arithmetic, and returns normalized JSON with per-field confidence.
TECH_STACK: Rust (axum) + pdfium bindings + PostgreSQL + S3 + queue workers, deployed on GCP Cloud Run
APP_TYPE: API service
LANGUAGE: Rust
SCALE: ~120 req/sec, 90 platform clients, ~300 GB stored documents
```

## 5. NotedDesk — markdown knowledge base

```text
APP_DESCRIPTION: A local-first desktop knowledge-base app for researchers and writers. Users write linked markdown notes with backlinks and graph view, full-text search across thousands of notes, tag-based smart folders, and export to publishable formats — all data stays in a local folder of plain files.
TECH_STACK: Tauri (Rust core) + React frontend + tantivy full-text index + local markdown files
APP_TYPE: desktop
LANGUAGE: Rust
SCALE: single user, 50k notes, <5 GB local data
```

## 6. PodiumBoard — game leaderboard service

```text
APP_DESCRIPTION: A leaderboard API service for indie game studios. Games submit signed score events; the service maintains global, friend, and seasonal leaderboards with anti-tamper validation and rate limiting, and exposes paginated rank queries with percentile lookups.
TECH_STACK: Rust (actix-web) + Redis sorted sets + PostgreSQL + HMAC-signed score submissions, deployed on Hetzner
APP_TYPE: API service
LANGUAGE: Rust
SCALE: ~3,000 req/sec launch-week peak, 40 games, 5M player profiles, ~25 GB data
```

## 7. HushDNS — home network DNS filter

```text
APP_DESCRIPTION: A self-hosted DNS filtering service for home-lab users. It answers LAN DNS queries with configurable blocklists (ads, trackers, malware domains), per-device policies and schedules (kids' devices), a local web dashboard of query statistics, and DoH upstream resolution.
TECH_STACK: Rust (tokio + hickory-dns) + SQLite + embedded web UI, distributed as single binary for Raspberry Pi/x86
APP_TYPE: API service
LANGUAGE: Rust
SCALE: ~200 DNS queries/sec, 30 LAN devices, <2 GB query log data
```

## 8. WaveBatch — audio transcoding pipeline

```text
APP_DESCRIPTION: A batch audio-transcoding data pipeline for an audiobook publisher. It ingests studio master WAV files, validates loudness against ACX/EBU R128 specs, transcodes to retailer-specific formats and bitrates, embeds chapter metadata, and delivers packaged outputs to distribution endpoints.
TECH_STACK: Rust + ffmpeg bindings + RabbitMQ work queue + PostgreSQL job ledger + S3, deployed on bare-metal workers
APP_TYPE: data pipeline
LANGUAGE: Rust
SCALE: ~400 titles/month (~1.2 TB/month processed), 6 retailer output profiles
```

## 9. LimitLedger — crypto exchange matching engine

```text
APP_DESCRIPTION: A low-latency matching-engine API for a spot cryptocurrency exchange. It maintains in-memory limit order books per trading pair, matches incoming orders with price-time priority, emits fill and book-delta events, and persists an append-only trade journal for settlement and audit.
TECH_STACK: Rust + tokio + lock-free in-memory order books + Redpanda event log + ScyllaDB trade store, deployed on bare-metal colocation
APP_TYPE: API service
LANGUAGE: Rust
SCALE: ~250,000 orders/sec peak, 180 trading pairs, sub-50µs match latency
```

## 10. FleetHeart — vehicle telematics ingestion service

```text
APP_DESCRIPTION: An IoT ingestion API for commercial fleet operators. It receives MQTT telemetry from truck OBD-II dongles (GPS, fuel, engine faults), decodes manufacturer PID codes, geofences routes, and streams enriched events to a dispatch dashboard and maintenance alerting system.
TECH_STACK: Rust (tokio + rumqtt broker) + TimescaleDB + Kafka + Protobuf payloads, deployed on Azure AKS
APP_TYPE: API service
LANGUAGE: Rust
SCALE: ~60,000 messages/sec, 85,000 connected vehicles, ~2 TB telemetry/month
```

## 11. GridWard — smart-meter reading pipeline

```text
APP_DESCRIPTION: A data pipeline for a regional electric utility that processes smart-meter interval reads. It ingests DLMS/COSEM meter packets over a headend concentrator, validates and gap-fills interval data, computes settlement-grade consumption totals, and publishes billing-ready records to the meter data management system.
TECH_STACK: Rust + tokio + Apache Arrow + Parquet + Kafka + PostgreSQL, deployed on on-prem OpenShift
APP_TYPE: data pipeline
LANGUAGE: Rust
SCALE: 3.2M meters at 15-min intervals (~3,500 reads/sec), ~9 TB/year
```

## 12. Chartwright — TUI git repository dashboard

```text
APP_DESCRIPTION: A terminal-UI developer tool that gives a live dashboard over local git repositories. It shows branch graphs, staged/unstaged diffs, blame heatmaps, and stash management in a keyboard-driven interface, letting engineers stage hunks and craft commits without leaving the terminal.
TECH_STACK: Rust CLI (ratatui + crossterm) + libgit2 bindings + local config, distributed via cargo install
APP_TYPE: CLI
LANGUAGE: Rust
SCALE: single developer, repos up to 500k commits
```

## 13. SkyParcel — drone delivery route planner

```text
APP_DESCRIPTION: A geospatial API service that computes flight-safe delivery routes for a last-mile drone logistics company. It fuses airspace restrictions, terrain elevation, no-fly geofences, and live wind data to produce battery-aware waypoint plans and re-routes drones mid-flight when conditions change.
TECH_STACK: Rust (axum) + GEOS/geo crate + PostGIS + Redis + gRPC to flight controllers, deployed on AWS Fargate
APP_TYPE: API service
LANGUAGE: Rust
SCALE: ~1,500 route computations/sec, 2,200 active drones, ~40 GB airspace data
```

## 14. Tessera — WASM collaborative whiteboard

```text
APP_DESCRIPTION: A browser-based collaborative whiteboard for design teams. A WASM-backed canvas engine handles vector shapes, freehand ink smoothing, and multi-user cursors with conflict-free merges, while a sync server relays CRDT operations so hundreds of participants can edit one board in real time.
TECH_STACK: Rust compiled to WASM (canvas engine) + yrs CRDT + TypeScript shell + WebSocket sync server (Rust/tokio), deployed on Fly.io
APP_TYPE: web app
LANGUAGE: Rust
SCALE: ~5,000 concurrent boards, up to 300 collaborators/board, ~15 GB board data
```

## 15. CodonForge — genomics variant calling pipeline

```text
APP_DESCRIPTION: A bioinformatics data pipeline for a clinical genomics lab. It ingests aligned sequencing reads (BAM), calls single-nucleotide and indel variants across target panels, annotates against reference databases, and emits filtered VCF reports for downstream diagnostic review.
TECH_STACK: Rust + rust-htslib + rayon parallelism + Apache Parquet + object storage, orchestrated on an HPC Slurm cluster
APP_TYPE: data pipeline
LANGUAGE: Rust
SCALE: ~1,200 exomes/day, ~30x coverage, ~180 GB reads/sample processed
```

## 16. Sentrylog — SIEM log correlation engine

```text
APP_DESCRIPTION: A defensive security data pipeline that correlates security events for enterprise SOC teams. It ingests syslog and endpoint telemetry, normalizes to a common schema, evaluates detection rules and sliding-window correlations, and raises prioritized alerts with enriched context to an incident queue.
TECH_STACK: Rust + tokio + vector-style pipeline + ClickHouse + Kafka + rule DSL engine, deployed on Kubernetes
APP_TYPE: data pipeline
LANGUAGE: Rust
SCALE: ~500,000 events/sec ingest, 12,000 endpoints, ~40 TB hot storage
```

## 17. Backhaul — CDN edge cache node

```text
APP_DESCRIPTION: An edge caching API service for a content delivery network. Each node terminates TLS, serves cached HTTP objects with range and revalidation support, applies per-origin cache policies, and coordinates with peer nodes for cache fill while streaming access logs to central analytics.
TECH_STACK: Rust (hyper + rustls) + memory + NVMe tiered cache + consistent-hash peering, deployed on bare-metal PoPs
APP_TYPE: API service
LANGUAGE: Rust
SCALE: ~120,000 req/sec/node, 95% cache hit ratio, 8 TB NVMe cache/node
```

## 18. Bindery — API client SDK generator CLI

```text
APP_DESCRIPTION: A developer CLI that generates typed API client libraries from OpenAPI specifications. It parses the spec, resolves schema references, and emits idiomatic client code in multiple target languages with retry, pagination, and auth helpers wired in, plus a diff mode for spec changes.
TECH_STACK: Rust CLI (clap) + serde + OpenAPI parser + handlebars templates, distributed via cargo and GitHub releases
APP_TYPE: CLI
LANGUAGE: Rust
SCALE: single developer, specs up to 4,000 endpoints
```

## 19. Reflow — HTTP load testing tool

```text
APP_DESCRIPTION: A command-line load-testing tool for backend engineers. It drives configurable request scenarios with weighted endpoints, ramps concurrency according to a schedule, and reports latency percentiles, throughput, and error breakdowns as live terminal charts and exportable reports.
TECH_STACK: Rust CLI (tokio + hyper) + hdrhistogram + ratatui live view + HTML report export
APP_TYPE: CLI
LANGUAGE: Rust
SCALE: single operator, sustains ~200,000 req/sec from one host
```

## 20. Cropline — satellite imagery NDVI pipeline

```text
APP_DESCRIPTION: A geospatial data pipeline for a precision-agriculture platform. It ingests multispectral satellite tiles, computes vegetation indices (NDVI, NDWI) per field boundary, detects crop-stress anomalies over time, and publishes per-field health layers to a grower dashboard.
TECH_STACK: Rust + gdal bindings + rayon + Cloud-Optimized GeoTIFF + PostGIS, deployed on GCP batch workers
APP_TYPE: data pipeline
LANGUAGE: Rust
SCALE: ~40,000 fields, ~2 TB imagery/week processed, weekly revisit cadence
```

## 21. Auxgate — OAuth2 authorization server

```text
APP_DESCRIPTION: A defensive-security API service providing OAuth2 and OIDC authorization for a B2B SaaS suite. It issues and validates tokens, manages client registrations and scopes, handles PKCE flows and refresh rotation, and exposes JWKS and introspection endpoints with strict audit logging.
TECH_STACK: Rust (axum) + PostgreSQL + Redis + jose/JWT crates + argon2, deployed on AWS EKS
APP_TYPE: API service
LANGUAGE: Rust
SCALE: ~8,000 token ops/sec, 3,500 client apps, 12M active sessions
```

## 22. Loomstate — Tauri time-tracking desktop app

```text
APP_DESCRIPTION: A cross-platform desktop time-tracking app for freelancers and small agencies. It captures timers per project and task, detects idle time, categorizes activity, generates invoices from tracked hours, and syncs encrypted work logs across the user's devices.
TECH_STACK: Tauri (Rust core) + Svelte frontend + SQLite + optional end-to-end encrypted cloud sync
APP_TYPE: desktop
LANGUAGE: Rust
SCALE: single user, ~5 years of entries (~500k records), <1 GB local data
```

## 23. Slabtrace — distributed tracing collector

```text
APP_DESCRIPTION: An observability API service that collects distributed traces from microservices. It receives OTLP spans, reassembles trace trees, computes service-dependency graphs and latency breakdowns, applies tail-based sampling, and forwards retained traces to long-term storage.
TECH_STACK: Rust (tonic/gRPC) + OpenTelemetry protocol + ClickHouse + Kafka, deployed on Kubernetes
APP_TYPE: API service
LANGUAGE: Rust
SCALE: ~1,200,000 spans/sec, 4,000 monitored services, ~25 TB trace storage
```

## 24. Beacontide — maritime AIS tracking service

```text
APP_DESCRIPTION: A geospatial API service for a port-authority operations center. It ingests AIS vessel position broadcasts, decodes NMEA sentences, tracks vessel courses and predicts collisions and geofence breaches, and serves a live traffic map with historical voyage playback.
TECH_STACK: Rust (axum + tokio) + PostGIS + Redis + WebSocket streaming, deployed on on-prem servers
APP_TYPE: API service
LANGUAGE: Rust
SCALE: ~25,000 position reports/sec, 90,000 tracked vessels, ~6 TB voyage history
```

## 25. Pressroom — WASM image editing web app

```text
APP_DESCRIPTION: A browser image-editing web app for e-commerce sellers. A WASM engine performs non-destructive adjustments, background removal, batch resizing, and format conversion entirely client-side, so product photos never leave the browser while edits stay responsive on large images.
TECH_STACK: Rust compiled to WASM (image pipeline) + image/photon crates + TypeScript UI + IndexedDB, static hosting on Cloudflare Pages
APP_TYPE: web app
LANGUAGE: Rust
SCALE: ~50,000 monthly users, images up to 50 MP, fully client-side processing
```

## 26. Cadwork — CNC G-code toolpath generator

```text
APP_DESCRIPTION: A desktop CAM tool for small machine shops that converts 2.5D part models into CNC toolpaths. It offsets contours, generates pocketing and drilling operations with feeds and speeds per material, simulates the cut, and exports validated G-code for specific machine post-processors.
TECH_STACK: Tauri (Rust core) + geometry/clipping crates + wgpu 3D preview + local project files
APP_TYPE: desktop
LANGUAGE: Rust
SCALE: single operator, parts up to 20,000 toolpath segments
```

## 27. Streambed — video ABR packaging pipeline

```text
APP_DESCRIPTION: A media data pipeline for a live-sports streaming platform. It ingests mezzanine feeds, transcodes into adaptive-bitrate renditions, packages HLS and DASH segments, inserts ad markers and DRM, and pushes segments to origin storage for edge delivery.
TECH_STACK: Rust + gstreamer bindings + tokio + S3-compatible origin + Redis manifest cache, deployed on GPU worker fleet
APP_TYPE: data pipeline
LANGUAGE: Rust
SCALE: ~800 concurrent live channels, 6 renditions each, ~40 Gbps egress
```

## 28. Klaxon — on-call alert routing service

```text
APP_DESCRIPTION: An API service that routes operational alerts to on-call engineers. It deduplicates incoming alerts, evaluates escalation policies and schedules, delivers notifications across channels with acknowledgement tracking, and provides an incident timeline for post-mortems.
TECH_STACK: Rust (axum) + PostgreSQL + Redis + provider integrations (SMS/push/email), deployed on AWS ECS
APP_TYPE: API service
LANGUAGE: Rust
SCALE: ~4,000 alerts/min at peak, 900 teams, ~30 GB incident history
```

## 29. Warmpath — building HVAC control service

```text
APP_DESCRIPTION: An industrial IoT API service for commercial building automation. It reads BACnet sensor points, runs zone-level PID and scheduling logic to optimize HVAC energy use, exposes setpoint overrides to facilities staff, and logs equipment runtime for predictive maintenance.
TECH_STACK: Rust (tokio) + BACnet stack + InfluxDB + MQTT + embedded web dashboard, deployed on edge gateways
APP_TYPE: API service
LANGUAGE: Rust
SCALE: ~40 buildings, 25,000 sensor points, 1-second control loop
```

## 30. Lexmark — legal contract diffing pipeline

```text
APP_DESCRIPTION: A data pipeline for a legal-tech platform that analyzes contract revisions. It parses DOCX and PDF contracts, segments clauses, aligns versions with semantic diffing, flags risky clause changes against a policy library, and outputs annotated redlines for reviewing attorneys.
TECH_STACK: Rust + docx/pdf parsers + tantivy clause index + PostgreSQL + queue workers, deployed on Azure Container Apps
APP_TYPE: data pipeline
LANGUAGE: Rust
SCALE: ~20,000 contracts/day, 600 firm clients, ~1.5 TB document store
```

## 31. Tremorline — seismic sensor stream processor

```text
APP_DESCRIPTION: A scientific data pipeline for a regional earthquake early-warning network. It ingests continuous waveform streams from seismometers, detects P-wave arrivals, estimates magnitude and epicenter in real time, and broadcasts warning messages before strong shaking reaches populated areas.
TECH_STACK: Rust + tokio + SeedLink protocol + ObsPy-compatible formats + Kafka + PostgreSQL, deployed on redundant on-prem clusters
APP_TYPE: data pipeline
LANGUAGE: Rust
SCALE: ~1,100 stations at 100 Hz (~110k samples/sec), sub-second detection latency
```

## 32. Quantico — options market data feed handler

```text
APP_DESCRIPTION: A fintech API service that normalizes options market data for a trading firm. It decodes exchange multicast feeds (OPRA), rebuilds full order books and NBBO, computes implied volatility and Greeks, and publishes a normalized feed to internal strategy engines over shared memory.
TECH_STACK: Rust + tokio + kernel-bypass UDP + shared-memory ring buffers + FlatBuffers, deployed on colocated bare-metal
APP_TYPE: API service
LANGUAGE: Rust
SCALE: ~15,000,000 messages/sec peak, 1.2M option contracts, sub-10µs processing
```

## 33. Palettewright — WASM color grading web app

```text
APP_DESCRIPTION: A browser web app for video colorists that applies cinematic color grades to clips. A WASM engine renders LUT-based grading, scopes (waveform, vectorscope), and node-based correction previews in real time, letting creators grade footage without installing heavy desktop software.
TECH_STACK: Rust compiled to WASM + wgpu (WebGPU) + TypeScript UI + WebCodecs, deployed on Vercel
APP_TYPE: web app
LANGUAGE: Rust
SCALE: ~30,000 users, 4K clip previews at 30 fps, client-side rendering
```

## 34. Depotcast — package tracking aggregation API

```text
APP_DESCRIPTION: An API service that unifies parcel tracking across carriers for e-commerce shops. It polls and normalizes carrier tracking events, predicts delivery windows, detects stuck or misrouted shipments, and pushes webhook updates and branded tracking pages to merchants.
TECH_STACK: Rust (axum) + PostgreSQL + Redis + carrier API connectors + webhook dispatcher, deployed on DigitalOcean Kubernetes
APP_TYPE: API service
LANGUAGE: Rust
SCALE: ~6,000 req/sec, 12M active shipments, ~200 GB event history
```

## 35. Millrun — factory OEE monitoring service

```text
APP_DESCRIPTION: An industrial IoT API service that computes Overall Equipment Effectiveness for manufacturing lines. It reads PLC tags over OPC-UA, tracks machine states, downtime reasons, and cycle counts, computes availability/performance/quality metrics, and drives an Andon dashboard for plant supervisors.
TECH_STACK: Rust (tokio) + OPC-UA client + TimescaleDB + MQTT + embedded web UI, deployed on plant-floor edge servers
APP_TYPE: API service
LANGUAGE: Rust
SCALE: ~35 production lines, 8,000 PLC tags, 250 ms polling interval
```

## 36. Bytecdr — columnar analytics query engine

```text
APP_DESCRIPTION: A data pipeline and embedded query engine for a product-analytics platform. It ingests event streams into columnar segments, builds sparse indexes, and executes vectorized aggregation queries (funnels, retention, cohorts) over billions of rows for interactive dashboards.
TECH_STACK: Rust + Apache Arrow + DataFusion + Parquet + object storage, deployed on AWS EKS
APP_TYPE: data pipeline
LANGUAGE: Rust
SCALE: ~40 billion events, ~300,000 events/sec ingest, sub-second p95 queries
```

## 37. Chirpwatch — bioacoustic bird ID pipeline

```text
APP_DESCRIPTION: A scientific data pipeline for a conservation research group. It processes field-recorder audio from forest sensor stations, segments candidate calls, runs a Rust-hosted ML model to classify species, and aggregates detections into biodiversity maps for ecologists.
TECH_STACK: Rust + hound/rubato audio + ONNX Runtime bindings + rayon + PostGIS, deployed on batch cloud workers
APP_TYPE: data pipeline
LANGUAGE: Rust
SCALE: ~600 sensor stations, ~4 TB audio/month, ~2M call detections/month
```

## 38. Tollgate — API gateway rate limiter

```text
APP_DESCRIPTION: A defensive-security API service acting as a gateway in front of internal microservices. It authenticates requests, enforces per-tenant rate limits and quotas, applies request validation and WAF rules, and load-balances to upstreams with circuit breaking and detailed access metrics.
TECH_STACK: Rust (hyper + tower) + Redis token buckets + config from etcd + Prometheus metrics, deployed on Kubernetes
APP_TYPE: API service
LANGUAGE: Rust
SCALE: ~180,000 req/sec, 2,500 tenants, sub-millisecond added latency
```

## 39. Fernwatch — infrastructure config linter CLI

```text
APP_DESCRIPTION: A developer CLI that lints infrastructure-as-code before deployment. It parses Terraform and Kubernetes manifests, evaluates security and best-practice policies, detects drift-prone patterns and secret leaks, and prints actionable findings with autofix suggestions in CI.
TECH_STACK: Rust CLI (clap) + HCL/YAML parsers + policy rule engine + SARIF output, distributed via cargo and container image
APP_TYPE: CLI
LANGUAGE: Rust
SCALE: single CI runner, repos up to 5,000 resources, sub-second scan
```

## 40. Cellframe — 5G RAN packet scheduler service

```text
APP_DESCRIPTION: A telecom API service implementing a MAC-layer packet scheduler for a private 5G base station. It allocates radio resource blocks across user equipment by QoS class, adapts to channel-quality reports, and enforces latency budgets for ultra-reliable low-latency traffic in an industrial deployment.
TECH_STACK: Rust + tokio + DPDK bindings + shared-memory IPC to PHY layer, deployed on carrier-grade edge servers
APP_TYPE: API service
LANGUAGE: Rust
SCALE: ~2,000 connected UEs, 1 ms scheduling slots, ~10 Gbps cell throughput
```

## 41. Vialoom — patient vitals monitoring service

```text
APP_DESCRIPTION: A healthcare API service that ingests bedside monitor vitals in a hospital ward. It receives HL7/FHIR-encoded vitals from patient monitors, detects early-warning-score deterioration, streams live waveforms to nurse stations, and alerts clinicians while writing to the EHR.
TECH_STACK: Rust (axum + tokio) + FHIR/HL7 parsers + TimescaleDB + WebSocket streaming, deployed on hospital on-prem Kubernetes
APP_TYPE: API service
LANGUAGE: Rust
SCALE: ~1,200 monitored beds, ~40,000 vitals/sec, ~3 TB waveform storage/month
```

## 42. Stitchbin — Docker image layer optimizer CLI

```text
APP_DESCRIPTION: A devtools CLI that analyzes and shrinks container images. It inspects image layers, identifies duplicate files and cache-busting patterns, rewrites layer ordering, and produces an optimized image plus a report of size savings and reproducibility warnings.
TECH_STACK: Rust CLI (clap) + OCI image spec parser + zstd + registry client, distributed via cargo and static binary
APP_TYPE: CLI
LANGUAGE: Rust
SCALE: single developer, images up to 8 GB, ~200 layers analyzed
```

## 43. Orbitcast — satellite pass prediction API

```text
APP_DESCRIPTION: A geospatial API service for ground-station operators tracking satellites. It propagates TLE orbital elements, predicts visible passes and doppler shifts for antenna scheduling, computes look angles, and serves conflict-free tracking schedules for a shared antenna network.
TECH_STACK: Rust (axum) + SGP4 propagator crate + PostgreSQL + Redis, deployed on AWS ECS
APP_TYPE: API service
LANGUAGE: Rust
SCALE: ~2,000 req/sec, 28,000 tracked objects, minute-level pass resolution
```

## 44. Feltboard — Tauri tabletop RPG toolkit

```text
APP_DESCRIPTION: A desktop app for tabletop RPG game masters to run sessions. It manages battle maps with fog of war, initiative tracking, dice rolling with modifiers, and encounter libraries, and shares a synced player view to a second screen over the local network.
TECH_STACK: Tauri (Rust core) + React frontend + SQLite + local WebSocket sync + wgpu map rendering
APP_TYPE: desktop
LANGUAGE: Rust
SCALE: single game master, ~10 players synced, campaigns up to 5 GB assets
```

## 45. Refluxdb — write-ahead log storage engine

```text
APP_DESCRIPTION: An embedded storage-engine data pipeline component for a time-series database. It provides an append-only write-ahead log, LSM-tree compaction, and crash-safe recovery, exposing a key-range scan API to the query layer with tunable durability and compression.
TECH_STACK: Rust + custom LSM + memmap2 + zstd + crc32 checksums, embedded as a library and in a storage daemon
APP_TYPE: data pipeline
LANGUAGE: Rust
SCALE: ~500,000 writes/sec/node, ~4 TB per node, microsecond read latency
```

## 46. Braidnet — mesh VPN coordination service

```text
APP_DESCRIPTION: A defensive-security API service that coordinates a peer-to-peer mesh VPN for distributed teams. It manages device enrollment and key exchange, computes NAT-traversal paths, distributes network ACLs, and relays traffic only when direct WireGuard tunnels can't be established.
TECH_STACK: Rust (axum + tokio) + WireGuard (boringtun) + PostgreSQL + STUN/ICE, deployed on multi-region VPS fleet
APP_TYPE: API service
LANGUAGE: Rust
SCALE: ~30,000 enrolled devices, 4,000 concurrent tunnels, ~1 GB coordination state
```

## 47. Emberflux — wildfire spread simulation pipeline

```text
APP_DESCRIPTION: A scientific data pipeline for a wildfire response agency. It fuses terrain, fuel-load maps, and live weather to run cellular-automata fire-spread simulations, produces hourly perimeter forecasts, and generates evacuation-timing layers for emergency planners.
TECH_STACK: Rust + rayon + gdal + ndarray + Cloud-Optimized GeoTIFF, deployed on GCP batch compute
APP_TYPE: data pipeline
LANGUAGE: Rust
SCALE: ~10 m grid over 500 km² regions, 200 Monte Carlo runs, hourly forecast cycle
```

## 48. Ledgerloom — double-entry accounting API

```text
APP_DESCRIPTION: A fintech API service providing a double-entry ledger for embedded finance products. It records immutable journal entries, enforces balanced postings and multi-currency accounts, computes real-time balances, and exposes trial-balance and reconciliation endpoints with a full audit trail.
TECH_STACK: Rust (axum) + PostgreSQL (append-only) + Redis + idempotency keys, deployed on AWS EKS
APP_TYPE: API service
LANGUAGE: Rust
SCALE: ~10,000 postings/sec, 8M accounts, ~600 GB immutable ledger
```

## 49. Snaptrace — eBPF syscall profiler CLI

```text
APP_DESCRIPTION: A Linux devtools CLI that profiles application behavior using eBPF. It attaches probes to syscalls and functions, aggregates latency histograms and off-CPU stacks, and renders live flamegraphs in the terminal to help engineers find performance bottlenecks in production.
TECH_STACK: Rust CLI (aya eBPF) + ratatui + perf event parsing, distributed as a static binary
APP_TYPE: CLI
LANGUAGE: Rust
SCALE: single host, ~200,000 probe events/sec, negligible target overhead
```

## 50. Quorumcast — Raft consensus coordination service

```text
APP_DESCRIPTION: A distributed-systems API service that provides strongly-consistent coordination for microservice clusters. It implements Raft-replicated key-value storage, distributed locks, leader election, and watch subscriptions, letting services store config and coordinate work with linearizable guarantees.
TECH_STACK: Rust + tokio + custom Raft implementation + sled storage + gRPC, deployed as a 5-node cluster on Kubernetes
APP_TYPE: API service
LANGUAGE: Rust
SCALE: ~50,000 ops/sec, 5-node quorum, ~20 GB replicated state
```

## 51. Pulsefeed — RSS feed reader web app

```text
APP_DESCRIPTION: A self-hostable feed-reader web app for information workers. A Rust backend polls thousands of RSS/Atom feeds, dedupes and full-text-indexes articles, applies user filter rules and read-later tagging, and serves a fast reading UI with keyboard navigation and offline caching.
TECH_STACK: Rust (axum) + tantivy + PostgreSQL + HTMX frontend + WASM offline cache, deployed via single container
APP_TYPE: web app
LANGUAGE: Rust
SCALE: ~5,000 users, 80,000 feeds polled, ~150 GB article store
```

## 52. Coldpour — cold-chain temperature monitor service

```text
APP_DESCRIPTION: An IoT API service for pharmaceutical cold-chain logistics. It ingests temperature and humidity readings from shipment loggers, detects excursions against product-specific thresholds, computes mean-kinetic-temperature stability, and alerts operators before spoilage compromises a batch.
TECH_STACK: Rust (tokio) + LoRaWAN/MQTT ingest + TimescaleDB + rules engine + webhook alerts, deployed on Azure IoT edge
APP_TYPE: API service
LANGUAGE: Rust
SCALE: ~20,000 active loggers, ~15,000 readings/sec, ~1 TB reading history
```

## 53. Marginfox — retail price optimization pipeline

```text
APP_DESCRIPTION: A data pipeline for a grocery retail chain that computes dynamic prices. It ingests competitor prices, demand elasticity, inventory levels, and expiry dates, runs an optimization model per SKU-store, and publishes price recommendations to electronic shelf labels overnight.
TECH_STACK: Rust + Polars + linear solver bindings + Parquet + Kafka, deployed on on-prem Spark-adjacent batch cluster
APP_TYPE: data pipeline
LANGUAGE: Rust
SCALE: ~1,800 stores, 45,000 SKUs each (~80M price points), nightly batch
```

## 54. Torquevault — EV charging session broker API

```text
APP_DESCRIPTION: An API service that brokers EV charging sessions for a public charging network. It speaks OCPP to chargers, authorizes drivers, meters energy delivery, prices sessions with time-of-use tariffs, and settles payments while balancing load across a site's available capacity.
TECH_STACK: Rust (axum + tokio) + OCPP WebSocket + PostgreSQL + Redis + payment gateway, deployed on AWS ECS
APP_TYPE: API service
LANGUAGE: Rust
SCALE: ~12,000 chargers, ~3,000 concurrent sessions, ~400 GB session data
```

## 55. Glyphsmith — WASM font subsetting web app

```text
APP_DESCRIPTION: A browser web app for web developers that optimizes fonts for the web. A WASM engine subsets fonts to used glyphs, converts formats to WOFF2, previews rendering across weights, and generates CSS @font-face snippets — all in the browser without uploading proprietary fonts.
TECH_STACK: Rust compiled to WASM + fontations/harfbuzz-style subsetting + TypeScript UI, static hosting on Netlify
APP_TYPE: web app
LANGUAGE: Rust
SCALE: ~40,000 users, fonts up to 30,000 glyphs, client-side processing
```

## 56. Lariat — service mesh sidecar proxy

```text
APP_DESCRIPTION: A cloud-native API service running as a sidecar proxy in a service mesh. It transparently intercepts pod traffic, applies mTLS, retries, timeouts, and traffic-splitting policies from a control plane, and exports rich L7 telemetry for each service-to-service call.
TECH_STACK: Rust (tokio + tower + rustls) + xDS control-plane client + Prometheus metrics, deployed as a Kubernetes sidecar
APP_TYPE: API service
LANGUAGE: Rust
SCALE: ~60,000 req/sec/pod, ~5,000 mesh pods, sub-millisecond proxy overhead
```

## 57. Pennywise — personal finance budgeting desktop app

```text
APP_DESCRIPTION: A privacy-first desktop budgeting app for individuals. It imports bank transactions via OFX/CSV, auto-categorizes spending, tracks envelope budgets and savings goals, forecasts cash flow, and keeps all financial data in a local encrypted database with no cloud dependency.
TECH_STACK: Tauri (Rust core) + Vue frontend + SQLite (SQLCipher) + local ML categorizer
APP_TYPE: desktop
LANGUAGE: Rust
SCALE: single user, ~10 years of transactions (~250k records), <2 GB local data
```

## 58. Streamweir — Kafka stream ETL pipeline

```text
APP_DESCRIPTION: A data pipeline for a data-engineering team that transforms event streams. It consumes raw Kafka topics, applies stateful windowed joins, deduplication, and schema-evolution-safe transforms defined in a config DSL, and writes conformed records to a data lake and downstream topics.
TECH_STACK: Rust + rdkafka + Apache Arrow + Iceberg tables + object storage, deployed on Kubernetes
APP_TYPE: data pipeline
LANGUAGE: Rust
SCALE: ~800,000 events/sec, 400 topics, ~10 TB/day into the lake
```

## 59. Wardline — hospital bed management API

```text
APP_DESCRIPTION: A healthcare API service that orchestrates bed allocation across a hospital system. It tracks bed status and cleaning workflows, matches admissions to appropriate units by acuity and isolation needs, predicts discharge timing, and gives bed-flow coordinators a live capacity board.
TECH_STACK: Rust (axum) + PostgreSQL + Redis + FHIR integration + WebSocket updates, deployed on hospital on-prem cluster
APP_TYPE: API service
LANGUAGE: Rust
SCALE: ~6 hospitals, 4,500 beds, ~2,000 status events/min
```

## 60. Runeforge — WASM regex playground web app

```text
APP_DESCRIPTION: A browser devtools web app for developers to build and test regular expressions. A WASM-compiled regex engine highlights matches and capture groups in real time, explains patterns step by step, benchmarks alternatives, and generates equivalent code snippets in several languages.
TECH_STACK: Rust compiled to WASM (regex crate) + TypeScript UI + Monaco editor, static hosting on Cloudflare Pages
APP_TYPE: web app
LANGUAGE: Rust
SCALE: ~80,000 monthly users, patterns tested against inputs up to 5 MB, client-side
```

## 61. Kilnwatch — additive manufacturing monitor service

```text
APP_DESCRIPTION: An industrial IoT API service for a metal 3D-printing facility. It ingests laser-power, melt-pool camera, and chamber telemetry per build layer, detects anomalies that predict part defects in real time, and logs full build provenance for aerospace quality certification.
TECH_STACK: Rust (tokio) + camera frame processing + TimescaleDB + Kafka + S3 build archive, deployed on plant edge servers
APP_TYPE: API service
LANGUAGE: Rust
SCALE: ~12 printers, ~30,000 telemetry points/sec, ~500 GB per build campaign
```

## 62. Nightjar — DNS-over-HTTPS resolver service

```text
APP_DESCRIPTION: A defensive-security API service providing a privacy-respecting recursive DNS-over-HTTPS resolver for a privacy startup. It performs full recursive resolution with DNSSEC validation, aggressive negative caching, and query-name minimization, discarding client identifiers after resolution.
TECH_STACK: Rust (hyper + rustls + hickory-dns) + in-memory cache + Redis shared cache, deployed on anycast edge nodes
APP_TYPE: API service
LANGUAGE: Rust
SCALE: ~150,000 queries/sec, anycast across 12 PoPs, ~40 GB cache footprint
```

## 63. Sortline — warehouse robot fleet coordinator

```text
APP_DESCRIPTION: A robotics API service that coordinates autonomous mobile robots in a fulfillment warehouse. It assigns pick tasks, plans conflict-free paths on a shared floor grid, manages battery swaps and traffic zones, and reroutes robots dynamically as orders and congestion change.
TECH_STACK: Rust (axum + tokio) + path-planning (A*/CBS) + Redis + gRPC to robots, deployed on on-prem edge cluster
APP_TYPE: API service
LANGUAGE: Rust
SCALE: ~600 robots, ~5,000 task assignments/min, 50 ms replanning loop
```

## 64. Verdigris — carbon accounting data pipeline

```text
APP_DESCRIPTION: A data pipeline for a corporate sustainability platform. It ingests utility bills, supplier spend, and activity data, maps them to emission factors, computes Scope 1/2/3 greenhouse-gas inventories, and produces audit-ready footprint reports with uncertainty ranges for ESG disclosure.
TECH_STACK: Rust + Polars + emission-factor database + Parquet + PostgreSQL, deployed on GCP Cloud Run jobs
APP_TYPE: data pipeline
LANGUAGE: Rust
SCALE: ~3,000 companies, ~50M activity records, quarterly reporting cycle
```

## 65. Baitline — phishing URL scanning service

```text
APP_DESCRIPTION: A defensive-security API service that scans URLs for phishing and malware for an email security vendor. It fetches and sandboxes pages, extracts features (domain age, TLS, page structure), scores threat likelihood with a Rust-hosted model, and returns verdicts for inline mail filtering.
TECH_STACK: Rust (axum + tokio) + headless-browser fetcher + ONNX Runtime + Redis + threat feed cache, deployed on Kubernetes
APP_TYPE: API service
LANGUAGE: Rust
SCALE: ~8,000 URLs/sec, ~200M daily scans, sub-200 ms verdict latency
```

## 66. Chartlock — WASM spreadsheet formula engine web app

```text
APP_DESCRIPTION: A browser web app offering a fast spreadsheet for analysts. A WASM calculation engine evaluates a dependency graph of formulas incrementally, supports large grids, pivot tables, and array functions, and recalculates only affected cells so million-row sheets stay responsive.
TECH_STACK: Rust compiled to WASM (calc engine) + TypeScript grid UI + IndexedDB persistence, hosted on Vercel
APP_TYPE: web app
LANGUAGE: Rust
SCALE: ~25,000 users, sheets up to 5M cells, client-side recalculation
```

## 67. Deepkeel — subsea sensor data pipeline

```text
APP_DESCRIPTION: A scientific data pipeline for an oceanography institute. It ingests multi-sensor data from moored subsea observatories (CTD, ADCP, hydrophones), decodes instrument protocols, quality-flags readings against oceanographic ranges, and publishes calibrated datasets to a research archive.
TECH_STACK: Rust + tokio + NetCDF/HDF5 bindings + Parquet + PostgreSQL catalog, deployed on institutional HPC
APP_TYPE: data pipeline
LANGUAGE: Rust
SCALE: ~120 instruments, ~2 TB/month ingested, multi-year time-series archive
```

## 68. Copperbill — telecom CDR rating engine

```text
APP_DESCRIPTION: A telecom data pipeline that rates call detail records for a mobile virtual network operator. It ingests CDR streams from switches, applies tariff plans, roaming rules, and bundle allowances, deduplicates and rates each event, and feeds rated records to the billing system.
TECH_STACK: Rust + tokio + rating rule engine + Kafka + PostgreSQL + Parquet archive, deployed on on-prem Kubernetes
APP_TYPE: data pipeline
LANGUAGE: Rust
SCALE: ~2.5M subscribers, ~200,000 CDRs/sec peak, ~5 TB rated records/month
```

## 69. Trelliscache — GraphQL edge caching API

```text
APP_DESCRIPTION: An API service that caches and federates GraphQL queries at the edge for a headless-commerce platform. It parses queries, normalizes and caches entities, computes per-field TTLs and invalidation on mutations, and stitches responses across multiple upstream subgraphs.
TECH_STACK: Rust (axum + async-graphql) + Redis + consistent hashing + upstream connectors, deployed on Fly.io edge
APP_TYPE: API service
LANGUAGE: Rust
SCALE: ~40,000 queries/sec, 500 storefronts, ~80% entity cache hit rate
```

## 70. Anvilpack — reproducible build cache CLI

```text
APP_DESCRIPTION: A devtools CLI that provides a content-addressed build cache for monorepos. It hashes task inputs, restores cached outputs across machines and CI, detects non-deterministic builds, and shares artifacts through a remote cache to cut redundant compilation across teams.
TECH_STACK: Rust CLI (clap) + blake3 hashing + zstd + gRPC remote cache client, distributed via cargo and container
APP_TYPE: CLI
LANGUAGE: Rust
SCALE: ~2,000 developers sharing cache, artifacts up to 4 GB, ~10 TB remote cache
```

## 71. Frostpane — Tauri weather station dashboard

```text
APP_DESCRIPTION: A desktop dashboard for weather enthusiasts running personal weather stations. It polls station hardware and public APIs, renders live gauges and historical charts, computes derived metrics (dew point, wind chill, heat index), and issues local threshold alerts for frost or storms.
TECH_STACK: Tauri (Rust core) + Svelte frontend + SQLite + serial/USB station drivers + charting
APP_TYPE: desktop
LANGUAGE: Rust
SCALE: single user, ~5 stations, 1-minute samples, ~3 years history (<1 GB)
```

## 72. Splitrail — feature flag evaluation service

```text
APP_DESCRIPTION: An API service that evaluates feature flags and experiments for product teams. It resolves flag rules and percentage rollouts against user context, assigns experiment variants deterministically, streams flag changes to SDKs, and logs exposure events for analysis.
TECH_STACK: Rust (axum + tokio) + Redis + PostgreSQL + Server-Sent Events streaming, deployed on AWS ECS
APP_TYPE: API service
LANGUAGE: Rust
SCALE: ~90,000 evaluations/sec, 1,200 flags, 40M user contexts, sub-millisecond eval
```

## 73. Loamcast — soil moisture irrigation pipeline

```text
APP_DESCRIPTION: An agricultural IoT data pipeline for a vineyard operator. It ingests soil-moisture, sap-flow, and microclimate sensor data, models zone-level water stress, computes irrigation schedules per block, and drives valve controllers while logging water use for compliance.
TECH_STACK: Rust + tokio + LoRaWAN ingest + TimescaleDB + rule engine + MQTT valve control, deployed on farm edge gateway
APP_TYPE: data pipeline
LANGUAGE: Rust
SCALE: ~1,500 sensors across 40 blocks, ~5,000 readings/min, seasonal history
```

## 74. Obsidianport — WASM markdown export web app

```text
APP_DESCRIPTION: A browser web app that converts markdown documents into polished formats for technical writers. A WASM engine parses extended markdown, renders diagrams and math, applies themeable layouts, and exports to PDF and static HTML entirely client-side for privacy-sensitive docs.
TECH_STACK: Rust compiled to WASM (pulldown-cmark + typst-style layout) + TypeScript UI, static hosting on GitHub Pages
APP_TYPE: web app
LANGUAGE: Rust
SCALE: ~30,000 users, documents up to 2,000 pages, client-side export
```

## 75. Sableflow — ad bid request processor service

```text
APP_DESCRIPTION: An adtech API service acting as a real-time bidder for a demand-side platform. It receives OpenRTB bid requests, matches campaigns and budgets, scores inventory with pacing and frequency caps, and returns bids within the auction timeout while logging for attribution.
TECH_STACK: Rust (hyper + tokio) + Redis (budgets) + Aerospike (user store) + Kafka logging, deployed on multi-region bare-metal
APP_TYPE: API service
LANGUAGE: Rust
SCALE: ~800,000 bid requests/sec, ~50ms auction budget, 6,000 active campaigns
```

## 76. Corelathe — dataset labeling QA pipeline

```text
APP_DESCRIPTION: A data pipeline for an ML data-operations team that validates labeled training data. It ingests annotation exports, checks label schema conformance, detects inter-annotator disagreement and outliers, computes quality metrics, and routes suspect samples back for review.
TECH_STACK: Rust + Polars + serde + Parquet + PostgreSQL + queue workers, deployed on Kubernetes batch jobs
APP_TYPE: data pipeline
LANGUAGE: Rust
SCALE: ~20M labeled samples/month, 300 annotators, ~2 TB annotation store
```

## 77. Ridgeline — mountain trail routing API

```text
APP_DESCRIPTION: A geospatial API service for a hiking and trail-running app. It routes over trail networks with elevation-aware cost models, estimates time by fitness profile, surfaces water sources and hazards, and generates GPX tracks with turn-by-turn cues for offline use.
TECH_STACK: Rust (axum) + contraction-hierarchies routing + OSM extracts + PostGIS + Redis, deployed on AWS Fargate
APP_TYPE: API service
LANGUAGE: Rust
SCALE: ~3,000 route requests/sec, 1.5M km of trails, ~120 GB routing graph
```

## 78. Coilnet — battery BMS diagnostics service

```text
APP_DESCRIPTION: An industrial IoT API service for a grid-scale battery storage operator. It ingests cell-level voltage, current, and temperature from battery management systems, detects cell imbalance and thermal-runaway precursors, estimates state-of-health, and drives safety derating commands.
TECH_STACK: Rust (tokio) + CAN/Modbus ingest + TimescaleDB + rule engine + MQTT control, deployed on site edge controllers
APP_TYPE: API service
LANGUAGE: Rust
SCALE: ~200,000 cells monitored, ~50,000 readings/sec, 100 ms safety loop
```

## 79. Typeset — Tauri e-book authoring app

```text
APP_DESCRIPTION: A desktop authoring app for independent authors producing e-books. It offers a distraction-free editor with chapter organization, live EPUB and print PDF preview, style templates, and validation against e-book store requirements, keeping manuscripts in local project files.
TECH_STACK: Tauri (Rust core) + React frontend + EPUB/PDF generation + SQLite project store
APP_TYPE: desktop
LANGUAGE: Rust
SCALE: single author, manuscripts up to 400k words, <500 MB project assets
```

## 80. Hushline — end-to-end encrypted messaging service

```text
APP_DESCRIPTION: A defensive-security API service providing the relay backend for an end-to-end encrypted messaging app. It stores and forwards sealed sender ciphertext, manages prekey bundles for the Signal-style protocol, delivers via push, and retains no plaintext or social graph metadata.
TECH_STACK: Rust (axum + tokio) + PostgreSQL + Redis + WebSocket + push gateways, deployed on hardened Kubernetes
APP_TYPE: API service
LANGUAGE: Rust
SCALE: ~20M users, ~120,000 messages/sec peak, ephemeral encrypted queues
```

## 81. Quarrycut — LiDAR point cloud processing pipeline

```text
APP_DESCRIPTION: A geospatial data pipeline for a surveying firm processing aerial LiDAR. It ingests raw point clouds, classifies ground and vegetation returns, builds digital terrain and surface models, computes volumetrics for stockpiles, and tiles outputs for a web viewer.
TECH_STACK: Rust + rayon + LAS/LAZ readers + kd-tree + Cloud-Optimized formats + object storage, deployed on GCP batch compute
APP_TYPE: data pipeline
LANGUAGE: Rust
SCALE: ~5 billion points/survey, ~3 TB per project, tiled to web LOD
```

## 82. Pilotwave — flight ops crew scheduling API

```text
APP_DESCRIPTION: An API service that builds and repairs crew schedules for a regional airline. It assigns pilots and cabin crew to flight pairings respecting duty-time regulations, rest rules, and qualifications, optimizes for cost, and re-solves disruptions when flights are delayed or cancelled.
TECH_STACK: Rust (axum) + constraint solver bindings + PostgreSQL + Redis, deployed on Azure Kubernetes
APP_TYPE: API service
LANGUAGE: Rust
SCALE: ~4,000 crew members, ~1,200 daily flights, sub-minute disruption re-solve
```

## 83. Slatemark — WASM diagram rendering web app

```text
APP_DESCRIPTION: A browser web app that turns text descriptions into technical diagrams for engineers. A WASM layout engine parses a diagram DSL, runs graph layout algorithms, and renders flowcharts, sequence, and ER diagrams as crisp SVG in real time as the user types.
TECH_STACK: Rust compiled to WASM (layout engine) + TypeScript editor UI + SVG output, static hosting on Cloudflare Pages
APP_TYPE: web app
LANGUAGE: Rust
SCALE: ~60,000 users, diagrams up to 5,000 nodes, client-side layout
```

## 84. Berthwatch — port crane scheduling service

```text
APP_DESCRIPTION: An industrial API service that schedules quay cranes and yard moves at a container terminal. It sequences container loads/unloads per vessel stowage plan, minimizes crane clashes and reshuffles, and re-optimizes as trucks and vessels arrive off schedule.
TECH_STACK: Rust (axum + tokio) + optimization solver + PostgreSQL + MQTT to equipment, deployed on terminal on-prem servers
APP_TYPE: API service
LANGUAGE: Rust
SCALE: ~8 berths, 40 cranes, ~15,000 container moves/day, minute-level replanning
```

## 85. Coderoll — dependency vulnerability scanner CLI

```text
APP_DESCRIPTION: A defensive-security devtools CLI that audits project dependencies for known vulnerabilities. It parses lockfiles across ecosystems, resolves the full dependency tree, matches against advisory databases, computes reachable-vulnerability paths, and outputs prioritized findings for CI gates.
TECH_STACK: Rust CLI (clap) + SPDX/SBOM parsing + advisory DB sync + SARIF output, distributed via cargo and container
APP_TYPE: CLI
LANGUAGE: Rust
SCALE: single CI runner, dependency trees up to 20,000 packages, sub-5s scan
```

## 86. Tempoloom — MIDI performance capture pipeline

```text
APP_DESCRIPTION: A media data pipeline for a music-education platform. It ingests live MIDI performances from student keyboards, aligns them to reference scores, scores timing and pitch accuracy note by note, and produces practice analytics and progress reports for teachers.
TECH_STACK: Rust + tokio + MIDI parsing + dynamic-time-warping alignment + PostgreSQL, deployed on cloud workers
APP_TYPE: data pipeline
LANGUAGE: Rust
SCALE: ~30,000 daily sessions, ~2,000 note events/session, ~500 GB performance store
```

## 87. Girderline — structural FEA solver service

```text
APP_DESCRIPTION: A scientific API service that runs finite-element analysis for a structural-engineering SaaS. It assembles stiffness matrices from CAD-derived meshes, solves static and modal analyses for beams and frames, and returns stress, displacement, and safety-factor fields for design checks.
TECH_STACK: Rust (axum) + sparse linear algebra (nalgebra + solver bindings) + rayon + object storage, deployed on compute-optimized cloud nodes
APP_TYPE: API service
LANGUAGE: Rust
SCALE: ~500 analyses/hour, meshes up to 5M degrees of freedom, minutes per solve
```

## 88. Nestwatch — smart home automation hub service

```text
APP_DESCRIPTION: A self-hosted IoT API service that unifies smart-home devices for privacy-focused homeowners. It bridges Zigbee, Z-Wave, and Matter devices, runs local automation rules and scenes, exposes a voice-assistant-free web dashboard, and keeps all state on-device with no cloud.
TECH_STACK: Rust (axum + tokio) + Zigbee/Matter stacks + SQLite + embedded web UI, single binary for home servers
APP_TYPE: API service
LANGUAGE: Rust
SCALE: ~250 devices, ~2,000 events/min, <5 GB local state
```

## 89. Cartostream — vector map tile server

```text
APP_DESCRIPTION: A geospatial API service that serves vector map tiles for a mapping platform. It builds and serves Mapbox Vector Tiles from a PostGIS database, applies zoom-dependent generalization and layer filtering, caches hot tiles, and supports on-the-fly styling parameters.
TECH_STACK: Rust (axum) + PostGIS + geozero + Redis tile cache + protobuf MVT, deployed on Kubernetes
APP_TYPE: API service
LANGUAGE: Rust
SCALE: ~50,000 tile req/sec, planet-scale dataset, ~800 GB tile cache
```

## 90. Auroralink — ground station demodulation pipeline

```text
APP_DESCRIPTION: A data pipeline for a small-satellite ground network that demodulates downlinked telemetry. It consumes IQ sample streams from software-defined radios, performs demodulation, forward-error-correction decoding, and frame synchronization, then routes decoded telemetry to mission operators.
TECH_STACK: Rust + tokio + DSP (rustfft) + SDR (SoapySDR bindings) + Kafka, deployed on ground-station edge servers
APP_TYPE: data pipeline
LANGUAGE: Rust
SCALE: ~40 Msamples/sec/stream, 12 antennas, real-time decode during passes
```

## 91. Vaultwright — secrets management API service

```text
APP_DESCRIPTION: A defensive-security API service that manages secrets and dynamic credentials for platform teams. It encrypts secrets at rest with envelope encryption, issues short-lived database and cloud credentials on demand, enforces access policies, and logs every access for audit.
TECH_STACK: Rust (axum + tokio) + PostgreSQL + KMS/HSM integration + policy engine, deployed on hardened Kubernetes
APP_TYPE: API service
LANGUAGE: Rust
SCALE: ~30,000 secret ops/sec, 5,000 policies, 2M leased credentials, full audit log
```

## 92. Emberkiln — log compaction and archival pipeline

```text
APP_DESCRIPTION: A data pipeline for an observability vendor that compacts and archives application logs. It consumes log streams, parses and structures lines, dedupes and rolls up high-cardinality fields, compresses into columnar segments, and tiers cold data to cheap object storage with an index.
TECH_STACK: Rust + tokio + Apache Arrow + zstd + Parquet + object storage, deployed on Kubernetes
APP_TYPE: data pipeline
LANGUAGE: Rust
SCALE: ~2,000,000 log lines/sec, ~60 TB/day ingested, 10:1 compression
```

## 93. Skiffline — river gauge flood forecasting service

```text
APP_DESCRIPTION: A scientific API service for a watershed authority that forecasts river flooding. It ingests rain-gauge and stream-gauge telemetry, runs hydrological routing models, predicts crest levels and timing at downstream gauges, and issues staged flood warnings to emergency managers.
TECH_STACK: Rust (axum + tokio) + hydrological model + TimescaleDB + PostGIS + alert dispatcher, deployed on government cloud
APP_TYPE: API service
LANGUAGE: Rust
SCALE: ~1,200 gauges, ~10,000 readings/min, 6-hour forecast horizon updated every 15 min
```

## 94. Chiselcast — WASM 3D model viewer web app

```text
APP_DESCRIPTION: A browser web app for manufacturers to share interactive 3D product models with customers. A WASM engine loads glTF/STEP-derived meshes, renders with physically based shading and exploded views, measures dimensions, and streams large assemblies progressively without a plugin.
TECH_STACK: Rust compiled to WASM + wgpu (WebGPU) + glTF loader + TypeScript UI, static hosting on AWS CloudFront
APP_TYPE: web app
LANGUAGE: Rust
SCALE: ~40,000 users, models up to 20M triangles, progressive client-side rendering
```

## 95. Reelforge — video thumbnail extraction pipeline

```text
APP_DESCRIPTION: A media data pipeline for a video-hosting platform that generates preview assets. It decodes uploaded videos, detects scene changes, extracts representative keyframes and animated preview clips, generates sprite sheets for scrubbing, and stores derived assets for the player.
TECH_STACK: Rust + ffmpeg bindings + tokio + object storage + PostgreSQL job ledger, deployed on GPU worker fleet
APP_TYPE: data pipeline
LANGUAGE: Rust
SCALE: ~50,000 videos/day, files up to 4K/2 hours, ~8 TB derived assets/day
```

## 96. Palegrid — power grid state estimator service

```text
APP_DESCRIPTION: A telecom-grade API service for a transmission system operator that estimates grid state. It ingests PMU and SCADA measurements, runs weighted-least-squares state estimation across the network topology, detects bad data, and publishes a coherent grid state to control-room applications.
TECH_STACK: Rust (axum + tokio) + sparse linear algebra + IEC 61850/DNP3 ingest + TimescaleDB, deployed on control-center on-prem cluster
APP_TYPE: API service
LANGUAGE: Rust
SCALE: ~15,000 measurements, ~50 estimation solves/sec, ~2,000-bus network
```

## 97. Threadbare — Tauri podcast production studio

```text
APP_DESCRIPTION: A desktop app for podcasters to edit and produce episodes. It offers multitrack audio editing, noise reduction, loudness normalization, transcript-based cut editing, and chapter marker management, exporting publish-ready files while keeping projects in local storage.
TECH_STACK: Tauri (Rust core) + React frontend + audio DSP crates + local speech-to-text + SQLite project store
APP_TYPE: desktop
LANGUAGE: Rust
SCALE: single producer, projects up to 8 tracks × 3 hours, <10 GB local assets
```

## 98. Meshpour — 3D print slicer CLI

```text
APP_DESCRIPTION: A CLI for makerspaces and print farms that slices 3D models into printer instructions. It repairs mesh geometry, generates layered toolpaths with configurable infill and supports per material, estimates print time and filament, and emits validated G-code for target printers.
TECH_STACK: Rust CLI (clap) + mesh processing + geometry/clipping crates + G-code generation, distributed via cargo and static binary
APP_TYPE: CLI
LANGUAGE: Rust
SCALE: single operator, meshes up to 10M triangles, batches of 50 models
```

## 99. Beaconforge — indoor positioning ingestion service

```text
APP_DESCRIPTION: An IoT API service that powers indoor positioning for large venues. It ingests BLE beacon and Wi-Fi RTT signals from mobile SDKs, runs trilateration and Kalman filtering to estimate device positions, and streams live location and dwell analytics to a venue operations dashboard.
TECH_STACK: Rust (axum + tokio) + signal filtering + Redis + TimescaleDB + WebSocket streaming, deployed on AWS EKS
APP_TYPE: API service
LANGUAGE: Rust
SCALE: ~25,000 devices tracked, ~80,000 signal reports/sec, ~1 TB location history
```

## 100. Slabmirror — object storage replication pipeline

```text
APP_DESCRIPTION: A data pipeline for a cloud-storage provider that replicates objects across regions. It watches change journals, computes content-addressed deltas, transfers only changed blocks with integrity verification, resolves conflicts, and maintains eventual consistency across geo-distributed buckets.
TECH_STACK: Rust + tokio + blake3 chunking + zstd + S3-compatible clients + FoundationDB metadata, deployed on multi-region Kubernetes
APP_TYPE: data pipeline
LANGUAGE: Rust
SCALE: ~500,000 objects/sec change rate, 6 regions, ~40 PB replicated
```
