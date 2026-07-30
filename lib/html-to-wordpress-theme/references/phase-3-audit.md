# Phase 3 - Self-Audit & Documentation

Include this in the final chunk alongside documentation.

## Audit Table

For **every** item below:
- **PASS** - cite specific file(s), function(s), and the exact lines checked as evidence. A PASS without evidence is automatically downgraded to FAIL.
- **FAIL** - explain what's wrong, which file(s) are affected, and provide the complete fix (not just a description).
- **N/A** - justify why this check doesn't apply to this specific theme.

In the Evidence column, name the specific files examined for that row. Do not write "all files" - list them.

**Sharing evidence across rows.** When a single file cluster is the evidence for several consecutive checks (e.g. all PHP files for "every file has a docblock", "no stub functions", "tabs not spaces"), you may write the file list once on the first row and use `see #N` on later rows that share the same files. The check description must still be evaluated on the merits - `see #N` only avoids re-typing the file list, not re-doing the check. Do not use `see #N` across distant rows or across categories.

🚫 = blocker. Any blocker FAIL = automatic NO-GO.

| # | 🚫? | Category | Check | Status | Files Checked | Evidence / Fix |
|---|------|----------|-------|--------|---------------|----------------|
| 1 | | Process | Phase 1A and 1B completed and approved before any code generation | | | |
| 2 | 🚫 | Files | All files in manifest (⑪) are present, complete, and contain no stubs/TODOs | | | |
| 3 | | Files | Additional helpers created where HTML analysis demanded them | | | |
| 4 | 🚫 | WP | Correct template hierarchy usage (`index.php` as ultimate fallback) | | | |
| 5 | | WP | Text domain consistently equals `THEME_SLUG` in every translation call | | | |
| 6 | | WP | `THEME_PREFIX` on all custom functions, classes, hooks, constants, handles | | | |
| 7 | 🚫 | Security | Every dynamic output escaped with the correct function | | | |
| 8 | 🚫 | Security | `the_author()` never called directly - `esc_html( get_the_author() )` used instead | | | |
| 9 | | i18n | All user-facing strings wrapped in translation functions | | | |
| 10 | | i18n | `translators:` comments present on all `sprintf` translation strings | | | |
| 11 | | Setup | Theme supports registered in `after_setup_theme` (only those the design uses) | | | |
| 12 | | Setup | Menus registered via `register_nav_menus()` and rendered with `wp_nav_menu()` | | | |
| 13 | | Setup | Sidebars registered if design includes them, with correct wrapper HTML | | | |
| 14 | | Setup | Custom image sizes registered for all sizes identified in ⑦ | | | |
| 15 | | Setup | `$content_width` set at file scope in `functions.php` (not inside a hook) | | | |
| 16 | 🚫 | Assets | Zero Tailwind CDN references in any file | | | |
| 17 | 🚫 | Assets | Zero hardcoded `<link>` or `<script>` tags in any template | | | |
| 18 | 🚫 | Assets | Tailwind v3 CLI build pipeline complete and functional | | | |
| 19 | | Assets | Content paths in `tailwind.config.js` cover all PHP and JS files | | | |
| 20 | 🚫 | Assets | Compiled CSS outputs to `assets/css/theme.css` | | | |
| 21 | 🚫 | Assets | All CSS/JS enqueued via `functions.php` with version strings | | | |
| 22 | | Assets | Root `style.css` contains WP header comment only - zero CSS rules | | | |
| 23 | | Assets | Version strings use `filemtime()` with `file_exists()` guard or theme version constant | | | |
| 24 | | Arch | `header.php` and `footer.php` properly separated | | | |
| 25 | 🚫 | Arch | `wp_head()` called before `</head>` in `header.php` | | | |
| 26 | 🚫 | Arch | `wp_footer()` called before `</body>` in `footer.php` | | | |
| 27 | 🚫 | Arch | `wp_body_open()` called immediately after `<body>` in `header.php` | | | |
| 28 | | Arch | Repeated markup uses `get_template_part()` | | | |
| 29 | | Arch | Loop uses template parts with `get_post_type()` | | | |
| 30 | | Arch | Single post has dedicated content partial | | | |
| 31 | | Arch | File-level docblocks on every PHP file | | | |
| 32 | | Arch | Function docblocks on every custom function | | | |
| 33 | | Arch | `functions.php` is ≤150 lines with logic extracted to `inc/` | | | |
| 34 | | Arch | `functions.php` require order: functions → tags → navigation → widgets | | | |
| 35 | | Dynamic | Navigation fully dynamic - zero hardcoded links in menus | | | |
| 36 | | Dynamic | All post data uses WP template tags (not hardcoded) | | | |
| 37 | | Dynamic | Sidebar uses `dynamic_sidebar()` with `is_active_sidebar()` check | | | |
| 38 | | Dynamic | Search uses `get_search_form()` | | | |
| 39 | | Dynamic | Comments integrated with WP comment system | | | |
| 40 | | Pages | Pagination uses `the_posts_pagination()` with `mid_size` ≤ 3 | | | |
| 41 | | Pages | Archive, category, tag, search templates present and functional | | | |
| 42 | | Pages | 404 template present with search form and helpful content | | | |
| 43 | | Pages | Custom page templates in `template-pages/` if applicable | | | |
| 44 | | Design | Visual structure faithfully matches source HTML | | | |
| 45 | | Design | All design tokens from ⑤ captured in `tailwind.config.js` | | | |
| 46 | | Design | Utility classes preserved or correctly translated from source | | | |
| 47 | 🚫 | A11y | Skip-to-content link is first focusable element after `wp_body_open()` | | | |
| 48 | | A11y | Semantic landmarks: `<header>`, `<nav>`, `<main>`, `<aside>`, `<footer>` | | | |
| 49 | | A11y | Single `<h1>` per page with logical heading hierarchy | | | |
| 50 | | A11y | Keyboard-navigable menus and interactive elements | | | |
| 51 | | A11y | All form inputs have associated `<label>` elements | | | |
| 52 | | A11y | Current/active page states visually and programmatically indicated | | | |
| 53 | | A11y | Focus styles visible on all interactive elements | | | |
| 54 | | A11y | Touch targets ≥ 44×44 CSS px | | | |
| 55 | | A11y | Animations wrapped in `prefers-reduced-motion` media query | | | |
| 56 | | A11y | `aria-label` on nav elements when multiple navs exist | | | |
| 57 | | A11y | Color contrast ratios meet thresholds (or flagged with issues) | | | |
| 58 | | A11y | Non-hero images use `loading="lazy"`; hero images use `fetchpriority="high"` | | | |
| 59 | | Quality | JS is minimal and purposeful - no jQuery unless a dependency requires it | | | |
| 60 | | Quality | No duplicated markup blocks across templates | | | |
| 61 | | Quality | Only justified Tailwind plugins included (per ⑤) - no `@tailwindcss/aspect-ratio` | | | |
| 62 | | Quality | WordPress PHP Coding Standards followed (tabs, Yoda, spacing, braces) | | | |
| 63 | | Quality | Strict comparisons used (`===` / `!==`) unless intentional | | | |
| 64 | | Docs | Step-by-step setup instructions with copy-pasteable commands | | | |
| 65 | | Docs | All assumptions from ⑩ documented with final resolutions | | | |
| 66 | | Docs | Known limitations from error recovery compiled and documented | | | |
| 67 | | Docs | `screenshot-instructions.md` with exact dimensions and capture steps | | | |
| 68 | | Docs | License declared in `style.css` header and `README.md` | | | |
| 69 | | Docs | Testing checklist included in `README.md` (per § Testing Checklist below) | | | |
| 70 | | Docs | Source HTML limitations documented (if grade C or D) | | | |
| 71 | | Meta | `Generated by html-to-wordpress-theme skill` included in `README.md` | | | |
| 72 | | Assets | Content paths in `tailwind.config.js` match actual directory structure - no paths to nonexistent directories | | | |
| 73 | | Sync | `$content_width`, `theme.json` `contentSize`, and `tailwind.config.js` `maxWidth.content` all use the same value from ⑤ | | | |
| 74 | | Child | Overridable template tags wrapped in `function_exists()` per child-theme rules | | | |
| 75 | | Child | No anonymous closures on `add_action` / `add_filter` | | | |
| 76 | | Child | `get_template_directory()` / `get_template_directory_uri()` used (not `get_stylesheet_*`) | | | |
| 77 | | Assets | All scripts load in footer with `defer` strategy via WP 6.3+ `$args` array syntax (unless blocking is justified and commented) | | | |
| 78 | | Assets | No inline `<script>` blocks remain in any template file | | | |
| 79 | | Docs | Child Theme Support section included in `README.md` listing overridable functions and removable hooks | | | |
| 80 | | Optional | Customizer settings (if opted in) registered with proper `sanitize_callback` per setting; output via `get_theme_mod()` is escaped for context | | | |
| 81 | | Optional | Transient caching (if opted in) - TTL set, cache key namespaced with `{prefix}_`, invalidation hook registered (`save_post`, `customize_save_after`, etc.) | | | |
| 82 | | Optional | Reading time (if opted in) - handles empty content gracefully, formatted via `_n()` with `translators:` comment, cached via transient if caching opted in | | | |
| 83 | | Optional | Related posts (if opted in) - `WP_Query` with `no_found_rows`, excludes current post, cached via transient if caching opted in | | | |
| 84 | | Optional | Schema.org JSON-LD (if opted in) - emitted via `wp_json_encode()` (not string concatenation), conditional per page type, ISO 8601 dates, validated against Google's Rich Results Test (documented in README) | | | |
| 85 | | Optional | Social share buttons (if opted in) - vanilla server-built URLs (no third-party JS), each link has `rel="noopener noreferrer"`, accessible labels for icon-only links | | | |
| 86 | | Optional | Author bio box (if opted in) - only displays when `get_the_author_meta( 'description' )` is non-empty, bio escaped with `wp_kses_post`, archive link with `esc_url` | | | |
| 87 | | Optional | Last-updated date (if opted in) - diff threshold respected (default `DAY_IN_SECONDS`) so trivial edits don't trigger the label, marked up with `<time datetime="...">` | | | |
| 88 | | Optional | AJAX handlers (if opted in) - every endpoint calls `check_ajax_referer()` first, nonce localized to JS, non-JS fallback works (standard form / `the_posts_pagination()` still functional with JS disabled) | | | |
| 89 | | Optional | Custom shortcodes (if opted in) - atts parsed via `shortcode_atts()`, output escaped, callbacks return (not echo), each shortcode documented in `README.md` Shortcodes section | | | |
| 90 | | Optional | Plugin integrations (if opted in) - every external API call wrapped in `function_exists()` / `class_exists()` guards, integration scope documented in ⑨ and `README.md` Compatibility section | | | |

