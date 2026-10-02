<?php
/**
 * Classic metabox as typically found in a classic theme's functions.php.
 * Migration target: functionality-plugin/inc/post-meta.php + block bindings.
 */

add_action( 'add_meta_boxes', function () {
	add_meta_box(
		'mytheme_event_details',
		__( 'Event Details', 'mytheme' ),
		'mytheme_render_event_metabox',
		'event',
		'normal',
		'high'
	);
} );

function mytheme_render_event_metabox( $post ) {
	$venue = get_post_meta( $post->ID, '_event_venue', true );
	wp_nonce_field( 'mytheme_event_save', 'mytheme_event_nonce' );
	echo '<label>Venue</label>';
	echo '<input type="text" name="event_venue" value="' . esc_attr( $venue ) . '" />';
}

add_action( 'save_post', function ( $post_id ) {
	if ( ! isset( $_POST['mytheme_event_nonce'] ) || ! wp_verify_nonce( $_POST['mytheme_event_nonce'], 'mytheme_event_save' ) ) {
		return;
	}
	if ( isset( $_POST['event_venue'] ) ) {
		update_post_meta( $post_id, '_event_venue', sanitize_text_field( $_POST['event_venue'] ) );
	}
} );
