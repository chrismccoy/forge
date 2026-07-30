# Phase 1 - Analysis & Planning

Read the provided `index.html` and `single.html` (and any additional HTML files confirmed during the Initialization Gate). Produce the analysis in two sub-phases. **Do not skip any section.**

---

## Phase 1A - Critical Analysis

This sub-phase covers the HTML validation, source quality assessment, and the most critical structural analysis sections. It must be completed in a single response.

### HTML Validation Report

Scan every provided HTML file. For each issue, output a row:

| File | Line/Selector | Issue | Category | Severity | Proposed Fix |
|------|--------------|-------|----------|----------|-------------|
| index.html | `<img class="hero">` | Missing alt attribute | A11y | Must fix | Add descriptive alt or alt="" if decorative |
| index.html | `<div style="color:red">` | Inline style | Maintainability | Should fix | Extract to Tailwind class |
| ... | ... | ... | ... | ... | ... |

**Categories to check:**
- Malformed / unclosed tags
- Missing alt attributes on all images
- Inline styles (must extract to Tailwind classes or `src/input.css`)
- Embedded `<style>` blocks (must extract rules to `src/input.css` custom layers, then remove the `<style>` tags)
- Missing form labels
- Hardcoded navigation links
- CDN references (list every `<link>` and `<script>` with external URLs)
- JavaScript framework dependencies (Alpine.js, HTMX, jQuery, React, Vue)
- Tailwind v4 syntax that needs v3 conversion
- Hardcoded content that implies CPTs, custom fields, or dynamic data
- Color pairs that appear to violate WCAG contrast ratios (estimate ratios)
- Missing language attributes, viewport meta, charset declaration
- Duplicate IDs
- Non-semantic markup (e.g. `<div>` where `<nav>`, `<main>`, `<article>` is appropriate)
- Missing `wp_head()`/`wp_footer()`-equivalent insertion points

**Severity levels:**
- **Blocker** - Cannot proceed without resolution. Request corrected files or user decision.
- **Must fix** - Will be fixed during implementation. No user action needed.
- **Should fix** - Recommended improvement. Implement unless user objects.
- **Info** - Noted for documentation. No action required.

If any **Blocker** issues exist, stop and request resolution before continuing.

---

### Source Quality Assessment

After the validation report, provide an overall source quality grade:

| Grade | Criteria | Action |
|-------|----------|--------|
| **A** | Clean semantic HTML, proper class structure, minimal issues | Proceed normally |
| **B** | Minor issues (a few missing alts, some inline styles, minor semantic gaps) | Proceed normally, fix during implementation |
| **C** | Significant issues (many inline styles, poor semantics, mixed frameworks, several accessibility gaps) | Warn user: "Source HTML has significant quality issues. Output theme will require extra post-generation review. Specific concerns: [list]." Proceed if user confirms. |
| **D** | Major structural problems (mostly inline styles, no class structure, broken HTML, no clear content hierarchy) | Warn user: "Source HTML quality is low. I can proceed, but the resulting theme will have documented limitations. Alternatively, you can improve the source HTML first. Specific problems: [list]." Proceed only with explicit user confirmation. |

If grade is C or D, all quality compromises must be documented in the final README under a "Source HTML Limitations" section.

---

### Structured Analysis (Critical Sections)

Produce ALL of the following sections. Number them exactly as shown. Section ③ (Sidebar & Widget Regions) is intentionally deferred to Phase 1B because it depends on the content map produced in ④.

---

#### ① Template Mapping

Apply the **Source HTML → WordPress Template Mapping** convention from the Initialization Gate (in `SKILL.md`) as the starting point. Each provided HTML file becomes the design source for its corresponding WordPress template; templates without a matching HTML file are derived from the closest available source per the convention's fallback rules (e.g. missing `single.html` derives from `index.html`, missing `archive.html` derives from `index.html`, missing `category.html` falls back to `archive.html`, etc.).

Then break each provided HTML file down into its distinct content regions and map them:

