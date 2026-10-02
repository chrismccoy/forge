# TypeScript Blueprint Types — Copy-Paste Input Sets

Copy a fenced block into the prompt as-is, or swap individual fields.

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

## 14. RosterHatch — restaurant shift scheduling

```text
APP_DESCRIPTION: A shift-scheduling web app for multi-location restaurant groups. Managers build weekly rotas against forecasted covers, staff swap shifts and claim open slots from their phones, and labor-cost dashboards flag overtime before payroll closes.
TECH_STACK: SvelteKit + Drizzle ORM + PostgreSQL + Tailwind CSS, deployed on Fly.io
APP_TYPE: web app
LANGUAGE: TypeScript
SCALE: 600 concurrent users, ~70 req/sec, ~9 GB data
```

## 15. SoilSense — farm sensor dashboard

```text
APP_DESCRIPTION: A web dashboard for row-crop farmers monitoring in-field soil probes. Growers view live moisture, temperature, and salinity readings per field zone, set irrigation trigger thresholds, and export agronomy reports for their crop advisors.
TECH_STACK: Next.js + TimescaleDB (PostgreSQL) + MQTT ingest via AWS IoT Core + Recharts
APP_TYPE: web app
LANGUAGE: TypeScript
SCALE: 150 concurrent users, 12,000 sensor messages/min ingested, ~200 GB time-series data
```

## 16. BriefBinder — legal matter workspace

```text
APP_DESCRIPTION: A matter-management web app for small litigation firms. Paralegals organize pleadings, exhibits, and correspondence per case, attorneys annotate documents and track filing deadlines, and conflict checks run automatically on new client intake.
TECH_STACK: Next.js + Prisma + PostgreSQL + S3 document storage + OpenSearch, deployed on AWS
APP_TYPE: web app
LANGUAGE: TypeScript
SCALE: 250 concurrent users, ~40 req/sec, ~300 GB data (documents)
```

## 17. StayCurator — boutique hotel channel manager

```text
APP_DESCRIPTION: A channel-management web app for boutique hotels and guesthouses. Owners sync room availability and rates to Booking.com, Airbnb, and Expedia from one calendar, avoid double-bookings with real-time locks, and see revenue-per-room analytics.
TECH_STACK: Remix + Prisma + PostgreSQL + Redis rate cache + OTA channel APIs, deployed on Render
APP_TYPE: web app
LANGUAGE: TypeScript
SCALE: 400 concurrent users, ~90 req/sec including channel syncs, ~20 GB data
```

## 18. ClaimNest — home insurance claims portal

```text
APP_DESCRIPTION: A self-service claims portal for regional home insurers. Policyholders file claims with photo evidence, track adjuster visits and payout status, and upload contractor estimates; adjusters triage queues and approve settlements.
TECH_STACK: Next.js + tRPC + Prisma + PostgreSQL + S3 media storage, deployed on AWS Amplify
APP_TYPE: web app
LANGUAGE: TypeScript
SCALE: 1,200 concurrent users after storm events, ~180 req/sec peak, ~150 GB data
```

## 19. CrewCompass — hourly workforce onboarding

```text
APP_DESCRIPTION: An HR onboarding web app for employers of hourly workers in warehousing and retail. New hires complete I-9s, tax forms, and safety training on their phones before day one; HR tracks completion funnels and e-signature audit trails.
TECH_STACK: Next.js + Prisma + PostgreSQL + DocuSign API + BullMQ workers, deployed on Railway
APP_TYPE: web app
LANGUAGE: TypeScript
SCALE: 900 concurrent users during seasonal hiring, ~110 req/sec, ~40 GB data
```

## 20. ChalkRoute — homeschool co-op scheduler

```text
APP_DESCRIPTION: A class-scheduling web app for homeschool co-ops. Coordinators publish semester course catalogs, parents enroll kids and volunteer for teaching slots, and the app resolves room conflicts and generates weekly family timetables.
TECH_STACK: SvelteKit + Prisma + PostgreSQL + Tailwind CSS, deployed on Vercel
APP_TYPE: web app
LANGUAGE: TypeScript
SCALE: 120 concurrent users, ~20 req/sec, ~3 GB data
```

## 21. PermitPilot — municipal building permits

```text
APP_DESCRIPTION: A permit-application web portal for mid-size city building departments. Contractors submit plans and fees online, plan reviewers route applications through inspection workflows, and homeowners track status without calling city hall.
TECH_STACK: Next.js + NestJS backend + PostgreSQL + S3 plan storage + Keycloak SSO, deployed on Azure
APP_TYPE: web app
LANGUAGE: TypeScript
SCALE: 350 concurrent users, ~45 req/sec, ~500 GB data (plan PDFs)
```

## 22. AssayTrack — research lab sample tracking

```text
APP_DESCRIPTION: A sample-tracking web app for university wet labs. Technicians register specimens with barcode labels, log freezer locations and chain of custody, schedule assay runs, and export audit-ready lineage reports for grant compliance.
TECH_STACK: Remix + Drizzle ORM + PostgreSQL + ZPL label printing service, deployed on Fly.io
APP_TYPE: web app
LANGUAGE: TypeScript
SCALE: 90 concurrent users, ~18 req/sec, ~30 GB data
```

## 23. TidePost — marina berth booking

```text
APP_DESCRIPTION: A berth-reservation web app for coastal marinas. Boaters book transient slips by vessel length and draft, harbormasters manage seasonal contracts and utility metering, and arrival dashboards show the day's inbound vessels.
TECH_STACK: Next.js + Prisma + PostgreSQL + Stripe + Mapbox harbor maps, deployed on Vercel
APP_TYPE: web app
LANGUAGE: TypeScript
SCALE: 200 concurrent users in season, ~30 req/sec, ~5 GB data
```

## 24. MoldMetric — injection molding OEE dashboard

