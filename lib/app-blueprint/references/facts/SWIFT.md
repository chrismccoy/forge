# SWIFT facts
Covers: Swift (SwiftUI, AppKit), Core Data, SwiftData, CloudKit, StoreKit 2, WeatherKit, Core Location, HealthKit, App Review
Verified: 2026-09-29 against official documentation. Re-verify facts older than 12 months.

## CloudKit sync

### SW-01 CloudKit-compatible model
- Trap: The Core Data or SwiftData model syncs as designed, with unique constraints and required relationships.
- Reality: CloudKit mirroring does not support unique constraints (`@Attribute(.unique)`), non-optional relationships, the Deny delete rule, or relationships across configurations. Relationships need inverses.
- Detect: "unique", "no duplicates", required relationships, or Deny, with CloudKit.
- Fix: Make relationships optional with inverses, and dedupe in app code by a stable ID after sync.
- Source: Creating a Core Data model for CloudKit - https://developer.apple.com/documentation/coredata/creating-a-core-data-model-for-cloudkit

### SW-02 Production schema is additive only
- Trap: The CloudKit schema follows model changes automatically, and fields can be renamed or dropped later.
- Reality: Production never creates record types. The schema must be initialized in development and promoted before App Store or TestFlight builds can sync. After promotion, types and fields cannot be deleted or modified, only added.
- Detect: No schema-promotion step in the release plan. "rename/drop field" or "v2 model" with CloudKit.
- Fix: Add schema promotion to the release checklist. Version by adding fields or a new container.
- Source: Sharing Core Data objects between iCloud users - https://developer.apple.com/documentation/coredata/sharing-core-data-objects-between-icloud-users

### SW-03 CloudKit sync is not real time
- Trap: Edits appear instantly on other devices, which supports live collaboration or "sync now".
- Reality: "CloudKit isn't for real-time synchronization." The system decides when to sync, and there is no API to set the timing.
- Detect: "real-time", "instantly", "live", "sync every N seconds" over CloudKit.
- Fix: Design for eventual consistency with visible sync state.
- Source: Sharing Core Data objects between iCloud users - https://developer.apple.com/documentation/coredata/sharing-core-data-objects-between-icloud-users

### SW-04 Database scopes and quotas
- Trap: CloudKit storage is free and unlimited, works without iCloud, and SwiftData can share data between users.
- Reality: The private DB counts against the user's iCloud quota and errors when no iCloud account is signed in. The public DB uses the app's quota and is world-readable. SwiftData offers only `.automatic`, `.private` or `.none`. Sharing with other users (CKShare) requires Core Data's `NSPersistentCloudKitContainer`.
- Detect: "shared household/partner" on SwiftData. Personal data in the public DB. No signed-out path.
- Fix: Use Core Data with a shared store for sharing. Check `accountStatus` and design a signed-out mode.
- Source: privateCloudDatabase - https://developer.apple.com/documentation/cloudkit/ckcontainer/privateclouddatabase ; ModelConfiguration.CloudKitDatabase - https://developer.apple.com/documentation/swiftdata/modelconfiguration/cloudkitdatabase-swift.struct

### SW-05 No personal health data in iCloud
- Trap: HealthKit values are copied into Core Data and synced or backed up with CloudKit.
- Reality: Guideline 5.1.3(ii): apps "may not store personal health information in iCloud".
- Detect: HealthKit plus CloudKit sync or "encrypted CloudKit backup" of health values.
- Fix: Keep health data on the device (re-query HealthKit), or use a compliant non-iCloud backend with consent.
- Source: App Review Guidelines 5.1.3 - https://developer.apple.com/app-store/review/guidelines/

## App Review and purchases

### SW-06 In-app purchase rules
- Trap: Premium features are unlocked with Stripe, web checkout or license keys, or physical goods are sold through IAP.
- Reality: 3.1.1: unlocking features or digital content requires IAP, not license keys or QR codes. 3.1.3(e): goods or services used outside the app must *not* use IAP. The US storefront may link to external purchases. Provide a restore mechanism. Subscriptions last at least 7 days.
- Detect: Stripe for digital content or subscriptions. IAP for deposits, tickets or physical items.
- Fix: StoreKit for digital goods, other payment methods for physical goods.
- Source: App Review Guidelines 3.1 - https://developer.apple.com/app-store/review/guidelines/

### SW-07 Account deletion in the app
- Trap: "Email support to delete your account", or deletion only on the website.
- Reality: 5.1.1(v): "If your app supports account creation, you must also offer account deletion within the app."
- Detect: A sign-up flow with no in-app delete-account step.
- Fix: Add in-app deletion that also removes the server-side data.
- Source: App Review Guidelines 5.1.1(v) - https://developer.apple.com/app-store/review/guidelines/

### SW-08 Social login needs an equivalent option
- Trap: A Google-only login is fine, or Sign in with Apple is always mandatory.
- Reality: 4.8: a third-party or social login for the primary account requires also offering a login that limits data to name and email, allows a private email, and does no ad tracking without consent. Exempt: own accounts only, enterprise/education, eID, and clients of one third-party service.
- Detect: "Sign in with Google/Facebook" as the only option.
- Fix: Add Sign in with Apple (it qualifies), or use only your own accounts.
- Source: App Review Guidelines 4.8 - https://developer.apple.com/app-store/review/guidelines/

