# Perl Blueprint Types — Copy-Paste Input Sets

Copy a fenced block into the prompt as-is, or swap individual fields.

## 1. LogSift — log anomaly digest pipeline

```text
APP_DESCRIPTION: A data pipeline for a hosting provider's ops team that digests server logs into daily anomaly reports. It parses syslog, auth, and web-server logs across 400 hosts, baselines normal patterns per host, surfaces anomalies (error bursts, unusual auth activity, disk warnings), and emails a prioritized morning digest.
TECH_STACK: Perl + regex parsing framework + PostgreSQL + rsyslog ingestion + cron scheduling, self-hosted
APP_TYPE: data pipeline
LANGUAGE: Perl
SCALE: 400 hosts, ~40 GB logs/day, nightly batch within 2-hour window
```

## 2. mailtrim — mailbox archive dedupe CLI

```text
APP_DESCRIPTION: A CLI tool for mail administrators that deduplicates and prunes large mail archives. It scans Maildir/mbox stores, identifies duplicate messages across folders by content hash, applies retention rules by age and folder, produces a dry-run report before any deletion, and writes an audit log of every action.
TECH_STACK: Perl CLI (Getopt::Long) + Mail::Box + SQLite hash index + configurable retention policy files
APP_TYPE: CLI
LANGUAGE: Perl
SCALE: single operator, archives up to 2 TB / 10M messages per run
```

## 3. EDIBridge — legacy EDI transformation pipeline

```text
APP_DESCRIPTION: A data pipeline for a wholesale distributor that bridges legacy EDI trading partners to a modern ERP. It ingests X12 documents (850 orders, 856 ship notices, 810 invoices) over AS2/SFTP, validates against partner-specific rules, transforms to the ERP's JSON API format, and manages acknowledgments and resubmission of failed documents.
TECH_STACK: Perl + X12 parsing modules + PostgreSQL document ledger + SFTP/AS2 endpoints + ERP REST integration, on-prem
APP_TYPE: data pipeline
LANGUAGE: Perl
SCALE: 120 trading partners, ~15k documents/day, <10 GB/month, 24/7 with 15-min SLA
```

## 4. RackTrack — intranet server inventory

```text
APP_DESCRIPTION: An intranet web app for a university IT department that inventories servers and network gear. Technicians record hardware specs, rack locations, warranty and lifecycle dates; automated agents report OS and patch levels; managers plan refresh budgets from age and warranty reports.
TECH_STACK: Perl (Mojolicious) + PostgreSQL + Template Toolkit + LDAP auth + agent check-in API, self-hosted
APP_TYPE: web app
LANGUAGE: Perl
SCALE: 40 concurrent users, ~8 req/sec, 3,500 tracked devices, ~2 GB data
```

## 5. HL7Relay — hospital interface engine

```text
APP_DESCRIPTION: A data pipeline for a regional hospital that routes HL7 v2 messages between clinical systems. It receives ADT, ORM, and ORU feeds over MLLP, normalizes segment quirks per sending system, maps codes to the shared master patient index, and forwards to the EHR, lab, and billing systems with guaranteed delivery and replay.
TECH_STACK: Perl + Net::HL7 + MLLP listener + PostgreSQL message store + persistent retry queue, on-prem
APP_TYPE: data pipeline
LANGUAGE: Perl
SCALE: 6 clinical systems, ~90k messages/day, 24/7 with sub-second forwarding
```

## 6. genoslice — FASTQ demultiplex CLI

```text
APP_DESCRIPTION: A CLI tool for a genomics core facility that demultiplexes raw sequencing reads by sample barcode. It reads gzipped FASTQ lanes, matches index reads against a sample sheet with mismatch tolerance, splits reads into per-sample files, and emits per-barcode yield and quality metrics for the run report.
TECH_STACK: Perl CLI + BioPerl + PerlIO::gzip + sample-sheet parser, HPC scheduler (Slurm)
APP_TYPE: CLI
LANGUAGE: Perl
SCALE: ~1.5 billion reads per run, 96 samples/lane, 8 lanes, ~400 GB/run
```

## 7. StatementForge — bank statement batch renderer

```text
APP_DESCRIPTION: A data pipeline for a community bank that generates monthly account statements. It reads the nightly core-banking extract, aggregates transactions per account, applies fee and interest logic, renders PDF and accessible HTML statements, and hands print-ready files to the mailhouse and e-statement portal.
TECH_STACK: Perl + fixed-width extract parser + Template Toolkit + PDF::API2 + Oracle read replica, on-prem batch
APP_TYPE: data pipeline
LANGUAGE: Perl
SCALE: 220k accounts/month, ~9M transactions, 4-hour batch window
```

## 8. peerwatch — BGP session monitor

```text
APP_DESCRIPTION: A CLI and daemon for an ISP network team that watches BGP peering health. It polls routers over SNMP and the BGP MIB, tracks session state and prefix counts per peer, alerts on flaps or prefix-count anomalies, and writes a historical record for capacity and dispute investigations.
TECH_STACK: Perl + Net::SNMP + RRDtool + POSIX daemon + email/pager alerting, self-hosted
APP_TYPE: CLI
LANGUAGE: Perl
SCALE: 60 routers, 900 BGP sessions, 60-second poll interval
```

## 9. shelfmark — library MARC import pipeline

```text
APP_DESCRIPTION: A data pipeline for a public library consortium that imports and normalizes bibliographic records. It ingests MARC21 files from vendors and OCLC, deduplicates against existing holdings, enriches with local call numbers and item barcodes, and loads clean records into the shared ILS with a rejects report for cataloguers.
TECH_STACK: Perl + MARC::Record + MySQL staging + Z39.50 lookups + cron, on-prem
APP_TYPE: data pipeline
LANGUAGE: Perl
SCALE: 12 branches, ~40k records/week, ~3M title catalog
```

## 10. cdrcrunch — telecom call record rating engine

```text
APP_DESCRIPTION: A data pipeline for a regional telecom carrier that rates call detail records for billing. It collects CDRs from switches, deduplicates and normalizes number formats, applies rating plans and interconnect tariffs, and produces rated records plus reconciliation totals for the billing platform.
TECH_STACK: Perl + fixed-width/CSV parsers + PostgreSQL rating tables + tariff config files, on-prem batch
APP_TYPE: data pipeline
LANGUAGE: Perl
SCALE: ~25M CDRs/day, hourly micro-batches, 30-day rerating window
```

## 11. archivemint — government records ingest CLI

```text
APP_DESCRIPTION: A CLI tool for a state archives office that ingests digital records for long-term preservation. It walks transfer packages, validates checksums and file formats against a policy list, extracts technical metadata, generates PREMIS/BagIt manifests, and moves accepted packages into the preservation store with a full audit trail.
TECH_STACK: Perl CLI + Archive::BagIt + File::MimeInfo + SQLite manifest DB + checksum verification
APP_TYPE: CLI
LANGUAGE: Perl
SCALE: ~500 transfer packages/month, individual packages up to 200 GB
```

## 12. doiforge — journal DOI registration pipeline

