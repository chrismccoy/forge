# Step 1 - read the theme first

Build the data model before a line of the importer is written. Every row is cited
`file:line`. Nothing below is guessed; it is found in the code.

Don't write any code until you have grepped the whole theme (including `inc/`, `includes/`, `lib/`, `classes/`, and `src/`) for the calls listed below, read every file those greps hit plus `functions.php` and every template that renders posts, and can answer these questions from the code. Skip `vendor/`, `node_modules/`, and bundled frameworks such as Redux, TGMPA, or Kirki; read only the theme's own config calls into them. For themes over about 100 PHP files, split the reading across subagents that return the tables below, not file contents; if you can't run subagents, read in batches and add each batch's rows to the tables in a scratch file outside the theme as you go, so earlier findings aren't lost.

**Content**
- Which post formats does it declare (`add_theme_support( 'post-formats' )`), and what does each format's template actually read to render?
- Which custom post types and taxonomies does it register? Record each post type's `supports` list and taxonomies, and each taxonomy's post types and whether it's hierarchical.
- How does it find images: featured image, attachments with `post_parent` and `menu_order`, `[gallery ids=""]`, or ACF fields? Which image sizes does it register, and what aspect ratio does each image slot show (`add_image_size`, CSS aspect-ratio classes)?
- How does it handle video and audio: an oEmbed URL in the content, a meta field, or a direct file? Which hosts does it parse (YouTube, Vimeo, .mp4)?
- What do sidebars, rails, archives, and the home page show: recent posts, tag clouds, category counts, comment counts, authors, vote or view counters, sort modes that depend on dates or meta?
- Does it display comments, and on which post types? Look for `comments_template()` calls, filters that force comments closed or empty, and any Customizer or theme options switch that turns comments on or off.
- Which values does it compute itself from content (reading time, ranks, term and comment counts, derived caches)? The importer never writes those; the theme's hooks compute them. Counters that visitors drive (views, likes, votes, ratings) are different: they only grow with traffic, so the importer seeds them (see Counters). A counter the templates print but no code in the theme ever writes gets seeded too, and reported as a theme bug.

**Fields**
- Which post, term, and user meta does it read (`get_post_meta`, `get_post_custom`, `get_metadata`, `get_field`), and what shape does each expect (URL, number, ID list, JSON)?
- List every meta box and custom field. Search for `add_meta_box` callbacks and their `save_post` handlers (the sanitize call shows the stored format), `register_post_meta` and `register_meta`, and field frameworks: ACF (`acf_add_local_field_group`, `acf-json/`), CMB2, Meta Box, and Carbon Fields.
- List every Customizer setting. Search for `customize_register` callbacks and each `add_setting` / `add_control` pair, Kirki or any other Customizer framework, and every `get_theme_mod()` and `get_option()` call in the templates (some themes read mods that have no control). Also cover the core site identity settings the theme uses: site title, tagline, `custom_logo`, site icon, header image, background, and the homepage settings `show_on_front`, `page_on_front`, and `page_for_posts`. Record other core options it reads (such as `date_format` or `posts_per_page`) separately; the importer never changes them.
- If the theme has its own options or settings panel, list every field in it, paying special attention to text. Search for `add_theme_page`, `add_menu_page`, `add_submenu_page`, `register_setting`, `add_settings_field`, options frameworks (Redux, OptionTree, Codestar/CSF, Kirki panels, ACF options pages via `acf_add_options_page` and `get_field( 'x', 'option' )`, Carbon Fields `theme_options`, CMB2 options pages, Titan), and every template call that reads those options, such as `get_option( '<theme>_options' )['footer_text']` or a helper like `<theme>_get_option()`.

**Site**
- Which nav menu locations, widget areas, and page templates does it use? Are any templates chosen by slug (`page-<slug>.php`, `is_page( 'slug' )`)? Does it add fields to menu items (a custom `Walker_Nav_Menu`, a `wp_update_nav_menu_item` handler, per-item meta such as an icon)?
- What does it seed on activation (terms, pages, menus, widgets, other posts, filled sidebars), and through which function? Does it have its own demo or sample-content system (a demo tag meta key, a tracked-settings option, remove or reset tools)?
- Which of its own functions or classes save, sanitize, seed defaults, or clear caches? Call them rather than re-implementing them.
- Which transients or object-cache keys does it set that would be stale after an import?
- Does it depend on plugins (WooCommerce, ACF, and so on)? If so, create that content only when the plugin is active, and warn otherwise.
- Does it build its CSS from source (Tailwind, Sass, PostCSS in `package.json`)? If so, build the source into a copy outside the theme with the theme's own command and compare the selector list with the committed CSS file (for example `grep -o '[^{}]*{' file | LC_ALL=C sort -u` on both, then `LC_ALL=C comm`; if the CSS uses native nesting, that list gets noisy, so compare class names instead with `grep -oE '\.[A-Za-z0-9_\\:/-]+' file | LC_ALL=C sort -u`). Rules the source defines but the committed file lacks (a stale build, or `content` globs that miss a folder) are theme bugs; report them. Never overwrite the committed CSS.

For every meta field, Customizer setting, and options field, record one table row: key (plus array key); storage (post, term, or user meta; theme_mod; option); field type, flagging text-carrying types (text, textarea, WYSIWYG, email, URL, tel, and text inside repeaters or groups); allowed choices or checked value (`'1'`, `'on'`, `'yes'`); date format; default; sanitize or save callback (image controls may store a URL or an attachment ID); serialized or one row per value; where it applies (post types, formats, page templates, and conditions such as "paid items only"); where templates output it; what the template prints around the value (labels, units, prefixes); and what shows when it's empty (a fallback, or the element is hidden).

Summarize this data model in markdown tables before you write the importer, citing `file:line` for each item.
