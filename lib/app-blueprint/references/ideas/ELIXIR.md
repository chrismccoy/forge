# Elixir Blueprint Types — Copy-Paste Input Sets

Copy a fenced block into the prompt as-is, or swap individual fields.

## 1. PulseBoard — real-time ops dashboard

```text
APP_DESCRIPTION: A live operations dashboard for SaaS teams that streams service health, deploy events, and business KPIs to a shared wallboard. Metrics arrive over Phoenix Channels and update in place without page reloads, and each team can pin custom tiles and alert thresholds. On-call engineers see incident state change the instant it happens.
TECH_STACK: Phoenix LiveView + Phoenix PubSub + Ecto + PostgreSQL + Telemetry, deployed on Fly.io
APP_TYPE: web app
LANGUAGE: Elixir
SCALE: 8,000 concurrent dashboards, ~120k metric updates/sec fan-out
```

## 2. LedgerLoom — double-entry fintech ledger

```text
APP_DESCRIPTION: An API service that provides an immutable double-entry ledger for fintech products. It records balanced journal entries, enforces account invariants inside database transactions, and exposes balance and statement queries. Every posting is idempotent so retried payment webhooks never double-count.
TECH_STACK: Elixir + Phoenix API + Ecto + PostgreSQL (serializable transactions) + Oban for async settlement, deployed on Gigalixir
APP_TYPE: API service
LANGUAGE: Elixir
SCALE: ~3,500 postings/sec, 2M accounts, strict consistency
```

## 3. HiveTelemetry — IoT sensor ingest pipeline

```text
APP_DESCRIPTION: A data pipeline that ingests telemetry from beehive monitoring devices measuring weight, temperature, humidity, and acoustic activity. It decodes MQTT payloads, batches readings, computes rolling health scores per hive, and writes time-series records for beekeeper dashboards. Anomalous swarm signatures raise alerts.
TECH_STACK: Elixir + Broadway + MQTT source + GenStage + TimescaleDB, mix releases on AWS ECS
APP_TYPE: data pipeline
LANGUAGE: Elixir
SCALE: 40,000 devices at 1 reading/10s (~4k msgs/sec), ~30 GB/month
```

## 4. QuillDesk — collaborative help-desk console

```text
APP_DESCRIPTION: A live help-desk console where support agents work a shared queue of customer conversations. Ticket assignment, typing indicators, and canned-reply insertion sync across every agent's browser in real time, and supervisors watch queue depth and SLA timers update continuously. Presence shows who is viewing which ticket.
TECH_STACK: Phoenix LiveView + Phoenix Presence + Phoenix PubSub + Ecto + PostgreSQL, deployed on Fly.io
APP_TYPE: web app
LANGUAGE: Elixir
SCALE: 1,500 concurrent agents, 25k open tickets, sub-100ms sync
```

## 5. StreamForge — clickstream ETL platform

```text
APP_DESCRIPTION: A streaming ETL platform that consumes raw web clickstream events from Kafka, enriches them with session and geo lookups, filters bots, and lands cleaned events into a warehouse. Each stage backpressures independently so spikes never overwhelm downstream sinks. Late-arriving events are windowed and reconciled.
TECH_STACK: Elixir + Broadway + broadway_kafka + Flow + Redis (session cache) + ClickHouse sink, mix releases on Kubernetes
APP_TYPE: data pipeline
LANGUAGE: Elixir
SCALE: ~250k events/sec sustained, 12 partitions, TB/day
```

## 6. Roomly — multiplayer whiteboard

```text
APP_DESCRIPTION: A real-time multiplayer whiteboard for remote design workshops. Participants draw shapes, drag sticky notes, and see one another's cursors move live, with per-room state kept in a supervised process. Rooms survive brief disconnects and replay recent operations to reconnecting clients.
TECH_STACK: Phoenix LiveView + Phoenix Channels + GenServer per room + Ecto + PostgreSQL (snapshots), deployed on Fly.io
APP_TYPE: web app
LANGUAGE: Elixir
SCALE: 5,000 active rooms, 20 users/room, ~60 ops/sec/room
```

## 7. CartWeaver — marketplace order API

```text
APP_DESCRIPTION: An API service powering a multi-vendor marketplace checkout. It validates carts across vendors, reserves inventory, splits orders per seller, and orchestrates payment capture with compensating rollbacks on failure. Each vendor receives a normalized order-fulfillment webhook.
TECH_STACK: Elixir + Phoenix API + Absinthe (GraphQL) + Ecto + PostgreSQL + Oban (saga steps), deployed on Gigalixir
APP_TYPE: API service
LANGUAGE: Elixir
SCALE: ~2,000 checkouts/min peak, 900 vendors, 40 GB catalog
```

## 8. VitalStream — hospital vitals event system

```text
APP_DESCRIPTION: A healthcare event system that consumes bedside monitor vitals and lab result feeds, normalizes them against patient records, and drives early-warning score calculation. Clinicians see deteriorating patients flagged in real time, and every event is retained for audit. HL7 and FHIR messages are parsed on ingest.
TECH_STACK: Elixir + Broadway + GenStage + Ecto + PostgreSQL + Phoenix PubSub (alert fan-out), mix releases on AWS EKS
APP_TYPE: data pipeline
LANGUAGE: Elixir
SCALE: 60 hospitals, ~18k beds, 90k vitals events/sec
```

## 9. Standuply — async team standup app

```text
APP_DESCRIPTION: A web app for distributed teams to run async daily standups. Members post blockers and progress, threads update live for everyone watching, and a scheduled bot compiles a digest each morning. Managers browse historical standups and surface recurring blockers.
TECH_STACK: Phoenix LiveView + Ecto + PostgreSQL + Oban (scheduled digests) + Swoosh email, deployed on Fly.io
APP_TYPE: web app
LANGUAGE: Elixir
SCALE: 4,000 teams, 30k daily posts, morning digest bursts
```

## 10. RouteCast — fleet GPS tracking pipeline

```text
APP_DESCRIPTION: A data pipeline for logistics fleets that ingests GPS pings from delivery vehicles, snaps positions to roads, computes ETAs against planned routes, and detects idle and off-route events. Dispatchers get continuous position updates and exception alerts. Historical traces feed route optimization.
TECH_STACK: Elixir + Broadway + GenStage + Redis (live positions) + PostgreSQL/PostGIS, mix releases on GCP GKE
APP_TYPE: data pipeline
LANGUAGE: Elixir
SCALE: 25,000 vehicles at 1 ping/2s (~12k msgs/sec), 5 GB/day
```

## 11. Chatterbox — scalable team chat backend

```text
APP_DESCRIPTION: An API and realtime backend for a team chat product. It handles channel membership, message delivery, read receipts, and typing state, distributing fan-out across a clustered node topology. Messages are durably stored and delivered in order per channel.
TECH_STACK: Elixir + Phoenix Channels + Phoenix PubSub (PG2 clustering) + Ecto + PostgreSQL + Redis, deployed on Kubernetes
APP_TYPE: API service
LANGUAGE: Elixir
SCALE: 200,000 concurrent sockets, 3 nodes, ~40k msgs/sec
```

## 12. GridSense — smart-meter reading pipeline

