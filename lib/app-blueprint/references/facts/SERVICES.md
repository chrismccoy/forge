# Third-party services facts
Covers: Stripe (Payments, Billing, ACH), AWS (S3, SES, Lambda, API Gateway, SQS), email deliverability, Vercel, Fly.io, Render, Cloud Run, Supabase, Firebase, Twilio SMS, Expo/FCM push
Verified: 2026-09-29 against official documentation. Re-verify facts older than 12 months.

## Payments (Stripe)

### SVC-01 Uncaptured authorizations expire
- Trap: "Authorize at booking, capture weeks later" with capture_method=manual.
- Reality: Online card holds last 7 days (Visa merchant-initiated: about 5); in-person 2 days for most brands. On expiry funds are released and the PaymentIntent becomes `canceled`. Extended authorization (up to 30 days) needs IC+ pricing, eligible brand/merchant category and `request_extended_authorization`. ACH cannot be held.
- Detect: hold, pre-authorize, deposit, capture later.
- Fix: Capture before `capture_before`, or save the card and charge later (SVC-02).
- Source: Place a hold on a payment method - https://docs.stripe.com/payments/place-a-hold-on-a-payment-method

### SVC-02 Charging later needs a saved PaymentMethod
- Trap: Keep a PaymentIntent or card token and charge it later without the customer.
- Reality: Attach the PaymentMethod to a Customer via SetupIntent or `setup_future_usage=off_session`, then confirm with `off_session=true`. Off-session charges can still fail with `authentication_required`; the customer must return on-session.
- Detect: no-show fee, charge balance later, card on file.
- Fix: Model Customer + saved PaymentMethod and a "come back to authenticate" flow.
- Source: Save a payment method without a payment - https://docs.stripe.com/payments/save-and-reuse

### SVC-03 3-D Secure returns requires_action
- Trap: The server call returns paid or declined; fulfill on the return page.
- Reality: PaymentIntents and first subscription invoices can return `requires_action`, which the client must complete while the customer is present. Customers may leave mid-flow.
- Detect: server-only charge flow, fulfillment on redirect.
- Fix: Handle `requires_action` client-side; fulfill only from verified webhooks (`payment_intent.succeeded`, `invoice.paid`).
- Source: How subscriptions work - https://docs.stripe.com/billing/subscriptions/overview

### SVC-04 Webhooks: raw body, duplicates, no ordering
- Trap: Parse JSON then verify; each event arrives once, in order.
- Reality: Signature verification needs the unmodified raw body. Events may repeat and arrive in any order; live mode retries up to 3 days. Redirects count as failures.
- Detect: JSON middleware on the webhook route, order-dependent state machine, no event-ID dedupe.
- Fix: Verify raw bytes, store processed event IDs, re-fetch objects from the API, return 2xx then queue work.
- Source: Receive Stripe events - https://docs.stripe.com/webhooks

### SVC-05 Idempotency keys on POST
- Trap: Retrying a timed-out create call is safe.
- Reality: Without `Idempotency-Key` a retry can charge twice. Keys live at least 24h; reuse with different parameters errors.
- Detect: retries or jobs creating PaymentIntents, refunds, transfers.
- Fix: Send a key derived from the operation (order ID + action) on every POST.
- Source: Idempotent requests - https://docs.stripe.com/api/idempotent_requests

### SVC-06 Subscriptions start incomplete; ACH is delayed
- Trap: Subscription created = paid; ACH behaves like a card.
- Reality: The first charge_automatically invoice must be paid within 23h or the subscription becomes `incomplete_expired`. ACH takes up to 4 business days, can fail after `succeeded` (as a dispute), and ACH subscriptions can be `active` while payment is `processing`.
- Detect: access granted on create, instant ACH access, no `past_due`/`unpaid` path.
- Fix: Provision from `invoice.paid`; design pending and revocation states.
- Source: ACH Direct Debit - https://docs.stripe.com/payments/ach-direct-debit

