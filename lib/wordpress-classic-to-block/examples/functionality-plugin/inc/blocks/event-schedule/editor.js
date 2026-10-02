/**
 * Minimal editor registration so the Site Editor can preview this server-rendered block.
 * Plain JS against wp.* globals — no build step. Not custom editor UI: the preview
 * comes from render.php via ServerSideRender.
 */
( function ( wp ) {
	const { registerBlockType } = wp.blocks;
	const { createElement: el } = wp.element;
	const { useBlockProps } = wp.blockEditor;
	const ServerSideRender = wp.serverSideRender;

	registerBlockType( 'mytheme/event-schedule', {
		edit: function Edit() {
			return el(
				'div',
				useBlockProps(),
				el( ServerSideRender, { block: 'mytheme/event-schedule' } )
			);
		},
		save: () => null, // Dynamic block: front end comes from render.php.
	} );
} )( window.wp );
