# Python Blueprint Types — Copy-Paste Input Sets

Copy a fenced block into the prompt as-is, or swap individual fields.

## 1. VetDesk — veterinary practice management

```text
APP_DESCRIPTION: A practice-management web app for small veterinary clinics. Front desk schedules appointments and vaccine reminders, vets record SOAP notes and prescriptions per patient animal, and owners receive visit summaries and invoices.
TECH_STACK: Django + PostgreSQL + HTMX + Celery/Redis for reminders, deployed on AWS Lightsail
APP_TYPE: web app
LANGUAGE: Python
SCALE: 90 concurrent users, ~20 req/sec, ~15 GB data
```

## 2. AirTrace — air-quality sensor ETL

```text
APP_DESCRIPTION: A data pipeline for a regional environmental agency that ingests air-quality readings (PM2.5, NO2, O3) from 800 public sensors. It cleans and calibrates raw readings against reference stations, flags sensor drift, and publishes hourly city-level aggregates to an open-data portal.
TECH_STACK: Python + Apache Airflow + pandas + PostgreSQL/PostGIS + S3, deployed on AWS
APP_TYPE: data pipeline
LANGUAGE: Python
SCALE: 800 sensors reporting every 60s (~13 readings/sec), ~2 GB/day, 5-year retention
```

## 3. DiscoveryDock — legal document search API

```text
APP_DESCRIPTION: An e-discovery search API service for litigation support teams. Paralegals upload document productions, the service extracts text and metadata, deduplicates near-identical documents, and exposes faceted full-text search with privilege-tag filtering.
TECH_STACK: FastAPI + PostgreSQL + OpenSearch + Celery workers + S3, deployed on AWS ECS
APP_TYPE: API service
LANGUAGE: Python
SCALE: ~40 req/sec, 50 concurrent reviewers, ~500 GB document corpus
```

## 4. BellSchedule — school timetable builder

```text
APP_DESCRIPTION: A timetable-construction web app for secondary school administrators. Schedulers define rooms, teacher availability, and course sections; a constraint solver proposes conflict-free timetables; staff publish final schedules to teachers and students.
TECH_STACK: Django + PostgreSQL + OR-Tools constraint solver + HTMX, deployed on Hetzner
APP_TYPE: web app
LANGUAGE: Python
SCALE: 150 concurrent users at term start, ~25 req/sec, ~3 GB data
```

## 5. ShelfSense — retail demand forecasting pipeline

```text
APP_DESCRIPTION: A demand-forecasting data pipeline for a 40-store grocery chain. It ingests nightly point-of-sale exports, joins promotions and weather data, retrains per-category forecasting models weekly, and delivers store-level order recommendations to the purchasing team each morning.
TECH_STACK: Python + Prefect + pandas/scikit-learn + Snowflake + dbt, deployed on AWS
APP_TYPE: data pipeline
LANGUAGE: Python
SCALE: 40 stores × ~25k SKUs nightly (~12 GB/day), forecasts due by 06:00 daily
```

## 6. PennyWise — personal budgeting app

```text
APP_DESCRIPTION: A personal-finance budgeting web app for young professionals. Users import bank CSV exports, auto-categorize transactions with editable rules, set monthly envelope budgets, and see overspend alerts and savings-goal progress.
TECH_STACK: Flask + SQLAlchemy + PostgreSQL + Chart.js, deployed on Fly.io
APP_TYPE: web app
LANGUAGE: Python
SCALE: 250 concurrent users, ~30 req/sec, ~10 GB data
```

## 7. SampleTrack — lab LIMS

```text
APP_DESCRIPTION: A sample-tracking web app (lightweight LIMS) for university research labs. Researchers register biological samples with storage locations (freezer/rack/box), log freeze-thaw cycles and derivations, book shared instruments, and export chain-of-custody reports.
TECH_STACK: Django + PostgreSQL + django-rest-framework + barcode label printing, self-hosted on lab server
APP_TYPE: web app
LANGUAGE: Python
SCALE: 50 concurrent users, ~10 req/sec, ~8 GB data
```

## 8. TileFactory — satellite imagery pipeline

```text
APP_DESCRIPTION: A data pipeline for an agritech company that processes satellite imagery into field-health map tiles. It ingests new Sentinel-2 scenes, computes NDVI and cloud masks per client field boundary, renders web map tiles, and notifies agronomists when field stress is detected.
TECH_STACK: Python + Celery + rasterio/GDAL + PostGIS + S3 + Docker, deployed on AWS Batch
APP_TYPE: data pipeline
LANGUAGE: Python
SCALE: ~300 scenes/day (~150 GB/day raw), 12,000 monitored fields, tiles served to 500 users
```

## 9. FeedMerge — job feed aggregation pipeline

```text
APP_DESCRIPTION: A data pipeline for a niche job board that aggregates partner-provided job feeds. It pulls licensed XML/JSON feeds from 60 staffing partners, normalizes titles and locations to a shared taxonomy, deduplicates cross-posted listings, and publishes a clean feed to the job-board database with expiry handling.
TECH_STACK: Python + Airflow + pydantic + PostgreSQL + Redis dedup cache, deployed on GCP
APP_TYPE: data pipeline
LANGUAGE: Python
SCALE: 60 feeds, ~400k listings/day processed, ~6 GB/day, hourly refresh
```

## 10. AsanaFlow — yoga studio booking

```text
APP_DESCRIPTION: A class-booking web app for independent yoga studios. Students buy class packs or memberships, book and cancel spots with waitlist promotion, and check in via QR code; instructors see rosters and studios track utilization.
TECH_STACK: Django + PostgreSQL + Stripe + HTMX + Celery reminders, deployed on Render
APP_TYPE: web app
LANGUAGE: Python
SCALE: 180 concurrent users at booking-open peak, ~25 req/sec, ~5 GB data
```

## 11. vaultkeeper — backup orchestration CLI

```text
APP_DESCRIPTION: A CLI tool for sysadmins that orchestrates database backups across heterogeneous servers. It reads a declarative config of PostgreSQL/MySQL/SQLite targets, runs scheduled dumps with compression and encryption, rotates archives by retention policy, verifies restorability with test restores, and reports to a webhook.
TECH_STACK: Python CLI (Typer) + paramiko SSH + age encryption + S3/B2 storage backends, distributed via pipx
APP_TYPE: CLI
LANGUAGE: Python
SCALE: single operator, ~200 database targets, ~50 GB nightly backup volume
```

## 12. LabelLens — nutrition label OCR API

```text
APP_DESCRIPTION: An API service for diet-app developers that extracts structured nutrition data from food-label photos. Clients POST label images; the service OCRs the nutrition panel, parses serving sizes and nutrient rows into normalized JSON, and flags low-confidence fields for human review.
TECH_STACK: FastAPI + Tesseract/PaddleOCR + PostgreSQL + Redis queue + S3, deployed on GCP Cloud Run
APP_TYPE: API service
LANGUAGE: Python
SCALE: ~90 req/sec peak, 40 API clients, ~80 GB image data
```

## 13. TrailCamAI — wildlife image pipeline

```text
APP_DESCRIPTION: A data pipeline for a conservation NGO that processes camera-trap images from 300 field cameras. It ingests SD-card and cellular uploads, runs species-classification models, filters empty frames, routes uncertain detections to volunteer reviewers, and aggregates sighting statistics per reserve.
TECH_STACK: Python + Celery + PyTorch (MegaDetector) + PostgreSQL + S3 + label-review web queue, deployed on AWS
APP_TYPE: data pipeline
LANGUAGE: Python
SCALE: ~50k images/day (~40 GB/day), 300 cameras, 150 volunteer reviewers
```

## 14. HiveMetric — apiary sensor telemetry pipeline

