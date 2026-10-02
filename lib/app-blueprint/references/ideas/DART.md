# Dart Blueprint Types — Copy-Paste Input Sets

Copy a fenced block into the prompt as-is, or swap individual fields.

## 1. TrailMend — backcountry trip journal

```text
APP_DESCRIPTION: A mobile trip journal for backcountry hikers that works with no signal. Users plan multi-day routes, cache offline topo tiles and waypoints, log daily distance, elevation, and camp notes with photos, and sync everything once they regain coverage.
TECH_STACK: Flutter + Riverpod + drift (SQLite) local store + flutter_map with cached MBTiles + Supabase (Postgres + Storage) sync, shipped to App Store and Play Store
APP_TYPE: mobile
LANGUAGE: Dart
SCALE: 40,000 installs, ~4,000 daily active hikers, offline-first with <5 GB per-device cache
```

## 2. DoseDial — medication adherence tracker

```text
APP_DESCRIPTION: A mobile medication adherence app for people on complex prescription schedules. It builds per-drug reminder plans, tracks doses taken, skipped, or delayed, warns on interaction conflicts from a bundled formulary, and produces adherence reports patients can share with their clinician.
TECH_STACK: Flutter + Bloc + Isar local database + flutter_local_notifications + Firebase Auth and Firestore sync, deployed to App Store and Play Store
APP_TYPE: mobile
LANGUAGE: Dart
SCALE: 120,000 installs, ~25,000 daily active users, ~8 scheduled reminders per user per day
```

## 3. FretFlow — guitar practice coach

```text
APP_DESCRIPTION: A mobile practice coach for guitarists that listens as they play. It runs on-device pitch detection to score exercises, tracks tempo progress on scales and songs, schedules spaced practice routines, and visualizes accuracy trends over weeks.
TECH_STACK: Flutter + Riverpod + native audio via platform channels for pitch DSP + Hive settings store + Supabase progress sync, packaged for App Store and Play Store
APP_TYPE: mobile
LANGUAGE: Dart
SCALE: 60,000 installs, ~10,000 weekly active players, real-time pitch analysis at 44.1 kHz on device
```

## 4. PantryPilot — kitchen inventory and meal planner

```text
APP_DESCRIPTION: A mobile kitchen manager that tracks what is in the pantry and fridge. Users scan barcodes to add items, get expiry alerts, generate weekly meal plans from what they already own, and export a consolidated shopping list grouped by store aisle.
TECH_STACK: Flutter + Riverpod + drift (SQLite) + mobile_scanner barcode reader + Open Food Facts API + Supabase household sync, shipped to App Store and Play Store
APP_TYPE: mobile
LANGUAGE: Dart
SCALE: 80,000 installs, shared households up to 6 members, ~500 tracked items per household
```

## 5. RideRoster — youth sports carpool coordinator

```text
APP_DESCRIPTION: A mobile carpool coordinator for youth sports teams. Parents post available seats and pickup windows for practices and games, claim rides, get schedule-change alerts from the team calendar, and coaches broadcast last-minute location changes.
TECH_STACK: Flutter + Bloc + Firebase Auth, Firestore, and Cloud Messaging + Google Maps SDK, deployed to App Store and Play Store
APP_TYPE: mobile
LANGUAGE: Dart
SCALE: 500 teams, ~15,000 parent accounts, push fan-out to team rosters of 12-20 within seconds
```

## 6. TideTally — tide and fishing conditions log

```text
APP_DESCRIPTION: A mobile companion for shore anglers that pairs tide and weather forecasts with a personal catch log. Users see tide curves and solunar windows for saved spots, record species, size, bait, and conditions per catch, and review which conditions produced the best sessions.
TECH_STACK: Flutter + Riverpod + drift local log + NOAA tides and marine weather APIs + Supabase spot and catch sync, shipped to App Store and Play Store
APP_TYPE: mobile
LANGUAGE: Dart
SCALE: 35,000 installs, ~6,000 monthly active anglers, offline access to cached tide tables for saved spots
```

## 7. BloomBudget — envelope budgeting

```text
APP_DESCRIPTION: A mobile envelope-budgeting app for households on variable income. Users allocate each paycheck into spending envelopes, log transactions against them, roll unspent amounts forward, and see which categories are overspending before month end.
TECH_STACK: Flutter + Riverpod + drift (SQLite) + local_auth biometric lock + Supabase encrypted sync across devices, deployed to App Store and Play Store
APP_TYPE: mobile
LANGUAGE: Dart
SCALE: 90,000 installs, ~20,000 monthly active users, multi-device sync for a household of 2-4
```

## 8. LatchLog — newborn care tracker

```text
APP_DESCRIPTION: A mobile tracker for new parents logging newborn feeding, sleep, and diapers. It records breastfeeding sessions with side and duration timers, bottle amounts, and sleep stretches, then charts patterns and flags pediatric-relevant trends for checkups.
TECH_STACK: Flutter + Bloc + Isar local store + WatchOS/Wear companion via platform channels + Firebase sync for two caregivers, shipped to App Store and Play Store
APP_TYPE: mobile
LANGUAGE: Dart
SCALE: 70,000 installs, ~12,000 daily active caregivers, real-time sync between two parent devices
```

## 9. PitchPortal — pickup soccer matchmaking

```text
APP_DESCRIPTION: A mobile app for organizing pickup soccer games. Players find nearby games by skill level, RSVP with a waitlist, split field-rental costs, and organizers manage rosters, no-show tracking, and balanced team generation on game day.
TECH_STACK: Flutter + Riverpod + Firebase Auth and Firestore + Stripe payments SDK + Google Maps SDK, deployed to App Store and Play Store
APP_TYPE: mobile
LANGUAGE: Dart
SCALE: 25,000 players across 60 cities, ~2,000 games/week, cost-splitting for groups of 10-22
```

## 10. CaskCatalog — home cellar manager

```text
APP_DESCRIPTION: A mobile cellar manager for wine and whisky collectors. Users catalog bottles by scanning labels, track drinking windows and current market value, log tasting notes, and get alerts when a bottle is entering its optimal window.
TECH_STACK: Flutter + Riverpod + drift local store + google_ml_kit on-device text recognition for labels + Supabase sync and Storage for photos, shipped to App Store and Play Store
APP_TYPE: mobile
LANGUAGE: Dart
SCALE: 20,000 installs, cellars up to 2,000 bottles, on-device label OCR with cloud photo backup
```

## 11. StepSwap — corporate wellness challenge

```text
APP_DESCRIPTION: A mobile step-challenge app for corporate wellness programs. Employees join team competitions, sync steps from health platforms, climb department leaderboards, and HR admins configure challenge windows, rewards, and anonymized participation reporting.
TECH_STACK: Flutter + Bloc + HealthKit and Google Fit via health package + a Dart Frog backend on Postgres for leaderboards, deployed to App Store, Play Store, and Cloud Run
APP_TYPE: mobile
LANGUAGE: Dart
SCALE: 300 employer tenants, ~80,000 participants, daily step aggregation across teams of 5-50
```

## 12. NestNote — home maintenance reminders

```text
APP_DESCRIPTION: A mobile home-maintenance planner. Homeowners register appliances and systems with install dates, receive seasonal upkeep reminders (filter changes, gutter cleaning, detector tests), log completed tasks with receipts, and build a service history for resale.
TECH_STACK: Flutter + Riverpod + drift (SQLite) + flutter_local_notifications + Supabase sync and Storage for receipt photos, shipped to App Store and Play Store
APP_TYPE: mobile
LANGUAGE: Dart
SCALE: 45,000 installs, ~30 tracked assets per home, seasonal reminder scheduling per household
```