```text
APP_DESCRIPTION: A data pipeline for a utility that ingests smart electricity meter readings, validates interval data, estimates gaps, and aggregates consumption per account and feeder. Billing and demand-response systems consume the cleaned aggregates. Tamper and outage signatures raise operational events.
TECH_STACK: Elixir + Broadway + broadway_kafka + Flow + TimescaleDB, mix releases on AWS EKS
APP_TYPE: data pipeline
LANGUAGE: Elixir
SCALE: 3M meters, 15-min intervals (~50k readings/sec), TB/month
```

## 13. Tourneo — live tournament brackets

```text
APP_DESCRIPTION: A web app for running live esports and sports tournaments. Organizers seed brackets, report match results, and spectators watch standings and next-match schedules update instantly. Presence tracks which matches have both players checked in.
TECH_STACK: Phoenix LiveView + Phoenix Presence + Ecto + PostgreSQL, deployed on Fly.io
APP_TYPE: web app
LANGUAGE: Elixir
SCALE: 3,000 concurrent tournaments, 50k spectators, live updates
```

## 14. Postmark — transactional email API

```text
APP_DESCRIPTION: An API service that accepts transactional email requests, renders templates, queues delivery with per-tenant rate limits, and tracks opens, clicks, bounces, and complaints. Webhooks report delivery events back to senders, and suppression lists are enforced automatically.
TECH_STACK: Elixir + Phoenix API + Oban (delivery queue) + Ecto + PostgreSQL + Tesla (SMTP/provider APIs), deployed on Gigalixir
APP_TYPE: API service
LANGUAGE: Elixir
SCALE: ~5,000 emails/sec, 10k tenants, per-tenant throttling
```

## 15. Nudge — multi-channel notification service

```text
APP_DESCRIPTION: An API service that delivers notifications across push, SMS, email, and in-app channels with user preference and quiet-hours resolution. It deduplicates, batches digests, and falls back across channels on delivery failure. Delivery status is exposed per notification.
TECH_STACK: Elixir + Phoenix API + Broadway (channel workers) + Oban + Ecto + PostgreSQL + Redis, deployed on Fly.io
APP_TYPE: API service
LANGUAGE: Elixir
SCALE: ~30k notifications/sec peak, 8M users, 4 channels
```

## 16. Cronica — distributed job scheduler platform

```text
APP_DESCRIPTION: A web app and backend for scheduling and monitoring background jobs across many services. Teams define cron and event-triggered jobs, watch runs stream live, and retry or cancel from a LiveView console. Failures alert owners and expose full run history.
TECH_STACK: Phoenix LiveView + Oban + Oban Web + Ecto + PostgreSQL, deployed on Gigalixir
APP_TYPE: web app
LANGUAGE: Elixir
SCALE: 50k scheduled jobs, ~1,500 runs/min, live run streams
```

## 17. Bidly — live auction platform

```text
APP_DESCRIPTION: A web app for timed online auctions where bidders compete in real time. Bids broadcast to all watchers instantly, anti-snipe rules extend closing times, and each lot's state lives in a supervised process. Outbid notifications reach users within milliseconds.
TECH_STACK: Phoenix LiveView + Phoenix PubSub + GenServer per lot + Ecto + PostgreSQL, deployed on Fly.io
APP_TYPE: web app
LANGUAGE: Elixir
SCALE: 10,000 concurrent bidders, 2k live lots, ~5k bids/sec peak
```

## 18. FeedFusion — social feed fan-out API

```text
APP_DESCRIPTION: An API service that builds personalized activity feeds for a social product. It fans out posts to follower timelines, merges ranked sources, and serves paginated feeds with low latency. Hot accounts use a pull model while ordinary accounts use push fan-out.
TECH_STACK: Elixir + Phoenix API + GenStage + Redis (timelines) + Ecto + PostgreSQL, deployed on Kubernetes
APP_TYPE: API service
LANGUAGE: Elixir
SCALE: 12M users, ~40k feed reads/sec, hybrid fan-out
```

## 19. Metricly — usage metering & billing engine

```text
APP_DESCRIPTION: A data pipeline that meters product usage events, aggregates them into billable quantities per customer and plan, and emits invoice line items. It handles late events, tier boundaries, and credits, and reconciles totals nightly. Aggregates power live usage dashboards.
TECH_STACK: Elixir + Broadway + Flow + Ecto + PostgreSQL + Oban (invoice rollups), mix releases on Fly.io
APP_TYPE: data pipeline
LANGUAGE: Elixir
SCALE: ~80k usage events/sec, 30k customers, hourly rollups
```

## 20. Signalway — webhook delivery gateway

```text
APP_DESCRIPTION: An API service that reliably delivers outbound webhooks for a platform. It signs payloads, retries with exponential backoff, respects per-endpoint concurrency, and circuit-breaks failing destinations. Customers replay and inspect delivery attempts through the API.
TECH_STACK: Elixir + Phoenix API + Oban (delivery + retry) + Tesla + Ecto + PostgreSQL + Redis, deployed on Gigalixir
APP_TYPE: API service
LANGUAGE: Elixir
SCALE: ~20k webhooks/sec, 60k endpoints, at-least-once delivery
```

## 21. Coursepad — live cohort learning platform

```text
APP_DESCRIPTION: A web app for cohort-based courses where instructors run live lessons with polls, Q&A, and shared progress. Students submit answers that tally on screen instantly, and breakout groups get isolated channels. Recordings and transcripts attach to each session afterward.
TECH_STACK: Phoenix LiveView + Phoenix Channels + Phoenix Presence + Ecto + PostgreSQL, deployed on Fly.io
APP_TYPE: web app
LANGUAGE: Elixir
SCALE: 500 live cohorts, 300 students each, real-time polling
```

## 22. Depotly — warehouse inventory admin

```text
APP_DESCRIPTION: A LiveView admin tool for warehouse inventory. Staff scan items, adjust stock, and process transfers while quantities and low-stock flags update live across every terminal. Cycle-count sessions lock bins and reconcile discrepancies with an audit trail.
TECH_STACK: Phoenix LiveView + Ecto + PostgreSQL + Phoenix PubSub, deployed on Gigalixir
APP_TYPE: web app
LANGUAGE: Elixir
SCALE: 40 warehouses, 800 concurrent terminals, 1M SKUs
```

## 23. Tickr — market data streaming API

```text
APP_DESCRIPTION: An API service that streams normalized market quotes and trades to trading clients over websockets. It subscribes to upstream feeds, throttles per-symbol, and delivers per-client subscriptions with conflated snapshots. Slow consumers are shed without stalling others.
TECH_STACK: Elixir + Phoenix Channels + GenStage + Redis + Ecto + PostgreSQL, deployed on Kubernetes
APP_TYPE: API service
LANGUAGE: Elixir
SCALE: 80,000 subscriptions, ~500k updates/sec upstream
```

## 24. Sentrylog — log ingestion & search pipeline

