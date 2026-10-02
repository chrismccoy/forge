# WordPress Blueprint Types — Copy-Paste Input Sets

Copy a fenced block into the prompt as-is.

---

# Plugins (1-45)

## 1. BookingBarn — appointment scheduling

```text
APP_DESCRIPTION: A WordPress plugin that adds appointment scheduling for service businesses (salons, tutors, consultants). Providers define services, durations, and working hours; customers book from a front-end calendar with buffer times and Stripe deposits; both sides get email/SMS reminders.
TECH_STACK: WordPress plugin (PHP) + custom post types + Gutenberg booking block + REST endpoints + MySQL custom tables + Stripe
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 200 concurrent visitors, ~20 req/sec, ~3 GB data
```

## 2. StockShelf — WooCommerce inventory alerts

```text
APP_DESCRIPTION: A WordPress plugin extending WooCommerce with advanced inventory management. Shop owners set per-product reorder points and supplier records, receive low-stock digests, log purchase orders and deliveries, and see stock-turn reports; customers can join back-in-stock waitlists.
TECH_STACK: WordPress plugin (PHP) + WooCommerce hooks + MySQL custom tables + Gutenberg waitlist block + WP-Cron digests
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 400 concurrent shoppers, ~50 req/sec, 30k SKUs, ~5 GB data
```

## 3. PewNews — church management

```text
APP_DESCRIPTION: A WordPress plugin that turns a church website into a congregation hub. Staff manage sermon archives with series and speakers, small-group signups, volunteer rosters for services, and prayer-request submission with private moderation.
TECH_STACK: WordPress plugin (PHP) + custom post types/taxonomies + Gutenberg blocks (sermon player, group signup) + REST endpoints + role-based capabilities
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 150 concurrent visitors Sunday peak, ~15 req/sec, ~10 GB sermon audio metadata
```

## 4. CaseCloak — law firm client intake

```text
APP_DESCRIPTION: A WordPress plugin for law firm websites that handles confidential client intake. Prospects complete practice-area-specific intake forms with conflict-check questions, files upload to encrypted storage, staff review submissions in a private queue with status tracking, and accepted intakes export to the firm's case-management system.
TECH_STACK: WordPress plugin (PHP) + multi-step Gutenberg form block + encrypted uploads + MySQL custom tables + REST export API + audit logging
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 60 concurrent visitors, ~8 req/sec, ~40 GB documents
```

## 5. HarvestCart — farm CSA subscriptions

```text
APP_DESCRIPTION: A WordPress plugin that sells CSA (community-supported agriculture) shares from a farm's website. Members subscribe to seasonal share sizes with weekly pickup locations, customize box contents from weekly availability, pause for vacations, and farmers plan harvest quantities from subscription rosters.
TECH_STACK: WordPress plugin (PHP) + Stripe subscriptions + custom post types + Gutenberg share-signup block + MySQL box-customization tables + WP-Cron cutoffs
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 120 concurrent members at customization deadline, ~12 req/sec, ~2 GB data
```

## 6. GradeBookWP — course LMS

```text
APP_DESCRIPTION: A WordPress plugin that adds a lightweight LMS for training providers. Instructors build courses from lessons and quizzes with prerequisites, students track progress and earn PDF certificates, and admins report completion rates per cohort — all inside the existing WordPress site.
TECH_STACK: WordPress plugin (PHP) + custom post types + Gutenberg lesson/quiz blocks + MySQL progress tables + PDF certificate generation + REST endpoints
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 500 concurrent students, ~40 req/sec, ~8 GB data
```

## 7. RescueRoster — pet adoption listings

```text
APP_DESCRIPTION: A WordPress plugin for animal shelters that manages adoptable-pet listings and applications. Staff publish pets with medical/temperament profiles and status workflow (available, pending, adopted), visitors filter by species/size/age and submit adoption applications, and volunteers coordinate foster placements.
TECH_STACK: WordPress plugin (PHP) + custom post types/taxonomies + Gutenberg pet-grid and application blocks + MySQL application tables + email notifications
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 250 concurrent visitors, ~25 req/sec, ~6 GB photos metadata
```

## 8. QuoteForge — service quote builder

```text
APP_DESCRIPTION: A WordPress plugin for trade businesses (landscaping, painting, roofing) that generates instant quotes. Owners define pricing rules per service with modifiers (area, materials, access difficulty), visitors build quotes through a step-by-step estimator, and qualified leads with quote details land in an admin pipeline.
TECH_STACK: WordPress plugin (PHP) + Gutenberg estimator block (multi-step) + pricing-rule engine + MySQL lead tables + REST endpoints + email/CRM webhooks
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 180 concurrent visitors, ~18 req/sec, ~1 GB data
```

## 9. StampCard — customer loyalty

```text
APP_DESCRIPTION: A WordPress plugin adding a points-based loyalty program to WooCommerce stores. Customers earn points on purchases, reviews, and referrals, redeem them as cart discounts, and see progress toward VIP tiers; owners configure earning rules and expiry policies and track program liability.
TECH_STACK: WordPress plugin (PHP) + WooCommerce hooks + MySQL points ledger + Gutenberg account-dashboard block + WP-Cron expiry jobs
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 600 concurrent shoppers, ~60 req/sec, 80k customer accounts, ~4 GB data
```

## 10. VenueVault — wedding venue inquiries

```text
APP_DESCRIPTION: A WordPress plugin for wedding venues that manages tour bookings and date availability. Couples check date availability on a public calendar, book venue tours in staff-defined slots, and receive brochure follow-ups; venue coordinators manage holds, deposits, and a season-at-a-glance dashboard.
TECH_STACK: WordPress plugin (PHP) + Gutenberg availability-calendar and tour-booking blocks + MySQL booking tables + Stripe deposits + iCal feeds
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 100 concurrent visitors, ~10 req/sec, ~1 GB data
```

## 11. DocsDrawer — document library

```text
APP_DESCRIPTION: A WordPress plugin that adds a searchable document library for associations and municipalities. Admins publish PDFs and policies with categories, versions, and effective dates; visitors filter and full-text search documents; download counts and version history give admins an audit trail.
TECH_STACK: WordPress plugin (PHP) + custom post types + full-text search index tables + Gutenberg library block with filters + version-controlled media handling
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 200 concurrent visitors, ~20 req/sec, ~60 GB documents
```

## 12. RaffleRight — fundraising raffles

```text
APP_DESCRIPTION: A WordPress plugin for nonprofits running compliant online raffles. Organizers create raffles with ticket tiers, entry limits, and draw dates; supporters buy numbered tickets with receipts; draws run with an auditable random selection and winners are notified automatically.
TECH_STACK: WordPress plugin (PHP) + Stripe Checkout + MySQL ticket ledger + Gutenberg raffle block + auditable draw log + WP-Cron draw scheduling
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 800 concurrent supporters at draw-day peak, ~80 req/sec, ~2 GB data
```

## 13. MenuMason — restaurant menu manager