| HTML Section (selector / description) | Source File | WP Template File | Template Part (if any) | Notes |
|---------------------------------------|-------------|-------------------|------------------------|-------|
| ... | ... | ... | ... | ... |

Include every distinct content region from every provided HTML file. The "Source File" column makes the mapping convention auditable - anyone reading the analysis can see which template was driven by which provided HTML and which were derived by fallback.

**Custom page templates:** Any HTML file whose name doesn't match a standard WordPress template (i.e. not `index`, `single`, `page`, `archive`, `category`, `tag`, `search`, `404`, or `comments`) becomes a custom page template stored in `template-pages/template-{name}.php` with a `Template Name:` header comment. Add these to the file manifest (⑪). Examples: `landing.html` → `template-pages/template-landing.php` with `Template Name: Landing`; `contact.html` → `template-pages/template-contact.php` with `Template Name: Contact`.

---

#### ② Navigation Inventory

For each navigation region found in the HTML:

| Nav Location | HTML Selector | Menu Type | Mobile Pattern | Walker Needed? |
|-------------|--------------|-----------|----------------|---------------|
| Primary | `<nav class="main-nav">` | Horizontal + dropdowns | Hamburger slide-out | See decision below |
| Footer | `<nav class="footer-nav">` | Simple horizontal | N/A | No |
| ... | ... | ... | ... | ... |

**Walker Decision Tree** - apply these questions to each row above where "Walker Needed?" is not yet determined:

| Question | Answer |
|----------|--------|
| 1. Does the HTML menu use nested elements beyond `<ul><li><a>`? | Yes/No |
| 2. Are there non-anchor elements inside `<li>` (icons, descriptions, badges)? | Yes/No |
| 3. Do dropdowns require wrapper `<div>`s not producible by default WP `wp_nav_menu()` args? | Yes/No |
| 4. Does the design use mega-menus or multi-column dropdowns? | Yes/No |
| 5. Does the menu need different markup at different depths (e.g. top-level horizontal, second-level vertical dropdown, third-level flyout)? | Yes/No |

- If ANY answer is Yes → custom walker required. Document which triggered it.
- If ALL answers are No → CSS/args only. No walker.
- If Q4 is Yes → custom walker required AND note that mega-menu markup will need `$args` passed through the walker. Flag complexity in ⑨.
- If Q5 is Yes → custom walker required with depth-aware output logic. Document each depth's expected markup in ⑨.

**Mobile menu specification:**
- Trigger element (hamburger button) requirements
- Animation type (slide, overlay, accordion)
- Keyboard interaction model (Escape to close, focus trapping)
- ARIA attributes needed (`aria-expanded`, `aria-controls`, `aria-hidden`)

---

#### ④ Content Mapping

| Static Element (selector) | WP Dynamic Replacement | Escaping Method | Notes |
|--------------------------|----------------------|----------------|-------|
| `<h2>Post Title</h2>` | `the_title()` | Self-escaping | ... |
| `<span class="author">John</span>` | `get_the_author()` | `esc_html()` | ... |
| `<img src="placeholder.jpg">` | `the_post_thumbnail()` | Self-escaping | Register custom size |
| ... | ... | ... | ... |

Map every piece of content that will become dynamic. Miss nothing.

---

#### ⑤ Design Token Extraction

| Token Type | Values Found | Tailwind Config Key | Custom? |
|-----------|-------------|-------------------|---------|
| Primary color | #1a1a2e | `colors.primary` | Yes - extend |
| Body font | Inter, sans-serif | `fontFamily.sans` | Override default |
| Heading font | Playfair Display, serif | `fontFamily.heading` | Yes - extend |
| Content max-width | 1200px | `maxWidth.content` | Yes - extend |
| Border radius (cards) | 12px | `borderRadius.card` | Yes - extend |
| Custom shadow | 0 4px 6px rgba(0,0,0,0.1) | `boxShadow.card` | Yes - extend |
| Custom breakpoint | none / 1440px | `screens.2xl` | Only if non-default |
| Transition duration | 300ms | `transitionDuration.DEFAULT` | Only if non-default |
| Animation keyframes | fade-in, slide-up | `keyframes.*`, `animation.*` | Document each |
| Z-index scale | modal: 50, dropdown: 40, header: 30 | `zIndex.*` | Document each |
| ... | ... | ... | ... |