```text
APP_DESCRIPTION: A production-monitoring web app for plastics injection-molding plants. Supervisors watch per-machine OEE, cycle times, and scrap rates in real time, log downtime reasons from tablets on the floor, and compare shifts across plants.
TECH_STACK: Next.js + Fastify ingest API + TimescaleDB + Redis + Grafana-style charts, on-prem Docker
APP_TYPE: web app
LANGUAGE: TypeScript
SCALE: 180 concurrent users, 8,000 machine events/min, ~400 GB time-series data
```

## 25. ChoreOrbit — property maintenance requests

```text
APP_DESCRIPTION: A maintenance-request web app for residential property managers. Tenants submit issues with photos, dispatchers assign vendors by trade and urgency, and owners see per-unit repair histories and spend rollups.
TECH_STACK: Next.js + tRPC + Prisma + PostgreSQL + Twilio SMS, deployed on Vercel
APP_TYPE: web app
LANGUAGE: TypeScript
SCALE: 500 concurrent users, ~60 req/sec, ~35 GB data
```

## 26. RayYield — residential solar quoting

```text
APP_DESCRIPTION: A quoting web app for residential solar installers. Sales reps draw roof layouts on satellite imagery, the app estimates panel counts and production from irradiance data, and generates financed proposals with payback curves.
TECH_STACK: Next.js + PostgreSQL + PostGIS + Google Solar API + PDF generation (Puppeteer), on Vercel
APP_TYPE: web app
LANGUAGE: TypeScript
SCALE: 300 concurrent users, ~40 req/sec, ~25 GB data
```

## 27. VoltVine — EV charging network operations

```text
APP_DESCRIPTION: An operations web app for EV charging network operators. NOC staff monitor charger uptime and fault codes across sites, dispatch field techs, manage dynamic pricing windows, and reconcile session billing disputes.
TECH_STACK: Next.js + NestJS + PostgreSQL + Redis + OCPP WebSocket gateway, deployed on AWS EKS
APP_TYPE: web app
LANGUAGE: TypeScript
SCALE: 250 concurrent users, 3,500 charger heartbeats/min, ~120 GB data
```

## 28. RinkRoster — ice rink time booking

```text
APP_DESCRIPTION: An ice-time booking web app for community rinks. Hockey clubs and figure-skating coaches reserve sheets by the hour, the rink manages resurfacing buffers and season contracts, and public skate sessions sell tickets online.
TECH_STACK: Remix + Prisma + PostgreSQL + Stripe + iCal feeds, deployed on Render
APP_TYPE: web app
LANGUAGE: TypeScript
SCALE: 150 concurrent users, ~25 req/sec, ~4 GB data
```

## 29. GrantGrid — municipal grant management

```text
APP_DESCRIPTION: A grant-lifecycle web app for county governments distributing community funds. Nonprofits apply through scored forms, review committees deliberate with conflict-of-interest tracking, and finance staff monitor disbursements and reporting deadlines.
TECH_STACK: Next.js + Prisma + PostgreSQL + Azure AD SSO + S3 attachments, deployed on Azure App Service
APP_TYPE: web app
LANGUAGE: TypeScript
SCALE: 200 concurrent users at deadline peaks, ~30 req/sec, ~60 GB data
```

## 30. StockStitch — fabric shop inventory

```text
APP_DESCRIPTION: An inventory web app for independent fabric and quilting shops. Owners track bolts by fiber, colorway, and remaining yardage, sync cut-to-order sales with the POS, and get reorder alerts when popular prints run low.
TECH_STACK: SvelteKit + Drizzle ORM + PostgreSQL + Square POS API, deployed on Fly.io
APP_TYPE: web app
LANGUAGE: TypeScript
SCALE: 50 concurrent users, ~10 req/sec, ~3 GB data
```

## 31. ShelfSherpa — planogram compliance

```text
APP_DESCRIPTION: A planogram-compliance web app for grocery chains. Merchandisers publish shelf layouts per store cluster, store associates photograph aisles for AI-assisted compliance scoring, and category managers track share-of-shelf trends.
TECH_STACK: Next.js + NestJS + PostgreSQL + S3 photo storage + inference microservice, on AWS ECS
APP_TYPE: web app
LANGUAGE: TypeScript
SCALE: 2,000 concurrent users across stores, ~220 req/sec, ~1 TB photo data
```

## 32. PerkPorter — benefits enrollment

```text
APP_DESCRIPTION: A benefits-enrollment web app for mid-market employers. Employees compare medical, dental, and 401(k) options with cost calculators during open enrollment, and HR admins manage plan configurations and carrier EDI feeds.
TECH_STACK: Next.js + tRPC + Prisma + PostgreSQL + SFTP EDI batch jobs, deployed on Vercel
APP_TYPE: web app
LANGUAGE: TypeScript
SCALE: 5,000 concurrent users during open enrollment, ~400 req/sec peak, ~50 GB data
```

## 33. ReviewRudder — performance review cycles

```text
APP_DESCRIPTION: A performance-review web app for growing tech companies. HR launches review cycles with calibrated rating scales, employees write self-reviews and peer feedback, and managers run calibration sessions with distribution guardrails.
TECH_STACK: Remix + Prisma + PostgreSQL + Slack notifications + Tailwind CSS, deployed on Fly.io
APP_TYPE: web app
LANGUAGE: TypeScript
SCALE: 800 concurrent users at cycle deadlines, ~90 req/sec, ~15 GB data
```

## 34. VestVault — cap table management

```text
APP_DESCRIPTION: A cap-table web app for early-stage startups and their counsel. Founders issue option grants with vesting schedules, employees view their equity and exercise windows, and lawyers model dilution across financing rounds.
TECH_STACK: Next.js + tRPC + Prisma + PostgreSQL + audit logging + PDF grant docs, deployed on Vercel
APP_TYPE: web app
LANGUAGE: TypeScript
SCALE: 250 concurrent users, ~35 req/sec, ~8 GB data
```

## 35. TutorTide — tutoring marketplace

```text
APP_DESCRIPTION: A marketplace web app connecting parents with vetted K-12 tutors. Parents filter by subject, level, and availability, book recurring sessions with integrated video, and tutors manage rosters, lesson notes, and payouts.
TECH_STACK: Next.js + Prisma + PostgreSQL + Stripe Connect + LiveKit video, deployed on Vercel
APP_TYPE: web app
LANGUAGE: TypeScript
SCALE: 1,500 concurrent users on weeknights, ~200 req/sec, ~30 GB data
```