```text
APP_DESCRIPTION: A data pipeline for an academic publisher that registers DOIs for newly published articles. It reads article metadata exports, builds Crossref deposit XML, submits to the registration API, tracks acceptance and error responses, and reconciles registered DOIs back into the editorial system.
TECH_STACK: Perl + XML::LibXML + LWP::UserAgent + Crossref API + PostgreSQL job ledger, self-hosted
APP_TYPE: data pipeline
LANGUAGE: Perl
SCALE: ~1,200 articles/week, retry queue with 24-hour reconciliation
```

## 13. quotaudit — hosting disk quota reporter

```text
APP_DESCRIPTION: A CLI tool for a shared-hosting provider that audits customer disk and inode usage. It walks per-account home directories across the fleet, computes usage against plan limits, flags accounts nearing or over quota, and emails account managers a per-server offenders report with growth trends.
TECH_STACK: Perl CLI + File::Find + quota system calls + SQLite history + cron, self-hosted
APP_TYPE: CLI
LANGUAGE: Perl
SCALE: 80 servers, ~35k hosting accounts, nightly walk under 90 minutes
```

## 14. formflow — Dancer2 grant submission portal

```text
APP_DESCRIPTION: A web app for a university research office where faculty submit internal grant applications. It collects proposal forms and budget spreadsheets, routes them through department and committee review stages, tracks status and deadlines, and generates award letters and funding reports for administrators.
TECH_STACK: Perl (Dancer2) + PostgreSQL + Template Toolkit + Shibboleth SSO + file uploads, self-hosted
APP_TYPE: web app
LANGUAGE: Perl
SCALE: ~600 active users, ~5 req/sec peak, ~2,000 submissions/cycle
```

## 15. dnszone — authoritative zone build pipeline

```text
APP_DESCRIPTION: A data pipeline for a DNS hosting provider that compiles customer records into authoritative zone files. It reads record changes from the provisioning database, validates syntax and delegation rules, generates and signs (DNSSEC) zone files, and pushes them to the nameserver fleet with change reporting.
TECH_STACK: Perl + Net::DNS + BIND zone generation + PostgreSQL + rsync distribution, self-hosted
APP_TYPE: data pipeline
LANGUAGE: Perl
SCALE: ~180k zones, ~4M records, incremental builds every 5 minutes
```

## 16. triagemail — helpdesk email-to-ticket parser

```text
APP_DESCRIPTION: A data pipeline for a managed-services company that turns inbound support email into tickets. It fetches from support mailboxes, threads replies to existing tickets, classifies by keyword and sender domain, extracts asset tags and priority hints, and creates or updates records in the ticketing system.
TECH_STACK: Perl + Email::MIME + IMAP fetcher + MySQL + ticketing REST API, self-hosted
APP_TYPE: data pipeline
LANGUAGE: Perl
SCALE: ~4,000 emails/day, 5-minute polling, dedupe across 3 mailboxes
```

## 17. tapecheck — backup verification CLI

```text
APP_DESCRIPTION: A CLI tool for a data-center operations team that verifies nightly backup jobs. It parses backup software logs and catalog exports, cross-checks that every protected host and volume ran and succeeded, detects silent skips and shrinking backup sizes, and emails a pass/fail matrix each morning.
TECH_STACK: Perl CLI + log parsers + SQLite trend DB + SMTP report + cron, self-hosted
APP_TYPE: CLI
LANGUAGE: Perl
SCALE: 1,200 backup clients, ~6,000 jobs/night, report by 06:00
```

## 18. isacheck — insurance claim edit engine

```text
APP_DESCRIPTION: A data pipeline for a health insurer that pre-adjudicates incoming claims. It ingests 837 claim files, applies eligibility, coding, and duplicate edits, splits clean claims from those needing review, and produces edit-reason reports plus 277 acknowledgment responses for clearinghouses.
TECH_STACK: Perl + X12 837/277 parsers + Oracle rules tables + SFTP intake, on-prem batch
APP_TYPE: data pipeline
LANGUAGE: Perl
SCALE: ~60k claims/day, hourly batches, 30 clearinghouse partners
```

## 19. crawlkeeper — link-rot checker for archives

```text
APP_DESCRIPTION: A CLI tool for a digital library that audits external links in its collections. It extracts URLs from catalog and finding-aid metadata, checks them for availability and redirects with polite rate limiting, records status history, and produces a curator worklist of broken and moved links.
TECH_STACK: Perl CLI + LWP::UserAgent + URI + SQLite status log + concurrency via forks
APP_TYPE: CLI
LANGUAGE: Perl
SCALE: ~1.2M tracked URLs, weekly sweep, 20 concurrent workers
```

## 20. payrun — nightly payroll batch processor

```text
APP_DESCRIPTION: A data pipeline for a mid-size employer's finance team that computes each pay cycle. It reads timekeeping and adjustment extracts, calculates gross pay, taxes, and deductions from rule tables, generates the bank ACH file and payslip data, and produces reconciliation and GL posting reports.
TECH_STACK: Perl + fixed-width extract parsers + PostgreSQL + NACHA file writer, on-prem batch
APP_TYPE: data pipeline
LANGUAGE: Perl
SCALE: ~18,000 employees, biweekly run within 3-hour window
```

## 21. spamscore — mail gateway content scorer

```text
APP_DESCRIPTION: An API service for an email provider that scores inbound messages for spam and phishing at the gateway. It receives message content and headers, applies rule sets, URL reputation lookups, and header-anomaly checks, and returns a verdict and score the MTA uses to accept, tag, or quarantine.
TECH_STACK: Perl (Mojolicious) + Redis caching + rule engine + DNSBL lookups + Milter integration, self-hosted
APP_TYPE: API service
LANGUAGE: Perl
SCALE: ~2M messages/day, <50 ms p95 verdict latency
```

## 22. curvemap — variant annotation pipeline

```text
APP_DESCRIPTION: A data pipeline for a clinical genetics lab that annotates called variants. It reads VCF files, joins against reference gene models and population frequency databases, predicts consequences, tags known pathogenic entries, and outputs annotated tables for review by molecular scientists.
TECH_STACK: Perl + BioPerl + Vcf parsing + SQLite/Berkeley DB reference stores, HPC batch
APP_TYPE: data pipeline
LANGUAGE: Perl
SCALE: ~200 samples/day, ~5M variants/sample, annotated within run window
```

## 23. netconf-sync — switch config backup CLI

```text
APP_DESCRIPTION: A CLI tool for an enterprise network team that backs up and diffs device configurations. It logs into switches and routers over SSH, retrieves running configs, stores versioned copies, diffs against the previous snapshot, and alerts on unexpected or out-of-window changes.
TECH_STACK: Perl CLI + Net::OpenSSH + Git-backed storage + Text::Diff + cron, self-hosted
APP_TYPE: CLI
LANGUAGE: Perl
SCALE: 1,500 devices, nightly capture, 90-day version retention
```

## 24. billsplit — utility meter billing pipeline

```text
APP_DESCRIPTION: A data pipeline for a municipal water utility that produces meter bills. It ingests meter reads from handheld and AMR imports, validates against consumption history, applies tiered rate schedules and taxes, generates bill records and exception lists for estimated or anomalous reads, and exports to the print and payment systems.
TECH_STACK: Perl + CSV/fixed-width parsers + PostgreSQL + rate config files, on-prem batch
APP_TYPE: data pipeline
LANGUAGE: Perl
SCALE: ~140k meters, monthly cycle split into daily route batches
```

