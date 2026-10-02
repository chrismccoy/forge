# C# Blueprint Types — Copy-Paste Input Sets

Copy a fenced block into the prompt as-is, or swap individual fields.

## 1. BiteRight — dental practice management

```text
APP_DESCRIPTION: A practice-management web app for multi-chair dental offices. Front desk manages appointments with recall reminders, dentists chart treatments on interactive tooth diagrams, billing staff generate insurance claims and patient statements, and the practice tracks production per provider.
TECH_STACK: ASP.NET Core + Blazor Server + Entity Framework Core + SQL Server, deployed on Azure App Service
APP_TYPE: web app
LANGUAGE: C#
SCALE: 120 concurrent users, ~25 req/sec, ~30 GB data
```

## 2. TillPoint — boutique point of sale

```text
APP_DESCRIPTION: A desktop point-of-sale app for independent clothing boutiques. Staff ring up sales with barcode scanning and size/color variants, process returns and exchanges, manage layaways and gift cards, and sync daily sales and stock levels to a cloud backend when online.
TECH_STACK: WPF (.NET 8) + SQLite local store + offline-first sync to ASP.NET Core API + receipt printer/cash drawer integration
APP_TYPE: desktop
LANGUAGE: C#
SCALE: 1-3 registers per store, 200 stores, offline-tolerant, <5 GB local data per store
```

## 3. PermitPath — municipal permit portal

```text
APP_DESCRIPTION: A permit-application web app for a city building department. Residents and contractors submit building/electrical/plumbing permit applications with document uploads, pay fees online, track review status across departments, and schedule inspections; reviewers manage queues and issue approvals.
TECH_STACK: ASP.NET Core MVC + Entity Framework Core + PostgreSQL + Azure Blob storage + GOV payment gateway
APP_TYPE: web app
LANGUAGE: C#
SCALE: 300 concurrent users, ~35 req/sec, ~100 GB documents
```

## 4. FleetFix — fleet maintenance API

```text
APP_DESCRIPTION: A fleet-maintenance API service for companies running vehicle fleets. It ingests odometer and fault-code telemetry, schedules preventive maintenance by usage thresholds, manages work orders with parts and labor tracking, and reports cost-per-mile and downtime per vehicle.
TECH_STACK: ASP.NET Core Web API + Entity Framework Core + SQL Server + Azure Service Bus + telematics webhooks
APP_TYPE: API service
LANGUAGE: C#
SCALE: ~150 req/sec, 25,000 vehicles, ~80 GB data
```

## 5. StaffSeed — AD user provisioning CLI

```text
APP_DESCRIPTION: A CLI tool for enterprise IT teams that automates Active Directory user lifecycle from HR data. It reads new-hire/change/termination records from an HR CSV or API export, creates or updates AD accounts, applies group memberships from role-mapping rules, generates onboarding reports, and runs in dry-run mode by default.
TECH_STACK: .NET 8 console app (System.CommandLine) + LDAP/Microsoft.Graph APIs + YAML role-mapping config, distributed as signed internal tool
APP_TYPE: CLI
LANGUAGE: C#
SCALE: single operator per run, 15,000 managed accounts, nightly scheduled runs
```

## 6. GavelLive — real-time auction platform

```text
APP_DESCRIPTION: A real-time auction web app for a regional auction house. Bidders join timed and live-streamed auctions, place bids with soft-close anti-sniping extensions, set maximum proxy bids, and pay invoices online; auctioneers manage lots, reserves, and live bid calling.
TECH_STACK: ASP.NET Core + SignalR + Entity Framework Core + PostgreSQL + Redis backplane + Stripe, deployed on Azure
APP_TYPE: web app
LANGUAGE: C#
SCALE: 2,500 concurrent bidders at marquee auctions, ~400 req/sec peak, ~15 GB data
```

## 7. LineSight — manufacturing OEE pipeline

```text
APP_DESCRIPTION: A data pipeline for a packaging manufacturer that computes OEE (overall equipment effectiveness) across 12 production lines. It ingests PLC cycle counts, downtime events, and reject counts via OPC UA, classifies downtime reasons, computes shift-level availability/performance/quality metrics, and feeds plant dashboards and morning-meeting reports.
TECH_STACK: .NET 8 workers + OPC UA ingestion + TimescaleDB + Grafana + MQTT, deployed on plant-floor edge servers
APP_TYPE: data pipeline
LANGUAGE: C#
SCALE: 12 lines × ~50 signals/sec (~600 events/sec), ~3 GB/day, 3-year retention
```

## 8. ClaimCrest — health insurance claims adjudication

```text
APP_DESCRIPTION: A claims-adjudication API service for a regional health insurer. It validates incoming 837 professional and institutional claims against member eligibility and benefit plans, applies fee schedules and prior-authorization rules, auto-adjudicates clean claims, and routes exceptions to examiner work queues with denial-reason codes.
TECH_STACK: ASP.NET Core Web API + EDI X12 parsing + Entity Framework Core + SQL Server + Azure Service Bus + rules engine
APP_TYPE: API service
LANGUAGE: C#
SCALE: ~450,000 claims/month, ~90 req/sec peak, ~600 GB data
```

## 9. WardWatch — hospital bed capacity board

```text
APP_DESCRIPTION: A bed-management web app for a 400-bed community hospital. Charge nurses view real-time bed status by unit, house supervisors assign incoming ED and transfer patients against isolation and telemetry requirements, and environmental services get automated turnover tasks when patients discharge.
TECH_STACK: ASP.NET Core + Blazor Server + SignalR + Entity Framework Core + SQL Server + HL7 ADT feed integration
APP_TYPE: web app
LANGUAGE: C#
SCALE: 250 concurrent clinical users, ~40 req/sec, ~2,000 ADT messages/day
```

## 10. ScriptSafe — retail pharmacy dispensing

```text
APP_DESCRIPTION: A desktop dispensing app for a 40-store regional pharmacy chain. Pharmacists verify prescriptions with drug-interaction and allergy checks, technicians fill and label with barcode confirmation, the system bills PBMs in real time via NCPDP claims, and controlled-substance dispensing reports to the state PDMP.
TECH_STACK: WPF (.NET 8) + SQL Server + NCPDP telecom claim integration + label printer/scanner hardware + central ASP.NET Core sync API
APP_TYPE: desktop
LANGUAGE: C#
SCALE: 40 stores, 3-6 workstations per store, ~9,000 prescriptions/day chain-wide
```

## 11. LoanLattice — commercial loan origination

```text
APP_DESCRIPTION: A loan-origination web app for a mid-size commercial bank. Relationship managers structure term loans and lines of credit, credit analysts spread borrower financials and compute covenant ratios, underwriters route deals through tiered approval workflows, and closers generate document checklists tied to collateral records.
TECH_STACK: ASP.NET Core MVC + Entity Framework Core + SQL Server + Azure AD authentication + document generation via OpenXML
APP_TYPE: web app
LANGUAGE: C#
SCALE: 180 concurrent users, ~1,200 active deals, ~250 GB documents
```

## 12. VaultVerve — portfolio rebalancing engine

```text
APP_DESCRIPTION: A portfolio-management API service for a wealth advisory firm. It ingests custodian position and transaction files nightly, computes drift against model portfolios, generates tax-aware rebalancing trade lists with wash-sale checks, and exposes household-level performance and fee billing data to the advisor portal.
TECH_STACK: ASP.NET Core Web API + Dapper + SQL Server + Hangfire nightly jobs + custodian SFTP file ingestion
APP_TYPE: API service
LANGUAGE: C#
SCALE: 32,000 accounts, ~5 million positions revalued nightly, ~60 req/sec daytime
```

## 13. AuditAnchor — internal audit workpapers

```text
APP_DESCRIPTION: A workpaper-management web app for corporate internal audit departments. Auditors build risk-and-control matrices, attach testing evidence with tickmarks, track findings through management-response and remediation cycles, and generate SOX 404 sign-off packages with full review-note history.
TECH_STACK: ASP.NET Core + Razor Pages + Entity Framework Core + PostgreSQL + Azure Blob evidence storage + Azure AD SSO
APP_TYPE: web app
LANGUAGE: C#
SCALE: 90 concurrent auditors, ~800 audits/year, ~400 GB evidence files
```

## 14. TaxTrellis — county property assessment

```text
APP_DESCRIPTION: A property tax assessment web app for a county assessor's office. Appraisers maintain parcel characteristics and sketch data, run mass-appraisal models against comparable sales, process homestead and veteran exemptions, and manage appeal hearings with before/after value documentation.
TECH_STACK: ASP.NET Core MVC + Entity Framework Core + SQL Server + GIS parcel map integration (Esri REST) + SSRS reporting
APP_TYPE: web app
LANGUAGE: C#
SCALE: 140 concurrent users, 310,000 parcels, ~120 GB data
```

