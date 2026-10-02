# Go Blueprint Types — Copy-Paste Input Sets

Copy a fenced block into the prompt as-is, or swap individual fields.

## 1. LinkForge — team URL shortener

```text
APP_DESCRIPTION: A URL-shortener API service for marketing teams. Teams mint branded short links with UTM presets, set expiry and geo-targeted destinations, and pull click analytics (referrer, device, region) via API for campaign dashboards.
TECH_STACK: Go (chi router) + PostgreSQL + Redis cache + ClickHouse for click events, deployed on AWS
APP_TYPE: API service
LANGUAGE: Go
SCALE: ~2,000 redirect req/sec, 500 API clients, ~100 GB click events/year
```

## 2. HaulTrace — freight tracking API

```text
APP_DESCRIPTION: A freight-tracking API service for regional trucking companies. Dispatchers create loads with stops and driver assignments, driver phones push GPS pings, and shipper customers poll or subscribe to webhook status updates (picked up, in transit, delayed, delivered).
TECH_STACK: Go (Gin) + PostgreSQL/PostGIS + NATS for ping ingestion + webhook dispatcher, deployed on GCP
APP_TYPE: API service
LANGUAGE: Go
SCALE: ~800 req/sec (GPS pings), 3,000 active loads, ~30 GB/month location data
```

## 3. LogHerd — log aggregation pipeline

```text
APP_DESCRIPTION: A data pipeline for a mid-size SaaS company that aggregates application logs from 200 services. It tails container log streams, parses and enriches entries with deploy metadata, samples high-volume debug noise, routes error spikes to alerting, and writes searchable indexes with tiered retention.
TECH_STACK: Go + Kafka + ClickHouse + Vector-compatible ingestion + Grafana, self-hosted on Kubernetes
APP_TYPE: data pipeline
LANGUAGE: Go
SCALE: ~150k log lines/sec peak, ~400 GB/day, 30-day hot / 1-year cold retention
```

## 4. FlagPost — self-hosted feature flags

```text
APP_DESCRIPTION: A self-hosted feature-flag API service for engineering teams that cannot use SaaS flag vendors for compliance reasons. Teams define flags with percentage rollouts, user-segment targeting, and kill switches; SDKs poll or stream flag states; audit logs record every change.
TECH_STACK: Go (echo) + PostgreSQL + SSE streaming + embedded admin UI, distributed as a single binary/Docker image
APP_TYPE: API service
LANGUAGE: Go
SCALE: ~5,000 flag-evaluation req/sec, 80 engineering teams, <5 GB data
```

## 5. kubelint — Kubernetes manifest linter CLI

```text
APP_DESCRIPTION: A CLI tool for platform teams that lints Kubernetes manifests before deploy. It checks raw YAML, Helm output, and Kustomize builds against built-in and custom policy rules (resource limits, probes, security contexts, deprecated APIs), and emits human, JSON, and SARIF reports for CI annotation.
TECH_STACK: Go CLI (cobra) + kubernetes API machinery for parsing + embedded rule engine, distributed via Homebrew/GitHub releases
APP_TYPE: CLI
LANGUAGE: Go
SCALE: single user per invocation, CI usage ~1,000 runs/day across teams, <10 MB local data
```

## 6. StallSense — parking occupancy API

```text
APP_DESCRIPTION: An API service for municipal parking authorities that tracks garage and lot occupancy. Entry/exit sensors and payment kiosks push events, the service maintains real-time stall counts per facility, exposes availability to city apps and roadside signs, and produces daily utilization reports.
TECH_STACK: Go (fiber) + PostgreSQL + Redis for live counts + MQTT sensor ingestion, deployed on Azure
APP_TYPE: API service
LANGUAGE: Go
SCALE: ~300 sensor events/sec, 45 facilities, 200 req/sec availability reads, ~10 GB/year
```

## 7. PicPress — image resizing edge service

```text
APP_DESCRIPTION: An on-the-fly image-resizing API service for e-commerce platforms. It fetches origin images, applies URL-signed transformations (resize, crop, format conversion, quality), caches aggressively at the edge, and enforces per-tenant usage quotas.
TECH_STACK: Go + libvips (bimg) + Redis + S3 origin + CDN in front, deployed on Fly.io regions
APP_TYPE: API service
LANGUAGE: Go
SCALE: ~1,500 req/sec (85% cache hit), 60 tenants, ~2 TB cached derivatives
```

## 8. BerthBook — marina berth booking

```text
APP_DESCRIPTION: A berth-booking web app for small marinas. Boat owners request seasonal or transient berths matched by vessel dimensions and draft, marina staff manage the berth map and utility billing (power, water), and visiting sailors book overnight moorings.
TECH_STACK: Go (templ + HTMX) + PostgreSQL + Stripe, deployed on a single Hetzner VPS
APP_TYPE: web app
LANGUAGE: Go
SCALE: 70 concurrent users, ~12 req/sec, ~2 GB data
```

## 9. PayStream — payroll file pipeline

```text
APP_DESCRIPTION: A data pipeline for a payroll bureau that generates bank payment files. It ingests approved payroll runs from client HR systems, validates account and amount data, produces SEPA/ACH batch files with hash totals, transmits them over SFTP to partner banks, and reconciles bank acknowledgments.
TECH_STACK: Go + PostgreSQL + SFTP integrations + audit event log, deployed on-premises for compliance
APP_TYPE: data pipeline
LANGUAGE: Go
SCALE: 900 client companies, ~250k payment lines per cycle, twice-monthly peaks, <20 GB data
```

## 10. repopulse — git metrics CLI

```text
APP_DESCRIPTION: A CLI tool for engineering managers that computes repository health metrics from local git history. It reports review latency, change failure hotspots, bus-factor per directory, and commit cadence trends, outputting terminal dashboards or JSON for further analysis — no data leaves the machine.
TECH_STACK: Go CLI (cobra) + go-git + local SQLite cache + terminal charts, distributed via GitHub releases
APP_TYPE: CLI
LANGUAGE: Go
SCALE: single user, repos up to 1M commits, <1 GB local cache
```

## 11. VoltMesh — EV charging network API

```text
APP_DESCRIPTION: An API service for EV charging network operators that manages charge points, sessions, and driver billing. Stations report status and meter values over OCPP, drivers start sessions from partner apps, and operators set dynamic tariffs and receive fault alerts per connector.
TECH_STACK: Go (chi) + PostgreSQL + Redis + OCPP 1.6/2.0 WebSocket gateway + Stripe billing, deployed on AWS
APP_TYPE: API service
LANGUAGE: Go
SCALE: 12,000 connected charge points, ~600 OCPP messages/sec, 90k sessions/day
```

## 12. GrainCast — grain elevator inventory API

```text
APP_DESCRIPTION: An API service for grain elevator cooperatives that tracks inbound truck tickets, bin inventory by commodity and grade, and forward contracts with farmers. Scale operators post weights and moisture readings, merchandisers see real-time position by commodity, and settlement statements are generated per delivery.
TECH_STACK: Go (Gin) + PostgreSQL + NATS for scale-house events + PDF settlement generation, deployed on GCP
APP_TYPE: API service
LANGUAGE: Go
SCALE: 35 elevator sites, ~1,200 truck tickets/day at harvest peak, ~15 GB/year
```

## 13. HookHarbor — webhook delivery service

```text
APP_DESCRIPTION: A webhook-delivery API service that SaaS products embed to send events to their customers reliably. Producers publish events, the service fans out to customer endpoints with signed payloads, exponential retries, circuit breakers per endpoint, and a searchable delivery log customers can replay from.
TECH_STACK: Go (chi) + PostgreSQL + Redis streams for queueing + HMAC signing, deployed on AWS with multi-region workers
APP_TYPE: API service
LANGUAGE: Go
SCALE: ~9,000 deliveries/sec peak, 40,000 registered endpoints, 30-day delivery log (~1 TB)
```

## 14. TideGate — coastal flood sensor pipeline