```text
APP_DESCRIPTION: A WordPress plugin that manages restaurant menus with dietary intelligence. Staff maintain dishes with prices, allergens, and dietary tags across lunch/dinner/seasonal menus; visitors filter by allergen and diet; menus render as styled blocks and auto-generate printable PDFs.
TECH_STACK: WordPress plugin (PHP) + custom post types + Gutenberg menu blocks with dietary filters + PDF export + schema.org Menu markup
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 300 concurrent visitors dinner peak, ~30 req/sec, <1 GB data
```

## 14. JobJoist — niche job board

```text
APP_DESCRIPTION: A WordPress plugin that runs a paid niche job board. Employers buy listing packages and post jobs with application routing (email, external URL, or on-site form), candidates filter and set job-alert emails, and admins moderate listings and track package revenue.
TECH_STACK: WordPress plugin (PHP) + custom post types + Stripe packages + Gutenberg job-search block + MySQL alert subscriptions + WP-Cron alert digests
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 500 concurrent visitors, ~45 req/sec, ~5 GB data
```

## 15. ReviewRoots — verified review collector

```text
APP_DESCRIPTION: A WordPress plugin that collects and displays verified customer reviews for service businesses. Post-purchase emails invite reviews via one-time links, reviews display with owner responses and star aggregates, and structured-data markup feeds review stars into search results.
TECH_STACK: WordPress plugin (PHP) + one-time token review forms + MySQL review tables + Gutenberg review-wall block + schema.org markup + moderation queue
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 250 concurrent visitors, ~25 req/sec, ~3 GB data
```

## 16. CrowdFundr — donation campaigns

```text
APP_DESCRIPTION: A WordPress plugin for nonprofits running donation campaigns with goals and matching. Campaigns show progress bars and donor walls, donors give one-time or monthly with tribute options, matching-gift windows double displayed impact, and finance staff export gift batches for accounting.
TECH_STACK: WordPress plugin (PHP) + Stripe (one-time + subscriptions) + MySQL gift ledger + Gutenberg campaign and donor-wall blocks + CSV exports
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 1,000 concurrent donors during giving-day peak, ~100 req/sec, ~4 GB data
```

## 17. SeatSaver — waitlist and queue

```text
APP_DESCRIPTION: A WordPress plugin providing waitlists for anything bookable — classes, products, tables, appointments. Visitors join waitlists with position visibility, automatic promotion fires when capacity opens with a timed claim window, and owners see conversion analytics per waitlist.
TECH_STACK: WordPress plugin (PHP) + MySQL queue tables + Gutenberg waitlist block + WP-Cron promotion jobs + email/SMS claim notifications
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 400 concurrent visitors, ~35 req/sec, ~2 GB data
```

## 18. PodPress — podcast publishing

```text
APP_DESCRIPTION: A WordPress plugin that publishes podcasts from a WordPress site. Podcasters upload episodes with show notes and chapters, the plugin generates compliant RSS feeds for Apple/Spotify, embeds a customizable player block, and tracks download statistics per episode and geography.
TECH_STACK: WordPress plugin (PHP) + custom post types + RSS feed generation + Gutenberg player block + download-stats tables + media offload to S3-compatible storage
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 2,000 feed hits/hour, ~30 req/sec, ~200 GB audio
```

## 19. TrailPass — tour operator bookings

```text
APP_DESCRIPTION: A WordPress plugin for tour operators selling guided tours. Operators schedule departures with capacity and guide assignments, travelers book seats with participant details and waivers, weather cancellations trigger rebooking flows, and manifests print per departure.
TECH_STACK: WordPress plugin (PHP) + custom post types + Gutenberg tour-booking block + MySQL departure/manifest tables + Stripe + waiver e-signature capture
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 300 concurrent visitors summer peak, ~30 req/sec, ~3 GB data
```

## 20. FormFerry — form-to-CRM bridge

```text
APP_DESCRIPTION: A WordPress plugin that routes form submissions from popular form plugins into CRMs. Admins map form fields to HubSpot/Salesforce/Pipedrive objects with transformation rules, failed deliveries queue with retry and alerting, and a delivery log shows every submission's journey.
TECH_STACK: WordPress plugin (PHP) + form-plugin hook adapters + field-mapping UI + MySQL delivery queue + CRM REST connectors + retry/backoff engine
APP_TYPE: web app
LANGUAGE: PHP
SCALE: ~10k submissions/day across sites, ~15 req/sec, ~2 GB delivery logs
```

## 21. GlossaryGnome — knowledge base and glossary

```text
APP_DESCRIPTION: A WordPress plugin that adds a knowledge base with auto-linking glossary for SaaS documentation sites. Writers manage articles with categories and helpfulness voting, glossary terms auto-link with hover definitions across all content, and search analytics reveal content gaps.
TECH_STACK: WordPress plugin (PHP) + custom post types + content-filter auto-linking + Gutenberg KB-search block + MySQL search-analytics tables
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 600 concurrent readers, ~55 req/sec, ~2 GB data
```

## 22. ConsentCraft — privacy consent manager

```text
APP_DESCRIPTION: A WordPress plugin that manages cookie and tracking consent for GDPR/CCPA compliance. Site owners declare services by category, visitors set granular consent stored with proof records, scripts block until consented, and a consent log supports regulator audits.
TECH_STACK: WordPress plugin (PHP) + script-blocking loader + consent banner block + MySQL consent-proof log + geolocation rule sets + policy-page generator
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 1,500 concurrent visitors, ~150 req/sec (cached banner), ~10 GB consent logs
```

## 23. BidBoard — silent auction

```text
APP_DESCRIPTION: A WordPress plugin for charity silent auctions. Organizers list donated items with starting bids and increments, bidders register and bid from phones with outbid notifications, soft-close extensions prevent sniping, and winners check out through integrated payment with receipts.
TECH_STACK: WordPress plugin (PHP) + heartbeat/REST live bidding + MySQL bid ledger + Gutenberg auction-catalog block + Stripe checkout + SMS outbid alerts
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 500 concurrent bidders event night, ~90 req/sec peak, ~1 GB data
```

## 24. FieldNotes — inspection reports

```text
APP_DESCRIPTION: A WordPress plugin for home and property inspectors that produces client-ready reports. Inspectors complete mobile-friendly checklists with photos and severity ratings per finding, reports assemble into branded PDFs with summaries, and clients access reports through expiring secure links.
TECH_STACK: WordPress plugin (PHP) + mobile-first checklist forms + photo annotation + PDF generation + MySQL findings tables + tokenized client access
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 40 concurrent inspectors, ~10 req/sec, ~150 GB report photos
```

## 25. StudioSlots — fitness class packs

```text
APP_DESCRIPTION: A WordPress plugin for fitness studios selling class packs and drop-ins. Members buy punch packs or unlimited months, reserve class spots with waitlist promotion and cancellation windows, and instructors check in attendees; owners see fill rates and pack-liability reports.
TECH_STACK: WordPress plugin (PHP) + Stripe + MySQL credits ledger + Gutenberg schedule block + WP-Cron reminders + QR check-in
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 350 concurrent members at schedule release, ~35 req/sec, ~3 GB data
```

## 26. PressKitPro — media kit manager

