# Ruby facts
Covers: Ruby on Rails (full-stack and API mode), Hotwire (Turbo Drive, Turbo Streams, Stimulus), Active Job, Action Cable, Active Storage, Solid Queue/Cache/Cable, Sidekiq (OSS, Pro, Enterprise), Ruby CLI gems (thor)
Verified: 2026-09-29 against official documentation. Re-verify facts older than 12 months.

## Jobs

### RB-01 Sidekiq runs jobs at least once
- Trap: A Sidekiq job runs exactly once, so charging a card or sending an SMS inside it is safe.
- Reality: "Sidekiq will execute your job at least once, not exactly once. Even a job which has completed can be re-run." Retries also re-run half-finished jobs.
- Detect: payments, refunds, SMS, email or counters in jobs with no idempotency key or "already done" check.
- Fix: Make every job idempotent: check state first, store an idempotency key under a unique index, pass keys to external APIs.
- Source: Sidekiq wiki "Best Practices" - https://github.com/sidekiq/sidekiq/wiki/Best-Practices

### RB-02 Job arguments: simple JSON for Sidekiq, GlobalID for Active Job
- Trap: `SomeJob.perform_async(order)` or symbol/keyword/Time arguments work.
- Reality: Native Sidekiq arguments must be JSON types (string, integer, float, boolean, nil, array, hash); symbols, keyword args, Date/Time objects do not round-trip. Active Job accepts records via GlobalID, but raises `ActiveJob::DeserializationError` if the record was deleted before the job runs.
- Detect: model objects, symbols or Time values passed to `perform_async`; jobs for records that may be destroyed.
- Fix: Pass IDs and ISO-8601 strings; look records up in `perform` and handle missing ones.
- Source: Sidekiq wiki "Best Practices" - https://github.com/sidekiq/sidekiq/wiki/Best-Practices ; Rails "Active Job Basics" - https://guides.rubyonrails.org/active_job_basics.html

### RB-03 Jobs enqueued inside a transaction can run before commit
- Trap: `perform_later`/`perform_async` inside `transaction do` or `after_save` sees the committed row.
- Reality: Rails 7.2 deferred Active Job enqueues until commit by default. Rails 8.0 deprecated that config; in Rails 8.1 `enqueue_after_transaction_commit` defaults to `false`, so jobs enqueue immediately unless enabled. Native `perform_async` pushes to Redis immediately unless `Sidekiq.transactional_push!` is on.
- Detect: enqueue calls in `after_save`/`after_create` or inside transactions; `RecordNotFound` retries in job designs.
- Fix: Set `self.enqueue_after_transaction_commit = true` on `ApplicationJob`, enqueue from `after_commit`, or enable `Sidekiq.transactional_push!`.
- Source: Rails "Active Job Basics" (Transactional Integrity on Jobs) - https://guides.rubyonrails.org/active_job_basics.html ; "Rails 8.1 Release Notes" - https://guides.rubyonrails.org/8_1_release_notes.html ; Sidekiq source `transaction_aware_client.rb` - https://github.com/sidekiq/sidekiq

### RB-04 Basic Sidekiq loses in-flight jobs on a crash
- Trap: Redis-backed Sidekiq never loses a job.
- Reality: OSS Sidekiq fetches with BRPOP, removing the job from Redis; "If Sidekiq crashes while processing that job, it is lost forever." `super_fetch` (Sidekiq Pro) fixes this. On graceful shutdown (TSTP early, TERM late, `-t` default 25 s) unfinished jobs are pushed back and run again. Redis must use `maxmemory-policy noeviction`, and not be a cache instance.
- Detect: OOM-killed or spot/autoscaled workers on OSS Sidekiq with no reconciliation; deploys that SIGKILL workers; one Redis for cache and Sidekiq.
- Fix: Use Sidekiq Pro `super_fetch` or a reconciliation sweep; give deploys the shutdown timeout; run a separate non-evicting Redis.
- Source: Sidekiq wiki "Reliability" - https://github.com/sidekiq/sidekiq/wiki/Reliability ; "Deployment" - https://github.com/sidekiq/sidekiq/wiki/Deployment ; "Using Redis" - https://github.com/sidekiq/sidekiq/wiki/Using-Redis

