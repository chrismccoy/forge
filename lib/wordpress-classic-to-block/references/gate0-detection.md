# Gate 0 — Detection Checklist

Run `scripts/static-checks.sh <theme> <empty-dir> <namespace>` on the classic theme: in classic mode it prints the signals below as INFO with counts and locations. Then confirm each by reading the code.

## Block-feature sabotage
grep for code that disables what a block theme needs — `use_block_editor_for_post`, `use_block_editor_for_post_type`, `use_widgets_block_editor`, `gutenberg_use_widgets_block_editor`, `'show_in_rest' => false` on post types and taxonomies (keeps them out of the block editor even after the filters go), dequeued `wp-block-library` / `global-styles` / `classic-theme-styles`, unhooked `wp_enqueue_global_styles`, removed `wp_oembed_register_route`. Also flag a strict Content-Security-Policy (`wp_headers`/`send_headers`) that nonces only `script_loader_tag` — it blocks script modules — and `unregister_widget( 'WP_Widget_Block' )`. Exempt record post types (rows created by code — form submissions, logs, PII — not staff-authored content) from the `show_in_rest` rule. Also grep admin JS for TinyMCE coupling (`tinymce`, `tinyMCE`, `QTags`, `#content`). Also list TinyMCE customizations (`mce_buttons*`, `mce_external_plugins`, `tiny_mce_before_init`) — authoring features lost at the editor switch. Never port the sabotage; deleting it changes the editing experience for every existing post at once, so schedule it as its own step. A theme that dequeues `global-styles` cannot use the hybrid path until that is removed.

## Complexity markers
WP-Cron schedules, theme lifecycle hooks (`after_switch_theme`/`switch_theme`), CPTs, taxonomies, shortcodes, REST endpoints, ACF field groups, metaboxes (simple vs repeater/conditional), theme options pages, custom widgets, nav walkers, jQuery scripts, WooCommerce templates, active plugins called from template PHP, share of Classic-editor content. These feed Gates 5–5d and the legacy-features plan.

## Grep list

```bash
grep -rnE "use_block_editor_for_post|use_widgets_block_editor|show_in_rest['\"]?\s*=>\s*false|wp_dequeue_style|wp_enqueue_global_styles|wp_oembed_register_route|WP_Widget_Block|Content-Security-Policy|wp_headers|send_headers" --include=*.php .
grep -rnE "register_rest_route|register_post_type|register_taxonomy|register_setting|WP_CLI::add_command|wp_privacy_personal_data|map_meta_cap|wp_schedule_(single_)?event|after_switch_theme|switch_theme|add_(menu|submenu|theme|options)_page|pre_get_posts|template_redirect|register_widget|customize_register|add_rewrite_rule|add_rewrite_endpoint|add_feed" --include=*.php .
grep -rlnE "tinymce|tinyMCE|QTags" --include=*.js .
grep -rnE "dbDelta|CREATE TABLE|apply_filters\(\s*.<prefix>_|do_action\(\s*.<prefix>_|wp_localize_script" --include=*.php .
```

## Units, near-threshold rule, Phase 0

Moved to `assess-reference.md`.
