# jq Blueprint Types — Copy-Paste Input Sets

Copy a fenced block into the prompt as-is, or swap individual fields.

## 1. traildigest — CloudTrail daily security digest

```text
APP_DESCRIPTION: A data pipeline for a security team that condenses raw AWS CloudTrail event batches into a daily digest. It groups events by principal and API action, flags console logins without MFA, root account usage, and IAM policy changes, and emits a Markdown summary for the morning review.
TECH_STACK: jq 1.7 filter modules (.jq files) + bash wrapper pulling gzipped CloudTrail files from S3 + jq --run-tests fixture suite, cron-driven
APP_TYPE: data pipeline
LANGUAGE: jq
SCALE: ~2.5M events/day across 40 AWS accounts, ~6 GB JSON per nightly run, 3 analysts consuming the digest
```

## 2. lockdiff — package-lock diff auditor

```text
APP_DESCRIPTION: A CLI tool for release managers that diffs two package-lock.json files and reports added, removed, upgraded, and downgraded packages with their resolved registry URLs. It highlights major-version jumps and packages whose registry host changed, feeding release-note drafts and supply-chain review.
TECH_STACK: jq 1.7 filter modules + thin bash wrapper (two-file --slurpfile invocation) + bats test suite with lockfile fixtures, input from git show of branch pairs
APP_TYPE: CLI
LANGUAGE: jq
SCALE: ~30 diffs/day in CI, lockfiles up to 12 MB / 4,000 packages each, 25 repos onboarded
```

## 3. podreap — kubectl pod health report

```text
APP_DESCRIPTION: A CLI tool for platform engineers that turns `kubectl get pods -A -o json` into a restart-and-failure report. It ranks pods by restart count, surfaces CrashLoopBackOff and OOMKilled containers with their exit codes, and prints a per-namespace table for the daily standup.
TECH_STACK: jq 1.7 filter modules + bash wrapper invoking kubectl with context/namespace flags + jq --run-tests fixtures captured from real clusters
APP_TYPE: CLI
LANGUAGE: jq
SCALE: 6 clusters, ~3,800 pods per run, 20–40 MB JSON per invocation, run 4x/day by 12 engineers
```

## 4. tfstately — terraform state query kit

```text
APP_DESCRIPTION: A CLI tool for infrastructure teams that answers questions against `terraform show -json` output: which resources reference a given AMI, which modules own untagged resources, and where a security group is consumed. Engineers use it during refactors instead of grepping raw state.
TECH_STACK: jq 1.7 filter library (one .jq module per question) + bash dispatcher + bats tests against sanitized state fixtures, input from terraform show -json
APP_TYPE: CLI
LANGUAGE: jq
SCALE: 45 workspaces, state files 5–90 MB, ~60 queries/day across 15 engineers
```

## 5. actionsum — GitHub Actions run digest

```text
APP_DESCRIPTION: A CLI tool for a platform team that summarizes GitHub Actions workflow runs from the REST API: failure rate per workflow, median duration, slowest jobs, and runners with queue delays. Output is a Markdown table pasted into the weekly engineering review.
TECH_STACK: jq 1.7 filter modules + bash wrapper paginating the GitHub Actions API via gh api + jq --run-tests fixtures, GITHUB_TOKEN from env
APP_TYPE: CLI
LANGUAGE: jq
SCALE: 80 repos, ~9,000 workflow runs/week analyzed, ~150 MB JSON per weekly run
```

## 6. specprune — OpenAPI dead-schema linter

```text
APP_DESCRIPTION: A CLI tool for API platform teams that lints OpenAPI 3.1 JSON specs for unreferenced components: schemas, parameters, and responses defined but never used by any path. It prints each orphan with its definition location so integrators can delete dead spec weight before publishing.
TECH_STACK: jq 1.7 filter modules (reference-graph walker) + bash wrapper + bats suite with minimal and pathological spec fixtures, input from spec repos in CI
APP_TYPE: CLI
LANGUAGE: jq
SCALE: 22 services, specs 0.5–8 MB, runs on every spec PR (~40 runs/day)
```

## 7. geoclip — GeoJSON property normalizer

```text
APP_DESCRIPTION: A CLI tool for a city GIS team that normalizes GeoJSON FeatureCollections from mixed vendor deliveries: renames inconsistent property keys, coerces numeric strings, drops internal vendor fields, and validates that every feature carries the required parcel-id and zoning fields before load into the mapping platform.
TECH_STACK: jq 1.7 filter modules + bash wrapper with per-vendor mapping files (--slurpfile) + jq --run-tests fixtures per vendor quirk
APP_TYPE: CLI
LANGUAGE: jq
SCALE: 8 vendors, monthly deliveries of 50k–400k features, files up to 1.2 GB, 3 GIS analysts
```

## 8. ndjrollup — NDJSON metrics hourly rollup

```text
APP_DESCRIPTION: A data pipeline for a SaaS backend team that rolls up NDJSON request-metric events (latency, status, tenant) into hourly aggregates: p50/p95 per endpoint, error rate per tenant, and top slow routes. Aggregates land as compact JSON consumed by a dashboard loader.
TECH_STACK: jq 1.7 streaming filters (inputs/reduce, -n flag) + bash wrapper reading gzipped NDJSON from object storage + jq --run-tests fixtures, hourly cron
APP_TYPE: data pipeline
LANGUAGE: jq
SCALE: ~40M events/day (~11 GB NDJSON), 24 runs/day, 90 endpoints tracked, 2 operators
```

## 9. jiraport — Jira export migration shaper

```text
APP_DESCRIPTION: A CLI tool for an IT migrations contractor that reshapes Jira Cloud JSON exports into the import format of a successor tracker: maps custom fields, flattens comment threads with author and timestamp, rewrites user account IDs from a mapping table, and splits output per project.
TECH_STACK: jq 1.7 filter modules + bash wrapper + user-mapping JSON via --slurpfile + bats tests against anonymized export fixtures
APP_TYPE: CLI
LANGUAGE: jq
SCALE: migrations of 5k–120k issues per engagement, exports up to 3 GB, ~15 migrations/year
```

## 10. slackmine — Slack export channel analytics

```text
APP_DESCRIPTION: A CLI tool for internal-comms managers that mines Slack workspace export ZIPs: messages per channel per month, top posters, thread depth, and dormant channels with no posts in 90 days. Produces a CSV that drives the quarterly channel-cleanup decision.
TECH_STACK: jq 1.7 filter modules + bash wrapper iterating per-channel per-day JSON files from the unzipped export + jq --run-tests fixtures
APP_TYPE: CLI
LANGUAGE: jq
SCALE: 900 channels, ~4M messages per export (~7 GB unzipped), run quarterly by 2 admins
```

## 11. notionflat — Notion export flattener

```text
APP_DESCRIPTION: A CLI tool for operations teams leaving Notion that flattens the nested block JSON of a workspace export into row-per-page CSV: title, parent path, last-edited time, and plain-text body extracted from rich-text arrays. The CSV seeds the content audit before re-platforming.
TECH_STACK: jq 1.7 recursive-descent filter modules + bash wrapper walking the export directory + bats tests with nested-block fixtures
APP_TYPE: CLI
LANGUAGE: jq
SCALE: workspaces of 3k–25k pages, exports 0.5–4 GB, one-shot runs during ~10 migrations/year
```

## 12. hookwash — webhook payload normalizer

```text
APP_DESCRIPTION: A data pipeline for an integrations team that normalizes inbound webhook payloads from Stripe, GitHub, and Shopify into one canonical event envelope (source, event_type, entity_id, occurred_at, body). Normalized NDJSON feeds the downstream event router.
TECH_STACK: jq 1.7 per-source filter modules + dispatch.jq selecting by source header + bash wrapper reading spooled payload files + jq --run-tests golden fixtures per source
APP_TYPE: data pipeline
LANGUAGE: jq
SCALE: ~180k webhooks/day across 3 sources, ~900 MB/day, 5-minute batch cadence, 4 integrators
```

## 13. csvledger — Stripe payout CSV builder

