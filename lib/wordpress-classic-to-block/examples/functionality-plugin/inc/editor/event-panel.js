/**
 * "Event details" panel in the post sidebar — replaces a complex metabox for
 * post-level fields stored in meta. No build step (wp.* globals).
 *
 * - event_date: required; publishing is locked until it is set (UX only — the
 *   server validates too, see inc/post-meta.php).
 * - event_related: relationship field (array of event IDs) via FormTokenField.
 */
( function ( wp ) {
	const { registerPlugin } = wp.plugins;
	// WP 6.6+ exports the panel from wp.editor; older versions from wp.editPost.
	const PluginDocumentSettingPanel =
		( wp.editor && wp.editor.PluginDocumentSettingPanel ) || wp.editPost.PluginDocumentSettingPanel;
	const { useSelect, useDispatch } = wp.data;
	const { useEntityProp } = wp.coreData;
	const { createElement: el, useEffect } = wp.element;
	const { TextControl, FormTokenField } = wp.components;
	const { __ } = wp.i18n;

	const LOCK = 'mytheme-event-date';
	const titleOf = ( post ) => ( post.title && ( post.title.raw || post.title.rendered ) ) || '#' + post.id;

	function EventPanel() {
		const { postType, postId } = useSelect( ( select ) => ( {
			postType: select( 'core/editor' ).getCurrentPostType(),
			postId: select( 'core/editor' ).getCurrentPostId(),
		} ), [] );
		const [ meta, setMeta ] = useEntityProp( 'postType', 'event', 'meta' );
		const { lockPostSaving, unlockPostSaving } = useDispatch( 'core/editor' );
		const events = useSelect(
			( select ) =>
				select( 'core' ).getEntityRecords( 'postType', 'event', { per_page: 100, exclude: [ postId ] } ) || [],
			[ postId ]
		);

		const date = ( meta && meta.event_date ) || '';
		useEffect( () => {
			if ( 'event' !== postType ) {
				return;
			}
			if ( date ) {
				unlockPostSaving( LOCK );
			} else {
				lockPostSaving( LOCK );
			}
		}, [ date, postType ] );

		if ( 'event' !== postType || ! meta ) {
			return null;
		}

		const relatedIds = meta.event_related || [];
		const tokens = relatedIds.map( ( id ) => {
			const match = events.find( ( e ) => e.id === id );
			return match ? titleOf( match ) : '#' + id;
		} );

		return el(
			PluginDocumentSettingPanel,
			{ name: 'mytheme-event-details', title: __( 'Event details', 'mytheme-functionality' ) },
			el( TextControl, {
				type: 'date',
				label: __( 'Event date', 'mytheme-functionality' ),
				help: date ? '' : __( 'Required. Publishing is disabled until a date is set.', 'mytheme-functionality' ),
				value: date,
				onChange: ( value ) => setMeta( { ...meta, event_date: value } ),
				__nextHasNoMarginBottom: true,
			} ),
			el( FormTokenField, {
				label: __( 'Related events', 'mytheme-functionality' ),
				value: tokens,
				suggestions: events.map( titleOf ),
				__experimentalExpandOnFocus: true,
				onChange: ( next ) =>
					setMeta( {
						...meta,
						event_related: next
							.map( ( token ) => {
								const match = events.find( ( e ) => titleOf( e ) === token );
								return match ? match.id : relatedIds[ tokens.indexOf( token ) ];
							} )
							.filter( Boolean ),
					} ),
			} )
		);
	}

	registerPlugin( 'mytheme-event-panel', { render: EventPanel } );
} )( window.wp );
