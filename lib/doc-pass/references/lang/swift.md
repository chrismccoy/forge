## Swift rules

### Files and tools

- In scope: `.swift`, including `Package.swift` (its `// swift-tools-version:` line stays first; put the header after it).
- Out of scope: `.build/`, `DerivedData/`, `Pods/`, `Carthage/`, generated sources (SwiftGen, Sourcery output, `*.generated.swift`), storyboards and XIBs, asset catalogs, `Info.plist`, `.xcodeproj` / `.pbxproj`, `Package.resolved`.
- Syntax check: the checker parse after each file (agents). Once per wave, the main session runs `swift build` for a package, or `xcodebuild build` with the project's scheme for an app, in its work copy.
- Baselines before and after: SwiftLint (`swiftlint lint`), swift-format (`swift-format lint -r`) or SwiftFormat (`swiftformat --lint`), whichever the project configures. Then the project's test runner (`swift test`, `xcodebuild test`).
- The bundled Swift grammar is older (raw strings `#"…"#` containing `\{` or `\(` are its most common failure): syntax newer than it parses as an error, and the checker locks the broken region byte for byte, comments included (`--list-frozen` prints `LOCKED:`): the enclosing declaration, or the broken statement and its neighbours. Edit comments only outside locked regions.

### Doc comment style

- `///` lines (or `/** … */` when the project uses them). `//` never counts.
- DocC markup: a one-sentence summary ending in a period, a blank `///` line, then discussion paragraphs.
- `- Parameter name: …` for a single parameter, or `- Parameters:` with one nested `- name: …` per parameter; `- Returns: …` unless the result is `Void`; `- Throws: …` naming the errors and when (for typed throws, the cases).
- Callouts only where they carry weight: `- Important:`, `- Warning:`, `- Note:`, `- Precondition:`.
- Symbol links: ` ``TypeName`` `, ` ``TypeName/method(_:)`` `, only to symbols that exist.
- Never repeat types. Say what they cannot: when `nil` is returned, units, ranges, the actor or thread a callback runs on, and for `async` functions whether they suspend across actors and how cancellation ends them.

### Coverage

- Every class, struct, enum, actor and protocol; every function, initializer, type alias and protocol requirement; every property at file level or in a type or protocol body. Local variables need none.
- Exempt: `override` members, an `extension` declaration itself (its members are scanned), and functions named `test…` in files ending `Test.swift` or `Tests.swift`.
- SwiftUI's `var body: some View` is scanned: one line saying what it lays out.
- Swift Testing `@Test` functions are not exempt: one line each.
- Checked by reading: enum cases whose meaning isn't plain, subscripts, `deinit`.
- The doc comment sits directly above the declaration and its attributes (`@MainActor`, `@Published`), with no blank line between.
- No file header is scanned. A header, when wanted, is plain `//` lines separated from the code by a blank line (the Xcode template form).
- `// MARK:` lines drive Xcode's jump bar: keep them as they are (checked by reading).

### Comments that are code

- Whole comment frozen when its first line starts with `swiftlint:disable` / `swiftlint:enable` (including `:next`, `:this`, `:previous`), `swift-format-ignore`, `swift-tools-version`, `sourcery:`, `periphery:ignore`, `swiftformat:disable` / `swiftformat:enable` / `swiftformat:options` / `swiftformat:sort`, `cspell:`, `spell-checker:`, `noinspection`, `NOSONAR` or `language=`; and when any line starts with `@generated`, `@license`, `Copyright`, `(c) 2024`, `©`, `SPDX-License-Identifier`, `Permission is hereby granted` or `Licensed under the`, or names the GNU (Lesser, Affero) General Public License.
- No frozen or kept tag lines.
- Last before their code: `swiftlint:disable:next`, `swift-format-ignore`, `periphery:ignore`, `swiftformat:disable:next`.
- Each `///` and `//` line is its own comment: never start any line with these words.
- Attributes (`@available`, `@objc`, `@discardableResult`), `#if`, `#warning` and macros are code.

### SwiftUI, UIKit and Vapor

- **Views:** what the view shows and which inputs it takes. State ownership in words: `@State` and `@StateObject` are owned by this view; `@Binding`, `@ObservedObject`, `@Bindable` and `@Environment` / `@EnvironmentObject` come from elsewhere (say from where). For `@Observable` models, say which view owns the instance.
- Modifiers with side effects (`.task`, `.onAppear`, `.onChange(of:)`, `.refreshable`) get an inline why comment when ordering or cancellation matters (`.task` cancels when the view disappears).
- **UIKit:** view controllers say what screen they manage, how they are created (storyboard identifier, coordinator) and what they hand back (delegate, closure). Lifecycle overrides are exempt but get inline why comments. `@IBOutlet` and `@IBAction` members get one line naming the control.
- **Concurrency:** say the isolation of each type: `@MainActor`, an `actor`, or `Sendable` and why. `nonisolated` members, `Task { }` (inherits the actor) versus `Task.detached`, and `@unchecked Sendable` get a why comment stating what makes access safe.
- **Vapor:** `routes(_:)` and each `RouteCollection.boot(routes:)` form the route map. Each route: method and full path (group prefixes included), middleware and auth (`grouped(User.guardMiddleware())`), inputs (`req.parameters`, `req.query`, `req.content.decode`) and validation (`Validatable`), responses and `Abort` statuses.
- **Fluent:** models name the schema and each `@Field(key:)` / `@Parent` meaning; migrations say what `prepare` changes and whether `revert` fully reverses it.
- **Environment:** `Environment.get("KEY")` reads form the env map; document each key once.

### Bug report additions

- Force unwraps (`!`), `try!` and `as!` on values that can fail; implicitly unwrapped optionals that can be read before assignment.
- Closures stored by `self` that capture `self` strongly (retain cycles).
- UI work off the main actor; `@unchecked Sendable` or `nonisolated(unsafe)` without a lock.
- `Task` work never cancelled; raw SQL built from request input.