## 13. VerseVault — reading plan and journaling

```text
APP_DESCRIPTION: A mobile scripture reading and journaling app. Users follow structured reading plans, highlight and annotate passages, keep dated reflections, and track streaks, with full offline access to bundled translations.
TECH_STACK: Flutter + Riverpod + Isar for bundled text and notes + flutter_local_notifications + Firebase sync for cross-device journals, deployed to App Store and Play Store
APP_TYPE: mobile
LANGUAGE: Dart
SCALE: 100,000 installs, ~18,000 daily readers, fully offline text with cloud-synced private journals
```

## 14. GritGauge — climbing session logbook

```text
APP_DESCRIPTION: A mobile logbook for boulderers and sport climbers. Users log sends and attempts by grade and gym, track projects across sessions, chart pyramid progression, and compare performance across indoor and outdoor problems.
TECH_STACK: Flutter + Bloc + drift local store + Supabase gym database and social sync, shipped to App Store and Play Store
APP_TYPE: mobile
LANGUAGE: Dart
SCALE: 30,000 installs, ~7,000 monthly active climbers, per-user history of thousands of logged climbs
```

## 15. FareFold — receipt and mileage capture

```text
APP_DESCRIPTION: A mobile expense-capture app for gig workers and small-business owners. It scans receipts to extract merchant, amount, and tax, tracks trip mileage via GPS, categorizes expenses for tax time, and exports summaries to accounting tools.
TECH_STACK: Flutter + Riverpod + google_ml_kit on-device OCR + geolocator for trip tracking + drift local store + a shelf export API on Cloud Run, deployed to App Store and Play Store
APP_TYPE: mobile
LANGUAGE: Dart
SCALE: 50,000 installs, ~15,000 active filers, on-device receipt OCR with monthly CSV/QBO export
```

## 16. PawPlanner — pet care and vet records

```text
APP_DESCRIPTION: A mobile pet-care organizer. Owners store vaccination and vet records, schedule medication and grooming reminders, track weight and feeding, and share a pet profile with sitters or new vets via a secure link.
TECH_STACK: Flutter + Riverpod + Isar local store + Firebase Auth, Firestore, and Storage + shareable web view via Flutter web, shipped to App Store and Play Store
APP_TYPE: mobile
LANGUAGE: Dart
SCALE: 65,000 installs, multi-pet households, secure share links viewed by sitters and clinics
```

## 17. LoomList — knitting and crochet tracker

```text
APP_DESCRIPTION: A mobile project tracker for knitters and crocheters. Users store patterns, track row counters and yarn stash, log progress photos per project, and calculate remaining yardage against their stash before starting a new piece.
TECH_STACK: Flutter + Bloc + drift local store + Supabase Storage for project photos and pattern PDFs, deployed to App Store and Play Store
APP_TYPE: mobile
LANGUAGE: Dart
SCALE: 22,000 installs, ~8,000 active makers, dozens of concurrent projects with photo history per user
```

## 18. QueueQuest — theme park day planner

```text
APP_DESCRIPTION: A mobile theme-park planner that optimizes a visitor's day. It ingests live wait times, builds an efficient ride order from must-do picks and party constraints, sends reordering suggestions as waits change, and tracks what the group has already ridden.
TECH_STACK: Flutter + Riverpod + a Dart Frog backend aggregating wait-time feeds on Postgres and Redis + Google Maps SDK, deployed to App Store, Play Store, and Cloud Run
APP_TYPE: mobile
LANGUAGE: Dart
SCALE: 40,000 installs, peak-day surges of ~5,000 concurrent planners, wait-time refresh every 5 minutes
```

## 19. ChoreChart — family chores and allowance

```text
APP_DESCRIPTION: A mobile chore and allowance manager for families. Parents assign recurring chores with point values, kids check off completed tasks for approval, and the app tracks earned allowance, savings goals, and payout history across children.
TECH_STACK: Flutter + Riverpod + Firebase Auth, Firestore, and Cloud Messaging for parent approvals, shipped to App Store and Play Store
APP_TYPE: mobile
LANGUAGE: Dart
SCALE: 35,000 family accounts, 2-6 members each, real-time chore approval notifications
```

## 20. MoodMosaic — mood journaling

```text
APP_DESCRIPTION: A mobile mood-tracking journal grounded in CBT practices. Users log mood, energy, and triggers several times a day, tag activities, complete guided reframing exercises, and review correlation charts between behaviors and mood over time.
TECH_STACK: Flutter + Bloc + Isar encrypted local store + local_auth biometric lock + optional Supabase encrypted backup, deployed to App Store and Play Store
APP_TYPE: mobile
LANGUAGE: Dart
SCALE: 55,000 installs, ~14,000 daily journalers, privacy-first with local encryption and opt-in cloud backup
```

## 21. GreenGauge — houseplant scheduler

```text
APP_DESCRIPTION: A mobile plant-care app. Users catalog houseplants with species-specific watering, light, and fertilizing schedules, get adaptive reminders adjusted for season and room, log care events, and diagnose common problems from a symptom guide.
TECH_STACK: Flutter + Riverpod + drift local store + a bundled species care database + flutter_local_notifications + Supabase photo backup, shipped to App Store and Play Store
APP_TYPE: mobile
LANGUAGE: Dart
SCALE: 60,000 installs, collections up to 200 plants, season-adjusted reminder scheduling per plant
```

## 22. RepReef — gym workout logger

```text
APP_DESCRIPTION: A mobile strength-training logger. Users build routines, log sets, reps, and weight with rest timers, track personal records and progressive overload, and review volume and one-rep-max trends per lift across mesocycles.
TECH_STACK: Flutter + Riverpod + drift (SQLite) local store + Supabase sync + Wear OS companion via platform channels, deployed to App Store and Play Store
APP_TYPE: mobile
LANGUAGE: Dart
SCALE: 85,000 installs, ~20,000 weekly active lifters, offline logging with cross-device workout history
```

## 23. SplitSprout — group trip expense splitter

```text
APP_DESCRIPTION: A mobile expense splitter for group trips. Members add shared expenses, assign custom splits, settle in multiple currencies with live rates, and the app computes the minimum set of transfers to square everyone up at trip end.
TECH_STACK: Flutter + Bloc + drift local store + Firebase Firestore for group sync + a currency-rate API, shipped to App Store and Play Store
APP_TYPE: mobile
LANGUAGE: Dart
SCALE: 45,000 installs, groups of 2-15, real-time multi-currency settlement across member devices
```

## 24. CoachCue — swim meet timing

```text
APP_DESCRIPTION: A tablet-first mobile app for swim coaches timing meets. Coaches assign lanes and events, capture split times with large touch targets, compare against season bests live, and export heat results to the meet management system.
TECH_STACK: Flutter + Riverpod + drift local store + CSV/Hy-Tek export + optional Supabase team sync, deployed to App Store and Play Store for tablets
APP_TYPE: mobile
LANGUAGE: Dart
SCALE: 800 teams, meets of ~300 swimmers, sub-second split capture with offline reliability poolside
```

## 25. BrewBench — home coffee recipe tracker

