# Ruby Blueprint Types — Copy-Paste Input Sets

Copy a fenced block into the prompt as-is, or swap individual fields.

## 1. InnKeep — boutique hotel booking

```text
APP_DESCRIPTION: A direct-booking web app for boutique hotels and guesthouses. Guests check live room availability, book with dynamic seasonal pricing, and manage stays; innkeepers run the front desk (check-in/out, housekeeping status), sync availability to OTA channels, and send pre-arrival emails.
TECH_STACK: Ruby on Rails + Hotwire (Turbo/Stimulus) + PostgreSQL + Stripe + channel-manager API sync, deployed on Heroku
APP_TYPE: web app
LANGUAGE: Ruby
SCALE: 200 concurrent users, ~25 req/sec, ~8 GB data
```

## 2. RoastPost — coffee subscription storefront

```text
APP_DESCRIPTION: A subscription storefront web app for a specialty coffee roastery. Customers build recurring coffee subscriptions (roast preference, grind, cadence), skip or swap upcoming shipments, and gift subscriptions; the roastery plans weekly roast batches from subscription demand and prints shipping labels.
TECH_STACK: Ruby on Rails + Hotwire + PostgreSQL + Stripe Billing + EasyPost shipping, deployed on Render
APP_TYPE: web app
LANGUAGE: Ruby
SCALE: 300 concurrent users, ~35 req/sec, ~6 GB data
```

## 3. HireLoop — applicant tracking system

```text
APP_DESCRIPTION: An applicant-tracking web app for companies of 50-500 employees. Recruiters post jobs to a branded careers page, move candidates through customizable pipeline stages with structured interview scorecards, schedule interviews with calendar sync, and report on time-to-hire and source effectiveness.
TECH_STACK: Ruby on Rails + Hotwire + PostgreSQL + Sidekiq + Google/Microsoft calendar APIs, deployed on AWS
APP_TYPE: web app
LANGUAGE: Ruby
SCALE: 600 concurrent users, ~70 req/sec, ~25 GB data
```

## 4. StageDoor — community theater ticketing

```text
APP_DESCRIPTION: A ticketing web app for community theaters. Patrons pick seats from an interactive seat map, buy season subscriptions with seat retention, and receive QR e-tickets; the box office manages holds and comps, scans tickets at the door, and reports nightly sales per production.
TECH_STACK: Ruby on Rails + Hotwire + PostgreSQL + Stripe + seat-map SVG rendering, deployed on Fly.io
APP_TYPE: web app
LANGUAGE: Ruby
SCALE: 400 concurrent users at season-open, ~50 req/sec peak, ~4 GB data
```

## 5. RateRelay — shipping rate aggregation API

```text
APP_DESCRIPTION: A shipping-rate aggregation API service for e-commerce developers. Clients submit parcel dimensions and destinations, the service fans out to carrier APIs (UPS, FedEx, USPS, DHL), normalizes and caches rate quotes, applies client-negotiated discounts, and returns ranked options with delivery estimates.
TECH_STACK: Ruby (Rails API mode) + PostgreSQL + Redis quote cache + Sidekiq + carrier API connectors, deployed on AWS
APP_TYPE: API service
LANGUAGE: Ruby
SCALE: ~180 req/sec, 250 client integrations, ~10 GB data
```

## 6. changelogger — release notes CLI

```text
APP_DESCRIPTION: A CLI tool for release managers that generates changelogs from git history. It parses conventional commits and PR labels between tags, groups entries by type and scope, drafts human-readable release notes with breaking-change callouts, and updates CHANGELOG.md plus GitHub release drafts.
TECH_STACK: Ruby CLI (thor) + rugged git bindings + GitHub API + ERB templates, distributed as a gem
APP_TYPE: CLI
LANGUAGE: Ruby
SCALE: single user per invocation, repos up to 100k commits, <100 MB local data
```

## 7. Vetrium — veterinary practice management

```text
APP_DESCRIPTION: A practice-management web app for small-animal veterinary clinics. Front-desk staff book exam-room appointments and send vaccine reminders, vets chart SOAP notes with medication dosing by weight, and owners view pet records, lab results, and invoices through a client portal.
TECH_STACK: Ruby on Rails + Hotwire + PostgreSQL + Sidekiq + Twilio SMS reminders, deployed on AWS
APP_TYPE: web app
LANGUAGE: Ruby
SCALE: 350 concurrent users, ~40 req/sec, ~30 GB data
```

## 8. BriefStack — small-firm legal case management

```text
APP_DESCRIPTION: A case-management web app for law firms of 2-25 attorneys. Lawyers track matters, deadlines, and court dates with statute-of-limitations alerts, log billable time against clients, assemble documents from clause templates, and run conflict-of-interest checks on intake.
TECH_STACK: Ruby on Rails + Hotwire + PostgreSQL + Sidekiq + ActiveStorage on S3 + LawPay billing, deployed on AWS
APP_TYPE: web app
LANGUAGE: Ruby
SCALE: 400 concurrent users, ~45 req/sec, ~60 GB data (documents)
```

## 9. CropCrate — CSA farm share management

```text
APP_DESCRIPTION: A web app for community-supported agriculture farms to run seasonal veggie-box programs. Members choose share sizes and pickup sites, swap disliked items within weekly harvest limits, and pause for vacations; farmers plan harvest quantities from share counts and print pack lists per pickup site.
TECH_STACK: Ruby on Rails + Hotwire + PostgreSQL + Stripe Billing + Sidekiq, deployed on Render
APP_TYPE: web app
LANGUAGE: Ruby
SCALE: 250 concurrent users on swap-deadline day, ~30 req/sec, ~3 GB data
```

## 10. SweatSlot — boutique fitness class booking

```text
APP_DESCRIPTION: A class-booking web app for boutique fitness studios (spin, yoga, HIIT). Members buy class packs or unlimited memberships, reserve bikes or mats from a room layout, and join waitlists with auto-promotion; studio owners manage instructor schedules, no-show fees, and attendance reports.
TECH_STACK: Ruby on Rails + Hotwire + PostgreSQL + Redis + Stripe + Sidekiq waitlist jobs, deployed on Heroku
APP_TYPE: web app
LANGUAGE: Ruby
SCALE: 800 concurrent users at booking-window open, ~90 req/sec peak, ~12 GB data
```

## 11. GiverGrid — nonprofit donor CRM

```text
APP_DESCRIPTION: A donor CRM web app for mid-size nonprofits. Development officers track donors, pledges, and giving history with soft credits, segment lists for appeal campaigns, record grant deadlines, and generate year-end tax receipts; leadership sees dashboards of retention and campaign progress.
TECH_STACK: Ruby on Rails + Hotwire + PostgreSQL + Sidekiq + SendGrid + Stripe donations, deployed on AWS
APP_TYPE: web app
LANGUAGE: Ruby
SCALE: 500 concurrent users, ~55 req/sec, ~40 GB data
```

## 12. LeaseLantern — residential property management

```text
APP_DESCRIPTION: A property-management web app for independent landlords with 5-200 units. Tenants pay rent online, submit maintenance requests with photos, and renew leases with e-signatures; landlords screen applicants, track work orders to vendors, and export owner statements per property.
TECH_STACK: Ruby on Rails + Hotwire + PostgreSQL + Sidekiq + Stripe ACH + ActiveStorage on S3, deployed on AWS
APP_TYPE: web app
LANGUAGE: Ruby
SCALE: 700 concurrent users on rent-due days, ~65 req/sec, ~35 GB data
```

## 13. VowVenue — wedding vendor marketplace

```text
APP_DESCRIPTION: A two-sided marketplace web app connecting engaged couples with wedding vendors (venues, photographers, caterers, florists). Couples browse portfolios filtered by date availability and budget, request quotes, and pay deposits in escrow; vendors manage inquiries, contracts, and reviews.
TECH_STACK: Ruby on Rails + Hotwire + PostgreSQL + Elasticsearch + Stripe Connect + Sidekiq, deployed on AWS
APP_TYPE: web app
LANGUAGE: Ruby
SCALE: 1,500 concurrent users, ~150 req/sec, ~80 GB data
```