```text
APP_DESCRIPTION: A CLI tool for a finance-ops team that converts Stripe balance-transaction API pages into the CSV their accounting system imports: one row per transaction with gross, fee, net, currency, payout id, and mapped ledger account code. It reconciles row totals against the payout amount before writing.
TECH_STACK: jq 1.7 filter modules (@csv output, account-code map via --slurpfile) + bash wrapper paginating the Stripe API with curl + bats tests with fixture pages
APP_TYPE: CLI
LANGUAGE: jq
SCALE: ~45k transactions/month, daily runs of 5–20 MB JSON, 2 finance operators, 3 currencies
```

## 14. schemascore — JSON Schema conformance reporter

```text
APP_DESCRIPTION: A CLI tool for a data governance team that checks a corpus of JSON documents against lightweight structural rules derived from their JSON Schemas (required keys, type checks, enum membership) and emits a conformance report: pass rate per rule, top offending producers, and sample failing paths.
TECH_STACK: jq 1.7 rule-engine filter modules + bash wrapper fanning out over a document directory + jq --run-tests fixtures for each rule type
APP_TYPE: CLI
LANGUAGE: jq
SCALE: ~250k documents per audit (~3 GB), 30 schemas, monthly runs, 4 data stewards
```

## 15. feedstitch — multi-feed merge and dedup

```text
APP_DESCRIPTION: A data pipeline for a content aggregator that merges JSON Feed and JSON API article feeds from 60 publisher endpoints, deduplicates by canonical URL and title fingerprint, normalizes timestamps to UTC, and emits one sorted NDJSON stream for the site builder.
TECH_STACK: jq 1.7 filter modules (group_by/unique_by dedup, date normalization) + bash wrapper with curl fan-in + jq --run-tests fixtures, 15-minute cron
APP_TYPE: data pipeline
LANGUAGE: jq
SCALE: 60 feeds, ~12k articles/day, ~200 MB JSON/day, 96 runs/day
```

## 16. awsbillcut — Cost Explorer team report

```text
APP_DESCRIPTION: A CLI tool for a FinOps analyst that turns AWS Cost Explorer GetCostAndUsage JSON into per-team Markdown reports keyed by cost-allocation tags: month-over-month delta per service, untagged spend, and the ten fastest-growing line items per team.
TECH_STACK: jq 1.7 filter modules + bash wrapper calling aws ce via CLI + team-tag map via --slurpfile + bats tests with fixture responses
APP_TYPE: CLI
LANGUAGE: jq
SCALE: 40 AWS accounts, ~90k cost line items/month (~120 MB JSON), monthly + ad-hoc runs, 14 team reports
```

## 17. ecrstale — container registry staleness report

```text
APP_DESCRIPTION: A CLI tool for a devops team that reports stale Amazon ECR images from describe-images JSON: untagged layers older than 30 days, tags never pulled, and repositories exceeding their size budget, with an estimated storage saving per repo for the cleanup ticket.
TECH_STACK: jq 1.7 filter modules + bash wrapper looping aws ecr describe-images per repo + jq --run-tests fixtures, weekly scheduled run in CI
APP_TYPE: CLI
LANGUAGE: jq
SCALE: 130 repositories, ~85k images scanned weekly, ~400 MB JSON per run
```

## 18. iamgraze — IAM policy wildcard audit

```text
APP_DESCRIPTION: A CLI tool for cloud security engineers that audits IAM policy documents from aws iam get-account-authorization-details: flags Action or Resource wildcards, NotAction grants, and policies attached directly to users, ranked by blast radius (number of attached principals).
TECH_STACK: jq 1.7 filter modules (policy-document walker handling string-or-array fields) + bash wrapper + bats tests with policy fixtures covering edge shapes
APP_TYPE: CLI
LANGUAGE: jq
SCALE: 40 accounts, ~6,500 policies per sweep (~250 MB JSON), monthly audit by 3 security engineers
```

## 19. sgaudit — security group exposure report

```text
APP_DESCRIPTION: A CLI tool for a network security team that reads aws ec2 describe-security-groups JSON and reports rules open to 0.0.0.0/0, unused groups with no attached interfaces, and groups whose descriptions violate the naming policy, grouped by VPC and account.
TECH_STACK: jq 1.7 filter modules + bash wrapper joining describe-security-groups with describe-network-interfaces output + jq --run-tests fixtures
APP_TYPE: CLI
LANGUAGE: jq
SCALE: 40 accounts, ~4,200 security groups per run, weekly sweep, findings feed 1 ticketing queue
```

## 20. zonediff — DNS zone export differ

```text
APP_DESCRIPTION: A CLI tool for platform operators that diffs two Route 53 list-resource-record-sets exports taken before and after a change window: added, removed, and modified records with TTL and value deltas, formatted for the change-review ticket.
TECH_STACK: jq 1.7 filter modules (record-set keyed diff) + bash wrapper with --slurpfile pairs + bats tests with zone fixture pairs
APP_TYPE: CLI
LANGUAGE: jq
SCALE: 75 hosted zones, largest zone ~28k records, ~20 diffs/month during change windows
```

## 21. gvmtags — Azure VM tag compliance

```text
APP_DESCRIPTION: A CLI tool for a cloud governance analyst that checks `az vm list` JSON against the mandatory tag policy (owner, cost-center, environment): reports missing or malformed tags per subscription and emits a CSV for the remediation campaign mail-merge.
TECH_STACK: jq 1.7 filter modules + bash wrapper iterating az CLI across subscriptions + policy definition JSON via --slurpfile + jq --run-tests fixtures
APP_TYPE: CLI
LANGUAGE: jq
SCALE: 18 subscriptions, ~5,600 VMs per sweep (~90 MB JSON), weekly run
```

## 22. helmleaf — Helm release values extractor

```text
APP_DESCRIPTION: A CLI tool for platform engineers that inventories deployed Helm releases from `helm list -o json` plus `helm get values -o json`: which releases override image tags, which pin outdated chart versions, and which set resource limits, producing a fleet posture table.
TECH_STACK: jq 1.7 filter modules + bash wrapper looping helm across clusters and namespaces + bats tests with release fixtures
APP_TYPE: CLI
LANGUAGE: jq
SCALE: 6 clusters, ~340 releases per sweep, run before each of ~26 platform upgrades/year
```

## 23. probelint — workload spec linter

```text
APP_DESCRIPTION: A CLI tool for an SRE team that lints Kubernetes Deployment and StatefulSet JSON (kubectl get -o json) for missing readiness probes, absent resource limits, images tagged :latest, and single-replica production workloads, printing one finding per line for CI annotation.
TECH_STACK: jq 1.7 rule modules (one .jq per rule, shared severity envelope) + bash wrapper + jq --run-tests fixtures per rule, wired into GitLab CI
APP_TYPE: CLI
LANGUAGE: jq
SCALE: ~950 workloads across 6 clusters, runs on every deploy PR (~70 runs/day)
```

## 24. ingressmap — ingress hostname inventory

```text
APP_DESCRIPTION: A CLI tool for a platform team that builds a hostname inventory from kubectl ingress JSON across clusters: every host, path, backing service, TLS secret, and cert issuer annotation, flagging duplicate hosts claimed by two ingresses. Output is a Markdown table for the routing wiki page.
TECH_STACK: jq 1.7 filter modules + bash wrapper merging per-cluster kubectl output with --slurpfile + bats fixture tests
APP_TYPE: CLI
LANGUAGE: jq
SCALE: 6 clusters, ~520 ingresses / 1,100 hostnames, weekly regeneration
```

## 25. nodecap — cluster capacity report

```text
APP_DESCRIPTION: A CLI tool for capacity planners that joins kubectl node JSON with pod resource requests to report allocatable vs requested CPU and memory per node pool, headroom percentage, and nodes above 85% commitment, feeding the monthly node-pool sizing decision.
TECH_STACK: jq 1.7 filter modules (unit parsing for Ki/Mi/m suffixes, join by nodeName) + bash wrapper + jq --run-tests fixtures with mixed unit forms
APP_TYPE: CLI
LANGUAGE: jq
SCALE: 6 clusters / 210 nodes / ~3,800 pods per run, ~35 MB JSON, run weekly plus before scaling events
```

## 26. cronwake — CronJob failure digest

