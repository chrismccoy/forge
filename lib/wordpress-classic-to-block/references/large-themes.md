# Large Themes (> ~60 PHP files or > ~15k PHP lines)

ASSESS and MIGRATE rules that change with size. Smaller themes ignore this file.

## Reading strategy

Above ~150 files or ~15k PHP lines, one context cannot read the theme. Split by top-level area into 4–6 parallel readers (views/parts; admin + CLI; options/metaboxes/widgets; CPT/REST/routing/importers; setup/SEO/media/infra/assets). Each reader returns **rows, never file contents**, in this schema so the results paste straight into the ASSESS:

| Table | Columns |
|---|---|
| T0 Modules | module (dir or file group) · files · lines · bucket(s) · views it renders · notes |
| T1 Key families | family pattern · storage · count · saved at · read at · live? |
| T2 Hooks | module · hook names registered (actions, filters, cron, REST, CLI) · custom `apply_filters`/`do_action` names |
| T3 Templates/views | view · template file · partials · MANUAL reason (own, not inherited) |
| T4 Risks | risk · module · evidence `file:line` |
| T5 Counts | CPTs, taxonomies, REST routes, settings, CLI commands, cron hooks, widgets, shortcodes, blocks |

Run `scripts/static-checks.sh` in classic mode first; its signal counts tell each reader what to expect.

## Gate 1 per module

- One row per **module** (a directory or a file group with one job); per-file rows only for MANUAL views and one-off risks.
- A module spanning buckets (80% infrastructure, 20% render) becomes two rows: the PLUGIN part and the MANUAL render part.
- No Score for DELETE rows; Score orders work within a bucket only.
- Units: hook-injected global UI that needs no template change (age gate, command palette, lightbox) is not a unit — price it as a moved module. Post-format or surface variants routed to different parts (video vs gallery single) count as separate views only when they render different templates.

## Length at scale

- Prose under ~3,000 words regardless of size.
- **Row budget** in the ASSESS body: ~40 Gate 1 rows, ~30 key-family rows, ~15 extraction rows, ~12 risks. Everything beyond goes into `ASSESS-APPENDIX.md` (full per-file and per-key detail), linked from the body.
- Field table above ~20 families: reduced columns — key family, storage, count, saved at, read at, live?, target, migration. Sanitizer, empty behavior, and shape move to the MIGRATE-time appendix.

## Strangler coexistence (default above ~50 logic files)

Re-prefixing hundreds of functions and running the plugin in data-layer-only mode makes Phase 1 deliver nothing testable. Instead:
1. Move one module group at a time into the plugin with **function names and hook names unchanged**.
2. Ship a classic release N.1 that requires the plugin and **deletes** each moved module — one copy of every function, no redeclare, no guard needed for moved code.
3. Repeat per group; the classic theme slims down while staying live and testable.
4. Build the block theme on top; the fallback is the slimmed classic N.x, not the original.

The coexistence guard (`coded-metaboxes.md`) remains for the few modules that must exist in both during a transition.

## Phase calendar at scale

Do not stretch the small-theme day calendar. Compute phases from the hour lines (Phase 1 = all plugin data-layer and moved-module lines, Phase 2 = blocks + scaffold + AUTO, …) or as percentages of the estimate.

## Splitting into several plugins

One `{original-slug}-functionality` plugin is the default. Split when a stack has its own lifecycle or replacement:
- **SEO stack:** if the site already runs (or should run) an SEO plugin, migrate data to it instead of porting the theme's stack; otherwise a separate `{slug}-seo` plugin so it can be swapped later.
- **Importers and dev tools** (demo importers, translation tools): a dev-only plugin, not shipped to production.
- Everything else stays in the one functionality plugin.

## Huge option arrays

One Settings API option with hundreds of sub-keys (often saved through REST): classify sub-keys like Customizer settings (presentation / data / copy).
- Scheme or palette keys → the active style variation; keep the key for the fallback.
- Data keys stay in the option (one `type: object` setting).
- Copy keys: editable by non-developers → keep in the option and render through a binding source; set once and rarely changed → write into the database copy of the template or part at cut-over. Decide per group and record it.

## Translations

Existing `.po`/`.mo` files split between the theme and plugin text domains. Extract msgids per package (`wp i18n make-pot` on each), then move existing translations with `msgmerge`/`msgcat` filtered by the new POT; budget per locale. Theme-shipped translation tools that write into the theme folder become a dev-only plugin.

## Hour model at scale

See `assess-reference.md` → Estimating; at scale use the size-based moved-module rate and apply CSS parity only to template, part, and block lines.