## 14. CastCove — podcast hosting and analytics

```text
APP_DESCRIPTION: A podcast hosting web app for independent podcasters. Creators upload episodes, schedule releases, and get an RSS feed plus embeddable player; the platform serves enclosure downloads, attributes listens by app and region (IAB-compliant), and manages dynamic ad-slot insertion markers.
TECH_STACK: Ruby on Rails + Hotwire + PostgreSQL + Sidekiq + S3/CloudFront audio delivery + ClickHouse analytics, deployed on AWS
APP_TYPE: web app
LANGUAGE: Ruby
SCALE: 1,000 concurrent dashboard users, ~2M enclosure requests/day, ~500 GB audio
```

## 15. HallPassHQ — school volunteer coordination

```text
APP_DESCRIPTION: A web app for school PTAs and front offices to coordinate parent volunteers. Coordinators post shifts for events (book fairs, carnivals, classroom help) with background-check requirements, parents sign up and get reminders, and the office tracks hours for district reporting.
TECH_STACK: Ruby on Rails + Hotwire + PostgreSQL + Sidekiq + Twilio SMS, deployed on Heroku
APP_TYPE: web app
LANGUAGE: Ruby
SCALE: 300 concurrent users at signup launch, ~30 req/sec, ~2 GB data
```

## 16. MolarMinder — dental practice scheduling

```text
APP_DESCRIPTION: A scheduling and recall web app for dental practices. Front desk books cleanings and procedures across operatories and hygienists, patients confirm via SMS and complete intake forms online, and the recall engine chases overdue six-month cleanings with escalating reminders.
TECH_STACK: Ruby on Rails + Hotwire + PostgreSQL + Sidekiq + Twilio + insurance eligibility API, deployed on AWS
APP_TYPE: web app
LANGUAGE: Ruby
SCALE: 450 concurrent users, ~50 req/sec, ~20 GB data
```

## 17. KegLedger — craft brewery taproom and distribution

```text
APP_DESCRIPTION: An operations web app for craft breweries. Taproom staff manage tap lists and pour inventory by keg, the brewhouse logs batches from brite tank to packaging, and the self-distribution side tracks kegs at retail accounts with deposit balances and delivery routes.
TECH_STACK: Ruby on Rails + Hotwire + PostgreSQL + Sidekiq + Square POS API + barcode keg labels, deployed on Fly.io
APP_TYPE: web app
LANGUAGE: Ruby
SCALE: 150 concurrent users, ~20 req/sec, ~5 GB data
```

## 18. TallyDrift — freelancer time tracking and invoicing

```text
APP_DESCRIPTION: A time-tracking and invoicing web app for freelancers and micro-agencies. Users log hours against clients and projects with a running timer, convert unbilled time into branded invoices with tax handling, chase overdue payments with scheduled reminders, and see profitability per client.
TECH_STACK: Ruby on Rails + Hotwire + PostgreSQL + Sidekiq + Stripe invoicing + PDF generation (Prawn), deployed on Render
APP_TYPE: web app
LANGUAGE: Ruby
SCALE: 1,200 concurrent users, ~110 req/sec, ~18 GB data
```

## 19. SpineShelf — indie bookstore storefront and inventory

```text
APP_DESCRIPTION: A web app for independent bookstores combining in-store inventory with an online storefront. Booksellers receive stock against publisher invoices with ISBN lookup, curate staff-pick shelves, and fulfill local-pickup and shipped orders; customers browse live in-store availability and place special orders.
TECH_STACK: Ruby on Rails + Hotwire + PostgreSQL + Stripe + ISBNdb/Ingram APIs + Sidekiq, deployed on Heroku
APP_TYPE: web app
LANGUAGE: Ruby
SCALE: 400 concurrent users, ~45 req/sec, ~10 GB data
```

## 20. PinePitch — campground reservations

```text
APP_DESCRIPTION: A reservation web app for private campgrounds and RV parks. Campers pick sites from an interactive park map filtered by hookups, rig length, and pet rules, pay deposits, and get gate codes before arrival; owners manage seasonal rates, site blocks for maintenance, and occupancy reports.
TECH_STACK: Ruby on Rails + Hotwire + PostgreSQL + Stripe + Sidekiq + map rendering with Leaflet, deployed on Render
APP_TYPE: web app
LANGUAGE: Ruby
SCALE: 900 concurrent users at summer-release, ~100 req/sec peak, ~8 GB data
```

## 21. CuratorKey — museum membership management

```text
APP_DESCRIPTION: A membership web app for museums and science centers. Visitors buy and renew tiered memberships with scannable digital cards, reserve timed-entry slots for special exhibitions, and register for member events; staff manage renewals, gift memberships, and admission-desk lookups.
TECH_STACK: Ruby on Rails + Hotwire + PostgreSQL + Stripe Billing + Sidekiq + Apple/Google Wallet passes, deployed on AWS
APP_TYPE: web app
LANGUAGE: Ruby
SCALE: 600 concurrent users during exhibit on-sale, ~70 req/sec, ~15 GB data
```

## 22. CurbsideCrave — food truck preorder platform

```text
APP_DESCRIPTION: A web app for food trucks to publish daily locations and take preorders. Customers find trucks on a map, order ahead for a pickup window, and get text alerts when food is ready; operators cap order volume per window, 86 sold-out items in real time, and see sales by location.
TECH_STACK: Ruby on Rails + Hotwire + PostgreSQL + Redis + Stripe + Twilio + Turbo Streams live menu, deployed on Fly.io
APP_TYPE: web app
LANGUAGE: Ruby
SCALE: 1,000 concurrent users at lunch rush, ~120 req/sec peak, ~6 GB data
```

## 23. TutorTide — tutoring marketplace

```text
APP_DESCRIPTION: A marketplace web app matching students with vetted tutors for K-12 and test prep. Parents search by subject, price, and availability, book recurring sessions with integrated video links, and pay per session; tutors manage calendars, session notes, and payouts with platform fees.
TECH_STACK: Ruby on Rails + Hotwire + PostgreSQL + Stripe Connect + Sidekiq + Zoom API, deployed on AWS
APP_TYPE: web app
LANGUAGE: Ruby
SCALE: 2,000 concurrent users, ~180 req/sec, ~50 GB data
```

## 24. RigReserve — construction equipment rental

```text
APP_DESCRIPTION: A rental-management web app for construction equipment yards. Contractors browse excavators, lifts, and compactors with real-time availability, reserve with delivery scheduling, and extend rentals from the field; the yard tracks utilization, inspection checklists, and damage claims per asset.
TECH_STACK: Ruby on Rails + Hotwire + PostgreSQL + Sidekiq + Stripe + telematics API integration, deployed on AWS
APP_TYPE: web app
LANGUAGE: Ruby
SCALE: 350 concurrent users, ~40 req/sec, ~22 GB data
```

## 25. TidyTrail — home cleaning service operations

```text
APP_DESCRIPTION: An operations web app for residential cleaning companies. Dispatchers build recurring route schedules for cleaning teams, customers book and reschedule visits with keyed-entry notes, cleaners check in/out from a mobile-friendly view with photo proof, and billing runs automatically after completion.
TECH_STACK: Ruby on Rails + Hotwire + PostgreSQL + Sidekiq + Stripe + Google Maps routing, deployed on Heroku
APP_TYPE: web app
LANGUAGE: Ruby
SCALE: 500 concurrent users, ~55 req/sec, ~14 GB data
```

## 26. PlotShare — community garden management

