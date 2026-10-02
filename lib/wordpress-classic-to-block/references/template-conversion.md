# Gate 3 — Template Conversion

Convert classic PHP templates to HTML block markup in `templates/` and `parts/`. `.html` files never execute PHP.

## Directory structure

```text
{theme-slug}/
  style.css                  ← header only + CSS theme.json cannot express (see "Stylesheets" below)
  functions.php              ← presentation hooks only; enqueues the theme stylesheet
  theme.json
  readme.txt                 ← required for WordPress.org (wporg-requirements.md)
  screenshot.png             ← 1200 × 900
  templates/
    index.html               ← required; final fallback
    front-page.html          ← static or custom home page (overrides home.html on the front page)
    home.html                ← blog posts index
    single.html
    single-{post-type}.html  ← per CPT (e.g. single-event.html)
    page.html
    archive.html
    archive-{post-type}.html ← CPT archives
    taxonomy-{taxonomy}.html ← custom taxonomy archives
    category.html, tag.html, author.html, date.html  ← only when they differ from archive.html
    search.html
    404.html
    full-width.html          ← custom template; every customTemplates entry needs a matching file
  parts/
    header.html
    footer.html
    post-meta.html
    sidebar.html             ← if a sidebar exists
  patterns/
    hidden-*.php             ← translatable text for templates (Inserter: no)
    hero-banner.php
  styles/                    ← style variations, presets, section styles (style-variations.md)
  assets/
    fonts/
    images/
    css/blocks/              ← per-block CSS loaded with wp_enqueue_block_style()
```

Template hierarchy is the same as for classic themes; `.html` replaces `.php`. Classic `page-{slug}.php` / `page-{id}.php` map to `page-{slug}.html`, Keep `page-{slug}.html` when behavior is keyed to the slug (`is_page( 'contact' )` enqueues, documented "a page at /contact becomes the contact page"); use a `customTemplates` entry for layouts editors choose per page.

Complete example set: `examples/block-theme/templates/` (`index`, `single`, `page`, `archive`, `search`, `404`, `full-width`, `single-event`) and `parts/` (`header`, `footer`, `post-meta`).

## Template-tag → block mapping

| Classic | Block markup |
|---|---|
| `get_header()` / `get_footer()` | `<!-- wp:template-part {"slug":"header","tagName":"header"} /-->` / `{"slug":"footer","tagName":"footer"}` |
| `get_sidebar()` | `<!-- wp:template-part {"slug":"sidebar","tagName":"aside"} /-->` |
| `the_content()` | `<!-- wp:post-content /-->` |
| `the_title()` | `<!-- wp:post-title /-->` |
| `the_excerpt()` | `<!-- wp:post-excerpt /-->` — the block calls `get_the_excerpt()` but never applies the `the_excerpt` filter: port theme `the_excerpt` filters (search-term highlighting) to `render_block_core/post-excerpt`; `excerpt_length` / `excerpt_more` are replaced by the block's `excerptLength` / `moreText` |
| `the_post_thumbnail()` | `<!-- wp:post-featured-image /-->` |
| `get_the_date()` / `the_author()` | `<!-- wp:post-date /-->` / `<!-- wp:post-author /-->` |
| `the_category()` / `the_tags()` | `<!-- wp:post-terms {"term":"category"} /-->` / `{"term":"post_tag"}` |
| `comments_template()` | `<!-- wp:comments -->…<!-- /wp:comments -->` |
| `wp_nav_menu()` | `<!-- wp:navigation /-->` |
| `the_custom_logo()` | `<!-- wp:site-logo /-->` |
| `bloginfo('name')` | `<!-- wp:site-title /-->` |
| `bloginfo('description')` | `<!-- wp:site-tagline /-->` |
| "N results" counts (`$wp_query->found_posts`) | `core/query-total` (WP 6.8+); on 6.6–6.7 a small plugin or render-filter block |
| `get_search_form()` | `<!-- wp:search /-->` |
| `the_posts_pagination()` | `<!-- wp:query-pagination -->…` inside the Query Loop |
| `while ( have_posts() )` loop | `<!-- wp:query {"query":{"inherit":true}} -->` + `<!-- wp:post-template -->` |

Template tags with no faithful core block:

| Classic | Gap | Fix |
|---|---|---|
| `if ( has_excerpt() ) the_excerpt();` | `core/post-excerpt` auto-generates from content | `render_block_core/post-excerpt` filter returning `''` when `! has_excerpt()`, opt-in via a block `className` |
| Modified date shown only when edited | `core/post-date` `displayType: modified` hides itself when never modified, but prefix text ("Last updated · %s") has no attribute | Filter or small dynamic block |
| `wp_link_pages()` | No block | `render_block_core/post-content` filter appending `wp_link_pages( array( 'echo' => 0 ) )` |
| Custom-logo fallback (initial letter) | `core/site-logo` renders nothing without a logo | `render_block_core/site-logo` filter returning the fallback markup |

