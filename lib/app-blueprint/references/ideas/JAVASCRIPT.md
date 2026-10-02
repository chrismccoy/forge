# JavaScript (Node.js) Blueprint Types — Copy-Paste Input Sets

Copy a fenced block into the prompt as-is, or swap individual fields.

## 1. HookMirror — webhook relay and inspector

```text
APP_DESCRIPTION: An API service that receives, inspects, and relays webhooks for development teams. Developers create endpoints that capture incoming webhook payloads, replay them against local tunnels or staging targets, and set transform/filter rules per destination.
TECH_STACK: Express + PostgreSQL + Redis (queue) + BullMQ, deployed on Railway
APP_TYPE: API service
LANGUAGE: JavaScript (Node.js)
SCALE: ~250 req/sec, 150 active teams, ~20 GB payload data
```

## 2. ParishCast — community livestream portal

```text
APP_DESCRIPTION: A livestream and event portal web app for churches and community centers. Staff schedule services and events, embed livestreams with live chat, collect prayer requests or announcements, and archive past streams by series.
TECH_STACK: Express + EJS templates + PostgreSQL + Mux video, deployed on Render
APP_TYPE: web app
LANGUAGE: JavaScript (Node.js)
SCALE: 600 concurrent viewers Sunday peak, ~40 req/sec, ~30 GB video metadata/archive index
```

## 3. BotBench — chatbot hosting dashboard

```text
APP_DESCRIPTION: A dashboard web app for hobbyists who run community chat bots. Users register bots, edit command configs and auto-moderation rules through forms, view invocation logs and error rates, and restart bot processes.
TECH_STACK: Express + React (Vite) + PostgreSQL + Docker API for bot processes, self-hosted
APP_TYPE: web app
LANGUAGE: JavaScript (Node.js)
SCALE: 100 concurrent users, ~20 req/sec, ~5 GB data
```

## 4. GreenFlow — greenhouse telemetry pipeline

```text
APP_DESCRIPTION: A data pipeline that ingests telemetry from smart-greenhouse sensors (temperature, humidity, soil moisture, CO2) for commercial growers. It validates and downsamples readings, detects threshold breaches for alerting, and loads hourly aggregates into a reporting database.
TECH_STACK: Node.js (streams) + MQTT ingestion + TimescaleDB + Grafana, deployed on a single VPS
APP_TYPE: data pipeline
LANGUAGE: JavaScript (Node.js)
SCALE: 2,000 sensor readings/sec, ~8 GB/day raw, 90-day retention
```

## 5. upcheck — uptime monitor CLI

```text
APP_DESCRIPTION: A CLI tool for freelancers who maintain client websites. It checks a config file of URLs for status, latency, SSL expiry, and content assertions, prints a color-coded report, and exits non-zero for CI or cron-based alerting.
TECH_STACK: Node.js CLI (yargs) + native fetch + JSON/YAML config, distributed via npm
APP_TYPE: CLI
LANGUAGE: JavaScript (Node.js)
SCALE: single user per invocation, up to 500 URLs per run, <50 MB local data
```

## 6. ShelfMate — library reservation system

```text
APP_DESCRIPTION: A book reservation web app for small-town public libraries. Patrons search the catalog, place holds, and get pickup notifications; librarians manage check-in/check-out, waitlists, and overdue notices.
TECH_STACK: Express + Pug templates + PostgreSQL + nodemailer, deployed on a municipal VPS
APP_TYPE: web app
LANGUAGE: JavaScript (Node.js)
SCALE: 120 concurrent users, ~15 req/sec, ~4 GB data
```

## 7. WeekPlate — recipe box and meal planner

```text
APP_DESCRIPTION: A meal-planning web app for busy households. Users save and tag recipes, drag them onto a weekly calendar, auto-generate consolidated grocery lists by store aisle, and scale portions per household size.
TECH_STACK: Fastify + React (Vite) + PostgreSQL + Redis session store, deployed on Fly.io
APP_TYPE: web app
LANGUAGE: JavaScript (Node.js)
SCALE: 400 concurrent users, ~45 req/sec, ~7 GB data
```

## 8. PressProof — print shop order intake

```text
APP_DESCRIPTION: An order-intake API service for commercial print shops. Customers' storefronts submit print jobs with artwork files and specs (stock, finish, quantity), the service validates artwork dimensions and bleed, quotes pricing from rule tables, and tracks jobs through proof-approval to production.
TECH_STACK: Express + PostgreSQL + S3-compatible file storage + Sharp for artwork validation, deployed on AWS
APP_TYPE: API service
LANGUAGE: JavaScript (Node.js)
SCALE: ~60 req/sec, 200 storefront integrations, ~200 GB artwork files
```

## 9. Clinicova — clinic appointment scheduler

```text
APP_DESCRIPTION: An appointment scheduling web app for small outpatient clinics. Front-desk staff manage provider calendars, double-booking rules, and recall reminders; patients self-book from open slots and receive SMS confirmations and intake forms.
TECH_STACK: Fastify + React (Vite) + PostgreSQL + Twilio SMS, deployed on Render
APP_TYPE: web app
LANGUAGE: JavaScript (Node.js)
SCALE: 300 concurrent users, ~35 req/sec, 45 clinics, ~12 GB data
```

## 10. HaulDesk — freight brokerage load board

```text
APP_DESCRIPTION: An API service for freight brokers that posts loads, matches them to carrier capacity, and tracks rate confirmations and tender acceptance. Integrates with carrier TMS systems and pushes status updates to shipper portals.
TECH_STACK: Express + PostgreSQL + Redis + BullMQ for tender workflows, deployed on AWS ECS
APP_TYPE: API service
LANGUAGE: JavaScript (Node.js)
SCALE: ~180 req/sec, 1,200 carrier integrations, ~60 GB data
```

## 11. QuizForge — quiz builder and auto-grader

```text
APP_DESCRIPTION: A web app for middle- and high-school teachers to build question banks, assemble timed quizzes, and auto-grade multiple-choice and short-answer submissions. Teachers see item-level analytics to spot which concepts a class is missing.
TECH_STACK: Express + Handlebars templates + PostgreSQL + Redis for quiz sessions, deployed on DigitalOcean
APP_TYPE: web app
LANGUAGE: JavaScript (Node.js)
SCALE: 2,500 concurrent students during exam windows, ~120 req/sec, ~9 GB data
```

## 12. HerdLine — livestock herd records

```text
APP_DESCRIPTION: A mobile app for cattle and sheep ranchers to record animal births, weights, vaccinations, and pasture moves from the field, offline-first with sync when back in signal. Generates treatment-withdrawal warnings before sale dates.
TECH_STACK: React Native + SQLite (offline) + Node.js/Express sync API + PostgreSQL, API on Fly.io
APP_TYPE: mobile
LANGUAGE: JavaScript (Node.js)
SCALE: 3,000 ranchers, ~500,000 animal records, ~10 sync req/sec peak
```

## 13. DocketPing — court deadline tracker

```text
APP_DESCRIPTION: An API service for small law firms that computes litigation deadlines from court rules (answer due dates, discovery cutoffs, appeal windows) when a filing event is posted, and pushes calendar entries and escalating reminders to attorneys.
TECH_STACK: Fastify + PostgreSQL + rule-table engine + Google Calendar/Outlook APIs, deployed on Heroku
APP_TYPE: API service
LANGUAGE: JavaScript (Node.js)
SCALE: ~25 req/sec, 800 firms, ~90,000 active matters, ~6 GB data
```

