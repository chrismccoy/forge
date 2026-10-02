# Java Blueprint Types — Copy-Paste Input Sets

Copy a fenced block into the prompt as-is, or swap individual fields.

## 1. TellerTime — bank branch appointments

```text
APP_DESCRIPTION: An appointment-scheduling web app for a regional bank's 60 branches. Customers book advisor slots by service type (mortgage, business, wealth), branch managers balance advisor calendars and walk-in queues, and the bank tracks no-show rates and service-time analytics.
TECH_STACK: Spring Boot + Thymeleaf + PostgreSQL + Redis + LDAP staff auth, deployed on on-prem Kubernetes
APP_TYPE: web app
LANGUAGE: Java
SCALE: 900 concurrent users, ~120 req/sec, ~40 GB data
```

## 2. ClaimGate — insurance claims intake API

```text
APP_DESCRIPTION: A claims-intake API service for a property insurer. Policyholder apps and partner portals submit claims with photos and documents, the service validates policy coverage and deductibles, assigns adjusters by region and workload, and publishes status events to downstream systems.
TECH_STACK: Spring Boot + PostgreSQL + Kafka + S3 document store + OAuth2 resource server, deployed on AWS EKS
APP_TYPE: API service
LANGUAGE: Java
SCALE: ~200 req/sec, 5,000 claims/day storm peak, ~1 TB documents
```

## 3. RackRoute — warehouse management

```text
APP_DESCRIPTION: A warehouse-management web app for a third-party logistics operator. Inbound staff receive and putaway stock against purchase orders, pickers work optimized pick paths from wave-released orders, and account managers see per-client inventory accuracy and SLA dashboards.
TECH_STACK: Spring Boot + React + PostgreSQL + RabbitMQ + Zebra barcode scanner integration, self-hosted
APP_TYPE: web app
LANGUAGE: Java
SCALE: 350 concurrent users across 3 warehouses, ~90 req/sec, ~60 GB data
```

## 4. WardWatch — hospital bed capacity dashboard

```text
APP_DESCRIPTION: A bed-capacity dashboard web app for a hospital network's operations center. Charge nurses update bed states (occupied, cleaning, blocked), transfer coordinators match incoming patients to available beds by unit and acuity, and executives view network-wide occupancy and discharge-forecast dashboards.
TECH_STACK: Spring Boot + WebSocket live updates + PostgreSQL + HL7 ADT feed integration, deployed on-prem
APP_TYPE: web app
LANGUAGE: Java
SCALE: 500 concurrent users across 4 hospitals, ~70 req/sec, ~20 GB data
```

## 5. CrewCycle — flight crew rostering API

```text
APP_DESCRIPTION: A crew-rostering API service for a regional airline. It ingests published flight schedules, generates legal crew pairings under duty-time regulations, handles crew swap and sick-call replacement requests, and exposes roster data to crew mobile apps and payroll.
TECH_STACK: Spring Boot + PostgreSQL + OptaPlanner for pairing optimization + Kafka events, deployed on Azure
APP_TYPE: API service
LANGUAGE: Java
SCALE: ~80 req/sec, 1,200 crew members, 400 flights/day, ~30 GB data
```

## 6. SettleRight — settlement reconciliation pipeline

```text
APP_DESCRIPTION: A nightly reconciliation data pipeline for a payments processor. It matches internal transaction ledgers against acquirer and bank settlement files, applies fee schedules, flags breaks by mismatch category for the operations team, and posts balanced journal batches to the general ledger.
TECH_STACK: Java + Spring Batch + PostgreSQL + SFTP file ingestion + Control-M scheduling, on-prem
APP_TYPE: data pipeline
LANGUAGE: Java
SCALE: ~8M transactions/night (~25 GB/night), 4-hour processing window, 7-year retention
```

## 7. CourseGate — university registration

```text
APP_DESCRIPTION: A course-registration web app for a mid-size university. Students search the catalog, build schedules with conflict checking, register during timed enrollment windows with prerequisite and seat-capacity enforcement, and join waitlists with automatic promotion.
TECH_STACK: Spring Boot + Vaadin + PostgreSQL + Redis for enrollment-window surge, deployed on university private cloud
APP_TYPE: web app
LANGUAGE: Java
SCALE: 8,000 concurrent users at registration open, ~600 req/sec peak, ~50 GB data
```

## 8. PortSwitch — telecom number porting API

```text
APP_DESCRIPTION: A number-porting orchestration API service for a national mobile carrier. It receives port-in and port-out requests from retail systems and rival carriers, validates subscriber identity and contract status, sequences the regulatory NPAC message exchange with deadline timers, and notifies provisioning once the number cuts over.
TECH_STACK: Quarkus + PostgreSQL + Kafka + Camel for carrier gateway adapters, deployed on OpenShift
APP_TYPE: API service
LANGUAGE: Java
SCALE: ~12,000 port requests/day, ~60 req/sec, 45M subscriber records
```

## 9. PlateForge — vehicle registration and titling

```text
APP_DESCRIPTION: A vehicle registration and titling web app for a state motor-vehicle agency. Counter clerks process title transfers with lien checks, residents renew registrations and order specialty plates online, and the agency reconciles fee collections against county treasurer remittances.
TECH_STACK: Spring Boot + JSF (legacy front office) + Angular (citizen portal) + Oracle 19c + IBM MQ to mainframe title registry, on-prem
APP_TYPE: web app
LANGUAGE: Java
SCALE: 2,500 concurrent users, ~300 req/sec renewal-deadline peak, 14M vehicle records
```

## 10. MeterMesh — smart meter reading pipeline

```text
APP_DESCRIPTION: A smart-meter data pipeline for an electric distribution utility. It ingests 15-minute interval reads from 2.1M AMI meters, runs validation-estimation-editing (VEE) rules to patch gaps and flag tamper events, and publishes billing-ready determinants to the customer information system and load-forecasting teams.
TECH_STACK: Java + Apache Flink + Kafka + TimescaleDB + Avro schema registry, deployed on AWS EKS
APP_TYPE: data pipeline
LANGUAGE: Java
SCALE: 2.1M meters, ~200M interval reads/day (~90 GB/day), 3-year hot retention
```

## 11. LineLens — factory OEE monitoring

```text
APP_DESCRIPTION: A production-line monitoring web app for an automotive parts manufacturer's 5 plants. Line supervisors watch live OEE (availability, performance, quality) per cell, operators log downtime reasons against fault codes from PLCs, and plant managers compare shift-over-shift scrap and changeover trends.
TECH_STACK: Spring Boot + Vue + PostgreSQL + MQTT ingestion from OPC-UA gateways + WebSocket dashboards, on-prem per plant
APP_TYPE: web app
LANGUAGE: Java
SCALE: 400 concurrent users across 5 plants, ~150 machine signals/sec, ~80 GB data
```

## 12. ScriptSafe — retail pharmacy dispensing

```text
APP_DESCRIPTION: A dispensing workflow web app for a 220-store pharmacy chain. Pharmacists verify e-prescriptions with drug-interaction and allergy checks, technicians manage fill queues and will-call bins, and the chain runs controlled-substance reporting to state PDMP systems.
TECH_STACK: Spring Boot + Thymeleaf + HTMX + PostgreSQL + NCPDP SCRIPT e-prescribing integration + Redis queue state, hosted in private cloud
APP_TYPE: web app
LANGUAGE: Java
SCALE: 1,800 concurrent users, ~140,000 fills/day, ~250 GB data
```

## 13. RailTrace — freight railcar tracking API

```text
APP_DESCRIPTION: A railcar-visibility API service for a Class I freight railroad. It consumes AEI trackside scanner events and interchange messages, maintains current location and ETA per car and unit train, and serves shipment-tracing queries to shipper portals and EDI 417/418 feeds to partner roads.
TECH_STACK: Micronaut + Kafka Streams + Cassandra + PostGIS for network model + gRPC internal APIs, deployed on GCP GKE
APP_TYPE: API service
LANGUAGE: Java
SCALE: ~3,000 events/sec, 90,000 active railcars, ~400 req/sec tracing queries
```

## 14. ClearLane — customs declaration filing