```text
APP_DESCRIPTION: A data pipeline that ingests application logs from many services, parses and structures them, extracts fields, and indexes for search. Backpressure protects the indexer during floods, and retention policies expire old data. Alert rules match streaming lines in real time.
TECH_STACK: Elixir + Broadway + broadway_kafka + Flow + Elasticsearch sink + Redis, mix releases on AWS EKS
APP_TYPE: data pipeline
LANGUAGE: Elixir
SCALE: ~300k log lines/sec, 500 services, 2 TB/day
```

## 25. Parcely — shipment tracking web app

```text
APP_DESCRIPTION: A web app that gives customers live shipment tracking across multiple carriers. Tracking pages update as carrier events arrive, showing map position and status changes without refresh. Users subscribe to delivery alerts by email and push.
TECH_STACK: Phoenix LiveView + Phoenix PubSub + Broadway (carrier ingest) + Ecto + PostgreSQL, deployed on Fly.io
APP_TYPE: web app
LANGUAGE: Elixir
SCALE: 2M active shipments, ~15k carrier events/sec, live pages
```

## 26. Quorum — realtime polling & voting API

```text
APP_DESCRIPTION: An API service that runs large-scale live polls and Q&A for events and broadcasts. It accepts votes at high concurrency, deduplicates per participant, and returns live tallies. Moderators approve and rank audience questions through the API.
TECH_STACK: Elixir + Phoenix API + Phoenix Channels + Redis (tallies) + Ecto + PostgreSQL, deployed on Gigalixir
APP_TYPE: API service
LANGUAGE: Elixir
SCALE: 1M voters per event, ~60k votes/sec bursts
```

## 27. Threadmill — forum & community platform

```text
APP_DESCRIPTION: A web app for large discussion communities with threaded posts, live reply notifications, reactions, and moderation queues. New replies and vote counts update in place, and presence shows who is reading a thread. Moderators act on reports from a live console.
TECH_STACK: Phoenix LiveView + Phoenix Presence + Ecto + PostgreSQL + Oban (notifications), deployed on Fly.io
APP_TYPE: web app
LANGUAGE: Elixir
SCALE: 800k members, 50k concurrent readers, live threads
```

## 28. Flowmeter — API rate-limiting gateway

```text
APP_DESCRIPTION: An API gateway service that enforces per-key rate limits, quotas, and burst policies in front of backend services. It uses distributed token buckets, returns standard limit headers, and exposes usage analytics. Policy changes take effect without redeploys.
TECH_STACK: Elixir + Bandit + Plug + Redis (token buckets) + Ecto + PostgreSQL, deployed on Kubernetes
APP_TYPE: API service
LANGUAGE: Elixir
SCALE: ~150k req/sec proxied, 40k API keys, sub-ms limiting
```

## 29. Cropcast — agriculture sensor pipeline

```text
APP_DESCRIPTION: A data pipeline for precision agriculture that ingests soil moisture, temperature, and weather-station readings from field devices. It calibrates readings, interpolates field maps, and computes irrigation recommendations. Growers receive threshold alerts and daily summaries.
TECH_STACK: Elixir + Nerves (edge gateways) + Broadway + GenStage + TimescaleDB, mix releases on AWS
APP_TYPE: data pipeline
LANGUAGE: Elixir
SCALE: 12,000 field sensors, 5-min intervals, ~1k msgs/sec
```

## 30. Slotly — appointment booking platform

```text
APP_DESCRIPTION: A web app for service businesses to manage appointment booking. Available slots update live as bookings land, double-booking is prevented with per-resource locking, and staff calendars sync in real time. Reminders go out automatically before appointments.
TECH_STACK: Phoenix LiveView + Ecto + PostgreSQL + Oban (reminders) + GenServer (slot locks), deployed on Gigalixir
APP_TYPE: web app
LANGUAGE: Elixir
SCALE: 20k businesses, 200k bookings/day, concurrent locking
```

## 31. Payloom — payment orchestration API

```text
APP_DESCRIPTION: An API service that routes payments across multiple processors, retries failed charges intelligently, and handles 3-D Secure and refund flows. It normalizes processor responses and stores an auditable transaction log. Smart routing picks the cheapest successful path.
TECH_STACK: Elixir + Phoenix API + Oban + Tesla (processor connectors) + Ecto + PostgreSQL, deployed on Gigalixir
APP_TYPE: API service
LANGUAGE: Elixir
SCALE: ~4,000 charges/sec, 6 processors, idempotent retries
```

## 32. Watchtower — uptime monitoring service

```text
APP_DESCRIPTION: A web app that monitors websites and APIs from multiple regions, running scheduled checks and streaming status to a live dashboard. Incidents open automatically when checks fail across regions, and status pages update in real time. On-call rotations get paged.
TECH_STACK: Phoenix LiveView + Oban (check scheduling) + Tesla + Ecto + PostgreSQL + Phoenix PubSub, deployed on Fly.io (multi-region)
APP_TYPE: web app
LANGUAGE: Elixir
SCALE: 60k monitors, 30s intervals (~2k checks/sec), live status
```

## 33. Draftly — collaborative document editor

```text
APP_DESCRIPTION: A web app for real-time collaborative document editing. Multiple authors edit the same document with operational transforms, seeing each other's cursors and selections live. Document state is held per-document in a supervised process and periodically snapshotted.
TECH_STACK: Phoenix LiveView + Phoenix Channels + GenServer per doc + Ecto + PostgreSQL, deployed on Fly.io
APP_TYPE: web app
LANGUAGE: Elixir
SCALE: 30k concurrent editors, 8k live documents, OT sync
```

## 34. Refyne — data enrichment pipeline

```text
APP_DESCRIPTION: A data pipeline that enriches inbound CRM lead records with firmographic, email-validation, and geo data from third-party APIs. It rate-limits per provider, caches lookups, and merges enriched attributes. Failed enrichments are retried and dead-lettered.
TECH_STACK: Elixir + Broadway + Tesla + Redis (cache) + Ecto + PostgreSQL, mix releases on Fly.io
APP_TYPE: data pipeline
LANGUAGE: Elixir
SCALE: ~10k records/sec, 5 enrichment providers, cached lookups
```

## 35. Cohortix — product analytics API

```text
APP_DESCRIPTION: An API service that captures product events and answers funnel, retention, and cohort queries. It ingests events at high volume, aggregates into time buckets, and serves fast segment queries. SDK clients send batched events over a compact endpoint.
TECH_STACK: Elixir + Phoenix API + Broadway + Flow + ClickHouse + Ecto + PostgreSQL, deployed on Kubernetes
APP_TYPE: API service
LANGUAGE: Elixir
SCALE: ~120k events/sec ingest, 8k projects, sub-second queries
```

## 36. Standby — incident on-call & paging app

```text
APP_DESCRIPTION: A web app for incident response and on-call management. Alerts route by schedule and escalation policy, responders acknowledge from a live timeline, and status updates broadcast to stakeholders. Postmortems assemble from the recorded event stream.
TECH_STACK: Phoenix LiveView + Oban (escalations) + Ecto + PostgreSQL + Phoenix PubSub + Tesla (SMS/voice), deployed on Fly.io
APP_TYPE: web app
LANGUAGE: Elixir
SCALE: 5k teams, 200k alerts/month, real-time escalation
```

## 37. Roostr — property rental marketplace