```text
APP_DESCRIPTION: A data pipeline for a coastal water authority that ingests tide gauge, rain gauge, and pump station telemetry across an estuary. It validates and gap-fills readings, computes surge thresholds against forecast models, triggers flood-barrier alerts to duty engineers, and archives series for regulators.
TECH_STACK: Go + MQTT ingestion + NATS JetStream + TimescaleDB + alert dispatcher (SMS/email), deployed on Azure
APP_TYPE: data pipeline
LANGUAGE: Go
SCALE: 850 sensors at 10-second intervals (~85 readings/sec), 25-year retention, ~120 GB/year
```

## 15. sqldrift — schema drift detection CLI

```text
APP_DESCRIPTION: A CLI tool for database teams that detects drift between declared schema files and live databases. It introspects PostgreSQL and MySQL instances, diffs against migration-managed DDL in the repo, flags manual hotfixes and missing indexes, and emits JSON or exit codes for CI gates.
TECH_STACK: Go CLI (cobra) + pgx/mysql drivers + embedded DDL parser + diff engine, distributed as a single binary
APP_TYPE: CLI
LANGUAGE: Go
SCALE: single user per invocation, ~400 CI runs/day, databases up to 2,000 tables
```

## 16. FleetFuel — fuel card transaction API

```text
APP_DESCRIPTION: An API service for a fleet fuel-card issuer that authorizes and settles fuel purchases. It scores each pump authorization against vehicle tank capacity, geofence, and odometer plausibility, blocks suspect swipes in real time, and feeds clean transactions to fleet expense systems.
TECH_STACK: Go (gRPC + REST gateway) + PostgreSQL + Redis for auth decisioning + Kafka settlement feed, deployed on AWS
APP_TYPE: API service
LANGUAGE: Go
SCALE: ~450 authorizations/sec peak, 220,000 active cards, <50 ms p99 auth latency
```

## 17. WardWatch — hospital bed capacity API

```text
APP_DESCRIPTION: An API service for a regional hospital group that tracks bed capacity and patient flow. ADT feeds from ward systems update bed states (occupied, cleaning, blocked), bed managers query capacity by ward and acuity, and transfer coordinators get alerts when ICU headroom drops below thresholds.
TECH_STACK: Go (echo) + PostgreSQL + HL7v2/FHIR ingestion adapters + SSE dashboards, deployed on-premises for health data compliance
APP_TYPE: API service
LANGUAGE: Go
SCALE: 14 hospitals, 6,800 beds, ~40 ADT events/sec, 5-year audit retention
```

## 18. SpoolPilot — 3D print farm manager

```text
APP_DESCRIPTION: A web app for print-farm operators running racks of 3D printers. It queues sliced jobs across printers by material and bed size, streams webcam snapshots and thermal telemetry, pauses jobs on spaghetti detection, and tracks filament spool inventory per machine.
TECH_STACK: Go (templ + HTMX) + SQLite + MQTT to printer agents + WebSocket status streams, self-hosted single binary
APP_TYPE: web app
LANGUAGE: Go
SCALE: 120 printers per farm, ~300 concurrent jobs/day, 15 operator users, ~40 GB webcam snapshots
```

## 19. AdVerdict — click-fraud scoring pipeline

```text
APP_DESCRIPTION: A data pipeline for an ad network that scores click and impression streams for fraud. It joins clicks against device fingerprints and IP reputation, detects click farms via velocity and entropy features, quarantines suspect traffic before advertiser billing, and produces daily invalid-traffic reports.
TECH_STACK: Go + Kafka + Redis feature store + ClickHouse + rules-plus-model scoring stage, deployed on GCP
APP_TYPE: data pipeline
LANGUAGE: Go
SCALE: ~220k events/sec peak, 4 billion events/day, decisions within 2 seconds of click
```

## 20. MatchMint — game matchmaking service

```text
APP_DESCRIPTION: A matchmaking API service for a multiplayer arena game studio. It maintains skill-rated queues per region and mode, forms balanced lobbies under latency and party-size constraints, reserves game-server slots via the fleet manager, and reports queue-time percentiles to designers.
TECH_STACK: Go (gRPC) + Redis sorted-set queues + NATS + Agones game-server integration, deployed on GKE
APP_TYPE: API service
LANGUAGE: Go
SCALE: 180,000 concurrent players peak, ~2,500 matches formed/min, p95 queue time under 45 s
```

## 21. ClipKiln — video transcoding pipeline

```text
APP_DESCRIPTION: A data pipeline for a video hosting platform that transcodes uploads into adaptive streaming ladders. It probes source files, splits long videos into segments for parallel encoding, assembles HLS/DASH renditions with thumbnails and preview sprites, and publishes to origin storage with CDN purge.
TECH_STACK: Go workers + FFmpeg + SQS job queues + S3 + PostgreSQL job ledger, autoscaled on EC2 spot instances
APP_TYPE: data pipeline
LANGUAGE: Go
SCALE: ~18,000 uploads/day, 2,200 hours of video/day, 6 renditions per source, ~55 TB/month output
```

## 22. zonewarden — DNS audit CLI

```text
APP_DESCRIPTION: A CLI tool for infrastructure teams that audits DNS zones for misconfigurations and takeover risk. It fetches records from Route 53, Cloudflare, and zone-file exports, flags dangling CNAMEs, missing CAA/SPF/DMARC records, and drift against a declared zone spec, and outputs JSON or SARIF for CI.
TECH_STACK: Go CLI (cobra) + provider APIs + miekg/dns resolver checks, distributed via Homebrew/GitHub releases
APP_TYPE: CLI
LANGUAGE: Go
SCALE: single user per invocation, zones up to 50,000 records, ~200 scheduled CI runs/day
```

## 23. MeterMuse — smart meter ingestion pipeline

```text
APP_DESCRIPTION: A data pipeline for an electricity retailer that ingests interval reads from smart meters. It normalizes vendor head-end formats, validates and estimates missing intervals per market rules, aggregates half-hourly consumption for settlement, and feeds billing and customer usage dashboards.
TECH_STACK: Go + Kafka + TimescaleDB + validation/estimation rule engine + S3 archive, deployed on AWS
APP_TYPE: data pipeline
LANGUAGE: Go
SCALE: 1.8 million meters, 86 million interval reads/day (~1,000/sec sustained), 7-year retention
```

## 24. QuayQueue — container terminal appointments

```text
APP_DESCRIPTION: An API service for a container port that manages truck gate appointments. Hauliers book time slots tied to container availability and customs status, the gate OCR system checks arrivals against bookings, and terminal planners tune slot capacity per shift to smooth yard congestion.
TECH_STACK: Go (Gin) + PostgreSQL + Redis slot inventory + EDI/API links to terminal operating system, deployed on Azure
APP_TYPE: API service
LANGUAGE: Go
SCALE: 4,500 truck visits/day, ~90 req/sec at booking window open, 380 haulier companies
```

## 25. VaultVane — secrets rotation service

```text
APP_DESCRIPTION: A self-hosted API service for platform teams that rotates database credentials, API keys, and TLS certificates on schedule. It brokers short-lived credentials to workloads, executes rotation plugins against PostgreSQL, MySQL, and cloud IAM, and records every issuance in a tamper-evident audit log.
TECH_STACK: Go (chi) + BoltDB encrypted store + plugin system + SPIFFE-compatible workload auth, single binary on Kubernetes
APP_TYPE: API service
LANGUAGE: Go
SCALE: ~1,200 workloads, 9,000 secret leases/hour, 4,000 rotations/day, <2 GB data
```

## 26. ClinicCal — clinic scheduling web app

```text
APP_DESCRIPTION: A scheduling web app for multi-provider outpatient clinics. Front-desk staff book and reschedule visits against provider templates and room availability, patients confirm via SMS links, waitlists auto-fill cancellations, and no-show risk flags help staff double-confirm high-risk slots.
TECH_STACK: Go (templ + HTMX) + PostgreSQL + Twilio SMS + iCal feeds, deployed on a managed VPS per clinic group
APP_TYPE: web app
LANGUAGE: Go
SCALE: 26 clinics, 340 staff users, ~5,200 appointments/day, ~8 GB/year
```

## 27. TallyBooth — election results API

