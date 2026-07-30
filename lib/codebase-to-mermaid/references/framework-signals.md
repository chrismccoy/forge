# Framework Signals - Phase 1 Grep Cheat Sheet

Use this reference when the project's stack is not immediately obvious from the manifest file. Each section lists the canonical strings and file shapes to `Grep` for. Stop on the first strong match per category; multiple categories can match (a Laravel + Livewire + Alpine app trips three).

## Node HTTP server

- `express()`, `app.use(`, `app.get/post/put/delete(`, `Router()`, `fastify(`, `Koa(`, `new Hono(`, `NestFactory.create`, `http.createServer`, `https.createServer`

## Node entry / process

- `package.json` `"main"`, `"bin"`, `"scripts.start"`
- `bin/*.js` shebangs
- `cluster.fork`, `worker_threads`, `pm2.config.*`, `ecosystem.config.js`
- Dockerfile `CMD ["node",...]`

## Node DB drivers / ORMs

- **MongoDB:** `mongodb` (`MongoClient`, `db.collection(...)`), `mongoose` (`mongoose.connect`, `Schema(`, `model(`), `typegoose`
- **MySQL / MariaDB:** `mysql2`, `mysql`, `createPool`, `pool.query`, `pool.execute`
- **PostgreSQL:** `pg` (`new Pool`, `client.query`), `postgres` (porsager), `node-postgres`
- **SQLite:** `better-sqlite3`, `sqlite3`, `new Database(`, `.prepare(`
- **SQL builders / ORMs:** `prisma` (`@prisma/client`, `schema.prisma`), `drizzle-orm`, `kysely`, `knex`, `typeorm` (`@Entity`, `getRepository`), `sequelize` (`sequelize.define`, `Model.init`), `mikro-orm`
- **Cache / KV:** `redis`, `ioredis`, `memcached`

## Node async / queue

- `bullmq`, `bee-queue`, `agenda`, `node-cron`, `EventEmitter`
- pub/sub: `amqplib`, `kafkajs`, `nats`

## Node validation / DTO

- `zod`, `yup`, `joi`, `class-validator`, `valibot`

## JS frontend / SSR

- `react-router`, `createBrowserRouter`, `vue-router`
- `next` (`app/` dir = App Router; `pages/` = Pages Router), `nuxt`, `astro`, `sveltekit`, `remix`, `solid-start`

## JS state / data

- `redux`, `zustand`, `pinia`, `@tanstack/query`, `swr`, `apollo`, `urql`, `trpc`

## JS bundler / runtime hints

- `vite.config.*`, `webpack.config.*`, `next.config.*`, `astro.config.*`, `turbo.json`
- monorepo: `pnpm-workspace.yaml`, `nx.json`

## WordPress plugin signals

- `Plugin Name:` header in main `.php`
- `register_activation_hook`, `register_deactivation_hook`, `plugin_dir_path`, `plugins_url`, `WP_PLUGIN_DIR`

## WordPress theme signals

- `style.css` with `Theme Name:` header
- `functions.php`, `wp_enqueue_style` / `wp_enqueue_script`
- template hierarchy files (`index.php`, `single.php`, `archive.php`, `page.php`, `header.php`, `footer.php`, `front-page.php`)
- `block-templates/`, `theme.json`

## WordPress hook surface

- `add_action(`, `add_filter(`, `do_action(`, `apply_filters(`
- `register_rest_route`, `register_post_type`, `register_taxonomy`
- `add_shortcode`, `add_meta_box`, `admin_menu`
- `wp_ajax_`, `wp_ajax_nopriv_`

## WordPress block editor (Gutenberg)

- `block.json`, `registerBlockType`, `wp.blocks`, `@wordpress/scripts`
- `src/blocks/*/index.js`

## WooCommerce

- `woocommerce_` prefixed hooks
- `WC_Product`, `WC()->cart`

## Laravel

