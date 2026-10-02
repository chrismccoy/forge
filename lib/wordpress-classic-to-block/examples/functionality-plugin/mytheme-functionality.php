<?php
/**
 * Plugin Name:       My Theme Functionality
 * Plugin URI:        https://example.com
 * Description:       Business logic, CPTs, taxonomies, metaboxes, REST endpoints, and
 *                    integrations extracted from the classic theme during FSE migration.
 * Version:           1.0.0
 * Requires at least: 6.5
 * Requires PHP:      8.1
 * Author:            Your Name
 * License:           GPL-2.0-or-later
 * Text Domain:       mytheme-functionality
 *
 * @package MythemeFunctionality
 */

declare( strict_types=1 );

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

define( 'MYTHEME_FUNC_VERSION', '1.0.0' );
define( 'MYTHEME_FUNC_DIR',     plugin_dir_path( __FILE__ ) );
define( 'MYTHEME_FUNC_URL',     plugin_dir_url( __FILE__ ) );

/*
 * Load modules at include time. Each file only registers hooks, so this is safe,
 * and it guarantees the functions exist when the activation hook below runs
 * (plugins_loaded has already fired by the time a plugin is activated).
 */
require_once MYTHEME_FUNC_DIR . 'inc/post-types.php';
require_once MYTHEME_FUNC_DIR . 'inc/post-meta.php';
require_once MYTHEME_FUNC_DIR . 'inc/blocks.php';
require_once MYTHEME_FUNC_DIR . 'inc/shortcodes.php';
require_once MYTHEME_FUNC_DIR . 'inc/editor.php';
require_once MYTHEME_FUNC_DIR . 'inc/query-loop.php';
require_once MYTHEME_FUNC_DIR . 'inc/site-options.php';
// Hand-coded metabox conversion (products are regular posts).
require_once MYTHEME_FUNC_DIR . 'inc/products/fields.php';
require_once MYTHEME_FUNC_DIR . 'inc/products/register.php';
require_once MYTHEME_FUNC_DIR . 'inc/products/derived.php';
require_once MYTHEME_FUNC_DIR . 'inc/products/editor.php';
require_once MYTHEME_FUNC_DIR . 'inc/products/navigation-icons.php';
// Add as needed: inc/taxonomies.php, inc/block-bindings.php, inc/rest-endpoints.php, inc/integrations.php.

if ( defined( 'WP_CLI' ) && WP_CLI ) {
	require_once MYTHEME_FUNC_DIR . 'inc/cli-migrations.php';
}

/**
 * On activation, register CPTs then flush rewrite rules so their slugs resolve immediately.
 */
register_activation_hook( __FILE__, static function (): void {
	mytheme_func_register_event_cpt();
	flush_rewrite_rules();
} );

register_deactivation_hook( __FILE__, 'flush_rewrite_rules' );
