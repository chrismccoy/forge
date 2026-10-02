<?php
/**
 * Editor-only scripts (no build step).
 *
 * @package MythemeFunctionality
 */

declare( strict_types=1 );

/**
 * Enqueue a script from inc/editor/ using its hand-written .asset.php file.
 */
function mytheme_func_enqueue_editor_script( string $handle, string $name ): void {
	$asset = include MYTHEME_FUNC_DIR . "inc/editor/{$name}.asset.php";
	wp_enqueue_script(
		$handle,
		MYTHEME_FUNC_URL . "inc/editor/{$name}.js",
		$asset['dependencies'],
		$asset['version'],
		true
	);
	wp_set_script_translations( $handle, 'mytheme-functionality' );
}

add_action( 'enqueue_block_editor_assets', static function (): void {
	// Query Loop variation: post editor and Site Editor.
	mytheme_func_enqueue_editor_script( 'mytheme-query-variations', 'query-variations' );

	// Event sidebar panel: only when editing an event.
	$screen = function_exists( 'get_current_screen' ) ? get_current_screen() : null;
	if ( $screen && 'event' === $screen->post_type ) {
		mytheme_func_enqueue_editor_script( 'mytheme-event-panel', 'event-panel' );
	}
} );