```text
APP_DESCRIPTION: A WordPress plugin for bands, authors, and speakers that maintains an always-current press kit. Owners manage bios in multiple lengths, approved photos with usage terms, press clippings, and tech riders; journalists download watermarked assets through a gated request flow with usage tracking.
TECH_STACK: WordPress plugin (PHP) + custom post types + gated download tokens + Gutenberg press-kit block + MySQL request log + watermarking
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 80 concurrent visitors, ~8 req/sec, ~25 GB assets
```

## 27. RouteRider — delivery zone checkout

```text
APP_DESCRIPTION: A WordPress plugin extending WooCommerce for local-delivery businesses. Owners draw delivery zones on a map with per-zone fees and minimums, customers see zone-validated delivery slots at checkout, and drivers get an optimized stop list per delivery window.
TECH_STACK: WordPress plugin (PHP) + WooCommerce checkout hooks + Leaflet zone editor + MySQL slot-capacity tables + route-ordering algorithm + driver manifest page
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 250 concurrent shoppers, ~30 req/sec, ~2 GB data
```

## 28. TutorTether — tutoring marketplace

```text
APP_DESCRIPTION: A WordPress plugin that runs a tutoring marketplace on a school-support site. Tutors publish profiles with subjects and hourly rates, parents book sessions matched by subject and availability, sessions confirm with video links, and the site takes a commission on payments.
TECH_STACK: WordPress plugin (PHP) + custom post types + Gutenberg tutor-search and booking blocks + Stripe Connect commissions + MySQL session tables + calendar sync
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 200 concurrent parents evening peak, ~20 req/sec, ~2 GB data
```

## 29. WikiWard — internal wiki hardening

```text
APP_DESCRIPTION: A WordPress plugin that turns a WordPress install into a permissioned internal wiki for companies. Spaces group pages with team-level read/edit permissions, page changes track with diff history and required review for sensitive spaces, and stale-page reports prompt owners to update or archive.
TECH_STACK: WordPress plugin (PHP) + hierarchical custom post types + role/space permission layer + revision diff UI + MySQL page-ownership tables + staleness WP-Cron audits
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 300 concurrent employees, ~40 req/sec, ~8 GB data
```

## 30. ShowTimeWP — cinema showtimes and tickets

```text
APP_DESCRIPTION: A WordPress plugin for independent cinemas selling tickets from their own site. Programmers schedule films across screens with pricing tiers, moviegoers pick seats from auditorium maps and receive QR tickets, and the box office scans tickets and sees per-showing sales.
TECH_STACK: WordPress plugin (PHP) + custom post types + seat-map Gutenberg block + MySQL seat-lock tables + Stripe + QR ticket scanning page
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 600 concurrent buyers for premiere on-sales, ~70 req/sec peak, ~3 GB data
```

## 31. GrantGate — grant application portal

```text
APP_DESCRIPTION: A WordPress plugin for community foundations that accepts and reviews grant applications. Applicants complete staged applications with budgets and attachments against published deadlines, reviewers score submissions on rubrics with conflict-of-interest recusal, and boards see ranked funding dockets.
TECH_STACK: WordPress plugin (PHP) + multi-stage form engine + MySQL application/scoring tables + reviewer role workflow + document uploads + deadline WP-Cron enforcement
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 150 concurrent applicants at deadline, ~15 req/sec, ~50 GB attachments
```

## 32. SwapShelf — community classifieds

```text
APP_DESCRIPTION: A WordPress plugin adding neighborhood classifieds to community sites. Members post items for sale, free, or trade with photos and expiry, message each other through anonymized relay, and moderators handle reports; expired listings auto-archive.
TECH_STACK: WordPress plugin (PHP) + custom post types + anonymized messaging relay + Gutenberg listings block + MySQL message tables + WP-Cron expiry
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 350 concurrent members, ~30 req/sec, ~8 GB photos metadata
```

## 33. ChefTable — supper club reservations

```text
APP_DESCRIPTION: A WordPress plugin for pop-up supper clubs and private chefs. Chefs announce dated dinner events with set menus and seat counts, guests reserve and prepay with dietary notes, waitlists fill cancellations automatically, and chefs export per-event guest and allergy lists.
TECH_STACK: WordPress plugin (PHP) + custom post types + Stripe prepayment + Gutenberg event-reservation block + MySQL guest tables + waitlist automation
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 200 concurrent guests at announcement drop, ~25 req/sec, <1 GB data
```

## 34. BadgeBloom — membership cards and perks

```text
APP_DESCRIPTION: A WordPress plugin for museums and gardens managing memberships with digital cards. Members join tiers with auto-renewal, receive wallet-compatible digital membership cards, and redeem partner perks; front-desk staff verify membership by QR scan and admissions reports track visit patterns.
TECH_STACK: WordPress plugin (PHP) + Stripe subscriptions + Apple/Google Wallet pass generation + QR verification endpoint + MySQL visit-log tables
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 250 concurrent members, ~25 req/sec, 40k members, ~3 GB data
```

## 35. HomeworkHub — school assignment portal

```text
APP_DESCRIPTION: A WordPress plugin for small private schools posting assignments and collecting submissions. Teachers post assignments per class with due dates and rubrics, students submit files or text with timestamp proof, parents see upcoming-work digests, and teachers grade in a queue with feedback.
TECH_STACK: WordPress plugin (PHP) + class/role structure + submission uploads + MySQL grade tables + parent digest WP-Cron + Gutenberg assignment-list block
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 400 concurrent students at due-date peaks, ~40 req/sec, ~30 GB submissions
```

## 36. VineVault — winery club allocations

```text
APP_DESCRIPTION: A WordPress plugin for wineries running wine-club allocations. Members join club tiers with quarterly allocations, customize shipments within allocation rules during claim windows, age verification gates checkout, and compliance rules block shipping to restricted states.
TECH_STACK: WordPress plugin (PHP) + WooCommerce integration + MySQL allocation tables + state-compliance rule engine + age-verification gate + claim-window WP-Cron
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 300 concurrent members during release windows, ~35 req/sec, ~2 GB data
```

## 37. SpeakEasy — conference session manager

```text
APP_DESCRIPTION: A WordPress plugin for community conferences managing calls-for-papers through published schedules. Speakers submit talk proposals, organizers review blind with scoring, accepted talks build a multi-track schedule block with personal agendas, and attendees rate sessions.
TECH_STACK: WordPress plugin (PHP) + custom post types + blind-review workflow + Gutenberg schedule-grid block + MySQL rating tables + speaker notifications
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 800 concurrent attendees during event, ~60 req/sec, ~2 GB data
```

## 38. RentRack — equipment rental

```text
APP_DESCRIPTION: A WordPress plugin for equipment rental shops (bikes, kayaks, tools). Owners list rentable items with hourly/daily rates, deposits, and quantity; customers book date ranges with availability conflict prevention; returns process with damage notes and deposit adjustments.
TECH_STACK: WordPress plugin (PHP) + custom post types + availability engine with MySQL reservation tables + Stripe deposits/captures + Gutenberg rental-search block
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 150 concurrent customers weekend peak, ~15 req/sec, ~2 GB data
```

