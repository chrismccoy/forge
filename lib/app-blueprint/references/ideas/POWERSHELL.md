# PowerShell Blueprint Types — Copy-Paste Input Sets

Copy a fenced block into the prompt as-is, or swap individual fields.

## 1. OffboardOps — employee offboarding runbook

```text
APP_DESCRIPTION: A CLI runbook for an enterprise IT service desk that executes employee offboarding end to end. It disables the AD account, revokes Entra ID sessions, converts the mailbox to shared, transfers OneDrive ownership to the manager, removes group memberships, and emits a signed completion report for HR.
TECH_STACK: PowerShell 7 + Microsoft.Graph + ExchangeOnlineManagement + ActiveDirectory module + Pester tests, distributed as internal repo module, run by service desk
APP_TYPE: CLI
LANGUAGE: PowerShell
SCALE: 12 service-desk operators, 18,000 employees, ~40 offboardings/week
```

## 2. GroupGroom — AD group hygiene auditor

```text
APP_DESCRIPTION: A CLI tool for a manufacturing conglomerate's directory team that audits Active Directory group sprawl. It finds empty groups, circular nesting, groups with no manager, token-bloat risks from deep nesting, and unused groups with no recent access, then produces a remediation worksheet with owner sign-off columns.
TECH_STACK: Windows PowerShell 5.1 + ActiveDirectory module + ImportExcel for worksheets + PSScriptAnalyzer in CI, internal repo module
APP_TYPE: CLI
LANGUAGE: PowerShell
SCALE: 3 directory admins, 45,000 groups across 6 domains, weekly run
```

## 3. StaleSweep — dormant computer account reporter

```text
APP_DESCRIPTION: A CLI tool for a school district's IT office that reports dormant computer accounts across campuses. It compares lastLogonTimestamp against a per-OU staleness policy, cross-checks the asset database export, flags machines still under warranty, and stages disable/move actions behind a dry-run gate.
TECH_STACK: Windows PowerShell 5.1 + ActiveDirectory module + CSV asset-db import + scheduled task on a management server
APP_TYPE: CLI
LANGUAGE: PowerShell
SCALE: 4 technicians, 22,000 computer accounts, 60 school sites, monthly run
```

## 4. GpoLens — Group Policy documentation generator

```text
APP_DESCRIPTION: A CLI tool for a county government IT department that documents and diffs Group Policy. It exports every GPO to HTML and XML, detects unlinked and duplicate GPOs, diffs settings between change-control snapshots, and produces an auditor-ready policy binder each quarter.
TECH_STACK: Windows PowerShell 5.1 + GroupPolicy module + ImportExcel + scheduled task, reports to a document library share
APP_TYPE: CLI
LANGUAGE: PowerShell
SCALE: 2 policy admins, 640 GPOs, 9,000 managed endpoints, quarterly binder
```

## 5. ExpiryHerald — password expiry notifier pipeline

```text
APP_DESCRIPTION: A data pipeline for a regional insurance carrier that warns users before AD password expiry. Nightly it computes days-to-expiry per user against fine-grained password policies, sends branded reminder emails at 14/7/2 days, escalates VIP accounts to the service desk, and logs delivery outcomes for compliance.
TECH_STACK: Windows PowerShell 5.1 + ActiveDirectory module + Send-MgUserMail via Microsoft.Graph + scheduled task, config in JSON
APP_TYPE: data pipeline
LANGUAGE: PowerShell
SCALE: 6,500 users, nightly run, ~300 notifications/day
```

## 6. PrivWatch — privileged group change sentinel

```text
APP_DESCRIPTION: A data pipeline for a bank's security operations team that watches privileged AD groups for membership drift. Every 15 minutes it snapshots Domain Admins, Enterprise Admins, and 40 delegated admin groups, diffs against the approved-membership baseline, alerts on unapproved additions, and appends every change to a tamper-evident audit log.
TECH_STACK: PowerShell 7 + ActiveDirectory module + JSON baseline store + SMTP alerting + scheduled task cluster, Pester + PSScriptAnalyzer in CI
APP_TYPE: data pipeline
LANGUAGE: PowerShell
SCALE: 43 monitored groups, 96 runs/day, 12,000-user forest
```

## 7. MailboxMeter — Exchange Online capacity reporter

```text
APP_DESCRIPTION: A CLI tool for a law firm's messaging team that reports Exchange Online mailbox growth. It collects mailbox and archive sizes, item counts, and quota headroom, trends growth per practice group, flags mailboxes within 10% of quota, and writes a partner-readable Excel workbook with charts.
TECH_STACK: PowerShell 7 + ExchangeOnlineManagement + ImportExcel + certificate-based app auth, scheduled task on a utility VM
APP_TYPE: CLI
LANGUAGE: PowerShell
SCALE: 2 messaging admins, 3,200 mailboxes, weekly report
```

## 8. ShareScope — shared mailbox permission auditor

```text
APP_DESCRIPTION: A CLI tool for a health insurer's compliance team that audits shared mailbox access. It enumerates FullAccess, SendAs, and SendOnBehalf grants across all shared mailboxes, resolves group grants to individual users, flags terminated-user grants and cross-department access, and exports evidence packs for HIPAA access reviews.
TECH_STACK: PowerShell 7 + ExchangeOnlineManagement + Microsoft.Graph for HR-status lookup + ImportExcel, internal PSGallery repo
APP_TYPE: CLI
LANGUAGE: PowerShell
SCALE: 5 compliance reviewers, 1,900 shared mailboxes, quarterly review cycle
```

## 9. TraceTally — mail flow analytics pipeline

```text
APP_DESCRIPTION: A data pipeline for a logistics company's messaging team that turns Exchange Online message traces into daily mail-flow analytics. It pages through message trace data, aggregates volumes by connector, domain, and verdict, tracks delivery latency percentiles, and publishes a morning dashboard workbook for the ops channel.
TECH_STACK: PowerShell 7 + ExchangeOnlineManagement Get-MessageTraceV2 + ImportExcel + scheduled task, results archived to a file share
APP_TYPE: data pipeline
LANGUAGE: PowerShell
SCALE: ~450,000 messages/day traced, 1 nightly run, 90-day rolling archive
```

## 10. ListLaundry — distribution list cleanup assistant

```text
APP_DESCRIPTION: A CLI tool for a university's collaboration team that cleans up distribution lists. It finds lists with no owner, no members, or no mail received in 180 days, emails owners a keep-or-retire ballot with a one-click reply, and stages retirements with a 30-day soft-delete window and restore command.
TECH_STACK: PowerShell 7 + ExchangeOnlineManagement + Microsoft.Graph mail + JSON state file, internal repo module run monthly
APP_TYPE: CLI
LANGUAGE: PowerShell
SCALE: 3 admins, 8,400 distribution lists, 55,000 mailboxes, monthly cycle
```

## 11. TeamReaper — stale Teams lifecycle manager

```text
APP_DESCRIPTION: A CLI tool for an engineering firm's M365 team that manages the Microsoft Teams lifecycle. It scores each team on channel activity, file changes, and membership churn, notifies owners of inactive teams, applies expiration extensions for project teams with active contracts, and archives teams past their retention grace period.
TECH_STACK: PowerShell 7 + Microsoft.Graph (Teams, Groups, Reports) + certificate app-only auth + Pester, scheduled task
APP_TYPE: CLI
LANGUAGE: PowerShell
SCALE: 2 operators, 4,700 teams, 12,000 users, monthly lifecycle pass
```

## 12. SiteSizer — SharePoint storage governor

```text
APP_DESCRIPTION: A CLI tool for a retail chain's collaboration admins that governs SharePoint Online storage. It inventories site collections with size, quota, version-history bloat, and owner info, identifies the top storage growers month over month, and produces chargeback figures per business unit.
TECH_STACK: PowerShell 7 + PnP.PowerShell + Microsoft.Graph + ImportExcel chargeback workbook, scheduled task on admin VM
APP_TYPE: CLI
LANGUAGE: PowerShell
SCALE: 3 admins, 2,600 site collections, 38 TB tenant storage, monthly run
```

## 13. DriveHandoff — OneDrive departure transfer tool

```text
APP_DESCRIPTION: A CLI tool for an MSP's service delivery team that handles OneDrive data when client employees leave. It grants delegated access to the manager, inventories file counts and sizes, kicks off a structured copy of flagged folders to a team site, and confirms retention-hold status before the account is purged.
TECH_STACK: PowerShell 7 + Microsoft.Graph + PnP.PowerShell + per-tenant certificate auth vault, packaged as internal PSGallery module
APP_TYPE: CLI
LANGUAGE: PowerShell
SCALE: 8 MSP technicians, 60 client tenants, ~120 departures/month
```

