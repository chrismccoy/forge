# KOTLIN facts
Covers: Kotlin on Android (Jetpack Compose, Room, WorkManager, CameraX/BLE apps), kotlinx.coroutines, Ktor server, Kotlin with Spring Boot (MVC, WebFlux, JPA), Compose Multiplatform Desktop, from the TECH_STACK lines of support-files/KOTLIN.md
Verified: 2026-09-29 against official documentation. Re-verify facts older than 12 months.

## Android background work

### KT-01 Coroutines are not background jobs; WorkManager is
- Trap: Sync or upload runs in `viewModelScope`/`lifecycleScope` (or a plain service) and finishes after the user leaves the app.
- Reality: Coroutines and threads are not persistent. They stop when the app leaves a valid lifecycle state. WorkManager work persists across process death and reboots and is the recommended default. Work longer than about 10 minutes is likely to be interrupted.
- Detect: "sync in the background with coroutines", offline queues flushed from a ViewModel, long uploads in one worker.
- Fix: Enqueue WorkManager work with constraints, split long work into chunks, and keep coroutines for in-app work only.
- Source: Background tasks overview - https://developer.android.com/develop/background-work/background-tasks

### KT-02 Foreground services need types and have time limits
- Trap: A generic foreground service can run sync, BLE or GPS indefinitely and can start from the background or on boot.
- Reality: Targeting Android 14+, each FGS must declare `foregroundServiceType` and its `FOREGROUND_SERVICE_*` permission, or it throws `MissingForegroundServiceTypeException`/`SecurityException`. Targeting Android 15+, `dataSync` and `mediaProcessing` get 6 hours per 24 hours, and `BOOT_COMPLETED` cannot start `dataSync`, `camera`, `mediaPlayback`, `phoneCall`, `mediaProjection` or `microphone` services. Apps in the background mostly cannot start an FGS (Android 12+).
- Detect: "foreground service keeps syncing", services started from boot receivers, no type in the manifest.
- Fix: Declare the correct type. Move `dataSync` to WorkManager or user-initiated data transfer jobs, and handle `Service.onTimeout`.
- Source: Foreground service types are required - https://developer.android.com/about/versions/14/changes/fgs-types-required ; Behavior changes: Android 15 - https://developer.android.com/about/versions/15/behavior-changes-15

### KT-03 Periodic work is inexact, minimum 15 minutes
- Trap: WorkManager can poll every minute or fire reminders at an exact time.
- Reality: The minimum `PeriodicWorkRequest` interval is 15 minutes. Constraints, Doze and quotas defer execution, and expedited work is quota-limited.
- Detect: "WorkManager every 5 minutes", medication, dose or brewing timers built on WorkManager.
- Fix: Use push (FCM) for near-real-time updates and exact alarms (KT-04) only for user-facing alarm times.
- Source: Define work requests - https://developer.android.com/develop/background-work/background-tasks/persistent/getting-started/define-work

### KT-04 Exact alarms are denied by default (Android 14)
- Trap: `setExact`/`setExactAndAllowWhileIdle` works once `SCHEDULE_EXACT_ALARM` is in the manifest.
- Reality: On Android 14, newly installed apps targeting 13+ are not pre-granted `SCHEDULE_EXACT_ALARM`, and the calls throw `SecurityException`. `USE_EXACT_ALARM` is only for alarm-clock and calendar apps under Play policy.
- Detect: Reminders or check-in deadlines "at exactly HH:MM" with no permission flow.
- Fix: Check `canScheduleExactAlarms()`, send the user to `ACTION_REQUEST_SCHEDULE_EXACT_ALARM`, and fall back to `setWindow`.
- Source: Schedule exact alarms are denied by default - https://developer.android.com/about/versions/14/changes/schedule-exact-alarms

## Android platform and Play

