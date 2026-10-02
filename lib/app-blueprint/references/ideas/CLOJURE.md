# Clojure Blueprint Types — Copy-Paste Input Sets

Copy a fenced block into the prompt as-is, or swap individual fields.

## 1. Rulebook — insurance underwriting rules console

```text
APP_DESCRIPTION: A web console where insurance underwriters author, test, and version pricing and eligibility rules. Analysts express rules as EDN data, run them against sample policy applications in a live preview, and promote rule sets through draft, staging, and production tiers with a full change history.
TECH_STACK: Clojure (JVM) + Ring + Reitit + Integrant + next.jdbc + PostgreSQL, ClojureScript + re-frame frontend via shadow-cljs, deployed on AWS ECS Fargate
APP_TYPE: web app
LANGUAGE: Clojure
SCALE: ~400 underwriters, 12,000 rule evaluations/day, 30k versioned rule sets
```

## 2. Ledgerlight — double-entry accounting dashboard

```text
APP_DESCRIPTION: A double-entry bookkeeping dashboard for small accounting firms. It records immutable journal entries, derives balance sheets and P&L statements on the fly from the transaction log, and lets accountants drill from any figure down to the originating entries. Every posting is append-only for auditability.
TECH_STACK: Clojure (JVM) + Pedestal + Datomic + Malli validation, ClojureScript + Reagent frontend, deployed on Fly.io
APP_TYPE: web app
LANGUAGE: Clojure
SCALE: ~600 firms, 2M journal entries, 90 GB Datomic history
```

## 3. Cohortly — SaaS retention analytics dashboard

```text
APP_DESCRIPTION: A retention-analytics web app for SaaS product teams. It ingests user event streams, computes cohort retention curves, funnel conversion, and feature adoption, and renders interactive heatmaps that let PMs slice by plan, region, and signup week without writing SQL.
TECH_STACK: Clojure (JVM) + Ring + Reitit + next.jdbc + PostgreSQL + Honey SQL, ClojureScript + re-frame + Vega-Lite charts, deployed on GCP Cloud Run
APP_TYPE: web app
LANGUAGE: Clojure
SCALE: ~1,500 workspaces, 80M events indexed, 25 GB warehouse
```

## 4. Tessera — event-sourced order management console

```text
APP_DESCRIPTION: An order-management console for a wholesale distributor built on event sourcing. Every order action is captured as an immutable event, projections rebuild current order state and inventory holds, and operators can replay an order's full timeline to diagnose fulfillment issues.
TECH_STACK: Clojure (JVM) + Aleph + core.async + XTDB event log + PostgreSQL projections, ClojureScript + Reagent, deployed on Kubernetes (EKS)
APP_TYPE: web app
LANGUAGE: Clojure
SCALE: ~200 operators, 500k orders/year, 6M stored events
```

## 5. Almanac — editorial content workflow CMS

```text
APP_DESCRIPTION: A headless CMS and editorial workflow app for a digital newsroom. Writers draft articles in structured EDN blocks, editors move pieces through review states on a kanban board, and scheduled publishing pushes rendered content to the public site with rollback to any prior revision.
TECH_STACK: Clojure (JVM) + Ring + Reitit + Integrant + next.jdbc + PostgreSQL, ClojureScript + re-frame + Sente for live collaboration, deployed on DigitalOcean App Platform
APP_TYPE: web app
LANGUAGE: Clojure
SCALE: ~150 editorial staff, 40k articles, 3k publishes/month
```

## 6. Signalboard — real-time ops monitoring dashboard

```text
APP_DESCRIPTION: A real-time operations dashboard for a delivery logistics company. It streams driver locations, order statuses, and SLA timers over websockets, aggregates fleet health metrics, and raises visual alerts when a route slips behind schedule so dispatchers can intervene.
TECH_STACK: Clojure (JVM) + Aleph + manifold + core.async + Sente websockets + Redis pub/sub, ClojureScript + Reagent, deployed on AWS ECS Fargate
APP_TYPE: web app
LANGUAGE: Clojure
SCALE: ~3,000 concurrent viewers, 12k live vehicles, 5k msgs/sec
```

## 7. Quorum — board governance and voting portal

```text
APP_DESCRIPTION: A governance portal for corporate boards and cooperatives. Members review meeting agendas, cast recorded votes on resolutions, and access an immutable minute book. Resolution outcomes and quorum calculations are derived from the append-only vote log for legal defensibility.
TECH_STACK: Clojure (JVM) + Pedestal + Datomic + Buddy auth, ClojureScript + re-frame frontend, deployed on Fly.io
APP_TYPE: web app
LANGUAGE: Clojure
SCALE: ~800 organizations, 25k members, 400k recorded votes
```

## 8. Palette — design token management studio

```text
APP_DESCRIPTION: A web studio where design systems teams manage color, spacing, and typography tokens as versioned data. Editors preview tokens across light and dark themes, diff proposed changes, and export platform-specific artifacts for web, iOS, and Android from a single source of truth.
TECH_STACK: ClojureScript + re-frame + Reagent (shadow-cljs) frontend, Clojure (JVM) + Ring + Reitit + XTDB backend, deployed on Netlify + Fly.io
APP_TYPE: web app
LANGUAGE: Clojure
SCALE: ~500 teams, 60k tokens, 8k exports/week
```

## 9. Fathom — cohort survey analytics app

```text
APP_DESCRIPTION: A survey analytics web app for UX researchers. It collects longitudinal survey responses, groups respondents into cohorts, and computes sentiment trends and cross-tab breakdowns. Researchers build filtered segments interactively and export shareable report snapshots.
TECH_STACK: Clojure (JVM) + Ring + Reitit + next.jdbc + PostgreSQL + Honey SQL, ClojureScript + re-frame + Vega charts, deployed on Railway
APP_TYPE: web app
LANGUAGE: Clojure
SCALE: ~700 research seats, 3M survey responses, 20 GB data
```

## 10. Warden — RBAC administration console

```text
APP_DESCRIPTION: A role-based access control admin console for enterprise platform teams. Admins model roles, permissions, and resource scopes as data, simulate the effective permissions of any user, and audit every grant change. Policy decisions are computed from an immutable permission graph.
TECH_STACK: Clojure (JVM) + Ring + Reitit + Integrant + next.jdbc + PostgreSQL, ClojureScript + Reagent, deployed on Kubernetes (GKE)
APP_TYPE: web app
LANGUAGE: Clojure
SCALE: ~250 admins, 40k managed users, 1.2M permission edges
```

## 11. Loomstate — supply-chain visibility dashboard

```text
APP_DESCRIPTION: A supply-chain visibility web app for a textile manufacturer. It maps purchase orders, shipments, and factory milestones onto an interactive timeline, flags at-risk deliveries, and lets planners trace any finished good back to its raw-material lots.
TECH_STACK: Clojure (JVM) + Pedestal + next.jdbc + PostgreSQL + core.async, ClojureScript + re-frame frontend, deployed on AWS ECS Fargate
APP_TYPE: web app
LANGUAGE: Clojure
SCALE: ~350 planners, 120k active POs, 2M shipment events
```

## 12. Cadence — clinical trial scheduling portal

