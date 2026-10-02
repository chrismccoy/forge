# Blueprint App Types — Copy-Paste Input Sets

100 ready-made input sets for `PROMPT.md`. 

Each block fills all five INPUTS, copy the fenced block into the prompt as-is, or swap individual fields.

---

# TypeScript

## 1. FreelanceLedger — invoicing and time tracking

```text
APP_DESCRIPTION: An invoicing and time-tracking web app for solo freelancers. Freelancers log billable hours against client projects, generate branded invoices from tracked time, and chase overdue payments with automated reminder emails.
TECH_STACK: Next.js (App Router) + Prisma + PostgreSQL + Tailwind CSS, deployed on Vercel
APP_TYPE: web app
LANGUAGE: TypeScript
SCALE: 300 concurrent users, ~50 req/sec, ~10 GB data
```

## 2. PlotShare — community garden manager

```text
APP_DESCRIPTION: A community garden management web app for city garden associations. Members reserve plots, log plantings and harvests, coordinate shared tool checkout, and organizers manage waitlists and seasonal fees.
TECH_STACK: Remix + Drizzle ORM + PostgreSQL + Tailwind CSS, deployed on Fly.io
APP_TYPE: web app
LANGUAGE: TypeScript
SCALE: 80 concurrent users, ~15 req/sec, ~2 GB data
```

## 3. VowVenue — wedding vendor marketplace

```text
APP_DESCRIPTION: A wedding-planning marketplace connecting engaged couples with local vendors. Couples build checklists and budgets, browse photographer/caterer/venue profiles, request quotes, and track bookings; vendors manage availability calendars and portfolios.
TECH_STACK: Next.js + tRPC + Prisma + PostgreSQL + Stripe Connect, deployed on Vercel
APP_TYPE: web app
LANGUAGE: TypeScript
SCALE: 500 concurrent users, ~80 req/sec, ~25 GB data
```

## 4. PhysioSlot — telehealth appointment booking

```text
APP_DESCRIPTION: A telehealth booking web app for physiotherapy clinics. Patients book video or in-person sessions, complete intake forms, and view exercise plans; therapists manage schedules, session notes, and follow-up reminders.
TECH_STACK: Next.js + Prisma + PostgreSQL + Daily.co video API, deployed on Vercel
APP_TYPE: web app
LANGUAGE: TypeScript
SCALE: 200 concurrent users, ~35 req/sec, ~8 GB data
```

## 5. OpenHouseAPI — real-estate showing scheduler

```text
APP_DESCRIPTION: An API service that lets real-estate brokerages schedule and manage open-house showings. Agents publish showing slots, buyers' agents book visits, and the service handles conflict detection, lockbox codes, and post-showing feedback collection.
TECH_STACK: NestJS + TypeORM + PostgreSQL + Redis, deployed on AWS ECS
APP_TYPE: API service
LANGUAGE: TypeScript
SCALE: ~120 req/sec, 400 concurrent agent sessions, ~15 GB data
```

## 6. BracketForge — e-sports tournament manager

```text
APP_DESCRIPTION: A tournament management web app for amateur e-sports organizers. Organizers create single/double-elimination brackets, players register and check in, match results update brackets live, and spectators follow standings in real time.
TECH_STACK: Next.js + Prisma + PostgreSQL + WebSockets (Pusher), deployed on Vercel
APP_TYPE: web app
LANGUAGE: TypeScript
SCALE: 1,000 concurrent users during finals, ~150 req/sec peak, ~5 GB data
```

## 7. StreakDaily — habit tracker

```text
APP_DESCRIPTION: A habit-tracking mobile app for people building daily routines. Users define habits with flexible schedules, log completions with streak tracking, get smart reminder notifications, and review monthly consistency heatmaps.
TECH_STACK: React Native (Expo) + Supabase (PostgreSQL + auth) + push notifications
APP_TYPE: mobile
LANGUAGE: TypeScript
SCALE: 5,000 MAU, 300 concurrent sessions, ~3 GB data
```

## 8. EpisodeDesk — podcast planning desktop app

```text
APP_DESCRIPTION: A desktop app for independent podcasters to plan and produce episodes. Podcasters outline episodes with segment timers, manage guest bookings and release calendars, track sponsor read obligations, and export show notes.
TECH_STACK: Electron + React + SQLite (better-sqlite3) + local filesystem storage
APP_TYPE: desktop
LANGUAGE: TypeScript
SCALE: single user, local data <2 GB
```

## 9. CurioCat — museum collection catalog

```text
APP_DESCRIPTION: A collection cataloging web app for small museums and historical societies. Curators register artifacts with provenance, condition reports, and photos; volunteers digitize records; researchers search the public catalog.
TECH_STACK: Next.js + Prisma + PostgreSQL + S3-compatible image storage, deployed on Render
APP_TYPE: web app
LANGUAGE: TypeScript
SCALE: 60 concurrent users, ~10 req/sec, ~50 GB data (images)
```

## 10. tokensync — design token CLI

```text
APP_DESCRIPTION: A CLI tool for design-system teams that syncs design tokens from Figma to code. It pulls token definitions via the Figma API, transforms them into platform outputs (CSS variables, Tailwind config, iOS/Android constants), and diffs changes against the committed token files.
TECH_STACK: Node.js CLI (commander) + Figma REST API + file-system codegen, distributed via npm
APP_TYPE: CLI
LANGUAGE: TypeScript
SCALE: single user per invocation, CI usage ~200 runs/day, <100 MB local data
```

## 11. TruckStop — food truck preorder

```text
APP_DESCRIPTION: A food-truck location and preorder web app. Truck owners publish daily locations and menus, customers find nearby trucks on a map and preorder for pickup windows, and owners manage order queues from a kitchen view.
TECH_STACK: Next.js + Prisma + PostgreSQL + Mapbox + Stripe, deployed on Vercel
APP_TYPE: web app
LANGUAGE: TypeScript
SCALE: 800 concurrent users at lunch peak, ~100 req/sec, ~6 GB data
```

## 12. DonorTrail — nonprofit donor CRM

```text
APP_DESCRIPTION: A donor-relationship CRM web app for small nonprofits. Development staff track donors, pledges, and gift histories, segment mailing lists, log stewardship touchpoints, and generate year-end tax receipt batches.
TECH_STACK: Next.js + Prisma + PostgreSQL + Resend email, deployed on Vercel
APP_TYPE: web app
LANGUAGE: TypeScript
SCALE: 40 concurrent users, ~8 req/sec, ~12 GB data
```

## 13. Lexicards — language flashcards

```text
APP_DESCRIPTION: A spaced-repetition flashcard mobile app for language learners. Learners build or import decks, review cards on an SM-2 schedule, hear native-speaker audio, and track retention statistics per language.
TECH_STACK: React Native (Expo) + SQLite (expo-sqlite) offline-first + optional cloud sync via Supabase
APP_TYPE: mobile
LANGUAGE: TypeScript
SCALE: 10,000 MAU, 500 concurrent sessions, ~4 GB cloud data
```

---

# JavaScript (Node.js)

## 14. HookMirror — webhook relay and inspector