## 14. LicenseLedger — M365 license optimization pipeline

```text
APP_DESCRIPTION: A data pipeline for a hospital network's IT finance team that optimizes Microsoft 365 licensing. Weekly it joins license assignments with last-activity data per workload, finds unused E5 features and disabled-user licenses, models downgrade savings, and emits a reclaim worklist plus a CFO summary workbook.
TECH_STACK: PowerShell 7 + Microsoft.Graph (users, subscribedSkus, reports) + ImportExcel + scheduled task, Pester-tested module
APP_TYPE: data pipeline
LANGUAGE: PowerShell
SCALE: 28,000 licensed users, 14 SKU types, weekly run, ~$310k/yr reclaim target
```

## 15. GuestGate — Entra guest access reviewer

```text
APP_DESCRIPTION: A CLI tool for a biotech company's identity team that reviews Entra ID guest accounts. It lists guests by sponsor, last sign-in, and group/site access, flags guests from unapproved domains and those idle over 90 days, mails sponsors an attestation request, and disables unattested guests after the grace period.
TECH_STACK: PowerShell 7 + Microsoft.Graph (identity, signIns, accessReviews) + JSON policy file + scheduled task, internal repo
APP_TYPE: CLI
LANGUAGE: PowerShell
SCALE: 2 identity admins, 5,800 guest accounts, 340 sponsor attestations/quarter
```

## 16. PolicyPlate — conditional access documenter

```text
APP_DESCRIPTION: A CLI tool for a credit union's security team that documents Entra conditional access. It exports every CA policy to versioned JSON, renders a plain-English policy matrix (who, what app, what condition, what control), diffs against the last approved snapshot, and flags policies in report-only mode older than 30 days.
TECH_STACK: PowerShell 7 + Microsoft.Graph identity.signIns + Git-backed snapshot folder + ImportExcel matrix, run from admin workstation
APP_TYPE: CLI
LANGUAGE: PowerShell
SCALE: 3 security engineers, 74 CA policies, 4,200 users, weekly diff
```

## 17. MfaMuster — MFA registration compliance reporter

```text
APP_DESCRIPTION: A data pipeline for a state university system that reports MFA registration compliance across campuses. Nightly it pulls authentication method registration details, segments by campus and role, tracks weak-method holdouts (SMS-only, none), and feeds per-campus compliance scorecards to IT directors.
TECH_STACK: PowerShell 7 + Microsoft.Graph reports API + ImportExcel scorecards + scheduled task on automation server
APP_TYPE: data pipeline
LANGUAGE: PowerShell
SCALE: 96,000 accounts across 8 campuses, nightly run, 92% compliance target
```

## 18. CostCourier — Azure spend digest pipeline

```text
APP_DESCRIPTION: A data pipeline for a SaaS company's platform team that digests Azure spend. Each morning it queries cost data grouped by subscription, resource group, and cost-center tag, detects day-over-day anomalies beyond forecast bands, attributes spikes to specific resources, and posts a digest workbook and alert summary.
TECH_STACK: PowerShell 7 + Az.CostManagement + Az.Accounts service principal + ImportExcel + scheduled task, alerting via SMTP
APP_TYPE: data pipeline
LANGUAGE: PowerShell
SCALE: 34 subscriptions, ~$220k/month spend, 1 run/day, 15% anomaly threshold
```

## 19. TagWarden — Azure tag policy enforcer

```text
APP_DESCRIPTION: A CLI tool for a media company's cloud governance team that enforces Azure resource tagging. It scans all resources for missing or malformed owner, environment, and cost-center tags, inherits tags from resource groups where safe, produces a violations report per team, and applies fixes only in explicit remediation mode.
TECH_STACK: PowerShell 7 + Az.Resources + JSON tag policy schema + Pester + PSScriptAnalyzer, run via scheduled task and on demand
APP_TYPE: CLI
LANGUAGE: PowerShell
SCALE: 4 governance engineers, 21,000 resources, 28 subscriptions, weekly sweep
```

## 20. NsgNanny — network security group rule auditor

```text
APP_DESCRIPTION: A CLI tool for a fintech's cloud security team that audits Azure NSG and firewall rules. It flags any-any rules, management ports exposed to the internet, rules unused according to flow logs, and drift from the approved rule baseline per environment, then emits a ranked findings report with owner assignments.
TECH_STACK: PowerShell 7 + Az.Network + Az.Monitor flow-log queries + YAML baseline files + ImportExcel findings, internal repo module
APP_TYPE: CLI
LANGUAGE: PowerShell
SCALE: 3 cloud security engineers, 190 NSGs, 4,100 rules, weekly audit
```

## 21. OrphanHunt — abandoned Azure resource finder

```text
APP_DESCRIPTION: A CLI tool for an e-commerce company's FinOps team that finds abandoned Azure resources. It detects unattached disks, orphaned NICs and public IPs, empty App Service plans, and stopped-but-allocated VMs, prices each finding monthly, and generates a cleanup proposal grouped by owning team with estimated savings.
TECH_STACK: PowerShell 7 + Az.Compute/Az.Network/Az.Websites + Azure Retail Prices API lookup + ImportExcel, monthly scheduled run
APP_TYPE: CLI
LANGUAGE: PowerShell
SCALE: 2 FinOps analysts, 26 subscriptions, ~14,000 resources scanned/run, monthly
```

## 22. VaultVerify — Azure backup restore validator

```text
APP_DESCRIPTION: A CLI tool for a payroll processor's infrastructure team that validates Azure Backup actually restores. It checks last-backup status for every protected VM and database, performs a rotating sample of test restores into an isolated resource group, verifies disk mount and service start, and files a signed restore-evidence report.
TECH_STACK: PowerShell 7 + Az.RecoveryServices + Az.Compute + Pester assertions on restored VMs + scheduled task, evidence to blob storage
APP_TYPE: CLI
LANGUAGE: PowerShell
SCALE: 380 protected VMs, 12 test restores/week, 100% weekly status coverage
```

## 23. IntuneInspector — device compliance reporter

```text
APP_DESCRIPTION: A data pipeline for a national retailer's endpoint team that reports Intune device compliance across stores. Nightly it pulls device compliance states, groups failures by policy and store region, distinguishes stale check-ins from true failures, and feeds regional IT leads a store-ranked remediation list.
TECH_STACK: PowerShell 7 + Microsoft.Graph deviceManagement + ImportExcel + scheduled task on automation server, Pester in CI
APP_TYPE: data pipeline
LANGUAGE: PowerShell
SCALE: 31,000 managed devices, 1,150 stores, nightly run, 95% compliance SLA
```

## 24. AppRollcall — Intune app deployment tracker

```text
APP_DESCRIPTION: A CLI tool for a pharmaceutical company's packaging team that tracks Intune application rollouts. It reports install status per app and ring, correlates failures by error code and device model, compares rollout velocity against the deployment plan, and flags apps stuck below threshold so the ring promotion pauses.
TECH_STACK: PowerShell 7 + Microsoft.Graph deviceAppManagement + JSON ring-plan config + ImportExcel status workbook, on-demand and scheduled
APP_TYPE: CLI
LANGUAGE: PowerShell
SCALE: 4 packagers, 240 managed apps, 9,800 devices, 3 rings, daily status run
```

## 25. HashHarvest — Autopilot enrollment prep tool

```text
APP_DESCRIPTION: A CLI tool for an MSP's deployment bench that collects and registers Windows Autopilot hardware hashes. It gathers hashes from machines on the bench network, validates them against the client's device naming and group-tag scheme, uploads to the correct client tenant, and confirms profile assignment before the device ships.
TECH_STACK: PowerShell 7 + Microsoft.Graph deviceManagement + WindowsAutopilotIntune module + per-tenant app registrations, USB-bootable script package
APP_TYPE: CLI
LANGUAGE: PowerShell
SCALE: 6 bench technicians, 45 client tenants, ~900 devices registered/month
```

## 26. PatchProof — patch compliance evidence pipeline

```text
APP_DESCRIPTION: A data pipeline for a utility company's security office that produces patch compliance evidence for regulators. Weekly it merges Windows Update status from endpoints, WSUS approval state, and vulnerability scanner exports, computes compliance per CVE severity and business system, and generates the NERC-audit evidence package.
TECH_STACK: Windows PowerShell 5.1 + PSWindowsUpdate remote queries + WSUS API + CSV scanner import + ImportExcel evidence pack, scheduled task
APP_TYPE: data pipeline
LANGUAGE: PowerShell
SCALE: 5,400 servers and workstations, weekly run, 14-day critical-patch SLA
```

