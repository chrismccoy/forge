<?php
/**
 * Field map for hand-coded "Product" metaboxes, rebuilt for the block editor.
 *
 * Modeled on a real classic theme whose products are regular posts with three
 * hand-coded metaboxes (Product Details, Pricing & Actions, Download File) and one
 * save_post handler. One map drives register_post_meta() AND the editor panel.
 *
 * THIS SHOWS THE PATTERN, NOT THE VALUES. In a real migration:
 * - Keep the theme's own meta keys ('mytheme_' stands in for the theme's prefix).
 * - Copy allowlists verbatim from the theme's helper functions; a shorter list
 *   blanks existing values on the next save.
 * - Mirror each sanitizer exactly, including where the handler had NO allowlist.
 *
 * @package MythemeFunctionality
 */

declare( strict_types=1 );

/**
 * Allowed icon keys — copied verbatim from the classic theme's helper (shortened
 * here for the example). It moves to the plugin because both the schema and the
 * renderer need it.
 */
function mytheme_func_icon_keys(): array {
	return array( 'folder', 'box', 'bolt', 'lock', 'layers', 'grid', 'book', 'download', 'search', 'chat', 'github' );
}

/**
 * Accent slugs offered in the editor for repeater rows. These are DATA values
 * (colour names stored in meta), not theme.json palette slugs: the palette stays
 * role-based, and render code maps data slug → colour (see coded-metaboxes.md).
 * The classic handler only ran
 * sanitize_key() on this column (no allowlist), so the registered sanitizer does the
 * same (see register.php) and these choices are UI suggestions, not a restriction.
 * Tighten to an allowlist only after auditing stored values.
 */
function mytheme_func_accent_slugs(): array {
	return array( 'emerald', 'blue', 'amber', 'rose', 'violet', 'teal' );
}

/**
 * The field map. Types:
 *   text | textarea | html | url | toggle | select | attachment | repeater
 * Repeater columns: [ key, label, type ] with type text | textarea | int | select.
 */
function mytheme_func_product_fields(): array {
	return array(
		// Product Details.
		'mytheme_subtitle'    => array( 'type' => 'text', 'label' => __( 'Subtitle', 'mytheme-functionality' ), 'panel' => 'details' ),
		'mytheme_icon'        => array( 'type' => 'select', 'label' => __( 'Icon', 'mytheme-functionality' ), 'panel' => 'details', 'options' => mytheme_func_icon_keys() ),
		'mytheme_overview'    => array( 'type' => 'html', 'label' => __( 'Overview', 'mytheme-functionality' ), 'panel' => 'details' ),
		'mytheme_updates'     => array( 'type' => 'text', 'label' => __( 'Updates', 'mytheme-functionality' ), 'panel' => 'details' ),
		'mytheme_support'     => array( 'type' => 'text', 'label' => __( 'Support', 'mytheme-functionality' ), 'panel' => 'details' ),
		'mytheme_compat'      => array( 'type' => 'text', 'label' => __( 'Compatible', 'mytheme-functionality' ), 'panel' => 'details' ),
		// Pricing & Actions.
		'mytheme_price'       => array( 'type' => 'text', 'label' => __( 'Price', 'mytheme-functionality' ), 'panel' => 'pricing' ),
		'mytheme_price_note'  => array( 'type' => 'text', 'label' => __( 'Card suffix', 'mytheme-functionality' ), 'panel' => 'pricing' ),
		'mytheme_price_terms' => array( 'type' => 'text', 'label' => __( 'Terms line', 'mytheme-functionality' ), 'panel' => 'pricing' ),
		'mytheme_version'     => array( 'type' => 'text', 'label' => __( 'Version', 'mytheme-functionality' ), 'panel' => 'pricing' ),
		'mytheme_featured'    => array( 'type' => 'toggle', 'label' => __( 'Featured (dark card)', 'mytheme-functionality' ), 'panel' => 'pricing' ),
		'mytheme_buy_label'   => array( 'type' => 'text', 'label' => __( 'Buy button label', 'mytheme-functionality' ), 'panel' => 'pricing' ),
		'mytheme_buy_url'     => array( 'type' => 'url', 'label' => __( 'Buy URL', 'mytheme-functionality' ), 'panel' => 'pricing' ),
		'mytheme_demo_label'  => array( 'type' => 'text', 'label' => __( 'Demo button label', 'mytheme-functionality' ), 'panel' => 'pricing' ),
		'mytheme_demo_url'    => array( 'type' => 'url', 'label' => __( 'Demo URL', 'mytheme-functionality' ), 'panel' => 'pricing' ),
		// Download File.
		'mytheme_filename'    => array( 'type' => 'attachment', 'label' => __( 'Download file', 'mytheme-functionality' ), 'panel' => 'download' ),
		// Repeaters (serialized arrays of rows in the classic theme).
		'mytheme_highlights'  => array(
			'type'    => 'repeater',
			'label'   => __( 'Highlight boxes', 'mytheme-functionality' ),
			'panel'   => 'details',
			'columns' => array( array( 'label', __( 'Label', 'mytheme-functionality' ), 'text' ), array( 'text', __( 'Text', 'mytheme-functionality' ), 'textarea' ) ),
		),
		'mytheme_terminal'    => array(
			'type'    => 'repeater',
			'label'   => __( 'Preview cards', 'mytheme-functionality' ),
			'panel'   => 'details',
			// No 'max': the classic handler stored every row; the template shows the first three.
			'columns' => array(
				array( 'label', __( 'Label', 'mytheme-functionality' ), 'text' ),
				array( 'text', __( 'Text', 'mytheme-functionality' ), 'textarea' ),
				array( 'pct', __( 'Bar %', 'mytheme-functionality' ), 'int' ),
				array( 'color', __( 'Bar colour', 'mytheme-functionality' ), 'select', mytheme_func_accent_slugs() ),
			),
		),
		'mytheme_features'    => array(
			'type'    => 'repeater',
			'label'   => __( 'Features', 'mytheme-functionality' ),
			'panel'   => 'details',
			'columns' => array( array( 'title', __( 'Title', 'mytheme-functionality' ), 'text' ), array( 'desc', __( 'Description', 'mytheme-functionality' ), 'textarea' ) ),
		),
		'mytheme_changelog'   => array(
			'type'    => 'repeater',
			'label'   => __( 'Changelog', 'mytheme-functionality' ),
			'panel'   => 'details',
			'columns' => array(
				array( 'version', __( 'Version', 'mytheme-functionality' ), 'text' ),
				array( 'date', __( 'Date', 'mytheme-functionality' ), 'text' ),
				array( 'note', __( 'Note', 'mytheme-functionality' ), 'textarea' ),
			),
		),
		'mytheme_includes'    => array(
			'type'    => 'repeater',
			'label'   => __( 'Includes', 'mytheme-functionality' ),
			'panel'   => 'details',
			'columns' => array( array( 'text', __( 'Item', 'mytheme-functionality' ), 'text' ) ),
		),
	);
}