### KT-05 Play target API and Android 16 behavior changes
- Trap: The app can target an older API level, and phone-only layout assumptions (portrait lock, opt out of edge-to-edge) still hold.
- Reality: From 2026-08-31, new apps and updates must target API 36 (Android 16). Existing apps below API 35 are hidden from new users on newer devices. Targeting API 36 removes the edge-to-edge opt-out, ignores orientation, resizability and aspect-ratio locks on displays ≥600dp, and stops calling `onBackPressed` (predictive back).
- Detect: "portrait-only tablet app", `screenOrientation` locks on rugged tablets, `onBackPressed` overrides, targetSdk below 36.
- Fix: Target API 36, handle insets, support resizable layouts, and migrate to `OnBackInvokedCallback`/`BackHandler`.
- Source: Target API level requirements - https://developer.android.com/google/play/requirements/target-sdk ; Behavior changes: Android 16 - https://developer.android.com/about/versions/16/behavior-changes-16

### KT-06 Notifications and background location need runtime opt-in
- Trap: FCM alerts appear once the app is installed, and granting location covers background tracking.
- Reality: Android 13+: `POST_NOTIFICATIONS` is a runtime permission, and notifications are off until granted. Android 10+: background location needs `ACCESS_BACKGROUND_LOCATION`. On Android 11+ the user must grant it in Settings, and Play restricts it to core features.
- Detect: Alert-driven features (waitlist, pickup, missed check-in) with no permission UX, geofences or tracking while backgrounded.
- Fix: Request notification permission in context and design a degraded path. Justify background location or use foreground-only location.
- Source: Notification runtime permission - https://developer.android.com/develop/ui/views/notifications/notification-permission ; Access location in the background - https://developer.android.com/develop/sensors-and-location/location/background

### KT-07 Scoped storage
- Trap: The app writes exports or photos to arbitrary external paths, or keeps its data after uninstall.
- Reality: Apps targeting API 29+ get scoped access. `WRITE_EXTERNAL_STORAGE` has no effect on API 30+. Shared files go through MediaStore or the Storage Access Framework, and media reads use `READ_MEDIA_*`. App-specific storage and Room databases are deleted on uninstall. `MANAGE_EXTERNAL_STORAGE` is restricted.
- Detect: "save PDF to /sdcard/...", broad storage permissions, offline data described as surviving reinstall.
- Fix: Use app-specific directories, MediaStore or SAF, and back important data up to the server.
- Source: Data and file storage overview - https://developer.android.com/training/data-storage

## Local data (Room)

### KT-08 Room needs migrations; destructive fallback wipes data
- Trap: Room upgrades the schema automatically, or `fallbackToDestructiveMigration()` is a safe default.
- Reality: A missing migration path throws `IllegalStateException`. Destructive fallback deletes all tables and user data, including unsynced offline queues. Auto-migrations need exported schemas and an `AutoMigrationSpec` for renames and deletes. Room also refuses main-thread queries.
- Detect: Offline stores or queues with no migration plan, `fallbackToDestructiveMigration` in production.
- Fix: Export schemas, write or auto-generate migrations, test with `MigrationTestHelper`, and use suspend/Flow DAOs.
- Source: Migrate your Room database - https://developer.android.com/training/data-storage/room/migrating-db-versions ; Write asynchronous DAO queries - https://developer.android.com/training/data-storage/room/async-queries

## Compose UI

### KT-09 Compose state and recomposition rules
- Trap: `remember` keeps form state across rotation, mutating a `mutableListOf` updates the UI, and composables are a safe place for side effects.
- Reality: `remember` does not survive configuration changes; `rememberSaveable` or a ViewModel does. Non-observable mutable collections do not trigger recomposition. Composables may run in any order, in parallel, as often as every frame, and recomposition can be cancelled. Side effects belong in effect APIs or the ViewModel.
- Detect: Multi-step forms held in `remember`, list state as `ArrayList`, network or DB calls inside composable bodies.
- Fix: Hoist state to a ViewModel exposing immutable `StateFlow`, use `rememberSaveable` for UI-only state, and keep composables side-effect free.
- Source: State and Jetpack Compose - https://developer.android.com/develop/ui/compose/state ; Thinking in Compose - https://developer.android.com/develop/ui/compose/mental-model