**Font loading strategy:**
- List every font family used
- For each: Google Fonts URL, self-hosted files, or system font
- Loading method: `wp_enqueue_style()` with `display=swap` or `@import` in `src/input.css`
- Recommend `font-display: swap` for all custom fonts

**Required Tailwind v3 plugins:**

| Plugin | Needed? | Justification |
|--------|---------|---------------|
| `@tailwindcss/typography` | Yes/No | Needed for prose styling on post content / Not needed because... |
| `@tailwindcss/forms` | Yes/No | Needed for form reset styling / Not needed because... |
| `@tailwindcss/container-queries` | Yes/No | Needed for component-level responsive / Not needed because... |

> **Note:** Do NOT include `@tailwindcss/aspect-ratio`. Native `aspect-*` utilities built into Tailwind v3.2+ make this plugin unnecessary.

---

#### ⑨ Decision Log

| # | Decision | Options Considered | Chosen | Rationale |
|---|----------|-------------------|--------|-----------|
| 1 | Nav walker | Custom walker vs. CSS/args-only | ... | Based on § ② decision tree |
| 2 | Sidebar approach | Widget area vs. hardcoded | ... | ... |
| 3 | Font loading | wp_enqueue_style vs. @import in input.css | ... | ... |
| 4 | Comment template | Custom callback vs. default | ... | ... |
| ... | ... | ... | ... | ... |

**Optional WordPress features:** Each item the user opted into during the Initialization Gate (Customizer settings, transient caching, reading time, related posts, Schema.org JSON-LD, social share, author bio, last-updated date, AJAX comments/pagination, custom shortcodes, plugin integrations, anything else) gets its own row here documenting the user's choice and the implementation approach (which file it lives in, which WP API it uses, any caching/invalidation strategy). Items the user did NOT opt into don't appear here - they're simply absent from the theme.

---

#### ⑩ Ambiguities & Assumptions

| # | Assumption or Ambiguity | Proposed Resolution | Needs User Input? |
|---|------------------------|--------------------|--------------------|
| 1 | No 404 page in source HTML | Create minimal styled 404 matching theme tokens | No |
| 2 | Sidebar content looks like it could be a CPT | Implement as widget area unless user says otherwise | Yes |
| ... | ... | ... | ... |

**Every row marked "Yes" in the last column MUST be answered by the user before proceeding to Phase 1B or Phase 2.**

---

#### ⑪ File Manifest