## 14. LedgerSift — invoice reconciliation pipeline

```text
APP_DESCRIPTION: A data pipeline for accounting teams that ingests supplier invoices (EDI, CSV, PDF-extracted), matches them against purchase orders and goods receipts, flags three-way-match exceptions, and exports approved batches to the ERP.
TECH_STACK: Node.js workers + RabbitMQ + PostgreSQL + pdf-parse, deployed on Kubernetes
APP_TYPE: data pipeline
LANGUAGE: JavaScript (Node.js)
SCALE: 40,000 invoices/day, ~2 GB/day ingest, 7-year archive
```

## 15. TidyTurn — hotel housekeeping operations

```text
APP_DESCRIPTION: A web app for mid-size hotels that assigns room-cleaning queues to housekeeping staff, tracks room status (dirty, in-progress, inspected), logs maintenance issues found during turns, and syncs readiness back to the front desk.
TECH_STACK: Express + Vue (Vite) + PostgreSQL + Socket.IO for live room status, deployed on Azure App Service
APP_TYPE: web app
LANGUAGE: JavaScript (Node.js)
SCALE: 90 hotels, 1,800 concurrent staff devices, ~50 req/sec, ~8 GB data
```

## 16. DuctPulse — commercial HVAC telemetry

```text
APP_DESCRIPTION: A data pipeline that ingests rooftop-unit and air-handler telemetry (supply temps, static pressure, compressor cycles) from office buildings, normalizes vendor formats, detects short-cycling and filter-clog signatures, and feeds a fault dashboard for building engineers.
TECH_STACK: Node.js streams + MQTT/BACnet gateways + Kafka + ClickHouse, deployed on GCP
APP_TYPE: data pipeline
LANGUAGE: JavaScript (Node.js)
SCALE: 12,000 readings/sec across 400 buildings, ~25 GB/day, 1-year retention
```

## 17. CastScribe — podcast transcription pipeline

```text
APP_DESCRIPTION: A data pipeline for podcast networks that pulls new episodes from RSS, runs speech-to-text, aligns speaker labels, generates chapter markers and show-notes drafts, and publishes transcripts to hosting platforms via API.
TECH_STACK: Node.js workers + BullMQ + Redis + Whisper API + S3, deployed on AWS
APP_TYPE: data pipeline
LANGUAGE: JavaScript (Node.js)
SCALE: 900 episodes/day, ~350 GB audio/month processed, 60 networks
```

## 18. FixNest — rental maintenance portal

```text
APP_DESCRIPTION: A web app connecting tenants, landlords, and contractors for rental-property maintenance. Tenants submit issues with photos, landlords approve quotes and dispatch vetted contractors, and everyone tracks job status and invoices in one thread.
TECH_STACK: Express + React (Vite) + PostgreSQL + S3 for photos + Stripe for contractor payouts, deployed on AWS
APP_TYPE: web app
LANGUAGE: JavaScript (Node.js)
SCALE: 25,000 rental units, ~70 req/sec, ~120 GB photo storage
```

## 19. PitchRoster — youth soccer league manager

```text
APP_DESCRIPTION: A web app for youth soccer leagues to build season schedules across shared fields, manage team rosters and coach assignments, record scores, and notify parents of rainouts and reschedules.
TECH_STACK: Express + EJS templates + PostgreSQL + nodemailer + Twilio, deployed on Render
APP_TYPE: web app
LANGUAGE: JavaScript (Node.js)
SCALE: 180 leagues, 9,000 teams, ~30 req/sec, ~5 GB data
```

## 20. PermitPath — municipal permit portal

```text
APP_DESCRIPTION: A web app for city building departments where residents and contractors apply for building, electrical, and plumbing permits, upload plans, pay fees, and track review status; inspectors log field results from a queue view.
TECH_STACK: Fastify + server-rendered Nunjucks + PostgreSQL + S3-compatible storage + Stripe, deployed on state government cloud
APP_TYPE: web app
LANGUAGE: JavaScript (Node.js)
SCALE: 14 municipalities, ~22,000 permits/year, ~18 req/sec, ~90 GB plan documents
```

## 21. StockBridge — POS inventory sync

```text
APP_DESCRIPTION: An API service that keeps inventory counts consistent across brick-and-mortar POS systems, e-commerce storefronts, and marketplace listings for independent retailers. It resolves conflicting decrements, applies safety-stock rules, and pushes low-stock alerts.
TECH_STACK: Fastify + PostgreSQL + Redis + BullMQ + Shopify/Square/Lightspeed connectors, deployed on Fly.io
APP_TYPE: API service
LANGUAGE: JavaScript (Node.js)
SCALE: ~400 req/sec, 2,600 retailers, ~1.8M SKUs tracked
```

## 22. LeaveLoop — PTO and leave tracking

```text
APP_DESCRIPTION: A web app for HR teams at 50-500 person companies to manage PTO policies, accrual rules, and approval chains. Employees request time off from a team calendar view; managers see coverage conflicts before approving.
TECH_STACK: Express + React (Vite) + PostgreSQL + Slack/Teams notifications, deployed on Heroku
APP_TYPE: web app
LANGUAGE: JavaScript (Node.js)
SCALE: 420 companies, 65,000 employees, ~40 req/sec, ~6 GB data
```

## 23. ClaimSnap — insurance claims photo intake

```text
APP_DESCRIPTION: An API service for auto and property insurers that receives claim photos from policyholder apps, validates image quality and EXIF geodata, runs damage-region tagging, and assembles adjuster-ready claim packets.
TECH_STACK: Express + S3 + Sharp + PostgreSQL + SQS worker queue, deployed on AWS Lambda + ECS
APP_TYPE: API service
LANGUAGE: JavaScript (Node.js)
SCALE: 30,000 photo uploads/day, ~85 req/sec peak, ~2 TB image storage
```

## 24. SunGauge — solar farm production monitor

```text
APP_DESCRIPTION: A data pipeline that collects inverter and string-level production data from utility-scale solar farms, reconciles it against irradiance forecasts, computes performance ratios, and flags underperforming strings for O&M dispatch.
TECH_STACK: Node.js workers + Modbus/SunSpec collectors + Kafka + TimescaleDB + Grafana, deployed on AWS
APP_TYPE: data pipeline
LANGUAGE: JavaScript (Node.js)
SCALE: 45 solar farms, 6,000 inverter readings/sec, ~15 GB/day, 5-year retention
```

## 25. RankVault — game leaderboard service

```text
APP_DESCRIPTION: An API service for indie game studios providing hosted leaderboards, seasonal resets, anti-cheat score validation, and friend-ranked views. Studios integrate via SDK; players' scores post with signed payloads.
TECH_STACK: Fastify + Redis (sorted sets) + PostgreSQL + HMAC score signing, deployed on Cloudflare-fronted Hetzner
APP_TYPE: API service
LANGUAGE: JavaScript (Node.js)
SCALE: ~1,500 req/sec peak, 320 games, 4M monthly players
```