```text
APP_DESCRIPTION: An API service for a state election office that publishes election-night results. County clerks upload signed precinct tallies, the service validates against ballot manifests, aggregates races in real time, and serves results to media outlets and the public site with cryptographic result hashes per update.
TECH_STACK: Go (echo) + PostgreSQL + Ed25519 signature verification + CDN-cached JSON feeds, deployed on government cloud
APP_TYPE: API service
LANGUAGE: Go
SCALE: 3,100 precincts, ~50,000 req/sec public reads on election night via CDN, updates every 5 minutes
```

## 28. HoofHub — livestock telemetry pipeline

```text
APP_DESCRIPTION: A data pipeline for cattle station operators that ingests ear-tag and collar telemetry. It tracks animal location, rumination, and temperature, detects estrus and illness patterns from movement baselines, alerts stock managers to strays outside virtual fences, and builds per-animal health histories.
TECH_STACK: Go + LoRaWAN/satellite gateway ingestion + NATS + TimescaleDB + geofence engine, deployed on AWS
APP_TYPE: data pipeline
LANGUAGE: Go
SCALE: 240,000 tagged animals, ~700 telemetry messages/sec, 60 stations, ~90 GB/month
```

## 29. FareBeacon — transit fare validation API

```text
APP_DESCRIPTION: An API service for a city transit agency that validates fares at bus and rail gates. Tap devices authorize contactless cards and mobile passes in real time, the service applies daily fare capping and transfer rules, and finance gets reconciled ridership and revenue by route and hour.
TECH_STACK: Go (gRPC to validators, REST admin) + PostgreSQL + Redis for cap state + Kafka ridership feed, deployed on-premises with cloud DR
APP_TYPE: API service
LANGUAGE: Go
SCALE: ~1,100 taps/sec at commute peak, 1.4 million cards, <100 ms p99 gate decision
```

## 30. bucketbill — storage cost analyzer CLI

```text
APP_DESCRIPTION: A CLI tool for cloud cost teams that analyzes object-storage spend. It inventories S3/GCS buckets, breaks cost down by prefix, storage class, and age, simulates lifecycle-policy changes against real access logs, and outputs ranked savings recommendations as terminal tables or JSON.
TECH_STACK: Go CLI (cobra) + cloud inventory/billing APIs + DuckDB-style local analysis over parquet inventories
APP_TYPE: CLI
LANGUAGE: Go
SCALE: single user per invocation, inventories up to 3 billion objects, ~200 buckets per account
```

## 31. ChirpRelay — LoRaWAN network server

```text
APP_DESCRIPTION: A data pipeline for an IoT connectivity provider operating a LoRaWAN network server. It deduplicates uplinks across gateways, handles join-server key exchange and ADR rate control, decodes device payloads via tenant codecs, and routes decoded readings to customer MQTT and HTTP integrations.
TECH_STACK: Go + UDP/gRPC gateway bridges + Redis device sessions + PostgreSQL + MQTT/HTTP egress, self-hosted on Kubernetes
APP_TYPE: data pipeline
LANGUAGE: Go
SCALE: 3,200 gateways, 900,000 devices, ~4,000 uplinks/sec peak, 45 tenants
```

## 32. LedgerLoom — double-entry ledger API

```text
APP_DESCRIPTION: A double-entry ledger API service that fintech products embed for wallet and money-movement accounting. It records atomic multi-leg transactions with idempotency keys, enforces per-account balance constraints and currency rules, and serves point-in-time balances and audit trails to downstream reporting.
TECH_STACK: Go (gRPC + REST) + PostgreSQL with strict serializable transactions + Kafka outbox + immutable event archive, deployed on AWS
APP_TYPE: API service
LANGUAGE: Go
SCALE: ~3,500 postings/sec peak, 40 million accounts, 100% balanced-books invariant checks nightly
```

## 33. codestamp — artifact signing CLI

```text
APP_DESCRIPTION: A CLI tool for release engineers that signs and verifies build artifacts in CI. It signs binaries, container images, and SBOMs with KMS-backed or keyless certificates, embeds provenance attestations, and verifies signatures against policy (allowed identities, max age) before deploy jobs proceed.
TECH_STACK: Go CLI (cobra) + Sigstore libraries + cloud KMS integrations + in-toto attestation format, distributed via GitHub releases
APP_TYPE: CLI
LANGUAGE: Go
SCALE: single user per invocation, ~2,500 CI signing operations/day across an org, artifacts up to 4 GB
```

## 34. RinkTime — ice rink booking web app

```text
APP_DESCRIPTION: A booking web app for municipal ice rinks. Hockey clubs and figure-skating coaches reserve ice slots by rink and surface-prep type, public skate sessions sell capacity-limited tickets, and rink managers schedule resurfacing gaps and see utilization heatmaps per season.
TECH_STACK: Go (templ + HTMX) + PostgreSQL + Stripe + iCal export, deployed on a single VPS per municipality
APP_TYPE: web app
LANGUAGE: Go
SCALE: 6 rinks, ~900 bookings/week, 180 concurrent users at season-opening, ~3 GB data
```

## 35. PressPipe — newswire ingestion pipeline

```text
APP_DESCRIPTION: A data pipeline for a digital newsroom that ingests wire-service feeds and press releases. It normalizes NewsML and RSS sources, deduplicates near-identical stories across wires, tags entities and topics, routes embargoed items to a timed release queue, and pushes matches to desk-specific editor alerts.
TECH_STACK: Go + Kafka + PostgreSQL + OpenSearch index + embargo scheduler, deployed on GCP
APP_TYPE: data pipeline
LANGUAGE: Go
SCALE: ~85,000 wire items/day, 14 source feeds, dedup+tag latency under 3 seconds, ~50 GB/month
```

## 36. RiskRudder — payment risk scoring API

```text
APP_DESCRIPTION: An API service for a payment gateway that scores card transactions for fraud before authorization. It evaluates velocity counters, device fingerprints, BIN and geo mismatch features against tenant-tuned rulesets, returns approve/review/decline within a strict latency budget, and feeds analyst case queues.
TECH_STACK: Go (gRPC) + Redis feature counters + PostgreSQL rules and cases + Kafka decision log, deployed on AWS across 3 regions
APP_TYPE: API service
LANGUAGE: Go
SCALE: ~6,000 scoring req/sec peak, <30 ms p99 decision latency, 320 merchant tenants
```

## 37. ApronAce — airport turnaround API

```text
APP_DESCRIPTION: An API service for airport ground handlers that coordinates aircraft turnarounds. It builds task timelines per flight (fueling, catering, cleaning, baggage, pushback), crews check off milestones from tablets, and delay codes propagate to airline ops when a critical-path task slips.
TECH_STACK: Go (fiber) + PostgreSQL + NATS for milestone events + AODB flight-feed integration, deployed on Azure
APP_TYPE: API service
LANGUAGE: Go
SCALE: 4 airports, ~650 turnarounds/day, 1,900 crew users, ~120 events/min at bank peaks
```

## 38. KegCompass — keg fleet tracking API

```text
APP_DESCRIPTION: An API service for craft breweries that tracks keg fleets through fill, distribution, and return. Fill-line scanners register batches to keg IDs, drivers scan drops and pickups at accounts, the service ages out kegs stuck at venues, and deposit balances reconcile per distributor.
TECH_STACK: Go (chi) + PostgreSQL + barcode/RFID scan ingestion API + webhook alerts, deployed on GCP
APP_TYPE: API service
LANGUAGE: Go
SCALE: 28 breweries, 190,000 kegs, ~45,000 scans/day, ~6 GB/year
```

## 39. GridNudge — demand response dispatch API

```text
APP_DESCRIPTION: An API service for a utility demand-response program that dispatches load-reduction events. It enrolls thermostats, EV chargers, and industrial loads via aggregator APIs, issues curtailment events with per-device setpoint strategies, measures delivered kilowatt reduction against baselines, and calculates participant credits.
TECH_STACK: Go (echo) + PostgreSQL + OpenADR/aggregator integrations + TimescaleDB for baselines, deployed on AWS GovCloud
APP_TYPE: API service
LANGUAGE: Go
SCALE: 310,000 enrolled devices, events dispatch to 100k devices in under 60 s, ~200 events/season
```

## 40. ProbeYard — synthetic monitoring service