```text
APP_DESCRIPTION: A customs-declaration filing web app for licensed customs brokers. Entry writers classify goods against the harmonized tariff schedule, calculate duties and anti-dumping fees, submit entries to the customs authority's single-window gateway, and track holds, exams, and release messages per shipment.
TECH_STACK: Spring Boot + React + PostgreSQL + AS4/EDIFACT government gateway integration + Drools tariff rules, deployed on Azure
APP_TYPE: web app
LANGUAGE: Java
SCALE: 1,200 concurrent users, ~9,000 entries/day, ~120 GB data
```

## 15. UnderWrit — life insurance underwriting API

```text
APP_DESCRIPTION: An automated underwriting decision API for a life insurer. It scores applications using rules over MIB reports, prescription histories, and motor-vehicle records, returns accept/refer/decline decisions with reason codes to agent portals, and routes referred cases to human underwriter queues.
TECH_STACK: Spring Boot + Drools decision tables + PostgreSQL + Kafka case events + vendor evidence-bureau REST integrations, deployed on AWS
APP_TYPE: API service
LANGUAGE: Java
SCALE: ~45,000 applications/day, ~90 req/sec, p99 decision latency under 800 ms
```

## 16. VaultView — corporate treasury cash positioning

```text
APP_DESCRIPTION: A cash-positioning web app for a multinational's treasury department. Analysts consolidate intraday balances from 240 bank accounts via MT940/CAMT feeds, forecast daily liquidity by entity and currency, and initiate sweep and FX funding decisions with four-eyes approval.
TECH_STACK: Spring Boot + Angular + Oracle 19c + SWIFT/EBICS bank connectivity + Quartz intraday refresh jobs, on-prem
APP_TYPE: web app
LANGUAGE: Java
SCALE: 150 concurrent users, 240 bank accounts across 30 currencies, ~15,000 statement lines/day
```

## 17. HoldWeight — air cargo booking API

```text
APP_DESCRIPTION: A cargo booking and capacity API service for a widebody freighter operator. Forwarders request quotes and book by weight, volume, and ULD type against flight-leg capacity, the service enforces dangerous-goods and embargo rules, and load planners receive booked-to-capacity forecasts per departure.
TECH_STACK: Quarkus + PostgreSQL + Kafka + IATA Cargo-XML/CIMP message translation + Redis capacity cache, deployed on AWS EKS
APP_TYPE: API service
LANGUAGE: Java
SCALE: ~150 req/sec, 2,800 bookings/day, 60 freighter departures/day
```

## 18. GridRestore — utility outage management

```text
APP_DESCRIPTION: An outage-management web app for an electric utility's control room. Dispatchers group smart-meter last-gasp signals and customer calls into predicted outage events on the network model, assign line crews with switching orders, and feed estimated-restoration times to the public outage map.
TECH_STACK: Spring Boot + React + PostGIS network model + Kafka meter events + CIM adapter to SCADA, on-prem with DR site
APP_TYPE: web app
LANGUAGE: Java
SCALE: 300 concurrent operators storm peak, ~500 events/sec during storms, 1.4M service points
```

## 19. TrialTrack — clinical trial site management

```text
APP_DESCRIPTION: A clinical-trial site-management web app for a contract research organization. Study coordinators screen and enroll patients against protocol inclusion criteria, schedule visit windows with deviation alerts, and capture case report form data with audit trails for FDA 21 CFR Part 11 compliance.
TECH_STACK: Spring Boot + Thymeleaf + PostgreSQL + Envers audit history + SSO via SAML, hosted in validated AWS GovCloud-style enclave
APP_TYPE: web app
LANGUAGE: Java
SCALE: 2,000 concurrent users across 180 sites, 45 active studies, ~35,000 patients, ~90 GB data
```

## 20. PermitPath — municipal building permits

```text
APP_DESCRIPTION: A building-permit web app for a metro city's development services department. Applicants submit plans with fee calculation by valuation and trade, plan reviewers run parallel review cycles with markup comments, and inspectors get routed daily inspection lists with pass/fail checklists.
TECH_STACK: Spring Boot + Angular + PostgreSQL + S3-compatible plan document storage + Camunda review workflow, hosted on city private cloud
APP_TYPE: web app
LANGUAGE: Java
SCALE: 800 concurrent users, ~48,000 permits/year, ~2 TB plan documents
```

## 21. DisputeDesk — card chargeback management

```text
APP_DESCRIPTION: A chargeback case-management web app for a card issuer's disputes team. Agents intake cardholder disputes with reason-code selection, the system assembles representment evidence packages under network deadlines, and team leads track win rates and write-off exposure by merchant category.
TECH_STACK: Spring Boot + React + Oracle 19c + Kafka + Visa/Mastercard dispute API connectors + Quartz deadline timers, on-prem
APP_TYPE: web app
LANGUAGE: Java
SCALE: 600 concurrent agents, ~22,000 new disputes/day, ~300 GB case data
```

## 22. LoanLatch — auto loan origination API

```text
APP_DESCRIPTION: An auto-loan origination API service for an indirect lender. Dealer F&I systems submit applications, the service pulls tri-bureau credit, prices tiers with risk-based APR and dealer reserve, returns approve/counter/decline decisions, and generates funding checklists for booked contracts.
TECH_STACK: Spring Boot + PostgreSQL + Kafka + bureau (Experian/TransUnion/Equifax) integrations + Drools pricing matrix, deployed on AWS
APP_TYPE: API service
LANGUAGE: Java
SCALE: ~30,000 applications/day, ~120 req/sec, p95 decision under 6 seconds
```

## 23. CallMeter — telecom billing mediation pipeline

```text
APP_DESCRIPTION: A billing-mediation data pipeline for a mobile network operator. It collects raw CDRs and EDRs from 4G/5G network elements, normalizes and deduplicates records, applies guiding rules to match usage to subscriber accounts, and delivers rated-ready files to the billing engine and interconnect settlement.
TECH_STACK: Java + Kafka + Kafka Streams + Oracle 19c reference data + ASN.1 decoders + Airflow orchestration, on-prem
APP_TYPE: data pipeline
LANGUAGE: Java
SCALE: ~1.2B CDRs/day (~600 GB/day), 22M subscribers, 6-hour end-to-end SLA
```

## 24. DeskKeeper — hotel property management

```text
APP_DESCRIPTION: A property-management web app for a 90-hotel midscale chain. Front-desk agents handle check-in/out with room assignment and folio postings, housekeeping tracks room status boards, and revenue managers push rate and availability updates to OTA channel connections.
TECH_STACK: Spring Boot + Vue + PostgreSQL + Redis room-status cache + OTA channel-manager REST integrations + fiscal printer interfaces, cloud-hosted per region
APP_TYPE: web app
LANGUAGE: Java
SCALE: 2,200 concurrent users, 11,000 rooms, ~180 req/sec checkout-hour peak, ~200 GB data
```

## 25. MillMinder — steel mill maintenance planning

```text
APP_DESCRIPTION: A maintenance-planning web app for an integrated steel mill. Reliability engineers schedule preventive work orders against rolling-mill and blast-furnace equipment hierarchies, planners kit spare parts from stores with reservation holds, and shutdown coordinators sequence annual outage task lists.
TECH_STACK: Spring Boot + Angular + Oracle 19c + IBM Maximo asset sync + Quartz PM-generation jobs, on-prem
APP_TYPE: web app
LANGUAGE: Java
SCALE: 900 users, 65,000 equipment assets, ~2,400 work orders/week, ~70 GB data
```

## 26. FleetPulse — fleet telematics ingestion pipeline

```text
APP_DESCRIPTION: A telematics ingestion pipeline for a commercial trucking fleet operator. It streams GPS positions, engine fault codes, and harsh-braking events from 18,000 vehicle gateways, enriches with driver-assignment and route context, and materializes safety scorecards and fuel-efficiency aggregates for fleet managers.
TECH_STACK: Java + Kafka + Kafka Streams + ClickHouse aggregates + PostgreSQL reference data + Protobuf device schema, deployed on AWS MSK/EKS
APP_TYPE: data pipeline
LANGUAGE: Java
SCALE: 18,000 vehicles, ~9,000 messages/sec, ~250 GB/day, 13-month retention
```

## 27. DocketDeck — court case management

```text
APP_DESCRIPTION: A case-management web app for a state's district courts. Clerks docket filings with fee assessment and party indexing, judges manage hearing calendars with courtroom and interpreter resources, and e-filing intake validates attorney submissions against local rules before acceptance.
TECH_STACK: Spring Boot + JSF + Oracle 19c + Alfresco document repository + ECF 4.0 e-filing gateway, hosted in state data center
APP_TYPE: web app
LANGUAGE: Java
SCALE: 4,500 concurrent users across 74 courthouses, ~600,000 new cases/year, ~5 TB documents
```