## 15. CourtCue — court docket scheduling

```text
APP_DESCRIPTION: A docket-management web app for a state circuit court. Clerks schedule hearings across judges and courtrooms with conflict detection, attorneys receive electronic notice and file continuance requests, and the court publishes daily dockets with speedy-trial deadline tracking for criminal cases.
TECH_STACK: ASP.NET Core + Blazor Server + Entity Framework Core + SQL Server + e-filing system integration + quartz-scheduled notices
APP_TYPE: web app
LANGUAGE: C#
SCALE: 220 concurrent users, ~45,000 active cases, ~90 GB data
```

## 16. GrantGrove — state grant lifecycle portal

```text
APP_DESCRIPTION: A grants-management web app for a state agency distributing federal pass-through funds. Nonprofits apply against published funding opportunities, reviewers score applications on weighted rubrics, awarded grantees submit quarterly expenditure reports with budget-line validation, and staff track drawdowns against federal award balances.
TECH_STACK: ASP.NET Core MVC + Entity Framework Core + PostgreSQL + Azure Blob uploads + Azure B2C for external applicants
APP_TYPE: web app
LANGUAGE: C#
SCALE: 500 concurrent users at deadline peaks, 4,200 active grants, ~200 GB documents
```

## 17. WeldWise — weld inspection QA

```text
APP_DESCRIPTION: A mobile inspection app for certified weld inspectors at structural steel fabricators. Inspectors pull weld maps for each assembly, record visual and UT inspection results against AWS D1.1 acceptance criteria, photograph defects with annotation, and sync signed inspection reports to the shop's quality system.
TECH_STACK: .NET MAUI (Android/iOS tablets) + SQLite offline store + ASP.NET Core sync API + Azure Blob photo storage
APP_TYPE: mobile
LANGUAGE: C#
SCALE: 85 inspectors across 6 fabrication shops, ~1,400 inspections/day, offline-tolerant
```

## 18. DieDock — tool and die job tracking

```text
APP_DESCRIPTION: A shop-floor desktop app for a tool-and-die job shop. Estimators quote dies from material and machining-hour breakdowns, machinists clock onto jobs at CNC and EDM stations, the shop tracks actual-versus-quoted hours per die component, and tryout results feed engineering change records.
TECH_STACK: WPF (.NET 8) + Entity Framework Core + SQL Server on LAN + barcode job-traveler scanning + Crystal-replacement reporting via QuestPDF
APP_TYPE: desktop
LANGUAGE: C#
SCALE: 45 shop-floor and office workstations, ~300 active jobs, ~20 GB data
```

## 19. KilnKeeper — ceramic kiln telemetry

```text
APP_DESCRIPTION: A data pipeline for a technical-ceramics manufacturer monitoring 18 tunnel and batch kilns. It ingests thermocouple profiles, gas flow, and cart position data, validates firing curves against product recipes, alerts on zone deviations that predict cracked ware, and archives complete firing records for aerospace customer audits.
TECH_STACK: .NET 8 worker services + Modbus/OPC UA ingestion + TimescaleDB + MQTT alerting + Grafana dashboards
APP_TYPE: data pipeline
LANGUAGE: C#
SCALE: 18 kilns × ~120 signals at 1 Hz (~2,100 points/sec), ~5 GB/day, 7-year retention
```

## 20. RouteRaven — LTL freight load planning

```text
APP_DESCRIPTION: A load-planning API service for a less-than-truckload carrier with 28 terminals. It rates shipments against tariff and accessorial rules, assigns freight to linehaul schedules by cube and weight, optimizes pup-trailer loading sequence by delivery stop order, and publishes dock worker load manifests.
TECH_STACK: ASP.NET Core Web API + Dapper + SQL Server + RabbitMQ events + OR-Tools-based optimization workers
APP_TYPE: API service
LANGUAGE: C#
SCALE: ~200 req/sec, 14,000 shipments/day, 28 terminals, ~150 GB data
```

## 21. DockDial — warehouse dock scheduling

```text
APP_DESCRIPTION: A dock-appointment web app for a grocery distribution center network. Inbound carriers book delivery slots against door capacity and commodity restrictions, the DC overrides slots for hot loads, gate check-in feeds live yard status, and detention disputes resolve from timestamped arrival/departure records.
TECH_STACK: ASP.NET Core + Blazor Server + Entity Framework Core + PostgreSQL + SignalR yard board + carrier email/SMS notifications
APP_TYPE: web app
LANGUAGE: C#
SCALE: 9 distribution centers, ~1,100 appointments/day, 350 concurrent users
```

## 22. FrostFleet — cold-chain trailer monitoring

```text
APP_DESCRIPTION: A cold-chain monitoring pipeline for a refrigerated carrier hauling produce and frozen foods. It ingests reefer unit temperature, setpoint, door, and fuel telemetry from cellular trackers, detects excursions against commodity-specific thresholds, alerts dispatch before loads spoil, and generates FSMA-compliant temperature history reports per shipment.
TECH_STACK: .NET 8 worker services + Azure Event Hubs + Azure Functions alerting + TimescaleDB + carrier TMS webhook integration
APP_TYPE: data pipeline
LANGUAGE: C#
SCALE: 1,800 trailers reporting every 5 minutes (~6 events/sec), ~1.5 GB/day, 2-year retention
```

## 23. StowSmart — container vessel stowage planning

```text
APP_DESCRIPTION: A desktop stowage-planning app for vessel planners at a container terminal operator. Planners load BAPLIE files, drag containers into bay/row/tier slots with real-time stability and lashing-force calculations, enforce dangerous-goods segregation rules, and export crane work sequences to terminal operating systems.
TECH_STACK: WPF (.NET 8) with 3D bay visualization (HelixToolkit) + BAPLIE/EDIFACT parsing + local SQLite + TOS integration API
APP_TYPE: desktop
LANGUAGE: C#
SCALE: 30 planners across 4 terminals, vessels up to 14,000 TEU, ~200 stowage plans/month
```

## 24. BellBook — K-12 attendance and scheduling

```text
APP_DESCRIPTION: A student attendance and bell-schedule web app for a 22-school public district. Teachers take period attendance with tardy and early-dismissal codes, attendance clerks process excuse notes and truancy letters, counselors build master schedules with section balancing, and the state extract job files daily ADA reports.
TECH_STACK: ASP.NET Core MVC + Entity Framework Core + SQL Server + Azure AD for staff SSO + state SIS extract jobs via Hangfire
APP_TYPE: web app
LANGUAGE: C#
SCALE: 1,900 teachers, 24,000 students, ~150 req/sec at first-period peak
```

## 25. QuizQuarry — university assessment delivery

```text
APP_DESCRIPTION: A secure exam-delivery web app for a university's testing center and online programs. Faculty author question banks with randomized pools and formula variants, students take proctored timed exams with autosave and lockdown-browser checks, and graders review flagged responses with rubric scoring that syncs to the LMS via LTI.
TECH_STACK: ASP.NET Core + Blazor WebAssembly + Entity Framework Core + PostgreSQL + Redis session state + LTI 1.3 integration
APP_TYPE: web app
LANGUAGE: C#
SCALE: 4,000 concurrent examinees at finals peak, ~900 req/sec peak, ~50 GB data
```

## 26. BursarBridge — tuition billing engine

```text
APP_DESCRIPTION: A tuition-billing API service for a private university system. It assesses charges from registration events using fee schedules by program and residency, applies financial aid disbursements and third-party sponsor contracts, manages installment payment plans with late-fee rules, and feeds 1098-T generation and general-ledger postings.
TECH_STACK: ASP.NET Core Web API + Entity Framework Core + SQL Server + Azure Service Bus registration events + payment gateway integration
APP_TYPE: API service
LANGUAGE: C#
SCALE: 38,000 students across 3 campuses, ~120 req/sec at term start, ~90 GB data
```

## 27. GridGauge — substation telemetry analytics

```text
APP_DESCRIPTION: A telemetry pipeline for an electric distribution cooperative monitoring 64 substations. It ingests SCADA point data for transformer load, voltage, and breaker status, computes feeder loading against seasonal ratings, flags transformers trending toward overload, and feeds outage-management and load-forecasting systems.
TECH_STACK: .NET 8 worker services + DNP3/ICCP ingestion adapters + Kafka + TimescaleDB + Grafana, deployed in a NERC-segmented network
APP_TYPE: data pipeline
LANGUAGE: C#
SCALE: 64 substations × ~400 points at 2-second scan (~12,800 points/sec), ~40 GB/day raw
```

