# PHP Blueprint Types — Copy-Paste Input Sets

Copy a fenced block into the prompt as-is, or swap individual fields.

## 1. RepZone — gym membership portal

```text
APP_DESCRIPTION: A membership portal web app for independent gyms. Members sign up for plans with recurring billing, book classes and personal-training sessions, and check in via QR; owners manage class schedules, freeze/cancel requests, and monthly revenue reports.
TECH_STACK: Laravel + Livewire + MySQL + Stripe Billing + Redis queues, deployed on Laravel Forge/DigitalOcean
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 250 concurrent users, ~30 req/sec, ~10 GB data
```

## 2. CraftBazaar — artisan marketplace

```text
APP_DESCRIPTION: A multi-vendor marketplace web app for handmade crafts. Artisans open shops with product listings and made-to-order options, buyers purchase across shops with a single cart, the platform splits payments with vendor payouts, and reviews and messaging build buyer-seller trust.
TECH_STACK: Laravel + Inertia.js (Vue) + MySQL + Stripe Connect + Meilisearch, deployed on AWS
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 1,200 concurrent users, ~150 req/sec, ~60 GB data
```

## 3. LeaseLine — landlord tenant portal

```text
APP_DESCRIPTION: A tenant-portal web app for small residential landlords. Tenants pay rent online, submit maintenance requests with photos, and receive notices; landlords track leases and renewals, log expenses per property, and export tax-ready income reports.
TECH_STACK: Symfony + Twig + PostgreSQL + Stripe ACH + Symfony Messenger queues, deployed on Platform.sh
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 150 concurrent users, ~20 req/sec, ~8 GB data
```

## 4. GateList — event ticketing API

```text
APP_DESCRIPTION: A ticketing API service for independent event promoters. Promoter storefronts create events with tiered ticket types and promo codes, the service handles inventory holds during checkout, issues QR-coded tickets, and validates scans at the door with offline-capable gate devices.
TECH_STACK: Laravel (API-only) + MySQL + Redis inventory locks + Stripe + signed QR validation, deployed on AWS
APP_TYPE: API service
LANGUAGE: PHP
SCALE: ~500 req/sec on-sale peak, 800 events/year, ~12 GB data
```

## 5. WP Plugin — StallFinder farmers-market directory

```text
APP_DESCRIPTION: A WordPress plugin that adds a farmers-market vendor directory with stall booking to a market's WordPress site. Market managers define market dates and stall maps, vendors apply and book stalls with seasonal pricing, and visitors browse vendor profiles by product category.
TECH_STACK: WordPress plugin (PHP) + custom post types + custom REST endpoints + Gutenberg blocks (vendor directory, stall map) + MySQL custom tables for bookings + Stripe
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 100 concurrent users on booking-open day, ~10 req/sec, ~1 GB data
```

## 6. WP Plugin — CourseCurtain membership drip

```text
APP_DESCRIPTION: A WordPress plugin that paywalls course content with drip scheduling for creators who sell courses from their own WordPress site. Creators mark lessons as free/member-only, define drip schedules per cohort, sell memberships with recurring billing, and track lesson completion per student.
TECH_STACK: WordPress plugin (PHP) + custom post types + Stripe subscriptions + MySQL progress tables + Gutenberg blocks for content gating (with shortcode fallback)
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 400 concurrent students, ~25 req/sec, ~5 GB data
```

## 7. WP Plugin — TableTonight restaurant reservations

```text
APP_DESCRIPTION: A WordPress plugin that adds table reservations to restaurant websites. Diners book by party size and time with live availability from a visual table map, the kitchen caps covers per service, hosts manage the floor from a same-day dashboard, and no-show protection takes card holds via Stripe.
TECH_STACK: WordPress plugin (PHP) + Gutenberg booking-widget block (REST-backed) + MySQL custom tables + Stripe + email/SMS confirmations
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 150 concurrent users Friday peak, ~15 req/sec, ~2 GB data
```

## 8. WP Plugin — DoorKey real-estate listings

```text
APP_DESCRIPTION: A WordPress plugin that turns an agency's WordPress site into a property-listings portal. Agents publish listings with photo galleries, price, and features; visitors filter by neighborhood, price band, bedrooms, and property type with map view; leads route to the listing agent with inquiry tracking.
TECH_STACK: WordPress plugin (PHP) + custom post types/taxonomies + Leaflet maps + MySQL meta indexes + Gutenberg blocks
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 300 concurrent visitors, ~35 req/sec, ~20 GB (photos in media library)
```

## 9. WP Plugin — TicketStub event calendar

```text
APP_DESCRIPTION: A WordPress plugin that adds an event calendar with paid ticket sales for community venues running WordPress. Staff publish events on month/list calendar views, sell tiered tickets with capacity limits through Stripe checkout, email QR tickets, and check attendees in from a mobile browser scanner page.
TECH_STACK: WordPress plugin (PHP) + custom post types + Gutenberg blocks (calendar, event list, ticket purchase) + Stripe Checkout + MySQL attendee tables + QR generation/scanning
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 200 concurrent users on-sale peak, ~20 req/sec, ~3 GB data
```

## 10. WP Theme — Aperture photography portfolio

```text
APP_DESCRIPTION: A WordPress theme for professional photographers, built around portfolio presentation and client proofing. It ships full-bleed gallery layouts with lazy-loaded images, password-protected client proofing galleries with favoriting, an about/booking page pattern, and print-shop-ready image protection options.
TECH_STACK: WordPress block theme (PHP + theme.json) + Gutenberg block patterns + custom gallery block + responsive image srcsets
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 200 concurrent visitors, ~25 req/sec, ~40 GB media
```

## 11. WP Theme — Broadsheet local news

```text
APP_DESCRIPTION: A WordPress theme for local newspapers and magazines. It provides front-page editorial layouts with story hierarchy (lead, features, briefs), section landing pages, breaking-news banners, reporter bylines and archives, and ad-slot regions — all editable by non-technical editors via the block editor.
TECH_STACK: WordPress block theme (PHP + theme.json) + block patterns for editorial layouts + category-driven templates + AMP-friendly markup
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 2,000 concurrent readers on breaking news, ~200 req/sec (page-cached), ~15 GB media
```

## 12. WP Theme — OpenHand charity

```text
APP_DESCRIPTION: A WordPress theme for charities and nonprofits centered on donations and volunteering. It includes campaign pages with progress bars, a donation block that integrates with common giving plugins, volunteer sign-up sections, impact-report layouts, and accessibility-first components meeting WCAG 2.2 AA.
TECH_STACK: WordPress block theme (PHP + theme.json) + Gutenberg block patterns + donation-plugin integration hooks + WCAG-audited components
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 500 concurrent visitors during appeal campaigns, ~50 req/sec, ~5 GB media
```

## 13. TriageDesk — clinic patient intake

```text
APP_DESCRIPTION: A patient-intake web app for multi-provider outpatient clinics. Patients complete pre-visit questionnaires, upload insurance cards, and e-sign consent forms from a tablet or phone; front-desk staff see a live intake queue, flag incomplete charts, and push structured intake data to the clinic's EHR.
TECH_STACK: Laravel + Livewire + PostgreSQL + Redis queues + HL7/FHIR export via API integration, deployed on AWS with HIPAA-aligned hosting
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 300 concurrent patients at morning peak, ~35 req/sec, ~25 GB data
```

## 14. HaulBoard — freight dispatch API

