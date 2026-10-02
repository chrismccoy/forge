# Erlang Blueprint Types — Copy-Paste Input Sets

Copy a fenced block into the prompt as-is, or swap individual fields.

## 1. Switchboard — MQTT broker for IoT fleets

```text
APP_DESCRIPTION: A multi-tenant MQTT broker that terminates millions of persistent device connections for smart-home and industrial sensors. It handles QoS 0/1/2, retained messages, shared subscriptions, and per-tenant topic ACLs, with back-pressure toward slow subscribers.
TECH_STACK: Erlang/OTP + ranch acceptor pool + gen_statem per session + ETS routing tables + Mnesia for subscription state + distributed clustering over epmd, packaged as a relx release
APP_TYPE: API service
LANGUAGE: Erlang
SCALE: 3M concurrent device connections per node, 500k msg/sec, five-nines uptime
```

## 2. Relaynet — SMS aggregation gateway

```text
APP_DESCRIPTION: An SMPP-based SMS aggregation gateway that bridges enterprise senders to dozens of carrier bind sessions. It normalizes DLRs, enforces per-account throttles, and retries failed submits across alternate routes with sticky ordering per destination.
TECH_STACK: Erlang/OTP + custom SMPP codec + gen_statem per bind + poolboy worker pools + PostgreSQL via epgsql for CDRs + eredis for rate counters, deployed as relx release on Kubernetes
APP_TYPE: API service
LANGUAGE: Erlang
SCALE: 40k SMS/sec sustained, 200 concurrent carrier binds, <20ms enqueue latency
```

## 3. Presently — chat presence and fan-out service

```text
APP_DESCRIPTION: A presence and message fan-out backend for a team chat product. It tracks who is online across devices, delivers typing indicators and read receipts, and pushes messages to every subscribed WebSocket in a channel with ordered delivery.
TECH_STACK: Erlang/OTP + Cowboy WebSocket handlers + gproc process registry + ETS presence tables + phoenix-style PubSub over distributed Erlang + Redis via eredis for cross-region hints
APP_TYPE: API service
LANGUAGE: Erlang
SCALE: 2M concurrent WebSocket sessions, 150k presence updates/sec, sub-50ms fan-out
```

## 4. Bidstorm — real-time bidding exchange

```text
APP_DESCRIPTION: An RTB ad exchange that runs OpenRTB auctions for display inventory. It fans a single bid request to hundreds of demand partners, collects bids within a strict timeout, and returns the winner while logging every auction for billing.
TECH_STACK: Erlang/OTP + Cowboy HTTP handlers + gen_server bidder proxies + ETS budget caches + Kafka bridge for auction logs + eredis for frequency capping, relx release with hot code loading
APP_TYPE: API service
LANGUAGE: Erlang
SCALE: 300k auctions/sec, 80ms hard auction deadline, five-nines availability
```

## 5. Talkpath — VoIP soft-switch control plane

```text
APP_DESCRIPTION: A SIP soft-switch control plane that manages call setup, teardown, and routing between trunks and endpoints. It runs a state machine per dialog, applies dial-plan rules, and coordinates media relays while surviving node failures mid-call.
TECH_STACK: Erlang/OTP + gen_statem per SIP dialog + ranch UDP/TCP listeners + Mnesia for registrar bindings + distributed clustering for failover + relx releases on bare metal
APP_TYPE: API service
LANGUAGE: Erlang
SCALE: 500k concurrent calls, 10k call setups/sec, 99.999% control-plane uptime
```

## 6. Tollgate — distributed API rate limiter

```text
APP_DESCRIPTION: A distributed rate-limiting service that enforces token-bucket and sliding-window quotas across an API gateway fleet. It answers allow/deny decisions in single-digit milliseconds and syncs counters across the cluster without a single bottleneck.
TECH_STACK: Erlang/OTP + gen_server bucket owners + ETS counter shards + riak_core consistent hashing for key ownership + eredis fallback store, packaged with rebar3 and relx
APP_TYPE: API service
LANGUAGE: Erlang
SCALE: 1M decisions/sec, <3ms p99, linear scaling to 64 nodes
```

## 7. Queuewright — durable distributed message queue

```text
APP_DESCRIPTION: A durable message queue broker with at-least-once delivery, consumer groups, and per-partition ordering. Producers append to append-only logs while consumers track offsets, and the cluster rebalances partitions when nodes join or leave.
TECH_STACK: Erlang/OTP + gen_server per partition + DETS/disk_log persistence + riak_core partition ownership + ranch client listeners + distributed Erlang replication, relx release
APP_TYPE: data pipeline
LANGUAGE: Erlang
SCALE: 1M messages/sec ingest, 10k partitions, zero-loss failover
```

## 8. Ledgerline — real-time payment switch

```text
APP_DESCRIPTION: A payment authorization switch that routes ISO 8583 card transactions between acquirers and issuers. It runs a strict state machine per transaction, enforces idempotency, and applies stand-in authorization when an issuer link drops.
TECH_STACK: Erlang/OTP + gen_statem per transaction + custom ISO 8583 codec + Mnesia for stand-in balances + PostgreSQL via epgsql for settlement + poolboy connection pools, relx release
APP_TYPE: API service
LANGUAGE: Erlang
SCALE: 60k TPS peak, <100ms round-trip authorization, five-nines uptime
```

## 9. Streamweir — event ingestion and enrichment pipeline

```text
APP_DESCRIPTION: A high-throughput event ingestion pipeline that accepts clickstream and telemetry events, validates schemas, enriches with geo and device lookups, and forwards to downstream sinks. Back-pressure protects the cluster during traffic spikes.
TECH_STACK: Erlang/OTP + Cowboy ingest endpoints + gen_stage-style producer/consumer stages + ETS enrichment caches + RabbitMQ for downstream fan-out + PostgreSQL via epgsql, relx release
APP_TYPE: data pipeline
LANGUAGE: Erlang
SCALE: 800k events/sec, 200-node cluster, bounded memory under load
```

## 10. Sessionhold — distributed session store

```text
APP_DESCRIPTION: A distributed session manager that holds authenticated sessions for a large web platform. It stores session state in memory with disk backup, replicates across nodes, and expires idle sessions while surviving individual node crashes.
TECH_STACK: Erlang/OTP + gen_server session owners + Mnesia fragmented tables + ETS hot cache + distributed clustering over epmd + Cowboy admin API, packaged with rebar3 and relx
APP_TYPE: API service
LANGUAGE: Erlang
SCALE: 20M active sessions, 100k reads/sec, transparent node-failure recovery
```

## 11. Pulsegate — device telemetry collector

```text
APP_DESCRIPTION: A telemetry collector for connected vehicles that ingests GPS, engine, and diagnostic frames over MQTT and CoAP. It de-duplicates bursts, batches to storage, and streams anomalies to a real-time alerting topic.
TECH_STACK: Erlang/OTP + EMQX-style MQTT frontend + gen_statem per device session + ETS dedup windows + Kafka bridge + PostgreSQL/TimescaleDB via epgsql, relx release on Kubernetes
APP_TYPE: data pipeline
LANGUAGE: Erlang
SCALE: 1.5M connected vehicles, 250k frames/sec, sub-second anomaly latency
```

