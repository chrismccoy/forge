# DART facts
Covers: Flutter (iOS, Android, web, Windows/macOS/Linux desktop), Riverpod, Bloc, platform channels, FFI, isolates, plugins (workmanager, flutter_local_notifications, geolocator), App Store and Play Store releases
Verified: 2026-09-29 against official documentation. Re-verify facts older than 12 months.

## Background work and isolates

### DT-01 Background execution is per platform
- Trap: Dart code (a Timer, a Stream or an isolate) keeps running in the background after the app is closed.
- Reality: Background Dart runs only through platform mechanisms such as callback dispatchers and plugins like WorkManager (tasks persist across restarts and reboots). The OS still decides timing: on iOS, background tasks are opportunistic (see SW-11).
- Detect: "background sync every N min", "keeps tracking when closed", `Timer.periodic` for background jobs.
- Fix: Use a background plugin per platform, treat timing as best-effort, and use notifications or push for time-critical events.
- Source: Background processes - https://docs.flutter.dev/packages-and-plugins/background-processes

### DT-02 Isolates share no memory
- Trap: A background isolate reads the app's providers, singletons or DB connection, or calls any plugin.
- Reality: Isolates cannot see each other's memory and communicate only by messages. Plugins and channels work only in the root isolate or in one registered with `BackgroundIsolateBinaryMessenger.ensureInitialized(RootIsolateToken)`. Flutter web does not support multiple isolates.
- Detect: An isolate touching global state, Riverpod/Bloc objects or plugin calls. Isolates for web parallelism.
- Fix: Pass plain data in and results out, open a separate DB connection per isolate, and register the token before using plugins.
- Source: Isolates - https://dart.dev/language/isolates ; Platform channels - https://docs.flutter.dev/platform-integration/platform-channels

## Platform integration

### DT-03 Platform channels are async and main-thread
- Trap: Channel calls are synchronous, or native code calls into Dart from any thread, with string-keyed maps for the whole API.
- Reality: Messages are asynchronous. Channel methods must be invoked on the platform's main (UI) thread. Pigeon generates type-safe messaging and avoids matching strings by hand.
- Detect: Custom native bridge with "MethodChannel" and no threading or codegen plan. Real-time audio or sensor data streamed per sample over channels.
- Fix: Use Pigeon, dispatch to the main thread, and keep hot loops native (or use FFI) while sending batched results.
- Source: Platform channels - https://docs.flutter.dev/platform-integration/platform-channels

## Store releases

### DT-04 Play target API deadlines
- Trap: The default or older `targetSdkVersion` is fine for launch and updates.
- Reality: From Aug 31, 2026, new apps and updates must target Android 16 (API 36), and Wear OS apps API 35. An extension to Nov 1, 2026 can be requested. Existing apps below API 35 stop being offered to new users on newer Android versions.
- Detect: No targetSdk plan. Pinned old Flutter or AGP versions.
- Fix: Target API 36 and test the behavior changes for that level.
- Source: Meet Google Play's target API level requirement - https://developer.android.com/google/play/requirements/target-sdk

### DT-05 16 KB page sizes for native code
- Trap: FFI or native `.so` libraries built with the default toolchain ship as-is.
- Reality: Apps targeting Android 15+ must support 16 KB pages on 64-bit devices. From Feb 1, 2027, updates without support cannot be released. Misaligned libraries (NDK r27 and lower without flags) crash. AGP 8.5.1+ handles packaging.
- Detect: FFI or prebuilt native libraries (libvips, FFmpeg, TFLite, OCR) on Android.
- Fix: Rebuild native libraries with 16 KB alignment, update AGP/NDK and plugins, and test on a 16 KB emulator.
- Source: Support 16 KB page sizes - https://developer.android.com/guide/practices/page-sizes

### DT-06 iOS privacy manifest covers plugins
- Trap: A Flutter app needs no privacy manifest, or the app's manifest covers every plugin.
- Reality: Apple requires `PrivacyInfo.xcprivacy` for required-reason APIs (see SW-14), and each SDK needs its own. Flutter plugins that use such APIs must bundle a manifest (a podspec resource bundle, or SwiftPM resources).
- Detect: iOS release with no manifest review of the app and plugins (e.g. shared_preferences, which uses UserDefaults).
- Fix: Add an app manifest and upgrade or replace plugins that lack one.
- Source: Developing packages & plugins - https://docs.flutter.dev/packages-and-plugins/developing-packages

### DT-07 Apple review rules apply to Flutter iOS builds
- Trap: A cross-platform app can use Stripe for premium features, Google-only login, or no in-app account deletion.
- Reality: App Review 3.1.1 (IAP for digital goods), 4.8 (equivalent login option) and 5.1.1(v) (in-app account deletion) apply regardless of framework. See SW-06 to SW-08.
- Detect: Stripe SDK for subscriptions or unlocks. Firebase Google-only sign-in.
- Fix: Use StoreKit/Play Billing (e.g. in_app_purchase) for digital goods, add a compliant login, and add in-app deletion.
- Source: App Review Guidelines - https://developer.apple.com/app-store/review/guidelines/

## Android permissions and services