```text
APP_DESCRIPTION: A data pipeline for commercial beekeeping operations that ingests hive-scale weight, temperature, and acoustic readings from in-hive sensors. It detects swarm precursors and queen loss from signal patterns and pushes daily hive-health digests to beekeepers before yard visits.
TECH_STACK: Python + Prefect + MQTT ingestion + TimescaleDB + scikit-learn anomaly models, deployed on Hetzner
APP_TYPE: data pipeline
LANGUAGE: Python
SCALE: 4,500 hives reporting every 15 min (~5 readings/sec), ~600 MB/day, 3-year retention
```

## 15. ClaimPilot — auto insurance claims triage

```text
APP_DESCRIPTION: A claims-intake web app for regional auto insurers. Policyholders file claims with photos and incident details, adjusters get severity-scored queues with fraud flags, and repair shops receive authorized estimates through a partner portal.
TECH_STACK: Django + PostgreSQL + Celery/Redis + S3 photo storage + HTMX, deployed on AWS ECS
APP_TYPE: web app
LANGUAGE: Python
SCALE: 400 concurrent users, ~55 req/sec, ~350 GB data including photos
```

## 16. FreightLoom — LTL freight quoting API

```text
APP_DESCRIPTION: A rating API service for less-than-truckload freight brokers. Client TMS systems submit shipment dimensions, lanes, and accessorials; the service normalizes freight class, queries contracted carrier rate tables, and returns ranked quotes with transit-time estimates.
TECH_STACK: FastAPI + PostgreSQL + Redis rate-table cache + pydantic + Docker, deployed on AWS Fargate
APP_TYPE: API service
LANGUAGE: Python
SCALE: ~120 req/sec peak, 85 broker integrations, ~40 GB rate data
```

## 17. CurriculumForge — corporate training LMS

```text
APP_DESCRIPTION: A learning-management web app for mid-size companies running compliance and skills training. L&D teams author course paths with quizzes and SCORM packages, managers assign tracks by role, and auditors export completion evidence for certifications.
TECH_STACK: Django + PostgreSQL + Celery + S3 media + Alpine.js, deployed on Azure App Service
APP_TYPE: web app
LANGUAGE: Python
SCALE: 1,200 concurrent learners at deadline peaks, ~80 req/sec, ~200 GB course media
```

## 18. GrapeGauge — vineyard disease-risk pipeline

```text
APP_DESCRIPTION: A data pipeline for wine-grape growers that fuses on-vineyard weather station data with regional forecasts to model mildew and botrytis risk per block. It issues spray-window recommendations and logs applied treatments for export compliance records.
TECH_STACK: Python + Dagster + pandas + PostgreSQL + weather API ingestion + Twilio alerts, deployed on GCP
APP_TYPE: data pipeline
LANGUAGE: Python
SCALE: 220 vineyards, 1,100 weather stations polled hourly, ~900 MB/day
```

## 19. DocketDing — court docket monitoring API

```text
APP_DESCRIPTION: An API service for law firms that monitors state and federal court dockets for new filings in tracked cases. It polls PACER and state e-filing systems, diffs docket entries, classifies filing types, and pushes webhook alerts to firm case-management systems.
TECH_STACK: FastAPI + Celery pollers + PostgreSQL + Redis + webhook delivery with retries, deployed on AWS
APP_TYPE: API service
LANGUAGE: Python
SCALE: 28,000 tracked dockets, ~15k new entries/day, 140 firm subscribers
```

## 20. TurbineTrace — wind turbine anomaly pipeline

```text
APP_DESCRIPTION: A data pipeline for a wind-farm operator that ingests SCADA telemetry from turbines across 9 sites. It computes power-curve deviations, detects gearbox and pitch-system anomalies, and opens prioritized maintenance work orders before failures ground turbines.
TECH_STACK: Python + Apache Airflow + Kafka ingestion + TimescaleDB + scikit-learn + Grafana, deployed on-prem with k3s
APP_TYPE: data pipeline
LANGUAGE: Python
SCALE: 310 turbines × 200 signals at 10s resolution (~6,200 points/sec), ~25 GB/day
```

## 21. GeneStitch — variant annotation pipeline

```text
APP_DESCRIPTION: A bioinformatics data pipeline for a clinical genetics lab that annotates variant call files from gene-panel sequencing runs. It normalizes VCFs, layers population frequency and pathogenicity annotations, applies ACMG classification rules, and produces draft reports for geneticist sign-off.
TECH_STACK: Python + Snakemake + pysam/cyvcf2 + PostgreSQL + VEP/ClinVar caches, run on an on-prem HPC cluster
APP_TYPE: data pipeline
LANGUAGE: Python
SCALE: ~60 sequencing runs/week, ~4M variants annotated weekly, ~2 TB reference data
```

## 22. StaySync — boutique hotel channel manager

```text
APP_DESCRIPTION: An API service that keeps room availability, rates, and bookings synchronized between boutique hotels' property-management systems and OTA channels like Booking.com and Expedia. It resolves double-booking conflicts and pushes rate-plan updates within seconds.
TECH_STACK: FastAPI + Celery + PostgreSQL + Redis + RabbitMQ channel connectors, deployed on DigitalOcean Kubernetes
APP_TYPE: API service
LANGUAGE: Python
SCALE: 650 properties, ~45k booking messages/day, ~35 req/sec peak
```

## 23. RxRoute — pharmacy delivery routing API

```text
APP_DESCRIPTION: An API service for independent pharmacies offering same-day prescription delivery. It batches ready prescriptions into optimized driver routes respecting refrigeration constraints and delivery windows, and exposes live ETA tracking links for patients.
TECH_STACK: FastAPI + OR-Tools VRP solver + PostgreSQL/PostGIS + Redis + OSRM routing, deployed on AWS
APP_TYPE: API service
LANGUAGE: Python
SCALE: 240 pharmacies, ~9k deliveries/day, ~30 req/sec, 380 drivers tracked
```

## 24. MatchLadder — amateur soccer league management

```text
APP_DESCRIPTION: A league-management web app for amateur soccer associations. Organizers generate fixture schedules with field and referee assignments, captains submit rosters and match reports, and standings, suspensions, and top-scorer tables update automatically.
TECH_STACK: Django + PostgreSQL + HTMX + Celery for fixture generation, deployed on Fly.io
APP_TYPE: web app
LANGUAGE: Python
SCALE: 320 concurrent users on match days, ~30 req/sec, 5,800 registered players
```

## 25. PermitPath — municipal building permit portal

```text
APP_DESCRIPTION: A permit-tracking web app for a mid-size city's building department. Contractors submit permit applications with plan documents, plan reviewers run parallel review tracks with comment cycles, and inspectors schedule and record field inspections from the same record.
TECH_STACK: Django + PostgreSQL + S3 document storage + Celery + GovDelivery notifications, deployed on AWS GovCloud
APP_TYPE: web app
LANGUAGE: Python
SCALE: 260 concurrent users, ~18k permits/year, ~1.2 TB plan documents
```

## 26. SoilScout — soil sample lab pipeline

```text
APP_DESCRIPTION: A data pipeline for an agricultural soil-testing laboratory that processes spectrometer and wet-chemistry results for farmer-submitted samples. It validates instrument exports, computes nutrient indices and lime recommendations by crop plan, and generates agronomist-branded PDF reports.
TECH_STACK: Python + Prefect + pandas + PostgreSQL + WeasyPrint reports + SFTP instrument ingestion, self-hosted
APP_TYPE: data pipeline
LANGUAGE: Python
SCALE: ~3,500 samples/day in season, 12 instruments, ~400 MB/day results data
```

## 27. CastFrame — podcast transcription pipeline