```text
APP_DESCRIPTION: A web app for city community-garden programs to manage plots and members. Gardeners apply for plots from waiting lists, pay seasonal fees, and log volunteer hours required by their agreement; coordinators map plot assignments, schedule shared workdays, and track water-access keys.
TECH_STACK: Ruby on Rails + Hotwire + PostgreSQL + Stripe + Sidekiq, deployed on Render
APP_TYPE: web app
LANGUAGE: Ruby
SCALE: 150 concurrent users at spring signup, ~15 req/sec, ~1 GB data
```

## 27. HelmAway — boat charter booking

```text
APP_DESCRIPTION: A booking web app for boat charter operators (sailing, fishing, sightseeing). Guests book half-day and full-day trips with per-passenger pricing and weather-hold policies, sign digital waivers, and get dock directions; captains manage vessel calendars, crew assignments, and tide-aware departure slots.
TECH_STACK: Ruby on Rails + Hotwire + PostgreSQL + Stripe + Sidekiq + weather API holds, deployed on Fly.io
APP_TYPE: web app
LANGUAGE: Ruby
SCALE: 400 concurrent users, ~45 req/sec, ~5 GB data
```

## 28. EaselEdge — art gallery consignment

```text
APP_DESCRIPTION: A consignment and sales web app for art galleries. Galleries catalog works with provenance, editions, and consignment terms, publish curated online viewing rooms for collectors, record sales with artist-split calculations, and generate consignor statements and insurance schedules.
TECH_STACK: Ruby on Rails + Hotwire + PostgreSQL + ActiveStorage on S3 + Stripe + Prawn PDF statements, deployed on Heroku
APP_TYPE: web app
LANGUAGE: Ruby
SCALE: 200 concurrent users, ~20 req/sec, ~45 GB data (images)
```

## 29. SteepleBase — congregation management

```text
APP_DESCRIPTION: A congregation-management web app for churches and synagogues. Staff maintain member households, schedule volunteers across services (ushers, childcare, music), receive tithes and pledges online with giving statements, and coordinate small groups with attendance tracking.
TECH_STACK: Ruby on Rails + Hotwire + PostgreSQL + Stripe + Sidekiq + Mailgun, deployed on AWS
APP_TYPE: web app
LANGUAGE: Ruby
SCALE: 600 concurrent users Sunday mornings, ~65 req/sec peak, ~12 GB data
```

## 30. PowderPath — ski school lesson booking

```text
APP_DESCRIPTION: A lesson-booking web app for ski resorts and independent ski schools. Families book group or private lessons by ability level with instructor matching, complete rental sizing and waivers before arrival, and receive meeting-point details; supervisors balance instructor rosters against demand and certifications.
TECH_STACK: Ruby on Rails + Hotwire + PostgreSQL + Stripe + Sidekiq + resort ticketing API integration, deployed on AWS
APP_TYPE: web app
LANGUAGE: Ruby
SCALE: 1,200 concurrent users on powder-day mornings, ~130 req/sec peak, ~10 GB data
```

## 31. SpokeSmith — bike shop service tracking

```text
APP_DESCRIPTION: A service-department web app for bicycle shops. Customers drop off bikes and get a ticket with photo condition notes, mechanics work a prioritized repair queue with parts picked from inventory, and automatic texts go out on estimate approval and pickup-ready status.
TECH_STACK: Ruby on Rails + Hotwire + PostgreSQL + Sidekiq + Twilio + Square payments, deployed on Render
APP_TYPE: web app
LANGUAGE: Ruby
SCALE: 120 concurrent users, ~15 req/sec, ~4 GB data
```

## 32. DeskHive — coworking space management

```text
APP_DESCRIPTION: A space-management web app for coworking operators. Members book hot desks, dedicated desks, and meeting rooms with credit allowances, unlock doors via integration, and get invoiced monthly; operators manage floor plans, day-pass sales, occupancy analytics, and community event RSVPs.
TECH_STACK: Ruby on Rails + Hotwire + PostgreSQL + Stripe Billing + Sidekiq + Kisi door-access API, deployed on AWS
APP_TYPE: web app
LANGUAGE: Ruby
SCALE: 700 concurrent users, ~75 req/sec, ~16 GB data
```

## 33. WagLodge — pet boarding and daycare

```text
APP_DESCRIPTION: A booking and operations web app for pet boarding and daycare facilities. Owners reserve kennel runs or daycare days with vaccination-record uploads, receive report cards with photos, and buy multi-day packages; staff manage feeding/medication schedules, playgroup assignments, and capacity by kennel size.
TECH_STACK: Ruby on Rails + Hotwire + PostgreSQL + Stripe + Sidekiq + ActiveStorage on S3, deployed on Heroku
APP_TYPE: web app
LANGUAGE: Ruby
SCALE: 500 concurrent users before holidays, ~55 req/sec peak, ~20 GB data
```

## 34. RampStart — employee onboarding platform

```text
APP_DESCRIPTION: An HR onboarding web app for growing companies. People-ops teams build role-specific onboarding checklists (equipment, accounts, training, policy sign-offs), new hires complete tasks and e-sign documents before day one, and managers see readiness dashboards with blockers flagged.
TECH_STACK: Ruby on Rails + Hotwire + PostgreSQL + Sidekiq + Slack/Google Workspace APIs + DocuSign, deployed on AWS
APP_TYPE: web app
LANGUAGE: Ruby
SCALE: 800 concurrent users, ~80 req/sec, ~30 GB data
```

## 35. TorqueTicket — auto repair shop management

```text
APP_DESCRIPTION: A shop-management web app for independent auto repair shops. Service writers create repair orders with VIN-decoded vehicle data, send digital inspection results with photos for customer approval, order parts against jobs, and schedule bays; customers approve estimates and pay by text link.
TECH_STACK: Ruby on Rails + Hotwire + PostgreSQL + Sidekiq + Twilio + PartsTech API + Stripe, deployed on AWS
APP_TYPE: web app
LANGUAGE: Ruby
SCALE: 450 concurrent users, ~50 req/sec, ~25 GB data
```

## 36. PetalRoute — florist order and delivery management

```text
APP_DESCRIPTION: A web app for retail florists managing orders and same-day delivery. Customers build arrangements with occasion-based suggestions and delivery windows, designers work a production queue with recipe cards, and drivers get optimized routes with photo proof-of-delivery at the door.
TECH_STACK: Ruby on Rails + Hotwire + PostgreSQL + Stripe + Sidekiq + Google Maps route optimization, deployed on Render
APP_TYPE: web app
LANGUAGE: Ruby
SCALE: 600 concurrent users on Valentine's week, ~70 req/sec peak, ~7 GB data
```

## 37. LinguaLatch — language school enrollment

```text
APP_DESCRIPTION: An enrollment web app for language schools. Prospective students take placement tests, enroll in level-based course sections with proration for mid-term starts, and track attendance and progression; academic coordinators manage teacher assignments, classroom capacity, and completion certificates.
TECH_STACK: Ruby on Rails + Hotwire + PostgreSQL + Stripe + Sidekiq + Prawn certificate PDFs, deployed on Heroku
APP_TYPE: web app
LANGUAGE: Ruby
SCALE: 350 concurrent users at term registration, ~40 req/sec, ~9 GB data
```

## 38. ShutterSuite — photography studio booking and galleries

```text
APP_DESCRIPTION: A web app for portrait and wedding photographers. Clients book session types with contracts and retainers, then receive password-protected proof galleries to favorite images and order prints; photographers manage shoot calendars, gallery expiration, and print-lab fulfillment.
TECH_STACK: Ruby on Rails + Hotwire + PostgreSQL + ActiveStorage on S3/CloudFront + Stripe + WHCC print API, deployed on AWS
APP_TYPE: web app
LANGUAGE: Ruby
SCALE: 900 concurrent gallery viewers, ~85 req/sec, ~800 GB images
```

## 39. FlipReady — vacation rental turnover operations