Pattern: `add_filter( 'render_block_core/{name}', fn( $html, $block ) => …, 10, 2 )` in the theme for pure presentation; a plugin block when data or logic is involved. Make filters opt-in (check a `className` marker) so they do not change every instance.

Drop `wp_head()`, `wp_footer()`, `body_class()`, `language_attributes()`, `<!DOCTYPE>`, `<head>` — WordPress emits them for block themes.

## No text or theme assets in `.html` files

`.html` templates cannot call `__()` or `get_theme_file_uri()`. Hardcoded strings ("No posts found.", "Page not found") are untranslatable and fail WordPress.org review; hardcoded image paths break when the theme folder is renamed.

Rule: put every user-facing string and theme image in a pattern with `Inserter: no`, and reference it:

```html
<!-- wp:query-no-results -->
    <!-- wp:pattern {"slug":"mytheme/hidden-no-results"} /-->
<!-- /wp:query-no-results -->
```

Examples: `patterns/hidden-no-results.php`, `patterns/hidden-404.php`, `patterns/footer-default.php` (referenced from `parts/footer.html`). Strings rendered by dynamic blocks (comments title, pagination labels, search defaults) are already translated by core.

**Context blocks do not work inside hidden patterns:** `core/pattern` renders its content with `do_blocks()`, which drops the parent context (`postId`, `queryId`). `core/post-terms`, `core/comments-title`, `core/post-template`, and `core/query-pagination` inside a pattern render nothing or the wrong query. Keep only text and global blocks (paragraphs, headings, search, `core/post-navigation-link`) in hidden patterns; put context blocks directly in the template, or wrap the label in a small plugin block that reads context.

**Pattern PHP runs once per insertion.** When a part that references a pattern is saved in the Site Editor, the pattern's rendered output (including `date_i18n( 'Y' )`, the site name, or a theme-mod value) is written into the database copy and never updates again. For a copyright year in a theme without a plugin, a theme `render_block` filter on a marked paragraph (`className` `x-copyright-year`) replacing a `{year}` token is enough and stays presentation. For text from settings, bind a block to a Block Bindings source (pattern text becomes the fallback shown when the source is missing) or use a dynamic block.

## Code around page templates

- **Same slug:** the fallback is a tagged zip, not an installed theme, so remap at cut-over with a reversible command (store old values in a meta key) and make lookups accept both values until the fallback is retired.
- **New slug — do not remap `_wp_page_template` while the classic fallback exists:** the classic theme (and its `is_page_template()`-gated code) needs the old values. For pages seeded by slug, build `page-{slug}.html` — block template resolution falls through to it when the assigned PHP template does not exist in the block theme. Remap only when the fallback retires, and then update code that reads `_wp_page_template` or calls `is_page_template( 'x.php' )` in the same deploy. Verify that a REST save of such a page does not reject the stale `template` value.
- A PHP template of **higher specificity** than the matching block template still wins in a block theme (`locate_block_template()` keeps a more specific PHP file). A legitimate interim path for a few complex page templates or endpoint templates; list each as temporary.
- Partials composed with `include` that share variables, and shortcodes that rely on a global `WP_Query` a partial set up, cannot be split into independent blocks as is: pass the data explicitly (block attributes, `postId` context) when converting.
- Taxonomies registered on `page` and used to relate content ("list items sharing this page's terms") need a Query Loop variation whose PHP filter reads the current post's terms (`get_the_terms( get_queried_object_id(), … )`), not a fixed query.

## Markup injected by hooks

- UI printed through `wp_footer` / `wp_body_open` with `get_template_part()` (search palette, mobile bottom bar, age gate, progress bar) has no partial to include in a block theme: rebuild it as blocks in the footer/header part, or print it from the plugin on the same hook with its own markup.
- `body_class( 'extra classes' )` arguments in `header.php` are lost (core calls `body_class()` without arguments): use the `body_class` filter.
- `nav_menu_link_attributes`, `nav_menu_css_class`, `wp_nav_menu_items` never apply to `core/navigation-link`: port them to `render_block_core/navigation-link` (or `render_block` with `WP_HTML_Tag_Processor`).

## Title tag

Block themes output the title through the title-tag path. `wp_title()` calls and `wp_title` filters go dead; port custom title logic to `document_title_parts` / `pre_get_document_title` in the plugin, or home and archive titles change silently.

## Comments

`comments.php` + `comments_template()` map to the Comments block family, shown in `examples/block-theme/templates/single.html`:

