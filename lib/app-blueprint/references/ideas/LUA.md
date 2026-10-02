# Lua Blueprint Types — Copy-Paste Input Sets

Copy a fenced block into the prompt as-is, or swap individual fields.

## 1. EdgeWeave — edge request router

```text
APP_DESCRIPTION: An API service that runs at CDN points of presence to route and rewrite requests before they hit origin. Operators define path, header, and geo rules as config-as-code; the service performs A/B splits, canary weighting, and origin failover, and emits per-rule latency metrics for the traffic team.
TECH_STACK: OpenResty (nginx + lua-nginx-module) + lua-resty-core + Redis for rule state + Consul config, deployed on bare-metal edge nodes
APP_TYPE: API service
LANGUAGE: Lua
SCALE: ~45,000 req/sec/node, 60 PoPs, sub-millisecond rule evaluation
```

## 2. GateSpark — API gateway auth plugin

```text
APP_DESCRIPTION: A Kong gateway plugin that centralizes authentication for a fintech's public APIs. It validates JWTs and HMAC-signed requests, enforces per-consumer rate tiers, checks IP allowlists, and injects downstream identity headers so backend services never handle raw credentials.
TECH_STACK: Lua Kong plugin + lua-resty-jwt + Redis token cache + PostgreSQL consumer store, deployed on Kubernetes with Kong Ingress
APP_TYPE: API service
LANGUAGE: Lua
SCALE: ~18,000 req/sec, 4,200 API consumers, token cache hit rate >97%
```

## 3. StitchRealm — multiplayer game backend

```text
APP_DESCRIPTION: A game backend service for a top-down co-op shooter that runs authoritative match logic. It manages room lifecycle, reconciles player inputs, runs server-side hit validation, and syncs world snapshots to clients over WebSocket while persisting match results and loadouts.
TECH_STACK: Luvit async runtime + WebSocket rooms + Tarantool for session and inventory + Redis matchmaking, deployed on Docker/K8s
APP_TYPE: API service
LANGUAGE: Lua
SCALE: ~8,000 concurrent match sessions, 20 Hz tick rate, ~40k concurrent players peak
```

## 4. LumberLift — nginx log enrichment pipeline

```text
APP_DESCRIPTION: A data pipeline embedded in the web tier that enriches access logs before shipping them. In the log phase it tags each request with tenant, route class, and cache disposition, samples high-volume 2xx noise, and forwards structured events to the analytics store for the SRE team.
TECH_STACK: OpenResty log-phase Lua + lua-resty-kafka producer + ClickHouse sink + Vector shipper, self-hosted on Kubernetes
APP_TYPE: data pipeline
LANGUAGE: Lua
SCALE: ~120k log events/sec, ~300 GB/day, 14-day hot retention
```

## 5. dissectr — protocol dissector CLI

```text
APP_DESCRIPTION: A CLI tool for network engineers that batch-analyzes packet captures with custom Lua dissectors. It loads pcap files, applies protocol grammars for proprietary industrial and telecom framing, extracts fields to tabular output, and flags malformed frames for offline forensics.
TECH_STACK: LuaJIT + Wireshark-compatible dissector API (tshark -X lua_script) + FFI pcap parsing, distributed via package managers
APP_TYPE: CLI
LANGUAGE: Lua
SCALE: captures up to 20 GB, ~500k packets/sec parsed, per-run field-extraction reports
```

## 6. TileTinker — 2D game level editor

```text
APP_DESCRIPTION: A desktop level editor for indie studios building tile-based platformers. Designers paint multi-layer tilemaps, place entities with typed properties, define collision and parallax layers, and live-preview levels in an embedded runtime before exporting to the game's asset format.
TECH_STACK: LÖVE (love2d) + custom immediate-mode UI + SQLite project store + JSON/binary level export, packaged for Windows/macOS/Linux
APP_TYPE: desktop
LANGUAGE: Lua
SCALE: maps up to 4,000×4,000 tiles, 12 layers, ~200 entities per level
```

## 7. VerseVault — Lapis content platform

```text
APP_DESCRIPTION: A web app for a poetry and short-fiction community built on Lapis. Writers publish pieces with drafts and revisions, readers follow authors and build collections, and editors run themed submission calls with anonymized review queues and scheduled publishing.
TECH_STACK: Lapis (OpenResty) + PostgreSQL via pgmoon + Redis sessions + etlua templates, deployed on containers behind a CDN
APP_TYPE: web app
LANGUAGE: Lua
SCALE: ~90,000 monthly readers, ~300 req/sec peak, ~40 GB content and media metadata
```

## 8. FluxDock — IoT firmware for sensor nodes

```text
APP_DESCRIPTION: Embedded firmware for cold-chain monitoring nodes that ride in refrigerated trucks. Each node samples temperature and humidity, buffers readings during connectivity gaps, applies threshold alarms locally, and uploads batched telemetry over cellular when a gateway is in range.
TECH_STACK: NodeMCU/Lua on ESP32 + luasocket over MQTT + local ring buffer in SPIFFS, OTA firmware updates
APP_TYPE: CLI
LANGUAGE: Lua
SCALE: fleet of ~6,000 nodes, sample every 30s, 24h local buffer during outages
```

## 9. ShardScript — Redis-side leaderboard engine

```text
APP_DESCRIPTION: An API service for mobile game studios that runs leaderboards and quota logic entirely as Redis server-side scripts. Score submissions execute atomic Lua scripts for ranked inserts, sliding-window rate checks, and reward eligibility, giving consistent results without round-trip races.
TECH_STACK: Redis Lua scripting + OpenResty API front door + lua-resty-redis + Redis Cluster, deployed on managed Redis with edge nodes
APP_TYPE: API service
LANGUAGE: Lua
SCALE: ~25,000 score writes/sec, 12M ranked players, atomic script exec <200 µs
```

## 10. PaneWright — Neovim workflow plugin

```text
APP_DESCRIPTION: A Neovim plugin for backend developers that turns the editor into a database and HTTP workbench. It runs SQL and REST requests from buffers, renders results in floating windows, saves parameterized request collections per project, and captures response history for quick diffing.
TECH_STACK: Neovim Lua + nvim-nio async + libuv jobs + Treesitter for request parsing, installed via lazy.nvim
APP_TYPE: desktop
LANGUAGE: Lua
SCALE: ~15k plugin users, request runs in <50ms overhead, per-project collection stores
```

## 11. BidBreeze — real-time bidding filter

```text
APP_DESCRIPTION: An API service in an ad-exchange hot path that filters and shapes bid requests. For each incoming impression it applies brand-safety rules, frequency caps, and budget pacing in-process, then fans qualified requests to demand partners within the auction deadline.
TECH_STACK: OpenResty + lua-resty-core + Tarantool for pacing counters + lua-resty-http to DSPs, deployed on bare metal across regions
APP_TYPE: API service
LANGUAGE: Lua
SCALE: ~150,000 bid req/sec, 80 ms auction budget, 30 demand partners
```

## 12. CanvasClink — pixel-art animation studio

```text
APP_DESCRIPTION: A desktop tool for game artists to draw and animate sprite sheets. Artists work frame by frame with onion-skinning, define animation clips with timing and pivots, preview loops at target frame rates, and export packed atlases with metadata for popular engines.
TECH_STACK: LÖVE (love2d) + custom timeline UI + SQLite + texture-atlas packer, packaged as native desktop builds
APP_TYPE: desktop
LANGUAGE: Lua
SCALE: sheets up to 2,048×2,048, 64 clips per project, real-time 60 fps preview
```

## 13. MeterMoss — smart-meter aggregation pipeline

