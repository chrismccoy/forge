# Theme-Bundled Mode (no companion plugin)

All business logic ships inside the block theme, structured as an extractable plugin. Chosen at Gate 0 as the **code home**.

## When to choose it

| Choose theme-bundled | Choose a companion plugin |
|---|---|
| Single client site; the developer maintains the theme long-term | Distribution on WordPress.org (plugin territory rule) |
| One package to deploy matters more than theme portability | The client may change themes, or other themes must read the data |
| No other plugin or theme depends on the CPTs, blocks, or REST routes | Several sites or themes share the same logic |

Record the choice and its consequence: switching to an unrelated theme later hides CPTs, meta panels, and custom blocks ("unsupported block") until the code is restored or extracted.

## Structure

```text
{theme-slug}/
  functions.php              ← presentation hooks + require inc/functionality/functionality.php
  inc/functionality/         ← plugin-shaped: everything Gate 5 would move to a plugin
    functionality.php        ← bootstrap: constants, requires, version-checked install
    inc/                     ← post types, meta, blocks, REST, cron, CLI, editor panels
    blocks/                  ← block.json + render.php + editor.js per block
    languages/
```

Rules that keep it extractable:
- Path and URL constants defined once in the bootstrap (`X_FUNC_DIR = get_theme_file_path( 'inc/functionality/' )`, `X_FUNC_URL = get_theme_file_uri( 'inc/functionality/' )`); every file uses them, never `get_template_directory()` directly. Extraction then means four steps: (1) move the folder, (2) add a plugin header, (3) switch the two constants to `plugin_dir_path()` / `plugin_dir_url()`, (4) swap the theme lifecycle for plugin lifecycle — replace the `switch_theme` handler with `register_deactivation_hook()` (cron unschedule) and the version-checked install trigger with `register_activation_hook()` plus the same version check. Without step 4, a theme switch wipes the plugin's cron and deactivation leaves orphan events. The bootstrap should return early when a plugin copy is already loaded, so theme folder and plugin can coexist during the move.
- Own namespace or function prefix (`x_func_`), no calls into theme presentation functions, and presentation never calls into it (keep the static check's function-prefix rule).
- Its own text domain is optional; with the theme's domain, extraction needs a domain change.

## Lifecycle without activation hooks

There is no plugin activation hook, and `after_switch_theme` does not fire when a same-slug block theme replaces the classic folder.
- **Install, upgrade, seeding, rewrite flush, custom tables:** a versioned install on `init` at a late priority (99, after post types and rewrite rules are registered, so the flush sees them) — `if ( get_option( 'x_func_version' ) !== X_FUNC_VERSION ) { x_func_install(); update_option( 'x_func_version', X_FUNC_VERSION ); }`. Make every step idempotent.
- **Cron:** schedule inside the install (guarded by a scan of `_get_cron_array()` for the hook with any args — `wp_next_scheduled()` without args misses chains queued with args); unschedule on `switch_theme` only when switching to an unrelated theme, and reset the version option then so returning reinstalls — a switch to the classic fallback must leave events and the version option alone.
- **WP-CLI migration commands:** register from the bootstrap behind `defined( 'WP_CLI' )`; they run while the theme is active.

## Rules elsewhere that do not apply in this mode

"Plugin" instructions mean `inc/functionality/`, **except**:
- `register_activation_hook` / `register_deactivation_hook` and "schedule on plugin activation" (`plugin-extraction.md` → WP-Cron, lifecycle, plugin scaffold) → use the version-checked install and the `switch_theme` rule above.
- Phase 1 "activate the plugin beside the classic theme" is impossible: nothing loads until the folder swap. Run data audits and migration dry-runs on a staging clone with the bundled theme active, or immediately after the swap.
- Coexistence guard, plugin-off smoke test, "plugin missing" notice → drop.

## What changes in the rest of the procedure

- **Gate 5 / plugin-extraction:** the PLUGIN bucket still applies — it means "goes to `inc/functionality/`", not "goes to another package". The extraction table, field recipes, blocks, and migrations are unchanged.
- **Coexistence guard:** not needed for the same-slug path (the classic theme carries its own copy of the logic until replaced). For a new slug, each theme contains its own logic and only the active one runs; shared data keys must stay identical.
- **Plugin dependency model:** not applicable; core-post templates may use the bundled blocks freely.
- **Verification:** drop the plugin-off smoke test; keep "switch to the fallback and back" (cron, seeders, menus intact) and run the static checks with the plugin directory set to `inc/functionality` — it is excluded from the theme-side checks.
- **WordPress.org:** record the plugin-territory deviation.
- **Estimate:** subtract plugin packaging and the coexistence guard (about 2–4 h); no other change.