## 26. TripStitch — group travel itinerary planner

```text
APP_DESCRIPTION: A mobile app for friend groups planning trips together. Members propose flights, lodging, and activities into a shared itinerary, vote on options, split cost estimates, and get day-of schedule notifications with maps.
TECH_STACK: React Native + Node.js/Fastify API + PostgreSQL + Redis + push via FCM/APNs, API on Railway
APP_TYPE: mobile
LANGUAGE: JavaScript (Node.js)
SCALE: 90,000 monthly active users, ~110 req/sec peak, ~14 GB data
```

## 27. DownLog — machine downtime logging

```text
APP_DESCRIPTION: An Electron desktop app for factory floor supervisors to log machine downtime events with reason codes, shift, and operator notes at kiosk stations beside each line. Syncs to a central server for OEE reporting when the plant network allows.
TECH_STACK: Electron + SQLite (local) + Node.js sync service + PostgreSQL, kiosks on plant LAN
APP_TYPE: desktop
LANGUAGE: JavaScript (Node.js)
SCALE: 35 plants, 900 kiosk installs, ~180,000 downtime events/month
```

## 28. PawChart — veterinary clinic records

```text
APP_DESCRIPTION: A web app for independent veterinary clinics covering patient charts, vaccination schedules, exam notes with templates, lab result attachments, and reminder postcards/SMS for boosters and checkups.
TECH_STACK: Express + Pug templates + PostgreSQL + S3 for attachments + Twilio, deployed on DigitalOcean
APP_TYPE: web app
LANGUAGE: JavaScript (Node.js)
SCALE: 260 clinics, ~55 req/sec, 1.1M patient records, ~40 GB data
```

## 29. GiveTally — nonprofit donor management

```text
APP_DESCRIPTION: A web app for small nonprofits to track donors, pledges, and recurring gifts, segment mailing lists by giving history, log grant deadlines, and generate year-end tax receipt batches.
TECH_STACK: Express + React (Vite) + PostgreSQL + Stripe + SendGrid, deployed on Render
APP_TYPE: web app
LANGUAGE: JavaScript (Node.js)
SCALE: 700 nonprofits, ~28 req/sec, 2.4M donor records, ~9 GB data
```

## 30. GigSlot — band rehearsal and venue booking

```text
APP_DESCRIPTION: A web app where bands book rehearsal rooms and small venues by the hour, with gear inventories per room, recurring slot holds, deposit handling, and a bulletin board for fill-in musicians.
TECH_STACK: Fastify + EJS templates + PostgreSQL + Stripe deposits + iCal feeds, deployed on Fly.io
APP_TYPE: web app
LANGUAGE: JavaScript (Node.js)
SCALE: 140 studios/venues, 11,000 bands, ~20 req/sec, ~3 GB data
```

## 31. ExpoFire — restaurant kitchen display system

```text
APP_DESCRIPTION: An Electron desktop app that replaces paper tickets in restaurant kitchens. Orders from the POS route to station screens (grill, fry, expo), cooks bump items as they finish, and the expo screen assembles orders with aging timers and rush flags.
TECH_STACK: Electron + Node.js local hub + WebSocket fan-out + SQLite + POS webhook ingestion, on-premise per restaurant
APP_TYPE: desktop
LANGUAGE: JavaScript (Node.js)
SCALE: 480 restaurants, ~2,200 station screens, ~90,000 tickets/day network-wide
```

## 32. RepSpot — gym class booking

```text
APP_DESCRIPTION: A class booking web app for boutique gyms and yoga studios. Members reserve spots in capacity-limited classes, join waitlists with auto-promotion, and manage class-pack credits; owners set schedules and instructor payroll exports.
TECH_STACK: Express + React (Vite) + PostgreSQL + Redis + Stripe billing, deployed on AWS Elastic Beanstalk
APP_TYPE: web app
LANGUAGE: JavaScript (Node.js)
SCALE: 350 studios, 190,000 members, ~95 req/sec at 6pm peak, ~11 GB data
```

## 33. SiteDiary — construction daily reports

```text
APP_DESCRIPTION: A mobile app for construction site superintendents to file daily reports: crew headcounts, weather, work completed, delays, safety incidents, and photo documentation. Reports compile into client-ready PDFs and feed claims documentation.
TECH_STACK: Ionic + Capacitor + Node.js/Express API + PostgreSQL + S3 + Puppeteer PDF generation, API on AWS
APP_TYPE: mobile
LANGUAGE: JavaScript (Node.js)
SCALE: 5,500 active job sites, ~7,000 reports/day, ~300 GB photo archive
```

## 34. CrownTrack — dental lab case tracking

```text
APP_DESCRIPTION: A web app for dental labs to track crown, bridge, and denture cases from dentist Rx intake through design, milling, finishing, and shipping. Includes remake tracking, shade records, and doctor-facing status pages.
TECH_STACK: Express + Handlebars templates + PostgreSQL + label printing via PDF + UPS/FedEx APIs, deployed on Azure
APP_TYPE: web app
LANGUAGE: JavaScript (Node.js)
SCALE: 85 labs, ~48,000 active cases, ~25 req/sec, ~7 GB data
```

## 35. RefillRelay — pharmacy refill reminders

```text
APP_DESCRIPTION: An API service for independent pharmacies that syncs prescription fill data from pharmacy management systems, predicts refill-due dates, and sends SMS/voice reminders with one-tap refill confirmation that queues back into the fill workflow.
TECH_STACK: Fastify + PostgreSQL + BullMQ + Twilio SMS/voice + HL7/NCPDP adapters, deployed on HIPAA-eligible AWS
APP_TYPE: API service
LANGUAGE: JavaScript (Node.js)
SCALE: 640 pharmacies, 210,000 reminders/day, ~65 req/sec
```

## 36. SlipHarbor — marina slip reservations

```text
APP_DESCRIPTION: A web app for marinas to manage seasonal and transient slip rentals. Boaters search by vessel length/beam/draft, book slips with power and pump-out add-ons, and check in on arrival; harbormasters see an occupancy map by dock.
TECH_STACK: Express + Vue (Vite) + PostgreSQL + Stripe + Leaflet dock maps, deployed on DigitalOcean
APP_TYPE: web app
LANGUAGE: JavaScript (Node.js)
SCALE: 110 marinas, 19,000 slips, ~18 req/sec, ~4 GB data
```

## 37. WingSlate — flight school scheduling

```text
APP_DESCRIPTION: A web app for flight schools to schedule aircraft, instructors, and students together, enforcing currency and weather minimums per student stage. Tracks Hobbs/tach times, squawks that ground aircraft, and stage-check signoffs.
TECH_STACK: Fastify + React (Vite) + PostgreSQL + METAR feed integration, deployed on Render
APP_TYPE: web app
LANGUAGE: JavaScript (Node.js)
SCALE: 95 schools, 780 aircraft, ~30 req/sec, ~5 GB data
```

## 38. WrenchQuote — auto repair estimates

```text
APP_DESCRIPTION: A web app for independent auto repair shops to build repair estimates from labor-time guides and parts pricing, send them to customers for e-approval by text, and convert approved lines into work orders with technician assignments.
TECH_STACK: Express + EJS templates + PostgreSQL + parts supplier APIs + Twilio, deployed on Heroku
APP_TYPE: web app
LANGUAGE: JavaScript (Node.js)
SCALE: 520 shops, ~38,000 estimates/month, ~32 req/sec, ~8 GB data
```