## 28. PanelPulse — solar farm inverter monitoring

```text
APP_DESCRIPTION: A monitoring pipeline for an independent power producer operating 23 utility-scale solar sites. It collects string-level inverter production, tracker position, and weather-station data, computes expected-versus-actual generation from irradiance models, ranks underperforming combiner boxes for field crews, and produces monthly PPA settlement reports.
TECH_STACK: .NET 8 workers + Modbus TCP site gateways + Azure IoT Hub + TimescaleDB + Power BI settlement reporting
APP_TYPE: data pipeline
LANGUAGE: C#
SCALE: 23 sites, ~110,000 tags at 1-minute resolution, ~8 GB/day, 25-year data retention
```

## 29. RigRoster — oilfield crew rotation scheduling

```text
APP_DESCRIPTION: A mobile crew-scheduling app for a drilling contractor running 14-and-14 rotations across West Texas rigs. Crew pushers confirm hitch assignments and call out replacements for no-shows, hands view upcoming rotations and submit time-off requests, and HR tracks certifications (H2S, well control) that block assignment when expired.
TECH_STACK: .NET MAUI (Android/iOS) + ASP.NET Core API + Entity Framework Core + SQL Server + push notifications via Azure Notification Hubs
APP_TYPE: mobile
LANGUAGE: C#
SCALE: 1,600 field employees, 38 active rigs, ~200 schedule changes/day
```

## 30. MeterMuse — water utility AMI ingestion

```text
APP_DESCRIPTION: A meter-data pipeline for a municipal water utility with advanced metering infrastructure. It ingests hourly interval reads from 190,000 endpoints, validates and estimates gaps using VEE rules, detects continuous-flow leak signatures and reversed meters, and delivers billing determinants to the CIS on cycle schedules.
TECH_STACK: .NET 8 worker services + AMI head-end SFTP/REST ingestion + Azure Service Bus + SQL Server partitioned tables + SSIS-replacement transform jobs
APP_TYPE: data pipeline
LANGUAGE: C#
SCALE: 190,000 meters × 24 reads/day (~4.6M reads/day), ~2 GB/day, 10-year retention
```

## 31. ShelfScript — retail planogram compliance

```text
APP_DESCRIPTION: A mobile merchandising app for field reps auditing planogram compliance in convenience stores. Reps photograph shelf sets, mark out-of-stocks and wrong-facings against the assigned planogram, capture competitor pricing, and submit visit reports that roll up to brand-level compliance scores for CPG clients.
TECH_STACK: .NET MAUI (Android) + SQLite offline queue + ASP.NET Core API + Azure Blob photo storage + PostgreSQL
APP_TYPE: mobile
LANGUAGE: C#
SCALE: 700 field reps, ~5,500 store visits/day, ~40,000 photos/day
```

## 32. ReturnRail — e-commerce returns processing

```text
APP_DESCRIPTION: A returns and RMA API service for mid-market e-commerce brands. Shoppers initiate returns against order line items with policy-driven eligibility windows, the service issues carrier labels and tracks packages inbound, warehouse operators disposition items (restock, refurbish, destroy), and refunds trigger automatically on inspection pass.
TECH_STACK: ASP.NET Core minimal APIs + Entity Framework Core + PostgreSQL + MassTransit/RabbitMQ + carrier label APIs (UPS/FedEx) + Stripe refunds
APP_TYPE: API service
LANGUAGE: C#
SCALE: ~300 req/sec, 22,000 returns/day across 40 merchant tenants, ~200 GB data
```

## 33. LoyaLoop — grocery loyalty and offers engine

```text
APP_DESCRIPTION: A loyalty API service for a 130-store grocery chain. It accrues points from POS basket data in real time, evaluates personalized offer eligibility at scan time so discounts apply at the register, manages fuel-points redemption partnerships, and segments members for weekly digital coupon drops.
TECH_STACK: ASP.NET Core Web API + Redis for real-time balance lookups + SQL Server + Kafka POS transaction stream + offer rules engine
APP_TYPE: API service
LANGUAGE: C#
SCALE: 1.1 million members, ~850 req/sec at Saturday peak, ~500 GB transaction history
```

## 34. HoistHawk — tower crane telemetry

```text
APP_DESCRIPTION: A telemetry pipeline for a crane rental company monitoring tower cranes on high-rise sites. It ingests load moment, trolley position, wind speed, and anti-collision zone events from crane PLCs, alerts site safety managers when wind or overload thresholds trip, and produces per-operator lift logs for incident investigations.
TECH_STACK: .NET 8 worker services + cellular edge gateways (MQTT) + Azure IoT Hub + TimescaleDB + Twilio SMS alerting
APP_TYPE: data pipeline
LANGUAGE: C#
SCALE: 240 cranes reporting at 1 Hz (~240 events/sec), ~1 GB/day, 5-year retention
```

## 35. PourPlan — ready-mix concrete dispatch

```text
APP_DESCRIPTION: A dispatch desktop app for a ready-mix concrete producer with 11 batch plants. Dispatchers schedule orders against plant capacity and truck availability, batch operators send mix designs to plant controls, drivers get sequenced tickets with pour times, and the system tracks returned concrete and washout for each load.
TECH_STACK: WPF (.NET 8) + SQL Server + batch-plant control system integration + GPS truck tracking feed + SignalR dispatch board
APP_TYPE: desktop
LANGUAGE: C#
SCALE: 11 plants, 95 mixer trucks, ~600 loads/day, 25 dispatcher/operator workstations
```

## 36. PaveTrack — road paving project tracking

```text
APP_DESCRIPTION: A project-tracking web app for a highway paving contractor. Project engineers log daily placement quantities by station and lift against bid items, plant reports reconcile asphalt tonnage shipped versus placed, density and smoothness test results attach to lots for DOT acceptance, and progress feeds monthly pay estimates.
TECH_STACK: ASP.NET Core MVC + Entity Framework Core + SQL Server + Azure Blob for test reports + DOT e-construction export
APP_TYPE: web app
LANGUAGE: C#
SCALE: 60 concurrent users, 45 active projects, ~35,000 tons placed/week in season
```

## 37. PlatPoint — land surveying job management

```text
APP_DESCRIPTION: A desktop job-management app for a civil/land surveying firm. Office staff manage boundary and ALTA survey jobs from request to recorded plat, crews' field notes and point files attach to jobs, drafters track plat revisions through county review comments, and the firm searches its 30-year archive of prior surveys by parcel.
TECH_STACK: WinUI 3 (.NET 8) + SQLite + network file store indexing + county parcel GIS lookups + PDF plat rendering
APP_TYPE: desktop
LANGUAGE: C#
SCALE: 35 users, ~1,100 jobs/year, 90,000 archived survey records
```

## 38. HydrantHub — fire hydrant inspection

```text
APP_DESCRIPTION: A mobile inspection app for municipal fire departments conducting annual hydrant inspections and flow tests. Firefighters locate assigned hydrants on a map, record static/residual pressure and flow readings, log defects like stuck caps or drainage failures that dispatch water-department work orders, and update NFPA color coding from computed flow class.
TECH_STACK: .NET MAUI (Android tablets) + SQLite offline + ASP.NET Core API + PostgreSQL/PostGIS + water utility work-order webhook
APP_TYPE: mobile
LANGUAGE: C#
SCALE: 6 departments, 21,000 hydrants, ~120 inspections/day in season, offline-tolerant
```

## 39. PulsePost — EMS patient care reporting

```text
APP_DESCRIPTION: A mobile ePCR app for a county ambulance service. Medics document patient assessments, vitals, medications, and procedures during transport with NEMSIS-compliant fields, capture ECG strips from monitor Bluetooth, obtain signatures for refusals and billing authorization, and submit reports that flow to hospitals and the state trauma registry.
TECH_STACK: .NET MAUI (rugged Android tablets) + SQLite offline + ASP.NET Core API + SQL Server + NEMSIS v3 state export + cardiac monitor BLE integration
APP_TYPE: mobile
LANGUAGE: C#
SCALE: 42 ambulances, ~180 runs/day, 380 medics, offline-first with store-and-forward sync
```

## 40. EvidEdge — police evidence chain of custody

```text
APP_DESCRIPTION: An evidence-management web app for a metro police department's property room. Officers pre-log seized items from the field with barcoded packaging, property technicians check items into shelved locations, every transfer for lab analysis or court records a custody event, and disposition workflows handle auction, destruction, and return with case-status checks.
TECH_STACK: ASP.NET Core MVC + Entity Framework Core + SQL Server + barcode/RFID scanning + CJIS-compliant hosting + audit logging
APP_TYPE: web app
LANGUAGE: C#
SCALE: 1,900 sworn officers, 240,000 items in custody, ~350 intake events/day
```