## 27. WsusJanitor — update server maintenance tool

```text
APP_DESCRIPTION: A CLI tool for a hospital's infrastructure team that maintains WSUS health. It declines superseded and expired updates, removes obsolete content files, reindexes the SUSDB, verifies downstream server sync freshness, and reports reclaimed disk and catalog size trends after each maintenance pass.
TECH_STACK: Windows PowerShell 5.1 + UpdateServices module + SQL Server maintenance via dbatools + scheduled task, HTML run report
APP_TYPE: CLI
LANGUAGE: PowerShell
SCALE: 1 primary + 4 downstream WSUS servers, 6,800 clients, monthly maintenance
```

## 28. RestoreRehearse — SQL backup verification pipeline

```text
APP_DESCRIPTION: A data pipeline for a community bank's DBA team that proves SQL Server backups restore. Nightly it inventories backup chains across instances, restores a rotating sample to a scratch instance, runs DBCC CHECKDB on the restored copy, and records restore duration and integrity results in a compliance ledger.
TECH_STACK: PowerShell 7 + dbatools (Test-DbaLastBackup) + SQL Server scratch instance + scheduled task, ledger in a SQL table + ImportExcel monthly report
APP_TYPE: data pipeline
LANGUAGE: PowerShell
SCALE: 42 instances, 610 databases, 8 test restores/night, 6 TB largest database
```

## 29. IndexIroner — SQL index maintenance orchestrator

```text
APP_DESCRIPTION: A CLI tool for a freight brokerage's DBA that orchestrates SQL index and statistics maintenance. It measures fragmentation, chooses reorganize vs rebuild per index against thresholds and edition capabilities, respects maintenance windows per instance, and logs before/after fragmentation and duration per object.
TECH_STACK: Windows PowerShell 5.1 + dbatools + Ola Hallengren integration + per-instance JSON window config + SQL Agent-launched, PSScriptAnalyzer-clean
APP_TYPE: CLI
LANGUAGE: PowerShell
SCALE: 1 DBA, 28 instances, ~19,000 indexes, nightly 4-hour window
```

## 30. AgHeartbeat — availability group health checker

```text
APP_DESCRIPTION: A CLI tool for a claims processor's database team that checks SQL Server Always On availability group health. It validates synchronization state, redo and send queue sizes, failover readiness per replica, listener DNS correctness, and quorum health, then produces a go/no-go patching readiness report.
TECH_STACK: PowerShell 7 + dbatools + FailoverClusters module + scheduled task every 15 minutes + SMTP alerts, Pester smoke tests
APP_TYPE: CLI
LANGUAGE: PowerShell
SCALE: 9 availability groups, 22 replicas, 96 checks/day, 60-second RPO target
```

## 31. LoginLedger — SQL Server access auditor

```text
APP_DESCRIPTION: A CLI tool for an accounting firm's data team that audits SQL Server logins and permissions. It inventories logins, orphaned users, sysadmin members, and direct table grants across instances, diffs against the approved access matrix, and produces the quarterly SOX access-review evidence with reviewer sign-off fields.
TECH_STACK: PowerShell 7 + dbatools + CSV access matrix + ImportExcel evidence workbook, internal repo module, run quarterly
APP_TYPE: CLI
LANGUAGE: PowerShell
SCALE: 2 auditors, 35 instances, ~4,800 logins reviewed/quarter
```

## 32. BindingBinder — IIS site and certificate inventory

```text
APP_DESCRIPTION: A CLI tool for a hosting provider's web operations team that inventories IIS estates. It collects sites, bindings, app pools, runtime versions, and certificate thumbprints from every web server, flags expired or SHA-1 certificates and app pools running as over-privileged accounts, and renders a fleet-wide HTML inventory.
TECH_STACK: Windows PowerShell 5.1 + WebAdministration/IISAdministration modules over PSRemoting + HTML report + scheduled task
APP_TYPE: CLI
LANGUAGE: PowerShell
SCALE: 3 web ops engineers, 140 IIS servers, ~2,300 sites, weekly inventory
```

## 33. CertSentry — certificate expiry watch pipeline

```text
APP_DESCRIPTION: A data pipeline for a telecom's PKI team that watches certificate expiry everywhere. Daily it scans machine stores across servers, TLS endpoints on internal load balancers, and Key Vault certificates, deduplicates by thumbprint, assigns owners from a CMDB export, and opens renewal tickets at 30/14/7 days out.
TECH_STACK: PowerShell 7 + PSRemoting store scans + Az.KeyVault + REST ticketing integration + CMDB CSV join, scheduled task, Pester in CI
APP_TYPE: data pipeline
LANGUAGE: PowerShell
SCALE: 1,900 servers scanned, ~8,200 certificates tracked, 1 run/day
```

## 34. IssuanceIndex — internal CA activity reporter

```text
APP_DESCRIPTION: A CLI tool for an aerospace manufacturer's PKI admins that reports internal CA issuance activity. It queries the CA database for issued, revoked, and failed requests, breaks down volume by template and requester, flags templates with dangerous ACLs or enrollee-supplies-subject settings, and trends issuance for capacity planning.
TECH_STACK: Windows PowerShell 5.1 + PSPKI module + ADCS template ACL analysis + ImportExcel, run monthly from PKI admin workstation
APP_TYPE: CLI
LANGUAGE: PowerShell
SCALE: 2 PKI admins, 2 issuing CAs, ~5,600 certs issued/month, 34 templates
```

## 35. ServiceShepherd — Windows service watchdog

```text
APP_DESCRIPTION: A CLI tool for a casino resort's IT operations that keeps critical Windows services healthy. It checks a manifest of must-run services across property systems, restarts failed services with backoff and dependency ordering, refuses restarts during declared change freezes, and logs every action with before/after state.
TECH_STACK: Windows PowerShell 5.1 + PSRemoting + JSON service manifest + Windows event log writes + scheduled task every 5 minutes
APP_TYPE: CLI
LANGUAGE: PowerShell
SCALE: 260 servers, 41 critical services watched, 288 runs/day
```

## 36. TaskTakestock — scheduled task fleet inventory

```text
APP_DESCRIPTION: A CLI tool for an energy trading firm's platform team that inventories scheduled tasks across servers. It collects every task's trigger, run-as account, action path, and last result, flags tasks running as personal accounts or from world-writable paths, and diffs the fleet against last month's baseline to catch unauthorized additions.
TECH_STACK: PowerShell 7 + ScheduledTasks module over PSRemoting + JSON baseline snapshots + ImportExcel exceptions report, monthly scheduled run
APP_TYPE: CLI
LANGUAGE: PowerShell
SCALE: 2 platform engineers, 480 servers, ~9,200 tasks inventoried/run
```

## 37. AclAtlas — file share permissions mapper

```text
APP_DESCRIPTION: A CLI tool for a law firm's records team that maps NTFS permissions on matter file shares. It walks share ACLs to a configured depth, resolves groups to users, highlights direct-user grants, broken inheritance, and Everyone/Authenticated Users access on client-matter folders, and exports an ethical-wall compliance report per matter.
TECH_STACK: PowerShell 7 + NTFSSecurity module + ActiveDirectory group expansion + ImportExcel per-matter reports, run from records admin server
APP_TYPE: CLI
LANGUAGE: PowerShell
SCALE: 3 records admins, 24 file servers, 118,000 matter folders, quarterly sweep
```

## 38. ColdCrate — stale data archive reporter

```text
APP_DESCRIPTION: A data pipeline for a civil engineering firm that identifies cold project data for archival. Weekly it scans project shares for folders untouched beyond the retention threshold, sizes candidates by project code, verifies the project is closed in the ERP export, and produces mover-ready manifests for the archive tier.
TECH_STACK: PowerShell 7 + parallel Get-ChildItem scanning + ERP CSV join + robocopy manifest generation + scheduled task on file server
APP_TYPE: data pipeline
LANGUAGE: PowerShell
SCALE: 85 TB across 6 file servers, ~2,400 project folders evaluated/week
```

## 39. TwinFinder — duplicate file reclaimer

```text
APP_DESCRIPTION: A CLI tool for a photography studio chain's storage admin that finds duplicate files on production shares. It groups candidates by size, confirms with buffered SHA-256 hashing, ranks duplicate sets by reclaimable space, protects configured master folders from ever being flagged, and emits a review list — it never deletes.
TECH_STACK: PowerShell 7 + parallel hashing runspaces + SQLite hash cache + ImportExcel review workbook, run on demand per share
APP_TYPE: CLI
LANGUAGE: PowerShell
SCALE: 1 storage admin, 40 TB scanned/run, ~6M files, monthly run
```