## 36. BrewBoard — brewery taproom and keg tracking

```text
APP_DESCRIPTION: An operations web app for craft breweries. Taproom staff manage rotating tap lists synced to digital menu screens, cellar crews track keg fill levels and locations, and owners see which beers move fastest by day and weather.
TECH_STACK: SvelteKit + Drizzle ORM + PostgreSQL + WebSocket menu screens, deployed on Railway
APP_TYPE: web app
LANGUAGE: TypeScript
SCALE: 100 concurrent users, ~20 req/sec, ~4 GB data
```

## 37. ClimbCache — climbing gym membership

```text
APP_DESCRIPTION: A membership and route-setting web app for climbing gyms. Members check in with QR codes, log sends and project routes, route setters plan wall resets by grade distribution, and staff manage waivers and day passes.
TECH_STACK: Next.js + Prisma + PostgreSQL + Stripe billing + QR check-in kiosk mode, on Vercel
APP_TYPE: web app
LANGUAGE: TypeScript
SCALE: 400 concurrent users on peak evenings, ~55 req/sec, ~10 GB data
```

## 38. RoamRaft — campervan rental platform

```text
APP_DESCRIPTION: A peer-to-peer campervan rental web app. Van owners list rigs with layouts and hookup specs, travelers book with mileage tiers and insurance add-ons, and handover checklists with photo documentation protect both sides.
TECH_STACK: Next.js + tRPC + Prisma + PostgreSQL + Stripe Connect + S3 photos, deployed on Vercel
APP_TYPE: web app
LANGUAGE: TypeScript
SCALE: 700 concurrent users in summer, ~85 req/sec, ~80 GB data
```

## 39. CrateCarrot — CSA farm-share subscriptions

```text
APP_DESCRIPTION: A subscription web app for community-supported agriculture farms. Members choose weekly box sizes and swap items within crop availability, farms plan harvest quantities from subscription counts, and pickup sites manage check-off lists.
TECH_STACK: Remix + Prisma + PostgreSQL + Stripe subscriptions + email digests via Resend, on Fly.io
APP_TYPE: web app
LANGUAGE: TypeScript
SCALE: 130 concurrent users on swap day, ~22 req/sec, ~4 GB data
```

## 40. BoothBloom — trade show booth booking

```text
APP_DESCRIPTION: An exhibitor-management web app for trade show organizers. Exhibitors pick booths from interactive floor plans with live availability, order power and furniture add-ons, and organizers manage move-in schedules and floor plan revisions.
TECH_STACK: Next.js + NestJS + PostgreSQL + Redis locks + SVG floor plan editor, deployed on AWS
APP_TYPE: web app
LANGUAGE: TypeScript
SCALE: 900 concurrent users when booth sales open, ~130 req/sec peak, ~15 GB data
```

## 41. NapNook — daycare parent updates

```text
APP_DESCRIPTION: A parent-communication web app for daycare centers. Teachers log naps, meals, and diaper changes from tablets, parents get real-time feeds with photos, and directors manage ratios, attendance, and licensing reports.
TECH_STACK: Next.js + Prisma + PostgreSQL + S3 photos + web push notifications, deployed on Vercel
APP_TYPE: web app
LANGUAGE: TypeScript
SCALE: 600 concurrent users at pickup time, ~75 req/sec, ~90 GB data (photos)
```

## 42. KinKeeper — family caregiver coordination

```text
APP_DESCRIPTION: A care-coordination web app for families managing elder care. Siblings share medication schedules, appointment calendars, and expense splits for an aging parent, and hired caregivers log visit notes visible to the whole family circle.
TECH_STACK: Next.js + tRPC + Prisma + PostgreSQL + Twilio reminders, deployed on Vercel
APP_TYPE: web app
LANGUAGE: TypeScript
SCALE: 350 concurrent users, ~30 req/sec, ~6 GB data
```

## 43. WrenchWren — auto repair shop scheduling

```text
APP_DESCRIPTION: A bay-scheduling web app for independent auto repair shops. Service writers book jobs against bay and technician availability, customers approve estimates by text link, and parts-on-order status feeds the daily board.
TECH_STACK: SvelteKit + Drizzle ORM + PostgreSQL + Twilio SMS + PartsTech API, deployed on Render
APP_TYPE: web app
LANGUAGE: TypeScript
SCALE: 80 concurrent users, ~15 req/sec, ~5 GB data
```

## 44. UsherUp — community theater ticketing

```text
APP_DESCRIPTION: A ticketing web app for community theaters and school auditoriums. Patrons pick seats from house maps, box office staff handle comps and season subscriptions, and front-of-house scans tickets at the door from any phone.
TECH_STACK: Next.js + Prisma + PostgreSQL + Stripe + QR ticket scanning PWA, deployed on Vercel
APP_TYPE: web app
LANGUAGE: TypeScript
SCALE: 1,000 concurrent users when a popular show goes on sale, ~140 req/sec peak, ~7 GB data
```

## 45. ScrubSlate — surgical instrument sterilization tracking

```text
APP_DESCRIPTION: A sterile-processing web app for hospital SPD departments. Techs scan instrument trays through wash, sterilize, and storage stages, the app enforces biological-indicator holds, and OR schedulers see tray readiness before each case.
TECH_STACK: Next.js + NestJS + PostgreSQL + barcode scanning + HL7 case feed, on-prem Kubernetes
APP_TYPE: web app
LANGUAGE: TypeScript
SCALE: 300 concurrent users across shifts, ~50 req/sec, ~45 GB data
```

## 46. PaddlePeak — pickleball league management

```text
APP_DESCRIPTION: A league-management web app for pickleball clubs. Organizers run ladder and round-robin leagues with DUPR-style ratings, players self-report scores with opponent confirmation, and courts are auto-assigned per match night.
TECH_STACK: Remix + Prisma + PostgreSQL + Tailwind CSS + SMS reminders, deployed on Fly.io
APP_TYPE: web app
LANGUAGE: TypeScript
SCALE: 250 concurrent users on league nights, ~35 req/sec, ~3 GB data
```

