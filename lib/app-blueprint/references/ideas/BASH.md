# Bash Blueprint Types — Copy-Paste Input Sets

Copy a fenced block into the prompt as-is, or swap individual fields.

## 1. logreaper — web log rotation and digest

```text
APP_DESCRIPTION: A cron-driven pipeline for a shared-hosting provider that rotates nginx access logs across customer vhosts, compresses and ships them to archive storage, and emits a nightly per-vhost traffic and error-rate digest for the support team.
TECH_STACK: bash + coreutils + logrotate + gzip + awk + rsync + cron, deployed via internal apt package to all web nodes
APP_TYPE: data pipeline
LANGUAGE: Bash
SCALE: 220 web nodes, ~18,000 vhosts, ~60 GB logs/day, nightly run within 90 minutes
```

## 2. certherd — TLS renewal fleet orchestrator

```text
APP_DESCRIPTION: A CLI for a managed-services provider that orchestrates Let's Encrypt renewals across client servers. It inventories certs over SSH, renews those inside the expiry window, reloads the right service per host (nginx, apache, haproxy), and writes a renewal ledger with failures flagged for the on-call engineer.
TECH_STACK: bash + certbot + openssl + ssh + jq ledger file + cron, distributed as a git repo cloned to the ops bastion
APP_TYPE: CLI
LANGUAGE: Bash
SCALE: 3 operators, 340 client hosts, ~900 certificates, daily run
```

## 3. dumpsafe — PostgreSQL dump and restore wrapper

```text
APP_DESCRIPTION: A CLI for a web development agency that wraps pg_dump/pg_restore with sane defaults: per-database compressed dumps, checksum verification, retention pruning, and a guided restore mode that refuses to overwrite a live database without an explicit flag.
TECH_STACK: bash + pg_dump/pg_restore + zstd + sha256sum + getopts, single script installed to /usr/local/bin on the db hosts
APP_TYPE: CLI
LANGUAGE: Bash
SCALE: 6 developers, 45 client databases, largest 80 GB, nightly dumps plus ad-hoc restores
```

## 4. snapcull — ZFS snapshot pruning janitor

```text
APP_DESCRIPTION: A cron CLI for a home-lab NAS that creates rolling ZFS snapshots and prunes them on a grandfather-father-son schedule, keeping hourly/daily/monthly tiers per dataset and refusing to prune below a configurable floor when the pool is healthy.
TECH_STACK: bash + zfs CLI + date arithmetic + flock + cron, single script in a dotfiles-style git repo
APP_TYPE: CLI
LANGUAGE: Bash
SCALE: 1 operator, 14 datasets, 48 TB pool, hourly snapshots, ~600 snapshots under management
```

## 5. rackseed — bare-metal provisioning bootstrap

```text
APP_DESCRIPTION: A first-boot provisioning script for a colocation data center that turns a freshly imaged Debian box into a rentable node: sets hostname and networking from an inventory file, creates admin users, applies the baseline package set and sysctl profile, and registers the host with monitoring.
TECH_STACK: bash + debconf + systemd-networkd + curl (inventory API) + useradd, served over PXE post-install hook
APP_TYPE: CLI
LANGUAGE: Bash
SCALE: 5 technicians, ~30 servers provisioned/week, 1,100-host fleet
```

## 6. cronminder — cron heartbeat monitor

```text
APP_DESCRIPTION: A monitoring pipeline for a SaaS startup that watches whether scheduled jobs actually ran. Jobs touch heartbeat files or curl a local endpoint; cronminder sweeps every five minutes, compares against an expected-schedule manifest, and alerts Slack on missed or overlong runs.
TECH_STACK: bash + find + jq manifest + curl (Slack webhook) + systemd timer, deployed by Ansible to all app hosts
APP_TYPE: data pipeline
LANGUAGE: Bash
SCALE: 40 hosts, 260 monitored jobs, 5-minute sweep interval, ~75,000 checks/day
```

## 7. transcodetide — broadcast batch transcoder

```text
APP_DESCRIPTION: A watch-folder pipeline for a regional TV station that transcodes incoming field footage into edit-ready and playout formats. It picks up files from ingest shares, runs parallel ffmpeg jobs with per-format profiles, verifies output duration against source, and files results into the MAM folder tree.
TECH_STACK: bash + ffmpeg + ffprobe + GNU parallel + inotifywait + NFS shares, installed as a systemd service on 2 ingest nodes
APP_TYPE: data pipeline
LANGUAGE: Bash
SCALE: ~180 clips/day, 400 GB/day throughput, 2 nodes x 32 cores, 24/7 operation
```

## 8. thumbmill — studio thumbnail batcher

```text
APP_DESCRIPTION: A CLI for a portrait photography studio that generates client-proof derivatives from RAW shoot folders: contact-sheet JPEGs, watermarked web previews, and print-size crops, preserving the shoot's folder structure and skipping already-rendered files on re-runs.
TECH_STACK: bash + ImageMagick + exiftool + dcraw + GNU parallel, Homebrew-tap formula for the studio's Macs
APP_TYPE: CLI
LANGUAGE: Bash
SCALE: 2 editors, ~25 shoots/week, 800-1,500 RAW frames per shoot, ~120 GB/week
```

## 9. hookwarden — git hook policy pack

```text
APP_DESCRIPTION: A git hook suite for a software consultancy that enforces repo hygiene before commits leave a laptop: blocks committed credentials and .env files, lints commit message format, runs the project's formatter on staged files only, and rejects direct commits to protected branches.
TECH_STACK: bash + git + grep/sed + optional ripgrep + per-repo config file, installed via a bootstrap script into .git/hooks
APP_TYPE: CLI
LANGUAGE: Bash
SCALE: 35 developers, ~90 active repos, ~400 commits/day passing through hooks
```

## 10. dockmop — CI runner docker janitor

```text
APP_DESCRIPTION: A cleanup CLI for a build-farm team that keeps CI runners from filling up: prunes exited containers, dangling images, and stale build cache by age, but protects images matching a keep-list of base images and anything used in the last N hours.
TECH_STACK: bash + docker CLI + jq (docker inspect output) + systemd timer, baked into the runner AMI
APP_TYPE: CLI
LANGUAGE: Bash
SCALE: 60 CI runners, ~2,400 builds/day, reclaims ~40 GB/runner/week, hourly runs
```

## 11. podnudge — kubernetes rollout helper

```text
APP_DESCRIPTION: An ops CLI for an e-commerce platform team that wraps common kubectl surgery: safe rolling restarts of a deployment with readiness gating, draining a node with progress output, and a "what changed" diff of a deployment's image tags across namespaces.
TECH_STACK: bash + kubectl + jq + fzf for interactive selection, distributed via internal Homebrew tap and apt repo
APP_TYPE: CLI
LANGUAGE: Bash
SCALE: 18 SREs, 4 clusters, ~900 pods, ~50 invocations/day
```

## 12. mirrorbarn — campus package mirror sync

```text
APP_DESCRIPTION: A nightly pipeline for a university IT department that maintains local Debian, Ubuntu, and Rocky mirrors plus a PyPI cache so lab machines install packages without touching the WAN. It syncs upstreams, validates repo metadata, flips a symlink to the new snapshot atomically, and prunes old snapshots.
TECH_STACK: bash + rsync + debmirror + reposync + hardlink snapshots + cron, runs on a dedicated mirror server
APP_TYPE: data pipeline
LANGUAGE: Bash
SCALE: 4 distros mirrored, 6 TB mirror set, ~30 GB delta/night, serves 2,800 lab machines
```

## 13. hireup — district account onboarding

```text
APP_DESCRIPTION: A CLI for a school district's IT office that provisions accounts for incoming staff from an HR CSV: creates Linux and LDAP accounts, sets group memberships by role and campus, generates a welcome sheet with initial credentials, and produces a reversal script for each batch.
TECH_STACK: bash + ldapadd/ldapmodify + useradd + awk CSV parsing + pwgen, run from the admin jump host
APP_TYPE: CLI
LANGUAGE: Bash
SCALE: 2 admins, ~350 accounts/summer batch, ~20/week during term, 4,000 total accounts
```