```text
APP_DESCRIPTION: A self-hosted API service for SRE teams that runs synthetic uptime and transaction checks. It schedules HTTP, TCP, DNS, and multi-step browser-less API checks from distributed worker nodes, evaluates SLO burn rates, pages on-call via escalation policies, and publishes public status pages.
TECH_STACK: Go (chi) + PostgreSQL + worker agents over gRPC + embedded status-page UI, single binary plus agents
APP_TYPE: API service
LANGUAGE: Go
SCALE: 9,500 checks at 30-second intervals (~320 checks/sec), 22 probe locations, 400 teams
```

## 41. veilctl — PII redaction CLI

```text
APP_DESCRIPTION: A CLI tool for data engineers that redacts personal data from files before sharing or lower-environment loads. It detects names, emails, national IDs, and card numbers in CSV, JSON, and SQL dumps via pattern and dictionary passes, applies consistent pseudonyms so joins still work, and reports redaction counts per column.
TECH_STACK: Go CLI (cobra) + streaming parsers + deterministic keyed pseudonymization (HMAC) + rule packs per jurisdiction
APP_TYPE: CLI
LANGUAGE: Go
SCALE: single user per invocation, files up to 500 GB streamed, ~150 MB/sec throughput per core
```

## 42. QuoteQuarry — insurance rating engine

```text
APP_DESCRIPTION: An API service for a specialty insurer that rates and quotes commercial policies. Broker portals submit risk details, the engine executes versioned rating tables and underwriting rules per product line, returns premiums with full calculation breakdowns, and locks quote versions for bind-time reproducibility.
TECH_STACK: Go (gRPC + REST) + PostgreSQL + versioned rule/table store + document generation service, deployed on Azure
APP_TYPE: API service
LANGUAGE: Go
SCALE: ~90 quotes/sec at renewal season peak, 6 product lines, 2,400 broker users, 10-year quote retention
```

## 43. PlowTrail — snowplow tracking API

```text
APP_DESCRIPTION: An API service for county road departments that tracks snowplow operations in winter storms. Plow AVL units stream position, blade state, and salt-spreader rates; supervisors see route completion per priority tier; and a public map shows when each street was last plowed.
TECH_STACK: Go (fiber) + PostgreSQL/PostGIS + NATS AVL ingestion + tile-server map feed, deployed on GCP
APP_TYPE: API service
LANGUAGE: Go
SCALE: 340 plows reporting every 5 s (~70 msg/sec), 9,000 road segments, 25,000 public map users during storms
```

## 44. BadgeBeam — conference check-in web app

```text
APP_DESCRIPTION: A check-in web app for conference organizers. Registration desks scan QR tickets for instant badge printing, session-room scanners enforce capacity and track attendance for CPE credits, and organizers watch live arrival curves and no-show rates per ticket tier.
TECH_STACK: Go (templ + HTMX) + SQLite in WAL mode + label-printer integration + offline-tolerant scan queue, single binary on venue LAN
APP_TYPE: web app
LANGUAGE: Go
SCALE: events up to 8,000 attendees, ~25 check-ins/sec at doors-open peak, 40 scanner stations
```

## 45. RoamRake — roaming CDR pipeline

```text
APP_DESCRIPTION: A data pipeline for a mobile network operator that processes inbound roaming call detail records. It parses TAP3 files from partner carriers, rates voice, SMS, and data events against inter-operator tariffs, flags fraud patterns like SIM-box traffic, and produces monthly settlement statements per roaming agreement.
TECH_STACK: Go + SFTP/AS2 file exchange + Kafka + PostgreSQL rating store + ClickHouse analytics, deployed on-premises
APP_TYPE: data pipeline
LANGUAGE: Go
SCALE: ~120 million CDRs/day, 480 roaming partners, files processed within 15 minutes of arrival
```

## 46. gatehouse — SSH bastion audit service

```text
APP_DESCRIPTION: A self-hosted SSH bastion API service for security teams that brokers and records privileged server access. Engineers request time-boxed access tied to tickets, sessions are proxied with full keystroke recording, sensitive commands trigger real-time alerts, and auditors replay sessions with search across transcripts.
TECH_STACK: Go (SSH proxy via golang.org/x/crypto/ssh) + PostgreSQL + S3 session archives + OIDC + embedded audit UI, single binary
APP_TYPE: API service
LANGUAGE: Go
SCALE: 1,800 engineers, ~2,400 sessions/day, 6,000 target hosts, 2-year session retention (~4 TB)
```

## 47. PlayPulse — game telemetry pipeline

```text
APP_DESCRIPTION: A data pipeline for a game studio that ingests gameplay telemetry from live titles. It validates event schemas per game build, sessionizes player actions, computes funnel and economy metrics (retention, currency sinks, quest drop-off), and feeds designer dashboards and LiveOps experiment analysis.
TECH_STACK: Go + Kafka + schema registry + ClickHouse + S3 raw archive, deployed on AWS
APP_TYPE: data pipeline
LANGUAGE: Go
SCALE: ~350k events/sec peak after content drops, 9 million DAU across titles, ~1.2 TB/day
```

## 48. HarvestCrate — farm box subscription web app

```text
APP_DESCRIPTION: A subscription web app for a farm cooperative selling weekly produce boxes. Members choose box sizes and swap items within seasonal availability, farms post expected harvest quantities that drive box planning, and pack-line sheets and delivery route manifests are generated per drop site.
TECH_STACK: Go (templ + HTMX) + PostgreSQL + Stripe subscriptions + route manifest PDFs, deployed on a single VPS
APP_TYPE: web app
LANGUAGE: Go
SCALE: 4,200 subscribers, 18 member farms, 60 drop sites, weekly pack cycle, ~4 GB data
```

## 49. linkreap — dead link checker CLI

```text
APP_DESCRIPTION: A CLI tool for documentation teams that finds dead and redirected links across sites and repos. It crawls rendered docs or scans Markdown/HTML sources, checks links concurrently with per-host rate limits and retry heuristics, ignores flaky domains via allowlists, and fails CI with an annotated report.
TECH_STACK: Go CLI (cobra) + concurrent HTTP checker + Markdown/HTML parsers + JUnit/JSON reporters, distributed via Homebrew
APP_TYPE: CLI
LANGUAGE: Go
SCALE: single user per invocation, sites up to 200,000 links, ~500 checks/sec with rate limiting
```

## 50. RunnerRodeo — CI runner autoscaler

```text
APP_DESCRIPTION: An API service for platform teams that autoscales self-hosted CI runners. It watches GitHub Actions and GitLab job queues via webhooks, launches ephemeral runner VMs or pods sized to job labels, bin-packs jobs to spot capacity, and reclaims idle runners while reporting queue-wait and cost metrics per team.
TECH_STACK: Go (chi) + webhook ingestion + cloud provider APIs (EC2/GCE) + Kubernetes runner pods + Prometheus metrics, self-hosted
APP_TYPE: API service
LANGUAGE: Go
SCALE: ~38,000 CI jobs/day, 900 concurrent runners at peak, scale-up decision under 5 s
```

## 51. CatchQuota — fisheries quota API

```text
APP_DESCRIPTION: An API service for a national fisheries authority that tracks catch against vessel quotas. Skippers log catch by species from at-sea apps, dockside inspectors record landings, quota trades between vessel owners are registered, and the service closes fisheries automatically when fleet-wide quota nears exhaustion.
TECH_STACK: Go (echo) + PostgreSQL + offline-tolerant sync API for at-sea devices + signed landing records, deployed on government cloud
APP_TYPE: API service
LANGUAGE: Go
SCALE: 2,900 licensed vessels, ~9,000 catch reports/day in season, 140 managed stocks, 10-year retention
```

## 52. RxRoute — prescription routing API

```text
APP_DESCRIPTION: An API service for a pharmacy network that routes electronic prescriptions. It receives e-prescriptions from clinic systems, validates against formulary and stock at nearby branches, routes to the optimal pharmacy by wait time and inventory, and pushes ready-for-pickup notifications to patients.
TECH_STACK: Go (gRPC + REST) + PostgreSQL + NCPDP/FHIR adapters + Redis branch stock cache, deployed on-premises for health compliance
APP_TYPE: API service
LANGUAGE: Go
SCALE: 640 pharmacies, ~55,000 prescriptions/day, routing decision under 500 ms, 7-year audit retention
```