## 25. catapult — Catalyst course registration app

```text
APP_DESCRIPTION: A legacy web app for a community college that runs course registration. Students search the schedule, check prerequisites and seat availability, enroll or waitlist, and view holds and bills; advisors manage overrides and section capacities during registration windows.
TECH_STACK: Perl (Catalyst) + DBIx::Class + Oracle + Template Toolkit + CAS SSO, self-hosted
APP_TYPE: web app
LANGUAGE: Perl
SCALE: ~12,000 students, ~120 req/sec at registration open, ~4,000 sections
```

## 26. feedfuse — RSS aggregation pipeline

```text
APP_DESCRIPTION: A data pipeline for a media monitoring firm that aggregates thousands of news feeds. It polls RSS/Atom sources on adaptive schedules, deduplicates articles by canonical URL and content hash, extracts and normalizes fields, tags by topic keywords, and loads items into the searchable monitoring database.
TECH_STACK: Perl + XML::Feed + LWP::UserAgent + PostgreSQL + full-text index, self-hosted
APP_TYPE: data pipeline
LANGUAGE: Perl
SCALE: ~30,000 feeds, ~500k items/day, 15-minute median poll cycle
```

## 27. certsentry — TLS certificate expiry monitor

```text
APP_DESCRIPTION: A CLI and daemon for a hosting provider's security team that tracks TLS certificate expiry across services. It connects to endpoints, reads certificate chains, records issuers and expiry dates, escalates alerts as expiry approaches, and produces a renewal worklist grouped by owner.
TECH_STACK: Perl + Net::SSLeay + IO::Socket::SSL + SQLite + tiered alerting, self-hosted
APP_TYPE: CLI
LANGUAGE: Perl
SCALE: ~9,000 endpoints, daily scan, 60/30/7-day alert tiers
```

## 28. omnifetch — supplier catalog normalizer

```text
APP_DESCRIPTION: A data pipeline for an online retailer that normalizes supplier product feeds. It downloads CSV, XML, and fixed-width catalogs from dozens of vendors, maps disparate fields to the internal schema, cleans units and currencies, matches to existing SKUs, and stages updates for merchandising review.
TECH_STACK: Perl + Text::CSV_XS + XML::Twig + PostgreSQL staging + SFTP/HTTP fetchers, self-hosted
APP_TYPE: data pipeline
LANGUAGE: Perl
SCALE: 85 vendor feeds, ~4M product rows/day, nightly refresh
```

## 29. rosterlink — LDAP account provisioning pipeline

```text
APP_DESCRIPTION: A data pipeline for a school district's IT team that provisions staff and student accounts. It reads roster extracts from the SIS, computes account attributes and group memberships from role rules, and reconciles them into LDAP and the mail system, deactivating departed users and logging every change.
TECH_STACK: Perl + Net::LDAP + fixed-width SIS parser + PostgreSQL state table + cron, on-prem
APP_TYPE: data pipeline
LANGUAGE: Perl
SCALE: ~48,000 accounts, nightly sync, full audit log
```

## 30. tollproc — highway toll transaction batcher

```text
APP_DESCRIPTION: A data pipeline for a toll-road authority that processes transponder and license-plate transactions. It ingests roadside capture files, matches to accounts, rates by gantry and vehicle class, handles image-review exceptions, and produces posting files for the account and violation systems.
TECH_STACK: Perl + fixed-width parsers + Oracle + rating config + SFTP intake, on-prem batch
APP_TYPE: data pipeline
LANGUAGE: Perl
SCALE: ~3M transactions/day, 15-minute micro-batches
```

## 31. depwatch — CPAN dependency audit CLI

```text
APP_DESCRIPTION: A CLI tool distributed on CPAN that audits a Perl project's dependency tree for outdated and vulnerable modules. It parses cpanfile and installed metadata, compares against the MetaCPAN release index and a security advisory feed, and reports upgrade candidates and known issues with suggested versions.
TECH_STACK: Perl CLI + Module::CPANfile + MetaCPAN API + JSON advisory feed + Getopt::Long
APP_TYPE: CLI
LANGUAGE: Perl
SCALE: distributed utility, ~2,000 installs, projects with up to ~800 deps
```

## 32. slidecast — courseware SCORM packaging pipeline

```text
APP_DESCRIPTION: A data pipeline for an e-learning publisher that packages course content into SCORM modules. It reads authored HTML and asset folders, injects the SCORM manifest and runtime hooks, validates structure and sequencing rules, and produces LMS-ready zip packages with a build report.
TECH_STACK: Perl + XML::LibXML + Archive::Zip + Template Toolkit + validation rules, self-hosted
APP_TYPE: data pipeline
LANGUAGE: Perl
SCALE: ~300 course builds/week, packages up to 500 MB
```

## 33. queuepeek — print spooler dashboard

```text
APP_DESCRIPTION: An intranet web app for a print-and-mail bureau that monitors production print queues. Operators view job status across printers, reorder and hold jobs, track SLA deadlines, and see per-shift throughput; supervisors get exception alerts for stalled or errored jobs.
TECH_STACK: Perl (Mojolicious) + CUPS/LPR interfaces + PostgreSQL + WebSocket updates, self-hosted
APP_TYPE: web app
LANGUAGE: Perl
SCALE: ~30 operators, 45 printers, ~20k jobs/day
```

## 34. flatpack — mainframe extract ETL

```text
APP_DESCRIPTION: A data pipeline for an insurance company that lands nightly mainframe extracts into the reporting warehouse. It decodes EBCDIC fixed-width files with COBOL copybook layouts, converts packed-decimal fields, applies type and range validation, and bulk-loads clean rows while quarantining rejects.
TECH_STACK: Perl + copybook-driven unpackers + PostgreSQL COPY + SFTP intake, on-prem batch
APP_TYPE: data pipeline
LANGUAGE: Perl
SCALE: ~40 extracts, ~120M rows/night, load within 4-hour window
```

## 35. wardstat — ward occupancy reporting job

```text
APP_DESCRIPTION: A data pipeline for a hospital operations team that compiles bed and ward occupancy reports. It reads ADT event feeds and bed-management extracts, reconstructs occupancy timelines, computes occupancy, turnover, and length-of-stay metrics per ward, and emails morning capacity reports to bed managers.
TECH_STACK: Perl + HL7/CSV parsers + PostgreSQL + Template Toolkit reports + cron, on-prem
APP_TYPE: data pipeline
LANGUAGE: Perl
SCALE: 700 beds, ~30 wards, hourly refresh with daily summary
```

## 36. gatecount — web log traffic analyzer CLI

```text
APP_DESCRIPTION: A CLI tool for a content site's ops team that summarizes web server access logs. It parses combined-format logs, filters bots via a rules list, aggregates hits, bandwidth, and status codes by URL, referrer, and country, and outputs daily traffic reports and top-N tables.
TECH_STACK: Perl CLI + regex log parser + GeoIP lookups + SQLite rollups + Getopt::Long
APP_TYPE: CLI
LANGUAGE: Perl
SCALE: ~80M log lines/day, single-pass streaming, report under 10 minutes
```

## 37. remitmatch — bank lockbox reconciliation pipeline

