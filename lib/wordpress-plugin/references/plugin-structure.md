# Plugin structure and main file header

## Required file structure

Always produce this baseline tree. Skip files that correspond to unselected features (e.g. no `includes/class-rest-controller.php` if REST endpoints not picked).

```
{plugin-slug}/
├── {plugin-slug}.php                 ← main plugin file (header + bootstrap)
├── uninstall.php                     ← runs on plugin deletion
├── readme.txt                        ← WordPress.org format
├── readme.md                         ← GitHub-friendly mirror
├── composer.json                     ← classmap autoload for includes/ (class-*.php names are not PSR-4), dev deps optional
├── .gitignore
├── languages/
│   └── {plugin-slug}.pot             ← translation template (header populated)
├── includes/
│   ├── class-plugin.php              ← singleton, loads other components
│   ├── class-activator.php           ← activation hook handler
│   ├── class-deactivator.php         ← deactivation hook handler
│   ├── class-i18n.php                ← text domain loader
│   ├── class-admin.php               ← admin pages, menus, settings (if admin features picked)
│   ├── class-frontend.php            ← shortcodes, scripts, public hooks (if frontend picked)
│   ├── class-database.php            ← dbDelta schema, migrations (if custom tables picked)
│   ├── class-ajax.php                ← admin-ajax handlers (if Frontend Forms or another AJAX-driven feature picked)
│   ├── class-rest-controller.php     ← REST routes (if REST picked)
│   ├── class-cron.php                ← scheduled events (if cron picked)
│   ├── class-cli.php                 ← WP-CLI commands (if CLI picked)
│   ├── class-roles.php               ← role/capability management (if roles picked)
│   ├── class-cpt.php                 ← custom post types/taxonomies (if CPT picked)
│   ├── class-meta-boxes.php          ← meta box registration (if meta boxes picked)
│   ├── class-list-table.php          ← WP_List_Table subclass (if list tables picked)
│   ├── class-dashboard-widget.php    ← dashboard widget (if picked)
│   ├── class-notices.php             ← dismissible admin notices (if picked)
│   ├── class-integration-{name}.php  ← one per third-party integration picked
│   └── helpers.php                   ← procedural utilities
├── assets/
│   ├── css/
│   │   ├── admin.css
│   │   └── public.css
│   ├── js/
│   │   ├── admin.js
│   │   └── public.js
│   └── images/
│       └── icon.svg
├── blocks/                           ← only if Gutenberg blocks picked
│   └── {block-slug}/
│       ├── block.json
│       ├── edit.js
│       ├── save.js
│       ├── index.js
│       ├── editor.scss
│       └── style.scss
├── docs/                             ← documented hooks, filters, and REST endpoints (if Developers or Mixed audience picked)
├── templates/                        ← user-overridable theme templates (if frontend picked)
│   └── {feature}-display.php
└── tests/
    └── README.md                     ← brief notes on running PHPUnit/WPCS
```

## Main file header template

Every plugin's `{slug}.php` opens with this header. Fill in real values - never leave placeholders. For `Plugin URI` / `Author` / `Author URI`: use the author's real details if known; otherwise omit those lines entirely rather than shipping literal `example.com`.

```php
<?php
/**
 * Plugin Name:       {Plugin Name}
 * Plugin URI:        https://example.com/{slug}
 * Description:       {One-line description derived from Q3.}
 * Version:           1.0.0
 * Requires at least: 6.0
 * Requires PHP:      7.4
 * Author:            {Author Name}
 * Author URI:        https://example.com
 * License:           GPL-2.0-or-later
 * License URI:       https://www.gnu.org/licenses/gpl-2.0.html
 * Text Domain:       {plugin-slug}
 * Domain Path:       /languages
 *
 * @package {Namespace}
 */

defined( 'ABSPATH' ) || exit;
```