```text
APP_DESCRIPTION: A data pipeline for a podcast hosting network that transcribes and enriches new episodes. It runs speech-to-text with speaker diarization, generates chapter markers and show-note drafts, and publishes searchable transcripts to each show's public page.
TECH_STACK: Python + Celery + WhisperX on GPU workers + PostgreSQL + S3 + Meilisearch, deployed on AWS with spot GPUs
APP_TYPE: data pipeline
LANGUAGE: Python
SCALE: ~800 episodes/day (~650 audio-hours), 4,200 shows, ~120 GB/day audio
```

## 28. CoolChain — cold-chain temperature monitoring

```text
APP_DESCRIPTION: A data pipeline for food and pharma distributors that monitors refrigerated trailers and warehouse zones via cellular temperature loggers. It detects excursions against product-specific thresholds, triggers escalating alerts, and compiles audit-ready temperature history per shipment.
TECH_STACK: Python + Kafka + Faust stream processing + TimescaleDB + PagerDuty/SMS alerting, deployed on AWS MSK
APP_TYPE: data pipeline
LANGUAGE: Python
SCALE: 7,200 loggers reporting every 5 min (~24 readings/sec), 1,500 shipments in transit daily
```

## 29. ParcelPeek — property comps API

```text
APP_DESCRIPTION: An API service for real-estate appraisers and lenders that returns comparable-sale analyses for a subject property. It matches recent sales by location, size, and condition adjustments, scores comp quality, and returns adjusted value ranges with supporting records.
TECH_STACK: FastAPI + PostgreSQL/PostGIS + Redis cache + nightly MLS ingest jobs, deployed on GCP Cloud Run
APP_TYPE: API service
LANGUAGE: Python
SCALE: ~70 req/sec peak, 6M property records, 90 lender integrations
```

## 30. LeaseLoft — small landlord property management

```text
APP_DESCRIPTION: A property-management web app for landlords with 5–100 units. Landlords track leases and rent ledgers, tenants pay rent and file maintenance requests with photos, and contractors receive work orders with scheduling and invoice capture.
TECH_STACK: Flask + SQLAlchemy + PostgreSQL + Stripe ACH + Celery + S3, deployed on Render
APP_TYPE: web app
LANGUAGE: Python
SCALE: 480 concurrent users on rent day, ~40 req/sec, 22,000 managed units
```

## 31. WardWatch — nurse shift scheduling

```text
APP_DESCRIPTION: A shift-scheduling web app for hospital nursing units. Unit managers build rosters against skill-mix and ratio rules, nurses bid on open shifts and swap with approval workflows, and the system flags fatigue-risk patterns like back-to-back nights.
TECH_STACK: Django + PostgreSQL + OR-Tools solver + Celery + HTMX + SSO/SAML, deployed on Azure
APP_TYPE: web app
LANGUAGE: Python
SCALE: 2,800 nurses across 60 units, ~50 req/sec at schedule release, ~12 GB data
```

## 32. RehabReel — physical therapy home programs

```text
APP_DESCRIPTION: A web app for physical therapy clinics that assigns video-guided home exercise programs. Therapists compose programs from an exercise library with sets and progressions, patients log completion and pain scores, and adherence dashboards drive plan adjustments between visits.
TECH_STACK: Django + PostgreSQL + S3/CloudFront video delivery + Celery reminders + HTMX, deployed on AWS
APP_TYPE: web app
LANGUAGE: Python
SCALE: 900 concurrent patients evenings, ~45 req/sec, ~600 GB exercise video
```

## 33. PlasmaQueue — blood donation center scheduling

```text
APP_DESCRIPTION: A donor-scheduling web app for a regional blood bank network. Donors book slots by donation type with eligibility-interval enforcement, centers manage bed capacity and mobile-drive calendars, and shortage alerts trigger targeted recall campaigns by blood type.
TECH_STACK: Django + PostgreSQL + Celery/Redis + Twilio SMS + HTMX, deployed on AWS
APP_TYPE: web app
LANGUAGE: Python
SCALE: 15 centers + 30 mobile drives/week, 600 concurrent users during shortage appeals, ~9 GB data
```

## 34. GridNudge — demand-response dispatch API

```text
APP_DESCRIPTION: An API service for an energy aggregator that dispatches demand-response events to commercial buildings. Utilities post curtailment calls; the service selects enrolled sites by forecast load and comfort constraints, sends setpoint commands to building systems, and meters verified kW reductions for settlement.
TECH_STACK: FastAPI + Celery + PostgreSQL + Redis + OpenADR/BACnet connectors, deployed on AWS
APP_TYPE: API service
LANGUAGE: Python
SCALE: 1,900 enrolled buildings, ~40 events/month, 5-min interval meter data (~55M readings/month)
```

## 35. MeterMuse — smart meter billing pipeline

```text
APP_DESCRIPTION: A data pipeline for a municipal water utility that turns smart-meter interval reads into monthly bills. It validates and estimates gaps in AMI data, detects continuous-flow leak signatures, applies tiered rate schedules, and exports bill files to the utility's print house.
TECH_STACK: Python + Apache Airflow + pandas + PostgreSQL + SFTP exchanges + Great Expectations validation, deployed on Azure
APP_TYPE: data pipeline
LANGUAGE: Python
SCALE: 145,000 meters at hourly reads (~3.5M reads/day), monthly billing run of 145k accounts
```

## 36. ForgeFlow — CNC job shop scheduler

```text
APP_DESCRIPTION: A desktop app for small CNC machine shops that schedules jobs across mills and lathes. Estimators load job travelers with routing steps, the scheduler sequences work against machine capacity and material arrival dates, and the shop floor screen shows live queue and due-date risk per machine.
TECH_STACK: Python + PySide6 + SQLite (shared network file) + APScheduler + matplotlib Gantt views, installed on shop PCs
APP_TYPE: desktop
LANGUAGE: Python
SCALE: 14 machines, ~250 active jobs, 8 concurrent desktop users
```

## 37. TalentTriage — resume screening pipeline

```text
APP_DESCRIPTION: A data pipeline for a high-volume staffing agency that screens inbound resumes against open requisitions. It parses resumes into structured profiles, scores skill and experience fit per req, flags knockout criteria, and syncs ranked shortlists into the agency's ATS with audit trails for review decisions.
TECH_STACK: Python + Prefect + spaCy + sentence-transformers + PostgreSQL + S3 + ATS webhook sync, deployed on GCP
APP_TYPE: data pipeline
LANGUAGE: Python
SCALE: ~18k resumes/day, 1,100 open requisitions, ~150 recruiters consuming shortlists
```

## 38. OnboardOwl — employee onboarding workflows

```text
APP_DESCRIPTION: An HR web app that orchestrates new-hire onboarding for distributed companies. HR builds role-based checklists spanning paperwork, equipment, and system access; tasks route to IT, payroll, and managers with due dates; new hires complete forms and e-signatures from a guided portal.
TECH_STACK: Django + PostgreSQL + Celery + DocuSign API + Slack notifications + HTMX, deployed on AWS
APP_TYPE: web app
LANGUAGE: Python
SCALE: 350 companies, ~2,400 active onboarding flows, ~35 req/sec peak
```

## 39. RiskRaster — property underwriting risk API

```text
APP_DESCRIPTION: An API service for home insurers that scores property risk at quote time. Given an address, it assembles wildfire, flood, roof-age, and crime layers from geospatial datasets, computes peril scores with explanatory factors, and returns underwriting guidance within the quote flow's latency budget.
TECH_STACK: FastAPI + PostgreSQL/PostGIS + rasterio + Redis cache + S3 data lake, deployed on AWS EKS
APP_TYPE: API service
LANGUAGE: Python
SCALE: ~200 req/sec peak, p95 < 300ms, 55M property footprints, 22 insurer clients
```