```text
APP_DESCRIPTION: An operations web app coordinating cleaning turnovers for short-term rental managers. Booking calendars sync from Airbnb/Vrbo to auto-generate turnover jobs between stays, cleaners claim jobs and submit room-by-room photo checklists, and inspectors flag issues that block same-day check-ins.
TECH_STACK: Ruby on Rails + Hotwire + PostgreSQL + Sidekiq + iCal/channel sync + Stripe payouts, deployed on AWS
APP_TYPE: web app
LANGUAGE: Ruby
SCALE: 700 concurrent users on Saturday changeovers, ~75 req/sec peak, ~28 GB data
```

## 40. PlatterPlan — catering order management

```text
APP_DESCRIPTION: A web app for catering companies managing corporate and event orders. Clients build menus from packages with headcount-based pricing and dietary tags, approve quotes and pay deposits; the kitchen gets consolidated prep sheets by event day, and drivers get load lists and delivery schedules.
TECH_STACK: Ruby on Rails + Hotwire + PostgreSQL + Stripe + Sidekiq + Prawn prep-sheet PDFs, deployed on Render
APP_TYPE: web app
LANGUAGE: Ruby
SCALE: 300 concurrent users, ~35 req/sec, ~8 GB data
```

## 41. PliePoint — dance studio management

```text
APP_DESCRIPTION: A studio-management web app for dance schools. Parents register dancers for classes by age and level with family discounts and autopay tuition, track recital costume fees, and get make-up class credits; owners manage instructor payroll hours, studio-room schedules, and recital program lineups.
TECH_STACK: Ruby on Rails + Hotwire + PostgreSQL + Stripe Billing + Sidekiq, deployed on Heroku
APP_TYPE: web app
LANGUAGE: Ruby
SCALE: 550 concurrent users at fall registration, ~60 req/sec peak, ~6 GB data
```

## 42. GavelGrove — auction house bidding platform

```text
APP_DESCRIPTION: An online-bidding web app for regional auction houses selling antiques and estates. Bidders browse lot catalogs with condition reports, place absentee bids or bid live with real-time price updates, and pay invoices with buyer's premium; the house manages consignors, lot numbering, and settlement statements.
TECH_STACK: Ruby on Rails + Hotwire (Turbo Streams live bidding) + PostgreSQL + Redis + Stripe + Sidekiq, deployed on AWS
APP_TYPE: web app
LANGUAGE: Ruby
SCALE: 2,500 concurrent bidders during live sales, ~300 req/sec peak, ~40 GB data
```

## 43. CruClub — winery club allocations

```text
APP_DESCRIPTION: A wine-club web app for wineries running allocation and club programs. Members set bottle preferences and shipping cadence, customize quarterly club shipments within allocation limits, and comply with state shipping rules at checkout; the winery manages tiers, will-call pickups, and compliance reporting.
TECH_STACK: Ruby on Rails + Hotwire + PostgreSQL + Stripe Billing + ShipCompliant API + Sidekiq, deployed on AWS
APP_TYPE: web app
LANGUAGE: Ruby
SCALE: 800 concurrent users at allocation release, ~90 req/sec peak, ~11 GB data
```

## 44. BleacherBase — youth sports league management

```text
APP_DESCRIPTION: A league-management web app for youth sports organizations. Parents register players with birth-certificate verification and pay fees, coaches get balanced team rosters and practice schedules, and the league auto-generates game schedules across shared fields with referee assignments and rainout rescheduling.
TECH_STACK: Ruby on Rails + Hotwire + PostgreSQL + Stripe + Sidekiq + Twilio rainout alerts, deployed on Heroku
APP_TYPE: web app
LANGUAGE: Ruby
SCALE: 1,000 concurrent users at registration open, ~110 req/sec peak, ~9 GB data
```

## 45. WillowRest — funeral home arrangements

```text
APP_DESCRIPTION: An arrangements web app for family-owned funeral homes. Directors manage cases from first call through service with task checklists (permits, obituaries, cemetery coordination), families select caskets and service options remotely with itemized GPL pricing, and obituaries publish with condolence guestbooks.
TECH_STACK: Ruby on Rails + Hotwire + PostgreSQL + Stripe + Sidekiq + ActiveStorage, deployed on AWS
APP_TYPE: web app
LANGUAGE: Ruby
SCALE: 200 concurrent users, ~20 req/sec, ~10 GB data
```

## 46. StrideSpring — physical therapy clinic platform

```text
APP_DESCRIPTION: A clinic web app for outpatient physical therapy practices. Patients book evaluations, complete outcome questionnaires (e.g., LEFS, DASH) before visits, and follow prescribed home-exercise programs with video demos and adherence logging; therapists document visits and track outcome scores across episodes of care.
TECH_STACK: Ruby on Rails + Hotwire + PostgreSQL + Sidekiq + Mux video + Twilio reminders, deployed on AWS
APP_TYPE: web app
LANGUAGE: Ruby
SCALE: 600 concurrent users, ~65 req/sec, ~35 GB data
```

## 47. LatchLore — escape room booking

```text
APP_DESCRIPTION: A booking web app for escape room venues. Players book rooms by time slot with public/private game options and team-size pricing, sign waivers on their phones, and get post-game photos and leaderboard rankings; owners manage room schedules, reset buffers, and gift-card sales.
TECH_STACK: Ruby on Rails + Hotwire + PostgreSQL + Stripe + Sidekiq, deployed on Fly.io
APP_TYPE: web app
LANGUAGE: Ruby
SCALE: 500 concurrent users on weekend evenings, ~55 req/sec peak, ~4 GB data
```

## 48. StallStreet — farmers market vendor management

```text
APP_DESCRIPTION: A web app for farmers market organizers managing vendors and stalls. Vendors apply with product categories and insurance certificates, get assigned stalls per market day with seniority rules, and pay stall fees online; managers track attendance, waitlists for popular markets, and SNAP/token reconciliation.
TECH_STACK: Ruby on Rails + Hotwire + PostgreSQL + Stripe + Sidekiq, deployed on Render
APP_TYPE: web app
LANGUAGE: Ruby
SCALE: 250 concurrent users, ~25 req/sec, ~3 GB data
```

## 49. MeritGate — scholarship application management

```text
APP_DESCRIPTION: A web app for foundations and universities running scholarship programs. Students submit applications with transcripts and essays against eligibility rules, reviewers score assigned applications on weighted rubrics with conflict recusal, and administrators run award rounds with fund budgets and acceptance tracking.
TECH_STACK: Ruby on Rails + Hotwire + PostgreSQL + Sidekiq + ActiveStorage on S3 + SendGrid, deployed on AWS
APP_TYPE: web app
LANGUAGE: Ruby
SCALE: 1,500 concurrent users at deadline day, ~160 req/sec peak, ~50 GB data
```

## 50. FolioFalls — literary magazine submissions

```text
APP_DESCRIPTION: A submissions web app for literary magazines and small presses. Writers submit stories and poems with simultaneous-submission tracking and reading fees, editors triage slush through tiered reading rounds with blind mode, and acceptances flow into issue planning with contracts and contributor payments.
TECH_STACK: Ruby on Rails + Hotwire + PostgreSQL + Stripe + Sidekiq + ActiveStorage, deployed on Heroku
APP_TYPE: web app
LANGUAGE: Ruby
SCALE: 400 concurrent users during open reading periods, ~40 req/sec, ~15 GB data
```

## 51. ShearSlot — salon and barbershop appointments

```text
APP_DESCRIPTION: An appointment web app for salons and barbershops. Clients book services with their preferred stylist, prepay or hold with a card, and reschedule within cancellation windows; stylists manage chair schedules and service durations, and the shop tracks rebooking rates, product retail sales, and tips.
TECH_STACK: Ruby on Rails + Hotwire + PostgreSQL + Stripe + Sidekiq + Twilio reminders, deployed on Render
APP_TYPE: web app
LANGUAGE: Ruby
SCALE: 1,100 concurrent users, ~120 req/sec, ~13 GB data
```