## 47. FrameFerry — optical lab order management

```text
APP_DESCRIPTION: An order-management web app connecting optometry practices with lens labs. Opticians submit Rx jobs with frame trace files, labs track jobs through surfacing and coating stations, and practices see promised dates and breakage remakes.
TECH_STACK: Next.js + NestJS + PostgreSQL + Redis job queue + OMA trace file parsing, on AWS ECS
APP_TYPE: web app
LANGUAGE: TypeScript
SCALE: 450 concurrent users, ~65 req/sec, ~25 GB data
```

## 48. HoofHold — farrier route scheduling

```text
APP_DESCRIPTION: A scheduling web app for farriers and equine dentists. Practitioners plan barn-to-barn routes on shoeing cycles, horse owners get due-date reminders and confirm visits, and per-horse records track shoe types and lameness notes.
TECH_STACK: SvelteKit + Drizzle ORM + PostgreSQL + Mapbox routing + Twilio, deployed on Railway
APP_TYPE: web app
LANGUAGE: TypeScript
SCALE: 60 concurrent users, ~8 req/sec, ~2 GB data
```

## 49. LoftLark — self-storage facility management

```text
APP_DESCRIPTION: A facility-management web app for self-storage operators. Renters lease units online with gate-code provisioning, managers run delinquency workflows through lien auctions, and occupancy heatmaps drive street-rate pricing.
TECH_STACK: Next.js + Prisma + PostgreSQL + Stripe billing + gate controller API, deployed on Vercel
APP_TYPE: web app
LANGUAGE: TypeScript
SCALE: 300 concurrent users, ~40 req/sec, ~18 GB data
```

## 50. FlockFold — congregation volunteer scheduling

```text
APP_DESCRIPTION: A volunteer-scheduling web app for churches and synagogues. Ministry leaders build serving rosters for greeters, musicians, and childcare, volunteers set blockout dates and swap slots, and reminders go out before each service.
TECH_STACK: Next.js + Prisma + PostgreSQL + Resend email + SMS reminders, deployed on Vercel
APP_TYPE: web app
LANGUAGE: TypeScript
SCALE: 200 concurrent users on planning nights, ~25 req/sec, ~4 GB data
```

## 51. SurfSlate — surf school lesson booking

```text
APP_DESCRIPTION: A lesson-booking web app for surf schools. Students book group or private lessons filtered by tide and swell windows, instructors manage certifications and board inventory, and weather-triggered rescheduling texts go out automatically.
TECH_STACK: Remix + Prisma + PostgreSQL + Stripe + Surfline forecast API + Twilio, on Fly.io
APP_TYPE: web app
LANGUAGE: TypeScript
SCALE: 150 concurrent users in season, ~20 req/sec, ~3 GB data
```

## 52. TrimTally — landscaping job costing

```text
APP_DESCRIPTION: A job-costing web app for landscaping companies. Estimators quote from a priced task catalog, crews clock time and materials against jobs from their phones, and owners compare quoted versus actual margin per property.
TECH_STACK: Next.js + tRPC + Prisma + PostgreSQL + offline-tolerant PWA time clock, on Vercel
APP_TYPE: web app
LANGUAGE: TypeScript
SCALE: 180 concurrent users, ~28 req/sec, ~7 GB data
```

## 53. ColdChainly — refrigerated freight telemetry API

```text
APP_DESCRIPTION: An API service for cold-chain logistics providers. Reefer trailer sensors post temperature and door-open events, the service evaluates excursion rules per commodity, and shippers pull compliance reports and real-time alerts via webhooks.
TECH_STACK: Fastify + TimescaleDB + Redis Streams + webhook fan-out workers, deployed on AWS ECS
APP_TYPE: API service
LANGUAGE: TypeScript
SCALE: ~2,500 req/sec sensor ingest, 15,000 active trailers, ~1.2 TB time-series data
```

## 54. FleetFathom — last-mile route optimization API

```text
APP_DESCRIPTION: A route-optimization API for last-mile delivery companies. Dispatch systems submit stop lists with time windows and vehicle capacities, the service returns optimized multi-vehicle routes, and re-optimization endpoints handle mid-day order injections.
TECH_STACK: NestJS + PostgreSQL + PostGIS + Redis + OR-Tools solver workers, deployed on GCP Cloud Run
APP_TYPE: API service
LANGUAGE: TypeScript
SCALE: ~300 req/sec, 40,000 routes optimized/day, ~90 GB data
```

## 55. ReconRobin — bank reconciliation API

```text
APP_DESCRIPTION: A reconciliation API for accounting platforms and bookkeeping firms. Clients push bank feed transactions and ledger entries, the service matches them with configurable fuzzy rules, and unmatched exceptions stream back for human review queues.
TECH_STACK: Fastify + PostgreSQL + Redis + Plaid integration + BullMQ matching workers, on AWS ECS
APP_TYPE: API service
LANGUAGE: TypeScript
SCALE: ~450 req/sec, 8 million transactions matched/day, ~600 GB data
```

## 56. TriagePager — clinical on-call paging API

```text
APP_DESCRIPTION: An on-call paging API for hospital systems replacing legacy pagers. Integrations post pages with acuity levels, the service resolves current on-call schedules per specialty, escalates unacknowledged pages, and logs delivery for compliance audits.
TECH_STACK: NestJS + PostgreSQL + Redis + Twilio/APNs/FCM delivery + escalation state machines, on Azure AKS
APP_TYPE: API service
LANGUAGE: TypeScript
SCALE: ~150 req/sec, 90,000 pages/day, 99.99% delivery SLO, ~40 GB data
```

## 57. PalletParrot — warehouse slotting API

```text
APP_DESCRIPTION: A slotting-optimization API for 3PL warehouses. WMS systems send SKU velocity and dimension data, the service recommends bin assignments that minimize picker travel, and what-if endpoints simulate re-slotting before a physical move.
TECH_STACK: Hono on Bun + PostgreSQL + Redis + heuristic solver workers, deployed on Fly.io
APP_TYPE: API service
LANGUAGE: TypeScript
SCALE: ~120 req/sec, 200 warehouses, ~150 GB data
```

