/**
 * "Upcoming events" — a Query Loop variation. Replaces a custom WP_Query loop.
 * Ordering and filtering by the event_date meta happen in PHP (inc/query-loop.php).
 */
( function ( wp ) {
	const { registerBlockVariation } = wp.blocks;
	const { __ } = wp.i18n;

	registerBlockVariation( 'core/query', {
		name: 'mytheme/upcoming-events',
		title: __( 'Upcoming events', 'mytheme-functionality' ),
		description: __( 'Events from today onward, soonest first.', 'mytheme-functionality' ),
		icon: 'calendar-alt',
		isActive: [ 'namespace' ],
		scope: [ 'inserter' ],
		attributes: {
			namespace: 'mytheme/upcoming-events',
			query: {
				perPage: 6,
				pages: 0,
				offset: 0,
				postType: 'event',
				order: 'asc',
				orderBy: 'date',
				author: '',
				search: '',
				exclude: [],
				sticky: '',
				inherit: false,
			},
		},
		// Hide controls that the PHP filter overrides anyway.
		allowedControls: [ 'taxQuery' ],
		innerBlocks: [
			[
				'core/post-template',
				{},
				[
					[ 'core/post-title', { isLink: true, level: 3 } ],
					[ 'mytheme/event-details', { layout: 'inline' } ],
				],
			],
			[ 'core/query-no-results', {}, [ [ 'core/paragraph', { placeholder: __( 'No upcoming events.', 'mytheme-functionality' ) } ] ] ],
		],
	} );
} )( window.wp );
