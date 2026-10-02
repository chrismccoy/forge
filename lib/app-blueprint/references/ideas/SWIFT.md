# Swift Blueprint Types — Copy-Paste Input Sets

Copy a fenced block into the prompt as-is, or swap individual fields.

## 1. StillMind — meditation and sleep app

```text
APP_DESCRIPTION: A meditation and sleep-sounds iOS app for stressed professionals. Users follow guided meditation programs with progress tracking, mix ambient sleep soundscapes with timers, log mood before/after sessions, and build streaks with gentle reminders — content downloadable for offline use.
TECH_STACK: Swift (SwiftUI) + Core Data + AVFoundation audio engine + StoreKit 2 subscriptions + CloudKit sync
APP_TYPE: mobile
LANGUAGE: Swift
SCALE: 40,000 MAU, 2,000 concurrent evening peak, ~2 GB cloud data per user cohort
```

## 2. HomeVault — home inventory for insurance

```text
APP_DESCRIPTION: A home-inventory iOS app for homeowners documenting possessions for insurance. Users photograph rooms and items with value estimates and receipts, organize by room and category, export insurer-ready PDF inventories, and store everything encrypted with private cloud backup.
TECH_STACK: Swift (SwiftUI) + Core Data + CloudKit private database + Vision framework for receipt OCR + PDF generation
APP_TYPE: mobile
LANGUAGE: Swift
SCALE: 10,000 MAU, single-user data model, ~5 GB media per active user
```

## 3. RidgeLog — hiking trail log

```text
APP_DESCRIPTION: A trail-logging iOS app for hikers. Hikers record GPS tracks with elevation profiles even offline, attach photos and condition notes to waypoints, maintain a lifetime peak/trail log with stats, and share GPX exports — offline topo map packs cover no-signal wilderness areas.
TECH_STACK: Swift (SwiftUI) + Core Location/HealthKit + MapKit with offline tile packs + Core Data + GPX import/export
APP_TYPE: mobile
LANGUAGE: Swift
SCALE: 25,000 MAU, heavy offline use, ~8 GB map/track data per device max
```

## 4. BarTime — menu-bar time tracker

```text
APP_DESCRIPTION: A macOS menu-bar time-tracking desktop app for consultants. Users start/stop timers per client project from the menu bar, get idle-detection prompts and calendar-aware suggestions, review weekly timesheets, and export billable-hours CSVs for invoicing tools.
TECH_STACK: Swift (SwiftUI + AppKit menu-bar integration) + Core Data local store + EventKit calendar access + CSV export
APP_TYPE: desktop
LANGUAGE: Swift
SCALE: single user, local data <1 GB
```

## 5. PushPilot — notification scheduling API

```text
APP_DESCRIPTION: A push-notification scheduling API service for small app studios. Studio backends register device tokens and audience segments, schedule one-off and recurring campaigns with per-timezone delivery windows, and get delivery/open analytics — the service handles APNs/FCM fan-out, retries, and token hygiene.
TECH_STACK: Swift (Vapor) + PostgreSQL + Redis queues + APNs/FCM providers, deployed on AWS ECS
APP_TYPE: API service
LANGUAGE: Swift
SCALE: ~600 req/sec during campaign fan-out, 30 studio clients, 8M device tokens, ~20 GB data
```

## 6. PelotonPals — cycling club tracker

```text
APP_DESCRIPTION: A club ride-tracking iOS app for local cycling clubs. Members RSVP to scheduled group rides with route previews, record rides with live group location sharing for regrouping, log personal stats and club leaderboards, and ride captains manage no-drop sweep lists.
TECH_STACK: Swift (SwiftUI) + Core Location + MapKit + CloudKit shared databases + HealthKit integration
APP_TYPE: mobile
LANGUAGE: Swift
SCALE: 5,000 MAU across 200 clubs, 400 concurrent during weekend rides, ~10 GB data
```

## 7. FrondKeeper — houseplant care companion

```text
APP_DESCRIPTION: A houseplant-care iOS app for urban plant collectors. Users catalog plants with photos and species profiles, get watering/fertilizing/repotting schedules tuned to season and pot size, diagnose leaf problems from photos, and track growth with a timeline per plant.
TECH_STACK: Swift (SwiftUI) + Core Data + CloudKit sync + Vision/Core ML leaf-issue classifier + local notifications
APP_TYPE: mobile
LANGUAGE: Swift
SCALE: 60,000 MAU, ~35 plants per active user, ~1 GB photo data per user
```

## 8. NestlingLog — newborn feeding and sleep tracker

```text
APP_DESCRIPTION: A newborn-tracking iOS app for new parents. Parents log feeds, diapers, sleep windows, and pumping sessions with one-tap timers, sync in real time between both caregivers' phones, spot emerging nap patterns on charts, and export pediatrician-ready summaries for checkups.
TECH_STACK: Swift (SwiftUI) + CloudKit shared database for two-caregiver sync + Core Data + Swift Charts + WidgetKit lock-screen widgets
APP_TYPE: mobile
LANGUAGE: Swift
SCALE: 80,000 MAU, ~40 log events per baby per day, 12-month typical retention window
```

## 9. LinguaSprout — vocabulary games for kids

```text
APP_DESCRIPTION: A language-learning iPad app teaching Spanish and French vocabulary to children aged 5–9. Kids play picture-matching and pronunciation mini-games with speech feedback, unlock story chapters as rewards, and parents get progress reports per word family — fully playable offline for car trips.
TECH_STACK: Swift (SwiftUI + SpriteKit mini-games) + Speech framework pronunciation scoring + Core Data + StoreKit 2 parental-gated purchases
APP_TYPE: mobile
LANGUAGE: Swift
SCALE: 30,000 MAU, 15-minute average sessions, ~600 MB bundled audio/asset content
```

## 10. CorkCellar — wine cellar manager

```text
APP_DESCRIPTION: A wine-cellar iOS app for home collectors. Users scan labels to auto-fill bottle details, track cellar locations and drink-by windows, log tasting notes with ratings, and get alerts when bottles enter peak maturity — cellar value tracked against purchase price.
TECH_STACK: Swift (SwiftUI) + Vision label recognition + Core Data + CloudKit private database + WidgetKit cellar-stats widget
APP_TYPE: mobile
LANGUAGE: Swift
SCALE: 12,000 MAU, ~250 bottles per active cellar, ~2 GB label imagery total
```

## 11. StrideCue — interval running coach for watchOS

```text
APP_DESCRIPTION: An Apple Watch–first interval-running coach for recreational runners chasing a first 10K. Runners follow structured workout plans with haptic pace cues on the wrist, phone-free workout playback, auto-logged splits into a training calendar, and adaptive plan adjustments after missed sessions.
TECH_STACK: Swift (SwiftUI for watchOS + iOS companion) + WorkoutKit/HealthKit + Core Location + WatchConnectivity + CloudKit sync
APP_TYPE: mobile
LANGUAGE: Swift
SCALE: 45,000 MAU, 3 workouts per user per week, 5,000 concurrent Saturday-morning sessions
```

## 12. PlumeList — birdwatching life list

```text
APP_DESCRIPTION: A birdwatching iOS app for hobbyist birders. Birders log sightings with location, weather, and photos, identify calls with on-device audio recognition, maintain life/year/county lists with milestone badges, and browse seasonal arrival forecasts for local hotspots.
TECH_STACK: Swift (SwiftUI) + Core ML/SoundAnalysis call identification + Core Location + MapKit + Core Data + CloudKit sync
APP_TYPE: mobile
LANGUAGE: Swift
SCALE: 20,000 MAU, spring-migration peak 3x baseline, ~900 species reference database
```

## 13. RoomRuler — AR room measurement

```text
APP_DESCRIPTION: An AR measurement iOS app for renters and interior decorators. Users scan rooms with LiDAR to capture wall dimensions and floor plans, place true-to-scale furniture bounding boxes to test fit before buying, annotate outlets and radiators, and export dimensioned floor-plan PDFs.
TECH_STACK: Swift (SwiftUI + ARKit/RoomPlan + RealityKit) + LiDAR scene capture + PDF/USDZ export + Core Data project storage
APP_TYPE: mobile
LANGUAGE: Swift
SCALE: 35,000 MAU, ~6 room scans per project, ~300 MB scan data per project
```

