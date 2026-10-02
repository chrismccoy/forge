/**
 * Event Session — one repeater row. Fields edited inline on the canvas.
 */
( function ( wp ) {
	const { registerBlockType } = wp.blocks;
	const { createElement: el } = wp.element;
	const { __ } = wp.i18n;
	const { RichText, useBlockProps } = wp.blockEditor;
	const { TextControl } = wp.components;

	registerBlockType( 'mytheme/event-session', {
		edit: function Edit( { attributes, setAttributes } ) {
			return el(
				'li',
				useBlockProps( { className: 'event-session' } ),
				el( TextControl, {
					label: __( 'Time', 'mytheme-functionality' ),
					hideLabelFromVision: true,
					placeholder: __( '09:00', 'mytheme-functionality' ),
					value: attributes.time,
					onChange: ( value ) => setAttributes( { time: value } ),
					__nextHasNoMarginBottom: true,
				} ),
				el( RichText, {
					tagName: 'strong',
					placeholder: __( 'Session title', 'mytheme-functionality' ),
					allowedFormats: [ 'core/italic', 'core/link' ],
					value: attributes.title,
					onChange: ( value ) => setAttributes( { title: value } ),
				} ),
				el( TextControl, {
					label: __( 'Speaker', 'mytheme-functionality' ),
					hideLabelFromVision: true,
					placeholder: __( 'Speaker', 'mytheme-functionality' ),
					value: attributes.speaker,
					onChange: ( value ) => setAttributes( { speaker: value } ),
					__nextHasNoMarginBottom: true,
				} )
			);
		},
		save: () => null,
	} );
} )( window.wp );