## 40. BondBeacon — municipal bond analytics pipeline

```text
APP_DESCRIPTION: A data pipeline for a fixed-income research desk that tracks the municipal bond market. It ingests EMMA disclosures and trade feeds, extracts financial ratios from issuer audit PDFs, computes spread and liquidity metrics per CUSIP, and refreshes analyst dashboards before market open.
TECH_STACK: Python + Dagster + pandas + pdfplumber + PostgreSQL + dbt + Metabase, deployed on AWS
APP_TYPE: data pipeline
LANGUAGE: Python
SCALE: ~1M CUSIPs tracked, ~45k trades/day ingested, dashboards due by 07:00 ET
```

## 41. MenuMint — restaurant menu engineering

```text
APP_DESCRIPTION: A web app for restaurant groups that analyzes menu profitability. It joins POS sales mix with recipe-level ingredient costs, classifies items into stars/dogs/puzzles/plowhorses, models price-change scenarios, and tracks margin impact after menu revisions.
TECH_STACK: Flask + SQLAlchemy + PostgreSQL + pandas + Celery POS imports + Chart.js, deployed on AWS Elastic Beanstalk
APP_TYPE: web app
LANGUAGE: Python
SCALE: 180 restaurant locations, ~90 concurrent users, nightly imports of ~250k POS line items
```

## 42. TarmacTempo — flight turnaround operations pipeline

```text
APP_DESCRIPTION: A data pipeline for an airport ground-handling company that tracks aircraft turnaround milestones. It fuses flight status feeds with ramp-crew scan events, predicts turnaround delays from missing milestones, and alerts duty managers when departures are at risk.
TECH_STACK: Python + Kafka + Faust + PostgreSQL + flight-data API ingestion + Grafana, deployed on Azure AKS
APP_TYPE: data pipeline
LANGUAGE: Python
SCALE: 480 turnarounds/day across 3 airports, ~60 milestone events/min at peak banks
```

## 43. RailRhythm — commuter rail delay prediction

```text
APP_DESCRIPTION: A data pipeline for a commuter rail operator that predicts knock-on delays across the network. It ingests GTFS-realtime positions and signal-block occupancy, models delay propagation per timetable, and feeds predicted arrival times to passenger displays and the dispatcher console.
TECH_STACK: Python + Apache Airflow + Kafka + LightGBM + TimescaleDB + Redis serving layer, deployed on-prem OpenShift
APP_TYPE: data pipeline
LANGUAGE: Python
SCALE: 610 trains/day, positions every 15s (~40 msgs/sec), predictions refreshed every 30s
```

## 44. ChorusBoard — community theater box office

```text
APP_DESCRIPTION: A ticketing web app for community theaters and performing-arts venues. Patrons pick seats from interactive seat maps, buy season subscriptions with renewal priority, and box-office staff handle exchanges, comps, and door lists with offline-tolerant check-in.
TECH_STACK: Django + PostgreSQL + Stripe + HTMX seat maps + Celery emails, deployed on Fly.io
APP_TYPE: web app
LANGUAGE: Python
SCALE: 45 venues, 850 concurrent users at on-sale peaks, ~65 req/sec, ~4 GB data
```

## 45. LotLore — auction house catalog API

```text
APP_DESCRIPTION: An API service for regional auction houses that manages lot catalogs and bidder data. Cataloguers submit lots with provenance, condition reports, and estimates; the service versions catalog revisions, syndicates lots to bidding platforms, and reconciles hammer results back to consignor statements.
TECH_STACK: FastAPI + PostgreSQL + S3 image pipeline + Celery syndication workers + Redis, deployed on AWS
APP_TYPE: API service
LANGUAGE: Python
SCALE: 70 auction houses, ~30k lots/month, ~25 req/sec, ~900 GB lot imagery
```

## 46. ArchiveAnt — museum collection digitization pipeline

```text
APP_DESCRIPTION: A data pipeline for a museum consortium digitizing collection objects. It ingests scanner and photo-station output, validates against imaging standards, extracts text from accession cards via OCR, links assets to collection records, and publishes derivatives to a public IIIF image server.
TECH_STACK: Python + Prefect + Tesseract + Pillow/pyvips + PostgreSQL + S3 + IIIF (Cantaloupe), deployed on-prem
APP_TYPE: data pipeline
LANGUAGE: Python
SCALE: ~2,000 objects/day digitized, 1.4M-object backlog, ~180 GB/day master TIFFs
```

## 47. ScholarSieve — systematic review screening

```text
APP_DESCRIPTION: A web app for medical research teams conducting systematic literature reviews. Teams import search results from PubMed and Embase, dual-screen abstracts with conflict resolution, apply ML-assisted relevance ranking to prioritize screening, and export PRISMA flow diagrams and inclusion logs.
TECH_STACK: Django + PostgreSQL + Celery + scikit-learn active learning + HTMX, deployed on university OpenStack
APP_TYPE: web app
LANGUAGE: Python
SCALE: 340 active reviews, ~28k abstracts screened/week, 1,900 registered reviewers
```

## 48. ScopeSlot — observatory telescope scheduling

```text
APP_DESCRIPTION: A web app for a university observatory network that schedules telescope time. Astronomers submit observing proposals with target lists and constraints, a scheduler packs nightly queues around moon phase and visibility windows, and completed exposures link back to proposals with data-quality flags.
TECH_STACK: Django + PostgreSQL + astropy/astroplan + Celery nightly scheduler + REST API, self-hosted at data center
APP_TYPE: web app
LANGUAGE: Python
SCALE: 6 telescopes, 420 active proposals, ~900 observations scheduled/night
```

## 49. QuakeQuilt — seismic network processing pipeline

```text
APP_DESCRIPTION: A data pipeline for a national seismological institute that processes continuous waveform data from field stations. It detects and associates seismic phases, locates events, computes magnitudes, and pushes reviewed event bulletins to the public catalog and early-alert partners.
TECH_STACK: Python + ObsPy + Kafka + SeisComP integration + PostgreSQL + S3 waveform archive, deployed on-prem HA cluster
APP_TYPE: data pipeline
LANGUAGE: Python
SCALE: 240 stations at 100 Hz continuous (~30 GB/day), ~80 located events/day, alerts within 90s
```

## 50. FloodFlag — river gauge flood alerting API

```text
APP_DESCRIPTION: An API service for county emergency managers that issues flood alerts from river and rain gauge networks. It ingests gauge telemetry, runs stage-forecast models against flood thresholds per basin, and delivers tiered alerts to emergency systems and a public subscription endpoint.
TECH_STACK: FastAPI + Celery + TimescaleDB + NOAA/USGS feed ingestion + SNS/SMS fan-out, deployed on AWS GovCloud
APP_TYPE: API service
LANGUAGE: Python
SCALE: 1,150 gauges polled every 5 min, 38 county subscribers, ~85k alert recipients
```

## 51. PowderPass — ski area pass and lift access

```text
APP_DESCRIPTION: A web app for independent ski areas selling season passes and day tickets. Guests buy passes with reloadable RFID media, gate scanners validate access against blackout and product rules, and operations dashboards show live skier visits and lift utilization.
TECH_STACK: Django + PostgreSQL + Stripe + Redis gate-validation cache + Celery + RFID gate API, deployed on AWS
APP_TYPE: web app
LANGUAGE: Python
SCALE: 11 ski areas, ~14k gate scans/hour peak, 190k pass holders, ~20 GB data
```

## 52. DiveDocket — dive shop certification tracking