## 52. VaultYard — self-storage facility management

```text
APP_DESCRIPTION: A facility-management web app for self-storage operators. Renters browse unit sizes with live availability and move in entirely online (lease e-sign, autopay, gate code issuance); managers run delinquency workflows through overlock and lien-sale stages, and adjust street rates by occupancy.
TECH_STACK: Ruby on Rails + Hotwire + PostgreSQL + Stripe + Sidekiq + gate-controller API, deployed on AWS
APP_TYPE: web app
LANGUAGE: Ruby
SCALE: 500 concurrent users, ~55 req/sec, ~12 GB data
```

## 53. ShelfShare — food bank inventory and distribution

```text
APP_DESCRIPTION: A web app for regional food banks managing inventory and partner distribution. Warehouse staff receive donations with lot dates and USDA commodity tracking, partner pantries place weekly orders against fair-share allocations, and drivers get palletized pick lists; reporting covers pounds distributed by county.
TECH_STACK: Ruby on Rails + Hotwire + PostgreSQL + Sidekiq + barcode scanning + Prawn pick-list PDFs, deployed on AWS
APP_TYPE: web app
LANGUAGE: Ruby
SCALE: 300 concurrent users, ~30 req/sec, ~14 GB data
```

## 54. KeyKindle — real estate showing scheduling

```text
APP_DESCRIPTION: A showing-coordination web app for residential real estate brokerages. Buyer agents request showings against listing availability rules, sellers approve or propose times from their phones, lockbox codes release only for confirmed windows, and listing agents get feedback surveys after each showing.
TECH_STACK: Ruby on Rails + Hotwire + PostgreSQL + Sidekiq + Twilio + MLS data sync, deployed on AWS
APP_TYPE: web app
LANGUAGE: Ruby
SCALE: 1,800 concurrent users, ~170 req/sec, ~30 GB data
```

## 55. QuorumQuarters — HOA and condo association management

```text
APP_DESCRIPTION: A web app for homeowners associations and condo boards. Residents pay dues, submit architectural-change requests, and reserve amenities like clubhouses; boards run violation workflows with photo evidence and escalating notices, publish meeting minutes, and conduct proxy voting for annual elections.
TECH_STACK: Ruby on Rails + Hotwire + PostgreSQL + Stripe ACH + Sidekiq + ActiveStorage, deployed on AWS
APP_TYPE: web app
LANGUAGE: Ruby
SCALE: 650 concurrent users, ~70 req/sec, ~18 GB data
```

## 56. CredentialCreek — continuing education credit tracking

```text
APP_DESCRIPTION: A web app for professional trade associations managing continuing-education requirements. Members register for accredited courses and webinars, credits post automatically to their transcripts against license-renewal requirements by state, and compliance deadlines trigger reminder campaigns; providers submit courses for accreditation review.
TECH_STACK: Ruby on Rails + Hotwire + PostgreSQL + Stripe + Sidekiq + Zoom webinar API, deployed on AWS
APP_TYPE: web app
LANGUAGE: Ruby
SCALE: 900 concurrent users near renewal deadlines, ~95 req/sec peak, ~26 GB data
```

## 57. FrondForge — plant nursery wholesale ordering

```text
APP_DESCRIPTION: A B2B ordering web app for wholesale plant nurseries. Landscapers and garden centers browse live availability lists with sizes and grades, place orders against weekly delivery routes, and manage standing orders for seasonal color; the nursery updates crop-ready dates and manages truck-load planning.
TECH_STACK: Ruby on Rails + Hotwire + PostgreSQL + Sidekiq + Stripe invoicing + route planning, deployed on Render
APP_TYPE: web app
LANGUAGE: Ruby
SCALE: 400 concurrent users Monday mornings, ~45 req/sec peak, ~7 GB data
```

## 58. JoistJournal — home inspection reporting

```text
APP_DESCRIPTION: A reporting web app for home inspection companies. Inspectors build reports on-site from reusable template libraries with photos, severity ratings, and repair-cost ranges, publish branded PDF/web reports to buyers and agents, and manage scheduling with agreement e-signing and payment collection up front.
TECH_STACK: Ruby on Rails + Hotwire + PostgreSQL + ActiveStorage on S3 + Stripe + Prawn PDF reports + Sidekiq, deployed on AWS
APP_TYPE: web app
LANGUAGE: Ruby
SCALE: 350 concurrent users, ~40 req/sec, ~120 GB data (photos)
```

## 59. GrantGrain — foundation grant management

```text
APP_DESCRIPTION: A grant-management web app for philanthropic foundations. Nonprofits submit LOIs and full proposals through configurable application cycles, program officers review with scoring panels and due-diligence checklists, and awarded grants track payments, budget revisions, and grantee progress reports.
TECH_STACK: Ruby on Rails + Hotwire + PostgreSQL + Sidekiq + ActiveStorage + DocuSign grant agreements, deployed on AWS
APP_TYPE: web app
LANGUAGE: Ruby
SCALE: 700 concurrent users at cycle deadlines, ~75 req/sec peak, ~40 GB data
```

## 60. MeepleManor — board game café reservations

```text
APP_DESCRIPTION: A web app for board game cafés managing table reservations and the game library. Guests reserve tables with party size and cover fees, browse the 1,500-game library with complexity and player-count filters, and request game recommendations; staff track checkouts, missing pieces, and event nights.
TECH_STACK: Ruby on Rails + Hotwire + PostgreSQL + Stripe + BoardGameGeek API sync + Sidekiq, deployed on Fly.io
APP_TYPE: web app
LANGUAGE: Ruby
SCALE: 300 concurrent users on Friday nights, ~35 req/sec peak, ~3 GB data
```

## 61. ShiftSkillet — restaurant staff scheduling

```text
APP_DESCRIPTION: A staff-scheduling web app for multi-location restaurant groups. Managers build weekly schedules against forecasted covers and labor-cost targets, staff swap shifts with rule-based approval and claim open shifts, and clock-in data flags overtime risk and missed breaks before payroll export.
TECH_STACK: Ruby on Rails + Hotwire + PostgreSQL + Redis + Sidekiq + Twilio shift alerts + payroll export APIs, deployed on AWS
APP_TYPE: web app
LANGUAGE: Ruby
SCALE: 2,200 concurrent users at schedule publish, ~200 req/sec peak, ~35 GB data
```

## 62. LaurelLink — alumni mentorship platform

```text
APP_DESCRIPTION: An alumni engagement web app for universities. Alumni create profiles with industries and mentoring availability, students request mentorship matches with guided program curricula and meeting logging, and advancement teams run reunion event registration and measure engagement scores across classes.
TECH_STACK: Ruby on Rails + Hotwire + PostgreSQL + Elasticsearch profile search + Sidekiq + SendGrid, deployed on AWS
APP_TYPE: web app
LANGUAGE: Ruby
SCALE: 1,300 concurrent users, ~130 req/sec, ~45 GB data
```

## 63. LevyLogic — sales tax calculation API

```text
APP_DESCRIPTION: A sales-tax calculation API service for e-commerce platforms. Clients submit order line items with ship-to addresses, the service resolves rooftop-accurate jurisdictions, applies product taxability rules and holiday exemptions, and returns itemized tax; it also aggregates liability by state for filing exports.
TECH_STACK: Ruby (Rails API mode) + PostgreSQL + Redis rate cache + Sidekiq + geocoding service, deployed on AWS
APP_TYPE: API service
LANGUAGE: Ruby
SCALE: ~450 req/sec, 600 client integrations, ~35 GB data
```

## 64. HookHarbor — webhook delivery infrastructure API