```text
APP_DESCRIPTION: A data pipeline for a utility that ingests smart electricity meter reads at the substation edge. Concentrator nodes decode DLMS/COSEM frames, validate meter identities, aggregate interval reads, and forward compressed batches to the head-end while caching during backhaul outages.
TECH_STACK: LuaJIT with FFI frame decoding + lua-resty-kafka + Redis dedup + ClickHouse warehouse, on edge concentrators and K8s
APP_TYPE: data pipeline
LANGUAGE: Lua
SCALE: ~2.1M meters, 15-min interval reads, ~200k frames/sec at peak decode
```

## 14. QuillQuartz — static site generator CLI

```text
APP_DESCRIPTION: A CLI static-site generator for documentation-heavy engineering teams. It reads Markdown with front matter, resolves cross-references and code includes, renders with themeable templates, builds a client-side search index, and outputs a deployable static bundle with incremental rebuilds.
TECH_STACK: LuaJIT CLI + lua-cmark Markdown + etlua templates + LuaFileSystem watch mode, distributed as a single binary via LuaRocks
APP_TYPE: CLI
LANGUAGE: Lua
SCALE: sites up to 8,000 pages, full build <12s, incremental rebuild <1s
```

## 15. HarborHush — MQTT broker authorization

```text
APP_DESCRIPTION: An API service that provides authorization and message routing rules for an industrial MQTT broker. It evaluates topic ACLs per device certificate, rewrites topics for tenant isolation, throttles chatty publishers, and logs policy decisions for the OT security team.
TECH_STACK: Lua auth plugin for VerneMQ/EMQX + Redis policy cache + PostgreSQL device registry, deployed on Kubernetes
APP_TYPE: API service
LANGUAGE: Lua
SCALE: ~500,000 connected devices, ~90k publishes/sec, policy eval <300 µs
```

## 16. GlyphGrove — font subsetting service

```text
APP_DESCRIPTION: An API service that serves optimized web fonts on demand. It receives page glyph coverage from a client shim, subsets and compresses fonts to only the characters in use, caches results per coverage signature at the edge, and reports bandwidth savings per site.
TECH_STACK: OpenResty + LuaJIT FFI to a subsetting library + Redis cache + S3 origin fonts + CDN, deployed on Fly.io regions
APP_TYPE: API service
LANGUAGE: Lua
SCALE: ~9,000 req/sec, 40k tracked sites, average 78% byte reduction per font
```

## 17. RiftRunner — dungeon crawler game

```text
APP_DESCRIPTION: A desktop roguelike where players descend procedurally generated dungeons, manage inventory and status effects, and fight turn-based tactical battles. It features permadeath runs, unlockable classes, and a modding API so the community can add rooms, items, and monster behaviors.
TECH_STACK: LÖVE (love2d) + Lua mod sandbox + serialized save state + Steamworks integration, shipped on Steam for Windows/macOS/Linux
APP_TYPE: desktop
LANGUAGE: Lua
SCALE: ~120k owners, runs with 5,000+ entities per floor, 60 fps target
```

## 18. TollThread — highway toll gantry service

```text
APP_DESCRIPTION: An API service at roadside toll gantries that matches transponder reads and plate events to accounts in real time. It debits balances, flags insufficient funds for downstream violation processing, and buffers transactions locally when the central link drops.
TECH_STACK: OpenResty on gantry controllers + Tarantool local store + lua-resty-http to central clearing + Redis, containerized on edge hardware
APP_TYPE: API service
LANGUAGE: Lua
SCALE: 220 gantries, ~3,000 vehicle events/sec at rush hour, <50ms decision latency
```

## 19. SpecSweep — API contract testing CLI

```text
APP_DESCRIPTION: A CLI tool for platform teams that verifies running services against their OpenAPI contracts. It generates request cases from the spec, replays them against staging, validates responses and schemas, checks backward compatibility between versions, and emits JUnit and JSON reports for CI.
TECH_STACK: LuaJIT CLI + lua-resty-http + a JSON Schema validator + cjson + LuaUnit assertions, distributed via LuaRocks and GitHub releases
APP_TYPE: CLI
LANGUAGE: Lua
SCALE: suites up to 4,000 cases, ~600 requests/sec replay, ~2,000 CI runs/day
```

## 20. NestNook — home automation hub

```text
APP_DESCRIPTION: A desktop and headless hub for smart homes that ties together lights, locks, sensors, and thermostats. Users script automations as declarative rules and Lua snippets, the hub runs them locally for privacy, and a web console shows device state and rule execution history.
TECH_STACK: Luvit event loop + local rule engine + SQLite state + Zigbee/Z-Wave adapters via FFI, runs on a Raspberry Pi appliance
APP_TYPE: desktop
LANGUAGE: Lua
SCALE: ~250 devices per home, sub-100ms local rule reaction, 30-day event history
```

## 21. StreamStrand — HLS packaging edge

```text
APP_DESCRIPTION: An API service that repackages live video into adaptive HLS/DASH at the edge for an IPTV provider. It rewrites manifests per client bandwidth, injects ad markers, enforces token-signed segment access, and shields origin encoders from request spikes during live events.
TECH_STACK: OpenResty + lua-resty-core manifest rewriting + Redis token store + segment cache + origin shield, deployed on edge PoPs
APP_TYPE: API service
LANGUAGE: Lua
SCALE: ~35,000 concurrent viewers/event, ~60k segment req/sec, manifest rewrite <2ms
```

## 22. ForgeFleet — CI runner orchestrator

```text
APP_DESCRIPTION: An API service that schedules self-hosted CI jobs across a fleet of build runners. It accepts pipeline webhooks, matches jobs to runners by capability labels, tracks live job state, streams logs to clients, and reclaims stuck runners with heartbeat timeouts.
TECH_STACK: Lapis (OpenResty) + PostgreSQL via pgmoon + Redis job queue + WebSocket log streaming + etlua console, deployed on Kubernetes
APP_TYPE: web app
LANGUAGE: Lua
SCALE: ~1,200 concurrent jobs, 400 runners, ~50k jobs/day
```

## 23. WaveWeld — DSP effects prototyper

```text
APP_DESCRIPTION: A desktop tool for audio engineers to prototype real-time DSP effect chains. Users patch filters, delays, and modulators as nodes, tweak parameters against live input, visualize spectra, and export chains as C or Faust stubs for embedding in hardware pedals.
TECH_STACK: LÖVE (love2d) for UI + LuaJIT FFI to a portaudio/dsp core + node graph engine, packaged as a desktop app
APP_TYPE: desktop
LANGUAGE: Lua
SCALE: <10ms round-trip latency, 64-node graphs, 48 kHz stereo processing
```

## 24. ScaleScribe — Redis rate-limit library

```text
APP_DESCRIPTION: An API service and reusable library that centralizes rate limiting for a microservice fleet. It exposes token-bucket, sliding-window, and concurrency-limit primitives as Redis Lua scripts, with a control plane for per-route policies and a dashboard of near-limit consumers.
TECH_STACK: Redis Lua scripts + OpenResty control plane + lua-resty-redis + PostgreSQL policy store, deployed on Kubernetes
APP_TYPE: API service
LANGUAGE: Lua
SCALE: ~40,000 limit checks/sec, 900 protected routes, atomic decision <150 µs
```

## 25. DriftDeck — Hammerspoon window automation

```text
APP_DESCRIPTION: A macOS desktop automation suite built on Hammerspoon for power users and developers. It provides tiling window layouts per app context, quick-switch workspaces, clipboard history, and app-launch macros triggered by hotkeys, all configured as versioned Lua config.
TECH_STACK: Hammerspoon Lua + hs.window/hs.hotkey APIs + local JSON state, distributed as a config bundle
APP_TYPE: desktop
LANGUAGE: Lua
SCALE: ~8k users, sub-50ms hotkey response, dozens of layout profiles per user
```