## 12. Fanmesh — WebSocket broadcast fabric

```text
APP_DESCRIPTION: A WebSocket broadcast fabric for live sports and trading UIs that pushes market and score updates to huge audiences. Publishers write once to a topic and the fabric fans out to every connected client with minimal per-message overhead.
TECH_STACK: Erlang/OTP + Cowboy WebSocket handlers + ranch acceptors + gproc topic registry + ETS subscriber sets + distributed Erlang for cross-node fan-out, relx release
APP_TYPE: API service
LANGUAGE: Erlang
SCALE: 4M concurrent viewers, 1M outbound messages/sec, <40ms delivery
```

## 13. Cellwarden — HLR/HSS subscriber registry

```text
APP_DESCRIPTION: A telecom subscriber data service acting as an HLR/HSS that answers authentication and location queries for a mobile core. It serves Diameter and MAP requests, maintains subscriber profiles, and replicates across geo-redundant sites.
TECH_STACK: Erlang/OTP + custom Diameter stack + gen_server query workers + Mnesia geo-replicated tables + poolboy pools + distributed clustering, relx release on carrier-grade hardware
APP_TYPE: API service
LANGUAGE: Erlang
SCALE: 80M subscriber records, 200k queries/sec, five-nines carrier-grade uptime
```

## 14. Dropforge — file upload and transcode pipeline

```text
APP_DESCRIPTION: An upload ingestion pipeline that accepts large media files, chunks them, verifies integrity, and dispatches transcode jobs to a worker fleet. It tracks job state and streams progress back to clients over WebSocket.
TECH_STACK: Erlang/OTP + Cowboy multipart handlers + gen_statem per job + poolboy transcode dispatchers + RabbitMQ job queue + object storage backend, relx release
APP_TYPE: data pipeline
LANGUAGE: Erlang
SCALE: 50k concurrent uploads, 10 GB/s aggregate ingest, resumable transfers
```

## 15. Beaconhub — push notification dispatcher

```text
APP_DESCRIPTION: A push notification dispatcher that delivers to APNs, FCM, and web push from a single API. It maintains persistent provider connections, batches tokens, handles per-provider throttling, and retries with exponential backoff.
TECH_STACK: Erlang/OTP + gen_statem per provider connection + poolboy sender pools + ETS token batches + eredis for dedup + Cowboy ingest API, relx release on Kubernetes
APP_TYPE: API service
LANGUAGE: Erlang
SCALE: 500k notifications/sec, 3 provider fan-out, <2s end-to-end delivery
```

## 16. Gridkeeper — smart-meter data concentrator

```text
APP_DESCRIPTION: A grid data concentrator that collects readings from millions of smart electricity meters over DLMS/COSEM. It aggregates interval data, detects tamper and outage signals, and forwards validated readings to the utility billing system.
TECH_STACK: Erlang/OTP + gen_statem per meter link + ranch listeners + ETS aggregation buffers + Mnesia for meter registry + Kafka bridge to billing, relx release
APP_TYPE: data pipeline
LANGUAGE: Erlang
SCALE: 5M meters, 100k readings/sec, guaranteed interval-data completeness
```

## 17. Roundtable — multiplayer game session server

```text
APP_DESCRIPTION: An authoritative game session server for real-time multiplayer matches. It runs one process per match, applies player inputs deterministically, broadcasts world snapshots, and migrates matches off failing nodes without dropping players.
TECH_STACK: Erlang/OTP + gen_statem per match + ranch UDP listeners + ETS entity state + gproc match registry + distributed clustering for migration, relx release
APP_TYPE: API service
LANGUAGE: Erlang
SCALE: 200k concurrent matches, 1M players online, 30Hz tick with <60ms latency
```

## 18. Clearpond — distributed job scheduler

```text
APP_DESCRIPTION: A distributed cron and job scheduler that guarantees each scheduled task fires exactly once across a cluster. It elects owners per job via consistent hashing, persists schedules, and reassigns work when nodes fail.
TECH_STACK: Erlang/OTP + riak_core for job ownership + gen_statem per job + Mnesia schedule store + poolboy executor pools + Cowboy management API, relx release
APP_TYPE: API service
LANGUAGE: Erlang
SCALE: 2M scheduled jobs, 20k firings/sec, exactly-once under node churn
```

## 19. Signalfen — network monitoring poller

```text
APP_DESCRIPTION: A network monitoring engine that polls tens of thousands of devices via SNMP and streaming telemetry. It supervises one poller per device, computes rollups, and raises alarms when thresholds breach, feeding a real-time NOC dashboard.
TECH_STACK: Erlang/OTP + gen_server pollers under supervisor trees + ETS metric buffers + PostgreSQL/TimescaleDB via epgsql + RabbitMQ alarm bus, relx release
APP_TYPE: data pipeline
LANGUAGE: Erlang
SCALE: 100k monitored devices, 500k metrics/sec, five-nines poller availability
```

## 20. Trellisway — API gateway and reverse proxy

```text
APP_DESCRIPTION: An API gateway that terminates client requests, authenticates tokens, applies routing and rate rules, and proxies to upstream services. It hot-reloads route config and sheds load gracefully under upstream failure.
TECH_STACK: Erlang/OTP + Cowboy front-end + gun HTTP client to upstreams + ETS route tables + eredis for token cache + hot code loading for config, relx release
APP_TYPE: API service
LANGUAGE: Erlang
SCALE: 400k requests/sec, <5ms added latency, zero-downtime config reloads
```

## 21. Cascadeq — stream processing topology

```text
APP_DESCRIPTION: A stream processing engine that runs windowed aggregations and joins over event streams for fraud scoring. Operators are supervised processes wired into a topology, with checkpointing so a node crash replays only unprocessed windows.
TECH_STACK: Erlang/OTP + gen_stage producer/consumer stages + ETS window state + disk_log checkpoints + Kafka source/sink + distributed clustering, relx release
APP_TYPE: data pipeline
LANGUAGE: Erlang
SCALE: 600k events/sec, sub-second window emit, at-least-once checkpointing
```

## 22. Portcall — SIP registrar and location service

```text
APP_DESCRIPTION: A SIP registrar and location service for a hosted PBX platform. It processes REGISTER requests, tracks device bindings with expiries, and answers location lookups for inbound call routing across a clustered deployment.
TECH_STACK: Erlang/OTP + gen_statem per registration + ranch UDP/TCP listeners + Mnesia binding store + gproc registry + distributed clustering, relx release
APP_TYPE: API service
LANGUAGE: Erlang
SCALE: 3M registered endpoints, 50k registrations/sec, five-nines uptime
```

## 23. Ripplecast — pub/sub message router

```text
APP_DESCRIPTION: A topic-based publish/subscribe router with wildcard subscriptions and hierarchical topics. It matches published messages against subscriber patterns in a trie and delivers to local and remote subscribers with ordered guarantees.
TECH_STACK: Erlang/OTP + gen_server topic trie owners + ETS subscription index + distributed Erlang inter-node delivery + Cowboy admin API + poolboy, relx release
APP_TYPE: API service
LANGUAGE: Erlang
SCALE: 5M subscriptions, 1M publishes/sec, <10ms match-and-route
```

## 24. Vaultline — distributed secrets and token broker