## 14. dotgrove — dotfile manager

```text
APP_DESCRIPTION: A dotfile manager for developers that symlinks configuration from a versioned repo into $HOME, supports per-machine overlays (work laptop vs home desktop), backs up any file it would clobber, and bootstraps a new machine with one curl-pipe installer.
TECH_STACK: bash + GNU stow-style symlinking (hand-rolled) + git + curl installer, published as a GitHub repo
APP_TYPE: CLI
LANGUAGE: Bash
SCALE: 1 primary user, 3 machines, ~70 managed files, community of ~200 GitHub stars
```

## 15. diskreaper — render farm scratch janitor

```text
APP_DESCRIPTION: A cron CLI for a 3D render farm that keeps node scratch disks alive: deletes finished-job temp directories past their retention, warns artists by email when their scratch usage crosses quota, and hard-stops only with a signed-off deny-list, never by blind age alone.
TECH_STACK: bash + find + du + quota parsing + sendmail + flock + cron, pushed by Ansible to all render nodes
APP_TYPE: CLI
LANGUAGE: Bash
SCALE: 85 render nodes, 2 TB scratch each, ~500 GB reclaimed/day, hourly sweeps
```

## 16. keysentry — SSH key estate auditor

```text
APP_DESCRIPTION: A defensive audit CLI for a payments company's security team that sweeps servers for authorized_keys entries, correlates them against the HR roster and an approved-keys inventory, flags orphaned or shared keys, and emits a signed CSV evidence report for compliance reviews.
TECH_STACK: bash + ssh + awk + sort/comm + gpg --sign for reports + read-only service account, run monthly from a hardened bastion
APP_TYPE: CLI
LANGUAGE: Bash
SCALE: 2 security engineers, 520 hosts, ~1,900 key entries audited/run, monthly cadence
```

## 17. shelfsync — retail product feed loader

```text
APP_DESCRIPTION: An ETL pipeline for a regional grocery chain that loads supplier product feeds into the pricing database. It fetches CSV/TSV feeds from supplier SFTP drops, normalizes encodings and units, validates against category rules, loads staged rows via mysql LOAD DATA, and quarantines rejects with reasons.
TECH_STACK: bash + sftp/lftp + iconv + awk + mysql client + cron, runs on the integration server
APP_TYPE: data pipeline
LANGUAGE: Bash
SCALE: 38 supplier feeds, ~180,000 rows/night, 45-minute batch window, 96 stores served
```

## 18. rsynchrone — lab data backup rotator

```text
APP_DESCRIPTION: A backup CLI for a microscopy lab that pulls instrument-PC data to the lab NAS with rsync hardlink rotation, keeping 14 dailies and 12 monthlies per instrument, verifying transfer counts against the source, and emailing the lab manager a one-page status each morning.
TECH_STACK: bash + rsync --link-dest + ssh + df/find + msmtp + cron, single script on the NAS with per-instrument config files
APP_TYPE: CLI
LANGUAGE: Bash
SCALE: 9 instrument PCs, ~200 GB new data/week, 26 retained generations each, nightly runs
```

## 19. renamewave — digitization batch renamer

```text
APP_DESCRIPTION: A CLI for a museum digitization team that renames scanner output into the catalog convention: maps ad-hoc filenames to accession numbers from a mapping CSV, zero-pads sequence numbers, embeds the accession into EXIF, always dry-runs first, and writes an undo script per batch.
TECH_STACK: bash + mv with manifest-driven loops + exiftool + awk + sha1sum manifests, run on the digitization workstation
APP_TYPE: CLI
LANGUAGE: Bash
SCALE: 3 technicians, ~4,000 images/week renamed, batches of 200-800 files
```

## 20. pingledger — uptime check and status writer

```text
APP_DESCRIPTION: A monitoring pipeline for a nonprofit's volunteer sysadmin that probes its public sites and mail server every two minutes, records response codes and latency to a flat-file ledger, flips a static status page on failures, and texts the on-call volunteer via an SMS gateway after three consecutive misses.
TECH_STACK: bash + curl + dig + awk ledger + static HTML rewrite + SMS gateway API + systemd timer, runs on a $5 VPS
APP_TYPE: data pipeline
LANGUAGE: Bash
SCALE: 12 endpoints, 2-minute interval, ~8,600 probes/day, 1 operator
```

## 21. vaultspool — law firm dump encryptor

```text
APP_DESCRIPTION: A nightly pipeline for a law firm that dumps the document-management MySQL database, encrypts the archive to the firm's offline-held public key, ships it to two offsite locations, and proves restorability by test-restoring into a throwaway container every Sunday.
TECH_STACK: bash + mysqldump + age encryption + rclone (S3 + SFTP offsite) + docker CLI for test restores + cron
APP_TYPE: data pipeline
LANGUAGE: Bash
SCALE: 1 database, 140 GB dump, 2 offsite targets, nightly with weekly restore drill
```

## 22. kernelherd — ISP patch-and-reboot orchestrator

```text
APP_DESCRIPTION: A CLI for a regional ISP's ops team that walks server groups through kernel updates in waves: checks pending updates per host, drains traffic where a drain hook exists, patches and reboots one wave at a time, and halts the run if any host fails to come back within its window.
TECH_STACK: bash + ssh + apt/dnf + wave definitions in a TSV inventory + nc port checks, run from the NOC jump box
APP_TYPE: CLI
LANGUAGE: Bash
SCALE: 4 operators, 260 hosts in 12 waves, monthly patch cycle, 15-minute reboot SLA per host
```

## 23. tapewrangle — LTO archive wrapper

```text
APP_DESCRIPTION: A CLI for a television archive that drives LTO tape backups of finished programs: builds tar spans sized to tape capacity, writes and verifies each span with read-back checksums, prints barcode labels, and appends every tape's contents to a searchable flat-file catalog.
TECH_STACK: bash + tar + mt/mtx changer control + sha256sum + lp label printing + a TSV catalog, runs on the archive workstation
APP_TYPE: CLI
LANGUAGE: Bash
SCALE: 2 archivists, ~6 TB written/week, LTO-9 tapes, catalog of 14,000 tapes
```

## 24. isofetch — distro image mirror fetcher

```text
APP_DESCRIPTION: A CLI for a university computer club that keeps a shelf of installer images fresh: downloads the latest ISOs for a configured list of Linux distros, verifies GPG signatures and checksums, retires superseded versions, and regenerates the club mirror's index page.
TECH_STACK: bash + curl/wget + gpg + sha256sum + jq for release APIs + cron, hosted on the club server
APP_TYPE: CLI
LANGUAGE: Bash
SCALE: 15 tracked distros, ~80 GB mirror, weekly refresh, ~300 student downloads/month
```

## 25. gradegate — assignment CI harness

```text
APP_DESCRIPTION: A pipeline for a CS department that autogrades programming submissions: unpacks each student tarball into a locked-down container, builds it, runs the instructor's test suite with CPU and time limits, and writes per-student score sheets plus a class summary CSV for the LMS.
TECH_STACK: bash + docker CLI + timeout + make + diff-based test comparison + cron pickup from the submission share
APP_TYPE: data pipeline
LANGUAGE: Bash
SCALE: 4 courses, ~600 students, ~1,800 submissions/deadline day, 90-second limit per run
```

## 26. deploycrate — blue-green deploy script

```text
APP_DESCRIPTION: A deployment CLI for a hosting shop's in-house PHP application that performs releases without downtime: builds a timestamped release directory, runs migrations against a guard check, warms the cache, flips the current symlink, health-checks, and rolls back the symlink automatically on a failed check.
TECH_STACK: bash + git + composer + rsync to app nodes + curl health checks + symlink release layout, triggered by CI over ssh
APP_TYPE: CLI
LANGUAGE: Bash
SCALE: 8 developers, 3 app nodes, ~25 deploys/week, 5 retained releases per node
```

