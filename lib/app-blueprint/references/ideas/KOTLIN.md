# Kotlin Blueprint Types — Copy-Paste Input Sets

Copy a fenced block into the prompt as-is, or swap individual fields.

## 1. WrenchWay — field service work orders

```text
APP_DESCRIPTION: A field-service mobile app for HVAC and plumbing technicians. Techs receive dispatched work orders with customer history and equipment records, navigate to jobs, capture photos and signatures, log parts used against van inventory, and generate on-site invoices — with full offline capability for basements and rural areas.
TECH_STACK: Kotlin (Android, Jetpack Compose) + Room offline store + WorkManager sync + Retrofit to REST backend
APP_TYPE: mobile
LANGUAGE: Kotlin
SCALE: 2,000 technician devices, 600 concurrent, ~10 GB backend data
```

## 2. TransitTap — public transit companion

```text
APP_DESCRIPTION: A transit companion mobile app for a metro region's riders. Riders see live arrivals from GTFS-realtime feeds, plan multi-modal trips, save favorite stops with departure widgets, and receive service-disruption alerts for their usual lines.
TECH_STACK: Kotlin (Android, Jetpack Compose) + GTFS/GTFS-RT feeds + Room cache + FCM push alerts + MapLibre
APP_TYPE: mobile
LANGUAGE: Kotlin
SCALE: 80,000 MAU, 5,000 concurrent at rush hour, ~15 GB feed/cache data
```

## 3. PunchCup — café loyalty app

```text
APP_DESCRIPTION: A digital punch-card loyalty mobile app for independent cafés. Customers collect stamps via QR scan at checkout, redeem free drinks, and discover participating cafés nearby; café owners configure reward rules and see repeat-visit analytics from a simple dashboard.
TECH_STACK: Kotlin (Android, Jetpack Compose) + Ktor backend + PostgreSQL + QR signing + FCM
APP_TYPE: mobile
LANGUAGE: Kotlin
SCALE: 15,000 MAU, 800 concurrent, 120 participating cafés, ~4 GB data
```

## 4. OrderSpine — order management API

```text
APP_DESCRIPTION: An order-management API service for direct-to-consumer brands. It receives orders from storefronts, orchestrates payment capture, fraud screening, and warehouse allocation, manages splits/backorders and cancellations, and emits status webhooks to storefronts and customer-notification systems.
TECH_STACK: Kotlin (Ktor) + Exposed + PostgreSQL + Kafka + Redis, deployed on GCP GKE
APP_TYPE: API service
LANGUAGE: Kotlin
SCALE: ~350 req/sec Black Friday peak, 45 brands, ~40 GB data
```

## 5. depwatch — Gradle dependency audit CLI

```text
APP_DESCRIPTION: A CLI tool for JVM teams that audits Gradle project dependencies. It resolves the full dependency graph, reports outdated versions with upgrade risk hints, flags known-vulnerable versions from the OSV database, detects unused declared dependencies, and emits console, JSON, and CI-annotation output.
TECH_STACK: Kotlin CLI (clikt) + Gradle Tooling API + OSV vulnerability database + local cache, distributed via Homebrew/GitHub releases
APP_TYPE: CLI
LANGUAGE: Kotlin
SCALE: single user per invocation, CI usage ~500 runs/day, <500 MB local cache
```

## 6. PickPath — warehouse picking app

```text
APP_DESCRIPTION: A warehouse picking mobile app for e-commerce fulfillment staff. Pickers receive wave-optimized pick lists on rugged Android scanners, confirm items by barcode with quantity and location validation, report short-picks and damaged stock, and hand off completed totes to packing stations.
TECH_STACK: Kotlin (Android, Jetpack Compose) + zebra scanner SDK + Room offline queue + gRPC to warehouse backend
APP_TYPE: mobile
LANGUAGE: Kotlin
SCALE: 250 scanner devices across 2 warehouses, 180 concurrent, ~5 GB backend data
```

## 7. DoseWise — medication adherence tracker

```text
APP_DESCRIPTION: A medication adherence mobile app for patients managing chronic conditions. Patients scan pill bottles to build a med list, get dose reminders tuned to meal times, log taken/skipped doses with side-effect notes, and share adherence reports with their prescriber before appointments.
TECH_STACK: Kotlin (Android, Jetpack Compose) + Room + WorkManager reminders + ML Kit barcode scanning + Ktor client to FHIR-backed API
APP_TYPE: mobile
LANGUAGE: Kotlin
SCALE: 45,000 MAU, 3,000 concurrent at morning reminder peak, ~8 GB backend data
```

## 8. HerdHalo — dairy herd management

```text
APP_DESCRIPTION: A herd-management mobile app for dairy farmers. Farmers record calvings, heats, vet treatments, and milk-yield observations per cow via RFID ear-tag scans, get withdrawal-period warnings before milk pickup, and review fertility and yield trends per animal — usable offline in the parlor and paddock.
TECH_STACK: Kotlin (Android, Jetpack Compose) + Room offline store + Bluetooth RFID reader SDK + WorkManager sync + Retrofit
APP_TYPE: mobile
LANGUAGE: Kotlin
SCALE: 6,000 farms, 9,500 MAU, herds up to 1,200 cows, ~20 GB backend data
```

## 9. LedgerLark — payment reconciliation API

```text
APP_DESCRIPTION: A reconciliation API service for finance teams at mid-size retailers. It ingests settlement files from card acquirers and PSPs, matches them against internal order ledgers, flags unmatched and partially-settled transactions with aging, and exports journal entries to accounting systems.
TECH_STACK: Kotlin (Spring Boot) + JPA + PostgreSQL + Apache POI/CSV parsers + SFTP ingestion + Redis, on AWS ECS
APP_TYPE: API service
LANGUAGE: Kotlin
SCALE: 1.2M transactions matched/day, 60 merchant tenants, ~150 GB data
```

## 10. CairnScout — offline hiking navigation

```text
APP_DESCRIPTION: An offline-first hiking navigation mobile app for backcountry walkers. Hikers download topo map regions and trail networks, follow routes with elevation profiles and off-trail warnings, drop waypoints with photos, and share a live safety beacon with an emergency contact when coverage allows.
TECH_STACK: Kotlin (Android, Jetpack Compose) + MapLibre with MBTiles offline packs + Room + fused location + FCM
APP_TYPE: mobile
LANGUAGE: Kotlin
SCALE: 120,000 MAU, 7,000 concurrent on summer weekends, ~2 TB tile storage backend
```

## 11. ChillChain — cold-chain telemetry pipeline

```text
APP_DESCRIPTION: A cold-chain monitoring data pipeline for pharmaceutical and frozen-food logistics. It ingests temperature, humidity, and door-open events from container-mounted IoT sensors, detects excursion windows against product-specific thresholds, and feeds alerting and compliance-report systems downstream.
TECH_STACK: Kotlin + Kafka + Kafka Streams + Avro/Schema Registry + TimescaleDB sink + Micrometer/Prometheus, on Kubernetes
APP_TYPE: data pipeline
LANGUAGE: Kotlin
SCALE: 40,000 sensors reporting every 30s (~1,300 events/sec), 90-day hot retention, ~1.5 TB
```

## 12. SnipSlot — barbershop booking

```text
APP_DESCRIPTION: A booking mobile app for barbershops and their walk-in-heavy clientele. Customers see live chair availability and wait times, book or join a virtual queue, save their preferred barber and cut notes, and pay/tip in-app; barbers manage their day from a companion mode.
TECH_STACK: Kotlin (Android, Jetpack Compose) + Ktor backend + PostgreSQL + Stripe SDK + FCM queue notifications
APP_TYPE: mobile
LANGUAGE: Kotlin
SCALE: 28,000 MAU, 1,500 concurrent Saturday peak, 340 shops, ~6 GB data
```

## 13. FreightFathom — freight quoting API

```text
APP_DESCRIPTION: A freight rating and booking API for regional trucking brokers. It computes LTL and FTL quotes from carrier rate cards, accessorials, and fuel surcharges, tenders loads to carriers with acceptance deadlines, and tracks booking status through pickup confirmation.
TECH_STACK: Kotlin (Spring Boot WebFlux) + R2DBC + PostgreSQL + Redis rate-card cache + Kafka events, on AWS EKS
APP_TYPE: API service
LANGUAGE: Kotlin
SCALE: ~90 req/sec quoting peak, 25 broker tenants, 800 carriers, ~60 GB data
```