```text
APP_DESCRIPTION: An API service that receives, inspects, and relays webhooks for development teams. Developers create endpoints that capture incoming webhook payloads, replay them against local tunnels or staging targets, and set transform/filter rules per destination.
TECH_STACK: Express + PostgreSQL + Redis (queue) + BullMQ, deployed on Railway
APP_TYPE: API service
LANGUAGE: JavaScript (Node.js)
SCALE: ~250 req/sec, 150 active teams, ~20 GB payload data
```

## 15. ParishCast — community livestream portal

```text
APP_DESCRIPTION: A livestream and event portal web app for churches and community centers. Staff schedule services and events, embed livestreams with live chat, collect prayer requests or announcements, and archive past streams by series.
TECH_STACK: Express + EJS templates + PostgreSQL + Mux video, deployed on Render
APP_TYPE: web app
LANGUAGE: JavaScript (Node.js)
SCALE: 600 concurrent viewers Sunday peak, ~40 req/sec, ~30 GB video metadata/archive index
```

## 16. BotBench — chatbot hosting dashboard

```text
APP_DESCRIPTION: A dashboard web app for hobbyists who run community chat bots. Users register bots, edit command configs and auto-moderation rules through forms, view invocation logs and error rates, and restart bot processes.
TECH_STACK: Express + React (Vite) + PostgreSQL + Docker API for bot processes, self-hosted
APP_TYPE: web app
LANGUAGE: JavaScript (Node.js)
SCALE: 100 concurrent users, ~20 req/sec, ~5 GB data
```

## 17. GreenFlow — greenhouse telemetry pipeline

```text
APP_DESCRIPTION: A data pipeline that ingests telemetry from smart-greenhouse sensors (temperature, humidity, soil moisture, CO2) for commercial growers. It validates and downsamples readings, detects threshold breaches for alerting, and loads hourly aggregates into a reporting database.
TECH_STACK: Node.js (streams) + MQTT ingestion + TimescaleDB + Grafana, deployed on a single VPS
APP_TYPE: data pipeline
LANGUAGE: JavaScript (Node.js)
SCALE: 2,000 sensor readings/sec, ~8 GB/day raw, 90-day retention
```

## 18. upcheck — uptime monitor CLI

```text
APP_DESCRIPTION: A CLI tool for freelancers who maintain client websites. It checks a config file of URLs for status, latency, SSL expiry, and content assertions, prints a color-coded report, and exits non-zero for CI or cron-based alerting.
TECH_STACK: Node.js CLI (yargs) + native fetch + JSON/YAML config, distributed via npm
APP_TYPE: CLI
LANGUAGE: JavaScript (Node.js)
SCALE: single user per invocation, up to 500 URLs per run, <50 MB local data
```

## 19. ShelfMate — library reservation system

```text
APP_DESCRIPTION: A book reservation web app for small-town public libraries. Patrons search the catalog, place holds, and get pickup notifications; librarians manage check-in/check-out, waitlists, and overdue notices.
TECH_STACK: Express + Pug templates + PostgreSQL + nodemailer, deployed on a municipal VPS
APP_TYPE: web app
LANGUAGE: JavaScript (Node.js)
SCALE: 120 concurrent users, ~15 req/sec, ~4 GB data
```

## 20. WeekPlate — recipe box and meal planner

```text
APP_DESCRIPTION: A meal-planning web app for busy households. Users save and tag recipes, drag them onto a weekly calendar, auto-generate consolidated grocery lists by store aisle, and scale portions per household size.
TECH_STACK: Fastify + React (Vite) + PostgreSQL + Redis session store, deployed on Fly.io
APP_TYPE: web app
LANGUAGE: JavaScript (Node.js)
SCALE: 400 concurrent users, ~45 req/sec, ~7 GB data
```

## 21. PressProof — print shop order intake

```text
APP_DESCRIPTION: An order-intake API service for commercial print shops. Customers' storefronts submit print jobs with artwork files and specs (stock, finish, quantity), the service validates artwork dimensions and bleed, quotes pricing from rule tables, and tracks jobs through proof-approval to production.
TECH_STACK: Express + PostgreSQL + S3-compatible file storage + Sharp for artwork validation, deployed on AWS
APP_TYPE: API service
LANGUAGE: JavaScript (Node.js)
SCALE: ~60 req/sec, 200 storefront integrations, ~200 GB artwork files
```

---

# Python

## 22. VetDesk — veterinary practice management

```text
APP_DESCRIPTION: A practice-management web app for small veterinary clinics. Front desk schedules appointments and vaccine reminders, vets record SOAP notes and prescriptions per patient animal, and owners receive visit summaries and invoices.
TECH_STACK: Django + PostgreSQL + HTMX + Celery/Redis for reminders, deployed on AWS Lightsail
APP_TYPE: web app
LANGUAGE: Python
SCALE: 90 concurrent users, ~20 req/sec, ~15 GB data
```

## 23. AirTrace — air-quality sensor ETL

```text
APP_DESCRIPTION: A data pipeline for a regional environmental agency that ingests air-quality readings (PM2.5, NO2, O3) from 800 public sensors. It cleans and calibrates raw readings against reference stations, flags sensor drift, and publishes hourly city-level aggregates to an open-data portal.
TECH_STACK: Python + Apache Airflow + pandas + PostgreSQL/PostGIS + S3, deployed on AWS
APP_TYPE: data pipeline
LANGUAGE: Python
SCALE: 800 sensors reporting every 60s (~13 readings/sec), ~2 GB/day, 5-year retention
```

## 24. DiscoveryDock — legal document search API

```text
APP_DESCRIPTION: An e-discovery search API service for litigation support teams. Paralegals upload document productions, the service extracts text and metadata, deduplicates near-identical documents, and exposes faceted full-text search with privilege-tag filtering.
TECH_STACK: FastAPI + PostgreSQL + OpenSearch + Celery workers + S3, deployed on AWS ECS
APP_TYPE: API service
LANGUAGE: Python
SCALE: ~40 req/sec, 50 concurrent reviewers, ~500 GB document corpus
```

## 25. BellSchedule — school timetable builder

```text
APP_DESCRIPTION: A timetable-construction web app for secondary school administrators. Schedulers define rooms, teacher availability, and course sections; a constraint solver proposes conflict-free timetables; staff publish final schedules to teachers and students.
TECH_STACK: Django + PostgreSQL + OR-Tools constraint solver + HTMX, deployed on Hetzner
APP_TYPE: web app
LANGUAGE: Python
SCALE: 150 concurrent users at term start, ~25 req/sec, ~3 GB data
```

## 26. ShelfSense — retail demand forecasting pipeline

```text
APP_DESCRIPTION: A demand-forecasting data pipeline for a 40-store grocery chain. It ingests nightly point-of-sale exports, joins promotions and weather data, retrains per-category forecasting models weekly, and delivers store-level order recommendations to the purchasing team each morning.
TECH_STACK: Python + Prefect + pandas/scikit-learn + Snowflake + dbt, deployed on AWS
APP_TYPE: data pipeline
LANGUAGE: Python
SCALE: 40 stores × ~25k SKUs nightly (~12 GB/day), forecasts due by 06:00 daily
```

## 27. PennyWise — personal budgeting app

```text
APP_DESCRIPTION: A personal-finance budgeting web app for young professionals. Users import bank CSV exports, auto-categorize transactions with editable rules, set monthly envelope budgets, and see overspend alerts and savings-goal progress.
TECH_STACK: Flask + SQLAlchemy + PostgreSQL + Chart.js, deployed on Fly.io
APP_TYPE: web app
LANGUAGE: Python
SCALE: 250 concurrent users, ~30 req/sec, ~10 GB data
```