```text
APP_DESCRIPTION: A dispatch API service for regional LTL freight brokers. It matches load tenders to carrier capacity, tracks shipment milestones from pickup to proof-of-delivery, calculates accessorial charges, and pushes status webhooks to shipper TMS systems.
TECH_STACK: Symfony + API Platform + PostgreSQL + RabbitMQ (Symfony Messenger) + JWT auth, deployed on AWS ECS
APP_TYPE: API service
LANGUAGE: PHP
SCALE: ~220 req/sec, 4,000 active loads/day, ~90 GB data
```

## 15. Attendly — school attendance tracker

```text
APP_DESCRIPTION: An attendance-tracking web app for K-12 school districts. Teachers take period-by-period attendance from a seating-chart view, the office auto-notifies guardians of unexplained absences by SMS and email, and administrators run truancy-threshold and chronic-absenteeism reports for state filings.
TECH_STACK: Laravel + Blade + Alpine.js + MySQL + Twilio SMS + Redis queues, deployed on district-managed VPS
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 1,800 concurrent teachers at first bell, ~120 req/sec, ~40 GB data
```

## 16. CropNote — agronomy field scouting API

```text
APP_DESCRIPTION: An API service backing field-scouting apps for agronomy consultancies. Scouts submit geotagged observations of pest pressure, disease, and crop staging; the service stores field boundaries, generates spray-recommendation reports per grower, and syncs offline-collected notes when scouts regain signal.
TECH_STACK: Laravel (API-only) + PostgreSQL/PostGIS + S3 photo storage + Laravel Sanctum + Redis, deployed on DigitalOcean
APP_TYPE: API service
LANGUAGE: PHP
SCALE: ~80 req/sec seasonal peak, 60,000 observations/season, ~35 GB data
```

## 17. MatterMill — law firm matter management

```text
APP_DESCRIPTION: A matter-management web app for small litigation firms. Attorneys open matters with conflict checks, track deadlines against court rules with automatic date chaining, log billable time from a running timer, and generate engagement letters and pre-bill drafts for partner review.
TECH_STACK: Symfony + Twig + Stimulus + PostgreSQL + Symfony Messenger + Gotenberg PDF generation, deployed on Platform.sh
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 200 concurrent users, ~25 req/sec, ~30 GB data
```

## 18. FactorFlow — invoice factoring platform

```text
APP_DESCRIPTION: A web app for invoice-factoring finance companies and their small-business clients. Businesses upload invoices for advance funding, the platform verifies debtors and computes advance rates and fees, funds via ACH, and tracks collections with aging dashboards and reserve-release schedules.
TECH_STACK: Laravel + Inertia.js (React) + PostgreSQL + Plaid + ACH via Moov + Redis queues + event-sourced ledger tables, deployed on AWS
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 400 concurrent users, ~45 req/sec, ~50 GB data
```

## 19. TidyTurn — hotel housekeeping operations

```text
APP_DESCRIPTION: A housekeeping-operations web app for mid-size hotels. Room attendants get prioritized room queues on their phones based on checkouts and arrivals, supervisors inspect and release rooms back to the PMS, and engineering receives maintenance tickets raised mid-clean with photos.
TECH_STACK: Laravel + Livewire + MySQL + Redis + PMS integration via webhooks (Opera/Mews), deployed on AWS Lightsail
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 350 concurrent staff across properties, ~40 req/sec, ~12 GB data
```

## 20. ReelVault — newsroom asset manager

```text
APP_DESCRIPTION: A digital-asset-management web app for broadcast newsrooms. Producers ingest video clips, photos, and graphics with rights metadata and embargo dates, editors search by transcript keywords and air date, and the system enforces licensing expiry by pulling assets from search when rights lapse.
TECH_STACK: Symfony + Vue + PostgreSQL + Elasticsearch + S3-compatible object storage + FFmpeg workers via Messenger, deployed on-prem Kubernetes
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 250 concurrent editors, ~30 req/sec, ~4 TB media with 20 GB metadata
```

## 21. PermitPath — municipal permit portal

```text
APP_DESCRIPTION: A permit-application web app for city building departments. Residents and contractors submit building, electrical, and plumbing permit applications with plan uploads, pay fees online, track review status across departments, and schedule inspections; reviewers annotate plans and issue corrections.
TECH_STACK: Laravel + Blade + MySQL + government payment gateway (Forte) + S3 plan storage + Redis queues, deployed on Azure Government
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 500 concurrent users, ~50 req/sec, ~120 GB (plan PDFs)
```

## 22. ShelfSync — retail inventory sync pipeline

```text
APP_DESCRIPTION: A queue-based data pipeline that keeps inventory consistent across a retailer's POS, e-commerce store, and 3PL warehouse. It ingests stock movements from all three sources, resolves conflicts with last-writer and safety-stock rules, and pushes corrected quantities back out within seconds.
TECH_STACK: PHP 8.3 workers + Symfony Messenger + RabbitMQ + PostgreSQL + Redis dedup cache + Shopify/Square/3PL REST connectors, deployed on AWS ECS
APP_TYPE: data pipeline
LANGUAGE: PHP
SCALE: ~900 messages/sec peak, 45,000 SKUs, ~70 GB data
```

## 23. LeaveLedger — HR leave management

```text
APP_DESCRIPTION: A leave-management web app for mid-size companies. Employees request vacation, sick, and parental leave against accrual balances, managers approve with team-calendar conflict warnings, and HR configures accrual policies per country and exports payroll-ready absence data.
TECH_STACK: Laravel + Inertia.js (Vue) + MySQL + Redis + SAML/SCIM SSO + iCal feeds, deployed on Hetzner Cloud
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 600 concurrent employees at year-end, ~40 req/sec, ~15 GB data
```

## 24. ClaimGate — insurance claims intake API

```text
APP_DESCRIPTION: A first-notice-of-loss API service for property and auto insurers. It accepts claim submissions from web forms, mobile apps, and call-center software, validates policy coverage in real time, assigns adjusters by territory and workload, and emits events to downstream fraud-scoring systems.
TECH_STACK: Symfony + API Platform + PostgreSQL + Kafka event emission + policy-system REST integration + OAuth2, deployed on AWS EKS
APP_TYPE: API service
LANGUAGE: PHP
SCALE: ~150 req/sec, spiking to 600 req/sec after storm events, ~200 GB data
```

## 25. WanderCraft — tour operator itinerary builder

```text
APP_DESCRIPTION: A web app for boutique tour operators to build and sell multi-day itineraries. Staff assemble day-by-day plans from a library of hotels, activities, and transfers with per-season pricing; travelers receive branded interactive itineraries, pay deposits and balances, and get document reminders before departure.
TECH_STACK: Laravel + Livewire + MySQL + Stripe + PDF itinerary generation (Browsershot) + Redis queues, deployed on Laravel Vapor
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 180 concurrent users, ~20 req/sec, ~18 GB data
```

## 26. PawChart — veterinary practice records

```text
APP_DESCRIPTION: A practice-management web app for independent veterinary clinics. Vets chart exams with species-specific templates, manage vaccine schedules with automatic owner reminders, dispense from an in-house pharmacy with controlled-substance logs, and invoice with pet-insurance claim summaries.
TECH_STACK: Laravel + Blade + Alpine.js + MySQL + Twilio reminders + Redis queues + label-printer integration, deployed on DigitalOcean
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 120 concurrent staff, ~15 req/sec, ~22 GB data
```

## 27. RefillRelay — pharmacy refill API

```text
APP_DESCRIPTION: An API service that lets independent pharmacies offer online prescription refills. Patients request refills by Rx number, the service verifies against the pharmacy-management system, queues fills by promised pickup time, and sends ready-for-pickup notifications with counseling flags for pharmacists.
TECH_STACK: Slim 4 + PHP-DI + MySQL + Redis job queues + pharmacy-system HL7 interface + Twilio, deployed on Linode
APP_TYPE: API service
LANGUAGE: PHP
SCALE: ~60 req/sec, 9,000 refills/day across 140 pharmacies, ~14 GB data
```