```text
APP_DESCRIPTION: A CLI tool for an on-call rotation that digests Kubernetes CronJob and Job JSON into a morning report: jobs that failed overnight with their last exit reason, jobs skipped by concurrency policy, and cron schedules that have not produced a successful run in 24 hours.
TECH_STACK: jq 1.7 filter modules + bash wrapper (kubectl get cronjobs,jobs -A -o json) + bats tests with failure-mode fixtures
APP_TYPE: CLI
LANGUAGE: jq
SCALE: ~140 CronJobs across 6 clusters, run daily by on-call, ~8 MB JSON per run
```

## 27. licensecull — npm dependency license audit

```text
APP_DESCRIPTION: A CLI tool for a release manager that audits `npm ls --all --json` output against an allowed-license list: flags GPL/AGPL packages, unknown license strings, and packages whose license changed since the last audit snapshot, producing the legal sign-off report per release.
TECH_STACK: jq 1.7 filter modules (recursive dependency tree walker) + bash wrapper + allowlist JSON via --slurpfile + jq --run-tests fixtures
APP_TYPE: CLI
LANGUAGE: jq
SCALE: 25 frontend repos, trees up to 3,200 packages, run per release (~10 runs/week)
```

## 28. wheelaudit — Python environment inspector

```text
APP_DESCRIPTION: A CLI tool for a platform team that audits `pip inspect` JSON from build images: packages installed outside the lockfile, yanked versions, and packages compiled without wheels, comparing environments across the 14 base images to catch drift.
TECH_STACK: jq 1.7 filter modules + bash wrapper collecting pip inspect from each image via docker run + bats tests with environment fixtures
APP_TYPE: CLI
LANGUAGE: jq
SCALE: 14 base images, ~450 packages each, nightly CI run, ~40 MB JSON per run
```

## 29. cargoscan — Rust workspace dependency report

```text
APP_DESCRIPTION: A CLI tool for a Rust platform team that analyzes `cargo metadata --format-version 1` output: duplicate crate versions inflating build time, crates pulled in by exactly one dependent, and feature flags enabled workspace-wide, printed as a Markdown report for the dependency-diet initiative.
TECH_STACK: jq 1.7 filter modules (resolve-graph walker) + bash wrapper + jq --run-tests fixtures from small workspaces
APP_TYPE: CLI
LANGUAGE: jq
SCALE: 8 workspaces, ~1,900 crates in the largest graph (~60 MB JSON), weekly run
```

## 30. depalert — Dependabot alert digest

```text
APP_DESCRIPTION: A CLI tool for an application security lead that digests GitHub Dependabot alert API responses org-wide: open critical/high alerts grouped by package and repo, alerts older than the 30-day SLA, and week-over-week burn-down, emitted as Markdown for the security standup.
TECH_STACK: jq 1.7 filter modules + bash wrapper paginating gh api /orgs/-/dependabot/alerts + jq --run-tests fixtures, weekly cron
APP_TYPE: CLI
LANGUAGE: jq
SCALE: 220 repos, ~1,400 open alerts tracked, weekly runs of ~80 MB JSON
```

## 31. prlag — pull request latency report

```text
APP_DESCRIPTION: A CLI tool for engineering managers that computes review latency from GitHub pull request API data: time-to-first-review and time-to-merge percentiles per repo, reviewers with the longest queues, and PRs idle beyond 3 business days, exported as CSV for the metrics deck.
TECH_STACK: jq 1.7 filter modules (ISO-8601 date math with fromdateiso8601) + bash wrapper using gh api with pagination + bats tests with PR fixtures
APP_TYPE: CLI
LANGUAGE: jq
SCALE: 45 repos, ~1,100 PRs/month analyzed, monthly runs of ~60 MB JSON, 6 managers
```

## 32. issuesweep — stale issue triage report

```text
APP_DESCRIPTION: A CLI tool for open-source maintainers that triages GitHub issues JSON: issues with no maintainer response in 14 days, issues missing required labels, and needs-reproduction issues where the reporter replied, ranked into a prioritized triage queue printed as Markdown checklists.
TECH_STACK: jq 1.7 filter modules + bash wrapper via gh api with since-cursor pagination + jq --run-tests fixtures per triage rule
APP_TYPE: CLI
LANGUAGE: jq
SCALE: 3 projects, ~2,600 open issues scanned, run twice weekly by 5 maintainers
```

## 33. glpipes — GitLab pipeline duration report

```text
APP_DESCRIPTION: A CLI tool for a build-infrastructure team that analyzes GitLab pipelines API JSON: median and p95 duration per project, jobs that dominate the critical path, retry-rate per runner tag, and week-over-week trend, driving the runner fleet sizing review.
TECH_STACK: jq 1.7 filter modules + bash wrapper paginating the GitLab REST API with curl + PRIVATE-TOKEN from env + bats fixture tests
APP_TYPE: CLI
LANGUAGE: jq
SCALE: 60 projects, ~14k pipelines/month (~200 MB JSON), weekly report runs
```

## 34. nginxsift — JSON access log summarizer

```text
APP_DESCRIPTION: A CLI tool for web operators that summarizes nginx JSON-format access logs: requests and error rate per vhost, top 20 URIs by p95 latency, status-class breakdown per upstream, and client IPs exceeding rate thresholds, printed as a plain-text incident triage report.
TECH_STACK: jq 1.7 streaming filters (-n with inputs over NDJSON) + bash wrapper with zcat over rotated logs + jq --run-tests fixtures
APP_TYPE: CLI
LANGUAGE: jq
SCALE: 12 vhosts, ~9M log lines/day (~5 GB), ad-hoc incident runs plus daily summary
```

## 35. errorspine — application error rollup

```text
APP_DESCRIPTION: A data pipeline for a backend team that rolls structured NDJSON application logs into an error spine: new error signatures (message template + top stack frame) per service per hour, first-seen and count, so the on-call sees novel breakage instead of raw log volume.
TECH_STACK: jq 1.7 filter modules (signature normalization, group_by rollup) + bash wrapper reading from the log shipper's S3 drop + jq --run-tests fixtures, hourly cron
APP_TYPE: data pipeline
LANGUAGE: jq
SCALE: 28 services, ~60M log lines/day (~25 GB NDJSON), 24 runs/day, on-call team of 9
```

## 36. sentrytrim — release health digest

```text
APP_DESCRIPTION: A CLI tool for release managers that condenses Sentry issues API JSON into a per-release health digest: new issue count vs previous release, crash-free session estimate, top 5 issues by affected users, and regressions of previously resolved issues, posted to the release channel.
TECH_STACK: jq 1.7 filter modules + bash wrapper calling the Sentry REST API per release tag + jq --run-tests fixtures
APP_TYPE: CLI
LANGUAGE: jq
SCALE: 6 apps, ~30 releases/month, ~2,000 issues scanned per digest, ~15 MB JSON per run
```

## 37. oncallcal — on-call schedule renderer

```text
APP_DESCRIPTION: A CLI tool for an SRE coordinator that turns PagerDuty schedule API exports into human artifacts: a Markdown month grid per rotation, per-person total on-call hours for the fairness review, and overlaps or gaps between primary and secondary layers.
TECH_STACK: jq 1.7 filter modules (date bucketing, layer overlap detection) + bash wrapper with curl against the PagerDuty API + bats fixture tests
APP_TYPE: CLI
LANGUAGE: jq
SCALE: 7 rotations / 45 responders, monthly generation plus ~10 ad-hoc runs, ~4 MB JSON per run
```

## 38. monlint — monitor config auditor

```text
APP_DESCRIPTION: A CLI tool for an observability team that audits Datadog monitor definitions exported via API: monitors with no notification channel, muted longer than 7 days, missing runbook links in the message, and duplicated queries across teams, emitted as a per-team fix list.
TECH_STACK: jq 1.7 rule modules + bash wrapper paginating the Datadog monitors API + jq --run-tests fixtures per rule
APP_TYPE: CLI
LANGUAGE: jq
SCALE: ~2,300 monitors across 18 teams, weekly audit, ~35 MB JSON per run
```

## 39. dashdrift — dashboard JSON drift linter