## 41. VisitVine — home health visit verification

```text
APP_DESCRIPTION: A mobile scheduling and EVV app for a home health agency. Aides and nurses see daily visit routes, clock in and out with GPS-verified electronic visit verification, document care tasks against each patient's plan of care, and flag missed visits so schedulers backfill; verified visits feed Medicaid EVV aggregators for billing.
TECH_STACK: .NET MAUI (Android/iOS) + ASP.NET Core API + Entity Framework Core + SQL Server + state EVV aggregator integration (HHAeXchange/Sandata)
APP_TYPE: mobile
LANGUAGE: C#
SCALE: 850 caregivers, ~3,200 visits/day, 4,100 active patients
```

## 42. TheraThread — physical therapy documentation

```text
APP_DESCRIPTION: A clinical documentation web app for a 15-clinic outpatient physical therapy group. Therapists document evaluations and daily notes with flowsheet-based exercise tracking, plans of care route for physician e-signature, front desk manages authorization visit counts before they exhaust, and compliance dashboards flag Medicare progress notes coming due.
TECH_STACK: ASP.NET Core + Blazor Server + Entity Framework Core + SQL Server + eFax integration for physician signatures + clearinghouse billing export
APP_TYPE: web app
LANGUAGE: C#
SCALE: 15 clinics, 130 therapists, ~1,900 visits/day, ~45 GB data
```

## 43. AssayLine — clinical laboratory LIMS

```text
APP_DESCRIPTION: A LIMS API service for a regional reference laboratory. It accessions specimens with barcode-driven container tracking, routes orders to chemistry, hematology, and micro analyzers via HL7 interfaces, applies auto-verification rules with delta checks against patient history, and releases results to ordering physicians and the state reportable-disease registry.
TECH_STACK: ASP.NET Core Web API + Entity Framework Core + SQL Server + HL7v2 analyzer interfaces (NHapi) + Azure Service Bus + auto-verification rules engine
APP_TYPE: API service
LANGUAGE: C#
SCALE: 28,000 specimens/day, ~110 analyzer interfaces, ~250 messages/sec peak, ~1 TB data
```

## 44. VaxVault — state immunization registry

```text
APP_DESCRIPTION: A state immunization information system API. Provider EHRs submit vaccination records via HL7 VXU messages with patient deduplication and MOGE matching, school nurses and pharmacies query consolidated histories with forecast recommendations from CDC schedules, and inventory decrements track publicly funded vaccine lots for VFC accountability.
TECH_STACK: ASP.NET Core Web API + HL7v2/FHIR endpoints + PostgreSQL + patient matching engine + Azure Government hosting
APP_TYPE: API service
LANGUAGE: C#
SCALE: 6.2 million patient records, ~180,000 messages/day, ~90 req/sec query peak
```

## 45. WagePress — multi-state payroll engine

```text
APP_DESCRIPTION: A payroll-calculation API service embedded in an HR platform for franchise restaurant groups. It computes gross-to-net across multi-state and local tax jurisdictions, handles tipped-wage credits and overtime blended rates, processes garnishments with priority ordering, and produces ACH files, tax deposits, and quarterly 941/state filings.
TECH_STACK: ASP.NET Core Web API + Entity Framework Core + SQL Server + tax engine rule tables with versioned effective dates + NACHA file generation + Hangfire
APP_TYPE: API service
LANGUAGE: C#
SCALE: 2,400 employer groups, 310,000 employees paid biweekly, ~95 req/sec on payroll days
```

## 46. PensionPier — public pension administration

```text
APP_DESCRIPTION: A pension-administration web app for a statewide public employee retirement system. Employers submit payroll contribution reports with error-level validation, members model retirement benefit estimates across service-credit scenarios, retirement counselors process applications with beneficiary elections, and the system runs monthly annuity payrolls with tax withholding and insurance deductions.
TECH_STACK: ASP.NET Core MVC + Entity Framework Core + SQL Server + batch annuity payroll via Hangfire + member self-service portal with Azure B2C
APP_TYPE: web app
LANGUAGE: C#
SCALE: 410,000 members and annuitants, 1,300 participating employers, ~500 concurrent users
```

## 47. TitleTide — title and escrow closing

```text
APP_DESCRIPTION: A closing-workflow web app for a multi-branch title insurance agency. Escrow officers open orders from purchase contracts, order title searches and clear requirement exceptions, build ALTA settlement statements with proration calculators, coordinate wire-verified disbursements, and issue policies with premium remittance to underwriters.
TECH_STACK: ASP.NET Core + Blazor Server + Entity Framework Core + SQL Server + document generation (OpenXML) + wire fraud verification service integration
APP_TYPE: web app
LANGUAGE: C#
SCALE: 14 branches, 160 users, ~900 open orders, ~28 closings/day
```

## 48. ValuVista — residential appraisal writing

```text
APP_DESCRIPTION: A desktop report-writing app for independent residential appraisers. Appraisers import MLS comparables and public-record data, build sales-comparison grids with adjustment support, sketch floor plans with ANSI-compliant GLA calculation, embed geocoded photos, and deliver UAD-compliant XML plus PDF reports to lender portals.
TECH_STACK: WPF (.NET 8) + SQLite local database + MLS/public-record data imports + sketch engine + UCDP/EAD delivery integration
APP_TYPE: desktop
LANGUAGE: C#
SCALE: 3,800 licensed appraiser seats, ~2-4 reports/appraiser/week, single-user local data
```

## 49. LeaseLoom — commercial lease administration

```text
APP_DESCRIPTION: A lease-administration web app for a REIT managing office and industrial portfolios. Lease admins abstract executed leases into rent schedules with escalations and CPI adjustments, the system bills CAM/tax/insurance recoveries with annual reconciliations against actual expenses, critical dates like renewals and rent reviews alert asset managers, and ASC 842 schedules export to the GL.
TECH_STACK: ASP.NET Core MVC + Entity Framework Core + SQL Server + Yardi/GL integration jobs + document abstraction workspace with Azure Blob
APP_TYPE: web app
LANGUAGE: C#
SCALE: 9.5 million sq ft, 2,700 active leases, 85 concurrent users
```

## 50. QuorumQuill — HOA governance portal

```text
APP_DESCRIPTION: A community-management web app for homeowners association management companies. Homeowners pay assessments and submit architectural review requests, boards vote on ARC applications and violations with quorum tracking, managers run violation escalation letters with photo evidence, and annual meeting proxies and ballots tally electronically.
TECH_STACK: ASP.NET Core + Razor Pages + Entity Framework Core + PostgreSQL + Stripe ACH assessments + document/CCR library with Azure Blob
APP_TYPE: web app
LANGUAGE: C#
SCALE: 340 associations, 92,000 homeowner accounts, ~180 concurrent users
```

## 51. BondBeacon — municipal bond compliance

```text
APP_DESCRIPTION: A post-issuance compliance web app for municipal bond issuers and their advisors. Finance staff track continuing-disclosure obligations with EMMA filing deadlines, monitor private-business-use of bond-financed facilities against IRS limits, manage arbitrage rebate computation schedules, and store transcripts and covenants per issue with maturity-level debt service schedules.
TECH_STACK: ASP.NET Core MVC + Entity Framework Core + SQL Server + EMMA filing reminders via Hangfire + Excel debt-schedule import/export (ClosedXML)
APP_TYPE: web app
LANGUAGE: C#
SCALE: 240 issuer clients, 3,100 outstanding bond issues, 60 concurrent users
```

## 52. FixFeeder — FIX order routing gateway

```text
APP_DESCRIPTION: A FIX gateway API service for a broker-dealer routing equity and options orders. It normalizes client FIX 4.2/4.4 sessions, applies pre-trade risk checks (fat-finger limits, buying power, restricted lists), routes to exchange and ATS destinations with smart failover, and journals every message for OATS/CAT regulatory reporting.
TECH_STACK: .NET 8 + QuickFIX/n + ASP.NET Core admin API + Redis risk-limit cache + SQL Server message journal + low-latency in-memory order book
APP_TYPE: API service
LANGUAGE: C#
SCALE: ~3,500 orders/sec peak, 180 client sessions, sub-2ms internal latency budget, ~80 GB/day journals
```

## 53. RiskRudder — overnight VaR batch