## 28. CrownTrack — dental lab case tracking

```text
APP_DESCRIPTION: A case-tracking web app for dental labs and their dentist clients. Dentists submit crown, bridge, and aligner cases with scan uploads and shade selections, lab technicians move cases through milling and finishing stations with barcode scans, and the lab invoices with remake-rate analytics.
TECH_STACK: Symfony + Twig + Turbo + MySQL + S3 scan storage + barcode scanning + Symfony Messenger, deployed on OVH
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 90 concurrent users, ~12 req/sec, ~150 GB (3D scan files)
```

## 29. RehabReps — physical therapy home program

```text
APP_DESCRIPTION: A web app where physical therapists assign home-exercise programs to patients. Therapists compose programs from a video exercise library with sets, reps, and progressions; patients log completion and pain scores from their phones; therapists monitor adherence dashboards between visits.
TECH_STACK: Laravel + Inertia.js (Vue) + PostgreSQL + Mux video streaming + Redis + web push notifications, deployed on AWS
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 700 concurrent patients evening peak, ~55 req/sec, ~30 GB data
```

## 30. HoursGuard — trucking HOS compliance pipeline

```text
APP_DESCRIPTION: A data pipeline that ingests ELD driving-status events from truck fleets and evaluates hours-of-service compliance. It computes remaining drive windows per driver, detects violations against FMCSA rulesets, alerts dispatchers before breaches, and archives audit-ready logs for roadside inspection requests.
TECH_STACK: PHP 8.3 workers + Laravel Horizon + Redis streams + TimescaleDB + ELD vendor webhook ingestion + SNS alerting, deployed on AWS
APP_TYPE: data pipeline
LANGUAGE: PHP
SCALE: ~1,500 events/sec from 8,000 trucks, ~500 GB rolling data
```

## 31. SlotSmith — warehouse slotting CLI

```text
APP_DESCRIPTION: A CLI tool for warehouse operations analysts that recomputes optimal bin slotting. It ingests order-history and SKU-dimension exports, scores pick-path efficiency, proposes re-slotting moves ranked by labor savings, and emits WMS-ready move task files plus a before/after travel-distance report.
TECH_STACK: PHP 8.3 + symfony/console + league/csv + SQLite working store + Box PHAR distribution
APP_TYPE: CLI
LANGUAGE: PHP
SCALE: 500,000 order lines per run, 80,000 SKUs, ~6 GB working data
```

## 32. CourierLoop — last-mile routing API

```text
APP_DESCRIPTION: An API service for regional courier companies that plans and monitors last-mile delivery routes. It clusters daily stops into driver routes with time-window and vehicle-capacity constraints, re-sequences on live traffic, and exposes recipient-facing tracking links with ETA updates.
TECH_STACK: Laravel Octane (Swoole) + PostgreSQL/PostGIS + OSRM routing engine + Redis + webhook push, deployed on AWS
APP_TYPE: API service
LANGUAGE: PHP
SCALE: ~350 req/sec, 25,000 stops/day, ~60 GB data
```

## 33. QuaySlot — port berth scheduling

```text
APP_DESCRIPTION: A berth-scheduling web app for small and mid-size seaports. Shipping agents request berth windows with vessel dimensions and cargo type, harbor masters allocate berths on a drag-and-drop quay timeline with draft and crane constraints, and pilots and linesmen get automated movement orders.
TECH_STACK: Symfony + Vue + PostgreSQL + Mercure real-time updates + Symfony Messenger + AIS feed ingestion, deployed on-prem
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 80 concurrent users, ~10 req/sec, 5,500 vessel calls/year, ~20 GB data
```

## 34. PupilPulse — student progress reporting

```text
APP_DESCRIPTION: A progress-reporting web app for primary schools. Teachers record termly assessments against curriculum objectives, comment banks speed up report writing with per-pupil personalization, heads moderate drafts before release, and parents read published reports in a secure portal with translation options.
TECH_STACK: Laravel + Livewire + MySQL + Redis + DeepL translation API + PDF report generation, deployed on UK-based VPS
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 900 concurrent parents on report day, ~70 req/sec, ~10 GB data
```

## 35. GrantTrellis — research grant tracking

```text
APP_DESCRIPTION: A web app for university research offices to manage the grant lifecycle. Investigators register proposals with budgets and compliance checklists, the office tracks submission deadlines and sponsor communications, and post-award staff monitor spend-down, effort certification, and report due dates.
TECH_STACK: Symfony + Twig + Stimulus + PostgreSQL + LDAP/Shibboleth SSO + Symfony Messenger + scheduled digest emails, deployed on university VMware
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 300 concurrent users at deadline periods, ~25 req/sec, ~45 GB data
```

## 36. ScholarSift — scholarship application review

```text
APP_DESCRIPTION: A web app for foundations that award scholarships. Applicants submit essays, transcripts, and recommender letters through staged forms; review committees score blinded applications against rubrics with conflict-of-interest recusal; administrators run award rounds and generate offer letters.
TECH_STACK: Laravel + Inertia.js (React) + MySQL + S3 document storage + Redis queues + rubric scoring engine, deployed on AWS
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 2,500 concurrent applicants at deadline, ~180 req/sec, ~80 GB documents
```

## 37. VineHaul — vineyard harvest logistics

```text
APP_DESCRIPTION: A harvest-logistics web app for wine regions. Vineyard managers schedule picking crews and grape deliveries against winery crush-pad capacity, weighbridge operators record bin weights and Brix at intake, and wineries see live tonnage dashboards per block, variety, and contract.
TECH_STACK: Laravel + Livewire + MySQL + Redis + weighbridge serial-bridge integration + SMS crew notifications, deployed on AWS Sydney
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 150 concurrent users during vintage, ~18 req/sec, ~8 GB data
```

## 38. HerdHalo — livestock health records API

```text
APP_DESCRIPTION: An API service for cattle and sheep producers that centralizes herd health records. It ingests EID tag scans from handheld readers, records treatments with withholding-period enforcement, tracks movements between properties for traceability schemes, and generates regulator-ready NLIS/EID reports.
TECH_STACK: Laravel (API-only) + PostgreSQL + Redis + offline-sync batch endpoints + government traceability API integration, deployed on AWS
APP_TYPE: API service
LANGUAGE: PHP
SCALE: ~90 req/sec, 1.2 million animal records, ~50 GB data
```

## 39. GrainGate — grain elevator settlements

```text
APP_DESCRIPTION: A web app for country grain elevators covering intake through settlement. Scale operators capture inbound tickets with moisture and test-weight grading, merchandisers apply contracts and spot prices with discount schedules, and growers view tickets, contracts, and settlement statements in a self-serve portal.
TECH_STACK: Laravel + Blade + Alpine.js + MySQL + scale-head integration + ACH payment file generation + Redis queues, deployed on-prem with cloud replica
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 200 concurrent growers at harvest, ~30 req/sec, ~25 GB data
```

## 40. DocketDoor — court e-filing gateway API

```text
APP_DESCRIPTION: An e-filing gateway API service that connects law-practice software to state court electronic-filing systems. It validates filings against per-court rules, converts documents to court-compliant PDF/A, submits envelopes with fee calculation, and relays clerk accept/reject events back to the source system.
TECH_STACK: Symfony + API Platform + PostgreSQL + Ghostscript/PDF-A conversion workers + RabbitMQ + court ECF SOAP/REST connectors, deployed on Azure
APP_TYPE: API service
LANGUAGE: PHP
SCALE: ~100 req/sec, 18,000 filings/day, ~300 GB documents
```