## 27. cronlock — overlap-safe job wrapper

```text
APP_DESCRIPTION: A tiny wrapper CLI used across an ad agency's servers that makes any cron job safe to schedule aggressively: takes an exclusive lock per job name, logs start/end and exit codes to a common ledger, kills jobs that exceed their declared max runtime, and reports chronic overrunners weekly.
TECH_STACK: bash + flock + logger/syslog + awk weekly report + cron, distributed as one file via configuration management
APP_TYPE: CLI
LANGUAGE: Bash
SCALE: 28 servers, ~140 wrapped jobs, ~3,000 executions/day
```

## 28. wavachop — podcast audio normalizer

```text
APP_DESCRIPTION: A CLI for a podcast network's producers that batch-processes raw episode audio: loudness-normalizes to -16 LUFS, trims leading/trailing silence, converts to distribution MP3 and AAC with embedded chapter and artwork tags, and names outputs by show/episode convention.
TECH_STACK: bash + ffmpeg loudnorm + sox silence trim + id3v2 tagging + GNU parallel, distributed as a Homebrew tap
APP_TYPE: CLI
LANGUAGE: Bash
SCALE: 5 producers, 22 shows, ~40 episodes/week, ~60-90 minutes audio each
```

## 29. framegrab — preview sprite generator

```text
APP_DESCRIPTION: A pipeline for a video course platform's ops team that generates seek-preview assets for uploaded lessons: extracts thumbnails every 5 seconds, tiles them into sprite sheets, writes the matching WebVTT map, and uploads the set alongside the video rendition folder.
TECH_STACK: bash + ffmpeg + ImageMagick montage + awk VTT writer + aws s3 cp + queue directory watched by a systemd path unit
APP_TYPE: data pipeline
LANGUAGE: Bash
SCALE: ~120 new videos/day, average 18 minutes each, sprite set ~2 MB per video
```

## 30. geodrip — survey tile mirror

```text
APP_DESCRIPTION: A pipeline for a land-surveying firm that mirrors public GIS datasets used by field crews: downloads county parcel shapefiles, LiDAR tiles, and orthoimagery on their agency release schedules, converts to the firm's working formats, and stages them onto the field-tablet sync share.
TECH_STACK: bash + curl + gdal_translate/ogr2ogr + unzip + rsync to the sync share + cron per-source schedules
APP_TYPE: data pipeline
LANGUAGE: Bash
SCALE: 11 upstream sources, ~90 GB refreshed/month, 14 field tablets synced
```

## 31. sensorspool — weather station logger

```text
APP_DESCRIPTION: A collection pipeline for a volunteer-run weather station that reads the console's serial feed, appends validated observations to daily CSV files, computes hourly aggregates, pushes to two citizen-weather networks, and gap-fills from the console's internal memory after outages.
TECH_STACK: bash + socat serial capture + awk validation/aggregation + curl uploads + systemd service and timers, on a Raspberry Pi
APP_TYPE: data pipeline
LANGUAGE: Bash
SCALE: 1 station, observation every 10 seconds, ~8,600 rows/day, 2 upstream networks
```

## 32. scopewash — observatory calibration batch

```text
APP_DESCRIPTION: A CLI for a university observatory that preprocesses each night's telescope images: applies dark/flat/bias calibration frames with the right exposure matching, sorts frames by target into the archive layout, flags saturated or trailed frames, and writes a night log for the astronomer.
TECH_STACK: bash + siril-cli for calibration + exiftool/FITS header tools + find + cron at dawn, runs on the dome control machine
APP_TYPE: data pipeline
LANGUAGE: Bash
SCALE: ~450 frames/clear night, 30 MB/frame, ~120 observing nights/year
```

## 33. seqferry — sequencer run offloader

```text
APP_DESCRIPTION: A transfer pipeline for a genomics core facility that moves completed sequencing runs from instrument workstations to cluster storage: detects run-complete sentinel files, copies with checksum verification, validates the run folder structure, notifies the queue that analysis can start, and frees instrument disk only after verification.
TECH_STACK: bash + rsync + md5sum manifests + inotifywait sentinel watch + ssh to cluster + Slack webhook, on each instrument PC
APP_TYPE: data pipeline
LANGUAGE: Bash
SCALE: 4 sequencers, ~3 runs/week each, 300-900 GB per run, verified within 4 hours of completion
```

## 34. bastionize — server hardening baseline

```text
APP_DESCRIPTION: A defensive hardening CLI a security consultancy runs on client Ubuntu servers: applies an agreed CIS-derived baseline (SSH config, auditd rules, sysctl, firewall defaults, password policy), records every change it makes, and produces a before/after compliance report — with a check-only mode for audits.
TECH_STACK: bash + sshd_config/sysctl editing with backups + ufw + auditd + a TSV rule catalog + diff reports, delivered as a signed tarball
APP_TYPE: CLI
LANGUAGE: Bash
SCALE: 6 consultants, ~40 client engagements/year, 5-50 servers per engagement, 120 checks per run
```

## 35. auditcomb — auth log intrusion digest

```text
APP_DESCRIPTION: A defensive log-review pipeline for a city government's IT office that parses auth and sudo logs across servers each night, clusters failed-login sources, flags first-seen admin logins and off-hours sudo use, and mails a ranked review sheet to the security officer.
TECH_STACK: bash + journalctl/auth.log parsing with awk + sort/uniq clustering + GeoIP lookup via mmdblookup + msmtp + cron
APP_TYPE: data pipeline
LANGUAGE: Bash
SCALE: 75 servers, ~2.5M auth events/day, nightly digest by 06:00, 1 reviewer
```

## 36. expirescan — certificate expiry sweeper

```text
APP_DESCRIPTION: A CLI for an enterprise infrastructure team that inventories TLS certificate expiry across everything: probes a host list's ports, checks local cert files on servers over SSH, merges findings into one expiry table, and opens tickets for anything inside 30 days via the ticketing API.
TECH_STACK: bash + openssl s_client + ssh + awk table merge + curl (ticket API) + jq + weekly systemd timer on the tools host
APP_TYPE: CLI
LANGUAGE: Bash
SCALE: 3 operators, 1,400 endpoints probed, ~2,100 certs tracked, weekly sweep in under 20 minutes
```

## 37. zoneherd — DNS zone deploy gatekeeper

```text
APP_DESCRIPTION: A CLI for a small DNS hosting provider that gates zone file changes: validates edited zones with named-checkzone, diffs against production, enforces serial bumps, pushes to the hidden primary, verifies propagation on all secondaries, and can roll back to the previous zone in one command.
TECH_STACK: bash + named-checkzone + git-versioned zones + rndc + dig verification loops + ssh, run from the zone-editing jump host
APP_TYPE: CLI
LANGUAGE: Bash
SCALE: 4 operators, ~5,200 zones, ~60 zone changes/day, 5 secondary servers
```

## 38. cachescrub — CDN purge helper

```text
APP_DESCRIPTION: A CLI for a news site's ops team that makes CDN purges safe and auditable: accepts URL lists or path patterns, previews what will be purged, batches purge API calls under the provider's rate limits, confirms cache status afterward with header probes, and logs who purged what.
TECH_STACK: bash + curl (CDN API + verification probes) + jq + xargs batching + an append-only audit log, in the ops toolbox repo
APP_TYPE: CLI
LANGUAGE: Bash
SCALE: 10 editors/ops users, ~30 purge operations/day, up to 5,000 URLs per operation
```

## 39. spoolsweep — mail queue janitor

```text
APP_DESCRIPTION: A CLI for an email hosting company's postmasters that manages stuck Postfix queues: summarizes queue contents by sender domain and error, quarantines obvious spam bursts to a hold queue, retries deferred mail for named domains, and expires undeliverables past policy with a per-message log.
TECH_STACK: bash + postqueue/postsuper/postcat + awk summaries + grep classification rules + cron for sweeps, on each MTA
APP_TYPE: CLI
LANGUAGE: Bash
SCALE: 6 MTAs, ~400,000 messages/day relayed, queue spikes to 80,000 messages handled
```