```text
APP_DESCRIPTION: A webhook delivery API service for SaaS developers. Producers POST events to the ingest endpoint, the service fans out to subscriber endpoints with HMAC signing, exponential-backoff retries, and dead-letter queues, and dashboards expose per-endpoint delivery rates, latencies, and replay tools.
TECH_STACK: Ruby (Rails API mode) + PostgreSQL + Redis + Sidekiq Pro delivery workers, deployed on AWS with autoscaling
APP_TYPE: API service
LANGUAGE: Ruby
SCALE: ~2,000 events/sec ingested, 1,200 client integrations, ~200 GB data
```

## 65. PaperPress — document generation API

```text
APP_DESCRIPTION: A document-generation API service for developers producing invoices, contracts, and certificates. Clients send JSON data against uploaded templates with merge fields, loops, and conditional sections; the service renders pixel-accurate PDFs with fonts and page numbering, and stores signed download URLs.
TECH_STACK: Ruby (Rails API mode) + PostgreSQL + Sidekiq render workers + headless Chromium + S3, deployed on Fly.io
APP_TYPE: API service
LANGUAGE: Ruby
SCALE: ~120 req/sec, 400 client integrations, ~300 GB rendered documents
```

## 66. PinPointer — address verification API

```text
APP_DESCRIPTION: An address verification and geocoding API service for checkout and logistics teams. Clients submit raw addresses, the service standardizes against postal reference data (USPS CASS, international formats), flags undeliverable or missing-unit addresses, and returns rooftop coordinates with confidence scores.
TECH_STACK: Ruby (Rails API mode) + PostgreSQL/PostGIS + Redis cache + postal reference datasets, deployed on AWS
APP_TYPE: API service
LANGUAGE: Ruby
SCALE: ~800 req/sec, 900 client integrations, ~150 GB reference data
```

## 67. ChassisCheck — VIN decode and vehicle data API

```text
APP_DESCRIPTION: A vehicle data API service for dealerships, insurers, and auto marketplaces. Clients submit VINs and receive decoded year/make/model/trim, factory equipment, recall status, and market-value ranges; batch endpoints enrich whole inventories overnight with change notifications.
TECH_STACK: Ruby (Rails API mode) + PostgreSQL + Redis + Sidekiq batch jobs + NHTSA/valuation data feeds, deployed on AWS
APP_TYPE: API service
LANGUAGE: Ruby
SCALE: ~250 req/sec, 350 client integrations, ~60 GB data
```

## 68. QuoteQuill — insurance rating API

```text
APP_DESCRIPTION: An insurance rating API service for MGAs and insurtech brokers. Clients submit risk profiles (property details, driver histories, coverage selections), the rating engine evaluates versioned carrier rate tables with underwriting rules, and returns bindable premium quotes with surcharge and discount breakdowns.
TECH_STACK: Ruby (Rails API mode) + PostgreSQL + versioned rate-table engine + Redis + Sidekiq, deployed on AWS
APP_TYPE: API service
LANGUAGE: Ruby
SCALE: ~90 req/sec, 120 client integrations, ~20 GB data
```

## 69. SlotSocket — embeddable scheduling API

```text
APP_DESCRIPTION: A scheduling availability API service for product teams embedding booking into their apps. Clients define resources, working hours, and buffer rules; the API computes bookable slots across time zones with conflict detection against synced Google/Outlook calendars, and holds slots during checkout flows.
TECH_STACK: Ruby (Rails API mode) + PostgreSQL + Redis slot holds + Sidekiq calendar sync + OAuth calendar APIs, deployed on Render
APP_TYPE: API service
LANGUAGE: Ruby
SCALE: ~300 req/sec, 500 client integrations, ~25 GB data
```

## 70. NudgeNumber — appointment reminder messaging API

```text
APP_DESCRIPTION: A messaging API service that sends appointment reminders for clinics, salons, and service businesses. Clients register appointments with reminder cadences; the service sends SMS and voice reminders with confirm/cancel keywords, writes responses back via webhooks, and tracks deliverability and opt-outs per number.
TECH_STACK: Ruby (Rails API mode) + PostgreSQL + Sidekiq send queues + Twilio/Telnyx SMS + Redis, deployed on AWS
APP_TYPE: API service
LANGUAGE: Ruby
SCALE: ~1.5M messages/day, 700 client integrations, ~80 GB data
```

## 71. ListingLattice — real estate listing syndication API

```text
APP_DESCRIPTION: A listing syndication API service for proptech developers. It ingests MLS feeds (RESO Web API), normalizes fields and photos across boards, deduplicates cross-listed properties, and serves search-ready listing data with geo queries, open-house times, and status-change webhooks.
TECH_STACK: Ruby (Rails API mode) + PostgreSQL/PostGIS + Elasticsearch + Sidekiq feed ingestion + S3 photo pipeline, deployed on AWS
APP_TYPE: API service
LANGUAGE: Ruby
SCALE: ~350 req/sec, 200 client integrations, ~1.2 TB data with photos
```

## 72. WageWeave — payroll tax calculation API

```text
APP_DESCRIPTION: A payroll tax calculation API service for HR and payroll platforms. Clients submit pay-run data (earnings, pretax deductions, work/residence locations), the service computes federal, state, and local withholding with reciprocity rules and wage-base caps, and returns per-employee tax breakdowns and employer liabilities.
TECH_STACK: Ruby (Rails API mode) + PostgreSQL + versioned tax-rule engine + Redis, deployed on AWS with SOC 2 controls
APP_TYPE: API service
LANGUAGE: Ruby
SCALE: ~150 req/sec with month-end spikes to 600, 180 client integrations, ~30 GB data
```

## 73. PerkPile — loyalty points ledger API

```text
APP_DESCRIPTION: A loyalty-points ledger API service for retail and hospitality brands. Clients post earn and burn events against member accounts, the double-entry ledger enforces balance integrity with expiration schedules and tier multipliers, and endpoints serve balances, activity history, and reward-catalog redemptions.
TECH_STACK: Ruby (Rails API mode) + PostgreSQL double-entry ledger + Redis + Sidekiq expiration jobs, deployed on AWS
APP_TYPE: API service
LANGUAGE: Ruby
SCALE: ~600 req/sec, 250 client integrations, ~90 GB data
```

## 74. MacroMenu — restaurant nutrition data API

```text
APP_DESCRIPTION: A nutrition data API service for restaurant chains and food-delivery apps. Clients query menu items for calories, macros, and allergens computed from recipe ingredient graphs, get FDA menu-labeling exports, and receive webhook updates when reformulated recipes change published nutrition facts.
TECH_STACK: Ruby (Rails API mode) + PostgreSQL recipe graph + Redis cache + Sidekiq recompute jobs, deployed on Render
APP_TYPE: API service
LANGUAGE: Ruby
SCALE: ~200 req/sec, 150 client integrations, ~15 GB data
```

## 75. FloatFerry — foreign exchange rates API

```text
APP_DESCRIPTION: A foreign-exchange rates API service for invoicing and travel apps. It aggregates rates from central-bank and market sources for 170 currencies, serves spot and historical endpoints with time-series queries, and offers conversion endpoints with client-configured markup and rate-lock windows.
TECH_STACK: Ruby (Rails API mode) + PostgreSQL time-series tables + Redis hot cache + Sidekiq rate fetchers, deployed on Fly.io
APP_TYPE: API service
LANGUAGE: Ruby
SCALE: ~1,100 req/sec, 2,000 client integrations, ~50 GB data
```

## 76. InkAnchor — e-signature API

```text
APP_DESCRIPTION: An e-signature API service for developers embedding signing into their products. Clients upload documents with signature/date/initial field placement, the service orchestrates multi-signer sequences with email/SMS links and identity checks, and returns completed PDFs with tamper-evident audit trails.
TECH_STACK: Ruby (Rails API mode) + PostgreSQL + S3 document storage + Sidekiq + HexaPDF signing + audit hash chains, deployed on AWS
APP_TYPE: API service
LANGUAGE: Ruby
SCALE: ~80 req/sec, 300 client integrations, ~400 GB documents
```