## 40. DfsDoctor — DFS replication health checker

```text
APP_DESCRIPTION: A CLI tool for a construction company's infrastructure team that checks DFS namespace and replication health. It validates namespace target availability per site, measures replication backlog between partners, detects stalled state on members, and produces a per-branch replication scorecard with backlog trend arrows.
TECH_STACK: Windows PowerShell 5.1 + DFSN/DFSR modules + WMI backlog queries + HTML scorecard + scheduled task twice daily
APP_TYPE: CLI
LANGUAGE: PowerShell
SCALE: 34 branch offices, 12 replication groups, 2 runs/day, <1,000 file backlog SLA
```

## 41. NightlyNotary — backup job verification pipeline

```text
APP_DESCRIPTION: A data pipeline for an MSP's NOC that verifies client backup jobs every morning. It queries Veeam job results across client backup servers, normalizes success/warning/failure with retry context, cross-checks that every server in each client's protection list actually has a recent restore point, and posts a per-client exceptions digest to the NOC queue.
TECH_STACK: PowerShell 7 + Veeam.Backup.PowerShell per site + PSRemoting collectors + JSON protection lists + SMTP digest, scheduled 06:00 run
APP_TYPE: data pipeline
LANGUAGE: PowerShell
SCALE: 38 client sites, 1,450 protected servers, 1 run/day, 07:30 digest SLA
```

## 42. CheckpointCheck — Hyper-V hygiene auditor

```text
APP_DESCRIPTION: A CLI tool for a managed hosting company's virtualization team that audits Hyper-V hygiene. It finds aged checkpoints, orphaned AVHDX chains, VMs with dynamic memory misconfiguration, and hosts approaching memory or storage overcommit, then produces a per-cluster remediation list ranked by risk of chain corruption.
TECH_STACK: Windows PowerShell 5.1 + Hyper-V module + FailoverClusters + CIM sessions across hosts + ImportExcel report, weekly scheduled run
APP_TYPE: CLI
LANGUAGE: PowerShell
SCALE: 3 virtualization engineers, 64 hosts, ~1,800 VMs, weekly audit
```

## 43. SnapSnitch — VMware snapshot age reporter

```text
APP_DESCRIPTION: A CLI tool for a pharmaceutical research campus's VMware team that reports snapshot sprawl. It inventories snapshots across vCenters with age, size, and creator, matches them to change tickets by naming convention, escalates unmatched or over-age snapshots to VM owners, and trends datastore space at risk.
TECH_STACK: PowerShell 7 + VMware.PowerCLI + ticket-reference regex validation + SMTP owner nudges + ImportExcel trend report, daily scheduled run
APP_TYPE: CLI
LANGUAGE: PowerShell
SCALE: 2 vSphere admins, 3 vCenters, 4,200 VMs, 1 run/day, 72-hour snapshot SLA
```

## 44. HostHomologate — ESXi configuration compliance checker

```text
APP_DESCRIPTION: A CLI tool for an airline's infrastructure team that checks ESXi host configuration compliance. It compares NTP, syslog, SSH policy, vSwitch security settings, and firmware/driver pairs against the golden host profile per cluster, reports drift with severity, and generates the change-request payload to remediate.
TECH_STACK: PowerShell 7 + VMware.PowerCLI + JSON golden-profile definitions + Pester compliance assertions + ImportExcel drift report
APP_TYPE: CLI
LANGUAGE: PowerShell
SCALE: 4 engineers, 96 ESXi hosts, 11 clusters, weekly compliance run
```

## 45. LogonLoupe — failed sign-in analysis pipeline

```text
APP_DESCRIPTION: A data pipeline for a regional grocery chain's security team that analyzes failed logon activity. Hourly it collects 4625/4771 events from domain controllers, clusters failures by account, source host, and failure code, distinguishes fat-fingered users from spray patterns, and writes prioritized findings to the SOC review queue.
TECH_STACK: PowerShell 7 + Get-WinEvent with XPath filters over PSRemoting + SQLite rolling store + JSON detection thresholds + scheduled task
APP_TYPE: data pipeline
LANGUAGE: PowerShell
SCALE: 8 domain controllers, ~600k events/day, 24 runs/day, 15-minute finding SLA
```

## 46. LockoutLocator — account lockout source tracer

```text
APP_DESCRIPTION: A CLI tool for a hospital service desk that traces the source of AD account lockouts. Given a username, it queries the PDC emulator and all DCs for 4740/4625 events, walks back to the originating workstation or service, identifies stale credentials in mapped drives, services, and tasks on that source, and prints a fix checklist.
TECH_STACK: Windows PowerShell 5.1 + ActiveDirectory module + Get-WinEvent remoting + CIM service/task credential inspection, deployed as internal repo module
APP_TYPE: CLI
LANGUAGE: PowerShell
SCALE: 25 service-desk operators, 14,000 users, ~30 lockout traces/day
```

## 47. ScopeScout — DHCP utilization reporter

```text
APP_DESCRIPTION: A CLI tool for a public school district's network team that reports DHCP scope health. It collects scope utilization, lease duration sanity, and failover relationship state from all DHCP servers, forecasts scope exhaustion dates from lease trends, and flags scopes above 85% before the school-year device surge.
TECH_STACK: Windows PowerShell 5.1 + DhcpServer module + CSV trend history + ImportExcel forecast workbook + scheduled task, weekly run
APP_TYPE: CLI
LANGUAGE: PowerShell
SCALE: 2 network admins, 14 DHCP servers, 420 scopes, 38,000 leases, weekly run
```

## 48. RecordReckon — DNS stale record analyst

```text
APP_DESCRIPTION: A CLI tool for a defense contractor's infrastructure team that analyzes stale DNS records. It compares dynamic A/PTR records against AD computer account activity and DHCP leases, identifies mismatched or orphaned records and missing PTRs, models what scavenging would delete before enabling it, and exports a signed pre-change evidence report.
TECH_STACK: Windows PowerShell 5.1 + DnsServer module + ActiveDirectory + DhcpServer cross-reference + ImportExcel evidence report
APP_TYPE: CLI
LANGUAGE: PowerShell
SCALE: 3 admins, 6 DNS servers, 92,000 records analyzed, monthly run
```

## 49. DriftWatch — DSC configuration drift pipeline

```text
APP_DESCRIPTION: A data pipeline for a payment processor's compliance engineering team that detects configuration drift on PCI-scoped servers. Every 4 hours it runs DSC compliance tests against role baselines, records per-resource drift with previous and current values, auto-files drift tickets tagged to the owning team, and maintains the continuous-compliance evidence trail.
TECH_STACK: PowerShell 7 + PSDesiredStateConfiguration + Pester-based baseline tests + REST ticketing integration + SQL evidence store, scheduled task
APP_TYPE: data pipeline
LANGUAGE: PowerShell
SCALE: 310 PCI-scoped servers, 6 runs/day, 24-hour remediation SLA
```

## 50. AdminAudit — local administrators reconciler

```text
APP_DESCRIPTION: A CLI tool for a mining company's security team that reconciles local Administrators groups across servers. It collects membership from every server, resolves nested domain groups, diffs against the role-based entitlement matrix, flags unauthorized members and orphaned SIDs, and stages removals behind an approval file.
TECH_STACK: PowerShell 7 + Invoke-Command fan-out + Microsoft.PowerShell.LocalAccounts + CSV entitlement matrix + ImportExcel exceptions, weekly scheduled run
APP_TYPE: CLI
LANGUAGE: PowerShell
SCALE: 2 security engineers, 720 servers, weekly run, <2% exception target
```

## 51. LapsLens — LAPS rotation verifier

```text
APP_DESCRIPTION: A CLI tool for a city government's endpoint security team that verifies Windows LAPS is working everywhere. It checks that every eligible computer has a current LAPS password within rotation age, identifies machines missing the policy or failing to escrow, verifies password retrieval permissions match the delegation model, and reports coverage by department.
TECH_STACK: PowerShell 7 + Windows LAPS module + ActiveDirectory + Microsoft.Graph for Entra-joined devices + ImportExcel coverage report, weekly run
APP_TYPE: CLI
LANGUAGE: PowerShell
SCALE: 3 operators, 11,500 endpoints, weekly run, 98% escrow coverage target
```

## 52. QueueQuell — print server health monitor