```text
APP_DESCRIPTION: A web app for scuba dive shops that manages certification courses and dive trips. Instructors track student progress through confined-water and open-water requirements with digital sign-offs, shops roster boat trips with equipment assignments, and divers carry verifiable e-cards.
TECH_STACK: Flask + SQLAlchemy + PostgreSQL + Celery + QR-verifiable certificates + Stripe, deployed on DigitalOcean
APP_TYPE: web app
LANGUAGE: Python
SCALE: 130 dive shops, 9,500 active students, ~15 req/sec, ~6 GB data
```

## 53. PaddockPro — equestrian boarding management

```text
APP_DESCRIPTION: A web app for horse boarding stables and riding schools. Barn managers track each horse's feed chart, farrier and vet schedules, and turnout groups; owners book lessons and arena time; and monthly board invoices assemble from care add-ons automatically.
TECH_STACK: Django + PostgreSQL + HTMX + Celery reminders + Stripe invoicing, deployed on Render
APP_TYPE: web app
LANGUAGE: Python
SCALE: 210 stables, 6,800 horses managed, ~120 concurrent users, ~7 GB data
```

## 54. StockyardSync — livestock auction bidding

```text
APP_DESCRIPTION: A web app for regional livestock auction barns running hybrid in-person/online sales. Sellers consign lots with weights and health papers, remote bidders join live sales with real-time bid updates, and settlement generates seller checks and buyer invoices with brand-inspection records.
TECH_STACK: Django + PostgreSQL + Django Channels/WebSockets + Redis + Celery settlement jobs, deployed on AWS
APP_TYPE: web app
LANGUAGE: Python
SCALE: 26 auction barns, 1,400 concurrent bidders on sale days, ~200 bid events/sec peak
```

## 55. SiloSense — grain elevator inventory pipeline

```text
APP_DESCRIPTION: A data pipeline for a grain elevator cooperative that tracks inventory across silos. It ingests level-sensor and temperature-cable readings, scale tickets, and moisture tests; reconciles book-to-physical grain positions daily; and flags hot spots that risk spoilage.
TECH_STACK: Python + Prefect + MQTT/Modbus ingestion + TimescaleDB + pandas reconciliation + email/SMS alerts, on-prem
APP_TYPE: data pipeline
LANGUAGE: Python
SCALE: 9 elevator sites, 140 silos, sensor reads every 10 min, ~600 scale tickets/day at harvest
```

## 56. BrewBatch — brewery batch tracking desktop

```text
APP_DESCRIPTION: A desktop app for craft breweries that tracks batches from grain to package. Brewers log mash and fermentation readings against recipe targets, manage tank assignments and yeast generations, and export TTB-compliant production records at month end.
TECH_STACK: Python + PySide6 + SQLite with Litestream replication + matplotlib fermentation charts, installed on brewhouse PCs
APP_TYPE: desktop
LANGUAGE: Python
SCALE: 1 brewery per install, ~45 batches/month, 12 tanks, 5 concurrent users
```

## 57. CrateDigger — used vinyl pricing API

```text
APP_DESCRIPTION: An API service for independent record stores that prices used vinyl at the counter. Staff scan a barcode or search a pressing; the service matches the exact pressing variant, aggregates recent marketplace sale prices, and returns condition-adjusted buy and sell price suggestions.
TECH_STACK: FastAPI + PostgreSQL + Redis cache + nightly marketplace scrape/ingest workers + Meilisearch, deployed on Hetzner
APP_TYPE: API service
LANGUAGE: Python
SCALE: 520 store clients, ~25 req/sec, 11M pressing records, nightly ingest of ~300k sales
```

## 58. CartCompass — cart abandonment analytics pipeline

```text
APP_DESCRIPTION: A data pipeline for mid-market e-commerce brands that analyzes checkout funnel abandonment. It ingests clickstream and cart events, sessionizes shopper journeys, attributes drop-off to shipping cost, payment friction, or stock issues, and feeds segmented win-back audiences to email platforms.
TECH_STACK: Python + Dagster + Kafka + dbt + ClickHouse + reverse-ETL to Klaviyo/Braze, deployed on GCP
APP_TYPE: data pipeline
LANGUAGE: Python
SCALE: 38 brands, ~9M events/day, hourly audience syncs, 90-day event retention (~1.1 TB)
```

## 59. ParcelPulse — last-mile delivery tracking API

```text
APP_DESCRIPTION: An API service for regional courier companies that unifies last-mile tracking. Driver apps post GPS and scan events; the service maintains per-parcel state machines, computes live ETAs with traffic, and serves branded tracking pages and webhook updates to shipper systems.
TECH_STACK: FastAPI + PostgreSQL + Redis geo-indexes + Kafka event log + OSRM ETAs, deployed on AWS EKS
APP_TYPE: API service
LANGUAGE: Python
SCALE: ~140k parcels/day, 2,100 drivers, ~350 events/sec peak, 60 shipper webhook consumers
```

## 60. HangarHawk — general aviation maintenance tracking

```text
APP_DESCRIPTION: A web app for general-aviation maintenance shops and aircraft owners. Mechanics log squawks and sign off work orders against aircraft records, the system tracks AD compliance and component times against limits, and owners see upcoming inspections like annuals and pitot-static checks.
TECH_STACK: Django + PostgreSQL + Celery AD-feed ingestion + PDF logbook exports + HTMX, deployed on AWS Lightsail
APP_TYPE: web app
LANGUAGE: Python
SCALE: 95 maintenance shops, 3,400 aircraft tracked, ~60 concurrent users, ~11 GB data
```

## 61. SiteStack — construction daily log platform

```text
APP_DESCRIPTION: A web app for general contractors that captures construction daily logs. Superintendents record crew counts, weather, deliveries, and delays with photos from the field; project managers roll logs into owner reports; and disputes pull time-stamped evidence by date and trade.
TECH_STACK: Django + PostgreSQL + S3 photo storage + Celery report generation + PWA offline capture, deployed on AWS
APP_TYPE: web app
LANGUAGE: Python
SCALE: 240 active projects, 1,100 field users, ~9k photos/day, ~2 TB media
```

## 62. PipePatrol — water main leak detection pipeline

```text
APP_DESCRIPTION: A data pipeline for water utilities that detects distribution-main leaks from acoustic loggers and district meter flows. It correlates night-flow anomalies with acoustic events, ranks leak candidates by estimated loss rate, and dispatches investigation orders to field crews.
TECH_STACK: Python + Apache Airflow + TimescaleDB + scipy signal processing + PostGIS + work-order API integration, deployed on Azure
APP_TYPE: data pipeline
LANGUAGE: Python
SCALE: 3,800 acoustic loggers, 92 district meters at 15-min intervals, ~35 leak candidates ranked/week
```

## 63. MopRoute — commercial cleaning crew routing API

```text
APP_DESCRIPTION: An API service for janitorial companies that builds nightly crew routes across client buildings. It sequences sites by service frequency, access windows, and crew skills; pushes routes to crew phones with geofenced check-in; and reports verified service times to client portals.
TECH_STACK: FastAPI + OR-Tools + PostgreSQL/PostGIS + Redis + Celery route builds + push notifications, deployed on GCP
APP_TYPE: API service
LANGUAGE: Python
SCALE: 85 cleaning companies, 6,200 serviced buildings, ~950 crews routed nightly
```

## 64. GrantGrove — nonprofit grant lifecycle tracking

```text
APP_DESCRIPTION: A web app for nonprofit development teams that manages the grant lifecycle. Teams track funder prospects and deadlines, collaborate on proposal drafts with attachment versioning, log award terms and reporting schedules, and see pipeline forecasts by program area.
TECH_STACK: Django + PostgreSQL + Celery deadline digests + S3 attachments + HTMX, deployed on Fly.io
APP_TYPE: web app
LANGUAGE: Python
SCALE: 420 nonprofit organizations, ~1,900 active grant applications, ~25 req/sec
```