### SVC-07 PCI scope depends on who collects the card
- Trap: "Stripe means no PCI," or card fields posted to our API.
- Reality: Checkout, Elements and the mobile SDKs (Stripe-hosted fields) qualify for SAQ A. Sending raw card data to Stripe's API from your server requires SAQ D. Annual attestation is still required.
- Detect: card number/CVC in your form, API schema, logs or DB.
- Fix: Collect cards only via Checkout, Elements or mobile SDKs; store IDs, brand, last4, expiry.
- Source: PCI DSS compliance guide - https://stripe.com/guides/pci-compliance

## Email and messaging

### SVC-08 Email authentication and bulk-sender rules
- Trap: Point SMTP at a provider and mail arrives.
- Reality: Gmail requires SPF or DKIM, PTR and TLS from all senders. Senders of ~5,000+/day to Gmail (permanent status) need SPF and DKIM, DMARC (p=none minimum), From alignment and one-click unsubscribe on marketing mail, honored within 48h. Transactional mail is exempt from one-click.
- Detect: newsletters, digests, bulk reminders; no DNS setup step.
- Fix: Configure SPF, DKIM, DMARC; add List-Unsubscribe headers to bulk mail.
- Source: Email sender guidelines FAQ - https://support.google.com/a/answer/14229414

### SVC-09 Amazon SES starts in the sandbox
- Trap: Create SES credentials and email users at launch.
- Reality: New accounts are sandboxed per Region: verified recipients only, 200/24h, 1/s. Leaving it is a manual review that asks about bounce/complaint handling.
- Detect: SES with no production-access or domain-verification step.
- Fix: Put domain verification and the production-access request in the launch plan.
- Source: Request production access - https://docs.aws.amazon.com/ses/latest/dg/request-production-access.html

### SVC-10 US SMS needs A2P 10DLC; STOP is enforced
- Trap: Buy a Twilio long code and text US users.
- Reality: Messages from +1 10DLC numbers without an approved A2P Brand and Campaign are blocked (error 30034); alternatives are verified toll-free or short codes. Twilio honors STOP, UNSUBSCRIBE, END, QUIT, STOPALL, REVOKE, OPTOUT, CANCEL on long codes; later sends fail with 21610 until START.
- Detect: SMS alerts with no registration step or opt-out state.
- Fix: Plan for registration lead time; store opt-outs from the inbound `OptOutType` field.
- Source: Error 30034 - https://www.twilio.com/docs/api/errors/30034

### SVC-11 Push: accepted is not delivered
- Trap: A successful send means delivery; tokens last forever.
- Reality: An Expo "ok" ticket means accepted only; receipts (kept 24h) carry errors. `DeviceNotRegistered` means stop using the token. FCM expires Android tokens after 270 days inactive and returns UNREGISTERED (404).
- Detect: no receipt check or token cleanup; push as the only channel for critical alerts.
- Fix: Check receipts, delete dead tokens, re-register tokens on app start.
- Source: Send notifications with Expo - https://docs.expo.dev/push-notifications/sending-notifications/

## Hosting and deploy

### SVC-12 Container disks are ephemeral
- Trap: Uploads or SQLite on the local disk of Fly.io or Render.
- Reality: Fly Machine root filesystems and Render filesystems reset on deploy/restart. A Fly volume mounts on one Machine, sits on one host and is not replicated. A Render disk pins the service to one instance with no zero-downtime deploys; free services cannot have one.
- Detect: local uploads dir, SQLite file, multiple instances plus local files.
- Fix: Use object storage and a managed DB, or single-instance volumes with backups.
- Source: Fly Volumes - https://docs.fly.io/volumes/overview/ ; Render disks - https://render.com/docs/disks