## Coroutines

### KT-10 Cancellation is cooperative and easy to swallow
- Trap: Cancelling a scope stops all work inside it, and `catch (e: Exception)` is harmless.
- Reality: CPU loops that never suspend or check `isActive`/`ensureActive()` keep running. Catching `Exception` (or using `runCatching`) also catches `CancellationException` and breaks cancellation.
- Detect: Long parsing or processing loops, generic catch blocks around suspend calls.
- Fix: Call `ensureActive()`/`yield()` in loops, rethrow `CancellationException`, and do cleanup in `withContext(NonCancellable)`.
- Source: Cancellation and timeouts - https://kotlinlang.org/docs/cancellation-and-timeouts.html ; Coroutines best practices - https://developer.android.com/kotlin/coroutines/coroutines-best-practices

### KT-11 runBlocking is only a bridge
- Trap: `runBlocking` is a convenient way to call suspend code from handlers, repositories or other suspend functions.
- Reality: It blocks the current thread. Calling it from suspend code is redundant and risks thread starvation. It is meant for `main`, tests and non-suspend callbacks.
- Detect: `runBlocking` in Ktor or Spring handlers, Android UI code, Kafka processors or repository layers.
- Fix: Make the call chain `suspend`, or launch in a proper scope.
- Source: runBlocking - https://kotlinlang.org/api/kotlinx.coroutines/kotlinx-coroutines-core/kotlinx.coroutines/run-blocking.html

## Kotlin with Spring

### KT-12 Final classes and JPA constructors need compiler plugins
- Trap: Kotlin Spring beans proxy like Java beans, and JPA entities can be plain `val` data classes.
- Reality: Kotlin classes are final. Without `kotlin-spring` (all-open for `@Component`, `@Transactional`, `@Async`, `@Cacheable`, ...), proxies and AOP fail. `kotlin-spring` does not cover `@Entity`: JPA needs `kotlin-jpa` for no-arg constructors, and the generated constructor is synthetic (reflection-only).
- Detect: Kotlin + JPA blueprints with no mention of the compiler plugins, entities as data classes.
- Fix: Apply `plugin.spring` and `plugin.jpa`, and model entities as regular classes.
- Source: All-open compiler plugin - https://kotlinlang.org/docs/all-open-plugin.html ; No-arg compiler plugin - https://kotlinlang.org/docs/no-arg-plugin.html

### KT-13 WebFlux does not fix blocking JPA/JDBC
- Trap: Kotlin coroutines plus WebFlux make JPA/JDBC access non-blocking.
- Reality: Spring recommends MVC when the app uses blocking persistence (JPA, JDBC). Blocking calls on the event loop stall it.
- Detect: "WebFlux + JPA", blocking vendor SDKs inside `suspend` handlers.
- Fix: Use R2DBC and reactive or suspending clients end to end, or use Spring MVC.
- Source: Spring WebFlux Overview - https://docs.spring.io/spring-framework/reference/web/webflux/new-framework.html

## Ktor server

### KT-14 Ktor auth and sessions are opt-in per route and payload
- Trap: Installing `Authentication` protects the API, and cookie sessions are tamper-proof by default.
- Reality: Only routes wrapped in `authenticate { }` are protected. Cookie and header sessions carry the whole payload to the client, unsigned and unencrypted, unless a transformer is added. `SessionStorageMemory` is for development only.
- Detect: Route lists with no `authenticate` blocks, session data holding roles or IDs, in-memory sessions on multi-replica deployments.
- Fix: Wrap protected routes in `authenticate`, use `SessionTransportTransformerEncrypt` (or the MAC transformer), and use shared server-side storage.
- Source: Authentication and authorization in Ktor Server - https://ktor.io/docs/server-auth.html ; Sessions - https://ktor.io/docs/server-sessions.html