## 40. mboxferry — mailbox migration wrapper

```text
APP_DESCRIPTION: A CLI for an email migration agency that wraps imapsync for client cutovers: reads a batch CSV of source/destination accounts, runs migrations in parallel with per-account logs, retries transient failures, computes per-mailbox verification counts, and produces the client's completion report.
TECH_STACK: bash + imapsync + GNU parallel + awk CSV handling + column report formatting, run from the migration workhorse VM
APP_TYPE: CLI
LANGUAGE: Bash
SCALE: 3 engineers, batches of 50-2,000 mailboxes, largest mailbox 40 GB, ~15 cutovers/month
```

## 41. sitesnap — agency site backup tool

```text
APP_DESCRIPTION: A CLI for a WordPress agency that snapshots any client site in one command: dumps the database, archives uploads and theme code, records plugin versions, encrypts the bundle, uploads to per-client storage, and verifies each bundle can be listed and its checksums match before rotating old ones.
TECH_STACK: bash + wp-cli + mysqldump + tar/zstd + age encryption + rclone (B2) + cron for the nightly all-sites run
APP_TYPE: CLI
LANGUAGE: Bash
SCALE: 4 operators, 130 client sites, ~350 GB total backup set, nightly plus pre-deploy snapshots
```

## 42. stagesync — sanitized staging refresher

```text
APP_DESCRIPTION: A pipeline for a B2B SaaS team that refreshes staging from production weekly: snapshots the production database, scrubs PII with a column-level sanitization map (emails, names, tokens), loads the scrubbed copy into staging, refreshes fixture S3 objects, and refuses to run if the sanitization map doesn't cover new columns.
TECH_STACK: bash + pg_dump/psql + sed/awk driven by a sanitization map file + aws s3 sync + schema-coverage check + cron
APP_TYPE: data pipeline
LANGUAGE: Bash
SCALE: 1 production db of 220 GB, weekly refresh in a 3-hour window, 14 developers served
```

## 43. artifactusher — build promotion gate

```text
APP_DESCRIPTION: A CI helper CLI for a game studio's build team that promotes nightly builds through channels: verifies the candidate's test-pass manifest, copies the artifact set from the nightly bucket to qa/beta/release paths with checksums, updates the launcher's channel manifest, and tags the exact commit in git.
TECH_STACK: bash + aws s3 cp + sha256sum + jq manifest edits + git tag + invoked as a CI job step and manually for releases
APP_TYPE: CLI
LANGUAGE: Bash
SCALE: 3 build engineers, ~8 GB artifact set, ~30 promotions/month across 3 channels
```

## 44. worldkeeper — game server backup and restart

```text
APP_DESCRIPTION: A CLI for a community Minecraft host that manages world data safety across tenant servers: announces restarts in-game, flushes and pauses world saves, snapshots world folders with rotation, restarts crashed instances with backoff, and lets an operator roll a single world back to any retained snapshot.
TECH_STACK: bash + screen/tmux server consoles + rcon-cli + tar snapshots + systemd units per server + cron rotation
APP_TYPE: CLI
LANGUAGE: Bash
SCALE: 40 tenant servers, ~25 GB world data total, 4-hourly snapshots, 21 retained generations
```

## 45. matchspool — esports demo organizer

```text
APP_DESCRIPTION: A CLI for an esports team's analysts that organizes scrim and match recordings: pulls demo files from team servers, names them by date/opponent/map from the server logs, deduplicates by hash, indexes them in a searchable TSV, and prunes practice demos past 90 days while keeping all official matches.
TECH_STACK: bash + scp/rsync pulls + sha1sum dedupe + awk log parsing + TSV index + weekly cron prune
APP_TYPE: CLI
LANGUAGE: Bash
SCALE: 2 analysts, ~120 demos/week, 300 MB average demo, 1.8 TB archive
```

## 46. pdfstitch — print shop imposition batcher

```text
APP_DESCRIPTION: A CLI for a commercial print shop's prepress desk that batch-prepares customer PDFs: normalizes page sizes, imposes booklet and n-up layouts per job ticket, adds crop marks, flattens transparency, and drops print-ready files into the RIP hot folder with the job number embedded.
TECH_STACK: bash + ghostscript + pdftk/qpdf + podofo tools + job-ticket TSV parsing, on the prepress Linux workstation
APP_TYPE: CLI
LANGUAGE: Bash
SCALE: 2 prepress operators, ~70 jobs/day, 4-600 pages per job
```

## 47. scanshuttle — accounting OCR intake

```text
APP_DESCRIPTION: A pipeline for an accounting firm that processes the office scanner's output tray: OCRs each PDF, extracts client and document-type hints from the text, files documents into the correct client/year folder, names them by convention, and routes anything ambiguous to a human-review folder.
TECH_STACK: bash + ocrmypdf/tesseract + pdftotext + grep classification rules + inotifywait on the scan share + samba shares
APP_TYPE: data pipeline
LANGUAGE: Bash
SCALE: ~250 documents/day, 900 client folders, 92% auto-filed, review queue under 20 docs/day
```

## 48. ledgerpull — plain-text bookkeeping importer

```text
APP_DESCRIPTION: A CLI for a bookkeeping cooperative that keeps client books in hledger: fetches bank and card CSV exports from a drop folder, normalizes each institution's format via per-bank rules files, deduplicates against existing journal entries, and appends categorized transactions for the bookkeeper to review.
TECH_STACK: bash + hledger + awk/sed per-bank normalizers + sort/comm dedupe + git-versioned journals, run weekly per client
APP_TYPE: CLI
LANGUAGE: Bash
SCALE: 3 bookkeepers, 55 client ledgers, ~6,000 transactions/month imported
```

## 49. invoicebale — freelancer document filer

```text
APP_DESCRIPTION: A CLI for a freelancers' cooperative that keeps member paperwork orderly: sweeps a shared inbox folder for invoices and receipts, reads dates and amounts from the PDF text, files documents into member/year/quarter trees, and emits a quarterly totals CSV that members hand to their tax preparers.
TECH_STACK: bash + pdftotext + grep/awk extraction + date parsing + rsync to the archive share + monthly cron
APP_TYPE: CLI
LANGUAGE: Bash
SCALE: 30 members, ~700 documents/quarter, 6-year retention tree of ~17,000 files
```

## 50. foliofetch — hotel night-audit exporter

```text
APP_DESCRIPTION: A pipeline for an independent hotel group that collects each property's nightly PMS export: pulls folio and occupancy reports over SFTP after night audit, validates record counts against control totals, converts to the accounting system's import format, and loads them so the controller sees consolidated numbers by 07:00.
TECH_STACK: bash + lftp + dos2unix/iconv + awk transforms + control-total checks + accounting system CLI import + cron
APP_TYPE: data pipeline
LANGUAGE: Bash
SCALE: 7 properties, ~1,200 folio records/night, complete by 07:00 daily
```

## 51. signloop — restaurant signage sync

```text
APP_DESCRIPTION: A CLI that keeps menu screens current for a fast-casual restaurant chain: each screen's Pi pulls the latest approved content bundle for its store and daypart, verifies the bundle signature, swaps content atomically, falls back to the last good bundle on failure, and phones home its playback health.
TECH_STACK: bash + curl bundle fetch + minisign verification + feh/mpv display control + systemd timers + health beacon POST, on Raspberry Pis
APP_TYPE: CLI
LANGUAGE: Bash
SCALE: 64 stores, 190 screens, 15-minute sync interval, ~40 MB bundle per daypart
```

## 52. tillsweep — POS end-of-day consolidator