- `composer.json` requires `laravel/framework`; `artisan` file at root
- `routes/web.php`, `routes/api.php`, `routes/console.php`
- `app/Http/Controllers/`, `app/Http/Middleware/`, `app/Models/`, `app/Providers/`, `app/Console/Commands/`, `app/Jobs/`, `app/Events/`, `app/Listeners/`, `app/Policies/`
- `config/`, `database/migrations/`, `database/seeders/`
- Blade in `resources/views/*.blade.php`
- Eloquent `extends Model`, `Route::get`, `Route::resource`, `dispatch(`, `event(`
- queue/listener wiring in `EventServiceProvider`

## Symfony

- `composer.json` requires `symfony/framework-bundle`; `bin/console`
- `config/routes.yaml`, `config/services.yaml`, `config/bundles.php`
- `src/Controller/`, `src/Entity/`, `src/Repository/`, `src/EventSubscriber/`, `src/EventListener/`, `src/Command/`, `src/MessageHandler/`
- route attributes `#[Route(`, `#[AsCommand(`, `#[AsEventListener(`, `#[AsMessageHandler]`
- Twig in `templates/*.html.twig`; Doctrine `#[ORM\Entity]`

## Other PHP MVC / micro

- Slim (`$app->get`), Lumen, CodeIgniter (`application/controllers/`), CakePHP (`src/Controller/`), Yii (`controllers/`)
- Drupal (`*.module`, `*.info.yml`, `hook_*`)
- Magento (`etc/module.xml`, `Block/`, `Model/`, `Controller/`)
- PrestaShop, Joomla (`extension.xml`)

## Custom PHP framework / vanilla

No recognized framework dep but PHP files present. Look for:

- hand-rolled front controller (`index.php` with `$_SERVER['REQUEST_URI']` parsing, `require`/`autoload.php`, custom `Router` class, raw `PDO`/`mysqli`, session bootstrap)

Treat the front controller as entry point and walk includes outward.

## PHP signal grep set

- `namespace `, `use App\`, `class .* extends Controller`
- `Route::`, `#[Route(`
- `add_action(`, `do_action(`, `apply_filters(`
- `dispatch(`, `event(`
- `Artisan::call`, `php artisan`
- `$app->`, `register_shutdown_function`, `spl_autoload_register`

## Other HTTP

- `FastAPI`, `flask`, `Rails::Application`

## Go

- **Manifest / layout:** `go.mod`, `go.sum`, `cmd/<name>/main.go`, `internal/`, `pkg/`, `Dockerfile` with `golang:` base
- **HTTP routers:** `net/http` (`http.HandleFunc`, `http.ListenAndServe`), `chi` (`chi.NewRouter`), `gin` (`gin.Default`, `r.GET`), `echo` (`echo.New`), `fiber` (`fiber.New`), `gorilla/mux` (`mux.NewRouter`), `httprouter`
- **gRPC / streaming:** `google.golang.org/grpc`, `RegisterXxxServer`, `*.proto`, `connectrpc`
- **Concurrency primitives:** `go func()`, `chan ` types, `select {`, `sync.WaitGroup`, `errgroup.Group`
- **DB:** `database/sql`, `sqlx`, `sqlc` (`db.Queries`), `pgx` (`pgxpool.New`), `gorm.io/gorm`, `ent.New`, `bun`, `sqlboiler`
- **CLI:** `cobra` (`cobra.Command{}`), `urfave/cli`, `kingpin`, `pflag`
- **Config / DI:** `viper`, `wire` (compile-time DI), `fx`

## Rust