## 28. SampleTrack — lab LIMS

```text
APP_DESCRIPTION: A sample-tracking web app (lightweight LIMS) for university research labs. Researchers register biological samples with storage locations (freezer/rack/box), log freeze-thaw cycles and derivations, book shared instruments, and export chain-of-custody reports.
TECH_STACK: Django + PostgreSQL + django-rest-framework + barcode label printing, self-hosted on lab server
APP_TYPE: web app
LANGUAGE: Python
SCALE: 50 concurrent users, ~10 req/sec, ~8 GB data
```

## 29. TileFactory — satellite imagery pipeline

```text
APP_DESCRIPTION: A data pipeline for an agritech company that processes satellite imagery into field-health map tiles. It ingests new Sentinel-2 scenes, computes NDVI and cloud masks per client field boundary, renders web map tiles, and notifies agronomists when field stress is detected.
TECH_STACK: Python + Celery + rasterio/GDAL + PostGIS + S3 + Docker, deployed on AWS Batch
APP_TYPE: data pipeline
LANGUAGE: Python
SCALE: ~300 scenes/day (~150 GB/day raw), 12,000 monitored fields, tiles served to 500 users
```

## 30. FeedMerge — job feed aggregation pipeline

```text
APP_DESCRIPTION: A data pipeline for a niche job board that aggregates partner-provided job feeds. It pulls licensed XML/JSON feeds from 60 staffing partners, normalizes titles and locations to a shared taxonomy, deduplicates cross-posted listings, and publishes a clean feed to the job-board database with expiry handling.
TECH_STACK: Python + Airflow + pydantic + PostgreSQL + Redis dedup cache, deployed on GCP
APP_TYPE: data pipeline
LANGUAGE: Python
SCALE: 60 feeds, ~400k listings/day processed, ~6 GB/day, hourly refresh
```

## 31. AsanaFlow — yoga studio booking

```text
APP_DESCRIPTION: A class-booking web app for independent yoga studios. Students buy class packs or memberships, book and cancel spots with waitlist promotion, and check in via QR code; instructors see rosters and studios track utilization.
TECH_STACK: Django + PostgreSQL + Stripe + HTMX + Celery reminders, deployed on Render
APP_TYPE: web app
LANGUAGE: Python
SCALE: 180 concurrent users at booking-open peak, ~25 req/sec, ~5 GB data
```

## 32. vaultkeeper — backup orchestration CLI

```text
APP_DESCRIPTION: A CLI tool for sysadmins that orchestrates database backups across heterogeneous servers. It reads a declarative config of PostgreSQL/MySQL/SQLite targets, runs scheduled dumps with compression and encryption, rotates archives by retention policy, verifies restorability with test restores, and reports to a webhook.
TECH_STACK: Python CLI (Typer) + paramiko SSH + age encryption + S3/B2 storage backends, distributed via pipx
APP_TYPE: CLI
LANGUAGE: Python
SCALE: single operator, ~200 database targets, ~50 GB nightly backup volume
```

## 33. LabelLens — nutrition label OCR API

```text
APP_DESCRIPTION: An API service for diet-app developers that extracts structured nutrition data from food-label photos. Clients POST label images; the service OCRs the nutrition panel, parses serving sizes and nutrient rows into normalized JSON, and flags low-confidence fields for human review.
TECH_STACK: FastAPI + Tesseract/PaddleOCR + PostgreSQL + Redis queue + S3, deployed on GCP Cloud Run
APP_TYPE: API service
LANGUAGE: Python
SCALE: ~90 req/sec peak, 40 API clients, ~80 GB image data
```

## 34. TrailCamAI — wildlife image pipeline

```text
APP_DESCRIPTION: A data pipeline for a conservation NGO that processes camera-trap images from 300 field cameras. It ingests SD-card and cellular uploads, runs species-classification models, filters empty frames, routes uncertain detections to volunteer reviewers, and aggregates sighting statistics per reserve.
TECH_STACK: Python + Celery + PyTorch (MegaDetector) + PostgreSQL + S3 + label-review web queue, deployed on AWS
APP_TYPE: data pipeline
LANGUAGE: Python
SCALE: ~50k images/day (~40 GB/day), 300 cameras, 150 volunteer reviewers
```

---

# Go

## 35. LinkForge — team URL shortener

```text
APP_DESCRIPTION: A URL-shortener API service for marketing teams. Teams mint branded short links with UTM presets, set expiry and geo-targeted destinations, and pull click analytics (referrer, device, region) via API for campaign dashboards.
TECH_STACK: Go (chi router) + PostgreSQL + Redis cache + ClickHouse for click events, deployed on AWS
APP_TYPE: API service
LANGUAGE: Go
SCALE: ~2,000 redirect req/sec, 500 API clients, ~100 GB click events/year
```

## 36. HaulTrace — freight tracking API

```text
APP_DESCRIPTION: A freight-tracking API service for regional trucking companies. Dispatchers create loads with stops and driver assignments, driver phones push GPS pings, and shipper customers poll or subscribe to webhook status updates (picked up, in transit, delayed, delivered).
TECH_STACK: Go (Gin) + PostgreSQL/PostGIS + NATS for ping ingestion + webhook dispatcher, deployed on GCP
APP_TYPE: API service
LANGUAGE: Go
SCALE: ~800 req/sec (GPS pings), 3,000 active loads, ~30 GB/month location data
```

## 37. LogHerd — log aggregation pipeline

```text
APP_DESCRIPTION: A data pipeline for a mid-size SaaS company that aggregates application logs from 200 services. It tails container log streams, parses and enriches entries with deploy metadata, samples high-volume debug noise, routes error spikes to alerting, and writes searchable indexes with tiered retention.
TECH_STACK: Go + Kafka + ClickHouse + Vector-compatible ingestion + Grafana, self-hosted on Kubernetes
APP_TYPE: data pipeline
LANGUAGE: Go
SCALE: ~150k log lines/sec peak, ~400 GB/day, 30-day hot / 1-year cold retention
```

## 38. FlagPost — self-hosted feature flags

```text
APP_DESCRIPTION: A self-hosted feature-flag API service for engineering teams that cannot use SaaS flag vendors for compliance reasons. Teams define flags with percentage rollouts, user-segment targeting, and kill switches; SDKs poll or stream flag states; audit logs record every change.
TECH_STACK: Go (echo) + PostgreSQL + SSE streaming + embedded admin UI, distributed as a single binary/Docker image
APP_TYPE: API service
LANGUAGE: Go
SCALE: ~5,000 flag-evaluation req/sec, 80 engineering teams, <5 GB data
```

## 39. kubelint — Kubernetes manifest linter CLI

```text
APP_DESCRIPTION: A CLI tool for platform teams that lints Kubernetes manifests before deploy. It checks raw YAML, Helm output, and Kustomize builds against built-in and custom policy rules (resource limits, probes, security contexts, deprecated APIs), and emits human, JSON, and SARIF reports for CI annotation.
TECH_STACK: Go CLI (cobra) + kubernetes API machinery for parsing + embedded rule engine, distributed via Homebrew/GitHub releases
APP_TYPE: CLI
LANGUAGE: Go
SCALE: single user per invocation, CI usage ~1,000 runs/day across teams, <10 MB local data
```

