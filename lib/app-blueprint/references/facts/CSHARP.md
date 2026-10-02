# CSHARP facts
Covers: .NET 8/9/10, ASP.NET Core (Web API, minimal APIs, MVC, Blazor Server/WASM, SignalR, Identity, Data Protection), EF Core, worker services/BackgroundService, .NET MAUI, WPF/WinUI 3, HttpClient, from the TECH_STACK lines of support-files/CSHARP.md
Verified: 2026-09-29 against official documentation. Re-verify facts older than 12 months.

## Platform support

### CS-01 .NET 8 and 9 reach end of support in November 2026
- Trap: ".NET 8 (LTS)" is a safe long-term target for a new system.
- Reality: .NET 8 (LTS) and .NET 9 (STS) both end support on 2026-11-10. .NET 10 (LTS) is supported until 2028-11-14. LTS gets 3 years and STS gets 2. Only the latest patch is supported.
- Detect: "WPF (.NET 8)", ".NET 8 worker services", or any new build pinned to net8.0/net9.0.
- Fix: Target .NET 10 and plan a yearly patch cadence plus the next LTS upgrade.
- Source: .NET and .NET Core Support Policy - https://dotnet.microsoft.com/en-us/platform/support/policy/dotnet-core

### CS-02 MAUI versions expire early and pin the Android target API
- Trap: A MAUI app can stay on the same .NET version as the backend and still ship to Google Play.
- Reality: Each MAUI version gets only 6 months of support after its successor ships. MAUI 8 ended 2025-05-14, MAUI 9 ended 2026-05-12, and MAUI 10 runs to 2027-05-11. `net10.0-android` targets API 36, which Play requires for updates from 2026-08-31. `net9.0-android` targets API 35.
- Detect: ".NET MAUI" with no version or an older one, "stay on .NET 8 for the mobile app".
- Fix: Use MAUI 10 now and budget a MAUI upgrade every year.
- Source: .NET MAUI Support Policy - https://dotnet.microsoft.com/en-us/platform/support/policy/maui ; What's new in .NET MAUI for .NET 10 - https://learn.microsoft.com/en-us/dotnet/maui/whats-new/dotnet-10

## EF Core

### CS-03 DbContext is scoped and not thread-safe
- Trap: One DbContext can be shared by a singleton, a BackgroundService, parallel tasks, or a Blazor Server page.
- Reality: `AddDbContext` registers a scoped context. Parallel operations on one instance are unsupported and throw, or silently corrupt state. Hosted services get no scope by default. In Blazor Server, one scoped context lives for the whole user circuit.
- Detect: `Task.WhenAll` over queries on one context, DbContext injected into singletons or workers, Blazor Server with `AddDbContext` only.
- Fix: Create a scope per unit of work (`IServiceScopeFactory`) or use `IDbContextFactory` (the recommended choice for Blazor), and await every call immediately.
- Source: DbContext Lifetime, Configuration, and Initialization - https://learn.microsoft.com/en-us/ef/core/dbcontext-configuration/

### CS-04 Loading and tracking defaults
- Trap: Navigation properties load on access, and read queries are cheap.
- Reality: Lazy loading is opt-in (`UseLazyLoadingProxies` with virtual navigations). Without it, navigations stay empty unless you use `Include` or explicit loading. With it, loops cause N+1 round trips. Queries track by default. `Include` on sibling collections causes cartesian explosion; single-query mode is the default.
- Detect: Report or list screens iterating navigations, "enable lazy loading" as a convenience, several collection `Include`s.
- Fix: Project to DTOs, use `AsNoTracking` for reads, and use `AsSplitQuery` (with a unique ordering when paging) for multiple collections.
- Source: Lazy Loading - https://learn.microsoft.com/en-us/ef/core/querying/related-data/lazy ; Single vs. Split Queries - https://learn.microsoft.com/en-us/ef/core/querying/single-split-queries ; Tracking vs. No-Tracking - https://learn.microsoft.com/en-us/ef/core/querying/tracking