```text
APP_DESCRIPTION: A CLI tool for a hospital's client services team that monitors print servers feeding clinical areas. It checks spooler health, stuck jobs, and offline queues across print servers, clears jobs stuck beyond threshold on non-clinical queues only, pages the on-call tech for pharmacy and lab label printers, and logs every intervention.
TECH_STACK: Windows PowerShell 5.1 + PrintManagement module + PSRemoting + JSON queue criticality map + scheduled task every 10 minutes
APP_TYPE: CLI
LANGUAGE: PowerShell
SCALE: 6 print servers, 840 queues, 144 runs/day, 5-minute clinical-queue SLA
```

## 53. StarterKit — new hire provisioning runbook

```text
APP_DESCRIPTION: A CLI runbook for a wealth management firm's IT team that provisions new hires from an HR ticket. It creates the AD account from role templates, assigns M365 licenses and groups, provisions the mailbox with the right retention policy, creates the home folder with correct ACLs, schedules a first-day password handoff, and prints a provisioning receipt for the ticket.
TECH_STACK: PowerShell 7 + ActiveDirectory + Microsoft.Graph + ExchangeOnlineManagement + JSON role templates + Pester validation, internal repo module
APP_TYPE: CLI
LANGUAGE: PowerShell
SCALE: 5 IT operators, 2,800 employees, ~25 hires/month, 30-minute provisioning target
```

## 54. TempusTerminus — contractor expiry enforcer

```text
APP_DESCRIPTION: A CLI tool for a shipbuilder's identity team that enforces contractor account expiration. It ensures every contractor account carries an expiration date matching the contract-end feed, warns sponsors 10 days before expiry with a renewal workflow, disables accounts the day after expiry, and reports contractors with missing or manually extended dates.
TECH_STACK: Windows PowerShell 5.1 + ActiveDirectory module + contracts CSV feed + SMTP sponsor notices + scheduled nightly task
APP_TYPE: CLI
LANGUAGE: PowerShell
SCALE: 2 identity admins, 3,400 contractor accounts, nightly run, 0 undated-account target
```

## 55. DiskDowser — server capacity forecast pipeline

```text
APP_DESCRIPTION: A data pipeline for a food distributor's operations team that forecasts server disk exhaustion. Daily it samples volume usage across servers, fits growth trends per volume, predicts days-to-full, distinguishes steady growth from sudden jumps worth investigating, and publishes a two-week warning list to the ops dashboard share.
TECH_STACK: PowerShell 7 + CIM volume queries fan-out + CSV time-series store + linear regression in script + ImportExcel dashboard, daily scheduled run
APP_TYPE: data pipeline
LANGUAGE: PowerShell
SCALE: 540 servers, ~2,100 volumes sampled/day, 1 run/day, 14-day warning horizon
```

## 56. RebootRoster — pending reboot coordinator

```text
APP_DESCRIPTION: A CLI tool for a plastics manufacturer's server team that manages pending reboots. It detects pending-reboot state from CBS, WUA, and rename-operation signals across servers, ages each pending state, matches servers to their allowed reboot windows and clustered roles, and produces the weekend reboot roster with safe ordering.
TECH_STACK: Windows PowerShell 5.1 + CIM/registry checks over PSRemoting + JSON maintenance-window calendar + ImportExcel roster, twice-weekly run
APP_TYPE: CLI
LANGUAGE: PowerShell
SCALE: 2 admins, 380 servers, 2 runs/week, 14-day max pending-reboot age
```

## 57. ShelfCheck — endpoint software inventory pipeline

```text
APP_DESCRIPTION: A data pipeline for a public library system that inventories installed software across branch computers. Nightly it collects installed applications and versions from staff and patron machines, normalizes publisher naming, diffs against the approved software catalog, and flags unapproved installs and out-of-support versions per branch.
TECH_STACK: PowerShell 7 + registry uninstall-key collection over PSRemoting + SQLite inventory store + CSV approved catalog + ImportExcel branch reports
APP_TYPE: data pipeline
LANGUAGE: PowerShell
SCALE: 26 branches, 2,900 computers, nightly run, ~1,400 distinct applications tracked
```

## 58. EscrowEnsure — BitLocker key escrow verifier

```text
APP_DESCRIPTION: A CLI tool for a health system's endpoint security team that verifies BitLocker recovery keys are escrowed. It confirms every encrypted device has a current recovery key in Entra ID or AD, detects keys rotated locally but never escrowed, checks encryption status and method per device, and reports unprotected devices by clinic.
TECH_STACK: PowerShell 7 + Microsoft.Graph (bitlocker recovery keys, devices) + ActiveDirectory msFVE lookups + ImportExcel clinic report, weekly run
APP_TYPE: CLI
LANGUAGE: PowerShell
SCALE: 3 operators, 16,000 encrypted devices, weekly run, 100% escrow requirement
```

## 59. DefendDigest — antivirus posture reporter

```text
APP_DESCRIPTION: A data pipeline for a furniture retailer's security team that reports Microsoft Defender posture. Daily it aggregates signature age, real-time protection state, last scan time, and active threat counts across endpoints, ranks stores by exposure, and emails the exceptions digest with per-device remediation commands to regional techs.
TECH_STACK: PowerShell 7 + Get-MpComputerStatus over PSRemoting + Microsoft.Graph security for cloud-managed devices + SMTP digest, daily scheduled run
APP_TYPE: data pipeline
LANGUAGE: PowerShell
SCALE: 210 stores, 7,400 endpoints, 1 run/day, 24-hour signature-age SLA
```

## 60. RulebookReconcile — host firewall baseline auditor

```text
APP_DESCRIPTION: A CLI tool for a stock transfer agent's security team that audits Windows Firewall configuration on servers. It exports effective firewall rules per server, compares against the role-based rule baseline, flags disabled profiles, shadowing rules, and unauthorized inbound allowances, and generates remediation GPO settings for approved fixes.
TECH_STACK: PowerShell 7 + NetSecurity module over PSRemoting + JSON role baselines + ImportExcel findings + PSScriptAnalyzer-clean module in internal repo
APP_TYPE: CLI
LANGUAGE: PowerShell
SCALE: 2 security engineers, 290 servers, ~34,000 rules evaluated, monthly audit
```

## 61. OpenDoorCensus — exposed share auditor

```text
APP_DESCRIPTION: A CLI tool for a regional airport authority's IT security team that audits SMB shares for overexposure. It enumerates shares across servers, evaluates share and NTFS permissions together for effective access, flags Everyone-writable paths and hidden shares with broad access, samples exposed paths for sensitive-file name patterns, and reports by data owner.
TECH_STACK: PowerShell 7 + SmbShare module + NTFSSecurity + PSRemoting fan-out + regex sensitive-name patterns + ImportExcel owner reports, quarterly run
APP_TYPE: CLI
LANGUAGE: PowerShell
SCALE: 2 analysts, 160 servers, ~3,800 shares audited/quarter
```

## 62. HomesteadMove — home directory migration tool

```text
APP_DESCRIPTION: A CLI tool for a merged credit union's infrastructure team that migrates user home directories between file servers. It pre-stages data with robocopy, verifies file counts and hashes per user, updates the homeDirectory attribute and drive mappings at cutover, supports per-branch waves with rollback, and produces a per-user migration certificate.
TECH_STACK: PowerShell 7 + robocopy orchestration with parsed logs + ActiveDirectory module + JSON wave plans + ImportExcel certificates, run per migration wave
APP_TYPE: CLI
LANGUAGE: PowerShell
SCALE: 3 engineers, 4,100 home directories, 9 TB total, 12 weekend waves
```

## 63. HoldFast — retention and litigation hold reporter

```text
APP_DESCRIPTION: A CLI tool for a pharmaceutical company's legal operations team that reports mailbox retention and hold status. It inventories which retention policies and litigation holds apply to each custodian, verifies hold coverage against the active legal-matters list, detects custodians released early or never placed on hold, and produces defensible hold-status evidence per matter.
TECH_STACK: PowerShell 7 + ExchangeOnlineManagement + Microsoft.Graph eDiscovery + legal-matters CSV join + ImportExcel evidence packs, weekly run
APP_TYPE: CLI
LANGUAGE: PowerShell
SCALE: 2 legal-ops analysts, 47 active matters, 1,300 custodian mailboxes, weekly run
```

## 64. RoomRoster — resource calendar administrator