## 39. AlumniArc — alumni network

```text
APP_DESCRIPTION: A WordPress plugin for school alumni associations. Alumni claim verified profiles by graduation year, browse an opt-in directory, post class notes and job opportunities, RSVP to reunions with ticket purchase, and the association tracks engagement per class cohort.
TECH_STACK: WordPress plugin (PHP) + verified registration flow + opt-in directory with privacy controls + Gutenberg directory/RSVP blocks + Stripe + MySQL engagement tables
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 500 concurrent alumni at reunion announcements, ~40 req/sec, 25k profiles, ~5 GB data
```

## 40. ParcelPost — local pickup lockers

```text
APP_DESCRIPTION: A WordPress plugin extending WooCommerce with smart-locker pickup. Checkout offers locker locations with live compartment availability, fulfilled orders reserve compartments and send pickup codes, expired pickups release compartments with refund workflow, and staff see locker utilization.
TECH_STACK: WordPress plugin (PHP) + WooCommerce shipping method + locker-provider REST API + MySQL reservation tables + pickup-code notifications + WP-Cron expiry
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 200 concurrent shoppers, ~20 req/sec, 15 locker sites, ~1 GB data
```

## 41. HerdBook — livestock registry

```text
APP_DESCRIPTION: A WordPress plugin for breed associations maintaining livestock registries. Breeders register animals with pedigrees, DNA-test records, and transfer history; pedigree trees render interactively; show results record placements; and the registrar approves registrations with certificate generation.
TECH_STACK: WordPress plugin (PHP) + custom post types + pedigree-tree Gutenberg block + MySQL lineage tables + PDF certificates + registrar approval workflow
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 100 concurrent breeders, ~10 req/sec, 200k animal records, ~8 GB data
```

## 42. SafeSend — secure client file exchange

```text
APP_DESCRIPTION: A WordPress plugin for accountants and advisors exchanging sensitive files with clients. Clients upload documents through expiring encrypted links tied to their portal account, staff organize files per client with retention policies, and every access logs for compliance; files never sit in the public media library.
TECH_STACK: WordPress plugin (PHP) + encrypted off-library storage + tokenized expiring links + client portal roles + MySQL access-audit tables + retention WP-Cron
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 150 concurrent clients tax-season peak, ~15 req/sec, ~200 GB files
```

## 43. TroopTrack — scouting group manager

```text
APP_DESCRIPTION: A WordPress plugin for scouting troops and youth groups. Leaders schedule meetings and campouts with permission-slip e-signatures, parents RSVP kids and pay activity fees, badge progress tracks per scout with requirement sign-offs, and rosters export for insurance filings.
TECH_STACK: WordPress plugin (PHP) + custom post types + e-signature capture + Stripe fees + MySQL badge-progress tables + roster CSV exports + reminder WP-Cron
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 120 concurrent parents, ~12 req/sec, ~5 GB data
```

## 44. HeatMapWP — content analytics

```text
APP_DESCRIPTION: A WordPress plugin giving site owners privacy-friendly content analytics without external services. A lightweight beacon records scroll depth, click positions, and reading time per post (no personal data), dashboards render heatmap overlays on page previews, and editors see engagement scores per article.
TECH_STACK: WordPress plugin (PHP) + first-party JS beacon + MySQL aggregate event tables + heatmap-overlay admin UI + data-retention pruning WP-Cron
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 3,000 concurrent visitors across tracked pages, ~250 beacon req/sec, ~20 GB aggregates
```

## 45. StagePass — theater season subscriptions

```text
APP_DESCRIPTION: A WordPress plugin for regional theaters selling season subscriptions with seat retention. Subscribers pick fixed or flex packages, keep their seats year over year with renewal windows, exchange tickets between performances within rules, and the box office manages holds and single-ticket release timing.
TECH_STACK: WordPress plugin (PHP) + seat-inventory MySQL tables + renewal-window engine + Stripe + Gutenberg subscription and exchange blocks + box-office admin screens
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 400 concurrent subscribers at renewal open, ~45 req/sec, ~3 GB data
```

---

# Themes (46-70)

## 46. Tablecloth — restaurant theme

```text
APP_DESCRIPTION: A WordPress block theme for restaurants. It ships menu-presentation patterns with price alignment, reservation call-to-action sections, hours/location blocks with open-now states, chef and story layouts, and food-photography-forward hero patterns — all editable without code.
TECH_STACK: WordPress block theme (PHP + theme.json) + block patterns + style variations + schema.org Restaurant markup
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 400 concurrent visitors dinner-decision peak, ~40 req/sec (page-cached), ~5 GB media
```

## 47. Counsel — law firm theme

```text
APP_DESCRIPTION: A WordPress block theme for law firms. Practice-area landing patterns with credibility sections, attorney profile layouts with bar admissions, results/verdict showcases with compliance disclaimers, and consultation-intake CTAs — designed to satisfy conservative-industry review committees.
TECH_STACK: WordPress block theme (PHP + theme.json) + block patterns + attorney profile patterns + accessibility WCAG 2.2 AA components
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 150 concurrent visitors, ~15 req/sec, ~2 GB media
```

## 48. Vitals — medical clinic theme

```text
APP_DESCRIPTION: A WordPress block theme for medical and dental clinics. Service-line pages with insurance-accepted blocks, provider directories with credentials and languages, patient-forms download sections, and appointment-request CTAs — with large-type accessibility styles for older patients.
TECH_STACK: WordPress block theme (PHP + theme.json) + block patterns + provider directory patterns + WCAG-audited high-contrast style variation
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 250 concurrent visitors, ~25 req/sec, ~3 GB media
```

## 49. Encore — band and musician theme

```text
APP_DESCRIPTION: A WordPress block theme for bands and solo musicians. Tour-date listing patterns with ticket links, discography grids with streaming-service buttons, full-bleed video heroes, press-quote walls, and mailing-list capture sections tuned for merch-drop announcements.
TECH_STACK: WordPress block theme (PHP + theme.json) + block patterns + audio/video embed patterns + dark stage-lighting style variations
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 2,000 concurrent visitors on tour announcement, ~150 req/sec (cached), ~10 GB media
```

## 50. Gather — wedding venue theme

```text
APP_DESCRIPTION: A WordPress block theme for wedding and event venues. Gallery-driven space showcases with capacity specs, seasonal pricing tables, preferred-vendor directories, real-wedding story layouts, and tour-request CTAs — image-heavy design with performance-conscious lazy loading.
TECH_STACK: WordPress block theme (PHP + theme.json) + block patterns + gallery patterns with responsive images + inquiry CTA patterns
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 300 concurrent visitors engagement-season peak, ~30 req/sec, ~20 GB media
```

## 51. Chalkboard — school theme

```text
APP_DESCRIPTION: A WordPress block theme for K-12 schools. News and announcement layouts with urgent-banner support, staff directories by department, calendar-forward homepage patterns, enrollment funnel pages, and multi-audience navigation (parents, students, staff) — district-accessibility compliant.
TECH_STACK: WordPress block theme (PHP + theme.json) + block patterns + announcement banner patterns + WCAG 2.2 AA + multi-audience menu patterns
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 800 concurrent parents on snow-day mornings, ~80 req/sec (cached), ~4 GB media
```