## 14. TillCraft — boutique retail POS desktop

```text
APP_DESCRIPTION: A point-of-sale desktop app for independent clothing boutiques. Staff ring up sales with barcode or search, apply markdowns and store credit, manage layaways and returns, and count registers at close; inventory and end-of-day summaries sync to the owner's cloud account.
TECH_STACK: Kotlin (Compose Multiplatform Desktop) + SQLDelight local DB + receipt printer/cash drawer via ESC-POS + Ktor sync client
APP_TYPE: desktop
LANGUAGE: Kotlin
SCALE: 900 store installs, ~3,500 transactions/day network-wide, <2 GB per store
```

## 15. WattWatch — home energy monitoring

```text
APP_DESCRIPTION: A home energy monitoring mobile app paired with a clamp-on meter sensor. Homeowners see live whole-home consumption, per-appliance estimates from load disaggregation, time-of-use cost projections, and nudges to shift heavy loads off peak tariff windows.
TECH_STACK: Kotlin (Android, Jetpack Compose) + BLE sensor pairing + MQTT ingestion backend + Room cache + Vico charts
APP_TYPE: mobile
LANGUAGE: Kotlin
SCALE: 60,000 paired homes, 35,000 MAU, ~500 readings/home/day, ~400 GB telemetry
```

## 16. lingosync — string resource translation CLI

```text
APP_DESCRIPTION: A CLI tool for Android teams that keeps strings.xml resources in sync with an external translation service. It diffs source strings against translated locales, pushes new/changed keys for translation, pulls completed translations back into resource folders, and fails CI on missing or stale locales.
TECH_STACK: Kotlin CLI (clikt) + XML resource parsing + translation-vendor REST APIs + kotlinx.serialization + local state cache
APP_TYPE: CLI
LANGUAGE: Kotlin
SCALE: single user per invocation, ~200 CI runs/day across 30 repos, 25 locales
```

## 17. DropSignal — blood donor engagement

```text
APP_DESCRIPTION: A blood-donation mobile app for a national blood service. Donors get eligibility countdowns after each donation, urgent type-specific appeals when regional stocks run low, appointment booking at drives and fixed centers, and a donation history with lifetime impact stats.
TECH_STACK: Kotlin (Android, Jetpack Compose) + Retrofit to Spring Boot backend + PostgreSQL + FCM targeted appeals + Room
APP_TYPE: mobile
LANGUAGE: Kotlin
SCALE: 300,000 registered donors, 90,000 MAU, 12,000 bookings/week, ~25 GB data
```

## 18. ClaimKestrel — insurance claims intake API

```text
APP_DESCRIPTION: A claims-intake API service for property and auto insurers. It accepts first-notice-of-loss submissions from web, mobile, and call-center channels, validates policy coverage in real time, triages claims by severity rules, assigns adjusters, and streams status events to policyholder channels.
TECH_STACK: Kotlin (Spring Boot) + JPA + PostgreSQL + Kafka + Drools-style rules via Kotlin DSL + S3 document storage, on Azure AKS
APP_TYPE: API service
LANGUAGE: Kotlin
SCALE: 8,000 claims/day (30,000/day post-storm surge), 4 insurer tenants, ~300 GB data
```

## 19. MoodMoss — mood journaling and CBT

```text
APP_DESCRIPTION: A mental-wellness mobile app centered on mood journaling. Users log moods with context tags, write guided CBT-style reflections, spot correlations between sleep, activity, and mood in weekly insights, and export a summary to bring to therapy sessions.
TECH_STACK: Kotlin (Android, Jetpack Compose) + Room with SQLCipher encryption + on-device sentiment tagging (TF Lite) + optional encrypted cloud backup via Ktor
APP_TYPE: mobile
LANGUAGE: Kotlin
SCALE: 70,000 MAU, 4,000 concurrent evening peak, on-device-first with ~50 GB backup storage
```

## 20. ClickCurrent — retail clickstream pipeline

```text
APP_DESCRIPTION: A clickstream sessionization pipeline for a fashion e-commerce group. It ingests raw page-view, search, and add-to-cart events, stitches them into sessions with bot filtering, computes funnel and abandonment metrics, and lands modeled tables for merchandising analysts and the recommendation engine.
TECH_STACK: Kotlin + Kafka + Kafka Streams (session windows) + Protobuf + ClickHouse sink + Airflow-orchestrated batch compaction
APP_TYPE: data pipeline
LANGUAGE: Kotlin
SCALE: 25,000 events/sec peak, 9M sessions/day, 13-month retention, ~40 TB
```

## 21. LeaveLoft — HR leave management portal

```text
APP_DESCRIPTION: A server-rendered leave-management web app for mid-size companies. Employees request vacation and sick leave against accrual balances, managers approve with team-calendar conflict warnings, and HR configures leave policies per country and exports payroll-ready absence reports.
TECH_STACK: Kotlin (Spring Boot + Thymeleaf + htmx) + JPA + PostgreSQL + LDAP/SSO integration
APP_TYPE: web app
LANGUAGE: Kotlin
SCALE: 90 company tenants, 40,000 employee users, ~600 requests/day, ~10 GB data
```

## 22. PawPassport — pet health records

```text
APP_DESCRIPTION: A pet health-record mobile app for dog and cat owners. Owners keep vaccination certificates, deworming and flea-treatment schedules, weight curves, and vet-visit notes per pet, get booster-due reminders, and show a scannable record at kennels, groomers, and border crossings.
TECH_STACK: Kotlin (Android, Jetpack Compose) + Room + WorkManager reminders + PDF certificate rendering + Ktor sync backend
APP_TYPE: mobile
LANGUAGE: Kotlin
SCALE: 55,000 MAU, 130,000 pet profiles, ~12 GB document storage
```

## 23. ScriptSwitch — e-prescription routing API

```text
APP_DESCRIPTION: An e-prescription routing API connecting clinic EHR systems to retail pharmacies. It validates prescriber credentials and drug-interaction warnings, routes scripts to the patient's chosen pharmacy, handles refill-request round-trips, and maintains a full audit trail for regulators.
TECH_STACK: Kotlin (Spring Boot) + PostgreSQL + Kafka + HL7/NCPDP-style message translation + mTLS partner auth, on-prem Kubernetes
APP_TYPE: API service
LANGUAGE: Kotlin
SCALE: 250,000 scripts/day, 3,800 pharmacies, 900 clinics, ~500 GB audit data
```

## 24. PowderPly — ski resort companion

```text
APP_DESCRIPTION: A resort companion mobile app for a group of alpine ski areas. Skiers check live lift status and wait times, groomed-run and snow reports, track day stats like vertical and top speed, locate friends on the trail map, and reload lift passes in-app.
TECH_STACK: Kotlin (Android, Jetpack Compose) + MapLibre custom trail maps + Room + FCM lift alerts + Retrofit + Google Wallet pass integration
APP_TYPE: mobile
LANGUAGE: Kotlin
SCALE: 95,000 seasonal MAU, 12,000 concurrent on powder days, 6 resorts, ~10 GB data
```

## 25. apkscope — APK size analysis CLI

```text
APP_DESCRIPTION: A CLI tool for Android release engineers that analyzes APK/AAB size. It breaks size down by dex packages, native libs, and resources, diffs two builds to attribute regressions to specific modules and dependencies, enforces per-module size budgets, and posts CI annotations on offending merge requests.
TECH_STACK: Kotlin CLI (clikt) + apkanalyzer/bundletool internals + dexlib2 + JSON/HTML report output
APP_TYPE: CLI
LANGUAGE: Kotlin
SCALE: single user per invocation, ~350 CI runs/day, builds up to 400 MB
```

## 26. CurbCoin — municipal parking payment

```text
APP_DESCRIPTION: A parking payment mobile app operated for city street parking and municipal garages. Drivers start and extend sessions by zone code or plate, get expiry warnings, and store receipts for expensing; enforcement officers verify payment by plate in a companion mode.
TECH_STACK: Kotlin (Android, Jetpack Compose) + Ktor backend + PostgreSQL + Stripe + FCM expiry alerts + plate-scan via ML Kit
APP_TYPE: mobile
LANGUAGE: Kotlin
SCALE: 200,000 MAU, 18,000 active sessions at midday peak, 3 cities, ~30 GB data
```