```text
APP_DESCRIPTION: A CLI tool for a private school network's IT office that administers room and equipment calendars. It standardizes booking policies across resource mailboxes, audits delegate and booking permissions per campus, finds double-booking-prone rooms with conflicting settings, and syncs room display names and capacities from the facilities spreadsheet.
TECH_STACK: PowerShell 7 + ExchangeOnlineManagement calendar processing cmdlets + ImportExcel facilities import + scheduled monthly run
APP_TYPE: CLI
LANGUAGE: PowerShell
SCALE: 2 admins, 340 resource mailboxes, 11 campuses, monthly policy pass
```

## 65. DialPlanDeputy — Teams phone assignment tool

```text
APP_DESCRIPTION: A CLI tool for an outsourced call center operator's telephony team that manages Teams Phone at scale. It assigns numbers from range inventory to new agents, applies the right voice routing and calling policies per client program, reconciles assigned numbers against HR rosters to reclaim from leavers, and reports number pool utilization per site.
TECH_STACK: PowerShell 7 + MicrosoftTeams module + Microsoft.Graph HR roster join + CSV number-range inventory + ImportExcel utilization report
APP_TYPE: CLI
LANGUAGE: PowerShell
SCALE: 4 telephony admins, 9,500 agents, 14 sites, ~350 moves/adds/changes per week
```

## 66. SecretSunset — app registration credential monitor

```text
APP_DESCRIPTION: A data pipeline for a software vendor's identity platform team that monitors Entra app registration credentials. Daily it inventories client secrets and certificates across app registrations, notifies owning teams at 45/14/3 days before expiry with rotation instructions, flags secrets valid beyond policy maximum, and reports apps with no assigned owner.
TECH_STACK: PowerShell 7 + Microsoft.Graph applications API + owner-mapping JSON + SMTP notifications + scheduled task, Pester in CI
APP_TYPE: data pipeline
LANGUAGE: PowerShell
SCALE: 1,150 app registrations, ~2,700 credentials tracked, 1 run/day
```

## 67. SpnSpotter — service account and SPN auditor

```text
APP_DESCRIPTION: A CLI tool for a rail operator's security team that audits AD service accounts. It inventories accounts with SPNs, password age, and encryption types, flags RC4-only and never-expiring passwords on kerberoastable accounts, identifies where each account logs on from event data, and builds the migration list to group managed service accounts.
TECH_STACK: PowerShell 7 + ActiveDirectory module + 4624 logon-source correlation via Get-WinEvent + ImportExcel migration workbook, monthly run
APP_TYPE: CLI
LANGUAGE: PowerShell
SCALE: 2 security engineers, 860 service accounts, 420 SPNs, monthly audit
```

## 68. DelegationDragnet — Kerberos delegation reviewer

```text
APP_DESCRIPTION: A CLI tool for a national laboratory's directory security team that reviews Kerberos delegation risk. It enumerates unconstrained, constrained, and resource-based delegation across the forest, maps which sensitive accounts could be impersonated through each path, verifies protected-users and not-delegated flags on privileged accounts, and reports the change list to eliminate unconstrained delegation.
TECH_STACK: PowerShell 7 + ActiveDirectory module + msDS-AllowedToActOnBehalfOfOtherIdentity parsing + ImportExcel risk report, run quarterly
APP_TYPE: CLI
LANGUAGE: PowerShell
SCALE: 3 analysts, 3 domains, 41,000 accounts scanned, quarterly review
```

## 69. ReplPulse — AD replication health monitor

```text
APP_DESCRIPTION: A CLI tool for a global logistics enterprise's directory team that monitors AD replication. It collects replication partner status and largest deltas from every DC, tests SYSVOL consistency with canary files, detects lingering-object and tombstone-window risks, and renders a follow-the-sun health board consumed by three regional teams.
TECH_STACK: PowerShell 7 + repadmin output parsing + ActiveDirectory module + canary-file SYSVOL test + HTML health board + scheduled hourly task
APP_TYPE: CLI
LANGUAGE: PowerShell
SCALE: 58 domain controllers, 4 domains, 24 runs/day, 15-minute max replication delta
```

## 70. RoleCallDc — domain controller readiness checker

```text
APP_DESCRIPTION: A CLI tool for a beverage bottler's infrastructure team that health-checks domain controllers before and after patching. It verifies FSMO role reachability, SYSVOL and NETLOGON shares, DNS registration, secure channel, time sync, and critical service state per DC, compares pre/post snapshots, and blocks the patch pipeline on regression.
TECH_STACK: Windows PowerShell 5.1 + dcdiag/repadmin wrappers + ActiveDirectory module + JSON snapshot store + exit-code gating for the patch orchestrator
APP_TYPE: CLI
LANGUAGE: PowerShell
SCALE: 22 domain controllers, 2 patch cycles/month, 44 gated check runs/month
```

## 71. ChronoCheck — fleet time sync auditor

```text
APP_DESCRIPTION: A CLI tool for a securities broker's infrastructure team that audits time synchronization for trade-record compliance. It measures clock offset on every server against the reference source, validates w32tm hierarchy and stratum configuration, flags servers beyond the 100 ms tolerance or syncing from wrong sources, and archives daily offset evidence for FINRA audits.
TECH_STACK: Windows PowerShell 5.1 + w32tm output parsing over PSRemoting + CSV evidence archive + scheduled task, SMTP alerts on tolerance breach
APP_TYPE: CLI
LANGUAGE: PowerShell
SCALE: 340 servers, 2 runs/day, 100 ms offset tolerance, 7-year evidence retention
```

## 72. SessionSexton — RDS farm usage reporter

```text
APP_DESCRIPTION: A CLI tool for an architecture firm's IT team that reports Remote Desktop Services farm usage. It samples session counts, disconnected-session age, and per-host resource load across session hosts, reconciles RDS CAL consumption against licensing, identifies users with chronically abandoned sessions, and produces the monthly capacity and license position report.
TECH_STACK: Windows PowerShell 5.1 + RemoteDesktop module + quser parsing + RD Licensing WMI + ImportExcel monthly report, sampling task every 30 minutes
APP_TYPE: CLI
LANGUAGE: PowerShell
SCALE: 2 admins, 18 session hosts, 640 users, 48 samples/day
```

## 73. ActivationAttest — Windows activation compliance checker

```text
APP_DESCRIPTION: A CLI tool for a discount retail chain's licensing coordinator that checks Windows and Office activation health. It queries activation status across store back-office machines, verifies KMS client counts and SRV records per region, detects grace-period machines before they hit notification mode, and files the quarterly license compliance attestation.
TECH_STACK: Windows PowerShell 5.1 + slmgr/ospp WMI equivalents via CIM + DNS SRV validation + ImportExcel attestation, weekly scheduled run
APP_TYPE: CLI
LANGUAGE: PowerShell
SCALE: 1 coordinator, 890 stores, 3,600 machines, weekly run
```

## 74. WaybillCopy — audited bulk file transfer tool

```text
APP_DESCRIPTION: A CLI tool for a television station group's media operations team that performs audited bulk file transfers between production and archive storage. It wraps robocopy with manifest-driven job definitions, parses logs into per-job transfer receipts with hash spot-checks, resumes interrupted jobs safely, and enforces bandwidth windows during broadcast hours.
TECH_STACK: PowerShell 7 + robocopy with parsed logging + JSON job manifests + Get-FileHash sampling + scheduled and on-demand execution
APP_TYPE: CLI
LANGUAGE: PowerShell
SCALE: 4 media ops staff, ~3 TB transferred/day, 30 jobs/day, 6-hour overnight window
```

## 75. RosterSync — HR-to-AD attribute sync pipeline

```text
APP_DESCRIPTION: A data pipeline for a hotel chain's identity team that syncs HR data into Active Directory. Nightly it ingests the HRIS export, validates and normalizes titles, departments, managers, and locations, applies attribute updates with per-field change thresholds that halt on suspicious mass changes, and writes a reconciliation report of applied, skipped, and quarantined records.
TECH_STACK: PowerShell 7 + ActiveDirectory module + CSV/JSON HRIS feed + change-threshold circuit breaker + ImportExcel reconciliation report, nightly scheduled task
APP_TYPE: data pipeline
LANGUAGE: PowerShell
SCALE: 19,000 employee records/night, ~400 attribute changes/day, 5% mass-change halt threshold
```

## 76. TicketTrends — service desk metrics workbook pipeline

```text
APP_DESCRIPTION: A data pipeline for a managed services provider that turns ticket system exports into client-facing monthly reports. It ingests per-client ticket CSVs, computes SLA attainment, first-touch resolution, category heat maps, and technician utilization, then renders a branded Excel report per client with month-over-month deltas.
TECH_STACK: PowerShell 7 + REST export from PSA tool + ImportExcel with charts and conditional formatting + scheduled first-of-month run
APP_TYPE: data pipeline
LANGUAGE: PowerShell
SCALE: 52 client reports/month, ~11,000 tickets/month processed, 1 run/month
```