- **Manifest / layout:** `Cargo.toml`, `Cargo.lock`, `src/main.rs`, `src/lib.rs`, `src/bin/*.rs`, workspace `[workspace] members =`
- **HTTP frameworks:** `axum` (`Router::new`, `.route(`), `actix-web` (`HttpServer::new`, `App::new`), `rocket` (`#[get(`, `#[launch]`), `warp`, `tide`, `salvo`, `poem`, `tower` middleware
- **Async runtime:** `tokio` (`#[tokio::main]`), `async-std`, `smol`
- **DB / ORM:** `sqlx` (`sqlx::query!`, `Pool<Postgres>`), `diesel` (`#[derive(Queryable)]`), `sea-orm` (`Entity::find`), `tokio-postgres`, `mysql_async`, `mongodb`
- **CLI / args:** `clap` (`#[derive(Parser)]`), `structopt`, `argh`
- **WASM frontend:** `leptos`, `yew`, `dioxus`, `wasm-bindgen`, `trunk.toml`
- **Error / serde:** `thiserror`, `anyhow`, `serde`, `serde_json`

## Hypermedia / lightweight JS frontends

Always pair the hypermedia archetype with the underlying server archetype (Laravel + Livewire, Rails + htmx, Go/chi + htmx, WordPress + Alpine, etc.) and emit one diagram per layer plus one `sequenceDiagram` of a round-trip (DOM event → request → server handler → HTML fragment response → swap target).

- **htmx:** `hx-get`, `hx-post`, `hx-put`, `hx-delete`, `hx-target`, `hx-swap`, `hx-trigger`, `hx-boost`, `hx-push-url`, `hx-vals`, `hx-include`, `hx-ext`, `<script src="…htmx.org…">`, `htmx.org` in `package.json`
- **Alpine.js:** `x-data`, `x-init`, `x-show`, `x-bind`, `x-model`, `x-for`, `x-if`, `x-on:` / `@click`, `Alpine.store(`, `Alpine.data(`, `Alpine.start()`, `alpinejs` in `package.json`
- **Livewire (Laravel):** `composer.json` requires `livewire/livewire`; PHP components in `app/Livewire/` or `app/Http/Livewire/` extending `Livewire\Component`; Blade views with `wire:model`, `wire:click`, `wire:submit`, `wire:loading`, `wire:poll`, `wire:navigate`, `@livewire(`, `@livewireStyles`, `@livewireScripts`; Volt (`Livewire\Volt\Volt::route`)
- **Vue.js (deep signals):** `*.vue` SFC files (`<template>`, `<script setup>`, `<style scoped>`), `defineComponent`, `defineProps`, `defineEmits`, `ref(`, `reactive(`, `computed(`, `watch(`, `provide`/`inject`, `<RouterView>`, `<Suspense>`, Options API `data()` / `methods` / `computed`, Pinia `defineStore(`, Vuex `createStore`, Nuxt `useFetch` / `useAsyncData`

## Java

- **Build / layout:** `pom.xml` (Maven), `build.gradle` / `build.gradle.kts` (Gradle), `settings.gradle`, `src/main/java/<pkg>/`, `src/main/resources/application.{yml,properties}`, `src/test/java/`, `Dockerfile` with `eclipse-temurin:` or `openjdk:` base, `mvnw`/`gradlew` wrappers
- **Spring Boot:** `@SpringBootApplication`, `SpringApplication.run`, `@RestController`, `@Controller`, `@Service`, `@Repository`, `@Component`, `@Configuration`, `@RequestMapping`, `@GetMapping`/`@PostMapping`/`@PutMapping`/`@DeleteMapping`, `@RequestBody`, `@PathVariable`, `@ExceptionHandler`, `@ControllerAdvice`, `@Scheduled`, `@Async`, Spring Security `@EnableWebSecurity` / `SecurityFilterChain`, Spring Cloud annotations
- **Persistence:** Spring Data JPA `extends JpaRepository<…>`, Hibernate `@Entity` / `@Table` / `@Id` / `@GeneratedValue`, raw `JdbcTemplate`, MyBatis (`@Mapper`, `*Mapper.xml`), R2DBC for reactive
- **Reactive:** `WebFlux`, `Mono`, `Flux`, `@EnableWebFlux`
- **Other Java HTTP / micro:** Jakarta EE (`@Path`, `@ApplicationPath` JAX-RS), Quarkus (`@QuarkusMain`, `application.properties`), Micronaut (`@Controller`, `@MicronautApplication`), Helidon, Vert.x (`AbstractVerticle`), Dropwizard
- **Messaging:** `@KafkaListener`, `@RabbitListener`, `@JmsListener`, Spring Cloud Stream `@StreamListener`