```text
APP_DESCRIPTION: A pipeline for a craft brewery's taprooms that consolidates each location's point-of-sale close-out: fetches Z-report exports, reconciles card-settlement totals against POS totals, flags variances over threshold for the manager, and appends the day's numbers to the sales warehouse CSV set.
TECH_STACK: bash + curl (POS export API) + jq + awk reconciliation + msmtp variance alerts + nightly cron on the office server
APP_TYPE: data pipeline
LANGUAGE: Bash
SCALE: 5 taprooms, ~2,800 transactions/day, nightly close by 03:00, variance threshold $25
```

## 53. barrelwatch — fermentation log rollup

```text
APP_DESCRIPTION: A pipeline for a winery that rolls up fermentation telemetry: collects temperature and gravity readings from tank controllers' network shares, validates ranges per varietal profile, appends to per-tank history files, and alerts the winemaker's phone when a tank drifts outside its fermentation curve.
TECH_STACK: bash + smbclient pulls + awk range checks against profile files + gnuplot daily charts + ntfy push alerts + 15-minute cron
APP_TYPE: data pipeline
LANGUAGE: Bash
SCALE: 28 tanks, readings every 15 minutes, ~2,700 readings/day, harvest season 24/7
```

## 54. coopwatch — poultry barn sentinel

```text
APP_DESCRIPTION: A monitoring CLI for a family egg farm that watches barn conditions: polls temperature/humidity sensors and the backup-generator status, logs readings locally with rotation, sounds the barn klaxon relay and texts the farmer on threshold breaches, and keeps working with no internet by queuing alerts.
TECH_STACK: bash + curl to sensor HTTP endpoints + gpioset relay control + awk thresholds + SMS gateway with offline queue + systemd timer, on a barn Pi
APP_TYPE: CLI
LANGUAGE: Bash
SCALE: 3 barns, 14 sensors, 60-second poll cycle, 12,000 birds protected
```

## 55. solarskim — inverter fleet harvester

```text
APP_DESCRIPTION: A pipeline for a residential solar installer that harvests production data from customer inverters: polls each supported vendor's local or cloud API on schedule, normalizes to a common per-site CSV schema, detects sites reporting zero production on sunny days, and feeds the monthly customer production reports.
TECH_STACK: bash + curl per-vendor API adapters + jq normalization + awk anomaly rules + rclone to report storage + hourly cron
APP_TYPE: data pipeline
LANGUAGE: Bash
SCALE: 640 customer sites, 4 inverter vendors, hourly polls, ~15,000 readings/day
```

## 56. metergrist — co-op meter reading collector

```text
APP_DESCRIPTION: A pipeline for a rural electric co-op that ingests nightly AMI meter files from the head-end system: validates file completeness against the meter roster, converts vendor formats to the billing system's layout, quarantines misreads and rollbacks for the metering tech, and confirms billing-system load counts.
TECH_STACK: bash + sftp pickup + awk fixed-width transforms + roster reconciliation with comm + billing import CLI + nightly cron
APP_TYPE: data pipeline
LANGUAGE: Bash
SCALE: 21,000 meters, 96 interval reads/meter/day, ~2M rows/night, 2-hour load window
```

## 57. boilerpoll — campus HVAC logger

```text
APP_DESCRIPTION: A collection CLI for a boarding school's facilities crew that polls boiler-room and air-handler controllers over Modbus TCP, writes readings to daily logs, renders a one-page morning summary of overnight temperatures per building, and alerts the duty phone when heating loops fall below setpoint for 30 minutes.
TECH_STACK: bash + mbpoll + awk aggregation + gnuplot summary charts + ntfy alerts + systemd timer on the facilities server
APP_TYPE: CLI
LANGUAGE: Bash
SCALE: 9 buildings, 46 polled points, 5-minute cycle, ~13,000 readings/day
```

## 58. fleetfuel — courier telematics ETL

```text
APP_DESCRIPTION: An ETL pipeline for a same-day courier company that merges GPS provider exports with fuel-card transactions: matches fill-ups to vehicles and locations, flags fills far from the vehicle's GPS position or outside shift hours, and produces the weekly per-driver mileage and fuel-efficiency sheet for dispatch.
TECH_STACK: bash + curl (telematics + fuel-card portals) + jq/awk joins on vehicle and timestamp + variance rules + weekly cron
APP_TYPE: data pipeline
LANGUAGE: Bash
SCALE: 85 vehicles, ~1,100 GPS points/vehicle/day, ~400 fuel transactions/week
```

## 59. switchvault — network config archiver

```text
APP_DESCRIPTION: A CLI for a regional telecom's network team that archives device configurations: pulls running configs from switches and routers nightly over SSH, strips volatile lines, commits changes to a git repo with the device and diff summary in the message, and emails the team when an unexpected out-of-window change appears.
TECH_STACK: bash + ssh/expect-style scripted logins + sed volatile-line filters + git + msmtp diff alerts + nightly cron
APP_TYPE: CLI
LANGUAGE: Bash
SCALE: 410 network devices, nightly collection in 40 minutes, ~30 config changes/week detected
```

## 60. voippulse — call-detail rollup

```text
APP_DESCRIPTION: A pipeline for an answering-service call center that rolls up Asterisk CDRs each night: aggregates per-client call counts, durations, and abandonment rates, prices calls against each client's contract table, exports invoice-ready CSVs, and trends week-over-week volumes for the operations dashboard spreadsheet.
TECH_STACK: bash + Asterisk CDR CSV parsing with awk + join against contract TSVs + bc pricing math + nightly cron on the PBX host
APP_TYPE: data pipeline
LANGUAGE: Bash
SCALE: 3 PBX hosts, ~38,000 calls/day, 120 client accounts, nightly rollup in 10 minutes
```

## 61. dialplanship — PBX config deployer

```text
APP_DESCRIPTION: A CLI for a managed-VoIP provider that deploys Asterisk dialplan and SIP configuration changes safely: renders per-tenant configs from templates and a tenant TSV, syntax-checks in a scratch container, pushes to the target PBX, reloads with a test-call verification, and reverts to the previous config on failure.
TECH_STACK: bash + envsubst templating + docker CLI syntax check + rsync + asterisk -rx reload commands + a test-call SIP probe, run from ops
APP_TYPE: CLI
LANGUAGE: Bash
SCALE: 5 engineers, 90 tenant PBXes, ~35 config deploys/week
```

## 62. tideskim — harbor conditions fetcher

```text
APP_DESCRIPTION: A CLI for a harbor pilots' association that assembles the daily operations sheet: fetches NOAA tide predictions, current tables, and marine forecasts for the pilotage zone, merges them into a single sunrise-to-sunset timeline per berth, and prints and emails the sheet before the 05:00 briefing.
TECH_STACK: bash + curl (NOAA CO-OPS + NWS APIs) + jq + awk timeline merge + groff/ps2pdf sheet rendering + msmtp + 04:15 cron
APP_TYPE: CLI
LANGUAGE: Bash
SCALE: 18 pilots served, 6 berths, 3 API sources, daily by 04:45
```

## 63. notamsift — flight school briefing digester

```text
APP_DESCRIPTION: A pipeline for a flight school that digests overnight aviation notices: pulls NOTAMs and TFRs for the school's training area and cross-country routes, filters the boilerplate, highlights items intersecting planned routes, and posts a plain-language morning brief to the dispatch board and instructors' channel.
TECH_STACK: bash + curl (FAA APIs) + jq + grep/awk route filters + Slack webhook + Markdown board file + 05:30 cron
APP_TYPE: data pipeline
LANGUAGE: Bash
SCALE: 22 aircraft, 40 instructors, ~300 NOTAMs filtered to ~15 relevant/day
```

## 64. quakefeed — seismic waveform mirror

```text
APP_DESCRIPTION: A pipeline for a geology department that maintains a local mirror of regional seismic data: downloads miniSEED waveform files and station metadata from federated data centers on schedule, verifies completeness against station uptime, backfills gaps, and maintains the directory layout the department's analysis tools expect.
TECH_STACK: bash + curl (FDSN web services) + jq station inventories + gap-scan with custom awk + rsync layout enforcement + hourly cron
APP_TYPE: data pipeline
LANGUAGE: Bash
SCALE: 45 stations mirrored, ~4 GB/day, 30-day rolling window plus event archives
```