### RB-05 Sidekiq retries for about three weeks
- Trap: A failed job fails fast, or retries a few times.
- Reality: Sidekiq retries 25 times with exponential backoff (about 20-21 days), then moves the job to the Dead set, kept 6 months. Active Job `retry_on` defaults to 5 attempts 3 s apart, then hands the job to Sidekiq's retries.
- Detect: time-sensitive jobs (reminders, holds, expirations) with default retries; no Dead-set monitoring.
- Fix: Set `retry:` per job, check staleness at the start of `perform`, alert on retries and dead jobs.
- Source: Sidekiq wiki "Error Handling" - https://github.com/sidekiq/sidekiq/wiki/Error-Handling ; "Active Job" - https://github.com/sidekiq/sidekiq/wiki/Active-Job

### RB-06 Unique and cron jobs are Sidekiq Enterprise features
- Trap: OSS Sidekiq can deduplicate jobs or run cron schedules.
- Reality: Unique jobs (`unique_for`) and periodic jobs are Sidekiq Enterprise. Uniqueness is "best effort, not a 100% guarantee" and expires with `unique_for`.
- Detect: "unique job", "dedupe" or "cron" with OSS Sidekiq and no licence or other scheduler named.
- Fix: Budget Enterprise, or use idempotent jobs plus Solid Queue recurring tasks or another scheduler.
- Source: Sidekiq wiki "Ent Unique Jobs" - https://github.com/sidekiq/sidekiq/wiki/Ent-Unique-Jobs ; "Ent Periodic Jobs" - https://github.com/sidekiq/sidekiq/wiki/Ent-Periodic-Jobs

## Models and controllers

### RB-07 after_save runs inside the transaction; side effects go in after_commit
- Trap: `after_save`/`after_create` is the place to call APIs, send email or broadcast.
- Reality: The whole callback chain runs in a transaction; an error rolls it back, and work done in `after_save` cannot be undone if the transaction later rolls back. `after_commit` runs only after commit. `update_all`, `update_column(s)`, `delete_all`, `insert_all`, `upsert_all` skip callbacks.
- Detect: external calls in `after_save`/`after_destroy`; callbacks relied on for audit after bulk updates.
- Fix: Put external effects in `after_commit` (or `ActiveRecord.after_all_transactions_commit`); audit bulk writes explicitly.
- Source: Rails "Active Record Callbacks" - https://guides.rubyonrails.org/active_record_callbacks.html

### RB-08 Strong parameters: permit explicitly
- Trap: `Model.create(params[:model])` works, or `permit!` is fine for admin forms.
- Reality: Unpermitted params raise `ActiveModel::ForbiddenAttributesError`. Rails 8.0+ recommends `params.expect(person: [:name])` over `require.permit`; it returns 400 on tampered shapes instead of 500.
- Detect: `permit!`, role or owner fields (`role`, `account_id`) in permitted lists.
- Fix: Permit only user-editable fields per action; set ownership from `current_user`.
- Source: Rails "Action Controller Overview" (Strong Parameters) - https://guides.rubyonrails.org/action_controller_overview.html

## Hotwire and real time

### RB-09 Turbo form submissions need 303 or 422
- Trap: Controllers render the form again with 200 on errors, or render a page after a successful POST.
- Reality: Turbo Drive expects a 303 redirect after a stateful form submission; validation errors must render with a 4xx (422 Unprocessable Content). Turbo ignores 200 renders from POST.
- Detect: `render :new` without `status: :unprocessable_entity`; success paths that render instead of redirect.
- Fix: `redirect_to ..., status: :see_other` on success, `render ..., status: :unprocessable_entity` on failure, or answer with Turbo Streams.
- Source: Turbo Handbook "Drive" (Redirecting After a Form Submission) - https://turbo.hotwired.dev/handbook/drive