## 14. GlucoGlance — diabetes logging companion

```text
APP_DESCRIPTION: A diabetes self-management iOS app for adults with type 2 diabetes. Users log glucose readings, meals with carb estimates, medication doses, and activity; see time-in-range trends and A1C projections; and share clinician-ready reports before endocrinology visits.
TECH_STACK: Swift (SwiftUI) + HealthKit glucose/activity integration + Core Data + Swift Charts + encrypted CloudKit backup + PDF report export
APP_TYPE: mobile
LANGUAGE: Swift
SCALE: 50,000 MAU, ~10 logged events per user per day, 7-year data retention
```

## 15. LadleBox — family recipe box and meal planner

```text
APP_DESCRIPTION: A recipe-keeping and meal-planning iOS app for home cooks. Users clip recipes from the web or scan handwritten family cards with OCR, plan a weekly dinner calendar, auto-build aisle-sorted grocery lists, and share the family recipe box with relatives.
TECH_STACK: Swift (SwiftUI) + VisionKit document scanning + Core Data + CloudKit shared database + web-clipper share extension
APP_TYPE: mobile
LANGUAGE: Swift
SCALE: 70,000 MAU, ~120 recipes per household, Sunday-evening planning peak of 6,000 concurrent
```

## 16. TorqueBook — car maintenance log

```text
APP_DESCRIPTION: A vehicle-maintenance iOS app for DIY car owners with multiple vehicles. Owners log oil changes, brake jobs, and repairs with mileage and receipt photos, get service reminders based on interval or odometer, track cost-per-mile per vehicle, and export full service histories when selling.
TECH_STACK: Swift (SwiftUI) + Core Data + CloudKit private database + Vision receipt capture + local notification scheduling
APP_TYPE: mobile
LANGUAGE: Swift
SCALE: 28,000 MAU, average 2.4 vehicles per user, ~15 years of records per long-term user
```

## 17. FretHabit — guitar practice tracker

```text
APP_DESCRIPTION: A guitar-practice iOS app for self-taught players. Players run structured practice sessions with a metronome and looped backing tracks, log tempo progress per exercise, get a chromatic tuner with alternate tunings, and watch their clean-take speed climb on per-song charts.
TECH_STACK: Swift (SwiftUI) + AVFoundation/AudioKit tuner and metronome DSP + Core Data + Swift Charts + StoreKit 2
APP_TYPE: mobile
LANGUAGE: Swift
SCALE: 22,000 MAU, 25-minute median practice session, ~4,000 concurrent evening peak
```

## 18. CreelMate — fishing catch log

```text
APP_DESCRIPTION: A fishing-log iOS app for freshwater anglers. Anglers record catches with species, length/weight, lure, and photo; pin spots on a private map with depth and structure notes; review solunar and barometric-pressure overlays for planning; and keep spot data fully private and offline-capable.
TECH_STACK: Swift (SwiftUI) + Core Location + MapKit offline regions + Core Data + WeatherKit + CloudKit private sync
APP_TYPE: mobile
LANGUAGE: Swift
SCALE: 18,000 MAU, strong weekend seasonality at 5x weekday use, ~1.5 GB photo data per active user
```

## 19. LunaTide — cycle tracking with privacy focus

```text
APP_DESCRIPTION: A menstrual-cycle-tracking iOS app for privacy-conscious users. Users log periods, symptoms, and moods with Face ID–gated access, get on-device-only predictions for upcoming cycles and fertile windows, and keep all health data local or end-to-end encrypted — no analytics, no accounts.
TECH_STACK: Swift (SwiftUI) + Core Data with file protection + on-device prediction (Core ML) + HealthKit cycle data + optional encrypted CloudKit
APP_TYPE: mobile
LANGUAGE: Swift
SCALE: 90,000 MAU, ~15 logged data points per cycle, zero server-side user data
```

## 20. SyllabusOwl — student semester planner

```text
APP_DESCRIPTION: A semester-planning iOS app for college students. Students import syllabi to auto-extract assignment deadlines, see a unified workload timeline across courses, break big projects into scheduled study blocks, and get grade-weight calculators showing what each final exam needs.
TECH_STACK: Swift (SwiftUI) + VisionKit/PDFKit syllabus parsing + EventKit calendar blocks + Core Data + WidgetKit deadline widgets
APP_TYPE: mobile
LANGUAGE: Swift
SCALE: 55,000 MAU, finals-week peak 4x baseline, ~5 courses and 60 deadlines per student per term
```

## 21. HeelWork — dog training progress app

```text
APP_DESCRIPTION: A dog-training iOS app for new puppy owners. Owners follow step-by-step positive-reinforcement lesson plans for core cues, log training reps with success rates per behavior, use a built-in clicker and whistle, and track potty-training and crate schedules across household members.
TECH_STACK: Swift (SwiftUI) + AVFoundation clicker audio + Core Data + CloudKit shared household sync + StoreKit 2 lesson packs
APP_TYPE: mobile
LANGUAGE: Swift
SCALE: 32,000 MAU, ~8 training sessions per week per dog, 65% multi-caregiver households
```

## 22. ZenithSky — stargazing session planner

```text
APP_DESCRIPTION: A stargazing iOS app for backyard astronomers. Users point their phone at the sky for an AR overlay of constellations and planets, plan sessions around darkness, moon phase, and cloud forecasts, log observations per target with sketches, and manage telescope equipment profiles.
TECH_STACK: Swift (SwiftUI + ARKit sky overlay) + Core Motion/Core Location + WeatherKit + Core Data observation log + SceneKit planetarium rendering
APP_TYPE: mobile
LANGUAGE: Swift
SCALE: 26,000 MAU, new-moon weekend peaks of 3,500 concurrent, ~12,000-object catalog on device
```

## 23. PouchBudget — envelope budgeting app

```text
APP_DESCRIPTION: An envelope-style budgeting iOS app for cash-flow-focused households. Users assign every paycheck dollar to named envelopes, log spending against them with quick-entry and receipt photos, roll surpluses forward monthly, and review category burn-down charts mid-month before overspending.
TECH_STACK: Swift (SwiftUI) + Core Data + CloudKit shared household budget + Swift Charts + App Intents quick-log shortcuts
APP_TYPE: mobile
LANGUAGE: Swift
SCALE: 48,000 MAU, payday-aligned usage spikes on the 1st/15th, ~200 transactions per household per month
```

## 24. LaceArchive — sneaker collection tracker

```text
APP_DESCRIPTION: A sneaker-collection iOS app for collectors and resellers. Collectors catalog pairs with colorway, size, condition, and box photos; track paid-versus-market value over time; log wear rotation to protect grails; and generate authenticated-looking sale sheets when flipping pairs.
TECH_STACK: Swift (SwiftUI) + Core Data + CloudKit sync + Swift Charts value history + PDF sale-sheet export + StoreKit 2
APP_TYPE: mobile
LANGUAGE: Swift
SCALE: 15,000 MAU, ~85 pairs per active collector, ~3 GB photo data per heavy user
```

## 25. SwellScout — surf conditions and session log

```text
APP_DESCRIPTION: A surf-tracking iOS app for everyday surfers. Surfers check dawn-patrol dashboards combining swell, wind, and tide for saved breaks, get push alerts when conditions match personal thresholds, log sessions with board and wave count, and review which conditions produced their best days.
TECH_STACK: Swift (SwiftUI) + WeatherKit + NOAA buoy/tide feeds + Core Location + Core Data session log + WidgetKit dawn-report widget
APP_TYPE: mobile
LANGUAGE: Swift
SCALE: 24,000 MAU, 5–7 AM usage peak of 4,000 concurrent, ~30 saved breaks per region
```

## 26. InkSlot — tattoo studio booking

```text
APP_DESCRIPTION: A booking and client-management iOS app for independent tattoo artists. Artists manage consultation requests with reference-photo intake, schedule sessions with deposit tracking, store per-client design history and aftercare notes, and send automated appointment and healing-check reminders.
TECH_STACK: Swift (SwiftUI) + CloudKit + Core Data + EventKit + Stripe SDK deposits + APNs reminder pipeline
APP_TYPE: mobile
LANGUAGE: Swift
SCALE: 6,000 artist MAU, ~40 active clients per artist, ~25 bookings per artist per month
```