## 65. FoiaFlow — public records request management

```text
APP_DESCRIPTION: A web app for state agencies that manages public records (FOIA) requests. Intake staff triage and assign requests with statutory clocks, records officers gather and redact responsive documents with review layers, and requesters track status and receive releases through a public portal.
TECH_STACK: Django + PostgreSQL + S3 + Celery deadline tracking + PDF redaction tooling (pikepdf) + audit logging, deployed on AWS GovCloud
APP_TYPE: web app
LANGUAGE: Python
SCALE: 65 agencies, ~4,200 open requests, ~800 GB responsive documents, statutory clocks per state
```

## 66. CurbCycle — recycling collection route pipeline

```text
APP_DESCRIPTION: A data pipeline for a municipal waste authority that optimizes recycling collection. It ingests truck GPS traces, bin RFID lifts, and contamination camera flags; rebalances weekly routes as participation shifts; and reports diversion tonnage and contamination hotspots by neighborhood.
TECH_STACK: Python + Prefect + PostGIS + OR-Tools arc routing + pandas + Superset dashboards, deployed on Azure
APP_TYPE: data pipeline
LANGUAGE: Python
SCALE: 68 trucks, 210k serviced bins, ~140k lift events/week, weekly route rebuild
```

## 67. TimberTally — forestry cruise data desktop

```text
APP_DESCRIPTION: A desktop app for consulting foresters that processes timber cruise data offline in the field. Foresters enter plot tallies by species and diameter class, the app computes volume and value estimates with regional taper equations, and stands roll up into appraisal reports synced when back online.
TECH_STACK: Python + PySide6 + SQLite + numpy volume equations + reportlab PDF appraisals + rugged-tablet install
APP_TYPE: desktop
LANGUAGE: Python
SCALE: single forester per install, ~120 plots/day entered, 350 stands per project database
```

## 68. OreOracle — mine haul fleet telemetry pipeline

```text
APP_DESCRIPTION: A data pipeline for an open-pit mining operator that monitors haul-truck fleets. It ingests payload, cycle-time, and engine telemetry; benchmarks loader-truck pairings and haul-road segments; and flags underloaded cycles and abnormal fuel burn for dispatch and maintenance action.
TECH_STACK: Python + Kafka + Spark (PySpark) + Delta Lake on S3 + Airflow + Grafana, deployed on AWS EMR
APP_TYPE: data pipeline
LANGUAGE: Python
SCALE: 130 haul trucks, ~2,900 cycles/day, telemetry at 1 Hz (~11M records/day)
```

## 69. WellWhisper — oil well production reporting pipeline

```text
APP_DESCRIPTION: A data pipeline for a small oil-and-gas operator that automates daily production reporting. It ingests SCADA tank levels and meter runs from field sites, allocates production to wells per lease agreements, reconciles against truck run tickets, and files regulatory production reports by state deadline.
TECH_STACK: Python + Apache Airflow + pandas + PostgreSQL + SCADA historian connector + state e-filing exports, deployed on-prem
APP_TYPE: data pipeline
LANGUAGE: Python
SCALE: 640 wells across 210 leases, hourly SCADA polls, monthly regulatory filings in 3 states
```

## 70. TrialTrellis — clinical trial supply forecasting

```text
APP_DESCRIPTION: A data pipeline for a contract research organization that forecasts clinical trial drug supply. It models enrollment curves per site, simulates kit demand against expiry dates and titration rules, and recommends depot-to-site shipments that avoid stockouts without wasting short-dated stock.
TECH_STACK: Python + Prefect + Monte Carlo simulation (numpy) + PostgreSQL + IRT system API ingestion + Power BI outputs, deployed on Azure
APP_TYPE: data pipeline
LANGUAGE: Python
SCALE: 42 active trials, 1,850 sites, weekly simulation runs of 10,000 scenarios per trial
```

## 71. ScanScrub — DICOM anonymization CLI

```text
APP_DESCRIPTION: A CLI tool for medical imaging researchers that de-identifies DICOM studies before sharing. It strips and remaps patient identifiers per configurable profiles, detects burned-in text on pixel data with OCR and masks it, and emits a crosswalk file and audit log for the honest-broker workflow.
TECH_STACK: Python CLI (Typer) + pydicom + Tesseract burned-in text detection + SQLite crosswalk store, distributed via pipx
APP_TYPE: CLI
LANGUAGE: Python
SCALE: batch runs of ~50k DICOM instances (~80 GB) per study export, 30 research-site users
```

## 72. LogLoom — log redaction CLI

```text
APP_DESCRIPTION: A CLI tool for DevOps teams that redacts secrets and PII from log archives before they reach vendors or lower environments. It streams through compressed log files applying detection rules for tokens, emails, card numbers, and custom patterns, and reports redaction counts per rule for compliance evidence.
TECH_STACK: Python CLI (Click) + regex/detect-secrets rulepacks + streaming gzip/zstd processing + YAML config, distributed via PyPI
APP_TYPE: CLI
LANGUAGE: Python
SCALE: ~200 GB log archive per run at ~150 MB/s, 400 installed seats across teams
```

## 73. PolyglotPack — i18n string extraction CLI

```text
APP_DESCRIPTION: A CLI tool for product teams that manages translation strings across codebases. It extracts translatable strings from Python, JS, and template files; diffs catalogs against previous releases; round-trips XLIFF with translation vendors; and fails CI when hardcoded strings or missing locales slip in.
TECH_STACK: Python CLI (Typer) + Babel + tree-sitter parsers + XLIFF/PO round-trip + CI-friendly JSON reports, distributed via PyPI
APP_TYPE: CLI
LANGUAGE: Python
SCALE: repos up to 900k LOC, 28 target locales, ~12k managed strings per project
```

## 74. MigrateMender — SQL migration linter CLI

```text
APP_DESCRIPTION: A CLI tool for backend teams that lints database migration files before deploy. It parses Alembic and raw SQL migrations, flags table-locking operations, missing concurrent index flags, and destructive changes without backfill steps, and enforces team policies as CI gates with severity overrides.
TECH_STACK: Python CLI (Click) + sqlglot AST analysis + Alembic introspection + TOML policy config + GitHub Actions annotations
APP_TYPE: CLI
LANGUAGE: Python
SCALE: ~600 repos in CI, ~1,400 migration checks/day, rule catalog of 55 checks
```

## 75. InvoiceIron — invoice PDF batch generator CLI

```text
APP_DESCRIPTION: A CLI tool for small accounting teams and SaaS back offices that batch-generates invoice PDFs. It reads billing rows from CSV or a database query, renders branded invoices from Jinja templates with tax and currency rules, emails them via configured SMTP or API providers, and writes a delivery manifest.
TECH_STACK: Python CLI (Typer) + Jinja2 + WeasyPrint + SQLAlchemy sources + SMTP/SendGrid delivery, distributed via pipx
APP_TYPE: CLI
LANGUAGE: Python
SCALE: monthly runs of ~40k invoices, ~3 invoices rendered/sec, 250 operator installs
```

## 76. SubSync — subtitle alignment CLI

```text
APP_DESCRIPTION: A CLI tool for video localization vendors that fixes subtitle timing at scale. It aligns SRT/VTT files against the actual audio track using speech activity detection, corrects drift and offset, validates reading-speed and line-length rules per platform spec, and batch-converts between caption formats.
TECH_STACK: Python CLI (Click) + ffmpeg + Silero VAD (ONNX) + pysubs2 + parallel worker pool, distributed via PyPI
APP_TYPE: CLI
LANGUAGE: Python
SCALE: batches of ~2,000 episodes, ~90 min audio processed/min/worker, 15 platform spec profiles
```

## 77. LicenseLantern — OSS license compliance CLI

