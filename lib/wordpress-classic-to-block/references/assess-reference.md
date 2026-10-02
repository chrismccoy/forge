# ASSESS Reference

Everything an ASSESS needs in one place: units and verdict rules, field-table columns, hour rates, slug choice, Phase 0 checklist, length rule.

## Units for the go/no-go

A **unit** is a view or a shared component (header, footer, card, nav, sidebar). Blocks that replace widgets or shortcodes are not units by themselves — they belong to the sidebar or view component that shows them. A component used by only one view belongs to that view (not a separate unit); split shared components only as finely as they will be built (header, footer, card, nav, sidebar — not every partial). **Near-threshold rule (all themes):** a result within 5 points of a threshold takes the **less severe** band (Moderate rather than High-risk, High-risk rather than Rebuild); state both numbers. Rebuild and High-risk both execute plugin-first and differ only in where templates start, so the label never changes the estimate. Shared components count as units whether AUTO or MANUAL.

## Field-table columns

- **Full table** (`coded-metaboxes.md` Step 2): Key; Storage (post/term/user/comment meta, theme mod, option, widget option, cookie, localStorage, transient, **custom table**); Type; Allowed value; Sanitizer; Empty; Shape; Applies to; Saved at; Printed at; Live?; Target storage; Target control; Migration.
- **Fast-path table:** Key; Storage; Printed at; Live?; Target.
- One row per **key family** (loop-generated or suffixed keys), not per key.

## Estimating

**Small-theme rates** (fast path, no plugin): count actual work, no per-unit floors — a three-line footer part is 0.25 h, a simple template 0.5–1 h. Utility-CSS removal or re-plumbing is either its own line or inside CSS parity, never both. Add WordPress.org packaging (readme, screenshot, licenses) 2–3 h and hidden i18n patterns 1–2 h when building to directory standards.

Hours per unit (adjust for the code's condition): AUTO template 1–2; MANUAL view 2–4 for template assembly (its blocks are counted separately); plugin block or shared component 2–6; simple meta field 0.5–1; repeater or complex field 3–6; widget type 2–4; shortcode → core block or transform 1–2, → plugin block plus shim 3; client-state JS feature (`localStorage` lists, filters) port 2–4 each; new or reworked AJAX/REST endpoint 3–8; module moved unchanged (prefixing, coexistence guard) 1–2 — above ~30 modules use 1 h per 10 files or ~2 h per KLOC instead; migration command 2–4. Also: `theme.json` derivation 4–8 plus 2 per hand-made style variation (generated variations: a flat 4–6 for the generator); utility-CSS build re-plumbing and self-hosted fonts/icons 4–8; Navigation import 1 per location; the editor switch (filters off, CPTs to REST, smoke test) 4–6; updating a theme-shipped test-data importer 1–8 (by size of change). Text-domain split 2 + 1 per shipped locale; theme-shipped legal/policy copy 0.25 per part. Then CSS parity 15–25% of the **template, part, and block lines only** (not infrastructure moves), then testing 15% of the result. Days = hours ÷ 6 productive hours. The phase calendar in `SKILL.md` is a default for about 40 hours; scale each phase to the estimate.

## Same slug or new slug

Decide at Gate 0 and record it:
- **Same slug** (block theme replaces the classic folder): theme mods and `nav_menu_locations` survive; the fallback is a git tag or a zip, not a side-by-side installed theme.
- **New slug:** the classic theme stays installed for instant fallback; copy `theme_mods_{old}` (and apply the Customizer data rule) before switching.

## Phase 0 checklist

1. Version control — Phase 0 assumes git. Without it: `git init` and commit the classic theme as the first step. The "no commits in years" criterion for unmaintained code is then unknown — score the other criteria only.
2. Tag what production runs: merge or discard in-flight branches and uncommitted fixes, rebuild compiled assets from that commit (the tagged `theme.css` must equal production), then tag. A tag of an unbuilt tree is not a fallback. Check in-repo change notes (`CHANGED.md`, `BUGS.md`) for uncommitted work.
3. Finish in-flight lazy data migrations (readers that write, backfill crons) with a one-off command (`coded-metaboxes.md` Step 1).
4. Audit stored shapes before registering keys (JSON repeater corruption, other writers).
5. Enable `WP_DEBUG`; confirm the WP version.

## Length rule

One-page summary first (verdict with both percentages, units, hours, plugin yes/no, slug, top 5 risks). Tables over prose; detail only for MANUAL and PLUGIN items. Group the plugin extraction list by module or file (not every hook) and the field table by key family. Keep prose under about 3,000 words — count prose only (exclude tables and code blocks). Above ~60 PHP files also apply the row budget and appendix in `large-themes.md`.