```text
APP_DESCRIPTION: A market-risk data pipeline for a regional bank's trading book. It snapshots end-of-day positions across rates, FX, and credit desks, revalues portfolios against 5 years of historical scenario shocks, computes 1-day and 10-day VaR with backtesting exceptions, and delivers desk-level risk reports and limit-breach alerts before the 6 AM risk meeting.
TECH_STACK: .NET 8 worker services + parallelized valuation grid + SQL Server + market data vendor feeds (Refinitiv) + Control-M-triggered batch orchestration
APP_TYPE: data pipeline
LANGUAGE: C#
SCALE: 85,000 positions, 1,260 historical scenarios, nightly 4-hour batch window, ~2 TB scenario store
```

## 54. FraudFerret — card fraud scoring

```text
APP_DESCRIPTION: A real-time fraud-scoring API service for a card issuer processor. It scores authorization requests in-line using velocity counters, merchant risk profiles, and geo-impossibility checks, returns approve/decline/challenge decisions within the network timeout, manages case queues for analyst review, and learns from confirmed fraud dispositions.
TECH_STACK: ASP.NET Core minimal APIs + Redis velocity counters + Kafka event stream + ML.NET scoring models + SQL Server case management
APP_TYPE: API service
LANGUAGE: C#
SCALE: ~2,200 authorizations/sec peak, p99 under 40ms, 9 million active cards
```

## 55. KycKestrel — KYC/AML screening

```text
APP_DESCRIPTION: A compliance-screening API service for fintechs and community banks. It screens customers at onboarding against OFAC/sanctions, PEP, and adverse-media lists with fuzzy name matching, re-screens the full customer base on nightly list updates, manages alert adjudication with four-eyes review, and files SAR-supporting audit trails.
TECH_STACK: ASP.NET Core Web API + Elasticsearch fuzzy matching + PostgreSQL + nightly list ingestion workers + Azure Service Bus
APP_TYPE: API service
LANGUAGE: C#
SCALE: 60 institution tenants, 4.5 million screened identities, ~70 req/sec, nightly rescreen of full base
```

## 56. ATMAtlas — ATM fleet health monitoring

```text
APP_DESCRIPTION: A monitoring pipeline for an independent ATM deployer operating machines in convenience stores and casinos. It ingests status events (cash levels, card reader faults, jam codes) from NDC/DDC terminal streams, predicts cash-outs from withdrawal velocity to schedule armored car replenishment, and dispatches technician tickets with fault-specific parts lists.
TECH_STACK: .NET 8 worker services + terminal event ingestion + SQL Server + Azure Service Bus + field service ticketing integration + cash forecasting jobs
APP_TYPE: data pipeline
LANGUAGE: C#
SCALE: 7,400 ATMs, ~90 events/sec, ~4,000 replenishments/month, ~120 GB data
```

## 57. TellerTempo — credit union teller workstation

```text
APP_DESCRIPTION: A teller-line desktop app for a multi-branch credit union. Tellers process deposits, withdrawals, transfers, and loan payments against the core banking system with real-time balancing, cash drawers reconcile with denomination-level counts, check scanners capture items for Check 21 clearing, and supervisors approve overrides above authority limits.
TECH_STACK: WPF (.NET 8) + core banking system API integration + check scanner/receipt printer/cash recycler hardware SDKs + local encrypted store
APP_TYPE: desktop
LANGUAGE: C#
SCALE: 19 branches, 140 teller workstations, ~11,000 transactions/day
```

## 58. RemitRook — cross-border remittance processing

```text
APP_DESCRIPTION: A remittance API service powering agent storefronts and a consumer app for corridors into Latin America and Southeast Asia. It quotes locked FX rates with corridor-specific fees, runs sender/receiver compliance checks against transaction limits, orchestrates payouts through bank, wallet, and cash-pickup partner networks, and reconciles partner settlements daily.
TECH_STACK: ASP.NET Core Web API + PostgreSQL + MassTransit/RabbitMQ payout orchestration + FX rate feed integration + partner payout APIs + Hangfire reconciliation
APP_TYPE: API service
LANGUAGE: C#
SCALE: ~85,000 transfers/day across 22 corridors, ~140 req/sec peak, ~300 GB data
```

## 59. InvoiceIbis — AP invoice OCR pipeline

```text
APP_DESCRIPTION: An accounts-payable ingestion pipeline for a shared-services center processing supplier invoices for 60 subsidiaries. It captures invoices from email and supplier portals, extracts header and line data with OCR plus template rules, matches against PO and goods-receipt records (3-way match), routes exceptions to approvers by tolerance rules, and posts matched vouchers to two different ERPs.
TECH_STACK: .NET 8 worker services + Azure AI Document Intelligence + Azure Service Bus + SQL Server + ERP posting adapters (SAP/Dynamics) + approval web queue
APP_TYPE: data pipeline
LANGUAGE: C#
SCALE: ~9,000 invoices/day, 60 subsidiaries, 82% touchless match rate target, ~350 GB document store
```

## 60. BidBirch — construction bid estimating

```text
APP_DESCRIPTION: A desktop estimating app for commercial general contractors. Estimators perform on-screen takeoff from PDF plan sheets with scaled measurement tools, build cost estimates from assemblies and crew-based labor production rates, level subcontractor quotes side by side by scope, and roll estimates into bid proposals with alternates and unit prices.
TECH_STACK: WPF (.NET 8) + PDF rendering/measurement engine + SQLite estimate database + cost database subscriptions import + Excel bid-form export (ClosedXML)
APP_TYPE: desktop
LANGUAGE: C#
SCALE: 2,200 estimator seats across 400 contractor firms, estimates up to 12,000 line items
```

## 61. SnagSparrow — construction punch list

```text
APP_DESCRIPTION: A mobile punch-list app for commercial construction closeout. Superintendents walk floors pinning defects on plan sheets with photos and responsible-subcontractor assignment, subs receive filtered lists and mark items complete with proof photos, architects verify corrections during back-check walks, and closeout reports export per unit or floor for owner turnover.
TECH_STACK: .NET MAUI (iOS/Android tablets) + SQLite offline + ASP.NET Core API + PostgreSQL + plan sheet tiling service + Azure Blob photos
APP_TYPE: mobile
LANGUAGE: C#
SCALE: 180 active projects, 4,500 users, ~9,000 punch items opened/day at peak, offline-tolerant
```

## 62. ScaffoldScout — scaffold rental inventory

```text
APP_DESCRIPTION: A rental-operations web app for a scaffolding supply and erection company. Branch staff reserve frames, planks, and system scaffold components against yard inventory, delivery tickets deplete stock to job sites with per-day rental billing, erection crews log handover certificates and weekly inspections, and off-rent counts reconcile returned versus lost components for damage invoicing.
TECH_STACK: ASP.NET Core MVC + Entity Framework Core + SQL Server + barcode yard scanning + recurring rental billing engine + QuickBooks integration
APP_TYPE: web app
LANGUAGE: C#
SCALE: 7 branches, 1.4 million component units tracked, 620 active job sites, 90 concurrent users
```

## 63. SiloSense — grain elevator inventory

```text
APP_DESCRIPTION: A data pipeline for a farm cooperative running 14 grain elevators. It ingests scale tickets, moisture and test-weight readings from probe systems, and bin temperature cable data, computes shrink-adjusted inventory positions by commodity and bin, alerts on hot spots that risk spoilage, and feeds daily grain position reports for the merchandising desk's hedge decisions.
TECH_STACK: .NET 8 worker services + scale/probe system integrations + temperature cable telemetry (Modbus) + SQL Server + Power BI position dashboards
APP_TYPE: data pipeline
LANGUAGE: C#
SCALE: 14 elevators, 22 million bushels capacity, ~1,100 scale tickets/day at harvest, ~9,000 temperature sensors
```

## 64. HerdHorizon — dairy herd management

```text
APP_DESCRIPTION: A desktop herd-management app for large dairy operations. Herdsmen record health events, breeding, and pregnancy checks per cow, milking parlor data imports daily yields and conductivity flags for mastitis screening, the system schedules synchronization protocols and dry-off lists, and DHIA test-day results benchmark production against herd goals.
TECH_STACK: WPF (.NET 8) + SQL Server Express on-farm + parlor system file imports (DelPro/AfiMilk) + RFID ear-tag reader integration + veterinary protocol scheduler
APP_TYPE: desktop
LANGUAGE: C#
SCALE: 480 dairy customers, herds of 500-8,000 cows, ~40 events/cow/year
```

## 65. FurFile — veterinary practice management

