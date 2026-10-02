<?php
/**
 * Post meta registration for block editor + Block Bindings support.
 * Replaces the classic metabox (see examples/classic/metabox.php).
 *
 * @package MythemeFunctionality
 */

declare( strict_types=1 );

/**
 * Register 'event_venue' meta field.
 * show_in_rest is REQUIRED for Block Bindings and the block editor to see this field.
 * The 'event' post type must support 'custom-fields'.
 *
 * NOTE: auth_callback is a baseline. Audit every migrated field individually —
 * metabox-heavy themes often have field-level capability logic (e.g. only admins
 * can edit a "featured" flag). A blanket callback can over- or under-expose fields via REST.
 */
function mytheme_func_register_event_meta(): void {
	register_post_meta(
		'event',
		'event_venue',
		array(
			'type'              => 'string',
			'single'            => true,
			'default'           => '',
			'show_in_rest'      => true,
			'sanitize_callback' => 'sanitize_text_field',
			'auth_callback'     => static function ( $allowed, $meta_key, $post_id ): bool {
				return current_user_can( 'edit_post', $post_id );
			},
		)
	);
}
add_action( 'init', 'mytheme_func_register_event_meta' );

/**
 * Fields edited in the "Event details" sidebar panel (inc/editor/event-panel.js).
 */
function mytheme_func_register_event_panel_meta(): void {
	$can_edit = static function ( $allowed, $meta_key, $post_id ): bool {
		return current_user_can( 'edit_post', $post_id );
	};

	register_post_meta(
		'event',
		'event_date',
		array(
			'type'              => 'string',
			'single'            => true,
			'default'           => '',
			'show_in_rest'      => array( 'schema' => array( 'type' => 'string', 'format' => 'date' ) ),
			'sanitize_callback' => static function ( $value ): string {
				$date = DateTimeImmutable::createFromFormat( '!Y-m-d', (string) $value );
				return $date ? $date->format( 'Y-m-d' ) : '';
			},
			'auth_callback'     => $can_edit,
		)
	);

	// Relationship field: array of event IDs. Arrays need an explicit REST schema.
	register_post_meta(
		'event',
		'event_related',
		array(
			'type'              => 'array',
			'single'            => true,
			'default'           => array(),
			'show_in_rest'      => array(
				'schema' => array(
					'type'  => 'array',
					'items' => array( 'type' => 'integer' ),
				),
			),
			'sanitize_callback' => static function ( $value ): array {
				return array_values( array_filter( array_map( 'absint', (array) $value ) ) );
			},
			'auth_callback'     => $can_edit,
		)
	);
}
add_action( 'init', 'mytheme_func_register_event_panel_meta' );

/**
 * Server-side enforcement of the required date. The editor's lockPostSaving is UX only.
 * The block editor saves through REST and sends meta in the same request, so validate
 * there: the incoming value wins, otherwise the stored value is checked.
 */
add_filter( 'rest_pre_insert_event', static function ( $prepared_post, WP_REST_Request $request ) {
	// Updates only carry fields that changed; fall back to the stored status.
	$status = $prepared_post->post_status ?? ( empty( $prepared_post->ID ) ? '' : get_post_status( (int) $prepared_post->ID ) );
	if ( 'publish' !== $status && 'future' !== $status ) {
		return $prepared_post;
	}
	$meta = $request->get_param( 'meta' );
	$date = is_array( $meta ) && array_key_exists( 'event_date', $meta )
		? (string) $meta['event_date']
		: ( empty( $prepared_post->ID ) ? '' : (string) get_post_meta( (int) $prepared_post->ID, 'event_date', true ) );

	if ( '' === $date ) {
		return new WP_Error(
			'mytheme_event_date_required',
			__( 'An event date is required before publishing.', 'mytheme-functionality' ),
			array( 'status' => 400 )
		);
	}
	return $prepared_post;
}, 10, 2 );