## 52. Steeple — church theme

```text
APP_DESCRIPTION: A WordPress block theme for churches. Service-times hero patterns, sermon-series archives with media players, ministry and small-group grids, giving CTAs, and event layouts — welcoming typography with multilingual-ready patterns for diverse congregations.
TECH_STACK: WordPress block theme (PHP + theme.json) + block patterns + sermon archive patterns + giving CTA patterns
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 300 concurrent visitors Sunday, ~30 req/sec, ~8 GB media
```

## 53. Hearthstay — B&B and inn theme

```text
APP_DESCRIPTION: A WordPress block theme for bed-and-breakfasts and small inns. Room showcases with amenity icons and rate tables, local-area guide layouts, seasonal-package promotions, guest-review walls, and booking-engine embed sections that fit common WP booking plugins.
TECH_STACK: WordPress block theme (PHP + theme.json) + block patterns + room showcase patterns + booking-plugin-friendly embed regions
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 120 concurrent visitors, ~12 req/sec, ~8 GB media
```

## 54. Repetition — gym and fitness theme

```text
APP_DESCRIPTION: A WordPress block theme for gyms and fitness studios. Class-schedule display patterns, trainer profiles with specialties, membership pricing tables with comparison layout, transformation-story showcases, and free-trial funnel pages — high-energy design with bold display typography.
TECH_STACK: WordPress block theme (PHP + theme.json) + block patterns + pricing table patterns + schedule-plugin-friendly embed regions
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 250 concurrent visitors New-Year peak, ~25 req/sec, ~4 GB media
```

## 55. Crema — café and coffee shop theme

```text
APP_DESCRIPTION: A WordPress block theme for cafés, coffee shops, and bakeries. Menu-board patterns with seasonal specials, location/hours cards for multi-location shops, coffee-origin story layouts, Instagram-feed-style photo grids, and order-online CTAs — warm palette with handcrafted feel.
TECH_STACK: WordPress block theme (PHP + theme.json) + block patterns + menu board patterns + multi-location card patterns
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 200 concurrent visitors morning peak, ~20 req/sec, ~3 GB media
```

## 56. Monospace — developer portfolio theme

```text
APP_DESCRIPTION: A WordPress block theme for software developers and technical writers. Project showcases with tech-stack tags and repo links, syntax-highlighted code blocks, long-form technical-writing typography, talk/publication lists, and an uptime-style "now" status section — dark-first design.
TECH_STACK: WordPress block theme (PHP + theme.json) + block patterns + code-highlighting styles + project showcase patterns + dark/light style variations
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 100 concurrent visitors on a front-page hit, ~30 req/sec (cached), ~1 GB media
```

## 57. Wanderline — travel blog theme

```text
APP_DESCRIPTION: A WordPress block theme for travel bloggers. Destination-guide layouts with map embeds, itinerary patterns with day-by-day structure, gear-list layouts with affiliate-link styling, photo-essay templates, and a destinations archive browsable by region — built for long-form storytelling.
TECH_STACK: WordPress block theme (PHP + theme.json) + block patterns + itinerary patterns + map embed patterns + photo-essay templates
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 1,500 concurrent readers on viral posts, ~120 req/sec (cached), ~15 GB media
```

## 58. Simmer — food blog theme

```text
APP_DESCRIPTION: A WordPress block theme for food bloggers. Recipe-forward article layouts with jump-to-recipe UX, ingredient-photography grids, seasonal recipe collections, cooking-tips callout patterns, and print-friendly recipe styling — designed to pair with recipe-card plugins.
TECH_STACK: WordPress block theme (PHP + theme.json) + block patterns + jump-to-recipe navigation + print stylesheet + recipe-plugin-friendly layouts
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 2,500 concurrent readers at dinner-planning peak, ~200 req/sec (cached), ~12 GB media
```

## 59. Storefront Slate — WooCommerce boutique theme

```text
APP_DESCRIPTION: A WordPress block theme purpose-built for small WooCommerce boutiques. Product-grid patterns with quick-view hooks, lookbook editorial layouts, size-guide and shipping-info patterns, cart/checkout styling consistent with the brand system, and conversion-focused product-page templates.
TECH_STACK: WordPress block theme (PHP + theme.json) + WooCommerce block templates + block patterns + lookbook patterns + style variations
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 800 concurrent shoppers sale peak, ~90 req/sec, ~10 GB media
```

## 60. Ledger — accounting firm theme

```text
APP_DESCRIPTION: A WordPress block theme for accounting and bookkeeping firms. Service pages with engagement-tier pricing patterns, tax-deadline countdown sections, resource-library layouts for guides and checklists, team credential displays, and secure-portal login CTAs — trust-forward conservative design.
TECH_STACK: WordPress block theme (PHP + theme.json) + block patterns + pricing tier patterns + resource library layouts
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 100 concurrent visitors tax-season peak, ~10 req/sec, ~1 GB media
```

## 61. Canopy — landscaping and outdoor services theme

```text
APP_DESCRIPTION: A WordPress block theme for landscapers, arborists, and outdoor contractors. Before/after project galleries, service-area maps, seasonal-service promotion patterns, crew and equipment showcases, and quote-request CTAs — photography-led with earthy style variations.
TECH_STACK: WordPress block theme (PHP + theme.json) + block patterns + before/after gallery patterns + service-area patterns
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 120 concurrent visitors spring peak, ~12 req/sec, ~6 GB media
```

## 62. Gavel — nonprofit advocacy theme

```text
APP_DESCRIPTION: A WordPress block theme for advocacy organizations and campaigns. Issue-explainer layouts with stat callouts, action-center patterns (petition, contact-representative, share), press-release archives, coalition-partner grids, and urgent-action banner systems — built for rapid response publishing.
TECH_STACK: WordPress block theme (PHP + theme.json) + block patterns + action-center patterns + urgent banner patterns + stat callout patterns
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 3,000 concurrent visitors during campaign moments, ~250 req/sec (cached), ~3 GB media
```

## 63. Blueprint & Beam — construction theme

```text
APP_DESCRIPTION: A WordPress block theme for construction companies and general contractors. Project portfolio layouts by sector (residential, commercial), capability statements with certification badges, safety-record sections, bid-request CTAs, and career pages for trade recruitment — bold industrial design.
TECH_STACK: WordPress block theme (PHP + theme.json) + block patterns + project portfolio patterns + certification badge patterns
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 80 concurrent visitors, ~8 req/sec, ~8 GB media
```

## 64. Whisk & Whimsy — kids activity center theme

```text
APP_DESCRIPTION: A WordPress block theme for children's activity centers (gymnastics, art studios, play cafés). Program grids by age group, birthday-party package layouts, camp-week schedules with registration CTAs, parent FAQ patterns, and photo-heavy fun-forward design with playful yet readable typography.
TECH_STACK: WordPress block theme (PHP + theme.json) + block patterns + program grid patterns + party package patterns
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 200 concurrent parents at camp-registration open, ~20 req/sec, ~4 GB media
```

