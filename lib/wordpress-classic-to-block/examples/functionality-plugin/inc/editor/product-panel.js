/**
 * Product panels — replaces hand-coded metaboxes. No build step (wp.* globals).
 *
 * Config-driven: window.mythemeProductFields comes from the same PHP field map that
 * registers the meta, so labels, choices, and repeater columns cannot drift.
 * Empty values are sent as null, which makes REST DELETE the meta row — matching the
 * classic handler's "store or delete" behavior (queries using EXISTS depend on it).
 */
( function ( wp, FIELDS ) {
	const { registerPlugin } = wp.plugins;
	const Panel = ( wp.editor && wp.editor.PluginDocumentSettingPanel ) || wp.editPost.PluginDocumentSettingPanel;
	const { useSelect } = wp.data;
	const { useEntityProp } = wp.coreData;
	const { createElement: el, Fragment } = wp.element;
	const { MediaUpload, MediaUploadCheck } = wp.blockEditor;
	const { TextControl, TextareaControl, ToggleControl, SelectControl, Button, Flex, FlexBlock, FlexItem, BaseControl } = wp.components;
	const { __, sprintf } = wp.i18n;

	const PANELS = [
		[ 'details', __( 'Product details', 'mytheme-functionality' ) ],
		[ 'pricing', __( 'Pricing & actions', 'mytheme-functionality' ) ],
		[ 'download', __( 'Download file', 'mytheme-functionality' ) ],
	];
	// '' → null so REST deletes the row. 0 counts as empty only for attachment IDs.
	const blankToNull = ( v, type ) => ( v === '' || v === undefined || ( type === 'attachment' && v === 0 ) ? null : v );
	const common = { __nextHasNoMarginBottom: true };

	function choices( options, current, removedOnSave ) {
		const list = [ { label: __( '— Automatic —', 'mytheme-functionality' ), value: '' } ].concat(
			options.map( ( o ) => ( { label: o, value: o } ) )
		);
		// Keep a stored off-list value visible. Top-level selects are allowlisted by the
		// sanitizer, so say it will be removed on save instead of silently dropping it.
		if ( current && options.indexOf( current ) === -1 ) {
			list.push( {
				label: removedOnSave ? sprintf( __( '%s (removed on save)', 'mytheme-functionality' ), current ) : current,
				value: current,
			} );
		}
		return list;
	}

	function Cell( { column, value, onChange } ) {
		const [ key, label, type, options ] = column;
		if ( type === 'textarea' ) {
			return el( TextareaControl, { ...common, label, rows: 2, value: value || '', onChange } );
		}
		if ( type === 'int' ) {
			return el( TextControl, { ...common, label, type: 'number', min: 0, max: 100, value: value ?? '', onChange: ( v ) => onChange( v === '' ? 0 : parseInt( v, 10 ) ) } );
		}
		if ( type === 'select' ) {
			// Repeater cells have no allowlist: an off-list value is kept as is.
			return el( SelectControl, { ...common, label, value: value || '', options: choices( options || [], value, false ), onChange } );
		}
		return el( TextControl, { ...common, label, value: value || '', onChange } );
	}

	function Repeater( { field, rows, onChange } ) {
		const list = Array.isArray( rows ) ? rows : [];
		const update = ( index, key, value ) =>
			onChange( list.map( ( row, i ) => ( i === index ? { ...row, [ key ]: value } : row ) ) );
		const move = ( from, to ) => {
			const next = list.slice();
			next.splice( to, 0, next.splice( from, 1 )[ 0 ] );
			onChange( next );
		};
		const blank = () => Object.fromEntries( field.columns.map( ( c ) => [ c[ 0 ], c[ 2 ] === 'int' ? 0 : '' ] ) );
		const full = field.max && list.length >= field.max;

		return el(
			BaseControl,
			{ __nextHasNoMarginBottom: true, label: field.label, id: 'rep-' + field.label },
			list.map( ( row, index ) =>
				el(
					'div',
					{ key: index, style: { border: '1px solid #ddd', padding: '8px', marginBottom: '8px' } },
					field.columns.map( ( column ) =>
						el( Cell, { key: column[ 0 ], column, value: row[ column[ 0 ] ], onChange: ( v ) => update( index, column[ 0 ], v ) } )
					),
					el(
						Flex,
						{ justify: 'flex-start' },
						el( Button, { size: 'small', icon: 'arrow-up-alt2', label: __( 'Move up', 'mytheme-functionality' ), disabled: index === 0, onClick: () => move( index, index - 1 ) } ),
						el( Button, { size: 'small', icon: 'arrow-down-alt2', label: __( 'Move down', 'mytheme-functionality' ), disabled: index === list.length - 1, onClick: () => move( index, index + 1 ) } ),
						el( Button, { size: 'small', isDestructive: true, variant: 'link', onClick: () => onChange( list.filter( ( _, i ) => i !== index ) ) }, __( 'Remove', 'mytheme-functionality' ) )
					)
				)
			),
			el(
				Button,
				{ variant: 'secondary', disabled: full, onClick: () => onChange( list.concat( [ blank() ] ) ) },
				full ? sprintf( __( 'Maximum %d rows', 'mytheme-functionality' ), field.max ) : __( 'Add row', 'mytheme-functionality' )
			)
		);
	}

	function AttachmentField( { field, value, onChange } ) {
		// getMedia() is deprecated; read the attachment as an entity record.
		const media = useSelect( ( select ) => ( value ? select( 'core' ).getEntityRecord( 'postType', 'attachment', value ) : null ), [ value ] );
		const name = media && media.source_url ? media.source_url.split( '/' ).pop() : '';
		return el(
			BaseControl,
			{ __nextHasNoMarginBottom: true, label: field.label, id: 'att-' + field.label },
			el( 'p', null, value ? name || '#' + value : __( 'No file selected.', 'mytheme-functionality' ) ),
			el(
				MediaUploadCheck,
				null,
				el( MediaUpload, {
					value,
					onSelect: ( item ) => onChange( item.id ),
					render: ( { open } ) => el( Button, { variant: 'secondary', onClick: open }, __( 'Select file', 'mytheme-functionality' ) ),
				} )
			),
			value ? el( Button, { variant: 'link', isDestructive: true, onClick: () => onChange( null ) }, __( 'Clear', 'mytheme-functionality' ) ) : null
		);
	}

	function Field( { name, field, meta, setMeta } ) {
		const value = meta[ name ];
		const set = ( v ) => setMeta( { ...meta, [ name ]: field.type === 'repeater' ? ( v.length ? v : null ) : blankToNull( v, field.type ) } );

		switch ( field.type ) {
			case 'toggle':
				return el( ToggleControl, { ...common, label: field.label, checked: value === '1', onChange: ( on ) => set( on ? '1' : '' ) } );
			case 'select':
				return el( SelectControl, { ...common, label: field.label, value: value || '', options: choices( field.options, value, true ), onChange: set } );
			case 'html':
			case 'textarea':
				return el( TextareaControl, { ...common, label: field.label, rows: 4, value: value || '', onChange: set } );
			case 'url':
				return el( TextControl, { ...common, label: field.label, type: 'url', value: value || '', onChange: set } );
			case 'attachment':
				return el( AttachmentField, { field, value, onChange: set } );
			case 'repeater':
				return el( Repeater, { field, rows: value, onChange: set } );
			default:
				return el( TextControl, { ...common, label: field.label, value: value || '', onChange: set } );
		}
	}

	function ProductPanels() {
		const postType = useSelect( ( select ) => select( 'core/editor' ).getCurrentPostType(), [] );
		const [ meta, setMeta ] = useEntityProp( 'postType', 'post', 'meta' );
		if ( 'post' !== postType || ! meta ) {
			return null;
		}
		return el(
			Fragment,
			null,
			PANELS.map( ( [ id, title ] ) =>
				el(
					Panel,
					{ key: id, name: 'mytheme-product-' + id, title },
					Object.entries( FIELDS )
						.filter( ( [ , field ] ) => field.panel === id )
						.map( ( [ name, field ] ) => el( Field, { key: name, name, field, meta, setMeta } ) )
				)
			)
		);
	}

	registerPlugin( 'mytheme-product-panels', { render: ProductPanels } );
} )( window.wp, window.mythemeProductFields || {} );