```text
APP_DESCRIPTION: A short-lived token and secrets broker for microservices. It issues and validates scoped credentials, rotates keys, and answers introspection queries under heavy load without a single point of contention.
TECH_STACK: Erlang/OTP + gen_server token issuers + ETS token cache + Mnesia for issued-token index + Cowboy API + eredis for revocation lists, relx release
APP_TYPE: API service
LANGUAGE: Erlang
SCALE: 300k token validations/sec, <2ms p99, five-nines availability
```

## 25. Meshworks — service discovery and health registry

```text
APP_DESCRIPTION: A service discovery registry where instances register, heartbeat, and are health-checked. Clients query for healthy endpoints and receive push updates as topology changes, with eventually consistent replication across the cluster.
TECH_STACK: Erlang/OTP + gen_statem per registered instance + Mnesia replicated tables + gproc watchers + Cowboy REST and WebSocket API + distributed clustering, relx release
APP_TYPE: API service
LANGUAGE: Erlang
SCALE: 500k registered instances, 100k heartbeats/sec, sub-second convergence
```

## 26. Tidebank — order-matching engine

```text
APP_DESCRIPTION: A limit-order matching engine for a crypto exchange. It maintains per-symbol order books in memory, matches incoming orders deterministically, and publishes fills and book deltas to a market-data stream.
TECH_STACK: Erlang/OTP + gen_statem per symbol book + ETS price levels + disk_log for order journal + Cowboy WebSocket market feed + distributed clustering, relx release
APP_TYPE: API service
LANGUAGE: Erlang
SCALE: 200k orders/sec per symbol, <50 microsecond match, deterministic replay
```

## 27. Loomport — webhook delivery service

```text
APP_DESCRIPTION: A reliable webhook delivery service that receives internal events and delivers HTTP callbacks to customer endpoints. It retries with backoff, respects per-endpoint concurrency, and dead-letters after exhausting attempts.
TECH_STACK: Erlang/OTP + gen_statem per delivery + poolboy sender pools + gun HTTP client + RabbitMQ retry queues + PostgreSQL via epgsql for delivery log, relx release
APP_TYPE: API service
LANGUAGE: Erlang
SCALE: 250k webhooks/sec, per-endpoint fairness, guaranteed at-least-once delivery
```

## 28. Sparkgrid — real-time analytics counter service

```text
APP_DESCRIPTION: A real-time counting service that maintains high-cardinality metrics like unique visitors, top-N lists, and rolling rates. It shards counters across the cluster and answers dashboard queries with fresh, low-latency aggregates.
TECH_STACK: Erlang/OTP + gen_server counter shards + ETS + HyperLogLog structures + riak_core key distribution + Cowboy query API, relx release
APP_TYPE: data pipeline
LANGUAGE: Erlang
SCALE: 1M increments/sec, billions of distinct keys, <20ms query latency
```

## 29. Beltway — MQTT-to-Kafka bridge

```text
APP_DESCRIPTION: A protocol bridge that terminates MQTT device traffic and republishes messages onto Kafka topics for downstream analytics. It preserves ordering per device, applies topic mapping rules, and buffers during Kafka slowdowns.
TECH_STACK: Erlang/OTP + VerneMQ-style MQTT frontend + gen_statem per session + ETS buffers + brod Kafka client + poolboy producer pools, relx release
APP_TYPE: data pipeline
LANGUAGE: Erlang
SCALE: 2M device connections, 400k msg/sec bridged, bounded buffering under back-pressure
```

## 30. Harborwatch — connection multiplexer for edge devices

```text
APP_DESCRIPTION: An edge connection concentrator that keeps long-lived tunnels open to field devices behind NAT and multiplexes control commands and firmware pushes. It maintains liveness, queues commands offline, and delivers on reconnect.
TECH_STACK: Erlang/OTP + gen_statem per tunnel + ranch listeners + ETS command queues + Mnesia for device state + Cowboy control API, relx release
APP_TYPE: API service
LANGUAGE: Erlang
SCALE: 1M persistent tunnels, 50k commands/sec, seamless reconnect resumption
```

## 31. Quorumline — Raft-based configuration store

```text
APP_DESCRIPTION: A strongly consistent configuration and coordination store built on a Raft consensus group. It provides linearizable reads, atomic compare-and-swap, and watch notifications for service coordination and leader election.
TECH_STACK: Erlang/OTP + ra Raft library + gen_statem state machines + disk_log persistence + Cowboy and gRPC API + distributed clustering, relx release
APP_TYPE: API service
LANGUAGE: Erlang
SCALE: 100k reads/sec, linearizable writes, sub-second leader failover
```

## 32. Fluxrelay — log shipping and aggregation pipeline

```text
APP_DESCRIPTION: A log aggregation pipeline that receives structured logs from thousands of hosts, parses and batches them, and forwards to storage and search backends. It applies sampling and back-pressure to protect the ingest tier.
TECH_STACK: Erlang/OTP + ranch TCP/TLS listeners + gen_stage stages + ETS batch buffers + brod Kafka sink + poolboy, relx release on Kubernetes
APP_TYPE: data pipeline
LANGUAGE: Erlang
SCALE: 1M log lines/sec, 5k source hosts, elastic back-pressure control
```

## 33. Chimewell — appointment and reminder engine

```text
APP_DESCRIPTION: A scheduling and reminder engine that fires timed reminders across SMS, email, and push for millions of appointments. It manages per-user timezones, coalesces reminders, and reschedules on changes without duplicate sends.
TECH_STACK: Erlang/OTP + gen_statem per reminder + Mnesia schedule store + poolboy dispatchers + RabbitMQ channel fan-out + PostgreSQL via epgsql, relx release
APP_TYPE: API service
LANGUAGE: Erlang
SCALE: 10M scheduled reminders, 30k firings/sec, exactly-once delivery
```

## 34. Currentline — CDR rating and billing pipeline

```text
APP_DESCRIPTION: A telecom rating engine that consumes call detail records, applies tariff plans and discounts in real time, and produces rated events for billing. It supports hot-swapping rate cards and deduplicates replayed CDRs.
TECH_STACK: Erlang/OTP + gen_server rating workers + ETS rate-card cache + Mnesia dedup index + brod Kafka source/sink + PostgreSQL via epgsql, relx release
APP_TYPE: data pipeline
LANGUAGE: Erlang
SCALE: 300k CDRs/sec, hot rate-card reloads, zero double-billing
```

## 35. Anchorhold — WebRTC signaling server

```text
APP_DESCRIPTION: A WebRTC signaling server that brokers SDP offers, answers, and ICE candidates between peers for video calls. It manages rooms, tracks participants, and coordinates renegotiation while surviving signaling-node failures.
TECH_STACK: Erlang/OTP + Cowboy WebSocket handlers + gen_statem per session + gproc room registry + ETS peer state + distributed clustering, relx release
APP_TYPE: API service
LANGUAGE: Erlang
SCALE: 500k concurrent signaling sessions, 50k room joins/sec, <30ms signaling latency
```

## 36. Emberpost — email delivery MTA