```text
APP_DESCRIPTION: A CLI tool for engineering compliance teams that audits open-source license obligations. It resolves dependency trees across Python, npm, and Go projects, matches licenses with SPDX identifiers including vendored code scans, flags copyleft conflicts against a company policy file, and emits SBOM and attribution documents.
TECH_STACK: Python CLI (Typer) + package-manager resolvers + scancode-toolkit + SPDX/CycloneDX output + policy YAML
APP_TYPE: CLI
LANGUAGE: Python
SCALE: ~350 scanned repos, dependency trees up to 4,000 packages, weekly org-wide audit run
```

## 78. SeedSprout — test data seeding CLI

```text
APP_DESCRIPTION: A CLI tool for QA and development teams that generates realistic seed data for test environments. It introspects database schemas, generates referentially consistent fake data with locale-aware names and addresses, respects declared uniqueness and distribution hints, and can subset-and-anonymize production snapshots.
TECH_STACK: Python CLI (Typer) + SQLAlchemy reflection + Faker + topological FK ordering + YAML seed profiles, distributed via PyPI
APP_TYPE: CLI
LANGUAGE: Python
SCALE: schemas up to 450 tables, ~2M rows generated/run, 600 downloads/week
```

## 79. DriftDetect — infrastructure config drift CLI

```text
APP_DESCRIPTION: A CLI tool for platform teams that audits configuration drift across server fleets. It gathers live system state over SSH (packages, services, sysctls, config file hashes), diffs against a declared baseline repo, ranks drift by risk category, and opens tickets for hosts that diverge.
TECH_STACK: Python CLI (Click) + asyncssh parallel collection + JSON state snapshots + Git baseline diffing + Jira API, distributed via pipx
APP_TYPE: CLI
LANGUAGE: Python
SCALE: fleets of ~1,800 hosts scanned in under 10 min, nightly scheduled runs, 12 baseline profiles
```

## 80. ClipCask — transcode farm controller CLI

```text
APP_DESCRIPTION: A CLI tool for post-production houses that drives a video transcode farm. Operators submit watch-folder or manifest jobs; the tool fans encodes out to worker nodes with codec ladders per delivery spec, verifies output with automated QC checks, and retries or quarantines failed renders.
TECH_STACK: Python CLI (Typer) + Redis job queue + ffmpeg workers + MediaInfo QC probes + S3/LTO output targets
APP_TYPE: CLI
LANGUAGE: Python
SCALE: 22 worker nodes, ~450 transcode jobs/day, ~8 TB/day throughput
```

## 81. MicroMark — microscopy annotation desktop

```text
APP_DESCRIPTION: A desktop app for histology research groups that annotates whole-slide microscopy images. Researchers pan and zoom gigapixel slides, draw region and cell-level annotations with class labels, track inter-annotator agreement, and export COCO-format datasets for model training.
TECH_STACK: Python + PySide6 + OpenSlide tiled rendering + SQLite annotation store + COCO/GeoJSON export, installed on lab workstations
APP_TYPE: desktop
LANGUAGE: Python
SCALE: slides up to 4 GB each, ~600 slides per project, 25 annotators across 4 labs
```

## 82. GaugeGlass — instrument bench control desktop

```text
APP_DESCRIPTION: A desktop app for electronics test engineers that orchestrates bench instruments. Engineers script sweeps across power supplies, DMMs, and oscilloscopes over VISA/SCPI, watch live measurement plots, and save runs with full instrument-settings provenance for repeatable characterization reports.
TECH_STACK: Python + PySide6 + PyVISA + pyqtgraph live plotting + HDF5 run storage, installed on lab bench PCs
APP_TYPE: desktop
LANGUAGE: Python
SCALE: 40 bench installs, up to 12 instruments per bench, sweeps logging 5k readings/sec
```

## 83. WaveWarden — broadcast loudness compliance desktop

```text
APP_DESCRIPTION: A desktop app for radio and TV stations that checks program audio against loudness regulations. Engineers drop in program files or capture live feeds, the app measures EBU R128/ATSC A/85 loudness and true peak, renders compliance timelines with violation markers, and produces signed compliance PDFs for regulators.
TECH_STACK: Python + PySide6 + ffmpeg/pyloudnorm measurement + SQLite history + reportlab compliance PDFs, installed in master control
APP_TYPE: desktop
LANGUAGE: Python
SCALE: 75 station installs, ~300 program files checked/day/station, files up to 6 hours long
```

## 84. FareFerret — airfare deal detection pipeline

```text
APP_DESCRIPTION: A data pipeline for a flight-deals subscription service that hunts mistake fares and route discounts. It polls fare-search APIs across seeded route pairs, compares against rolling price baselines per route and season, verifies deals are bookable, and publishes curated alerts to regional subscriber segments.
TECH_STACK: Python + Celery beat pollers + PostgreSQL + Redis + fare API connectors + Mailgun segmented sends, deployed on AWS
APP_TYPE: data pipeline
LANGUAGE: Python
SCALE: 18k monitored route pairs polled 4×/day, ~140 published deals/week, 260k subscribers
```

## 85. ChildChirp — daycare parent communication

```text
APP_DESCRIPTION: A web app for daycare centers that keeps parents in the loop. Teachers log meals, naps, diaper changes, and photos per child from a room tablet view; parents get a live daily feed and end-of-day summaries; and directors manage ratios, sign-in/out records, and incident reports.
TECH_STACK: Django + PostgreSQL + S3 photos + Celery digest emails + PWA tablet interface, deployed on Heroku
APP_TYPE: web app
LANGUAGE: Python
SCALE: 380 daycare centers, 21,000 enrolled children, ~70 req/sec during pickup hours
```

## 86. ElderEase — home care visit verification API

```text
APP_DESCRIPTION: An API service for home-care agencies that provides electronic visit verification (EVV). Caregiver apps check in and out at client homes with GPS attestation, the service validates visits against authorized care plans and flags anomalies, and agencies export state-compliant EVV records for Medicaid claims.
TECH_STACK: FastAPI + PostgreSQL/PostGIS + Redis + Celery + state EVV aggregator integrations, deployed on AWS
APP_TYPE: API service
LANGUAGE: Python
SCALE: 160 agencies, ~48k visits verified/day, ~60 req/sec, 7-year record retention
```

## 87. WillowRest — funeral home arrangement management

```text
APP_DESCRIPTION: A web app for family-owned funeral homes that manages arrangements from first call to service. Directors record decedent details and family wishes, coordinate caskets, permits, and obituary drafts through checklists, schedule chapel and vehicle resources, and produce itemized statements compliant with the FTC Funeral Rule.
TECH_STACK: Django + PostgreSQL + Celery + document templates (docxtpl) + resource calendar + HTMX, deployed on AWS Lightsail
APP_TYPE: web app
LANGUAGE: Python
SCALE: 140 funeral homes, ~1,100 active cases, ~35 concurrent users, ~14 GB data
```

## 88. TollTally — toll transaction reconciliation pipeline

```text
APP_DESCRIPTION: A data pipeline for a toll road authority that reconciles gantry transactions to payments. It matches transponder reads and license-plate camera events to accounts, resolves plate-read disputes with image review queues, nets interoperability settlements with neighboring toll agencies, and generates violation notices for unmatched trips.
TECH_STACK: Python + Apache Airflow + Spark (PySpark) + PostgreSQL + S3 image store + agency settlement file exchange, deployed on AWS
APP_TYPE: data pipeline
LANGUAGE: Python
SCALE: ~1.9M transactions/day across 34 gantries, 98.2% auto-match target, monthly settlement with 5 agencies
```

## 89. PollenPost — allergy forecast API

