## Dart rules

### Files and tools

- In scope: `.dart` under `lib/`, `bin/`, `test/`, `tool/`, `integration_test/`, and Flutter's `lib/` in each package of a workspace.
- Out of scope: generated files, which the walker skips by their `// GENERATED CODE - DO NOT MODIFY BY HAND` marker (`*.g.dart`, `*.freezed.dart`, `*.mapper.dart`, `*.gr.dart`, `*.config.dart`, slang / intl `*.g.dart`); `.dart_tool/`, `build/`, platform folders (`android/`, `ios/`, `macos/`, `linux/`, `windows/`, `web/`), whose native code follows its own language file; `pubspec.lock`.
- Syntax check and baseline (the main session, once per wave, in its work copy; agents rely on the checker parse): `dart analyze` (or `flutter analyze`) before and after: no new issues. `dart format --output=none --set-exit-if-changed <files>` in check mode, when the project formats. Tests: `dart test` or `flutter test`.
- The bundled Dart grammar predates Dart 3 patterns: `switch` expressions and object patterns (`case Foo():`) parse as errors, and the checker compares the region around them byte for byte (`--list-frozen` prints `LOCKED:`; **Locked regions** in the universal rules gives its size). Edit comments only outside locked regions.

### Doc comment style

- `///` lines. `/** … */` only where the project already uses it. `//` is not documentation.
- Leave a blank line above each new doc comment that follows another member. `dart format` (3.7+) adds one, and its check fails without it.
- First sentence: a summary ending in a period, on its own paragraph. Effective Dart voice: third-person verbs for functions and methods ("Returns …", "Starts …"), noun phrases for classes and variables, "Whether …" for booleans.
- No `@param` tags: name parameters in prose with square brackets: `[count]`, `[onDone]`. Link other symbols the same way: `[Foo]`, `[Foo.bar]`, only to names in scope (imported).
- Say what the signature cannot: when it throws (`Throws a [StateError] if …`), what `null` means, units, which isolate a callback runs on, whether a `Future` completes on error or never.
- Constructors: document the unnamed constructor only when it does more than store its arguments; named and factory constructors say how they differ.
- No file header is scanned by `dart analyze`, but every file gets one here: plain `//` lines at the top, separated from the first import by a blank line. Never a `///` block at the top of the file: `dangling_library_doc_comments` warns on a `///` that isn't attached to a declaration or a `library;` directive. When the file already has `library;`, a `///` library doc above it is the header.

### Coverage

- Every class (including `abstract`, `sealed`, `base`, `interface`, `final`, `mixin class`), mixin, extension, extension type, enum and `typedef`; every top-level function and variable; every method, getter, setter, operator, field and constructor in a class, mixin, extension or enum body.
- Exempt: members with `@override`; a constructor whose parameters are all `this.x` / `super.x` with no body or initializer list; a setter whose getter is documented; `main` in `*_test.dart`.
- Checked by reading: enum values whose meaning isn't plain, closures passed to `setState`, `addListener`, `stream.listen`, `ref.listen`, and private (`_name`) helpers that are not obvious.
- The doc comment sits above the declaration's annotations (`@immutable`, `@riverpod`, `@JsonSerializable()`), with no blank line between.

### Comments that are code

- Frozen whole comment: `// ignore: …` and `// ignore_for_file: …` (analyzer suppressions), `// coverage:ignore-line` / `ignore-start` / `ignore-end` / `ignore-file`, the language-version override `// @dart = 3.0`, `// dart format off` / `on`, plus the shared license, `@generated`, `cspell:` and `noinspection` forms.
- Last before its code: `// ignore: …` (it suppresses diagnostics on the next line, or on its own line when trailing).
- Kept lines: dartdoc directives `{@template name}`, `{@endtemplate}`, `{@macro name}`, `{@tool …}`, `{@end-tool}`, `{@youtube …}`, `{@animation …}`, `{@inject-html}`, `@nodoc`. Other doc comments include templates by name, so never rename or drop one.
- Annotations (`@Deprecated('…')`, `@visibleForTesting`, `@pragma('vm:entry-point')`) and `part` / `part of` directives are code.

### Flutter, Riverpod and server code

- **Widgets:** what the widget shows and its inputs. `build` is an override (exempt) but gets inline why comments for non-obvious layout or rebuild decisions. For a `StatefulWidget`, the `State` class says what state it owns and what `initState` / `dispose` start and stop.
- **State management:** for Riverpod providers (`@riverpod`, `Provider`, `NotifierProvider`), Bloc / Cubit, Provider or Refena, say what state the provider holds, what it depends on (`ref.watch`), when it rebuilds or is disposed (`autoDispose`, `keepAlive`), and which events change it. One description per provider, at its declaration.
- **Async and isolates:** say which isolate runs the code, what crosses the boundary (`SendPort` messages), and what a `Stream` emits, when it closes and whether it is broadcast. Futures started without `await` (`unawaited`) get a why comment.
- **Platform channels:** `MethodChannel` names and method strings are a contract with native code: name the native file that implements each one.
- **Server (shelf, dart_frog, serverpod):** route handlers follow the route rules: method, path, auth, inputs, statuses.
- **Environment:** `String.fromEnvironment`, `bool.fromEnvironment` (`--dart-define`) and `Platform.environment` reads form the env map.

### Bug report additions

- `BuildContext` used after an `await` without a `mounted` check; controllers, subscriptions and timers never disposed.
- `!` on values that can be null; `late` fields read before assignment.
- Futures neither awaited nor marked `unawaited`; errors swallowed by `catchError` returning the wrong type.
- Work on the UI isolate that blocks frames (large JSON parsing, file hashing).