```text
APP_DESCRIPTION: A scheduling portal for clinical trial coordinators. It manages participant visit windows, protocol-driven procedure checklists, and site capacity, then generates compliant visit calendars and flags protocol deviations before they occur.
TECH_STACK: Clojure (JVM) + Ring + Reitit + Malli + next.jdbc + PostgreSQL, ClojureScript + re-frame frontend, deployed on Azure Container Apps
APP_TYPE: web app
LANGUAGE: Clojure
SCALE: ~120 trial sites, 30k participants, 500k scheduled visits
```

## 13. Beacon — municipal 311 request tracker

```text
APP_DESCRIPTION: A citizen service request tracker for a mid-size city. Residents report potholes, outages, and noise complaints; the app routes each case to the right department, tracks resolution SLAs on a public map, and publishes open-data metrics on response times.
TECH_STACK: Clojure (JVM) + Ring + Reitit + next.jdbc + PostGIS, ClojureScript + Reagent + MapLibre, deployed on DigitalOcean App Platform
APP_TYPE: web app
LANGUAGE: Clojure
SCALE: ~200k residents, 90k requests/year, 40 departments
```

## 14. Ledgerloom — immutable audit-trail viewer

```text
APP_DESCRIPTION: A web viewer for compliance officers to browse immutable audit trails across internal systems. It ingests append-only event records, reconstructs entity state at any point in time, and lets investigators diff two moments and export tamper-evident evidence bundles.
TECH_STACK: Clojure (JVM) + Pedestal + XTDB bitemporal store + Malli, ClojureScript + re-frame frontend, deployed on Fly.io
APP_TYPE: web app
LANGUAGE: Clojure
SCALE: ~180 compliance users, 50M audit events, 120 GB history
```

## 15. Ferry — logistics dispatch board

```text
APP_DESCRIPTION: A live dispatch board for a regional courier network. Dispatchers drag jobs onto driver lanes, the app recomputes ETAs and load balance in real time, and drivers receive updated manifests instantly. Assignment history is retained for payroll reconciliation.
TECH_STACK: Clojure (JVM) + Aleph + Sente websockets + core.async + Redis + PostgreSQL, ClojureScript + Reagent, deployed on AWS ECS Fargate
APP_TYPE: web app
LANGUAGE: Clojure
SCALE: ~500 dispatchers, 4k drivers, 60k jobs/day
```

## 16. Verdant — carbon accounting dashboard

```text
APP_DESCRIPTION: A carbon accounting web app for sustainability teams. It ingests activity data across facilities, applies emission factors as versioned data tables, and produces auditable scope 1, 2, and 3 breakdowns with year-over-year trend charts and export-ready disclosures.
TECH_STACK: Clojure (JVM) + Ring + Reitit + next.jdbc + PostgreSQL + Honey SQL, ClojureScript + re-frame + Vega-Lite, deployed on GCP Cloud Run
APP_TYPE: web app
LANGUAGE: Clojure
SCALE: ~400 companies, 2M activity records, 15 GB data
```

## 17. Choir — collaborative setlist planner

```text
APP_DESCRIPTION: A collaborative planning app for choirs and worship teams. Members co-edit song setlists in real time, attach keys and arrangements, and vote on selections. Scheduling suggestions are derived from rehearsal history and member availability.
TECH_STACK: ClojureScript + re-frame + Sente (shadow-cljs) frontend, Clojure (JVM) + Ring + Reitit + Datascript-backed sync + PostgreSQL, deployed on Railway
APP_TYPE: web app
LANGUAGE: Clojure
SCALE: ~2,000 groups, 30k members, 100k setlists
```

## 18. Mesa — data catalog and lineage explorer

```text
APP_DESCRIPTION: An internal data catalog where analysts discover tables, columns, and dashboards across the warehouse. It parses SQL to build a lineage graph, surfaces ownership and freshness metadata, and lets users trace any metric upstream to its raw sources.
TECH_STACK: Clojure (JVM) + Pedestal + next.jdbc + PostgreSQL + core.async crawlers, ClojureScript + Reagent graph view, deployed on Kubernetes (EKS)
APP_TYPE: web app
LANGUAGE: Clojure
SCALE: ~900 analysts, 40k datasets, 300k lineage edges
```

## 19. Riffle — feature-flag management console

```text
APP_DESCRIPTION: A feature-flag management console for engineering orgs. Teams define flags and targeting rules as data, roll out percentages by segment, and watch live exposure metrics. Every flag change is versioned with instant rollback and an audit log.
TECH_STACK: Clojure (JVM) + Ring + Reitit + Integrant + next.jdbc + PostgreSQL + Redis, ClojureScript + re-frame frontend, deployed on Fly.io
APP_TYPE: web app
LANGUAGE: Clojure
SCALE: ~600 teams, 25k flags, 40k rule changes/month
```

## 20. Steward — grant application review portal

```text
APP_DESCRIPTION: A grant review portal for a philanthropic foundation. Applicants submit structured proposals, reviewers score them against weighted rubrics, and program officers rank cohorts and manage award decisions with a full deliberation history retained for compliance.
TECH_STACK: Clojure (JVM) + Ring + Reitit + Malli + next.jdbc + PostgreSQL, ClojureScript + re-frame frontend, deployed on Azure Container Apps
APP_TYPE: web app
LANGUAGE: Clojure
SCALE: ~300 reviewers, 12k applications/cycle, 5k awards
```

## 21. Tallyhouse — election results tabulation dashboard

```text
APP_DESCRIPTION: A results tabulation dashboard for a county election board. It ingests precinct-level tallies, computes running totals and turnout by district, and renders live maps and swing charts while preserving an immutable record of every reported batch for canvass audits.
TECH_STACK: Clojure (JVM) + Aleph + core.async + XTDB + PostGIS, ClojureScript + Reagent + MapLibre, deployed on self-hosted uberjar behind Nginx
APP_TYPE: web app
LANGUAGE: Clojure
SCALE: ~1,200 precincts, 800k ballots, 50 concurrent staff
```

## 22. Meridian — timezone-aware team scheduler

```text
APP_DESCRIPTION: A scheduling web app for distributed teams. It reconciles members' working hours across timezones, proposes optimal meeting windows, and manages rotating on-call shifts with fair-distribution rules computed from historical coverage.
TECH_STACK: Clojure (JVM) + Ring + Reitit + next.jdbc + PostgreSQL + tick time library, ClojureScript + re-frame frontend, deployed on Railway
APP_TYPE: web app
LANGUAGE: Clojure
SCALE: ~1,000 teams, 18k members, 200k scheduled events
```

## 23. Provenance — art collection cataloging app

```text
APP_DESCRIPTION: A cataloging web app for galleries and private collectors. It records artworks, exhibition history, and ownership chains as bitemporal data, generates condition reports, and lets curators trace provenance and valuation over time with an immutable record.
TECH_STACK: Clojure (JVM) + Pedestal + XTDB bitemporal store + Malli, ClojureScript + Reagent frontend, deployed on Fly.io
APP_TYPE: web app
LANGUAGE: Clojure
SCALE: ~350 collections, 200k artworks, 1M provenance records
```

## 24. Foundry — internal developer platform portal

```text
APP_DESCRIPTION: An internal developer platform portal where engineers browse a service catalog, self-serve new environments from golden templates, and view ownership, dependencies, and deploy status per service. Scorecards derive service health from CI, incident, and coverage data.
TECH_STACK: Clojure (JVM) + Ring + Reitit + Integrant + next.jdbc + PostgreSQL + core.async, ClojureScript + re-frame frontend, deployed on Kubernetes (GKE)
APP_TYPE: web app
LANGUAGE: Clojure
SCALE: ~2,000 engineers, 1,500 services, 8k deploys/week
```