| File Path | Purpose | Chunk | Conditional? |
|-----------|---------|-------|--------------|
| `style.css` | WP theme header comment (zero CSS rules) | 1 | No |
| `functions.php` | Theme setup, enqueues, includes (≤150 lines - logic in inc/) | 1 | No |
| `package.json` | Tailwind build config | 1 | No |
| `tailwind.config.js` | Design tokens and content paths | 1 | No |
| `src/input.css` | Tailwind directives + custom CSS | 1 | No |
| `.editorconfig` | Editor consistency settings | 1 | No |
| `inc/template-functions.php` | Helper/utility functions (return values, not markup) | 1 | No |
| `inc/template-tags.php` | Template tag functions (output markup directly) | 1 | No |
| `inc/widgets.php` | Widget registrations | 1 | Only if theme has widget areas |
| `inc/navigation.php` | Walker class | 1 | Only if walker required (see ②) |
| `inc/customizer.php` | Customizer options | 1 | Only if opted into in Initialization Gate |
| `inc/schema.php` | Schema.org JSON-LD output (in `wp_head`) | 1 | Only if opted into in Initialization Gate |
| `inc/shortcodes.php` | Custom shortcode registrations | 1 | Only if opted into in Initialization Gate |
| `inc/ajax-handlers.php` | AJAX endpoints for comments/pagination + nonce verification | 1 | Only if opted into in Initialization Gate |
| `inc/plugin-compat.php` | Plugin-integration shims (ACF, Yoast, WPForms, etc.) | 1 | Only if opted into in Initialization Gate |
| `theme.json` | Block editor settings | 1 | Yes - minimal by default |
| `header.php` | Site header + opening tags | 2 | No |
| `footer.php` | Site footer + closing tags | 2 | No |
| `sidebar.php` | Sidebar template | 2 | Only if theme has sidebar |
| `index.php` | Main fallback / archive | 2 | No |
| `single.php` | Single post | 2 | No |
| `page.php` | Static page | 2 | No |
| `comments.php` | Comments template | 2 | No |
| `archive.php` | Date/author archives | 3 | No |
| `category.php` | Category archive | 3 | No |
| `tag.php` | Tag archive | 3 | No |
| `search.php` | Search results | 3 | No |
| `searchform.php` | Custom search form | 3 | Only if source HTML has search markup not achievable via `get_search_form()` args alone |
| `404.php` | Not found page | 3 | No |
| `template-parts/content.php` | Archive post card | 4 | No |
| `template-parts/content-single.php` | Full single post | 4 | No |
| `template-parts/content-page.php` | Page content | 4 | No |
| `template-parts/content-none.php` | No results | 4 | No |
| `template-parts/pagination.php` | Pagination block | 4 | No |
| `template-parts/author-bio.php` | Author bio box (avatar + name + bio + archive link) | 4 | Only if opted into in Initialization Gate |
| `template-parts/social-share.php` | Social share button row | 4 | Only if opted into in Initialization Gate |
| `template-parts/related-posts.php` | Related posts list | 4 | Only if opted into in Initialization Gate |
| `template-pages/template-{name}.php` | Custom page template | 4 | Only if unique page layouts exist |
| `js/navigation.js` | Mobile menu + keyboard nav | 4 | No |
| `js/ajax-comments.js` | AJAX comment loading | 4 | Only if opted into in Initialization Gate |
| `js/ajax-pagination.js` | AJAX archive/search pagination | 4 | Only if opted into in Initialization Gate |
| `screenshot-instructions.md` | How to create screenshot.png | 5 | Only if no screenshot.png provided |
| `screenshot-placeholder.txt` | Reminds developer to add screenshot.png | 5 | Only if no screenshot.png provided |
| `CHANGELOG.md` | Release history starting with 1.0.0 | 5 | No |
| `README.md` | Setup instructions + documentation | 5 | No |

**`functions.php` size rule:** `functions.php` must contain only `define()` constants, `require` statements, and `add_action()` calls. All other logic must be extracted to files in `inc/`. Target: under 150 lines.

The 150-line target counts non-blank, non-comment lines only (docblocks, blank lines, and inline comments are excluded from the count). If `functions.php` would exceed 150 non-blank, non-comment lines even after extracting all logic to `inc/`, document the reason in ⑨ Decision Log and proceed. This is a strong guideline, not a blocker - complex themes with many hook registrations may legitimately exceed it.

Flag any additional file beyond this set and justify its inclusion. Remove any conditional file that isn't needed and justify its removal.

**Do NOT create `singular.php`.** Use `single.php` and `page.php` separately so each can have a distinct layout tailored to its content type.

---

### Phase Gate 1A

**STOP.** Output the critical analysis above. Do NOT generate code or proceed to Phase 1B.

Wait for the user to reply. Any message that does not explicitly ask for changes or corrections is treated as approval to proceed. If the user asks a clarifying question, answer it and then ask: "Shall I continue to Phase 1B?"

All ambiguities marked "Needs User Input? Yes" in ⑩ **must** be resolved before proceeding. If the user says "continue" without answering them, ask again before moving forward.

---

## Phase 1B - Extended Analysis

This sub-phase covers supporting analysis sections that build on the approved critical analysis.

### Structured Analysis (Extended Sections)

---

#### ③ Sidebar & Widget Regions

| Region | HTML Selector | Current Static Content | WP Implementation | Empty Fallback |
|--------|--------------|----------------------|-------------------|---------------|
| ... | ... | ... | `register_sidebar()` / static | Hide region / show defaults |