## 27. MeterMesh — smart meter data collection API

```text
APP_DESCRIPTION: A meter-data collection API for a regional electricity distributor. It receives interval reads from smart-meter head-end systems, validates and estimates gaps per industry rules, serves consumption history to billing and customer portals, and publishes settlement-ready datasets to the market operator.
TECH_STACK: Kotlin (Ktor) + TimescaleDB + Kafka + Redis + scheduled VEE (validation-estimation-editing) jobs, on Azure AKS
APP_TYPE: API service
LANGUAGE: Kotlin
SCALE: 1.8M meters, 4 reads/hour each (~2,000 writes/sec), ~12 TB time-series data
```

## 28. HiveHatch — beekeeping inspection log

```text
APP_DESCRIPTION: A hive-inspection mobile app for hobbyist and sideliner beekeepers. Keepers log queen status, brood pattern, stores, and mite counts per hive with photo frames, get treatment and feeding reminders by season and climate zone, and track honey harvests per apiary.
TECH_STACK: Kotlin (Android, Jetpack Compose) + Room offline store + CameraX + WorkManager + Ktor sync backend
APP_TYPE: mobile
LANGUAGE: Kotlin
SCALE: 22,000 MAU, 140,000 registered hives, ~9 GB photo/backend data
```

## 29. MuxMill — video transcoding orchestration API

```text
APP_DESCRIPTION: A transcoding-orchestration API for a video course platform. It accepts uploaded lecture masters, fans out renditions across worker fleets (HLS ladders, audio-only, thumbnails), tracks job progress with retries and priority lanes, and notifies the CMS when assets are ready.
TECH_STACK: Kotlin (Ktor) + PostgreSQL job store + RabbitMQ work queues + FFmpeg worker containers + S3/CloudFront, on AWS EKS
APP_TYPE: API service
LANGUAGE: Kotlin
SCALE: 4,000 videos transcoded/day, 300 concurrent worker jobs, ~80 TB asset storage
```

## 30. StallStar — farmers market vendor POS

```text
APP_DESCRIPTION: A lightweight point-of-sale mobile app for farmers market vendors. Vendors build a quick-tap product grid with per-market pricing, take card and QR payments offline-tolerant, track stall inventory sold by weight or unit, and see per-market takings compared across the season.
TECH_STACK: Kotlin (Android, Jetpack Compose) + Tap to Pay / SumUp SDK + Room offline queue + Ktor backend + PostgreSQL
APP_TYPE: mobile
LANGUAGE: Kotlin
SCALE: 8,000 vendor MAU, 2,200 concurrent on Saturday mornings, ~5 GB data
```

## 31. TeleTrace — insurance telematics pipeline

```text
APP_DESCRIPTION: A driving-telematics data pipeline for usage-based auto insurance. It ingests GPS, accelerometer, and trip events from policyholder devices and OBD dongles, detects harsh braking, speeding, and phone-handling episodes, scores trips, and delivers monthly risk factors to the pricing engine.
TECH_STACK: Kotlin + Kafka + Apache Flink (Kotlin jobs) + Protobuf + S3 data lake + Parquet + Spark batch scoring
APP_TYPE: data pipeline
LANGUAGE: Kotlin
SCALE: 500,000 insured vehicles, 60,000 events/sec peak, ~90 TB data lake
```

## 32. SignSpruce — document e-signature API

```text
APP_DESCRIPTION: An e-signature API service for SaaS products that embed contract signing. It manages envelope creation from templates with merge fields, sequential and parallel signer routing, identity checks via email/SMS codes, tamper-evident audit certificates, and completion webhooks.
TECH_STACK: Kotlin (Spring Boot) + PostgreSQL + S3 + PDFBox signing/stamping + Redis + SES/SNS, on AWS ECS
APP_TYPE: API service
LANGUAGE: Kotlin
SCALE: 90,000 envelopes/month, 220 integrating products, ~2 TB document storage
```

## 33. CruxCount — climbing gym progress tracker

```text
APP_DESCRIPTION: A progress-tracking mobile app for indoor climbers, integrated with partner gyms' route databases. Climbers log sends and attempts by scanning route tags, track grade pyramids and project history, get notified when their projects are about to be reset, and compare progress with friends.
TECH_STACK: Kotlin (Android, Jetpack Compose) + NFC/QR route tags + Room + Ktor backend + PostgreSQL + FCM reset alerts
APP_TYPE: mobile
LANGUAGE: Kotlin
SCALE: 40,000 MAU across 85 partner gyms, 2,500 concurrent evening peak, ~7 GB data
```

## 34. PagePorch — small library catalog portal

```text
APP_DESCRIPTION: A server-rendered catalog and circulation web app for small-town and school libraries. Patrons search holdings, place holds, and renew loans; librarians check items in/out by barcode, manage member accounts, and run overdue and acquisition reports — simple enough to run without an IT department.
TECH_STACK: Kotlin (Ktor + FreeMarker templates + htmx) + Exposed + PostgreSQL + MARC record import
APP_TYPE: web app
LANGUAGE: Kotlin
SCALE: 260 library tenants, 180,000 patron accounts, ~1,200 checkouts/day, ~15 GB data
```

## 35. AmpAtlas — EV charging finder

```text
APP_DESCRIPTION: An EV-charging mobile app aggregating networks across a country. Drivers filter chargers by connector, speed, and live availability, start and pay for sessions across roaming networks with one account, and plan long trips with charge stops sized to their car's real consumption curve.
TECH_STACK: Kotlin (Android, Jetpack Compose) + OCPI network integrations + MapLibre + Room cache + Stripe + FCM session updates
APP_TYPE: mobile
LANGUAGE: Kotlin
SCALE: 150,000 MAU, 9,000 concurrent sessions peak, 42,000 charge points, ~20 GB data
```

## 36. SuiteSweep — hotel housekeeping operations

```text
APP_DESCRIPTION: A housekeeping operations mobile app for hotel room attendants and supervisors. Attendants receive prioritized room queues driven by checkouts and arrivals, mark cleaning stages with timestamps, report maintenance defects with photos, and log minibar usage; supervisors reassign boards and inspect rooms.
TECH_STACK: Kotlin (Android, Jetpack Compose) + Retrofit to PMS-integrated Spring Boot backend + Room offline queue + FCM room-status pushes
APP_TYPE: mobile
LANGUAGE: Kotlin
SCALE: 320 hotels, 6,500 attendant devices, 4,000 concurrent morning peak, ~18 GB data
```

## 37. HelixRelay — hospital HL7 routing pipeline

```text
APP_DESCRIPTION: A clinical message routing pipeline for a hospital group's integration team. It ingests HL7v2 ADT, ORM, and ORU feeds from EHR, lab, and radiology systems, transforms segments between site-specific dialects, enriches with a patient-identity registry, and routes to subscribing systems with guaranteed ordering per patient.
TECH_STACK: Kotlin + Kafka (keyed by patient ID) + HAPI HL7 parsing + Kafka Streams transforms + PostgreSQL registry + dead-letter reprocessing UI hooks
APP_TYPE: data pipeline
LANGUAGE: Kotlin
SCALE: 3.5M messages/day across 11 hospitals, 140 subscribing systems, 7-year archive ~25 TB
```

## 38. ChalkCheck — classroom attendance and notes

```text
APP_DESCRIPTION: An attendance and behavior-note mobile app for primary and secondary teachers. Teachers take attendance in two taps with late/excused codes synced to the school office, log positive and concern notes per student, and trigger parent notifications for unexplained absences within the first period.
TECH_STACK: Kotlin (Android, Jetpack Compose) + Retrofit to school SIS API + Room offline cache + FCM parent notifications
APP_TYPE: mobile
LANGUAGE: Kotlin
SCALE: 1,100 schools, 38,000 teacher MAU, 25,000 concurrent at first bell, ~30 GB data
```

## 39. IdentIvy — KYC verification API