## 58. ClauseCraft — contract clause library API

```text
APP_DESCRIPTION: A clause-library API for legal tech products. Firms store approved contract clauses with jurisdiction tags and fallback positions, drafting tools query alternates by risk posture, and version history tracks negotiated deviations.
TECH_STACK: NestJS + PostgreSQL + OpenSearch full-text + Redis cache, deployed on AWS ECS
APP_TYPE: API service
LANGUAGE: TypeScript
SCALE: ~200 req/sec, 1.5 million clauses stored, ~80 GB data
```

## 59. DocketDove — court docket alert API

```text
APP_DESCRIPTION: A docket-monitoring API for litigation teams. Subscribers register case numbers across state and federal courts, the service polls docket feeds and PACER, diffs new filings, and pushes structured alerts to email, Slack, and webhooks.
TECH_STACK: Fastify + PostgreSQL + BullMQ pollers + S3 filing cache + webhook delivery, on Render
APP_TYPE: API service
LANGUAGE: TypeScript
SCALE: ~80 req/sec, 250,000 watched dockets, ~200 GB data
```

## 60. CurbCue — curbside pickup orchestration API

```text
APP_DESCRIPTION: A curbside-pickup API for big-box retail chains. Order systems register pickups, the customer's phone reports arrival by geofence, and the service sequences staging, assigns parking bays, and measures wait-time SLAs per store.
TECH_STACK: NestJS + PostgreSQL + Redis geofence state + push notification fan-out, on GCP Cloud Run
APP_TYPE: API service
LANGUAGE: TypeScript
SCALE: ~600 req/sec, 1,800 stores, 350,000 pickups/day, ~100 GB data
```

## 61. AirCheck — radio ad airplay verification API

```text
APP_DESCRIPTION: An airplay-verification API for radio advertisers and agencies. The service fingerprints station streams, matches aired spots against booked schedules, and exposes discrepancy reports so agencies can claim make-goods for missed spots.
TECH_STACK: Fastify + PostgreSQL + audio fingerprint workers + S3 stream captures + Redis, on AWS ECS
APP_TYPE: API service
LANGUAGE: TypeScript
SCALE: ~90 req/sec, 1,200 monitored stations, ~2 TB audio capture data
```

## 62. GeoGrouse — geofencing rules API

```text
APP_DESCRIPTION: A geofencing API for field-service and delivery apps. Clients define polygon fences with dwell rules, devices stream location pings, and the service emits enter/exit/dwell events with debouncing to webhooks and message queues.
TECH_STACK: Hono + PostgreSQL + PostGIS + Redis + Kafka event output, deployed on AWS EKS
APP_TYPE: API service
LANGUAGE: TypeScript
SCALE: ~4,000 location pings/sec, 500,000 active fences, ~300 GB data
```

## 63. WattWicket — interval billing API for utilities

```text
APP_DESCRIPTION: A billing-calculation API for community choice aggregators and small utilities. It rates 15-minute interval meter data against time-of-use tariffs, applies net-metering credits for solar customers, and produces bill-ready line items.
TECH_STACK: NestJS + TimescaleDB + Redis + tariff rules engine + batch rating workers, on Azure AKS
APP_TYPE: API service
LANGUAGE: TypeScript
SCALE: ~250 req/sec, 900,000 meters rated monthly, ~2 TB interval data
```

## 64. SignetSeal — embedded e-signature API

```text
APP_DESCRIPTION: An embeddable e-signature API for SaaS products. Developers create envelopes from templates with merge fields, end users sign in a hosted or iframe flow, and the service maintains tamper-evident audit trails and completion webhooks.
TECH_STACK: Fastify + PostgreSQL + S3 document storage + KMS signing + webhook workers, on AWS ECS
APP_TYPE: API service
LANGUAGE: TypeScript
SCALE: ~350 req/sec, 120,000 envelopes/day, ~5 TB document data
```

## 65. MenuMoss — allergen and nutrition data API

```text
APP_DESCRIPTION: A menu-data API for restaurant groups and delivery platforms. It stores recipes with ingredient-level allergen and nutrition breakdowns, recalculates labels when suppliers substitute ingredients, and serves compliant menu data per region's labeling laws.
TECH_STACK: NestJS + PostgreSQL + Redis cache + nutrient calculation workers, deployed on GCP Cloud Run
APP_TYPE: API service
LANGUAGE: TypeScript
SCALE: ~500 req/sec, 2 million recipe records, ~120 GB data
```

## 66. CensusCrane — demographic data API

```text
APP_DESCRIPTION: A demographics API for site-selection and market-research tools. It normalizes census and ACS datasets into a consistent schema, answers radius and drive-time queries with population, income, and household stats, and versions data by release year.
TECH_STACK: Fastify + PostgreSQL + PostGIS + Redis + tile-based caching, deployed on Fly.io
APP_TYPE: API service
LANGUAGE: TypeScript
SCALE: ~700 req/sec, ~900 GB reference data
```

## 67. PayoutPuffin — marketplace payout orchestration API

```text
APP_DESCRIPTION: A payout-orchestration API for gig and creator marketplaces. Platforms submit earnings events, the service handles split calculations, tax-form thresholds, and multi-rail disbursement (ACH, instant debit, PayPal), with retry and reconciliation built in.
TECH_STACK: NestJS + PostgreSQL + Redis + Stripe Treasury/ACH rails + idempotent job workers, on AWS EKS
APP_TYPE: API service
LANGUAGE: TypeScript
SCALE: ~400 req/sec, $18M disbursed/month across 250,000 payees, ~200 GB data
```

## 68. TransitTrellis — transit realtime API