For each registered sidebar, specify the `before_widget`, `after_widget`, `before_title`, `after_title` HTML that matches the source design.

---

#### ⑥ Interactive Behavior Inventory

| Interaction | HTML Source Implementation | WP-Compatible Strategy | File |
|-------------|--------------------------|----------------------|------|
| Mobile nav toggle | Inline `onclick` handler | Vanilla JS event listener | `js/navigation.js` |
| Dropdown menus | CSS `:hover` only | Add keyboard support (Enter/Space/Escape) | `js/navigation.js` |
| Scroll to top | None present | Add if user wants | `js/scroll-top.js` |
| ... | ... | ... | ... |

For each interaction, specify:
- Trigger event(s)
- ARIA state changes
- Keyboard support required
- `prefers-reduced-motion` handling (if animation involved)

---

#### ⑦ Image Handling Plan

| Image in Source HTML | Type | WP Handling | Registered Size? | Notes |
|---------------------|------|-------------|------------------|-------|
| Hero banner | Featured image | `the_post_thumbnail( 'flavor-studio-hero' )` | Yes: 1920×800, hard crop | fetchpriority="high" |
| Post card thumbnail | Featured image | `the_post_thumbnail( 'flavor-studio-card' )` | Yes: 600×400, hard crop | loading="lazy" |
| Author photo | Avatar | `get_avatar( ..., 48 )` | No - core handles | ... |
| Logo | Site identity | `the_custom_logo()` | N/A | Register custom-logo support |
| Decorative divider | Static asset | `assets/images/` | N/A | Use `alt=""` |
| ... | ... | ... | ... | ... |

---

#### ⑧ Comments Specification

| Aspect | Implementation |
|--------|---------------|
| Design exists in source HTML? | Yes (describe) / No (create minimal design matching theme) |
| Comment list structure | `wp_list_comments()` with callback / without |
| Comment form fields | Map source form fields to `comment_form()` args |
| Nested/threaded support | Yes - depth from Settings |
| Gravatar display | Yes - size Npx / No |
| States to handle | Open + has comments, Open + zero comments, Closed, Password-protected |

---

#### ⑫ theme.json Recommendation

| Question | Answer |
|----------|--------|
| Include `theme.json`? | Yes - minimal by default |
| Rationale | Controls block editor width and prevents default block styles from conflicting with Tailwind |
| Conflict risk with Tailwind | [Describe any token duplication or style override concerns] |
| Scope | `settings.layout` (contentSize, wideSize) at minimum. Optionally `settings.color` and `settings.typography` if block editor use is expected. |
| Custom templates | [List any block template definitions] |
| `appearanceTools` | `false` unless user explicitly needs them |
| Child theme compatibility | The minimal `theme.json` is designed to be safely extended by child themes. Avoid overly restrictive settings that would require a child theme to override rather than extend. Prefer `false` over empty arrays for disabling features, so child themes can re-enable cleanly. |

If `theme.json` is included, follow these rules:
- Color palette in `theme.json` must mirror Tailwind config tokens exactly
- Typography settings must match Tailwind font config
- Layout `contentSize` and `wideSize` must match Tailwind max-width values
- Set `appearanceTools` to `false` unless user explicitly needs them
- Never define spacing presets that conflict with Tailwind spacing scale
- Include only `settings` - no `styles` section (Tailwind handles all styling)

**Minimal `theme.json` baseline** (always include unless user opts out):

```json
{
	"$schema": "https://schemas.wp.org/trunk/theme.json",
	"version": 2,
	"settings": {
		"appearanceTools": false,
		"layout": {
			"contentSize": "1200px",
			"wideSize": "1280px"
		},
		"color": {
			"custom": false,
			"defaultPalette": false,
			"defaultGradients": false
		},
		"typography": {
			"customFontSize": false,
			"dropCap": false
		},
		"spacing": {
			"padding": false,
			"margin": false,
			"units": []
		}
	}
}
```