## 28. PayLedger — payroll processing pipeline

```text
APP_DESCRIPTION: A payroll-processing batch pipeline for an outsourced payroll bureau serving 3,200 employer clients. It ingests approved timesheets and salary changes, calculates gross-to-net with multi-state tax and garnishment rules, produces ACH files and pay stubs, and generates quarterly 941 and W-2 filings.
TECH_STACK: Java + Spring Batch + Oracle 19c + Vertex tax engine integration + SFTP bank delivery + Control-M scheduling, on-prem
APP_TYPE: data pipeline
LANGUAGE: Java
SCALE: 480,000 employees paid per cycle, ~2M calculations/night, 3-hour window, 7-year retention
```

## 29. TreatyDesk — reinsurance treaty management

```text
APP_DESCRIPTION: A treaty-management web app for a reinsurance broker. Placement teams structure quota-share and excess-of-loss programs with layer and participation terms, technical accountants process cedent bordereaux and premium/claims statements, and claims staff track cessions against layer erosion.
TECH_STACK: Spring Boot + Angular + PostgreSQL + Apache POI bordereau ingestion + Keycloak SSO, deployed on Azure
APP_TYPE: web app
LANGUAGE: Java
SCALE: 350 concurrent users, 4,800 active treaties, ~600 bordereau files/month, ~150 GB data
```

## 30. QuayGate — container terminal gate API

```text
APP_DESCRIPTION: A truck-gate automation API service for a container port terminal. It validates trucker appointments and container pickup rights against the terminal operating system, processes OCR lane reads of container and chassis numbers, issues yard position tickets, and reports gate turn times to the port authority.
TECH_STACK: Quarkus + PostgreSQL + Kafka + OCR lane-hardware integration + EDI CODECO messaging, on-prem at terminal with cloud reporting
APP_TYPE: API service
LANGUAGE: Java
SCALE: ~6,500 truck transactions/day, ~40 req/sec gate peak, 28,000 TEU yard capacity
```

## 31. HemoStock — blood bank inventory

```text
APP_DESCRIPTION: A blood-inventory web app for a regional blood center supplying 40 hospitals. Staff track units from donation through testing, component separation, and labeling with ISBT 128 barcodes, hospital customers place standing and emergency orders by blood group, and the center manages expiry-driven rotation.
TECH_STACK: Spring Boot + Thymeleaf + PostgreSQL + barcode label printer integration + HL7 interfaces to hospital LIS, on-prem
APP_TYPE: web app
LANGUAGE: Java
SCALE: 400 concurrent users, ~1,100 units collected/day, 40 hospital accounts, ~30 GB data
```

## 32. FlagWire — AML transaction monitoring pipeline

```text
APP_DESCRIPTION: An anti-money-laundering monitoring pipeline for a mid-size retail bank. It screens wire, ACH, and card transactions in near-real-time against sanctions lists and behavioral scenarios (structuring, rapid movement, dormant-account activity), scores alerts, and feeds a case queue for the financial-crimes team.
TECH_STACK: Java + Apache Flink + Kafka + PostgreSQL case store + Elasticsearch entity search + OFAC/EU list feeds, on-prem Kubernetes
APP_TYPE: data pipeline
LANGUAGE: Java
SCALE: ~15M transactions/day, ~400 events/sec sustained, ~900 alerts/day, 10-year retention
```

## 33. ShelfCycle — retail replenishment pipeline

```text
APP_DESCRIPTION: A store-replenishment data pipeline for a 640-store grocery chain. It ingests nightly POS sales and perpetual inventory positions, forecasts item-store demand with promotion and seasonality uplift, computes order quantities against pack sizes and shelf capacity, and emits purchase orders to distribution centers.
TECH_STACK: Java + Spark on EMR + Kafka + PostgreSQL order staging + Airflow orchestration + parquet on S3, AWS
APP_TYPE: data pipeline
LANGUAGE: Java
SCALE: 640 stores x 38,000 SKUs (~24M item-store combinations/night), 5-hour window, ~180 GB/night
```

## 34. LiftLog — elevator technician mobile app

```text
APP_DESCRIPTION: A field-service Android app for an elevator maintenance company's 850 technicians. Techs receive dispatched callbacks and preventive-maintenance routes, capture unit condition checklists and part usage offline in machine rooms, and close work orders with customer signature capture.
TECH_STACK: Android (Java) + Room offline store + Retrofit sync to Spring Boot backend + Firebase push dispatch + zebra printer receipts
APP_TYPE: mobile
LANGUAGE: Java
SCALE: 850 field technicians, ~3,200 work orders/day, 48,000 maintained units, offline-first sync
```

## 35. PipePatrol — gas utility field inspection

```text
APP_DESCRIPTION: A field-inspection Android app for a natural gas distribution utility. Crews complete leak-survey routes with GPS breadcrumb capture, record atmospheric corrosion and valve inspections against regulatory form templates, and escalate grade-1 leaks to dispatch with photo evidence.
TECH_STACK: Android (Java) + SQLite offline forms + ESRI ArcGIS Runtime maps + REST sync to Jakarta EE (WildFly) backend + MDM-managed rugged tablets
APP_TYPE: mobile
LANGUAGE: Java
SCALE: 600 field users, ~14,000 inspections/month, 21,000 miles of main, offline-first
```

## 36. BondBench — fixed income trading desktop

```text
APP_DESCRIPTION: A fixed-income order-management desktop app for a broker-dealer's 120-seat trading floor. Traders stage and work corporate and municipal bond orders with real-time pricing and spread-to-benchmark views, compliance rules check concentration and restricted lists pre-trade, and fills flow to middle-office allocation.
TECH_STACK: JavaFX desktop + Chronicle Queue for low-latency messaging + FIX 4.4 engine (QuickFIX/J) + kdb+ market data + Oracle trade store
APP_TYPE: desktop
LANGUAGE: Java
SCALE: 120 trader workstations, ~8,000 orders/day, market-data updates ~5,000 ticks/sec, sub-10 ms order path
```

## 37. RadBoard — radiology worklist desktop

```text
APP_DESCRIPTION: A radiology-worklist desktop app for a teleradiology group covering 300 hospitals overnight. Radiologists claim studies from priority-ranked queues (stroke, trauma, routine), view prior-report context pulled from the RIS, and dictate structured findings with critical-results escalation to referring ED physicians.
TECH_STACK: JavaFX desktop + DICOM (dcm4che) study metadata + HL7 ORU results + PostgreSQL worklist backend + WebSocket queue updates
APP_TYPE: desktop
LANGUAGE: Java
SCALE: 190 radiologists, ~11,000 studies/night, p95 stroke-study turnaround under 12 minutes
```

## 38. BagMatch — baggage reconciliation API

```text
APP_DESCRIPTION: A baggage-reconciliation API service for a hub airport's ground handler. It matches bag-tag scans at check-in, sortation, and loading against passenger boarding status, enforces the rule that no bag flies without its boarded passenger, and triggers offload instructions to ramp teams for no-show passengers.
TECH_STACK: Micronaut + Kafka + Redis live bag state + PostgreSQL + IATA BSM/BPM Type B message parsing, on-prem airport data center
APP_TYPE: API service
LANGUAGE: Java
SCALE: ~85,000 bags/day, ~350 scans/sec bank peak, 900 departures/day, p99 match under 500 ms
```

## 39. PensionPost — pension contribution pipeline

```text
APP_DESCRIPTION: A contribution-processing pipeline for a workplace pension administrator. It ingests employer payroll contribution files, validates member records and salary-band contribution rates, allocates units across investment funds at daily prices, and produces exception reports for late or mismatched employer payments.
TECH_STACK: Java + Spring Batch + PostgreSQL + SFTP employer file intake + fund-price feed integration + Kubernetes CronJobs, private cloud
APP_TYPE: data pipeline
LANGUAGE: Java
SCALE: 26,000 employer schemes, ~3.4M member contributions/month, nightly 3-hour window
```

## 40. TollTally — toll transaction rating pipeline