## 39. TimberTally — timber harvest scale tickets

```text
APP_DESCRIPTION: A data pipeline for forestry companies that ingests truck scale tickets from mill scale houses, matches loads to harvest tracts and hauling contracts, computes stumpage and hauling settlements, and exports pay files to accounting.
TECH_STACK: Node.js workers + SFTP/CSV ingestion + PostgreSQL + BullMQ + settlement PDF generation, deployed on AWS
APP_TYPE: data pipeline
LANGUAGE: JavaScript (Node.js)
SCALE: 8,500 scale tickets/day across 60 mills, ~1 GB/day, 10-year retention
```

## 40. GillWatch — aquaculture water quality

```text
APP_DESCRIPTION: A mobile app for fish farm technicians monitoring pond and pen water quality. Techs log dissolved oxygen, pH, and temperature readings or pair with Bluetooth probes, get night-shift low-oxygen alarms, and record feed and mortality counts per pond.
TECH_STACK: React Native + BLE probe integration + Node.js/Fastify API + TimescaleDB + push alerts, API on GCP
APP_TYPE: mobile
LANGUAGE: JavaScript (Node.js)
SCALE: 230 farms, 6,800 ponds/pens, ~40,000 readings/day
```

## 41. tagchange — changelog generator CLI

```text
APP_DESCRIPTION: A CLI tool for open-source maintainers that generates release changelogs from conventional commits between git tags, groups entries by type and scope, links PRs and issues, and updates CHANGELOG.md or drafts a GitHub release.
TECH_STACK: Node.js CLI (commander) + simple-git + GitHub REST API, distributed via npm
APP_TYPE: CLI
LANGUAGE: JavaScript (Node.js)
SCALE: single user per invocation, repos up to 50,000 commits, ~85,000 npm downloads/month
```

## 42. lingosift — i18n string extractor

```text
APP_DESCRIPTION: A CLI tool for frontend teams that scans source trees for translatable strings, diffs them against locale JSON/PO files, flags missing or orphaned keys, and fails CI when translations fall below a completeness threshold.
TECH_STACK: Node.js CLI (yargs) + Babel/AST parsing + glob file walker, distributed via npm
APP_TYPE: CLI
LANGUAGE: JavaScript (Node.js)
SCALE: single user or CI per invocation, codebases up to 20,000 files, 40 locales per project
```

## 43. squishpix — image optimization CLI

```text
APP_DESCRIPTION: A CLI tool for static-site developers that batch-optimizes images: resizes to configured breakpoints, converts to WebP/AVIF, strips metadata, and writes a manifest of generated variants for build tools to consume.
TECH_STACK: Node.js CLI (commander) + Sharp + worker threads for parallelism, distributed via npm
APP_TYPE: CLI
LANGUAGE: JavaScript (Node.js)
SCALE: single user per invocation, up to 10,000 images per run, ~4 GB processed per batch
```

## 44. schemabump — SQL migration runner

```text
APP_DESCRIPTION: A CLI tool for backend teams that runs versioned SQL migrations with checksums, dry-run plans, per-environment locking, and down-migration guards. Prints a drift report when the live schema diverges from the migration history.
TECH_STACK: Node.js CLI (commander) + pg/mysql2 drivers + advisory locks, distributed via npm
APP_TYPE: CLI
LANGUAGE: JavaScript (Node.js)
SCALE: single user or CI per invocation, projects with up to 2,000 migrations, ~30,000 npm downloads/month
```

## 45. crawlmap — sitemap auditor CLI

```text
APP_DESCRIPTION: A CLI tool for SEO consultants that crawls a site, compares discovered pages against the XML sitemap, and reports orphan pages, sitemap entries returning non-200s, redirect chains, and canonical mismatches as CSV or JSON.
TECH_STACK: Node.js CLI (yargs) + undici with concurrency pool + robots.txt parser, distributed via npm
APP_TYPE: CLI
LANGUAGE: JavaScript (Node.js)
SCALE: single user per invocation, crawls up to 100,000 URLs per run at 20 req/sec
```

## 46. licenselint — dependency license checker

```text
APP_DESCRIPTION: A CLI tool for engineering compliance that inventories npm dependency licenses, checks them against an allow/deny policy file, flags copyleft in production bundles, and emits SPDX reports for legal review.
TECH_STACK: Node.js CLI (commander) + package-lock/pnpm-lock parsers + SPDX data, distributed via npm
APP_TYPE: CLI
LANGUAGE: JavaScript (Node.js)
SCALE: single user or CI per invocation, dependency trees up to 8,000 packages, ~55,000 npm downloads/month
```

## 47. envlinter — environment config linter

```text
APP_DESCRIPTION: A CLI tool that validates .env files and deployment environment variables against a declared schema: required keys, types, URL/port formats, and forbidden plaintext secrets. Runs in CI and as a pre-deploy gate.
TECH_STACK: Node.js CLI (yargs) + zod-based schema + dotenv parsing, distributed via npm
APP_TYPE: CLI
LANGUAGE: JavaScript (Node.js)
SCALE: single user or CI per invocation, schemas up to 300 variables across 12 environments
```

## 48. apidiff — OpenAPI contract differ

```text
APP_DESCRIPTION: A CLI tool for API platform teams that diffs two OpenAPI specs and classifies changes as breaking, deprecating, or additive — removed endpoints, narrowed types, new required fields — and fails CI on breaking changes without a version bump.
TECH_STACK: Node.js CLI (commander) + OpenAPI 3.x parser + JSON schema comparison, distributed via npm
APP_TYPE: CLI
LANGUAGE: JavaScript (Node.js)
SCALE: single user or CI per invocation, specs up to 1,500 endpoints, ~20,000 npm downloads/month
```

## 49. taillight — structured log pretty-printer

```text
APP_DESCRIPTION: A CLI tool that tails JSON log streams from files, kubectl, or stdin and renders them human-readable: level colors, field filtering with a query flag, trace-id grouping, and a stats mode summarizing error rates per service.
TECH_STACK: Node.js CLI + stream transforms + chalk + minimal query grammar, distributed via npm
APP_TYPE: CLI
LANGUAGE: JavaScript (Node.js)
SCALE: single user per invocation, sustains 50,000 log lines/sec throughput
```

## 50. restorecheck — backup restore verifier

```text
APP_DESCRIPTION: A CLI tool for ops teams that proves backups are restorable: pulls the latest database dump from object storage, restores it into a scratch container, runs row-count and checksum assertions, and posts pass/fail to a status webhook.
TECH_STACK: Node.js CLI (commander) + S3 SDK + Docker API + pg_restore/mysql orchestration, distributed via npm
APP_TYPE: CLI
LANGUAGE: JavaScript (Node.js)
SCALE: cron-invoked, verifies backups up to 500 GB, 200 scheduled checks/day per install
```

## 51. favforge — favicon and manifest generator