```text
APP_DESCRIPTION: A mobile brewing companion for home baristas. Users log recipes by method, grind, ratio, and time, rate results, track bean inventory and freshness, and get dial-in suggestions when a shot pulls too fast or slow.
TECH_STACK: Flutter + Riverpod + drift local store + integrated brew timer + Supabase recipe sync and sharing, shipped to App Store and Play Store
APP_TYPE: mobile
LANGUAGE: Dart
SCALE: 28,000 installs, ~9,000 monthly active brewers, per-user library of hundreds of logged brews
```

## 26. VoltVista — EV charging trip planner

```text
APP_DESCRIPTION: A mobile trip planner for EV drivers. It plans routes with charging stops based on the vehicle's range and charger networks, shows live station availability, estimates arrival state-of-charge, and logs charging costs and sessions.
TECH_STACK: Flutter + Bloc + a Dart Frog routing backend on Postgres + Open Charge Map and network availability APIs + Mapbox SDK, deployed to App Store, Play Store, and Cloud Run
APP_TYPE: mobile
LANGUAGE: Dart
SCALE: 30,000 installs, ~5,000 daily route plans, station-availability refresh on a 2-minute cadence
```

## 27. CivicSignal — municipal issue reporting

```text
APP_DESCRIPTION: A mobile 311-style civic reporting app. Residents photograph and geotag issues like potholes, broken lights, and graffiti, track resolution status, and the city routes reports to the right department with SLA timers.
TECH_STACK: Flutter + Riverpod + a Dart Frog intake API on Postgres + PostGIS + Firebase Cloud Messaging status updates + Mapbox SDK, deployed to App Store, Play Store, and a managed container host
APP_TYPE: mobile
LANGUAGE: Dart
SCALE: mid-size city of 250,000 residents, ~1,200 reports/week, department routing with SLA tracking
```

## 28. TastePass — restaurant loyalty and ordering

```text
APP_DESCRIPTION: A mobile loyalty and mobile-ordering app for a regional restaurant group. Diners browse menus, order for pickup, earn and redeem points, receive location-based offers, and reorder favorites in a couple of taps.
TECH_STACK: Flutter + Bloc + a Serverpod backend on Postgres and Redis + Stripe payments + Firebase Cloud Messaging, deployed to App Store, Play Store, and a managed container host
APP_TYPE: mobile
LANGUAGE: Dart
SCALE: 40 locations, ~60,000 members, lunch-rush peaks of ~500 concurrent orders
```

## 29. FloraField — plant identification for foragers

```text
APP_DESCRIPTION: A mobile plant-identification app for foragers and gardeners that works offline in the field. It classifies plants from photos with an on-device model, warns on toxic look-alikes, and lets users build a personal field log of finds with locations.
TECH_STACK: Flutter + Riverpod + a bundled TFLite classifier via tflite_flutter + drift find log + Supabase optional sync, shipped to App Store and Play Store
APP_TYPE: mobile
LANGUAGE: Dart
SCALE: 50,000 installs, on-device inference with no connectivity required, ~3,000 species in the bundled model
```

## 30. ShiftStack — hourly shift swap

```text
APP_DESCRIPTION: A mobile shift-management app for hourly retail and hospitality staff. Employees view schedules, request and approve swaps within manager rules, mark availability, and clock in with geofenced verification.
TECH_STACK: Flutter + Bloc + a Dart Frog backend on Postgres + geolocator geofencing + Firebase Cloud Messaging, deployed to App Store, Play Store, and Cloud Run
APP_TYPE: mobile
LANGUAGE: Dart
SCALE: 200 store tenants, ~18,000 staff, swap approvals and schedule pushes in near real time
```

## 31. LingoLoop — spaced-repetition vocabulary

```text
APP_DESCRIPTION: A mobile vocabulary trainer using spaced repetition. Learners study curated or custom decks with audio, review on an adaptive schedule, practice listening and typing recall, and track retention and streaks per language.
TECH_STACK: Flutter + Riverpod + drift (SQLite) with an SM-2 scheduler + bundled audio assets + Supabase deck sync and marketplace, deployed to App Store and Play Store
APP_TYPE: mobile
LANGUAGE: Dart
SCALE: 90,000 installs, ~22,000 daily reviewers, offline scheduling with cloud-synced custom decks
```

## 32. GuardGait — elderly fall detection companion

```text
APP_DESCRIPTION: A mobile safety companion for older adults living alone. It monitors motion sensors for fall patterns, prompts a check-in when a fall is suspected, escalates to caregivers if unanswered, and shares a daily activity summary with family.
TECH_STACK: Flutter + Bloc + sensors_plus accelerometer processing + background_fetch + a Dart Frog alerting backend with Twilio escalation, deployed to App Store, Play Store, and Cloud Run
APP_TYPE: mobile
LANGUAGE: Dart
SCALE: 15,000 installs, continuous background sensor monitoring, caregiver escalation within seconds of a missed check-in
```

## 33. HarborHail — small-marina slip booking

```text
APP_DESCRIPTION: A mobile app for transient boaters booking marina slips. Captains search marinas by draft, beam, and amenities, request slips for date ranges, pay dockage, and receive gate and Wi-Fi access details on arrival.
TECH_STACK: Flutter + Riverpod + a Serverpod backend on Postgres + Stripe payments + Mapbox SDK, deployed to App Store, Play Store, and a managed container host
APP_TYPE: mobile
LANGUAGE: Dart
SCALE: 400 participating marinas, ~20,000 boater accounts, seasonal booking peaks along popular cruising routes
```

## 34. StageStep — rehearsal blocking

```text
APP_DESCRIPTION: A tablet-first mobile app for theater directors and stage managers. It stores blocking notes tied to script lines, maps actor positions on a stage grid per scene, tracks cues, and generates rehearsal reports for the production team.
TECH_STACK: Flutter + Bloc + drift local store + PDF script import + Supabase production sync, deployed to App Store and Play Store for tablets
APP_TYPE: mobile
LANGUAGE: Dart
SCALE: 1,500 productions, casts of 5-40, real-time sync between director and stage-manager tablets
```

## 35. FieldFix — offline field-service work orders

```text
APP_DESCRIPTION: A mobile app for field technicians in areas with poor connectivity. Techs receive routed work orders, capture parts used, photos, and customer signatures offline, and the app syncs completed jobs and updates inventory when back online.
TECH_STACK: Flutter + Riverpod + drift offline queue + a Dart Frog dispatch API on Postgres + conflict-aware sync, deployed to App Store, Play Store, and Cloud Run
APP_TYPE: mobile
LANGUAGE: Dart
SCALE: 60 service companies, ~4,000 technicians, ~40 work orders per tech per week with offline-first sync
```

## 36. AisleAlly — accessible store navigation

```text
APP_DESCRIPTION: A mobile in-store navigation app for shoppers with visual impairments. It guides users aisle by aisle to items on their list using BLE beacons, announces nearby departments and offers, and supports full screen-reader and haptic navigation.
TECH_STACK: Flutter + Bloc + flutter_blue_plus beacon ranging + a Serverpod store-catalog backend on Postgres + platform accessibility APIs, deployed to App Store, Play Store, and a managed container host
APP_TYPE: mobile
LANGUAGE: Dart
SCALE: 3 pilot chains, stores with ~200 beacons each, sub-aisle positioning with accessibility-first UX
```

## 37. ScoutSnap — birdwatching life list

```text
APP_DESCRIPTION: A mobile birding companion. Birders log sightings with location, count, and audio, maintain a life list, get range-based species suggestions, and contribute observations to citizen-science datasets with offline capture in remote areas.
TECH_STACK: Flutter + Riverpod + drift offline log + eBird/GBIF integration + Supabase media Storage, shipped to App Store and Play Store
APP_TYPE: mobile
LANGUAGE: Dart
SCALE: 40,000 installs, life lists of thousands of records, offline field capture with later dataset upload
```