## 41. ClauseComb — contract clause extraction pipeline

```text
APP_DESCRIPTION: A queue-based pipeline for corporate legal teams that extracts key clauses from uploaded contracts. Workers OCR scanned agreements, detect governing law, renewal, indemnity, and termination clauses, normalize dates and parties into a searchable register, and flag deviations from playbook standards.
TECH_STACK: PHP 8.3 workers + Symfony Messenger + RabbitMQ + Tesseract OCR + LLM extraction API + PostgreSQL + Meilisearch, deployed on AWS ECS
APP_TYPE: data pipeline
LANGUAGE: PHP
SCALE: 3,000 contracts/day, ~40 jobs/sec at batch peak, ~250 GB documents
```

## 42. SealScribe — notary journal platform

```text
APP_DESCRIPTION: A web app for mobile and in-office notaries to keep compliant electronic journals. Notaries log notarial acts with signer ID details, thumbprint image capture, and fee records; the system enforces state-specific journal fields, generates audit exports for commissions, and reminds on commission renewals.
TECH_STACK: Laravel + Livewire + MySQL + S3 encrypted image storage + Redis + state-rule configuration engine, deployed on AWS
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 400 concurrent notaries, ~20 req/sec, ~40 GB data
```

## 43. SpendSpool — expense reimbursement

```text
APP_DESCRIPTION: An expense-reimbursement web app for mid-size companies. Employees snap receipts that OCR into line items with policy checks (per-diem caps, category limits), managers approve on mobile, finance exports to the ledger with tax-code mapping, and out-of-policy spend surfaces in exception dashboards.
TECH_STACK: Laravel + Inertia.js (Vue) + MySQL + receipt OCR (Textract) + Redis queues + NetSuite/Xero export connectors, deployed on AWS
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 800 concurrent employees at month-end, ~60 req/sec, ~55 GB receipts
```

## 44. ReconRail — payment reconciliation pipeline

```text
APP_DESCRIPTION: A data pipeline for finance teams that reconciles payment-processor settlements against internal order ledgers. It ingests daily settlement files from card processors and PSPs, matches transactions with tolerance rules, isolates chargebacks and fee discrepancies, and posts balanced journals to the accounting system.
TECH_STACK: PHP 8.3 + Laravel Zero scheduled workers + Horizon + Redis + PostgreSQL + SFTP/API file ingestion + Xero/NetSuite posting, deployed on AWS
APP_TYPE: data pipeline
LANGUAGE: PHP
SCALE: 2 million transactions/day matched, ~150 GB data
```

## 45. LedgerLatch — payroll tax filing CLI

```text
APP_DESCRIPTION: A CLI tool for payroll bureaus that prepares quarterly and annual payroll tax filings. It validates payroll exports against jurisdiction rules, computes 941/940 and state unemployment figures, generates e-file-ready submission files and W-2/1099 print batches, and produces a discrepancy report per client.
TECH_STACK: PHP 8.3 + symfony/console + SQLite staging DB + XML/EFW2 file generation + PGP encryption for transmission bundles
APP_TYPE: CLI
LANGUAGE: PHP
SCALE: 1,200 client companies per quarterly run, 450,000 employee records, ~12 GB working data
```

## 46. LoanLoom — credit union loan origination

```text
APP_DESCRIPTION: A loan-origination web app for community credit unions. Members apply for auto and personal loans online, the system pulls credit bureau data and computes debt-to-income with configurable decisioning rules, officers review referred applications with document checklists, and approved loans e-sign and fund to member accounts.
TECH_STACK: Symfony + Twig + Turbo + PostgreSQL + credit bureau API integration + DocuSign + core-banking REST connector + Messenger queues, deployed on private cloud
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 250 concurrent members, ~30 req/sec, ~70 GB data
```

## 47. PantryProcure — restaurant supplier ordering

```text
APP_DESCRIPTION: A B2B ordering web app connecting restaurants with food distributors. Chefs build orders from distributor catalogs with contract pricing and par-level suggestions, distributors manage cutoff times and delivery routes, and both sides reconcile deliveries against invoices with credit-request workflows for shorts.
TECH_STACK: Laravel + Inertia.js (Vue) + MySQL + Meilisearch catalog search + Redis + EDI 850/810 export, deployed on AWS
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 900 concurrent buyers before cutoff, ~110 req/sec, ~65 GB data
```

## 48. RoomRelay — hotel channel sync pipeline

```text
APP_DESCRIPTION: A data pipeline that synchronizes rates, availability, and reservations between independent hotels' PMS systems and online travel agencies. It fans out rate and inventory updates to OTA channel APIs, ingests bookings and cancellations back, and detects oversell risk with automatic stop-sell triggers.
TECH_STACK: PHP 8.3 workers + Symfony Messenger + RabbitMQ + MySQL + Redis rate-limit buckets + Booking.com/Expedia/Airbnb API connectors, deployed on AWS ECS
APP_TYPE: data pipeline
LANGUAGE: PHP
SCALE: ~1,100 channel updates/sec peak, 2,800 hotels, ~110 GB data
```

## 49. BanquetBoard — catering production planning

```text
APP_DESCRIPTION: A production-planning web app for catering companies. Sales enters confirmed events with menus and guest counts, the kitchen gets auto-scaled prep lists and station schedules, purchasing sees aggregated ingredient demand across the week, and drivers get load sheets with equipment checklists per event.
TECH_STACK: Laravel + Livewire + MySQL + Redis + recipe-scaling engine + printable kitchen tickets, deployed on DigitalOcean
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 100 concurrent staff, ~12 req/sec, ~9 GB data
```

## 50. CaptionCrate — video captioning pipeline

```text
APP_DESCRIPTION: A queue-based pipeline for media companies that generates and QCs captions for video libraries. It pulls newly published videos, runs speech-to-text with speaker diarization, applies house-style rules (profanity masking, number formatting), routes low-confidence segments to human editors, and delivers WebVTT/SCC files to the CDN.
TECH_STACK: PHP 8.3 workers + Laravel Horizon + Redis + Whisper API + FFmpeg audio extraction + PostgreSQL + S3/CDN delivery, deployed on AWS
APP_TYPE: data pipeline
LANGUAGE: PHP
SCALE: 1,400 video hours/day processed, ~60 jobs/sec, ~2 TB rolling media
```

## 51. LensLedger — stock photo licensing API

```text
APP_DESCRIPTION: A licensing API service for photo agencies that sell editorial and commercial imagery. It exposes searchable catalogs with rights metadata, computes license fees by usage type, territory, and duration, issues license certificates with watermark-free download tokens, and tracks usage for renewal invoicing.
TECH_STACK: Symfony + API Platform + PostgreSQL + Elasticsearch + S3 + signed URL delivery + Stripe invoicing, deployed on AWS
APP_TYPE: API service
LANGUAGE: PHP
SCALE: ~180 req/sec, 4 million images cataloged, ~30 TB media with 90 GB metadata
```

## 52. CivicSignal — municipal 311 issue tracker

```text
APP_DESCRIPTION: A 311-style web app for city governments. Residents report potholes, graffiti, and streetlight outages with photos and map pins, requests auto-route to the right department with SLA timers, crews update status from the field, and open-data dashboards publish response-time stats by neighborhood.
TECH_STACK: Laravel + Blade + Leaflet + PostgreSQL/PostGIS + Redis queues + Open311 API compatibility + SMS notifications, deployed on Azure Government
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 700 concurrent residents after storms, ~65 req/sec, ~90 GB (photos)
```