```text
APP_DESCRIPTION: A transit-data API for city trip-planner apps. It ingests GTFS and GTFS-RT feeds from regional agencies, reconciles schedule versus realtime positions, and serves arrival predictions and service alerts per stop with sub-second latency.
TECH_STACK: Hono on Bun + PostgreSQL + Redis + GTFS-RT protobuf ingestion workers, on GCP Cloud Run
APP_TYPE: API service
LANGUAGE: TypeScript
SCALE: ~3,000 req/sec at commute peak, 45 agency feeds, ~250 GB data
```

## 69. VetVersa — mobile veterinary dispatch API

```text
APP_DESCRIPTION: A dispatch API for mobile veterinary services. Booking frontends request house-call slots, the service assigns vets by species competency, travel radius, and controlled-substance licensing, and syncs visit records to practice management systems.
TECH_STACK: NestJS + PostgreSQL + PostGIS + Redis + calendar sync workers, deployed on Render
APP_TYPE: API service
LANGUAGE: TypeScript
SCALE: ~100 req/sec, 3,500 daily visits scheduled, ~30 GB data
```

## 70. RefRelay — sports officiating assignment API

```text
APP_DESCRIPTION: An official-assignment API for youth and amateur sports associations. Leagues post game schedules, the service assigns referees by certification level, availability, and travel distance, and handles turn-backs with automatic re-assignment.
TECH_STACK: Fastify + PostgreSQL + Redis + constraint-based assignment workers, deployed on Railway
APP_TYPE: API service
LANGUAGE: TypeScript
SCALE: ~60 req/sec, 25,000 games assigned/season, ~12 GB data
```

## 71. PixelPorter — image transformation API

```text
APP_DESCRIPTION: An on-the-fly image transformation API for e-commerce and media sites. Clients request resizes, crops, format negotiation (AVIF/WebP), and watermarks via URL parameters, with origin fetch, edge caching, and per-tenant usage metering.
TECH_STACK: Hono on Cloudflare Workers + R2 storage + sharp-based transform tier + usage analytics in ClickHouse
APP_TYPE: API service
LANGUAGE: TypeScript
SCALE: ~9,000 req/sec at edge, 85% cache hit ratio, ~40 TB stored originals
```

## 72. StencilStork — document generation API

```text
APP_DESCRIPTION: A document-generation API for SaaS back offices. Developers upload DOCX/HTML templates with merge tags, post JSON payloads to render PDFs (statements, certificates, contracts), and receive signed URLs with configurable retention.
TECH_STACK: Fastify + Puppeteer/LibreOffice render pool + S3 + Redis queue, deployed on AWS ECS
APP_TYPE: API service
LANGUAGE: TypeScript
SCALE: ~250 req/sec, 1.4 million documents/day, ~8 TB rendered output
```

## 73. OathOtter — remote notary session API

```text
APP_DESCRIPTION: A remote online notarization API for title and lending platforms. It schedules notary sessions, runs KBA identity checks and credential analysis, records audiovisual sessions for statutory retention, and applies digital notary seals.
TECH_STACK: NestJS + PostgreSQL + LiveKit recording + KBA vendor integrations + S3 WORM storage, on AWS
APP_TYPE: API service
LANGUAGE: TypeScript
SCALE: ~70 req/sec, 6,000 notarization sessions/day, ~60 TB video retention
```

## 74. RoyaltyRook — music royalty split API

```text
APP_DESCRIPTION: A royalty-splitting API for indie labels and distributors. Rights holders register works with contributor split sheets, the service allocates streaming revenue imports across splits, and collaborators get statements and payout instructions.
TECH_STACK: Fastify + PostgreSQL + Redis + DSP report ingestion workers + Decimal-safe money math, on Fly.io
APP_TYPE: API service
LANGUAGE: TypeScript
SCALE: ~90 req/sec, 4 million royalty lines processed/month, ~180 GB data
```

## 75. VineTally — vineyard harvest tracking

```text
APP_DESCRIPTION: A harvest-tracking mobile app for vineyard managers. Crews log picked bins by block and clone with offline support, brix and pH samples get recorded at the sorting table, and winemakers watch tonnage arrive against tank capacity in real time.
TECH_STACK: React Native (Expo) + WatermelonDB offline-first + Supabase sync + barcode bin tags
APP_TYPE: mobile
LANGUAGE: TypeScript
SCALE: 800 MAU, 200 concurrent users during crush, ~6 GB data
```

## 76. HiveMetric — beekeeping inspection log

```text
APP_DESCRIPTION: A hive-inspection mobile app for sideliner beekeepers. Keepers log queen status, brood patterns, and mite counts per hive with photo notes, get treatment reminders based on thresholds, and compare yard performance across seasons.
TECH_STACK: React Native (Expo) + SQLite offline-first + Supabase cloud sync + push notifications
APP_TYPE: mobile
LANGUAGE: TypeScript
SCALE: 12,000 MAU, 600 concurrent sessions, ~15 GB data
```

## 77. StrideSync — running club training plans

```text
APP_DESCRIPTION: A training-plan mobile app for running clubs and their coaches. Coaches assign weekly workouts to pace groups, runners sync completed runs from Garmin and Strava, and group-run RSVPs coordinate meetup points and pace pods.
TECH_STACK: React Native (Expo) + NestJS backend + PostgreSQL + Strava/Garmin OAuth APIs
APP_TYPE: mobile
LANGUAGE: TypeScript
SCALE: 25,000 MAU, 1,500 concurrent sessions on Saturday mornings, ~35 GB data
```

## 78. DoseDock — pharmacy refill companion

```text
APP_DESCRIPTION: A refill-management mobile app for independent pharmacy patients. Patients scan bottle barcodes to request refills, get ready-for-pickup notifications, manage family members' medications, and set dose reminders with adherence streaks.
TECH_STACK: React Native (Expo) + Fastify backend + PostgreSQL + pharmacy system (Rx30) integration + FCM/APNs
APP_TYPE: mobile
LANGUAGE: TypeScript
SCALE: 40,000 MAU, 2,000 concurrent sessions, ~25 GB data
```

## 79. CivicSnag — municipal issue reporting

