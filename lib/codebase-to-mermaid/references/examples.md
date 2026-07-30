# Few-shot Archetype → Diagram Examples

Twenty-four worked examples mapping concrete repo shapes to concrete diagram choices. Use when the archetype is borderline or paired.

**Example 1.** Repo has `cmd/api/main.go`, `internal/handlers/*.go`, `chi.Router`.
→ Archetype: HTTP request handler. Diagrams: `flowchart LR` of router → middleware → handlers → repo layer, plus one `sequenceDiagram` for the busiest route.

**Example 2.** Repo has `dags/`, `airflow.cfg`, Python operators chained with `>>`.
→ Archetype: data pipeline. Diagram: `flowchart LR` per DAG, nodes = tasks, edges = `>>` dependencies.

**Example 3.** Repo `wp-content/plugins/foo/foo.php` with `Plugin Name:` header, `add_action('rest_api_init', …)`, `register_post_type`, an admin settings page.
→ Archetype: WordPress plugin. Diagrams: (a) `flowchart TD` lifecycle activation → `plugins_loaded` → `init` → `admin_init`/`rest_api_init` → frontend filters. (b) `sequenceDiagram` of one REST endpoint: `WP_REST_Server` → permission callback → handler → DB → response. (c) `flowchart LR` of registered hooks → callbacks → side effects.

**Example 4.** Repo `wp-content/themes/bar/` with `style.css`, `functions.php`, `single.php`, `archive.php`, `page.php`, `template-parts/`, `block-templates/single.html`, `theme.json`.
→ Archetype: WordPress theme. Diagrams: (a) `flowchart TD` template hierarchy resolution by request type. (b) `flowchart LR` of `functions.php` hook registrations → callbacks. (c) per-template enqueue map.

**Example 5.** Repo has `src/main.tsx`, `react-router-dom`, `@tanstack/query`, `zustand` store, REST fetches in `src/api/`.
→ Archetype: Frontend SPA. Diagrams: (a) `flowchart TD` route tree from `createBrowserRouter`. (b) `flowchart LR` of page component → React Query hook → fetcher → backend endpoint (with the backend node labeled as external). (c) `classDiagram` (optional) of Zustand store slices.

**Example 6.** Repo has `app/` directory with `app/(marketing)/page.tsx`, `app/api/users/route.ts`, server actions, `prisma/schema.prisma`.
→ Archetype: Next.js App Router. Diagrams: (a) `flowchart TD` route tree split into Server vs Client component groups (use subgraphs). (b) `sequenceDiagram` for one route: browser → server component → action → Prisma → Postgres → revalidate → response. (c) `classDiagram` of Prisma models.

**Example 7.** Repo has `server.js` with `express()`, routers in `routes/`, `mongoose.connect`, schemas in `models/`.
→ Archetype: Node backend, MongoDB. Diagrams: (a) `flowchart LR` `server.js` → middleware (`helmet`, `morgan`, `cors`, body parser) → router → controller → service → Mongoose model → `Mongo`. (b) `sequenceDiagram` of one route covering Zod validation, Mongoose query, response. (c) `classDiagram` of Mongoose schemas with refs as associations.

**Example 8.** Repo has `index.ts` with `Fastify()`, `prisma/schema.prisma` pointing at Postgres, `bullmq` worker in `workers/email.ts`.
→ Archetype: Node backend, Postgres + queue. Diagrams: (a) `flowchart LR` HTTP path: Fastify → plugin chain → route → service → Prisma → `Postgres`. (b) `flowchart LR` async path: producer (`Queue.add`) → Redis → worker → service → Postgres / external SMTP. (c) `sequenceDiagram` of a job lifecycle.

**Example 9.** Repo has `server.js` using `better-sqlite3`, hand-written routes via `http.createServer`, no framework.
→ Archetype: Node backend, SQLite, no framework. Diagrams: (a) `flowchart TD` of `server.js` request dispatch (URL switch → handler functions → prepared statements → `SQLite` file). (b) `flowchart LR` include/require graph for the top 20 modules.

**Example 10.** Repo has `artisan`, `routes/web.php`, `routes/api.php`, controllers in `app/Http/Controllers/`, Eloquent models, queued jobs in `app/Jobs/`.
→ Archetype: Laravel app. Diagrams: (a) `flowchart LR` HTTP kernel → global middleware → route middleware → controller → service → Eloquent model → DB. (b) `flowchart TD` service providers boot order + key bindings. (c) `sequenceDiagram` for an event → listener → queued job → DB write.

