# Section 2: what to look for

The numbered check list, and the single source of check IDs: `SKILL.md`, subagents, and the coverage file all use these IDs. Read it in full before section 2, and give it to every reading and verification subagent.

Check every row of the data model and every template against this list. Each check has an ID (`FLD-01`); cite it on every candidate bug, and record in the coverage file, for every ID, whether it was checked (with the number of bugs it found), doesn't apply to this theme (with why), or was skipped (with why). An ID with no outcome means the check was forgotten. Check IDs are stable across prompt versions: a new check gets the next free number in its group, a removed check's number is retired and never reused, and an ID always means the same check, so audits made with different prompt versions can be compared. Record each candidate bug in `<work>/findings.md` with its check ID and `file:line` as you find it; section 3 confirms it on a live site where it can.

**Fields and settings**
- **FLD-01** The save handler stores a shape the template doesn't read (a URL where the template expects an attachment ID, a comma list where it expects an array, a different key or prefix).
- **FLD-02** A template reads a field that no meta box, control, or save handler ever writes, so the admin has no way to set it.
- **FLD-03** A field, Customizer setting, or options field that no template reads, so changing it does nothing.
- **FLD-04** A checkbox saved as one value (`'1'`) and compared against another (`'on'`, `true` with `===`); a checkbox that can never be unchecked because the handler skips missing keys.
- **FLD-05** Two different defaults for one setting (the `add_setting` default and a `get_theme_mod( 'x', 'other' )` fallback), so the Customizer shows one value and the site shows another.
- **FLD-06** A sanitize callback that lets invalid values through (a select that accepts any string, a number without bounds, a colour that isn't checked as hex), or rejects valid ones; a Customizer setting with no sanitize callback at all.
- **FLD-07** An options sanitizer that rebuilds the whole array and wipes keys it doesn't know, or keys that belong to another tab of the same panel.
- **FLD-08** A save handler with no nonce check, no capability check, or no autosave and revision guard, or one that writes meta on the wrong post type.
- **FLD-09** A text value printed without escaping, or escaped with the wrong function for its context (`esc_html` inside an attribute, `esc_attr` on a URL); a WYSIWYG field stripped of the HTML its editor allows.
- **FLD-10** A meta key or option printed raw (or through a weak filter) that someone other than an administrator can write: check every such key's write paths, whatever plugin or screen normally fills it. Keys without a leading underscore can be set by any user who can edit the post through the core Custom Fields box, and by REST when `show_in_rest` is on; keys registered without an `auth_callback` are writable by anyone who can edit the post. A contributor writing script into a key the theme echoes is stored XSS.

**Customizer**
- **CUS-01** A setting with `transport` set to `postMessage` that the preview script never binds, so the preview doesn't change until a reload; a preview binding for a setting that doesn't exist, or that updates the wrong selector.
- **CUS-02** A selective refresh partial whose selector matches no markup, whose `render_callback` errors or returns different markup from the template, or that is missing `container_inclusive` where the template replaces the wrapper.
- **CUS-03** An `active_callback` that hides a control when it should show, or references a setting ID that doesn't exist; a panel or section with no controls, which core hides, so its settings can't be reached.
- **CUS-04** A custom control class whose JS errors, doesn't save, or doesn't restore its saved value when the Customizer reopens; a control whose `choices` differ from what its sanitize callback accepts.
- **CUS-05** A setting whose `capability` is higher or lower than the rest (for example `manage_options` on a theme mod), or whose `type` is `option` with no prefix, so it can clash with a plugin.
- **CUS-06** A setting or control ID that is registered twice, so the second silently replaces the first.

**Theme options panel**
- **OPT-01** The form posts an option group that doesn't match `register_setting`, so saving fails with "Error: options page not found" or saves nothing.
- **OPT-02** A page registered with a capability higher or lower than it needs, or a menu page whose callback prints nothing.
- **OPT-03** Saving one tab wipes the fields on another tab, or an unchecked checkbox on one tab is treated as unchecked on every tab.
- **OPT-04** A reset-to-defaults tool that resets different values from the registered defaults, or that has no nonce or confirmation; an import tool that accepts arbitrary options or unserializes input; an export that includes secrets.
- **OPT-05** Validation errors that are never shown, or a success message shown when saving failed.
- **OPT-06** Options left behind or deleted unexpectedly on theme switch or deletion, if the theme claims to handle it.

**Category and taxonomy fields**
- **TAX-01** A field on the add-term form that isn't saved on create (only the `edited_` hook is wired), or a field on the edit form that isn't saved on edit.
- **TAX-02** Quick edit on a term, which fires the save hooks without the custom fields in `$_POST`, wiping the term's meta because the handler doesn't check `isset()` first. Check the same for posts: quick edit and bulk edit fire `save_post` without meta box fields, so a handler that doesn't check its nonce or `isset()` clears the meta.
- **TAX-03** Term meta or term options not deleted when the term is deleted (`delete_term`, `delete_{$taxonomy}`), or kept under a term ID that a new term can reuse.
- **TAX-04** A term image or colour field whose picker script doesn't load on the add form, the edit form, or both; an image stored as a URL on one screen and an ID on the other.
- **TAX-05** A list-table column that errors or shows the wrong value when the field is empty.
- **TAX-06** A template that reads term meta for a taxonomy whose screen has no field for it, or a field added to a taxonomy that no template reads.
- **TAX-07** The same fields for user profiles and attachments, where the theme has them.

**Content and templates**
- **CNT-01** A counter the templates print that no code in the theme ever writes (views, likes, votes), so it is always zero.
- **CNT-02** A post format, post type, or taxonomy the theme declares that no template renders differently, or a template branch for a format the theme doesn't declare.
- **CNT-03** A template that reads a post's child attachments with no way to exclude the featured image, so the featured image appears twice.
- **CNT-04** Image slots that request a size the theme never registers, or a registered size no template uses.
- **CNT-05** Empty states: a missing featured image, an empty field, a post with no terms, an author with no bio, zero comments. Each should either fall back cleanly or hide its element; a stray label, an empty wrapper that still takes space, a broken `<img>`, or a PHP notice is a bug.
- **CNT-06** Fallback content that is placeholder or developer text ("Set a form action URL", "Lorem ipsum", "Add widgets here" shown to visitors).
- **CNT-07** Comments: a template that shows a comment count or form where comments can never appear, or a switch that claims to turn comments on and doesn't.

**Site**
- **SITE-01** A registered menu location, widget area, or page template that no template displays.
- **SITE-02** `custom-logo`, `custom-header`, or `custom-background` declared but never output.
- **SITE-03** An activation seeder that errors, duplicates content when run twice, or overwrites what the owner already set.
- **SITE-04** A sample-content or one-click import system whose remove or reset tool deletes seeded content or the owner's settings, or misses the content it created.
- **SITE-05** Transients or caches that nothing clears when the content they cache changes.
- **SITE-06** A missing plugin dependency that causes a fatal error instead of a notice or fallback.
- **SITE-07** Build problems: a build that fails, or warns about missing files or deprecated options, with the documented command and the Node.js version the theme asks for; a lockfile that is missing or doesn't match `package.json`.
- **SITE-08** Stale built files: CSS rules or JS behaviour the source defines but the committed output lacks, or output that no longer matches the source; a built file that the theme enqueues but that is ignored by `.gitignore` and not committed, so a copy made from the repository has no styles or scripts, unless the theme documents a release build that adds it.
- **SITE-09** Tailwind and other class scanners: a class the templates or JS use that the built CSS doesn't contain, because the `content` globs miss a folder or file type, or because the class name is assembled at runtime (`'bg-' . $color`, `` `text-${size}` ``), which scanners can't see and which needs a safelist.

**Code**
- **CODE-01** PHP errors: run `php -l` on every theme PHP file, and note any function removed or deprecated in the PHP and WordPress versions the theme claims to support (`Requires PHP`, `Requires at least` in `style.css` and `readme.txt`).
- **CODE-02** Calls to functions, methods, or classes that don't exist in the theme, core, or a declared dependency, including callbacks passed by name with a typo.
- **CODE-03** Unused code: every function, method, class, hook callback, template part, JS function, and CSS/JS file that nothing calls, hooks, loads, or enqueues. For each candidate, search the whole theme (PHP and JS) for its name before calling it unused, and rule out the ways code runs without a literal call: a hook, route, shortcode, or callback registered by string or array; a dynamic name (`"prefix_{$type}"`, `call_user_func`, `get_template_part( 'parts/card', $format )`, template file names core loads by hierarchy); a pluggable function wrapped in `function_exists()` for child themes to override; a method called through `$this`, `static::`, or a parent class; a function the theme documents as a public template tag. Anything that survives those checks is unused. List every unused item in the coverage file with status `Unused`, and put it in the bug file grouped by feature (one bug per unused feature or file, listing every function in it), because unused code is usually a half-built or half-removed feature.
- **CODE-04** Hooks added to actions that never fire in that context (for example admin-only code behind `is_admin()` that a front-end template needs, or a hook added after the action has already fired), and hooks added with a misspelled name.
- **CODE-05** `accepted_args` lower than the number of parameters the callback needs, so later arguments arrive as their defaults; a filter callback that doesn't return its value, so the filtered value becomes `null`.
- **CODE-06** `remove_action` / `remove_filter` with a priority or callback that doesn't match the `add_` call, so nothing is removed.
- **CODE-07** Functions that run but return the wrong result: wrong query arguments (`posts_per_page` ignored, `post_type` missing, `meta_query` comparing a number as a string), off-by-one loops, conditions that can never be true, early returns that skip needed work, `pre_get_posts` changes that also hit admin screens or secondary queries.
- **CODE-08** Entry points: an AJAX handler, REST route, or admin-post handler with no nonce check, no capability check, or no `permission_callback`; one that doesn't `wp_die()` or `exit`, so `0` is appended to the response; a `nopriv` handler missing where logged-out visitors use the feature; a shortcode that echoes instead of returning, or breaks on missing attributes; a widget that errors with an empty instance; a cron event scheduled on every page load or never unscheduled on theme switch.
- **CODE-09** REST: a route with `permission_callback` set to `__return_true` that writes data or returns anything private; a missing `permission_callback` (core logs a `_doing_it_wrong` notice); `args` with no validation, so a wrong type or missing field reaches the callback; a callback that returns a bare value or `false` instead of a `WP_REST_Response` or `WP_Error` with a proper status code, or returns 200 on failure; a response that leaks private data to logged-out visitors (emails, drafts, private posts, private meta, user data beyond core's public fields); meta or fields registered with `show_in_rest` whose schema doesn't match what is stored, so reads fail or writes are rejected; a `rest_endpoints` or `rest_authentication_errors` filter that breaks or opens up core routes; a route the theme's JS calls without the `X-WP-Nonce` header, so it fails for logged-in users.
- **CODE-10** Text domain mismatches: strings in a text domain other than the theme's slug.
- **CODE-11** Accessibility and HTML validity problems in the markup the theme outputs: missing `alt` on content images, form fields with no label, duplicate IDs, links with no text, broken heading order in templates.

**Templates and template parts**
- **TPL-01** A `get_template_part()` call whose slug and name resolve to no file (it fails silently and prints nothing), including values a dynamic name can take that have no matching file and no `<slug>.php` fallback; a `get_header( 'name' )`, `get_footer( 'name' )`, or `get_sidebar( 'name' )` variant whose file doesn't exist, so core silently loads the default.
- **TPL-02** A part that uses a variable defined in the file that loaded it: `get_template_part()` runs the part in its own scope, so the variable is undefined (a PHP warning, and an empty value). The part should read it from `$args`. The reverse too: a key passed in `$args` that the part never reads, or reads under another name, or without a default when a caller doesn't pass it.
- **TPL-03** `locate_template( ..., true )` with `$require_once` left at its default of `true` inside a loop, so the part renders only for the first item; a part loaded with `include` or `require` instead of `get_template_part()` or `locate_template()`, so a child theme can't override it.
- **TPL-04** A part that runs its own `WP_Query` or `setup_postdata()` without `wp_reset_postdata()`, or calls `query_posts()`, so everything after it shows the wrong post, title, or comments; a part that assumes the loop (`get_the_ID()`, `the_title()`) but is also loaded outside it.
- **TPL-05** HTML opened in one part and closed in another (`header.php` opens a wrapper that `footer.php` closes) where some template path skips one of them, leaving unclosed or extra closing tags; unbalanced tags inside a single part's branches.
- **TPL-06** A template in the hierarchy that is never reached because of a misspelled file name (`single-portfolio.php` for a post type registered as `portfolios`), or a more specific file that shadows it; a `Template Name:` header with a typo, or a `Template Post Type:` that hides a page template from the post type it's meant for.
- **TPL-07** A template missing `wp_head()`, `wp_footer()`, `wp_body_open()`, `body_class()`, or `post_class()`, which breaks plugins, the admin bar, and styles; a singular template missing `wp_link_pages()`, so posts split with `<!--nextpage-->` lose every page after the first; a template that shows comments without `comments_template()`.
- **TPL-08** The same part rendered twice on one page by accident (for example once in the template and once through a hook).

**Namespaces**
- **NS-01** A class used inside a namespace without a leading `\` or a `use` import (`new WP_Query` in `namespace Theme;` looks for `Theme\WP_Query` and fatals); the same for `instanceof`, `catch ( Exception $e )` (which silently never catches), type hints, and `::class`.
- **NS-02** A callback passed as a string without its namespace (`add_action( 'init', 'setup' )` inside a namespace calls the global `setup`, not `Theme\setup`); the fix is `__NAMESPACE__ . '\setup'` or a callable. The same for `function_exists()`, `is_callable()`, `call_user_func()`, and callbacks in `register_setting`, `add_meta_box`, and `add_shortcode`.
- **NS-03** A `use` import of a class that doesn't exist or is never used, or two imports with the same alias.
- **NS-04** A namespace or class name whose case differs from its folder or file name, so the autoloader works on macOS and Windows but fatals on a Linux server, which is where most customers are; check each autoloaded class with `class_exists()` on the Linux test site.
- **NS-05** Strict types: `declare( strict_types=1 )` in a file that passes WordPress's string values (`get_option()`, `get_post_meta()`, `$_GET`) to parameters typed `int` or `bool`, which throws a `TypeError`.

**Classes**
- **CLS-01** A class whose constructor adds hooks and which is instantiated more than once, so every hook runs twice (duplicate output, double saves, double queries).
- **CLS-02** A hook callback pointing at a `private` or `protected` method, which WordPress can't call; `[ __CLASS__, 'method' ]` or `'Class::method'` pointing at a non-static method, which is an error on PHP 8.
- **CLS-03** Hooks added with a closure or a fresh `new` instance, so a child theme or plugin can never `remove_action()` them; report these as Low, and only when the theme documents that its behaviour can be changed.
- **CLS-04** A property used without being declared (a dynamic property, deprecated since PHP 8.2 and an error in later versions); a method called on a property that can be `null`; a class that doesn't implement every method of its interface or abstract parent; a trait method that clashes with the class using it.
- **CLS-05** A singleton that holds per-request state across `switch_to_blog()` or multiple renders, or caches a value before the data it depends on is ready (for example reading theme mods in a constructor that runs before `after_setup_theme`).
- **CLS-06** A class or interface name that is neither namespaced nor prefixed, so it can clash with a plugin; a class that is autoloaded but never used, or that `require`s a file the autoloader also loads.
- **CLS-07** Composer: `vendor/autoload.php` required but `vendor/` not committed or shipped, so the theme fatals on customer sites; or a committed `vendor/` whose `composer.lock` doesn't match `composer.json`.

**Procedural code**
- **PROC-01** A function without the theme's prefix, so it can clash with a plugin or core; two theme functions with the same name in files that are both loaded.
- **PROC-02** A function the theme documents as overridable that isn't wrapped in `function_exists()`, or one that is wrapped but defined after the code that calls it runs, so a child theme's version is never used.
- **PROC-03** A function defined inside a condition or another function, which fatals with "Cannot redeclare" the second time that code runs; a file loaded with `require` or `include` instead of `require_once` that can be loaded twice.
- **PROC-04** A `global` variable read before anything sets it, or overwritten by core or a plugin using the same name; a constant defined without a prefix or without a `defined()` check.
- **PROC-05** A `require` or `include` path built from a relative path or the current working directory instead of `__DIR__` or `get_template_directory()`.

**JavaScript**
- **JS-01** An enqueued file that doesn't exist, a dependency handle that isn't registered, or a script that uses `jQuery` or `wp.*` without declaring that dependency.
- **JS-02** An AJAX action or REST path the JS calls that PHP never registers, or one PHP registers that no JS calls; a localized key the JS reads that PHP never passes, or a different name for the same value on each side.
- **JS-03** Selectors the JS binds to that match no markup the theme outputs, so the feature silently does nothing.
- **JS-04** Errors thrown on page load or on interaction; handlers bound twice so a click fires twice; features that break when the element they expect is missing from a page.
- **JS-05** Keyboard and screen-reader breakage in interactive parts: a menu toggle or modal that can't be reached or closed by keyboard, or that never updates `aria-expanded`.
- **JS-06** Admin JavaScript that changes the post being edited as a side effect (`wp.media.featuredImage.set()` or `.remove()`, `wp.data.dispatch( 'core/editor' )`, writing to form fields such as `#_thumbnail_id` or meta inputs): trace each call to the user action that triggers it, and treat any change the user didn't ask for as a data-loss candidate.

**Blocks**
- **BLK-01** A `block.json` that is invalid or points at a `file:` asset that doesn't exist (often a `build/` file that isn't committed); a block registered twice, or both in PHP and JS with different attributes; an `apiVersion` or `supports` key the theme's minimum WordPress version doesn't know.
- **BLK-02** A dynamic block whose render callback errors, prints nothing, or prints unescaped attributes when an attribute is missing, empty, or of the wrong type; a render callback that echoes instead of returning.
- **BLK-03** A static block whose `save()` changed without a matching `deprecated` entry, so existing posts show "This block contains unexpected or invalid content" in the editor.
- **BLK-04** Block front-end styles or view scripts that load on every page even when the block isn't used, or don't load when it is; editor styles that don't match the front end.
- **BLK-05** No-build blocks: a script that uses a `wp.*` global without declaring its handle as a dependency (`wp-blocks`, `wp-element`, `wp-block-editor`, `wp-components`, `wp-i18n`, `wp-data`), so the editor throws on load; JSX or `import` in a file that is served unbuilt, which is a syntax error in the browser; strings not wrapped in `wp.i18n.__` or no `wp_set_script_translations()` call; a `block.json` `editorScript` pointing at a handle that is never registered.
- **BLK-06** Built blocks: an `index.asset.php` whose dependencies or version don't match the build, a `block.json` that points at `src/` instead of `build/`, or source that changed without a rebuild (the Build step compares them).
- **BLK-07** Dynamic blocks: a `render.php` or `render_callback` that assumes attributes exist without defaults (PHP warnings when one is missing), skips `get_block_wrapper_attributes()` so the block's `supports` (colour, spacing, alignment, custom class) have no effect on the front end, ignores `$content` so inner blocks vanish, runs a query per render that isn't cached, or renders differently in the `ServerSideRender` preview (the `/wp/v2/block-renderer/<name>` REST route) than on the front end.
- **BLK-08** Interactivity API blocks: directives that reference state or actions the store doesn't define, or a `viewScriptModule` that doesn't load.
- **BLK-09** Patterns: invalid block markup (the editor offers "Attempt block recovery"); a pattern using a block that isn't registered or that the theme unregisters; a hard-coded image URL, attachment ID, or post ID that won't exist on a customer site (images should come from `get_theme_file_uri()`); a missing or duplicate `Slug`, a slug without the theme's prefix, or a `Categories` value that isn't registered; `Block Types` or `Post Types` that hide it where it's meant to appear; PHP pattern files that print text without translation functions or escaping; a pattern that references a template part or another pattern that doesn't exist; a layout that breaks at phone width.
- **BLK-10** `theme.json` that is invalid for its `version`, a palette or font size that disagrees with the Customizer or CSS values, or a colour pair in the palette that fails contrast when used as the theme suggests.
- **BLK-11** Block templates or parts that reference a template part, pattern, or block that doesn't exist.
- **BLK-12** Blocks, patterns, or block styles that assume the block editor while the theme's customers use the Classic Editor plugin, so a feature the theme advertises can't be used.

**Security**
- **SEC-01** `is_admin()` used as a permission check: it's also true for every `admin-ajax.php` request, including logged-out ones, so it guards nothing. Permission checks use `current_user_can()` with the right capability (not `edit_posts` for a site-wide setting, not `read` for anything that writes).
- **SEC-02** A file path built from request input (`get_template_part( $_GET['view'] )`, `include $_POST['file']`, `locate_template( $input )`), which lets a visitor load other files.
- **SEC-03** An outbound request to a URL taken from input or a setting without `wp_safe_remote_*` or host checks (server-side request forgery); `sslverify` turned off.
- **SEC-04** SVG uploads enabled (`upload_mimes`) without sanitizing the file, which allows stored XSS; a theme upload or file-write handler that doesn't use `wp_handle_upload()`, check the file type, or check capabilities.
- **SEC-05** `unserialize()` or `maybe_unserialize()` on input, cookies, or imported settings; `extract()` on input; `eval()`, `create_function()`, `assert()` with strings, `preg_replace` with `/e`, or code hidden with `base64_decode`, `gzinflate`, `str_rot13`, or long encoded strings.
- **SEC-06** Hard-coded credentials, API keys, license keys, or tokens in the theme's files.
- **SEC-07** Inline scripts built by string concatenation (`wp_add_inline_script`, `<script>` in templates) with values that aren't passed through `wp_json_encode()`; HTML built in JS with `innerHTML` or jQuery `.html()` from AJAX or URL data.
- **SEC-08** Open redirects: `wp_redirect()` to a URL from input where `wp_safe_redirect()` is needed.
- **SEC-09** Admin actions triggered by a GET link without a nonce (CSRF), and `admin_init` or `init` handlers that change data without a capability check.
- **SEC-10** SQL with `esc_sql()` or string concatenation instead of `$wpdb->prepare()`, and `LIKE` clauses without `$wpdb->esc_like()`.
- **SEC-11** PHP files that do something when requested directly (output, writes, errors that reveal paths) because they lack `defined( 'ABSPATH' ) || exit;`.
- **SEC-12** Debug output left in: `var_dump`, `print_r`, `error_log` of user data, `console.log` of private data, or a debug mode that turns itself on.
- **SEC-13** Content of password-protected posts leaking before the password is entered: embeds, galleries, downloads (ZIPs, files), excerpts, custom fields, structured data, feeds, and REST output that skip `post_password_required()`.
- **SEC-14** Public (`nopriv`, `permission_callback` open, or front-end form) endpoints: for each, check that IDs are checked for existence, the right post type, and published status; that the endpoint respects the theme option that's meant to turn its feature off; that it limits how often one visitor can act (votes, views, likes, favourites, transient-creating lookups); and that deduplication doesn't rest only on a cookie or `localStorage`, which a visitor controls (cookie-only dedupe is no dedupe). Every endpoint a fix makes newly reachable gets the same checks.

**Updates and upgrades**
- **UPG-01** A renamed or removed option, theme mod, or meta key with no migration, so existing sites lose settings after updating.
- **UPG-02** A migration or upgrade routine that runs on every page load (no stored version check), runs twice, fails partway without recording it, or can't run on a site that skipped a version.
- **UPG-03** A public function, hook, template tag, pluggable function, or template part path that was removed or renamed since the earlier release, so customers' child themes break; report it unless the theme's changelog announces it.
- **UPG-04** A changed Customizer default: sites that never saved that setting change their look silently on update.
- **UPG-05** A new or changed image size with no note that thumbnails must be regenerated, so old images show the wrong crop.
- **UPG-06** Assets enqueued with `null`, `false`, a hard-coded version that isn't bumped, or the WordPress version, so browsers and CDNs keep serving the old CSS and JS after an update.

**Update checker and license**
- **LIC-01** Requests to the update or license server with no timeout, a timeout over 10 seconds, or on every admin page load instead of from a cached transient, so wp-admin hangs when that server is slow or down.
- **LIC-02** A `WP_Error` from the request used as if it were a response (PHP warnings or fatals when the server is down); a failed check cached as "no update" forever, or never cached so it retries on every load.
- **LIC-03** An entry added to the `update_themes` transient under the wrong key or with missing fields (`theme`, `new_version`, `url`, `package`), which causes warnings on the Updates screen or updates the wrong theme.
- **LIC-04** License keys sent over `http://`, shown in page HTML, localized scripts, or exports, or stored with autoload in a way that leaks through the REST API.
- **LIC-05** Site data (admin email, URL, plugin list) sent to a remote server without the theme saying so.

**Caching**
- **CACHE-01** A nonce printed in logged-out page HTML and used by AJAX or REST calls: under a page cache it expires after 12–24 hours and the feature fails for every visitor served the cached page. It needs a fresh nonce fetched by JS, or a nonce-free public endpoint with other protection.
- **CACHE-02** A view, like, or vote counter incremented while PHP renders the page: under a page cache it stops counting. It needs an AJAX or REST call.
- **CACHE-03** Logged-out HTML that differs per visitor (cookie values, `$_SERVER` data, random content, "recently viewed"), which a page cache freezes for everyone.
- **CACHE-04** `DONOTCACHEPAGE`, `nocache_headers()`, or `session_start()` on every page, which silently disables page caching for the whole site.
- **CACHE-05** Code that assumes the object cache is not persistent (storing objects that go stale, using `wp_cache_*` as a lock).
- **CACHE-06** A page whose HTML depends on a visitor's cookie (favourites, history, recently viewed, dismissed notices): under a page cache, the first visitor's version is shown to everyone. Such content must be loaded by JS after the page loads, or the page must be excluded from caching.
- **CACHE-07** Code that assumes the object cache *is* persistent: values kept only in `wp_cache_*` (counters, rate limits, locks, queues) that are lost on every request without a persistent cache, or that are lost or double-counted when one is added.

**Performance**
- **PERF-01** `flush_rewrite_rules()` on `init` or any other hook that runs on every request, instead of once on activation or when rules change.
- **PERF-02** Autoloaded options owned by the theme that total over 100 KB, or a single one over 50 KB; transients stored without an expiry that keep growing.
- **PERF-03** Images output as raw `<img>` tags without `srcset`, `sizes`, `width`, and `height` where `wp_get_attachment_image()` would add them; the first large image above the fold marked `loading="lazy"`, which delays the largest paint.
- **PERF-04** Scripts and styles loaded on every page when only one template uses them; render-blocking scripts in `<head>` that could be deferred.
- **PERF-05** Remote requests during a normal page load; uncached expensive queries in widgets or menus that run on every page.

**Privacy**
- **PRIV-01** Fonts, scripts, or styles loaded from third-party hosts in visitors' browsers (Google Fonts, CDNs, Gravatar where the theme adds it), including through `@import` and `url()` inside the theme's CSS and bundled library CSS, which page HTML doesn't show, without an option to host them locally or turn them off; in the EU this is a known legal problem.
- **PRIV-02** IP addresses, emails, or other personal data stored (for votes, likes, or forms) with no retention limit and no personal data exporter or eraser.
- **PRIV-03** Cookies or `localStorage` entries set before any consent, with no filter or setting to hold them back, or without the theme listing them.

**Translation and time**
- **I18N-01** A fresh `.pot` built from the code (step 15) that has strings the shipped `.pot` lacks, or the reverse.
- **I18N-02** `sprintf()` placeholders that don't match the arguments, or several placeholders without numbered positions (`%1$s`) so translators can't reorder them; placeholders without a `/* translators: */` comment; sentences built by concatenating translated pieces; plurals built with `if` instead of `_n()`.
- **I18N-03** `load_theme_textdomain()` missing, or called before `after_setup_theme`, or translated strings used before `init` (WordPress 6.7 and later logs "Translation loading was triggered too early"); JS strings with no `wp_set_script_translations()`.
- **I18N-04** Dates shown with `date()` or `gmdate()` instead of `wp_date()`, or with a hard-coded format instead of the site's `date_format` and `time_format`; `number_format()` where `number_format_i18n()` belongs.
- **I18N-05** `current_time( 'timestamp' )` compared with `time()` or passed to `date()`, comparisons that mix GMT and local times (`post_date` against `time()`), and `strtotime()` on local dates without the site's time zone, so relative times, "new" badges, countdowns, and scheduled items are off by the site's offset.

**SEO and structured data**
- **SEO-01** JSON-LD that isn't valid JSON, or that has required properties missing or wrong for its `@type`; microdata with broken nesting.
- **SEO-02** A `<title>` printed by the theme instead of `add_theme_support( 'title-tag' )`, or two `<title>` tags; Open Graph, Twitter, or schema output duplicated when an SEO plugin (Yoast, Rank Math) is active, with no check for it.
- **SEO-03** Feeds, `wp-sitemap.xml`, or embeds (`/embed/`) that error, leave out the theme's public post types, or include private ones.

**Accessibility**
- **A11Y-01** No skip link as the first focusable element, or one that points at an ID the page doesn't have; focus outlines removed with no replacement.
- **A11Y-02** Animations, transitions, auto-playing sliders, or parallax that ignore `prefers-reduced-motion`.
- **A11Y-03** Content that overflows, overlaps, or needs horizontal scrolling at 200% zoom (a 720 px wide viewport stands in for 1440 at 200%).
- **A11Y-04** Text and background colours that fail WCAG AA contrast with the theme's defaults, or with the colour choices its own palette or presets offer.
- **A11Y-05** Keyboard traps in menus, modals, and sliders; content only reachable on hover.

**CSS**
- **CSS-01** Invalid properties or values, unknown units, and duplicate selectors that override each other by accident (from stylelint).
- **CSS-02** Features the theme's supported browsers don't have, with no fallback (from the browser-support check).
- **CSS-03** `@media print` rules that hide the content or print navigation and ads, where the theme ships print styles.

**Admin**
- **ADM-01** An admin notice that can't be dismissed, whose dismissal isn't saved per user, that shows on every admin screen instead of where it matters, or that shows to users who can't act on it.
- **ADM-02** Output sent before headers in admin (a notice or `echo` too early), which causes "headers already sent" warnings and breaks redirects.

**Multisite**
- **MS-01** `get_option()` where a network-wide setting needs `get_site_option()`, or the reverse; hard-coded URLs or upload paths that are wrong on sub-sites; `switch_to_blog()` without `restore_current_blog()`; `manage_options` checks that lock out sub-site admins or let them change network settings; activation code that only runs for the main site.

**Theme switch**
- **SW-01** Settings, widgets, menu locations, or theme mods deleted or broken when a customer switches to another theme and back (a customer testing another theme loses their setup).
- **SW-02** `switch_theme` and `after_switch_theme` handlers that error, or activation code that runs again on every switch back and duplicates content.

**Marketplace rules** (only if intake question 6 chose WordPress.org or ThemeForest)
- **MKT-01** WordPress.org: every `REQUIRED` and `WARNING` item from the Theme Check plugin (step 15), plus the handbook rules it can't check: plugin territory (custom post types, shortcodes, and non-presentational features belong in a plugin), no removal of core features, no admin nags, fonts and scripts bundled rather than loaded from CDNs, GPL-compatible licenses for every bundled file, and a `screenshot.png` of 1200×900 or smaller.
- **MKT-02** ThemeForest: the Envato WordPress requirements, including plugin territory, TGMPA for required plugins, prefixing, escaping late, no removal of core features, and no minified-only files without their source.
- **MKT-03** These go in the bug file's `## Marketplace review` section (section 5), not the severity groups, unless the item is also a bug.
