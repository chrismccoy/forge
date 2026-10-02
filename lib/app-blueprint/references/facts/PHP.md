# PHP facts
Covers: Laravel (Horizon, Octane, Sanctum, Livewire, Laravel Zero), Symfony (Messenger, Scheduler, Security, API Platform, symfony/console), Doctrine ORM, Slim 4, PHP-FPM, Redis/RabbitMQ queue workers
Verified: 2026-09-29 against official documentation. Re-verify facts older than 12 months.

## Jobs and queues

### PHP-01 Queued work can run more than once
- Trap: A Laravel job or Messenger handler runs exactly once, so charging or emailing inside it is safe.
- Reality: Symfony: "A message can be delivered more than once under normal operating conditions". Laravel re-runs a job still processing after `retry_after`, and on retry. `ShouldBeUnique` only blocks duplicate dispatch while its lock is held (needs a lock-capable cache); it does not make execution exactly-once.
- Detect: payments, SMS, ledger or stock changes in jobs with no idempotency key; "exactly once"; `ShouldBeUnique` as the guarantee.
- Fix: Make handlers idempotent: record a unique idempotency key under a DB unique constraint before side effects, and pass it to external APIs.
- Source: Symfony Messenger "Writing Idempotent Handlers" - https://symfony.com/doc/current/messenger.html ; Laravel Queues "Unique Jobs" - https://laravel.com/docs/13.x/queues

### PHP-02 Job timeout must be below retry_after
- Trap: Long jobs (FFmpeg, OCR) just need a bigger `--timeout`.
- Reality: `retry_after` (default 90 s on redis/database) releases a still-running job back to the queue. Job timeout (default 60 s) must be a few seconds below `retry_after`, "Otherwise, your jobs may be processed twice." Horizon's timeout must exceed job timeouts; Supervisor `stopwaitsecs` must exceed the longest job or it is killed mid-run.
- Detect: multi-minute jobs with default `config/queue.php`.
- Fix: Per connection, job timeout < `retry_after`; give long jobs their own connection with a larger `retry_after`.
- Source: Laravel Queues "Job Expirations and Timeouts", "Supervisor Configuration" - https://laravel.com/docs/13.x/queues ; Horizon "Job Timeout" - https://laravel.com/docs/13.x/horizon

### PHP-03 Jobs dispatched inside a transaction can run before commit
- Trap: Dispatching a job inside `DB::transaction()` means the worker sees the committed row.
- Reality: Laravel: "it is possible that the job will be processed by a worker before the parent transaction has committed." `after_commit` is `false` in the default `config/queue.php`. Symfony: a message dispatched inside a handler is handled even if that handler's transaction then fails, unless stamped `DispatchAfterCurrentBusStamp`.
- Detect: "save order, then dispatch job" inside one transaction; no `afterCommit`.
- Fix: Set `after_commit => true` or call `->afterCommit()`; use `ShouldQueueAfterCommit` for queued listeners; in Symfony use `DispatchAfterCurrentBusStamp`.
- Source: Laravel Queues "Jobs & Database Transactions" - https://laravel.com/docs/13.x/queues ; Symfony Messenger "DispatchAfterCurrentBusMiddleware" - https://symfony.com/doc/current/messenger.html

### PHP-04 Messenger discards messages after 3 retries by default
- Trap: Failed Symfony messages stay in the queue until fixed.
- Reality: A failing message is retried 3 times by default then discarded unless a `failure_transport` is configured. `UnrecoverableMessageHandlingException` skips retries.
- Detect: Messenger design with no `failure_transport` or replay runbook.
- Fix: Configure `failure_transport` (and per-transport `retry_strategy`), alert on its size, document replay.
- Source: Symfony Messenger "Retries & Failures" - https://symfony.com/doc/current/messenger.html

### PHP-05 Jobs carry IDs, not live models or entities
- Trap: A job receives the model or entity as it was at dispatch time.
- Reality: Laravel `SerializesModels` stores only the model identifier and re-fetches the model and its loaded relations when the job runs. Symfony advises passing the entity's primary key, not the entity.
- Detect: jobs needing pre-change values; Doctrine entities in messages.
- Fix: Pass IDs plus any point-in-time values explicitly as scalars.
- Source: Laravel Queues "Class Structure" - https://laravel.com/docs/13.x/queues ; Symfony Messenger "Doctrine Entities in Messages" - https://symfony.com/doc/current/messenger.html