| Classic | Block |
|---|---|
| `comments_template()` wrapper | `wp:comments` |
| Comment count heading | `wp:comments-title` |
| `wp_list_comments()` + callback | `wp:comment-template` containing `wp:avatar`, `wp:comment-author-name`, `wp:comment-date`, `wp:comment-content`, `wp:comment-reply-link` |
| `paginate_comments_links()` | `wp:comments-pagination` |
| `comment_form()` | `wp:post-comments-form` |

Custom `wp_list_comments` callbacks with extra markup become layout inside `wp:comment-template`. Custom comment fields (`comment_form_default_fields` filter) move to the companion plugin; the filter still applies to `wp:post-comments-form`.

## Stylesheets

- WordPress never enqueues `style.css` for any theme, classic or block. Port the classic theme's own enqueue — often a compiled file (`assets/css/theme.css`) rather than `style.css` — and add the same file with `add_editor_style()` so the editor matches. See `examples/block-theme/functions.php`.
- Move every rule `theme.json` can express out of `style.css`. Leftover block-specific rules go to `assets/css/blocks/{block}.css` loaded with `wp_enqueue_block_style()` — only on pages where the block appears.
- Never give `main` or a pattern wrapper a `className` that is also a component selector in the stylesheet (`.x-search` for the search form) — use a namespaced modifier (`x-main--search`). A real migration squeezed a whole search page, and a 404 page, into component-width columns this way.
- Audit class names reused on new wrappers: a classic selector (`.x-search` for the search form) attached to a different element in the block theme (`main.x-search`) inherits the old rules — a real migration squeezed a whole search page into a form-width column this way. Grep the stylesheet for every class added to templates and parts.
- Rename classic selectors to block classes (`.site-header` stays only if the part sets `className`; `.entry-title` → `.wp-block-post-title`).
- Classic `.alignwide`/`.alignfull` CSS conflicts with core layout styles; delete it and rely on `layout` + `useRootPaddingAwareAlignments`.

## Plain hand-written CSS (no build tool)

Triage instead of rewriting:
1. **Parity first:** keep the legacy stylesheet enqueued unchanged for the first release.
2. **Neutralize resets that break blocks:** `ul,li{list-style:none}`, `a{outline:none}`, `body{line-height:1}`, `*{margin:0}` — scope them away from block content (`:where(:not(.wp-block-post-content *))`) or remove them; restore focus outlines.
3. **Tokens:** move colors, fonts, and widths into `theme.json` from what is **actually printed** (live CSS), not from settings defaults.
4. **Peel later:** move rules to `theme.json` and per-block CSS over time; replace ID selectors as their elements become blocks.
5. **RTL:** keep the RTL sheet with `wp_style_add_data( $handle, 'rtl', 'replace' )`.
6. **Hand-concatenated JS bundles** (`app.js` = several sources): split per block (`viewScript`) or keep one front-end bundle enqueued only where its blocks render.
7. **Frozen generated CSS** (a Customizer CSS file with absolute production URLs): delete after its values move to `theme.json`.

## WooCommerce scope

Classify first: **content mentions only** (the word in copy) → not a marker; **integration only** (`add_theme_support( 'woocommerce' )`, `woocommerce_*` hooks, cart fragments, no `woocommerce/` folder) → move hooks to the plugin, restyle Woo blocks, low risk; **template overrides** (`woocommerce/*.php`) → high-risk marker as below.


WooCommerce ships its own block templates (`single-product.html`, `archive-product.html`, `page-cart.html`, `page-checkout.html`) that apply automatically in block themes. Classic `woocommerce/*.php` overrides stop applying to those views.
- In scope: list every classic override in Gate 1 as MANUAL; restyle WooCommerce blocks through `theme.json` (`styles.blocks["woocommerce/…"]`) and patterns.
- Out of scope: re-implementing override PHP logic. Hooks/filters used by overrides move to the companion plugin where they still apply; markup-level overrides are rebuilt with WooCommerce blocks or flagged for a WooCommerce specialist.

## Example: header.php → parts/header.html

- Before: `examples/classic/header.php`
- After: `examples/block-theme/parts/header.html`

Points to note:
- The part's root is a plain `<div>` group. The referencing `template-part` block carries `"tagName":"header"`, so the `<header>` element is emitted once. Making both the part root and the reference a `<header>` produces nested `<header>` landmarks.
- `has_custom_logo()` / site-title fallback becomes `wp:site-logo` + `wp:site-title {"level":0}` side by side. `wp:site-logo` renders nothing when no logo is set, so the title covers the fallback; drop the title block if the logo already contains the name.
- Do not hardcode a `ref` on `wp:navigation`. Leave it unset; WordPress attaches the primary menu or the editor picks one, and classic menus can be imported from the Navigation block.

## Example: classic loop → Query Loop

- Before: `examples/classic/archive.php`
- After: `examples/block-theme/templates/archive.html`