## 40. StallSense — parking occupancy API

```text
APP_DESCRIPTION: An API service for municipal parking authorities that tracks garage and lot occupancy. Entry/exit sensors and payment kiosks push events, the service maintains real-time stall counts per facility, exposes availability to city apps and roadside signs, and produces daily utilization reports.
TECH_STACK: Go (fiber) + PostgreSQL + Redis for live counts + MQTT sensor ingestion, deployed on Azure
APP_TYPE: API service
LANGUAGE: Go
SCALE: ~300 sensor events/sec, 45 facilities, 200 req/sec availability reads, ~10 GB/year
```

## 41. PicPress — image resizing edge service

```text
APP_DESCRIPTION: An on-the-fly image-resizing API service for e-commerce platforms. It fetches origin images, applies URL-signed transformations (resize, crop, format conversion, quality), caches aggressively at the edge, and enforces per-tenant usage quotas.
TECH_STACK: Go + libvips (bimg) + Redis + S3 origin + CDN in front, deployed on Fly.io regions
APP_TYPE: API service
LANGUAGE: Go
SCALE: ~1,500 req/sec (85% cache hit), 60 tenants, ~2 TB cached derivatives
```

## 42. BerthBook — marina berth booking

```text
APP_DESCRIPTION: A berth-booking web app for small marinas. Boat owners request seasonal or transient berths matched by vessel dimensions and draft, marina staff manage the berth map and utility billing (power, water), and visiting sailors book overnight moorings.
TECH_STACK: Go (templ + HTMX) + PostgreSQL + Stripe, deployed on a single Hetzner VPS
APP_TYPE: web app
LANGUAGE: Go
SCALE: 70 concurrent users, ~12 req/sec, ~2 GB data
```

## 43. PayStream — payroll file pipeline

```text
APP_DESCRIPTION: A data pipeline for a payroll bureau that generates bank payment files. It ingests approved payroll runs from client HR systems, validates account and amount data, produces SEPA/ACH batch files with hash totals, transmits them over SFTP to partner banks, and reconciles bank acknowledgments.
TECH_STACK: Go + PostgreSQL + SFTP integrations + audit event log, deployed on-premises for compliance
APP_TYPE: data pipeline
LANGUAGE: Go
SCALE: 900 client companies, ~250k payment lines per cycle, twice-monthly peaks, <20 GB data
```

## 44. repopulse — git metrics CLI

```text
APP_DESCRIPTION: A CLI tool for engineering managers that computes repository health metrics from local git history. It reports review latency, change failure hotspots, bus-factor per directory, and commit cadence trends, outputting terminal dashboards or JSON for further analysis — no data leaves the machine.
TECH_STACK: Go CLI (cobra) + go-git + local SQLite cache + terminal charts, distributed via GitHub releases
APP_TYPE: CLI
LANGUAGE: Go
SCALE: single user, repos up to 1M commits, <1 GB local cache
```

---

# Rust

## 45. StockPulse — marketplace inventory sync API

```text
APP_DESCRIPTION: A high-throughput inventory-sync API service for merchants selling across multiple marketplaces. It receives stock deltas from warehouse systems, resolves per-channel allocation rules, and pushes near-real-time quantity updates to marketplace APIs to prevent overselling.
TECH_STACK: Rust (axum) + PostgreSQL + Redis + Kafka + marketplace API connectors, deployed on AWS EKS
APP_TYPE: API service
LANGUAGE: Rust
SCALE: ~4,000 stock-delta req/sec peak, 1,200 merchants, ~50 GB data
```

## 46. lockbox — local password vault CLI

```text
APP_DESCRIPTION: A local-first password vault CLI for developers. It stores credentials and TOTP seeds in an age-encrypted local file, supports fuzzy search and clipboard copy with auto-clear, generates passwords by policy, and syncs the encrypted vault via the user's own git remote — no server component.
TECH_STACK: Rust CLI (clap) + age encryption + local encrypted file store + optional git sync, distributed via cargo/Homebrew
APP_TYPE: CLI
LANGUAGE: Rust
SCALE: single user, <10 MB vault data
```

## 47. PitWire — race telemetry pipeline

```text
APP_DESCRIPTION: A data pipeline for club motorsport teams that processes live car telemetry. It ingests high-frequency CAN-bus channels (RPM, throttle, brake pressure, tire temps) over trackside radio, decodes and time-aligns channels, computes lap and sector deltas in real time, and stores sessions for post-race analysis.
TECH_STACK: Rust + tokio + UDP ingestion + Apache Parquet session storage + TimescaleDB for live views
APP_TYPE: data pipeline
LANGUAGE: Rust
SCALE: 2 cars × 400 channels at 100 Hz (~80k points/sec), ~5 GB per race weekend
```

## 48. InvoiceMiner — PDF invoice parsing API

```text
APP_DESCRIPTION: An API service for accounting platforms that extracts structured data from PDF invoices. Clients upload supplier invoices; the service parses layout and tables, extracts header fields (supplier, dates, totals, tax) and line items, validates arithmetic, and returns normalized JSON with per-field confidence.
TECH_STACK: Rust (axum) + pdfium bindings + PostgreSQL + S3 + queue workers, deployed on GCP Cloud Run
APP_TYPE: API service
LANGUAGE: Rust
SCALE: ~120 req/sec, 90 platform clients, ~300 GB stored documents
```

## 49. NotedDesk — markdown knowledge base

```text
APP_DESCRIPTION: A local-first desktop knowledge-base app for researchers and writers. Users write linked markdown notes with backlinks and graph view, full-text search across thousands of notes, tag-based smart folders, and export to publishable formats — all data stays in a local folder of plain files.
TECH_STACK: Tauri (Rust core) + React frontend + tantivy full-text index + local markdown files
APP_TYPE: desktop
LANGUAGE: Rust
SCALE: single user, 50k notes, <5 GB local data
```

## 50. PodiumBoard — game leaderboard service

```text
APP_DESCRIPTION: A leaderboard API service for indie game studios. Games submit signed score events; the service maintains global, friend, and seasonal leaderboards with anti-tamper validation and rate limiting, and exposes paginated rank queries with percentile lookups.
TECH_STACK: Rust (actix-web) + Redis sorted sets + PostgreSQL + HMAC-signed score submissions, deployed on Hetzner
APP_TYPE: API service
LANGUAGE: Rust
SCALE: ~3,000 req/sec launch-week peak, 40 games, 5M player profiles, ~25 GB data
```

## 51. HushDNS — home network DNS filter

```text
APP_DESCRIPTION: A self-hosted DNS filtering service for home-lab users. It answers LAN DNS queries with configurable blocklists (ads, trackers, malware domains), per-device policies and schedules (kids' devices), a local web dashboard of query statistics, and DoH upstream resolution.
TECH_STACK: Rust (tokio + hickory-dns) + SQLite + embedded web UI, distributed as single binary for Raspberry Pi/x86
APP_TYPE: API service
LANGUAGE: Rust
SCALE: ~200 DNS queries/sec, 30 LAN devices, <2 GB query log data
```

## 52. WaveBatch — audio transcoding pipeline