## 26. PulsePave — clickstream ingest pipeline

```text
APP_DESCRIPTION: A data pipeline that ingests web and app analytics events at the edge and normalizes them for downstream warehousing. It validates event schemas, enriches with geo and device parsing, drops bots, batches by tenant, and delivers to the warehouse with at-least-once guarantees.
TECH_STACK: OpenResty ingest + lua-resty-kafka + Redis dedup + ClickHouse + schema registry, self-hosted on Kubernetes
APP_TYPE: data pipeline
LANGUAGE: Lua
SCALE: ~200k events/sec peak, ~500 GB/day, 2,000 tenant streams
```

## 27. CobbleClad — package manager CLI

```text
APP_DESCRIPTION: A CLI package and environment manager for embedded Lua projects. It resolves dependency trees with version constraints, vendors rocks into a project-local tree, builds native modules per target, and produces reproducible lockfiles for firmware and game builds.
TECH_STACK: LuaJIT CLI wrapping LuaRocks + FFI build hooks + SQLite manifest cache, distributed as a self-contained binary
APP_TYPE: CLI
LANGUAGE: Lua
SCALE: trees up to 300 dependencies, cross-builds for 6 targets, lockfile reproducibility
```

## 28. AtlasAnvil — MMO zone server

```text
APP_DESCRIPTION: An API service that runs a single MMO world zone with authoritative simulation. It manages entity interest zones, resolves combat and crafting actions, streams state deltas to nearby clients, and persists character and world changes with graceful zone handoff on transfer.
TECH_STACK: Luvit + spatial interest management + Tarantool persistence + Redis cross-zone messaging, deployed on Docker/K8s
APP_TYPE: API service
LANGUAGE: Lua
SCALE: ~3,000 concurrent players per zone, 15 Hz sim, ~200 zones in the shard
```

## 29. PermaPrint — receipt printer firmware

```text
APP_DESCRIPTION: Embedded firmware for networked thermal receipt printers in retail. It renders ESC/POS jobs from a print queue, manages paper and cutter status, exposes a small local API for POS terminals, and reports supply and error telemetry to a fleet dashboard.
TECH_STACK: eLua on ARM Cortex-M + luasocket TCP server + local job spool in flash, OTA firmware channel
APP_TYPE: CLI
LANGUAGE: Lua
SCALE: ~40k deployed printers, ~5 jobs/sec/store peak, 8-job local spool
```

## 30. VellumVault — Lapis document workspace

```text
APP_DESCRIPTION: A web app for legal teams to draft and review structured documents. Users assemble contracts from clause libraries, track redlines with per-clause history, route approvals, and generate final PDFs, with role-based access and full audit trails per matter.
TECH_STACK: Lapis (OpenResty) + PostgreSQL via pgmoon + Redis sessions + a Lua PDF renderer + S3 storage, deployed on AWS containers
APP_TYPE: web app
LANGUAGE: Lua
SCALE: ~1,800 users, ~120k documents, ~80 req/sec, 7-year retention
```

## 31. FrameFerry — mpv media companion

```text
APP_DESCRIPTION: A desktop scripting suite for mpv that turns the player into a study and review tool for language learners and film editors. It adds looping subtitle navigation, screenshot-with-subtitle export, per-file bookmarks, and auto-generated review decks from marked segments.
TECH_STACK: mpv Lua scripting API + JSON sidecar state + luasocket to a local export helper, installed as mpv scripts
APP_TYPE: desktop
LANGUAGE: Lua
SCALE: ~25k users, instant seek/loop response, per-file bookmark stores
```

## 32. QuotaQuill — API usage metering service

```text
APP_DESCRIPTION: A web app that meters and bills third-party API usage for a SaaS platform. It counts requests per plan dimension at the gateway, aggregates rolling usage windows, enforces overage rules, and gives customers a portal with usage dashboards, plan management, and monthly invoices.
TECH_STACK: Lapis (OpenResty) portal + an APISIX metering plugin + Redis counters + Tarantool aggregation + PostgreSQL billing, deployed on Kubernetes
APP_TYPE: web app
LANGUAGE: Lua
SCALE: ~30,000 metered req/sec, 6,000 tenants, minute-granularity usage rollups
```

## 33. KeywordKiln — Lightroom AI keywording plugin

```text
APP_DESCRIPTION: A Lightroom Classic plugin that auto-tags a photographer's catalog using a cloud vision model. It sends rendered previews of selected photos to a tagging API, maps returned labels onto a controlled hierarchical keyword tree, and writes confidence-scored keywords and IPTC captions back to each image for faster library search.
TECH_STACK: Lightroom Classic Lua SDK (LrTasks/LrHttp/LrCatalog) + JSON keyword schema + cloud vision REST API, packaged as an .lrplugin bundle
APP_TYPE: desktop
LANGUAGE: Lua
SCALE: catalogs up to 500k photos, batch tagging ~40 previews/min, throttled API concurrency
```

## 34. SluiceStream — Kafka transform pipeline

```text
APP_DESCRIPTION: A data pipeline that performs stateless and windowed transforms on event streams for a telecom analytics team. It parses call-detail records, joins reference lookups, computes per-cell rollups, and writes enriched records to the warehouse and a real-time alerting topic.
TECH_STACK: LuaJIT workers + lua-resty-kafka consumers/producers + Redis lookup cache + ClickHouse sink, containerized on Kubernetes
APP_TYPE: data pipeline
LANGUAGE: Lua
SCALE: ~180k CDRs/sec, ~1.2 TB/day, 5-minute windowed rollups
```

## 35. KnitKernel — Defold puzzle game

```text
APP_DESCRIPTION: A cross-platform puzzle game where players route colored yarn through grids to complete patterns under move limits. It features hundreds of handcrafted levels, a daily challenge mode, and a built-in level editor whose community creations sync through a shared gallery.
TECH_STACK: Defold engine with Lua scripts + Defold live-update content + a Lapis backend for the gallery, shipped on desktop and web
APP_TYPE: desktop
LANGUAGE: Lua
SCALE: ~400k installs, 900 built-in levels, 60 fps on low-end hardware
```

## 36. SentrySlice — WAF rule engine

```text
APP_DESCRIPTION: An API service that provides a web application firewall in front of customer origins. It evaluates request signatures, anomaly scores, and rate anomalies per rule set, challenges suspicious traffic, and lets security teams ship and test rules as versioned config with shadow mode.
TECH_STACK: OpenResty + lua-resty-waf-style engine + Redis reputation store + ClickHouse event log, deployed on edge PoPs
APP_TYPE: API service
LANGUAGE: Lua
SCALE: ~60,000 req/sec inspected, 40k protected hostnames, rule eval <1ms
```

## 37. ChartChisel — terminal dashboard CLI

```text
APP_DESCRIPTION: A CLI tool that renders live operational dashboards in the terminal for on-call engineers. It pulls metrics from Prometheus and log sources, draws sparklines, gauges, and tables with configurable layouts, and supports drill-down and alert acknowledgment without leaving the shell.
TECH_STACK: LuaJIT + a TUI library + lua-resty-http metric fetchers + YAML dashboard config, distributed via LuaRocks
APP_TYPE: CLI
LANGUAGE: Lua
SCALE: refresh every 2s, 40 panels per dashboard, dozens of concurrent metric queries
```

## 38. GroveGate — IoT device provisioning API