```text
APP_DESCRIPTION: A CLI tool for an observability team that lints Grafana dashboard JSON stored in git: panels pointing at deprecated datasource UIDs, templating variables with hardcoded environment values, and dashboards diverging from the provisioned version in the running instance.
TECH_STACK: jq 1.7 filter modules (panel tree walker) + bash wrapper comparing git copies against Grafana HTTP API exports + bats tests with dashboard fixtures
APP_TYPE: CLI
LANGUAGE: jq
SCALE: 240 dashboards / ~3,900 panels, runs on every dashboard PR plus nightly sweep
```

## 40. alertfold — alert webhook dedup pipeline

```text
APP_DESCRIPTION: A data pipeline for a NOC team that folds Alertmanager webhook JSON bursts into deduplicated incident candidates: groups firing alerts by cluster and alertname, suppresses flapping series that resolve within 5 minutes, and emits one NDJSON incident record per stable group for the ticketing bridge.
TECH_STACK: jq 1.7 filter modules (windowed group/fold logic) + bash wrapper draining a spool directory every minute + jq --run-tests fixtures for flap scenarios
APP_TYPE: data pipeline
LANGUAGE: jq
SCALE: ~11k webhook posts/day folding to ~180 incidents, 1-minute cadence, 6 NOC operators
```

## 41. payoutrecon — marketplace payout reconciler

```text
APP_DESCRIPTION: A CLI tool for a finance-ops analyst that reconciles PayPal transaction-search API JSON against the internal orders export: matches transactions to order IDs, computes fee totals per settlement batch, and lists unmatched transactions and orders for manual investigation.
TECH_STACK: jq 1.7 filter modules (two-source join via --slurpfile, INDEX/lookup) + bash wrapper + bats tests with matched/unmatched fixture pairs
APP_TYPE: CLI
LANGUAGE: jq
SCALE: ~28k transactions/month, daily reconciliation runs of ~15 MB JSON, 2 analysts
```

## 42. shopflat — product catalog export shaper

```text
APP_DESCRIPTION: A CLI tool for an e-commerce operations team that reshapes Shopify product API JSON into the flat feed a price-comparison partner requires: one row per variant with SKU, GTIN, price, inventory, and image URL, dropping draft products and variants without barcodes.
TECH_STACK: jq 1.7 filter modules (variant explosion, @csv and TSV emitters) + bash wrapper paginating the Admin API + jq --run-tests fixtures
APP_TYPE: CLI
LANGUAGE: jq
SCALE: ~18k products / 65k variants, nightly feed generation, ~250 MB JSON per run
```

## 43. sfwash — CRM export field normalizer

```text
APP_DESCRIPTION: A CLI tool for a revenue-operations team that cleans Salesforce REST export JSON before warehouse load: normalizes phone numbers and country codes, maps legacy picklist values to the current set, nulls out placeholder strings like "N/A", and reports a per-field cleansing tally.
TECH_STACK: jq 1.7 filter modules (per-field cleaner library, picklist map via --slurpfile) + bash wrapper + bats tests with dirty-record fixtures
APP_TYPE: CLI
LANGUAGE: jq
SCALE: ~600k records per weekly export (~2.5 GB JSON), 52 runs/year, 3 rev-ops users
```

## 44. hubdup — contact export deduplicator

```text
APP_DESCRIPTION: A CLI tool for a marketing-operations manager that finds duplicates in HubSpot contact export JSON: clusters records by normalized email and by company+name fingerprint, picks a survivor by completeness score, and emits a merge plan CSV for review before any API merges run.
TECH_STACK: jq 1.7 filter modules (normalization + group_by clustering + scoring) + bash wrapper + jq --run-tests fixtures for cluster edge cases
APP_TYPE: CLI
LANGUAGE: jq
SCALE: ~340k contacts per export (~1.1 GB), quarterly dedup campaigns, ~9k duplicate clusters found per run
```

## 45. zensift — support ticket SLA digest

```text
APP_DESCRIPTION: A CLI tool for a support team lead that digests Zendesk ticket export JSON: first-reply-time and resolution-time percentiles per queue, SLA breaches by tier, reopened-ticket rate per agent, and topic tag trends, rendered as a Markdown weekly ops review.
TECH_STACK: jq 1.7 filter modules (timestamp math, percentile helpers) + bash wrapper over incremental export API pages + bats fixture tests
APP_TYPE: CLI
LANGUAGE: jq
SCALE: ~9k tickets/week across 4 queues, weekly runs of ~180 MB JSON, 3 leads consuming
```

## 46. bouncebin — email bounce report

```text
APP_DESCRIPTION: A CLI tool for a deliverability specialist that classifies Mailgun events API JSON: hard bounces by recipient domain, spam complaints per campaign, and addresses to suppress, producing both a summary table and a suppression CSV handed to the sending platform.
TECH_STACK: jq 1.7 filter modules (event classification, domain rollup) + bash wrapper paginating the events API + jq --run-tests fixtures per event type
APP_TYPE: CLI
LANGUAGE: jq
SCALE: ~1.2M send events/week (~600 MB JSON), weekly runs, ~4k suppressions emitted per run
```

## 47. supprune — suppression list reconciler

```text
APP_DESCRIPTION: A CLI tool for a CRM administrator that reconciles SendGrid suppression exports (bounces, blocks, unsubscribes) against the CRM do-not-contact list: addresses suppressed upstream but still marketable in CRM, and CRM opt-outs missing from the provider, emitted as two fix-up CSVs.
TECH_STACK: jq 1.7 filter modules (set difference via INDEX) + bash wrapper fetching both exports + bats tests with fixture pairs
APP_TYPE: CLI
LANGUAGE: jq
SCALE: ~250k suppressed addresses vs 1.8M CRM records, monthly reconciliation, ~500 MB JSON per run
```

## 48. callcut — telephony usage cost report

```text
APP_DESCRIPTION: A CLI tool for an operations accountant that turns Twilio call and message log JSON into a per-department cost report: minutes and spend by department prefix, international calls over threshold, and numbers with zero usage that can be released, exported as CSV for chargeback.
TECH_STACK: jq 1.7 filter modules (price aggregation, prefix mapping via --slurpfile) + bash wrapper paginating the Twilio API + jq --run-tests fixtures
APP_TYPE: CLI
LANGUAGE: jq
SCALE: ~90k calls + 300k messages/month (~350 MB JSON), monthly close runs, 11 departments
```

## 49. oktasift — identity log anomaly review

```text
APP_DESCRIPTION: A CLI tool for a security analyst's defensive log review that sifts Okta System Log API JSON: impossible-travel sign-in pairs, MFA fatigue patterns (repeated push denials), new-device admin logins, and API token usage from unseen IPs, printed as a ranked review worksheet.
TECH_STACK: jq 1.7 filter modules (per-detection .jq files, geo/ASN annotation from a lookup file) + bash wrapper paginating the System Log API + jq --run-tests fixtures per detection
APP_TYPE: CLI
LANGUAGE: jq
SCALE: ~700k events/day (~2 GB JSON), daily review runs, 4 analysts, 12k monitored identities
```

## 50. authtrail — auth event stream digester

```text
APP_DESCRIPTION: A data pipeline for an identity team that digests Auth0 log-stream NDJSON into hourly summaries: failed-login rate per connection, signup conversion per client app, brute-force lockouts, and rule-execution errors, appended to a rolling 30-day trend file for the dashboard.
TECH_STACK: jq 1.7 streaming filter modules + bash wrapper reading the log-stream S3 sink + jq --run-tests fixtures, hourly cron
APP_TYPE: data pipeline
LANGUAGE: jq
SCALE: ~3M auth events/day (~1.5 GB NDJSON), 24 runs/day, 9 client applications tracked
```

## 51. vaultsift — secrets audit log summarizer

```text
APP_DESCRIPTION: A CLI tool for a platform security team that summarizes HashiCorp Vault audit-device NDJSON: read volume per secret path, tokens accessing paths outside their usual set, root-token usage events, and dormant AppRoles with no logins in 60 days, formatted for the quarterly access review.
TECH_STACK: jq 1.7 streaming filter modules (HMAC'd-field aware) + bash wrapper over rotated audit files + bats fixture tests
APP_TYPE: CLI
LANGUAGE: jq
SCALE: ~2.5M audit entries/day (~3 GB NDJSON), quarterly review over 90-day windows, 3 reviewers
```