## 25. Cascade — incident postmortem tracker

```text
APP_DESCRIPTION: An incident and postmortem tracker for SRE teams. It captures incident timelines, links contributing signals, and guides blameless retro authoring. Action items are tracked to closure and aggregate reliability trends are computed across incident history.
TECH_STACK: Clojure (JVM) + Ring + Reitit + next.jdbc + PostgreSQL, ClojureScript + re-frame frontend, deployed on AWS ECS Fargate
APP_TYPE: web app
LANGUAGE: Clojure
SCALE: ~400 responders, 6k incidents, 20k action items
```

## 26. Harbor — vendor onboarding workflow

```text
APP_DESCRIPTION: A vendor onboarding workflow app for procurement teams. It collects vendor documents, runs configurable approval chains as data-driven state machines, and tracks compliance expirations, surfacing a live view of where each vendor sits in the pipeline.
TECH_STACK: Clojure (JVM) + Ring + Reitit + Malli + next.jdbc + PostgreSQL, ClojureScript + Reagent frontend, deployed on DigitalOcean App Platform
APP_TYPE: web app
LANGUAGE: Clojure
SCALE: ~250 buyers, 15k vendors, 40k documents
```

## 27. Loft — real-estate listing management console

```text
APP_DESCRIPTION: A listing management console for a real-estate brokerage. Agents manage property listings, schedule showings, and track offer negotiations, while managers monitor pipeline velocity and commission forecasts derived from deal-stage history.
TECH_STACK: Clojure (JVM) + Ring + Reitit + next.jdbc + PostgreSQL + Honey SQL, ClojureScript + re-frame frontend, deployed on Railway
APP_TYPE: web app
LANGUAGE: Clojure
SCALE: ~800 agents, 40k listings, 12k deals/year
```

## 28. Kiln — bakery recipe and inventory app

```text
APP_DESCRIPTION: A production and inventory web app for artisan bakeries. It scales recipes by batch, deducts ingredient stock as bakes are logged, forecasts reorder points, and computes per-item costing from live ingredient prices.
TECH_STACK: Clojure (JVM) + Ring + Reitit + next.jdbc + PostgreSQL, ClojureScript + Reagent frontend, deployed on Fly.io
APP_TYPE: web app
LANGUAGE: Clojure
SCALE: ~600 bakeries, 30k recipes, 5k daily bake logs
```

## 29. Sentinel — compliance evidence portal

```text
APP_DESCRIPTION: A compliance evidence collection portal for teams pursuing SOC 2 and ISO 27001. It maps controls to required evidence, auto-collects artifacts from integrations, tracks control status, and assembles auditor-ready packages with an immutable trail of every submission.
TECH_STACK: Clojure (JVM) + Pedestal + next.jdbc + PostgreSQL + core.async collectors, ClojureScript + re-frame frontend, deployed on Kubernetes (EKS)
APP_TYPE: web app
LANGUAGE: Clojure
SCALE: ~500 companies, 200 controls each, 300k evidence artifacts
```

## 30. Chorus — customer feedback triage board

```text
APP_DESCRIPTION: A customer feedback triage board for product teams. It aggregates feedback from support, reviews, and surveys, clusters similar requests, and links them to roadmap items. Impact scores are computed from account value and mention frequency.
TECH_STACK: Clojure (JVM) + Ring + Reitit + next.jdbc + PostgreSQL + core.async, ClojureScript + re-frame frontend, deployed on GCP Cloud Run
APP_TYPE: web app
LANGUAGE: Clojure
SCALE: ~700 product teams, 400k feedback items, 30k roadmap links
```

## 31. Tollgate — API rate-limiting and quota service

```text
APP_DESCRIPTION: An API service that enforces rate limits and usage quotas for a multi-tenant platform. It evaluates token-bucket and sliding-window policies per key at the edge, meters usage for billing, and exposes real-time quota status to client dashboards.
TECH_STACK: Clojure (JVM) + Aleph + manifold + Redis + PostgreSQL + Malli, deployed on Kubernetes (EKS)
APP_TYPE: API service
LANGUAGE: Clojure
SCALE: ~30,000 req/sec peak, 8k API keys, sub-5ms decision latency
```

## 32. Cartographer — geospatial routing API

```text
APP_DESCRIPTION: A geospatial routing API for delivery and field-service apps. It computes shortest and time-windowed routes over a road graph, batches multi-stop optimization, and returns turn-by-turn geometry. Route requests and results are cached for repeat lookups.
TECH_STACK: Clojure (JVM) + Reitit + Ring + PostGIS + Redis + core.async, deployed on AWS ECS Fargate
APP_TYPE: API service
LANGUAGE: Clojure
SCALE: ~6,000 route req/sec, 40M road edges, 200 GB graph
```

## 33. Vellum — document generation API

```text
APP_DESCRIPTION: A document generation API that renders contracts, invoices, and statements from templates and structured EDN data. It merges data into layouts, produces PDFs at scale, and returns signed URLs. Template versions are retained so any historical document can be re-rendered.
TECH_STACK: Clojure (JVM) + Reitit + Ring + next.jdbc + PostgreSQL + S3 + core.async workers, deployed on AWS ECS Fargate
APP_TYPE: API service
LANGUAGE: Clojure
SCALE: ~2,000 docs/sec peak, 50M documents/year, 5 GB templates
```

## 34. Envoyage — transactional email dispatch API

```text
APP_DESCRIPTION: A transactional email dispatch API for product teams. It accepts templated send requests, renders per-recipient content, throttles by provider limits, and tracks delivery, bounce, and open events. Sends are queued durably and retried with backoff.
TECH_STACK: Clojure (JVM) + Aleph + Kafka via jackdaw + PostgreSQL + Redis, deployed on Kubernetes (GKE)
APP_TYPE: API service
LANGUAGE: Clojure
SCALE: ~10,000 sends/sec peak, 300M emails/month, 4k tenants
```

## 35. Assay — feature-flag evaluation API

```text
APP_DESCRIPTION: A low-latency feature-flag evaluation API. Client SDKs request flag decisions for a user context; the service evaluates targeting rules, returns variants, and streams config updates. Exposure events are recorded for experiment analysis.
TECH_STACK: Clojure (JVM) + Aleph + manifold + Redis + PostgreSQL + Malli, deployed on Fly.io multi-region
APP_TYPE: API service
LANGUAGE: Clojure
SCALE: ~25,000 eval req/sec, 20k flags, sub-3ms p99
```

## 36. Keymaster — OAuth2/OIDC token service

```text
APP_DESCRIPTION: An OAuth2 and OpenID Connect authorization service for a platform ecosystem. It handles authorization-code and client-credentials flows, issues and rotates signed JWTs, manages consent, and exposes token introspection and revocation endpoints.
TECH_STACK: Clojure (JVM) + Reitit + Ring + Buddy + next.jdbc + PostgreSQL + Redis, deployed on Kubernetes (EKS)
APP_TYPE: API service
LANGUAGE: Clojure
SCALE: ~8,000 token req/sec, 2M active sessions, 5k client apps
```

## 37. Ledgerwire — payments ledger API