### PHP-06 Workers are long-lived and must be restarted on deploy
- Trap: Deploying new code updates running queue workers, as with PHP-FPM.
- Reality: Laravel workers "will not notice changes in your code base" and static state is not reset between jobs; restart with `queue:restart` (`horizon:terminate` under Horizon). Symfony: run `messenger:stop-workers` on deploy and bound workers with `--limit`, `--memory-limit` or `--time-limit`. Horizon requires Redis and does not support Redis Cluster.
- Detect: deploy steps without a worker restart; static caches in job code; Horizon on Redis Cluster or SQS.
- Fix: Restart workers on deploy under Supervisor/systemd; keep job code free of static state.
- Source: Laravel Queues "Queue Workers and Deployment" - https://laravel.com/docs/13.x/queues ; Horizon "Installation" - https://laravel.com/docs/13.x/horizon ; Symfony Messenger "Restart Workers on Deploy" - https://symfony.com/doc/current/messenger.html

### PHP-07 Scheduled tasks run on every server unless locked
- Trap: Several servers running the scheduler still fire each task once.
- Reality: Laravel needs a single `schedule:run` cron entry per server, and each server runs every task unless it uses `onOneServer()`, which needs a shared `database`, `memcached`, `dynamodb` or `redis` default cache. Symfony Scheduler needs `->lock()` for multiple workers; the lock covers the whole schedule, so more workers add availability, not throughput.
- Detect: scheduler on more than one node; `file` or `array` cache; one cron line per task.
- Fix: One cron entry plus `onOneServer()` on a shared cache, or a Symfony lock.
- Source: Laravel "Task Scheduling" - https://laravel.com/docs/13.x/scheduling ; Symfony "Scheduler" - https://symfony.com/doc/current/scheduler.html

## Auth and input

### PHP-08 Livewire state and action arguments are client-controlled
- Trap: A Livewire public property such as `$postId`, or a `wire:click="delete(5)"` argument, is trusted server state.
- Reality: Livewire docs: action parameters "are mutable on the client and should be treated as un-trusted user input"; public properties likewise.
- Detect: Livewire actions that load by ID and write without `$this->authorize()`; editable IDs in public properties.
- Fix: Authorize inside every action, store models (not raw IDs) as properties, or mark IDs `#[Locked]`.
- Source: Livewire "Security" - https://livewire.laravel.com/docs/4.x/security

### PHP-09 Mass assignment needs an allow-list
- Trap: `Model::create($request->all())` is fine because the form only has safe fields.
- Reality: Eloquent needs `fillable` or `guarded` (or Laravel 13 `#[Fillable]` attributes); unlisted attributes are silently dropped. Unguarding lets `is_admin`-style fields through. Mass `update()`/`delete()` queries fire no model events (`saved`, `updated`, `deleted`).
- Detect: `$request->all()` into `create`/`update`; unguarded models; observers expected on bulk updates.
- Fix: Pass `$request->validated()` into fillable models; do bulk changes per model or audit them explicitly.
- Source: Laravel "Eloquent: Getting Started" (Mass Assignment, Mass Updates) - https://laravel.com/docs/13.x/eloquent

### PHP-10 Sanctum: cookies for your SPA, tokens for third parties
- Trap: The first-party SPA stores a Sanctum bearer token in localStorage; tokens expire by default.
- Reality: "You should not use API tokens to authenticate your own first-party SPA." SPA auth uses session cookies, needs the same top-level domain (subdomains OK), `stateful` domains, `/sanctum/csrf-cookie` first. API tokens never expire unless `expiration` is set.
- Detect: SPA on a different registrable domain; token in localStorage; no token expiry or revocation.
- Fix: Cookie auth for the SPA on a shared parent domain; tokens for mobile/third parties, with `expiration` set.
- Source: Laravel "Sanctum" - https://laravel.com/docs/13.x/sanctum