## 52. acmwatch — certificate expiry reporter

```text
APP_DESCRIPTION: A CLI tool for a devops team that reports on AWS ACM list/describe-certificate JSON across accounts: certificates expiring within 30 days, failed renewals with their validation errors, and certs whose domains no longer resolve to the load balancer, printed as an actionable expiry table.
TECH_STACK: jq 1.7 filter modules (date math, multi-account merge) + bash wrapper looping aws acm across profiles + jq --run-tests fixtures
APP_TYPE: CLI
LANGUAGE: jq
SCALE: 40 accounts, ~1,100 certificates, daily scheduled run, ~20 MB JSON per sweep
```

## 53. cfzlint — CDN zone settings auditor

```text
APP_DESCRIPTION: A CLI tool for a web platform team that audits Cloudflare API zone JSON against the security baseline: zones without strict TLS, missing HSTS, development mode left on, and firewall rules disabled since the last audit, producing a per-zone pass/fail matrix.
TECH_STACK: jq 1.7 rule modules + baseline JSON via --slurpfile + bash wrapper paginating the Cloudflare v4 API + jq --run-tests fixtures per rule
APP_TYPE: CLI
LANGUAGE: jq
SCALE: 85 zones, weekly audit runs of ~15 MB JSON, 14 baseline rules enforced
```

## 54. lifecyclint — object storage lifecycle audit

```text
APP_DESCRIPTION: A CLI tool for a storage cost owner that audits s3api get-bucket-lifecycle-configuration JSON fleet-wide: buckets with no expiration rules, incomplete-multipart-upload cleanup missing, rules disabled but never deleted, and buckets whose noncurrent-version retention exceeds policy.
TECH_STACK: jq 1.7 filter modules + bash wrapper looping s3api per bucket with error-tolerant collection + bats tests with rule fixtures
APP_TYPE: CLI
LANGUAGE: jq
SCALE: ~640 buckets across 40 accounts, monthly audit, findings feed ~30 tickets/quarter
```

## 55. lambdaledger — serverless function inventory

```text
APP_DESCRIPTION: A CLI tool for a platform team that inventories aws lambda list-functions JSON: functions on deprecated runtimes with their deprecation date, memory/timeout outliers, functions not invoked in 90 days (joined with CloudWatch metric JSON), and env vars that look like inline secrets.
TECH_STACK: jq 1.7 filter modules (runtime deprecation table via --slurpfile, metric join) + bash wrapper + jq --run-tests fixtures
APP_TYPE: CLI
LANGUAGE: jq
SCALE: ~820 functions across 40 accounts, monthly sweep of ~45 MB JSON, drives runtime-upgrade campaigns
```

## 56. taskdiff — container task definition differ

```text
APP_DESCRIPTION: A CLI tool for a deployment engineer that diffs two ECS task-definition revisions from describe-task-definition JSON: image tag changes, env var additions/removals (values masked), CPU/memory shifts, and new secrets references, formatted as the change summary pasted into deploy tickets.
TECH_STACK: jq 1.7 filter modules (container-keyed structural diff, secret masking) + bash wrapper + bats tests with revision-pair fixtures
APP_TYPE: CLI
LANGUAGE: jq
SCALE: 95 services, ~400 diffs/month in the deploy pipeline, task definitions up to 60 KB each
```

## 57. scaletrace — autoscaling activity reporter

```text
APP_DESCRIPTION: A CLI tool for an SRE team that reports on aws autoscaling describe-scaling-activities JSON: scale-out storms per group per day, failed launches with their error causes, and thrash (opposing actions within 10 minutes), guiding cooldown and policy tuning.
TECH_STACK: jq 1.7 filter modules (time-window pairing, cause-string extraction) + bash wrapper across regions + jq --run-tests fixtures
APP_TYPE: CLI
LANGUAGE: jq
SCALE: 48 autoscaling groups, ~6k activities/week analyzed, weekly tuning runs
```

## 58. volorphan — unattached volume reaper report

```text
APP_DESCRIPTION: A CLI tool for a cloud cost analyst that reports orphaned block storage from ec2 describe-volumes JSON: unattached volumes with age and monthly cost estimate, volumes whose last attached instance no longer exists, and snapshots orphaned by deleted volumes, as a deletion-candidate CSV.
TECH_STACK: jq 1.7 filter modules (price table via --slurpfile, cross-referencing describe-instances) + bash wrapper + bats fixture tests
APP_TYPE: CLI
LANGUAGE: jq
SCALE: 40 accounts, ~3,900 volumes scanned weekly, typically 200–400 orphan candidates per run
```

## 59. patchgrade — patch compliance rollup

```text
APP_DESCRIPTION: A CLI tool for an infrastructure compliance officer that rolls up AWS SSM patch-compliance JSON: compliant vs missing-patch instance counts per patch group, instances failing scans for 3+ cycles, and critical patches outstanding past SLA, formatted as the monthly compliance attachment.
TECH_STACK: jq 1.7 filter modules + bash wrapper over ssm list-resource-compliance-summaries pagination + jq --run-tests fixtures
APP_TYPE: CLI
LANGUAGE: jq
SCALE: ~2,700 managed instances / 14 patch groups, monthly report plus weekly spot runs, ~70 MB JSON per sweep
```

## 60. guardsift — threat findings digest pipeline

```text
APP_DESCRIPTION: A data pipeline for a security operations team that digests Amazon GuardDuty findings JSON exported to S3: dedupes recurring findings by resource and type, escalates new high-severity types, tracks suppressed-finding volume, and emits a daily NDJSON triage queue for the SOAR intake.
TECH_STACK: jq 1.7 filter modules (finding fingerprinting, severity routing) + bash wrapper on the S3 export prefix + jq --run-tests fixtures per finding type, daily cron
APP_TYPE: data pipeline
LANGUAGE: jq
SCALE: ~4,500 findings/day deduped to ~120 triage items, 40 accounts, daily run, 5 SOC analysts
```

## 61. trivymark — scan report PR renderer

```text
APP_DESCRIPTION: A CLI tool for a devsecops team that converts Trivy JSON scan reports into Markdown PR comments: vulnerability table grouped by severity with fixed-version column, comparison against the base branch scan to show only newly introduced CVEs, and a pass/fail verdict against the severity gate.
TECH_STACK: jq 1.7 filter modules (report diffing via --slurpfile, Markdown table emitter) + bash wrapper in GitHub Actions + jq --run-tests golden-output fixtures
APP_TYPE: CLI
LANGUAGE: jq
SCALE: 70 repos, ~250 scans/day in CI, reports 0.1–40 MB each
```

## 62. grypefold — fleet vulnerability aggregator

```text
APP_DESCRIPTION: A CLI tool for a security engineering team that aggregates Grype JSON scans from all service images into one fleet view: CVE frequency across images, packages driving the most findings, images whose count rose since last week, and a top-20 fix-first list weighted by severity and spread.
TECH_STACK: jq 1.7 filter modules (multi-file reduce over a scan directory) + bash wrapper + bats tests with multi-image fixtures, weekly scheduled run
APP_TYPE: CLI
LANGUAGE: jq
SCALE: 180 images scanned weekly, ~1.4 GB of scan JSON per run, ~9k raw findings folded to ~600 unique CVEs
```

## 63. sarifknit — static analysis report merger

```text
APP_DESCRIPTION: A CLI tool for a CI platform team that merges SARIF files from multiple analyzers (CodeQL, Semgrep, custom linters) into one deduplicated upload: normalizes rule IDs, drops results in generated code paths, and dedupes identical findings reported by two tools at the same location.
TECH_STACK: jq 1.7 filter modules (SARIF 2.1.0 run merging, location fingerprints) + bash wrapper in the CI upload step + jq --run-tests fixtures per analyzer dialect
APP_TYPE: CLI
LANGUAGE: jq
SCALE: 90 repos, 3 analyzers each, ~300 merges/day, SARIF files up to 25 MB
```

## 64. lintboard — lint debt team scoreboard