## 53. FoiaFlow — public records request tracker

```text
APP_DESCRIPTION: A web app for government agencies to manage public-records requests. Requesters submit and track FOIA requests, records officers assign searches to custodians with due-date clocks, redaction reviewers process responsive documents with exemption tagging, and fee estimates and invoices generate automatically.
TECH_STACK: Symfony + Twig + Stimulus + PostgreSQL + S3 document storage + PDF redaction tooling integration + Messenger queues, deployed on AWS GovCloud
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 150 concurrent staff, ~15 req/sec, ~400 GB documents
```

## 54. CurbPass — residential parking permits

```text
APP_DESCRIPTION: A web app for city parking authorities that issues residential and visitor parking permits. Residents prove address eligibility with document upload, buy annual zone permits and daily visitor passes, and manage plates; enforcement officers verify permits by plate lookup from patrol devices.
TECH_STACK: Laravel + Livewire + MySQL + Stripe + address-verification API + plate-lookup REST endpoint for enforcement, deployed on AWS
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 1,000 concurrent residents at renewal season, ~85 req/sec, ~35 GB data
```

## 55. ReturnRamp — e-commerce returns management

```text
APP_DESCRIPTION: A returns-management web app for online retailers. Shoppers start returns from an order-lookup portal with reason capture and exchange suggestions, the system issues carrier labels and QR drop-off codes, warehouses grade returned items for restock or liquidation, and refunds trigger by policy rules.
TECH_STACK: Laravel + Inertia.js (React) + MySQL + Shopify/Magento connectors + EasyPost labels + Redis queues, deployed on AWS
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 1,500 concurrent shoppers post-holiday peak, ~130 req/sec, ~60 GB data
```

## 56. TillTally — POS back office

```text
APP_DESCRIPTION: A back-office web app for convenience-store chains running electronic tills. Head office manages products, price books, and promotions pushed to stores, receives end-of-day sales and cash-declaration uploads, flags till variances and void anomalies per cashier, and consolidates VAT-ready daily summaries.
TECH_STACK: Laminas MVC + PostgreSQL + Redis + store-till sync API + scheduled report generation, deployed on-prem with per-region replicas
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 350 stores syncing, 200 concurrent HQ users, ~140 GB data
```

## 57. FeedForge — product feed generator CLI

```text
APP_DESCRIPTION: A CLI tool for e-commerce teams that builds advertising product feeds. It pulls catalog data from store databases or APIs, applies channel-specific mappings and category taxonomies for Google Shopping, Meta, and marketplaces, validates against channel specs, and uploads feeds on schedule with diff reports.
TECH_STACK: PHP 8.3 + symfony/console + Guzzle + XML/CSV/TSV writers + SQLite cache + cron/systemd timer execution, distributed via Composer
APP_TYPE: CLI
LANGUAGE: PHP
SCALE: 2 million SKUs per run across 14 channels, ~8 GB working data
```

## 58. ScreenSeal — background screening API

```text
APP_DESCRIPTION: An API service for HR platforms that orchestrates employment background checks. It accepts candidate consent and identity data, fans out to criminal-record, education, and employment-verification providers, normalizes disparate results into a single adjudication-ready report, and enforces FCRA adverse-action timelines.
TECH_STACK: Symfony + API Platform + PostgreSQL + RabbitMQ orchestration workers + provider REST/SOAP connectors + OAuth2 + webhook callbacks, deployed on AWS
APP_TYPE: API service
LANGUAGE: PHP
SCALE: ~120 req/sec, 30,000 checks/day, ~180 GB data
```

## 59. RotaRelay — shift marketplace for staff

```text
APP_DESCRIPTION: A web app for hospitals and care homes where staff swap and pick up open shifts. Schedulers publish unfilled shifts with skill and certification requirements, qualified staff claim or trade shifts with rule-checked approvals (rest hours, overtime caps), and payroll receives clean worked-hours exports.
TECH_STACK: Laravel + Livewire + MySQL + Redis + push/SMS notifications + rostering-system import, deployed on AWS
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 2,000 concurrent staff when shifts drop, ~160 req/sec, ~25 GB data
```

## 60. EnrollEase — benefits enrollment portal

```text
APP_DESCRIPTION: A benefits-enrollment web app for employers and brokers. Employees compare medical, dental, and life plans with side-by-side cost modeling during open enrollment, life events trigger mid-year change windows with documentation rules, and carriers receive EDI 834 enrollment files nightly.
TECH_STACK: Laravel + Inertia.js (Vue) + PostgreSQL + EDI 834 generation workers + Redis queues + SSO (SAML), deployed on AWS
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 5,000 concurrent employees during open enrollment, ~250 req/sec, ~75 GB data
```

## 61. PolicyPing — insurance renewal pipeline

```text
APP_DESCRIPTION: A queue-based pipeline for insurance agencies that automates policy-renewal outreach. It ingests policy expiration data from agency-management systems nightly, segments renewals by risk and premium change, schedules multi-touch email/SMS sequences, and writes engagement outcomes back for producers to action.
TECH_STACK: PHP 8.3 workers + Laravel Horizon + Redis + MySQL + AMS360/EZLynx API ingestion + SendGrid/Twilio, deployed on AWS
APP_TYPE: data pipeline
LANGUAGE: PHP
SCALE: 90,000 renewals/month processed, ~200,000 messages/day peak, ~40 GB data
```

## 62. TelemTide — fleet telematics ingestion

```text
APP_DESCRIPTION: A data pipeline that ingests GPS and CAN-bus telemetry from commercial vehicle fleets. It normalizes feeds from mixed tracker hardware, detects events (harsh braking, idling, geofence entry), rolls up per-vehicle utilization and fuel metrics, and serves aggregates to customer dashboards and API consumers.
TECH_STACK: PHP 8.3 + Swoole TCP ingest workers + Kafka + TimescaleDB + Redis + downstream REST API, deployed on AWS EKS
APP_TYPE: data pipeline
LANGUAGE: PHP
SCALE: ~4,000 telemetry points/sec from 15,000 vehicles, ~1.2 TB rolling data
```

## 63. EntryReady — visa document checker

```text
APP_DESCRIPTION: A web app for corporate travel and mobility teams that checks visa and entry requirements. Travelers enter trip legs and nationality, the system returns required visas, vaccinations, and passport-validity rules per destination, tracks application progress with document checklists, and alerts on requirement changes before departure.
TECH_STACK: Laravel + Blade + Alpine.js + MySQL + requirements rules engine + government-source change monitoring jobs + Redis, deployed on AWS
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 600 concurrent travelers, ~45 req/sec, ~12 GB data
```

## 64. BagBeacon — baggage tracing API

```text
APP_DESCRIPTION: An API service for regional airlines and ground handlers that traces checked baggage. It ingests bag-tag scan events across check-in, sortation, loading, and arrival, matches bags to passenger itineraries, raises mishandling alerts when scans miss connection windows, and powers passenger-facing bag-status lookups.
TECH_STACK: Slim 4 + PostgreSQL + Redis streams + BSM/BPM message parsing + IATA integration adapters, deployed on Azure
APP_TYPE: API service
LANGUAGE: PHP
SCALE: ~800 scan events/sec hub peak, 120,000 bags/day, ~200 GB data
```

## 65. CurioCase — museum collection catalog

```text
APP_DESCRIPTION: A collections-management web app for regional museums. Registrars catalog objects with provenance, condition reports, and location history down to shelf level; curators assemble exhibition checklists with loan agreements and insurance values; and a public portal exposes digitized highlights with IIIF image viewing.
TECH_STACK: Symfony + Twig + PostgreSQL + Elasticsearch + IIIF image server integration + S3 media storage, deployed on institutional VMware
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 60 concurrent staff + 400 concurrent public visitors, ~35 req/sec, ~500 GB media
```