```text
APP_DESCRIPTION: A practice-management web app for companion-animal veterinary clinics. Front desk books appointments across DVM and tech schedules, doctors chart SOAP notes with weight-based dosing calculators, in-house lab and imaging results attach to patient records, reminders drive vaccine and dental recalls, and invoicing bundles services with controlled-drug log deductions.
TECH_STACK: ASP.NET Core + Blazor Server + Entity Framework Core + PostgreSQL + in-house lab analyzer integrations + SMS/email reminder service
APP_TYPE: web app
LANGUAGE: C#
SCALE: 320 clinics, 2,900 concurrent users at peak, ~14,000 appointments/day
```

## 66. SprayScribe — spray application compliance

```text
APP_DESCRIPTION: A mobile record-keeping app for agricultural custom applicators and farm managers. Applicators log pesticide applications with EPA product numbers, rates, and field boundaries, the app validates against label restrictions (wind speed, REI, buffer zones) using on-site weather readings, and season-end reports satisfy state restricted-use pesticide audits.
TECH_STACK: .NET MAUI (Android/iOS) + SQLite offline + ASP.NET Core API + PostgreSQL/PostGIS field boundaries + product label database + weather station Bluetooth
APP_TYPE: mobile
LANGUAGE: C#
SCALE: 5,200 applicators, ~18,000 application records/day in season, offline-tolerant
```

## 67. TimberTally — logging harvest ticketing

```text
APP_DESCRIPTION: A mobile ticketing app for timber harvesting crews and log truck drivers. Loader operators create load tickets by species, product, and estimated tons, drivers carry tickets to mill scales where certified weights reconcile, landowners see stumpage settlements by tract, and the logging company tracks production per crew and hauling cost per ton.
TECH_STACK: .NET MAUI (Android) + SQLite offline + ASP.NET Core API + SQL Server + mill scale system integration + settlement statement generation
APP_TYPE: mobile
LANGUAGE: C#
SCALE: 90 crews, ~700 loads/day, 60 receiving mills, offline in remote timber tracts
```

## 68. QuotaQuay — commercial fishing catch reporting

```text
APP_DESCRIPTION: A catch-reporting API service for a regional fishery management program. Vessel operators submit electronic trip reports with species, gear, and area codes, dealers file landing reports that cross-validate against trips, the service tracks individual quota balances with real-time overage alerts before offload, and aggregated data feeds stock-assessment scientists.
TECH_STACK: ASP.NET Core Web API + PostgreSQL + vessel e-logbook integrations + dealer reporting portal + NOAA data exchange formats + quota ledger engine
APP_TYPE: API service
LANGUAGE: C#
SCALE: 2,600 permitted vessels, 410 dealers, ~1,800 reports/day in season, ~60 GB data
```

## 69. BrewBatch — craft brewery operations

```text
APP_DESCRIPTION: A brewery-operations web app for craft breweries from brewpub to regional scale. Brewers schedule batches against tank availability and follow recipes with actual-versus-target gravity readings, cellar operations log transfers, dry-hop additions, and yeast generations, packaging runs deplete finished-goods lots, and TTB excise reports generate from barrel-accurate movement records.
TECH_STACK: ASP.NET Core + Razor Pages + Entity Framework Core + PostgreSQL + tank sensor integrations (optional) + TTB Brewer's Report generation
APP_TYPE: web app
LANGUAGE: C#
SCALE: 850 brewery tenants, ~5,600 users, ~2,400 active batches at any time
```

## 70. CrushCadence — winery harvest logistics

```text
APP_DESCRIPTION: A harvest-operations web app for a wine group crushing fruit from 60 vineyard blocks across three facilities. Viticulturists schedule picks from ripeness sampling data, weigh-tag records capture tons by block and contract terms at the crush pad, cellar masters assign lots to tanks with fermentation tracking (brix, temp, punch-downs), and grower payments calculate from contracted price per ton with quality adjustments.
TECH_STACK: ASP.NET Core MVC + Entity Framework Core + PostgreSQL + weighbridge integration + fermentation sensor feeds + grower settlement reports
APP_TYPE: web app
LANGUAGE: C#
SCALE: 3 crush facilities, ~9,000 tons/harvest, 140 users during crush, ~500 fermentation lots
```

## 71. GradeGate — meat processing yield tracking

```text
APP_DESCRIPTION: A plant-floor desktop app for a beef processor tracking carcass grading and fabrication yield. Graders record USDA quality and yield grades at the rail with carcass ID scanning, fabrication lines weigh primal cuts against expected yield curves per carcass, variances flag trim-loss problems by station, and lot-level traceability links retail cases back to source animals.
TECH_STACK: WinUI 3 (.NET 8) + SQL Server + rail scanner and floor scale integrations + label printer SDKs + USDA grading data capture
APP_TYPE: desktop
LANGUAGE: C#
SCALE: 2 plants, ~2,100 head/day, 30 floor workstations, lot traceability retained 3 years
```

## 72. AssetAnvil — Unity asset build pipeline CLI

```text
APP_DESCRIPTION: A CLI tool for game studios that automates Unity asset bundle and addressables builds across platforms. It validates asset import settings against studio conventions (texture compression, mesh limits), builds platform-specific bundles in parallel on build farm agents, diffs bundle contents between releases to catch size regressions, and uploads versioned bundles to the CDN with manifest signing.
TECH_STACK: .NET 8 console app (System.CommandLine) + Unity batch-mode orchestration + content hashing/diffing + S3/CloudFront upload + JSON build manifests
APP_TYPE: CLI
LANGUAGE: C#
SCALE: 3 studios, ~40 CI builds/day, 25 GB asset library, 5 target platforms per build
```

## 73. MatchMason — multiplayer matchmaking backend

```text
APP_DESCRIPTION: A matchmaking API service for a session-based 4v4 arena game. It queues players by skill rating with role and region preferences, widens search windows over wait time, forms balanced matches and allocates dedicated game server instances, handles party grouping with rating averaging, and feeds post-match rating updates back through a TrueSkill-style model.
TECH_STACK: ASP.NET Core minimal APIs + Redis queue state + gRPC to game server fleet manager (Agones) + PostgreSQL player ratings + Kafka match telemetry
APP_TYPE: API service
LANGUAGE: C#
SCALE: 90,000 concurrent players at peak, ~1,200 matches formed/minute, p95 queue time under 45s
```

## 74. LootLedger — game economy telemetry

```text
APP_DESCRIPTION: A telemetry pipeline for a live-service RPG's in-game economy. It ingests item drop, craft, trade, and vendor transaction events from game servers, computes currency faucet/sink balances and item price indices per server shard, detects gold-farming and duplication anomalies from transfer graphs, and feeds the economy team's tuning dashboards.
TECH_STACK: .NET 8 worker services + Kafka event ingestion + ClickHouse analytics store + anomaly detection jobs + Grafana dashboards
APP_TYPE: data pipeline
LANGUAGE: C#
SCALE: ~45,000 events/sec at peak, 30 server shards, ~400 GB/day raw events, 18-month retention
```

## 75. PatchPorter — game patch distribution CLI

```text
APP_DESCRIPTION: A CLI tool that builds and publishes game client patches for a studio's self-hosted launcher. It generates binary diffs between build versions with chunk-level deduplication, assembles delta patch packages per source-version range, stages releases through dev/beta/live channels with signed manifests, and can roll back a channel to any prior build in one command.
TECH_STACK: .NET 8 console app (System.CommandLine) + content-defined chunking + zstd compression + CDN origin upload + Ed25519 manifest signing
APP_TYPE: CLI
LANGUAGE: C#
SCALE: 60 GB full client, typical delta 800 MB, 4 release channels, ~3 releases/week
```

## 76. ShardShepherd — game server fleet control plane

```text
APP_DESCRIPTION: A fleet-orchestration API service managing dedicated game server instances across cloud regions. It scales server pools from matchmaking demand forecasts, drains and recycles instances after match completion, rolls out new server builds region by region with health gating, and exposes fleet capacity and cost dashboards to the live-ops team.
TECH_STACK: ASP.NET Core Web API + gRPC agent channels + Kubernetes/Agones integration + PostgreSQL fleet state + Prometheus metrics + Terraform-provisioned multi-region clusters
APP_TYPE: API service
LANGUAGE: C#
SCALE: 8 regions, up to 12,000 concurrent server instances, ~600 scale operations/hour at peak
```

## 77. TurnstileTempo — stadium access control

```text
APP_DESCRIPTION: A ticket-validation API service for a 62,000-seat stadium and its arena sister venue. It validates rotating-barcode and NFC tickets at gate readers with sub-second response, prevents pass-backs and screenshots via token rotation, manages re-entry and gate-specific access rules for suites and club levels, and streams live ingress counts to operations dashboards for gate staffing.
TECH_STACK: ASP.NET Core minimal APIs + Redis token state + gate reader SDK integrations + SignalR ops dashboard + SQL Server + ticketing platform webhooks (Ticketmaster/SeatGeek)
APP_TYPE: API service
LANGUAGE: C#
SCALE: 55,000 scans in a 90-minute ingress window (~35 scans/sec sustained, 150/sec peak), 120 gate readers
```