```text
APP_DESCRIPTION: A payments ledger API providing strongly consistent double-entry balances. It records money movements as immutable postings, enforces balance invariants transactionally, and exposes account balances and statement history. Idempotency keys guard against duplicate charges.
TECH_STACK: Clojure (JVM) + Reitit + Ring + next.jdbc + PostgreSQL (serializable) + Malli, deployed on AWS ECS Fargate
APP_TYPE: API service
LANGUAGE: Clojure
SCALE: ~4,000 postings/sec, 80M accounts, 500M postings/year
```

## 38. Slate — headless CMS content API

```text
APP_DESCRIPTION: A headless CMS content API exposing structured content over GraphQL. Editors' content models become a typed schema, clients query exactly the fields they need, and published content is served from a read-optimized cache with per-locale variants.
TECH_STACK: Clojure (JVM) + Lacinia GraphQL + Ring + next.jdbc + PostgreSQL + Redis, deployed on GCP Cloud Run
APP_TYPE: API service
LANGUAGE: Clojure
SCALE: ~5,000 queries/sec, 2k content models, 40M content nodes
```

## 39. Reckon — tax calculation API

```text
APP_DESCRIPTION: A sales-tax and VAT calculation API for e-commerce checkouts. It resolves jurisdiction from address, applies versioned rate tables and product taxability rules as data, and returns line-item tax breakdowns with a reproducible calculation trace.
TECH_STACK: Clojure (JVM) + Reitit + Ring + next.jdbc + PostgreSQL + Malli, deployed on AWS Lambda (via HikariCP proxy)
APP_TYPE: API service
LANGUAGE: Clojure
SCALE: ~7,000 calc req/sec, 12k jurisdictions, 3M rate rules
```

## 40. Waypoint — geofencing events API

```text
APP_DESCRIPTION: A geofencing API for mobility apps. Clients register polygonal zones and stream device positions; the service detects enter, dwell, and exit events, debounces noise, and delivers callbacks. Zone definitions and event history are queryable.
TECH_STACK: Clojure (JVM) + Aleph + core.async + PostGIS + Redis, deployed on Kubernetes (GKE)
APP_TYPE: API service
LANGUAGE: Clojure
SCALE: ~15,000 position updates/sec, 200k geofences, 3M events/day
```

## 41. Curator — product catalog GraphQL API

```text
APP_DESCRIPTION: A product catalog API for a retail platform, served over GraphQL. It exposes products, variants, pricing, and availability with faceted search and returns exactly the fields storefronts request. Catalog reads are cache-accelerated and inventory is near real time.
TECH_STACK: Clojure (JVM) + Lacinia GraphQL + Ring + next.jdbc + PostgreSQL + Elasticsearch + Redis, deployed on AWS ECS Fargate
APP_TYPE: API service
LANGUAGE: Clojure
SCALE: ~9,000 queries/sec, 4M SKUs, 300 storefronts
```

## 42. Ledgerbook — invoicing API

```text
APP_DESCRIPTION: An invoicing API for B2B billing. It generates invoices from usage and subscription data, tracks payment states, applies dunning schedules, and exposes aging reports. Every invoice revision is versioned for audit and dispute handling.
TECH_STACK: Clojure (JVM) + Reitit + Ring + next.jdbc + PostgreSQL + core.async workers, deployed on Fly.io
APP_TYPE: API service
LANGUAGE: Clojure
SCALE: ~1,500 req/sec, 6k billing accounts, 10M invoices/year
```

## 43. Pulsecheck — health-check aggregation API

```text
APP_DESCRIPTION: A health-check aggregation API that probes registered services and dependencies, rolls up status into system-level health, and exposes both a summary endpoint and per-check history. It computes uptime SLAs and emits alerts on state transitions.
TECH_STACK: Clojure (JVM) + Aleph + manifold + core.async + PostgreSQL + Redis, deployed on Kubernetes (EKS)
APP_TYPE: API service
LANGUAGE: Clojure
SCALE: ~2,000 checks/sec, 30k monitored endpoints, 90-day history
```

## 44. Nomad — device provisioning API

```text
APP_DESCRIPTION: A device provisioning and configuration API for an IoT fleet. Devices enroll, fetch signed config bundles, and report state; the service manages rollout groups, staged config versions, and certificate lifecycle with an audit of every provisioning action.
TECH_STACK: Clojure (JVM) + Reitit + Ring + Buddy + next.jdbc + PostgreSQL + MQTT bridge, deployed on Azure Container Apps
APP_TYPE: API service
LANGUAGE: Clojure
SCALE: ~500k enrolled devices, 3,000 config fetches/sec, 40 rollout groups
```

## 45. Verify — KYC identity verification API

```text
APP_DESCRIPTION: A KYC and identity verification API for fintech onboarding. It orchestrates document checks, watchlist screening, and liveness signals across providers, returns a normalized risk decision, and retains an immutable verification record for regulators.
TECH_STACK: Clojure (JVM) + Reitit + Ring + core.async + next.jdbc + PostgreSQL + provider connectors, deployed on AWS ECS Fargate
APP_TYPE: API service
LANGUAGE: Clojure
SCALE: ~1,200 verifications/sec peak, 20M checks/year, 8 providers
```

## 46. Tally — polling and voting backend API

```text
APP_DESCRIPTION: A polling backend API powering live audience voting during broadcasts. It accepts high-burst votes, enforces one-vote rules, tallies results in real time, and exposes streaming aggregates. Raw votes are retained immutably for verification.
TECH_STACK: Clojure (JVM) + Aleph + core.async + Redis + Kafka via jackdaw, deployed on Kubernetes (GKE)
APP_TYPE: API service
LANGUAGE: Clojure
SCALE: ~40,000 votes/sec peak, 200 concurrent polls, 500M votes/month
```

## 47. Scribe — audit-log ingestion API

```text
APP_DESCRIPTION: An audit-log ingestion API for security teams. Services emit structured audit events; the API validates, enriches, and durably stores them in a tamper-evident, append-only ledger, then serves filtered queries and export bundles for investigations.
TECH_STACK: Clojure (JVM) + Aleph + Malli + Kafka via jackdaw + XTDB, deployed on Kubernetes (EKS)
APP_TYPE: API service
LANGUAGE: Clojure
SCALE: ~20,000 events/sec, 100B events retained, 400 source services
```

## 48. Fanout — webhook delivery API

```text
APP_DESCRIPTION: A reliable webhook delivery API. Producers publish events; the service fans them out to subscriber endpoints with signing, retries, and circuit breaking, and exposes per-endpoint delivery logs and replay. Dead-letter events are queryable.
TECH_STACK: Clojure (JVM) + Aleph + manifold + core.async + Kafka via jackdaw + PostgreSQL, deployed on Fly.io multi-region
APP_TYPE: API service
LANGUAGE: Clojure
SCALE: ~12,000 deliveries/sec, 30k endpoints, 400M events/day
```

## 49. Cipherbox — secrets management API

```text
APP_DESCRIPTION: A secrets management API for application platforms. It stores encrypted secrets, issues short-lived dynamic credentials, enforces per-path access policies as data, and logs every read. Secrets are versioned with instant rollback and rotation hooks.
TECH_STACK: Clojure (JVM) + Reitit + Ring + Buddy + next.jdbc + PostgreSQL + envelope encryption (KMS), deployed on Kubernetes (EKS)
APP_TYPE: API service
LANGUAGE: Clojure
SCALE: ~5,000 secret reads/sec, 200k secrets, 2k services
```

## 50. Timetable — scheduling and availability API