```text
APP_DESCRIPTION: A 311-style mobile app for city residents to report potholes, broken streetlights, and graffiti. Reports carry geotagged photos, route to the right public-works queue automatically, and reporters get status updates through resolution.
TECH_STACK: React Native (Expo) + NestJS backend + PostgreSQL + PostGIS + S3 photos + push notifications
APP_TYPE: mobile
LANGUAGE: TypeScript
SCALE: 60,000 MAU, 1,200 reports/day, ~120 GB photo data
```

## 80. ScoreScout — youth soccer scouting notes

```text
APP_DESCRIPTION: A scouting mobile app for youth soccer club evaluators. Scouts rate players on standardized rubrics during tryouts and matches, tag video timestamp moments, and directors of coaching build ranked lists for team placement decisions.
TECH_STACK: React Native (Expo) + tRPC backend + PostgreSQL + offline queue + S3 video clips
APP_TYPE: mobile
LANGUAGE: TypeScript
SCALE: 3,000 MAU, 400 concurrent users during tryout weekends, ~200 GB video data
```

## 81. PunchPine — construction punch lists

```text
APP_DESCRIPTION: A punch-list mobile app for general contractors closing out projects. Superintendents pin defects on floor plans with photos, assign items to subcontractors with due dates, and owners sign off completed items from the same app.
TECH_STACK: React Native (Expo) + WatermelonDB offline-first + NestJS sync backend + PostgreSQL + S3
APP_TYPE: mobile
LANGUAGE: TypeScript
SCALE: 8,000 MAU, 900 concurrent field users, ~350 GB data (photos and plans)
```

## 82. FieldFinch — citizen-science bird surveys

```text
APP_DESCRIPTION: A survey mobile app for citizen-science bird counts. Volunteers run timed point counts with species checklists and audio notes, GPS tracks validate survey routes, and regional coordinators export datasets to research repositories.
TECH_STACK: React Native (Expo) + SQLite offline-first + Fastify sync API + PostgreSQL + S3 audio
APP_TYPE: mobile
LANGUAGE: TypeScript
SCALE: 18,000 MAU, 2,500 surveys submitted/week, ~90 GB data
```

## 83. ReelStack — video review desktop app

```text
APP_DESCRIPTION: A desktop app for freelance video editors managing client review rounds. Editors organize cuts by project version, collect frame-accurate client comments imported from review links, and track which notes are addressed before export.
TECH_STACK: Electron + React + SQLite (better-sqlite3) + ffmpeg thumbnailing + local proxy media
APP_TYPE: desktop
LANGUAGE: TypeScript
SCALE: single user, ~500 GB local media library indexed, <5 GB app data
```

## 84. MintMark — coin collection cataloger

```text
APP_DESCRIPTION: A desktop app for numismatists cataloging coin collections. Collectors record coins with mint marks, grades, and provenance, attach macro photos, track market values against price-guide imports, and print insurance inventories.
TECH_STACK: Tauri + React + SQLite + local image storage + CSV price-guide import
APP_TYPE: desktop
LANGUAGE: TypeScript
SCALE: single user, collections up to 50,000 coins, <20 GB local data
```

## 85. SetlistSage — band setlist planner

```text
APP_DESCRIPTION: A desktop app for gigging bands planning setlists. Bandleaders arrange songs by key, tempo, and energy arc, attach charts and lyrics per song, time out sets against venue slots, and export stage-ready setlist PDFs.
TECH_STACK: Electron + React + SQLite (better-sqlite3) + PDF export + optional Dropbox chart sync
APP_TYPE: desktop
LANGUAGE: TypeScript
SCALE: single user, band library up to 2,000 songs, <3 GB local data
```

## 86. KnitKiln — knitting pattern designer

```text
APP_DESCRIPTION: A desktop app for knitwear designers creating graded patterns. Designers chart colorwork and cable motifs on stitch grids, define sizing formulas that regrade automatically, and export tech-edited PDFs for pattern marketplaces.
TECH_STACK: Tauri + SvelteKit frontend + SQLite + SVG chart rendering + PDF export
APP_TYPE: desktop
LANGUAGE: TypeScript
SCALE: single user, ~800 patterns per library, <2 GB local data
```

## 87. ArchiveAlder — genealogy research desktop

```text
APP_DESCRIPTION: A desktop app for genealogists managing research across archives. Researchers link source citations to people and events, track repository visit to-do lists, resolve conflicting evidence with proof arguments, and export GEDCOM files.
TECH_STACK: Electron + React + SQLite (better-sqlite3) + GEDCOM import/export + local document scans
APP_TYPE: desktop
LANGUAGE: TypeScript
SCALE: single user, trees up to 100,000 individuals, <40 GB local scans
```

## 88. BenchBeacon — electronics repair shop tickets

```text
APP_DESCRIPTION: A desktop app for electronics repair shops running bench operations. Techs intake devices with condition photos, track diagnosis and parts-wait states per ticket, print claim labels, and text customers quotes and pickup notices.
TECH_STACK: Tauri + React + SQLite + label printer integration + Twilio SMS via local service
APP_TYPE: desktop
LANGUAGE: TypeScript
SCALE: 5 concurrent workstations per shop, ~30,000 tickets/year, <10 GB local data
```

## 89. schemasift — database schema diff CLI

```text
APP_DESCRIPTION: A CLI tool for backend teams that diffs database schemas across environments. It introspects two PostgreSQL or MySQL targets, produces ordered migration SQL with destructive-change warnings, and gates CI when staging drifts from committed migrations.
TECH_STACK: Node.js CLI (commander) + pg/mysql2 introspection + SQL AST diffing, distributed via npm
APP_TYPE: CLI
LANGUAGE: TypeScript
SCALE: single user per invocation, CI usage ~500 runs/day, schemas up to 2,000 tables
```

## 90. loglens — structured log query CLI

```text
APP_DESCRIPTION: A CLI tool for developers querying structured JSON logs locally. It tails files or kubectl streams, filters with a jq-like expression language, reconstructs request traces by correlation ID, and renders latency histograms in the terminal.
TECH_STACK: Node.js CLI (clipanion) + stream processing + WASM-compiled query engine, distributed via npm and Homebrew
APP_TYPE: CLI
LANGUAGE: TypeScript
SCALE: single user per invocation, processes up to 5 GB log files, ~50,000 lines/sec throughput
```

