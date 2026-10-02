<?php
/**
 * Dynamic block registration.
 *
 * @package MythemeFunctionality
 */

declare( strict_types=1 );

add_action( 'init', static function (): void {
	foreach ( array( 'event-schedule', 'event-details', 'event-sessions', 'event-session' ) as $block ) {
		register_block_type( MYTHEME_FUNC_DIR . 'inc/blocks/' . $block );
	}
} );