```text
APP_DESCRIPTION: A web app marketplace connecting short-term rental hosts and guests. Listings, availability, and instant-book slots update live, messaging between parties is real time, and hosts manage bookings from a LiveView dashboard. Search filters recompute results as guests refine them.
TECH_STACK: Phoenix LiveView + Ecto + PostgreSQL/PostGIS + Oban + Phoenix PubSub, deployed on Gigalixir
APP_TYPE: web app
LANGUAGE: Elixir
SCALE: 400k listings, 60k concurrent searchers, live messaging
```

## 38. Coinledge — crypto exchange matching engine

```text
APP_DESCRIPTION: An API service providing an order-matching engine for a crypto spot exchange. It maintains in-memory order books per pair, matches limit and market orders deterministically, and streams fills and book depth to clients. Each pair runs in an isolated process for fault isolation.
TECH_STACK: Elixir + GenServer per pair + Phoenix Channels + Ecto + PostgreSQL (settlement) + Redis, deployed on Kubernetes
APP_TYPE: API service
LANGUAGE: Elixir
SCALE: 300 trading pairs, ~50k orders/sec, live depth feeds
```

## 39. Batchmason — media transcoding pipeline

```text
APP_DESCRIPTION: A data pipeline that transcodes uploaded video into multiple renditions and packages HLS. It coordinates worker pools, tracks per-job progress, retries failed segments, and writes outputs to object storage. Upload completion triggers automatic profile selection.
TECH_STACK: Elixir + Broadway + Oban (job orchestration) + ffmpeg workers + S3 + Ecto + PostgreSQL, mix releases on AWS ECS
APP_TYPE: data pipeline
LANGUAGE: Elixir
SCALE: ~8,000 videos/hour, 5 renditions each, parallel workers
```

## 40. Presencely — live event presence backend

```text
APP_DESCRIPTION: An API and realtime backend that tracks who is online, where, and doing what across a product. It maintains distributed presence across nodes, exposes subscribe endpoints, and diffs presence changes efficiently. Reconnecting clients receive a compact presence snapshot.
TECH_STACK: Elixir + Phoenix Presence + Phoenix PubSub (clustering) + Redis + Ecto + PostgreSQL, deployed on Kubernetes
APP_TYPE: API service
LANGUAGE: Elixir
SCALE: 500,000 concurrent users, 4 nodes, live presence diffs
```

## 41. Gradebook — school grading LiveView admin

```text
APP_DESCRIPTION: A LiveView admin tool for teachers to enter grades, track attendance, and message parents. Class rosters and grade summaries update live, and cross-teacher changes to shared students reflect immediately. Report-card generation runs as a background job.
TECH_STACK: Phoenix LiveView + Ecto + PostgreSQL + Oban (report cards) + Phoenix PubSub, deployed on Gigalixir
APP_TYPE: web app
LANGUAGE: Elixir
SCALE: 3k schools, 40k concurrent teachers, live rosters
```

## 42. Feednix — RSS & content aggregation pipeline

```text
APP_DESCRIPTION: A data pipeline that polls thousands of RSS and Atom feeds, deduplicates articles, extracts full text, and classifies topics. It schedules polls adaptively by feed freshness and backpressures parsing. Cleaned articles flow to subscriber timelines.
TECH_STACK: Elixir + Broadway + Oban (adaptive polling) + Tesla + Ecto + PostgreSQL + Redis, mix releases on Fly.io
APP_TYPE: data pipeline
LANGUAGE: Elixir
SCALE: 200k feeds, adaptive polling, ~5k articles/min
```

## 43. Signd — e-signature workflow API

```text
APP_DESCRIPTION: An API service for e-signature workflows. It orchestrates signing order, tracks recipient status, sends reminders, and seals completed documents with an audit certificate. Webhooks notify integrators as each recipient acts.
TECH_STACK: Elixir + Phoenix API + Oban (reminders) + Ecto + PostgreSQL + S3, deployed on Gigalixir
APP_TYPE: API service
LANGUAGE: Elixir
SCALE: ~2,000 envelopes/min, 500k active signers, audit trails
```

## 44. Rallypoint — live sports scoreboard app

```text
APP_DESCRIPTION: A web app that broadcasts live scores, play-by-play, and stats for amateur leagues. Scorekeepers enter events on the field and fans watch scoreboards update instantly across devices. Standings and player stats recompute live as games conclude.
TECH_STACK: Phoenix LiveView + Phoenix PubSub + Ecto + PostgreSQL, deployed on Fly.io
APP_TYPE: web app
LANGUAGE: Elixir
SCALE: 10k concurrent games, 200k fans, real-time scores
```

## 45. Dispatchr — ride-hailing matching API

```text
APP_DESCRIPTION: An API service that matches ride requests to nearby drivers in real time. It tracks driver locations, runs geospatial matching, and coordinates offer-accept handshakes with timeouts. Surge pricing recalculates per zone from live supply and demand.
TECH_STACK: Elixir + Phoenix Channels + GenServer (zone actors) + Redis (geo) + Ecto + PostgreSQL/PostGIS, deployed on Kubernetes
APP_TYPE: API service
LANGUAGE: Elixir
SCALE: 100k active drivers, ~8k matches/min, sub-second dispatch
```

## 46. Tallyroom — expense splitting web app

```text
APP_DESCRIPTION: A web app for groups to track shared expenses and settle balances. Members add expenses and balances update live for everyone in the group, with settlement suggestions minimizing transfers. Activity feeds show who paid what in real time.
TECH_STACK: Phoenix LiveView + Ecto + PostgreSQL + Phoenix PubSub, deployed on Fly.io
APP_TYPE: web app
LANGUAGE: Elixir
SCALE: 600k groups, 4M users, live balance updates
```

## 47. Streamcut — Kafka stream processor

```text
APP_DESCRIPTION: A data pipeline that consumes domain events from Kafka topics, applies stateful transformations and joins, and republishes derived events. It manages consumer offsets, rebalances gracefully, and exposes lag metrics. Windowed aggregations emit on time and count triggers.
TECH_STACK: Elixir + Broadway + broadway_kafka + Flow + Redis (state) + Telemetry, mix releases on Kubernetes
APP_TYPE: data pipeline
LANGUAGE: Elixir
SCALE: ~400k events/sec, 24 partitions, stateful windows
```

## 48. Vaultkeeper — secrets management API

```text
APP_DESCRIPTION: An API service that stores and issues application secrets with envelope encryption, versioning, and per-service access policies. It leases dynamic credentials, audits every access, and rotates secrets on schedule. Clients fetch secrets over mTLS-authenticated calls.
TECH_STACK: Elixir + Phoenix API + Ecto + PostgreSQL + Oban (rotation) + Redis, deployed on Kubernetes
APP_TYPE: API service
LANGUAGE: Elixir
SCALE: 5k services, ~20k secret fetches/sec, audited access
```

## 49. Beacon — geofencing & proximity pipeline

```text
APP_DESCRIPTION: A data pipeline that evaluates device location updates against geofences to trigger enter, exit, and dwell events. It indexes fences spatially, batches evaluations, and emits events to downstream marketing and safety systems. Dwell timers are tracked per device and fence.
TECH_STACK: Elixir + Broadway + GenStage + Redis + PostgreSQL/PostGIS, mix releases on AWS EKS
APP_TYPE: data pipeline
LANGUAGE: Elixir
SCALE: 2M devices, ~30k location updates/sec, 100k geofences
```