```text
APP_DESCRIPTION: A know-your-customer verification API for fintechs and marketplaces. It orchestrates document capture checks, face-match liveness results, sanctions and PEP screening, and address verification into a single decision with reason codes, and re-screens existing customers on watchlist updates.
TECH_STACK: Kotlin (Spring Boot WebFlux) + PostgreSQL + Kafka + vendor adapters (doc-verify, liveness, watchlists) + Vault-managed secrets, on GCP GKE
APP_TYPE: API service
LANGUAGE: Kotlin
SCALE: 55,000 verifications/day, 130 client integrations, ~200 GB encrypted evidence store
```

## 40. DoorDossier — open-house tour companion

```text
APP_DESCRIPTION: A home-buying mobile app for touring open houses. Buyers check in at listings via QR, capture room-by-room photos and voice notes organized per property, rate homes against their must-have checklist, and compare shortlisted properties side by side with their agent.
TECH_STACK: Kotlin (Android, Jetpack Compose) + CameraX + Room + MLS listing API via Retrofit + Ktor sync backend + S3 media
APP_TYPE: mobile
LANGUAGE: Kotlin
SCALE: 65,000 MAU, 15,000 tours logged/weekend, ~35 GB media storage
```

## 41. helmdrift — Helm values drift CLI

```text
APP_DESCRIPTION: A CLI tool for platform teams that detects drift between Helm release values and their git-declared sources. It renders charts with environment overlays, diffs against live cluster state, classifies drift as benign or breaking via policy rules, and emits console, JSON, and GitOps-PR-comment output.
TECH_STACK: Kotlin CLI (clikt) + Kubernetes/Helm client libraries + YAML diff engine + OPA-style policy rules in Kotlin DSL
APP_TYPE: CLI
LANGUAGE: Kotlin
SCALE: single user per invocation, ~600 CI runs/day across 45 clusters, <200 MB cache
```

## 42. BrewBarrel — homebrew batch tracker

```text
APP_DESCRIPTION: A batch-tracking mobile app for homebrewers. Brewers plan recipes with grain, hop, and yeast bills, log mash and fermentation readings with Bluetooth hydrometer support, get step timers on brew day, and keep a tasting journal across batch iterations of the same recipe.
TECH_STACK: Kotlin (Android, Jetpack Compose) + Room + BLE hydrometer (Tilt-style) integration + WorkManager timers + optional Ktor cloud sync
APP_TYPE: mobile
LANGUAGE: Kotlin
SCALE: 33,000 MAU, 400,000 batches logged, ~6 GB backend data
```

## 43. RoomRelay — hotel channel manager API

```text
APP_DESCRIPTION: A channel-manager API for independent hotels and small chains. It synchronizes room availability, rates, and restrictions to OTAs and the hotel's own booking engine, ingests reservations and cancellations from all channels into one stream, and prevents overbooking with atomic inventory holds.
TECH_STACK: Kotlin (Ktor) + PostgreSQL + Redis inventory locks + Kafka reservation stream + OTA partner adapters (XML/JSON), on AWS EKS
APP_TYPE: API service
LANGUAGE: Kotlin
SCALE: 2,800 hotels, 11 channel integrations, ~180 sync ops/sec peak, ~70 GB data
```

## 44. MotorMinder — car maintenance log

```text
APP_DESCRIPTION: A vehicle-maintenance mobile app for private car owners. Owners log services, fuel-ups, and repairs per vehicle with receipt photos, get mileage- and time-based reminders for oil, tires, and inspections, decode dashboard warning lights via a Bluetooth OBD reader, and export history when selling the car.
TECH_STACK: Kotlin (Android, Jetpack Compose) + Room + BLE OBD-II integration + WorkManager reminders + PDF export + Ktor backup sync
APP_TYPE: mobile
LANGUAGE: Kotlin
SCALE: 110,000 MAU, 190,000 vehicles tracked, ~14 GB receipt/media storage
```

## 45. LabLatch — lab instrument capture desktop

```text
APP_DESCRIPTION: A bench-side desktop app for environmental testing labs. Technicians capture readings directly from balances, pH meters, and spectrophotometers over serial/USB, validate results against method-specific acceptance ranges, attach them to sample chains of custody, and push signed results to the lab's LIMS.
TECH_STACK: Kotlin (Compose Multiplatform Desktop) + jSerialComm instrument I/O + SQLDelight local store + Ktor client to LIMS REST API
APP_TYPE: desktop
LANGUAGE: Kotlin
SCALE: 40 labs, 350 bench installs, ~12,000 readings/day, <5 GB per lab
```

## 46. PotholePing — civic issue reporting

```text
APP_DESCRIPTION: A civic-issue reporting mobile app run by a city public-works department. Residents report potholes, broken streetlights, graffiti, and illegal dumping with geotagged photos, track repair status through triage and crew dispatch, and see a map of recently fixed issues in their neighborhood.
TECH_STACK: Kotlin (Android, Jetpack Compose) + CameraX + Retrofit to Spring Boot backend + PostGIS + FCM status updates
APP_TYPE: mobile
LANGUAGE: Kotlin
SCALE: 85,000 MAU, 1,400 reports/day, 2,200 city crew users, ~50 GB media/data
```

## 47. OddsOtter — sports fixtures and odds API

```text
APP_DESCRIPTION: A sports data API serving fixtures, live scores, and aggregated betting odds to media sites and fantasy apps. It normalizes feeds from multiple data providers, resolves team and player identity across sources, pushes in-play score changes over websockets, and enforces per-client rate and market entitlements.
TECH_STACK: Kotlin (Ktor) + Redis hot cache + PostgreSQL + Kafka feed ingestion + WebSocket fan-out, on GCP GKE
APP_TYPE: API service
LANGUAGE: Kotlin
SCALE: 12,000 req/sec Saturday peak, 480 client keys, 30 sports, ~90 GB data
```

## 48. PlayPulse — game telemetry pipeline

```text
APP_DESCRIPTION: A player-telemetry pipeline for a mobile game studio's live-ops team. It ingests session, progression, purchase, and crash events from game clients, sessionizes and validates against the event schema registry, computes retention and economy KPIs, and feeds A/B test evaluation and churn-prediction models.
TECH_STACK: Kotlin + Kafka + Kafka Streams + Avro/Schema Registry + BigQuery sink + dbt-modeled marts, on GCP
APP_TYPE: data pipeline
LANGUAGE: Kotlin
SCALE: 4M DAU across 5 titles, 45,000 events/sec peak, ~120 TB warehouse
```

## 49. CreaseCourier — dry-cleaning pickup service

```text
APP_DESCRIPTION: An on-demand laundry and dry-cleaning mobile app. Customers schedule doorstep pickups with itemized garment lists and care notes, track orders through cleaning and pressing stages, and get delivery windows; drivers get optimized pickup routes and scan bag tags at each handoff.
TECH_STACK: Kotlin (Android, Jetpack Compose) + Ktor backend + PostgreSQL + route optimization service + Stripe + FCM stage updates
APP_TYPE: mobile
LANGUAGE: Kotlin
SCALE: 26,000 MAU, 3,000 orders/day, 190 drivers, 40 partner cleaners, ~8 GB data
```

## 50. CarbonQuill — carbon accounting API

```text
APP_DESCRIPTION: A carbon-accounting API for corporate sustainability teams. It ingests activity data (energy bills, fleet fuel, purchased goods, travel bookings), applies versioned emission factors per region and year, computes Scope 1–3 footprints with audit lineage, and exports disclosure-ready reports (CSRD/GHG Protocol).
TECH_STACK: Kotlin (Spring Boot) + JPA + PostgreSQL + emission-factor dataset versioning + Kafka ingestion + S3 evidence store, on AWS EKS
APP_TYPE: API service
LANGUAGE: Kotlin
SCALE: 240 corporate tenants, 15M activity records/year, ~110 GB data
```

## 51. DiveDatum — scuba dive log

```text
APP_DESCRIPTION: A dive-logging mobile app for recreational scuba divers. Divers import depth profiles from Bluetooth dive computers, log conditions, buddies, and marine-life sightings per dive site, track certification progress and gear service intervals, and share dive-site reviews with the community.
TECH_STACK: Kotlin (Android, Jetpack Compose) + BLE dive computer protocols + Room + MapLibre dive-site map + Ktor community backend
APP_TYPE: mobile
LANGUAGE: Kotlin
SCALE: 48,000 MAU, 1.2M logged dives, 30,000 dive sites, ~11 GB data
```

