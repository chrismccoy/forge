# Anti-patterns — Full List

Flag each when seen, explain the consequence, and refuse to proceed past the critical ones (marked in `SKILL.md`) until resolved.

- **Hardcoded hex colors or font sizes in block markup.** Use preset slugs.
- **CPTs, metaboxes, or shortcodes left in `functions.php`.** Content structure that vanishes on theme switch means an incomplete migration. Offer to build the companion plugin first.
- **"Move the CPTs later."** Logic stays in the theme until it causes an incident. Move it during migration.
- **Page builder markup converted verbatim.** Flag MANUAL; rebuild section by section with patterns.
- **`theme.json` version 1 or 2 on WP 6.6+.** Use version 3.
- **Big-bang migration without a tagged fallback.** Refuse until the classic theme is committed and tagged.
- **Enqueues or PHP inside `.html` templates.** HTML templates never execute PHP; enqueue from `functions.php` or the plugin.
- **Custom `WP_Query` or `get_post_meta()` in theme templates.** Use Query Loop attributes, Block Bindings, or a plugin dynamic block.
- **Migrating ACF fields to `register_post_meta()` when ACF PRO 6.3+ is installed.** Redundant; use ACF's binding source.
- **Renaming a meta key without migrating existing data.** Incomplete until the CLI migration runs and is spot-checked.
- **Migrating from the metabox form instead of the save handler.** The handler defines keys, sanitizers, and empty behavior.
- **Legacy metaboxes left active beside a panel for the same key.** The metabox POST overwrites the panel value.
- **Building complex-field UI before choosing storage.** Decide meta vs attribute vs child blocks vs option first.
- **Client-side-only validation.** `lockPostSaving` is UX; re-validate in REST.
- **Large React applications** (wizards, drag-and-drop builders). Out of scope; flag MANUAL.
- **Theme-enqueued jQuery for menus or accordions.** Use the Navigation overlay and `core/details`.
- **Hardcoded text or theme image paths in `.html` templates.** Untranslatable and fragile; use hidden patterns.
- **New color-named slugs (`white`, `blue`).** Break under style variations; new slugs are role-based. Existing slugs already used in saved content stay (see `theme-json.md`).
- **Assuming a stylesheet loads by itself.** No theme gets `style.css` enqueued automatically; port the classic enqueue.
- **Porting block-feature sabotage.** Filters that disable the block editor, dequeue block CSS, or unhook global styles are deleted, never carried over. A justified exception (one CPT kept on the classic editor because its body is Markdown or raw text) is recorded with its reason and marked `static-checks:allow`.
- **Removing one metabox while another still relies on its nonce.** Boxes sharing a nonce leave together.
- **Porting security holes verbatim.** Unsanitized saves and unescaped output get fixed and recorded as deviations.
- **Copying example allowlists.** Allowlists, sanitizers, and keys come from the theme's own handler, verbatim.
- **Theme that breaks without the companion plugin, undeclared.** Choose the plugin dependency model (Gate 5) and document it.
- **Deploying file changes over Site Editor customizations.** Check and reset or export database copies first.
- **Switching themes without exporting site state.** Additional CSS, widgets, and menu locations do not carry over; theme mods survive only under the same folder slug (`site-state-migration.md`).