---

## Scoring & Verdicts

| Result | Criteria | Action |
|--------|----------|--------|
| ✅ **GO** | All blockers PASS + ≤ 3 non-blocker FAILs | Theme is ready. List any non-blocker FAILs as minor follow-ups. |
| ⚠️ **CONDITIONAL** | All blockers PASS + 4-8 non-blocker FAILs | List every FAIL with its fix. Offer to apply all fixes in one follow-up chunk. |
| ❌ **NO-GO** | Any blocker FAIL | List ALL failures (blocker and non-blocker). Provide fixes for each per Change Management Protocol. Offer to regenerate affected files. |

---

## Testing Checklist (for README.md)

The generated `README.md` must include this testing checklist (adapted to the specific theme's features):

````markdown
## Testing Checklist

After installing and activating the theme, verify:

### Core Functionality
- [ ] Theme activates without PHP errors or warnings
- [ ] Homepage displays posts correctly
- [ ] Single post page renders with correct layout
- [ ] Static pages render correctly
- [ ] Navigation menus are assignable in Appearance → Menus
- [ ] All registered menu locations appear in wp-admin

### Widgets & Sidebars
- [ ] Widget areas appear in Appearance → Widgets
- [ ] Widgets render correctly on front end
- [ ] Empty sidebars hide gracefully (no broken layout)

### Content Features
- [ ] Featured images display at correct sizes
- [ ] Post pagination works (older/newer posts)
- [ ] Category and tag archive pages work
- [ ] Author archive pages work
- [ ] Date-based archive pages work
- [ ] Search returns results correctly
- [ ] Search with no results shows helpful message + retry form
- [ ] 404 page displays for invalid URLs
- [ ] Comments form appears on single posts (if enabled)
- [ ] Comments display threaded/nested correctly
- [ ] Custom page templates appear in Page Attributes → Template (if applicable)

### Responsive & Accessibility
- [ ] Layout is responsive at 320px, 640px, 768px, 1024px, 1280px
- [ ] Mobile menu opens and closes correctly
- [ ] Mobile menu is keyboard accessible (Tab, Escape)
- [ ] Skip-to-content link appears on Tab focus
- [ ] All interactive elements have visible focus styles
- [ ] Screen reader testing passes basic checks (landmarks, headings, labels)
- [ ] Images outside hero area load lazily (check Network tab)

### Build System
- [ ] `npm install` completes without errors
- [ ] `npm run build` compiles CSS to assets/css/theme.css
- [ ] `npm run watch` rebuilds on PHP/CSS changes
- [ ] No Tailwind CDN references in page source
````