## 27. WombWeeks — week-by-week pregnancy companion

```text
APP_DESCRIPTION: A pregnancy-tracking iOS app for expecting parents. Parents follow week-by-week fetal development guides, log symptoms, weight, and kick counts, build appointment checklists with question prompts for the OB, and share a partner view with milestone notifications.
TECH_STACK: Swift (SwiftUI) + Core Data + HealthKit weight integration + CloudKit shared partner access + WidgetKit week-countdown widget
APP_TYPE: mobile
LANGUAGE: Swift
SCALE: 65,000 MAU, 40-week engagement arc per user, ~70% partner-linked accounts
```

## 28. MeepleShelf — board game collection and plays

```text
APP_DESCRIPTION: A board-game-shelf iOS app for tabletop hobbyists. Players catalog their collection by scanning box barcodes, log plays with scores and player rosters, get game-night picks filtered by player count and time available, and see H-index and shelf-of-shame stats.
TECH_STACK: Swift (SwiftUI) + VisionKit barcode scanning + BoardGameGeek API import + Core Data + CloudKit sync + Swift Charts
APP_TYPE: mobile
LANGUAGE: Swift
SCALE: 19,000 MAU, ~140 games per collection, Friday/Saturday logging peak of 2,500 concurrent
```

## 29. VanCompass — campervan trip planner

```text
APP_DESCRIPTION: A road-trip-planning iOS app for campervan and RV travelers. Travelers plan multi-stop routes with vehicle-height-aware roads, find and review overnight spots with hookup and cell-signal details, track fresh/grey water and battery levels, and journal each leg with photos — offline maps for remote stretches.
TECH_STACK: Swift (SwiftUI) + MapKit with offline packs + Core Location + Core Data + CloudKit sync + community spot API
APP_TYPE: mobile
LANGUAGE: Swift
SCALE: 21,000 MAU, summer peak 3x winter, ~2,200-mile average planned trip
```

## 30. CruxDeck — climbing gym session log

```text
APP_DESCRIPTION: A climbing-log iOS app for indoor boulderers and rope climbers. Climbers log sends and attempts by grade with wall-angle and hold-style tags, track finger-strength and hangboard protocols, watch grade-pyramid progression per discipline, and compare session volume against injury-safe load targets.
TECH_STACK: Swift (SwiftUI) + Core Data + HealthKit workout sessions + Swift Charts + CloudKit sync + WidgetKit streak widget
APP_TYPE: mobile
LANGUAGE: Swift
SCALE: 27,000 MAU, 2–3 sessions per climber per week, weekday 6–9 PM peak of 3,800 concurrent
```

## 31. DoseDove — medication manager for seniors

```text
APP_DESCRIPTION: An accessibility-first medication-reminder iOS app for seniors and their adult-child caregivers. Seniors get large-type, high-contrast dose reminders with photo-verified pill identification, one-tap taken/skipped logging, and refill alerts; remote caregivers see adherence dashboards and missed-dose notifications.
TECH_STACK: Swift (SwiftUI with Dynamic Type/VoiceOver-first design) + Core Data + CloudKit family sharing + critical alerts entitlement + Vision pill recognition
APP_TYPE: mobile
LANGUAGE: Swift
SCALE: 38,000 MAU, ~6 medications per senior, 92% caregiver-linked accounts, 4 reminder windows daily
```

## 32. HandSpeak — ASL learning with camera feedback

```text
APP_DESCRIPTION: An American Sign Language learning iOS app for hearing family members of Deaf relatives. Learners work through themed sign lessons with slow-motion video, practice in front of the camera with on-device handshape feedback, drill fingerspelling recognition games, and build custom family-vocabulary decks.
TECH_STACK: Swift (SwiftUI) + Vision hand-pose estimation + Core ML sign classifier + AVFoundation video lessons + Core Data spaced repetition
APP_TYPE: mobile
LANGUAGE: Swift
SCALE: 16,000 MAU, 10-minute median lesson, ~1,200-sign lesson library
```

## 33. FairwayNote — golf scorecard and stats

```text
APP_DESCRIPTION: A golf-scoring iOS app for weekend golfers. Golfers keep digital scorecards with GPS distances to greens, track fairways-hit, putts, and greens-in-regulation per round, maintain a live handicap estimate, and run friendly skins and match-play games within their foursome.
TECH_STACK: Swift (SwiftUI + watchOS companion) + Core Location course GPS + course database API + Core Data + CloudKit group scorecards
APP_TYPE: mobile
LANGUAGE: Swift
SCALE: 42,000 MAU, weekend-morning peak of 9,000 concurrent rounds, ~28,000-course database
```

## 34. DriftPages — photo-first daily journal

```text
APP_DESCRIPTION: A journaling iOS app for memory-keepers who think in pictures. Users write daily entries anchored to auto-suggested photos, locations, and weather from their day, revisit "on this day" flashbacks, search entries by place or person, and print hardcover year-books from their archive.
TECH_STACK: Swift (SwiftUI) + PhotoKit suggestions + Core Data + CloudKit encrypted sync + JournalingSuggestions API + print-on-demand order API
APP_TYPE: mobile
LANGUAGE: Swift
SCALE: 58,000 MAU, evening 9–11 PM writing peak, ~4 GB media per multi-year journal
```

## 35. KilnNotes — pottery glaze and firing log

```text
APP_DESCRIPTION: A studio-companion iOS app for hobby potters. Potters document each piece from throwing to glaze with stage photos, record glaze recipes and layering combinations with cone temperatures, log kiln firing schedules and results, and search past pieces to reproduce a glaze effect that worked.
TECH_STACK: Swift (SwiftUI) + Core Data + CloudKit sync + PhotoKit stage capture + searchable glaze-recipe index (Core Spotlight)
APP_TYPE: mobile
LANGUAGE: Swift
SCALE: 9,000 MAU, ~30 pieces in progress per potter, ~2 GB photo documentation per active user
```

## 36. PlatformPing — commuter transit companion

```text
APP_DESCRIPTION: A commute-companion iOS app for daily rail and bus commuters in one metro area. Commuters get leave-now nudges based on live departures and walking time, one-glance disruption alerts for only their saved lines, Live Activities tracking the ride in progress, and monthly commute-time stats.
TECH_STACK: Swift (SwiftUI) + GTFS-realtime feeds + Core Location + ActivityKit Live Activities + WidgetKit + APNs disruption alerts
APP_TYPE: mobile
LANGUAGE: Swift
SCALE: 85,000 MAU, 7–9 AM peak of 22,000 concurrent, ~400 tracked routes
```

## 37. HalyardLog — sailing passage log

```text
APP_DESCRIPTION: A digital ship's-log iOS app for coastal sailors. Skippers auto-log GPS track, speed, and heading during passages, record crew, sail changes, and engine hours per leg, overlay tide and wind history on completed tracks, and export season summaries for insurance and yacht-club records.
TECH_STACK: Swift (SwiftUI) + Core Location marine tracking + MapKit + WeatherKit marine data + Core Data + GPX/PDF export
APP_TYPE: mobile
LANGUAGE: Swift
SCALE: 11,000 MAU, sailing-season concentration May–Oct, ~120 engine/log entries per boat per season
```

## 38. TampCraft — coffee brewing journal

```text
APP_DESCRIPTION: A brewing-journal iOS app for specialty-coffee home baristas. Users log espresso shots and pour-overs with dose, grind setting, time, and yield; rate results to dial in recipes per bean; track bag freshness with roast-date countdowns; and get brew-ratio calculators with live shot timers.
TECH_STACK: Swift (SwiftUI) + Core Data + CloudKit sync + App Intents "log last shot" shortcuts + Swift Charts extraction trends
APP_TYPE: mobile
LANGUAGE: Swift
SCALE: 23,000 MAU, morning 6–9 AM peak, ~450 logged brews per active user per year
```

## 39. CorduroyDays — ski season tracker