```text
APP_DESCRIPTION: A scheduling API that manages resource availability and bookings for appointment apps. It computes free slots from calendars and buffer rules, holds and confirms reservations transactionally, and prevents double-booking under concurrency.
TECH_STACK: Clojure (JVM) + Reitit + Ring + next.jdbc + PostgreSQL + Redis + tick, deployed on Railway
APP_TYPE: API service
LANGUAGE: Clojure
SCALE: ~3,000 req/sec, 500k resources, 8M bookings/month
```

## 51. Loomwork — workflow orchestration API

```text
APP_DESCRIPTION: A workflow orchestration API where clients define multi-step business processes as data-driven state machines. The service runs steps, handles retries and compensation, tracks each instance's position, and exposes run history for debugging.
TECH_STACK: Clojure (JVM) + Reitit + Ring + core.async + next.jdbc + PostgreSQL + Malli, deployed on AWS ECS Fargate
APP_TYPE: API service
LANGUAGE: Clojure
SCALE: ~2,000 step executions/sec, 40k workflow definitions, 5M runs/month
```

## 52. Quill — notification preferences API

```text
APP_DESCRIPTION: A notification preferences and delivery API. It stores per-user channel preferences and quiet hours, resolves which channels to use for each event type, and dispatches to email, push, and SMS providers with delivery tracking.
TECH_STACK: Clojure (JVM) + Reitit + Ring + next.jdbc + PostgreSQL + core.async + provider connectors, deployed on GCP Cloud Run
APP_TYPE: API service
LANGUAGE: Clojure
SCALE: ~6,000 notifications/sec, 15M users, 200 event types
```

## 53. Bazaar — multi-tenant marketplace API

```text
APP_DESCRIPTION: A marketplace backend API connecting buyers and sellers. It manages listings, carts, orders, and payouts across tenants, enforces per-tenant business rules, and exposes order lifecycle events. Financial records are append-only for settlement.
TECH_STACK: Clojure (JVM) + Reitit + Ring + next.jdbc + PostgreSQL + Kafka via jackdaw + Redis, deployed on Kubernetes (GKE)
APP_TYPE: API service
LANGUAGE: Clojure
SCALE: ~4,000 req/sec, 3k tenants, 20M orders/year
```

## 54. Ledgerguard — fraud-scoring API

```text
APP_DESCRIPTION: A real-time fraud-scoring API for transactions. It evaluates rules and computed features against incoming events, returns a risk score and decision within tight latency, and records every scored event for model retraining and dispute review.
TECH_STACK: Clojure (JVM) + Aleph + manifold + Redis + PostgreSQL + Malli rules, deployed on AWS ECS Fargate
APP_TYPE: API service
LANGUAGE: Clojure
SCALE: ~8,000 scores/sec, sub-20ms p99, 300M events/month
```

## 55. Sift — search and indexing API

```text
APP_DESCRIPTION: A search API for content platforms. It ingests documents, maintains inverted and vector indexes, and serves ranked, faceted, and typo-tolerant queries with per-tenant relevance tuning. Index updates are near real time.
TECH_STACK: Clojure (JVM) + Reitit + Ring + Elasticsearch + core.async indexers + PostgreSQL, deployed on Kubernetes (EKS)
APP_TYPE: API service
LANGUAGE: Clojure
SCALE: ~10,000 queries/sec, 80M documents, 500 tenants
```

## 56. Cohesion — customer data platform API

```text
APP_DESCRIPTION: A customer data platform API that ingests identity and behavioral events, resolves them into unified profiles, and serves real-time trait lookups and audience membership to activation tools. Identity merges are recorded immutably.
TECH_STACK: Clojure (JVM) + Aleph + Kafka via jackdaw + next.jdbc + PostgreSQL + Redis, deployed on Kubernetes (GKE)
APP_TYPE: API service
LANGUAGE: Clojure
SCALE: ~18,000 events/sec, 60M profiles, 4k audiences
```

## 57. Lantern — feature-usage metering API

```text
APP_DESCRIPTION: A usage metering API for consumption-based billing. It ingests raw usage events, aggregates them into billable meters against pricing plans, and exposes current usage and projected cost. Aggregations are recomputable from the immutable event log.
TECH_STACK: Clojure (JVM) + Aleph + Kafka via jackdaw + PostgreSQL + core.async, deployed on AWS ECS Fargate
APP_TYPE: API service
LANGUAGE: Clojure
SCALE: ~14,000 usage events/sec, 5k accounts, 2B events/month
```

## 58. Compass — recommendation API

```text
APP_DESCRIPTION: A recommendation API serving personalized item suggestions for a content and commerce app. It combines collaborative signals and business rules, returns ranked recommendations with explanations, and logs impressions for offline evaluation.
TECH_STACK: Clojure (JVM) + Reitit + Ring + Redis + PostgreSQL + core.async feature loaders, deployed on GCP Cloud Run
APP_TYPE: API service
LANGUAGE: Clojure
SCALE: ~9,000 rec req/sec, 30M users, 5M catalog items
```

## 59. Strongroom — encryption-at-rest gateway API

```text
APP_DESCRIPTION: An encryption gateway API that transparently encrypts and tokenizes sensitive fields for downstream apps. It manages data keys, performs format-preserving tokenization, enforces access policy per field, and logs every decrypt for compliance.
TECH_STACK: Clojure (JVM) + Aleph + Buddy + next.jdbc + PostgreSQL + KMS envelope encryption, deployed on Kubernetes (EKS)
APP_TYPE: API service
LANGUAGE: Clojure
SCALE: ~7,000 crypto ops/sec, 40M tokenized values, 300 client apps
```

## 60. Relay — GraphQL federation gateway

```text
APP_DESCRIPTION: A GraphQL federation gateway that composes multiple domain subgraphs into one unified schema. It plans and executes cross-service queries, batches and caches resolvers, enforces auth at the edge, and exposes query traces for performance tuning.
TECH_STACK: Clojure (JVM) + Lacinia + Aleph + core.async + Redis, deployed on Kubernetes (GKE)
APP_TYPE: API service
LANGUAGE: Clojure
SCALE: ~11,000 queries/sec, 40 subgraphs, sub-40ms p95
```

## 61. Sluice — Kafka clickstream ETL pipeline

```text
APP_DESCRIPTION: A streaming ETL pipeline that consumes raw clickstream events from Kafka, validates and normalizes them, enriches with user and geo dimensions, and writes conformed events to the warehouse. Malformed records are routed to a dead-letter topic for replay.
TECH_STACK: Clojure (JVM) + Kafka via jackdaw + core.async + Malli + next.jdbc + Snowflake sink, orchestrated with Integrant, deployed on Kubernetes (EKS)
APP_TYPE: data pipeline
LANGUAGE: Clojure
SCALE: ~50,000 events/sec, 4B events/day, 300 event schemas
```

## 62. Watershed — event-stream aggregation pipeline

```text
APP_DESCRIPTION: A stream aggregation pipeline that computes windowed rollups over product events. It maintains tumbling and sliding windows in state, emits per-minute and hourly aggregates, and handles late-arriving data with watermarks. Results feed downstream dashboards.
TECH_STACK: Clojure (JVM) + Kafka Streams via jackdaw + core.async + RocksDB state + PostgreSQL sink, deployed on Kubernetes (GKE)
APP_TYPE: data pipeline
LANGUAGE: Clojure
SCALE: ~30,000 events/sec, 2M keyed windows, 10 GB state
```

