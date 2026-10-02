# Fact sheets

Fact sheets list framework and service behavior that plans commonly get
wrong: defaults, limits, lifetimes, parameter support and security defaults.
`REVIEW.md` checks a plan against them, and `SPIKE.md` can use them to decide
what is worth testing.

Every fact was checked against official documentation on the date in its
sheet's `Verified:` line. Frameworks change, so re-check facts older than a
year before relying on them. `FORMAT.md` explains how to add or update facts.

## Which sheets to paste

Paste the sheet for your stack, plus the shared sheets that apply:

- **Always:** the stack sheet from the table below.
- **If the plan uses a database, cache or queue** (PostgreSQL, MySQL, SQLite,
  Redis, Kafka, RabbitMQ, TimescaleDB, ClickHouse, Elasticsearch): `DATA.md`.
- **If the plan uses hosted services** (Stripe, Vercel, Fly.io, Render, AWS,
  Twilio, email providers, push notifications, Supabase, Firebase):
  `SERVICES.md`.
- **If the plan has a user interface with accessibility requirements**
  (WCAG, ADA, Section 508, public-sector or school sites): `A11Y.md`.
- **If the plan has a CI/CD pipeline** (almost always): `CICD.md`.

| Stack (support-files/) | Sheet | Main coverage |
|---|---|---|
| WP.md | `WP.md` | Plugins, block themes, REST, capabilities, WP-Cron, WooCommerce |
| TYPESCRIPT.md | `TYPESCRIPT.md` | Next.js, Prisma, Auth.js, NestJS, React Native |
| JAVASCRIPT.md | `JAVASCRIPT.md` | Express, Fastify, React SPAs, Node CLIs, npm packages |
| PYTHON.md | `PYTHON.md` | Django, FastAPI, Celery, SQLAlchemy, Pydantic |
| PHP.md | `PHP.md` | Laravel, Livewire, Symfony, PHP-FPM |
| RUBY.md | `RUBY.md` | Rails, Hotwire, Sidekiq |
| JAVA.md | `JAVA.md` | Spring Boot, Spring Batch, Quarkus, Micronaut |
| KOTLIN.md | `KOTLIN.md` | Android/Compose, Room, Ktor, Kotlin Spring |
| CSHARP.md | `CSHARP.md` | ASP.NET Core, EF Core, MAUI, worker services |
| GO.md | `GO.md` | net/http, concurrency, database/sql, pgx, builds |
| RUST.md | `RUST.md` | tokio, axum, sqlx, serde, static builds |
| SWIFT.md | `SWIFT.md` | CloudKit, StoreKit 2, App Review, background work |
| DART.md | `DART.md` | Flutter mobile, desktop and web; store releases |
| ELIXIR.md | `ELIXIR.md` | Phoenix LiveView, Ecto, Oban, Broadway, clustering |
| ERLANG.md | `ERLANG.md` | OTP, distribution, netsplits, relx, Cowboy |
| HASKELL.md | `HASKELL.md` | GHC runtime, laziness, Hasql, reproducible builds |
| CLOJURE.md | `CLOJURE.md` | core.async, Ring, Reitit, next.jdbc, ClojureScript |
| C.md | `C.md` | epoll, signals, fork, OpenSSL, CMake, systemd |
| CPP.md | `CPP.md` | ABI, Asio, Eigen, mobile toolchains, OpenMP |
| LUA.md | `LUA.md` | OpenResty, LuaJIT, LÖVE, Lapis |
| JULIA.md | `JULIA.md` | Latency, PackageCompiler, threads, Oxygen.jl |
| BASH.md | `BASH.md` | set -e, cron, systemd timers, curl, rsync |
| POWERSHELL.md | `POWERSHELL.md` | 5.1 vs 7, Graph, Exchange Online, scheduled tasks |
| PERL.md | `PERL.md` | DBI, taint, Unicode, Template Toolkit |
| JQ.md | `JQ.md` | jq 1.7 behavior, streaming, modules, tests |

A WordPress plugin that takes Stripe payments and uses custom MySQL tables,
for example, gets `WP.md` + `SERVICES.md` + `DATA.md`.