## 52. EchoScribe — desktop transcription studio

```text
APP_DESCRIPTION: An offline-first desktop transcription app for journalists and qualitative researchers. Users import interview recordings, get on-device speech-to-text with speaker separation, correct transcripts in a synced audio-text editor with timestamps, and export to Word, subtitle, and QDA formats.
TECH_STACK: Kotlin (Compose Multiplatform Desktop) + whisper.cpp via JNI + SQLDelight project store + FFmpeg audio decoding
APP_TYPE: desktop
LANGUAGE: Kotlin
SCALE: 25,000 installs, ~9,000 MAU, recordings up to 6 hours, fully local data
```

## 53. SnagSnap — construction punch lists

```text
APP_DESCRIPTION: A snagging and punch-list mobile app for construction site managers and subcontractors. Managers pin defects to floor plans with photos and trade assignments, subcontractors mark items resolved with evidence photos, and handover reports compile outstanding items per zone for the client walkthrough.
TECH_STACK: Kotlin (Android, Jetpack Compose) + PDF floor-plan rendering + CameraX + Room offline store + WorkManager sync + Ktor backend
APP_TYPE: mobile
LANGUAGE: Kotlin
SCALE: 850 active projects, 14,000 MAU, ~9,000 defects logged/day, ~120 GB media
```

## 54. PinPress — address validation API

```text
APP_DESCRIPTION: An address validation and geocoding API for checkout forms and shipping systems. It parses free-text addresses into structured components, corrects and standardizes against national postal datasets, returns rooftop coordinates with confidence scores, and suggests completions for type-ahead address entry.
TECH_STACK: Kotlin (Ktor) + Lucene-based fuzzy index + PostGIS + national postal reference datasets + Redis, on Hetzner Kubernetes
APP_TYPE: API service
LANGUAGE: Kotlin
SCALE: 2,500 req/sec autocomplete peak, 900 client keys, 14 country datasets, ~180 GB reference data
```

## 55. PaperPerch — conference CFP review portal

```text
APP_DESCRIPTION: A server-rendered call-for-papers web app for tech and academic conference organizers. Speakers submit talk proposals with abstracts and past-talk links, reviewers score anonymized submissions against rubric criteria, and organizers resolve conflicts, build the accepted schedule, and send batched notifications.
TECH_STACK: Kotlin (Spring Boot + Thymeleaf) + JPA + PostgreSQL + anonymization rules + transactional email via SES
APP_TYPE: web app
LANGUAGE: Kotlin
SCALE: 130 conferences/year, 22,000 submissions/year, 4,500 reviewer accounts, ~8 GB data
```

## 56. StarSlate — amateur astronomy planner

```text
APP_DESCRIPTION: A stargazing planner mobile app for amateur astronomers. Users get tonight's visible planets, ISS passes, and deep-sky targets for their location and equipment, a light-pollution and cloud-cover forecast for session planning, and an observation log with sketches and imaging notes.
TECH_STACK: Kotlin (Android, Jetpack Compose) + on-device ephemeris calculations + weather/light-pollution APIs via Retrofit + Room log + sensor-driven sky compass
APP_TYPE: mobile
LANGUAGE: Kotlin
SCALE: 58,000 MAU, 5,000 concurrent on clear-sky evenings, ~4 GB backend data
```

## 57. sqlsquash — migration squashing CLI

```text
APP_DESCRIPTION: A CLI tool for backend teams drowning in years of incremental SQL migrations. It replays a migration directory against an ephemeral database, generates a single squashed baseline schema with data-migration guards, verifies equivalence by schema diff, and rewrites the migration history with tool-specific metadata (Flyway/Liquibase).
TECH_STACK: Kotlin CLI (clikt) + Testcontainers ephemeral databases + JDBC schema introspection + SQL AST diffing
APP_TYPE: CLI
LANGUAGE: Kotlin
SCALE: single user per invocation, projects with up to 3,000 migrations, ~150 CI runs/day
```

## 58. BillBirch — subscription billing API

```text
APP_DESCRIPTION: A subscription-billing API for B2B SaaS companies. It manages plans with seats, usage meters, and tiered pricing, handles proration on upgrades and mid-cycle seat changes, runs dunning flows for failed payments, computes revenue-recognition schedules, and syncs invoices to accounting systems.
TECH_STACK: Kotlin (Spring Boot) + JPA + PostgreSQL + Kafka billing events + Stripe/Adyen payment adapters + Redis, on AWS EKS
APP_TYPE: API service
LANGUAGE: Kotlin
SCALE: 380 SaaS tenants, 2.1M subscriptions, 450,000 invoices/month, ~250 GB data
```

## 59. RideRing — school-run carpool

```text
APP_DESCRIPTION: A school-run carpooling mobile app for parent communities. Parents form verified carpool circles per school, schedule recurring morning and afternoon rotations with fair-share balancing, get live pickup confirmations when their child is collected, and swap turns when plans change.
TECH_STACK: Kotlin (Android, Jetpack Compose) + Ktor backend + PostgreSQL + school-domain verification + FCM pickup confirmations + fused location check-ins
APP_TYPE: mobile
LANGUAGE: Kotlin
SCALE: 42,000 MAU, 6,800 active circles across 900 schools, ~7 GB data
```

## 60. QuoteQuarry — market data normalization pipeline

```text
APP_DESCRIPTION: A market-data pipeline for a brokerage's trading platform. It ingests equity and ETF quote/trade feeds from multiple exchanges, normalizes symbology and timestamps, builds consolidated best-bid-offer and one-minute bars, and publishes to the order-management system and charting services with strict latency budgets.
TECH_STACK: Kotlin + Kafka + custom low-GC stream processors (Kotlin/JVM, Chronicle Queue) + kdb-style time-series sink + Prometheus latency SLOs
APP_TYPE: data pipeline
LANGUAGE: Kotlin
SCALE: 220,000 messages/sec market-open peak, 9,000 symbols, ~6 TB/day raw, 5-year bars ~50 TB
```

## 61. VinVault — wine cellar management

```text
APP_DESCRIPTION: A cellar-management mobile app for wine collectors. Collectors catalog bottles by label scan with vintage and provenance details, map physical cellar locations by rack and slot, get drink-by-window alerts, log tasting notes against professional scores, and track collection valuation over time.
TECH_STACK: Kotlin (Android, Jetpack Compose) + ML Kit label recognition + wine database API via Retrofit + Room + Ktor sync + FCM drink-window alerts
APP_TYPE: mobile
LANGUAGE: Kotlin
SCALE: 30,000 MAU, 4.5M bottles cataloged, ~16 GB data
```

## 62. LotLink — dealership inventory syndication API

```text
APP_DESCRIPTION: An inventory-syndication API for auto dealer groups. It ingests vehicle stock from dealer management systems, enriches listings with VIN-decoded specs, options, and photo sets, publishes normalized feeds to marketplaces and the group's websites, and reconciles leads back to the originating vehicle and store.
TECH_STACK: Kotlin (Spring Boot) + PostgreSQL + VIN decode service + Kafka feed fan-out + S3 image pipeline with renditions, on Azure AKS
APP_TYPE: API service
LANGUAGE: Kotlin
SCALE: 1,400 dealerships, 260,000 live vehicles, 18 marketplace feeds, ~35 GB data + 12 TB images
```

## 63. LeaseLantern — tenant screening API

```text
APP_DESCRIPTION: A tenant-screening API for property managers and rental platforms. It runs applicant consent flows, orchestrates credit, eviction-history, and income-verification checks through bureau adapters, produces a standardized screening report with adverse-action reason codes, and enforces jurisdiction-specific screening rules.
TECH_STACK: Kotlin (Spring Boot WebFlux) + PostgreSQL + bureau/verification vendor adapters + Kafka + KMS field-level encryption, on AWS ECS
APP_TYPE: API service
LANGUAGE: Kotlin
SCALE: 28,000 screenings/day, 95 platform integrations, ~140 GB encrypted data
```

## 64. CrewCompass — flight crew roster companion