## 63. Distill — log parsing and enrichment pipeline

```text
APP_DESCRIPTION: A log processing pipeline that ingests unstructured application logs, parses them into structured fields with grok-style patterns, enriches with service metadata, and ships them to a search store. It samples high-volume sources and drops known noise.
TECH_STACK: Clojure (JVM) + core.async + Aleph ingestion + Malli + Elasticsearch sink, deployed on AWS ECS Fargate
APP_TYPE: data pipeline
LANGUAGE: Clojure
SCALE: ~40,000 lines/sec, 2 TB/day, 500 source services
```

## 64. Winnow — data quality validation pipeline

```text
APP_DESCRIPTION: A data quality pipeline that runs configurable expectation checks over incoming datasets. It profiles columns, asserts constraints expressed as data, quarantines failing batches, and publishes quality scorecards and alerts to data owners.
TECH_STACK: Clojure (JVM) + next.jdbc + PostgreSQL + Malli + Tablecloth (dataset) + core.async, orchestrated with Integrant, deployed on Kubernetes (EKS)
APP_TYPE: data pipeline
LANGUAGE: Clojure
SCALE: ~2,000 batches/day, 5k expectation rules, 40 GB scanned/day
```

## 65. Tributary — change-data-capture replication pipeline

```text
APP_DESCRIPTION: A CDC pipeline that streams row-level changes from operational databases into an analytics store. It reads the transaction log, transforms change events, preserves ordering per key, and applies upserts idempotently with schema-evolution handling.
TECH_STACK: Clojure (JVM) + Debezium via Kafka + jackdaw + core.async + next.jdbc + BigQuery sink, deployed on GCP GKE
APP_TYPE: data pipeline
LANGUAGE: Clojure
SCALE: ~20,000 changes/sec, 600 source tables, 1B rows synced
```

## 66. Alluvium — batch analytics rollup pipeline

```text
APP_DESCRIPTION: A nightly batch pipeline that rolls raw fact tables into aggregated marts. It computes daily, weekly, and cohort aggregates, applies slowly-changing dimension logic, and materializes summary tables that power reporting, with reproducible reruns.
TECH_STACK: Clojure (JVM) + next.jdbc + PostgreSQL + Honey SQL + Tablecloth + core.async, orchestrated with Integrant, deployed on AWS ECS scheduled tasks
APP_TYPE: data pipeline
LANGUAGE: Clojure
SCALE: ~500M fact rows/night, 200 mart tables, 3-hour window
```

## 67. Prism — telemetry fan-out pipeline

```text
APP_DESCRIPTION: A telemetry routing pipeline that receives metrics and traces, tags and samples them by rules, and fans them out to multiple observability backends. It buffers durably during backend outages and replays without data loss.
TECH_STACK: Clojure (JVM) + Aleph ingestion + core.async + Kafka via jackdaw + backend exporters, deployed on Kubernetes (EKS)
APP_TYPE: data pipeline
LANGUAGE: Clojure
SCALE: ~60,000 spans/sec, 5 backends, 3B spans/day
```

## 68. Thresher — IoT sensor ingestion pipeline

```text
APP_DESCRIPTION: An IoT ingestion pipeline for industrial sensors. It receives high-frequency readings over MQTT, decodes device payloads, downsamples and detects out-of-range values, and stores time series for monitoring. Gap-filling handles intermittent connectivity.
TECH_STACK: Clojure (JVM) + MQTT bridge + core.async + Malli + TimescaleDB sink, orchestrated with Component, deployed on Azure Kubernetes Service
APP_TYPE: data pipeline
LANGUAGE: Clojure
SCALE: ~80,000 readings/sec, 200k sensors, 5B points/day
```

## 69. Percolate — real-time feature computation pipeline

```text
APP_DESCRIPTION: A feature pipeline that computes model features from live event streams for online serving. It maintains rolling aggregates and joins reference data, writes features to a low-latency store, and keeps offline and online definitions consistent.
TECH_STACK: Clojure (JVM) + Kafka via jackdaw + core.async + Redis feature store + PostgreSQL, deployed on Kubernetes (GKE)
APP_TYPE: data pipeline
LANGUAGE: Clojure
SCALE: ~25,000 events/sec, 800 features, sub-second freshness
```

## 70. Delta — CDC-to-warehouse sync pipeline

```text
APP_DESCRIPTION: A warehouse sync pipeline that continuously mirrors microservice databases into a lakehouse. It captures inserts, updates, and deletes, deduplicates on primary key, compacts into columnar files, and exposes snapshot and history views for analytics.
TECH_STACK: Clojure (JVM) + Kafka via jackdaw + core.async + Apache Parquet + S3 + Athena catalog, deployed on AWS EKS
APP_TYPE: data pipeline
LANGUAGE: Clojure
SCALE: ~15,000 changes/sec, 400 tables, 2 TB lakehouse
```

## 71. Rill — streaming metrics pipeline

```text
APP_DESCRIPTION: A streaming metrics pipeline that turns application events into business KPIs. It parses events, computes counters and rates over time windows, and pushes updates to a live metrics store that powers real-time executive dashboards.
TECH_STACK: Clojure (JVM) + Kafka Streams via jackdaw + core.async + Redis + PostgreSQL, deployed on Kubernetes (EKS)
APP_TYPE: data pipeline
LANGUAGE: Clojure
SCALE: ~35,000 events/sec, 1,200 metrics, 15-second refresh
```

## 72. Ferment — social sentiment pipeline

```text
APP_DESCRIPTION: A social media analytics pipeline that ingests posts and comments, cleans and language-detects text, scores sentiment and topics, and aggregates brand mention trends. Results feed a marketing dashboard with drill-down to source posts.
TECH_STACK: Clojure (JVM) + core.async + Kafka via jackdaw + Malli + next.jdbc + PostgreSQL, deployed on GCP Cloud Run jobs
APP_TYPE: data pipeline
LANGUAGE: Clojure
SCALE: ~8,000 posts/sec, 200M posts/month, 40 tracked brands
```

## 73. Sediment — cold-storage archival pipeline

```text
APP_DESCRIPTION: An archival pipeline that ages out warm data into compressed cold storage. It selects records past retention thresholds, batches and compresses them into columnar archives, verifies integrity checksums, and maintains an index for on-demand restore.
TECH_STACK: Clojure (JVM) + next.jdbc + PostgreSQL + Apache Parquet + S3 Glacier + core.async, orchestrated with Integrant, deployed on AWS ECS scheduled tasks
APP_TYPE: data pipeline
LANGUAGE: Clojure
SCALE: ~2 TB archived/day, 500M records/run, 5-year retention
```

## 74. Currents — financial tick data pipeline

```text
APP_DESCRIPTION: A market data pipeline that ingests real-time price ticks, normalizes symbols across venues, computes OHLC bars and rolling indicators, and persists both raw ticks and derived bars for backtesting and live charting.
TECH_STACK: Clojure (JVM) + Aleph + core.async + Kafka via jackdaw + kdb-style TimescaleDB sink, deployed on Kubernetes (EKS)
APP_TYPE: data pipeline
LANGUAGE: Clojure
SCALE: ~100,000 ticks/sec peak, 8k instruments, 20B ticks/day
```

## 75. Loomfeed — ad-impression aggregation pipeline