## C# / .NET

- **Build / layout:** `*.csproj`, `*.sln`, `global.json`, `Directory.Build.props`, `Program.cs`, `Startup.cs`, `appsettings.json`, `Dockerfile` with `mcr.microsoft.com/dotnet/`
- **ASP.NET Core:** Minimal API (`var app = WebApplication.CreateBuilder(...).Build();`, `app.MapGet(`, `app.MapPost(`), MVC controllers (`: ControllerBase`, `[ApiController]`, `[Route(`, `[HttpGet]`/`[HttpPost]`), Razor Pages (`@page`), Blazor (`*.razor`, `@code {`, `@inject`), SignalR (`Hub`, `[HubMethodName]`)
- **DI / hosting:** `IServiceCollection`, `builder.Services.AddScoped/AddSingleton/AddTransient`, `IHostedService`, `BackgroundService`, MediatR (`IRequest<>`, `IRequestHandler<>`)
- **EF Core / data:** `DbContext`, `DbSet<>`, `OnModelCreating`, migrations in `Migrations/`, Dapper `connection.Query<T>`, raw ADO.NET `SqlConnection`
- **WPF / WinForms / MAUI / Xamarin:** `*.xaml`, `App.xaml`, `MainWindow.xaml`, `[XamlCompilation]`, MAUI `Shell`
- **Unity:** `MonoBehaviour`, `[SerializeField]`, `Update()`/`Start()`, `Assets/Scripts/`

## C++

- **Build:** `CMakeLists.txt` (`cmake_minimum_required`, `add_executable`, `target_link_libraries`), `Makefile`, Bazel (`BUILD`, `WORKSPACE`), `Meson.build`, `conanfile.{txt,py}`, `vcpkg.json`
- **Layout:** `include/`, `src/`, header/source pairs (`.h`/`.hpp` ↔ `.cpp`/`.cc`/`.cxx`), `main.cpp`
- **Standard idioms:** `#include`, `namespace`, `class`/`struct` defs, `template<...>`, `std::unique_ptr`/`shared_ptr`, RAII, `<thread>`, `<future>`, `<coroutine>`
- **Frameworks:** Qt (`Q_OBJECT`, `signals:`, `slots:`, `.ui` files, `qmake`/`qmlmodule`), Boost (`<boost/…>`), POCO, gRPC C++, Drogon (`#include <drogon/HttpController.h>`), oat++, Crow, Pistache, OpenCV, ROS (`package.xml`, `catkin`/`colcon`), Unreal Engine (`*.uproject`, `UCLASS()`, `UFUNCTION()`)
- **GPU / compute:** CUDA (`*.cu`, `__global__`), OpenMP `#pragma omp`, SYCL, oneAPI

## C

- **Build:** `Makefile`, `configure.ac`/`configure`, `CMakeLists.txt`, `meson.build`, `Kbuild`/`Kconfig` (kernel)
- **Layout:** `src/`, `include/`, header/source pairs (`.h` ↔ `.c`), `main.c`, often a `lib/` plus `bin/` split
- **Standard idioms:** `#include`, `static` linkage, `struct` typedefs, function-pointer dispatch tables, `errno` propagation, `goto` cleanup blocks
- **Frameworks / stacks:** glib/GTK (`g_object_new`, `gtk_application_new`), libuv (`uv_loop_t`), nginx modules (`ngx_module_t`), Linux kernel modules (`module_init`, `MODULE_LICENSE`), embedded vendor SDKs (ESP-IDF `app_main`, STM32 HAL, Zephyr `K_THREAD_DEFINE`), POSIX threads (`pthread_create`)
- **CLI:** `getopt_long`, `argp`, hand-rolled `argv` parsing