## 38. TransitTether — paratransit rider app

```text
APP_DESCRIPTION: A mobile app for paratransit riders with accessibility needs. Riders book door-to-door trips within eligibility windows, track the vehicle's live ETA, receive audio and haptic pickup alerts, and rate rides for the transit agency.
TECH_STACK: Flutter + Bloc + a Dart Frog booking backend on Postgres + PostGIS + real-time vehicle tracking via WebSockets + Firebase Cloud Messaging, deployed to App Store, Play Store, and a managed container host
APP_TYPE: mobile
LANGUAGE: Dart
SCALE: regional agency with ~120 vehicles, ~8,000 registered riders, live ETA updates every 15 seconds
```

## 39. ClipCanvas — screen-recording annotation studio

```text
APP_DESCRIPTION: A desktop studio for annotating screen recordings and screenshots. Users capture or import clips, add callouts, blur regions, trim segments, and export MP4 or animated GIF walkthroughs for support docs and bug reports.
TECH_STACK: Flutter desktop + Riverpod + FFI to native capture and FFmpeg encoding + drift project store, packaged as MSIX, DMG, and AppImage for Windows, macOS, and Linux
APP_TYPE: desktop
LANGUAGE: Dart
SCALE: single-user workstation app, clips up to 20 minutes, local export with no cloud dependency
```

## 40. MacroMint — double-entry personal ledger

```text
APP_DESCRIPTION: A desktop double-entry personal finance ledger for privacy-conscious users. It imports bank CSV and OFX files, applies rule-based categorization, reconciles accounts, and generates net-worth, cash-flow, and budget reports entirely offline.
TECH_STACK: Flutter desktop + Bloc + drift (SQLite) ledger + fl_chart reporting + local file import, packaged for Windows, macOS, and Linux
APP_TYPE: desktop
LANGUAGE: Dart
SCALE: single-user, decades of transaction history in a local encrypted database, <2 GB typical file size
```

## 41. NoteNimbus — markdown knowledge base

```text
APP_DESCRIPTION: A desktop markdown knowledge base with bidirectional links. Users write notes with wiki-links and tags, navigate a backlink graph, run full-text search, and keep everything in a local plain-text vault that syncs via their own file storage.
TECH_STACK: Flutter desktop + Riverpod + a local markdown vault + an SQLite FTS5 search index via drift, packaged for Windows, macOS, and Linux
APP_TYPE: desktop
LANGUAGE: Dart
SCALE: single-user vaults of 20,000+ notes, sub-100 ms full-text search, file-system-based sync
```

## 42. RenderRoost — batch image processing

```text
APP_DESCRIPTION: A desktop batch image processor for photographers. Users define pipelines of resize, watermark, format-convert, and metadata steps, preview on a sample, and process thousands of files in parallel with a progress dashboard.
TECH_STACK: Flutter desktop + Riverpod + Dart isolates for parallel processing + the image package and FFI to libvips, packaged for Windows, macOS, and Linux
APP_TYPE: desktop
LANGUAGE: Dart
SCALE: single-user, batches of 10,000+ images, parallel processing across all CPU cores
```

## 43. SubSculptor — subtitle editor

```text
APP_DESCRIPTION: A desktop subtitle editor for translators and video teams. It syncs captions to a waveform and video preview, supports SRT, VTT, and ASS formats, checks reading speed and overlap, and batch-shifts timing across a file.
TECH_STACK: Flutter desktop + Bloc + media_kit for video and waveform + drift project store, packaged for Windows, macOS, and Linux
APP_TYPE: desktop
LANGUAGE: Dart
SCALE: single-user, feature-length projects with thousands of cues, frame-accurate timing at 24-60 fps
```

## 44. PatchPylon — game mod manager

```text
APP_DESCRIPTION: A desktop mod manager for PC games. Players browse and install mods, resolve load-order and dependency conflicts, create isolated profiles per playthrough, and roll back to a known-good configuration after a bad update.
TECH_STACK: Flutter desktop + Riverpod + drift profile store + FFI archive extraction + mod-repository APIs, packaged as MSIX, DMG, and AppImage
APP_TYPE: desktop
LANGUAGE: Dart
SCALE: single-user, load orders of hundreds of mods, conflict resolution over multi-gigabyte game folders
```

## 45. TomeTailor — ebook library manager

```text
APP_DESCRIPTION: A desktop ebook library manager. It catalogs EPUB and PDF collections, fetches and edits metadata and covers, converts between formats, and sends books to e-readers over USB or a companion drop folder.
TECH_STACK: Flutter desktop + Bloc + drift catalog + an SQLite FTS index + FFI to a conversion library, packaged for Windows, macOS, and Linux
APP_TYPE: desktop
LANGUAGE: Dart
SCALE: single-user libraries of 50,000+ books, fast metadata search, batch format conversion
```

## 46. FlowForge — visual node pipeline editor

```text
APP_DESCRIPTION: A desktop node-based editor for building data-transformation pipelines. Users wire source, transform, and sink nodes on a canvas, preview intermediate results, run pipelines locally, and export them as portable config for headless execution.
TECH_STACK: Flutter desktop + Riverpod + a custom canvas engine + Dart isolates for node execution + drift graph store, packaged for Windows, macOS, and Linux
APP_TYPE: desktop
LANGUAGE: Dart
SCALE: single-user, graphs of hundreds of nodes, local execution over datasets up to a few GB
```

## 47. DeckDrafter — TCG deck builder and playtester

```text
APP_DESCRIPTION: A desktop deck builder and solo playtester for trading card games. Players build decks against a card database, validate against format legality, simulate opening hands and mulligans, and track statistics across goldfish test games.
TECH_STACK: Flutter desktop + Bloc + drift card database + a Dart rules-simulation engine + card-data API sync, packaged for Windows, macOS, and Linux
APP_TYPE: desktop
LANGUAGE: Dart
SCALE: single-user, card pools of 30,000+ cards, thousands of simulated draws for probability stats
```

## 48. SignScribe — receipt and label designer

```text
APP_DESCRIPTION: A desktop design tool for retail receipts, price labels, and shelf tags. Users lay out templates with barcodes and dynamic fields, bind them to a product CSV, preview, and print in bulk to thermal and label printers.
TECH_STACK: Flutter desktop + Riverpod + a barcode rendering library + FFI to native print drivers + drift template store, packaged for Windows and macOS
APP_TYPE: desktop
LANGUAGE: Dart
SCALE: single-store operator, catalogs of ~20,000 products, bulk print runs of thousands of labels
```

## 49. ChartChisel — CSV exploration and charting

```text
APP_DESCRIPTION: A desktop tool for quickly exploring CSV and Parquet files. Users load a file, filter and pivot without code, build charts by dragging fields, and export views as images or a shareable static report.
TECH_STACK: Flutter desktop + Bloc + Dart isolates for parsing + fl_chart rendering + FFI to a columnar reader, packaged for Windows, macOS, and Linux
APP_TYPE: desktop
LANGUAGE: Dart
SCALE: single-user, files up to 5 GB, interactive filtering over millions of rows via columnar loading
```

## 50. VaultVerge — offline password manager