## 50. Boardwalk — kanban project tool

```text
APP_DESCRIPTION: A web app for team project management with kanban boards. Cards move across columns and updates sync live to every board viewer, with presence showing active collaborators. WIP limits and due-date alerts enforce on the fly.
TECH_STACK: Phoenix LiveView + Phoenix Presence + Ecto + PostgreSQL + Oban, deployed on Gigalixir
APP_TYPE: web app
LANGUAGE: Elixir
SCALE: 50k boards, 20k concurrent users, live card sync
```

## 51. Fareloom — dynamic pricing engine API

```text
APP_DESCRIPTION: An API service that computes dynamic prices for travel inventory from demand, competitor, and inventory signals. It evaluates pricing rules per product, caches results, and serves prices with low latency. Rule changes propagate to live prices without redeploys.
TECH_STACK: Elixir + Phoenix API + GenStage + Redis + Ecto + PostgreSQL, deployed on Kubernetes
APP_TYPE: API service
LANGUAGE: Elixir
SCALE: ~60k price requests/sec, 2M products, live rule updates
```

## 52. Loopback — device firmware OTA pipeline

```text
APP_DESCRIPTION: A data pipeline and control plane for over-the-air firmware updates to IoT fleets. It schedules staged rollouts, tracks per-device update status from telemetry, and halts rollouts on failure-rate thresholds. Edge gateways verify and apply signed images.
TECH_STACK: Elixir + Nerves (devices) + Broadway (status ingest) + Oban (rollout control) + Ecto + PostgreSQL, mix releases on AWS
APP_TYPE: data pipeline
LANGUAGE: Elixir
SCALE: 500k devices, staged rollouts, ~5k status msgs/sec
```

## 53. Consensus — feature flag & config service

```text
APP_DESCRIPTION: An API service that serves feature flags and remote config with targeting rules, percentage rollouts, and instant kill switches. SDK clients stream flag changes and evaluate rules locally. Flag edits propagate to all connected clients within seconds.
TECH_STACK: Elixir + Phoenix API + Phoenix Channels + Ecto + PostgreSQL + Redis, deployed on Kubernetes
APP_TYPE: API service
LANGUAGE: Elixir
SCALE: 40k connected SDKs, ~100k evaluations/sec, live pushes
```

## 54. Habitloop — habit tracking web app

```text
APP_DESCRIPTION: A web app for building and tracking daily habits with streaks, reminders, and shared accountability groups. Group progress updates live as members check in, and streak calculations run continuously. Reminders fire on personalized schedules.
TECH_STACK: Phoenix LiveView + Ecto + PostgreSQL + Oban (reminders) + Phoenix PubSub, deployed on Fly.io
APP_TYPE: web app
LANGUAGE: Elixir
SCALE: 300k users, 1M daily check-ins, live group feeds
```

## 55. Portside — customs & trade docs API

```text
APP_DESCRIPTION: An API service that generates and validates customs declarations and shipping documents for freight forwarders. It maps commodity codes, validates against country rules, and submits to government portals. Submission status is tracked and surfaced back to clients.
TECH_STACK: Elixir + Phoenix API + Tesla (portal connectors) + Oban + Ecto + PostgreSQL, deployed on Gigalixir
APP_TYPE: API service
LANGUAGE: Elixir
SCALE: ~1,500 declarations/min, 40 country rulesets, tracked submits
```

## 56. Emberchat — customer live-chat widget backend

```text
APP_DESCRIPTION: An API and realtime backend powering an embeddable customer chat widget. It routes visitor conversations to available agents, streams messages and typing state, and persists transcripts. Visitor context and page history attach to each conversation.
TECH_STACK: Elixir + Phoenix Channels + Phoenix Presence + Ecto + PostgreSQL + Redis, deployed on Kubernetes
APP_TYPE: API service
LANGUAGE: Elixir
SCALE: 150k concurrent visitors, 5k agents, real-time routing
```

## 57. Sweepline — fraud detection pipeline

```text
APP_DESCRIPTION: A data pipeline that scores transactions for fraud in real time. It enriches each transaction with velocity features, evaluates rule sets and model scores, and emits decline, review, or approve decisions within tight latency budgets. Flagged cases stream to a review queue.
TECH_STACK: Elixir + Broadway + GenStage + Redis (feature store) + Ecto + PostgreSQL, mix releases on AWS EKS
APP_TYPE: data pipeline
LANGUAGE: Elixir
SCALE: ~25k transactions/sec, <50ms scoring budget
```

## 58. Studio — live streaming chat & reactions

```text
APP_DESCRIPTION: A web app that overlays live chat, reactions, and polls on video streams. Thousands of viewers per stream chat concurrently, reactions animate in real time, and moderators filter messages from a live console. Chat is sharded per stream for isolation.
TECH_STACK: Phoenix LiveView + Phoenix Channels + Phoenix PubSub + Redis + Ecto + PostgreSQL, deployed on Kubernetes
APP_TYPE: web app
LANGUAGE: Elixir
SCALE: 20k concurrent streams, 100k viewers each on big events
```

## 59. Roster — shift scheduling platform

```text
APP_DESCRIPTION: A web app for scheduling staff shifts across locations. Managers build rosters and employees see assignments and swaps update live, with conflict and overtime warnings computed on the fly. Open shifts broadcast to eligible staff who claim them in real time.
TECH_STACK: Phoenix LiveView + Ecto + PostgreSQL + Oban + Phoenix PubSub, deployed on Gigalixir
APP_TYPE: web app
LANGUAGE: Elixir
SCALE: 15k locations, 300k employees, live shift claiming
```

## 60. Cablecar — CDC database replication pipeline

```text
APP_DESCRIPTION: A data pipeline that captures change-data-capture streams from operational databases, transforms rows, and syncs them to search indexes and data warehouses. It preserves ordering per key, handles schema evolution, and replays from checkpoints. Backpressure protects downstream sinks.
TECH_STACK: Elixir + Broadway + broadway_kafka (Debezium topics) + Flow + Ecto + PostgreSQL, mix releases on Kubernetes
APP_TYPE: data pipeline
LANGUAGE: Elixir
SCALE: ~200k row changes/sec, 300 tables, ordered per key
```

## 61. Almanac — realtime weather alerts API

```text
APP_DESCRIPTION: An API service that ingests weather model and radar feeds and pushes location-specific alerts to subscribers. It evaluates alert polygons against subscriber locations and streams warnings over websockets. Severe events fan out to millions within seconds.
TECH_STACK: Elixir + Phoenix API + Phoenix Channels + Broadway (feed ingest) + Redis + PostgreSQL/PostGIS, deployed on Kubernetes
APP_TYPE: API service
LANGUAGE: Elixir
SCALE: 8M subscribers, ~10k alerts/min during storms, fast fan-out
```

## 62. Cellar — inventory & recipe costing app