## 65. dronedump — survey flight ingester

```text
APP_DESCRIPTION: A CLI for an aerial survey firm's field crews that ingests drone SD cards at the truck: copies flights with checksum verification, groups images by flight from EXIF timestamps and GPS tracks, names folders by project/site/flight convention, flags gaps in image sequence numbers, and clears cards only after double verification.
TECH_STACK: bash + rsync + exiftool + sha256sum manifests + udev automount hooks, on ruggedized field laptops
APP_TYPE: CLI
LANGUAGE: Bash
SCALE: 6 field crews, ~8 flights/day each, 800-2,000 images per flight, ~150 GB/day ingested
```

## 66. cadcrate — drawing office backup

```text
APP_DESCRIPTION: A CLI for an architecture firm that protects project drawings: snapshots each active project's CAD and model directories to the archive server with hardlink deduplication, keeps issue-milestone snapshots forever and dailies for 60 days, and lets a project lead restore any file as of any retained date.
TECH_STACK: bash + rsync --link-dest + project manifest TSV + find retention pruning + smbclient for the Windows shares + nightly cron
APP_TYPE: CLI
LANGUAGE: Bash
SCALE: 38 active projects, ~3.2 TB working set, ~45 GB nightly delta, 60 daily generations
```

## 67. renderherd — farm job submit wrapper

```text
APP_DESCRIPTION: A CLI for an animation studio's artists that submits render jobs without touching the scheduler directly: validates scene paths and output targets, estimates frame cost from a history table, splits frame ranges into chunks, submits with the right pool and priority for the show, and tails job progress in the terminal.
TECH_STACK: bash + scheduler CLI (Deadline command) + awk cost estimates from history CSV + getopts UX + watch-style progress, in the studio toolbox
APP_TYPE: CLI
LANGUAGE: Bash
SCALE: 55 artists, ~250 job submissions/day, chunks of 5-20 frames, 85-node farm
```

## 68. platesling — VFX footage ingest checker

```text
APP_DESCRIPTION: A CLI for a VFX house's I/O department that ingests client footage drives: verifies delivered plates against the client's manifest (count, checksums, frame ranges), detects dropped or duplicate frames in image sequences, transcodes review proxies, and files plates into the show/shot tree with an ingest report per delivery.
TECH_STACK: bash + md5sum/xxhsum manifest verification + ffmpeg proxy transcodes + seq-gap detection in awk + rsync to SAN, on the I/O workstations
APP_TYPE: CLI
LANGUAGE: Bash
SCALE: 3 I/O operators, ~10 deliveries/week, 2-12 TB per delivery, 4K EXR sequences
```

## 69. subshift — subtitle batch converter

```text
APP_DESCRIPTION: A CLI for a subtitling agency that batch-converts caption deliverables: transforms between SRT, VTT, and broadcast STL, shifts timecodes for frame-rate conversions, validates reading-speed and line-length rules per client style guide, and packages per-language deliverable sets with a QC summary.
TECH_STACK: bash + ffmpeg subtitle muxing + awk timecode math + per-client rule files + zip packaging, distributed as a git repo with an installer
APP_TYPE: CLI
LANGUAGE: Bash
SCALE: 12 subtitlers, ~90 deliverables/week, 25 target languages, files of 400-1,800 cues
```

## 70. epubforge — indie press book builder

```text
APP_DESCRIPTION: A build pipeline for a small press that produces ebooks from manuscript sources: converts Markdown manuscripts through pandoc templates to EPUB and print-ready PDF, embeds fonts and cover art, validates EPUBs with epubcheck, stamps edition metadata, and archives every released build with its exact inputs.
TECH_STACK: bash + pandoc + LaTeX (print PDF) + epubcheck + exiftool metadata + git tags per release + make-style dependency checks
APP_TYPE: data pipeline
LANGUAGE: Bash
SCALE: 2 production staff, ~35 titles/year, 4 output formats per title, builds under 5 minutes
```

## 71. issuepress — newspaper edition archiver

```text
APP_DESCRIPTION: A pipeline for a daily newspaper that archives each night's edition: collects final page PDFs from the pagination system, assembles the complete-edition PDF in page order, generates web-quality and text-extracted copies for the searchable archive, and delivers the e-edition bundle to the digital replica vendor by deadline.
TECH_STACK: bash + qpdf assembly + ghostscript downsampling + pdftotext + rsync vendor delivery + control file from pagination + 00:45 cron
APP_TYPE: data pipeline
LANGUAGE: Bash
SCALE: 1 daily edition, 28-64 pages/night, vendor deadline 01:30, 25-year archive of ~9,000 editions
```

## 72. adrotor — radio traffic reconciler

```text
APP_DESCRIPTION: A pipeline for a commercial radio station that reconciles advertising: compares the traffic system's scheduled spot log against the automation system's as-played log each night, identifies missed or mistimed spots needing make-goods, and produces the affidavit-ready reconciliation report for the traffic manager.
TECH_STACK: bash + awk join of scheduled vs as-played logs + tolerance-window matching + report formatting with column + nightly cron
APP_TYPE: data pipeline
LANGUAGE: Bash
SCALE: 2 stations, ~450 spots/day each, reconciliation by 06:00, ~8 discrepancies/day flagged
```

## 73. sermoncast — worship recording publisher

```text
APP_DESCRIPTION: A CLI for a church's volunteer AV team that publishes Sunday recordings: trims the service recording to the sermon using marker timestamps, normalizes audio, renders a video with the title card, uploads audio to the podcast host and video to the streaming channel, and updates the sermon archive page's index.
TECH_STACK: bash + ffmpeg trim/loudnorm + ImageMagick title cards + curl uploads (podcast host + YouTube API) + a TSV sermon index
APP_TYPE: CLI
LANGUAGE: Bash
SCALE: 3 volunteers, 1-2 services/week, 90-minute source recordings, published within 3 hours
```

## 74. lectureloop — college capture publisher

```text
APP_DESCRIPTION: A pipeline for a community college's media services that publishes lecture-capture recordings: collects room-recorder files overnight, matches each to the course schedule by room and time, transcodes to streaming renditions, requests captions from the captioning vendor, and posts the finished lecture to the right LMS course shell.
TECH_STACK: bash + ffmpeg renditions + schedule TSV matching in awk + curl (captioning vendor + LMS APIs) + jq + nightly cron on the media server
APP_TYPE: data pipeline
LANGUAGE: Bash
SCALE: 45 equipped rooms, ~140 recordings/day in term, published by 07:00 next morning
```

## 75. turnstally — gym access rollup

```text
APP_DESCRIPTION: A pipeline for a regional gym chain that consolidates door-controller access logs: pulls swipe events from each club's controller nightly, deduplicates crossings, computes per-club hourly utilization and peak occupancy, flags badge IDs that no longer map to active members, and feeds the staffing planner's spreadsheet.
TECH_STACK: bash + curl (controller exports) + awk sessionization + membership roster join with comm + CSV outputs + nightly cron
APP_TYPE: data pipeline
LANGUAGE: Bash
SCALE: 14 clubs, ~9,000 swipes/day, 60,000 members, nightly rollup in 15 minutes
```

## 76. chartsafe — dental imaging backup

```text
APP_DESCRIPTION: A CLI for a three-office dental practice that safeguards imaging data: verifies each office's X-ray sensor workstation wrote the day's studies to the practice server, snapshots the imaging store with rotation, encrypts and ships a copy offsite, and prints a morning one-liner per office confirming last night's backup health.
TECH_STACK: bash + rsync --link-dest + study-count verification with find + age encryption + rclone offsite + msmtp morning report + nightly cron
APP_TYPE: CLI
LANGUAGE: Bash
SCALE: 3 offices, ~60 imaging studies/day, 1.4 TB imaging store, 30 daily + 12 monthly generations
```