```text
APP_DESCRIPTION: A desktop offline password manager. It stores credentials, TOTP seeds, and secure notes in a locally encrypted vault, autofills via a browser companion, audits for weak and reused passwords, and syncs through the user's own cloud folder.
TECH_STACK: Flutter desktop + Riverpod + an encrypted SQLite vault via drift + FFI to libsodium + a native browser-integration bridge, packaged for Windows, macOS, and Linux
APP_TYPE: desktop
LANGUAGE: Dart
SCALE: single-user, thousands of stored entries, zero-knowledge local encryption with user-controlled sync
```

## 51. StitchStudio — embroidery pattern designer

```text
APP_DESCRIPTION: A desktop designer for machine-embroidery patterns. Users import artwork, auto-digitize into stitches, edit stitch order and density, simulate the stitch-out, and export to formats their embroidery machines accept.
TECH_STACK: Flutter desktop + Bloc + a Dart stitch-generation engine + Dart isolates for path processing + drift project store, packaged for Windows and macOS
APP_TYPE: desktop
LANGUAGE: Dart
SCALE: single-user, designs with 100,000+ stitches, real-time stitch simulation preview
```

## 52. LoreLedger — tabletop RPG campaign manager

```text
APP_DESCRIPTION: A desktop campaign manager for tabletop RPG game masters. It organizes NPCs, locations, quests, and session notes with cross-links, tracks initiative and party state during play, and reveals prepared content to players on a second-screen view.
TECH_STACK: Flutter desktop + Riverpod + drift campaign store + a local WebSocket server for player second-screen, packaged for Windows, macOS, and Linux
APP_TYPE: desktop
LANGUAGE: Dart
SCALE: single-GM, campaigns with thousands of linked entries, live second-screen sync to players on the LAN
```

## 53. PixelPress — retro sprite and tilemap editor

```text
APP_DESCRIPTION: A desktop pixel-art and tilemap editor for retro game developers. Artists draw sprites with palette constraints, animate frames, assemble tilemaps with collision layers, and export sheets and map data for popular engines.
TECH_STACK: Flutter desktop + Bloc + a custom canvas engine + drift project store + JSON/PNG export, packaged for Windows, macOS, and Linux
APP_TYPE: desktop
LANGUAGE: Dart
SCALE: single-user, projects with hundreds of sprites and multi-layer maps, 60 fps canvas editing
```

## 54. MergeMason — three-way file diff and merge

```text
APP_DESCRIPTION: A desktop three-way diff and merge tool for developers. It compares base, local, and remote versions side by side, offers word-level highlighting, resolves conflicts with one-click choices, and integrates as a git merge and difftool.
TECH_STACK: Flutter desktop + Riverpod + a Dart diff engine + FFI to git plumbing + syntax highlighting, packaged for Windows, macOS, and Linux
APP_TYPE: desktop
LANGUAGE: Dart
SCALE: single-user, files up to tens of thousands of lines, near-instant word-level diffing
```

## 55. GrantGrove — nonprofit grant tracker

```text
APP_DESCRIPTION: A web app for nonprofits managing grants. Program staff track application deadlines, reporting requirements, and disbursement schedules, store funder documents, and generate board-ready pipeline and compliance reports.
TECH_STACK: Flutter web + Riverpod front end + a Serverpod backend on Postgres + object Storage for documents, deployed to a static host and a managed container host
APP_TYPE: web app
LANGUAGE: Dart
SCALE: 400 nonprofit tenants, ~2,500 staff users, ~50 concurrent users, <20 GB documents
```

## 56. RosterRise — volunteer scheduling

```text
APP_DESCRIPTION: A web app for coordinating volunteers at events and shelters. Coordinators post shifts with role requirements, volunteers self-schedule and swap, and the app tracks hours, sends reminders, and reports participation to funders.
TECH_STACK: Flutter web + Bloc + a Dart Frog backend on Postgres + Redis + email/SMS notifications, deployed to a static host and Cloud Run
APP_TYPE: web app
LANGUAGE: Dart
SCALE: 600 organizations, ~40,000 volunteers, event-day peaks of ~200 concurrent schedulers
```

## 57. ClinicCompass — patient intake

```text
APP_DESCRIPTION: A web app for small clinics handling patient intake. Patients complete digital forms and consent before visits, staff review and push data to the EHR, and the app manages check-in queues and no-show follow-ups.
TECH_STACK: Flutter web + Riverpod + a Serverpod backend on Postgres + FHIR export + audit logging, deployed to a HIPAA-eligible container host behind a static front end
APP_TYPE: web app
LANGUAGE: Dart
SCALE: 120 clinics, ~1,500 staff, ~80 concurrent users at peak, HIPAA-aligned handling of PHI
```

## 58. StallStream — farmers-market vendor manager

```text
APP_DESCRIPTION: A web app for farmers-market organizers. It manages vendor applications and stall assignments, collects fees, tracks product categories to balance the market mix, and publishes a public vendor map and schedule.
TECH_STACK: Flutter web + Bloc + a Dart Frog backend on Postgres + Stripe payments + a public Flutter web map, deployed to a static host and Cloud Run
APP_TYPE: web app
LANGUAGE: Dart
SCALE: 300 markets, ~12,000 vendors, seasonal application surges with ~100 concurrent organizers
```

## 59. TuneTribe — indie music release planner

```text
APP_DESCRIPTION: A web app for independent musicians planning releases. Artists build release timelines, track distributor and playlist submissions, coordinate assets with collaborators, and monitor pre-save and streaming milestones from one board.
TECH_STACK: Flutter web + Riverpod + a Serverpod backend on Postgres + object Storage for assets + streaming-platform API integrations, deployed to a static host and a managed container host
APP_TYPE: web app
LANGUAGE: Dart
SCALE: 8,000 artist accounts, collaborative teams of 2-8, ~120 concurrent users
```

## 60. DeskDrift — hot-desk booking

```text
APP_DESCRIPTION: A web app for hybrid offices managing hot-desks and meeting rooms. Employees book desks on an interactive floor plan, see team presence, check in via QR on arrival, and facilities admins analyze utilization to right-size space.
TECH_STACK: Flutter web + Bloc + a Dart Frog backend on Postgres + Redis + SSO integration, deployed to a static host and Cloud Run
APP_TYPE: web app
LANGUAGE: Dart
SCALE: 150 employer tenants, ~30,000 employees, morning booking peaks of ~400 concurrent users
```

## 61. LedgerLoom — HOA dues and maintenance

```text
APP_DESCRIPTION: A web app for homeowners associations. Boards track dues and payments, manage maintenance requests and vendor bids, publish announcements and documents, and residents pay online and view their account history.
TECH_STACK: Flutter web + Riverpod + a Serverpod backend on Postgres + Stripe billing + object Storage for documents, deployed to a static host and a managed container host
APP_TYPE: web app
LANGUAGE: Dart
SCALE: 500 associations, ~60,000 households, ~60 concurrent users, monthly dues billing cycles
```

## 62. CourseCrafter — micro-course builder

```text
APP_DESCRIPTION: A web app for creators building short online courses. Authors assemble lessons with video, text, and quizzes, drip-release modules, track learner progress and completion, and issue certificates on finish.
TECH_STACK: Flutter web + Bloc + a Serverpod backend on Postgres + Mux/Cloudflare video + Stripe payments, deployed to a static host and a managed container host
APP_TYPE: web app
LANGUAGE: Dart
SCALE: 5,000 creators, ~200,000 learners, ~300 concurrent learners at peak
```

## 63. PollPeak — live audience Q&A and polling