### RB-10 Turbo Stream broadcasts need a cross-process cable adapter
- Trap: Broadcasts from jobs or models reach browsers with the default Action Cable setup.
- Reality: The `async` adapter "is intended for development/testing and should not be used in production" and works only inside one process, so broadcasts from Sidekiq or another dyno are lost. Production needs Redis or Solid Cable (database-backed).
- Detect: live bidding, menus or dashboards broadcast from jobs with no `config/cable.yml` production adapter.
- Fix: Configure Redis or Solid Cable for production and size it for the broadcast rate.
- Source: Rails "Action Cable Overview" (Subscription Adapter) - https://guides.rubyonrails.org/action_cable_overview.html

## Deploy and config

### RB-11 Rails 8 defaults to Solid Queue, Solid Cache and Solid Cable
- Trap: A new Rails 8 app already uses Sidekiq and Redis, or has no production job backend.
- Reality: New Rails 8 apps set `queue_adapter = :solid_queue` in production, on a separate `queue` database by default, run by `bin/jobs`. Development uses the in-process `async` adapter, which loses jobs on crash. Solid Cache and Solid Cable are the default cache and cable stores.
- Detect: Sidekiq in the stack but no `queue_adapter = :sidekiq`; Solid Queue with no worker process or queue database planned.
- Fix: Name one job backend and configure it per environment, with its worker process in the deploy.
- Source: Rails "Active Job Basics" (Default Backend: Solid Queue) - https://guides.rubyonrails.org/active_job_basics.html ; "Rails 8.0 Release Notes" - https://guides.rubyonrails.org/8_0_release_notes.html

### RB-12 Credentials: commit the encrypted file, never the key
- Trap: Secrets live in committed YAML, or `config/master.key` ships in the repo or image.
- Reality: `config/credentials.yml.enc` is encrypted and can be committed; it is decrypted with `config/master.key` or `RAILS_MASTER_KEY`. "Do not commit your master key."
- Detect: plaintext secret files; master key in git or a Docker layer; no plan to supply `RAILS_MASTER_KEY`.
- Fix: Commit only `.enc` files; inject `RAILS_MASTER_KEY` from the platform's secret store.
- Source: Rails "Securing Rails Applications" (Custom Credentials) - https://guides.rubyonrails.org/security.html

### RB-13 Zeitwerk: file names must match constants
- Trap: `app/services/html_parser.rb` can define `HTMLParser`, or any file can define several top-level classes.
- Reality: File names map to constants via `String#camelize` (directories are namespaces), so `html_parser.rb` must define `HtmlParser` unless an inflection is added. Mismatches break eager loading in production.
- Detect: acronym class names (API, PDF, SMS) without inflection rules.
- Fix: Follow camelize naming or add inflections; run `bin/rails zeitwerk:check` in CI.
- Source: Rails "Autoloading and Reloading Constants" - https://guides.rubyonrails.org/autoloading_and_reloading_constants.html

### RB-14 Encrypted attributes are not queryable by default
- Trap: `encrypts :ssn` still allows `where(ssn: ...)` lookups and uniqueness checks.
- Reality: Active Record Encryption is non-deterministic by default, so equality queries do not match; querying needs `deterministic: true`.
- Detect: lookups or unique validations on encrypted PII columns.
- Fix: Use `deterministic: true` only for fields you must query; keep the rest non-deterministic.
- Source: Rails "Active Record Encryption" - https://guides.rubyonrails.org/active_record_encryption.html

### RB-15 Rails versions pin Ruby and the Sidekiq adapter
- Trap: Rails 8 on Ruby 3.1, or the Active Job Sidekiq adapter assumed to ship with Rails forever.
- Reality: Rails 7.2 needs Ruby 3.1+; Rails 8.0 and 8.1 need Ruby 3.2+. Rails 8.1 deprecates the built-in Sidekiq adapter, which is now provided by the sidekiq gem.
- Detect: pinned Ruby below the Rails minimum; old Sidekiq with Rails 8.1.
- Fix: Match Ruby to the Rails gemspec and keep Sidekiq current enough to supply the adapter.
- Source: "Rails 7.2 Release Notes" - https://guides.rubyonrails.org/7_2_release_notes.html ; "Rails 8.1 Release Notes" - https://guides.rubyonrails.org/8_1_release_notes.html ; rails.gemspec - https://github.com/rails/rails/blob/v8.1.4/rails.gemspec
