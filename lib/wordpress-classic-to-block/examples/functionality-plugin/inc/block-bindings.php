<?php
/**
 * OPTIONAL custom Block Bindings source.
 *
 * Plain post meta does NOT need this: bind to the built-in "core/post-meta" source
 * (see examples/block-theme/templates/single-event.html). Register a custom source only
 * when the value must be computed or formatted (e.g. a date, a price, a lookup).
 *
 * @package MythemeFunctionality
 */

declare( strict_types=1 );

add_action( 'init', static function (): void {
	register_block_bindings_source(
		'mytheme/event-meta',
		array(
			'label'              => __( 'Event Meta (formatted)', 'mytheme-functionality' ),
			'uses_context'       => array( 'postId' ),
			'get_value_callback' => static function ( array $source_args, $block_instance ) {
				$post_id = $block_instance->context['postId'] ?? get_the_ID();
				if ( ! $post_id || empty( $source_args['key'] ) ) {
					return null;
				}
				$value = get_post_meta( $post_id, $source_args['key'], true );
				return '' === $value ? null : esc_html( (string) $value );
			},
		)
	);
} );