## 77. kennelsync — boarding record exporter

```text
APP_DESCRIPTION: A pipeline for a veterinary boarding facility that keeps the kennel whiteboard system in sync with the clinic's practice-management exports: imports tonight's check-ins/check-outs and feeding or medication notes from the PM system's CSV export, generates printable run-cards per kennel, and flags pets whose vaccination records lapse during their stay.
TECH_STACK: bash + CSV parsing with awk + date arithmetic for stay windows + groff run-card rendering + lp printing + 3x daily cron
APP_TYPE: data pipeline
LANGUAGE: Bash
SCALE: 48 kennels, ~35 check-ins/day, 3 syncs/day, run-cards printed by 06:30
```

## 78. claimferry — insurance batch mover

```text
APP_DESCRIPTION: A pipeline for a regional insurance office that moves claims batches between partners: sweeps the adjusters' outbound folder, validates each claim package's required documents against a checklist, encrypts and transmits batches to carrier SFTP endpoints on their schedules, and reconciles carrier acknowledgment files the next morning.
TECH_STACK: bash + package checklist validation with find/grep + gpg encryption + lftp per-carrier profiles + ack reconciliation in awk + cron
APP_TYPE: data pipeline
LANGUAGE: Bash
SCALE: 6 carriers, ~180 claim packages/day, transmission windows 22:00-02:00, acks reconciled by 08:00
```

## 79. achbundle — credit union file gatekeeper

```text
APP_DESCRIPTION: A CLI for a credit union's operations team that gates outgoing ACH files: validates NACHA file structure and batch/entry control totals, enforces per-file dollar caps and duplicate-file detection by hash, requires a second operator's confirmation code for release, and logs every file's lifecycle for examiners.
TECH_STACK: bash + fixed-width NACHA parsing in awk + bc control-total math + sha256 duplicate ledger + two-person release flow + sftp submission
APP_TYPE: CLI
LANGUAGE: Bash
SCALE: 4 operators, 3 files/day, ~2,400 entries/file, $4M average file value, zero duplicate releases tolerated
```

## 80. mlsdrip — brokerage listing media fetcher

```text
APP_DESCRIPTION: A pipeline for a real-estate brokerage that keeps listing media current on its website: polls the MLS RESO API for the brokerage's active listings, downloads new or changed photos, generates web renditions, purges media for delisted properties, and writes the manifest the website templates read.
TECH_STACK: bash + curl (RESO Web API with token refresh) + jq + ImageMagick renditions + rsync to web storage + manifest JSON via jq + hourly cron
APP_TYPE: data pipeline
LANGUAGE: Bash
SCALE: 240 active listings, ~30 photo changes/hour peak, 5 renditions per photo, hourly sync
```

## 81. manifestmerge — freight document consolidator

```text
APP_DESCRIPTION: An ETL pipeline for a freight forwarder that consolidates shipping documents: collects manifests, bookings, and container status files from carrier portals and email drops, normalizes references to the house bill number, merges them into one status record per shipment, and exports the operations team's morning tracking sheet.
TECH_STACK: bash + lftp/curl collectors + munpack email extraction + awk reference normalization + join-based merging + XLSX-compatible CSV export + cron
APP_TYPE: data pipeline
LANGUAGE: Bash
SCALE: 9 carriers, ~450 active shipments, ~1,100 documents/week, tracking sheet by 07:30 daily
```

## 82. plantpulse — factory line log collector

```text
APP_DESCRIPTION: A collection pipeline for a plastics manufacturer that gathers production logs from injection-molding machine controllers: pulls cycle logs from each machine's FTP share hourly, converts vendor formats to a common schema, computes shift OEE inputs (cycle counts, downtime gaps, rejects), and appends to the plant historian CSVs.
TECH_STACK: bash + lftp pulls + dos2unix + awk schema normalization + gap detection + per-shift rollups + hourly cron on the plant-floor server
APP_TYPE: data pipeline
LANGUAGE: Bash
SCALE: 22 machines, ~90,000 cycle records/day, 3 shifts, hourly collection within 5 minutes
```

## 83. slurmtidy — HPC scratch policy enforcer

```text
APP_DESCRIPTION: A CLI for a university HPC center that enforces scratch-storage policy: scans scratch filesystems for files past the posted retention, exempts paths tied to running or queued Slurm jobs, warns owners by email at 7 and 2 days before purge, and executes purges with a per-user manifest kept for 90 days.
TECH_STACK: bash + lfs find (Lustre) + squeue cross-reference + awk owner aggregation + sendmail warnings + purge manifests + daily cron on the management node
APP_TYPE: CLI
LANGUAGE: Bash
SCALE: 1.5 PB scratch, 900 active users, ~40 TB purged/week, daily scan in 3 hours
```

## 84. robobale — ROS bag archiver

```text
APP_DESCRIPTION: A CLI for a robotics lab that archives experiment recordings: sweeps robot workstations for new ROS bag files, compresses and tags them with experiment metadata prompted from the operator, verifies topic counts against the experiment's expected sensor list, and moves them to the lab archive with a searchable index entry.
TECH_STACK: bash + rsync sweeps + ros2 bag info parsing + zstd + a TSV metadata index + read-back verification, run at end of each experiment day
APP_TYPE: CLI
LANGUAGE: Bash
SCALE: 6 robots, ~30 bags/week, 2-40 GB per bag, 28 TB archive
```

## 85. dicomferry — imaging study router

```text
APP_DESCRIPTION: A pipeline for an outpatient imaging clinic that routes DICOM studies after hours: watches the modality inbox, verifies study completeness by instance counts, forwards studies to the radiology group's PACS and the archive simultaneously, confirms both storage commitments, and escalates any unrouted study older than 30 minutes.
TECH_STACK: bash + dcmtk (storescu/findscu) + inotifywait inbox watch + instance-count checks + msmtp escalation + systemd service on the gateway box
APP_TYPE: data pipeline
LANGUAGE: Bash
SCALE: 4 modalities, ~90 studies/day, 200-1,500 instances per study, 30-minute routing SLA
```

## 86. marcstack — library record loader

```text
APP_DESCRIPTION: A pipeline for a public library system that loads vendor bibliographic records: picks up weekly MARC files from cataloging vendors, validates record structure and required fields, deduplicates against the catalog by control numbers, stages accepted records for the ILS bulk importer, and reports rejects to the cataloging librarian.
TECH_STACK: bash + yaz-marcdump validation/conversion + grep/awk field checks + comm dedupe against exported control-number lists + ILS import CLI + weekly cron
APP_TYPE: data pipeline
LANGUAGE: Bash
SCALE: 5 vendors, ~4,000 records/week, 1.1M-record catalog, Monday load before opening
```

## 87. artcrate — gallery derivative generator

```text
APP_DESCRIPTION: A CLI for a contemporary art gallery that produces image derivatives from master photography: generates web, catalog-print, and thumbnail renditions with the gallery's color profile, embeds artist and copyright metadata from the collection spreadsheet, and organizes output by exhibition and artist for the website and print designers.
TECH_STACK: bash + ImageMagick with ICC profiles + exiftool metadata from CSV + parallel batch runs + rsync to the design share
APP_TYPE: CLI
LANGUAGE: Bash
SCALE: 1 registrar, ~50 new masters/week, 3 renditions each, 12,000-image collection
```

## 88. archivegrain — municipal web archiver

```text
APP_DESCRIPTION: A pipeline for a city archives office that preserves official web content: crawls the city's sites and social-media export dumps on a monthly schedule into WARC files, verifies capture completeness against a seed list, generates access copies and a capture report, and writes everything to preservation storage with fixity manifests.
TECH_STACK: bash + wget --warc + seed-list TSV + sha512 fixity manifests + rclone to preservation storage + monthly cron on the archives server
APP_TYPE: data pipeline
LANGUAGE: Bash
SCALE: 45 seed sites, ~25 GB WARC/month, monthly crawls, 10-year retention mandate
```