```text
APP_DESCRIPTION: A toll-rating data pipeline for a statewide electronic tolling authority. It processes transponder reads and license-plate image results from 210 gantries, rates trips with time-of-day and axle-class pricing, aggregates account statements, and hands unmatched plates to a violation-processing queue.
TECH_STACK: Java + Kafka + Flink trip-building + PostgreSQL accounts + ALPR vendor result integration + S3 image archive, AWS
APP_TYPE: data pipeline
LANGUAGE: Java
SCALE: ~4.2M transactions/day, 210 gantries, ~1,800 events/sec rush peak, ~120 GB/day images metadata
```

## 41. ChurnRoute — dairy cooperative milk collection

```text
APP_DESCRIPTION: A milk-collection management web app for a dairy cooperative of 1,900 member farms. Logistics planners build daily tanker routes by farm volume forecasts, hauliers record pickup volumes and antibiotic test strips per farm, and the co-op calculates member payments on volume, butterfat, and quality grades.
TECH_STACK: Spring Boot + Vue + PostgreSQL + jsprit route optimization + tanker onboard-computer file import, hosted on Azure
APP_TYPE: web app
LANGUAGE: Java
SCALE: 1,900 member farms, 85 tanker routes/day, ~450 concurrent users, ~25 GB data
```

## 42. GrainGauge — grain elevator operations

```text
APP_DESCRIPTION: A grain elevator operations web app for a 28-location agricultural cooperative. Scale operators capture inbound truck weights with moisture and test-weight grading, merchandisers manage storage, drying discounts, and forward contracts per grower, and accounting settles grower payments against contract pricing.
TECH_STACK: Spring Boot + Thymeleaf + PostgreSQL + scale-head and moisture-tester serial integrations + DTN commodity price feed, self-hosted
APP_TYPE: web app
LANGUAGE: Java
SCALE: 28 locations, ~2,600 scale tickets/day harvest peak, 9,500 grower accounts, ~40 GB data
```

## 43. EscrowEngine — mortgage escrow analysis pipeline

```text
APP_DESCRIPTION: An escrow-analysis batch pipeline for a mortgage servicer's 1.1M-loan portfolio. It projects 12-month tax and insurance disbursements per loan, computes shortage/surplus against RESPA cushion limits, generates annual escrow statements and payment-change notices, and schedules surplus refund checks.
TECH_STACK: Java + Spring Batch + Oracle 19c + tax-authority and insurer disbursement feeds + PDF statement rendering (Apache PDFBox), on-prem
APP_TYPE: data pipeline
LANGUAGE: Java
SCALE: 1.1M loans analyzed/year (~95,000/month), ~380,000 statements/cycle, 4-hour nightly window
```

## 44. IdentiPass — KYC onboarding API

```text
APP_DESCRIPTION: A KYC-onboarding orchestration API for a digital brokerage. It sequences identity document verification, liveness checks, sanctions/PEP screening, and beneficial-ownership questionnaires per account type, maintains an auditable decision trail, and pushes approved profiles to account opening.
TECH_STACK: Spring Boot + PostgreSQL + Kafka + Temporal workflow orchestration + vendor IDV/screening REST integrations, deployed on AWS EKS
APP_TYPE: API service
LANGUAGE: Java
SCALE: ~18,000 onboardings/day, ~70 req/sec, p95 straight-through decision under 90 seconds
```

## 45. LabLink — hospital lab results API

```text
APP_DESCRIPTION: A lab-results delivery API service for a reference laboratory network. It receives verified results from analyzers via the LIS, maps local codes to LOINC, routes HL7v2 and FHIR results to 900 ordering practices with delivery-confirmation tracking, and manages critical-value callback escalation lists.
TECH_STACK: Quarkus + Kafka + PostgreSQL + HAPI FHIR + HL7v2 (HAPI) interface engine + Mirth channel migration layer, private cloud
APP_TYPE: API service
LANGUAGE: Java
SCALE: ~600,000 results/day, ~200 messages/sec morning peak, 900 practice endpoints
```

## 46. ChairSide — dental group practice management

```text
APP_DESCRIPTION: A practice-management web app for a 75-clinic dental service organization. Front desks schedule operatory chairs by procedure length and provider, clinicians chart perio measurements and treatment plans on tooth diagrams, and billing submits ADA claims with attachment imaging to dental payers.
TECH_STACK: Spring Boot + React + PostgreSQL + X12 837D claim generation + DICOM imaging link + Redis schedule cache, cloud-hosted
APP_TYPE: web app
LANGUAGE: Java
SCALE: 75 clinics, 2,400 concurrent users, ~9,000 appointments/day, ~500 GB data with imaging metadata
```

## 47. BusBound — school transportation routing

```text
APP_DESCRIPTION: A school-bus routing web app for a 92,000-student district. Transportation planners build stop-and-route networks with bell-time tiers and special-needs vehicle requirements, dispatchers manage daily driver assignments and substitutions, and parents see live bus ETAs during morning and afternoon runs.
TECH_STACK: Spring Boot + Angular + PostGIS + GraphHopper routing + AVL bus GPS feed + parent notification via SMS gateway, district data center
APP_TYPE: web app
LANGUAGE: Java
SCALE: 92,000 students, 780 buses, ~40,000 parent app sessions on snow-day mornings, ~30 GB data
```

## 48. BranchBook — public library system

```text
APP_DESCRIPTION: A library-services web app for a 31-branch county library system. Circulation staff handle checkouts, holds queues, and inter-branch transit routing, catalogers maintain MARC bibliographic records, and patrons manage accounts, renewals, and room bookings through the public portal.
TECH_STACK: Spring Boot + Thymeleaf + PostgreSQL + Solr catalog search + SIP2 self-checkout kiosk integration + EZproxy e-resource auth, county-hosted
APP_TYPE: web app
LANGUAGE: Java
SCALE: 31 branches, 410,000 active cardholders, ~5.8M annual circulations, ~1,100 concurrent portal users
```

## 49. ChargeGrid — EV charging network billing API

```text
APP_DESCRIPTION: A charging-session billing API for an operator of 9,400 public EV chargers. It authorizes sessions via RFID and app tokens, meters energy with OCPP telemetry, rates sessions on time-of-use tariffs with idle fees, settles roaming sessions with other networks via OCPI, and pushes receipts to driver apps.
TECH_STACK: Spring Boot + PostgreSQL + Kafka + OCPP 1.6/2.0.1 WebSocket gateway + OCPI roaming module + Stripe payouts, AWS EKS
APP_TYPE: API service
LANGUAGE: Java
SCALE: 9,400 charge points, ~55,000 sessions/day, ~1,200 concurrent OCPP connections, ~150 req/sec
```

## 50. NomFlow — gas pipeline nominations API

```text
APP_DESCRIPTION: A nominations and scheduling API service for an interstate natural gas pipeline. Shippers submit daily and intraday nominations against contracted capacity, the service runs confirmation with upstream/downstream connected parties, allocates scheduled quantities at constrained points, and publishes NAESB-cycle results.
TECH_STACK: Quarkus + Oracle 19c + Kafka + NAESB EDI/FF flat-file exchange + Drools allocation rules, on-prem with cloud DR
APP_TYPE: API service
LANGUAGE: Java
SCALE: 640 shipper contracts, 5 NAESB cycles/day, ~28,000 nomination lines/day, 11,000-mile system
```

## 51. AquaBill — water utility metering and billing

```text
APP_DESCRIPTION: A metering-and-billing web app for a municipal water utility serving 310,000 accounts. Billing staff run monthly cycles with tiered consumption rates and sewer surcharges, field supervisors dispatch re-read and shutoff orders, and customers view usage history, leak alerts, and payment plans in the portal.
TECH_STACK: Spring Boot + JSF back office + React customer portal + Oracle 19c + AMR drive-by read file imports + payment processor integration, city data center
APP_TYPE: web app
LANGUAGE: Java
SCALE: 310,000 accounts, ~15,000 bills generated/night in cycle, ~700 concurrent portal users, ~90 GB data
```

## 52. BinRoute — waste collection operations

```text
APP_DESCRIPTION: A waste-collection operations web app for a private hauler serving 14 municipalities. Route managers balance residential and commercial routes by cart counts and disposal capacity, drivers' onboard tablets report lift events and contamination flags from RFID-tagged carts, and billing reconciles tonnage tickets from transfer stations.
TECH_STACK: Spring Boot + Vue + PostGIS + Kafka lift-event ingestion + RFID/onboard-computer vendor API + jsprit route balancing, Azure-hosted
APP_TYPE: web app
LANGUAGE: Java
SCALE: 14 municipalities, 240 trucks, ~310,000 lift events/day, ~60 GB data
```