Rules:
- Use `"inherit":true` on archive, index, and search templates so the query follows the main request.
- Use `"inherit":false` with explicit `postType`, `perPage`, `taxQuery` only for secondary queries (e.g. "latest projects" section). Put those in patterns, not in the main template.
- `if ( have_posts() ) … else` becomes `wp:query-no-results` inside the query.
- Custom `WP_Query` arguments that the Query Loop UI cannot express (meta queries, complex ordering) go to the companion plugin, either via the `query_loop_block_query_vars` filter or a dynamic block.

## Post formats

`get_template_part( 'content', get_post_format() )` has no `.html` equivalent for single posts. Use one format-aware dynamic block in `single.html` and the Query Loop post template (`coded-metaboxes.md` → Post-format branching).

## Presentation-only PHP helpers

Breadcrumbs, readout panels, category browse lists, and similar template-tag output have no `.html` equivalent. Options:
1. Core blocks where they exist (`core/query-title`, `core/term-description`, `core/post-terms`, `core/categories`).
2. A pattern (`patterns/*.php` runs PHP at registration time — fine for static output, not per-request data).
3. A dynamic block. Registering blocks is plugin territory for WordPress.org themes; for private client themes, a theme-registered block is acceptable when it is pure presentation.

## Business logic inside templates

Templates that process input (a contact form handling `$_POST` before `get_header()`) move that handler to the plugin on `template_redirect` or `init`. The block template keeps the form markup (a pattern or block); the no-JS POST path must still work.

## Position-dependent loop layouts

"First 6 compact, items 7–9 as cards, rest compact" (classic `$wp_query->current_post` checks): keep one `core/post-template` and style by position with `:nth-child()` (`li:nth-child(n+7):nth-child(-n+9)`), scoped to page one with `body:not(.paged)` when needed. When markup (not only styling) differs, a `render_block_core/post-template` filter can rewrite items by index with `WP_HTML_Tag_Processor`. No plugin block needed.

## Inserting non-post items into a Query Loop

Option-driven ads or promos between posts (classic: a counter in the loop): a `render_block_core/post-template` filter, scoped by a `className` marker, splits the rendered HTML after the Nth `</li>` and inserts rendered blocks (`do_blocks()` of a pattern, or `render_block()` of a plugin block) — page one only or every page, per the classic behavior. The editor preview never shows the inserted items; say so to the client.

## Core block behavior that differs from classic templates

- **Attachments:** classic `single.php` often served attachment pages; a block theme needs `single-attachment.html` (an `attachment.html` makes core skip `prepend_attachment`, dropping the image).
- **Sticky posts in secondary queries:** a non-inherit Query block on a non-home view (404, page) still behaves as `is_home` for stickies and prepends them; set `"sticky":"ignore"` (WP 6.8+) or filter `query_loop_block_query_vars` on older targets.
- **Markup quirks to style against:** `core/post-navigation-link` renders its label outside the `<a>`; `core/comments-title` says "responses" and prints nothing at zero comments (port wording with a `render_block_core/comments-title` filter); custom Navigation links never get `aria-current` (add it in a `render_block_core/navigation-link` filter). Measure rendered core markup before writing CSS — never assume it.

## Custom routes and template lookups

- **Custom rewrite routes** rendered today by `template_include` → a PHP file: in a block theme ship `templates/{route}.html` and have the plugin return it — add the slug to the hierarchy via `{type}_template_hierarchy` filters (e.g. `index_template_hierarchy` for the route's query) so `locate_block_template()` finds it, or for plugin-owned templates register them with `register_block_template()` (WP 6.7+). Never point `template_include` at a PHP file in a block theme.
- **Code that queries or compares template filenames** (`meta_value = 'page-x.php'`, `is_page_template( 'x.php' )`, enqueue gates by template): list every occurrence and switch to block template slugs (accept both during coexistence).
- **`page-{id}.php` vs `page-{slug}.php`:** a numeric file name matches both the page ID and a page whose slug is that number. Convert to `page-{slug}.html` with the real slug, or a custom template.
- **Theme-defined actions inside templates** (`do_action( 'x_before_content' )`): unreachable from `.html`. For each, fire it from the block that replaces that region (`render.php`), or document it as removed.

## Views served by fallback

A missing template is a view too: no `404.php` means 404s render `index.php` (often with a wrong heading such as "Archives"). List each fallback view in the ASSESS and decide: reproduce for parity, or fix by adding `404.html` (record the decision).

## Conditional logic

Template PHP conditionals (`is_front_page()`, `is_user_logged_in()`, role checks) have no `.html` equivalent. Resolve each by:
1. Template hierarchy — `front-page.html`, `home.html`, `single-{post-type}.html`, `page-{slug}.html`.
2. Custom templates selectable per post (`customTemplates` in theme.json).
3. A dynamic block in the companion plugin when the condition is runtime (logged-in state, user role).

Classify every conditional that does not fit 1 or 2 as MANUAL in Gate 1.
