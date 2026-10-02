<?php
/**
 * Registers every product field from the field map with REST schemas and sanitizers
 * that reproduce the classic save_post handler, so REST saves store the same shapes.
 *
 * Runs on every request — never behind is_admin(). Block-editor saves are REST
 * requests, where is_admin() is false.
 *
 * @package MythemeFunctionality
 */

declare( strict_types=1 );

/**
 * Sanitize one repeater cell the way the classic handler did.
 *
 * @param mixed $value  Raw cell.
 * @param array $column [ key, label, type, options? ].
 */
function mytheme_func_sanitize_cell( $value, array $column ) {
	switch ( $column[2] ) {
		case 'textarea':
			return sanitize_textarea_field( (string) $value );
		case 'int':
			return max( 0, min( 100, absint( $value ) ) ); // Classic handler clamped 0–100.
		case 'select':
			// Mirrors the classic handler: sanitize_key only, no allowlist, so existing
			// off-list values (e.g. 'red', 'zinc') survive a save.
			return sanitize_key( (string) $value );
		default:
			return sanitize_text_field( (string) $value );
	}
}

/**
 * Build register_post_meta() args for one field.
 *
 * Rules learned from a real migration:
 * - Every key gets a `default` ('' / 0 / []). The block editor sends the whole meta
 *   object back on save; without a default, REST compares an untouched '' against
 *   "no row" and writes an empty row for every key on every save.
 * - No `enum` / `additionalProperties: false` in REST schemas. The editor echoes
 *   stored values back; one legacy off-list value would fail the whole save with a
 *   400. Allowlists live in the sanitizer, exactly as in the classic handler.
 * - Empty values are deleted server-side (derived.php), not only by the panel.
 */
function mytheme_func_meta_args( array $field ): array {

	switch ( $field['type'] ) {
		case 'toggle':
			// Classic stored '1' or deleted the row. Keep the string so templates comparing '1' still work.
			return array(
				'type'              => 'string',
				'default'           => '',
				'show_in_rest'      => true,
				'sanitize_callback' => static fn( $v ): string => $v ? '1' : '',
			);

		case 'select':
			return array(
				'type'              => 'string',
				'default'           => '',
				'show_in_rest'      => true,
				// Off-list → '' → deleted by the empty-value hook, as the classic handler did.
				'sanitize_callback' => static fn( $v ): string => in_array( $v, $field['options'], true ) ? $v : '',
			);

		case 'url':
			return array( 'type' => 'string', 'default' => '', 'show_in_rest' => true, 'sanitize_callback' => 'esc_url_raw' );

		case 'html':
			return array( 'type' => 'string', 'default' => '', 'show_in_rest' => true, 'sanitize_callback' => 'wp_kses_post' );

		case 'textarea':
			return array( 'type' => 'string', 'default' => '', 'show_in_rest' => true, 'sanitize_callback' => 'sanitize_textarea_field' );

		case 'attachment':
			return array( 'type' => 'integer', 'default' => 0, 'show_in_rest' => true, 'sanitize_callback' => 'absint' );

		case 'repeater':
			$properties = array();
			foreach ( $field['columns'] as $column ) {
				$properties[ $column[0] ] = array( 'type' => 'int' === $column[2] ? 'integer' : 'string' );
			}
			return array(
				'type'              => 'array',
				'default'           => array(),
				'show_in_rest'      => array(
					'schema' => array(
						'type'  => 'array',
						'items' => array( 'type' => 'object', 'properties' => $properties ),
					),
				),
				'sanitize_callback' => static function ( $rows ) use ( $field ): array {
					$clean = array();
					foreach ( (array) $rows as $row ) {
						$out      = array();
						$has_data = false;
						foreach ( $field['columns'] as $column ) {
							$out[ $column[0] ] = mytheme_func_sanitize_cell( $row[ $column[0] ] ?? '', $column );
							$has_data          = $has_data || '' !== trim( (string) $out[ $column[0] ] );
						}
						if ( $has_data ) { // Classic handler dropped empty rows.
							$clean[] = $out;
						}
					}
					return $clean; // No row cap: the classic handler stored every row.
				},
			);

		default:
			return array( 'type' => 'string', 'default' => '', 'show_in_rest' => true, 'sanitize_callback' => 'sanitize_text_field' );
	}
}

add_action( 'init', static function (): void {
	foreach ( mytheme_func_product_fields() as $key => $field ) {
		register_post_meta(
			'post',
			$key,
			array_merge(
				array(
					'single'        => true,
					'auth_callback' => static fn( $allowed, $meta_key, $post_id ): bool => current_user_can( 'edit_post', $post_id ),
				),
				mytheme_func_meta_args( $field )
			)
		);
	}

	// Same key on pages, different sanitizer: the classic page metabox stored plain text.
	register_post_meta(
		'page',
		'mytheme_overview',
		array(
			'type'              => 'string',
			'single'            => true,
			'default'           => '',
			'show_in_rest'      => true,
			'sanitize_callback' => 'sanitize_textarea_field',
			'auth_callback'     => static fn( $allowed, $meta_key, $post_id ): bool => current_user_can( 'edit_post', $post_id ),
		)
	);
} );