```text
APP_DESCRIPTION: An ad analytics pipeline that processes impression, click, and conversion events. It deduplicates, attributes conversions to prior impressions within windows, and aggregates spend and performance by campaign for near-real-time reporting.
TECH_STACK: Clojure (JVM) + Kafka via jackdaw + core.async + Redis dedup + next.jdbc + ClickHouse sink, deployed on GCP GKE
APP_TYPE: data pipeline
LANGUAGE: Clojure
SCALE: ~45,000 events/sec, 3B impressions/day, 20k campaigns
```

## 76. Harvest — web-scraping normalization pipeline

```text
APP_DESCRIPTION: A crawling and normalization pipeline for a price-intelligence product. It fetches product pages on a schedule, extracts structured fields, resolves duplicates across sources, and writes a clean canonical catalog with change history per item.
TECH_STACK: Clojure (JVM) + core.async crawlers + Jsoup + Malli + next.jdbc + PostgreSQL, orchestrated with Integrant, deployed on AWS ECS Fargate
APP_TYPE: data pipeline
LANGUAGE: Clojure
SCALE: ~5M pages/day, 40k sources, 12M canonical products
```

## 77. Refinery — clickstream sessionization pipeline

```text
APP_DESCRIPTION: A sessionization pipeline that stitches raw pageview and interaction events into user sessions. It orders events per visitor, applies inactivity timeouts to bound sessions, computes session-level metrics, and emits enriched session records for analytics.
TECH_STACK: Clojure (JVM) + Kafka Streams via jackdaw + core.async + RocksDB state + BigQuery sink, deployed on GCP GKE
APP_TYPE: data pipeline
LANGUAGE: Clojure
SCALE: ~28,000 events/sec, 40M sessions/day, 8 GB state
```

## 78. Estuary — data lake ingestion pipeline

```text
APP_DESCRIPTION: A multi-source ingestion pipeline feeding a data lake. It pulls from APIs, files, and databases on schedules, standardizes into a common schema, partitions by date and source, and registers datasets in a catalog with lineage metadata.
TECH_STACK: Clojure (JVM) + core.async + next.jdbc + Apache Parquet + S3 + Glue catalog, orchestrated with Integrant, deployed on AWS EKS
APP_TYPE: data pipeline
LANGUAGE: Clojure
SCALE: ~300 source connectors, 1.5 TB ingested/day, 4k datasets
```

## 79. Cinder — server log anomaly pipeline

```text
APP_DESCRIPTION: A log anomaly detection pipeline for infrastructure teams. It streams system logs, extracts templates, computes baseline frequencies, and flags statistical spikes and rare patterns, forwarding anomalies with context to on-call channels.
TECH_STACK: Clojure (JVM) + core.async + Kafka via jackdaw + Malli + Redis baselines + Elasticsearch, deployed on Kubernetes (EKS)
APP_TYPE: data pipeline
LANGUAGE: Clojure
SCALE: ~50,000 log lines/sec, 20k templates, 1B lines/day
```

## 80. Tidewater — geolocation trip-stitching pipeline

```text
APP_DESCRIPTION: A mobility pipeline that stitches raw GPS pings into coherent trips. It orders points per device, map-matches to roads, segments trips on stops, and computes distance, duration, and mode. Trip records feed usage-based pricing and analytics.
TECH_STACK: Clojure (JVM) + Kafka via jackdaw + core.async + PostGIS + TimescaleDB sink, deployed on GCP GKE
APP_TYPE: data pipeline
LANGUAGE: Clojure
SCALE: ~30,000 pings/sec, 500k trips/day, 200k devices
```

## 81. Vintage — order-history ETL pipeline

```text
APP_DESCRIPTION: An ETL pipeline that consolidates e-commerce order history from multiple storefronts into a unified analytics model. It reconciles currencies, resolves customer identities across stores, and builds RFM and lifetime-value tables refreshed nightly.
TECH_STACK: Clojure (JVM) + next.jdbc + PostgreSQL + Tablecloth + core.async, orchestrated with Integrant, deployed on AWS ECS scheduled tasks
APP_TYPE: data pipeline
LANGUAGE: Clojure
SCALE: ~40M orders processed/night, 12 storefronts, 8M customers
```

## 82. Sonar — network flow analytics pipeline

```text
APP_DESCRIPTION: A network telemetry pipeline that ingests NetFlow and packet-summary records, aggregates traffic by source, destination, and protocol, and detects volumetric anomalies. Aggregates feed a security dashboard and threshold-based alerts.
TECH_STACK: Clojure (JVM) + Aleph UDP ingestion + core.async + Kafka via jackdaw + ClickHouse sink, deployed on Kubernetes (EKS)
APP_TYPE: data pipeline
LANGUAGE: Clojure
SCALE: ~70,000 flows/sec, 4B flows/day, 30k monitored hosts
```

## 83. Almagest — astronomy observation pipeline

```text
APP_DESCRIPTION: A data pipeline for an amateur observatory network. It ingests time-series photometry from telescopes, calibrates against reference frames, detects transient brightness changes, and archives reduced light curves for follow-up analysis.
TECH_STACK: Clojure (JVM) + core.async + Tablecloth + Malli + next.jdbc + Parquet + PostgreSQL, orchestrated with Integrant, deployed on self-hosted uberjar
APP_TYPE: data pipeline
LANGUAGE: Clojure
SCALE: ~2M observations/night, 400 telescopes, 5 TB archive
```

## 84. Ledgerflow — transaction reconciliation pipeline

```text
APP_DESCRIPTION: A reconciliation pipeline for finance operations. It ingests internal ledger entries and external bank and processor statements, matches them with configurable rules, and surfaces unmatched and duplicate items with a full audit of every match decision.
TECH_STACK: Clojure (JVM) + next.jdbc + PostgreSQL + Malli rules + core.async, orchestrated with Integrant, deployed on AWS ECS scheduled tasks
APP_TYPE: data pipeline
LANGUAGE: Clojure
SCALE: ~20M transactions/day, 40 sources, 99.5% auto-match
```

## 85. Pollen — email deliverability metrics pipeline

```text
APP_DESCRIPTION: A deliverability analytics pipeline that consumes email event webhooks, joins them to sends, and computes bounce, complaint, and engagement rates per domain and campaign. It detects reputation risks and feeds a sender-health dashboard.
TECH_STACK: Clojure (JVM) + Aleph ingestion + Kafka via jackdaw + core.async + next.jdbc + PostgreSQL, deployed on GCP Cloud Run jobs
APP_TYPE: data pipeline
LANGUAGE: Clojure
SCALE: ~25,000 events/sec, 300M events/month, 8k sending domains
```

## 86. Cauldron — data migration CLI

```text
APP_DESCRIPTION: A command-line tool for migrating data between databases. It reads a declarative EDN mapping, streams rows in batches with transformation functions, resumes from checkpoints on failure, and reports throughput and row-level errors. It runs safely against production replicas.
TECH_STACK: Clojure (JVM) CLI (tools.cli) + next.jdbc + core.async, packaged as an uberjar and a GraalVM native-image binary, distributed via GitHub Releases
APP_TYPE: CLI
LANGUAGE: Clojure
SCALE: ~50M rows/run, resumable checkpoints, single operator
```

## 87. Sprocket — deps.edn dependency auditor CLI

```text
APP_DESCRIPTION: A CLI that audits Clojure projects for dependency risks. It resolves the full deps.edn tree, flags outdated and vulnerable libraries against an advisory feed, detects version conflicts, and emits a report in text or JSON for CI gating.
TECH_STACK: Babashka CLI + tools.deps resolution + Cheshire, distributed via bbin and Homebrew
APP_TYPE: CLI
LANGUAGE: Clojure
SCALE: ~2,000 deps resolved/run, sub-3s cold start, single user
```