```text
APP_DESCRIPTION: A high-volume outbound MTA that accepts mail via SMTP submission, queues per-destination, and delivers with connection pooling, retries, and bounce handling. It enforces per-domain rate limits and warms up sending IPs.
TECH_STACK: Erlang/OTP + gen_smtp server + gen_statem per delivery + poolboy connection pools + Mnesia queue index + eredis for reputation counters, relx release
APP_TYPE: API service
LANGUAGE: Erlang
SCALE: 200k emails/sec, per-domain throttling, resilient retry queues
```

## 37. Slipstream — CDC change data capture pipeline

```text
APP_DESCRIPTION: A change data capture pipeline that reads database write-ahead logs, transforms row changes into events, and streams them to consumers with ordering per key. It tracks replication slots and resumes exactly where it left off.
TECH_STACK: Erlang/OTP + epgsql logical replication + gen_stage stages + ETS transform cache + brod Kafka sink + disk_log offset store, relx release
APP_TYPE: data pipeline
LANGUAGE: Erlang
SCALE: 500k row changes/sec, per-key ordering, exactly-once resume
```

## 38. Watchtower — distributed feature flag service

```text
APP_DESCRIPTION: A feature flag and dynamic config service that evaluates targeting rules and pushes flag changes to SDKs in real time. It supports percentage rollouts, segment targeting, and instant kill switches across the fleet.
TECH_STACK: Erlang/OTP + Cowboy REST and streaming API + ETS flag cache + Mnesia rule store + gproc subscriber registry + distributed clustering, relx release
APP_TYPE: API service
LANGUAGE: Erlang
SCALE: 1M SDK connections, <1s change propagation, 200k evaluations/sec
```

## 39. Dampfield — back-pressure-aware ingest buffer

```text
APP_DESCRIPTION: A shock-absorber ingest buffer that sits in front of a slower analytics store, accepting bursts of events and draining at a controlled rate. It spills to disk when memory fills and preserves ordering per source.
TECH_STACK: Erlang/OTP + gen_stage producer/consumer + ETS in-memory ring + disk_log overflow + ranch listeners + poolboy drainers, relx release
APP_TYPE: data pipeline
LANGUAGE: Erlang
SCALE: 700k events/sec burst absorb, disk-backed overflow, no data loss under spikes
```

## 40. Talonlink — Diameter charging gateway

```text
APP_DESCRIPTION: An online charging Diameter gateway that authorizes and meters data sessions for a mobile network in real time. It reserves quota, applies credit control, and terminates sessions on exhaustion with graceful re-authorization.
TECH_STACK: Erlang/OTP + custom Diameter Gy/Gx stack + gen_statem per session + Mnesia balance store + poolboy + distributed clustering, relx release on carrier hardware
APP_TYPE: API service
LANGUAGE: Erlang
SCALE: 5M concurrent charging sessions, 150k credit-control requests/sec, five-nines
```

## 41. Cradlenet — IoT device provisioning service

```text
APP_DESCRIPTION: A device onboarding and provisioning service that authenticates new IoT devices, issues certificates, assigns configuration, and enrolls them into fleets. It handles bulk factory provisioning and staged rollouts.
TECH_STACK: Erlang/OTP + Cowboy REST API + gen_statem per enrollment + Mnesia device registry + eredis for nonce cache + poolboy CA workers, relx release
APP_TYPE: API service
LANGUAGE: Erlang
SCALE: 100k enrollments/sec at factory bursts, 50M enrolled devices, five-nines
```

## 42. Riverbend — geospatial proximity matcher

```text
APP_DESCRIPTION: A real-time proximity matching service for ride-hailing that indexes driver locations and answers nearest-available queries. It updates positions continuously and dispatches match offers with per-driver state machines.
TECH_STACK: Erlang/OTP + gen_statem per driver + ETS geohash index + gproc registry + Cowboy API + distributed clustering, relx release
APP_TYPE: API service
LANGUAGE: Erlang
SCALE: 2M active drivers, 300k location updates/sec, <50ms match query
```

## 43. Beacontide — presence-aware notification hub

```text
APP_DESCRIPTION: A notification hub that routes alerts to users based on live presence, choosing in-app delivery when online and push or email when away. It dedupes across channels and honors quiet-hours preferences.
TECH_STACK: Erlang/OTP + Cowboy WebSocket + gproc presence registry + gen_statem routers + poolboy channel senders + eredis dedup, relx release
APP_TYPE: API service
LANGUAGE: Erlang
SCALE: 3M connected users, 200k notifications/sec, sub-100ms in-app delivery
```

## 44. Millstream — batch-to-stream ETL orchestrator

```text
APP_DESCRIPTION: An ETL orchestrator that coordinates extract, transform, and load stages across a worker fleet, tracking dependencies and retries. It runs supervised pipelines, checkpoints progress, and resumes failed stages without full reruns.
TECH_STACK: Erlang/OTP + gen_statem per pipeline run + supervisor trees + poolboy workers + Mnesia run state + RabbitMQ task queue + PostgreSQL via epgsql, relx release
APP_TYPE: data pipeline
LANGUAGE: Erlang
SCALE: 50k concurrent pipeline runs, stage-level retry, resumable checkpoints
```

## 45. Overwatch — cluster health control plane

```text
APP_DESCRIPTION: A control plane that monitors a large distributed system, tracks node membership, detects partitions, and orchestrates failover and rebalancing. It exposes a live topology API and drives automated remediation actions.
TECH_STACK: Erlang/OTP + distributed Erlang + gossip membership + gen_statem controllers + Mnesia topology store + Cowboy API + ra for coordination, relx release
APP_TYPE: API service
LANGUAGE: Erlang
SCALE: 1000-node clusters, sub-second failure detection, five-nines control-plane uptime
```

## 46. Pennywise — micropayment metering service

```text
APP_DESCRIPTION: A usage metering and micropayment service that meters API and content consumption per user, aggregates tiny charges, and settles in batches. It guarantees accurate counts under concurrency and idempotent event ingestion.
TECH_STACK: Erlang/OTP + gen_server meter owners + ETS counters + Mnesia idempotency index + Cowboy ingest API + PostgreSQL via epgsql settlement, relx release
APP_TYPE: API service
LANGUAGE: Erlang
SCALE: 500k metering events/sec, exact per-user counts, idempotent ingest
```

## 47. Slateforge — collaborative document sync backend

```text
APP_DESCRIPTION: A real-time collaborative editing backend that merges concurrent edits using operational transforms. It maintains one process per document, sequences operations, and broadcasts transformed ops to all connected editors.
TECH_STACK: Erlang/OTP + Cowboy WebSocket + gen_server per document + ETS op logs + gproc registry + PostgreSQL via epgsql snapshots, relx release
APP_TYPE: API service
LANGUAGE: Erlang
SCALE: 500k active documents, 100k ops/sec, <50ms edit propagation
```

## 48. Hollowpoint — DNS authoritative server

```text
APP_DESCRIPTION: An authoritative DNS server that answers queries for millions of zones with geo and latency-based routing. It serves from in-memory zone data, supports dynamic record updates, and mitigates floods with rate controls.
TECH_STACK: Erlang/OTP + ranch UDP/TCP listeners + gen_server query workers + ETS zone tables + Mnesia zone store + distributed clustering, relx release
APP_TYPE: API service
LANGUAGE: Erlang
SCALE: 2M queries/sec, millions of zones, <1ms answer latency
```