## 65. Meridian — city magazine theme

```text
APP_DESCRIPTION: A WordPress block theme for city and lifestyle magazines. Neighborhood-guide layouts, best-of list templates with ranked entries, event-roundup patterns, restaurant-review layouts with rating displays, and edition-based archive browsing — dense editorial design with strong art direction.
TECH_STACK: WordPress block theme (PHP + theme.json) + block patterns + ranked list templates + review layout patterns + editorial typography system
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 1,800 concurrent readers weekend-guide peak, ~160 req/sec (cached), ~20 GB media
```

## 66. Kilnworks — artist and maker theme

```text
APP_DESCRIPTION: A WordPress block theme for ceramicists, woodworkers, and independent makers. Process-story layouts pairing studio photography with narrative, collection showcases with availability states (available, commissioned, sold), stockist maps, workshop-class announcements, and commission-inquiry patterns.
TECH_STACK: WordPress block theme (PHP + theme.json) + block patterns + collection showcase patterns + availability badge styles + commission inquiry patterns
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 90 concurrent visitors after a market weekend, ~10 req/sec, ~6 GB media
```

## 67. Nightowl — bar and brewery theme

```text
APP_DESCRIPTION: A WordPress block theme for bars, breweries, and taprooms. Tap-list patterns with rotating beer entries and style/ABV columns, event calendars for trivia and live music, private-event booking sections, age-gate support, and merch highlights — moody dark design with neon-accent style variation.
TECH_STACK: WordPress block theme (PHP + theme.json) + block patterns + tap list patterns + event calendar patterns + age-gate template part
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 300 concurrent visitors Friday evening, ~30 req/sec, ~5 GB media
```

## 68. Fieldhouse — sports club theme

```text
APP_DESCRIPTION: A WordPress block theme for amateur sports clubs and leagues. Fixture and results tables, team rosters with player cards, standings displays, club-news layouts, sponsor showcases with tiered logos, and registration CTAs for seasonal signups — scoreboard-inspired design system.
TECH_STACK: WordPress block theme (PHP + theme.json) + block patterns + fixture/results table patterns + roster card patterns + sponsor tier patterns
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 500 concurrent visitors match-day peak, ~45 req/sec, ~4 GB media
```

## 69. Quill — author and book theme

```text
APP_DESCRIPTION: A WordPress block theme for authors. Book showcases with retailer buy-buttons per format, series reading-order displays, excerpt/sample-chapter layouts, event and signing calendars, press/review quote walls, and newsletter signups with reader-magnet delivery patterns.
TECH_STACK: WordPress block theme (PHP + theme.json) + block patterns + book showcase patterns + retailer button patterns + series order patterns
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 600 concurrent visitors on release day, ~50 req/sec (cached), ~2 GB media
```

## 70. Meadowlark — wellness retreat theme

```text
APP_DESCRIPTION: A WordPress block theme for retreat centers and wellness venues. Retreat-program layouts with schedules and accommodation tiers, facilitator profiles, grounds/facility galleries, testimonial journeys, seasonal-calendar displays, and inquiry funnels — calm spacious design with generous whitespace.
TECH_STACK: WordPress block theme (PHP + theme.json) + block patterns + program layout patterns + accommodation tier patterns + gallery patterns
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 150 concurrent visitors January peak, ~15 req/sec, ~10 GB media
```

---

# Blocks (71-90)

## 71. TableCraft — pricing table block

```text
APP_DESCRIPTION: A WordPress block plugin providing a pricing-table block for SaaS and service sites. Editors build tiered pricing columns with feature checklists, highlighted recommended tiers, monthly/annual toggles with per-toggle prices, and currency formatting — fully editable in the block editor with live preview.
TECH_STACK: WordPress block plugin (PHP registration + @wordpress/scripts JS build) + block.json + InnerBlocks column structure + toggle interactivity via Interactivity API
APP_TYPE: web app
LANGUAGE: PHP
SCALE: used on 5,000 sites, ~1,000 concurrent visitors per large site, static render
```

## 72. StepStory — timeline block

```text
APP_DESCRIPTION: A WordPress block plugin that renders vertical and horizontal timelines. Editors add dated milestones with icons, media, and expandable detail; layouts switch between vertical, horizontal-scroll, and compact list; entries animate into view on scroll — used for company histories and project roadmaps.
TECH_STACK: WordPress block plugin (PHP + @wordpress/scripts) + block.json + InnerBlocks milestone children + intersection-observer animations + style variations
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 3,000 installs, static render with light JS, no server load beyond page render
```

## 73. ChartChisel — data chart block

```text
APP_DESCRIPTION: A WordPress block plugin for publishing charts without external services. Editors paste CSV data or connect a Google Sheet, choose bar/line/pie/area types with theme-inherited colors, add axis labels and source attribution, and charts render as accessible SVG with screen-reader data tables.
TECH_STACK: WordPress block plugin (PHP + @wordpress/scripts) + block.json + SVG chart rendering + CSV parser + optional Sheets fetch with transient caching + a11y data-table fallback
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 2,000 installs, sheet-connected charts refresh hourly via transients, ~5 req/sec per busy site
```

## 74. FlipCard — before/after comparison block

```text
APP_DESCRIPTION: A WordPress block plugin providing before/after image comparison with a draggable divider. Editors pick two images with alignment lock, set starting divider position and orientation, add optional labels, and the block renders touch-friendly slider comparison — popular with renovators, detailers, and photo editors.
TECH_STACK: WordPress block plugin (PHP + @wordpress/scripts) + block.json + pointer-event slider + responsive image handling + Interactivity API
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 8,000 installs, static render with light JS, no server-side load
```

## 75. RecipeRibbon — recipe card block

```text
APP_DESCRIPTION: A WordPress block plugin providing a structured recipe card for food bloggers. Editors fill ingredients with unit scaling, steps with per-step photos, times and yields; readers scale servings, check off ingredients, and activate a cook-mode screen-wake; output carries full schema.org Recipe markup for rich results.
TECH_STACK: WordPress block plugin (PHP + @wordpress/scripts) + block.json + schema.org Recipe JSON-LD + serving-scaler Interactivity API + print styles
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 12,000 installs, high-traffic food blogs at ~200 req/sec (page-cached), static render
```

## 76. TocTick — table of contents block

```text
APP_DESCRIPTION: A WordPress block plugin generating a table of contents from post headings. It auto-detects heading structure with include/exclude controls per level, renders collapsible nested lists with smooth-scroll anchors, highlights the active section while reading, and optionally floats as a sticky sidebar on wide screens.
TECH_STACK: WordPress block plugin (PHP + @wordpress/scripts) + block.json + server-side heading parse + scroll-spy Interactivity API + sticky positioning styles
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 20,000 installs, static render with light JS, no server load beyond render
```

## 77. CountClock — countdown timer block