```text
APP_DESCRIPTION: A ski-and-snowboard season-tracking iOS app for resort skiers. Skiers auto-record runs, vertical, and top speed via motion and GPS, relive days on 3D resort maps, compare season stats with friends, and log conditions and crowd notes per resort day — works glove-friendly with watch companion.
TECH_STACK: Swift (SwiftUI + watchOS companion) + Core Motion/Core Location run detection + MapKit 3D terrain + HealthKit + CloudKit friend leaderboards
APP_TYPE: mobile
LANGUAGE: Swift
SCALE: 33,000 MAU in season, powder-day peaks of 8,000 concurrent, ~25 tracked days per skier per season
```

## 40. HiveLedger — beekeeping inspection log

```text
APP_DESCRIPTION: A hive-management iOS app for backyard beekeepers. Beekeepers run guided inspection checklists per hive with queen, brood, and mite-count fields, get treatment and feeding schedules by season and climate zone, track honey harvests per hive, and review colony-health timelines before winter prep.
TECH_STACK: Swift (SwiftUI) + Core Data + CloudKit sync + WeatherKit forage-weather context + PDF apiary-report export
APP_TYPE: mobile
LANGUAGE: Swift
SCALE: 8,000 MAU, ~4 hives per beekeeper, inspection cadence every 7–10 days in season
```

## 41. PaddockPro — horse stable management

```text
APP_DESCRIPTION: A stable-management iOS app for small boarding barns. Barn managers schedule feeding, turnout, and stall assignments across horses, log vet, farrier, and vaccination records with due-date alerts, coordinate staff task checklists by shift, and message owners with per-horse updates and photos.
TECH_STACK: Swift (SwiftUI) + CloudKit shared barn database + Core Data + APNs owner notifications + PDF health-record export
APP_TYPE: mobile
LANGUAGE: Swift
SCALE: 4,500 MAU across 600 barns, ~22 horses per barn, 5 AM–8 PM staff usage window
```

## 42. GrooveCrate — vinyl record collection

```text
APP_DESCRIPTION: A vinyl-collection iOS app for record collectors. Collectors catalog pressings by scanning barcodes or matrix runouts, grade condition with standardized sleeve/media scales, track collection value against marketplace prices, and build want-lists that alert when a local store or online listing matches.
TECH_STACK: Swift (SwiftUI) + VisionKit barcode capture + Discogs API + Core Data + CloudKit sync + APNs want-list alerts
APP_TYPE: mobile
LANGUAGE: Swift
SCALE: 17,000 MAU, ~320 records per collection, weekly marketplace price refresh across 5M listings
```

## 43. PurlPlanner — knitting project tracker

```text
APP_DESCRIPTION: A knitting-companion iOS app for yarn crafters. Knitters track projects with per-section row counters and pattern PDFs kept in sync, manage yarn stash with dye-lot photos and yardage math, get needle-inventory checks before starting patterns, and log finished objects with recipient and gift notes.
TECH_STACK: Swift (SwiftUI) + PDFKit pattern annotation + Core Data + CloudKit sync + WidgetKit row-counter widget + App Intents voice counting
APP_TYPE: mobile
LANGUAGE: Swift
SCALE: 29,000 MAU, ~3 works-in-progress per knitter, evening/podcast-hours usage peak
```

## 44. SafeBite — food allergy label scanner

```text
APP_DESCRIPTION: An allergy-safety iOS app for families managing severe food allergies. Users scan product barcodes or ingredient labels for instant flagging against each family member's allergen profile, including cross-contamination advisories; save verified-safe product lists per store; and share profiles with grandparents and sitters.
TECH_STACK: Swift (SwiftUI) + VisionKit label OCR + barcode product database API + Core Data offline safe-lists + CloudKit family sharing
APP_TYPE: mobile
LANGUAGE: Swift
SCALE: 44,000 MAU, ~30 scans per family per week, 14-allergen rule engine, offline-first scanning
```

## 45. ChoreQuest — kids chores and allowance

```text
APP_DESCRIPTION: A family chores-and-allowance iOS app for parents of school-age kids. Parents assign recurring chores with photo-proof check-off, kids level up avatars and earn allowance tracked toward savings goals, and the family dashboard settles weekly payouts — teaching earn/save/spend splits along the way.
TECH_STACK: Swift (SwiftUI) + CloudKit family shared database + Core Data + StoreKit 2 premium + WidgetKit kid-facing chore widgets
APP_TYPE: mobile
LANGUAGE: Swift
SCALE: 36,000 MAU across 12,000 families, ~9 chores per kid per week, Sunday payout-night peak
```

## 46. HouseHuntNote — open-house comparison notes

```text
APP_DESCRIPTION: A home-shopping iOS app for first-time buyers touring open houses. Buyers capture structured walkthrough notes with room-by-room photos and voice memos, score each property against their personal must-have checklist, compare finalists side-by-side, and track offer history and outcomes per listing.
TECH_STACK: Swift (SwiftUI) + Core Data + PhotoKit/AVFoundation capture + CloudKit couple-sharing + MapKit listing pins + listing API import
APP_TYPE: mobile
LANGUAGE: Swift
SCALE: 14,000 MAU, weekend open-house peak 6x weekday, ~18 toured homes per buying journey
```

## 47. TriForge — triathlon training planner

```text
APP_DESCRIPTION: A triathlon-training iOS app for age-group triathletes balancing swim, bike, and run. Athletes follow periodized plans that auto-adjust to missed workouts, review load balance across the three disciplines with fatigue warnings, log brick sessions and transitions, and taper with race-day pacing calculators.
TECH_STACK: Swift (SwiftUI + watchOS workout recording) + HealthKit/WorkoutKit + Core Data + Swift Charts training load + CloudKit sync
APP_TYPE: mobile
LANGUAGE: Swift
SCALE: 13,000 MAU, 8–11 workouts per athlete per week, spring race-season peak 2.5x baseline
```

## 48. SporeTrail — mushroom foraging journal

```text
APP_DESCRIPTION: A foraging-journal iOS app for cautious mushroom hunters. Foragers photograph finds with cap/gill/stem detail prompts, get on-device lookalike warnings that always defer to expert verification, pin private spots with seasonal recurrence reminders, and keep spore-print and habitat notes per specimen.
TECH_STACK: Swift (SwiftUI) + Core ML genus suggestions with safety disclaimers + Core Location private pins + Core Data + offline field guide content
APP_TYPE: mobile
LANGUAGE: Swift
SCALE: 12,000 MAU, autumn peak 5x summer, spot data device-encrypted, ~700-species reference guide
```

## 49. VerboVoice — speech therapy home practice

```text
APP_DESCRIPTION: A speech-practice iOS app for children in articulation therapy and their parents. Kids play short daily drills targeting their assigned sounds with recorded-playback comparison and star rewards, parents see accuracy trends between clinic visits, and speech-language pathologists assign word lists remotely.
TECH_STACK: Swift (SwiftUI) + Speech framework + AVFoundation record/playback + Core Data + CloudKit therapist-assignment sync + StoreKit 2
APP_TYPE: mobile
LANGUAGE: Swift
SCALE: 10,000 MAU, 10-minute daily practice target, ~350 SLP-linked caseloads
```

## 50. HearthSync — shared family command center

```text
APP_DESCRIPTION: A family-organizer iOS app for busy two-career households. Families run a shared color-coded calendar with school and activity feeds, coordinate grocery and to-do lists that sync instantly, post a fridge-style message board with pinned reminders, and rotate a who's-doing-pickup schedule.
TECH_STACK: Swift (SwiftUI) + CloudKit shared database + EventKit school-calendar import + Core Data + WidgetKit family-dashboard widgets
APP_TYPE: mobile
LANGUAGE: Swift
SCALE: 52,000 MAU across 17,000 households, Sunday-evening planning peak of 7,000 concurrent
```

## 51. ThrottleTour — motorcycle touring routes

```text
APP_DESCRIPTION: A touring iOS app for motorcycle riders who chase twisty roads. Riders discover curated curvy-road routes with surface-quality ratings, record rides with lean-friendly glanceable navigation cues, log bike-specific fuel range with tank-stop planning, and journal multi-day tours with weather and lodging notes.
TECH_STACK: Swift (SwiftUI) + MapKit turn-by-turn + Core Location/Core Motion + Core Data + CloudKit sync + CarPlay-style glance UI
APP_TYPE: mobile
LANGUAGE: Swift
SCALE: 16,000 MAU, weekend peak of 3,000 concurrent rides, ~5,000 curated route library
```