```text
APP_DESCRIPTION: A web app for live event audience engagement. Presenters run polls, word clouds, and moderated Q&A; attendees join with a code from any device, upvote questions, and results update on the big screen in real time.
TECH_STACK: Flutter web + Riverpod + a Dart Frog backend with WebSockets on Postgres and Redis, deployed to a static host and a managed container host with horizontal scaling
APP_TYPE: web app
LANGUAGE: Dart
SCALE: events up to 10,000 attendees, ~600 req/sec vote bursts, sub-second result broadcast via WebSockets
```

## 64. CrateChorus — vinyl shop inventory

```text
APP_DESCRIPTION: A web app for independent record shops. Staff catalog inventory by pressing and condition, sync stock to an online storefront and marketplaces, process in-store and web sales, and surface restock and pricing insights.
TECH_STACK: Flutter web + Bloc + a Serverpod backend on Postgres + Discogs API + Stripe payments, deployed to a static host and a managed container host
APP_TYPE: web app
LANGUAGE: Dart
SCALE: 200 shops, catalogs of ~50,000 records each, ~40 concurrent staff and storefront sessions
```

## 65. BrandBoard — design asset review and approval

```text
APP_DESCRIPTION: A web app for creative teams reviewing design assets. Reviewers leave pinned comments on images, videos, and PDFs, compare versions, run approval workflows with sign-off, and hand off approved assets to stakeholders.
TECH_STACK: Flutter web + Riverpod + a Serverpod backend on Postgres + object Storage + real-time comments over WebSockets, deployed to a static host and a managed container host
APP_TYPE: web app
LANGUAGE: Dart
SCALE: 1,200 agency teams, ~25,000 users, ~150 concurrent reviewers, large media assets in object storage
```

## 66. SlotSprocket — equipment rental booking

```text
APP_DESCRIPTION: A web app for equipment rental businesses. Customers browse availability, book gear for date ranges, and pay deposits; staff manage inventory, check-in and check-out condition, and overdue and damage tracking.
TECH_STACK: Flutter web + Bloc + a Dart Frog backend on Postgres + Redis availability cache + Stripe payments, deployed to a static host and Cloud Run
APP_TYPE: web app
LANGUAGE: Dart
SCALE: 300 rental businesses, ~200,000 SKUs total, ~80 concurrent bookings, availability calc across date ranges
```

## 67. WardWatch — hospital bed management

```text
APP_DESCRIPTION: A web app for hospital bed and patient-flow coordination. Charge nurses see live bed status by ward, manage admissions, transfers, and discharges, flag isolation and cleaning needs, and track time-to-placement for the flow team.
TECH_STACK: Flutter web + Riverpod + a Serverpod backend on Postgres + real-time status over WebSockets + HL7/FHIR feeds, deployed to a hospital-hosted container platform behind a static front end
APP_TYPE: web app
LANGUAGE: Dart
SCALE: 400-bed hospital, ~500 staff users, ~120 concurrent users, live bed-status updates within seconds
```

## 68. FormFathom — dynamic form builder

```text
APP_DESCRIPTION: A web app for building and publishing dynamic forms. Authors drag fields, add conditional logic and validation, publish as embeddable or hosted forms, collect responses, and export or webhook submissions to other systems.
TECH_STACK: Flutter web + Bloc + a Dart Frog backend on Postgres + Redis + a lightweight embeddable renderer, deployed to a static host and Cloud Run
APP_TYPE: web app
LANGUAGE: Dart
SCALE: 6,000 authors, ~2M submissions/month, ~250 concurrent respondents at campaign peaks
```

## 69. PulsePort — wearable telemetry ingestion API

```text
APP_DESCRIPTION: An API service that ingests high-frequency telemetry from fitness wearables. It accepts batched heart-rate, GPS, and activity streams, validates and deduplicates readings, computes rollups, and exposes query endpoints for partner apps.
TECH_STACK: Dart Frog + Postgres with TimescaleDB + Redis + Kafka ingestion, containerized on Kubernetes
APP_TYPE: API service
LANGUAGE: Dart
SCALE: 200,000 devices, ~40,000 req/sec ingest at peak, 90-day hot retention of time-series data
```

## 70. ScanSluice — document OCR pipeline API

```text
APP_DESCRIPTION: An API service that turns uploaded documents into structured data. Clients submit PDFs and images, the service runs OCR and layout extraction asynchronously, returns fields and tables via callback, and stores results for retrieval.
TECH_STACK: Dart shelf + a job queue on Redis + Postgres + object Storage + FFI to a native OCR engine, containerized on a managed container host
APP_TYPE: API service
LANGUAGE: Dart
SCALE: ~500,000 documents/day, async processing with p95 under 30 seconds per page, autoscaling workers
```

## 71. GeoGird — geofencing and proximity events API

```text
APP_DESCRIPTION: An API service that emits events when tracked entities enter or leave defined zones. Clients register geofences and push location updates; the service evaluates crossings, debounces noise, and delivers enter/exit webhooks in near real time.
TECH_STACK: Dart Frog + Postgres with PostGIS + Redis geospatial index + webhook delivery with retries, containerized on Kubernetes
APP_TYPE: API service
LANGUAGE: Dart
SCALE: 2M tracked entities, ~25,000 location updates/sec, geofence evaluation with sub-second event delivery
```

## 72. TokenTrellis — feature-flag and config service

```text
APP_DESCRIPTION: An API service for feature flags and remote configuration. Teams define flags with targeting rules and rollouts, SDKs fetch and stream evaluated values, and the service records exposure events for experiment analysis.
TECH_STACK: Dart Frog + Postgres + Redis pub/sub for streaming + a CDN edge cache, containerized on Kubernetes
APP_TYPE: API service
LANGUAGE: Dart
SCALE: 800 client apps, ~60,000 flag-evaluation req/sec, streaming config updates propagated in under a second
```

## 73. NudgeNexus — multi-channel notification gateway

```text
APP_DESCRIPTION: An API service that unifies push, email, and SMS delivery. Applications send a single notification request with user preferences and channel fallbacks; the gateway routes to providers, respects quiet hours and rate limits, and tracks delivery status.
TECH_STACK: Dart shelf + Postgres + Redis + a queue with provider adapters (FCM, APNs, SES, Twilio), containerized on a managed container host
APP_TYPE: API service
LANGUAGE: Dart
SCALE: ~10M notifications/day, ~8,000 req/sec at peak, per-tenant rate limiting and delivery tracking
```

## 74. LedgerLatch — double-entry accounting API

```text
APP_DESCRIPTION: An API service providing double-entry accounting primitives for fintech apps. Clients post immutable journal entries, the service enforces balanced transactions, computes account balances and trial balances, and exposes an auditable transaction log.
TECH_STACK: Dart Frog + Postgres with serializable transactions + an append-only event log + Redis balance cache, containerized on Kubernetes
APP_TYPE: API service
LANGUAGE: Dart
SCALE: 50M accounts, ~5,000 posted transactions/sec, strict consistency with a full immutable audit trail
```

## 75. SwarmSocket — realtime presence and chat backend

```text
APP_DESCRIPTION: An API and WebSocket backend for in-app chat and presence. It manages channels and membership, fans out messages with delivery receipts, tracks online presence and typing indicators, and persists history for replay on reconnect.
TECH_STACK: Dart Frog with WebSockets + Postgres + Redis pub/sub for fan-out + object Storage for attachments, containerized on Kubernetes with horizontal scaling
APP_TYPE: API service
LANGUAGE: Dart
SCALE: 1M concurrent connections, ~50,000 messages/sec at peak, presence fan-out across sharded nodes
```