**Example 11.** Repo has `bin/console`, `config/routes.yaml`, controllers with `#[Route(`, `src/EventSubscriber/`, `src/MessageHandler/`.
→ Archetype: Symfony app. Diagrams: (a) `flowchart LR` HttpKernel → `kernel.request` → `kernel.controller` → controller → service → Doctrine repository → DB. (b) `flowchart TD` of bundle registration and tagged services. (c) `sequenceDiagram` of a Messenger handler dispatched via `MessageBusInterface`.

**Example 12.** Repo has `index.php` parsing `$_SERVER['REQUEST_URI']`, custom `Router` class, raw PDO calls, included partials. No composer framework dep.
→ Archetype: Custom / vanilla PHP. Diagrams: (a) `flowchart TD`: `index.php` → router parse → dispatched handler → included files → PDO → MySQL → rendered template. (b) `flowchart LR` include graph of top 20 includes. Notes section calls out that no framework was detected and the router is hand-rolled.

**Example 13.** Repo is a `scripts/` directory with `deploy.sh`, `backup.sh`, `lib/common.sh` (`source`d), `Makefile` with `build`/`deploy`/`clean` targets, plus `set -euo pipefail` everywhere.
→ Archetype: Bash script collection. Diagrams: (a) `flowchart TD` per top-level script: entry → arg parsing (`getopts`) → guards → sourced helpers → external commands (`aws s3 cp`, `docker push`, `kubectl apply`) → exit. (b) `flowchart LR` of Makefile target DAG with edges from `target:` dependencies. External services rendered as cylinder/stadium nodes. Destructive steps (`rm -rf`, `aws s3 rm --recursive`) tagged with a warning style.

**Example 14.** Repo has `bin/wp-bootstrap.sh`, `bin/wp-deploy.sh`, both invoking `wp core install`, `wp plugin install`, `wp option update`, `wp search-replace`, optionally `--ssh=` to a remote host. One PHP file registers `WP_CLI::add_command('mycli ingest', ...)`.
→ Archetype: WP-CLI script. Diagrams: (a) `flowchart TD` of `wp-bootstrap.sh`: guards → `wp core download` → `wp config create` → `wp core install` → `wp plugin install/activate` (list) → `wp theme activate` → `wp rewrite flush`. Each `wp` call is a node with the full subcommand as label. (b) `sequenceDiagram`: shell → `wp` binary → `wp-load.php` → WordPress core (`plugins_loaded`, `init`) → activated plugin hooks → MySQL. (c) `classDiagram` of `mycli ingest` command class showing its subcommands and arg signatures. Notes section flags `wp search-replace` and `wp db reset` as destructive.

**Example 15.** Repo has `go.mod`, `cmd/api/main.go`, chi router in `internal/http/`, services in `internal/service/`, sqlc-generated repo in `internal/db/`.
→ Archetype: Go HTTP service. Diagrams: (a) `flowchart LR`: `main.go` → chi router → middleware (`chi.Logger`, `chi.Recoverer`) → handler → service → sqlc `Queries` → `Postgres`. (b) `sequenceDiagram` for `POST /users` covering JSON decode, validate, `tx.Begin`, sqlc query, commit, response. (c) `classDiagram` of sqlc generated structs.

**Example 16.** Repo has `Cargo.toml` w/ `axum`, `tokio`, `sqlx`; `src/main.rs` with `#[tokio::main]`; `src/handlers/`, `src/db/`.
→ Archetype: Rust web service. Diagrams: (a) `flowchart LR`: `main.rs` → `Router::new()` → tower layers (`TraceLayer`, `CorsLayer`) → extractors (`State<AppState>`, `Json<T>`) → handler → repo → `sqlx::query_as!` → `Postgres`. (b) `sequenceDiagram` for one route showing extractor parse, query, `Result<Json<…>, AppError>`. (c) `classDiagram` of `FromRow` structs and `AppError` enum.

**Example 17.** Laravel 11 app with `composer.json` requiring `livewire/livewire`. `app/Livewire/UserDashboard.php` extends `Livewire\Component` with `wire:model` properties; `resources/views/livewire/user-dashboard.blade.php`; `routes/web.php` mounting `Route::get('/dashboard', UserDashboard::class)`.
→ Archetypes: Laravel + Livewire (paired). Diagrams: (a) Laravel `flowchart LR` request → middleware → route → Livewire route handler → component class. (b) Livewire `sequenceDiagram` of one `wire:click="save"`: browser → `livewire/update` POST → component hydration → `save()` method → Eloquent → DB → component diff → DOM patch. (c) `classDiagram` of all Livewire components: public props, computed properties, `$listeners`, methods.