```text
APP_DESCRIPTION: A web app that onboards and manages fleets of IoT devices for an industrial customer. Devices attest identity on first boot and receive scoped credentials and config over an API, while operators use a console to manage rollout rings, OTA eligibility, revocation, and fleet health dashboards.
TECH_STACK: Lapis (OpenResty) console + an OpenResty device API + lua-resty-jwt + Tarantool device registry + Redis + S3 firmware, deployed on Kubernetes
APP_TYPE: web app
LANGUAGE: Lua
SCALE: ~2M devices, ~10k check-ins/sec, staged OTA to rings of 50k
```

## 39. LatchLoom — password vault CLI

```text
APP_DESCRIPTION: A CLI secrets manager for developers that stores credentials in an encrypted local vault and syncs across machines. It supports hierarchical secret paths, per-item TOTP generation, git-backed encrypted sync, and shell integration to inject secrets into command environments.
TECH_STACK: LuaJIT + FFI to libsodium + SQLite encrypted store + git sync + shell hooks, distributed as a single binary
APP_TYPE: CLI
LANGUAGE: Lua
SCALE: vaults up to 10k secrets, unlock <100ms, encrypted git sync
```

## 40. PortfolioPost — Lightroom portfolio publish service

```text
APP_DESCRIPTION: A Lightroom Classic publish-service plugin that keeps a photographer's website galleries in sync with the catalog. Photographers drag photos into published collections; the plugin exports sized renditions, uploads them to the portfolio host, and tracks added, edited, and removed images so remote galleries mirror the catalog exactly.
TECH_STACK: Lightroom Classic Lua SDK (LrPublishService/LrExportSession/LrHttp) + OAuth token store + portfolio host REST API, distributed as an .lrplugin
APP_TYPE: desktop
LANGUAGE: Lua
SCALE: syncs 100+ published collections, incremental uploads, ~2k photos per gallery
```

## 41. QueueQuartz — job scheduling API

```text
APP_DESCRIPTION: An API service that provides reliable background job scheduling for application teams. It accepts one-off and cron jobs, guarantees at-least-once delivery with retries and backoff, supports priority lanes and rate caps per queue, and exposes a status API for job introspection.
TECH_STACK: OpenResty + Redis Lua scripts for atomic dequeue + lua-resty-redis + PostgreSQL job archive, deployed on Kubernetes
APP_TYPE: API service
LANGUAGE: Lua
SCALE: ~20,000 jobs/sec enqueued, 300 queues, exactly-once-ish dedup window
```

## 42. TerraTint — GIS tile server

```text
APP_DESCRIPTION: An API service that renders and serves map vector and raster tiles for a logistics platform. It reads geometry from a spatial store, styles tiles per client theme, caches by tile coordinate at the edge, and supports on-the-fly filtering of features by attribute.
TECH_STACK: OpenResty + LuaJIT geometry FFI + PostGIS via pgmoon + Redis tile cache + CDN, deployed on cloud regions
APP_TYPE: API service
LANGUAGE: Lua
SCALE: ~12,000 tile req/sec, planet-scale tileset, cache hit rate >90%
```

## 43. FlockForge — chat server plugin suite

```text
APP_DESCRIPTION: A set of Prosody XMPP server modules for a company running self-hosted team chat. The modules add message archiving policies, per-room moderation, compliance export, and rate limits on presence and typing, all configurable per virtual host by admins.
TECH_STACK: Prosody Lua modules + PostgreSQL archive + Redis presence cache, deployed on Linux servers
APP_TYPE: API service
LANGUAGE: Lua
SCALE: ~50,000 online users, ~8k messages/sec, multi-year compliant archive
```

## 44. CairnCraft — 3D voxel building game

```text
APP_DESCRIPTION: A sandbox desktop game where players mine, build, and automate in a voxel world with survival mechanics. It supports a deep Lua modding API for blocks, tools, and machines, cooperative LAN play, and a scripting console for in-world redstone-style logic circuits.
TECH_STACK: Minetest/Luanti Lua game API + LuaJIT + SQLite map store + LAN multiplayer, distributed via game platforms
APP_TYPE: desktop
LANGUAGE: Lua
SCALE: worlds spanning millions of blocks, 16-player LAN, hundreds of active mods
```

## 45. LedgerLatch — payment webhook gateway

```text
APP_DESCRIPTION: An API service that receives, verifies, and fans out payment provider webhooks for an e-commerce backend. It validates signatures, deduplicates retries, normalizes event shapes across providers, and reliably delivers to internal consumers with ordered per-order guarantees.
TECH_STACK: OpenResty + lua-resty-hmac + Redis dedup + Tarantool ordered delivery queue + PostgreSQL, deployed on Kubernetes
APP_TYPE: API service
LANGUAGE: Lua
SCALE: ~6,000 webhooks/sec at sale peaks, 5 providers, ordered per-order delivery
```

## 46. MesaMender — config linter CLI

```text
APP_DESCRIPTION: A CLI tool for platform teams that lints and validates infrastructure config-as-code across formats. It parses nginx, HAProxy, and OpenResty configs, checks for insecure directives, duplicate routes, and missing timeouts, and outputs annotated diffs and SARIF for CI review.
TECH_STACK: LuaJIT parser + a rule engine + cjson/SARIF output + LuaFileSystem, distributed via LuaRocks and container images
APP_TYPE: CLI
LANGUAGE: Lua
SCALE: repos with thousands of config files, full lint <8s, ~1,500 CI runs/day
```

## 47. NimbusNook — edge KV store service

```text
APP_DESCRIPTION: An API service that offers a low-latency key-value store replicated to edge locations for feature config and A/B assignments. Writes go to a primary and stream to edges; reads are served locally in sub-millisecond time with per-key TTLs and namespace isolation.
TECH_STACK: OpenResty + lua-resty-lrucache + Tarantool replication + Redis pub/sub invalidation, deployed on global edge nodes
APP_TYPE: API service
LANGUAGE: Lua
SCALE: ~80,000 reads/sec/edge, 50 edge locations, read latency <0.5ms
```

## 48. StitchStudio — Neovim colorscheme designer

```text
APP_DESCRIPTION: A Neovim plugin for developers to design and live-edit editor colorschemes. It shows a palette editor in a split, previews highlight groups across real buffers and plugins, checks contrast ratios for accessibility, and exports themes as portable Lua files.
TECH_STACK: Neovim Lua + Treesitter highlight introspection + libuv + Lua theme codegen, installed via lazy.nvim
APP_TYPE: desktop
LANGUAGE: Lua
SCALE: ~10k users, live preview across 200+ highlight groups, instant apply
```

## 49. WicketWeir — SMS gateway router

```text
APP_DESCRIPTION: An API service that routes outbound SMS and OTP traffic across multiple carrier providers for a messaging platform. It picks routes by cost, deliverability, and destination rules, retries failed sends on alternate carriers, and enforces per-tenant send-rate quotas.
TECH_STACK: OpenResty + lua-resty-http to carrier APIs + Redis rate/quota + Tarantool routing table + PostgreSQL logs, on Kubernetes
APP_TYPE: API service
LANGUAGE: Lua
SCALE: ~4,000 messages/sec, 12 carrier routes, per-tenant quota enforcement
```

## 50. PixelPantry — asset packing CLI

```text
APP_DESCRIPTION: A CLI build tool for game teams that packs and optimizes art assets. It trims and packs sprites into atlases, compresses textures per platform, generates mipmaps and 9-slice metadata, and produces manifest files, integrating into engine build steps with caching.
TECH_STACK: LuaJIT + FFI to image codecs + a bin-packing algorithm + JSON manifests, distributed as a build binary
APP_TYPE: CLI
LANGUAGE: Lua
SCALE: thousands of source images, packing in <5s incremental, multi-platform outputs
```