## TypeScript (in addition to JS signals above)

- **Manifest / tsconfig:** `tsconfig.json` (`compilerOptions.strict`, `paths`, `baseUrl`), `tsconfig.build.json`, multiple `tsconfig.*.json` in a monorepo
- **Type-driven shapes:** `interface`, `type`, `enum`, `class … implements`, generics `<T extends …>`, discriminated unions, `as const`, `satisfies`
- **Server frameworks (TS-native):** NestJS (`@Module`, `@Controller`, `@Injectable`, `@Get`, decorators-heavy), tRPC (`router({ … })`, `createTRPCRouter`, `procedure.input(zod).query/mutation`), Hono w/ TS, ts-rest, Encore
- **Schema/codegen:** Zod (`z.object`), Yup, io-ts, ArkType, GraphQL Codegen, Prisma generated client types, OpenAPI codegen (`openapi-typescript`)
- **Frontend TS specifics:** `.tsx` files, typed React props (`React.FC<Props>`, `interface Props`), `useState<T>`, Vue `<script setup lang="ts">`, Svelte 5 with TS
- **Build tools:** `tsc`, `tsx`, `ts-node`, `swc`, `esbuild`, `vite` with TS preset, `tsup`, `unbuild`

## Bash scripts

- **Shebangs:** `#!/usr/bin/env bash`, `#!/bin/bash`, `#!/bin/sh`, `#!/usr/bin/env zsh`
- **Script layout:** `*.sh` files, `bin/` or `scripts/` dirs, `Makefile`, `justfile`, `Taskfile.yml`, `.envrc`, `install.sh`, `deploy.sh`, `entrypoint.sh`
- **Control flow markers:** `set -euo pipefail`, `trap`, `case ... esac`, `if [[`, `while read`, `for f in`, function defs `foo() {`
- **Side effects:** `curl`, `wget`, `aws `, `gcloud `, `docker `, `kubectl `, `ssh `, `rsync `, `scp `, `systemctl`, `cron`, `tar`, `zip`, `git `, `mysql`, `psql`, `sqlite3`, `mongoexport`, `redis-cli`
- **Pipelines / composition:** subshells `$(...)`, pipes `|`, `xargs`, `tee`, `>&2`, here-docs `<<EOF`

## WP-CLI scripts (Bash + WordPress)

- **Shebang + signal:** any `.sh` file with `wp ` invocations on a line. `wp --info`, `wp core download`, `wp core install`, `wp plugin install/activate`, `wp theme install/activate`, `wp option update`, `wp user create`, `wp post create`, `wp db export/import`, `wp search-replace`, `wp cron event run`, `wp cli alias`, `wp eval`, `wp eval-file`, `wp rewrite flush`, `wp transient delete`, `wp media regenerate`
- **Common wrappers:** `WP_CLI=$(which wp)`, `wp --allow-root`, `wp --path=/var/www/html`, `wp --url=`, `wp --ssh=user@host:/path`
- **Multisite signals:** `wp site list`, `wp site create`, `--network`
- **Custom WP-CLI commands defined in PHP:** `WP_CLI::add_command(`, `WP_CLI::log`, `WP_CLI::success`, `WP_CLI::error` inside `*.php` files referenced by `bin/` scripts

## CLI frameworks

- `argparse`, `clap`, `cobra`, `commander`, `click`, `yargs`, `oclif`

## Data pipeline

- `airflow`, `prefect`, `dagster`, `luigi`, `spark`

## Event-driven

- `kafka`, `rabbitmq`, `EventBridge`, `pubsub`, generic hook/event-emitter systems
