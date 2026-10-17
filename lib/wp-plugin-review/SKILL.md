# WordPress Plugin Development Review

Review WordPress plugins (6.x+) for architecture, lifecycle, API usage, and WordPress.org compliance. Report findings by file, with line numbers, severity (CRITICAL/WARNING/INFO), and BAD/GOOD code pairs.

**Out of scope:** themes, Gutenberg blocks, WooCommerce extensions, performance audits. Security depth (nonces, capabilities, sanitization, escaping) belongs to the `/wp-security-review` command: list security observations one line each under `Security note:`, with no severity, outside the issue counts.

**How-to questions** with no code to review: skip the workflow and answer from the matching reference file.

## Review Workflow

### 1. Establish context

Context changes severity. Determine it first.

| Context | Recognize by | Severity effect |
|---|---|---|
| WordPress.org | User says so, or `readme.txt` with `Stable tag` | Strictest: the catalog's "WordPress.org:" escalations apply |
| Private | Custom updater, proprietary license, no readme.txt | readme.txt and GPL not required. Prefixing still required |
| mu-plugin | Lives in `wp-content/mu-plugins/` | Activation/deactivation/uninstall hooks never fire. Missing hooks are no finding; setup that depends on them is |
| Drop-in | Reserved filename such as `object-cache.php`, `db.php` | Skip header, activation, and text domain checks |

Full rules and the drop-in list: `references/review-checklist.md` → "Platform Context". For WordPress.org reviews, also apply the checklist in "Platform Context" → "WordPress.org Submission Context".

### 2. Run the scanner

`<skill-dir>` is `${CLAUDE_PLUGIN_ROOT}/lib/wp-plugin-review`, the folder that contains this procedure file; every relative `references/...` or `scripts/...` path below is inside it. Run the scanner as a command of its own (no `cd`, `;`, `&&`, or pipe), so the pre-approved tool rule matches:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/lib/wp-plugin-review/scripts/scan.sh <absolute-plugin-dir>
```

It prints candidates by severity and ends with a READ LIST of every PHP file (excluding `vendor/`, `node_modules/`, `tests/`) and the files that register hooks. Every hit is a candidate: confirm it in the code before reporting. It does not check global variables, option/meta key prefixes, deprecated functions, settings fields without `register_setting()`, post types before `init`, closures in `register_uninstall_hook()`, write routes using `__return_true`, or readme/license validity.

If it can't run (no ripgrep, or pasted code), apply the checklist by hand.

### 3. Read every file

Read every READ LIST file completely, main file and `uninstall.php` first. Many problems sit in files with no scanner hits.

Size is no reason to stop below about 20,000 lines. Above that, read in this order: files with scanner hits, files that register hooks, the rest. Continue until done or context runs short, and list unread files in `Coverage:`.

Before classifying anything, read `references/severity-catalog.md`: it holds the CRITICAL/WARNING/INFO tables, and severity comes only from it. Apply the matching section of `references/review-checklist.md` per file type.

### 4. Filter false positives

Check each finding against "Not a Problem". Drop matches entirely: never write a finding and then call it acceptable.

### 5. Write the report

Use the output format. Base GOOD code on the matching PLG pair in `references/code-examples.md`, adapting prefix and text domain. Every GOOD snippet must itself pass the severity catalog.

## Not a Problem

| Pattern | Why |
|---|---|
| mu-plugin without activation hooks, when no setup depends on them | Never activates |
| `defined( 'WPINC' ) \|\| die;` | Equivalent guard |
| Drop-in without header; private plugin without readme or GPL | Not required in those contexts |
| `README.TXT`, `Readme.md`, or other capitalization | WordPress.org and Plugin Check match `readme.(txt\|md)` case-insensitively |
| `__return_true` on a GET route | Public read-only endpoint |
| `sanitize_callback` that changes type | Checkbox to boolean is valid |
| Verbatim core string with no text domain (private/mu) | Core translates it. If unsure the string is in core, report INFO "verify" |
| Class or function named after the slug (`User_Role_Editor`) | The slug is the prefix |
| Short prefix inside a namespace | Namespace isolates it. Keys still need a prefix |
| No activation hook when nothing needs setup | Nothing to set up |
| `flush_rewrite_rules()` on a slug-changing settings save | One-time, user-triggered |
| `DROP TABLE` via `$wpdb->query()` in uninstall | `dbDelta()` doesn't drop |
| Untranslated `error_log()` strings | Developer-facing |
| Backend-only taxonomy (not on an editor-facing type) without `show_in_rest` | No editor UI needed |
| `register_setting()` on `init` (sections and fields are not covered) | Needed for `show_in_rest` |
| One space after `PRIMARY KEY`, `INDEX`, backticks in `dbDelta()` SQL | Normalized since 4.2 |

## Output Format

```
# WordPress Plugin Review: <plugin-slug>

Context: <WordPress.org | private | mu-plugin | drop-in>
Coverage: <"14/14 PHP files read" | "9/14 PHP files read; unread: a.php, b.php; review is partial" | "pasted code only">

## FILE: <relative/path.php>

### Line <n>: <SEVERITY> - <short title> (<PLG-ID, or "uncatalogued">)
<One-sentence impact.>

❌ BAD:
<code from the plugin>

✅ GOOD:
<corrected code using the plugin's prefix and text domain>

## SUMMARY

Total issues: <n> (CRITICAL <n>, WARNING <n>, INFO <n>)
WordPress.org readiness: <READY | NOT READY - n critical issues block submission | N/A (not for WordPress.org)>
Submission checklist: <WordPress.org only: failed items, or "all pass">
Security note: <if any: one line each, file:line, no severity> Recommend `/wp-security-review`.
```

Main plugin file first; findings in line order. One heading per issue: report a pattern repeated across files either once with all locations or once per file, never both. A heading means a counted finding: patterns cleared by "Not a Problem" and security observations (even ones Plugin Check flags) get no heading.

## Additional Resources

`scripts/scan.sh` calls two tokenizer helpers, `scripts/hooks.php` (hook callbacks) and `scripts/toplevel.php` (code at load). Neither runs plugin code. A clean helper result proves nothing, because unresolvable callbacks are skipped.

| Load when | File |
|---|---|
| Always, before classifying: CRITICAL/WARNING/INFO tables | `references/severity-catalog.md` |
| Per-file checks, context severity, WordPress.org submission checklist | `references/review-checklist.md` |
| Writing a BAD/GOOD pair | `references/code-examples.md` |
| Structure, lifecycle (incl. multisite uninstall), upgrades, prefixing, dependencies | `references/architecture-patterns.md` |
| Hook order, timing, priority, `accepted_args`, removal | `references/hooks-guide.md` |
| Namespaces, callbacks, autoloading, bundled Composer code | `references/oop-patterns.md` |
| Settings, Options autoload, REST, Transients, `dbDelta()`, AJAX, Cron, menus | `references/api-patterns.md` |