### DT-08 Notifications and exact alarms
- Trap: Scheduled local notifications (reminders, timers) fire on time without asking.
- Reality: Android 13+: `POST_NOTIFICATIONS` is a runtime permission, and notifications are off by default for new installs. Android 14+: `SCHEDULE_EXACT_ALARM` is denied by default for new apps targeting 13+. Only calendar and alarm-clock apps may use `USE_EXACT_ALARM`. Exact scheduling without the permission throws a SecurityException.
- Detect: flutter_local_notifications "exact time" reminders with no permission flow.
- Fix: Request the notification permission in context, use inexact scheduling or ask for the exact-alarm permission, and degrade gracefully.
- Source: Notification runtime permission - https://developer.android.com/develop/ui/views/notifications/notification-permission ; Exact alarms denied by default - https://developer.android.com/about/versions/14/changes/schedule-exact-alarms

### DT-09 Background location and foreground services
- Trap: geolocator trip or geofence tracking gets background access from the first permission prompt.
- Reality: On Android 11+, "Allow all the time" is not in the dialog, so users must enable background location in Settings. Android 14+: every foreground service needs a declared type and permission, and the types must be declared in Play Console. Android 15: dataSync and mediaProcessing services are limited to 6 h per 24 h.
- Detect: Background tracking, long uploads or a sync service with no FGS type or settings-page flow.
- Fix: Request foreground location first, then explain and send users to Settings. Declare FGS types in the manifest and in Play Console.
- Source: Request background location - https://developer.android.com/develop/sensors-and-location/location/permissions/background ; Foreground service types - https://developer.android.com/develop/background-work/services/fgs/service-types

## Desktop

### DT-10 macOS sandbox and notarization
- Trap: A macOS release build can reach the network and files like the debug build, and a .dmg can be shipped unsigned.
- Reality: macOS builds are sandboxed by default. Outgoing requests need `com.apple.security.network.client`, or they fail with "Operation not permitted". `network.server` is enabled only in Debug/Profile entitlements. File access needs user-selected entitlements. Distribution outside the Mac App Store needs a Hardened Runtime build that is signed and notarized. A Windows MSIX distributed outside the Microsoft Store needs a .pfx signing certificate.
- Detect: Desktop app with network, file import or a local server, and no entitlements or signing step.
- Fix: Edit both `Runner-*.entitlements` files, and add signing and notarization to the release pipeline.
- Source: Building macOS apps with Flutter - https://docs.flutter.dev/platform-integration/macos/building ; Building Windows apps - https://docs.flutter.dev/platform-integration/windows/building

## Web

### DT-11 Flutter web is not for SEO content
- Trap: Public, search-indexed pages (landing, listings, shareable views) are built in Flutter web.
- Reality: Flutter web output "doesn't align with what search engines need to properly index". It is "not suitable for static websites with text-rich flow-based content". `dart:io` file system and `Platform.isX` do not work on web.
- Detect: SEO, public share links or a marketing site in Flutter web.
- Fix: Serve indexable pages as HTML (or Jaspr), and keep Flutter web for the app itself.
- Source: Web FAQ - https://docs.flutter.dev/platform-integration/web/faq

### DT-12 Wasm build requirements
- Trap: `--wasm` builds run multithreaded everywhere, and existing web code compiles.
- Reality: Wasm needs WasmGC (Chromium 119+). Otherwise the build falls back to JS. Firefox and Safari are currently blocked by bugs, and iOS browsers cannot run it. Multithreaded rendering needs COOP `same-origin` and COEP `require-corp` or `credentialless` headers. Code using `dart:html` or `package:js` does not compile to Wasm; migrate to `package:web` and `dart:js_interop`.
- Detect: "Wasm for performance" on a static host with no header config. dart:html dependencies.
- Fix: Configure the headers, migrate interop, and test the JS fallback.
- Source: Support for WebAssembly - https://docs.flutter.dev/platform-integration/web/wasm

## State and language

### DT-13 State management is not persistence
- Trap: Riverpod or Bloc state survives app restarts, or acts as the offline store.
- Reality: Provider and Bloc state lives in memory. Riverpod's offline persistence is experimental, applies to Notifiers only, and is not a database replacement. autoDispose providers drop their state when unused. Bloc needs `hydrated_bloc` to persist.
- Detect: "state is saved in the provider/bloc" with no storage layer. Offline-first with no DB.
- Fix: Persist to drift, Isar or Hive (or the backend) and hydrate providers or blocs from it.
- Source: Offline persistence (experimental) - https://riverpod.dev/docs/concepts2/offline ; hydrated_bloc - https://pub.dev/packages/hydrated_bloc

### DT-14 Sound null safety is mandatory
- Trap: Packages without null safety can be used, or null safety is an optional migration.
- Reality: Since Dart 3 (May 2023), null safety is built in and cannot be turned off. Packages without null safety fail `dart pub get` version solving.
- Detect: Old unmaintained packages, or "migrate to null safety later".
- Fix: Choose null-safe packages, and validate JSON at the boundary into non-nullable models.
- Source: Dart 3 migration guide - https://dart.dev/resources/dart-3-migration