**Example 18.** Static marketing site with HTML/CSS, `<script src="https://unpkg.com/htmx.org@2.0.4" integrity="sha384-..." crossorigin="anonymous">` (SRI-pinned), attributes `hx-get="/api/quote"`, `hx-target="#quote"`, plus Alpine.js `x-data="{ open: false }"` on disclosure widgets. Server is a Go/chi backend returning HTML partials.
→ Archetypes: Go HTTP service + htmx + Alpine (three paired diagrams). Diagrams: (a) Go backend `flowchart LR` as Example 15. (b) htmx `sequenceDiagram` of `hx-get="/api/quote"` click → server route `/api/quote` → HTML partial → `hx-swap="outerHTML"` into `#quote`. (c) Alpine `flowchart TD` per `x-data` island: state → `@click` handler → reactive `x-show` bindings → DOM effects.

**Example 19.** Repo `*.vue` SFCs with `<script setup lang="ts">`, `vue-router`, Pinia store `stores/cart.ts`, `useFetch` composable hitting a Nest backend.
→ Archetype: Vue.js SPA (TypeScript-typed). Diagrams: (a) `flowchart TD` route tree from `createRouter`. (b) `flowchart LR` per page: page SFC → child SFCs → composable → fetcher → backend endpoint. (c) `classDiagram` of Pinia store (state/getters/actions) plus DTO interfaces shared between client and Nest server.

**Example 20.** Spring Boot 3 app: `pom.xml` w/ `spring-boot-starter-web`, `spring-boot-starter-data-jpa`, `Application.java` with `@SpringBootApplication`, controllers under `com.example.api.web`, services under `…service`, JPA entities under `…domain`, `application.yml` pointing at PostgreSQL.
→ Archetype: Spring Boot. Diagrams: (a) `flowchart LR`: `Application.main` → DispatcherServlet → `SecurityFilterChain` → `@RestController` → `@Service` (`@Transactional`) → `JpaRepository` → `Postgres`. (b) `sequenceDiagram` for `POST /api/orders` covering DTO validation, mapper, transaction, JPA save, response. (c) `classDiagram` of `@Entity` classes with `@OneToMany`/`@ManyToOne` edges.

**Example 21.** ASP.NET Core 8 Minimal API: `Program.cs` registers `builder.Services.AddDbContext<AppDbContext>`, maps endpoints via `app.MapGet("/users", …)`, EF Core entities in `Models/`, migrations in `Migrations/`.
→ Archetype: ASP.NET Core (Minimal API). Diagrams: (a) `flowchart LR`: `Program.cs` → middleware (`UseAuthentication`, `UseAuthorization`, `UseEndpoints`) → mapped endpoint delegate → `AppDbContext` → EF Core → `SqlServer`. (b) `sequenceDiagram` for one endpoint covering model binding, validation, EF query, JSON response. (c) `classDiagram` of EF entities with navigation properties. (d) DI map `flowchart LR` of `AddScoped`/`AddSingleton` registrations → consumers.

**Example 22.** C++ project with `CMakeLists.txt` defining `app` executable linking `libcore`, sources in `src/`, headers in `include/core/`, Qt-based UI in `src/ui/` with `Q_OBJECT`/`signals`/`slots`.
→ Archetype: C++ service/app (Qt). Diagrams: (a) `flowchart LR` CMake target graph (`add_library(core)` → `target_link_libraries(app PRIVATE core Qt6::Widgets)`). (b) `flowchart TD` of `main.cpp` → `QApplication` → `MainWindow` ctor → child widgets → signal/slot wiring. (c) `classDiagram` of public classes in `include/core/`. (d) `flowchart LR` of Qt signal/slot connections per `QObject`.

**Example 23.** C project: `src/main.c` parses CLI with `getopt_long`, loads config, opens a libuv loop, dispatches to handlers under `src/handlers/`, errors propagate via `goto cleanup;`.
→ Archetype: C application. Diagrams: (a) `flowchart TD` of `main`: `getopt_long` → config load → `uv_loop_init` → register handles → `uv_run` → cleanup labels (each `goto cleanup_N` is its own node). (b) `flowchart LR` include graph of top 20 `.c` files. (c) Notes section flags every `errno` propagation point worth auditing.

**Example 24.** TypeScript tRPC monorepo: `apps/api` with `appRouter` composing routers per domain, `apps/web` Next.js consuming `@trpc/react-query`. Prisma schema shared.
→ Archetype: TypeScript-typed Node backend + Next.js frontend. Diagrams: (a) `flowchart TD` tRPC procedure tree (router → sub-routers → procedures with input/output Zod schemas). (b) `flowchart LR`: web component → `trpc.users.list.useQuery()` → HTTP → server handler → Prisma → `Postgres`. (c) `classDiagram` of Prisma models. (d) Notes section calls out which procedures are public vs protected based on middleware.