### CS-05 Applying migrations in production
- Trap: Call `Database.Migrate()` (or `EnsureCreated()`) at startup on every instance.
- Reality: Microsoft recommends migration bundles for automated deployment and SQL scripts when review is needed. EF Core 9+ takes a database-wide lock for `Migrate`, but runtime migration still needs schema-altering rights and gives no review or rollback. EF 9+ `Migrate()` throws on pending model changes. `EnsureCreated` bypasses migrations and breaks a later `Migrate`.
- Detect: `Migrate()` in `Program.cs`, the app identity as `db_owner`, `EnsureCreated` outside tests.
- Fix: Build an `efbundle` or idempotent script in CI, run it as a one-shot deploy job with a separate identity, and gate CI on `has-pending-model-changes`.
- Source: Applying Migrations - https://learn.microsoft.com/en-us/ef/core/managing-schemas/migrations/applying

## Background work

### CS-06 BackgroundService exceptions stop the host
- Trap: If a worker loop throws, the service logs it and keeps running, or restarts itself.
- Reality: Since .NET 6, an unhandled exception in `ExecuteAsync` is logged and stops the whole host, taking the web app down with it. `BackgroundServiceExceptionBehavior.Ignore` restores the old silent-death behavior.
- Detect: Ingestion or poll workers without per-iteration try/catch, workers hosted inside the API process.
- Fix: Catch and handle per message or iteration, and let the orchestrator (systemd, Windows Service recovery, Kubernetes) restart on fatal errors.
- Source: Breaking change: Exception handling in hosting - https://learn.microsoft.com/en-us/dotnet/core/compatibility/core-libraries/6.0/hosting-exception-handling

### CS-07 Hosted service startup and shutdown are sequential
- Trap: Long initialization in `StartAsync` or the start of `ExecuteAsync` runs in parallel with app startup.
- Reality: Hosted services start in registration order, and each `StartAsync` must finish before the next starts. `ExecuteAsync` blocks startup until its first real `await`. The host waits for `ExecuteAsync` on stop, limited by `ShutdownTimeout`. `ServicesStartConcurrently` is opt-in.
- Detect: Cache warm-up, broker connection or data loads in worker startup, no cancellation token handling.
- Fix: Keep startup short, `await` early, honor the stopping token, and tune `ShutdownTimeout` for in-flight work.
- Source: Background tasks with hosted services - https://learn.microsoft.com/en-us/aspnet/core/fundamentals/host/hosted-services

## HTTP clients

### CS-08 HttpClient lifetime
- Trap: `new HttpClient()` per call in a `using` block, or one static client forever.
- Reality: A client per request exhausts ports (TIME_WAIT). A long-lived client ignores DNS changes unless `PooledConnectionLifetime` is set. `IHttpClientFactory` pools handlers but its clients are meant to be short-lived, and pooled handlers share cookie containers.
- Detect: Partner or vendor adapters creating clients per request, typed clients captured in singletons.
- Fix: Use a static/singleton client with `PooledConnectionLifetime`, or typed clients from `IHttpClientFactory` (with resilience handlers).
- Source: HttpClient guidelines for .NET - https://learn.microsoft.com/en-us/dotnet/fundamentals/networking/http/httpclient-guidelines

## Auth and security

### CS-09 Data Protection keys must persist and be shared
- Trap: Auth cookies, antiforgery tokens and protected payloads just work across restarts and replicas.
- Reality: Payloads are encrypted with a key ring that is isolated per app by content-root path. In containers, keys must live on a persistent volume or an external store. Replicas must share the key repository and the same `SetApplicationName`. Otherwise users are logged out and antiforgery fails after deploys or across nodes. Keys roll every 90 days by default.
- Detect: Multi-instance App Service or Kubernetes deployments with cookie auth or Blazor Server and no key storage plan.
- Fix: `PersistKeysTo…` (Blob, Redis with persistence, file share) plus `ProtectKeysWith…` and `SetApplicationName`.
- Source: Configure ASP.NET Core Data Protection - https://learn.microsoft.com/en-us/aspnet/core/security/data-protection/configuration/overview

