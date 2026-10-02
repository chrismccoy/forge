<?php
/**
 * MyTheme functions — presentation only.
 * Business logic lives in the mytheme-functionality plugin.
 *
 * Block themes get these automatically, so they are NOT declared here:
 * post-thumbnails, responsive-embeds, editor-styles, html5, automatic-feed-links, title tag.
 *
 * @package MyTheme
 */

declare( strict_types=1 );

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

/**
 * Theme setup.
 */
add_action( 'after_setup_theme', static function (): void {
	// Load style.css inside the editor canvas too.
	add_editor_style( 'style.css' );

	// Optional: hide core's bundled patterns so the inserter shows the theme's own.
	remove_theme_support( 'core-block-patterns' );
} );

/**
 * Front-end stylesheet. WordPress never enqueues style.css for any theme. This example's
 * only stylesheet is style.css; when the classic theme enqueued a compiled file
 * (e.g. assets/css/theme.css), port that enqueue instead of this one.
 */
add_action( 'wp_enqueue_scripts', static function (): void {
	wp_enqueue_style(
		'mytheme-style',
		get_stylesheet_uri(),
		array(),
		wp_get_theme()->get( 'Version' )
	);
} );

/**
 * Per-block styles: loaded only on pages where the block renders (front end and editor).
 * Use for leftover classic CSS that targets a specific block.
 */
add_action( 'init', static function (): void {
	wp_enqueue_block_style(
		'core/navigation',
		array(
			'handle' => 'mytheme-core-navigation',
			'src'    => get_theme_file_uri( 'assets/css/blocks/core-navigation.css' ),
			'path'   => get_theme_file_path( 'assets/css/blocks/core-navigation.css' ),
			'ver'    => wp_get_theme()->get( 'Version' ),
		)
	);
} );

/**
 * Custom pattern category for the theme's patterns.
 */
add_action( 'init', static function (): void {
	register_block_pattern_category(
		'mytheme',
		array( 'label' => __( 'MyTheme', 'mytheme' ) )
	);
} );