```text
APP_DESCRIPTION: A WordPress block plugin for countdown timers targeting launches, sales, and events. Editors set target datetimes with timezone handling, choose digit styles and labels, and define expiry behavior (hide, swap to message, or reveal hidden content) — evergreen per-visitor countdowns support email-campaign landing pages.
TECH_STACK: WordPress block plugin (PHP + @wordpress/scripts) + block.json + timezone-safe rendering + expiry content swap + evergreen cookie mode
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 6,000 installs, launch-page spikes ~500 concurrent visitors, client-side ticking
```

## 78. FaceBoard — team members block

```text
APP_DESCRIPTION: A WordPress block plugin displaying team member grids. Editors add members with photos, roles, bios, and social links; layouts include grid, list, and org-chart grouping by department; hover reveals bios; and a reusable member store means one edit updates every placement across the site.
TECH_STACK: WordPress block plugin (PHP + @wordpress/scripts) + block.json + custom post type member store + department grouping + grid/org-chart layouts
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 4,000 installs, teams up to 500 members, static render
```

## 79. QuoteCarousel — testimonial slider block

```text
APP_DESCRIPTION: A WordPress block plugin for testimonial display. Editors collect testimonials with author, company, avatar, and star rating into a shared library, then place carousel, wall, or single-highlight layouts anywhere; autoplay respects reduced-motion preferences and markup includes review structured data.
TECH_STACK: WordPress block plugin (PHP + @wordpress/scripts) + block.json + testimonial custom post type library + carousel Interactivity API + schema.org Review markup
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 9,000 installs, static render with light JS
```

## 80. MapMarker — interactive map block

```text
APP_DESCRIPTION: A WordPress block plugin embedding interactive maps without Google dependency. Editors drop pins with titles, descriptions, and category icons on OpenStreetMap tiles, draw service-area polygons, and cluster dense pin sets; visitors filter pins by category — no API keys or per-load billing.
TECH_STACK: WordPress block plugin (PHP + @wordpress/scripts) + block.json + Leaflet + OpenStreetMap tiles + pin clustering + category filter UI
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 7,000 installs, maps with up to 2,000 pins, tile loads offloaded to OSM CDN
```

## 81. AudioAisle — audio player block

```text
APP_DESCRIPTION: A WordPress block plugin providing a styled audio player for musicians and podcasters. Editors build playlists from media-library tracks with artwork and per-track buy links, players offer speed control and chapter markers, and listening progress persists across pages via local storage.
TECH_STACK: WordPress block plugin (PHP + @wordpress/scripts) + block.json + HTML5 audio + playlist InnerBlocks + local-storage progress + chapter marker support
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 3,500 installs, audio served from media library/CDN, static render
```

## 82. HotSpot — image hotspot block

```text
APP_DESCRIPTION: A WordPress block plugin adding interactive hotspots to images. Editors place numbered or icon markers on any image with popover content (text, links, prices), making shoppable lookbooks, annotated diagrams, and facility maps; popovers are keyboard-navigable and touch-friendly.
TECH_STACK: WordPress block plugin (PHP + @wordpress/scripts) + block.json + percentage-anchored markers + accessible popover Interactivity API + responsive repositioning
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 5,000 installs, static render with light JS
```

## 83. FoldOut — accordion FAQ block

```text
APP_DESCRIPTION: A WordPress block plugin for accordion and FAQ sections. Editors nest any blocks inside collapsible panels with single-open or multi-open behavior, deep links open the right panel from anchor URLs, search-within-page works via browser find integration, and FAQ schema markup targets rich results.
TECH_STACK: WordPress block plugin (PHP + @wordpress/scripts) + block.json + InnerBlocks panels + details/summary progressive enhancement + FAQPage JSON-LD
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 15,000 installs, static render, no server load beyond render
```

## 84. TabTrek — tabs block

```text
APP_DESCRIPTION: A WordPress block plugin providing horizontal and vertical tabbed content. Editors create tab sets holding any blocks per panel, tabs convert to accordions on narrow screens, URL hashes select tabs for shareable deep links, and keyboard navigation follows WAI-ARIA tab patterns.
TECH_STACK: WordPress block plugin (PHP + @wordpress/scripts) + block.json + InnerBlocks panels + ARIA tabs pattern + responsive accordion fallback
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 10,000 installs, static render with light JS
```

## 85. BrickWall — masonry gallery block

```text
APP_DESCRIPTION: A WordPress block plugin rendering masonry photo galleries. Editors pick media-library images with per-image captions and link targets, layout balances columns without row gaps, a lightbox offers swipe navigation and caption display, and images lazy-load with LQIP placeholders for fast first paint.
TECH_STACK: WordPress block plugin (PHP + @wordpress/scripts) + block.json + CSS columns/grid masonry + lightbox Interactivity API + responsive srcset + LQIP placeholders
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 11,000 installs, galleries up to 300 images, static render
```

## 86. CodeCase — code snippet block

```text
APP_DESCRIPTION: A WordPress block plugin for technical blogs displaying code. Editors paste snippets with language selection and optional line highlighting and file-name labels, readers copy with one click and toggle wrap, themes are chosen once site-wide, and rendering happens server-side so no highlighting JS ships to readers.
TECH_STACK: WordPress block plugin (PHP + @wordpress/scripts) + block.json + server-side syntax highlighting + copy-to-clipboard + line-highlight ranges
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 6,000 installs on developer blogs, static render, zero client highlight cost
```

## 87. StatSpark — animated stats block

```text
APP_DESCRIPTION: A WordPress block plugin displaying key-number stat rows. Editors add stats with values, labels, prefixes/suffixes, and optional icons; numbers count up when scrolled into view respecting reduced-motion; layouts span 2-6 columns with divider styles — the staple "500+ clients, 98% satisfaction" section done right.
TECH_STACK: WordPress block plugin (PHP + @wordpress/scripts) + block.json + count-up Interactivity API + reduced-motion handling + column layout variations
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 13,000 installs, static render with light JS
```

## 88. FormFlare — conversational form block

```text
APP_DESCRIPTION: A WordPress block plugin providing one-question-at-a-time conversational forms. Editors compose question sequences with branching logic (answer-dependent paths), progress indication, and inline validation; submissions store locally with export and webhook delivery — a typeform-style experience without the SaaS.
TECH_STACK: WordPress block plugin (PHP + @wordpress/scripts) + block.json + branching logic engine + MySQL submissions table + REST submission endpoint + webhook delivery
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 4,000 installs, ~50 submissions/day per active site, ~20 req/sec on busiest sites
```

## 89. EventStrip — event list block

```text
APP_DESCRIPTION: A WordPress block plugin rendering upcoming-event lists from multiple sources. Editors point it at an iCal/Google Calendar URL or manual entries, events display in list/card/mini-calendar layouts with timezone-correct times, past events auto-drop, and add-to-calendar buttons cover Apple/Google/Outlook.
TECH_STACK: WordPress block plugin (PHP + @wordpress/scripts) + block.json + iCal feed parser with transient caching + timezone handling + add-to-calendar generation
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 8,000 installs, feeds refresh every 30 min via transients, static render between refreshes
```

## 90. SocialProofling — live activity toast block