```text
APP_DESCRIPTION: A batch audio-transcoding data pipeline for an audiobook publisher. It ingests studio master WAV files, validates loudness against ACX/EBU R128 specs, transcodes to retailer-specific formats and bitrates, embeds chapter metadata, and delivers packaged outputs to distribution endpoints.
TECH_STACK: Rust + ffmpeg bindings + RabbitMQ work queue + PostgreSQL job ledger + S3, deployed on bare-metal workers
APP_TYPE: data pipeline
LANGUAGE: Rust
SCALE: ~400 titles/month (~1.2 TB/month processed), 6 retailer output profiles
```

---

# Java

## 53. TellerTime — bank branch appointments

```text
APP_DESCRIPTION: An appointment-scheduling web app for a regional bank's 60 branches. Customers book advisor slots by service type (mortgage, business, wealth), branch managers balance advisor calendars and walk-in queues, and the bank tracks no-show rates and service-time analytics.
TECH_STACK: Spring Boot + Thymeleaf + PostgreSQL + Redis + LDAP staff auth, deployed on on-prem Kubernetes
APP_TYPE: web app
LANGUAGE: Java
SCALE: 900 concurrent users, ~120 req/sec, ~40 GB data
```

## 54. ClaimGate — insurance claims intake API

```text
APP_DESCRIPTION: A claims-intake API service for a property insurer. Policyholder apps and partner portals submit claims with photos and documents, the service validates policy coverage and deductibles, assigns adjusters by region and workload, and publishes status events to downstream systems.
TECH_STACK: Spring Boot + PostgreSQL + Kafka + S3 document store + OAuth2 resource server, deployed on AWS EKS
APP_TYPE: API service
LANGUAGE: Java
SCALE: ~200 req/sec, 5,000 claims/day storm peak, ~1 TB documents
```

## 55. RackRoute — warehouse management

```text
APP_DESCRIPTION: A warehouse-management web app for a third-party logistics operator. Inbound staff receive and putaway stock against purchase orders, pickers work optimized pick paths from wave-released orders, and account managers see per-client inventory accuracy and SLA dashboards.
TECH_STACK: Spring Boot + React + PostgreSQL + RabbitMQ + Zebra barcode scanner integration, self-hosted
APP_TYPE: web app
LANGUAGE: Java
SCALE: 350 concurrent users across 3 warehouses, ~90 req/sec, ~60 GB data
```

## 56. WardWatch — hospital bed capacity dashboard

```text
APP_DESCRIPTION: A bed-capacity dashboard web app for a hospital network's operations center. Charge nurses update bed states (occupied, cleaning, blocked), transfer coordinators match incoming patients to available beds by unit and acuity, and executives view network-wide occupancy and discharge-forecast dashboards.
TECH_STACK: Spring Boot + WebSocket live updates + PostgreSQL + HL7 ADT feed integration, deployed on-prem
APP_TYPE: web app
LANGUAGE: Java
SCALE: 500 concurrent users across 4 hospitals, ~70 req/sec, ~20 GB data
```

## 57. CrewCycle — flight crew rostering API

```text
APP_DESCRIPTION: A crew-rostering API service for a regional airline. It ingests published flight schedules, generates legal crew pairings under duty-time regulations, handles crew swap and sick-call replacement requests, and exposes roster data to crew mobile apps and payroll.
TECH_STACK: Spring Boot + PostgreSQL + OptaPlanner for pairing optimization + Kafka events, deployed on Azure
APP_TYPE: API service
LANGUAGE: Java
SCALE: ~80 req/sec, 1,200 crew members, 400 flights/day, ~30 GB data
```

## 58. SettleRight — settlement reconciliation pipeline

```text
APP_DESCRIPTION: A nightly reconciliation data pipeline for a payments processor. It matches internal transaction ledgers against acquirer and bank settlement files, applies fee schedules, flags breaks by mismatch category for the operations team, and posts balanced journal batches to the general ledger.
TECH_STACK: Java + Spring Batch + PostgreSQL + SFTP file ingestion + Control-M scheduling, on-prem
APP_TYPE: data pipeline
LANGUAGE: Java
SCALE: ~8M transactions/night (~25 GB/night), 4-hour processing window, 7-year retention
```

## 59. CourseGate — university registration

```text
APP_DESCRIPTION: A course-registration web app for a mid-size university. Students search the catalog, build schedules with conflict checking, register during timed enrollment windows with prerequisite and seat-capacity enforcement, and join waitlists with automatic promotion.
TECH_STACK: Spring Boot + Vaadin + PostgreSQL + Redis for enrollment-window surge, deployed on university private cloud
APP_TYPE: web app
LANGUAGE: Java
SCALE: 8,000 concurrent users at registration open, ~600 req/sec peak, ~50 GB data
```

---

# C#

## 60. BiteRight — dental practice management

```text
APP_DESCRIPTION: A practice-management web app for multi-chair dental offices. Front desk manages appointments with recall reminders, dentists chart treatments on interactive tooth diagrams, billing staff generate insurance claims and patient statements, and the practice tracks production per provider.
TECH_STACK: ASP.NET Core + Blazor Server + Entity Framework Core + SQL Server, deployed on Azure App Service
APP_TYPE: web app
LANGUAGE: C#
SCALE: 120 concurrent users, ~25 req/sec, ~30 GB data
```

## 61. TillPoint — boutique point of sale

```text
APP_DESCRIPTION: A desktop point-of-sale app for independent clothing boutiques. Staff ring up sales with barcode scanning and size/color variants, process returns and exchanges, manage layaways and gift cards, and sync daily sales and stock levels to a cloud backend when online.
TECH_STACK: WPF (.NET 8) + SQLite local store + offline-first sync to ASP.NET Core API + receipt printer/cash drawer integration
APP_TYPE: desktop
LANGUAGE: C#
SCALE: 1-3 registers per store, 200 stores, offline-tolerant, <5 GB local data per store
```

## 62. PermitPath — municipal permit portal

```text
APP_DESCRIPTION: A permit-application web app for a city building department. Residents and contractors submit building/electrical/plumbing permit applications with document uploads, pay fees online, track review status across departments, and schedule inspections; reviewers manage queues and issue approvals.
TECH_STACK: ASP.NET Core MVC + Entity Framework Core + PostgreSQL + Azure Blob storage + GOV payment gateway
APP_TYPE: web app
LANGUAGE: C#
SCALE: 300 concurrent users, ~35 req/sec, ~100 GB documents
```

## 63. FleetFix — fleet maintenance API

```text
APP_DESCRIPTION: A fleet-maintenance API service for companies running vehicle fleets. It ingests odometer and fault-code telemetry, schedules preventive maintenance by usage thresholds, manages work orders with parts and labor tracking, and reports cost-per-mile and downtime per vehicle.
TECH_STACK: ASP.NET Core Web API + Entity Framework Core + SQL Server + Azure Service Bus + telematics webhooks
APP_TYPE: API service
LANGUAGE: C#
SCALE: ~150 req/sec, 25,000 vehicles, ~80 GB data
```

## 64. StaffSeed — AD user provisioning CLI

