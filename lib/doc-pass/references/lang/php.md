## PHP rules

PHPDoc on declarations, `//` for why-comments. Static analysers, IDE helpers and API generators read PHPDoc, so many tag lines are code.

### Files and tools

- **In scope:** `.php`, `.phtml`, `.inc`.
- **Out of scope** (read for facts only): `.blade.php`, `.twig`, `.latte`, `vendor/`, `storage/`, `bootstrap/cache/`, Symfony `var/`, `phpstan-baseline.php`, and generated IDE helpers (`_ide_helper.php`, `_ide_helper_models.php`, `.phpstorm.meta.php`).
- **Syntax check:** `php -l <file>` on each edited file. Without a `php` binary, say so.
- **Baselines** (project binaries only; when `vendor/` is missing, run `composer install --no-scripts` in the scratchpad copy):
  - PHPStan / Larastan: `vendor/bin/phpstan analyse --no-progress --error-format=json`, counted per identifier. A new `phpDoc.*` error from an added tag is fixed in the comment.
  - Psalm: `vendor/bin/psalm --no-cache --output-format=json`, per issue type.
  - phpcs: `vendor/bin/phpcs --report=json`, per (file, sniff). Commenting sniffs go down; nothing goes up.
  - `vendor/bin/php-cs-fixer fix --dry-run --diff` and `vendor/bin/pint --test`: no file newly fails.
  - Tests: `vendor/bin/phpunit`, `vendor/bin/pest` or `php artisan test`.
- **`--checked-types`:** pass it to every verify and selftest run when PHPStan, Larastan or Psalm is configured (`phpstan.neon`, `phpstan.neon.dist`, `phpstan.dist.neon`, `psalm.xml`, `psalm.xml.dist`). PHPDoc types are then code.

### Doc comment style

- **Dialect:** a WPCS ruleset (`WordPress-Docs` in `phpcs.xml`) means WordPress style: third-person summaries, `@since`, hash notation for array arguments, no `@return void`. Otherwise PSR-5 / PSR-19 (phpDocumentor). Follow the phpdoc rules in `.php-cs-fixer.php` or `pint.json`, and the project's voice (Laravel and Symfony use the imperative: "Get the invoice total.").
- **Layout:** one-line summary ending in a period, a blank ` *` line, the description, then tags in the fixer's `phpdoc_order`, else `@param`, `@return`, `@throws`.
- **Types only where they add to the native type.** A bare `@param int $id` is noise (`no_superfluous_phpdoc_tags` flags it); `@param int $id Invoice ID from the route.` is fine. On a new or untyped tag, refine instead of repeating (an existing typed tag stays as it is under `--checked-types`: its type is compared): `list<string>`, `array{id: int, name: string}`, `class-string<Model>`, `Collection<int, Invoice>`. Generics and shapes only when PHPStan or Psalm runs, or the project already uses them.
- **`@throws ModelNotFoundException When …`** for each exception thrown on purpose.
- **Properties:** a summary; `@var` only when it refines the native type.
- **Overrides** that add nothing: `{@inheritDoc}` alone, in the codebase's casing. Never on a class without a parent or interface.
- **Promoted constructor properties:** when the constructor needs a docblock, give each promoted data property (DTO, value object) an `@param`.
- **File docblock:** after `<?php`, above `declare(strict_types=1);`, `namespace` and `use`. An existing `/* … */` license block stays first (checked by reading).
- **Inline:** `//` full sentences. Never start a `#` comment with `[` (`#[` is an attribute). Never write `?>` in a `//` or `#` comment: it ends PHP mode. Never comment inside a heredoc or nowdoc.

### Coverage

- **File header:** a `/**` docblock between `<?php` and the first statement. When that statement is a class, interface, trait, enum or function, two docblocks must sit there. `/*` and `//` do not count.
- **Needs a `/**` docblock directly above** (no blank line; put it above any attributes): every class, interface, trait and enum; every named function, nested or inside `if (! function_exists())`; every method, abstract, interface and private included; every property declaration and every `const` declaration (one per statement, class or top level).
- **Exempt:** a constructor whose parameters are all promoted and whose body is empty; framework configuration properties whose meaning the framework defines (Eloquent `$table`, `$fillable`, `$guarded`, `$hidden`, `$casts`, `$with`, `$appends`, `$primaryKey`, `$timestamps`; console `$signature`, `$description`; kernel `$middleware…`, `$commands`; provider `$listen`, `$subscribe`, `$policies`; handler `$dontReport`, `$dontFlash`, and similar); and, in a `test/` or `tests/` folder or a `*Test.php` file, methods named `test…`, `setUp`, `tearDown`, `setUpBeforeClass`, `tearDownAfterClass` or `…Provider`, and methods marked `#[Test]` or `@test`. Other test helpers are not exempt.
- **Not scanned, checked by reading:** closures, arrow functions, enum cases, `define()`, Pest `it()` / `test()` callbacks, statement comments (route registrations, container definitions). An anonymous class (`return new class extends Migration`) needs none itself; its members do.

### Comments that are code

