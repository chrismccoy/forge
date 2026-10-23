## Java and Kotlin rules

### Files and tools

- In scope: `.java`, `.kt`, `.kts` (Gradle scripts only when the plan lists them).
- Out of scope: `build/`, `target/`, `.gradle/`, generated sources, `src/main/resources/`, Android `res/` and layout XML, JSP and Thymeleaf views.
- Syntax check: the checker parse after each file (agents). Once per wave, the main session runs the project's compile tasks in its work copy (`./gradlew compileJava compileTestJava compileKotlin`, `mvn -q test-compile`, or `javac`), never in the project.
- Baselines before and after: Checkstyle, PMD, SpotBugs, Error Prone, ktlint, detekt, and `javadoc` when the build runs it (doclint fails on malformed HTML and unknown `@param` names). Then the project's test runner.
- The bundled Kotlin grammar is older: newer syntax parses as an error, and the checker locks the broken region byte for byte, comments included (`--list-frozen` prints `LOCKED:`): the enclosing declaration, or the broken statement and its neighbours. Edit comments only outside locked regions.

### Doc comment style

- `/** … */` only. `//` and `/* */` never count as docs. Java Markdown comments (`///`) are not recognized: write `/** … */`.
- The first sentence is the summary: third person, ending in a period. Further paragraphs start with `<p>` in Javadoc, a blank line in KDoc.
- Javadoc: `@param` per parameter, `@param <T>` per type parameter, `@return` unless `void`, `@throws X if …` for each exception thrown on purpose, checked or not. A record documents each component with `@param` in the record's comment.
- Escape for doclint: `{@code a < b}`, `&lt;`, `&amp;`. Link only to targets that exist: `{@link Type#method(Arg)}`.
- KDoc: `@param`, `@return`, `@throws`, `@property` for primary-constructor properties, `@receiver` for an extension's receiver, `[Name]` links. The `@Throws(…)` annotation is code.
- Never repeat types. Say what they cannot: when `null` is returned, units, ranges, thread confinement, and a `suspend` function's dispatcher and cancellation.
- With spring-javaformat (its Maven or Gradle plugin, or `.springjavaformatconfig`), the validate step reflows Javadoc: fill each line to the limit (90 columns by default) before breaking, or the check fails. If the check still fails, leave the comment as it is and say so in your report: the main session repairs it in final verification (SKILL.md step 4, item 7).

### Coverage

- Java: every class, interface, enum, record and annotation type; every method, constructor and field. Exempt: members annotated `@Override`, `@Test`, `@ParameterizedTest`, `@RepeatedTest`, `@TestFactory`, `@BeforeEach`, `@AfterEach`, `@BeforeAll`, `@AfterAll`, `@Before` or `@After`, and a constructor whose body only stores its parameters (`this.repo = repo;`), as injected-dependency constructors do.
- Kotlin: every class (`interface`, `enum class`, `data class` included), `object`, and property at top level or in a class body, and every function at any depth, local functions included. Exempt: `override` members and `@Test` functions.
- Checked by reading: enum constants whose meaning isn't plain, `companion object`s, secondary constructors.
- The doc comment sits directly above the declaration and its annotations, with no blank line between.
- No file header is scanned. Never put `/** … */` above `package` outside `package-info.java`: javadoc ignores it. The main type's doc comment carries the file's role; a Kotlin file of only top-level functions gets a plain `/* … */` header. Package docs go in an existing `package-info.java`; never create one.

### Comments that are code

- Both languages, whole comment frozen when its first line starts with `cspell:`, `spell-checker:`, `noinspection`, `NOSONAR`, `language=` or `@formatter:off` / `@formatter:on`, and when any line starts with `@generated`, `@license`, `Copyright`, `(c) 2024`, `©`, `SPDX-License-Identifier`, `Permission is hereby granted` or `Licensed under the`, or names the GNU (Lesser, Affero) General Public License.
- Java also freezes `CHECKSTYLE:OFF` / `CHECKSTYLE:ON`, `SUPPRESS CHECKSTYLE`, `NOPMD`, `$NON-NLS`, `spotless:off` / `spotless:on` comments, and a comment that is only a fall-through marker (`fall through`, `fallthrough`, `falls through`). Frozen tag lines: `@deprecated`, `@hide`. Kept lines (keep each exactly; new ones allowed): `@since`, `@see`, `@author`, `@serial`, `@serialData`, `@serialField`. Last before their code: `noinspection`, `CHECKSTYLE`, `NOPMD`.
- Kotlin also freezes `ktlint-disable` / `ktlint-enable`, `detekt:` and `spotless:off` / `spotless:on`. Frozen tag lines: `@deprecated`, `@suppress`. Kept: `@since`, `@see`, `@author`, `@sample`. Last before their code: `noinspection`, `ktlint-disable`.
- Never start a new comment, or a line of one, with these words. Annotations (`@SuppressWarnings`, `@Suppress`) are code.

### Spring Boot

- **Controllers:** the class comment names the base `@RequestMapping` path and shared security. Each handler: method and full path (route map), authorization (`SecurityFilterChain`, `@PreAuthorize`), inputs (`@PathVariable`, `@RequestParam` defaults, `@RequestBody` and whether `@Valid` sends 400), statuses (`@ResponseStatus`, `ResponseEntity`), and exceptions mapped by `@ControllerAdvice`.
- **Beans:** `@Bean` methods say what they build, any non-singleton scope, and why a condition applies (`@Profile`, `@ConditionalOnProperty`).
- **Environment:** `@Value("${key:default}")` sites and `@ConfigurationProperties` classes form the env map: key, meaning, unit, default, required. Environment variables bind by relaxed binding (`APP_MAIL_HOST` to `app.mail.host`). `application*.yml` and `.properties` files are out of scope.
- **Comments a tool reads:** with `spring-boot-configuration-processor`, field Javadoc on `@ConfigurationProperties` classes becomes the metadata `description` shown in IDEs; with springdoc and `therapi-runtime-javadoc`, controller Javadoc becomes OpenAPI text.
- **JPA entities:** the table, each field's meaning, relations in words (owning side, fetch type, cascade), `@Version` locking, lifecycle callbacks. Repository methods say what they match and return when nothing matches. `@Query` text is code.
- **Transactions:** what `@Transactional` spans, propagation, `readOnly`, rollback (default: unchecked exceptions and errors only; note `rollbackFor`).

### Android

- Activities and fragments: the screen, its launch inputs (intent extras, navigation arguments), its ViewModel, the result it returns.
- Lifecycle overrides are exempt from the scan but get inline why comments (work in `onStart` rather than `onResume`, binding cleared in `onDestroyView`).
- ViewModels: the state exposed (`StateFlow`, `LiveData`), what survives process death (`SavedStateHandle` keys), the coroutine scope.
- `@Composable` functions: what renders, which state is hoisted or remembered, effect keys and cleanup (`LaunchedEffect`, `DisposableEffect`).
- `AndroidManifest.xml` and `res/` are out of scope; read them for facts.

### Bug report additions

- Java: resources closed outside try-with-resources, swallowed `InterruptedException`, `equals` without `hashCode`, unchecked `Optional.get()`, `@Transactional` on private or self-invoked methods, N+1 lazy loading, SQL built by concatenation.
- Kotlin: `!!` on nullable values, `lateinit` read before assignment, `GlobalScope`, `runBlocking` on the main thread, swallowed `CancellationException`.
- Android: a `Context` or `View` held by a ViewModel or static field; blocking work on the main thread.