### SW-09 StoreKit 2 transaction handling
- Trap: Access is granted only from the `purchase()` result, and Restore calls `AppStore.sync()` at launch.
- Reality: Iterate `Transaction.updates` in a Task from launch (iOS 15+), or Ask to Buy, other-device and unfinished transactions are missed. Check `VerificationResult`. Call `finish()` after delivering the content. Derive entitlements from `Transaction.currentEntitlements` (it excludes consumables and refunds). `sync()` prompts for sign-in, so call it only on user action.
- Detect: No launch listener. Unverified payloads used. A UserDefaults flag as the entitlement source.
- Fix: Launch listener, then verify, grant, finish. A Restore button calls sync().
- Source: Transaction.updates - https://developer.apple.com/documentation/storekit/transaction/updates ; AppStore.sync() - https://developer.apple.com/documentation/storekit/appstore/sync()

### SW-10 App Store Server Notifications V2
- Trap: The webhook trusts the JSON, always returns 200, and treats price as whole currency units.
- Reality: Payloads are signed JWS, so verify them (App Store Server Library `verifyAndDecode...`). Needs HTTPS with TLS 1.2+. A 200-206 status acknowledges the post; a 40x or 50x makes the App Store retry. JWS prices are in milliunits, while StoreKit prices are in units.
- Detect: No JWS verification or idempotency.
- Fix: Verify, persist idempotently, then return 200. Convert milliunits.
- Source: App Store Server Notifications V2 - https://developer.apple.com/documentation/appstoreservernotifications/app-store-server-notifications-v2

## Background execution and location

### SW-11 Background tasks are opportunistic
- Trap: A BGAppRefreshTask or BGProcessingTask runs every N minutes or at a set time.
- Reality: `earliestBeginDate` is only a lower bound, and the system decides when or whether to run. Register tasks before launch finishes. iOS 26+: `BGContinuedProcessingTask` continues *user-started* work with a progress UI.
- Detect: "every 15 minutes", "at 6am", guaranteed background sync, background-timer alerts.
- Fix: Use local or remote notifications for time-critical alerts. Treat refresh as best-effort.
- Source: earliestBeginDate - https://developer.apple.com/documentation/backgroundtasks/bgtaskrequest/earliestbegindate ; Choosing background strategies - https://developer.apple.com/documentation/backgroundtasks/choosing-background-strategies-for-your-app

### SW-12 Background location setup
- Trap: Always permission alone gives continuous background tracking.
- Reality: Needs `UIBackgroundModes`=`location` plus `allowsBackgroundLocationUpdates = true` (without the mode it crashes). `NSLocationWhenInUseUsageDescription` is always required, and Always also needs `NSLocationAlwaysAndWhenInUseUsageDescription`. The upgrade to Always can be requested only once. A terminated app with When in Use is never relaunched for updates.
- Detect: Track recording or geofences with no background-mode plan.
- Fix: Declare the mode and keys, start updates in the foreground, and restart services on relaunch.
- Source: allowsBackgroundLocationUpdates - https://developer.apple.com/documentation/corelocation/cllocationmanager/allowsbackgroundlocationupdates ; Requesting authorization - https://developer.apple.com/documentation/corelocation/requesting-authorization-to-use-location-services

## Privacy and security

### SW-13 HealthKit authorization is opaque
- Trap: The app detects a denied read permission, or reads HealthKit in the background while the phone is locked.
- Reality: A denied read looks like no data. The store is encrypted while locked, so background reads can fail. A missing `NSHealthShareUsageDescription` or `NSHealthUpdateUsageDescription` crashes the app.
- Detect: "if denied, show...", overnight background HealthKit analysis.
- Fix: Treat empty results as possibly denied, and read while the device is unlocked.
- Source: Protecting user privacy - https://developer.apple.com/documentation/healthkit/protecting-user-privacy

### SW-14 Privacy manifest and required-reason APIs
- Trap: A privacy manifest is needed only for tracking SDKs.
- Reality: Since May 1, 2024, App Store Connect rejects uploads that use required-reason APIs (UserDefaults, file timestamps, system boot time, disk space, active keyboards) without reasons in `PrivacyInfo.xcprivacy`. Each SDK needs its own manifest, and listed SDKs also need a signature.
- Detect: No PrivacyInfo.xcprivacy in the plan.
- Fix: Add an app manifest (data types and API reasons), and verify that each SDK ships one.
- Source: Describing use of required reason API - https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api

### SW-15 Secrets belong in the Keychain
- Trap: Tokens, API keys or PINs are stored in UserDefaults or @AppStorage.
- Reality: UserDefaults is stored on disk unencrypted and included in backups. Apple says to store sensitive data in the Keychain.
- Detect: "token/password/PIN in UserDefaults/AppStorage".
- Fix: Keychain for secrets, with UserDefaults for non-sensitive settings only.
- Source: UserDefaults - https://developer.apple.com/documentation/foundation/userdefaults

## WeatherKit

### SW-16 Attribution and quota
- Trap: WeatherKit data is shown unbranded and fetched without limit.
- Reality: Attribution is required: the Apple Weather mark and a legal link (`WeatherService.attribution`). Membership includes 500,000 calls per month; paid tiers cover more, and unused calls do not roll over.
- Detect: Weather UI or widget with no attribution. Fetches on every view or widget refresh.
- Fix: Show attribution wherever weather appears, and cache responses.
- Source: WeatherKit - Get started - https://developer.apple.com/weatherkit/get-started/

## Concurrency

### SW-17 Swift 6 data-race checking
- Trap: Swift 5 patterns (shared mutable singletons, non-Sendable models crossing tasks) compile unchanged in Swift 6.
- Reality: The Swift 6 language mode is opt-in per module and reports data races as compile errors. Swift 6.2 adds opt-in default MainActor isolation and `@concurrent`.
- Detect: "Swift 6" with global mutable caches, or managed objects passed across tasks.
- Fix: Choose the language mode per target, keep UI state @MainActor, and pass Sendable values or IDs between actors.
- Source: Announcing Swift 6 - https://www.swift.org/blog/announcing-swift-6/