## 66. StackShuttle — interlibrary loan manager

```text
APP_DESCRIPTION: A web app for library consortia managing interlibrary loans. Patrons request titles not held locally, the system locates lending copies across member catalogs by holdings lookup, routes requests down a lender ladder with response deadlines, and tracks physical shipments and due-date chains between libraries.
TECH_STACK: Laravel + Blade + MySQL + Z39.50/ISO ILL protocol adapters + Redis queues + courier label printing, deployed on consortium data center
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 300 concurrent library staff, ~25 req/sec, 500,000 requests/year, ~30 GB data
```

## 67. LeagueLattice — sports league operations

```text
APP_DESCRIPTION: A league-operations web app for amateur sports associations. Administrators generate season fixtures with venue and referee assignment constraints, teams manage rosters with player eligibility checks, scores and standings update live with tiebreaker rules, and disciplinary reports track suspensions across seasons.
TECH_STACK: Laravel + Livewire + MySQL + Redis + fixture-generation solver + iCal team feeds, deployed on Hetzner
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 1,200 concurrent users on game-day evenings, ~90 req/sec, ~15 GB data
```

## 68. SnagSnap — construction punch list

```text
APP_DESCRIPTION: A punch-list web app for general contractors closing out construction projects. Field teams log defects with photos pinned to floor plans, items assign to subcontractors with due dates and cost-back tracking, re-inspection workflows verify fixes, and owners receive completion reports per zone at handover.
TECH_STACK: Laravel + Inertia.js (Vue) + PostgreSQL + S3 photo storage + floor-plan pin rendering + offline-tolerant sync endpoints + Redis, deployed on AWS
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 450 concurrent field users, ~40 req/sec, ~180 GB photos
```

## 69. DuctDispatch — HVAC field service

```text
APP_DESCRIPTION: A field-service web app for HVAC contractors. Dispatchers schedule service calls on a drag-and-drop board with technician skills and travel time, techs run job workflows on their phones (diagnosis, parts, photos, customer signature), quotes convert to work orders, and service agreements auto-generate seasonal maintenance visits.
TECH_STACK: Laravel + Livewire + MySQL + Redis + Stripe payments in the field + Twilio appointment texts + QuickBooks sync, deployed on AWS
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 300 concurrent technicians and dispatchers, ~35 req/sec, ~45 GB data
```

## 70. LinePulse — factory OEE pipeline

```text
APP_DESCRIPTION: A data pipeline for manufacturers that computes overall equipment effectiveness from shop-floor signals. It ingests machine-state and part-count events from PLC gateways, classifies downtime against reason codes, computes availability, performance, and quality per line and shift, and feeds andon boards and morning-meeting reports.
TECH_STACK: PHP 8.3 workers + Symfony Messenger + MQTT ingestion bridge + TimescaleDB + Redis + Grafana-facing REST API, deployed on plant-edge Kubernetes
APP_TYPE: data pipeline
LANGUAGE: PHP
SCALE: ~2,500 machine events/sec across 40 lines, ~700 GB rolling data
```

## 71. WeftWorks — textile order tracking

```text
APP_DESCRIPTION: An order-tracking web app for textile mills and their apparel-brand customers. Brands place dyeing and weaving orders with technical specs and lab-dip approvals, the mill tracks lots through warping, weaving, dyeing, and finishing with quality-check gates, and shipment documents generate with roll-level barcodes.
TECH_STACK: Symfony + Twig + Turbo + MySQL + barcode label generation + Messenger queues + customer portal with S3 spec storage, deployed on AWS Mumbai
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 180 concurrent users, ~20 req/sec, ~35 GB data
```

## 72. PrepProof — food safety logging

```text
APP_DESCRIPTION: A HACCP compliance web app for commercial kitchens and food manufacturers. Staff complete scheduled checks (fridge temps, cooking/cooling logs, cleaning schedules) from wall-mounted tablets, Bluetooth probes feed readings automatically, out-of-range values trigger corrective-action workflows, and auditors get one-click compliance packs.
TECH_STACK: Laravel + Livewire + MySQL + Redis + Bluetooth probe gateway API + scheduled check engine + PDF audit packs, deployed on AWS
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 900 sites logging, ~70 req/sec at shift checks, ~50 GB data
```

## 73. MashMetric — brewery batch tracking

```text
APP_DESCRIPTION: A batch-tracking web app for craft breweries. Brewers plan brews against recipes with ingredient lot tracking, log gravity and temperature readings through fermentation, manage tank scheduling and transfers, and generate TTB-ready excise reports plus packaged-inventory counts by keg and can run.
TECH_STACK: Laravel + Blade + Alpine.js + MySQL + Redis + Tilt/PLAATO sensor ingestion webhook + reporting exports, deployed on DigitalOcean
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 250 breweries, 120 concurrent users, ~18 GB data
```

## 74. RoastRoster — coffee roastery operations

```text
APP_DESCRIPTION: An operations web app for specialty coffee roasters. Green-buyers track inventory by lot with arrival cupping scores, roasters schedule production against wholesale standing orders and cafe par levels, roast profiles log per batch with shrinkage tracking, and wholesale customers reorder through a B2B portal.
TECH_STACK: Laravel + Inertia.js (Vue) + MySQL + Redis + roaster-software (Cropster) API sync + Stripe B2B invoicing, deployed on AWS
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 140 concurrent users, ~15 req/sec, ~10 GB data
```

## 75. PlumeProbe — air quality ingestion pipeline

```text
APP_DESCRIPTION: A data pipeline for environmental agencies and research groups that processes air-quality sensor networks. It ingests PM2.5, NO2, and ozone readings from mixed-vendor sensors, applies calibration models and outlier rejection, computes rolling AQI per station, and publishes open-data feeds plus threshold-breach alerts to subscribers.
TECH_STACK: PHP 8.3 workers + Symfony Messenger + RabbitMQ + TimescaleDB + calibration model service + public REST/CSV feeds + SNS alerts, deployed on AWS
APP_TYPE: data pipeline
LANGUAGE: PHP
SCALE: ~1,800 readings/sec from 6,000 sensors, ~900 GB rolling data
```

## 76. CurbCycle — waste collection routing API

```text
APP_DESCRIPTION: An API service for municipal waste contractors that manages collection routes and exceptions. It serves optimized daily routes to truck tablets, records lift events from RFID bin scans, captures missed-bin and contamination reports with photos, and feeds billing systems with verified service counts per household.
TECH_STACK: Laravel (API-only) + PostgreSQL/PostGIS + Redis + RFID event ingestion + route optimization service integration + webhook billing feeds, deployed on Azure
APP_TYPE: API service
LANGUAGE: PHP
SCALE: ~300 req/sec during collection hours, 400,000 households served, ~130 GB data
```

## 77. MeterMuster — utility meter ingestion pipeline

```text
APP_DESCRIPTION: A data pipeline for water and gas utilities that processes smart-meter readings. It ingests AMI interval reads from head-end systems, validates with estimation rules for gaps and rollovers, detects leak and tamper signatures, and delivers billing-determinant files to the CIS plus consumption APIs for customer portals.
TECH_STACK: PHP 8.3 + Laravel Horizon workers + Kafka + TimescaleDB + Redis + head-end SFTP/MultiSpeak connectors, deployed on private cloud
APP_TYPE: data pipeline
LANGUAGE: PHP
SCALE: 500,000 meters at 15-minute intervals (~550 reads/sec sustained), ~2 TB rolling data
```