## 76. QuotaQuay — API metering and rate limiting

```text
APP_DESCRIPTION: An API service that meters usage and enforces plan limits for API providers. It counts requests per key and dimension, enforces token-bucket and sliding-window limits at the edge, emits overage events, and exposes usage for billing.
TECH_STACK: Dart shelf + Redis for counters + Postgres for plans and aggregates + a Kafka usage stream, containerized on Kubernetes
APP_TYPE: API service
LANGUAGE: Dart
SCALE: 3,000 API tenants, ~80,000 metering decisions/sec, sub-millisecond limit checks at the edge
```

## 77. VaultVane — secrets brokering service

```text
APP_DESCRIPTION: An API service that brokers short-lived secrets to workloads. Services authenticate with workload identity, request scoped credentials, and receive time-bound secrets; the broker rotates backing secrets, logs every issuance, and revokes on demand.
TECH_STACK: Dart Frog + Postgres + a KMS/HSM integration + mTLS between workloads, containerized on Kubernetes
APP_TYPE: API service
LANGUAGE: Dart
SCALE: 5,000 workloads, ~2,000 secret issuances/sec, short-lived credentials with full issuance audit logging
```

## 78. MeshMuster — IoT device registry and command API

```text
APP_DESCRIPTION: An API service that registers IoT devices and dispatches commands. Devices enroll and report state over MQTT; the service maintains a device shadow, queues commands for offline devices, and exposes fleet query and control endpoints.
TECH_STACK: Dart shelf + an MQTT broker bridge + Postgres device registry + Redis shadow cache, containerized on Kubernetes
APP_TYPE: API service
LANGUAGE: Dart
SCALE: 500,000 devices, ~30,000 state reports/sec, command queuing for intermittently connected fleets
```

## 79. RouteRibbon — last-mile delivery dispatch API

```text
APP_DESCRIPTION: An API service for last-mile delivery dispatch. It accepts orders, batches and optimizes multi-stop routes, assigns drivers, tracks live progress, and exposes ETA and proof-of-delivery endpoints for the ordering app.
TECH_STACK: Dart Frog + Postgres with PostGIS + Redis + a routing engine integration + WebSocket driver tracking, containerized on Kubernetes
APP_TYPE: API service
LANGUAGE: Dart
SCALE: 200 delivery hubs, ~150,000 deliveries/day, route optimization for fleets of thousands of drivers
```

## 80. TicketTide — helpdesk ticketing backend

```text
APP_DESCRIPTION: An API service powering helpdesk ticketing. It ingests tickets from email, chat, and API, applies routing and SLA rules, tracks status and assignment, threads conversations, and exposes reporting on resolution metrics.
TECH_STACK: Dart Frog + Postgres + Redis + an inbound email parser + webhook integrations, containerized on a managed container host
APP_TYPE: API service
LANGUAGE: Dart
SCALE: 1,000 support tenants, ~2M tickets/month, ~3,000 req/sec at peak with SLA timer evaluation
```

## 81. FeedFerry — RSS and podcast aggregation API

```text
APP_DESCRIPTION: An API service that aggregates and normalizes RSS and podcast feeds. It polls thousands of sources on adaptive schedules, deduplicates and enriches items, detects new episodes, and serves unified, paginated feeds to client apps.
TECH_STACK: Dart shelf + Postgres + Redis + Dart isolates for parallel polling + object Storage for enclosures, containerized on a managed container host
APP_TYPE: API service
LANGUAGE: Dart
SCALE: 200,000 tracked feeds, adaptive polling with ~10,000 fetches/min, deduplicated delivery to clients
```

## 82. StockStile — multichannel inventory sync

```text
APP_DESCRIPTION: An API service that keeps product inventory consistent across sales channels. It reconciles stock from a warehouse system to marketplaces and storefronts, prevents oversells with reservations, and emits low-stock and sync-conflict events.
TECH_STACK: Dart Frog + Postgres + Redis reservation locks + channel adapters (Shopify, Amazon) + a Kafka event stream, containerized on Kubernetes
APP_TYPE: API service
LANGUAGE: Dart
SCALE: 2,000 merchants, ~5M SKUs, ~10,000 stock updates/sec during sales, near-real-time cross-channel sync
```

## 83. AuthAnchor — passwordless auth service

```text
APP_DESCRIPTION: An API service providing passwordless authentication. It issues magic links and one-time codes, supports passkeys and social login, manages sessions and refresh tokens, and enforces device and risk-based step-up challenges.
TECH_STACK: Dart Frog + Postgres + Redis session store + WebAuthn support + email/SMS delivery, containerized on Kubernetes
APP_TYPE: API service
LANGUAGE: Dart
SCALE: 3,000 client apps, ~40M end users, ~20,000 auth req/sec at peak, passkey and risk-based flows
```

## 84. PricePloom — dynamic pricing engine

```text
APP_DESCRIPTION: An API service that computes dynamic prices from rules and signals. Clients define pricing strategies over demand, inventory, and competitor inputs; the engine evaluates them per request, returns prices with explanations, and logs decisions for audit.
TECH_STACK: Dart Frog + Postgres + Redis feature cache + a rules evaluation engine + a Kafka decision log, containerized on Kubernetes
APP_TYPE: API service
LANGUAGE: Dart
SCALE: 500 merchants, ~3M priced SKUs, ~15,000 price evaluations/sec, auditable per-decision logging
```

## 85. ClaimCurrent — insurance claim intake API

```text
APP_DESCRIPTION: An API service for insurance claim intake and triage. It validates first-notice-of-loss submissions, attaches documents and photos, runs fraud and completeness checks, routes to adjusters by rules, and exposes claim status endpoints.
TECH_STACK: Dart shelf + Postgres + object Storage + a rules engine + async document processing on Redis queues, containerized on a compliant container host
APP_TYPE: API service
LANGUAGE: Dart
SCALE: 40 insurer tenants, ~200,000 claims/month, ~2,000 req/sec at peak, audited PII-handling workflows
```

## 86. MatchMarrow — marketplace matching engine

```text
APP_DESCRIPTION: An API service that matches supply and demand in a two-sided marketplace. It scores candidates against constraints and preferences, ranks matches, handles concurrent claiming without double-booking, and emits match and expiry events.
TECH_STACK: Dart Frog + Postgres + Redis for locking and ranking cache + a scoring engine + a Kafka event stream, containerized on Kubernetes
APP_TYPE: API service
LANGUAGE: Dart
SCALE: 1M active participants, ~10,000 match requests/sec, concurrency-safe claiming under high contention
```

## 87. dartsweep — dependency and license auditor CLI

```text
APP_DESCRIPTION: A command-line tool that audits Dart and Flutter projects for dependency risk. It resolves the full package graph, flags outdated, deprecated, and vulnerable packages, checks license compatibility against a policy, and outputs a report for CI gating.
TECH_STACK: Dart CLI with the args and pub_semver packages + pub.dev and OSV API queries + JSON and SARIF output, distributed via pub global and a compiled native binary
APP_TYPE: CLI
LANGUAGE: Dart
SCALE: single-developer and CI use, dependency graphs of thousands of packages, full audit in under 10 seconds
```

## 88. schemashift — database migration runner CLI