## 88. Scaffold — project generator CLI

```text
APP_DESCRIPTION: A scaffolding CLI that generates new Clojure services from templates. It prompts for options, renders a project with Reitit, Integrant, and test wiring, and initializes git. Templates are data-driven so teams can add their own conventions.
TECH_STACK: Babashka CLI + Selmer templating + tools.build, distributed via bbin
APP_TYPE: CLI
LANGUAGE: Clojure
SCALE: ~40 templates, sub-1s generation, thousands of installs
```

## 89. Ferrite — schema diff and migration CLI

```text
APP_DESCRIPTION: A database schema CLI that compares a target schema described in EDN against a live database, generates the DDL diff, and applies forward and rollback migrations transactionally with a locked migration ledger to prevent concurrent runs.
TECH_STACK: Clojure (JVM) CLI (tools.cli) + next.jdbc + Honey SQL, packaged as a GraalVM native binary, distributed via Homebrew
APP_TYPE: CLI
LANGUAGE: Clojure
SCALE: ~500 tables diffed, ordered migration ledger, single operator
```

## 90. Tinderbox — log tailing and search CLI

```text
APP_DESCRIPTION: A CLI for tailing and searching structured logs across servers. It follows multiple sources, parses JSON lines, filters with an EDN query DSL, highlights matches, and can pivot to aggregate counts by field, all in the terminal.
TECH_STACK: Babashka CLI + core.async + SSH streaming, distributed via bbin and Homebrew
APP_TYPE: CLI
LANGUAGE: Clojure
SCALE: ~100k lines/sec parsed, 50 tailed sources, single user
```

## 91. Cronwright — cron schedule visualizer CLI

```text
APP_DESCRIPTION: A CLI that parses cron and scheduling definitions across a repo, explains each schedule in plain English, projects the next N run times, and flags overlaps and gaps so on-call engineers can reason about batch job timing.
TECH_STACK: Babashka CLI + cron parser + tick time library, distributed via bbin
APP_TYPE: CLI
LANGUAGE: Clojure
SCALE: ~1,000 schedules parsed, 12-month projection, single user
```

## 92. Salvo — load-testing CLI

```text
APP_DESCRIPTION: A load-testing CLI for HTTP and GraphQL endpoints. It runs scenarios defined in EDN, ramps virtual users with core.async, and reports latency percentiles, throughput, and error rates live in the terminal with a summary export for CI.
TECH_STACK: Clojure (JVM) CLI (tools.cli) + Aleph HTTP client + core.async, packaged as an uberjar and native binary, distributed via GitHub Releases
APP_TYPE: CLI
LANGUAGE: Clojure
SCALE: ~20,000 req/sec generated, 10k virtual users, single machine
```

## 93. Quartz — EDN transformation CLI

```text
APP_DESCRIPTION: A command-line data transformation tool for EDN and JSON. It applies a pipeline of transformations expressed as a small DSL, supports streaming large files, and pretty-prints or minifies output, acting as a jq-for-EDN in shell workflows.
TECH_STACK: Babashka CLI + Specter + Cheshire, distributed via bbin and Homebrew
APP_TYPE: CLI
LANGUAGE: Clojure
SCALE: ~1 GB files streamed, sub-1s startup, thousands of installs
```

## 94. Envman — secrets sync CLI

```text
APP_DESCRIPTION: A CLI that syncs environment configuration and secrets between a secrets manager and local .env files. It pulls, diffs, and pushes values per environment, masks secrets in output, and records who changed what, keeping developer machines in sync.
TECH_STACK: Clojure (JVM) CLI (tools.cli) + Buddy encryption + cloud secrets SDK, packaged as a GraalVM native binary, distributed via Homebrew
APP_TYPE: CLI
LANGUAGE: Clojure
SCALE: ~2,000 keys managed, 20 environments, per-developer use
```

## 95. Reaper — cloud resource cleanup CLI

```text
APP_DESCRIPTION: A CLI that finds and cleans up orphaned cloud resources. It scans accounts for untagged volumes, idle load balancers, and stale snapshots, previews a dry-run plan, and deletes with confirmation and an audit log to control cloud spend.
TECH_STACK: Clojure (JVM) CLI (tools.cli) + AWS SDK + core.async + Malli policy rules, packaged as an uberjar, distributed via GitHub Releases
APP_TYPE: CLI
LANGUAGE: Clojure
SCALE: ~50k resources scanned, dry-run default, single operator
```

## 96. Datashard — database seeding CLI

```text
APP_DESCRIPTION: A CLI for generating and loading realistic seed data into databases. It reads schema-aware EDN generators, produces referentially consistent fake records, and bulk-loads them, letting teams spin up populated dev and demo environments on demand.
TECH_STACK: Babashka CLI + test.check generators + next.jdbc, distributed via bbin
APP_TYPE: CLI
LANGUAGE: Clojure
SCALE: ~5M rows generated/run, 200 tables, single developer
```

## 97. Cobbler — changelog generator CLI

```text
APP_DESCRIPTION: A CLI that assembles release changelogs from git history. It parses conventional commits, groups changes by type and scope, links issues, and renders Markdown release notes, keeping a project's CHANGELOG current in CI on each tag.
TECH_STACK: Babashka CLI + git plumbing + Selmer templating, distributed via bbin and Homebrew
APP_TYPE: CLI
LANGUAGE: Clojure
SCALE: ~10k commits parsed, sub-2s runs, per-repo CI use
```

## 98. Lodestar — REPL-driven deployment CLI

```text
APP_DESCRIPTION: A deployment CLI that drives releases from declarative EDN specs. It builds artifacts, runs pre-flight checks, performs rolling deploys with health gating, and can roll back to a prior release. Deploy history and diffs are recorded for audit.
TECH_STACK: Clojure (JVM) CLI (tools.cli) + tools.build + Kubernetes API + core.async, packaged as an uberjar, distributed via internal artifact registry
APP_TYPE: CLI
LANGUAGE: Clojure
SCALE: ~40 services managed, staged rollouts, single operator
```

## 99. Grommet — API contract testing CLI

```text
APP_DESCRIPTION: A CLI that validates running APIs against their contracts. It reads an OpenAPI or Malli schema, generates and replays example requests, checks responses against the spec, and reports mismatches, gating deploys when a service drifts from its contract.
TECH_STACK: Clojure (JVM) CLI (tools.cli) + Malli + test.check + Aleph HTTP client, packaged as a native binary, distributed via GitHub Releases
APP_TYPE: CLI
LANGUAGE: Clojure
SCALE: ~2,000 cases/run, 300 endpoints, per-service CI use
```

## 100. Backstage — release orchestration CLI

```text
APP_DESCRIPTION: A release orchestration CLI that coordinates multi-service releases. It reads a dependency-ordered release plan in EDN, sequences deploys with gates between waves, aggregates status, and halts on failure with a resumable, audited run record.
TECH_STACK: Clojure (JVM) CLI (tools.cli) + core.async + next.jdbc + PostgreSQL run store, packaged as an uberjar, distributed via internal artifact registry
APP_TYPE: CLI
LANGUAGE: Clojure
SCALE: ~60 services/release, ordered waves, single release manager
```