```text
APP_DESCRIPTION: A LiveView admin app for restaurants to track ingredient inventory and recipe costs. Stock levels update live as orders and prep deduct ingredients, and recipe margins recompute when supplier prices change. Low-stock and expiry alerts surface in real time.
TECH_STACK: Phoenix LiveView + Ecto + PostgreSQL + Oban + Phoenix PubSub, deployed on Fly.io
APP_TYPE: web app
LANGUAGE: Elixir
SCALE: 8k restaurants, 25k SKUs each, live cost recompute
```

## 63. Meshpoint — MQTT broker bridge service

```text
APP_DESCRIPTION: An API and gateway service that bridges MQTT device traffic into a platform's internal event bus. It authenticates devices, enforces topic ACLs, and translates MQTT messages into normalized events. Device connection state is tracked and exposed to operators.
TECH_STACK: Elixir + Bandit + Tortoise MQTT + Phoenix PubSub + Ecto + PostgreSQL + Redis, deployed on Kubernetes
APP_TYPE: API service
LANGUAGE: Elixir
SCALE: 1M connected devices, ~80k msgs/sec, per-topic ACLs
```

## 64. Snappoll — audience response mobile-web app

```text
APP_DESCRIPTION: A web app that lets live audiences respond to presenter questions from their phones. Presenters advance slides and results animate live on the projected screen, while participants see confirmation instantly. Sessions handle sudden joins when a large room scans a code at once.
TECH_STACK: Phoenix LiveView + Phoenix Channels + Redis + Ecto + PostgreSQL, deployed on Fly.io
APP_TYPE: web app
LANGUAGE: Elixir
SCALE: 5k concurrent sessions, 2k participants each, spike joins
```

## 65. Longhaul — background job orchestration API

```text
APP_DESCRIPTION: An API service that runs durable multi-step workflows for other services. It sequences steps, handles retries and compensation, persists workflow state, and exposes status queries. Long-running steps checkpoint so restarts resume cleanly.
TECH_STACK: Elixir + Phoenix API + Oban (workflow steps) + Ecto + PostgreSQL, deployed on Gigalixir
APP_TYPE: API service
LANGUAGE: Elixir
SCALE: 200k workflows/day, ~2k steps/sec, durable state
```

## 66. Nestwatch — smart home telemetry pipeline

```text
APP_DESCRIPTION: A data pipeline that ingests smart-home device telemetry and automation triggers, evaluates user-defined rules, and dispatches device commands. It correlates sensor events, debounces noisy triggers, and records automation history. Rules run per home in isolated processes.
TECH_STACK: Elixir + Nerves (hubs) + Broadway + GenServer per home + Ecto + PostgreSQL, mix releases on AWS
APP_TYPE: data pipeline
LANGUAGE: Elixir
SCALE: 400k homes, ~40k events/sec, per-home rule engines
```

## 67. Voyant — travel itinerary planning app

```text
APP_DESCRIPTION: A web app for collaboratively planning trips. Travel companions add flights, stays, and activities to a shared itinerary that updates live, with conflict detection on overlapping times. Price and availability changes surface as alerts during planning.
TECH_STACK: Phoenix LiveView + Phoenix Presence + Ecto + PostgreSQL + Tesla + Oban, deployed on Fly.io
APP_TYPE: web app
LANGUAGE: Elixir
SCALE: 300k trips, 60k concurrent planners, live collaboration
```

## 68. Ripcord — API request replay & mocking service

```text
APP_DESCRIPTION: An API service that records inbound requests, replays them against staging, and serves configurable mock responses for testing. It captures full request context, diffs responses across environments, and rate-limits replays. Teams share recorded suites for regression testing.
TECH_STACK: Elixir + Bandit + Plug + Ecto + PostgreSQL + Redis, deployed on Gigalixir
APP_TYPE: API service
LANGUAGE: Elixir
SCALE: ~30k requests/sec captured, 5k suites, environment diffs
```

## 69. Mailsift — inbound email parsing pipeline

```text
APP_DESCRIPTION: A data pipeline that receives inbound emails, parses headers, bodies, and attachments, classifies intent, and routes structured data to downstream systems. It handles MIME edge cases, extracts entities, and quarantines spam. Attachments are scanned and stored.
TECH_STACK: Elixir + Broadway + GenStage + Ecto + PostgreSQL + S3, mix releases on Fly.io
APP_TYPE: data pipeline
LANGUAGE: Elixir
SCALE: ~15k emails/sec peak, MIME parsing, entity extraction
```

## 70. Districtly — civic 311 reporting app

```text
APP_DESCRIPTION: A web app for residents to report and track non-emergency city issues. Reports appear live on a staff map, status changes notify residents, and duplicate reports cluster automatically. Departments manage queues and SLAs from a LiveView console.
TECH_STACK: Phoenix LiveView + Ecto + PostgreSQL/PostGIS + Oban + Phoenix PubSub, deployed on Gigalixir
APP_TYPE: web app
LANGUAGE: Elixir
SCALE: 200 cities, 2M reports/year, live staff maps
```

## 71. Blockwatch — blockchain indexer pipeline

```text
APP_DESCRIPTION: A data pipeline that indexes blockchain blocks and transactions into queryable tables. It follows the chain head, handles reorgs by rolling back affected blocks, decodes contract events, and exposes balances and transfer histories. Indexing resumes from the last safe block.
TECH_STACK: Elixir + Broadway + GenStage + Tesla (node RPC) + Ecto + PostgreSQL, mix releases on Kubernetes
APP_TYPE: data pipeline
LANGUAGE: Elixir
SCALE: ~5k tx/sec indexed, reorg-safe, 500 GB index
```

## 72. Cadence — subscription billing platform

```text
APP_DESCRIPTION: A web app and backend for recurring subscription billing. It manages plans, proration, dunning, and invoicing, with a LiveView admin showing MRR and churn live. Failed payments trigger retry schedules and customer notifications automatically.
TECH_STACK: Phoenix LiveView + Oban (billing cycles) + Ecto + PostgreSQL + Tesla (processors), deployed on Gigalixir
APP_TYPE: web app
LANGUAGE: Elixir
SCALE: 40k merchants, 5M subscriptions, nightly billing runs
```

## 73. Sonarline — call center realtime analytics

```text
APP_DESCRIPTION: An API and realtime service that tracks call center metrics live. It ingests call events, computes queue wait, handle time, and agent occupancy, and streams supervisor wallboards. Threshold breaches trigger real-time alerts and callbacks.
TECH_STACK: Elixir + Phoenix Channels + Broadway (event ingest) + Redis + Ecto + PostgreSQL, deployed on Kubernetes
APP_TYPE: API service
LANGUAGE: Elixir
SCALE: 2k call centers, 200k agents, ~20k call events/sec
```

## 74. Fieldsync — offline-first mobile sync API

```text
APP_DESCRIPTION: An API service that syncs data for offline-first field apps. It resolves conflicts, applies delta changes, and pushes updates to reconnecting clients. Per-tenant partitions keep sync isolated, and change logs support incremental pull.
TECH_STACK: Elixir + Phoenix API + Phoenix Channels + Ecto + PostgreSQL + Redis, deployed on Fly.io
APP_TYPE: API service
LANGUAGE: Elixir
SCALE: 80k field devices, delta sync, conflict resolution
```

