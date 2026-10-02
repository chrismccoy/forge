<?php
/**
 * Shortcode compatibility shims.
 * Existing content still contains [event_schedule] — do not break it.
 * New content should use the mytheme/event-schedule block instead.
 * Each shim delegates to the block so there is exactly one render path.
 *
 * @package MythemeFunctionality
 */

declare( strict_types=1 );

add_shortcode( 'event_schedule', static function (): string {
	// render_block() returns the HTML; it does not echo.
	return render_block(
		array(
			'blockName'    => 'mytheme/event-schedule',
			'attrs'        => array(),
			'innerBlocks'  => array(),
			'innerHTML'    => '',
			'innerContent' => array(),
		)
	);
} );