```text
APP_DESCRIPTION: A roster companion mobile app for airline pilots and cabin crew. Crew see published rosters with pairing details, hotel and transport info per layover, receive reassignment and delay notifications, track flight-time limitations against regulatory limits, and bid on open trips.
TECH_STACK: Kotlin (Android, Jetpack Compose) + Retrofit to crew-management system API + Room offline roster + FCM reassignment alerts + calendar sync
APP_TYPE: mobile
LANGUAGE: Kotlin
SCALE: 19,000 crew MAU at 3 airlines, 6,000 concurrent during disruption events, ~9 GB data
```

## 65. YardYoke — equipment rental yard portal

```text
APP_DESCRIPTION: A server-rendered rental management web app for tool and plant-hire yards. Counter staff create hire contracts with availability checks, damage-deposit handling, and delivery scheduling; the yard tracks each asset's utilization, maintenance due-hours, and off-hire inspections with charge-back for damage.
TECH_STACK: Kotlin (Spring Boot + Thymeleaf + htmx) + JPA + PostgreSQL + label/contract PDF printing + Stripe deposits
APP_TYPE: web app
LANGUAGE: Kotlin
SCALE: 75 yards, 60,000 rental assets, ~1,800 contracts/day network-wide, ~20 GB data
```

## 66. KinKeeper — family caregiver coordination

```text
APP_DESCRIPTION: A care-coordination mobile app for families looking after aging parents. Family members share a care calendar for visits, meds pickups, and appointments, log daily check-in notes visible to the circle, get alerts when a scheduled check-in is missed, and store key documents like insurance and advance directives.
TECH_STACK: Kotlin (Android, Jetpack Compose) + Ktor backend + PostgreSQL + FCM missed-check-in alerts + encrypted document storage (S3 + KMS)
APP_TYPE: mobile
LANGUAGE: Kotlin
SCALE: 52,000 MAU, 21,000 care circles, ~13 GB data
```

## 67. SlateSpine — student information API

```text
APP_DESCRIPTION: A student-information-system API for a network of charter schools. It manages enrollment, schedules, grades, and attendance as the system of record, syncs rosters to learning tools via OneRoster, enforces guardian data-access rules, and publishes gradebook and attendance events to the district's analytics warehouse.
TECH_STACK: Kotlin (Spring Boot) + JPA + PostgreSQL + OneRoster/LTI integrations + Kafka events + row-level access policies, on GCP GKE
APP_TYPE: API service
LANGUAGE: Kotlin
SCALE: 110 schools, 68,000 students, 9,000 staff users, ~90 GB data
```

## 68. CreelClerk — fishing catch log

```text
APP_DESCRIPTION: A catch-logging mobile app for recreational anglers. Anglers log catches with species, length, and photo, auto-tagged with water body, weather, and moon phase, check local regulations and size/bag limits by location, and see seasonal bite patterns from their own history — offline-capable on the water.
TECH_STACK: Kotlin (Android, Jetpack Compose) + Room offline store + CameraX + regulations dataset sync + weather API + MapLibre
APP_TYPE: mobile
LANGUAGE: Kotlin
SCALE: 88,000 MAU, 2.8M catches logged/year, ~28 GB media/data
```

## 69. specfold — OpenAPI client generator CLI

```text
APP_DESCRIPTION: A CLI tool that generates idiomatic Kotlin API clients from OpenAPI specs. It emits coroutine-based Ktor or Retrofit clients with kotlinx.serialization models, sealed-class error hierarchies per endpoint, and configurable auth plumbing, and can diff two spec versions to flag breaking changes in CI.
TECH_STACK: Kotlin CLI (clikt) + Swagger parser + KotlinPoet code generation + Gradle plugin companion
APP_TYPE: CLI
LANGUAGE: Kotlin
SCALE: single user per invocation, specs up to 900 endpoints, ~250 CI runs/day across adopting teams
```

## 70. FurrowCast — farm weather pipeline

```text
APP_DESCRIPTION: An agri-weather data pipeline for a crop-advisory company. It ingests readings from on-farm weather stations and soil-moisture probes, blends them with radar and forecast model grids, computes field-level spray windows, frost risk, and irrigation recommendations, and pushes advisories to agronomist tools.
TECH_STACK: Kotlin + Kafka + Kafka Streams + station/probe MQTT ingestion + GRIB forecast decoding + PostGIS field geometry + TimescaleDB
APP_TYPE: data pipeline
LANGUAGE: Kotlin
SCALE: 12,000 stations and probes, ~800 readings/sec, 45,000 monitored fields, ~8 TB time-series
```

## 71. BirdieBook — golf scoring and handicap

```text
APP_DESCRIPTION: A golf scoring mobile app for club and society golfers. Players keep live scorecards with stableford and stroke-play formats, get GPS distances to greens and hazards per hole, maintain an official-style handicap index from submitted rounds, and run society leaderboards that update as groups finish holes.
TECH_STACK: Kotlin (Android, Jetpack Compose) + course database + fused location + Room + Ktor backend + live leaderboard over WebSockets
APP_TYPE: mobile
LANGUAGE: Kotlin
SCALE: 74,000 MAU, 9,000 concurrent Sunday-morning peak, 6,200 mapped courses, ~15 GB data
```

## 72. RigRoster — ham radio logging desktop

```text
APP_DESCRIPTION: A logging and rig-control desktop app for amateur radio operators. Operators log QSOs with automatic frequency/mode capture from CAT-connected transceivers, look up callsigns against online databases, track awards progress (DXCC, grid squares), and upload confirmations to LoTW and eQSL.
TECH_STACK: Kotlin (Compose Multiplatform Desktop) + serial CAT control (hamlib bindings) + SQLDelight logbook + ADIF import/export + callsign lookup APIs
APP_TYPE: desktop
LANGUAGE: Kotlin
SCALE: 18,000 installs, logbooks up to 500,000 QSOs, fully local with optional cloud backup
```

## 73. DocentDot — museum audio guide

```text
APP_DESCRIPTION: An audio-guide mobile app for a consortium of museums and heritage sites. Visitors unlock tours by ticket QR, follow numbered or beacon-triggered stops with audio in nine languages, view zoomable artwork details, and build a "my visit" collection of favorites emailed after the trip.
TECH_STACK: Kotlin (Android, Jetpack Compose) + ExoPlayer + BLE beacon triggers + offline tour packs via Room/downloads + Ktor CMS backend
APP_TYPE: mobile
LANGUAGE: Kotlin
SCALE: 300,000 visitors/year, 40,000 MAU in season, 55 venues, ~180 GB audio assets
```

## 74. MoveMason — moving company operations portal

```text
APP_DESCRIPTION: A server-rendered operations web app for residential moving companies. Estimators build room-by-room inventories into binding quotes, dispatchers assign crews and trucks against a capacity board, crews confirm job stages from a mobile browser, and the office invoices with storage and materials line items.
TECH_STACK: Kotlin (Ktor + FreeMarker + htmx) + Exposed + PostgreSQL + PDF quote/invoice generation + Twilio SMS notifications
APP_TYPE: web app
LANGUAGE: Kotlin
SCALE: 60 moving companies, ~450 jobs/day network-wide, 2,800 crew users, ~12 GB data
```

## 75. SableScore — transaction fraud scoring API

```text
APP_DESCRIPTION: A real-time fraud-scoring API for card issuers and payment processors. It scores authorization requests against device, velocity, and merchant-risk features within a strict latency budget, applies issuer-configurable rule overlays, supports analyst case review feedback loops, and retrains feature baselines nightly.
TECH_STACK: Kotlin (Ktor, low-latency tuned) + Redis feature store + Kafka + ONNX model inference + PostgreSQL case store, on-prem Kubernetes
APP_TYPE: API service
LANGUAGE: Kotlin
SCALE: 6,000 authorizations/sec peak at p99 <40ms, 9 issuer tenants, ~4 TB feature/event data
```

## 76. NestNine — pregnancy companion

```text
APP_DESCRIPTION: A pregnancy-companion mobile app for expecting parents. Parents follow week-by-week fetal development with clinically reviewed content, track symptoms, weight, and kick counts, keep a checklist of appointments and screening windows synced with their care schedule, and prepare a birth plan to share with the midwife.
TECH_STACK: Kotlin (Android, Jetpack Compose) + Room + WorkManager reminders + CMS-backed content via Ktor client + FCM
APP_TYPE: mobile
LANGUAGE: Kotlin
SCALE: 130,000 MAU, ~30-week average engagement span, ~22 GB content/backend data
```