## 53. SimForge — SIM and eSIM provisioning API

```text
APP_DESCRIPTION: A SIM-provisioning API service for an MVNO platform hosting 40 virtual operators. It orchestrates eSIM profile downloads via SM-DP+ and physical SIM activations against the host network HLR/HSS, manages MSISDN and IMSI number pools per operator, and enforces plan-to-network-service mappings.
TECH_STACK: Micronaut + PostgreSQL + Kafka + GSMA SM-DP+ ES2+ integration + SOAP adapters to carrier HLR provisioning gateway, GCP GKE
APP_TYPE: API service
LANGUAGE: Java
SCALE: 40 tenant operators, 6.5M active SIMs, ~90,000 provisioning operations/day, ~50 req/sec
```

## 54. FiberFolio — telecom fiber plant inventory

```text
APP_DESCRIPTION: A fiber-plant inventory web app for a regional fiber broadband provider. Outside-plant engineers record spans, splice cases, and strand assignments on the network map, service designers trace end-to-end circuit paths for enterprise orders, and construction crews update as-built redlines after builds.
TECH_STACK: Spring Boot + React + PostGIS + GeoServer map tiles + Neo4j connectivity graph for circuit tracing, self-hosted
APP_TYPE: web app
LANGUAGE: Java
SCALE: 620,000 fiber strand-miles modeled, 480 concurrent users, ~85,000 circuits, ~200 GB geodata
```

## 55. RentReady — car rental operations

```text
APP_DESCRIPTION: A rental-operations web app for a 130-branch car rental company. Counter agents open agreements with license scans, damage walkarounds, and upsell options, fleet controllers rebalance vehicles between airport and city branches against reservation demand, and the back office processes tolls, fuel, and damage recharges.
TECH_STACK: Spring Boot + Angular + PostgreSQL + Redis availability cache + telematics odometer feed + payment tokenization gateway, AWS
APP_TYPE: web app
LANGUAGE: Java
SCALE: 130 branches, 21,000 vehicles, ~7,500 rental agreements/day, ~180 req/sec airport morning peak
```

## 56. PartsPit — dealership parts inventory API

```text
APP_DESCRIPTION: A parts-inventory API service for a 45-store auto dealership group. It serves real-time on-hand and bin-location lookups to service advisors and body shops, automates stock-order suggestions from OEM daily parts feeds, and brokers inter-store parts transfers with in-transit tracking.
TECH_STACK: Spring Boot + PostgreSQL + Kafka + OEM DMS (CDK/Reynolds) file integrations + Redis lookup cache, Azure-hosted
APP_TYPE: API service
LANGUAGE: Java
SCALE: 45 stores, 1.8M part-location records, ~250 req/sec service-lane peak, ~4,000 transfers/month
```

## 57. OreOps — mining equipment telemetry pipeline

```text
APP_DESCRIPTION: A haul-fleet telemetry pipeline for an open-pit copper mine. It streams payload weights, cycle segments, and engine health from 140 haul trucks and shovels, computes cycle-time and payload-variance KPIs per loading unit, and alerts dispatch on queue buildup at crushers and fuel-burn anomalies.
TECH_STACK: Java + Kafka + Flink + TimescaleDB + OPC-UA edge collectors on pit LTE network + Grafana dashboards, hybrid edge/AWS
APP_TYPE: data pipeline
LANGUAGE: Java
SCALE: 140 mobile assets, ~4,500 sensor messages/sec, ~300 GB/day, 24/7 operation
```

## 58. PumpProof — oil well production reporting

```text
APP_DESCRIPTION: A production-allocation web app for an upstream oil and gas operator with 3,800 wells. Pumpers enter daily gauge readings and downtime codes by route, engineers allocate commingled battery volumes back to wells using well tests, and regulatory staff generate state production filings and royalty-owner statements.
TECH_STACK: Spring Boot + Thymeleaf + Oracle 19c + SCADA tank-level feed import + PDF regulatory report generation, on-prem
APP_TYPE: web app
LANGUAGE: Java
SCALE: 3,800 wells, 260 field users, ~95,000 daily readings, ~120 GB data, monthly state filings
```

## 59. ReactorLog — chemical batch records

```text
APP_DESCRIPTION: An electronic batch-record web app for a specialty chemicals plant. Operators execute recipe steps with weigh-and-dispense verification against material lots, quality reviews batch deviations before release, and the system maintains genealogy from raw-material lots to finished product for recall traceability.
TECH_STACK: Spring Boot + Vue + PostgreSQL + OPC-UA reads from DCS for critical process values + Envers audit trails + barcode scale integration, on-prem
APP_TYPE: web app
LANGUAGE: Java
SCALE: 3 production buildings, 240 users, ~85 batches/week, 12,000 material lots/year, ~50 GB data
```

## 60. AuditBite — food safety audit mobile app

```text
APP_DESCRIPTION: A food-safety audit Android app for a restaurant group's 380 locations. District managers run HACCP checklist audits with temperature-probe Bluetooth readings and photo evidence, kitchen managers complete daily line checks and cooling logs, and corporate quality tracks corrective-action closure rates by region.
TECH_STACK: Android (Java) + Room offline audits + Bluetooth LE thermometer SDK + Retrofit sync to Spring Boot/PostgreSQL backend + Firebase push
APP_TYPE: mobile
LANGUAGE: Java
SCALE: 380 locations, 1,600 mobile users, ~5,200 audits/week, offline-first with nightly sync
```

## 61. ChillChain — cold chain monitoring pipeline

```text
APP_DESCRIPTION: A cold-chain monitoring pipeline for a pharmaceutical distributor. It ingests temperature and door-event telemetry from 2,600 reefer trailers and depot cold rooms, evaluates excursions against product-specific stability budgets, and generates release/quarantine dispositions and GDP compliance reports per shipment.
TECH_STACK: Java + Kafka + Kafka Streams + TimescaleDB + IoT gateway MQTT ingestion + PostgreSQL disposition store, Azure IoT Hub + AKS
APP_TYPE: data pipeline
LANGUAGE: Java
SCALE: 2,600 monitored assets, ~1,100 readings/sec, ~9,000 shipments/week, 5-year audit retention
```

## 62. CutTrace — meat processing traceability API

```text
APP_DESCRIPTION: A traceability API service for a beef and pork processor's 6 plants. It records carcass-to-primal-to-case breakdown events with lot and line context, answers one-up/one-down trace queries for recalls in seconds, and serves country-of-origin and animal-welfare attestations to retail customers' supplier portals.
TECH_STACK: Quarkus + PostgreSQL + Kafka plant-floor event ingestion + EPCIS 2.0 event model + GS1 label integration, hybrid plant-edge/AWS
APP_TYPE: API service
LANGUAGE: Java
SCALE: 6 plants, ~1.4M traceability events/day, recall trace query p95 under 4 seconds, ~2 TB event store
```

## 63. MashPlan — brewery production planning

```text
APP_DESCRIPTION: A production-planning web app for a craft brewery group with 4 breweries and 900 wholesale accounts. Planners schedule brews across brewhouse and fermenter capacity from distributor demand forecasts, cellar staff log gravity readings and tank transfers, and packaging lines report fill counts against orders.
TECH_STACK: Spring Boot + React + PostgreSQL + Redis tank-status board + EDI 852 distributor sell-through ingestion, cloud-hosted
APP_TYPE: web app
LANGUAGE: Java
SCALE: 4 breweries, 96 fermenters, 260 users, ~45 brews/week, ~20 GB data
```

## 64. CommCalc — insurance commission pipeline

```text
APP_DESCRIPTION: A commission-calculation pipeline for an insurance carrier's 28,000-agent distribution network. It processes policy premium transactions monthly, applies hierarchy splits, overrides, and persistency bonuses per agent contract schedules, claws back commissions on early lapses, and feeds statements and 1099 accumulation.
TECH_STACK: Java + Spring Batch + Oracle 19c + Drools commission schedule rules + PDF statement generation + Control-M, on-prem
APP_TYPE: data pipeline
LANGUAGE: Java
SCALE: 28,000 agents, ~2.6M premium transactions/month, 6-hour monthly run, 10-year statement retention
```

## 65. ActionDate — corporate actions pipeline