```text
APP_DESCRIPTION: A data pipeline for a bank's treasury services that matches incoming payments to open invoices. It ingests lockbox and ACH remittance files, parses varied remittance advice formats, matches by invoice number and amount with fuzzy fallback, and produces auto-applied postings plus an exceptions queue for clerks.
TECH_STACK: Perl + BAI2/CSV parsers + Oracle + matching heuristics, on-prem batch
APP_TYPE: data pipeline
LANGUAGE: Perl
SCALE: ~50k remittances/day, hourly batches, 95% auto-match target
```

## 38. probemux — SNMP metrics collector daemon

```text
APP_DESCRIPTION: A data pipeline for a hosting provider that collects device metrics for capacity planning. It polls interfaces, CPU, memory, and environmental sensors over SNMP across the fleet, stores time series, computes rollups, and feeds threshold breaches to the alerting system.
TECH_STACK: Perl + Net::SNMP + RRDtool/InfluxDB + forked pollers + config-driven targets, self-hosted
APP_TYPE: data pipeline
LANGUAGE: Perl
SCALE: 5,000 devices, ~250k OIDs, 30-second poll interval
```

## 39. paperroute — journal peer-review workflow app

```text
APP_DESCRIPTION: A web app for an academic publisher that manages manuscript peer review. Authors submit papers, editors assign reviewers and track deadlines, reviewers upload scored assessments, and the system enforces double-blind rules, sends reminders, and produces decision letters and reviewer-load reports.
TECH_STACK: Perl (Catalyst) + DBIx::Class + PostgreSQL + Template Toolkit + email notifications, self-hosted
APP_TYPE: web app
LANGUAGE: Perl
SCALE: ~8,000 registered reviewers, ~50 req/sec peak, ~15k submissions/year
```

## 40. seqtrim — read quality trimming CLI

```text
APP_DESCRIPTION: A CLI tool for a sequencing lab that quality-trims and filters sequencing reads before assembly. It streams paired-end FASTQ, clips adapters, trims low-quality bases by sliding window, drops short reads, and writes cleaned pairs with a per-file QC summary.
TECH_STACK: Perl CLI + PerlIO::gzip + adapter-matching routines + Getopt::Long, HPC batch
APP_TYPE: CLI
LANGUAGE: Perl
SCALE: ~800M read pairs/run, streaming, ~2 GB/s throughput target
```

## 41. escrowledger — mortgage escrow analysis batch

```text
APP_DESCRIPTION: A data pipeline for a mortgage servicer that runs annual escrow analyses. It reads loan, tax, and insurance disbursement extracts, projects next year's escrow needs, computes shortages and surpluses, adjusts payment schedules, and generates borrower disclosure statements and audit files.
TECH_STACK: Perl + fixed-width extract parsers + Oracle + PDF::API2 statements, on-prem batch
APP_TYPE: data pipeline
LANGUAGE: Perl
SCALE: ~600k loans, staggered monthly analysis runs
```

## 42. patchpulse — fleet patch compliance API

```text
APP_DESCRIPTION: An API service for an enterprise IT team that aggregates OS patch compliance. Endpoint agents post installed-package inventories; the service compares against baseline patch levels per OS and role, computes compliance scores, and exposes queryable results for dashboards and audit exports.
TECH_STACK: Perl (Mojolicious) + PostgreSQL + JSON API + baseline rule tables, self-hosted
APP_TYPE: API service
LANGUAGE: Perl
SCALE: ~25,000 endpoints, ~200 req/sec check-in bursts
```

## 43. slurpfix — flat-file to warehouse loader

```text
APP_DESCRIPTION: A data pipeline for a retail chain that consolidates daily store sales files into the central warehouse. It collects per-store fixed-width sales and inventory files over SFTP, validates completeness per store, transforms to the warehouse schema, and bulk-loads with a store-arrival dashboard for the data team.
TECH_STACK: Perl + fixed-width parsers + PostgreSQL COPY + SFTP intake + cron, self-hosted
APP_TYPE: data pipeline
LANGUAGE: Perl
SCALE: 1,800 stores, ~2M rows/day, complete load by 05:00
```

## 44. faxgateway — inbound fax routing pipeline

```text
APP_DESCRIPTION: A data pipeline for a medical clinic group that routes inbound faxes to the right department. It picks up faxes from the fax server, runs OCR on cover pages, matches to referring providers and patient identifiers by rules, and files documents into the EHR queues with an unmatched-review bucket.
TECH_STACK: Perl + Tesseract wrappers + Image::Magick + PostgreSQL + EHR integration, on-prem
APP_TYPE: data pipeline
LANGUAGE: Perl
SCALE: ~4,000 faxes/day, 5-minute pickup interval
```

## 45. tariffgen — freight rate quote engine

```text
APP_DESCRIPTION: An API service for a logistics broker that returns freight quotes. It accepts shipment parameters, applies carrier tariff tables, fuel surcharges, and accessorial rules, and returns ranked quotes with breakdowns; nightly jobs refresh tariff data from carrier files.
TECH_STACK: Perl (Dancer2) + PostgreSQL rate tables + Redis cache + tariff import jobs, self-hosted
APP_TYPE: API service
LANGUAGE: Perl
SCALE: ~40 req/sec, 60 carriers, sub-200 ms quote latency
```

## 46. mothcheck — herbarium specimen import CLI

```text
APP_DESCRIPTION: A CLI tool for a natural history museum that imports digitized specimen records. It reads spreadsheet exports from imaging stations, validates taxonomy against a name authority, normalizes collector and locality fields, geocodes localities, and loads clean records into the collections database with a curator error list.
TECH_STACK: Perl CLI + Spreadsheet::ParseExcel + taxonomy lookup + PostgreSQL + Getopt::Long
APP_TYPE: CLI
LANGUAGE: Perl
SCALE: ~2M specimen catalog, ~10k new records/week
```

## 47. rollcall — attendance SMS reminder pipeline

```text
APP_DESCRIPTION: A data pipeline for a vocational training provider that sends class attendance reminders. It reads enrollment and timetable extracts, computes who has upcoming sessions and outstanding absences, personalizes SMS messages, dispatches them via a gateway API, and logs delivery for compliance reporting.
TECH_STACK: Perl + CSV parsers + PostgreSQL + SMS gateway REST + cron, self-hosted
APP_TYPE: data pipeline
LANGUAGE: Perl
SCALE: ~20,000 learners, ~8k messages/day
```

## 48. vaultsweep — secrets rotation CLI

```text
APP_DESCRIPTION: A CLI tool for a platform team that rotates service account credentials. It reads a rotation policy inventory, generates new secrets, updates them in the secret store and dependent config files, verifies services still authenticate, and produces a rotation report with rollback pointers.
TECH_STACK: Perl CLI + Net::OpenSSH + Vault API + config templating + Getopt::Long, self-hosted
APP_TYPE: CLI
LANGUAGE: Perl
SCALE: ~1,200 credentials, monthly rotation batches
```

## 49. abstractmill — conference submission pipeline

```text
APP_DESCRIPTION: A data pipeline for a scientific society that processes conference abstract submissions. It ingests submitted abstracts and metadata, checks formatting and word limits, assigns to review tracks by topic rules, packages anonymized bundles for reviewers, and compiles accepted abstracts into the program book source.
TECH_STACK: Perl + Text processing + XML::LibXML + PostgreSQL + Template Toolkit, self-hosted
APP_TYPE: data pipeline
LANGUAGE: Perl
SCALE: ~6,000 abstracts/cycle, review packaging within 48 hours
```

