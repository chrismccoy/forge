/**
 * Event Details — block with sidebar options (no build step, wp.* globals).
 * Options live in block attributes; event data (date, venue) lives in post meta and is
 * rendered by render.php. The canvas shows a server-side preview.
 */
( function ( wp ) {
	const { registerBlockType } = wp.blocks;
	const { createElement: el, Fragment } = wp.element;
	const { __ } = wp.i18n;
	const { InspectorControls, MediaUpload, MediaUploadCheck, useBlockProps } = wp.blockEditor;
	const { PanelBody, SelectControl, ToggleControl, TextControl, Button } = wp.components;
	const ServerSideRender = wp.serverSideRender;

	registerBlockType( 'mytheme/event-details', {
		edit: function Edit( { attributes, setAttributes, context } ) {
			const { layout, bannerId, showCta, ctaLabel, ctaUrl } = attributes;

			const displayPanel = el(
				PanelBody,
				{ title: __( 'Display', 'mytheme-functionality' ) },
				el( SelectControl, {
					label: __( 'Layout', 'mytheme-functionality' ),
					value: layout,
					options: [
						{ label: __( 'Card', 'mytheme-functionality' ), value: 'card' },
						{ label: __( 'Inline', 'mytheme-functionality' ), value: 'inline' },
					],
					onChange: ( value ) => setAttributes( { layout: value } ),
					__nextHasNoMarginBottom: true,
				} )
			);

			// Conditional fields: CTA label and URL appear only when the toggle is on.
			const ctaPanel = el(
				PanelBody,
				{ title: __( 'Call to action', 'mytheme-functionality' ) },
				el( ToggleControl, {
					label: __( 'Show button', 'mytheme-functionality' ),
					checked: showCta,
					onChange: ( value ) => setAttributes( { showCta: value } ),
					__nextHasNoMarginBottom: true,
				} ),
				showCta
					? el(
						Fragment,
						null,
						el( TextControl, {
							label: __( 'Button label', 'mytheme-functionality' ),
							value: ctaLabel,
							onChange: ( value ) => setAttributes( { ctaLabel: value } ),
							__nextHasNoMarginBottom: true,
						} ),
						el( TextControl, {
							label: __( 'Button URL', 'mytheme-functionality' ),
							type: 'url',
							value: ctaUrl,
							onChange: ( value ) => setAttributes( { ctaUrl: value } ),
							__nextHasNoMarginBottom: true,
						} )
					)
					: null
			);

			const bannerPanel = el(
				PanelBody,
				{ title: __( 'Banner image', 'mytheme-functionality' ) },
				el(
					MediaUploadCheck,
					null,
					el( MediaUpload, {
						allowedTypes: [ 'image' ],
						value: bannerId,
						onSelect: ( media ) => setAttributes( { bannerId: media.id } ),
						render: ( { open } ) =>
							el(
								Button,
								{ variant: 'secondary', onClick: open },
								bannerId ? __( 'Replace image', 'mytheme-functionality' ) : __( 'Select image', 'mytheme-functionality' )
							),
					} )
				),
				bannerId
					? el(
						Button,
						{ variant: 'link', isDestructive: true, onClick: () => setAttributes( { bannerId: undefined } ) },
						__( 'Remove image', 'mytheme-functionality' )
					)
					: null
			);

			return el(
				Fragment,
				null,
				el( InspectorControls, null, displayPanel, ctaPanel, bannerPanel ),
				el(
					'div',
					useBlockProps(),
					el( ServerSideRender, {
						block: 'mytheme/event-details',
						attributes,
						// Lets render.php read the current post's meta during preview.
						// Only numeric IDs: in the Site Editor the post ID can be a template ID ('theme//slug'), which the renderer rejects with 400.
						urlQueryArgs: Number.isInteger( context.postId ) ? { post_id: context.postId } : {},
					} )
				)
			);
		},
		save: () => null,
	} );
} )( window.wp );