```text
APP_DESCRIPTION: A CLI tool for web developers that takes one source image and generates the full favicon set — ICO, PNG sizes, Apple touch icons, maskable icons — plus a web manifest and the HTML head snippet to paste in.
TECH_STACK: Node.js CLI (yargs) + Sharp + png-to-ico, distributed via npm
APP_TYPE: CLI
LANGUAGE: JavaScript (Node.js)
SCALE: single user per invocation, ~120,000 npm downloads/month
```

## 52. kilocheck — bundle size budget checker

```text
APP_DESCRIPTION: A CLI tool for frontend teams that measures built JS/CSS bundle sizes (raw, gzip, brotli) against per-file budgets in config, comments the delta on pull requests, and fails CI when a budget is exceeded.
TECH_STACK: Node.js CLI (commander) + glob + zlib/brotli + GitHub Checks API, distributed via npm
APP_TYPE: CLI
LANGUAGE: JavaScript (Node.js)
SCALE: CI-invoked, builds up to 4,000 output files, ~45,000 npm downloads/month
```

## 53. seedstock — test fixture generator

```text
APP_DESCRIPTION: A CLI tool for backend developers that generates realistic seed data from a database schema: reads foreign keys to build valid object graphs, applies locale-aware fake values per column type, and writes SQL inserts or JSON fixtures.
TECH_STACK: Node.js CLI (yargs) + schema introspection (pg/mysql2) + faker, distributed via npm
APP_TYPE: CLI
LANGUAGE: JavaScript (Node.js)
SCALE: single user per invocation, schemas up to 400 tables, generates 5M rows per run
```

## 54. branchsweep — stale branch cleaner

```text
APP_DESCRIPTION: A CLI tool for repo maintainers that lists remote branches by staleness, merge status, and author, then interactively or via flags deletes merged and abandoned branches, with a protection list and a dry-run report for team review.
TECH_STACK: Node.js CLI (commander) + simple-git + GitHub/GitLab APIs, distributed via npm
APP_TYPE: CLI
LANGUAGE: JavaScript (Node.js)
SCALE: single user per invocation, repos with up to 5,000 branches, ~15,000 npm downloads/month
```

## 55. CueDeck — theater show control

```text
APP_DESCRIPTION: An Electron desktop app for community and school theaters that manages show cue sheets: lighting, sound, and projection cues sequenced per scene, triggered live by the stage manager with a GO button, with rehearsal notes attached to each cue.
TECH_STACK: Electron + SQLite + OSC/MIDI output to lighting and sound consoles + Web Audio for playback
APP_TYPE: desktop
LANGUAGE: JavaScript (Node.js)
SCALE: 2,400 installed venues, shows up to 600 cues, 12,000 performances/year logged
```

## 56. CrateIndex — vinyl collection cataloger

```text
APP_DESCRIPTION: An Electron desktop app for record collectors and used-record stores to catalog vinyl: barcode/matrix lookup against Discogs, condition grading, purchase and valuation history, and want-list matching against store intake.
TECH_STACK: Electron + SQLite + Discogs API + barcode scanner input + CSV export
APP_TYPE: desktop
LANGUAGE: JavaScript (Node.js)
SCALE: 18,000 installs, collections up to 40,000 records, ~2 GB local data per heavy user
```

## 57. LotHammer — auction clerking desktop

```text
APP_DESCRIPTION: An Electron desktop app for estate and livestock auction houses to clerk live auctions: rapid lot entry, bidder number lookup, hammer-price recording with keyboard-only flow, and instant buyer invoices and seller settlements at close.
TECH_STACK: Electron + SQLite (offline-capable) + Node.js sync to cloud PostgreSQL + receipt printer integration
APP_TYPE: desktop
LANGUAGE: JavaScript (Node.js)
SCALE: 340 auction houses, sales up to 2,500 lots, ~9,000 auctions/year
```

## 58. StitchBay — embroidery job prep

```text
APP_DESCRIPTION: An Electron desktop app for embroidery shops that queues machine jobs: imports DST/PES stitch files, previews designs with thread-color mapping, estimates run time and thread usage, and sequences jobs across multi-head machines.
TECH_STACK: Electron + stitch-format parsers + SQLite + machine folder/USB export + canvas preview rendering
APP_TYPE: desktop
LANGUAGE: JavaScript (Node.js)
SCALE: 1,100 shops, ~450 jobs/shop/month, design files up to 80,000 stitches
```

## 59. AirwaveLog — amateur radio logbook

```text
APP_DESCRIPTION: An Electron desktop app for ham radio operators that logs contacts (QSOs) with rig control integration for automatic frequency/mode capture, tracks award progress (DXCC, grid squares), and uploads confirmations to LoTW and eQSL.
TECH_STACK: Electron + SQLite + hamlib rig control + ADIF import/export + LoTW/eQSL APIs
APP_TYPE: desktop
LANGUAGE: JavaScript (Node.js)
SCALE: 26,000 active operators, logbooks up to 500,000 QSOs, ~1.2M uploads/month
```

## 60. CullFrame — photo culling workstation

```text
APP_DESCRIPTION: An Electron desktop app for wedding and event photographers to cull shoots fast: side-by-side RAW preview with focus-peaking overlay, keyboard rating flow, duplicate-burst grouping, and export of picks as an XMP-rated set for Lightroom.
TECH_STACK: Electron + libraw bindings + worker-thread thumbnail pipeline + SQLite catalog + XMP writer
APP_TYPE: desktop
LANGUAGE: JavaScript (Node.js)
SCALE: 14,000 photographers, shoots up to 8,000 RAW frames, ~60 GB scratch per session
```

## 61. MeterMate — utility meter reading

```text
APP_DESCRIPTION: A mobile app for municipal water and gas utility field readers. Routes load as ordered walk lists, readers key or photograph register values with anomaly checks against prior reads, and completed routes sync to the billing system.
TECH_STACK: Ionic + Capacitor + offline SQLite + Node.js/Express sync API + PostgreSQL, API on gov-cloud VPS
APP_TYPE: mobile
LANGUAGE: JavaScript (Node.js)
SCALE: 38 utilities, 640 readers, ~85,000 reads/day, ~1.5 GB/day sync
```

## 62. TrailTag — trail maintenance reporting

```text
APP_DESCRIPTION: A mobile app for park rangers and volunteer trail crews to report trail damage — downed trees, washouts, broken bridges — with GPS pins and photos, claim work orders, and log completed maintenance for grant reporting.
TECH_STACK: React Native + offline queue + Node.js/Fastify API + PostGIS + S3 photos, API on AWS
APP_TYPE: mobile
LANGUAGE: JavaScript (Node.js)
SCALE: 120 park systems, 9,000 reporters, ~1,400 reports/week, ~45 GB photos
```

## 63. FareStream — transit fare transaction pipeline

```text
APP_DESCRIPTION: A data pipeline for regional transit agencies that ingests tap events from bus and rail fare validators, applies fare-capping and transfer rules, settles daily totals per rider account, and feeds ridership dashboards for service planners.
TECH_STACK: Node.js consumers + Kafka + PostgreSQL + Redis fare-rule cache + nightly settlement jobs, deployed on Azure
APP_TYPE: data pipeline
LANGUAGE: JavaScript (Node.js)
SCALE: 1.4M tap events/day, ~350 events/sec peak, 3 agencies, 2-year retention
```

## 64. ClickSluice — ad click fraud filter