Adjust `contentSize` and `wideSize` values to match design tokens from ⑤.

---

### Phase Gate 1B

**STOP.** Output the extended analysis above. Do NOT generate any code.

Present the proposed chunk plan (see `phase-2-implementation.md` § Chunk Planning) at the end of this response.

Wait for the user to reply. Any message that does not explicitly ask for changes or corrections is treated as approval to proceed. If the user asks a clarifying question, answer it and then ask: "Shall I continue to Chunk 1?"

---

## Abort & Degraded Mode Criteria

### Abort Criteria

**If any of the following are true, refuse to proceed and explain why.** These override all other instructions.

| # | Condition | Reason |
|---|-----------|--------|
| 1 | Source HTML is a compiled SPA (React, Vue, Angular, Svelte) | Cannot meaningfully convert framework-rendered output to PHP templates |
| 2 | Source HTML relies on server-side rendering from another framework (Next.js, Nuxt, Laravel Blade) | Template logic is framework-specific and not portable |
| 3 | Source HTML is primarily Web Components (`<custom-element>`) | Shadow DOM is incompatible with WordPress template architecture |
| 4 | More than 80% of source HTML is inline styles with no class structure | No meaningful Tailwind conversion possible - requires redesign |
| 5 | Source HTML has no discernible content structure (no headings, no articles, no sections) | Cannot map to WordPress template hierarchy |
| 6 | User requests functionality that requires a plugin (e-commerce, LMS, membership) and it cannot be reasonably implemented in theme code | Themes must not replicate plugin territory per WP guidelines |

For borderline cases, explain the concern to the user and ask how they'd like to proceed rather than silently aborting.

---

### Degraded Mode Triggers

If source HTML has significant quality issues that do NOT meet abort thresholds but materially impact conversion quality, enter **Degraded Mode** instead of aborting.

#### Degraded Mode Triggers

| # | Condition | Impact |
|---|-----------|--------|
| 1 | 40-80% inline styles with minimal class structure | Tailwind conversion will be approximate; many custom utilities needed |
| 2 | 15+ unclosed or malformed HTML tags | Template splitting may introduce rendering bugs |
| 3 | Mixed CSS frameworks (e.g. Bootstrap classes + Tailwind classes) | Must normalize to Tailwind only; visual discrepancies likely |
| 4 | Heavy reliance on JavaScript framework features (Alpine.js directives, HTMX attributes) without clear vanilla JS fallback | Interactive features will be simplified or reduced |
| 5 | No responsive/mobile styles in source HTML | Mobile layout will be best-effort based on content structure |
| 6 | Extensive use of absolute positioning / pixel-based layouts | Responsive behavior will require significant rework |
| 7 | Source HTML mixes multiple unrelated page designs in a single file | Template separation will require assumptions about content boundaries |

#### Degraded Mode Protocol

When any trigger above is detected:

1. **Present a Source Quality Assessment** with grade C or D
2. **List every triggered condition** with specific examples from the HTML
3. **Warn the user explicitly:**

> **Degraded Mode Warning**
>
> The source HTML has the following quality issues that will limit conversion fidelity:
>
> - [List each triggered condition]
>
> **Options:**
> 1. **Proceed anyway** - I'll do my best, but the resulting theme will have documented limitations in the README under "Source HTML Limitations."
> 2. **Provide improved source HTML** - Fix the issues listed above and re-submit. I can give specific guidance on what to change.
> 3. **Proceed with specific compromises** - Tell me which issues you accept and which you'd like me to prioritize fixing.

4. **If the user chooses to proceed:**
   - Document every compromise in the Phase 1 analysis (⑩ Ambiguities)
   - Add a `## Source HTML Limitations` section to `README.md` listing every quality compromise and its impact on the final theme
   - During the self-audit, mark affected items with a note: `"Limited by source HTML quality - see README § Source HTML Limitations"`

5. **If the user chooses to provide improved HTML:**
   - Provide specific, actionable guidance for each issue
   - Wait for the updated files
   - Re-run the Initialization Gate from the beginning