```text
APP_DESCRIPTION: A corporate-actions processing pipeline for a securities custodian. It consumes ISO 15022/20022 event announcements from depositories, scrubs conflicting terms across data vendors, calculates client entitlements for dividends, rights, and mergers across 4M positions, and generates election instructions and payment postings.
TECH_STACK: Java + Kafka + Oracle 19c + SWIFT MT564/MT566 parsing + Bloomberg/SIX vendor feed reconciliation + Spring Batch entitlement runs, on-prem
APP_TYPE: data pipeline
LANGUAGE: Java
SCALE: ~1,900 events/day, 4M client positions, ~350,000 entitlements/month, zero-miss payment SLA
```

## 66. NavNight — fund NAV calculation pipeline

```text
APP_DESCRIPTION: A nightly NAV-calculation pipeline for a fund administrator servicing 320 mutual funds and ETFs. It ingests custodian positions, vendor prices, and corporate-action adjustments, values portfolios with fair-value triggers for stale prices, accrues fees and expenses, and publishes strike NAVs to transfer agents and market data vendors by deadline.
TECH_STACK: Java + Spring Batch + PostgreSQL + Refinitiv/ICE price feeds + tolerance-check rule engine + Autosys scheduling, private cloud
APP_TYPE: data pipeline
LANGUAGE: Java
SCALE: 320 funds, ~480,000 positions valued/night, 90-minute strike window, 100% on-time NAV SLA
```

## 67. WireBridge — ISO 20022 payment gateway API

```text
APP_DESCRIPTION: A payment-gateway API service that connects a commercial bank's core to SWIFT and domestic RTGS rails. It transforms legacy MT and internal formats to ISO 20022 pacs messages, runs sanctions pre-screening and duplicate detection, manages cutoff-time queues per currency, and tracks gpi status updates end to end.
TECH_STACK: Spring Boot + IBM MQ + Oracle 19c + SWIFT Alliance gateway integration + XSLT/Java mapping layer + HSM signing, on-prem dual data center
APP_TYPE: API service
LANGUAGE: Java
SCALE: ~140,000 payments/day, ~$9B daily value, p99 straight-through processing under 30 seconds
```

## 68. TaxRail — corporate tax e-filing API

```text
APP_DESCRIPTION: An e-filing API service operated by a national tax authority for corporate income tax and VAT returns. Accounting software vendors submit returns via certified endpoints, the service validates against yearly schema and arithmetic rules, issues filing receipts with timestamps, and routes risk-scored returns to audit selection.
TECH_STACK: Jakarta EE on WildFly + Oracle Exadata + XML schema validation pipeline + digital signature (XAdES) verification + IBM MQ to assessment systems, government data center
APP_TYPE: API service
LANGUAGE: Java
SCALE: 2.4M registered filers, ~180,000 returns/day at deadline peak, ~450 req/sec, 11-year retention
```

## 69. BenefitBridge — social benefits eligibility

```text
APP_DESCRIPTION: A benefits-eligibility web app for a state human-services agency covering food, cash, and childcare assistance programs. Caseworkers process applications with household composition and income verification against federal poverty guidelines, the rules engine determines multi-program eligibility in one pass, and recipients upload documents and report changes via the self-service portal.
TECH_STACK: Spring Boot + Angular + Oracle 19c + Drools eligibility rules + document management integration + IRS/SSA verification hub interfaces, state data center
APP_TYPE: web app
LANGUAGE: Java
SCALE: 6,200 caseworkers, 1.9M recipient cases, ~85,000 applications/month, ~4 TB case documents
```

## 70. PassTrack — passport application processing

```text
APP_DESCRIPTION: A passport-application processing web app for a national identity agency. Applicants book biometric enrollment appointments at 240 offices, examiners adjudicate applications with facial-match and watchlist check results, and the system dispatches approved books to a central personalization facility with courier tracking.
TECH_STACK: Spring Boot + React + PostgreSQL + biometric matching (ABIS) integration + PKI document signing + Kafka case events, government private cloud
APP_TYPE: web app
LANGUAGE: Java
SCALE: 240 enrollment offices, ~38,000 applications/day summer peak, 5,500 concurrent staff users
```

## 71. DeedDesk — land registry and titles

```text
APP_DESCRIPTION: A land-registry web app for a provincial titles office. Conveyancers lodge transfer, mortgage, and caveat instruments electronically with priority timestamping, examiners verify chains of title against the parcel register, and the public searches titles and survey plans with pay-per-search billing.
TECH_STACK: Spring Boot + JSF examiner desktop + React public search + Oracle 19c + PostGIS parcel fabric + digital signature validation, government data center
APP_TYPE: web app
LANGUAGE: Java
SCALE: 3.1M land parcels, ~6,500 instruments lodged/day, ~22,000 title searches/day, ~1.5 TB registry
```

## 72. LeaseLedge — commercial lease administration

```text
APP_DESCRIPTION: A lease-administration web app for a REIT managing 480 office and retail properties. Lease administrators abstract rent schedules, escalations, and CAM recovery terms, accounting runs monthly rent rolls with percentage-rent calculations from tenant sales reports, and asset managers track expirations, options, and vacancy exposure.
TECH_STACK: Spring Boot + Angular + PostgreSQL + Apache POI rent-roll exports + Yardi GL integration + Quartz billing cycles, Azure-hosted
APP_TYPE: web app
LANGUAGE: Java
SCALE: 480 properties, 9,800 active leases, 320 users, ~$2.1B annual rents administered, ~60 GB data
```

## 73. FareForge — transit fare collection API

```text
APP_DESCRIPTION: A fare-collection backend API for a metropolitan transit authority's tap-to-pay system. It authorizes contactless card and mobile-wallet taps from 4,800 bus and rail validators, applies fare capping and transfer rules per rider account, settles open-loop transactions with the payments acquirer, and flags negative-balance cards to the deny list.
TECH_STACK: Quarkus + Redis deny-list replication + PostgreSQL + Kafka tap events + EMV transit-model acquirer integration, dual-region AWS
APP_TYPE: API service
LANGUAGE: Java
SCALE: ~1.6M taps/day, ~900 taps/sec rush peak, p99 authorization under 300 ms, 4,800 validators
```

## 74. RailSlate — train timetable planning desktop

```text
APP_DESCRIPTION: A timetable-planning desktop app for a national passenger rail operator. Planners construct annual and disruption timetables on time-distance graphs with headway and platform-occupation conflict detection, simulate journey times by rolling-stock class, and export conflict-free paths to the infrastructure manager's capacity system.
TECH_STACK: JavaFX desktop + embedded H2 working store + PostgreSQL central repository + RailML import/export + JGraphT conflict algorithms
APP_TYPE: desktop
LANGUAGE: Java
SCALE: 85 planner workstations, 26,000 train paths/day national timetable, 3,100 stations modeled
```

## 75. CiteSite — parking enforcement mobile app

```text
APP_DESCRIPTION: A parking-enforcement Android app for a city's 210 enforcement officers. Officers run plate lookups against permit and scofflaw lists via ALPR camera or manual entry, issue electronic citations with photo evidence and Bluetooth-printed tickets, and record chalk timers for time-limited zones.
TECH_STACK: Android (Java) + SQLite offline permit cache + ALPR SDK integration + Bluetooth ticket printer + REST sync to Spring Boot citation backend
APP_TYPE: mobile
LANGUAGE: Java
SCALE: 210 officers, ~3,800 citations/day, 95,000 permit records synced nightly, offline-capable
```

## 76. LoadLasso — freight brokerage load board

```text
APP_DESCRIPTION: A load-matching web app for a freight brokerage moving 1,400 loads/day. Brokers post shipper loads with lane pricing guidance from historical rates, carrier reps search and book loads with instant rate confirmations, and the TMS side tracks check calls, detention, and proof-of-delivery documents to trigger carrier pay.
TECH_STACK: Spring Boot + React + PostgreSQL + Elasticsearch lane search + DAT/Truckstop rate API integrations + Twilio check-call automation, AWS
APP_TYPE: web app
LANGUAGE: Java
SCALE: 1,400 loads/day, 850 concurrent users, 92,000 carrier records, ~250 req/sec quote bursts
```

## 77. ParcelPace — last-mile delivery driver app