## 78. JouleJury — energy bill audit CLI

```text
APP_DESCRIPTION: A CLI tool for energy consultants that audits commercial utility bills. It parses PDF and EDI bill batches across electricity, gas, and water accounts, validates charges against tariff libraries and contract rates, flags billing errors and demand-charge anomalies, and produces client-ready recovery-claim workbooks.
TECH_STACK: PHP 8.3 + symfony/console + PDF parsing (smalot/pdfparser) + EDI 810 parsing + SQLite tariff store + PhpSpreadsheet output
APP_TYPE: CLI
LANGUAGE: PHP
SCALE: 40,000 bills per monthly run across 2,500 sites, ~5 GB working data
```

## 79. SimSpindle — telecom SIM provisioning API

```text
APP_DESCRIPTION: An API service for MVNOs that provisions and manages SIM lifecycles. It activates physical and eSIM profiles against carrier wholesale APIs, assigns plans with throttle and roaming policies, processes number ports with regulatory validation, and suspends or swaps SIMs with full audit trails.
TECH_STACK: Symfony + API Platform + PostgreSQL + RabbitMQ orchestration + carrier SOAP/REST adapters + eSIM SM-DP+ integration + OAuth2, deployed on AWS
APP_TYPE: API service
LANGUAGE: PHP
SCALE: ~140 req/sec, 900,000 active SIMs, ~160 GB data
```

## 80. FiberFront — ISP customer portal

```text
APP_DESCRIPTION: A customer portal web app for regional fiber ISPs. Subscribers view usage and invoices, upgrade speed tiers with instant provisioning, run guided line diagnostics before opening tickets, and book technician visits; support staff see modem telemetry alongside tickets to resolve issues without truck rolls.
TECH_STACK: Laravel + Inertia.js (Vue) + MySQL + RADIUS/ACS provisioning integration + Stripe billing + Redis + ticketing module, deployed on ISP-owned infrastructure
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 3,000 concurrent subscribers during outages, ~200 req/sec, ~85 GB data
```

## 81. CertSentry — certificate expiry monitor CLI

```text
APP_DESCRIPTION: A CLI tool for ops teams that monitors TLS certificate and domain expirations across large estates. It scans host lists and cloud DNS zones, checks certificate chains, expiry windows, and weak-key issues, verifies domain registration and DNSSEC status, and emits alerts to Slack/PagerDuty plus a fleet-health JSON report.
TECH_STACK: PHP 8.3 + symfony/console + parallel socket checks (amphp) + WHOIS/RDAP + cloud DNS APIs + SQLite state DB, distributed as PHAR
APP_TYPE: CLI
LANGUAGE: PHP
SCALE: 25,000 endpoints scanned per hourly run, ~2 GB state data
```

## 82. StatusStrand — hosted incident status pages

```text
APP_DESCRIPTION: A web app that hosts branded status pages for SaaS companies. Operators declare incidents with component-level impact and post timeline updates, subscribers get email/SMS/webhook notifications, uptime metrics render from monitoring-API integrations, and scheduled maintenance windows announce automatically.
TECH_STACK: Laravel + Livewire + MySQL + Redis + CDN-cached public pages + Postmark/Twilio + monitoring webhook ingestion, deployed on AWS with multi-region failover
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 40,000 concurrent page viewers during a major incident, ~600 req/sec (edge-cached), ~20 GB data
```

## 83. WarmWire — email deliverability warmup pipeline

```text
APP_DESCRIPTION: A queue-based pipeline for email service providers that warms up new sending domains and IPs. It schedules ramped send volumes across seed networks, harvests inbox-placement and spam-folder signals, adjusts daily quotas per domain reputation, and produces deliverability scorecards before customers go to full volume.
TECH_STACK: PHP 8.3 workers + Laravel Horizon + Redis + PostgreSQL + SMTP send workers + IMAP seed-inbox polling + reputation APIs, deployed on AWS
APP_TYPE: data pipeline
LANGUAGE: PHP
SCALE: 350,000 warmup emails/day across 1,200 domains, ~25 GB data
```

## 84. NudgeNode — appointment reminder API

```text
APP_DESCRIPTION: An API service that adds automated appointment reminders to vertical SaaS products. Client systems push upcoming appointments, the service schedules multi-channel reminder cascades (SMS, email, voice) with quiet-hours and locale handling, captures confirm/reschedule replies, and reports no-show reduction metrics per client.
TECH_STACK: Slim 4 + PHP-DI + MySQL + Redis delayed queues + Twilio/SendGrid + inbound reply webhooks + HMAC-signed client APIs, deployed on Google Cloud Run
APP_TYPE: API service
LANGUAGE: PHP
SCALE: ~250 req/sec, 500,000 reminders/day, ~45 GB data
```

## 85. SteepleSuite — church community management

```text
APP_DESCRIPTION: A community-management web app for churches and parishes. Staff maintain member households with pastoral-care notes, schedule services and volunteer teams (music, ushers, children's ministry) with availability matching, track giving with annual statements, and coordinate small groups with attendance and communication tools.
TECH_STACK: Laravel + Livewire + MySQL + Stripe/ACH giving + Redis + email/SMS broadcasts + printable directories, deployed on DigitalOcean
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 800 concurrent members Sunday mornings, ~55 req/sec, ~20 GB data
```

## 86. WillowWake — funeral home coordination

```text
APP_DESCRIPTION: A case-coordination web app for funeral homes. Directors manage arrangements from first call through service — decedent details, permits and death-certificate orders, casket and service selections with itemized statements, obituary drafting and publication, and family task checklists shared through a private family portal.
TECH_STACK: Symfony + Twig + Turbo + PostgreSQL + document e-sign integration + Stripe payment plans + Messenger queues, deployed on AWS
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 90 concurrent staff across locations, ~10 req/sec, ~15 GB data
```

## 87. KinKeeper — genealogy archive platform

```text
APP_DESCRIPTION: A genealogy web app for family historians and local heritage societies. Researchers build family trees with sourced citations, upload and transcribe scanned records (censuses, parish registers, letters), link individuals across trees with match suggestions, and publish privacy-filtered trees that hide living persons.
TECH_STACK: Laravel + Inertia.js (Vue) + PostgreSQL + Elasticsearch person search + S3 scan storage + GEDCOM import/export + Redis, deployed on Hetzner
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 1,000 concurrent researchers, ~75 req/sec, ~350 GB scans
```

## 88. LinguaLoom — translation agency management

```text
APP_DESCRIPTION: A project-management web app for translation agencies. Project managers quote jobs by word count and language pair with CAT-tool analysis imports, assign vetted freelance linguists with deadline tracking, run translation-review-QA workflows per file, and invoice clients while generating linguist purchase orders.
TECH_STACK: Symfony + Vue + PostgreSQL + XLIFF/TMX file handling + Messenger queues + Stripe invoicing + linguist portal, deployed on AWS Frankfurt
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 300 concurrent PMs and linguists, ~30 req/sec, ~120 GB project files
```

## 89. VisitVouch — home care visit verification API

```text
APP_DESCRIPTION: An electronic-visit-verification API service for home-care agencies. Caregiver apps check in and out of client visits with GPS and telephony fallback, the service validates visits against authorized care plans and schedules, flags exceptions (late, short, wrong location) for supervisor review, and submits state-compliant EVV records to Medicaid aggregators.
TECH_STACK: Laravel (API-only) + PostgreSQL + Redis + Twilio IVR check-in + state aggregator (Sandata/HHAeXchange) connectors + HMAC-signed device APIs, deployed on AWS
APP_TYPE: API service
LANGUAGE: PHP
SCALE: ~200 req/sec at shift changes, 45,000 visits/day, ~90 GB data
```

