<?php
/**
 * Menu-item icons. The classic theme stored a Font Awesome class list in
 * `_mytheme_menu_icon` meta on each nav_menu_item and printed <i class="…"> from a
 * custom Walker. The Navigation block has no per-item meta, and importing a classic
 * menu into a wp_navigation post drops that meta.
 *
 * New storage: the icon classes go in the link block's `className`, prefixed with
 * `icon-` markers (e.g. "icon-fa-solid icon-fa-bolt"). This filter turns them back
 * into an <i> element at render time, so editors set icons via Advanced → Additional CSS class.
 *
 * @package MythemeFunctionality
 */

declare( strict_types=1 );

/**
 * Split "icon-…" classes out of a className string.
 *
 * @return array{0: string, 1: string} [ remaining classes, icon classes ].
 */
function mytheme_func_split_icon_classes( string $class_name ): array {
	$keep = array();
	$icon = array();
	foreach ( preg_split( '/\s+/', trim( $class_name ) ) ?: array() as $class ) {
		if ( str_starts_with( $class, 'icon-' ) && strlen( $class ) > 5 ) {
			$icon[] = sanitize_html_class( substr( $class, 5 ) );
		} elseif ( '' !== $class ) {
			$keep[] = $class;
		}
	}
	return array( implode( ' ', $keep ), implode( ' ', $icon ) );
}

/*
 * Only `render_block` is used: the Navigation block renders its links with
 * WP_Block::render() directly, so `render_block_data` does not reach them, but
 * `render_block` always fires.
 */
add_filter( 'render_block', static function ( string $html, array $block ): string {
	if ( ! in_array( $block['blockName'] ?? '', array( 'core/navigation-link', 'core/navigation-submenu' ), true ) ) {
		return $html;
	}
	[ , $icon ] = mytheme_func_split_icon_classes( (string) ( $block['attrs']['className'] ?? '' ) );
	if ( '' === $icon ) {
		return $html;
	}

	// Remove the icon-* marker classes from the <li>.
	$tags = new WP_HTML_Tag_Processor( $html );
	if ( $tags->next_tag( 'li' ) ) {
		foreach ( preg_split( '/\s+/', $icon ) as $class ) {
			$tags->remove_class( 'icon-' . $class );
		}
		$html = $tags->get_updated_html();
	}

	// Insert the icon as a sibling BEFORE the label span (inside the link). Putting it
	// inside the label made it wrap above the text in no-wrap menu rows. Style the link
	// with `display:inline-flex; align-items:center; gap:.4em` in theme CSS.
	$marker = '<span class="wp-block-navigation-item__label"';
	$pos    = strpos( $html, $marker );
	if ( false === $pos ) {
		return $html;
	}
	return substr( $html, 0, $pos ) . '<i class="' . esc_attr( $icon ) . '" aria-hidden="true"></i>' . substr( $html, $pos );
}, 10, 2 );