```text
APP_DESCRIPTION: A CLI tool for a frontend guild that turns ESLint --format json output from all repos into a debt scoreboard: warnings per rule per team, files over the error budget, rules trending up since last month, and the top 10 quick-win rules by autofixable count.
TECH_STACK: jq 1.7 filter modules (repo-to-team map via --slurpfile, trend diff) + bash wrapper collecting CI artifacts + bats fixture tests
APP_TYPE: CLI
LANGUAGE: jq
SCALE: 32 repos / 9 teams, ~85k lint messages per monthly rollup, ~500 MB JSON per run
```

## 65. flakeledger — flaky test tracking pipeline

```text
APP_DESCRIPTION: A data pipeline for a developer-experience team that ingests Jest --json result files from every CI run and maintains a flake ledger: tests that both passed and failed on the same commit, flake rate per suite over a 14-day window, and newly flaky tests since yesterday, published as NDJSON for the quarantine bot.
TECH_STACK: jq 1.7 filter modules (result folding, rolling-window ledger update) + bash wrapper on the CI artifact bucket + jq --run-tests fixtures, nightly cron
APP_TYPE: data pipeline
LANGUAGE: jq
SCALE: ~1,200 CI runs/day, 48k tests tracked, ~2 GB of result JSON nightly, 1 quarantine bot consumer
```

## 66. covtrend — coverage trend pipeline

```text
APP_DESCRIPTION: A data pipeline for an engineering-quality lead that appends each build's coverage-summary.json to a per-repo NDJSON history and emits trend reports: coverage delta per package since last release, files that dropped more than 5 points, and repos below the 70% floor.
TECH_STACK: jq 1.7 filter modules (summary flattening, threshold rules) + bash wrapper triggered post-build in CI + bats tests with summary fixtures
APP_TYPE: data pipeline
LANGUAGE: jq
SCALE: 38 repos, ~400 builds/day appended, history files up to 80 MB, weekly trend report
```

## 67. lhbudget — performance budget gate

```text
APP_DESCRIPTION: A CLI tool for a web performance engineer that evaluates Lighthouse JSON reports against per-page budgets: LCP, CLS, total byte weight, and unused JavaScript, failing CI with a table of which budget each URL blew and by how much.
TECH_STACK: jq 1.7 filter modules (audit extraction, budget file via --slurpfile) + bash wrapper around lighthouse-ci artifacts + jq --run-tests fixtures
APP_TYPE: CLI
LANGUAGE: jq
SCALE: 25 tracked URLs, ~120 report evaluations/day in CI, reports ~2 MB each
```

## 68. apidrift — API breaking-change reporter

```text
APP_DESCRIPTION: A CLI tool for API integrators that compares two OpenAPI JSON spec versions and reports consumer-breaking drift: removed paths and operations, parameters that became required, response fields removed or retyped, and enum values dropped, grouped by affected endpoint for the partner changelog.
TECH_STACK: jq 1.7 filter modules (path/schema structural diff via --slurpfile pair) + bash wrapper + bats tests with before/after spec fixtures
APP_TYPE: CLI
LANGUAGE: jq
SCALE: 14 partner-facing APIs, ~50 comparisons/month in the release pipeline, specs up to 6 MB
```

## 69. postwash — API collection sanitizer

```text
APP_DESCRIPTION: A CLI tool for a developer-relations team that sanitizes Postman collection JSON before publishing to partners: strips auth tokens and cookie headers, replaces internal hostnames with placeholder variables, drops disabled requests, and verifies every request has a description.
TECH_STACK: jq 1.7 filter modules (recursive item-tree walker, secret pattern scrub) + bash wrapper + jq --run-tests fixtures with planted secrets
APP_TYPE: CLI
LANGUAGE: jq
SCALE: 9 published collections, ~600 requests total, sanitized on every docs release (~8 runs/month)
```

## 70. harslim — web session HAR analyzer

```text
APP_DESCRIPTION: A CLI tool for a frontend performance consultant that analyzes browser HAR files: third-party requests grouped by domain with byte and blocking-time totals, requests missing cache headers, duplicate downloads of the same asset, and a stripped-down HAR with response bodies removed for sharing.
TECH_STACK: jq 1.7 filter modules (entry aggregation, body stripping) + bash wrapper + bats tests with recorded HAR fixtures
APP_TYPE: CLI
LANGUAGE: jq
SCALE: HAR files 5–150 MB, ~30 client audits/month, 400–2,000 entries per capture
```

## 71. k6cut — load test result summarizer

```text
APP_DESCRIPTION: A CLI tool for a performance testing team that summarizes k6 NDJSON metric output: p95/p99 latency per endpoint tag, error rate per scenario, threshold pass/fail recap, and a run-over-run comparison against the stored baseline, printed as the report attached to each release.
TECH_STACK: jq 1.7 streaming filter modules (point folding by metric+tags) + bash wrapper with baseline via --slurpfile + jq --run-tests fixtures
APP_TYPE: CLI
LANGUAGE: jq
SCALE: ~20 load tests/month, 2–6 GB NDJSON per test run, 15 endpoint tags per run
```

## 72. parcelprop — land parcel attribute mapper

```text
APP_DESCRIPTION: A CLI tool for a county assessor's data team that maps parcel GeoJSON attributes between the appraisal system's schema and the state submission schema: field renames, land-use code translation via lookup table, acreage unit conversion, and a rejects file for parcels failing required-field checks.
TECH_STACK: jq 1.7 filter modules (feature-wise mapping, code table via --slurpfile) + bash wrapper + bats tests with parcel fixtures per land-use class
APP_TYPE: CLI
LANGUAGE: jq
SCALE: ~210k parcels per quarterly submission (~1.8 GB GeoJSON), 4 runs/year plus corrections, 2 operators
```

## 73. poiforge — OpenStreetMap POI extractor

```text
APP_DESCRIPTION: A CLI tool for a delivery-logistics analyst that converts Overpass API JSON into clean CSV point-of-interest lists: filters by amenity tags, merges node and way centroids, normalizes opening_hours and phone tags, and dedupes POIs within 25 meters bearing the same name.
TECH_STACK: jq 1.7 filter modules (tag normalization, proximity fingerprint dedup) + bash wrapper templating Overpass queries with curl + jq --run-tests fixtures
APP_TYPE: CLI
LANGUAGE: jq
SCALE: ~35 city extracts/month, 5k–80k POIs per extract, responses up to 300 MB
```

## 74. transitlag — vehicle delay rollup pipeline

```text
APP_DESCRIPTION: A data pipeline for a regional transit agency's service planners that rolls up GTFS-realtime JSON vehicle-position feeds into delay statistics: median delay per route per hour, stops with chronic dwell overruns, and vehicles reporting stale positions, appended to a daily NDJSON archive.
TECH_STACK: jq 1.7 streaming filter modules + bash wrapper polling the JSON feed endpoint every minute + jq --run-tests fixtures, systemd timer
APP_TYPE: data pipeline
LANGUAGE: jq
SCALE: 340 vehicles / 58 routes, 1,440 polls/day (~2.5 GB JSON/day), 3 planners consuming reports
```

## 75. shadowaudit — IoT device shadow auditor

```text
APP_DESCRIPTION: A CLI tool for an IoT fleet operator that audits AWS IoT device-shadow JSON across the fleet: devices whose reported firmware lags desired by 2+ versions, shadows with delta unresolved for 7 days, and config values outside safe ranges, producing the weekly fleet health sheet.
TECH_STACK: jq 1.7 filter modules (desired/reported delta analysis, range rules via --slurpfile) + bash wrapper looping get-thing-shadow + bats fixture tests
APP_TYPE: CLI
LANGUAGE: jq
SCALE: ~7,200 devices, weekly full sweep (~1.5 GB shadow JSON), 2 fleet operators
```

## 76. sensorbin — telemetry binning pipeline

```text
APP_DESCRIPTION: A data pipeline for a building-management contractor that bins NDJSON sensor telemetry (temperature, humidity, CO2) into 15-minute aggregates per zone: min/max/mean, out-of-range minutes, and sensors silent for 2+ intervals, writing compact JSON consumed by the tenant comfort dashboard.
TECH_STACK: jq 1.7 streaming filter modules (timestamp bucketing, per-zone fold) + bash wrapper on the MQTT bridge's file sink + jq --run-tests fixtures, 15-minute cron
APP_TYPE: data pipeline
LANGUAGE: jq
SCALE: 3,400 sensors across 12 buildings, ~29M readings/day (~4 GB NDJSON), 96 runs/day
```