## 91. mockmoth — contract-first API mocking CLI

```text
APP_DESCRIPTION: A CLI tool for frontend teams that spins up mock API servers from OpenAPI specs. It generates realistic seeded fake data per schema, simulates latency and error-rate scenarios, and records real traffic to snapshot new mock fixtures.
TECH_STACK: Node.js CLI (commander) + Fastify mock server + OpenAPI parser + faker-based generators, via npm
APP_TYPE: CLI
LANGUAGE: TypeScript
SCALE: single user per invocation, mocks specs up to 800 endpoints, ~1,000 req/sec local throughput
```

## 92. a11yowl — accessibility audit CLI

```text
APP_DESCRIPTION: A CLI tool that audits web builds for accessibility regressions in CI. It crawls a built site or Storybook with headless Chromium, runs axe-core rules plus custom keyboard-trap checks, and fails builds on new violations against a committed baseline.
TECH_STACK: Node.js CLI (commander) + Playwright + axe-core + JUnit/SARIF reporters, distributed via npm
APP_TYPE: CLI
LANGUAGE: TypeScript
SCALE: CI usage ~800 runs/day across teams, crawls up to 3,000 pages per run
```

## 93. scrubjay — PII redaction CLI

```text
APP_DESCRIPTION: A CLI tool for data engineers redacting PII from datasets before sharing. It scans CSV, JSONL, and Parquet files with pattern and dictionary detectors for names, emails, and national IDs, then masks, hashes, or tokenizes fields per a redaction policy file.
TECH_STACK: Node.js CLI (clipanion) + streaming parsers + Apache Arrow for Parquet + policy YAML, via npm
APP_TYPE: CLI
LANGUAGE: TypeScript
SCALE: single user per invocation, files up to 50 GB streamed, ~30 MB/sec throughput
```

## 94. licenselark — OSS license audit CLI

```text
APP_DESCRIPTION: A CLI tool for engineering compliance teams auditing dependency licenses. It resolves full npm/pnpm/yarn dependency trees, classifies licenses against an allow/deny policy, flags copyleft obligations in shipped bundles, and emits SPDX SBOM files.
TECH_STACK: Node.js CLI (commander) + lockfile parsers + SPDX generator + policy engine, distributed via npm
APP_TYPE: CLI
LANGUAGE: TypeScript
SCALE: CI usage ~1,200 runs/day, audits dependency trees up to 15,000 packages
```

## 95. patchpigeon — game server patch orchestration CLI

```text
APP_DESCRIPTION: A CLI tool for indie multiplayer studios orchestrating game server patches. It drains player sessions region by region, rolls out new server builds with health-gated canaries, and rolls back automatically when match-error rates spike.
TECH_STACK: Node.js CLI (oclif) + Agones/Kubernetes API + Prometheus health queries + Slack notifications, via npm
APP_TYPE: CLI
LANGUAGE: TypeScript
SCALE: operator usage ~40 rollouts/week, fleets up to 3,000 game server pods
```

## 96. GridPulse — smart meter ingestion pipeline

```text
APP_DESCRIPTION: A data pipeline for electric utilities ingesting smart-meter reads. It validates and gap-fills AMI interval data from head-end systems, detects outage and tamper signatures, and publishes cleansed reads to billing and load-forecasting consumers.
TECH_STACK: Node.js workers + Kafka + TimescaleDB + Redis dedupe + S3 raw archive, deployed on AWS EKS
APP_TYPE: data pipeline
LANGUAGE: TypeScript
SCALE: 1.1 million meters, ~110 million interval reads/day, ~8 TB warm data
```

## 97. FraudFerret — transaction anomaly pipeline

```text
APP_DESCRIPTION: A data pipeline for a payments processor screening card transactions. It enriches authorization streams with merchant and device history, scores anomalies against velocity rules and an ML model, and routes suspects to analyst case queues within seconds.
TECH_STACK: Node.js stream processors + Kafka + Redis feature store + PostgreSQL case DB + ONNX model serving, on GCP
APP_TYPE: data pipeline
LANGUAGE: TypeScript
SCALE: ~5,000 transactions/sec sustained, 12,000 tps peak, ~15 TB event data
```

## 98. QuayData — port container event pipeline

```text
APP_DESCRIPTION: A data pipeline for a container port authority unifying terminal events. It ingests crane moves, gate transactions, and vessel EDI messages, reconciles container lifecycles across systems, and feeds dwell-time dashboards and demurrage billing.
TECH_STACK: Node.js workers + RabbitMQ + PostgreSQL + EDIFACT parsers + ClickHouse analytics store, on Azure AKS
APP_TYPE: data pipeline
LANGUAGE: TypeScript
SCALE: ~900,000 events/day, 2.4 million container moves/year, ~3 TB data
```

## 99. StarSieve — telescope survey pipeline

```text
APP_DESCRIPTION: A data pipeline for a university observatory's nightly sky survey. It calibrates raw CCD frames, runs source extraction and cross-matches detections against star catalogs, and flags transient candidates for astronomer review each morning.
TECH_STACK: Node.js orchestration + BullMQ + PostgreSQL + Python worker containers (astropy) + S3 FITS storage
APP_TYPE: data pipeline
LANGUAGE: TypeScript
SCALE: ~600 GB raw frames/night, 40 million detections/night cross-matched, ~200 TB archive
```

## 100. SpliceSprout — genomics variant pipeline

```text
APP_DESCRIPTION: A data pipeline for an agricultural genomics lab processing crop sequencing runs. It orchestrates alignment and variant calling for breeding programs, annotates variants against trait-marker panels, and delivers selection reports to plant breeders.
TECH_STACK: Node.js workflow orchestrator + AWS Batch (BWA/GATK containers) + PostgreSQL + S3 + Step Functions
APP_TYPE: data pipeline
LANGUAGE: TypeScript
SCALE: ~120 sequencing runs/month, 4 TB reads processed/month, ~90 TB archived data
```
