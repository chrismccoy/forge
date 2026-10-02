<?php
/**
 * Enqueue the config-driven product panel and pass it the field map.
 * Also removes the legacy metaboxes so they cannot overwrite panel values.
 *
 * @package MythemeFunctionality
 */

declare( strict_types=1 );

add_action( 'enqueue_block_editor_assets', static function (): void {
	$screen = function_exists( 'get_current_screen' ) ? get_current_screen() : null;
	if ( ! $screen || 'post' !== $screen->post_type ) {
		return;
	}
	mytheme_func_enqueue_editor_script( 'mytheme-product-panel', 'product-panel' );
	wp_add_inline_script(
		'mytheme-product-panel',
		'window.mythemeProductFields = ' . wp_json_encode( mytheme_func_product_fields() ) . ';',
		'before'
	);
} );

/*
 * Interim phase only (classic theme still active, block editor enabled): the theme's
 * metaboxes render under the block editor and POST after the REST save, overwriting
 * panel values with stale form data. Remove them once the panel owns those keys.
 */
add_action( 'add_meta_boxes', static function (): void {
	foreach ( array( 'mytheme_product', 'mytheme_pricing', 'mytheme_download' ) as $id ) {
		remove_meta_box( $id, 'post', 'normal' );
	}
}, 99 );