```text
APP_DESCRIPTION: A delivery-driver Android app for a regional parcel carrier's 2,900 drivers. Drivers scan van loads against manifests, follow stop-sequenced navigation with delivery-window countdowns, capture signatures, photos, and safe-place codes at the door, and process on-the-spot redelivery or pickup requests.
TECH_STACK: Android (Java) + Room offline manifest + integrated laser scanner SDK on rugged devices + MQTT position reporting + Retrofit sync to Spring Boot backend
APP_TYPE: mobile
LANGUAGE: Java
SCALE: 2,900 drivers, ~420,000 stops/day, ~1,500 scans/sec depot-load peak, offline-first
```

## 78. QuoteKeel — ocean freight quoting API

```text
APP_DESCRIPTION: An ocean-freight quoting API service for an NVOCC. It prices FCL and LCL door-to-door quotes by combining contract ocean rates, port surcharges, and inland haulage tables, validates equipment availability and sailing schedules from carrier feeds, and locks quoted rates with validity windows for booking conversion.
TECH_STACK: Micronaut + PostgreSQL + Redis rate-table cache + carrier schedule (DCSA) API integrations + Kafka quote events, GCP
APP_TYPE: API service
LANGUAGE: Java
SCALE: ~65,000 quotes/day, ~180 req/sec, 1.2M active rate lines, p95 quote under 900 ms
```

## 79. HangarHub — aircraft maintenance (MRO)

```text
APP_DESCRIPTION: An MRO web app for a heavy-maintenance provider running 11 hangar lines. Planners load C-check work packages with task cards from OEM maintenance programs, mechanics sign off steps with license validation and dual-inspection gates, and materials staff track serialized rotable parts with airworthiness certificate custody.
TECH_STACK: Spring Boot + Angular + Oracle 19c + Spec 2000 parts messaging + barcode task-card scanning + Envers regulatory audit trail, on-prem
APP_TYPE: web app
LANGUAGE: Java
SCALE: 11 hangar lines, 2,600 mechanics, ~180,000 task-card signoffs/month, ~350 GB records
```

## 80. GustGauge — wind farm telemetry pipeline

```text
APP_DESCRIPTION: A turbine-telemetry pipeline for an operator of 14 wind farms. It streams SCADA tags (rotor speed, pitch, gearbox temperatures, power output) from 1,050 turbines, detects underperformance against manufacturer power curves, predicts gearbox and bearing faults from vibration trends, and schedules technician visits before failures.
TECH_STACK: Java + Kafka + Flink + TimescaleDB + OPC-UA farm collectors + Python model-serving sidecar via gRPC, Azure IoT Edge + AKS
APP_TYPE: data pipeline
LANGUAGE: Java
SCALE: 1,050 turbines, ~52,000 tag updates/sec, ~700 GB/day, 10-year fleet history
```

## 81. PrintPost — bank statement rendering pipeline

```text
APP_DESCRIPTION: A statement-composition batch pipeline for a retail bank's 4.2M customers. It aggregates monthly account activity, composes statements with product-specific templates, regulatory inserts, and targeted marketing messages, renders archival PDFs and print files for the mail house, and delivers e-statements with notification fan-out.
TECH_STACK: Java + Spring Batch + Oracle 19c + XSL-FO/Apache FOP composition + AFP print-stream output + S3-compatible archive + Control-M, on-prem
APP_TYPE: data pipeline
LANGUAGE: Java
SCALE: 4.2M statements/cycle, ~600,000 renders/night, 5-night cycle window, 7-year archive (~40 TB)
```

## 82. AtmCast — ATM cash forecasting pipeline

```text
APP_DESCRIPTION: A cash-demand forecasting pipeline for a bank's 3,100-ATM fleet. It ingests hourly dispense and deposit counters per terminal, forecasts denomination-level demand with payday and holiday effects, optimizes replenishment orders against courier routes and insurance limits, and alerts on predicted cash-outs.
TECH_STACK: Java + Spring Batch + Kafka terminal telemetry + PostgreSQL + OR-Tools replenishment optimization + armored-courier order file exchange, private cloud
APP_TYPE: data pipeline
LANGUAGE: Java
SCALE: 3,100 ATMs, ~2.8M transactions/day ingested, nightly 90-minute forecast run, 8% cash-holding reduction target
```

## 83. LeaveLoom — enterprise absence management

```text
APP_DESCRIPTION: An absence-management web app for a 68,000-employee industrial conglomerate. Employees request vacation, sick, and statutory leave against country-specific entitlement rules across 14 jurisdictions, managers approve with team-coverage conflict warnings, and HR reconciles balances to payroll and works-council reporting.
TECH_STACK: Spring Boot + React + PostgreSQL + country rule packs in Drools + SAP HR master-data sync + SAML SSO, hosted on Azure
APP_TYPE: web app
LANGUAGE: Java
SCALE: 68,000 employees, 14 countries, ~9,000 requests/day January peak, ~45 GB data
```

## 84. ClockCore — workforce time clock API

```text
APP_DESCRIPTION: A time-and-attendance API service for a manufacturing group's 41 plants. It ingests badge and biometric punches from 900 wall clocks, applies shift rules, grace periods, and overtime thresholds per union agreement, routes exceptions to supervisor approval queues, and exports certified hours to three different payroll systems.
TECH_STACK: Spring Boot + PostgreSQL + Kafka punch stream + clock-hardware vendor TCP protocol adapters + rule engine per bargaining unit, private cloud
APP_TYPE: API service
LANGUAGE: Java
SCALE: 52,000 hourly workers, ~210,000 punches/day, 900 clock devices, ~120 punches/sec shift change
```

## 85. AuditTrip — travel expense audit

```text
APP_DESCRIPTION: A travel-expense audit web app for a consulting firm's finance shared-services center. Auditors review risk-scored expense reports flagged for policy violations (duplicate receipts, weekend upgrades, out-of-window submissions), OCR-extracted receipt data is matched against corporate card feeds, and partners see chargeability and leakage dashboards by engagement.
TECH_STACK: Spring Boot + Vue + PostgreSQL + Tesseract OCR pipeline + Amex/Visa commercial card feed ingestion + Elasticsearch duplicate detection, AWS
APP_TYPE: web app
LANGUAGE: Java
SCALE: 34,000 employees submitting, ~18,000 reports/week, 60 auditors, ~900 GB receipt images
```

## 86. TenderTrack — procurement bidding platform

```text
APP_DESCRIPTION: A supplier-bidding web app for a hospital purchasing consortium of 130 member hospitals. Category managers publish RFQs with line-item specifications and compliance questionnaires, suppliers submit sealed bids before deadlines, and evaluation committees score technical and commercial envelopes with automated ranking and award audit trails.
TECH_STACK: Spring Boot + Angular + PostgreSQL + sealed-bid encryption with timed key release + document store + digital signature verification, cloud-hosted
APP_TYPE: web app
LANGUAGE: Java
SCALE: 130 member hospitals, 8,400 registered suppliers, ~350 active tenders, ~200 GB bid documents
```

## 87. SeatSurge — stadium ticketing

```text
APP_DESCRIPTION: A ticketing web app for a 58,000-seat football stadium and its concert calendar. Fans buy reserved seats from an interactive seat map with dynamic pricing by demand tier, season-ticket holders manage transfers and resale listings, and gate operations validate rotating-barcode mobile tickets with duplicate-entry detection.
TECH_STACK: Spring Boot + React + PostgreSQL + Redis seat-hold locks + Kafka + CDN-fronted on-sale queue with virtual waiting room, AWS multi-AZ
APP_TYPE: web app
LANGUAGE: Java
SCALE: 58,000 seats, 250,000 queue entrants at major on-sales, ~3,500 orders/min peak, ~1,200 gate scans/min
```

## 88. CurioCat — museum collection management

```text
APP_DESCRIPTION: A collection-management web app for a natural history museum holding 14M specimens. Registrars catalog accessions with taxonomy, locality, and provenance fields, conservators log condition reports and treatments, and loan officers manage outgoing loans to other institutions with insurance valuations and courier requirements.
TECH_STACK: Spring Boot + Thymeleaf + PostgreSQL + Solr faceted specimen search + IIIF image server integration + Darwin Core export, museum-hosted
APP_TYPE: web app
LANGUAGE: Java
SCALE: 14M specimen records, 180 staff users, ~65,000 new accessions/year, ~3 TB with imaging metadata
```

## 89. BreakBook — TV ad traffic scheduling