## 77. scrubline — log anonymization CLI

```text
APP_DESCRIPTION: A CLI tool for compliance and support teams that anonymizes production logs before sharing. It detects and masks emails, phone numbers, IPs, tokens, and national ID patterns across structured and free-text logs, preserves referential consistency with deterministic pseudonyms, and emits a redaction report for audit.
TECH_STACK: Kotlin CLI (clikt) + streaming line processors + regex/dictionary detectors + deterministic HMAC pseudonymization + JSON/logfmt awareness
APP_TYPE: CLI
LANGUAGE: Kotlin
SCALE: single user per invocation, files up to 50 GB streamed, ~80 runs/day across teams
```

## 78. SwipeSage — campus meal plan companion

```text
APP_DESCRIPTION: A campus dining mobile app for university students. Students check meal-swipe and dining-dollar balances, see hall menus with allergen and macro filters, view live occupancy to dodge lunch rushes, and pre-order grab-and-go meals for pickup lockers between classes.
TECH_STACK: Kotlin (Android, Jetpack Compose) + Retrofit to campus-card system API + Ktor ordering backend + PostgreSQL + FCM order-ready alerts
APP_TYPE: mobile
LANGUAGE: Kotlin
SCALE: 34,000 student MAU at 4 universities, 5,500 concurrent lunch peak, ~5 GB data
```

## 79. InvoIris — e-invoicing compliance API

```text
APP_DESCRIPTION: An e-invoicing API that keeps sellers compliant across jurisdictions. It converts invoice payloads into country-mandated formats (Peppol BIS, FatturaPA, CFDI-style), handles clearance submission to tax-authority networks with signature and QR requirements, tracks acceptance status, and archives invoices per local retention law.
TECH_STACK: Kotlin (Spring Boot) + PostgreSQL + XML/UBL transformation + digital signature (HSM-backed) + Peppol access point integration + S3 WORM archive
APP_TYPE: API service
LANGUAGE: Kotlin
SCALE: 900,000 invoices/month, 320 seller tenants, 17 country profiles, ~1.2 TB archive
```

## 80. WingWatch — birdwatching life list

```text
APP_DESCRIPTION: A birdwatching mobile app for hobbyist birders. Birders log sightings with location and behavior notes, get ID help from photo and song-recording recognition, maintain life and year lists with rarity flags, and receive alerts when a target species is reported nearby by the community.
TECH_STACK: Kotlin (Android, Jetpack Compose) + TF Lite image/audio ID models + Room offline log + Ktor community backend + PostGIS + FCM rarity alerts
APP_TYPE: mobile
LANGUAGE: Kotlin
SCALE: 96,000 MAU, 12M sightings/year, ~60 GB media/backend data
```

## 81. StreamStoat — Kafka topic browser desktop

```text
APP_DESCRIPTION: A desktop workbench for developers operating Kafka clusters. Engineers browse topics with schema-aware message decoding (Avro/Protobuf/JSON), search offsets by timestamp and key, produce test messages against schemas, inspect consumer-group lag, and compare topic configs across dev/stage/prod clusters.
TECH_STACK: Kotlin (Compose Multiplatform Desktop) + Kafka client + Schema Registry client + SQLDelight for saved workspaces + SASL/TLS profiles
APP_TYPE: desktop
LANGUAGE: Kotlin
SCALE: 12,000 installs, clusters up to 4,000 topics, read-heavy tooling with local-only state
```

## 82. ThreadThrift — secondhand fashion marketplace

```text
APP_DESCRIPTION: A peer-to-peer secondhand fashion mobile marketplace. Sellers list garments with guided photos, brand/size autocomplete, and price suggestions from sold comparables; buyers filter by size profile and follow closets, chat with offers, and pay through escrow with tracked shipping labels generated in-app.
TECH_STACK: Kotlin (Android, Jetpack Compose) + Ktor backend + PostgreSQL + Elasticsearch search + Stripe Connect escrow + shipping-label APIs + FCM
APP_TYPE: mobile
LANGUAGE: Kotlin
SCALE: 220,000 MAU, 65,000 new listings/week, 9,000 concurrent evening peak, ~500 GB media
```

## 83. MainsMinder — water network sensor pipeline

```text
APP_DESCRIPTION: A leak-detection data pipeline for a municipal water utility. It ingests pressure, flow, and acoustic-sensor readings from district metered areas, detects anomalies indicating bursts and background leakage against night-flow baselines, prioritizes zones by estimated loss, and dispatches events to the works-order system.
TECH_STACK: Kotlin + Kafka + Kafka Streams anomaly detectors + LoRaWAN/NB-IoT ingestion gateway + TimescaleDB + Grafana operational dashboards
APP_TYPE: data pipeline
LANGUAGE: Kotlin
SCALE: 18,000 network sensors, 260 district metered areas, ~600 readings/sec, ~5 TB time-series
```

## 84. AxleAudit — bus fleet pre-trip inspections

```text
APP_DESCRIPTION: A vehicle-inspection mobile app for bus and coach operators. Drivers complete regulated daily walkaround checks with guided item lists and photo evidence of defects, mechanics receive prioritized defect queues with vehicle-out-of-service locks, and compliance officers export inspection records for roadside audits.
TECH_STACK: Kotlin (Android, Jetpack Compose) + Room offline checklists + CameraX + Retrofit to Spring Boot backend + FCM defect assignment
APP_TYPE: mobile
LANGUAGE: Kotlin
SCALE: 240 operators, 11,000 vehicles, 9,500 driver MAU, ~16,000 inspections/day, ~40 GB data
```

## 85. TrackTrellis — shipment tracking aggregation API

```text
APP_DESCRIPTION: A shipment-tracking aggregation API for e-commerce platforms and customer-service tools. It normalizes tracking events from parcel carriers worldwide into one status model, predicts delivery dates from lane history, detects stalled and exception shipments proactively, and pushes webhook updates per parcel.
TECH_STACK: Kotlin (Ktor) + PostgreSQL + Kafka + carrier adapter framework (REST/EDI/scraper) + Redis + webhook delivery with retries, on AWS EKS
APP_TYPE: API service
LANGUAGE: Kotlin
SCALE: 2.5M active parcels tracked, 140 carrier integrations, ~900 events/sec, ~350 GB data
```

## 86. SetSummit — home strength training

```text
APP_DESCRIPTION: A home strength-training mobile app for dumbbell and bodyweight athletes. Users follow progressive programs that auto-adjust loads from logged sets and RPE, get rest timers and form-cue videos per exercise, track volume and personal records per muscle group, and swap exercises based on available equipment.
TECH_STACK: Kotlin (Android, Jetpack Compose) + Room + ExoPlayer form videos + Health Connect integration + Ktor sync backend
APP_TYPE: mobile
LANGUAGE: Kotlin
SCALE: 105,000 MAU, 7,000 concurrent evening peak, ~10 GB backend data + 40 GB video
```

## 87. LyricLumen — worship presentation desktop

```text
APP_DESCRIPTION: A presentation desktop app for church production volunteers. Operators build service run-sheets with song lyrics, scripture passages, and sermon slides, output to projectors and stage displays with independent layouts, follow the worship leader with quick verse/chorus jumps, and sync song libraries across campuses.
TECH_STACK: Kotlin (Compose Multiplatform Desktop) + multi-display rendering + SQLDelight song library + CCLI reporting export + Ktor cloud sync
APP_TYPE: desktop
LANGUAGE: Kotlin
SCALE: 7,500 congregations, 20,000 operator installs, libraries up to 8,000 songs, <3 GB per site
```

## 88. PlotPatch — community garden management

```text
APP_DESCRIPTION: A server-rendered web app for community garden associations. Coordinators manage plot maps, waitlists, and annual renewals with fee collection, members book shared tools and greenhouse slots, log watering-rota duties, and post surplus-harvest swaps on the noticeboard.
TECH_STACK: Kotlin (Ktor + kotlinx.html + htmx) + Exposed + PostgreSQL + Stripe renewals + email digests
APP_TYPE: web app
LANGUAGE: Kotlin
SCALE: 420 garden associations, 38,000 members, 15,000 plots, ~4 GB data
```

## 89. AdAbacus — ad impression aggregation pipeline