```text
APP_DESCRIPTION: A CLI tool for enterprise IT teams that automates Active Directory user lifecycle from HR data. It reads new-hire/change/termination records from an HR CSV or API export, creates or updates AD accounts, applies group memberships from role-mapping rules, generates onboarding reports, and runs in dry-run mode by default.
TECH_STACK: .NET 8 console app (System.CommandLine) + LDAP/Microsoft.Graph APIs + YAML role-mapping config, distributed as signed internal tool
APP_TYPE: CLI
LANGUAGE: C#
SCALE: single operator per run, 15,000 managed accounts, nightly scheduled runs
```

## 65. GavelLive — real-time auction platform

```text
APP_DESCRIPTION: A real-time auction web app for a regional auction house. Bidders join timed and live-streamed auctions, place bids with soft-close anti-sniping extensions, set maximum proxy bids, and pay invoices online; auctioneers manage lots, reserves, and live bid calling.
TECH_STACK: ASP.NET Core + SignalR + Entity Framework Core + PostgreSQL + Redis backplane + Stripe, deployed on Azure
APP_TYPE: web app
LANGUAGE: C#
SCALE: 2,500 concurrent bidders at marquee auctions, ~400 req/sec peak, ~15 GB data
```

## 66. LineSight — manufacturing OEE pipeline

```text
APP_DESCRIPTION: A data pipeline for a packaging manufacturer that computes OEE (overall equipment effectiveness) across 12 production lines. It ingests PLC cycle counts, downtime events, and reject counts via OPC UA, classifies downtime reasons, computes shift-level availability/performance/quality metrics, and feeds plant dashboards and morning-meeting reports.
TECH_STACK: .NET 8 workers + OPC UA ingestion + TimescaleDB + Grafana + MQTT, deployed on plant-floor edge servers
APP_TYPE: data pipeline
LANGUAGE: C#
SCALE: 12 lines × ~50 signals/sec (~600 events/sec), ~3 GB/day, 3-year retention
```

---

# PHP

## 67. RepZone — gym membership portal

```text
APP_DESCRIPTION: A membership portal web app for independent gyms. Members sign up for plans with recurring billing, book classes and personal-training sessions, and check in via QR; owners manage class schedules, freeze/cancel requests, and monthly revenue reports.
TECH_STACK: Laravel + Livewire + MySQL + Stripe Billing + Redis queues, deployed on Laravel Forge/DigitalOcean
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 250 concurrent users, ~30 req/sec, ~10 GB data
```

## 68. CraftBazaar — artisan marketplace

```text
APP_DESCRIPTION: A multi-vendor marketplace web app for handmade crafts. Artisans open shops with product listings and made-to-order options, buyers purchase across shops with a single cart, the platform splits payments with vendor payouts, and reviews and messaging build buyer-seller trust.
TECH_STACK: Laravel + Inertia.js (Vue) + MySQL + Stripe Connect + Meilisearch, deployed on AWS
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 1,200 concurrent users, ~150 req/sec, ~60 GB data
```

## 69. LeaseLine — landlord tenant portal

```text
APP_DESCRIPTION: A tenant-portal web app for small residential landlords. Tenants pay rent online, submit maintenance requests with photos, and receive notices; landlords track leases and renewals, log expenses per property, and export tax-ready income reports.
TECH_STACK: Symfony + Twig + PostgreSQL + Stripe ACH + Symfony Messenger queues, deployed on Platform.sh
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 150 concurrent users, ~20 req/sec, ~8 GB data
```

## 70. GateList — event ticketing API

```text
APP_DESCRIPTION: A ticketing API service for independent event promoters. Promoter storefronts create events with tiered ticket types and promo codes, the service handles inventory holds during checkout, issues QR-coded tickets, and validates scans at the door with offline-capable gate devices.
TECH_STACK: Laravel (API-only) + MySQL + Redis inventory locks + Stripe + signed QR validation, deployed on AWS
APP_TYPE: API service
LANGUAGE: PHP
SCALE: ~500 req/sec on-sale peak, 800 events/year, ~12 GB data
```

## 71. WP Plugin — StallFinder farmers-market directory

```text
APP_DESCRIPTION: A WordPress plugin that adds a farmers-market vendor directory with stall booking to a market's WordPress site. Market managers define market dates and stall maps, vendors apply and book stalls with seasonal pricing, and visitors browse vendor profiles by product category.
TECH_STACK: WordPress plugin (PHP) + custom post types + custom REST endpoints + Gutenberg blocks (vendor directory, stall map) + MySQL custom tables for bookings + Stripe
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 100 concurrent users on booking-open day, ~10 req/sec, ~1 GB data
```

## 72. WP Plugin — CourseCurtain membership drip

```text
APP_DESCRIPTION: A WordPress plugin that paywalls course content with drip scheduling for creators who sell courses from their own WordPress site. Creators mark lessons as free/member-only, define drip schedules per cohort, sell memberships with recurring billing, and track lesson completion per student.
TECH_STACK: WordPress plugin (PHP) + custom post types + Stripe subscriptions + MySQL progress tables + Gutenberg blocks for content gating (with shortcode fallback)
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 400 concurrent students, ~25 req/sec, ~5 GB data
```

## 73. WP Plugin — TableTonight restaurant reservations

```text
APP_DESCRIPTION: A WordPress plugin that adds table reservations to restaurant websites. Diners book by party size and time with live availability from a visual table map, the kitchen caps covers per service, hosts manage the floor from a same-day dashboard, and no-show protection takes card holds via Stripe.
TECH_STACK: WordPress plugin (PHP) + Gutenberg booking-widget block (REST-backed) + MySQL custom tables + Stripe + email/SMS confirmations
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 150 concurrent users Friday peak, ~15 req/sec, ~2 GB data
```

## 74. WP Plugin — DoorKey real-estate listings

```text
APP_DESCRIPTION: A WordPress plugin that turns an agency's WordPress site into a property-listings portal. Agents publish listings with photo galleries, price, and features; visitors filter by neighborhood, price band, bedrooms, and property type with map view; leads route to the listing agent with inquiry tracking.
TECH_STACK: WordPress plugin (PHP) + custom post types/taxonomies + Leaflet maps + MySQL meta indexes + Gutenberg blocks
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 300 concurrent visitors, ~35 req/sec, ~20 GB (photos in media library)
```

## 75. WP Plugin — TicketStub event calendar

```text
APP_DESCRIPTION: A WordPress plugin that adds an event calendar with paid ticket sales for community venues running WordPress. Staff publish events on month/list calendar views, sell tiered tickets with capacity limits through Stripe checkout, email QR tickets, and check attendees in from a mobile browser scanner page.
TECH_STACK: WordPress plugin (PHP) + custom post types + Gutenberg blocks (calendar, event list, ticket purchase) + Stripe Checkout + MySQL attendee tables + QR generation/scanning
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 200 concurrent users on-sale peak, ~20 req/sec, ~3 GB data
```

## 76. WP Theme — Aperture photography portfolio

```text
APP_DESCRIPTION: A WordPress theme for professional photographers, built around portfolio presentation and client proofing. It ships full-bleed gallery layouts with lazy-loaded images, password-protected client proofing galleries with favoriting, an about/booking page pattern, and print-shop-ready image protection options.
TECH_STACK: WordPress block theme (PHP + theme.json) + Gutenberg block patterns + custom gallery block + responsive image srcsets
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 200 concurrent visitors, ~25 req/sec, ~40 GB media
```

## 77. WP Theme — Broadsheet local news