## 53. AisleSignal — retail foot traffic pipeline

```text
APP_DESCRIPTION: A data pipeline for a grocery chain that processes in-store sensor data. It ingests door counters, shelf-camera stock signals, and queue-length sensors, computes conversion and shelf-availability metrics per store hour, and alerts store managers when checkout queues breach service thresholds.
TECH_STACK: Go + MQTT edge gateways + Kafka + ClickHouse + store alert webhooks, deployed on Azure
APP_TYPE: data pipeline
LANGUAGE: Go
SCALE: 410 stores, ~28,000 sensors, ~5,500 events/sec, 3-year metric retention
```

## 54. thawtest — backup restore verification CLI

```text
APP_DESCRIPTION: A CLI tool for infrastructure teams that proves backups actually restore. It pulls recent database and volume backups, restores them into throwaway containers, runs integrity queries and row-count assertions against production manifests, and emits pass/fail evidence reports for compliance audits.
TECH_STACK: Go CLI (cobra) + Docker API for sandbox restores + pgx/mysql check probes + S3/restic backup sources
APP_TYPE: CLI
LANGUAGE: Go
SCALE: single user or nightly CI, ~80 backup sets verified/night, restores up to 2 TB
```

## 55. AcreLens — crop imagery pipeline

```text
APP_DESCRIPTION: A data pipeline for an agronomy service that processes drone and satellite imagery of farmland. It stitches and orthorectifies drone captures, computes NDVI and canopy-cover indices per field zone, detects irrigation faults and pest hotspots against historical baselines, and delivers scouting maps to agronomists.
TECH_STACK: Go orchestration + GDAL processing stages + S3 + PostgreSQL/PostGIS field zones + tile pyramid output, deployed on AWS Batch
APP_TYPE: data pipeline
LANGUAGE: Go
SCALE: 12,000 monitored fields, ~900 flights/week in season, 4 TB imagery/month, maps within 3 hours of upload
```

## 56. GantryFlow — toll transaction pipeline

```text
APP_DESCRIPTION: A data pipeline for a highway toll operator that clears gantry transactions. It matches ANPR plate reads with transponder pings, rates trips across gantry sequences and time-of-day tariffs, routes unmatched plates to a manual review queue, and exports settled charges to payment and violation systems.
TECH_STACK: Go + Kafka + PostgreSQL + plate-match dedup engine + SFTP exports to payment processors, deployed on-premises with cloud burst
APP_TYPE: data pipeline
LANGUAGE: Go
SCALE: ~2.6 million transactions/day (~90/sec sustained, 400/sec rush hour), 62 gantries, 99.5% auto-match rate
```

## 57. DocketDoor — court e-filing API

```text
APP_DESCRIPTION: An API service for a state judiciary that accepts electronic court filings. Attorneys submit documents with case metadata and fee payments, clerks review queues with rule-based rejection reasons, accepted filings stamp into the docket with certified timestamps, and service notifications reach opposing counsel.
TECH_STACK: Go (chi) + PostgreSQL + S3 document store with virus scanning + payment gateway + signed timestamp authority, government cloud
APP_TYPE: API service
LANGUAGE: Go
SCALE: 84 courts, ~31,000 filings/day, deadline-day peaks of 40 req/sec, 50-year document retention
```

## 58. SparkSpread — power trading API

```text
APP_DESCRIPTION: An API service for an energy trading desk that manages intraday power positions. It ingests exchange order books and grid forecast feeds, lets traders and algos place limit orders within risk limits, tracks open positions and P&L per delivery hour, and enforces kill-switch limits when volatility spikes.
TECH_STACK: Go (gRPC) + FIX/exchange API connectors + Redis order state + PostgreSQL + Kafka market-data bus, colocated deployment
APP_TYPE: API service
LANGUAGE: Go
SCALE: ~45,000 market-data updates/sec, 1,200 orders/min at gate closures, <5 ms internal order-path latency
```

## 59. dmarcden — email authentication analyzer

```text
APP_DESCRIPTION: A self-hosted API service for IT teams that analyzes DMARC, SPF, and DKIM posture. It receives aggregate and forensic DMARC reports to a dedicated mailbox/HTTPS endpoint, parses and geolocates sending sources, distinguishes legitimate senders from spoofers, and guides teams to enforcement with per-domain rollout scoring.
TECH_STACK: Go (echo) + IMAP/HTTPS report intake + XML report parsers + PostgreSQL + embedded dashboard UI, single binary
APP_TYPE: API service
LANGUAGE: Go
SCALE: 350 monitored domains, ~180,000 aggregate report rows/day, 13-month rolling retention
```

## 60. InkShed — self-hosted headless CMS

```text
APP_DESCRIPTION: A self-hosted headless CMS web app for content teams at agencies. Editors model content types with field validation, draft and schedule entries through review workflows, and localized content is served over a cached delivery API with webhooks that trigger static site rebuilds.
TECH_STACK: Go (chi) + SQLite or PostgreSQL + embedded React admin SPA + S3-compatible asset storage, distributed as a single binary
APP_TYPE: web app
LANGUAGE: Go
SCALE: 200 editor seats across tenants, ~1,800 delivery API req/sec cached, 120,000 content entries
```

## 61. ClubKey — gym access control API

```text
APP_DESCRIPTION: An API service for a gym franchise that controls member door access. Door controllers verify member QR and NFC credentials against membership status and club hours in real time, tailgating alerts flag single-scan multiple entries, and franchise owners see visit patterns and peak-load forecasts per club.
TECH_STACK: Go (fiber) + PostgreSQL + Redis credential cache + MQTT to door controllers + billing system webhooks, deployed on AWS
APP_TYPE: API service
LANGUAGE: Go
SCALE: 480 clubs, 1.1 million members, ~220 door checks/sec at evening peak, <150 ms unlock decision
```

## 62. imagemoat — container image scanner CLI

```text
APP_DESCRIPTION: A CLI tool for DevSecOps teams that scans container images for vulnerabilities and policy violations before push. It walks image layers for OS packages and language dependencies, matches against synced CVE databases, checks configs for root users and secrets in layers, and gates CI with severity thresholds.
TECH_STACK: Go CLI (cobra) + OCI registry client + local vulnerability DB (bbolt) + SBOM (SPDX/CycloneDX) output, single binary
APP_TYPE: CLI
LANGUAGE: Go
SCALE: single user per invocation, ~3,000 CI scans/day across an org, images up to 8 GB, DB sync of ~2M advisories
```

## 63. RailRoster — train crew scheduling API

```text
APP_DESCRIPTION: An API service for a regional rail operator that schedules train crew. It builds legal rosters against rest-period, route-knowledge, and traction-certification rules, handles day-of-operations disruption re-crewing with call-out lists, and tracks hours worked for payroll and safety compliance.
TECH_STACK: Go (Gin) + PostgreSQL + constraint-check rule engine + roster export to payroll + mobile crew notifications, on-premises
APP_TYPE: API service
LANGUAGE: Go
SCALE: 3,400 crew members, 1,900 daily train services, disruption re-plan for 60 services under 2 minutes
```

## 64. ScrapSort — recycling weighbridge API

```text
APP_DESCRIPTION: An API service for scrap-metal and recycling yards that handles weighbridge tickets and material grading. Inbound loads get tare/gross weights from bridge hardware, graders assign material codes with photo evidence, prices apply from daily commodity sheets, and sellers are paid against compliance-checked IDs.
TECH_STACK: Go (chi) + PostgreSQL + serial/IP weighbridge integration + photo storage on S3 + payment export, deployed on Azure
APP_TYPE: API service
LANGUAGE: Go
SCALE: 55 yards, ~3,800 weigh tickets/day, 7-year transaction retention for regulators, ~250 GB photos/year
```

## 65. FlashFlock — IoT firmware OTA service