## 89. permitpull — county filing fetcher

```text
APP_DESCRIPTION: A pipeline for a construction-data company that collects building permit filings from county portals: fetches new permit PDFs and CSV registers from a list of county sources on each county's publish schedule, normalizes fields to a common schema, deduplicates by permit number, and delivers a daily combined feed to subscribers.
TECH_STACK: bash + curl per-county fetch profiles + pdftotext extraction + awk schema mapping + sort-based dedupe + sftp subscriber delivery + cron
APP_TYPE: data pipeline
LANGUAGE: Bash
SCALE: 32 counties, ~900 new permits/day, subscriber feed by 09:00, 14 subscribers
```

## 90. docketferry — court calendar distributor

```text
APP_DESCRIPTION: A pipeline for a county court clerk's office that distributes daily docket calendars: pulls tomorrow's hearing schedule export from the case-management system, splits it into per-courtroom and per-judge calendars, renders printable PDFs and posts the public versions with sealed-case rows removed, and emails each judge's chambers their calendar.
TECH_STACK: bash + CSV split/filter with awk + sealed-flag redaction rules + groff/ps2pdf rendering + msmtp distribution + 17:30 cron
APP_TYPE: data pipeline
LANGUAGE: Bash
SCALE: 14 courtrooms, ~220 hearings/day, distribution by 18:00, zero sealed-case leaks tolerated
```

## 91. stallcount — parking garage tallier

```text
APP_DESCRIPTION: A pipeline for a downtown parking operator that tallies garage occupancy: collects entry/exit counter events from each garage's controller, corrects drift against nightly physical-count baselines, publishes current space counts to the wayfinding signs' data file, and produces the monthly utilization report per garage.
TECH_STACK: bash + curl controller polls + awk running tallies with drift correction + JSON sign feed via jq + monthly report rollups + 1-minute systemd timer
APP_TYPE: data pipeline
LANGUAGE: Bash
SCALE: 6 garages, 4,800 total stalls, ~14,000 gate events/day, sign feed updated every minute
```

## 92. kioskkick — mall directory watchdog

```text
APP_DESCRIPTION: A watchdog CLI for a shopping-mall operator's directory kiosks: each kiosk checks its browser process, touchscreen input health, and content freshness on a timer, restarts the browser or reboots on failure with escalating backoff, and reports status upstream so facilities sees a red/green board of all kiosks.
TECH_STACK: bash + pgrep/xdotool health probes + systemd watchdog integration + curl status beacon + content-hash freshness check, preinstalled on kiosk images
APP_TYPE: CLI
LANGUAGE: Bash
SCALE: 3 properties, 41 kiosks, 2-minute check cycle, target 99.5% kiosk uptime
```

## 93. badgeforge — event credential batcher

```text
APP_DESCRIPTION: A CLI for a conference-production agency that generates attendee credentials: merges the registration CSV into badge PDF templates with per-tier designs, generates QR codes carrying signed check-in tokens, imposes badges onto print sheets in stock order, and produces reprint files for on-site corrections in seconds.
TECH_STACK: bash + qrencode + ImageMagick/pdftk template composition + openssl-signed tokens + registration CSV via awk, run on the ops laptop
APP_TYPE: CLI
LANGUAGE: Bash
SCALE: ~20 events/year, 300-8,000 badges per event, full batch render under 15 minutes
```

## 94. boothstage — demo fleet provisioner

```text
APP_DESCRIPTION: A CLI for a marketing agency's events team that stages trade-show demo laptops: applies the event's profile to each machine (wallpaper, kiosk user, demo build install, browser homepage, telemetry opt-outs), locks down USB and sleep settings, verifies the demo launches cleanly, and resets machines to a clean state between shows.
TECH_STACK: bash + per-event profile directories + dconf/gsettings + systemd unit installs + demo smoke-test with timeout + USB provisioning stick
APP_TYPE: CLI
LANGUAGE: Bash
SCALE: 30 demo laptops, ~12 shows/year, full stage of a laptop in 8 minutes
```

## 95. coldeye — colo environment sentinel

```text
APP_DESCRIPTION: A monitoring pipeline for a colocation facility that watches environmental telemetry: polls temperature, humidity, and door sensors across rows plus PDU load per rack, writes readings to ring-buffer logs, alerts the facilities pager on threshold breaches with row/rack location, and renders an hourly heat report per aisle.
TECH_STACK: bash + snmpget sensor polls + awk thresholds and ring buffers + gnuplot aisle reports + pager gateway curl + 30-second systemd timer
APP_TYPE: data pipeline
LANGUAGE: Bash
SCALE: 12 aisles, 340 sensors, 30-second polls, ~980,000 readings/day
```

## 96. repofreeze — foundation code mirror

```text
APP_DESCRIPTION: A pipeline for an open-source foundation that maintains disaster-recovery mirrors of its project repositories: enumerates all organizations' repos via the forge API, mirror-clones new ones and fetches existing ones, bundles each repo weekly into verifiable archives, and reports any repo that fails to fetch for 3 consecutive days.
TECH_STACK: bash + gh api / curl enumeration + git clone --mirror + git bundle + jq + sha256 manifests + rclone to two storage providers + nightly cron
APP_TYPE: data pipeline
LANGUAGE: Bash
SCALE: 9 organizations, ~1,150 repositories, 210 GB mirror set, nightly fetch in 2 hours
```

## 97. secretsweep — pre-push credential scanner

```text
APP_DESCRIPTION: A defensive git hook CLI for a development consultancy that stops credentials leaving laptops: scans outgoing commits for key patterns, entropy-suspicious strings, and known config filenames, checks against a per-repo allowlist for accepted false positives, blocks the push with an explain-why report, and never transmits code anywhere.
TECH_STACK: bash + git diff plumbing + grep -P pattern catalog + awk entropy scoring + per-repo allowlist files, installed via the repo's bootstrap script
APP_TYPE: CLI
LANGUAGE: Bash
SCALE: 45 developers, ~120 repos, ~500 pushes/day scanned, median scan under 400 ms
```

## 98. imagebake — training lab image builder

```text
APP_DESCRIPTION: A CLI for a technical-training company that bakes golden VM images for classes: builds each course's image from a base plus a course profile (packages, exercise files, user accounts, snapshots at lesson checkpoints), boots the result headless for a smoke test, and publishes versioned images to the classroom deployment server.
TECH_STACK: bash + qemu-img/virt-customize + cloud-init seeds + course profile directories + smoke-test via ssh with timeout + rsync publish
APP_TYPE: CLI
LANGUAGE: Bash
SCALE: 14 course images, weekly rebuilds, 25 GB average image, classroom of 30 seats per site
```

## 99. journalbale — reseller log shipper

```text
APP_DESCRIPTION: A pipeline for a hosting reseller that ships customer-server logs to cold storage for its support workflow: exports each host's systemd journal daily in bounded chunks, compresses and encrypts per-customer bundles, uploads with lifecycle tagging so storage auto-expires at the retention date, and verifies yesterday's uploads before deleting local copies.
TECH_STACK: bash + journalctl export + zstd + age per-customer keys + aws s3 cp with object tags + verification manifest + daily cron via config management
APP_TYPE: data pipeline
LANGUAGE: Bash
SCALE: 130 customer servers, ~35 GB journal exports/day, 90-day retention, daily window 02:00-05:00
```

## 100. usherlight — theater show-file distributor

```text
APP_DESCRIPTION: A CLI for a performing-arts center's technical crew that distributes show configuration between venues: packages a production's lighting, sound, and projection show files with a manifest, verifies console firmware compatibility per venue from an equipment inventory, pushes the package to the target venue's show network, and archives every loaded version for revival remounts.
TECH_STACK: bash + tar packaged show bundles + TSV equipment inventory checks + rsync over the show network + versioned archive tree + sha256 manifests
APP_TYPE: CLI
LANGUAGE: Bash
SCALE: 3 venues, ~22 productions/year, show packages 2-30 GB, archive of 240 versions
```