## 77. citecut — scholarly citation exporter

```text
APP_DESCRIPTION: A CLI tool for a university research-impact office that extracts citation data from OpenAlex API JSON: publications per faculty author with citation counts, open-access status, and co-author institutions, flattened to the CSV format the annual assessment spreadsheet expects.
TECH_STACK: jq 1.7 filter modules (author disambiguation by ORCID, @csv emitter) + bash wrapper with cursor pagination via curl + jq --run-tests fixtures
APP_TYPE: CLI
LANGUAGE: jq
SCALE: ~1,900 faculty, ~48k works per annual export (~900 MB JSON), 1 annual run plus monthly refreshes
```

## 78. crossknit — publication metadata normalizer

```text
APP_DESCRIPTION: A CLI tool for a library metadata team that normalizes Crossref works API JSON into the repository ingest format: reconstructs author name order, picks the best date from the date-parts ladder, maps license URLs to SPDX identifiers, and reports records with missing DOI relations.
TECH_STACK: jq 1.7 filter modules (date-parts handling, license map via --slurpfile) + bash wrapper batching DOI queries + bats tests with messy-record fixtures
APP_TYPE: CLI
LANGUAGE: jq
SCALE: ~15k records/month ingested, batches of 500 DOIs, ~120 MB JSON monthly, 3 catalogers
```

## 79. cratewatch — registry dependency freshness

```text
APP_DESCRIPTION: A CLI tool for a Rust team lead that checks workspace dependencies against crates.io API JSON: crates more than one minor version behind, dependencies yanked upstream, and crates with no release in 2 years, printed as an upgrade-planning table with links.
TECH_STACK: jq 1.7 filter modules (semver comparison helpers) + bash wrapper joining cargo metadata output with crates.io API responses + jq --run-tests fixtures
APP_TYPE: CLI
LANGUAGE: jq
SCALE: 8 workspaces / ~600 direct dependencies, weekly runs, ~50 MB JSON per sweep
```

## 80. composerlock — PHP lockfile auditor

```text
APP_DESCRIPTION: A CLI tool for a PHP platform team that audits composer.lock files across client sites: abandoned packages (per packagist metadata), packages installed from dist vs VCS forks, PHP version constraint conflicts with the target runtime, and a cross-site matrix of shared outdated packages.
TECH_STACK: jq 1.7 filter modules + bash wrapper collecting lockfiles from site repos and packagist API metadata + bats tests with lockfile fixtures
APP_TYPE: CLI
LANGUAGE: jq
SCALE: 46 client sites, lockfiles ~1–3 MB each, monthly audit run, ~180 packages flagged per cycle
```

## 81. fhirtrim — clinical bundle extractor

```text
APP_DESCRIPTION: A CLI tool for a health-tech integration engineer that extracts targeted resources from FHIR R4 Bundle JSON: patient demographics, active medication statements, and recent observations by LOINC code, flattened into the row format the analytics staging table expects, with PHI fields the downstream system must not receive removed.
TECH_STACK: jq 1.7 filter modules (resourceType routing, reference resolution within bundle, field redaction) + bash wrapper + jq --run-tests fixtures with synthetic Synthea bundles
APP_TYPE: CLI
LANGUAGE: jq
SCALE: ~1,200 bundles/day from 3 sending systems (~2 GB JSON/day), nightly batch, 2 integration engineers
```

## 82. wcorders — storefront order feed builder

```text
APP_DESCRIPTION: A CLI tool for a third-party-logistics coordinator that converts WooCommerce REST API order JSON into the warehouse's pick-list CSV: one row per line item with SKU, bin-ready quantity, shipping service mapping, and gift-note flag, excluding orders on hold or flagged for fraud review.
TECH_STACK: jq 1.7 filter modules (line-item explosion, shipping map via --slurpfile) + bash wrapper paginating the REST API + bats fixture tests
APP_TYPE: CLI
LANGUAGE: jq
SCALE: ~850 orders/day (~2,600 line items), 3 feed runs/day, ~60 MB JSON per day
```

## 83. graphusers — tenant license audit

```text
APP_DESCRIPTION: A CLI tool for a Microsoft 365 administrator that audits Graph API user JSON: licensed accounts with no sign-in for 60 days, disabled users still holding licenses, guests with owner roles on groups, and license SKU totals vs contract entitlements, output as the monthly true-up worksheet.
TECH_STACK: jq 1.7 filter modules (SKU map via --slurpfile, signInActivity joins) + bash wrapper paginating Graph with az rest + jq --run-tests fixtures
APP_TYPE: CLI
LANGUAGE: jq
SCALE: ~9,800 users / 14 license SKUs, monthly audit of ~350 MB JSON, reclaims ~120 licenses/quarter
```

## 84. wsauditroll — workspace admin activity digest

```text
APP_DESCRIPTION: A CLI tool for a Google Workspace administrator's security review that digests Admin SDK Reports API JSON: external file-sharing events by department, new OAuth app grants with requested scopes, admin-role changes, and takeout requests, compiled into a weekly review document.
TECH_STACK: jq 1.7 filter modules (activity event flattening, scope risk table via --slurpfile) + bash wrapper with OAuth token refresh + bats fixture tests
APP_TYPE: CLI
LANGUAGE: jq
SCALE: 3,200 users, ~450k activity events/week (~700 MB JSON), weekly runs, 2 admins reviewing
```

## 85. resticledger — backup snapshot verifier

```text
APP_DESCRIPTION: A CLI tool for a managed-services provider that verifies restic backup fleets from `restic snapshots --json` and `restic stats --json`: hosts with no snapshot in 24 hours, repositories violating the 7-daily/4-weekly retention shape, and repos growing faster than 20% week over week, as a per-client status board.
TECH_STACK: jq 1.7 filter modules (retention shape checker, growth trend) + bash wrapper looping repos with per-client credentials + jq --run-tests fixtures
APP_TYPE: CLI
LANGUAGE: jq
SCALE: 38 clients / 410 hosts, daily verification run, ~25 MB JSON per sweep
```

## 86. smartfleet — disk health fleet pipeline

```text
APP_DESCRIPTION: A data pipeline for a datacenter operations team that collects `smartctl -j` output from every host nightly and produces a failing-disk watchlist: reallocated-sector growth, pending sectors, SSD wear percentage over threshold, and drives whose attributes degraded since the previous run.
TECH_STACK: jq 1.7 filter modules (attribute delta vs prior snapshot via --slurpfile) + bash wrapper aggregating per-host files from the collection share + jq --run-tests fixtures, nightly cron
APP_TYPE: data pipeline
LANGUAGE: jq
SCALE: 620 hosts / ~4,900 drives, nightly runs of ~300 MB JSON, 8–15 watchlist entries per week
```

## 87. layerlens — image config auditor

```text
APP_DESCRIPTION: A CLI tool for a container platform team that audits `docker inspect` and image config JSON: images running as root, exposed ports outside the allowed set, layers over 500 MB, missing OCI labels required by the provenance policy, and ENV values matching secret patterns.
TECH_STACK: jq 1.7 rule modules + bash wrapper pulling configs via crane/docker for each release image + jq --run-tests fixtures per rule
APP_TYPE: CLI
LANGUAGE: jq
SCALE: 180 images per release cycle, ~40 audit runs/week in CI, configs ~100 KB each
```

## 88. unitfail — systemd fleet failure digest

```text
APP_DESCRIPTION: A CLI tool for a Linux fleet administrator that digests `systemctl list-units --output=json` collected from all hosts: failed units grouped by unit name across the fleet, hosts with degraded system state, and units flapping between runs, printed as the morning fleet health summary.
TECH_STACK: jq 1.7 filter modules (fleet merge, flap detection vs previous snapshot) + bash wrapper over per-host files gathered by the config-management run + bats fixture tests
APP_TYPE: CLI
LANGUAGE: jq
SCALE: 480 hosts, ~95k unit records per sweep (~120 MB JSON), 2 runs/day
```

## 89. journalsift — boot log error extractor