```text
APP_DESCRIPTION: An API service for device manufacturers that delivers over-the-air firmware updates. It manages signed firmware releases with staged rollout rings, devices check in and download delta updates with resume support, failed-boot telemetry auto-pauses rollouts, and fleet dashboards show version distribution.
TECH_STACK: Go (gRPC + HTTPS download endpoints) + PostgreSQL + S3/CDN firmware artifacts + Ed25519 signing + delta diff engine, on AWS
APP_TYPE: API service
LANGUAGE: Go
SCALE: 2.4 million devices, ~1,500 check-ins/sec, rollout rings from 1% to 100%, firmware images up to 512 MB
```

## 66. CaptionCraft — subtitle generation pipeline

```text
APP_DESCRIPTION: A data pipeline for a streaming media company that produces subtitles and captions. It extracts audio from masters, runs speech-to-text with speaker diarization, aligns and segments captions to broadcast timing rules, routes low-confidence segments to human review, and exports WebVTT/TTML per platform spec.
TECH_STACK: Go orchestration + GPU transcription workers + SQS + PostgreSQL job state + S3 media, deployed on AWS
APP_TYPE: data pipeline
LANGUAGE: Go
SCALE: ~700 hours of content/day, 14 output languages, 92% segments auto-approved, delivery SLA 6 hours
```

## 67. TitleTrack — real estate escrow API

```text
APP_DESCRIPTION: An API service for title and escrow companies that tracks closing milestones. It manages title search, lien clearance, document signing, and funding tasks per transaction, coordinates deadlines between lenders, agents, and county recorders, and releases escrow disbursement instructions once conditions clear.
TECH_STACK: Go (echo) + PostgreSQL + e-signature and county recorder integrations + wire-instruction verification callbacks, deployed on AWS
APP_TYPE: API service
LANGUAGE: Go
SCALE: 90 escrow offices, ~5,600 open transactions, 45-day average lifecycle, 10-year record retention
```

## 68. queuescope — message queue lag CLI

```text
APP_DESCRIPTION: A CLI tool for backend engineers that inspects message-queue health from the terminal. It renders live consumer-group lag, throughput, and rebalance history for Kafka, NATS, and RabbitMQ in a TUI, diffs lag trends before and after deploys, and snapshots metrics to JSON for incident timelines.
TECH_STACK: Go CLI (cobra + bubbletea TUI) + Kafka/NATS/AMQP admin clients + local snapshot files, single binary
APP_TYPE: CLI
LANGUAGE: Go
SCALE: single user per invocation, clusters up to 5,000 partitions, 1-second refresh across 200 consumer groups
```

## 69. GlassGrove — greenhouse climate pipeline

```text
APP_DESCRIPTION: A data pipeline for commercial greenhouse operators that manages climate telemetry. It ingests temperature, humidity, CO2, and irrigation-flow sensors per bay, drives setpoint recommendations against crop-stage recipes, alerts growers to vent or boiler faults, and correlates climate history with yield per cultivar.
TECH_STACK: Go + Modbus/MQTT ingestion at edge gateways + NATS + TimescaleDB + recipe rule engine, hybrid edge/cloud on GCP
APP_TYPE: data pipeline
LANGUAGE: Go
SCALE: 38 sites, ~52,000 sensors at 30-second intervals (~1,700 readings/sec), 5-year retention
```

## 70. InvoiceIron — e-invoicing exchange API

```text
APP_DESCRIPTION: An API service that connects mid-size ERPs to government e-invoicing networks. It converts ERP invoice exports to Peppol BIS and national formats, validates against schematron rules before submission, tracks acceptance/rejection lifecycle per invoice, and archives signed documents for tax audits.
TECH_STACK: Go (chi) + PostgreSQL + Peppol access point integration + XML validation pipeline + WORM archive storage, deployed on Azure
APP_TYPE: API service
LANGUAGE: Go
SCALE: 1,900 companies, ~380,000 invoices/month with quarter-end spikes of 60/sec, 11-year archive
```

## 71. WhistleWell — whistleblower intake web app

```text
APP_DESCRIPTION: A self-hosted anonymous-reporting web app that public agencies and enterprises run for whistleblower compliance. Reporters submit cases through an anonymizing inbox with attachment scrubbing, two-way anonymous messaging lets case handlers ask follow-ups, and statutory deadline tracking covers acknowledgment and feedback duties.
TECH_STACK: Go (templ) + PostgreSQL with per-case encryption + metadata-stripping attachment pipeline + onion-service support, single binary on-premises
APP_TYPE: web app
LANGUAGE: Go
SCALE: organizations up to 40,000 employees, ~120 cases/year each, 5-year case retention, zero reporter-identifying logs
```

## 72. LeagueLadder — amateur sports league web app

```text
APP_DESCRIPTION: A league-management web app for amateur soccer and netball associations. Committees generate season fixtures with venue and referee constraints, team managers submit results and lineups, standings and suspension points update automatically, and players see fixtures and pitch locations on shareable team pages.
TECH_STACK: Go (templ + HTMX) + PostgreSQL + fixture-generation solver + iCal feeds, deployed on a managed VPS
APP_TYPE: web app
LANGUAGE: Go
SCALE: 85 leagues, 2,300 teams, ~1,900 matches/weekend, 28,000 registered players, ~6 GB data
```

## 73. SpanSnap — fiber network alarm pipeline

```text
APP_DESCRIPTION: A data pipeline for a fiber broadband operator that correlates network alarms. It ingests SNMP traps and syslog from OLTs, switches, and amplifiers, groups alarm storms to root-cause events using topology (a cut trunk suppresses downstream noise), estimates affected subscriber counts, and opens enriched NOC tickets.
TECH_STACK: Go + SNMP/syslog collectors + Kafka + Neo4j-style topology graph in memory + PostgreSQL + ticketing API, on-premises
APP_TYPE: data pipeline
LANGUAGE: Go
SCALE: ~8,000 alarms/min during storms collapsed to <40 root causes, 1.3 million subscribers, 90,000 network elements
```

## 74. TankTattle — fuel tank telemetry API

```text
APP_DESCRIPTION: An API service for fuel distributors that monitors tank levels at gas stations and depots. Tank gauges report levels and temperatures, the service forecasts run-out times per tank from sales velocity, auto-generates replenishment orders routed to dispatch, and flags sudden level drops that suggest leaks or theft.
TECH_STACK: Go (Gin) + PostgreSQL + TimescaleDB levels + gauge protocol adapters (Veeder-Root et al.) + dispatch webhooks, on AWS
APP_TYPE: API service
LANGUAGE: Go
SCALE: 5,200 sites, 21,000 tanks polling every 5 minutes (~70 readings/sec), run-out forecasts refreshed hourly
```

## 75. ArchiveAnvil — records digitization pipeline

```text
APP_DESCRIPTION: A data pipeline for a national archive digitizing paper records. It ingests scanner output batches, runs OCR with language detection on historical typefaces, validates image quality against preservation standards, extracts metadata to catalog schemas, and writes preservation masters plus access derivatives.
TECH_STACK: Go orchestration + OCR workers (Tesseract) + checksummed object storage + PostgreSQL catalog + METS/ALTO output, on-premises cluster
APP_TYPE: data pipeline
LANGUAGE: Go
SCALE: ~450,000 pages/week, 300 DPI TIFF masters (~9 TB/month), 60 scanning stations, fixity checks on 100% of files
```

## 76. AirCue — radio ad scheduling API

```text
APP_DESCRIPTION: An API service for a radio broadcast group that schedules ad spots. Sales orders book campaigns with daypart and separation rules (no competing advertisers back-to-back), the scheduler fills breaks across stations, playout systems pull daily logs, and as-run reconciliation drives make-good spots and invoicing.
TECH_STACK: Go (echo) + PostgreSQL + constraint-based break scheduler + playout system integrations + billing export, deployed on GCP
APP_TYPE: API service
LANGUAGE: Go
SCALE: 46 stations, ~9,500 spots/day scheduled, log generation for all stations under 10 minutes, 7-year as-run retention
```

## 77. layerlint — container image linter CLI