## 90. CohortCompass — clinical trial coordination

```text
APP_DESCRIPTION: A site-coordination web app for clinical research organizations. Coordinators screen and enroll participants against inclusion criteria, schedule protocol visits with window compliance tracking, log deviations and adverse events with sponsor notifications, and manage stipend payments and document binders per study.
TECH_STACK: Symfony + Twig + Stimulus + PostgreSQL + audit-trail event log (21 CFR Part 11 aligned) + Messenger queues + e-signature integration, deployed on validated AWS environment
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 250 concurrent coordinators across 80 sites, ~25 req/sec, ~60 GB data
```

## 91. ScrubStack — medical claim scrubbing pipeline

```text
APP_DESCRIPTION: A queue-based pipeline for medical billing companies that scrubs insurance claims before submission. It ingests 837 claim batches from practice-management systems, validates codes against payer rules, CCI edits, and modifier logic, auto-corrects fixable errors, routes rejects to biller work queues, and forwards clean claims to clearinghouses.
TECH_STACK: PHP 8.3 workers + Symfony Messenger + RabbitMQ + PostgreSQL rules engine + X12 837/277 parsing + clearinghouse SFTP/API delivery, deployed on HIPAA-aligned AWS
APP_TYPE: data pipeline
LANGUAGE: PHP
SCALE: 300,000 claims/day scrubbed, ~120 jobs/sec batch peak, ~220 GB data
```

## 92. ReelJury — film festival submissions

```text
APP_DESCRIPTION: A submissions web app for film festivals. Filmmakers submit entries with screeners, stills, and press kits across categories and deadlines with tiered fees, programmers screen and score films through assignment queues with watch-progress tracking, and selection meetings run from shortlist boards that publish accept/decline notifications.
TECH_STACK: Laravel + Inertia.js (React) + MySQL + Mux screener streaming with watermarking + Stripe entry fees + Redis queues, deployed on AWS
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 1,800 concurrent filmmakers at deadline, ~140 req/sec, ~5 TB screeners with 40 GB metadata
```

## 93. RoyaltyRail — music royalty accounting

```text
APP_DESCRIPTION: A royalty-accounting web app for independent record labels. Staff import streaming and sales statements from distributors, the system matches lines to releases and splits earnings by contract terms (advances, recoupment, splits), artists view earnings dashboards, and quarterly statements generate with payout batches.
TECH_STACK: Laravel + Livewire + PostgreSQL + statement-import parsers (DSP CSV/flat files) + Redis queue processing + Wise payout API + PDF statements, deployed on AWS
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 200 labels, 12 million statement lines/quarter processed, ~150 GB data
```

## 94. TariffTrek — customs brokerage workflow

```text
APP_DESCRIPTION: A workflow web app for customs brokers clearing import shipments. Entry writers classify goods with HS-code lookup and duty calculation, compile entry packets from commercial invoices and bills of lading, file to customs via ABI/CDS integrations, and track holds, exams, and duty payments with client status portals.
TECH_STACK: Symfony + Twig + Turbo + PostgreSQL + HS tariff database + customs (ABI/ACE) EDI integration + Messenger queues + S3 document storage, deployed on AWS
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 150 concurrent entry writers, ~20 req/sec, 3,000 entries/day, ~200 GB documents
```

## 95. ChillChain — cold-chain monitoring API

```text
APP_DESCRIPTION: An API service that monitors temperature-controlled shipments for food and pharma logistics. IoT loggers stream temperature and humidity readings per shipment, the service evaluates excursions against product-specific stability budgets, alerts stakeholders mid-transit, and issues tamper-evident compliance certificates on delivery.
TECH_STACK: Laravel Octane (Swoole) + TimescaleDB + Redis + MQTT ingestion bridge + PDF certificate generation + webhook/SMS alerting, deployed on AWS
APP_TYPE: API service
LANGUAGE: PHP
SCALE: ~1,000 readings/sec from 30,000 active shipments, ~400 GB rolling data
```

## 96. SeedSeal — cannabis compliance API

```text
APP_DESCRIPTION: A seed-to-sale compliance API service for licensed cannabis operators. It tracks plants and packages through cultivation, processing, and retail with state-mandated tag events, syncs to state traceability systems (Metrc), enforces plant-count and transfer-manifest rules, and surfaces audit-risk discrepancies before inspections.
TECH_STACK: Laravel (API-only) + PostgreSQL + Redis + Metrc API sync workers + manifest generation + OAuth2 client APIs, deployed on Google Cloud
APP_TYPE: API service
LANGUAGE: PHP
SCALE: ~130 req/sec, 250 licensed facilities, 2 million tracked packages, ~110 GB data
```

## 97. NetHaul — fisheries catch reporting API

```text
APP_DESCRIPTION: An API service for fisheries regulators and fishing cooperatives that handles electronic catch reporting. Vessel apps submit trip declarations and catch reports by species, gear, and zone (with offline queueing at sea), the service validates against quota balances and closed areas, and dockside monitors reconcile landings against reports.
TECH_STACK: Slim 4 + PostgreSQL/PostGIS + Redis + offline batch sync endpoints + quota ledger engine + regulator data-exchange feeds, deployed on national government cloud
APP_TYPE: API service
LANGUAGE: PHP
SCALE: ~40 req/sec with landing-time spikes, 6,000 vessels reporting, ~55 GB data
```

## 98. PressPorter — WordPress backup and migration CLI

```text
APP_DESCRIPTION: A CLI tool for agencies managing fleets of client WordPress sites. It snapshots databases and uploads to versioned offsite storage with incremental deduplication, migrates sites between hosts with automatic URL rewriting and environment config swaps, and verifies restores by booting throwaway containers and smoke-testing key pages.
TECH_STACK: PHP 8.3 + symfony/console + WP-CLI orchestration + mysqldump/rsync + S3-compatible storage + Docker verify harness, distributed as PHAR
APP_TYPE: CLI
LANGUAGE: PHP
SCALE: 600 sites per nightly run, ~1.5 TB backup storage under management
```

## 99. CartCourier — WooCommerce-to-ERP sync pipeline

```text
APP_DESCRIPTION: A queue-based pipeline that syncs WooCommerce stores with ERP systems for wholesale brands. It streams orders into the ERP with customer and tax mapping, pushes stock levels and tier pricing back to the stores, reconciles refunds and credit memos bidirectionally, and quarantines mapping conflicts in an operator review queue.
TECH_STACK: PHP 8.3 workers + Symfony Messenger + RabbitMQ + MySQL + WooCommerce REST + ERP (Business Central/SAP B1) connectors + Redis dedup, deployed on AWS ECS
APP_TYPE: data pipeline
LANGUAGE: PHP
SCALE: ~300 sync messages/sec peak, 85 stores, 40,000 orders/day, ~95 GB data
```

## 100. PressPipe — headless WordPress content API

```text
APP_DESCRIPTION: An API service that fronts multi-brand WordPress editorial backends for headless delivery. It aggregates content from several WordPress installs into a normalized content graph, serves cached, versioned JSON to web and app frontends with preview tokens for editors, and invalidates edge caches on publish webhooks.
TECH_STACK: Symfony + API Platform + PostgreSQL content index + Redis + Varnish/CDN edge caching + WordPress REST/GraphQL ingestion + publish webhooks, deployed on AWS
APP_TYPE: API service
LANGUAGE: PHP
SCALE: ~1,200 req/sec (95% edge-cached), 9 source sites, ~50 GB content index
```