## 49. Cinderpath — dead-letter and retry orchestrator

```text
APP_DESCRIPTION: A retry orchestration service that captures failed operations from across a platform, applies configurable backoff policies, and replays them safely. It surfaces stuck items and supports manual and automated retries.
TECH_STACK: Erlang/OTP + gen_statem per retry item + RabbitMQ dead-letter queues + Mnesia item store + Cowboy dashboard API + poolboy, relx release
APP_TYPE: API service
LANGUAGE: Erlang
SCALE: 200k retry items/sec, policy-driven backoff, no lost failures
```

## 50. Wavelength — live audio streaming relay

```text
APP_DESCRIPTION: A live audio relay for talk rooms and podcasts that mixes and forwards RTP streams to listeners. It manages per-room speaker slots, adapts to network jitter, and scales rooms across nodes with participant migration.
TECH_STACK: Erlang/OTP + ranch RTP listeners + gen_statem per room + ETS participant state + gproc registry + distributed clustering, relx release
APP_TYPE: API service
LANGUAGE: Erlang
SCALE: 100k concurrent rooms, 2M listeners, <80ms audio relay latency
```

## 51. Northgauge — API usage analytics collector

```text
APP_DESCRIPTION: A usage analytics collector that captures per-key API call metadata, aggregates by route and customer, and exposes near-real-time dashboards and billing exports. It samples high-volume keys and buffers under load.
TECH_STACK: Erlang/OTP + Cowboy ingest + gen_stage aggregation + ETS rollup tables + brod Kafka sink + PostgreSQL via epgsql, relx release
APP_TYPE: data pipeline
LANGUAGE: Erlang
SCALE: 800k API events/sec, per-customer rollups, near-real-time dashboards
```

## 52. Bulwark — DDoS mitigation edge filter

```text
APP_DESCRIPTION: An edge filtering service that inspects incoming connections, scores clients, and drops or challenges suspicious traffic before it reaches origins. It maintains per-IP reputation and adapts thresholds during attacks.
TECH_STACK: Erlang/OTP + ranch listeners + gen_server scorer workers + ETS reputation tables + eredis shared blocklists + distributed clustering, relx release
APP_TYPE: API service
LANGUAGE: Erlang
SCALE: 3M connections/sec inspection, <2ms decision, adaptive attack response
```

## 53. Foldharbor — message archival pipeline

```text
APP_DESCRIPTION: A compliance archival pipeline that captures every chat and email message, indexes metadata, and writes immutable records to long-term storage. It guarantees completeness for audits and supports fast retrieval by query.
TECH_STACK: Erlang/OTP + gen_stage stages + ETS index buffers + Mnesia metadata store + brod Kafka source + object storage sink, relx release
APP_TYPE: data pipeline
LANGUAGE: Erlang
SCALE: 500k messages/sec archived, immutable write guarantees, audit-complete
```

## 54. Starcross — matchmaking and lobby service

```text
APP_DESCRIPTION: A matchmaking service that groups players into balanced matches by skill, latency, and party constraints. It runs matching pools as processes, forms lobbies, and hands off to game servers with reservation guarantees.
TECH_STACK: Erlang/OTP + gen_statem per pool + ETS candidate buckets + gproc lobby registry + Cowboy API + distributed clustering, relx release
APP_TYPE: API service
LANGUAGE: Erlang
SCALE: 1M players in queue, 20k matches/sec formed, <2s match wait
```

## 55. Ironvane — MQTT rules and routing engine

```text
APP_DESCRIPTION: A rules engine layered on an MQTT broker that evaluates SQL-like rules against inbound device messages and routes results to actions like database writes, HTTP calls, and re-publishes. Rules hot-reload without downtime.
TECH_STACK: Erlang/OTP + EMQX-style broker hooks + gen_server rule evaluators + ETS compiled rules + poolboy action workers + gun HTTP client, relx release
APP_TYPE: data pipeline
LANGUAGE: Erlang
SCALE: 1M device messages/sec evaluated, hot rule reloads, <5ms rule latency
```

## 56. Quillrun — activity feed fan-out service

```text
APP_DESCRIPTION: A social activity feed backend that fans out posts to follower timelines and serves personalized feeds. It blends fan-out-on-write for normal users with fan-out-on-read for high-follower accounts to stay fast.
TECH_STACK: Erlang/OTP + gen_server timeline workers + ETS feed caches + eredis timeline store + Cowboy API + poolboy, relx release
APP_TYPE: API service
LANGUAGE: Erlang
SCALE: 100k posts/sec, 50M timelines, <100ms feed read
```

## 57. Deepwater — telemetry downsampling pipeline

```text
APP_DESCRIPTION: A metrics downsampling pipeline that ingests raw time series, computes rollups at multiple resolutions, and expires raw data on retention policies. It keeps recent data hot and older data compacted for cheap queries.
TECH_STACK: Erlang/OTP + gen_stage stages + ETS rollup buffers + PostgreSQL/TimescaleDB via epgsql + disk_log staging, relx release
APP_TYPE: data pipeline
LANGUAGE: Erlang
SCALE: 1M data points/sec, multi-resolution rollups, retention-driven compaction
```

## 58. Cobblelink — legacy protocol adapter gateway

```text
APP_DESCRIPTION: A protocol adapter gateway that translates between legacy binary protocols and modern JSON APIs for industrial systems. It keeps stateful sessions to old equipment and exposes clean REST and streaming endpoints.
TECH_STACK: Erlang/OTP + gen_statem per legacy session + ranch listeners + custom binary codecs + Cowboy REST/WebSocket + poolboy, relx release
APP_TYPE: API service
LANGUAGE: Erlang
SCALE: 200k legacy sessions, 50k translations/sec, five-nines gateway uptime
```

## 59. Nightferry — cross-region replication relay

```text
APP_DESCRIPTION: A replication relay that ships data changes between geographically separate clusters with ordering, conflict detection, and back-pressure. It resumes from durable offsets and tolerates long inter-region outages.
TECH_STACK: Erlang/OTP + gen_statem per stream + disk_log offset store + distributed Erlang + brod Kafka bridge + poolboy shippers, relx release
APP_TYPE: data pipeline
LANGUAGE: Erlang
SCALE: 400k changes/sec cross-region, outage-tolerant resume, ordered delivery
```

## 60. Greenwarden — carbon telemetry aggregator

```text
APP_DESCRIPTION: An energy and carbon telemetry aggregator that collects consumption data from buildings and data centers, computes emissions in real time, and streams intensity signals for load-shifting decisions.
TECH_STACK: Erlang/OTP + MQTT frontend + gen_stage aggregation + ETS rollups + PostgreSQL via epgsql + RabbitMQ signal bus, relx release
APP_TYPE: data pipeline
LANGUAGE: Erlang
SCALE: 500k sensors, 200k readings/sec, sub-second intensity signals
```

## 61. Thornwire — abuse and anti-fraud scoring service

```text
APP_DESCRIPTION: A real-time risk scoring service that evaluates signup and transaction events against rules and velocity checks, returning allow, review, or block decisions. It maintains per-entity counters and updates models without downtime.
TECH_STACK: Erlang/OTP + Cowboy API + gen_server scorers + ETS velocity windows + eredis shared counters + hot code loading, relx release
APP_TYPE: API service
LANGUAGE: Erlang
SCALE: 300k risk decisions/sec, <10ms p99, hot model updates
```

