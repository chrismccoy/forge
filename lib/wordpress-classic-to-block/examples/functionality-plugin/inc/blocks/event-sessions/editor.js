/**
 * Event Sessions — repeater parent. Rows are child blocks (mytheme/event-session),
 * so add / remove / reorder use native block-editor controls.
 */
( function ( wp ) {
	const { registerBlockType } = wp.blocks;
	const { createElement: el } = wp.element;
	const { InnerBlocks, useBlockProps, useInnerBlocksProps } = wp.blockEditor;

	registerBlockType( 'mytheme/event-sessions', {
		edit: function Edit() {
			const blockProps = useBlockProps( { className: 'event-sessions' } );
			const innerBlocksProps = useInnerBlocksProps( blockProps, {
				allowedBlocks: [ 'mytheme/event-session' ],
				template: [ [ 'mytheme/event-session' ] ],
				renderAppender: InnerBlocks.ButtonBlockAppender,
			} );
			return el( 'ul', innerBlocksProps );
		},
		// Dynamic parent with inner blocks: save the children, render the wrapper in PHP.
		save: () => el( InnerBlocks.Content ),
	} );
} )( window.wp );
