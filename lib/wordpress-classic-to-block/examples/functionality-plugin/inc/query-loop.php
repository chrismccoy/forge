<?php
/**
 * Server side of the "Upcoming events" Query Loop variation.
 *
 * The variation's `namespace` attribute is not passed to inner blocks, so flag the
 * query attributes before render; the flag then reaches core/post-template (and the
 * pagination blocks) through the `query` block context.
 *
 * Editor preview uses the REST API and shows default ordering; the front end is exact.
 *
 * @package MythemeFunctionality
 */

declare( strict_types=1 );

add_filter( 'render_block_data', static function ( array $parsed_block ): array {
	if (
		'core/query' === ( $parsed_block['blockName'] ?? '' )
		&& 'mytheme/upcoming-events' === ( $parsed_block['attrs']['namespace'] ?? '' )
	) {
		$parsed_block['attrs']['query']['mythemeUpcoming'] = true;
	}
	return $parsed_block;
} );

add_filter( 'query_loop_block_query_vars', static function ( array $query, WP_Block $block ): array {
	if ( empty( $block->context['query']['mythemeUpcoming'] ) ) {
		return $query;
	}
	$query['meta_key']   = 'event_date'; // phpcs:ignore WordPress.DB.SlowDBQuery
	$query['orderby']    = 'meta_value';
	$query['order']      = 'ASC';
	$query['meta_query'] = array( // phpcs:ignore WordPress.DB.SlowDBQuery
		array(
			'key'     => 'event_date',
			'value'   => current_time( 'Y-m-d' ),
			'compare' => '>=',
			'type'    => 'DATE',
		),
	);
	return $query;
}, 10, 2 );