### CS-10 Identity defaults are weak for regulated apps
- Trap: ASP.NET Core Identity locks out brute-force attempts and enforces unique, confirmed emails by default.
- Reality: Lockout triggers only if sign-in passes `lockoutOnFailure: true`, and the template passes `false`. After that, the defaults are 5 attempts and 5 minutes. `RequireConfirmedEmail` is false, `RequireUniqueEmail` is false, and the minimum password length is 6.
- Detect: Member, patient or financial portals on Identity with "account lockout" or password policy claims and no configuration.
- Fix: Set `lockoutOnFailure: true`, configure `PasswordOptions`, `SignIn` and `User` options explicitly, and document the policy.
- Source: Configure ASP.NET Core Identity - https://learn.microsoft.com/en-us/aspnet/core/security/authentication/identity-configuration

## Real-time and Blazor Server

### CS-11 SignalR and Blazor Server scale-out need affinity plus a backplane
- Trap: SignalR hubs and Blazor Server scale out behind a round-robin load balancer, and a Redis backplane removes the need for sticky sessions.
- Reality: Sticky sessions are required on a farm, even with the Redis backplane, unless you use Azure SignalR Service or WebSockets-only with SkipNegotiation. Without a backplane, broadcasts reach only the clients on the sending server.
- Detect: SignalR dashboards or yard boards on multiple instances with no affinity or backplane decision.
- Fix: Use Azure SignalR Service, or Redis backplane plus session affinity (ARR affinity, ingress cookie affinity).
- Source: SignalR hosting and scaling - https://learn.microsoft.com/en-us/aspnet/core/signalr/scale

### CS-12 Blazor Server state lives in server memory
- Trap: Blazor Server keeps form state safely, like a SPA.
- Reality: Component state lives in the circuit on one server, at about 250 KB or more per circuit. If reconnect fails (server restart, scale-in) or the user reloads, a new circuit starts with fresh state. Persistence is not automatic. .NET 10 adds opt-in circuit state persistence, which is still lost on a page refresh.
- Detect: Long multi-step forms or edit sessions on Blazor Server with no save or draft strategy, "stateless" autoscaling.
- Fix: Persist high-value state (drafts in the DB or browser storage, IDs in the URL) and plan memory per concurrent user.
- Source: Blazor server-side state management - https://learn.microsoft.com/en-us/aspnet/core/blazor/state-management/server ; Host and deploy server-side Blazor - https://learn.microsoft.com/en-us/aspnet/core/blazor/host-and-deploy/server/

## Web APIs

### CS-13 Minimal APIs: validation and controller-only features
- Trap: Minimal API endpoints validate DataAnnotations like `[ApiController]` does.
- Reality: Built-in minimal API validation arrived in .NET 10 and requires `builder.Services.AddValidation()`, which discovers types only in the calling assembly. Earlier versions do no automatic validation. Controllers still provide `IModelBinder` extensibility, `IModelValidator`, application parts and OData.
- Detect: Minimal APIs on .NET 8/9 relying on `[Required]`, endpoints split across assemblies.
- Fix: On .NET 10, call `AddValidation` in each assembly that defines endpoints. Otherwise validate explicitly, or choose controllers when those features matter.
- Source: What's new in ASP.NET Core 10.0 - https://learn.microsoft.com/en-us/aspnet/core/release-notes/aspnetcore-10.0 ; APIs overview - https://learn.microsoft.com/en-us/aspnet/core/fundamentals/apis

## MAUI platform

### CS-14 MAUI SecureStorage is platform-dependent
- Trap: `SecureStorage` behaves the same everywhere and is wiped on uninstall.
- Reality: On Android, Auto Backup can restore encrypted preferences that cannot be decrypted, so `GetAsync` can throw. On iOS, Keychain entries survive uninstall and may sync through iCloud Keychain. It is designed for small values only.
- Detect: Tokens or PHI in `SecureStorage` on shared or rugged devices, no backup rules.
- Fix: Exclude the SecureStorage prefs from Auto Backup, wrap calls in try/catch with `RemoveAll`, and clear the Keychain on first launch.
- Source: Secure storage - https://learn.microsoft.com/en-us/dotnet/maui/platform-integration/storage/secure-storage