## 51. HearthHelm — restaurant KDS

```text
APP_DESCRIPTION: A desktop kitchen display system for restaurants that shows and routes incoming orders to prep stations. Cooks bump tickets through stages, the system tracks ticket times and station load, groups items by course, and syncs order state with the front-of-house POS.
TECH_STACK: LÖVE (love2d) touchscreen UI + luasocket to POS + SQLite local state + Redis sync, deployed on kitchen-mounted panels
APP_TYPE: desktop
LANGUAGE: Lua
SCALE: ~40 stores, ~300 tickets/hour peak, sub-second ticket routing
```

## 52. CrestCache — image transform edge

```text
APP_DESCRIPTION: An API service that performs on-the-fly image resizing and format conversion at the edge for a media site. It applies signed transform URLs, negotiates AVIF/WebP by client support, caches variants aggressively, and enforces per-tenant transform quotas.
TECH_STACK: OpenResty + LuaJIT FFI to libvips + Redis cache + S3 origin + CDN, deployed on Fly.io regions
APP_TYPE: API service
LANGUAGE: Lua
SCALE: ~14,000 req/sec, 60k tenant sites, variant cache hit rate >92%
```

## 53. SignalSprig — packet capture forensics pipeline

```text
APP_DESCRIPTION: A data pipeline for a network security team that processes archived captures into indexed session records. It reassembles TCP streams, applies Lua dissectors for enterprise protocols, extracts metadata and file transfers, and writes searchable session summaries for incident review.
TECH_STACK: LuaJIT with FFI pcap + Wireshark dissector library + ClickHouse index + object storage, on Kubernetes batch workers
APP_TYPE: data pipeline
LANGUAGE: Lua
SCALE: ~5 TB/day of captures, ~800k packets/sec reassembled, 90-day searchable index
```

## 54. TumbleTome — interactive fiction engine

```text
APP_DESCRIPTION: A desktop authoring tool and runtime for branching interactive fiction. Authors write stories in a structured scripting language, define variables and conditional passages, test playthroughs with state inspection, and export self-contained playable builds for web and desktop.
TECH_STACK: LÖVE (love2d) editor and runtime + a Lua-based story DSL + SQLite project store + HTML export, packaged for desktop
APP_TYPE: desktop
LANGUAGE: Lua
SCALE: stories up to 10k passages, instant state inspection, exports under 3 MB
```

## 55. RelayRoost — GraphQL gateway

```text
APP_DESCRIPTION: An API service that federates multiple backend services behind a single GraphQL endpoint. It parses and plans queries, batches and caches subrequests, enforces per-field authorization and depth limits, and streams partial results, shielding clients from backend topology.
TECH_STACK: OpenResty + a Lua GraphQL executor + lua-resty-http subrequests + Redis response cache, deployed on Kubernetes
APP_TYPE: API service
LANGUAGE: Lua
SCALE: ~9,000 queries/sec, 22 federated services, per-field auth and depth limits
```

## 56. BeaconBraid — BLE gateway firmware

```text
APP_DESCRIPTION: Embedded firmware for Bluetooth Low Energy gateways in retail and warehouse settings. It scans for asset tags and beacons, filters and dedupes advertisements, computes coarse zone presence, and forwards batched location events to a central platform over Wi-Fi.
TECH_STACK: NodeMCU/Lua on ESP32 + BLE scan FFI + luasocket MQTT + local dedup buffer, OTA firmware updates
APP_TYPE: CLI
LANGUAGE: Lua
SCALE: ~10k gateways, ~2,000 advertisements/sec/gateway scanned, zone events batched every 5s
```

## 57. MortarMuse — Lapis marketplace

```text
APP_DESCRIPTION: A web app marketplace for handmade building materials connecting artisans and contractors. Sellers list products with lead times and regional shipping, buyers request quotes and place orders, and the platform handles messaging, order tracking, and escrowed payouts.
TECH_STACK: Lapis (OpenResty) + PostgreSQL via pgmoon + Redis + Stripe integration + S3 media, deployed on cloud containers
APP_TYPE: web app
LANGUAGE: Lua
SCALE: ~4,500 sellers, ~40k listings, ~120 req/sec, seasonal traffic spikes
```

## 58. VoltVane — EV charger management API

```text
APP_DESCRIPTION: An API service that manages a network of EV charging stations over OCPP. It handles charger heartbeats and session start/stop, authorizes RFID and app-initiated charges, meters energy for billing, and balances load across stations on shared circuits.
TECH_STACK: OpenResty WebSocket OCPP handler + Tarantool session store + Redis + PostgreSQL billing, deployed on Kubernetes
APP_TYPE: API service
LANGUAGE: Lua
SCALE: ~30,000 chargers, ~5k concurrent sessions, per-circuit load balancing
```

## 59. GlideGlyph — subtitle timing CLI

```text
APP_DESCRIPTION: A CLI tool for localization teams that repairs and retimes subtitle files in bulk. It detects timing drift against audio, fixes overlap and reading-speed violations, converts between subtitle formats, and validates against broadcast style rules with a per-file report.
TECH_STACK: LuaJIT + FFI to an audio VAD library + SRT/VTT/ASS parsers + cjson reports, distributed via LuaRocks
APP_TYPE: CLI
LANGUAGE: Lua
SCALE: batches of thousands of files, ~50 files/sec retimed, style-rule reporting
```

## 60. SprocketScape — factory HMI panel

```text
APP_DESCRIPTION: A desktop human-machine interface for a manufacturing line that visualizes machine state and lets operators control setpoints. It polls PLCs over Modbus, renders live mimic diagrams, logs alarms with acknowledgment, and trends process values for shift handover.
TECH_STACK: LÖVE (love2d) HMI UI + LuaJIT FFI Modbus + SQLite historian + local alarm log, on panel PCs at the line
APP_TYPE: desktop
LANGUAGE: Lua
SCALE: polls 300 tags at 5 Hz, ~20 machines per panel, 30-day local trend history
```

## 61. QuarryQuill — search indexing pipeline

```text
APP_DESCRIPTION: A data pipeline that builds and updates search indexes for an e-commerce catalog. It consumes product change events, denormalizes and enriches documents with pricing and inventory, computes ranking signals, and streams incremental updates to the search cluster.
TECH_STACK: LuaJIT workers + lua-resty-kafka consumers + Redis join cache + OpenSearch bulk API, containerized on Kubernetes
APP_TYPE: data pipeline
LANGUAGE: Lua
SCALE: ~8M products, ~40k change events/sec at catalog reindex, sub-minute freshness
```

## 62. MarkMuse — Lightroom watermark and export plugin

```text
APP_DESCRIPTION: A Lightroom Classic export plugin that applies branded watermarks and delivery presets in one pass. Users pick a logo, position, and opacity per output size; the plugin renders JPEG and web variants, embeds copyright metadata, and writes them into dated client-delivery folders.
TECH_STACK: Lightroom Classic Lua SDK (LrExportSession/LrView/LrBinding) + LrExportRendition post-processing + template config, packaged as an .lrplugin
APP_TYPE: desktop
LANGUAGE: Lua
SCALE: export batches of 1,000+ frames, multiple size variants per photo, reusable preset library
```

## 63. HingeHarbor — reverse proxy control plane