## 50. netflowroll — NetFlow aggregation pipeline

```text
APP_DESCRIPTION: A data pipeline for an ISP that aggregates NetFlow records for traffic analysis and billing. It collects flow exports from edge routers, aggregates by customer prefix and protocol, computes 95th-percentile usage, and stores rollups for capacity planning and commit-tier billing reports.
TECH_STACK: Perl + flow record decoders + PostgreSQL + prefix-to-customer maps, self-hosted
APP_TYPE: data pipeline
LANGUAGE: Perl
SCALE: ~50 exporters, ~2B flows/day, 5-minute aggregation windows
```

## 51. permitdesk — Dancer2 building permit intake

```text
APP_DESCRIPTION: A web app for a city planning department where residents and contractors apply for building permits. Applicants submit forms and plan documents, staff route applications through zoning and inspection review stages, fees are calculated, and the system tracks status and issues permit certificates.
TECH_STACK: Perl (Dancer2) + PostgreSQL + Template Toolkit + file uploads + email, self-hosted
APP_TYPE: web app
LANGUAGE: Perl
SCALE: ~150 concurrent staff/applicants, ~12k applications/year
```

## 52. dictbuild — dictionary corpus compilation pipeline

```text
APP_DESCRIPTION: A data pipeline for a language reference publisher that compiles a dictionary corpus. It ingests marked-up entry sources, validates cross-references and sense links, applies typographic and encoding normalization, and generates print typesetting input and the searchable online edition dataset.
TECH_STACK: Perl + XML::LibXML + Unicode normalization + PostgreSQL + Template Toolkit, self-hosted
APP_TYPE: data pipeline
LANGUAGE: Perl
SCALE: ~350k headwords, full rebuild in under 30 minutes
```

## 53. hostpulse — uptime probe scheduler

```text
APP_DESCRIPTION: A data pipeline and daemon for a hosting provider that runs synthetic uptime checks. It schedules HTTP, TCP, and DNS probes against customer services from multiple vantage points, records latency and status, computes SLA uptime, and feeds outages to the alerting and status-page systems.
TECH_STACK: Perl + LWP + Net::DNS + forked workers + PostgreSQL + status feed, self-hosted
APP_TYPE: data pipeline
LANGUAGE: Perl
SCALE: ~40,000 checks, 60-second interval, 3 vantage points
```

## 54. gradesync — SIS grade export pipeline

```text
APP_DESCRIPTION: A data pipeline for a university registrar that moves final grades from the LMS into the student system. It pulls grade exports per course, validates against enrollment rosters, maps LMS scales to institutional grades, handles incompletes and change requests, and loads posted grades with a discrepancy report.
TECH_STACK: Perl + CSV/JSON parsers + Oracle + LMS API + cron, on-prem
APP_TYPE: data pipeline
LANGUAGE: Perl
SCALE: ~4,500 sections/term, batch runs during grading window
```

## 55. numscrub — data masking CLI for test refresh

```text
APP_DESCRIPTION: A CLI tool for a bank's DBA team that masks production data for test environments. It reads table and column masking rules, applies format-preserving masking to PII and account fields, maintains referential consistency across tables, and produces a masked extract plus a coverage report proving all sensitive columns were handled.
TECH_STACK: Perl CLI + DBI + Oracle/PostgreSQL + rule config + Getopt::Long, on-prem
APP_TYPE: CLI
LANGUAGE: Perl
SCALE: ~2,000 tables, ~500M rows, refresh within nightly window
```

## 56. mirrorward — package mirror sync CLI

```text
APP_DESCRIPTION: A CLI tool for a university that maintains a local mirror of Linux distribution repositories. It compares upstream metadata against the local mirror, downloads changed packages with bandwidth throttling, verifies checksums and signatures, prunes obsolete files, and reports sync deltas and disk usage.
TECH_STACK: Perl CLI + LWP::UserAgent + rsync + checksum verification + cron, self-hosted
APP_TYPE: CLI
LANGUAGE: Perl
SCALE: ~8 distributions, ~1.5 TB mirror, nightly delta sync
```

## 57. claimscrub — provider directory validation pipeline

```text
APP_DESCRIPTION: A data pipeline for a health plan that keeps its provider directory accurate. It ingests provider roster files from networks, validates NPIs and taxonomy codes, deduplicates practitioners across locations, flags stale entries, and produces a clean directory dataset plus an outreach worklist for verification.
TECH_STACK: Perl + CSV/fixed-width parsers + PostgreSQL + NPI registry lookups, on-prem batch
APP_TYPE: data pipeline
LANGUAGE: Perl
SCALE: ~400k provider records, weekly full validation
```

## 58. jobwarden — cron job orchestration dashboard

```text
APP_DESCRIPTION: An intranet web app for a data operations team that oversees batch job runs. It records job starts, completions, and exit codes reported by wrapper scripts, visualizes schedules and dependencies, alerts on missed or failed runs, and lets operators acknowledge and rerun jobs.
TECH_STACK: Perl (Mojolicious) + PostgreSQL + Template Toolkit + wrapper-script API, self-hosted
APP_TYPE: web app
LANGUAGE: Perl
SCALE: ~35 users, ~3,000 tracked jobs, ~15k runs/day
```

## 59. phylojoin — ortholog clustering pipeline

```text
APP_DESCRIPTION: A data pipeline for a comparative genomics group that clusters orthologous genes across species. It reads protein FASTA and pairwise similarity results, builds clusters by reciprocal best hits, annotates clusters with functional terms, and outputs cluster tables and per-species presence/absence matrices.
TECH_STACK: Perl + BioPerl + graph clustering routines + SQLite + HPC batch
APP_TYPE: data pipeline
LANGUAGE: Perl
SCALE: 60 genomes, ~1.2M proteins, full run in under 6 hours
```

## 60. dunning — accounts-receivable reminder pipeline

```text
APP_DESCRIPTION: A data pipeline for a B2B software vendor's finance team that runs dunning cycles. It reads open invoices and payment history, computes aging buckets, selects accounts for each reminder stage, generates escalating email and letter content, and logs communications for the collections audit trail.
TECH_STACK: Perl + DBI + PostgreSQL + Template Toolkit + SMTP + cron, self-hosted
APP_TYPE: data pipeline
LANGUAGE: Perl
SCALE: ~40k open invoices, daily dunning selection
```

## 61. spoolguard — spam quarantine digest pipeline

```text
APP_DESCRIPTION: A data pipeline for an email provider that sends users their quarantine digests. It reads quarantined-message metadata, groups by recipient, builds per-user digest emails with release links, dispatches them on each user's schedule, and processes release and delete actions submitted back from the links.
TECH_STACK: Perl + Email::MIME + PostgreSQL + Template Toolkit + release-token API, self-hosted
APP_TYPE: data pipeline
LANGUAGE: Perl
SCALE: ~300k mailboxes, ~120k digests/day
```

## 62. assetdepr — fixed asset depreciation batch