## 62. Lanterncore — cluster-wide distributed lock manager

```text
APP_DESCRIPTION: A distributed lock and lease manager that grants mutual exclusion and leader leases across services. It supports fencing tokens, automatic lease expiry, and fair queuing for contended locks under high concurrency.
TECH_STACK: Erlang/OTP + ra Raft group + gen_statem lock owners + ETS wait queues + Cowboy API + distributed clustering, relx release
APP_TYPE: API service
LANGUAGE: Erlang
SCALE: 200k lock ops/sec, fencing guarantees, sub-second lease failover
```

## 63. Saltmarsh — data validation and quality gate

```text
APP_DESCRIPTION: A streaming data quality gate that validates records against schemas and business rules, quarantining bad data and passing clean records downstream. It emits quality metrics and supports rule updates on the fly.
TECH_STACK: Erlang/OTP + gen_stage validation stages + ETS rule cache + brod Kafka source/sink + Mnesia quarantine index, relx release
APP_TYPE: data pipeline
LANGUAGE: Erlang
SCALE: 600k records/sec validated, live rule updates, quarantine without data loss
```

## 64. Bramblehost — chat room and channel backend

```text
APP_DESCRIPTION: A chat backend for communities that manages channels, memberships, message history, and moderation. It runs one process per active channel, fans messages to members, and persists history for scrollback.
TECH_STACK: Erlang/OTP + Cowboy WebSocket + gen_server per channel + gproc registry + ETS member sets + PostgreSQL via epgsql history, relx release
APP_TYPE: API service
LANGUAGE: Erlang
SCALE: 1M active channels, 300k messages/sec, <60ms fan-out
```

## 65. Ridgeline — API request replay and shadow tester

```text
APP_DESCRIPTION: A traffic shadowing service that captures live API requests, replays them against candidate service versions, and diffs responses to catch regressions before release. It samples traffic and isolates side effects.
TECH_STACK: Erlang/OTP + Cowboy capture proxy + gun replay client + gen_server diff workers + ETS capture buffers + poolboy, relx release
APP_TYPE: API service
LANGUAGE: Erlang
SCALE: 200k captured requests/sec, real-time diffing, negligible added latency
```

## 66. Stormhold — high-availability queue broker

```text
APP_DESCRIPTION: A highly available AMQP-compatible broker with mirrored queues, publisher confirms, and consumer acknowledgements. It survives node loss without message loss and rebalances queue leaders automatically.
TECH_STACK: Erlang/OTP + custom AMQP handling + gen_statem per queue + ra quorum queues + Mnesia metadata + ranch listeners, relx release
APP_TYPE: API service
LANGUAGE: Erlang
SCALE: 500k messages/sec, mirrored durability, sub-second leader failover
```

## 67. Copperfield — telemetry alerting and escalation engine

```text
APP_DESCRIPTION: An alerting engine that evaluates metric and log streams against alert rules, deduplicates and groups incidents, and drives on-call escalation with acknowledgements and paging. Rules and routes reload without downtime.
TECH_STACK: Erlang/OTP + gen_statem per incident + ETS rule state + RabbitMQ notification bus + Cowboy API + PostgreSQL via epgsql, relx release
APP_TYPE: API service
LANGUAGE: Erlang
SCALE: 500k evaluations/sec, deduplicated incidents, sub-second paging
```

## 68. Driftline — GPS fleet tracking ingest

```text
APP_DESCRIPTION: A fleet tracking ingest service that receives GPS pings from vehicles, snaps to roads, computes trip segments, and streams live positions to dispatch dashboards. It handles offline buffering and out-of-order pings.
TECH_STACK: Erlang/OTP + MQTT/TCP frontend + gen_statem per vehicle + ETS position cache + PostgreSQL/PostGIS via epgsql + Cowboy WebSocket, relx release
APP_TYPE: data pipeline
LANGUAGE: Erlang
SCALE: 1M vehicles, 300k pings/sec, sub-second live position updates
```

## 69. Ashvault — audit log write pipeline

```text
APP_DESCRIPTION: A tamper-evident audit log pipeline that ingests security events, chains them with hashes, and writes to append-only storage. It guarantees ordering per tenant and supports verifiable exports for compliance.
TECH_STACK: Erlang/OTP + gen_server per tenant chain + disk_log append store + ETS staging + brod Kafka source + Cowboy query API, relx release
APP_TYPE: data pipeline
LANGUAGE: Erlang
SCALE: 400k audit events/sec, hash-chained integrity, per-tenant ordering
```

## 70. Windrose — service mesh sidecar controller

```text
APP_DESCRIPTION: A control service for a service mesh that distributes routing, retry, and mTLS policy to sidecars and collects their telemetry. It pushes config changes cluster-wide and reacts to endpoint health in real time.
TECH_STACK: Erlang/OTP + gRPC and Cowboy API + gen_statem per sidecar + Mnesia policy store + gproc watchers + distributed clustering, relx release
APP_TYPE: API service
LANGUAGE: Erlang
SCALE: 200k sidecars, sub-second config push, five-nines control-plane uptime
```

## 71. Cloudferry — bulk data export service

```text
APP_DESCRIPTION: A bulk export service that streams large query results and dataset snapshots to customer destinations like S3 and SFTP. It parallelizes across shards, resumes interrupted transfers, and throttles to protect sources.
TECH_STACK: Erlang/OTP + gen_statem per export job + poolboy workers + epgsql streaming + object storage clients + Cowboy API, relx release
APP_TYPE: data pipeline
LANGUAGE: Erlang
SCALE: 10k concurrent exports, multi-GB/s throughput, resumable transfers
```

## 72. Tidewatch — real-time leaderboard service

```text
APP_DESCRIPTION: A real-time leaderboard service for games and contests that ingests score updates and serves ranked queries and around-me windows. It shards by leaderboard, keeps sorted structures hot, and pushes rank changes live.
TECH_STACK: Erlang/OTP + gen_server per leaderboard + ETS ordered sets + eredis backup + Cowboy WebSocket + distributed clustering, relx release
APP_TYPE: API service
LANGUAGE: Erlang
SCALE: 100k leaderboards, 300k score updates/sec, <20ms rank query
```

## 73. Emberline — SMPP delivery receipt reconciler

```text
APP_DESCRIPTION: A reconciliation pipeline that matches outbound SMS submissions with asynchronous carrier delivery receipts, resolving final status and surfacing undelivered messages. It handles late and duplicate DLRs gracefully.
TECH_STACK: Erlang/OTP + gen_statem per message + Mnesia correlation store + ETS pending index + brod Kafka source + PostgreSQL via epgsql, relx release
APP_TYPE: data pipeline
LANGUAGE: Erlang
SCALE: 300k DLRs/sec reconciled, late-receipt tolerance, exactly-once status
```

## 74. Glasshollow — WebSocket API gateway

```text
APP_DESCRIPTION: A WebSocket-first API gateway that upgrades client connections, authenticates them, multiplexes subscriptions to backend services, and enforces per-connection quotas. It keeps millions of connections alive efficiently.
TECH_STACK: Erlang/OTP + Cowboy WebSocket + ranch acceptors + gen_statem per connection + ETS subscription maps + gun to backends, relx release
APP_TYPE: API service
LANGUAGE: Erlang
SCALE: 2M concurrent WebSocket connections, 200k messages/sec, <30ms round-trip
```