## 77. WeblogWinnow — IIS log aggregation pipeline

```text
APP_DESCRIPTION: A data pipeline for a university registrar's web team that aggregates IIS logs from enrollment applications. Nightly it collects W3C logs from web servers, parses and filters bot traffic, aggregates status-code and latency distributions per application, flags error-rate anomalies during registration windows, and ships summarized data to the reporting database.
TECH_STACK: PowerShell 7 + streaming W3C log parser + SQL Server bulk insert via dbatools + scheduled task, log retention rotation included
APP_TYPE: data pipeline
LANGUAGE: PowerShell
SCALE: 12 web servers, ~9 GB logs/night, 40M requests/day peak, 2-hour batch window
```

## 78. FeedFortify — SIEM export enrichment pipeline

```text
APP_DESCRIPTION: A data pipeline for an electric cooperative's security team that enriches security exports before SIEM review. It ingests authentication and endpoint alert CSVs, joins asset criticality from the CMDB, adds user department and employment status from AD, deduplicates alert storms into incidents, and outputs analyst-ready enriched files to the review share.
TECH_STACK: PowerShell 7 + CSV stream processing + ActiveDirectory lookups with caching + CMDB REST queries + scheduled task every 2 hours
APP_TYPE: data pipeline
LANGUAGE: PowerShell
SCALE: ~45,000 alert rows/day, 12 runs/day, 800-asset CMDB, 30-minute enrichment SLA
```

## 79. UptimeUmpire — reboot compliance scorekeeper

```text
APP_DESCRIPTION: A CLI tool for a paper mill's IT operations that scores server reboot compliance. It reads last-boot times across servers, matches each against its patch-cycle reboot requirement and exemption register, identifies servers up beyond the 45-day policy or that rebooted unexpectedly outside windows, and publishes the compliance scoreboard to the ops review.
TECH_STACK: Windows PowerShell 5.1 + CIM Win32_OperatingSystem fan-out + CSV exemption register + HTML scoreboard + weekly scheduled run
APP_TYPE: CLI
LANGUAGE: PowerShell
SCALE: 265 servers, weekly run, 45-day max uptime policy, 5% exemption cap
```

## 80. PolicyPreserve — GPO backup automation

```text
APP_DESCRIPTION: A CLI tool for a gas utility's directory team that automates Group Policy backup and restore readiness. Nightly it backs up all GPOs with WMI filters and link state, keeps a versioned history with change annotations from who-changed-what event data, verifies restorability by test-importing a sample into a staging domain, and prunes history by retention policy.
TECH_STACK: Windows PowerShell 5.1 + GroupPolicy module + versioned backup folder structure + 5136/5137 event correlation + scheduled nightly task
APP_TYPE: CLI
LANGUAGE: PowerShell
SCALE: 480 GPOs backed up/night, 90-day version retention, 2 test-restores/week
```

## 81. StewardshipScan — AD delegation ACL auditor

```text
APP_DESCRIPTION: A CLI tool for a semiconductor firm's identity security team that audits delegated permissions in Active Directory. It reads ACLs on OUs and privileged objects, filters default entries to surface explicit delegations, maps who can reset passwords or modify membership where, diffs against the documented delegation model, and flags shadow-admin paths for removal.
TECH_STACK: PowerShell 7 + Get-Acl over AD provider + GUID-to-rights resolution tables + JSON delegation model + ImportExcel findings, monthly run
APP_TYPE: CLI
LANGUAGE: PowerShell
SCALE: 2 analysts, 1,900 OUs, ~85,000 ACEs evaluated, monthly audit
```

## 82. SidSalvage — orphaned SID cleanup reporter

```text
APP_DESCRIPTION: A CLI tool for a merged regional bank's file services team that reports orphaned SIDs left by domain migrations. It scans NTFS ACLs across file servers for unresolvable SIDs, maps salvageable ones through the migration sIDHistory table, quantifies affected folders per share, and produces a staged cleanup plan that never touches ACLs without an approval manifest.
TECH_STACK: PowerShell 7 + NTFSSecurity module + sIDHistory mapping CSV + parallel share scanning + ImportExcel cleanup plan, run per migration phase
APP_TYPE: CLI
LANGUAGE: PowerShell
SCALE: 3 engineers, 18 file servers, 31 TB scanned, ~240,000 orphaned ACEs found
```

## 83. QuotaQuill — FSRM quota and screen reporter

```text
APP_DESCRIPTION: A CLI tool for a community college's storage admin that reports File Server Resource Manager posture. It collects quota usage and threshold events per department share, summarizes file-screen violations by type, identifies departments repeatedly hitting quota for allocation review, and generates the per-dean storage stewardship report each term.
TECH_STACK: Windows PowerShell 5.1 + FileServerResourceManager module + PSRemoting across file servers + ImportExcel term reports, weekly scheduled run
APP_TYPE: CLI
LANGUAGE: PowerShell
SCALE: 1 storage admin, 5 file servers, 210 quota'd shares, 14,000 students, weekly run
```

## 84. TransportTome — Exchange transport rule documenter

```text
APP_DESCRIPTION: A CLI tool for an import/export brokerage's messaging admin that documents Exchange Online transport rules. It exports every rule with conditions, actions, and exceptions rendered in plain English, maps rule interactions and ordering conflicts, identifies disabled and never-matching rules from message trace sampling, and versions the rulebook for change audits.
TECH_STACK: PowerShell 7 + ExchangeOnlineManagement + rule-to-prose rendering + message trace sampling + Git-versioned Markdown rulebook, monthly run
APP_TYPE: CLI
LANGUAGE: PowerShell
SCALE: 1 messaging admin, 128 transport rules, 2,400 mailboxes, monthly documentation run
```

## 85. SenderShield — email authentication posture checker

```text
APP_DESCRIPTION: A CLI tool for a franchise restaurant group's IT team that checks email authentication across owned domains. It validates SPF record syntax and lookup counts, DKIM selector publication and key length, and DMARC policy and reporting addresses for every domain, compares against the target enforcement policy, and tracks progression from none to quarantine to reject.
TECH_STACK: PowerShell 7 + Resolve-DnsName record analysis + domain inventory CSV + ImportExcel posture tracker, weekly scheduled run
APP_TYPE: CLI
LANGUAGE: PowerShell
SCALE: 1 admin, 74 owned domains, weekly run, 100% DMARC-reject target by year end
```

## 86. RadiusReader — NPS authentication log analyst

```text
APP_DESCRIPTION: A data pipeline for a boarding school's network team that analyzes NPS RADIUS logs for Wi-Fi health. Nightly it parses NPS accounting logs, aggregates authentication failures by reason code, SSID, and building, identifies certificate-expired devices and misconfigured supplicants, and produces a helpdesk pre-brief of users likely to call tomorrow.
TECH_STACK: Windows PowerShell 5.1 + NPS IAS-format log parser + CSV aggregation store + HTML pre-brief report + scheduled nightly task
APP_TYPE: data pipeline
LANGUAGE: PowerShell
SCALE: 2 network staff, ~85,000 auth events/day, 3,200 devices, nightly run
```

## 87. RebindRelay — web certificate renewal orchestrator

```text
APP_DESCRIPTION: A CLI tool for a ticketing platform's web operations team that orchestrates internal certificate renewal and rebinding. It requests renewals from the internal CA for expiring web certificates, installs to the machine store on target servers, updates IIS bindings atomically with rollback on failed health checks, and records the renewal chain of custody.
TECH_STACK: PowerShell 7 + Certificate enrollment API + IISAdministration over PSRemoting + post-bind HTTPS health probes + JSON run ledger, run weekly
APP_TYPE: CLI
LANGUAGE: PowerShell
SCALE: 2 web ops engineers, 85 servers, ~40 renewals/month, zero-downtime rebind requirement
```

## 88. PackagePulse — Chocolatey deployment status reporter

```text
APP_DESCRIPTION: A CLI tool for a game studio's IT team that reports Chocolatey package deployment status across workstations. It inventories installed package versions against the internal repository's promoted versions, identifies machines pinned to old builds or failing upgrades, summarizes adoption lag per team, and flags packages installed from unapproved sources.
TECH_STACK: PowerShell 7 + choco CLI output parsing over PSRemoting + internal Chocolatey repo API + ImportExcel adoption report, twice-weekly run
APP_TYPE: CLI
LANGUAGE: PowerShell
SCALE: 2 IT staff, 640 workstations, 120 managed packages, 2 runs/week
```