```text
APP_DESCRIPTION: A CLI tool for an embedded-device support team that sifts `journalctl -o json` exports pulled from field devices: errors and warnings in the last boot grouped by unit, kernel messages matching known-fault signatures, and time gaps suggesting watchdog resets, producing the triage summary attached to each RMA ticket.
TECH_STACK: jq 1.7 streaming filter modules (signature table via --slurpfile) + bash wrapper over uploaded journal exports + jq --run-tests fixtures per fault signature
APP_TYPE: CLI
LANGUAGE: jq
SCALE: ~60 device journals/week, 50–400 MB NDJSON each, 4 support engineers, 23 fault signatures
```

## 90. speedledger — ISP performance trend pipeline

```text
APP_DESCRIPTION: A data pipeline for a rural ISP's network planner that appends speedtest-CLI JSON results from customer-premises probes to per-probe NDJSON ledgers and emits weekly trends: median down/up per node, probes below the advertised tier for 3+ days, and evening congestion windows per segment.
TECH_STACK: jq 1.7 filter modules (ledger append, tier table via --slurpfile) + bash wrapper collecting probe uploads + jq --run-tests fixtures, hourly ingest + weekly report cron
APP_TYPE: data pipeline
LANGUAGE: jq
SCALE: 240 probes, 24 tests/probe/day (~5,800 results/day), ledgers ~1 GB total, weekly report to 3 planners
```

## 91. unifiroll — campus network client inventory

```text
APP_DESCRIPTION: A CLI tool for a school-district network administrator that inventories UniFi controller API JSON: clients per SSID and building, unknown MAC vendors on staff VLANs, APs with high retry rates, and devices seen on more than 3 buildings in a day, exported as CSV for the asset and security reviews.
TECH_STACK: jq 1.7 filter modules (OUI vendor table via --slurpfile, per-site merge) + bash wrapper with controller API session handling + bats fixture tests
APP_TYPE: CLI
LANGUAGE: jq
SCALE: 14 school sites, ~11k client devices / 380 APs per sweep, daily run of ~90 MB JSON
```

## 92. sbomroll — software bill-of-materials rollup

```text
APP_DESCRIPTION: A CLI tool for a compliance engineer that rolls CycloneDX SBOM JSON files from all shipped products into one component ledger: component frequency across products, license distribution with copyleft flags, components lacking supplier data, and which products embed a given CVE-affected component.
TECH_STACK: jq 1.7 filter modules (purl-keyed merge across SBOM directory) + bash wrapper + jq --run-tests fixtures with multi-format component entries
APP_TYPE: CLI
LANGUAGE: jq
SCALE: 26 products, SBOMs totaling ~450 MB, ~38k unique components, monthly rollup plus per-CVE ad-hoc queries
```

## 93. flagsweep — feature flag debt auditor

```text
APP_DESCRIPTION: A CLI tool for a release engineering team that audits LaunchDarkly API flag JSON: flags fully rolled out for 90+ days that should be removed, flags with no evaluations in 30 days, temporary flags past their planned removal date, and per-team flag debt counts for the cleanup rotation.
TECH_STACK: jq 1.7 filter modules (flag status + evaluation stats join) + bash wrapper paginating the LaunchDarkly REST API + jq --run-tests fixtures
APP_TYPE: CLI
LANGUAGE: jq
SCALE: ~940 flags across 12 projects, biweekly audit, ~30 MB JSON per run, ~25 removal candidates per cycle
```

## 94. incidentroll — status page history reporter

```text
APP_DESCRIPTION: A CLI tool for a customer-success director that compiles Statuspage API incident JSON into the quarterly reliability report: incidents by component and impact level, mean time to resolution per severity, maintenance vs unplanned ratio, and month-over-month uptime table per product line.
TECH_STACK: jq 1.7 filter modules (incident timeline math from status transitions) + bash wrapper over the Statuspage REST API + bats fixture tests
APP_TYPE: CLI
LANGUAGE: jq
SCALE: 3 status pages / 28 components, ~140 incidents/quarter analyzed, quarterly runs of ~10 MB JSON
```

## 95. falcofold — runtime alert triage pipeline

```text
APP_DESCRIPTION: A data pipeline for a container security team's defensive review that folds Falco NDJSON events into triage bundles: groups events by rule and workload, suppresses known-benign patterns from an allowlist, escalates never-before-seen rule+image combinations, and emits a prioritized NDJSON queue for analyst review.
TECH_STACK: jq 1.7 streaming filter modules (allowlist via --slurpfile, first-seen ledger) + bash wrapper on the Falco file output + jq --run-tests fixtures per rule family, 10-minute cron
APP_TYPE: data pipeline
LANGUAGE: jq
SCALE: ~800k events/day folding to ~90 review items, 6 clusters, 144 runs/day, 3 analysts
```

## 96. evesift — IDS alert digest pipeline

```text
APP_DESCRIPTION: A data pipeline for a university SOC's defensive monitoring that digests Suricata eve.json: alert counts by signature and internal subnet, top talkers per alert category, TLS connections with anomaly flags, and new signatures firing for the first time, delivered as an hourly summary to the SOC dashboard drop folder.
TECH_STACK: jq 1.7 streaming filter modules (event_type routing, subnet tagging via --slurpfile) + bash wrapper over rotated eve.json files + jq --run-tests fixtures, hourly cron
APP_TYPE: data pipeline
LANGUAGE: jq
SCALE: ~35M events/day (~18 GB NDJSON), 24 runs/day, 5 SOC analysts, 2,400 active signatures
```

## 97. zeekconn — network flow summarizer

```text
APP_DESCRIPTION: A CLI tool for an incident responder's defensive investigation that summarizes Zeek conn.log JSON for a time window: top talker pairs by bytes, long-lived connections to external hosts, rare destination ports from server subnets, and beacon-like connection intervals, printed as the investigation worksheet.
TECH_STACK: jq 1.7 streaming filter modules (interval regularity scoring, subnet classification) + bash wrapper over compressed Zeek JSON logs + bats fixture tests
APP_TYPE: CLI
LANGUAGE: jq
SCALE: ~50M conn records/day available (~20 GB), typical investigation window 2–24 hours, 4 responders
```

## 98. quakefeed — seismic event digest pipeline

```text
APP_DESCRIPTION: A data pipeline for a public-broadcaster newsroom that digests the USGS earthquake GeoJSON feed: events above magnitude thresholds by region, felt-report counts, tsunami-flag events, and a deduplicated update stream when magnitudes are revised, formatted as ready-to-publish alert snippets.
TECH_STACK: jq 1.7 filter modules (event revision dedup by id, region polygon lookup table) + bash wrapper polling the feed with curl + jq --run-tests fixtures, 5-minute cron
APP_TYPE: data pipeline
LANGUAGE: jq
SCALE: ~400 feed events/day, 288 polls/day (~150 MB JSON/day), 2 newsroom editors, alerts within 5 minutes of feed update
```

## 99. edgarfacts — company financials extractor

```text
APP_DESCRIPTION: A CLI tool for a buy-side research analyst that extracts standardized metrics from SEC EDGAR companyfacts JSON: revenue, net income, and share counts per fiscal period with their exact XBRL tags and filing references, aligned across a ticker watchlist into one comparison CSV.
TECH_STACK: jq 1.7 filter modules (us-gaap tag ladder with fallbacks, period alignment) + bash wrapper fetching companyfacts per CIK with rate limiting + jq --run-tests fixtures
APP_TYPE: CLI
LANGUAGE: jq
SCALE: 85-ticker watchlist, companyfacts files 2–25 MB each (~800 MB per full run), quarterly refresh plus ~20 ad-hoc pulls/week
```

## 100. socrataport — open data extract builder

```text
APP_DESCRIPTION: A CLI tool for a data journalism team that builds story-ready extracts from city open-data portal JSON (Socrata SODA API): filters records by date and district, normalizes agency-specific field names across dataset vintages, joins code tables for human-readable categories, and writes analysis-ready CSVs.
TECH_STACK: jq 1.7 filter modules (vintage field-map via --slurpfile, @csv output) + bash wrapper paginating SODA endpoints with curl + bats tests with dataset fixtures
APP_TYPE: CLI
LANGUAGE: jq
SCALE: ~15 datasets/month pulled, 10k–2M rows per dataset (up to 3 GB JSON), 5 journalists
```