```text
APP_DESCRIPTION: A WordPress block plugin showing recent-activity toasts ("Ana from Lisbon just enrolled") for course and product sites. Site owners connect WooCommerce or form-plugin events, configure display rules (pages, frequency, anonymization), and toasts rotate real recent events with full GDPR-safe anonymization controls.
TECH_STACK: WordPress block plugin (PHP + @wordpress/scripts) + block.json + event-source adapters (WooCommerce/forms) + MySQL event buffer + anonymization rules + toast Interactivity API
APP_TYPE: web app
LANGUAGE: PHP
SCALE: 3,000 installs, event buffers ~5k events/site, ~10 req/sec polling on busy sites
```

---

# WP-CLI Tools (91-100)

## 91. wp mediatrim — media library optimizer

```text
APP_DESCRIPTION: A WP-CLI command package for agencies maintaining client sites. It scans the media library for unused attachments (no post, meta, or content references), oversized originals, and missing thumbnail sizes; regenerates or converts images to WebP/AVIF in batches; and reports reclaimable space — dry-run by default with an undo manifest.
TECH_STACK: WP-CLI command package (PHP + Composer) + WP_CLI API + attachment reference scanner + image conversion via Imagick + batch processing with progress bars
APP_TYPE: CLI
LANGUAGE: PHP
SCALE: single operator, libraries up to 500k attachments / 400 GB per site
```

## 92. wp contentport — content migration tool

```text
APP_DESCRIPTION: A WP-CLI command package that migrates content between WordPress sites. It exports selected post types with media, terms, meta, and author mapping into a portable archive, imports with URL rewriting and ID remapping, resolves slug collisions by policy, and produces a migration report with skipped-item reasons.
TECH_STACK: WP-CLI command package (PHP + Composer) + WP_CLI API + portable archive format + ID remap tables + media sideloading + URL search-replace integration
APP_TYPE: CLI
LANGUAGE: PHP
SCALE: single operator, migrations up to 100k posts / 50 GB media per run
```

## 93. wp linkherd — broken link scanner

```text
APP_DESCRIPTION: A WP-CLI command package that audits links across a site. It crawls post content, custom fields, and menus for internal and external links, checks status with rate-limited concurrent requests, distinguishes redirects/timeouts/hard-404s, suggests internal-link fixes from fuzzy slug matching, and outputs CSV/JSON reports for editors.
TECH_STACK: WP-CLI command package (PHP + Composer) + WP_CLI API + concurrent HTTP checking + link extraction parsers + fuzzy slug matcher + resumable scan state
APP_TYPE: CLI
LANGUAGE: PHP
SCALE: single operator, sites up to 200k posts / 2M links, resumable multi-hour scans
```

## 94. wp dbsweep — database cleanup

```text
APP_DESCRIPTION: A WP-CLI command package that safely cleans WordPress databases. It reports and purges expired transients, orphaned post meta/term relationships, spam/trashed items past retention, oversized autoloaded options, and stale post revisions by policy — every destructive action requires explicit flags and writes a rollback SQL file first.
TECH_STACK: WP-CLI command package (PHP + Composer) + WP_CLI API + orphan-detection queries + autoload analyzer + rollback SQL generation + per-table size reporting
APP_TYPE: CLI
LANGUAGE: PHP
SCALE: single operator, databases up to 50 GB / multisite networks of 200 sites
```

## 95. wp useraudit — user and role auditor

```text
APP_DESCRIPTION: A WP-CLI command package auditing users and capabilities for security reviews. It reports dormant accounts with elevated roles, users with direct capability grants outside their role, administrators without recent logins, weak-signal accounts (never logged in, disposable email domains), and role-capability drift versus WordPress defaults — with CSV evidence exports for compliance.
TECH_STACK: WP-CLI command package (PHP + Composer) + WP_CLI API + capability diff engine + login-activity integration + report exporters
APP_TYPE: CLI
LANGUAGE: PHP
SCALE: single operator, sites up to 500k users / multisite networks
```

## 96. wp cronwrangler — cron inspector

```text
APP_DESCRIPTION: A WP-CLI command package for diagnosing WP-Cron problems. It lists scheduled events with next-run drift analysis, detects orphaned hooks from removed plugins, measures per-hook execution time by instrumented runs, unschedules or reschedules events safely, and exports a health report used before moving sites to system cron.
TECH_STACK: WP-CLI command package (PHP + Composer) + WP_CLI API + cron array introspection + instrumented event runner + drift analysis + orphan hook detection
APP_TYPE: CLI
LANGUAGE: PHP
SCALE: single operator, sites with up to 10k scheduled events
```

## 97. wp seoscan — on-page SEO auditor

```text
APP_DESCRIPTION: A WP-CLI command package auditing on-page SEO at scale. It scans posts for missing/duplicate titles and meta descriptions, heading-structure problems, missing alt text, thin content by word-count thresholds, orphaned pages with no internal links, and redirect chains — scoring each post and emitting prioritized fix lists as CSV for content teams.
TECH_STACK: WP-CLI command package (PHP + Composer) + WP_CLI API + content parsers + internal-link graph builder + scoring rules + CSV/JSON reporters
APP_TYPE: CLI
LANGUAGE: PHP
SCALE: single operator, sites up to 300k posts, resumable scans
```

## 98. wp bulkloom — structured content importer

```text
APP_DESCRIPTION: A WP-CLI command package importing structured content from spreadsheets and APIs. It maps CSV/JSON/XML columns to post fields, taxonomies, and meta through reusable mapping profiles, sideloads images from URLs with dedup, upserts by external-ID to keep imports repeatable, and validates rows against mapping rules with a rejects file.
TECH_STACK: WP-CLI command package (PHP + Composer) + WP_CLI API + mapping-profile YAML + upsert-by-external-ID engine + image sideloader + row validation with rejects output
APP_TYPE: CLI
LANGUAGE: PHP
SCALE: single operator, imports up to 500k rows per run, nightly scheduled re-imports
```

## 99. wp netgardener — multisite network manager

```text
APP_DESCRIPTION: A WP-CLI command package for multisite network administrators. It bulk-activates/deactivates plugins across selected sites with pre-flight compatibility checks, reports plugin/theme/version drift per site, clones a template site into new network sites with content and settings, and archives dormant sites by traffic thresholds.
TECH_STACK: WP-CLI command package (PHP + Composer) + WP_CLI API + network-wide iteration with error isolation + site cloning engine + drift reporting
APP_TYPE: CLI
LANGUAGE: PHP
SCALE: single operator, networks up to 2,000 sites
```

## 100. wp stagesync — environment sync tool

```text
APP_DESCRIPTION: A WP-CLI command package syncing WordPress environments. It pulls production database and uploads to staging with automatic URL rewriting, PII scrubbing profiles (fake emails, masked names) for developer safety, selective table/upload-directory inclusion, and push-protection that refuses to overwrite production without an explicit unlock flag.
TECH_STACK: WP-CLI command package (PHP + Composer) + WP_CLI API + DB export/import with search-replace + PII scrubbing profiles + rsync-style selective upload sync + environment locks
APP_TYPE: CLI
LANGUAGE: PHP
SCALE: single operator, databases up to 30 GB / uploads up to 500 GB per sync
```