## 75. Marrowdeep — sensor anomaly detection pipeline

```text
APP_DESCRIPTION: An anomaly detection pipeline that scores streaming industrial sensor data against baselines and models, flagging deviations and predicting failures. It maintains per-sensor state and emits alerts with low latency.
TECH_STACK: Erlang/OTP + gen_stage stages + ETS per-sensor windows + MQTT source + RabbitMQ alert sink + PostgreSQL via epgsql, relx release
APP_TYPE: data pipeline
LANGUAGE: Erlang
SCALE: 800k sensor readings/sec, per-sensor models, sub-second anomaly alerts
```

## 76. Stonewell — distributed cache cluster

```text
APP_DESCRIPTION: A distributed in-memory cache with consistent hashing, TTL expiry, and read-through to backing stores. It replicates hot keys, rebalances on membership change, and serves reads with minimal latency across nodes.
TECH_STACK: Erlang/OTP + riak_core key distribution + gen_server shard owners + ETS storage + ranch protocol listeners + distributed clustering, relx release
APP_TYPE: API service
LANGUAGE: Erlang
SCALE: 1M cache ops/sec, consistent-hash sharding, <1ms read latency
```

## 77. Firelark — IoT command and control API

```text
APP_DESCRIPTION: A command-and-control API for IoT fleets that lets operators issue commands to devices, track acknowledgements, and roll out firmware in waves. It queues commands for offline devices and reports status in real time.
TECH_STACK: Erlang/OTP + Cowboy REST API + MQTT downlink + gen_statem per device + Mnesia command store + gproc registry, relx release
APP_TYPE: API service
LANGUAGE: Erlang
SCALE: 5M managed devices, 100k commands/sec, staged firmware rollouts
```

## 78. Brackenflow — clickstream sessionization pipeline

```text
APP_DESCRIPTION: A sessionization pipeline that groups raw web and app events into user sessions with inactivity gaps, computes session metrics, and emits enriched sessions downstream. It handles out-of-order and late events.
TECH_STACK: Erlang/OTP + gen_stage stages + ETS session windows + brod Kafka source/sink + disk_log checkpoints, relx release
APP_TYPE: data pipeline
LANGUAGE: Erlang
SCALE: 700k events/sec, per-user sessionization, late-event tolerance
```

## 79. Kestrelnet — mobile carrier signaling proxy

```text
APP_DESCRIPTION: A signaling proxy that mediates SS7/SIGTRAN and Diameter interworking between network elements, enforcing firewall rules and rate limits. It maintains stateful associations and shields the core from malformed signaling.
TECH_STACK: Erlang/OTP + SIGTRAN/SCTP stack + gen_statem per association + ETS rule tables + Mnesia state + distributed clustering, relx release
APP_TYPE: API service
LANGUAGE: Erlang
SCALE: 200k signaling messages/sec, stateful firewalling, five-nines carrier uptime
```

## 80. Amberpool — connection pool broker for databases

```text
APP_DESCRIPTION: A shared database connection broker that multiplexes many client requests over a bounded pool of backend connections, queuing fairly and shedding under overload. It supports multiple backends and health checks.
TECH_STACK: Erlang/OTP + poolboy pools + gen_statem per backend + epgsql and eredis clients + ranch client listeners + ETS metrics, relx release
APP_TYPE: API service
LANGUAGE: Erlang
SCALE: 200k queries/sec brokered, fair queuing, graceful overload shedding
```

## 81. Willowgate — omnichannel message router

```text
APP_DESCRIPTION: An omnichannel routing service that accepts inbound customer messages from SMS, chat, and email and dispatches them to available agents by skill and availability. It tracks conversations as long-lived state machines.
TECH_STACK: Erlang/OTP + gen_statem per conversation + Cowboy and WebSocket API + Mnesia routing state + gproc agent registry + RabbitMQ, relx release
APP_TYPE: API service
LANGUAGE: Erlang
SCALE: 500k concurrent conversations, 50k routes/sec, <100ms assignment
```

## 82. Slagheap — batch reprocessing pipeline

```text
APP_DESCRIPTION: A reprocessing pipeline that replays historical event archives through updated logic to backfill derived data. It parallelizes across time ranges, tracks progress durably, and resumes from failure without duplicating output.
TECH_STACK: Erlang/OTP + gen_statem per range + poolboy workers + disk_log progress store + brod Kafka source + object storage, relx release
APP_TYPE: data pipeline
LANGUAGE: Erlang
SCALE: 1M events/sec replay, parallel time-range processing, resumable backfills
```

## 83. Frostline — TLS termination and load balancer

```text
APP_DESCRIPTION: A layer-7 load balancer that terminates TLS, load-balances across upstream pools with health checks, and supports sticky sessions and connection draining. It hot-reloads certificates and pool config without dropping connections.
TECH_STACK: Erlang/OTP + ranch TLS listeners + Cowboy + gun upstream client + ETS pool tables + hot code loading, relx release
APP_TYPE: API service
LANGUAGE: Erlang
SCALE: 500k concurrent connections, 300k requests/sec, zero-downtime cert rotation
```

## 84. Pinewatch — inventory reservation service

```text
APP_DESCRIPTION: An inventory reservation service for e-commerce that holds stock during checkout, prevents oversell under concurrency, and releases expired holds. It keeps per-SKU state consistent across a clustered deployment.
TECH_STACK: Erlang/OTP + gen_statem per SKU + Mnesia stock store + ETS hot cache + Cowboy API + distributed clustering, relx release
APP_TYPE: API service
LANGUAGE: Erlang
SCALE: 200k reservations/sec, zero oversell under concurrency, five-nines uptime
```

## 85. Marlowe — CLI for cluster operations

```text
APP_DESCRIPTION: An operator CLI that connects to a live Erlang cluster to inspect processes, trace messages, roll node upgrades, and drain traffic. It talks to nodes over distribution and renders health and load at a glance.
TECH_STACK: Erlang/OTP escript + distributed Erlang RPC + recon for introspection + rebar3 build, distributed as an escript binary
APP_TYPE: CLI
LANGUAGE: Erlang
SCALE: operates on 1000-node clusters, live tracing with minimal overhead
```

## 86. Quarrystone — schema migration CLI

```text
APP_DESCRIPTION: A migration CLI for Mnesia and PostgreSQL that applies versioned schema changes across a cluster, coordinates rolling table transforms, and verifies consistency. It supports dry-run and rollback of migrations.
TECH_STACK: Erlang/OTP escript + Mnesia transforms + epgsql + rebar3, packaged as an escript binary
APP_TYPE: CLI
LANGUAGE: Erlang
SCALE: coordinates migrations across 100-node clusters, zero-downtime table transforms
```

## 87. Emberforge — load generation CLI

```text
APP_DESCRIPTION: A load testing CLI that spins up huge numbers of virtual clients to hammer MQTT, WebSocket, and HTTP endpoints, reporting latency percentiles and throughput. Each virtual client is a lightweight process.
TECH_STACK: Erlang/OTP escript + gun and MQTT clients + spawned process swarms + ETS metric aggregation + rebar3, escript binary
APP_TYPE: CLI
LANGUAGE: Erlang
SCALE: 1M virtual clients from one node, live latency histograms
```