## 52. GildLight — photography light planner

```text
APP_DESCRIPTION: A light-planning iOS app for landscape and portrait photographers. Photographers see golden-hour and blue-hour windows for any saved location, preview sun/moon position overlays in AR at the shoot spot, plan around weather and cloud-cover forecasts, and get calendar-synced shoot reminders.
TECH_STACK: Swift (SwiftUI + ARKit sun-path overlay) + Core Location + WeatherKit + solar/lunar ephemeris engine + EventKit + WidgetKit
APP_TYPE: mobile
LANGUAGE: Swift
SCALE: 31,000 MAU, sunset-hour usage peak of 5,500 concurrent, ~20 saved locations per photographer
```

## 53. BlockParty — neighborhood mutual aid board

```text
APP_DESCRIPTION: A neighborhood iOS app for residential blocks organizing mutual aid. Neighbors post tool-lending and skill-share offers, coordinate meal trains for new parents and recovering neighbors, organize block events with RSVP and potluck slots, and verify membership by address to keep boards hyper-local.
TECH_STACK: Swift (SwiftUI) + CloudKit shared zones per block + Core Location address verification + APNs + Core Data
APP_TYPE: mobile
LANGUAGE: Swift
SCALE: 20,000 MAU across 1,400 blocks, ~35 households per block, event-weekend activity spikes
```

## 54. CorpusVista — visionOS anatomy explorer

```text
APP_DESCRIPTION: A spatial anatomy-learning visionOS app for nursing and pre-med students. Students walk around life-size 3D body systems, peel layers from skin to skeleton with hand gestures, pin flash-card labels to structures for spaced-repetition review, and follow guided dissection-style lessons per organ system.
TECH_STACK: Swift (SwiftUI + RealityKit for visionOS) + USDZ anatomical model pipeline + Core Data spaced repetition + StoreKit 2 system packs
APP_TYPE: mobile
LANGUAGE: Swift
SCALE: 7,000 MAU, 25-minute median study session, ~2,400 labeled structures across 11 systems
```

## 55. MuseumMuse — visionOS gallery experiences

```text
APP_DESCRIPTION: A visionOS app bringing museum exhibitions into the living room for art lovers far from major cities. Users walk through curated virtual galleries with true-scale artworks, hear curator audio anchored to each piece, zoom into brushwork detail beyond glass-case distance, and save personal collections across exhibitions.
TECH_STACK: Swift (SwiftUI + RealityKit immersive spaces) + high-resolution IIIF artwork pipeline + spatial audio (PHASE) + CloudKit favorites + StoreKit 2 exhibition passes
APP_TYPE: mobile
LANGUAGE: Swift
SCALE: 5,000 MAU, 3 new exhibitions per quarter, ~40 GB streamed asset catalog
```

## 56. OarRhythm — rowing training on the wrist

```text
APP_DESCRIPTION: An Apple Watch–first rowing app for indoor erg and on-water rowers. Rowers get live stroke-rate and split targets with haptic pacing on the wrist, sync erg workouts from PM5 monitors over Bluetooth, track drive/recovery ratio trends, and follow club training plans with weekly meters leaderboards.
TECH_STACK: Swift (SwiftUI for watchOS + iOS companion) + Core Bluetooth PM5 integration + HealthKit/WorkoutKit + CloudKit club leaderboards + Swift Charts
APP_TYPE: mobile
LANGUAGE: Swift
SCALE: 9,000 MAU, 5–7 AM erg-session peak, ~250 club leaderboards
```

## 57. EmberChain — habit streak builder

```text
APP_DESCRIPTION: A habit-building iOS app for people who abandon habit apps. Users commit to a maximum of three habits at once with friction-free one-tap logging from widgets and watch, get streak-freeze tokens instead of guilt when life happens, and review honest monthly consistency reports rather than gamified noise.
TECH_STACK: Swift (SwiftUI) + Core Data + WidgetKit interactive widgets + watchOS complication logging + App Intents + CloudKit sync
APP_TYPE: mobile
LANGUAGE: Swift
SCALE: 75,000 MAU, morning 6–8 AM logging peak of 11,000 concurrent, 3-habit cap per user
```

## 58. SplitNest — roommate expense settling

```text
APP_DESCRIPTION: An expense-splitting iOS app for roommates in shared apartments. Roommates log shared costs with receipt photos and custom split ratios, track recurring bills like rent and utilities with due-date reminders, settle up with minimal-transaction suggestions, and keep a deposit-deduction log for move-out.
TECH_STACK: Swift (SwiftUI) + CloudKit shared household ledger + Core Data + VisionKit receipt capture + APNs settle-up reminders
APP_TYPE: mobile
LANGUAGE: Swift
SCALE: 40,000 MAU across 14,000 households, month-end settle-up peak, ~45 shared expenses per household per month
```

## 59. CrumbCoat — sourdough baking log

```text
APP_DESCRIPTION: A sourdough-baking iOS app for home bread bakers. Bakers track starter feedings with rise-time photos and health indicators, run guided bake timelines with stretch-and-fold timers adjusted to kitchen temperature, log crumb shots with hydration and flour-blend details, and iterate recipes toward their ideal loaf.
TECH_STACK: Swift (SwiftUI) + Core Data + local notification bake timers + PhotoKit crumb gallery + CloudKit sync + WeatherKit ambient-temperature hints
APP_TYPE: mobile
LANGUAGE: Swift
SCALE: 18,000 MAU, weekend bake-day peak 4x weekday, ~60 logged bakes per active baker per year
```

## 60. NockPoint — archery practice tracker

```text
APP_DESCRIPTION: An archery-training iOS app for target and field archers. Archers plot arrow groups on digital target faces by tapping impact points, track scoring rounds against personal bests per distance, log equipment tuning changes with before/after group sizes, and prep for tournaments with round-format simulations.
TECH_STACK: Swift (SwiftUI + PencilKit target plotting) + Core Data + Swift Charts group analysis + CloudKit sync + StoreKit 2
APP_TYPE: mobile
LANGUAGE: Swift
SCALE: 7,500 MAU, ~90 arrows per session, weekend range-day peak
```

## 61. DecibelGuard — sound exposure companion

```text
APP_DESCRIPTION: A hearing-health iOS app for musicians, concertgoers, and hearing-aid users. Users monitor live ambient sound levels with safe-exposure countdowns at loud venues, log noise doses against WHO daily limits from watch and phone sensors, get earplug reminders geofenced to saved venues, and track hearing-test results over time.
TECH_STACK: Swift (SwiftUI + watchOS) + AVAudioEngine level metering + HealthKit environmental audio and audiogram data + Core Location geofences + Swift Charts
APP_TYPE: mobile
LANGUAGE: Swift
SCALE: 26,000 MAU, concert-night peaks of 4,500 concurrent, daily exposure-dose tracking
```

## 62. PoolLoop — school carpool coordination

```text
APP_DESCRIPTION: A carpool-coordination iOS app for parents at the same school. Parents build trusted driver circles with verified school membership, schedule recurring pickup rotations with automatic fairness balancing, get live "kid picked up" confirmations with driver ETA, and handle sick-day swaps with one-tap substitute requests.
TECH_STACK: Swift (SwiftUI) + CloudKit shared circles + Core Location trip confirmation + APNs + ActivityKit pickup Live Activities + Core Data
APP_TYPE: mobile
LANGUAGE: Swift
SCALE: 22,000 MAU across 900 schools, 2:30–4 PM pickup peak of 6,000 concurrent, ~5 families per circle
```

## 63. StandCrate — farm stand and CSA companion

```text
APP_DESCRIPTION: A farm-stand iOS app for small farms running CSA shares and roadside stands. Farmers post weekly harvest availability with photos, members customize their share box and set vacation holds, the app tallies pack lists per pickup day, and self-serve stand sales run through QR checkout with tap-to-pay.
TECH_STACK: Swift (SwiftUI) + CloudKit + Core Data + Tap to Pay on iPhone / Stripe Terminal + APNs harvest announcements
APP_TYPE: mobile
LANGUAGE: Swift
SCALE: 8,500 MAU across 350 farms, ~80 CSA members per farm, Saturday-pickup usage peak
```

## 64. FathomDive — scuba dive log