```text
APP_DESCRIPTION: A WordPress theme for local newspapers and magazines. It provides front-page editorial layouts with story hierarchy (lead, features, briefs), section landing pages, breaking-news banners, reporter bylines and archives, and ad-slot regions — all editable by non-technical editors via the block editor.
TECH_STACK: WordPress block theme (PHP + theme.json) + block patterns for editorial layouts + category-driven templates + AMP-friendly markup
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 2,000 concurrent readers on breaking news, ~200 req/sec (page-cached), ~15 GB media
```

## 78. WP Theme — OpenHand charity

```text
APP_DESCRIPTION: A WordPress theme for charities and nonprofits centered on donations and volunteering. It includes campaign pages with progress bars, a donation block that integrates with common giving plugins, volunteer sign-up sections, impact-report layouts, and accessibility-first components meeting WCAG 2.2 AA.
TECH_STACK: WordPress block theme (PHP + theme.json) + Gutenberg block patterns + donation-plugin integration hooks + WCAG-audited components
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 500 concurrent visitors during appeal campaigns, ~50 req/sec, ~5 GB media
```

---

# Ruby

## 79. InnKeep — boutique hotel booking

```text
APP_DESCRIPTION: A direct-booking web app for boutique hotels and guesthouses. Guests check live room availability, book with dynamic seasonal pricing, and manage stays; innkeepers run the front desk (check-in/out, housekeeping status), sync availability to OTA channels, and send pre-arrival emails.
TECH_STACK: Ruby on Rails + Hotwire (Turbo/Stimulus) + PostgreSQL + Stripe + channel-manager API sync, deployed on Heroku
APP_TYPE: web app
LANGUAGE: Ruby
SCALE: 200 concurrent users, ~25 req/sec, ~8 GB data
```

## 80. RoastPost — coffee subscription storefront

```text
APP_DESCRIPTION: A subscription storefront web app for a specialty coffee roastery. Customers build recurring coffee subscriptions (roast preference, grind, cadence), skip or swap upcoming shipments, and gift subscriptions; the roastery plans weekly roast batches from subscription demand and prints shipping labels.
TECH_STACK: Ruby on Rails + Hotwire + PostgreSQL + Stripe Billing + EasyPost shipping, deployed on Render
APP_TYPE: web app
LANGUAGE: Ruby
SCALE: 300 concurrent users, ~35 req/sec, ~6 GB data
```

## 81. HireLoop — applicant tracking system

```text
APP_DESCRIPTION: An applicant-tracking web app for companies of 50-500 employees. Recruiters post jobs to a branded careers page, move candidates through customizable pipeline stages with structured interview scorecards, schedule interviews with calendar sync, and report on time-to-hire and source effectiveness.
TECH_STACK: Ruby on Rails + Hotwire + PostgreSQL + Sidekiq + Google/Microsoft calendar APIs, deployed on AWS
APP_TYPE: web app
LANGUAGE: Ruby
SCALE: 600 concurrent users, ~70 req/sec, ~25 GB data
```

## 82. StageDoor — community theater ticketing

```text
APP_DESCRIPTION: A ticketing web app for community theaters. Patrons pick seats from an interactive seat map, buy season subscriptions with seat retention, and receive QR e-tickets; the box office manages holds and comps, scans tickets at the door, and reports nightly sales per production.
TECH_STACK: Ruby on Rails + Hotwire + PostgreSQL + Stripe + seat-map SVG rendering, deployed on Fly.io
APP_TYPE: web app
LANGUAGE: Ruby
SCALE: 400 concurrent users at season-open, ~50 req/sec peak, ~4 GB data
```

## 83. RateRelay — shipping rate aggregation API

```text
APP_DESCRIPTION: A shipping-rate aggregation API service for e-commerce developers. Clients submit parcel dimensions and destinations, the service fans out to carrier APIs (UPS, FedEx, USPS, DHL), normalizes and caches rate quotes, applies client-negotiated discounts, and returns ranked options with delivery estimates.
TECH_STACK: Ruby (Rails API mode) + PostgreSQL + Redis quote cache + Sidekiq + carrier API connectors, deployed on AWS
APP_TYPE: API service
LANGUAGE: Ruby
SCALE: ~180 req/sec, 250 client integrations, ~10 GB data
```

## 84. changelogger — release notes CLI

```text
APP_DESCRIPTION: A CLI tool for release managers that generates changelogs from git history. It parses conventional commits and PR labels between tags, groups entries by type and scope, drafts human-readable release notes with breaking-change callouts, and updates CHANGELOG.md plus GitHub release drafts.
TECH_STACK: Ruby CLI (thor) + rugged git bindings + GitHub API + ERB templates, distributed as a gem
APP_TYPE: CLI
LANGUAGE: Ruby
SCALE: single user per invocation, repos up to 100k commits, <100 MB local data
```

---

# Perl

## 85. LogSift — log anomaly digest pipeline

```text
APP_DESCRIPTION: A data pipeline for a hosting provider's ops team that digests server logs into daily anomaly reports. It parses syslog, auth, and web-server logs across 400 hosts, baselines normal patterns per host, surfaces anomalies (error bursts, unusual auth activity, disk warnings), and emails a prioritized morning digest.
TECH_STACK: Perl + regex parsing framework + PostgreSQL + rsyslog ingestion + cron scheduling, self-hosted
APP_TYPE: data pipeline
LANGUAGE: Perl
SCALE: 400 hosts, ~40 GB logs/day, nightly batch within 2-hour window
```

## 86. mailtrim — mailbox archive dedupe CLI

```text
APP_DESCRIPTION: A CLI tool for mail administrators that deduplicates and prunes large mail archives. It scans Maildir/mbox stores, identifies duplicate messages across folders by content hash, applies retention rules by age and folder, produces a dry-run report before any deletion, and writes an audit log of every action.
TECH_STACK: Perl CLI (Getopt::Long) + Mail::Box + SQLite hash index + configurable retention policy files
APP_TYPE: CLI
LANGUAGE: Perl
SCALE: single operator, archives up to 2 TB / 10M messages per run
```

## 87. EDIBridge — legacy EDI transformation pipeline

```text
APP_DESCRIPTION: A data pipeline for a wholesale distributor that bridges legacy EDI trading partners to a modern ERP. It ingests X12 documents (850 orders, 856 ship notices, 810 invoices) over AS2/SFTP, validates against partner-specific rules, transforms to the ERP's JSON API format, and manages acknowledgments and resubmission of failed documents.
TECH_STACK: Perl + X12 parsing modules + PostgreSQL document ledger + SFTP/AS2 endpoints + ERP REST integration, on-prem
APP_TYPE: data pipeline
LANGUAGE: Perl
SCALE: 120 trading partners, ~15k documents/day, <10 GB/month, 24/7 with 15-min SLA
```

## 88. RackTrack — intranet server inventory

```text
APP_DESCRIPTION: An intranet web app for a university IT department that inventories servers and network gear. Technicians record hardware specs, rack locations, warranty and lifecycle dates; automated agents report OS and patch levels; managers plan refresh budgets from age and warranty reports.
TECH_STACK: Perl (Mojolicious) + PostgreSQL + Template Toolkit + LDAP auth + agent check-in API, self-hosted
APP_TYPE: web app
LANGUAGE: Perl
SCALE: 40 concurrent users, ~8 req/sec, 3,500 tracked devices, ~2 GB data
```

---