## 77. ClearGate — background screening API

```text
APP_DESCRIPTION: A background screening API service for gig platforms and staffing agencies. Clients submit candidate consent packages, the service orchestrates county criminal, MVR, and sex-offender registry checks across data providers with FCRA-compliant adverse-action workflows, and streams status webhooks as results clear.
TECH_STACK: Ruby (Rails API mode) + PostgreSQL + Sidekiq provider orchestration + encrypted PII vault, deployed on AWS
APP_TYPE: API service
LANGUAGE: Ruby
SCALE: ~40 req/sec, 90 client integrations, ~70 GB data
```

## 78. FrameForge — image processing API

```text
APP_DESCRIPTION: An image processing API service for content platforms. Clients request on-the-fly transforms (resize, crop, format conversion to WebP/AVIF, watermarking) via signed URLs against origin images, with a CDN-backed variant cache; batch endpoints regenerate variants when brand presets change.
TECH_STACK: Ruby (Rails API mode) + libvips (ruby-vips) + Redis + Sidekiq batch workers + S3/CloudFront, deployed on AWS
APP_TYPE: API service
LANGUAGE: Ruby
SCALE: ~900 req/sec at CDN origin, 450 client integrations, ~2 TB image variants
```

## 79. scrubdub — database anonymization CLI

```text
APP_DESCRIPTION: A CLI tool for backend developers that produces anonymized copies of production databases for staging and local dev. It reads a YAML policy mapping tables and columns to fakers (names, emails, SSNs, free text), streams a scrubbed dump preserving referential integrity, and fails builds on unpoliced PII columns.
TECH_STACK: Ruby CLI (thor) + pg gem streaming COPY + Faker + YAML policy engine, distributed as a gem
APP_TYPE: CLI
LANGUAGE: Ruby
SCALE: single user per invocation, databases up to 500 GB, streams without full local copy
```

## 80. railsage — Rails upgrade advisor CLI

```text
APP_DESCRIPTION: A CLI tool for teams planning Rails version upgrades. It scans a codebase for deprecated APIs, gem incompatibilities against the target Rails version, and config drift from framework defaults, then emits a phased upgrade plan with effort estimates and links to changed behavior notes.
TECH_STACK: Ruby CLI (thor) + parser gem AST analysis + bundler API + rubygems.org compatibility data, distributed as a gem
APP_TYPE: CLI
LANGUAGE: Ruby
SCALE: single user per invocation, codebases up to 1M lines, <200 MB working data
```

## 81. localeloom — i18n locale file manager CLI

```text
APP_DESCRIPTION: A CLI tool for developers maintaining translations in i18n apps. It diffs locale YAML/JSON files against the source language to find missing, orphaned, and stale keys, syncs with translation platforms (Lokalise, Crowdin), and lints interpolation-variable mismatches that crash at runtime.
TECH_STACK: Ruby CLI (thor) + YAML/JSON parsers + translation platform APIs + diff engine, distributed as a gem
APP_TYPE: CLI
LANGUAGE: Ruby
SCALE: single user per invocation, projects with up to 60 locales and 50k keys, <50 MB local data
```

## 82. leakpeek — secrets scanning CLI

```text
APP_DESCRIPTION: A CLI tool for security-minded developers that scans repositories for committed secrets. It matches API keys, private keys, and connection strings via pattern and entropy analysis across working tree and git history, supports baseline files to suppress accepted findings, and gates CI with severity thresholds.
TECH_STACK: Ruby CLI (thor) + rugged git bindings + regex/entropy detectors + SARIF output, distributed as a gem
APP_TYPE: CLI
LANGUAGE: Ruby
SCALE: single user or CI job per invocation, repos up to 200k commits, <500 MB scanned history
```

## 83. migright — migration safety linter CLI

```text
APP_DESCRIPTION: A CLI tool for Rails teams that lints ActiveRecord migrations for production safety before merge. It flags locking operations on large tables (non-concurrent index builds, column type changes, NOT NULL without backfill), suggests safe multi-step rewrites, and enforces rules in CI with per-table size hints.
TECH_STACK: Ruby CLI (thor) + parser gem AST checks + PostgreSQL catalog stats via pg gem, distributed as a gem
APP_TYPE: CLI
LANGUAGE: Ruby
SCALE: single CI job per invocation, apps with up to 5,000 migrations, <10 MB local data
```

## 84. gemproof — license compliance CLI

```text
APP_DESCRIPTION: A CLI tool for engineering and legal teams auditing open-source license compliance in Ruby projects. It resolves the full dependency tree from Gemfile.lock, classifies licenses with copyleft risk levels against a company policy file, generates attribution notices, and fails CI on newly introduced violations.
TECH_STACK: Ruby CLI (thor) + bundler integration + SPDX license data + policy DSL + SBOM (CycloneDX) export, distributed as a gem
APP_TYPE: CLI
LANGUAGE: Ruby
SCALE: single CI job per invocation, dependency trees up to 2,000 gems, <20 MB local data
```

## 85. groklog — log triage CLI

```text
APP_DESCRIPTION: A CLI tool for on-call engineers triaging production log files. It parses mixed-format logs (JSON lines, Rails, nginx), clusters similar errors by normalized fingerprint, surfaces frequency spikes against a time window, and renders a terminal summary with drill-down into representative stack traces.
TECH_STACK: Ruby CLI (thor) + streaming line parsers + fingerprint clustering + tty-table terminal UI, distributed as a gem
APP_TYPE: CLI
LANGUAGE: Ruby
SCALE: single user per invocation, log files up to 20 GB streamed, constant-memory processing
```

## 86. columncraft — CSV wrangling CLI

```text
APP_DESCRIPTION: A CLI tool for analysts and developers cleaning messy CSV exports. It profiles columns (types, null rates, outliers), applies declarative transform pipelines (rename, split, coerce dates, dedupe on keys), joins files on shared columns, and writes validated output with a rejects file for bad rows.
TECH_STACK: Ruby CLI (thor) + streaming CSV parser + transform pipeline DSL + JSON schema validation, distributed as a gem
APP_TYPE: CLI
LANGUAGE: Ruby
SCALE: single user per invocation, files up to 50M rows streamed, constant-memory processing
```

## 87. specsmith — OpenAPI client generator CLI

```text
APP_DESCRIPTION: A CLI tool for Ruby developers that generates typed API client gems from OpenAPI 3.1 specs. It emits resource classes with keyword-argument methods, response objects with typed attributes, retry/pagination helpers, and WebMock-based test stubs, and regenerates diffs cleanly when specs change.
TECH_STACK: Ruby CLI (thor) + OpenAPI parser + ERB code templates + rubocop autoformatting of output, distributed as a gem
APP_TYPE: CLI
LANGUAGE: Ruby
SCALE: single user per invocation, specs up to 800 endpoints, <30 MB generated code
```

## 88. thumbtack — asset optimization CLI

```text
APP_DESCRIPTION: A CLI tool for web developers that optimizes image and SVG assets before deploy. It recompresses PNG/JPEG, converts to WebP/AVIF with quality budgets per directory, strips EXIF metadata, minifies SVGs, and writes a manifest of size savings; a check mode fails CI when unoptimized assets land.
TECH_STACK: Ruby CLI (thor) + ruby-vips + svg_optimizer + parallel workers + manifest JSON, distributed as a gem
APP_TYPE: CLI
LANGUAGE: Ruby
SCALE: single user or CI job per invocation, asset trees up to 50k files, 8 parallel workers
```

## 89. feedfettle — RSS/Atom feed validator CLI