### PHP-11 Symfony authorization: first access_control match wins
- Trap: Several `access_control` rules combine, and one denying voter blocks access.
- Reality: Only the first matching `access_control` entry is used. The default decision strategy is `affirmative`: one granting voter is enough.
- Detect: broad rules listed before narrow ones; relying on one voter to veto.
- Fix: Order rules narrow-to-broad; authorize objects with voters (`denyAccessUnlessGranted`/`#[IsGranted]`); use `unanimous` if any deny must win.
- Source: Symfony "Security" - https://symfony.com/doc/current/security.html ; "Voters" - https://symfony.com/doc/current/security/voters.html

## Runtime and deploy

### PHP-12 config:cache makes env() return only real env vars
- Trap: Application code calls `env('STRIPE_KEY')`.
- Reality: After `php artisan config:cache`, `.env` is not loaded, so `env()` outside `config/*.php` returns only system environment variables (usually `null`).
- Detect: `env()` in controllers, services or jobs.
- Fix: Read `env()` only in config files; use `config('services.stripe.key')` elsewhere.
- Source: Laravel "Configuration" (Configuration Caching) - https://laravel.com/docs/13.x/configuration

### PHP-13 Octane keeps the app in memory between requests
- Trap: Octane (Swoole, RoadRunner, FrankenPHP) is a drop-in speed-up.
- Reality: Octane boots once; service provider `register`/`boot` run once per worker. Singletons holding the container, request or config serve stale data to later requests; appending to static arrays leaks memory. Workers restart after 500 requests by default.
- Detect: singletons built from `$app['request']`; per-request data in static properties.
- Fix: Resolve request/config at call time (`request()`, `config()`), avoid statics, run `octane:reload` on deploy.
- Source: Laravel "Octane" (Dependency Injection and Octane) - https://laravel.com/docs/13.x/octane

### PHP-14 PHP-FPM concurrency is capped by pm.max_children
- Trap: A PHP-FPM app handles many slow requests (exports, external API calls) concurrently.
- Reality: `pm.max_children` "sets the limit on the number of simultaneous requests that will be served"; each child serves one request at a time.
- Detect: long synchronous calls or streaming in request handlers.
- Fix: Size `pm.max_children` to RAM, move slow work to queues, set timeouts on outbound calls and `request_terminate_timeout`.
- Source: PHP Manual "FPM Configuration" - https://www.php.net/manual/en/install.fpm.configuration.php

### PHP-15 Framework releases pin the PHP version
- Trap: "PHP 8.3 + Symfony 8" or "PHP 8.2 + Laravel 13".
- Reality: Laravel 12 supports PHP 8.2-8.5; Laravel 13 (Mar 2026) needs 8.3-8.5. Symfony 8.x needs PHP 8.4+; Symfony 7.4 LTS needs 8.2+. PHP 8.2 security support ends 31 Dec 2026, 8.3 ends 31 Dec 2027.
- Detect: pinned PHP version next to a framework major.
- Fix: Pick a matching pair; on PHP 8.3 use Symfony 7.4 LTS or Laravel 12/13.
- Source: Laravel "Release Notes" (Support Policy) - https://laravel.com/docs/13.x/releases ; Symfony "Releases" - https://symfony.com/releases ; PHP "Supported Versions" - https://www.php.net/supported-versions.php

### PHP-16 ORM relations lazy-load one query at a time
- Trap: Touching `$order->customer` in a loop costs nothing extra.
- Reality: Eloquent relations and Doctrine proxies load lazily, one query per parent (N+1). Eloquent can throw on lazy loads with `Model::preventLazyLoading()`; Doctrine avoids it with a fetch join.
- Detect: lists, exports or API collections rendering relations without `with()` or a join.
- Fix: Eager-load (`with()`, Doctrine `JOIN ... addSelect`) and enable `preventLazyLoading` outside production.
- Source: Laravel "Eloquent: Getting Started" (Configuring Eloquent Strictness) - https://laravel.com/docs/13.x/eloquent ; Symfony "Doctrine Associations" - https://symfony.com/doc/current/doctrine/associations.html