## 89. ModuleMuster — PowerShell module compliance checker

```text
APP_DESCRIPTION: A CLI tool for an investment manager's automation team that keeps PowerShell module versions consistent across automation servers. It inventories installed module versions per server, compares against the pinned manifest for each server role, detects side-by-side version conflicts and modules installed outside the internal repository, and stages compliant updates per maintenance window.
TECH_STACK: PowerShell 7 + PowerShellGet/PSResourceGet + internal NuGet repository + JSON role manifests + Pester post-update validation, weekly run
APP_TYPE: CLI
LANGUAGE: PowerShell
SCALE: 2 automation engineers, 46 automation servers, 85 pinned modules, weekly run
```

## 90. RunAsRegister — task credential exposure auditor

```text
APP_DESCRIPTION: A CLI tool for a chemicals manufacturer's security team that audits credentials used by scheduled tasks and services. It inventories run-as identities across servers, flags personal accounts, domain admins, and accounts with passwords older than policy running unattended workloads, maps each to the migration path (gMSA, managed identity), and tracks burn-down per quarter.
TECH_STACK: PowerShell 7 + ScheduledTasks and CIM service queries over PSRemoting + ActiveDirectory password-age join + ImportExcel burn-down tracker
APP_TYPE: CLI
LANGUAGE: PowerShell
SCALE: 2 security engineers, 410 servers, ~1,600 unattended identities audited, quarterly
```

## 91. GrowthGauge — database capacity trend pipeline

```text
APP_DESCRIPTION: A data pipeline for a healthcare claims clearinghouse's DBA team that trends SQL database growth. Daily it samples data and log file sizes, free space, and autogrowth events across instances, fits per-database growth curves, forecasts when volumes and instances hit capacity, and feeds the quarterly storage purchase plan with per-database projections.
TECH_STACK: PowerShell 7 + dbatools size collection + SQL time-series repository + regression forecasting in script + ImportExcel projections, daily scheduled run
APP_TYPE: data pipeline
LANGUAGE: PowerShell
SCALE: 51 instances, 940 databases sampled/day, 1 run/day, 90-day forecast horizon
```

## 92. QuorumQuiz — failover cluster validation runner

```text
APP_DESCRIPTION: A CLI tool for a dairy cooperative's infrastructure team that validates failover cluster health before maintenance. It runs targeted cluster validation categories, checks CSV free space and redirected-access state, verifies witness health and node vote configuration, confirms VM and role distribution allows single-node drain, and gates the maintenance ticket on a passing report.
TECH_STACK: Windows PowerShell 5.1 + FailoverClusters module (Test-Cluster subsets) + Hyper-V role checks + HTML gate report + on-demand and pre-patch runs
APP_TYPE: CLI
LANGUAGE: PowerShell
SCALE: 2 admins, 7 clusters, 26 nodes, ~10 gated maintenance runs/month
```

## 93. KeeperKeys — Key Vault secret lifecycle reporter

```text
APP_DESCRIPTION: A CLI tool for an online travel agency's platform team that reports Azure Key Vault secret hygiene. It inventories secrets, keys, and certificates with expiry and rotation metadata across vaults, flags items without expiration dates, near-expiry credentials, and vaults missing purge protection or diagnostic logging, and assigns findings to owning teams via tags.
TECH_STACK: PowerShell 7 + Az.KeyVault + Az.Monitor diagnostic checks + tag-based owner routing + ImportExcel findings, weekly scheduled run
APP_TYPE: CLI
LANGUAGE: PowerShell
SCALE: 3 platform engineers, 120 vaults, ~5,400 tracked items, weekly run
```

## 94. PortablePatrol — removable media usage auditor

```text
APP_DESCRIPTION: A data pipeline for a defense research institute's insider-risk team that audits removable media usage. Daily it collects device-connection and file-write audit events from monitored endpoints, matches devices against the approved encrypted-drive register, summarizes write volumes per user and department, and escalates unregistered-device writes to the security review queue.
TECH_STACK: PowerShell 7 + Get-WinEvent device/removable-storage audit collection + approved-device CSV register + SQLite rolling store + daily scheduled run
APP_TYPE: data pipeline
LANGUAGE: PowerShell
SCALE: 2,100 monitored endpoints, ~18,000 events/day, 1 run/day, 4-hour escalation SLA
```

## 95. ForwardFence — mailbox forwarding rule auditor

```text
APP_DESCRIPTION: A CLI tool for a title insurance company's security team that audits mailbox forwarding for compromise indicators. It inventories mailbox-level forwarding, inbox rules that forward or redirect externally, and rules that delete security notifications, whitelists documented business forwards, and produces a same-day review list because wire-fraud attempts spike after phishing waves.
TECH_STACK: PowerShell 7 + ExchangeOnlineManagement inbox-rule enumeration + approved-forwards CSV + SMTP alert on new external forwards, daily scheduled run
APP_TYPE: CLI
LANGUAGE: PowerShell
SCALE: 2 analysts, 4,600 mailboxes, 1 run/day, same-day review SLA
```

## 96. WelcomeWagon — student account season pipeline

```text
APP_DESCRIPTION: A data pipeline for a community college district that provisions student accounts each enrollment season. It ingests the nightly SIS enrollment file, creates or reactivates AD and M365 accounts with campus-based OU placement and license groups, generates claim codes for the credential portal, handles name changes and cross-campus transfers, and reconciles totals against the SIS.
TECH_STACK: PowerShell 7 + ActiveDirectory + Microsoft.Graph + SIS CSV feed + JSON campus mapping rules + nightly scheduled task, Pester-tested transforms
APP_TYPE: data pipeline
LANGUAGE: PowerShell
SCALE: 62,000 student accounts, ~1,800 changes/night in peak season, nightly run
```

## 97. FreezerBurn — offline VM and image staleness reporter

```text
APP_DESCRIPTION: A CLI tool for a video game publisher's infrastructure team that reports staleness of offline VMs and golden images. It inventories powered-off VMs with off-duration and owner, computes patch debt for each golden image against the current baseline, flags templates overdue for rebuild, and schedules image refresh work orders before the debt exceeds policy.
TECH_STACK: PowerShell 7 + VMware.PowerCLI + image build-date metadata + patch baseline CSV + ImportExcel work orders, monthly scheduled run
APP_TYPE: CLI
LANGUAGE: PowerShell
SCALE: 2 engineers, 310 powered-off VMs, 45 golden images, 30-day max image patch debt
```

## 98. MinuteMinder — meeting room device health reporter

```text
APP_DESCRIPTION: A CLI tool for a consulting firm's workplace technology team that reports Teams Rooms device health. It pulls device health and peripheral status for room systems across offices, correlates offline devices with recent room bookings to prioritize fixes, tracks firmware currency per model, and produces the facilities walk-list ordered by tomorrow's booking density.
TECH_STACK: PowerShell 7 + Microsoft.Graph (Teams devices, calendar) + ImportExcel walk-list + scheduled early-morning run
APP_TYPE: CLI
LANGUAGE: PowerShell
SCALE: 2 workplace techs, 260 room systems, 34 offices, 1 run/day
```

## 99. LedgerLoad — finance data warehouse loader

```text
APP_DESCRIPTION: A data pipeline for a property management company's finance team that loads nightly accounting extracts into the reporting warehouse. It validates fixed-width and CSV extracts from three property systems, enforces schema and balance-total checks that quarantine bad batches, loads staged data via bulk insert, runs reconciliation queries, and emails the load certificate to finance.
TECH_STACK: PowerShell 7 + dbatools bulk insert + schema/checksum validation + quarantine folder workflow + SQL Agent-launched, PSScriptAnalyzer-clean
APP_TYPE: data pipeline
LANGUAGE: PowerShell
SCALE: 3 source systems, ~2.4M rows/night, 6 GB/month, 03:00–05:00 load window
```

## 100. BranchBastion — branch server morning check runner

```text
APP_DESCRIPTION: A CLI tool for a farm equipment dealership network's IT team that runs morning health checks on branch servers. Before stores open it verifies each branch server's disk space, backup completion, replication state, critical services, and point-of-sale dependency reachability, rolls results into a single traffic-light board, and opens tickets only for consecutive failures.
TECH_STACK: Windows PowerShell 5.1 + PSRemoting check fan-out + JSON check definitions per branch role + HTML traffic-light board + 05:30 scheduled task
APP_TYPE: CLI
LANGUAGE: PowerShell
SCALE: 3 IT staff, 47 branches, 47 servers checked/run, 1 run/day before 06:30
```
