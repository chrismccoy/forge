# Performance Review Checks

The per-subsystem checklist applied to every manifest file in Step 4, with the default severity for each check. Execution context can lower a severity (admin, CLI, and cron paths face less load than a public page); say so in the finding when it does. For bad and good code for each pattern, see `anti-patterns.md`.

## Plugin and theme PHP
- `query_posts()` - CRITICAL, replaces the main query and breaks pagination
- `posts_per_page => -1`, `numberposts => -1` - CRITICAL, unbounded query
- `session_start()` - CRITICAL, bypasses page cache for the whole site
- Expensive work on `init` or `wp_loaded` with no context guard - WARNING
- `update_option` / `add_option` on a frontend path - CRITICAL, a database write per request
- `wp_remote_get` / `wp_remote_post` with no caching or timeout - WARNING

## WP_Query and database code
- Missing `posts_per_page` - WARNING, falls back to the blog setting
- `meta_query` comparing `value` - WARNING, unindexed scan
- `post__not_in` with large arrays - WARNING, slow exclusion
- `LIKE '%term%'` - WARNING, full table scan
- Missing `no_found_rows => true` when not paginating - INFO
- Any query inside a loop - CRITICAL, N+1

## AJAX and REST
- `admin-ajax.php` on a frontend path - WARNING, full admin bootstrap per request; REST has a leaner one
- POST for read operations - WARNING, bypasses cache
- `setInterval` polling - CRITICAL, self-inflicted DDoS
- Missing nonce - note it as security, outside this review's scoring

## Templates
- `get_template_part` inside loops - INFO on its own; score the queries or meta reads inside the partial, multiplied by the loop
- Queries inside the loop - CRITICAL, query multiplication
- `wp_remote_get` in a template - WARNING, blocks rendering

## JavaScript
- `$.post(` for reads - WARNING, use GET so it can be cached
- `setInterval` with fetch or ajax - CRITICAL, polling
- Full library imports (`import _ from 'lodash'`) - WARNING, bundle bloat
- Inline `<script>` firing AJAX on every page load - WARNING, an uncached request per view; INFO if it runs only on rare pages

## Block editor
- Many `registerBlockStyle()` calls - WARNING, a preview iframe per style
- `wp_kses_post( $content )` in a render callback - WARNING, breaks InnerBlocks
- Static blocks with no `render_callback` - INFO

## Asset registration
- Unconditional `wp_enqueue_script` / `wp_enqueue_style` - WARNING, site-wide load
- No version string - INFO, cache busting
- No `defer` or `async` strategy - INFO, render blocking

## Transients and options
- `set_transient` with dynamic keys - WARNING, one `wp_options` row per entity
- `set_transient` for volatile data - WARNING, defeats the cache
- Large autoloaded options - WARNING, loaded on every request

## WP-Cron
- No `DISABLE_WP_CRON` - INFO, cron runs on page requests
- A callback looping all users or posts - CRITICAL, blocks the cron queue
- `wp_schedule_event` without `wp_next_scheduled` - WARNING, duplicate events