```text
APP_DESCRIPTION: An ad-delivery measurement pipeline for a publisher network's ad-ops team. It ingests impression, viewability, and click beacons, deduplicates and filters invalid traffic against IAB lists, aggregates delivery counts per campaign line-item in near-real-time for pacing decisions, and reconciles against advertiser-side counts for billing.
TECH_STACK: Kotlin + Kafka + Kafka Streams windowed aggregation + Redis pacing counters + ClickHouse reporting sink + IVT filter lists
APP_TYPE: data pipeline
LANGUAGE: Kotlin
SCALE: 90,000 impressions/sec peak, 1,200 active campaigns, 92-day hot retention ~30 TB
```

## 90. KeyKerb — car-share vehicle inspections

```text
APP_DESCRIPTION: A trip-inspection mobile app embedded in a free-floating car-share service. Members photograph the vehicle's four corners and interior before and after trips with AI damage-diff flagging, report cleanliness and fuel/charge issues, and unlock/lock the car in-app; operations gets damage claims tied to the responsible trip.
TECH_STACK: Kotlin (Android, Jetpack Compose) + CameraX + on-device damage-diff model (TF Lite) + BLE vehicle unlock + Retrofit to fleet backend
APP_TYPE: mobile
LANGUAGE: Kotlin
SCALE: 68,000 MAU, 3,400 vehicles in 5 cities, 25,000 trips/day, ~200 GB inspection media
```

## 91. VisitVine — telehealth scheduling API

```text
APP_DESCRIPTION: A telehealth scheduling and session-orchestration API for clinic networks. It matches patients to clinicians by specialty, language, and licensure state, manages bookings with insurance-eligibility pre-checks, provisions video-session rooms with waiting-room state, and writes visit summaries back to the clinic EHR.
TECH_STACK: Kotlin (Spring Boot) + PostgreSQL + Redis session state + video platform API (Twilio-style) + FHIR EHR write-back + Kafka, on GCP GKE
APP_TYPE: API service
LANGUAGE: Kotlin
SCALE: 15,000 visits/day, 4,200 clinicians, 32 clinic tenants, ~120 GB data
```

## 92. FarmFigures — farm accounting desktop

```text
APP_DESCRIPTION: An accounting desktop app built for family farms. Farmers record income and expenses against enterprises (dairy, arable, contracting), track machinery costs and depreciation per implement, reconcile bank feeds, and produce cashflow forecasts around harvest and subsidy payment dates for the bank manager.
TECH_STACK: Kotlin (Compose Multiplatform Desktop) + SQLDelight double-entry ledger + bank feed (Open Banking) sync via Ktor + PDF report output
APP_TYPE: desktop
LANGUAGE: Kotlin
SCALE: 14,000 farm installs, ledgers up to 80,000 transactions, <1 GB per farm, offline-first
```

## 93. WordWren — early literacy practice

```text
APP_DESCRIPTION: An early-literacy mobile app for children aged 4–7 and their parents. Kids practice phonics through short game rounds that adapt to their letter-sound gaps, record themselves reading decodable sentences with speech-recognition feedback, and unlock story rewards; parents see a weekly progress digest.
TECH_STACK: Kotlin (Android, Jetpack Compose) + on-device speech recognition + adaptive sequencing engine + Room + COPPA-compliant Ktor backend
APP_TYPE: mobile
LANGUAGE: Kotlin
SCALE: 82,000 MAU, 15-minute average sessions, ~12 GB content + backend data
```

## 94. LocalLede — local news reader

```text
APP_DESCRIPTION: A local-news mobile app for a cooperative of independent town and county newsrooms. Readers follow their towns and topics like schools, planning applications, and high-school sports, get a morning digest and breaking alerts geofenced to their area, and unlock member-only reporting through one shared subscription.
TECH_STACK: Kotlin (Android, Jetpack Compose) + Ktor content API + PostgreSQL + FCM geofenced alerts + Room offline reading + Stripe subscriptions
APP_TYPE: mobile
LANGUAGE: Kotlin
SCALE: 140,000 MAU across 60 newsrooms, 9,000 concurrent at morning digest, ~30 GB content
```

## 95. VoxVellum — accessible audiobook player

```text
APP_DESCRIPTION: An audiobook player mobile app designed for blind and low-vision readers. Listeners navigate libraries and chapters through large-target gestures and full TalkBack-first UI, control granular speed and pitch per narrator, place voice-note bookmarks, and sync positions with library lending services like DAISY-format collections.
TECH_STACK: Kotlin (Android, Jetpack Compose with custom accessibility semantics) + ExoPlayer + DAISY/EPUB audio parsing + Room + library lending APIs
APP_TYPE: mobile
LANGUAGE: Kotlin
SCALE: 27,000 MAU, 350,000 lending checkouts/year, ~6 GB backend data
```

## 96. CrumbCycle — surplus food rescue

```text
APP_DESCRIPTION: A food-rescue mobile app connecting bakeries, grocers, and restaurants with surplus food to nearby charities and consumers. Businesses list end-of-day surplus bags with pickup windows, consumers reserve and pay a small rescue price, charities get priority claim windows, and impact stats show meals and CO2 saved.
TECH_STACK: Kotlin (Android, Jetpack Compose) + Ktor backend + PostGIS proximity search + Stripe + FCM pickup-window reminders
APP_TYPE: mobile
LANGUAGE: Kotlin
SCALE: 190,000 MAU, 2,400 partner businesses, 11,000 bags rescued/day, ~10 GB data
```

## 97. MatMingle — yoga studio booking

```text
APP_DESCRIPTION: A class-booking mobile app for boutique yoga and pilates studios. Members book classes against their pass or unlimited membership with waitlist auto-promotion, check in by QR at the door, track their practice streaks and favorite instructors, and get notified when a spot opens in a full class.
TECH_STACK: Kotlin (Android, Jetpack Compose) + Ktor backend + PostgreSQL + Stripe memberships + FCM waitlist promotions + QR check-in
APP_TYPE: mobile
LANGUAGE: Kotlin
SCALE: 46,000 MAU, 280 studios, 8,500 classes/week, ~7 GB data
```

## 98. SpendSpruce — personal budgeting

```text
APP_DESCRIPTION: A personal budgeting mobile app built on open-banking connections. Users link current accounts and cards, get transactions auto-categorized with local-model suggestions they can correct, set envelope budgets with safe-to-spend today amounts, and receive alerts for duplicate charges and creeping subscriptions.
TECH_STACK: Kotlin (Android, Jetpack Compose) + Open Banking aggregation via Ktor backend + PostgreSQL + on-device categorization model + biometric auth + FCM
APP_TYPE: mobile
LANGUAGE: Kotlin
SCALE: 175,000 MAU, 480,000 linked accounts, ~14M transactions/month, ~220 GB data
```

## 99. GiveGrove — nonprofit donation API

```text
APP_DESCRIPTION: A donation-processing API for nonprofits and fundraising platforms. It handles one-off and recurring gifts with employer-matching lookups, manages campaign and peer-to-peer fundraiser attribution, issues tax receipts per jurisdiction, retries failed recurring charges with donor-friendly dunning, and syncs donors to CRM systems.
TECH_STACK: Kotlin (Ktor) + Exposed + PostgreSQL + Stripe/PayPal adapters + Kafka events + receipt PDF service + CRM webhooks, on AWS ECS
APP_TYPE: API service
LANGUAGE: Kotlin
SCALE: 1,900 nonprofit tenants, 620,000 donations/month, ~$18M/month processed, ~130 GB data
```

## 100. OrchardOtter — orchard harvest management

```text
APP_DESCRIPTION: A harvest-management mobile app for apple and stone-fruit orchards. Crew leads assign picker teams to blocks and rows, pickers scan bin tags to credit piece-rate work, quality checkers grade samples per bin, and the packhouse sees incoming bin flow by variety — all offline-tolerant among the trees.
TECH_STACK: Kotlin (Android, Jetpack Compose) + QR bin-tag scanning (ML Kit) + Room offline queue + WorkManager sync + Ktor backend + PostgreSQL
APP_TYPE: mobile
LANGUAGE: Kotlin
SCALE: 160 orchards, 5,800 seasonal picker devices, 45,000 bins/day at harvest peak, ~9 GB data
```