### SVC-13 Idle instances stop
- Trap: Schedulers, queues or sockets run forever inside the web process.
- Reality: Render free services sleep after 15 min idle (~1 min wake); free Postgres expires after 30 days. `fly launch` defaults to auto-stop with min_machines_running=0; autostart reacts only to proxied HTTP. Cloud Run's default request-based billing gives CPU only during requests; idle instances can be shut down any time.
- Detect: in-process cron/worker, free tier in production.
- Fix: Separate always-on worker or platform scheduler; min instances or instance-based billing.
- Source: Render free - https://render.com/docs/free ; Fly autostop - https://docs.fly.io/launch/autostop-autostart/

## Serverless

### SVC-14 Vercel Cron semantics
- Trap: Cron POSTs, retries on failure, runs exactly once, any frequency.
- Reality: GET to the production URL, UTC. With CRON_SECRET set it sends `Authorization: Bearer <CRON_SECRET>`. No retries; runs can be missed, duplicated or overlap. Hobby: once a day, ±59 min; Pro/Enterprise: per minute.
- Detect: POST handler, unauthenticated cron route, sub-daily Hobby jobs.
- Fix: Check the bearer on GET; make jobs idempotent and reconciling; add a lock.
- Source: Managing Cron Jobs - https://vercel.com/docs/cron-jobs/manage-cron-jobs

### SVC-15 Vercel Functions limits
- Trap: Uploads through API routes, long jobs, files on disk.
- Reality: 4.5 MB request/response body (413). Max duration (Fluid compute): Hobby 300s; Pro/Enterprise 800s (1800s beta). Read-only filesystem apart from scratch `/tmp`.
- Detect: file upload API route, long PDF/video jobs, local persistence.
- Fix: Direct-to-storage uploads, queue/workflow for long jobs, external storage.
- Source: Vercel Functions Limits - https://vercel.com/docs/functions/limitations

### SVC-16 Lambda and API Gateway timeouts
- Trap: Long work behind API Gateway; unbounded payloads.
- Reality: Lambda max 900s; `/tmp` 512 MB-10 GB, not durable; payload 6 MB sync, 1 MB async. REST API integration timeout 29s by default (Regional/private raisable by quota request, may cut throttle quota; edge-optimized not). HTTP API max 30s, fixed. API payload 10 MB.
- Detect: synchronous exports/reports, uploads via API Gateway.
- Fix: Return 202 and process async; presigned S3 uploads.
- Source: REST API quotas - https://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-execution-service-limits-table.html

### SVC-17 SQS is at-least-once
- Trap: Each message is processed exactly once.
- Reality: Standard queues can redeliver. Undeleted messages reappear after the visibility timeout (default 30s, max 12h from first receive).
- Detect: non-idempotent consumers, jobs longer than the timeout, no DLQ.
- Fix: Idempotent consumers, extend visibility, dead-letter queue.
- Source: SQS visibility timeout - https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-visibility-timeout.html

## Storage and backend-as-a-service

### SVC-18 S3 presigned URLs and concurrency
- Trap: Month-long presigned links; eventual consistency; S3 blocks concurrent overwrites.
- Reality: SigV4 presigned URLs last at most 7 days; if signed with role/STS credentials they die with them (often 1-6h). Reads are strongly consistent, but concurrent PUTs to a key are last-writer-wins.
- Detect: long share links signed in Lambda/ECS, consistency sleeps, shared mutable keys.
- Fix: Sign on demand; unique keys or versioning; app-level locking.
- Source: Presigned URLs - https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-presigned-url.html

### SVC-19 Supabase and Firebase client keys are public
- Trap: The anon/publishable key or Firebase config is secret; client checks secure data.
- Reality: Supabase tables in exposed schemas without RLS are readable and writable by any granted role; `service_role` and default views bypass RLS. Firebase test-mode rules allow anyone; rules are not filters; the Admin SDK bypasses them.
- Detect: no RLS/rules section, service key in the client, `auth != null` as the only rule.
- Fix: Enable RLS/rules on every table or collection with owner/role policies, and test them.
- Source: Supabase RLS - https://supabase.com/docs/guides/database/postgres/row-level-security ; Firebase insecure rules - https://firebase.google.com/docs/rules/insecure-rules