```text
APP_DESCRIPTION: A data pipeline for performance-marketing agencies that scores incoming ad click events for fraud — datacenter IPs, click-flood patterns, impossible geo jumps — quarantines suspect traffic before conversion attribution, and produces refund-claim evidence reports per campaign.
TECH_STACK: Node.js stream processors + Redis + ClickHouse + IP intelligence feeds + BullMQ, deployed on Hetzner
APP_TYPE: data pipeline
LANGUAGE: JavaScript (Node.js)
SCALE: 9,000 clicks/sec peak, ~60 GB/day events, 45 agencies, 13-month retention
```

## 65. FeedMill — news feed dedup pipeline

```text
APP_DESCRIPTION: A data pipeline for media-monitoring firms that polls thousands of RSS feeds and news sitemaps, extracts article text, clusters near-duplicate syndicated stories, tags entities and topics, and delivers deduplicated story clusters to client alerting rules.
TECH_STACK: Node.js workers + BullMQ + Redis + PostgreSQL + MinHash clustering + Readability extraction, deployed on GCP
APP_TYPE: data pipeline
LANGUAGE: JavaScript (Node.js)
SCALE: 22,000 feeds polled, ~180,000 articles/day, ~12 GB/day text, 90-day hot storage
```

## 66. AssayFlow — clinical lab results routing

```text
APP_DESCRIPTION: A data pipeline for regional clinical laboratories that receives analyzer results via HL7, validates them against reference ranges and delta checks, flags critical values for immediate phone-notification workflows, and routes finalized results to ordering providers' EHR interfaces.
TECH_STACK: Node.js + HL7 v2 parsing + RabbitMQ + PostgreSQL + audit log store, deployed on-premise with HA pair
APP_TYPE: data pipeline
LANGUAGE: JavaScript (Node.js)
SCALE: 95,000 results/day across 4 labs, ~40 msg/sec peak, 7-year audit retention
```

## 67. PingFleet — delivery van telematics

```text
APP_DESCRIPTION: A data pipeline for last-mile delivery operators that ingests GPS pings and ignition/door-sensor events from van trackers, snaps traces to road networks, computes stop dwell times and idle waste, and emits geofence arrival events to customer-notification systems.
TECH_STACK: Node.js consumers + MQTT + Kafka + PostGIS map-matching + TimescaleDB, deployed on AWS
APP_TYPE: data pipeline
LANGUAGE: JavaScript (Node.js)
SCALE: 5,200 vans, 900 pings/sec, ~10 GB/day, 6-month retention
```

## 68. FenceRay — geofence event service

```text
APP_DESCRIPTION: An API service for field-service software vendors that manages geofences around job sites and fires enter/exit events from technician location updates, powering auto clock-in, arrival ETAs, and mileage segmentation.
TECH_STACK: Fastify + Redis geo indexes + PostgreSQL + webhook delivery with retries, deployed on Fly.io multi-region
APP_TYPE: API service
LANGUAGE: JavaScript (Node.js)
SCALE: ~2,000 location updates/sec, 70,000 active geofences, 55 vendor tenants
```

## 69. LevyLine — sales tax rate lookup

```text
APP_DESCRIPTION: An API service that returns sales tax rates and taxability rules for a given address and product category across US state and local jurisdictions, with rooftop-level jurisdiction resolution and monthly rate-change feeds for e-commerce platforms.
TECH_STACK: Fastify + PostGIS jurisdiction boundaries + PostgreSQL rate tables + Redis cache, deployed on AWS
APP_TYPE: API service
LANGUAGE: JavaScript (Node.js)
SCALE: ~1,100 req/sec, 11,000 tax jurisdictions, 400 platform customers
```

## 70. SignSeal — e-signature workflow API

```text
APP_DESCRIPTION: An API service for SaaS products that need embedded document signing: upload a PDF, place signature and date fields, route to signers in order, and receive completion webhooks with a tamper-evident audit certificate.
TECH_STACK: Express + PostgreSQL + S3 + pdf-lib field stamping + signed audit hash chain, deployed on AWS
APP_TYPE: API service
LANGUAGE: JavaScript (Node.js)
SCALE: 85,000 envelopes/month, ~45 req/sec, ~900 GB document storage
```

## 71. MenuMorph — menu syndication API

```text
APP_DESCRIPTION: An API service for restaurant groups that keeps one canonical menu and syndicates it to delivery marketplaces, Google Business profiles, and in-store kiosks — translating modifiers, 86ing items in real time, and reconciling per-channel price markups.
TECH_STACK: Fastify + PostgreSQL + BullMQ + DoorDash/UberEats/Grubhub connectors + Redis, deployed on GCP Cloud Run
APP_TYPE: API service
LANGUAGE: JavaScript (Node.js)
SCALE: 3,800 restaurant locations, ~140 req/sec, 95,000 menu items synced
```

## 72. VinVerity — VIN decode and history

```text
APP_DESCRIPTION: An API service for dealer software and insurers that decodes VINs to build/trim/options, aggregates title brands, odometer records, and recall status from data providers, and returns a normalized vehicle profile with confidence scores.
TECH_STACK: Express + PostgreSQL + provider aggregation layer + Redis cache + rate-limited API keys, deployed on AWS
APP_TYPE: API service
LANGUAGE: JavaScript (Node.js)
SCALE: ~600 req/sec, 240 integrator customers, 180M vehicle records indexed
```

## 73. SporeCast — pollen and air quality forecast

```text
APP_DESCRIPTION: An API service delivering hyperlocal pollen, mold spore, and air quality forecasts for allergy and wellness apps. Blends monitoring-station data with weather models into a per-coordinate daily index and severity push triggers.
TECH_STACK: Fastify + TimescaleDB + weather model ingestion jobs + Redis tile cache, deployed on GCP
APP_TYPE: API service
LANGUAGE: JavaScript (Node.js)
SCALE: ~800 req/sec, 60 app customers, 14M forecast tiles refreshed daily
```

## 74. RateRoost — short-term rental pricing

```text
APP_DESCRIPTION: An API service for vacation-rental hosts and property managers that suggests nightly prices from comparable listings, seasonality, local events, and booking-pace signals, and pushes accepted prices to Airbnb and Vrbo calendars.
TECH_STACK: Express + PostgreSQL + nightly comp-analysis jobs + channel-manager APIs + Redis, deployed on AWS
APP_TYPE: API service
LANGUAGE: JavaScript (Node.js)
SCALE: 92,000 listings priced nightly, ~75 req/sec, ~35 GB comp data
```

## 75. VouchGate — reference verification API

```text
APP_DESCRIPTION: An API service for property managers and staffing agencies that automates tenant and employment reference checks: sends structured questionnaires to landlords and employers, verifies responder identity, and returns scored verification reports.
TECH_STACK: Fastify + PostgreSQL + BullMQ + SendGrid/Twilio outreach + document upload to S3, deployed on Render
APP_TYPE: API service
LANGUAGE: JavaScript (Node.js)
SCALE: 42,000 verifications/month, ~20 req/sec, 1,300 customer accounts
```

## 76. EmberCount — shipping emissions estimates

