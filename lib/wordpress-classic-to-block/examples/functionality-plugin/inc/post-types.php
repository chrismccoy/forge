<?php
/**
 * Custom Post Type registration.
 * Moved from classic theme functions.php during FSE migration.
 *
 * @package MythemeFunctionality
 */

declare( strict_types=1 );

/**
 * Register the 'event' CPT.
 */
function mytheme_func_register_event_cpt(): void {
	$labels = array(
		'name'          => _x( 'Events', 'post type general name', 'mytheme-functionality' ),
		'singular_name' => _x( 'Event', 'post type singular name', 'mytheme-functionality' ),
		'add_new_item'  => __( 'Add New Event', 'mytheme-functionality' ),
		'edit_item'     => __( 'Edit Event', 'mytheme-functionality' ),
		'view_item'     => __( 'View Event', 'mytheme-functionality' ),
		'search_items'  => __( 'Search Events', 'mytheme-functionality' ),
		'not_found'     => __( 'No events found.', 'mytheme-functionality' ),
	);

	register_post_type(
		'event',
		array(
			'labels'       => $labels,
			'public'       => true,
			'show_in_rest' => true, // Required for block editor support.
			'has_archive'  => true,
			'rewrite'      => array( 'slug' => 'events' ),
			// 'custom-fields' is required for registered meta to appear in REST / Block Bindings.
			'supports'     => array( 'title', 'editor', 'thumbnail', 'excerpt', 'custom-fields' ),
			'menu_icon'    => 'dashicons-calendar-alt',
			// Structured edit screen: the block layout editors fill in, replacing the metabox form.
			'template'      => array(
				array( 'mytheme/event-details' ),
				array( 'mytheme/event-sessions', array(), array( array( 'mytheme/event-session' ) ) ),
				array( 'core/paragraph', array( 'placeholder' => __( 'Describe the event…', 'mytheme-functionality' ) ) ),
			),
			'template_lock' => 'insert', // Blocks can be edited and moved, not added or removed at top level.
		)
	);
}
add_action( 'init', 'mytheme_func_register_event_cpt' );