## 75. Almanaut — content scheduling & publishing app

```text
APP_DESCRIPTION: A web app for scheduling and publishing content across social channels. Teams plan a calendar, preview posts, and watch publish status update live as scheduled jobs fire. Approval workflows gate posts before they go out.
TECH_STACK: Phoenix LiveView + Oban (scheduled publish) + Tesla (channel APIs) + Ecto + PostgreSQL, deployed on Gigalixir
APP_TYPE: web app
LANGUAGE: Elixir
SCALE: 30k brands, 500k scheduled posts/month, live status
```

## 76. Gaugewire — infrastructure metrics pipeline

```text
APP_DESCRIPTION: A data pipeline that scrapes and ingests infrastructure metrics from thousands of hosts, downsamples time series, and evaluates alerting rules. It batches writes, deduplicates series, and forwards firing alerts. Recording rules precompute expensive queries.
TECH_STACK: Elixir + Broadway + GenStage + TimescaleDB + Redis, mix releases on Kubernetes
APP_TYPE: data pipeline
LANGUAGE: Elixir
SCALE: 20k hosts, ~2M samples/sec, downsampled retention
```

## 77. Guildhall — gaming community & matchmaking

```text
APP_DESCRIPTION: A web app where gamers form groups and get matched into sessions. Lobbies update live as players join, skill-based matchmaking assembles balanced teams, and voice-channel presence syncs across members. Party invites and ready checks resolve in real time.
TECH_STACK: Phoenix LiveView + Phoenix Presence + GenServer (lobbies) + Ecto + PostgreSQL + Redis, deployed on Kubernetes
APP_TYPE: web app
LANGUAGE: Elixir
SCALE: 200k concurrent players, 40k lobbies, live matchmaking
```

## 78. Tenderly — RFP & procurement platform

```text
APP_DESCRIPTION: A web app for running procurement tenders. Buyers publish RFPs, suppliers submit bids, and evaluation scores update live for the review committee. Sealed bids unlock at deadline and clarifications thread in real time between parties.
TECH_STACK: Phoenix LiveView + Ecto + PostgreSQL + Oban (deadlines) + Phoenix PubSub, deployed on Gigalixir
APP_TYPE: web app
LANGUAGE: Elixir
SCALE: 10k organizations, 100k tenders/year, live evaluation
```

## 79. Currentsee — energy trading ledger API

```text
APP_DESCRIPTION: An API service that records energy trades and positions for a power-trading desk. It books deals, marks positions to market, and computes exposure limits in real time. Every trade is appended to an immutable log with position snapshots.
TECH_STACK: Elixir + Phoenix API + Ecto + PostgreSQL + GenStage + Redis, deployed on Kubernetes
APP_TYPE: API service
LANGUAGE: Elixir
SCALE: ~8k trades/sec at peak, live exposure, immutable log
```

## 80. Cartograph — realtime collaborative maps

```text
APP_DESCRIPTION: A web app for teams to build maps together, dropping pins, drawing routes, and annotating regions live. Everyone sees edits and cursors in real time, and layer visibility syncs per user. Large datasets cluster and render progressively.
TECH_STACK: Phoenix LiveView + Phoenix Channels + Ecto + PostgreSQL/PostGIS + Redis, deployed on Fly.io
APP_TYPE: web app
LANGUAGE: Elixir
SCALE: 20k concurrent editors, 5k live maps, geo clustering
```

## 81. Provisr — device provisioning CLI

```text
APP_DESCRIPTION: A command-line tool for operators to provision and manage fleets of embedded devices. It flashes firmware images, registers devices against the backend, applies config profiles, and streams provisioning logs. Batch mode provisions many devices from a manifest.
TECH_STACK: Elixir CLI (escript) + Nerves tooling + Tesla (backend API), distributed as a mix release / escript
APP_TYPE: CLI
LANGUAGE: Elixir
SCALE: batch provisioning ~500 devices/run, operator use
```

## 82. Migratr — database migration CLI

```text
APP_DESCRIPTION: A command-line tool that plans, applies, and rolls back database schema migrations across environments. It diffs schema state, runs migrations transactionally where possible, and reports drift. Dry-run mode prints the exact SQL before applying.
TECH_STACK: Elixir CLI (escript) + Ecto + PostgreSQL adapter, distributed via mix escript / Homebrew
APP_TYPE: CLI
LANGUAGE: Elixir
SCALE: single operator, dozens of environments, transactional
```

## 83. Seedr — test data generation CLI

```text
APP_DESCRIPTION: A command-line tool that generates realistic seed data for development and staging databases. It reads a schema and relationship spec, produces referentially consistent rows, and streams inserts in batches. Profiles control volume and locale of generated data.
TECH_STACK: Elixir CLI (escript) + Ecto + PostgreSQL + Flow (parallel generation), distributed via mix escript
APP_TYPE: CLI
LANGUAGE: Elixir
SCALE: generates ~5M rows in minutes, parallel batching
```

## 84. Clustergaze — cluster health inspection CLI

```text
APP_DESCRIPTION: A command-line tool for inspecting a running Elixir/OTP cluster. It connects to nodes, reports process counts, memory, message-queue lengths, and supervision trees, and highlights hotspots. Watch mode refreshes stats live in the terminal.
TECH_STACK: Elixir CLI (escript) + :erlang distribution + Telemetry, distributed as a mix release
APP_TYPE: CLI
LANGUAGE: Elixir
SCALE: inspects clusters of 3-50 nodes, live refresh
```

## 85. Logtail — structured log tailing CLI

```text
APP_DESCRIPTION: A command-line tool that tails and filters structured logs from multiple sources in real time. It parses JSON lines, applies query expressions, highlights fields, and follows rotating files. Streams merge from several hosts into one ordered view.
TECH_STACK: Elixir CLI (escript) + GenStage + Tesla (remote log APIs), distributed via mix escript / Homebrew
APP_TYPE: CLI
LANGUAGE: Elixir
SCALE: tails ~50k lines/sec, multi-source merge
```

## 86. Benchwright — load testing CLI

```text
APP_DESCRIPTION: A command-line load-testing tool that drives HTTP and websocket endpoints at high concurrency. It ramps virtual users, records latency percentiles, and prints live throughput. Scenario scripts model realistic user flows with think times.
TECH_STACK: Elixir CLI (escript) + Task/Supervisor concurrency + Tesla + Telemetry, distributed as a mix release
APP_TYPE: CLI
LANGUAGE: Elixir
SCALE: drives ~100k concurrent virtual users from one host
```

## 87. Secretary — encrypted config CLI

```text
APP_DESCRIPTION: A command-line tool that manages encrypted application configuration and secrets in version control. It encrypts values per environment, decrypts at deploy, and diffs config changes safely. Team members share access via recipient keys without exposing plaintext.
TECH_STACK: Elixir CLI (escript) + libsodium bindings + local encrypted files + git, distributed via mix escript
APP_TYPE: CLI
LANGUAGE: Elixir
SCALE: single team, dozens of environments, encrypted at rest
```

## 88. Reindexer — search index rebuild CLI