```text
APP_DESCRIPTION: A CLI tool for publishers and podcast producers that validates RSS and Atom feeds. It checks XML validity, required channel/item elements, podcast namespace tags (iTunes, podcast:), enclosure reachability with byte-range support, and episode GUID stability across fetches, reporting errors with spec citations.
TECH_STACK: Ruby CLI (thor) + Nokogiri XML parsing + HTTP HEAD probes + spec rule engine, distributed as a gem
APP_TYPE: CLI
LANGUAGE: Ruby
SCALE: single user per invocation, feeds up to 10k items, batch mode for 500 feeds per run
```

## 90. SkuSluice — product catalog feed pipeline

```text
APP_DESCRIPTION: A data pipeline that ingests merchant product catalogs for a shopping comparison site. It pulls supplier feeds (CSV, XML, Google Merchant format) on schedules, normalizes attributes and units, matches duplicate products across merchants with fuzzy matching, and publishes searchable offers with price-change history.
TECH_STACK: Ruby + Sidekiq Pro pipelines + PostgreSQL + Redis + Elasticsearch + S3 feed staging, deployed on AWS
APP_TYPE: data pipeline
LANGUAGE: Ruby
SCALE: 40M offers refreshed daily, ~1,200 feeds, ~900 GB data
```

## 91. ClaimCurrent — healthcare claims processing pipeline

```text
APP_DESCRIPTION: A data pipeline for a medical billing company that processes insurance claims. It ingests EDI 837 claim files from clinic practice-management systems, validates against payer-specific rules to catch rejections before submission, routes claims to clearinghouses, and reconciles 835 remittances back to patient accounts.
TECH_STACK: Ruby + Sidekiq + PostgreSQL + EDI parsing + SFTP payer connections + encrypted S3 archive, deployed on AWS (HIPAA controls)
APP_TYPE: data pipeline
LANGUAGE: Ruby
SCALE: 300k claims/day, 450 clinic sources, ~600 GB data
```

## 92. LoamPulse — farm sensor telemetry pipeline

```text
APP_DESCRIPTION: A data pipeline for a precision-agriculture company processing field sensor telemetry. It ingests soil-moisture, temperature, and weather-station readings from LoRaWAN gateways, validates and gap-fills series, computes irrigation recommendations per field zone against crop models, and pushes alerts when readings cross agronomist-set thresholds.
TECH_STACK: Ruby + Sidekiq + TimescaleDB (PostgreSQL) + MQTT ingestion bridge + Redis + Twilio alerts, deployed on AWS
APP_TYPE: data pipeline
LANGUAGE: Ruby
SCALE: 25M sensor readings/day from 40k sensors, ~2 TB time-series data
```

## 93. PressPulse — media monitoring ingestion pipeline

```text
APP_DESCRIPTION: A data pipeline for a media monitoring service that tracks brand mentions for PR teams. It crawls news sites and RSS feeds, deduplicates syndicated articles by content fingerprint, extracts entities and sentiment per mention, and matches articles against client keyword profiles to feed morning digest emails.
TECH_STACK: Ruby + Sidekiq crawl/enrich queues + PostgreSQL + Elasticsearch + Redis + NLP service calls, deployed on AWS
APP_TYPE: data pipeline
LANGUAGE: Ruby
SCALE: 1.5M articles/day from 90k sources, ~1.5 TB indexed data
```

## 94. TallyTruce — bank transaction reconciliation pipeline

```text
APP_DESCRIPTION: A data pipeline for a fintech bookkeeping service that reconciles client bank activity. It ingests transaction feeds via banking aggregators and OFX files, matches transactions to invoices and bills with amount/date/counterparty heuristics, flags unmatched items for bookkeeper review queues, and posts matched entries to the general ledger.
TECH_STACK: Ruby + Sidekiq + PostgreSQL + Plaid/OFX ingestion + matching-rules engine + Redis, deployed on AWS
APP_TYPE: data pipeline
LANGUAGE: Ruby
SCALE: 4M transactions/day across 30k client accounts, ~250 GB data
```

## 95. OpenOmen — email engagement analytics pipeline

```text
APP_DESCRIPTION: A data pipeline for an email marketing platform processing engagement events. It consumes delivery, open, click, bounce, and complaint webhooks from sending infrastructure, sessionizes events per campaign and subscriber, updates deliverability health scores per sending domain, and materializes campaign report rollups.
TECH_STACK: Ruby + Sidekiq + PostgreSQL + ClickHouse event store + Redis + webhook ingestion endpoints, deployed on AWS
APP_TYPE: data pipeline
LANGUAGE: Ruby
SCALE: 60M events/day, 15k sending domains scored, ~3 TB event data
```

## 96. DockDocket — 3PL warehouse event pipeline

```text
APP_DESCRIPTION: A data pipeline for a third-party logistics provider synchronizing warehouse events with client stores. It ingests WMS events (receipts, picks, packs, shipments, cycle counts), reconciles inventory levels per client SKU across warehouses, pushes stock and tracking updates to Shopify/Amazon channels, and flags shrinkage discrepancies.
TECH_STACK: Ruby + Sidekiq + PostgreSQL + Redis + Shopify/Amazon SP-API connectors + SFTP WMS feeds, deployed on AWS
APP_TYPE: data pipeline
LANGUAGE: Ruby
SCALE: 8M warehouse events/day, 220 client stores, ~400 GB data
```

## 97. WattWarden — smart meter data pipeline

```text
APP_DESCRIPTION: A data pipeline for a municipal utility processing smart-meter readings. It ingests 15-minute interval reads via AMI head-end exports, validates and estimates gaps per regulatory VEE rules, detects usage anomalies suggesting leaks or meter tampering, and feeds billing determinants and customer usage dashboards.
TECH_STACK: Ruby + Sidekiq + TimescaleDB (PostgreSQL) + SFTP head-end ingestion + Redis + anomaly rules engine, deployed on Azure
APP_TYPE: data pipeline
LANGUAGE: Ruby
SCALE: 38M interval reads/day from 400k meters, ~4 TB time-series data
```

## 98. VacancyVane — job posting aggregation pipeline

```text
APP_DESCRIPTION: A data pipeline for a niche job board aggregating postings in the skilled trades. It crawls company career pages and ATS APIs, deduplicates reposted listings, normalizes titles and pay ranges to a trade taxonomy, geocodes work locations, and expires stale postings; matched jobs trigger candidate alert emails.
TECH_STACK: Ruby + Sidekiq crawl queues + PostgreSQL + Elasticsearch + Redis + geocoding API, deployed on Render
APP_TYPE: data pipeline
LANGUAGE: Ruby
SCALE: 500k postings/day crawled from 12k sources, ~350 GB data
```

## 99. DocketDrift — court records ingestion pipeline

```text
APP_DESCRIPTION: A data pipeline for a legal research company tracking civil court dockets. It polls state e-filing portals and PACER for docket updates on watched cases, parses filings into structured events (motions, orders, hearings), OCRs scanned documents, and pushes same-day alerts to litigation teams monitoring parties or judges.
TECH_STACK: Ruby + Sidekiq + PostgreSQL + Tesseract OCR workers + S3 document store + portal scrapers, deployed on AWS
APP_TYPE: data pipeline
LANGUAGE: Ruby
SCALE: 900k docket entries/day, 70k watched cases, ~2.5 TB documents
```

## 100. RegisterRollup — franchise POS sales pipeline

```text
APP_DESCRIPTION: A data pipeline for a restaurant franchisor consolidating point-of-sale data across franchise locations. It ingests nightly POS exports and streaming ticket data from mixed systems (Toast, Square, NCR), normalizes menu items to a corporate hierarchy, computes royalty and ad-fund fees from gross sales, and feeds same-store-sales dashboards.
TECH_STACK: Ruby + Sidekiq + PostgreSQL + Redis + POS vendor APIs/SFTP + dbt-style rollup jobs, deployed on AWS
APP_TYPE: data pipeline
LANGUAGE: Ruby
SCALE: 6M ticket lines/day from 850 locations, ~700 GB data
```