```text
APP_DESCRIPTION: An API service and control plane for a self-hosted reverse proxy fleet. Operators define routes, TLS, and upstreams as declarative config; the control plane validates and pushes to edge OpenResty nodes, tracks rollout health, and rolls back on error-rate spikes.
TECH_STACK: Lapis control plane + OpenResty data plane + etcd config + Redis health state + etlua dashboards, deployed on Kubernetes
APP_TYPE: web app
LANGUAGE: Lua
SCALE: 200 edge nodes, ~70k req/sec aggregate, config push in <2s cluster-wide
```

## 64. FableForge — dialogue tree editor

```text
APP_DESCRIPTION: A desktop tool for narrative designers to build branching game dialogue. Writers create nodes with conditions, variables, and voice-line references, visualize the graph, simulate playthroughs against a state model, and export localized dialogue tables for the engine.
TECH_STACK: LÖVE (love2d) graph UI + a Lua condition interpreter + SQLite + CSV/JSON export, packaged for desktop
APP_TYPE: desktop
LANGUAGE: Lua
SCALE: graphs up to 8,000 nodes, live simulation, exports for 15 languages
```

## 65. SluiceSentinel — DDoS mitigation edge

```text
APP_DESCRIPTION: An API service at the network edge that detects and mitigates volumetric and application-layer attacks. It scores traffic anomalies per source, issues JS and proof-of-work challenges, applies adaptive rate limits, and drains attack traffic while keeping legitimate users flowing.
TECH_STACK: OpenResty + lua-resty-core + Redis reputation + ClickHouse telemetry + BPF hooks via FFI, on bare-metal edge
APP_TYPE: API service
LANGUAGE: Lua
SCALE: ~200,000 req/sec inspected under attack, challenge decision <1ms, 60 PoPs
```

## 66. RootRattle — dependency audit CLI

```text
APP_DESCRIPTION: A CLI security tool that audits Lua and mixed-language project dependencies for known vulnerabilities and license risks. It resolves rockspecs and lockfiles, matches against advisory feeds, flags outdated and abandoned modules, and outputs remediation suggestions for CI gating.
TECH_STACK: LuaJIT CLI + rockspec parser + advisory feed sync + SQLite cache + SARIF output, distributed via LuaRocks
APP_TYPE: CLI
LANGUAGE: Lua
SCALE: scans trees of 500+ deps in <4s, daily advisory sync, CI gate integration
```

## 67. AmberArc — retro arcade cabinet frontend

```text
APP_DESCRIPTION: A desktop game launcher and frontend for retro arcade cabinets. It presents a scrollable game wall with art and video previews, launches emulators with per-game settings, tracks high scores and play time, and supports attract mode and coin-input hardware.
TECH_STACK: LÖVE (love2d) frontend + LuaJIT + SQLite metadata + GPIO/serial coin input via FFI, on cabinet PCs
APP_TYPE: desktop
LANGUAGE: Lua
SCALE: libraries of 5,000+ titles, 60 fps attract mode, per-game launch profiles
```

## 68. TideTally — sports live-scoring API

```text
APP_DESCRIPTION: An API service that ingests and distributes live sports scores and play-by-play. It accepts operator inputs and feed events, computes derived stats, pushes updates to subscribers over WebSocket and SSE, and serves cached snapshots to high-traffic scoreboard widgets.
TECH_STACK: OpenResty + WebSocket/SSE fan-out + Redis pub/sub + Tarantool stat store, deployed on edge PoPs
APP_TYPE: API service
LANGUAGE: Lua
SCALE: ~500k concurrent subscribers on match day, ~30k updates/sec fan-out
```

## 69. CogClave — build system CLI

```text
APP_DESCRIPTION: A CLI incremental build tool for polyglot embedded projects. It reads a Lua build description, computes a task graph with content hashing, runs compilers and codegen in parallel with caching, and produces reproducible artifacts with dependency-accurate rebuilds.
TECH_STACK: LuaJIT + libuv process pool + content-addressed cache in SQLite + FFI, distributed as a single binary
APP_TYPE: CLI
LANGUAGE: Lua
SCALE: graphs of 20k tasks, parallel across all cores, cache-hit rebuilds in <1s
```

## 70. PetalPost — Lapis newsletter platform

```text
APP_DESCRIPTION: A web app for independent writers to run paid email newsletters. Authors compose issues with a block editor, manage free and paid tiers, schedule sends, and view open and click analytics; readers manage subscriptions and archives through a hosted reader.
TECH_STACK: Lapis (OpenResty) + PostgreSQL via pgmoon + Redis queue + an SMTP sending worker + Stripe, deployed on containers
APP_TYPE: web app
LANGUAGE: Lua
SCALE: ~12k newsletters, ~3M subscribers, sends batched at ~5k emails/sec
```

## 71. MoltMonitor — industrial telemetry pipeline

```text
APP_DESCRIPTION: A data pipeline for a steel mill that ingests high-rate furnace and rolling-line telemetry. Edge collectors decode OPC-UA and Modbus streams, downsample and compress signals, detect out-of-band excursions, and forward both raw and rollup streams to the historian and alerting.
TECH_STACK: LuaJIT edge collectors + FFI OPC-UA + lua-resty-kafka + ClickHouse historian + Redis alert state, on edge and K8s
APP_TYPE: data pipeline
LANGUAGE: Lua
SCALE: ~50k tags at 100 Hz (~5M samples/sec), 30-day hot historian
```

## 72. StitchStrand — WebSocket presence service

```text
APP_DESCRIPTION: An API service that powers real-time presence and collaboration signals for apps. Clients connect over WebSocket to broadcast cursor, typing, and online state within rooms; the service fans out updates with backpressure and reconciles state on reconnect.
TECH_STACK: OpenResty WebSocket + lua-resty-websocket + Redis pub/sub + Tarantool presence store, deployed on Kubernetes
APP_TYPE: API service
LANGUAGE: Lua
SCALE: ~1M concurrent connections, ~80k presence updates/sec, per-room fan-out
```

## 73. QuillQuiver — API mock server CLI

```text
APP_DESCRIPTION: A CLI tool that spins up realistic mock API servers from specs for frontend and integration testing. It generates stateful responses from OpenAPI, supports scripted scenarios and latency/error injection, records and replays real traffic, and runs as a lightweight local process.
TECH_STACK: OpenResty embedded + a Lua scenario DSL + cjson + SQLite recorded traffic, distributed as a single binary
APP_TYPE: CLI
LANGUAGE: Lua
SCALE: handles ~10k req/sec locally, hundreds of scripted routes, deterministic replay
```

## 74. GraniteGlade — tower defense game

```text
APP_DESCRIPTION: A desktop tower-defense game with a physics-driven twist where terrain deforms as towers and enemies interact. It offers campaign and endless modes, a broad tech tree, and Steam Workshop mod support for custom maps, towers, and enemy waves written in Lua.
TECH_STACK: LÖVE (love2d) + a Lua physics layer + serialized saves + Steam Workshop, shipped on Steam
APP_TYPE: desktop
LANGUAGE: Lua
SCALE: ~250k owners, 2,000+ entities per wave, 60 fps with physics
```

## 75. CircuitCurl — hardware test runner CLI

```text
APP_DESCRIPTION: A CLI test harness for electronics manufacturing that runs end-of-line functional tests on boards. It sequences instrument measurements over SCPI, drives GPIO fixtures, evaluates pass/fail limits, and logs results with full traceability per serial number to the MES.
TECH_STACK: LuaJIT + FFI to VISA/SCPI + serial/GPIO drivers + SQLite result log + MES upload, on test-station PCs
APP_TYPE: CLI
LANGUAGE: Lua
SCALE: ~1,200 boards/shift, ~40 measurements per board, full per-serial traceability
```

## 76. HollowHelm — dungeon master toolkit