```text
APP_DESCRIPTION: A data pipeline for a manufacturer's accounting team that computes monthly depreciation. It reads the fixed-asset register, applies depreciation methods and useful-life schedules per asset class, handles disposals and partial-period acquisitions, and produces GL journal entries and depreciation schedules.
TECH_STACK: Perl + DBI + Oracle + depreciation rule tables, on-prem batch
APP_TYPE: data pipeline
LANGUAGE: Perl
SCALE: ~180k assets, monthly close batch
```

## 63. beacontail — IoT sensor ingest pipeline

```text
APP_DESCRIPTION: A data pipeline for an agricultural cooperative that ingests field sensor readings. It receives soil moisture, temperature, and weather telemetry over MQTT, validates and deduplicates readings, fills gaps, computes per-field rollups, and stores series feeding irrigation dashboards and alerts.
TECH_STACK: Perl + Net::MQTT + PostgreSQL/TimescaleDB + validation rules, self-hosted
APP_TYPE: data pipeline
LANGUAGE: Perl
SCALE: ~12,000 sensors, ~5M readings/day, 1-minute reporting
```

## 64. renderqueue — typesetting job API

```text
APP_DESCRIPTION: An API service for a book publisher that renders manuscript chapters into typeset PDFs. Clients submit markup and style parameters; the service queues jobs, runs the typesetting toolchain, returns proof PDFs and logs, and exposes status endpoints for the editorial front end.
TECH_STACK: Perl (Mojolicious) + job queue (Minion) + LaTeX toolchain + PostgreSQL, self-hosted
APP_TYPE: API service
LANGUAGE: Perl
SCALE: ~2,000 render jobs/day, ~30 req/sec status polling
```

## 65. flowtoll — interconnect settlement pipeline

```text
APP_DESCRIPTION: A data pipeline for a telecom carrier that settles interconnect traffic with partner networks. It reconciles outbound and inbound CDR summaries against partner statements, applies negotiated rates, computes net settlement amounts, flags disputes over tolerance, and generates settlement reports and invoices.
TECH_STACK: Perl + CSV/fixed-width parsers + PostgreSQL + rate agreements, on-prem batch
APP_TYPE: data pipeline
LANGUAGE: Perl
SCALE: 40 partners, ~30M CDR summaries/month, monthly settlement
```

## 66. shelfscan — ILS overdue notice pipeline

```text
APP_DESCRIPTION: A data pipeline for a public library that sends overdue and hold-ready notices. It reads circulation extracts, computes overdue items and fines by patron, respects notification preferences and quiet hours, and dispatches email and SMS notices while logging deliveries for staff follow-up.
TECH_STACK: Perl + DBI + MySQL + SMTP + SMS gateway + cron, on-prem
APP_TYPE: data pipeline
LANGUAGE: Perl
SCALE: ~250k patrons, ~15k notices/day
```

## 67. confmerge — device config template renderer CLI

```text
APP_DESCRIPTION: A CLI tool for a network engineering team that generates device configs from templates and an inventory. It reads a per-device variable inventory, renders vendor-specific config templates, validates required fields, and outputs deployable config files with a diff against current running configs.
TECH_STACK: Perl CLI + Template Toolkit + YAML inventory + Text::Diff + Getopt::Long
APP_TYPE: CLI
LANGUAGE: Perl
SCALE: ~2,500 devices, full render in under 5 minutes
```

## 68. rxcheck — pharmacy interaction screening API

```text
APP_DESCRIPTION: An API service for a pharmacy chain that screens prescriptions for interactions and dosing issues. It accepts a patient medication list and new prescription, checks against interaction and dosing rule databases, and returns severity-ranked warnings the dispensing system surfaces to pharmacists.
TECH_STACK: Perl (Mojolicious) + PostgreSQL rule tables + Redis cache + JSON API, on-prem
APP_TYPE: API service
LANGUAGE: Perl
SCALE: ~500k screenings/day, <100 ms p95 latency
```

## 69. crawlvault — web harvest capture pipeline

```text
APP_DESCRIPTION: A data pipeline for a national library's web archiving program that harvests scoped websites. It manages seed lists and crawl scopes, fetches pages with politeness rules, writes WARC files, extracts links for the frontier, and produces per-crawl coverage and error reports for curators.
TECH_STACK: Perl + LWP::UserAgent + WARC writer + PostgreSQL frontier + forked fetchers, self-hosted
APP_TYPE: data pipeline
LANGUAGE: Perl
SCALE: ~5,000 seeds/crawl, ~2M pages, weekly scheduled crawls
```

## 70. flexbill — subscription invoicing batch

```text
APP_DESCRIPTION: A data pipeline for a SaaS company's billing team that generates subscription invoices. It reads plan, usage, and proration data, computes charges, credits, and taxes, generates invoice records and PDFs, and produces a payment-gateway charge file plus revenue recognition entries.
TECH_STACK: Perl + DBI + PostgreSQL + PDF::API2 + tax rules + cron, self-hosted
APP_TYPE: data pipeline
LANGUAGE: Perl
SCALE: ~120k subscriptions, monthly and metered daily runs
```

## 71. filewatch — directory sync integrity CLI

```text
APP_DESCRIPTION: A CLI tool for a media production house that verifies large file transfers between storage tiers. It computes and compares checksums across source and destination trees, detects missing, truncated, or corrupted files after transfers, retries failures, and writes a verification manifest for chain-of-custody.
TECH_STACK: Perl CLI + File::Find + Digest::SHA + parallel workers + Getopt::Long
APP_TYPE: CLI
LANGUAGE: Perl
SCALE: ~500k files, up to 40 TB per verification run
```

## 72. votetally — election results aggregation pipeline

```text
APP_DESCRIPTION: A data pipeline for a county elections office that aggregates precinct results on election night. It ingests result files from tabulators as they arrive, validates against expected precinct and contest lists, aggregates totals by contest, and publishes progressive results feeds with a reconciliation report.
TECH_STACK: Perl + fixed-width/XML parsers + PostgreSQL + JSON feed generator, on-prem
APP_TYPE: data pipeline
LANGUAGE: Perl
SCALE: ~350 precincts, results refreshed every 2 minutes on election night
```

## 73. imgproxy-cache — image thumbnail generation API

```text
APP_DESCRIPTION: An API service for a photo-archive site that serves resized images on demand. It receives requests for a source image and size preset, generates and caches thumbnails, applies watermarks for previews, and serves cached variants; a background job pre-warms popular sizes.
TECH_STACK: Perl (Mojolicious) + Image::Magick + filesystem/Redis cache + Minion jobs, self-hosted
APP_TYPE: API service
LANGUAGE: Perl
SCALE: ~150 req/sec, ~4M source images, cache hit target 95%
```

## 74. porthunt — network service discovery pipeline

```text
APP_DESCRIPTION: A data pipeline for a security team that maintains an inventory of exposed network services. It scans assigned IP ranges for open ports and banners on a schedule, diffs against the known baseline, flags new or unexpected services, and feeds changes into the asset and ticketing systems.
TECH_STACK: Perl + Net::Ping + IO::Socket + forked scanners + PostgreSQL, self-hosted
APP_TYPE: data pipeline
LANGUAGE: Perl
SCALE: ~65,000 addresses, weekly full scan, daily delta on key ranges
```

## 75. transcode-farm — audio conversion job dispatcher