```text
APP_DESCRIPTION: A CLI tool for developers that lints Dockerfiles and built OCI images for size and hygiene issues. It flags unpinned base images, secrets baked into layers, missing multi-stage builds, cache-busting instruction order, and oversized layers, then suggests concrete rewrites and fails CI on configurable rules.
TECH_STACK: Go CLI (cobra) + Dockerfile AST parser + OCI layer inspection + autofix suggestion engine, distributed via Homebrew/GitHub releases
APP_TYPE: CLI
LANGUAGE: Go
SCALE: single user per invocation, ~1,800 CI runs/day across an org, images up to 12 GB analyzed in <20 s
```

## 78. PlasmaPath — blood bank inventory API

```text
APP_DESCRIPTION: An API service for a regional blood service that manages blood product inventory. Donation centers register units through testing and component separation, hospitals order by blood group and product with expiry-aware allocation, cold-chain sensors flag temperature excursions, and traceability links every unit from donor arm to transfusion.
TECH_STACK: Go (chi) + PostgreSQL + ISBT 128 barcode handling + cold-chain MQTT monitors + hospital HL7 interfaces, on-premises for compliance
APP_TYPE: API service
LANGUAGE: Go
SCALE: 9 processing centers, 180 hospitals, ~4,100 units processed/day, 30-year traceability retention
```

## 79. OreOracle — mining telemetry pipeline

```text
APP_DESCRIPTION: A data pipeline for an open-pit mining operator that processes equipment telemetry. It ingests haul truck payload, engine, and GPS data plus drill and crusher sensors, computes cycle times and payload utilization per shift, predicts component failures from vibration trends, and feeds maintenance planning queues.
TECH_STACK: Go + edge collectors over satellite/LTE + Kafka + TimescaleDB + parquet lake export, hybrid on-site/AWS
APP_TYPE: data pipeline
LANGUAGE: Go
SCALE: 3 sites, 260 heavy machines, ~11,000 sensor readings/sec, ~600 GB/day, shift reports within 10 minutes of shift end
```

## 80. HomeHerald — listing syndication pipeline

```text
APP_DESCRIPTION: A data pipeline for a property portal that ingests real-estate listings from agent CRMs and MLS feeds. It normalizes formats, deduplicates the same property across agencies using address and image fingerprints, detects price and status changes for alert subscribers, and syndicates clean listings to search indexes.
TECH_STACK: Go + feed pollers/webhooks + Kafka + PostgreSQL + perceptual image hashing + OpenSearch output, deployed on GCP
APP_TYPE: data pipeline
LANGUAGE: Go
SCALE: ~420 source feeds, 2.1 million active listings, ~350,000 updates/day, dedup precision target 99.7%
```

## 81. GaleGauge — wind farm SCADA pipeline

```text
APP_DESCRIPTION: A data pipeline for a wind farm operator that ingests turbine SCADA data. It collects rotor speed, pitch, gearbox temperature, and power output per turbine, detects underperformance against power curves and wake models, raises early-warning alerts for bearing degradation, and reports availability for energy settlement.
TECH_STACK: Go + OPC UA/IEC 60870 collectors + NATS JetStream + TimescaleDB + power-curve analytics jobs, hybrid edge/Azure
APP_TYPE: data pipeline
LANGUAGE: Go
SCALE: 14 farms, 620 turbines at 1-second resolution (~75,000 points/sec), 10-year retention, ~800 GB/month
```

## 82. PawPilot — veterinary lab results API

```text
APP_DESCRIPTION: An API service that connects veterinary clinics with diagnostic laboratories. Clinics submit test orders with patient species and history, labs push structured results with reference ranges adjusted per species and breed, abnormal flags trigger vet notifications, and practice-management systems sync results automatically.
TECH_STACK: Go (Gin) + PostgreSQL + lab instrument/LIS integrations + PMS webhook/polling APIs + PDF report rendering, deployed on AWS
APP_TYPE: API service
LANGUAGE: Go
SCALE: 3,800 clinics, 22 labs, ~48,000 test results/day, results delivered within 60 s of lab sign-off
```

## 83. permsweep — cloud IAM audit CLI

```text
APP_DESCRIPTION: A CLI tool for cloud security engineers that audits IAM posture across AWS, GCP, and Azure. It inventories roles, policies, and service accounts, flags wildcard grants, unused permissions from access-log analysis, and privilege-escalation paths, and outputs prioritized findings with least-privilege policy rewrites.
TECH_STACK: Go CLI (cobra) + cloud IAM/access-analyzer APIs + local policy graph analysis + JSON/SARIF/HTML reports, single binary
APP_TYPE: CLI
LANGUAGE: Go
SCALE: single user per invocation, orgs up to 900 accounts/projects, ~120,000 principals analyzed in one run
```

## 84. BidBrook — live auction bidding API

```text
APP_DESCRIPTION: An API service for an auction house that runs live and timed online bidding. Bidders place bids over WebSockets with server-side increment validation, auctioneers control lots from a rostrum console synced with floor bids, anti-sniping extensions stretch timed lots, and settlement generates buyer invoices with premiums.
TECH_STACK: Go (WebSocket hub + REST) + PostgreSQL + Redis for hot lot state + Stripe/deferred invoicing + CDN-fed catalog, deployed on AWS
APP_TYPE: API service
LANGUAGE: Go
SCALE: 15,000 concurrent bidders on flagship sales, ~900 bids/min on hot lots, bid acknowledgment under 80 ms
```

## 85. PodPresser — podcast processing pipeline

```text
APP_DESCRIPTION: A data pipeline for a podcast hosting platform that processes uploaded episodes. It normalizes loudness to platform targets, strips silences and encodes distribution formats, injects dynamic ad markers by timestamp rules, generates transcripts and chapter suggestions, and publishes RSS with byte-range-accurate enclosures.
TECH_STACK: Go workers + FFmpeg audio stages + transcription service + S3 + PostgreSQL + CDN-cached RSS rendering, deployed on GCP
APP_TYPE: data pipeline
LANGUAGE: Go
SCALE: ~6,500 episodes/day processed, 90,000 shows, ~140 million enclosure downloads/month, episode ready in <15 min
```

## 86. MenuMint — school meal payments API

```text
APP_DESCRIPTION: An API service for school districts that handles cafeteria meal accounts. Parents fund student balances and set dietary restrictions, point-of-sale lines charge accounts with allergen blocking at checkout, free/reduced-lunch eligibility applies discreetly with identical flows, and districts get participation claims reports for reimbursement.
TECH_STACK: Go (fiber) + PostgreSQL + POS terminal API + Stripe funding + state reimbursement report exports, deployed on AWS GovCloud
APP_TYPE: API service
LANGUAGE: Go
SCALE: 38 districts, 410 schools, 290,000 students, ~1,400 transactions/sec across lunch periods, <200 ms checkout
```

## 87. PhishFold — phishing triage service

```text
APP_DESCRIPTION: A defensive security API service that triages employee-reported phishing emails. Reported messages arrive via a mail-plugin button, the service detonates URLs in sandboxed fetchers, scores sender infrastructure and lookalike domains, auto-resolves benign bulk mail, and escalates confirmed campaigns with mailbox-wide purge suggestions for responders.
TECH_STACK: Go (chi) + IMAP/Graph API intake + sandboxed URL analysis workers + PostgreSQL + SOAR webhook integrations, self-hosted
APP_TYPE: API service
LANGUAGE: Go
SCALE: organizations up to 150,000 mailboxes, ~7,000 reports/day, 80% auto-resolved, analyst verdicts within 10 minutes
```

## 88. modwharf — private Go module proxy

```text
APP_DESCRIPTION: A self-hosted API service that acts as a private Go module proxy and registry for enterprises. It caches upstream modules for airgap resilience, hosts private modules with per-team access controls, enforces org-wide blocklists for vulnerable versions, and serves checksum database verification for supply-chain integrity.
TECH_STACK: Go (net/http, GOPROXY protocol) + S3-compatible module storage + PostgreSQL metadata + OIDC/SSO auth, single binary on Kubernetes
APP_TYPE: API service
LANGUAGE: Go
SCALE: 2,600 developers + CI, ~140 module downloads/sec at CI peak, 85,000 cached module versions, ~1.5 TB storage
```

## 89. BoilerBill — district heating billing pipeline