```text
APP_DESCRIPTION: A desktop toolkit for tabletop RPG game masters to run sessions. It manages encounter initiative, tracks combatant state and conditions, rolls dice with rule macros, reveals maps with fog of war on a second screen, and keeps campaign notes linked to entities.
TECH_STACK: LÖVE (love2d) UI + a Lua rules DSL + SQLite campaign store + second-screen output, packaged for desktop
APP_TYPE: desktop
LANGUAGE: Lua
SCALE: campaigns with thousands of entities, dual-screen map reveal, offline-first
```

## 77. PylonPulse — API health check service

```text
APP_DESCRIPTION: A web app that runs synthetic health checks against a company's endpoints from multiple regions. Teams configure scripted probes and assertions, watch SLO burn and latency dashboards, manage on-call alert routing, and publish a hosted status page that updates on sustained failures.
TECH_STACK: Lapis (OpenResty) dashboard + OpenResty probe timers + lua-resty-http + Tarantool result store + Redis + PostgreSQL SLO data, on multi-region K8s
APP_TYPE: web app
LANGUAGE: Lua
SCALE: ~40k probes/min across 8 regions, 6,000 monitored endpoints, sub-minute alerting
```

## 78. WarpWeave — CDN purge orchestrator

```text
APP_DESCRIPTION: An API service that coordinates cache purges across a multi-tier CDN. It accepts tag- and URL-based purge requests, expands them into node-level invalidations, fans out to edge caches with rate control, tracks completion, and confirms purge propagation to clients.
TECH_STACK: OpenResty + Redis purge queue + lua-resty-http to edge nodes + Tarantool tag index, deployed on Kubernetes
APP_TYPE: API service
LANGUAGE: Lua
SCALE: ~5,000 purge requests/sec, 300 edge nodes, tag expansion to millions of keys
```

## 79. GeoGraft — Lightroom GPS geotagging plugin

```text
APP_DESCRIPTION: A Lightroom Classic plugin that geotags photos from GPS track logs. It matches each photo's capture time to interpolated positions in imported GPX/FIT tracks, handles camera-clock and timezone offsets, and writes latitude, longitude, and altitude into the catalog with a map preview before committing.
TECH_STACK: Lightroom Classic Lua SDK (LrCatalog/LrView/LrPhotoInfo) + GPX/FIT parser in Lua + reverse-geocode REST lookup, packaged as an .lrplugin
APP_TYPE: desktop
LANGUAGE: Lua
SCALE: track logs with 100k+ points, matches thousands of photos per trip, sub-second time interpolation
```

## 80. TrellisTrace — distributed tracing collector

```text
APP_DESCRIPTION: A data pipeline that collects, samples, and processes distributed traces for a microservices platform. It receives OTLP spans at the edge, applies tail-based sampling by latency and error, assembles traces, computes service dependency metrics, and writes to the trace store.
TECH_STACK: OpenResty OTLP receiver + LuaJIT span buffers + lua-resty-kafka + ClickHouse trace store, on Kubernetes
APP_TYPE: data pipeline
LANGUAGE: Lua
SCALE: ~1M spans/sec ingested, tail-sampling to 2%, 15-day trace retention
```

## 81. AnvilAria — music tracker desktop

```text
APP_DESCRIPTION: A desktop music tracker for chiptune and game composers. Musicians sequence patterns across channels with a keyboard-driven grid, design instruments with envelopes and effects, preview in real time, and export to engine-ready audio and pattern data.
TECH_STACK: LÖVE (love2d) + LuaJIT FFI audio synth core + SQLite project store + WAV/module export, packaged for desktop
APP_TYPE: desktop
LANGUAGE: Lua
SCALE: songs with 64 channels, real-time synthesis, <10ms audio latency
```

## 82. QuayQuill — freight rating API

```text
APP_DESCRIPTION: An API service that computes shipping rates and transit estimates for a logistics broker. It evaluates carrier rate tables, fuel surcharges, dimensional weight, and accessorials against shipment inputs, returns ranked quotes, and caches carrier lookups to hit tight response budgets.
TECH_STACK: OpenResty + lua-resty-http to carrier APIs + Redis rate cache + Tarantool tariff tables + PostgreSQL, on Kubernetes
APP_TYPE: API service
LANGUAGE: Lua
SCALE: ~7,000 quote req/sec, 40 carriers, quote response under 120ms
```

## 83. MossMender — log parsing CLI

```text
APP_DESCRIPTION: A CLI tool for SREs that parses, filters, and reshapes log files on the command line. It applies named grok-style patterns, extracts fields, computes aggregations and top-N breakdowns, follows live files, and outputs JSON, tables, or line formats for piping.
TECH_STACK: LuaJIT + a pattern compiler + libuv file tailing + cjson output, distributed as a single binary via LuaRocks
APP_TYPE: CLI
LANGUAGE: Lua
SCALE: parses ~1M lines/sec, tails multi-GB files, streaming aggregation
```

## 84. HaloHarbor — game telemetry ingest

```text
APP_DESCRIPTION: A data pipeline that ingests gameplay telemetry from clients for a game analytics team. It receives batched events at the edge, validates and schematizes them, deduplicates client retries, enriches with player segments, and lands sessionized data in the warehouse.
TECH_STACK: OpenResty ingest + lua-resty-kafka + Redis dedup + ClickHouse + a schema registry, self-hosted on Kubernetes
APP_TYPE: data pipeline
LANGUAGE: Lua
SCALE: ~250k events/sec at launch peaks, ~600 GB/day, sessionized within minutes
```

## 85. FernFrame — Neovim task runner plugin

```text
APP_DESCRIPTION: A Neovim plugin that turns project task definitions into an in-editor runner. It discovers tasks from Makefiles and config, runs them in managed terminals with live output, parses errors into the quickfix list, and remembers per-project task history and favorites.
TECH_STACK: Neovim Lua + libuv jobs + Treesitter config parsing + quickfix integration, installed via lazy.nvim
APP_TYPE: desktop
LANGUAGE: Lua
SCALE: ~20k users, parallel task terminals, instant quickfix error routing
```

## 86. VaneVault — session store service

```text
APP_DESCRIPTION: An API service that provides fast, replicated session storage for web fleets. It stores and retrieves session blobs by token with TTL and sliding expiry, replicates across zones for failover, supports server-side session invalidation, and exposes bulk-revoke for security events.
TECH_STACK: OpenResty + lua-resty-redis + Tarantool replicated store + lua-resty-lrucache, deployed on multi-zone Kubernetes
APP_TYPE: API service
LANGUAGE: Lua
SCALE: ~60,000 session ops/sec, 40M active sessions, cross-zone failover <2s
```

## 87. CinderCraft — 2D physics sandbox game

```text
APP_DESCRIPTION: A desktop physics sandbox where players build machines and contraptions with joints, motors, and materials, then run simulations to solve challenges. It ships with a puzzle campaign, a free-build mode, and shareable creations exported as compact save files.
TECH_STACK: LÖVE (love2d) + Box2D bindings + LuaJIT + serialized creation files + a share gallery backend, shipped on desktop and web
APP_TYPE: desktop
LANGUAGE: Lua
SCALE: ~180k players, 1,500+ bodies simulated at 60 fps, shareable creations
```

## 88. ProbePetal — SNMP polling pipeline

```text
APP_DESCRIPTION: A data pipeline for a network operations team that polls SNMP metrics from thousands of devices. It schedules polls across communities and OIDs, handles retries and rate control per device, computes rate-of-change counters, and streams normalized metrics to the time-series store.
TECH_STACK: LuaJIT pollers + FFI to net-snmp + lua-resty-kafka + a time-series database + Redis scheduler, on Kubernetes
APP_TYPE: data pipeline
LANGUAGE: Lua
SCALE: ~40k devices, ~500k OID polls/min, 60s polling interval
```