```text
APP_DESCRIPTION: A dive-logging iOS app for recreational scuba divers. Divers import depth profiles from Bluetooth dive computers, log conditions, buddies, and marine-life sightings per dive, track certification progress and surface-interval planning, and keep gear service records with regulator due-date alerts.
TECH_STACK: Swift (SwiftUI) + Core Bluetooth dive-computer import + Core Data + MapKit dive-site pins + CloudKit sync + PDF logbook export
APP_TYPE: mobile
LANGUAGE: Swift
SCALE: 13,000 MAU, vacation-clustered usage, ~45 logged dives per diver per year
```

## 65. SnipShade — screenshot annotation for macOS

```text
APP_DESCRIPTION: A macOS menu-bar screenshot tool for support teams and technical writers. Users capture regions or windows with a hotkey, annotate with arrows, redaction blur, and step-number badges, auto-copy compressed output to the clipboard, and keep a searchable capture history organized by app.
TECH_STACK: Swift (SwiftUI + AppKit) + ScreenCaptureKit + Core Image redaction/compression + Core Data capture history + global hotkey handling
APP_TYPE: desktop
LANGUAGE: Swift
SCALE: 25,000 MAU, ~15 captures per user per day, local library <2 GB
```

## 66. ChapterForge — podcast production suite

```text
APP_DESCRIPTION: A macOS podcast-editing desktop app for independent podcasters. Podcasters edit multi-track episodes with silence trimming and filler-word detection, level guest audio with loudness normalization to podcast standards, drop chapter markers with artwork, and export tagged MP3s straight to their hosting feed.
TECH_STACK: Swift (SwiftUI + AppKit timeline) + AVFoundation/Accelerate audio DSP + Speech framework filler detection + Core Data projects + MP3 chapter tagging
APP_TYPE: desktop
LANGUAGE: Swift
SCALE: 9,000 MAU, ~70-minute average episode, 4-track typical project, local projects ~10 GB
```

## 67. PastePorter — clipboard history manager

```text
APP_DESCRIPTION: A macOS menu-bar clipboard manager for developers and writers. Users summon searchable clipboard history with a hotkey, pin snippets into organized boards with paste-as-plain-text rules per app, sync history across their Macs end-to-end encrypted, and exclude password managers automatically.
TECH_STACK: Swift (SwiftUI + AppKit pasteboard monitoring) + Core Data + CloudKit encrypted sync + global hotkeys + per-app exclusion rules
APP_TYPE: desktop
LANGUAGE: Swift
SCALE: 40,000 MAU, ~200 clipboard events per user per day, 5,000-item history cap
```

## 68. GlyphDock — font manager for designers

```text
APP_DESCRIPTION: A macOS font-management desktop app for brand and type designers. Designers organize thousands of typefaces into client-scoped activation sets, preview custom pangrams across weights side-by-side, auto-activate fonts when design files open, and catch duplicate or corrupt font files before they break exports.
TECH_STACK: Swift (SwiftUI + AppKit) + Core Text font parsing/activation + SQLite (GRDB) catalog + file-system event monitoring + Quick Look previews
APP_TYPE: desktop
LANGUAGE: Swift
SCALE: 12,000 MAU, ~4,800 fonts per power-user library, 60 activation sets per designer
```

## 69. RowboatDB — database browser for macOS

```text
APP_DESCRIPTION: A native macOS database client for backend developers working with Postgres and SQLite. Developers browse schemas with instant table previews, edit rows inline with type-aware editors and transaction safety, save parameterized query snippets per project, and diff schema changes between environments before deploys.
TECH_STACK: Swift (SwiftUI + AppKit table views) + PostgresNIO + SQLite drivers + Keychain credential storage + Core Data workspace state
APP_TYPE: desktop
LANGUAGE: Swift
SCALE: 15,000 MAU, ~8 saved connections per developer, million-row table browsing with virtualized scrolling
```

## 70. LedgerLoom — freelancer invoicing for macOS

```text
APP_DESCRIPTION: A macOS invoicing desktop app for freelancers and studios of one. Freelancers build branded invoices from tracked line items with tax and currency handling, schedule recurring retainers with auto-send, chase overdue payments with polite reminder sequences, and see year-to-date income dashboards ready for tax season.
TECH_STACK: Swift (SwiftUI) + Core Data + PDFKit invoice rendering + CloudKit sync + Stripe payment links + Swift Charts income dashboards
APP_TYPE: desktop
LANGUAGE: Swift
SCALE: 11,000 MAU, ~14 invoices per user per month, 7-year financial record retention
```

## 71. ZettelBloom — networked notes for macOS

```text
APP_DESCRIPTION: A macOS zettelkasten note-taking desktop app for researchers and PhD students. Users write Markdown notes with instant wiki-links and backlink panels, visualize their idea graph with cluster detection, resurface orphaned notes during weekly reviews, and cite sources with BibTeX integration for manuscript drafts.
TECH_STACK: Swift (SwiftUI + AppKit text system) + plain-file Markdown vault + SQLite (GRDB) link index + Core Spotlight + BibTeX parser
APP_TYPE: desktop
LANGUAGE: Swift
SCALE: 14,000 MAU, ~3,500 notes per mature vault, sub-50ms search across 10,000 notes
```

## 72. MicMaster — meeting AV control from the menu bar

```text
APP_DESCRIPTION: A macOS menu-bar utility for remote workers juggling back-to-back video calls. Users get one global hotkey to mute any conferencing app, see an always-visible on-air indicator for camera and mic, auto-pause music when meetings start, and set per-app audio device routing so the good mic is always used.
TECH_STACK: Swift (SwiftUI + AppKit) + Core Audio device routing + camera/mic usage detection + EventKit meeting awareness + global hotkeys
APP_TYPE: desktop
LANGUAGE: Swift
SCALE: 30,000 MAU, 5–7 meetings per user per day, sub-100ms mute latency target
```

## 73. CullFrame — photo culling for wedding photographers

```text
APP_DESCRIPTION: A macOS photo-culling desktop app for wedding and event photographers. Photographers blaze through 4,000-shot cards with GPU-accelerated full-res previews, auto-flag blinks, soft focus, and duplicates with on-device ML, rate and tag with one-key shortcuts, and hand picked selects to Lightroom via XMP.
TECH_STACK: Swift (SwiftUI + AppKit) + Core Image/Metal preview pipeline + Vision blink/sharpness models + RAW decoding + XMP sidecar export
APP_TYPE: desktop
LANGUAGE: Swift
SCALE: 6,000 MAU, ~4,000 RAW frames per event, 20-image-per-second culling throughput target
```

## 74. NozzleWatch — 3D printer farm monitor

```text
APP_DESCRIPTION: A macOS desktop app for makers running multiple 3D printers. Operators watch live camera and temperature tiles for every printer on the network, get failure detection alerts for spaghetti and detached prints, queue jobs across idle machines with filament-type matching, and log filament spool usage and costs per print.
TECH_STACK: Swift (SwiftUI) + Moonraker/OctoPrint APIs over local network + Network framework mDNS discovery + Vision failure detection + Core Data job history
APP_TYPE: desktop
LANGUAGE: Swift
SCALE: 5,500 MAU, ~6 printers per farm, 24/7 monitoring with 30-second poll cycles
```

## 75. PacketLantern — network diagnostics menu bar

```text
APP_DESCRIPTION: A macOS menu-bar network-diagnostics utility for remote workers on flaky connections. Users see live latency, jitter, and packet loss to key services at a glance, get "your Wi-Fi vs your ISP" fault isolation when calls degrade, log outage timelines to show providers, and test speeds on a schedule.
TECH_STACK: Swift (SwiftUI + AppKit menu bar) + Network framework path monitoring + ICMP/HTTP probes + Core Data outage log + Swift Charts history
APP_TYPE: desktop
LANGUAGE: Swift
SCALE: 18,000 MAU, probes every 15 seconds, 90-day local diagnostic history
```

## 76. SlugLine — screenwriting studio for macOS

```text
APP_DESCRIPTION: A macOS screenwriting desktop app for indie filmmakers and TV writers. Writers draft in industry-standard format with auto-completing character and scene elements, outline with index-card corkboards that stay linked to script scenes, track revisions with colored draft pages, and export production-ready Final Draft and PDF files.
TECH_STACK: Swift (SwiftUI + AppKit text engine) + Fountain/FDX import-export + Core Data outline model + PDFKit paginated output + CloudKit draft sync
APP_TYPE: desktop
LANGUAGE: Swift
SCALE: 8,000 MAU, ~110-page feature drafts, 30+ revision passes per produced script
```