## 78. RinkRoster — ice rink scheduling and leagues

```text
APP_DESCRIPTION: A facility-management web app for multi-sheet ice rinks. Schedulers allocate ice time across hockey leagues, figure skating clubs, learn-to-skate sessions, and public skates with resurfacer buffer rules, league coordinators manage rosters, standings, and official assignments, and families register and pay for programs with USA Hockey number validation.
TECH_STACK: ASP.NET Core MVC + Entity Framework Core + PostgreSQL + Stripe registration payments + calendar feeds (iCal) + league standings engine
APP_TYPE: web app
LANGUAGE: C#
SCALE: 45 facilities, 110 ice sheets, 68,000 registered participants, ~250 concurrent users
```

## 79. SweatSlate — gym membership and booking

```text
APP_DESCRIPTION: A membership web app for a regional chain of 26 fitness clubs. Members book classes and court reservations with waitlist promotion, front desk manages check-ins with membership-status gating and guest passes, billing runs monthly dues with dunning for failed drafts, and trainers schedule and bill personal-training session packs.
TECH_STACK: ASP.NET Core + Blazor Server + Entity Framework Core + SQL Server + recurring billing with Stripe + barcode/RFID check-in hardware + SMS waitlist notifications
APP_TYPE: web app
LANGUAGE: C#
SCALE: 26 clubs, 94,000 members, ~7,000 class bookings/day, ~30,000 check-ins/day
```

## 80. SteepleSuite — church membership and giving

```text
APP_DESCRIPTION: A church-management web app for mid-size and large congregations. Staff maintain household and member records with ministry group involvement, online and text giving posts to pledge campaigns and designated funds, children's ministry check-in prints security-matched pickup tags, and year-end giving statements generate per IRS substantiation rules.
TECH_STACK: ASP.NET Core + Razor Pages + Entity Framework Core + PostgreSQL + Stripe/ACH giving + label printer check-in kiosks + email statement delivery
APP_TYPE: web app
LANGUAGE: C#
SCALE: 480 congregation tenants, 390,000 member records, giving peaks ~40 req/sec Sunday mornings
```

## 81. CuratorCove — museum collections management

```text
APP_DESCRIPTION: A collections-management web app for regional museums and university galleries. Registrars catalog objects with provenance chains, condition reports, and controlled vocabularies (AAT/ULAN), track locations from vault shelf to gallery case to outgoing loan with facility reports, manage acquisition and deaccession approvals, and publish selected records to a public online collection.
TECH_STACK: ASP.NET Core MVC + Entity Framework Core + PostgreSQL + IIIF image server integration + Azure Blob high-res imagery + public search index (Elasticsearch)
APP_TYPE: web app
LANGUAGE: C#
SCALE: 38 institutions, 2.1 million cataloged objects, ~600 GB imagery, 220 concurrent users
```

## 82. ShelfSteward — library circulation client

```text
APP_DESCRIPTION: A staff circulation desktop app for a county public library system with 12 branches. Circulation staff check items in and out with RFID pad reads, manage holds queues with branch transfer routing, register patrons and resolve fines with payment recording, and process interlibrary loans; the client stays operable in offline mode during network outages and reconciles when reconnected.
TECH_STACK: WinUI 3 (.NET 8) + ILS REST API integration + RFID/barcode reader SDKs + receipt printers + local SQLite offline transaction queue
APP_TYPE: desktop
LANGUAGE: C#
SCALE: 12 branches, 85 circulation workstations, ~9,500 checkouts/day, 410,000 registered patrons
```

## 83. ArchiveAlder — records retention scanner CLI

```text
APP_DESCRIPTION: A CLI tool for government records officers that enforces retention schedules across file shares and SharePoint libraries. It scans repositories classifying documents against the agency's retention schedule using path rules and content patterns, flags records past disposition dates, generates legally defensible destruction certificates for approved batches, and places litigation holds that exempt matching records from disposition runs.
TECH_STACK: .NET 8 console app (System.CommandLine) + SMB/Microsoft Graph scanning + SQLite classification catalog + YAML retention schedule definitions + signed PDF certificates
APP_TYPE: CLI
LANGUAGE: C#
SCALE: ~40 million files across 85 TB of shares, quarterly disposition runs, 6 records officers
```

## 84. FoiaFlow — public records request tracking

```text
APP_DESCRIPTION: A public-records request web app for state and municipal agencies. Requesters submit and track FOIA requests through a public portal, records staff route requests to custodian departments with statutory deadline clocks, reviewers redact exempt material with page-level exemption citations, and fee estimates, invoices, and response letters generate from templates.
TECH_STACK: ASP.NET Core MVC + Entity Framework Core + PostgreSQL + PDF redaction workspace + Azure Blob document storage + deadline escalation jobs via Hangfire
APP_TYPE: web app
LANGUAGE: C#
SCALE: 55 agency tenants, ~2,800 open requests, ~450 new requests/week, 300 GB responsive documents
```

## 85. PollPost — election worker management

```text
APP_DESCRIPTION: A poll-worker management web app for county election offices. Coordinators recruit and assign workers to precincts by role, party balance, and language skills, workers complete required training modules with certification tracking, election-day check-in confirms staffing with standby activation for no-shows, and payroll exports compute stipends by role and training hours.
TECH_STACK: ASP.NET Core + Razor Pages + Entity Framework Core + SQL Server + SMS/email notifications + training LMS integration + payroll export files
APP_TYPE: web app
LANGUAGE: C#
SCALE: 8 county tenants, 14,000 poll workers, 1,100 precincts, peak load in the two weeks before elections
```

## 86. SnowSentry — snowplow dispatch telemetry

```text
APP_DESCRIPTION: A winter-operations data pipeline for a state DOT district. It ingests AVL GPS, plow-position, and material-spreader rates from 320 trucks, maps treated lane-miles against priority route coverage targets in real time, reconciles salt and brine usage against storm budgets by garage, and produces per-storm after-action reports with route timeline playback.
TECH_STACK: .NET 8 worker services + cellular AVL ingestion + PostgreSQL/PostGIS + map-matching engine + SignalR live ops map + storm report generation
APP_TYPE: data pipeline
LANGUAGE: C#
SCALE: 320 trucks reporting every 10 seconds during storms (~32 events/sec), 4,100 lane-miles, ~25 storm events/season
```

## 87. FareFalcon — transit fare collection backend

```text
APP_DESCRIPTION: An account-based fare collection API service for a metro transit agency. It processes taps from bus validators and rail faregates against rider accounts with fare capping (daily/weekly best-fare), handles contactless EMV and closed-loop card tokens, applies reduced-fare eligibility categories, and settles operator revenue splits across the regional partner agencies.
TECH_STACK: ASP.NET Core Web API + Redis tap deduplication and account cache + PostgreSQL ledger + EMV payment gateway + offline validator store-and-forward reconciliation
APP_TYPE: API service
LANGUAGE: C#
SCALE: ~480,000 taps/day (~90 taps/sec peak), 1.2 million active fare accounts, 2,400 validators
```

## 88. ParkPerch — parking enforcement

```text
APP_DESCRIPTION: A mobile enforcement app for city parking officers. Officers run plates against permit, payment, and scofflaw databases with ALPR-assisted capture, issue electronic citations with photo evidence printed curbside, chalk vehicles digitally for time-limit zones with GPS-stamped observations, and request tows for boot-eligible vehicles with outstanding-citation thresholds.
TECH_STACK: .NET MAUI (rugged Android handhelds) + Bluetooth citation printers + ALPR camera SDK + ASP.NET Core API + SQL Server + pay-station and permit system integrations
APP_TYPE: mobile
LANGUAGE: C#
SCALE: 3 city tenants, 130 officers, ~2,600 citations/day, ~45,000 plate queries/day
```

## 89. ImpoundInk — tow and impound lot management

```text
APP_DESCRIPTION: A desktop lot-management app for a towing company operating police-rotation and private impound lots. Dispatchers log tows with reason codes and photo condition reports, the lot tracks storage-day charges with statutory fee caps, staff process owner releases with lien-holder and law-enforcement hold checks, and unclaimed vehicles flow through certified-letter notification timelines to auction eligibility.
TECH_STACK: WPF (.NET 8) + SQL Server + VIN decoding service + certified mail integration + state DMV owner-lookup interface + auction listing export
APP_TYPE: desktop
LANGUAGE: C#
SCALE: 4 lots, ~90 tows/day, 1,100 vehicles in storage, 12 workstations
```