```text
APP_DESCRIPTION: An API service that calculates carbon emissions per shipment for e-commerce and 3PL platforms using distance, mode, carrier fleet factors, and packaging weight, returning per-order CO2e figures and aggregated ESG reporting exports.
TECH_STACK: Express + PostgreSQL emission-factor tables + geodistance routing + Redis cache, deployed on Fly.io
APP_TYPE: API service
LANGUAGE: JavaScript (Node.js)
SCALE: ~320 req/sec, 8M shipments scored/month, 150 platform customers
```

## 77. CurbTicket — parking session and enforcement

```text
APP_DESCRIPTION: An API service for city parking operators that manages pay-by-plate parking sessions, answers enforcement officers' plate-check queries in real time, and issues digital citations with photo evidence and appeal-window tracking.
TECH_STACK: Fastify + PostgreSQL + Redis session cache + payment gateway integration + S3 evidence storage, deployed on Azure
APP_TYPE: API service
LANGUAGE: JavaScript (Node.js)
SCALE: 190,000 sessions/day, ~450 plate checks/sec peak, 26 city deployments
```

## 78. GrainTape — commodity price feed

```text
APP_DESCRIPTION: An API service for grain elevators and farm co-ops that publishes local cash bids and basis against futures, streams intraday bid changes to farmer-facing apps, and archives historical basis curves for marketing-decision tools.
TECH_STACK: Express + WebSocket streams + PostgreSQL + futures feed ingestion + Redis pub/sub, deployed on AWS
APP_TYPE: API service
LANGUAGE: JavaScript (Node.js)
SCALE: 1,900 elevator locations, ~55,000 bid updates/day, 12,000 streaming subscribers
```

## 79. FoiaFlow — public records request tracking

```text
APP_DESCRIPTION: An API service for state and county agencies that manages public records (FOIA) requests: intake with statutory-clock computation, redaction task assignment, fee estimates, and requester status portals fed by webhook events.
TECH_STACK: Fastify + PostgreSQL + BullMQ deadline jobs + S3 document storage + audit logging, deployed on gov-cloud AWS
APP_TYPE: API service
LANGUAGE: JavaScript (Node.js)
SCALE: 31 agencies, ~48,000 requests/year, ~12 req/sec, ~350 GB records storage
```

## 80. TollTally — toll transaction reconciliation

```text
APP_DESCRIPTION: An API service for commercial fleet managers that aggregates toll transactions from multiple tolling authorities and transponder programs, matches charges to vehicles and trips, disputes duplicates and misreads, and produces per-customer rebilling files.
TECH_STACK: Express + PostgreSQL + authority file/API ingestion + BullMQ matching jobs, deployed on AWS
APP_TYPE: API service
LANGUAGE: JavaScript (Node.js)
SCALE: 2.2M toll transactions/month, 68,000 fleet vehicles, ~30 req/sec
```

## 81. WarrantyWell — appliance warranty claims

```text
APP_DESCRIPTION: An API service for appliance manufacturers that handles warranty registration, entitlement checks by serial number, service-claim submission from repair networks, and parts-reimbursement adjudication against coverage rules.
TECH_STACK: Fastify + PostgreSQL + serial-range entitlement engine + servicer portal webhooks, deployed on Azure
APP_TYPE: API service
LANGUAGE: JavaScript (Node.js)
SCALE: 14M registered units, ~90 req/sec, 41,000 claims/month, 9 manufacturer tenants
```

## 82. ClipRights — stock footage licensing

```text
APP_DESCRIPTION: An API service for stock footage marketplaces that manages clip licensing: license-type catalogs, usage-rights checks per territory and medium, watermarked preview delivery, and signed download URLs issued after purchase with royalty splits to contributors.
TECH_STACK: Express + PostgreSQL + S3 + CloudFront signed URLs + Stripe Connect royalty payouts, deployed on AWS
APP_TYPE: API service
LANGUAGE: JavaScript (Node.js)
SCALE: 3.5M clips, ~110 req/sec, 28,000 licenses/month, ~150 TB media referenced
```

## 83. GridNudge — demand response dispatch

```text
APP_DESCRIPTION: An API service for electric utilities running demand-response programs: enrolls smart thermostats and EV chargers, dispatches curtailment events to device-vendor clouds, verifies load reduction from meter interval data, and computes participant credits.
TECH_STACK: Fastify + PostgreSQL + vendor cloud APIs (OpenADR) + TimescaleDB interval data + BullMQ, deployed on AWS
APP_TYPE: API service
LANGUAGE: JavaScript (Node.js)
SCALE: 310,000 enrolled devices, ~200 req/sec during events, 45 dispatch events/season
```

## 84. ChoreOrbit — family chore and allowance tracker

```text
APP_DESCRIPTION: A web app for families that turns chores into rotating assignments with point values, tracks completion streaks per kid, and converts points into allowance payouts parents approve weekly, with a shared fridge-tablet dashboard view.
TECH_STACK: Fastify + React (Vite) + PostgreSQL + Redis + PWA push reminders, deployed on Railway
APP_TYPE: web app
LANGUAGE: JavaScript (Node.js)
SCALE: 60,000 families, ~40 req/sec evening peak, ~4 GB data
```

## 85. TableVow — wedding seating planner

```text
APP_DESCRIPTION: A web app for engaged couples and wedding planners to manage guest lists, RSVPs with meal choices, and drag-and-drop seating charts that enforce keep-apart and seat-together rules, exporting place cards and caterer counts.
TECH_STACK: Express + React (Vite) + PostgreSQL + drag-and-drop canvas + PDF export, deployed on Render
APP_TYPE: web app
LANGUAGE: JavaScript (Node.js)
SCALE: 45,000 active weddings/season, ~55 req/sec, ~6 GB data
```

## 86. KilnQueue — pottery studio kiln scheduler

```text
APP_DESCRIPTION: A web app for community pottery studios to schedule kiln firings: members tag pieces to bisque or glaze loads, techs plan shelf layouts by piece height, log cone results per firing, and bill members by shelf-inch used.
TECH_STACK: Express + EJS templates + PostgreSQL + Stripe metered billing, deployed on DigitalOcean
APP_TYPE: web app
LANGUAGE: JavaScript (Node.js)
SCALE: 220 studios, 17,000 members, ~12 req/sec, ~2 GB data
```

## 87. CombKeeper — apiary management

```text
APP_DESCRIPTION: A web app for beekeepers managing multiple apiaries: hive inspection logs (queen status, brood pattern, mite counts), treatment schedules with withdrawal periods before honey harvest, and yard-level maps of hive health trends.
TECH_STACK: Fastify + Vue (Vite) + PostgreSQL + Leaflet yard maps + reminder emails, deployed on Fly.io
APP_TYPE: web app
LANGUAGE: JavaScript (Node.js)
SCALE: 9,500 beekeepers, 130,000 hives tracked, ~10 req/sec, ~3 GB data
```

## 88. TutorLoft — tutoring scheduling and billing

```text
APP_DESCRIPTION: A web app for independent tutors and small tutoring centers to schedule recurring sessions, share lesson notes and homework with parents, track package hours, and auto-invoice with late-cancellation fee rules.
TECH_STACK: Express + React (Vite) + PostgreSQL + Stripe + Google Calendar sync, deployed on Heroku
APP_TYPE: web app
LANGUAGE: JavaScript (Node.js)
SCALE: 4,200 tutors, 58,000 students, ~26 req/sec, ~5 GB data
```