```text
APP_DESCRIPTION: A data pipeline for a radio broadcaster's archive that transcodes audio into delivery formats. It watches ingest folders, dispatches conversion jobs to worker nodes, tracks progress and failures, writes normalized output formats with embedded metadata, and reports daily throughput to archivists.
TECH_STACK: Perl + Minion job queue + ffmpeg wrappers + PostgreSQL + NFS storage, self-hosted
APP_TYPE: data pipeline
LANGUAGE: Perl
SCALE: ~8,000 files/day, 12 worker nodes
```

## 76. glubinvoice — freight invoice audit CLI

```text
APP_DESCRIPTION: A CLI tool for a shipper's logistics team that audits carrier freight invoices against contracted rates. It parses carrier EDI 210 invoices, recomputes expected charges from the rate agreement, flags overbillings and duplicate charges, and produces a dispute worklist with supporting detail.
TECH_STACK: Perl CLI + X12 210 parser + PostgreSQL rate tables + Getopt::Long
APP_TYPE: CLI
LANGUAGE: Perl
SCALE: ~30k invoices/month, batch audit runs
```

## 77. rosterweb — Catalyst volunteer scheduling app

```text
APP_DESCRIPTION: A legacy web app for a nonprofit hospital auxiliary that schedules volunteers. Coordinators post shifts, volunteers self-sign-up subject to role and clearance rules, the system tracks hours and certifications, sends shift reminders, and produces coverage and hours reports for administrators.
TECH_STACK: Perl (Catalyst) + DBIx::Class + PostgreSQL + Template Toolkit + email, self-hosted
APP_TYPE: web app
LANGUAGE: Perl
SCALE: ~2,500 volunteers, ~30 req/sec peak, ~1,500 shifts/week
```

## 78. dnsblfeed — reputation list build pipeline

```text
APP_DESCRIPTION: A data pipeline for an anti-abuse provider that builds DNS blocklist zones from abuse signals. It ingests spam trap hits, honeypot data, and partner feeds, scores IPs and domains by rules and decay, promotes and expires entries, and publishes zone files and export feeds to subscribers.
TECH_STACK: Perl + scoring engine + PostgreSQL + Net::DNS zone writers + rsync, self-hosted
APP_TYPE: data pipeline
LANGUAGE: Perl
SCALE: ~40M tracked entries, 5-minute publish cycle
```

## 79. copybook-gen — data dictionary generator CLI

```text
APP_DESCRIPTION: A CLI tool for a data integration team that generates parsers and documentation from COBOL copybooks. It parses copybook definitions, resolves REDEFINES and OCCURS clauses, and emits Perl unpack templates, field maps, and human-readable layout docs for downstream ETL jobs.
TECH_STACK: Perl CLI + custom copybook grammar + Template Toolkit + Getopt::Long
APP_TYPE: CLI
LANGUAGE: Perl
SCALE: ~800 copybooks, regenerate full set in under 2 minutes
```

## 80. shiftsum — call center metrics pipeline

```text
APP_DESCRIPTION: A data pipeline for a contact center operations team that compiles agent and queue metrics. It ingests ACD event exports, reconstructs call and agent-state timelines, computes handle time, occupancy, and service-level metrics per queue and interval, and loads them for workforce reports and dashboards.
TECH_STACK: Perl + CSV parsers + PostgreSQL + interval rollups + cron, self-hosted
APP_TYPE: data pipeline
LANGUAGE: Perl
SCALE: ~1,500 agents, ~400k events/day, 15-minute interval rollups
```

## 81. safecheck — food inspection scheduling app

```text
APP_DESCRIPTION: A web app for a county health department that schedules and records food establishment inspections. Inspectors view assigned routes, record violations against a code checklist offline-then-sync, and the system computes risk-based reinspection dates and generates public inspection reports.
TECH_STACK: Perl (Dancer2) + PostgreSQL + Template Toolkit + REST sync endpoint, self-hosted
APP_TYPE: web app
LANGUAGE: Perl
SCALE: ~60 inspectors, ~9,000 establishments, ~500 inspections/week
```

## 82. lipidflow — mass-spec results processing pipeline

```text
APP_DESCRIPTION: A data pipeline for a metabolomics lab that processes mass spectrometry output. It reads instrument peak lists, aligns features across samples, matches masses against compound libraries with tolerance, normalizes intensities, and outputs annotated feature tables for statistical analysis.
TECH_STACK: Perl + numeric processing modules + SQLite compound library + HPC batch
APP_TYPE: data pipeline
LANGUAGE: Perl
SCALE: ~500 samples/batch, ~20k features/sample
```

## 83. warmcache — CDN purge orchestration API

```text
APP_DESCRIPTION: An API service for a publishing platform that coordinates cache purges across edge nodes. It accepts purge requests by URL or tag, fans them out to edge caches, tracks completion per node, retries failures, and returns aggregated status; it also schedules pre-warm fetches after purges.
TECH_STACK: Perl (Mojolicious) + Redis job state + HTTP fanout + Minion workers, self-hosted
APP_TYPE: API service
LANGUAGE: Perl
SCALE: ~40 edge nodes, ~5k purge requests/hour
```

## 84. lien-scan — property records ingest pipeline

```text
APP_DESCRIPTION: A data pipeline for a county recorder's office that indexes recorded property documents. It ingests document metadata and OCR text from the imaging system, parses grantor/grantee and legal descriptions, links to parcels, and loads a searchable index with an exceptions queue for unmatched documents.
TECH_STACK: Perl + text parsers + PostgreSQL full-text + parcel lookups + cron, on-prem
APP_TYPE: data pipeline
LANGUAGE: Perl
SCALE: ~8,000 documents/day, next-day searchability
```

## 85. throttlelog — API usage metering pipeline

```text
APP_DESCRIPTION: A data pipeline for an API platform that meters customer usage for rate limiting and billing. It streams gateway access logs, aggregates calls per API key and endpoint into time buckets, enforces plan quotas by feeding counters back to the gateway, and produces monthly usage invoices data.
TECH_STACK: Perl + log tailers + Redis counters + PostgreSQL rollups, self-hosted
APP_TYPE: data pipeline
LANGUAGE: Perl
SCALE: ~200M API calls/day, 1-minute aggregation
```

## 86. seedbank — accession catalog CLI

```text
APP_DESCRIPTION: A CLI tool for an agricultural gene bank that manages seed accession records. It imports collection spreadsheets, validates taxonomy and accession-number rules, tracks storage location and viability test schedules, flags accessions due for regeneration, and exports catalog reports for curators.
TECH_STACK: Perl CLI + Spreadsheet::ParseExcel + SQLite + Getopt::Long
APP_TYPE: CLI
LANGUAGE: Perl
SCALE: ~120k accessions, weekly imports
```

## 87. mailflow-mta — mail queue analytics pipeline

```text
APP_DESCRIPTION: A data pipeline for an email service provider that analyzes MTA queue and delivery logs. It parses Postfix/Exim logs across mail servers, correlates message lifecycle events, computes deferral, bounce, and delivery-time metrics per destination domain, and surfaces deliverability problems to the ops team.
TECH_STACK: Perl + log parsers + PostgreSQL + correlation engine + cron, self-hosted
APP_TYPE: data pipeline
LANGUAGE: Perl
SCALE: ~12 mail servers, ~30M log events/day, hourly rollups
```

## 88. paycard-recon — settlement reconciliation batch

