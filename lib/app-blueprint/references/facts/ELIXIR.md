# ELIXIR facts
Covers: Elixir, Phoenix (API, Channels, PubSub, Presence), Phoenix LiveView, Ecto, Oban, Broadway, GenStage, mix releases, libcluster/dns_cluster, Fly.io, Gigalixir, Kubernetes
Verified: 2026-09-29 against official documentation. Re-verify facts older than 12 months.

## LiveView

### EX-01 mount/3 runs twice
- Trap: mount/3 runs once per page view, so it is the place to subscribe to PubSub, start timers or write audit rows.
- Reality: For each root LiveView, mount/3 is invoked twice: once for the static HTTP render and again when the live socket connects.
- Detect: subscriptions, counters or writes in mount with no connected?/1 check.
- Fix: Guard stateful work with `connected?(socket)`; make any mount side effect idempotent.
- Source: Phoenix.LiveView (Life-cycle, connected?/1) - https://phoenix-live-view.hexdocs.pm/Phoenix.LiveView.html

### EX-02 Assigns are server memory per connection
- Trap: LiveView state is cheap, so each connection can hold full lists, feeds or result sets in assigns.
- Reality: Socket assigns live on the server in each LiveView process, so memory grows with connections × assign size. Streams keep collections on the client and free items after render; `temporary_assigns` reset after every render.
- Detect: large tables or chat histories in assigns, capacity plans ignoring per-connection memory.
- Fix: Use `stream/4` for large or growing collections and keep only IDs and small state in assigns.
- Source: Phoenix.LiveView (Streams, mount options) - https://phoenix-live-view.hexdocs.pm/Phoenix.LiveView.html

### EX-03 Authorize in every handle_event
- Trap: Hiding a button or authenticating in mount protects the action.
- Reality: Clients can send any event with any payload. Authentication in mount/on_mount covers both renders, but each handle_event must authorize its action. live_session draws authentication boundaries, not per-action authorization.
- Detect: "only admins see the delete button", role checks only in templates or the router, handle_event that loads records by client-supplied ID with no ownership check.
- Fix: Use an on_mount hook for authentication and an explicit permission check inside every handle_event that mutates or reads protected data.
- Source: Security considerations - https://phoenix-live-view.hexdocs.pm/security-model.html

## Jobs (Oban)

### EX-04 Oban jobs can run more than once
- Trap: Each Oban job runs exactly once, so workers can send email or charge cards without checks.
- Reality: Failed jobs retry (max_attempts default 20). Lifeline rescues jobs stuck in `executing` after a node shutdown (default after 1 hour) and "may ... cause duplicate execution". Jobs have no timeout by default, and perform/1 always gets string keys in args.
- Detect: "exactly once", non-idempotent perform/1, atom-key matches on args.
- Fix: Make workers idempotent (idempotency keys, state checks), match string keys, and set `timeout/1` for jobs that call external systems.
- Source: Oban.Worker - https://oban.hexdocs.pm/Oban.Worker.html ; Oban.Lifeline - https://oban.hexdocs.pm/Oban.Lifeline.html

### EX-05 Unique jobs only dedupe inserts
- Trap: `unique:` guarantees a job never runs twice or concurrently.
- Reality: Uniqueness only blocks duplicate inserts within a period (default 60 s). Oban OSS uses locks and queries and is "prone to race conditions"; only Pro's Smart Engine uses unique constraints. A duplicate insert returns `{:ok, job}` with `conflict?: true`.
- Detect: "unique jobs ensure exactly once", uniqueness as a mutex, no period, `{:ok, job}` read as "new job".
- Fix: Set an explicit period and states, check `job.conflict?`, and enforce hard invariants with a database constraint.
- Source: Unique Jobs - https://oban.hexdocs.pm/unique_jobs.html

### EX-06 Enqueue in the same transaction
- Trap: Write the row, then enqueue the job in a separate call.
- Reality: Oban stores jobs in the application database, and `Oban.insert/5` and `insert_all/5` add the insert to an `Ecto.Multi`, so the job and the data commit or roll back together.
- Detect: "after saving, enqueue", enqueue calls outside the transaction.
- Fix: Put the job insert in the same `Ecto.Multi` or `Repo.transaction` as the data change.
- Source: Oban - https://oban.hexdocs.pm/Oban.html