# Kotlin

## 89. WrenchWay — field service work orders

```text
APP_DESCRIPTION: A field-service mobile app for HVAC and plumbing technicians. Techs receive dispatched work orders with customer history and equipment records, navigate to jobs, capture photos and signatures, log parts used against van inventory, and generate on-site invoices — with full offline capability for basements and rural areas.
TECH_STACK: Kotlin (Android, Jetpack Compose) + Room offline store + WorkManager sync + Retrofit to REST backend
APP_TYPE: mobile
LANGUAGE: Kotlin
SCALE: 2,000 technician devices, 600 concurrent, ~10 GB backend data
```

## 90. TransitTap — public transit companion

```text
APP_DESCRIPTION: A transit companion mobile app for a metro region's riders. Riders see live arrivals from GTFS-realtime feeds, plan multi-modal trips, save favorite stops with departure widgets, and receive service-disruption alerts for their usual lines.
TECH_STACK: Kotlin (Android, Jetpack Compose) + GTFS/GTFS-RT feeds + Room cache + FCM push alerts + MapLibre
APP_TYPE: mobile
LANGUAGE: Kotlin
SCALE: 80,000 MAU, 5,000 concurrent at rush hour, ~15 GB feed/cache data
```

## 91. PunchCup — café loyalty app

```text
APP_DESCRIPTION: A digital punch-card loyalty mobile app for independent cafés. Customers collect stamps via QR scan at checkout, redeem free drinks, and discover participating cafés nearby; café owners configure reward rules and see repeat-visit analytics from a simple dashboard.
TECH_STACK: Kotlin (Android, Jetpack Compose) + Ktor backend + PostgreSQL + QR signing + FCM
APP_TYPE: mobile
LANGUAGE: Kotlin
SCALE: 15,000 MAU, 800 concurrent, 120 participating cafés, ~4 GB data
```

## 92. OrderSpine — order management API

```text
APP_DESCRIPTION: An order-management API service for direct-to-consumer brands. It receives orders from storefronts, orchestrates payment capture, fraud screening, and warehouse allocation, manages splits/backorders and cancellations, and emits status webhooks to storefronts and customer-notification systems.
TECH_STACK: Kotlin (Ktor) + Exposed + PostgreSQL + Kafka + Redis, deployed on GCP GKE
APP_TYPE: API service
LANGUAGE: Kotlin
SCALE: ~350 req/sec Black Friday peak, 45 brands, ~40 GB data
```

## 93. depwatch — Gradle dependency audit CLI

```text
APP_DESCRIPTION: A CLI tool for JVM teams that audits Gradle project dependencies. It resolves the full dependency graph, reports outdated versions with upgrade risk hints, flags known-vulnerable versions from the OSV database, detects unused declared dependencies, and emits console, JSON, and CI-annotation output.
TECH_STACK: Kotlin CLI (clikt) + Gradle Tooling API + OSV vulnerability database + local cache, distributed via Homebrew/GitHub releases
APP_TYPE: CLI
LANGUAGE: Kotlin
SCALE: single user per invocation, CI usage ~500 runs/day, <500 MB local cache
```

## 94. PickPath — warehouse picking app

```text
APP_DESCRIPTION: A warehouse picking mobile app for e-commerce fulfillment staff. Pickers receive wave-optimized pick lists on rugged Android scanners, confirm items by barcode with quantity and location validation, report short-picks and damaged stock, and hand off completed totes to packing stations.
TECH_STACK: Kotlin (Android, Jetpack Compose) + zebra scanner SDK + Room offline queue + gRPC to warehouse backend
APP_TYPE: mobile
LANGUAGE: Kotlin
SCALE: 250 scanner devices across 2 warehouses, 180 concurrent, ~5 GB backend data
```

---

# Swift

## 95. StillMind — meditation and sleep app

```text
APP_DESCRIPTION: A meditation and sleep-sounds iOS app for stressed professionals. Users follow guided meditation programs with progress tracking, mix ambient sleep soundscapes with timers, log mood before/after sessions, and build streaks with gentle reminders — content downloadable for offline use.
TECH_STACK: Swift (SwiftUI) + Core Data + AVFoundation audio engine + StoreKit 2 subscriptions + CloudKit sync
APP_TYPE: mobile
LANGUAGE: Swift
SCALE: 40,000 MAU, 2,000 concurrent evening peak, ~2 GB cloud data per user cohort
```

## 96. HomeVault — home inventory for insurance

```text
APP_DESCRIPTION: A home-inventory iOS app for homeowners documenting possessions for insurance. Users photograph rooms and items with value estimates and receipts, organize by room and category, export insurer-ready PDF inventories, and store everything encrypted with private cloud backup.
TECH_STACK: Swift (SwiftUI) + Core Data + CloudKit private database + Vision framework for receipt OCR + PDF generation
APP_TYPE: mobile
LANGUAGE: Swift
SCALE: 10,000 MAU, single-user data model, ~5 GB media per active user
```

## 97. RidgeLog — hiking trail log

```text
APP_DESCRIPTION: A trail-logging iOS app for hikers. Hikers record GPS tracks with elevation profiles even offline, attach photos and condition notes to waypoints, maintain a lifetime peak/trail log with stats, and share GPX exports — offline topo map packs cover no-signal wilderness areas.
TECH_STACK: Swift (SwiftUI) + Core Location/HealthKit + MapKit with offline tile packs + Core Data + GPX import/export
APP_TYPE: mobile
LANGUAGE: Swift
SCALE: 25,000 MAU, heavy offline use, ~8 GB map/track data per device max
```

## 98. BarTime — menu-bar time tracker

```text
APP_DESCRIPTION: A macOS menu-bar time-tracking desktop app for consultants. Users start/stop timers per client project from the menu bar, get idle-detection prompts and calendar-aware suggestions, review weekly timesheets, and export billable-hours CSVs for invoicing tools.
TECH_STACK: Swift (SwiftUI + AppKit menu-bar integration) + Core Data local store + EventKit calendar access + CSV export
APP_TYPE: desktop
LANGUAGE: Swift
SCALE: single user, local data <1 GB
```

## 99. PushPilot — notification scheduling API

```text
APP_DESCRIPTION: A push-notification scheduling API service for small app studios. Studio backends register device tokens and audience segments, schedule one-off and recurring campaigns with per-timezone delivery windows, and get delivery/open analytics — the service handles APNs/FCM fan-out, retries, and token hygiene.
TECH_STACK: Swift (Vapor) + PostgreSQL + Redis queues + APNs/FCM providers, deployed on AWS ECS
APP_TYPE: API service
LANGUAGE: Swift
SCALE: ~600 req/sec during campaign fan-out, 30 studio clients, 8M device tokens, ~20 GB data
```

## 100. PelotonPals — cycling club tracker

```text
APP_DESCRIPTION: A club ride-tracking iOS app for local cycling clubs. Members RSVP to scheduled group rides with route previews, record rides with live group location sharing for regrouping, log personal stats and club leaderboards, and ride captains manage no-drop sweep lists.
TECH_STACK: Swift (SwiftUI) + Core Location + MapKit + CloudKit shared databases + HealthKit integration
APP_TYPE: mobile
LANGUAGE: Swift
SCALE: 5,000 MAU across 200 clubs, 400 concurrent during weekend rides, ~10 GB data
```