## 88. Copperline — release deployment CLI

```text
APP_DESCRIPTION: A deployment CLI that builds relx releases, ships them to target nodes, and performs hot code upgrades with appup relups. It orchestrates rolling upgrades and rolls back on health-check failure.
TECH_STACK: Erlang/OTP escript + relx and rebar3 + distributed Erlang + release_handler + SSH transport, escript binary
APP_TYPE: CLI
LANGUAGE: Erlang
SCALE: rolling upgrades across 500 nodes, hot code swaps with zero downtime
```

## 89. Thistledown — MQTT debugging CLI

```text
APP_DESCRIPTION: An MQTT debugging CLI that subscribes to topic patterns, publishes test payloads, and inspects broker state and connected sessions. It renders live message flows and latency for troubleshooting brokers.
TECH_STACK: Erlang/OTP escript + MQTT client library + ETS message buffers + rebar3, escript binary
APP_TYPE: CLI
LANGUAGE: Erlang
SCALE: monitors brokers with 2M connections, live topic tracing
```

## 90. Gravelport — distributed trace query CLI

```text
APP_DESCRIPTION: A tracing CLI that queries a distributed trace store, reconstructs request spans across services, and highlights latency hot spots. It streams live traces from running nodes and filters by service or error.
TECH_STACK: Erlang/OTP escript + distributed Erlang + recon tracing + epgsql trace store + rebar3, escript binary
APP_TYPE: CLI
LANGUAGE: Erlang
SCALE: queries millions of spans, live cross-service trace assembly
```

## 91. Hearthspan — real-time collaboration presence API

```text
APP_DESCRIPTION: A presence and cursor-sharing API for collaborative design tools that broadcasts live cursors, selections, and viewport state between collaborators. It runs one process per room and coalesces high-frequency updates.
TECH_STACK: Erlang/OTP + Cowboy WebSocket + gen_server per room + ETS cursor state + gproc registry + distributed clustering, relx release
APP_TYPE: API service
LANGUAGE: Erlang
SCALE: 300k active rooms, 500k cursor updates/sec, <40ms broadcast
```

## 92. Oldharbor — Cowboy admin dashboard for brokers

```text
APP_DESCRIPTION: A web dashboard for operating a messaging broker cluster, showing live connection counts, topic throughput, and node health with drill-downs. Operators can disconnect clients, adjust limits, and inspect sessions.
TECH_STACK: Erlang/OTP + Cowboy web server + server-rendered pages and WebSocket updates + ETS live metrics + distributed Erlang to broker nodes, relx release
APP_TYPE: web app
LANGUAGE: Erlang
SCALE: monitors clusters serving 3M connections, sub-second live metric refresh
```

## 93. Lanternwood — status page and incident web app

```text
APP_DESCRIPTION: A public status page web app that aggregates health signals from monitored services, renders live component status, and publishes incident timelines. It pushes real-time updates to viewers during outages.
TECH_STACK: Erlang/OTP + Cowboy web server + WebSocket live updates + Mnesia incident store + gen_server health aggregators, relx release
APP_TYPE: web app
LANGUAGE: Erlang
SCALE: 500k concurrent status viewers during incidents, live push updates
```

## 94. Riverstone — live auction web app

```text
APP_DESCRIPTION: A live auction web app where bidders join rooms and place bids in real time as prices update for all participants. It runs each auction as a state machine, enforces bid rules, and closes lots on timers.
TECH_STACK: Erlang/OTP + Cowboy web server + WebSocket + gen_statem per auction + ETS bid state + PostgreSQL via epgsql, relx release
APP_TYPE: web app
LANGUAGE: Erlang
SCALE: 100k concurrent bidders, 50k bids/sec, <50ms price updates
```

## 95. Cinderhall — real-time dashboards web app

```text
APP_DESCRIPTION: A real-time operations dashboard web app that streams live metrics, alerts, and event feeds to browsers with configurable panels. It subscribes users to data streams and pushes deltas efficiently over WebSocket.
TECH_STACK: Erlang/OTP + Cowboy web server + WebSocket fan-out + gproc subscription registry + ETS metric cache + brod Kafka source, relx release
APP_TYPE: web app
LANGUAGE: Erlang
SCALE: 200k concurrent dashboard sessions, 300k metric updates/sec, <50ms delivery
```

## 96. Wetstone — multiplayer whiteboard web app

```text
APP_DESCRIPTION: A collaborative whiteboard web app where teams draw and annotate together in real time. It sequences drawing operations per board, resolves concurrent edits, and replays history for late joiners.
TECH_STACK: Erlang/OTP + Cowboy web server + WebSocket + gen_server per board + ETS op logs + PostgreSQL via epgsql snapshots, relx release
APP_TYPE: web app
LANGUAGE: Erlang
SCALE: 200k active boards, 150k ops/sec, <60ms stroke propagation
```

## 97. Nettleford — live chat support web app

```text
APP_DESCRIPTION: A customer support chat web app embedded on websites that connects visitors to agents in real time, with typing indicators, queueing, and canned responses. It routes chats by availability and persists transcripts.
TECH_STACK: Erlang/OTP + Cowboy web server + WebSocket + gen_statem per chat + gproc agent registry + PostgreSQL via epgsql, relx release
APP_TYPE: web app
LANGUAGE: Erlang
SCALE: 500k concurrent visitor chats, 50k routes/sec, sub-100ms message delivery
```

## 98. Glenwarden — real-time polling web app

```text
APP_DESCRIPTION: A live polling and Q&A web app for events where audiences vote and submit questions and results update instantly on screen. It tallies votes concurrently, prevents duplicates, and pushes live counts to all viewers.
TECH_STACK: Erlang/OTP + Cowboy web server + WebSocket + gen_server per poll + ETS vote tallies + eredis dedup, relx release
APP_TYPE: web app
LANGUAGE: Erlang
SCALE: 300k concurrent voters, 200k votes/sec, live result updates
```

## 99. Slatewind — IoT fleet management web app

```text
APP_DESCRIPTION: A fleet management web app for IoT operators to view device status, push commands, and monitor telemetry across large deployments. It streams live device state to the browser and issues control actions through the broker.
TECH_STACK: Erlang/OTP + Cowboy web server + WebSocket + MQTT backend integration + Mnesia device registry + gen_statem per device, relx release
APP_TYPE: web app
LANGUAGE: Erlang
SCALE: monitors 5M devices, 100k live state updates/sec, sub-second control actions
```

## 100. Bellhaven — trading floor market-data web app

```text
APP_DESCRIPTION: A market-data web app that streams live quotes, order book depth, and trade tickers to trader browsers with configurable watchlists. It fans a shared market feed to thousands of clients with minimal per-client cost.
TECH_STACK: Erlang/OTP + Cowboy web server + WebSocket fan-out + gproc symbol registry + ETS quote cache + distributed clustering, relx release
APP_TYPE: web app
LANGUAGE: Erlang
SCALE: 200k concurrent traders, 1M quote updates/sec, <30ms feed latency
```