```text
APP_DESCRIPTION: A data pipeline for a district heating utility that turns heat-meter readings into invoices. It collects hourly energy and flow readings from building substations, validates against physical plausibility bands, allocates costs across apartment sub-meters, applies seasonal tariffs, and generates monthly invoices with consumption comparisons.
TECH_STACK: Go + M-Bus/wireless meter collectors + Kafka + PostgreSQL + tariff engine + invoice PDF/e-invoice output, on-premises
APP_TYPE: data pipeline
LANGUAGE: Go
SCALE: 96,000 metering points hourly (~27 readings/sec), 3,400 buildings, monthly billing run completes in <4 hours
```

## 90. TopicTap — desktop MQTT workbench

```text
APP_DESCRIPTION: A desktop app for IoT engineers that inspects and debugs MQTT brokers. It subscribes to topic trees with live payload decoding (JSON, CBOR, Protobuf via schema import), replays recorded message sessions against test brokers, simulates fleets of publishing devices, and diffs retained state between environments.
TECH_STACK: Go + Fyne UI + paho MQTT client + local BoltDB session recordings + schema registry import, distributed as signed desktop builds
APP_TYPE: desktop
LANGUAGE: Go
SCALE: single user, brokers up to 50,000 topics, live rendering at 5,000 msg/sec, recordings up to 10 GB
```

## 91. QueryQuill — desktop database client

```text
APP_DESCRIPTION: A desktop database client for developers and analysts working with PostgreSQL, MySQL, and SQLite. It offers a tabbed SQL editor with schema-aware autocomplete, visual explain-plan rendering, safe-mode transactions that require explicit commit for writes, and connection profiles with SSH tunnels stored in the OS keychain.
TECH_STACK: Go + Wails (embedded web UI) + native DB drivers + OS keychain integration + local query history in SQLite, cross-platform builds
APP_TYPE: desktop
LANGUAGE: Go
SCALE: single user, result grids up to 5 million rows streamed, 40 saved connections, query history of 100k entries
```

## 92. planpatrol — Terraform policy CLI

```text
APP_DESCRIPTION: A CLI tool for platform teams that enforces policy on Terraform plans before apply. It parses plan JSON, evaluates rules for tagging standards, disallowed instance types, public-exposure changes, and cost deltas against team budgets, and posts annotated verdicts to pull requests with override workflows for exceptions.
TECH_STACK: Go CLI (cobra) + Terraform plan JSON parser + CEL-based rule engine + GitHub/GitLab PR annotations, distributed via GitHub releases
APP_TYPE: CLI
LANGUAGE: Go
SCALE: single user per invocation, ~600 CI evaluations/day, plans up to 15,000 resources evaluated in <10 s
```

## 93. CellarSage — restaurant wine cellar web app

```text
APP_DESCRIPTION: A cellar-management web app for restaurants and wine bars. Sommeliers track bins, vintages, and drinking windows, POS sales decrement stock automatically, purchase suggestions surface gaps against the wine list, and printable list exports stay in sync with what is actually in the cellar.
TECH_STACK: Go (templ + HTMX) + SQLite + POS webhook integrations + label-scan intake (barcode) + PDF list rendering, single binary per venue
APP_TYPE: web app
LANGUAGE: Go
SCALE: venues with up to 4,500 bottles across 900 SKUs, 8 staff users, ~200 stock movements/day
```

## 94. StayStitch — hotel channel manager API

```text
APP_DESCRIPTION: An API service for boutique hotel groups that synchronizes rooms across booking channels. It pushes rates and availability to OTAs and the hotel's own booking engine, ingests reservations with conflict resolution to prevent double-bookings, and applies yield rules that adjust prices by occupancy and lead time.
TECH_STACK: Go (chi) + PostgreSQL + OTA connectivity (channel XML/JSON APIs) + Redis availability cache + rate rule engine, deployed on AWS
APP_TYPE: API service
LANGUAGE: Go
SCALE: 340 hotels, 12,000 rooms, ~90 channel updates/sec at rate refresh, reservation sync under 30 s end-to-end
```

## 95. loadlark — HTTP load testing CLI

```text
APP_DESCRIPTION: A CLI tool for performance engineers that load-tests HTTP and gRPC services. It runs scripted scenarios with ramping virtual users, data-driven request bodies, and response assertions, streams live latency histograms to the terminal, and exports percentile reports and pass/fail SLO verdicts for CI performance gates.
TECH_STACK: Go CLI (cobra) + tuned net/http and gRPC clients + HDR histogram aggregation + scenario files (YAML/JS-lite) + JSON/HTML reports
APP_TYPE: CLI
LANGUAGE: Go
SCALE: single machine drives ~80,000 req/sec, distributed mode to 20 worker nodes, scenarios up to 1 million virtual users
```

## 96. HiveHum — apiary sensor pipeline

```text
APP_DESCRIPTION: A data pipeline for commercial beekeepers that monitors hive health remotely. Hive scales, temperature, humidity, and acoustic sensors report over LoRa, the pipeline detects swarm-prep acoustics and abnormal weight drops (robbing, absconding), forecasts nectar-flow timing from weight trends, and prioritizes yard visit routes.
TECH_STACK: Go + LoRaWAN uplink ingestion + NATS + TimescaleDB + acoustic feature analysis workers + mobile alert pushes, deployed on GCP
APP_TYPE: data pipeline
LANGUAGE: Go
SCALE: 18,000 monitored hives across 700 yards, readings every 10 minutes (~30/sec), 5 seasons of retention
```

## 97. CurbCourier — last-mile routing API

```text
APP_DESCRIPTION: An API service for urban courier fleets that plans and re-plans last-mile delivery routes. Dispatch imports daily manifests, the optimizer sequences stops under time windows, vehicle capacity, and rider shift limits, live traffic and failed-delivery events trigger mid-route re-optimization, and recipients get dynamic ETA links.
TECH_STACK: Go (gRPC + REST) + PostgreSQL/PostGIS + OSRM routing engine + Redis + NATS for driver app events, deployed on AWS
APP_TYPE: API service
LANGUAGE: Go
SCALE: 45 depots, ~85,000 parcels/day, 1,200 riders, full depot re-optimization (600 stops) in <20 s
```

## 98. SeatSmith — event ticketing inventory API

```text
APP_DESCRIPTION: An API service for a ticketing platform that manages reserved seating inventory. It holds seats atomically during multi-user checkout with expiring locks, enforces per-order limits and presale codes, handles high-demand on-sales with a fair virtual queue, and syncs seat maps and holds with venue box offices.
TECH_STACK: Go (chi) + PostgreSQL + Redis seat locks and queue tokens + WebSocket seat-map updates + payment provider integration, on AWS
APP_TYPE: API service
LANGUAGE: Go
SCALE: on-sale peaks of 25,000 req/sec through queue, arenas up to 70,000 seats, zero double-sell tolerance
```

## 99. GrantGlade — grant application portal

```text
APP_DESCRIPTION: A web app for a state grants office that manages funding programs end to end. Applicants complete staged forms with document uploads, review panels score submissions against weighted rubrics with conflict-of-interest recusal, award letters and payment schedules are generated, and grantees file milestone reports against budgets.
TECH_STACK: Go (templ + HTMX) + PostgreSQL + S3 document storage + rubric scoring workflows + payment system export, government cloud
APP_TYPE: web app
LANGUAGE: Go
SCALE: 24 grant programs/year, ~9,000 applications per cycle with deadline-day peaks of 600 concurrent users, 7-year retention
```

## 100. DoseDial — clinical trial randomization API

```text
APP_DESCRIPTION: An API service for a contract research organization that handles clinical trial randomization and drug supply. Sites enroll subjects and receive treatment-arm assignments from stratified randomization lists with blinding preserved, kit inventory at sites triggers resupply shipments, and emergency unblinding follows dual-authorization with full audit capture.
TECH_STACK: Go (echo) + PostgreSQL + validated randomization module + depot/shipment integrations + 21 CFR Part 11 audit trails, on-premises validated environment
APP_TYPE: API service
LANGUAGE: Go
SCALE: 60 active trials, 1,400 sites, ~900 randomizations/day, 25-year regulatory record retention
```