## Clustering and deploy

### EX-07 PubSub and Presence need a cluster
- Trap: Phoenix PubSub broadcasts reach every instance, and Fly.io machines cluster automatically.
- Reality: The default PG2 adapter delivers across nodes over distributed Erlang; unclustered instances see only local broadcasts, and nothing is persisted. Fly.io needs dns_cluster (`DNS_CLUSTER_QUERY=<app>.internal`), IPv6 node names in `rel/env.sh.eex`, `ERL_AFLAGS="-proto_dist inet6_tcp"` and one shared `RELEASE_COOKIE`. On Kubernetes, libcluster has Kubernetes and Kubernetes.DNS strategies.
- Detect: multi-instance PubSub/Presence/Channels with no clustering or Redis adapter, PubSub used as a queue.
- Fix: Configure dns_cluster or libcluster (or the Redis adapter) and use Oban or a broker for messages that must survive.
- Source: Phoenix.PubSub - https://phoenix-pubsub.hexdocs.pm/Phoenix.PubSub.html ; Clustering Your Application (Fly.io) - https://docs.fly.io/elixir/the-basics/clustering/ ; libcluster - https://libcluster.hexdocs.pm/readme.html

### EX-08 Hot code upgrades are not a deploy plan
- Trap: Elixir apps deploy with zero downtime through hot code upgrades.
- Reality: Hot code upgrades are "not supported out of the box by Elixir releases"; they need hand-written appups, code_change callbacks and heavy testing.
- Detect: "hot code swapping for zero-downtime deploys" on containers.
- Fix: Use rolling or blue-green deploys with graceful shutdown; design state (GenServers, LiveView) to rebuild after restart.
- Source: mix release (Hot Code Upgrades) - https://mix.hexdocs.pm/Mix.Tasks.Release.html

### EX-09 Runtime config belongs in runtime.exs
- Trap: Read secrets with `System.get_env` in config/config.exs or prod.exs.
- Reality: config.exs is evaluated when the release is built; config/runtime.exs runs at startup and must not use Mix. The cookie comes from `RELEASE_COOKIE` or `releases/COOKIE`.
- Detect: env vars read in config.exs/prod.exs, a hard-coded cookie.
- Fix: Read environment variables in config/runtime.exs and set a long random `RELEASE_COOKIE` as a secret.
- Source: mix release - https://mix.hexdocs.pm/Mix.Tasks.Release.html

## Data (Ecto)

### EX-10 Ecto never lazy-loads associations
- Trap: `post.comments` loads on access as in ActiveRecord.
- Reality: Unloaded associations are `%Ecto.Association.NotLoaded{}`. Data must be preloaded with `Repo.preload/3` or `Ecto.Query.preload/3` (optionally with a join).
- Detect: ORM-style association access in templates, no preload strategy.
- Fix: Preload explicitly in the context function that loads the data.
- Source: Ecto.Repo (preload/3) - https://ecto.hexdocs.pm/Ecto.Repo.html

## Pipelines (Broadway)

### EX-11 Broadway does not retry failures
- Trap: Broadway retries failed messages and keeps per-key order.
- Reality: "Broadway does not provide any sort of retries out of the box"; failed messages are acked as failed and redelivery depends on the producer. With `partition_by`, a partition keeps going after a failure.
- Detect: "Broadway retries", ordering guarantees that assume a failure halts the key.
- Fix: Handle failures in `handle_failed/2` (dead-letter, Oban job) and rely on the broker's redelivery settings.
- Source: Broadway - https://broadway.hexdocs.pm/Broadway.html

## Testing

### EX-12 Ecto sandbox needs allowances
- Trap: Async tests can exercise GenServers, LiveViews and jobs against the database with no extra setup.
- Reality: In manual mode each test owns one connection in a rolled-back transaction; other processes need `Sandbox.allow/3` or shared mode (no async). Multi-connection concurrency and deferred constraints cannot be tested faithfully.
- Detect: async tests using processes started elsewhere, locking tests inside the sandbox.
- Fix: Allow spawned processes explicitly, and test concurrency behavior outside the sandbox.
- Source: Ecto.Adapters.SQL.Sandbox - https://ecto-sql.hexdocs.pm/Ecto.Adapters.SQL.Sandbox.html