## 77. PromptGlass — stage teleprompter for macOS

```text
APP_DESCRIPTION: A macOS teleprompter desktop app for YouTubers, pastors, and conference speakers. Speakers load scripts with per-section speed and font settings, scroll hands-free with voice-tracking that follows their spoken position, mirror output to external prompter displays, and mark elapsed-time targets to stay inside their slot.
TECH_STACK: Swift (SwiftUI + AppKit multi-display output) + Speech framework voice tracking + Core Data script library + external display mirroring
APP_TYPE: desktop
LANGUAGE: Swift
SCALE: 7,000 MAU, ~1,800-word average script, dual-display use in 60% of sessions
```

## 78. TomeHarbor — personal ebook library manager

```text
APP_DESCRIPTION: A macOS ebook-library desktop app for heavy readers with sprawling collections. Readers import EPUBs and PDFs with automatic metadata and cover fetching, deduplicate and organize into smart shelves by rules, convert between formats for different devices, and sync reading progress notes across their library.
TECH_STACK: Swift (SwiftUI) + EPUB/PDF parsing + SQLite (GRDB) catalog + metadata lookup APIs + format conversion pipeline + Core Spotlight search
APP_TYPE: desktop
LANGUAGE: Swift
SCALE: 10,000 MAU, ~2,600 books per power-user library, ~40 GB local library typical
```

## 79. StringDeck — localization editor for app teams

```text
APP_DESCRIPTION: A macOS desktop app for iOS teams managing app localization. Developers and translators edit String Catalogs side-by-side with source-context screenshots, flag missing and stale translations across 20 languages, preview pluralization and length overflow per device size, and export translator packages with change-only diffs.
TECH_STACK: Swift (SwiftUI) + xcstrings/xliff parsing + Core Data review state + screenshot-context rendering + diff engine
APP_TYPE: desktop
LANGUAGE: Swift
SCALE: 4,000 MAU, ~3,200 string keys per app, 20-language matrices, weekly release cadence
```

## 80. TickerBar — portfolio glance for the menu bar

```text
APP_DESCRIPTION: A macOS menu-bar portfolio tracker for long-term retail investors. Investors see their watchlist and portfolio day-change at a glance without opening a brokerage, set quiet-hours so prices don't distract during deep work, get earnings-date and dividend reminders, and review allocation drift against target percentages.
TECH_STACK: Swift (SwiftUI + AppKit menu bar) + market data API with WebSocket quotes + Core Data holdings + Keychain + Swift Charts allocation views
APP_TYPE: desktop
LANGUAGE: Swift
SCALE: 20,000 MAU, market-hours refresh every 15 seconds, ~35 tickers per user
```

## 81. RootsAtlas — family tree research studio

```text
APP_DESCRIPTION: A macOS genealogy desktop app for family-history researchers. Researchers build multi-generation trees with source citations attached to every fact, scan and enhance old family photos with face tagging linked to tree members, import GEDCOM files from other tools, and print poster-size descendant charts for reunions.
TECH_STACK: Swift (SwiftUI + AppKit chart rendering) + Core Data graph model + GEDCOM import/export + Vision face tagging + Core Image photo restoration + PDF poster output
APP_TYPE: desktop
LANGUAGE: Swift
SCALE: 9,500 MAU, ~1,400 individuals per mature tree, ~15 GB scanned media per researcher
```

## 82. HookHerald — webhook relay and replay API

```text
APP_DESCRIPTION: A webhook reliability API service for SaaS integration teams. Client systems point third-party webhooks at HookHerald endpoints, which verify signatures, deduplicate, fan out to multiple internal consumers with per-endpoint retry policies, and provide searchable delivery logs with one-click replay of failed events.
TECH_STACK: Swift (Vapor) + PostgreSQL delivery log + Redis retry queues + HMAC signature verification + Docker on Fly.io
APP_TYPE: API service
LANGUAGE: Swift
SCALE: 1,200 req/sec sustained ingest, 140 tenant workspaces, 30-day 2 TB delivery-log retention
```

## 83. FrameForge — on-the-fly image transformation API

```text
APP_DESCRIPTION: An image-processing API service for mobile app backends. Clients request resized, cropped, and format-converted variants of stored originals via URL parameters, get automatic HEIC/WebP negotiation and smart-crop face awareness, and serve results through CDN with signed URLs — one original, every device size derived on demand.
TECH_STACK: Swift (Vapor) + SwiftNIO + libvips bindings + S3-compatible object storage + CloudFront CDN + Redis variant cache
APP_TYPE: API service
LANGUAGE: Swift
SCALE: 900 req/sec peak (85% CDN hit rate), 60M stored originals, ~45 TB object storage
```

## 84. KeyKiln — license key service for indie developers

```text
APP_DESCRIPTION: A software-licensing API service for indie Mac and iOS developers selling outside the App Store. Developer storefronts issue signed license keys on purchase, apps validate and activate against per-seat device limits, trials and upgrades are handled with offline-tolerant grace periods, and dashboards show activation and churn analytics.
TECH_STACK: Swift (Vapor) + PostgreSQL + Ed25519 signed license payloads + Paddle/Stripe purchase webhooks + Redis rate limiting
APP_TYPE: API service
LANGUAGE: Swift
SCALE: 250 req/sec validation traffic, 800 developer accounts, 2.5M issued licenses
```

## 85. ToggleTide — feature flag delivery API

```text
APP_DESCRIPTION: A feature-flag API service for small mobile teams. Engineering teams define flags with percentage rollouts, device and locale targeting rules, and kill switches; SDKs fetch evaluated flag sets with sub-50ms edge-cached responses; and every flag change is audit-logged with instant rollback.
TECH_STACK: Swift (Vapor) + PostgreSQL rules store + Redis evaluation cache + SSE streaming updates + Swift/Kotlin client SDKs + Docker on AWS
APP_TYPE: API service
LANGUAGE: Swift
SCALE: 2,000 req/sec flag evaluations, 400 team workspaces, 15,000 active flags
```

## 86. ReceiptRanger — StoreKit server validation API

```text
APP_DESCRIPTION: A subscription-backend API service for iOS app developers who don't want to build App Store Server API plumbing. Apps send StoreKit transactions for server-side verification, the service tracks entitlement state across renewals, refunds, and grace periods via App Store Server Notifications, and developers query a clean entitlements API plus churn dashboards.
TECH_STACK: Swift (Vapor) + App Store Server API/Notifications V2 + PostgreSQL entitlement ledger + Redis + JWS verification + Grafana metrics
APP_TYPE: API service
LANGUAGE: Swift
SCALE: 700 req/sec entitlement checks, 350 client apps, 9M tracked subscribers
```

## 87. MenuMorse — QR menu and ordering API for restaurants

```text
APP_DESCRIPTION: A QR-menu API service for independent restaurants. Restaurant tablets manage menus with daily specials and 86'd-item toggles that update diner-facing QR menus instantly, diners browse and place table-side orders from their phones, and tickets route to kitchen displays with course timing — no app install for diners.
TECH_STACK: Swift (Vapor) + PostgreSQL + Redis pub/sub for kitchen tickets + WebSocket order streams + server-rendered Leaf menu pages
APP_TYPE: API service
LANGUAGE: Swift
SCALE: 450 req/sec dinner-rush peak, 900 restaurants, 60,000 orders per day
```

## 88. AgriCast — field weather API for farm software

```text
APP_DESCRIPTION: An agricultural-weather API service for farm-management software vendors. Client platforms query field-level forecasts blended from multiple weather models, get growing-degree-day and frost-risk calculations per crop and planting date, subscribe to spray-window and irrigation advisories, and pull historical weather for yield analysis.
TECH_STACK: Swift (Vapor) + PostgreSQL/PostGIS field geometries + TimescaleDB weather series + multi-model ingestion workers + Redis cache
APP_TYPE: API service
LANGUAGE: Swift
SCALE: 350 req/sec, 45 vendor clients, 1.2M registered field polygons, 10 years of hourly history
```