```text
APP_DESCRIPTION: A data pipeline for a payment processor's operations team that reconciles card settlements. It ingests network settlement and acquirer files, matches transactions to authorizations, computes fees and net funding, flags mismatches and chargebacks, and produces funding and exception reports for finance.
TECH_STACK: Perl + fixed-width parsers + Oracle + matching rules, on-prem batch
APP_TYPE: data pipeline
LANGUAGE: Perl
SCALE: ~10M transactions/day, daily settlement cycle
```

## 89. wikiharvest — content migration pipeline

```text
APP_DESCRIPTION: A data pipeline for a technical publisher migrating a legacy wiki into a new CMS. It reads exported wiki markup and attachments, converts markup to the target format, rewrites internal links, preserves revision history, and loads content into the CMS with a migration report of unconverted constructs.
TECH_STACK: Perl + markup parsers + XML::LibXML + CMS REST API + PostgreSQL tracking, self-hosted
APP_TYPE: data pipeline
LANGUAGE: Perl
SCALE: ~80k pages, one-time migration with reruns
```

## 90. queuemon — printer supply telemetry CLI

```text
APP_DESCRIPTION: A CLI tool for a managed print services provider that monitors fleet printer supplies. It polls printers over SNMP for toner and part counters, predicts depletion from usage trends, generates proactive supply-order and service-call worklists, and emails per-customer supply status summaries.
TECH_STACK: Perl CLI + Net::SNMP + SQLite trend store + SMTP + cron, self-hosted
APP_TYPE: CLI
LANGUAGE: Perl
SCALE: ~14,000 printers across ~600 customer sites, daily poll
```

## 91. bookclose — general ledger close pipeline

```text
APP_DESCRIPTION: A data pipeline for a retail group's accounting team that runs the month-end GL close. It gathers subledger extracts, validates that they balance, applies allocation and accrual rules, posts consolidating journal entries, and produces trial balance and variance reports for controllers.
TECH_STACK: Perl + DBI + Oracle + allocation rule tables + cron, on-prem batch
APP_TYPE: data pipeline
LANGUAGE: Perl
SCALE: ~40 legal entities, monthly close over 2-day window
```

## 92. streamcue — video ingest metadata pipeline

```text
APP_DESCRIPTION: A data pipeline for a broadcaster's media asset system that catalogs ingested video. It watches ingest storage, extracts technical and embedded metadata, generates checksums and proxy-render requests, matches to program schedules, and registers assets in the MAM with a QC exception list.
TECH_STACK: Perl + mediainfo wrappers + Minion jobs + PostgreSQL + NFS, self-hosted
APP_TYPE: data pipeline
LANGUAGE: Perl
SCALE: ~1,500 assets/day, files up to 200 GB
```

## 93. holdscan — interlibrary loan routing pipeline

```text
APP_DESCRIPTION: A data pipeline for a library consortium that routes interlibrary loan requests. It reads incoming ILL requests, checks holdings and availability across member libraries by lending rules, selects the best lender, generates pull slips and shipping labels, and tracks request status across the network.
TECH_STACK: Perl + DBI + MySQL + Template Toolkit + member API integration, on-prem
APP_TYPE: data pipeline
LANGUAGE: Perl
SCALE: 45 member libraries, ~6,000 requests/day
```

## 94. authproxy — legacy SSO shim API

```text
APP_DESCRIPTION: An API service for an enterprise that bridges old applications to modern single sign-on. It validates SAML and OIDC tokens from the identity provider, maps identities to legacy application roles, issues short-lived session cookies old apps understand, and logs authentication events for audit.
TECH_STACK: Perl (Mojolicious) + Net::SAML2 + JWT + Redis sessions, self-hosted
APP_TYPE: API service
LANGUAGE: Perl
SCALE: ~30,000 users, ~300 auth req/sec peak
```

## 95. gridfeed — smart meter reading pipeline

```text
APP_DESCRIPTION: A data pipeline for an electric utility that processes smart meter interval reads. It ingests AMI head-end exports, validates and estimates missing intervals, aggregates to billing determinants, detects tamper and outage flags, and feeds the billing and outage-management systems.
TECH_STACK: Perl + fixed-width/XML parsers + PostgreSQL/TimescaleDB + validation rules, on-prem batch
APP_TYPE: data pipeline
LANGUAGE: Perl
SCALE: ~800k meters, 15-minute intervals, hourly ingest
```

## 96. redactor — document PII scrubbing CLI

```text
APP_DESCRIPTION: A CLI tool for a law firm's records team that redacts sensitive data from document exports. It scans text and OCR layers for patterns like SSNs, account numbers, and named parties from a rules list, applies redactions, produces redacted PDFs and a redaction log, and flags low-confidence matches for review.
TECH_STACK: Perl CLI + regex/NER rules + PDF::API2 + SQLite log + Getopt::Long
APP_TYPE: CLI
LANGUAGE: Perl
SCALE: ~20k documents/batch, matter-driven runs
```

## 97. slotplan — clinic appointment reminder pipeline

```text
APP_DESCRIPTION: A data pipeline for a multi-site dental group that sends appointment reminders and manages confirmations. It reads scheduling extracts, computes upcoming appointments per preferences, dispatches SMS, email, and voice reminders, processes confirm/cancel replies, and produces no-show risk and open-slot reports.
TECH_STACK: Perl + DBI + PostgreSQL + SMS/voice gateway APIs + cron, self-hosted
APP_TYPE: data pipeline
LANGUAGE: Perl
SCALE: ~40 clinics, ~25k reminders/day
```

## 98. flowdiff — schema migration diff CLI

```text
APP_DESCRIPTION: A CLI tool for a database team that compares schemas across environments and generates migration scripts. It introspects source and target databases, diffs tables, columns, indexes, and constraints, and emits ordered DDL migration and rollback scripts with a summary of risky changes.
TECH_STACK: Perl CLI + DBI + PostgreSQL/MySQL introspection + Template Toolkit + Getopt::Long
APP_TYPE: CLI
LANGUAGE: Perl
SCALE: schemas up to ~2,000 objects, seconds-scale diff runs
```

## 99. subscribertrack — ISP provisioning reporting app

```text
APP_DESCRIPTION: An intranet web app for a regional ISP that reports on subscriber provisioning and network assignments. Support and field staff look up subscriber circuits, IP assignments, and modem status, view provisioning history, and managers pull churn, activation, and capacity reports by region.
TECH_STACK: Perl (Mojolicious) + PostgreSQL + Template Toolkit + RADIUS/DHCP data feeds + LDAP auth, self-hosted
APP_TYPE: web app
LANGUAGE: Perl
SCALE: ~120 staff users, ~40 req/sec, ~180k subscribers
```

## 100. corpustag — text annotation batch pipeline

```text
APP_DESCRIPTION: A data pipeline for a computational linguistics group that annotates a text corpus. It reads raw document collections, tokenizes and sentence-splits with language-specific rules, applies part-of-speech and named-entity tagging, and outputs standoff annotation files plus corpus statistics for researchers.
TECH_STACK: Perl + Unicode tokenizers + Lingua modules + SQLite index + HPC batch
APP_TYPE: data pipeline
LANGUAGE: Perl
SCALE: ~5M documents, ~2 billion tokens, full run over 8 hours
```