## 89. GildGate — mTLS service mesh sidecar

```text
APP_DESCRIPTION: An API service that runs as a lightweight mesh sidecar handling service-to-service traffic. It terminates and originates mTLS, enforces per-service authorization policies, applies retries and circuit breaking, and emits golden-signal metrics without changing application code.
TECH_STACK: OpenResty sidecar + lua-resty-core + FFI to a TLS library + xDS config from a control plane + Prometheus, on Kubernetes
APP_TYPE: API service
LANGUAGE: Lua
SCALE: ~25,000 req/sec/sidecar, mTLS handshake reuse, policy eval <500 µs
```

## 90. ProofPerch — Lightroom client proofing plugin

```text
APP_DESCRIPTION: A Lightroom Classic publish-service plugin for client photo proofing. It uploads watermarked proofs to a hosted gallery, invites clients to favorite their selects, and pulls those picks back into the catalog as flags and color labels so the photographer can filter approved shots for retouching.
TECH_STACK: Lightroom Classic Lua SDK (LrPublishService/LrHttp/LrTasks) + proofing gallery REST API + selection sync polling, distributed as an .lrplugin
APP_TYPE: desktop
LANGUAGE: Lua
SCALE: 50+ concurrent client galleries, two-way select sync, ~800 proofs per session
```

## 91. QuiverQuay — feature flag edge service

```text
APP_DESCRIPTION: An API service that evaluates feature flags and experiment assignments at the edge for low latency. It resolves flags against user context with targeting rules and rollouts, assigns experiment variants with sticky bucketing, and streams flag changes to edges in real time.
TECH_STACK: OpenResty + lua-resty-lrucache + Tarantool flag store + Redis pub/sub + a Lapis admin, on global edge nodes
APP_TYPE: API service
LANGUAGE: Lua
SCALE: ~50,000 evaluations/sec/edge, 30 edge locations, eval latency <0.4ms
```

## 92. BastionBraid — SSH bastion audit gateway

```text
APP_DESCRIPTION: An API and proxy service that fronts SSH access to production hosts with recording and policy. It authenticates users against SSO, authorizes target hosts per role, records full session transcripts, enforces just-in-time access windows, and streams audit events to SIEM.
TECH_STACK: Luvit + FFI to libssh + Tarantool policy and session store + Redis + PostgreSQL audit, deployed on Kubernetes
APP_TYPE: API service
LANGUAGE: Lua
SCALE: ~2,000 concurrent sessions, 8,000 target hosts, full session recording
```

## 93. PloverParse — EDI translation pipeline

```text
APP_DESCRIPTION: A data pipeline for a supply-chain integrator that translates EDI documents between trading partners and internal systems. It parses X12 and EDIFACT interchanges, validates against partner maps, transforms to canonical JSON, and routes to ERP endpoints with acknowledgment tracking.
TECH_STACK: LuaJIT parsers + lua-resty-kafka + partner map store in PostgreSQL + Redis dedup + ERP connectors, on Kubernetes
APP_TYPE: data pipeline
LANGUAGE: Lua
SCALE: ~800k documents/day, 300 trading partners, ack round-trip tracked per interchange
```

## 94. VaultVerge — Lightroom offsite backup plugin

```text
APP_DESCRIPTION: A Lightroom Classic plugin that archives originals and catalog backups to offsite object storage. It tracks which masters have already been uploaded, streams new raws and sidecars to an S3-compatible bucket after each import, and verifies checksums so a photographer can restore any shoot after local drive loss.
TECH_STACK: Lightroom Classic Lua SDK (LrCatalog/LrTasks/LrFileUtils) + S3-compatible signed REST uploads + local upload-state ledger, packaged as an .lrplugin
APP_TYPE: desktop
LANGUAGE: Lua
SCALE: catalogs of 2-5 TB masters, incremental nightly archive, checksum-verified restores
```

## 95. GaugeGarden — Grafana-style metrics API

```text
APP_DESCRIPTION: An API service that serves a query and aggregation layer over a metrics store for dashboards. It parses a query language, plans and executes range and instant queries with downsampling, caches hot series, and enforces per-tenant query cost limits to protect the backend.
TECH_STACK: OpenResty + a Lua query planner + lua-resty-http to the TSDB + Redis result cache + Tarantool tenant limits, on K8s
APP_TYPE: API service
LANGUAGE: Lua
SCALE: ~10,000 queries/sec, 50M active series, per-tenant cost budgeting
```

## 96. RivetReel — video thumbnail sprite CLI

```text
APP_DESCRIPTION: A CLI tool for streaming platforms that generates thumbnail sprite sheets and preview reels from source video. It samples frames at scene changes and intervals, packs them into WebVTT-referenced sprites, produces hover-preview clips, and writes manifests for the player.
TECH_STACK: LuaJIT + FFI to ffmpeg + a sprite packer + WebVTT/JSON manifests, distributed as a build binary and container
APP_TYPE: CLI
LANGUAGE: Lua
SCALE: processes ~2,000 videos/day, scene-change sampling, sprites for hour-long files
```

## 97. HeatherHub — Lapis community forum

```text
APP_DESCRIPTION: A web app forum platform for hobbyist communities. Members post threads with rich formatting, follow categories, earn reputation, and moderate via flag queues; admins configure categories, roles, and anti-spam rules, with full-text search across the archive.
TECH_STACK: Lapis (OpenResty) + PostgreSQL via pgmoon + Redis cache + a full-text search index + S3 uploads, on cloud containers
APP_TYPE: web app
LANGUAGE: Lua
SCALE: ~200k members, ~4M posts, ~150 req/sec, sub-second search
```

## 98. ThistleThread — chatbot routing gateway

```text
APP_DESCRIPTION: An API service that routes customer messages across web, SMS, and messaging channels to bot and human agents. It normalizes inbound messages, applies routing and business-hours rules, maintains conversation state, and hands off to live agents with context on escalation.
TECH_STACK: OpenResty + lua-resty-http channel adapters + Tarantool conversation store + Redis + PostgreSQL, deployed on Kubernetes
APP_TYPE: API service
LANGUAGE: Lua
SCALE: ~6,000 messages/sec, 5 channels, stateful conversations across sessions
```

## 99. QuillQuarry — API documentation generator CLI

```text
APP_DESCRIPTION: A CLI tool that generates browsable API documentation from annotated Lua source and OpenAPI specs. It extracts doc comments and type annotations, cross-links modules and endpoints, renders a themeable static site with a try-it console, and validates that examples still pass.
TECH_STACK: LuaJIT + a Lua source parser + etlua templates + a JSON Schema validator + LuaFileSystem, distributed via LuaRocks
APP_TYPE: CLI
LANGUAGE: Lua
SCALE: codebases with thousands of symbols, full doc build <10s, example validation in CI
```

## 100. VineVanguard — robotics motion control

```text
APP_DESCRIPTION: A desktop and embedded control application for a warehouse pick robot that plans and executes motion. It runs inverse-kinematics solves, sequences pick-and-place trajectories, monitors joint telemetry for faults, and offers an operator console for jogging and program editing.
TECH_STACK: LuaJIT with FFI to a real-time motion core + luasocket to controllers + LÖVE operator console + SQLite programs, on an industrial PC
APP_TYPE: desktop
LANGUAGE: Lua
SCALE: 6-axis arms at 1 kHz control loop, ~600 picks/hour, per-joint fault monitoring
```