## 90. RiseRoute — elevator maintenance dispatch

```text
APP_DESCRIPTION: A mobile field-service app for elevator maintenance mechanics. Mechanics receive route stops and entrapment callouts with unit maintenance history and code-compliance status, log maintenance-control-program tasks per ASME A17.1 with time-on-site capture, order parts against unit-specific equipment records, and complete state-required inspection paperwork with e-signatures.
TECH_STACK: .NET MAUI (iPhone/Android) + offline SQLite + ASP.NET Core API + SQL Server + parts catalog integration + push dispatch via Azure Notification Hubs
APP_TYPE: mobile
LANGUAGE: C#
SCALE: 260 mechanics, 9,800 elevator units under contract, ~1,400 stops/day, 30-minute entrapment response SLA
```

## 91. DuctDeck — HVAC field quoting

```text
APP_DESCRIPTION: A mobile quoting and job-costing app for residential HVAC contractors. Comfort advisors build good/better/best replacement proposals on the kitchen table with equipment, ductwork, and accessory pricing from distributor catalogs, apply financing options with monthly-payment display, capture signatures, and completed jobs reconcile actual equipment and labor costs against the quote.
TECH_STACK: .NET MAUI (iPad/Android tablets) + SQLite offline catalogs + ASP.NET Core API + PostgreSQL + distributor pricing feeds + financing lender API + DocuSign-style e-sign
APP_TYPE: mobile
LANGUAGE: C#
SCALE: 340 contractor companies, 2,100 advisors, ~4,800 proposals/day, 38% close-rate tracking
```

## 92. PestPilot — pest control route management

```text
APP_DESCRIPTION: A mobile route app for pest control technicians running recurring residential and commercial accounts. Technicians follow optimized daily routes with service-history and chemical-sensitivity notes per stop, record materials applied with EPA registration numbers and target pests for state reporting, photograph evidence of activity, and collect payments or flag renewals for the office.
TECH_STACK: .NET MAUI (Android/iOS) + SQLite offline + ASP.NET Core API + SQL Server + route optimization service + state pesticide-use report exports + card-present payments SDK
APP_TYPE: mobile
LANGUAGE: C#
SCALE: 190 branches, 3,400 technicians, ~38,000 service stops/day, offline-tolerant
```

## 93. WindWarden — wind turbine SCADA analytics

```text
APP_DESCRIPTION: An analytics pipeline for a renewables operator managing 6 wind farms. It ingests 10-minute SCADA aggregates and high-frequency event logs from 310 turbines, computes power-curve deviations that flag blade soiling and pitch faults, categorizes downtime against warranty availability guarantees for OEM claims, and forecasts day-ahead production for energy market bids.
TECH_STACK: .NET 8 worker services + OPC UA/IEC 61400-25 ingestion + TimescaleDB + ML.NET power-curve models + market bid file generation + Grafana
APP_TYPE: data pipeline
LANGUAGE: C#
SCALE: 310 turbines × ~200 tags (10-minute aggregates plus ~50 events/sec), ~6 GB/day, warranty data retained 12 years
```

## 94. PigPath — pipeline inline inspection processing

```text
APP_DESCRIPTION: A data-processing pipeline for a gas transmission operator's integrity program. It ingests inline-inspection (smart pig) sensor runs, aligns magnetic-flux-leakage anomaly indications to pipeline stationing with GPS weld-joint references, matches anomalies across historical runs to compute corrosion growth rates, and prioritizes dig lists per CFR 192 integrity management deadlines.
TECH_STACK: .NET 8 worker services + ILI vendor data format parsers + PostgreSQL/PostGIS centerline model + anomaly matching engine + GIS integration (Esri) + dig-sheet report generation
APP_TYPE: data pipeline
LANGUAGE: C#
SCALE: 4,200 miles of pipeline, ~15 ILI runs/year at 2-4 million indications per run, ~1 TB run archive
```

## 95. HearthHost — boutique inn property management

```text
APP_DESCRIPTION: A property-management web app for boutique inns and small hotel groups. Innkeepers manage room inventory with rate plans and seasonal pricing, direct-booking pages sync availability with OTA channel managers to prevent double-bookings, front desk handles check-in with folio charges for dining and spa add-ons, and housekeeping boards track room turnover status.
TECH_STACK: ASP.NET Core + Blazor Server + Entity Framework Core + PostgreSQL + OTA channel manager API integration + Stripe deposits + housekeeping mobile-web board
APP_TYPE: web app
LANGUAGE: C#
SCALE: 620 properties (8-60 rooms each), ~11,000 reservations/day, 900 concurrent users
```

## 96. PrepPress — commissary kitchen production planning

```text
APP_DESCRIPTION: A production-planning web app for a commissary kitchen supplying 85 corporate cafes and grab-and-go retail points. Chefs plan daily production from standardized recipes scaled by outlet forecasts, prep stations get batched task lists with allergen segregation flags, finished items label with dated barcodes and nutrition panels, and shrink tracking compares delivered versus sold quantities to tune forecasts.
TECH_STACK: ASP.NET Core MVC + Entity Framework Core + SQL Server + recipe scaling and nutrition calculation engine + label printer integration + demand forecast jobs via Hangfire
APP_TYPE: web app
LANGUAGE: C#
SCALE: 85 outlets, ~9,000 prepared items/day, 60 kitchen users, 2,800 recipes
```

## 97. CaterCraft — catering event management

```text
APP_DESCRIPTION: A desktop event-management app for full-service catering companies. Sales staff build event proposals with menu packages, staffing plans, and rental equipment, kitchens receive consolidated production sheets across the week's events with scaled quantities, event captains get load-out checklists and timeline run-sheets, and post-event costing compares actual food and labor spend to the quote.
TECH_STACK: WPF (.NET 8) + SQL Server + proposal PDF generation (QuestPDF) + Outlook calendar integration + rental inventory tracking + QuickBooks invoicing sync
APP_TYPE: desktop
LANGUAGE: C#
SCALE: 45 catering companies, 8-25 users each, ~30 events/company/week in peak season
```

## 98. CertCairn — TLS certificate rotation CLI

```text
APP_DESCRIPTION: A CLI tool for enterprise infrastructure teams that inventories and rotates TLS certificates across the estate. It discovers certificates by scanning load balancers, IIS bindings, Java keystores, and Kubernetes secrets, reports expirations against policy thresholds, renews eligible certs via ACME or the internal Microsoft CA, deploys renewed certs to their bindings with validation probes, and rolls back on failed health checks.
TECH_STACK: .NET 8 console app (System.CommandLine) + ACME client + Microsoft CA (certreq/DCOM) integration + F5/IIS/K8s deployment adapters + SQLite inventory + JSON/HTML reporting
APP_TYPE: CLI
LANGUAGE: C#
SCALE: ~9,500 certificates inventoried, ~400 rotations/month, nightly discovery scans across 3 datacenters
```

## 99. SqlSherpa — database migration runner CLI

```text
APP_DESCRIPTION: A CLI migration tool for teams managing SQL Server schema changes across many customer-hosted databases. It applies versioned migration scripts transactionally with checksum drift detection, generates rollback scripts from schema snapshots, runs pre-flight checks (disk space, blocking sessions, replication lag) before touching production, and fans out upgrades across hundreds of tenant databases with per-tenant success reporting.
TECH_STACK: .NET 8 console app (System.CommandLine) + SMO/Microsoft.Data.SqlClient + DacFx schema compare + parallel tenant execution + JSON run manifests for CI pipelines
APP_TYPE: CLI
LANGUAGE: C#
SCALE: 1,400 tenant databases per release wave, ~25 migrations/release, 8 releases/year
```

## 100. FeedForge — NuGet dependency audit CLI

```text
APP_DESCRIPTION: A CLI tool for platform engineering teams that audits NuGet dependencies across an organization's repositories. It scans solution and project files for direct and transitive packages, checks versions against known CVE advisories and internal deny-lists, flags packages drifting from the blessed internal-feed versions, and opens standardized upgrade pull requests with changelog excerpts for approved bumps.
TECH_STACK: .NET 8 console app (System.CommandLine) + NuGet.Protocol APIs + OSV/GitHub advisory feeds + Azure DevOps/GitHub PR automation + SQLite scan cache + SARIF output for pipelines
APP_TYPE: CLI
LANGUAGE: C#
SCALE: 380 repositories scanned nightly, ~5,200 distinct packages tracked, ~60 upgrade PRs/week
```