```text
APP_DESCRIPTION: An ad-traffic web app for a broadcaster running 12 regional TV channels. Traffic coordinators place sold spots into commercial breaks under separation rules (competitor, content adjacency), the system reconciles as-run logs against booked schedules for make-good management, and sales sees inventory-availability forecasts by daypart.
TECH_STACK: Spring Boot + Angular + Oracle 19c + BXF schedule exchange with playout automation + OptaPlanner spot placement, broadcaster data center
APP_TYPE: web app
LANGUAGE: Java
SCALE: 12 channels, ~9,500 spots placed/day, 140 users, as-run reconciliation of ~280,000 events/day
```

## 90. QuotaQuay — fisheries catch reporting API

```text
APP_DESCRIPTION: A catch-reporting API service for a national fisheries authority. Vessel skippers submit electronic logbook hauls by species and gear type from onboard systems, the service decrements individual transferable quota balances in real time, validates landings against dockside weigh-ins, and alerts enforcement on quota overruns and closed-area fishing.
TECH_STACK: Quarkus + PostgreSQL + Kafka + satellite VMS position feed correlation + ERS/FLUX EU message standard support, government cloud
APP_TYPE: API service
LANGUAGE: Java
SCALE: 4,100 licensed vessels, ~28,000 haul reports/day season peak, 310 quota stocks tracked
```

## 91. TimberTag — timber harvest tracking API

```text
APP_DESCRIPTION: A timber-tracking API service for a forestry products group. It registers harvested log batches with GPS harvest-block origin and species grading, tracks custody transfers from forwarder to truck to mill weighbridge, and produces chain-of-custody certificates for FSC/PEFC audits and EU deforestation-regulation due diligence.
TECH_STACK: Micronaut + PostgreSQL + PostGIS harvest blocks + Kafka + harvester head (StanForD) file ingestion + QR batch labels, hybrid forest-edge/Azure
APP_TYPE: API service
LANGUAGE: Java
SCALE: 190 harvest machines, ~5.2M cubic meters/year tracked, ~45,000 custody events/day, ~80 GB data
```

## 92. TillPoint — supermarket POS desktop

```text
APP_DESCRIPTION: A point-of-sale desktop app for a 240-store supermarket chain's checkout lanes. Cashiers scan items with weighted-produce and age-restriction handling, promotions apply multi-buy and loyalty-card discounts in real time, and lanes run offline against a local price file when store connectivity drops, syncing transactions on restore.
TECH_STACK: JavaFX on lane hardware + embedded H2 offline store + JavaPOS peripherals (scanner, scale, cash drawer) + store-server sync to central Spring Boot pricing service
APP_TYPE: desktop
LANGUAGE: Java
SCALE: 240 stores, 2,900 lanes, ~1.9M transactions/day, ~140,000 SKU price file, offline-capable
```

## 93. ScaleHouse — quarry weighbridge desktop

```text
APP_DESCRIPTION: A weighbridge desktop app for an aggregates producer's 17 quarries. Operators weigh trucks in and out with driver-camera capture and tare validation, the app prices loads by product, customer contract, and haulage zone, prints delivery dockets, and posts daily dispatch summaries to the central sales ledger.
TECH_STACK: JavaFX desktop + serial/IP weighbridge indicator integration + ANPR camera SDK + local PostgreSQL + nightly sync to central ERP via REST
APP_TYPE: desktop
LANGUAGE: Java
SCALE: 17 quarries, ~2,400 weighments/day, 6,800 customer contracts, offline-tolerant per site
```

## 94. AssayDesk — lab instrument data capture desktop

```text
APP_DESCRIPTION: An instrument-integration desktop app for an environmental testing laboratory. Bench chemists run calibration curves and sample batches on ICP-MS and GC instruments with control-chart checks, the app parses instrument output files into result sets with detection-limit qualifiers, and validated results post to the LIMS with full audit trails.
TECH_STACK: JavaFX desktop + instrument vendor file/RS-232 parsers + H2 local staging + REST posting to LabWare LIMS + NIST control-chart calculations
APP_TYPE: desktop
LANGUAGE: Java
SCALE: 45 instrument workstations, ~7,000 sample results/day, 22 instrument models supported
```

## 95. SchemaShift — database release CLI

```text
APP_DESCRIPTION: A database-migration CLI for an insurance company's 90 application teams. Release engineers apply versioned, checksummed schema changesets to Oracle and PostgreSQL targets with pre-flight drift detection, generate rollback scripts, and produce change-ticket evidence reports for the change-advisory board.
TECH_STACK: Java 21 + picocli + JDBC multi-vendor drivers + GraalVM native image binaries + Git-backed changeset repository, distributed via internal Artifactory
APP_TYPE: CLI
LANGUAGE: Java
SCALE: 90 teams, ~1,400 databases managed, ~600 migration runs/week across CI/CD pipelines
```

## 96. RedactRun — log PII redaction CLI

```text
APP_DESCRIPTION: A log-redaction CLI used by a telecom's security team before shipping logs to outside vendors and regulators. It streams multi-gigabyte log archives, detects and masks MSISDNs, IMSIs, national ID numbers, and payment card PANs with format-preserving tokens, and emits a redaction manifest for audit sign-off.
TECH_STACK: Java 21 + picocli + streaming regex/Aho-Corasick detection engines + zstd/gzip archive handling + GraalVM native image, run in air-gapped batch hosts
APP_TYPE: CLI
LANGUAGE: Java
SCALE: ~400 GB logs/day processed, ~180 MB/sec single-node throughput, 40+ PII pattern packs
```

## 97. FeedProof — EDI file validation CLI

```text
APP_DESCRIPTION: An EDI-validation CLI for a retail supply-chain integration team. Onboarding analysts validate trading-partner X12 files (850, 856, 810) against partner-specific companion guides, get line-precise error reports with segment and element references, and generate acknowledgment (997/999) files for test cycles.
TECH_STACK: Java 17 + picocli + Smooks EDI parsing + YAML companion-guide rule definitions + JUnit-style HTML report output, distributed as self-contained jlink runtime
APP_TYPE: CLI
LANGUAGE: Java
SCALE: 1,100 trading partners, ~9,000 validation runs/month in onboarding and CI, files up to 2 GB
```

## 98. CertHerd — certificate rotation CLI

```text
APP_DESCRIPTION: A certificate-management CLI for a bank's middleware operations team. Operators inventory expiring certificates across JKS/PKCS12 keystores on 3,500 WebSphere and Tomcat hosts, request renewals from the internal CA via ACME/EST, stage and hot-swap keystores with rollback snapshots, and export expiry compliance reports.
TECH_STACK: Java 21 + picocli + Bouncy Castle + ACME/EST client + SSH (Apache MINA sshd) fleet execution + CSV/JSON inventory output, GraalVM native image
APP_TYPE: CLI
LANGUAGE: Java
SCALE: 3,500 hosts, ~28,000 tracked certificates, ~900 rotations/month, zero expired-cert incidents target
```

## 99. DormDraft — university housing assignment

```text
APP_DESCRIPTION: A student-housing web app for a university housing office managing 14,500 beds. Students rank residence halls and form roommate groups during timed selection windows, the allocation engine assigns rooms respecting accessibility needs, living-learning communities, and class-year quotas, and hall staff manage check-in, room-condition reports, and mid-year room swaps.
TECH_STACK: Spring Boot + React + PostgreSQL + Redis selection-window queue + OptaPlanner assignment solver + student-information-system sync, university private cloud
APP_TYPE: web app
LANGUAGE: Java
SCALE: 14,500 beds, 21,000 applicants/cycle, 6,000 concurrent users at selection open, ~15 GB data
```

## 100. PriorPath — prior authorization API

```text
APP_DESCRIPTION: A prior-authorization API service for a health insurer covering 3.8M members. Provider EHRs submit authorization requests for imaging, specialty drugs, and surgical procedures, clinical rules auto-approve requests meeting medical-necessity criteria, borderline cases route to nurse and physician review queues, and determinations return with CMS-mandated turnaround tracking.
TECH_STACK: Spring Boot + PostgreSQL + Kafka + HL7 FHIR (Da Vinci PAS) endpoints + X12 278 legacy intake + clinical criteria rules engine, deployed on AWS EKS
APP_TYPE: API service
LANGUAGE: Java
SCALE: 3.8M members, ~26,000 auth requests/day, 62% auto-determination rate, p95 electronic response under 20 seconds
```