## 89. CaddyBook — golf tee time booking

```text
APP_DESCRIPTION: A web app for public golf courses to sell tee times: dynamic pricing by daypart and weather outlook, foursome-fill matching for solo players, cart and rental add-ons, and pro-shop check-in with pace-of-play tracking.
TECH_STACK: Fastify + React (Vite) + PostgreSQL + Redis + Stripe + weather API, deployed on AWS
APP_TYPE: web app
LANGUAGE: JavaScript (Node.js)
SCALE: 310 courses, ~68,000 rounds booked/week, ~120 req/sec Saturday peak, ~9 GB data
```

## 90. RescueRoster — animal rescue foster coordination

```text
APP_DESCRIPTION: A web app for animal rescue organizations to coordinate foster homes: intake records with medical needs, foster matching by household constraints (fenced yard, no cats), supply reimbursement tracking, and adoption-event scheduling.
TECH_STACK: Express + Pug templates + PostgreSQL + S3 for animal photos + SendGrid, deployed on Render
APP_TYPE: web app
LANGUAGE: JavaScript (Node.js)
SCALE: 480 rescues, 21,000 active fosters, ~15 req/sec, ~25 GB photos
```

## 91. PlowPilot — snow removal dispatch

```text
APP_DESCRIPTION: A web app for residential snow removal contractors that opens dispatch when snowfall thresholds trigger, sequences driveways into plow routes by truck, lets crews mark completions with timestamped photos, and bills per-push or seasonal contracts.
TECH_STACK: Express + React (Vite) + PostgreSQL + weather trigger jobs + Twilio crew alerts + Stripe, deployed on DigitalOcean
APP_TYPE: web app
LANGUAGE: JavaScript (Node.js)
SCALE: 260 contractors, 48,000 properties, ~200 req/sec during storm events, ~30 GB photos
```

## 92. MashMeter — craft brewery batch tracking

```text
APP_DESCRIPTION: A web app for craft breweries to track batches from grain to keg: recipes with mash schedules, fermentation readings against target curves, packaging runs with lot codes, and TTB-ready production and loss reporting.
TECH_STACK: Fastify + Vue (Vite) + PostgreSQL + Tilt hydrometer Bluetooth-bridge ingestion, deployed on Fly.io
APP_TYPE: web app
LANGUAGE: JavaScript (Node.js)
SCALE: 540 breweries, ~38,000 batches/year, ~18 req/sec, ~4 GB data
```

## 93. BoothBloom — farmers market vendor booking

```text
APP_DESCRIPTION: A web app for farmers market operators to manage vendor applications, assign booth spaces on a market map, collect stall fees, track seasonal attendance and product-category balance, and message vendors about weather calls.
TECH_STACK: Express + EJS templates + PostgreSQL + Stripe + SVG market maps + Twilio, deployed on Render
APP_TYPE: web app
LANGUAGE: JavaScript (Node.js)
SCALE: 190 markets, 12,500 vendors, ~9 req/sec, ~2 GB data
```

## 94. VisitVine — home health visit scheduling

```text
APP_DESCRIPTION: A web app for home health agencies that schedules nurse and aide visits against care plans, optimizes daily routes per clinician, verifies visits with GPS check-in for EVV compliance, and exports visit records to state Medicaid aggregators.
TECH_STACK: Fastify + React (Vite) + PostgreSQL + route optimization jobs + EVV aggregator APIs, deployed on HIPAA-eligible AWS
APP_TYPE: web app
LANGUAGE: JavaScript (Node.js)
SCALE: 75 agencies, 8,400 clinicians, ~52,000 visits/week, ~60 req/sec
```

## 95. SceneScout — film location scouting

```text
APP_DESCRIPTION: A web app for film and commercial production companies to scout locations: scouts upload tagged photo sets with sun-path and parking notes, producers shortlist and compare options side by side, and permit applications track per jurisdiction.
TECH_STACK: Express + React (Vite) + PostgreSQL + S3 + Mapbox + PDF permit packets, deployed on AWS
APP_TYPE: web app
LANGUAGE: JavaScript (Node.js)
SCALE: 130 production companies, 85,000 location records, ~22 req/sec, ~400 GB photos
```

## 96. BenchBooker — makerspace equipment reservations

```text
APP_DESCRIPTION: A web app for makerspaces to manage equipment reservations for laser cutters, CNC routers, and 3D printers, gating bookings behind completed safety certifications, tracking machine hours for maintenance, and billing material usage.
TECH_STACK: Fastify + Vue (Vite) + PostgreSQL + Redis + Stripe + badge-reader check-in webhook, deployed on Railway
APP_TYPE: web app
LANGUAGE: JavaScript (Node.js)
SCALE: 175 makerspaces, 42,000 members, ~16 req/sec, ~3 GB data
```

## 97. SirenShift — volunteer fire department scheduling

```text
APP_DESCRIPTION: A web app for volunteer fire departments to manage duty-crew shift signups, track certification expirations (EMT, pump operator), log training hours toward state requirements, and record apparatus checks with defect flags.
TECH_STACK: Express + Handlebars templates + PostgreSQL + SMS shift reminders via Twilio, deployed on a county VPS
APP_TYPE: web app
LANGUAGE: JavaScript (Node.js)
SCALE: 340 departments, 15,000 volunteers, ~8 req/sec, ~2 GB data
```

## 98. CampClutch — campground reservations

```text
APP_DESCRIPTION: A web app for private campgrounds and RV parks to sell site reservations: interactive site maps with rig-length and hookup filters, seasonal-guest contracts, gate-code issuance on check-in, and occupancy pacing reports for owners.
TECH_STACK: Express + React (Vite) + PostgreSQL + Redis + Stripe + SVG site maps, deployed on AWS Lightsail
APP_TYPE: web app
LANGUAGE: JavaScript (Node.js)
SCALE: 290 campgrounds, 31,000 sites, ~85 req/sec holiday-weekend peak, ~6 GB data
```

## 99. DuesDeck — HOA dues and violations portal

```text
APP_DESCRIPTION: A web app for homeowner association management companies covering dues invoicing and autopay, architectural request review workflows, violation notices with photo evidence and cure deadlines, and board vote recording per community.
TECH_STACK: Fastify + React (Vite) + PostgreSQL + Stripe ACH + S3 + document e-delivery, deployed on Azure
APP_TYPE: web app
LANGUAGE: JavaScript (Node.js)
SCALE: 95 management companies, 2,100 communities, 380,000 homes, ~70 req/sec
```

## 100. SpecSentry — factory quality inspection checklists

```text
APP_DESCRIPTION: A web app for manufacturing quality teams to run in-process and final inspection checklists: measurement entries validated against spec tolerances, photo evidence per defect, automatic nonconformance reports with disposition workflow, and first-pass-yield dashboards per line.
TECH_STACK: Express + Vue (Vite) + PostgreSQL + S3 + tablet-friendly PWA + CSV export to QMS, deployed on plant-adjacent AWS
APP_TYPE: web app
LANGUAGE: JavaScript (Node.js)
SCALE: 60 plants, ~24,000 inspections/day, ~45 req/sec, ~150 GB evidence photos
```
