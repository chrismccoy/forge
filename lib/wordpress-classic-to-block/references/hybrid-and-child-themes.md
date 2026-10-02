# Hybrid Path and Child Themes

## Hybrid path (stepping stone)

Choose hybrid when the go/no-go is high-risk (heavy WooCommerce overrides, page builder, many MANUAL templates) but the client wants block tooling now. A hybrid theme stays a classic theme (PHP templates, Customizer, widgets) and adopts block features incrementally.

| Step | Mechanism | Effect |
|---|---|---|
| 1 | Add `theme.json` to the classic theme | Presets, Global Styles subset, editor matches front end. No template change. |
| 2 | `add_theme_support( 'block-template-parts' )` (WP 6.1+) + `parts/header.html` | Appearance → Template Parts lets editors edit the header/footer as blocks |
| 3 | Render parts from PHP: `block_template_part( 'header' );` in `header.php` | Classic templates output block-based parts |
| 4 | Move logic to the companion plugin (Gate 5) | Same as full migration — independent of theme type |
| 5 | Add `templates/index.html` | Theme becomes a block theme; continue with Gate 3 for remaining templates |

Each step ships independently. Step 5 is the cut-over and is where Gate 6 applies in full.

Caveats:
- Until step 5, the Site Editor shows only Styles and Template Parts, not templates.
- Widgets and Customizer remain available in the hybrid state, so site-state migration (`site-state-migration.md`) can wait until step 5.

## Rebuild path

When the go/no-go says Rebuild, the plan keeps the **contracts** and replaces the implementation:
- **Preserved:** meta/term/option keys and shapes (until the fallback retires), URLs and rewrite rules, feeds, REST routes, page slugs, menu and widget content (migrated), SEO output.
- **Replaced:** templates, front-end CSS and JS, and edit-screen field UI. Admin tool screens move unchanged.
- **Reused:** in utility-CSS themes, the classic template markup is the starting point for each block's `render.php` and the compiled utility CSS ships scoped under a wrapper — exact parity at the lowest cost.
- **Rebuild vs High-risk:** both execute plugin-first. Rebuild additionally starts templates from the live design instead of converting classic templates one by one, and budgets the editor switch and data audits as their own phase.
- **Phases:** (0) tag, inventory, data audits (shapes, corruption) → (1) plugin data layer + migrations, coexisting with the classic theme → (2) design tokens and block theme scaffold from the live design (printed CSS; screenshots for hand-written CSS themes) → (3) blocks per component from the risk register → (4) parity review and cut-over. Plugin-first still applies.

## Estimating, version control, slug choice

Moved to `assess-reference.md`.

## Child themes

### Classic child of a classic parent

Migrate the parent first. Then rebuild the child as a block child theme containing only its delta.

### Block child theme structure

```text
mytheme-child/
  style.css      ← header with "Template: mytheme" (parent folder name)
  theme.json     ← partial; merges over the parent's theme.json
  templates/     ← only templates that differ from the parent
  parts/         ← only parts that differ
  patterns/      ← additional patterns
  styles/        ← additional variations
  functions.php  ← optional
```

Example: `examples/child-theme/` (palette override only).

Rules:
- A child file with the same name replaces the parent file entirely (templates, parts). There is no partial merge for markup — copy then edit.
- `theme.json` merges key by key; presets with the same slug override parent values.
- Classic child CSS overrides become `theme.json` values or per-block CSS. Classic child PHP template overrides become `.html` templates.
- Child themes do not enqueue the parent `style.css` with `@import`; enqueue explicitly from `functions.php` if the parent's stylesheet is needed.