```text
APP_DESCRIPTION: An API service for health and weather apps that serves localized pollen forecasts. It blends certified pollen-counter station data with phenology and weather models to produce species-level (tree/grass/weed) indices per grid cell, and exposes daily forecasts and historical series by coordinate.
TECH_STACK: FastAPI + xarray/numpy gridded models + TimescaleDB + Redis edge cache + station data ingestion jobs, deployed on GCP
APP_TYPE: API service
LANGUAGE: Python
SCALE: ~450 req/sec peak in spring, 1 km grid over 6 countries, 85 app integrations
```

## 90. SpinSpanner — gym equipment maintenance API

```text
APP_DESCRIPTION: An API service for gym chains that manages fitness equipment maintenance. Club staff scan asset QR codes to report faults with photos, the service schedules preventive maintenance from usage-hour telemetry, dispatches technician work orders with parts suggestions, and tracks downtime cost per club.
TECH_STACK: FastAPI + PostgreSQL + Celery PM scheduling + S3 + equipment IoT telemetry webhooks, deployed on Azure Container Apps
APP_TYPE: API service
LANGUAGE: Python
SCALE: 620 clubs, 74,000 tracked machines, ~1,900 work orders/week, ~20 req/sec
```

## 91. HerdHealth — dairy herd analytics pipeline

```text
APP_DESCRIPTION: A data pipeline for dairy cooperatives that monitors herd health and milk performance. It ingests milking-parlor yield data, activity-collar readings, and milk-quality lab results; detects early mastitis and heat events per cow; and delivers action lists to herd managers each milking shift.
TECH_STACK: Python + Prefect + parlor system connectors + TimescaleDB + scikit-learn detection models + farmer mobile-web reports, deployed on AWS
APP_TYPE: data pipeline
LANGUAGE: Python
SCALE: 290 member farms, 118,000 cows, 2–3 milkings/day (~300k yield records/day)
```

## 92. TutorTempo — online tutoring marketplace

```text
APP_DESCRIPTION: A marketplace web app connecting parents with vetted tutors for school subjects and test prep. Parents search by subject, level, and availability; booking handles trial lessons, recurring slots, and reschedules across time zones; and tutors run sessions with integrated whiteboard links, packages, and payouts.
TECH_STACK: Django + PostgreSQL + Stripe Connect payouts + Celery + Redis + HTMX search, deployed on AWS ECS
APP_TYPE: web app
LANGUAGE: Python
SCALE: 8,500 active tutors, 3,200 sessions/day, 700 concurrent users on weekday evenings
```

## 93. QuizQuarry — exam item banking API

```text
APP_DESCRIPTION: An API service for certification bodies and test publishers that manages secure exam item banks. Item writers submit questions through review workflows with psychometric metadata, the service assembles exam forms against blueprints with exposure controls, and delivers encrypted form packages to proctoring platforms.
TECH_STACK: FastAPI + PostgreSQL + item-response-theory scoring jobs (numpy) + Celery + KMS-encrypted packages, deployed on AWS
APP_TYPE: API service
LANGUAGE: Python
SCALE: 45 certification programs, 380k banked items, ~900 exam forms assembled/month
```

## 94. PressPulse — media monitoring pipeline

```text
APP_DESCRIPTION: A data pipeline for PR agencies that monitors client mentions across news and broadcast sources. It ingests licensed news feeds and broadcast transcripts, deduplicates syndicated copies, scores sentiment and prominence per mention, and compiles morning coverage briefs per client with spokesperson quote tracking.
TECH_STACK: Python + Dagster + Kafka + spaCy/transformers NER and sentiment + OpenSearch + PostgreSQL, deployed on GCP
APP_TYPE: data pipeline
LANGUAGE: Python
SCALE: ~1.4M articles/day ingested, 320 client brief configurations, briefs due by 06:30 local
```

## 95. QuayQueue — container terminal slot booking API

```text
APP_DESCRIPTION: An API service for a container terminal that manages truck appointment slots. Trucking companies book gate windows tied to container availability and customs status, the service levels demand across hours to cut queue times, and gate systems validate arrivals against bookings with no-show penalty tracking.
TECH_STACK: FastAPI + PostgreSQL + Redis slot inventory + Kafka TOS event ingestion + EDI/API trucker integrations, deployed on Azure
APP_TYPE: API service
LANGUAGE: Python
SCALE: ~3,600 truck visits/day, 240 trucking companies, ~50 req/sec booking peak at slot release
```

## 96. GlazeGuard — paint line visual QC desktop

```text
APP_DESCRIPTION: A desktop app for an appliance factory's paint line that performs camera-based finish inspection. It grabs frames from line cameras at inspection stations, runs defect models for runs, orange peel, and thin coverage, displays operator pass/fail verdicts with defect overlays, and logs reject causes for the quality team.
TECH_STACK: Python + PySide6 + OpenCV + ONNX Runtime defect models + GigE camera SDK + PostgreSQL quality logs, on factory floor PCs
APP_TYPE: desktop
LANGUAGE: Python
SCALE: 3 inspection stations, 22 parts/min line speed, ~9,500 inspections/shift
```

## 97. MapMender — address geocoding cleanup CLI

```text
APP_DESCRIPTION: A CLI tool for data teams that repairs messy address data in bulk. It parses and standardizes free-text addresses, validates against national address files, geocodes with fallback provider chains and confidence scoring, and outputs match-tier reports so analysts can review low-confidence rows before loading.
TECH_STACK: Python CLI (Typer) + libpostal parsing + provider-chain geocoding + DuckDB batch processing + CSV/Parquet I/O
APP_TYPE: CLI
LANGUAGE: Python
SCALE: batches up to 25M addresses, ~4k addresses/sec parsed, match-rate reporting per run
```

## 98. FinFarm — aquaculture water quality pipeline

```text
APP_DESCRIPTION: A data pipeline for salmon farm operators that monitors sea-pen water quality and fish welfare. It ingests dissolved-oxygen, temperature, and salinity probes with feed-camera appetite signals, predicts low-oxygen events from tide and weather forecasts, and adjusts feeding schedules while alerting site managers.
TECH_STACK: Python + Prefect + MQTT probe ingestion + TimescaleDB + LightGBM forecasting + feed-system API + SMS alerts, deployed on Azure
APP_TYPE: data pipeline
LANGUAGE: Python
SCALE: 14 farm sites, 96 pens, probes every 60s (~130 readings/min), ~2.1M fish under monitoring
```

## 99. MoldMinder — injection molding OEE desktop

```text
APP_DESCRIPTION: A desktop app for plastics factories that tracks injection-molding machine effectiveness. It reads cycle counts and alarm states from press PLCs, lets operators tag downtime reasons at the machine, computes live OEE (availability, performance, quality) per press and shift, and exports Pareto reports for continuous-improvement meetings.
TECH_STACK: Python + Tkinter kiosk UI + pycomm3/OPC-UA PLC polling + SQLite with nightly server sync + openpyxl reports, on press-side PCs
APP_TYPE: desktop
LANGUAGE: Python
SCALE: 26 presses across 2 plants, cycle events every ~30s per press, 3 shifts/day logged
```

## 100. LensLedger — optical lab order tracking

```text
APP_DESCRIPTION: A web app for optical retailers and their lens labs that tracks eyewear orders end to end. Opticians enter prescriptions and frame/lens selections with automatic validity checks, labs update grind-and-coat job stages with breakage tracking, and stores see promised dates, remake rates, and patient-ready notifications.
TECH_STACK: Django + PostgreSQL + Celery status notifications + REST API for lab machines + HTMX order boards, deployed on AWS
APP_TYPE: web app
LANGUAGE: Python
SCALE: 340 retail locations, 6 lab facilities, ~5,200 orders/day, ~45 req/sec
```