- **Frozen whole comment** when its first line starts with `phpcs:ignore`, `phpcs:disable`, `phpcs:enable`, `@codingStandardsIgnore`, `@phpstan-ignore`, `@psalm-suppress`, `php-cs-fixer:`, `translators:`, `cspell:`, `spell-checker:`, `noinspection`, `NOSONAR` or `language=`; or when any line starts with `@generated`, `@license`, `Copyright`, `(c)` and a digit, `©`, `SPDX-License-Identifier`, `Permission is hereby granted` or `Licensed under the`, or names the GNU (Lesser, Affero) General Public License.
- **Frozen tag lines** (never added): `@test`, `@dataProvider`, `@depends`, `@group`, `@ticket`, `@covers…`, `@uses`, `@requires`, `@runInSeparateProcess`, `@runTestsInSeparateProcesses`, `@preserveGlobalState`, `@backupGlobals`, `@backupStaticAttributes`, `@doesNotPerformAssertions`, `@expectedException…`, `@before…`, `@after…`, `@testWith`, `@testdox`, `@small` / `@medium` / `@large`, `@noinspection`, `@codeCoverageIgnore…`, `@infection-ignore-all`, `@deprecated`, `@internal`, `@final`, `@readonly`, `@pure`, `@immutable`, `@required`, `@phpstan-ignore…`, `@psalm-suppress`, the Scribe / API-doc tags `@response`, `@status`, `@unauthenticated`, `@operationId`, `@requestMediaType`, and any tag starting with a capital or containing a namespace (`@ORM\Column`, `@Route`, `@OA\Get`).
- **Kept whole:** `@since`, `@see`, `@link`, `@author`, `@api`.
- **Kept typed** (tag, type and `$name` stay; the description may change; a tag whose type spans lines is joined until its brackets balance): `@phpstan-*`, `@psalm-*`, `@template*`, `@mixin`, `@extends`, `@implements`, `@property`, `@property-read`, `@property-write`, `@method` (always: they feed Larastan and IDE helpers). `@method` keeps its whole signature up to the closing `)`; `@phpstan-type`, `@psalm-type`, `@*-import-type` and `@template*` lines stay whole; with `--checked-types` also `@param`, `@return`, `@var`, `@throws`. You may add a type to an untyped `@param`; never change or loosen an existing type.
- **Next-line directives** stay last before their code: `phpcs:ignore`, `@phpstan-ignore-next-line`, `@psalm-suppress`, `translators:`.
- Never start a new comment, or a line in one, with these words or with `@` and a capital.

### Laravel

- **Routes files:** the header names the prefix and middleware group from `bootstrap/app.php` or `RouteServiceProvider`. A doc comment before each `Route::` registration or group with a closure body: method, full path, name, middleware. Keep the `|---` banners.
- **Controllers:** each action names its route, form request, policy check and response (view, resource, redirect, status).
- **Form requests:** `authorize()` says who passes; `rules()` describes the input in words.
- **Eloquent models:** the table and what a row means. `@property` blocks feed Larastan and the IDE; when `ide-helper:models --write` made them, add the summary above and leave the tags. Document `$fillable` / `$guarded` (mass-assignment exposure), `$hidden`, `casts()`, each relationship (model, foreign key, nullable), scopes, accessors and mutators.
- **Observers, policies, jobs, events, listeners:** which model events an observer handles; who each policy ability allows; a job's queue, `$tries`, `$backoff`, `$timeout`, uniqueness and side effects; events per the event map, and whether a listener is queued.
- **Migrations:** what changes and whether `down()` reverses it.
- **Service providers:** what `register()` binds and its lifetime (`singleton`, `bind`, `scoped`); what `boot()` registers.
- **Facades:** keep `@method static` lines; name the bound service.
- **Config:** document each `env()` once in `config/*.php`; elsewhere cite the `config()` key.
- **Scramble** (`dedoc/scramble`): controller docblocks and comments above `rules()` keys become OpenAPI text. Treat it as a comment-reading tool; never add `@response`, `@status`, `@unauthenticated`, `@operationId`, `@example` or `@default`. The checker freezes the first four; `@example` and `@default` are checked by reading.

### Symfony

- **Controllers:** `#[Route]`, `#[IsGranted]`, `#[MapRequestPayload]` are code. The docblock states path, name, methods, access and responses.
- **`services.yaml`** and XML config are out of scope; read them for autowiring, tags and bindings.
- **Doctrine entities:** attributes are code. In annotation blocks, every `@ORM\…` line, continuation lines included, stays byte for byte; the summary goes above them. Document each field's meaning, nullability and owning side.
- **Console commands:** `#[AsCommand]` arguments, `setDescription()`, `setHelp()` and option help strings are code. The docblock gives a summary, what the command reads and writes, and exit codes.

### Slim and plain PHP

- **Route files:** the `return function (App $app)` closure lists groups and their middleware. An `[Controller::class, 'method']` route is documented on the method; a closure handler before its statement.
- **Middleware:** Slim runs the last-added first. Say why each `$app->add()` sits where it does, and when a middleware short-circuits.
- **DI definitions** (PHP-DI `$container->set()`, `DI\autowire()`, `DI\factory()`): what each builds and reads; PHP-DI resolves it once per container.
- **Templates:** a `.php` / `.phtml` view mixing HTML and `<?php ?>` gets only a header in its first `<?php` block.

### Bug report additions

- SQL from input: concatenated PDO queries, `DB::raw()`, `whereRaw()`, `orderBy()` with a request column.
- `unserialize()` on input, `eval()`, `extract($_REQUEST)`, `include` of an input path; `exec()` / `shell_exec()` without `escapeshellarg()`; URLs from input fetched (SSRF).
- `==` on tokens (not `hash_equals()`), `md5()` / `sha1()` passwords, `rand()` / `uniqid()` tokens.
- `$guarded = []` or `$request->all()` into `create()`; `authorize()` returning `true` on a write.
- `{!! !!}` or `|raw` on user data; unescaped `echo`; unchecked redirect targets; no session regeneration after login.
- `env()` outside `config/`, leftover `dd()` / `var_dump()`, `@` suppression, swallowed `\Throwable`, N+1 lazy loading.