```text
APP_DESCRIPTION: A command-line tool that rebuilds and backfills search indexes from a primary database. It streams records, transforms them into index documents, and bulk-loads with backpressure and progress reporting. Resumable checkpoints allow interrupted rebuilds to continue.
TECH_STACK: Elixir CLI (escript) + GenStage/Flow + Ecto + PostgreSQL + Elasticsearch, distributed as a mix release
APP_TYPE: CLI
LANGUAGE: Elixir
SCALE: reindexes ~50M documents, resumable checkpoints
```

## 89. Portico — API schema linting CLI

```text
APP_DESCRIPTION: A command-line tool that lints and validates GraphQL and OpenAPI schemas against team style rules. It detects breaking changes between versions, flags naming and pagination issues, and outputs machine-readable reports for CI. Custom rule packs extend the checks.
TECH_STACK: Elixir CLI (escript) + Absinthe parsing + custom rule engine, distributed via mix escript / Homebrew
APP_TYPE: CLI
LANGUAGE: Elixir
SCALE: runs in CI on large schemas, breaking-change detection
```

## 90. Backhaul — batch export CLI

```text
APP_DESCRIPTION: A command-line tool that exports large datasets from operational databases into partitioned files for analytics. It streams query results, transforms rows, and writes compressed partitions to object storage with parallel workers. Incremental mode exports only changed rows.
TECH_STACK: Elixir CLI (escript) + Flow + Ecto + PostgreSQL + S3, distributed as a mix release
APP_TYPE: CLI
LANGUAGE: Elixir
SCALE: exports 100M+ rows, parallel partitioned writes
```

## 91. Signalflow — clinical trial data pipeline

```text
APP_DESCRIPTION: A data pipeline for clinical trials that ingests case report form submissions and device readings, validates them against study protocols, and flags out-of-range values for review. It maintains an auditable trail and de-identifies data for analysis. Query rules run continuously as data arrives.
TECH_STACK: Elixir + Broadway + GenStage + Ecto + PostgreSQL + Oban, mix releases on AWS EKS
APP_TYPE: data pipeline
LANGUAGE: Elixir
SCALE: 300 trial sites, ~8k submissions/sec bursts, audited
```

## 92. Marketframe — B2B wholesale marketplace

```text
APP_DESCRIPTION: A web app marketplace where wholesale buyers order from suppliers at negotiated pricing. Catalogs, tiered prices, and stock update live, order approval workflows route in real time, and buyers track fulfillment on a LiveView dashboard. Reordering suggests items from purchase history.
TECH_STACK: Phoenix LiveView + Absinthe + Ecto + PostgreSQL + Oban + Phoenix PubSub, deployed on Gigalixir
APP_TYPE: web app
LANGUAGE: Elixir
SCALE: 20k suppliers, 200k buyers, live catalogs and pricing
```

## 93. Threadpool — realtime comment system API

```text
APP_DESCRIPTION: An API and realtime backend providing embeddable comments for publishers. It streams new comments and votes to readers, moderates with rules and queues, and threads replies. Comment counts and live viewer presence attach to each article.
TECH_STACK: Elixir + Phoenix Channels + Phoenix Presence + Ecto + PostgreSQL + Redis, deployed on Kubernetes
APP_TYPE: API service
LANGUAGE: Elixir
SCALE: 50k publisher sites, 300k concurrent readers, live threads
```

## 94. Ledgerly — expense & approval admin

```text
APP_DESCRIPTION: A LiveView admin tool for company expense management. Employees submit expenses, managers approve from a live queue, and policy checks flag violations instantly. Reimbursement batches run as background jobs and status updates broadcast to submitters.
TECH_STACK: Phoenix LiveView + Ecto + PostgreSQL + Oban + Phoenix PubSub, deployed on Fly.io
APP_TYPE: web app
LANGUAGE: Elixir
SCALE: 8k companies, 400k employees, live approval queues
```

## 95. Radarr — ad bid request pipeline

```text
APP_DESCRIPTION: A data pipeline that handles programmatic ad bid requests, enriches them with audience segments, evaluates campaign targeting, and returns bids within tight latency limits. It caps frequency, tracks spend, and logs auctions. Budget pacing adjusts bids in real time.
TECH_STACK: Elixir + Broadway + GenStage + Redis + Ecto + PostgreSQL, mix releases on Kubernetes
APP_TYPE: data pipeline
LANGUAGE: Elixir
SCALE: ~200k bid requests/sec, <20ms response budget
```

## 96. Convene — virtual event platform

```text
APP_DESCRIPTION: A web app for hosting virtual conferences with live sessions, networking rooms, and expo booths. Attendee presence, session chat, and Q&A sync in real time, and schedule changes push instantly. Booth staff see visitor presence and start chats live.
TECH_STACK: Phoenix LiveView + Phoenix Presence + Phoenix Channels + Ecto + PostgreSQL + Redis, deployed on Kubernetes
APP_TYPE: web app
LANGUAGE: Elixir
SCALE: 100k concurrent attendees, 500 sessions, live networking
```

## 97. Tollgate — API monetization & analytics API

```text
APP_DESCRIPTION: An API service that meters, authenticates, and monetizes third-party API access. It validates keys, meters calls per plan, enforces quotas, and produces usage-based billing records. A live dashboard shows per-consumer traffic and revenue.
TECH_STACK: Elixir + Bandit + Plug + Redis + Ecto + PostgreSQL + Oban (billing), deployed on Kubernetes
APP_TYPE: API service
LANGUAGE: Elixir
SCALE: ~100k req/sec metered, 30k consumers, usage billing
```

## 98. Pulsegrid — energy grid balancing pipeline

```text
APP_DESCRIPTION: A data pipeline that balances a distributed energy grid by ingesting generation and demand telemetry, forecasting short-term load, and dispatching set-points to controllable assets. It reacts within seconds to frequency deviations and logs every dispatch decision.
TECH_STACK: Elixir + Nerves (edge controllers) + Broadway + GenStage + TimescaleDB, mix releases on AWS
APP_TYPE: data pipeline
LANGUAGE: Elixir
SCALE: 50k grid assets, sub-second dispatch, ~30k readings/sec
```

## 99. Backstage — realtime CMS admin

```text
APP_DESCRIPTION: A LiveView admin for a headless CMS where editors manage content collaboratively. Draft edits, publish status, and locks sync live so two editors never clobber each other, and preview updates render as content changes. Scheduled publishing fires as background jobs.
TECH_STACK: Phoenix LiveView + Phoenix Presence + Absinthe (delivery API) + Ecto + PostgreSQL + Oban, deployed on Fly.io
APP_TYPE: web app
LANGUAGE: Elixir
SCALE: 15k sites, 40k editors, live locking and preview
```

## 100. Currents — realtime analytics dashboard API

```text
APP_DESCRIPTION: An API service that powers embeddable realtime analytics widgets. It ingests events, maintains rolling aggregates, and streams live counters, charts, and top-N lists to subscribed clients. Widgets subscribe to precisely the metrics they render.
TECH_STACK: Elixir + Phoenix Channels + Broadway + Flow + Redis + Ecto + PostgreSQL, deployed on Kubernetes
APP_TYPE: API service
LANGUAGE: Elixir
SCALE: 40k dashboards, ~150k events/sec, live rolling aggregates
```