## 89. ArenaLoom — turn-based game matchmaking API

```text
APP_DESCRIPTION: A matchmaking and turn-state API service for indie developers of turn-based mobile games. Game clients join skill-banded matchmaking queues, exchange validated turn payloads with server-authoritative state storage, trigger your-turn push notifications, and run seasonal ladders with Elo-style ratings — one backend across a studio's catalog.
TECH_STACK: Swift (Vapor) + PostgreSQL match state + Redis matchmaking queues + APNs/FCM turn notifications + JWT player auth
APP_TYPE: API service
LANGUAGE: Swift
SCALE: 1,500 req/sec evening peak, 28 client games, 600,000 active matches, 4M registered players
```

## 90. MailMason — transactional email templating API

```text
APP_DESCRIPTION: A transactional-email API service for product teams tired of hardcoded email HTML. Teams design versioned email templates with typed variables and locale variants, backends trigger sends with JSON payloads validated against template schemas, and delivery, open, and bounce events stream back via webhooks with suppression-list hygiene.
TECH_STACK: Swift (Vapor) + PostgreSQL template store + Redis send queues + SES/SMTP relay adapters + MJML-style rendering pipeline
APP_TYPE: API service
LANGUAGE: Swift
SCALE: 800 req/sec send bursts, 220 team workspaces, 40M emails per month
```

## 91. SiloSense — grain storage telemetry backend

```text
APP_DESCRIPTION: An IoT telemetry API service for grain-storage cooperatives. Sensor gateways in silos stream temperature and moisture readings, the service detects hot-spot and spoilage-risk patterns across cable grids, alerts elevator operators by severity with escalation rules, and serves historical curves to agronomist dashboards.
TECH_STACK: Swift (Vapor) + SwiftNIO MQTT ingestion + TimescaleDB sensor series + PostgreSQL + APNs/SMS alert escalation + Grafana-facing query API
APP_TYPE: API service
LANGUAGE: Swift
SCALE: 12,000 sensor readings/sec ingest, 85 cooperative sites, 40,000 sensors, 5-year series retention
```

## 92. ShearShare — booking API for salons and barbershops

```text
APP_DESCRIPTION: An appointment-booking API service powering white-label salon and barbershop apps. Shop systems manage stylist calendars with service durations and buffer rules, clients book through embedded widgets with deposit capture, no-show protection runs automated reminder and rebooking flows, and owners pull utilization and rebooking-rate reports.
TECH_STACK: Swift (Vapor) + PostgreSQL scheduling engine + Redis slot-hold locks + Stripe deposits + Twilio/APNs reminders + iCal feed output
APP_TYPE: API service
LANGUAGE: Swift
SCALE: 500 req/sec booking-widget traffic, 1,800 shops, 95,000 appointments per week
```

## 93. AssetSieve — asset catalog optimizer CLI

```text
APP_DESCRIPTION: A command-line tool for iOS build engineers auditing Xcode asset catalogs. The CLI scans .xcassets for unused images by cross-referencing source code, flags missing dark-mode and scale variants, recompresses oversized assets with quality budgets, and fails CI when the asset payload exceeds a configured app-size cap.
TECH_STACK: Swift (swift-argument-parser) + XcodeProj parsing + SwiftSyntax usage scanning + Core Graphics recompression + JSON/CI report output
APP_TYPE: CLI
LANGUAGE: Swift
SCALE: 3,000 monthly active installs, ~2,500 assets scanned per run, <30-second CI budget per app
```

## 94. LocLinter — localization strings linter CLI

```text
APP_DESCRIPTION: A command-line linter for iOS teams shipping in many languages. The CLI validates String Catalogs and .strings files for missing keys, mismatched format specifiers, and untranslated placeholders across locales, enforces terminology glossaries, and posts annotated diffs to pull requests as a CI gate.
TECH_STACK: Swift (swift-argument-parser) + xcstrings/strings parsers + format-specifier static analysis + glossary rule engine + GitHub Checks API output
APP_TYPE: CLI
LANGUAGE: Swift
SCALE: 4,500 monthly active installs, 20-locale × 3,000-key matrices per run, sub-10-second runs
```

## 95. ShotCaller — App Store screenshot automation CLI

```text
APP_DESCRIPTION: A command-line tool for indie iOS developers generating App Store screenshots. The CLI drives XCUITest flows across device sizes and locales, composites captures into framed marketing templates with localized captions, validates against App Store dimension requirements, and uploads finished sets via the App Store Connect API.
TECH_STACK: Swift (swift-argument-parser) + xcodebuild/XCUITest orchestration + Core Graphics compositing + App Store Connect API client + YAML template config
APP_TYPE: CLI
LANGUAGE: Swift
SCALE: 2,000 monthly active installs, 8 device sizes × 12 locales = 480 screenshots per release run
```

## 96. CertScope — signing and provisioning doctor CLI

```text
APP_DESCRIPTION: A command-line diagnostics tool for iOS developers fighting code-signing failures. The CLI inspects local certificates, provisioning profiles, and keychain state, explains signing errors in plain language with the exact mismatch identified, cleans expired duplicate profiles safely, and verifies CI signing setups before release day.
TECH_STACK: Swift (swift-argument-parser) + Security framework keychain APIs + provisioning profile (CMS) parsing + Xcode project signing-config analysis
APP_TYPE: CLI
LANGUAGE: Swift
SCALE: 6,000 monthly active installs, ~40 profiles inspected per machine, top-3 error classes auto-explained
```

## 97. PackAudit — SwiftPM dependency audit CLI

```text
APP_DESCRIPTION: A command-line dependency auditor for Swift teams with compliance requirements. The CLI resolves a project's full SwiftPM dependency graph, reports licenses with policy violations (GPL in App Store builds, missing notices), checks versions against known-vulnerability advisories, and generates SBOM files for enterprise security reviews.
TECH_STACK: Swift (swift-argument-parser) + SwiftPM Package.resolved graph resolution + SPDX license detection + OSV advisory API + CycloneDX SBOM output
APP_TYPE: CLI
LANGUAGE: Swift
SCALE: 3,500 monthly active installs, ~120 transitive dependencies per audited app, weekly CI schedule
```

## 98. StaticSpin — static site generator CLI

```text
APP_DESCRIPTION: A command-line static site generator for Swift developers publishing blogs and docs sites. Authors write Markdown with front matter, define layouts in a type-safe Swift DSL instead of template strings, get incremental builds with live-reload preview, and deploy output to any static host — plugins ship as SwiftPM packages.
TECH_STACK: Swift (swift-argument-parser) + swift-markdown parsing + result-builder HTML DSL + file-watching incremental build engine + SwiftNIO preview server
APP_TYPE: CLI
LANGUAGE: Swift
SCALE: 5,000 monthly active installs, 400-page sites built in <3 seconds incremental, ~90 community plugins
```

## 99. TokenSmith — design token codegen CLI

```text
APP_DESCRIPTION: A command-line tool for mobile design-systems teams syncing design tokens to code. The CLI ingests token JSON exported from Figma, generates type-safe Swift color, typography, and spacing constants with light/dark variants, diffs token changes against the previous release with visual changelogs, and opens PRs when tokens drift.
TECH_STACK: Swift (swift-argument-parser) + W3C design-token JSON parsing + SwiftSyntax code generation + asset-catalog color emission + GitHub API PR automation
APP_TYPE: CLI
LANGUAGE: Swift
SCALE: 1,800 monthly active installs, ~600 tokens per design system, tokens synced across 12 apps per org
```

## 100. SimWrangler — simulator fleet management CLI

```text
APP_DESCRIPTION: A command-line tool for iOS QA engineers managing herds of simulators. The CLI boots configured simulator matrices by device and OS version, seeds them with test media, contacts, and locale/timezone states, streams logs and captures videos across the fleet during test runs, and resets everything to clean snapshots between suites.
TECH_STACK: Swift (swift-argument-parser) + simctl orchestration wrapper + YAML fleet manifests + parallel process management (Swift Concurrency) + JUnit-adjacent reporting
APP_TYPE: CLI
LANGUAGE: Swift
SCALE: 2,500 monthly active installs, 15-simulator parallel fleets, ~200 test-suite runs per team per week
```