```text
APP_DESCRIPTION: A command-line database migration runner. It applies and rolls back versioned SQL and Dart migrations, tracks applied state in a migrations table, supports dry-run diffs, and guards production runs with checksums and locks.
TECH_STACK: Dart CLI + the postgres and mysql1 drivers + a migration lock table + args-based commands, distributed via pub global and compiled binaries
APP_TYPE: CLI
LANGUAGE: Dart
SCALE: single-user and CI/CD use, hundreds of migrations per project, advisory-locked concurrent-safe runs
```

## 89. mockmint — API mock server generator CLI

```text
APP_DESCRIPTION: A command-line tool that spins up mock API servers from OpenAPI specs. It generates example responses, supports stateful scenarios and latency injection, records real traffic to build fixtures, and runs as a local server for front-end development.
TECH_STACK: Dart CLI + shelf mock server + an OpenAPI parser + a scenario config format, distributed via pub global and compiled binaries
APP_TYPE: CLI
LANGUAGE: Dart
SCALE: single-developer use, specs with hundreds of endpoints, local mock server handling thousands of req/sec
```

## 90. logloom — structured log tail and filter CLI

```text
APP_DESCRIPTION: A command-line tool for tailing and querying structured logs. It parses JSON and logfmt streams, filters and highlights by field expressions, follows files and stdin live, and pretty-prints or re-emits compact output for piping.
TECH_STACK: Dart CLI reading stdin and files + a streaming JSON parser + a filter expression evaluator + ANSI output, distributed via pub global and compiled binaries
APP_TYPE: CLI
LANGUAGE: Dart
SCALE: single-user use, log streams of hundreds of thousands of lines/sec, constant-memory streaming
```

## 91. envelope — .env validation and secret scan CLI

```text
APP_DESCRIPTION: A command-line tool that validates environment configuration. It checks .env files against a declared schema, flags missing or malformed variables, scans staged changes for accidentally committed secrets, and blocks unsafe commits in a git hook.
TECH_STACK: Dart CLI + a schema DSL + entropy and pattern-based secret detection + git integration, distributed via pub global and compiled binaries
APP_TYPE: CLI
LANGUAGE: Dart
SCALE: single-developer and CI use, repositories with hundreds of config keys, pre-commit scan in under a second
```

## 92. gitglyph — repo stats and changelog generator CLI

```text
APP_DESCRIPTION: A command-line tool that generates changelogs and contribution stats from git history. It parses conventional commits, groups changes by type since the last tag, computes per-author and churn metrics, and writes release notes and a stats summary.
TECH_STACK: Dart CLI + FFI or shell to git plumbing + a conventional-commit parser + Markdown output, distributed via pub global and compiled binaries
APP_TYPE: CLI
LANGUAGE: Dart
SCALE: single-user and CI use, repositories with 100,000+ commits, changelog generation in a few seconds
```

## 93. snapship — release artifact packager CLI

```text
APP_DESCRIPTION: A command-line tool that packages and publishes release artifacts. It builds cross-platform binaries, computes checksums and SBOMs, signs artifacts, generates release notes, and uploads to GitHub Releases and package registries in one command.
TECH_STACK: Dart CLI + dart compile for native builds + registry and GitHub API clients + signing integration, distributed via pub global and compiled binaries
APP_TYPE: CLI
LANGUAGE: Dart
SCALE: single-maintainer and CI use, multi-platform release matrices, full package-and-publish in one run
```

## 94. l10nlift — localization sync CLI

```text
APP_DESCRIPTION: A command-line tool that keeps app localization in sync. It extracts strings from Dart and Flutter sources, syncs ARB files with a translation service, flags missing and stale keys, and validates placeholder consistency across locales.
TECH_STACK: Dart CLI + an ARB parser + translation-management API clients + placeholder validation, distributed via pub global and compiled binaries
APP_TYPE: CLI
LANGUAGE: Dart
SCALE: single-team and CI use, projects with thousands of keys across dozens of locales, full sync in seconds
```

## 95. covcarve — coverage report differ CLI

```text
APP_DESCRIPTION: A command-line tool that analyzes and diffs code coverage. It parses LCOV reports, computes coverage on changed lines in a pull request, enforces per-diff thresholds, and posts an annotated summary to fail CI when new code is untested.
TECH_STACK: Dart CLI + an LCOV parser + git diff integration + CI annotation output, distributed via pub global and compiled binaries
APP_TYPE: CLI
LANGUAGE: Dart
SCALE: single-project and CI use, codebases of hundreds of thousands of lines, per-PR diff coverage in seconds
```

## 96. flutterfarm — project scaffolding CLI

```text
APP_DESCRIPTION: A command-line scaffolding tool for Flutter and Dart projects. It generates apps and packages from templates with chosen state management, routing, and CI wired in, adds features from bricks, and enforces a consistent structure across a team's repos.
TECH_STACK: Dart CLI built on Mason + template bricks + interactive prompts + post-gen hooks, distributed via pub global and compiled binaries
APP_TYPE: CLI
LANGUAGE: Dart
SCALE: team-wide use, template catalogs of dozens of bricks, full project generation in under 5 seconds
```

## 97. pubprowl — package health CLI

```text
APP_DESCRIPTION: A command-line tool that reports on the health of pub.dev packages. It queries popularity, maintenance, and platform-support scores, checks null-safety and latest-version status, compares alternatives, and produces a ranked report for dependency selection.
TECH_STACK: Dart CLI + the pub.dev API + a local response cache + table and JSON output, distributed via pub global and compiled binaries
APP_TYPE: CLI
LANGUAGE: Dart
SCALE: single-developer use, comparisons across dozens of candidate packages, cached lookups for fast reruns
```

## 98. StreamSilt — clickstream ETL pipeline

```text
APP_DESCRIPTION: A data pipeline that transforms raw web and app clickstream events into analytics-ready tables. It consumes events from a queue, sessionizes and enriches them, deduplicates late arrivals, and writes partitioned outputs to the warehouse for BI.
TECH_STACK: Dart worker services using Dart isolates + a Kafka consumer + Postgres staging + Parquet writes to object Storage + a warehouse loader, containerized on Kubernetes
APP_TYPE: data pipeline
LANGUAGE: Dart
SCALE: ~200,000 events/sec ingest, hourly batch materialization, ~2 TB/day into the warehouse
```

## 99. HarvestHopper — IoT sensor rollup pipeline

```text
APP_DESCRIPTION: A data pipeline for agricultural IoT sensor data. It ingests soil, weather, and irrigation readings, validates and gap-fills series, computes per-field hourly and daily rollups, and publishes aggregates for dashboards and alerting.
TECH_STACK: Dart worker services + Dart isolates for parallel aggregation + an MQTT/Kafka source + Postgres with TimescaleDB sink, containerized on a managed container host
APP_TYPE: data pipeline
LANGUAGE: Dart
SCALE: 50,000 sensors, ~15,000 readings/sec, hourly rollups with 1-year retention of aggregates
```

## 100. LedgerLift — nightly financial reconciliation pipeline

```text
APP_DESCRIPTION: A data pipeline that reconciles financial records nightly. It pulls transactions from payment processors, bank feeds, and the internal ledger, matches them by rules and tolerances, flags discrepancies for review, and produces a reconciliation report and audit trail.
TECH_STACK: Dart batch workers with isolates + Postgres staging + object Storage for source files + a matching-rules engine, orchestrated as a scheduled job on a managed container host
APP_TYPE: data pipeline
LANGUAGE: Dart
SCALE: ~5M transactions/night, single nightly run within a 2-hour window, full audit trail of match decisions
```
