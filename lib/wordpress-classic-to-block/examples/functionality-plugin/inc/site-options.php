<?php
/**
 * Site-wide fields that lived on a classic "Theme Options" page.
 * Data → registered options (REST-exposed). Display → a Block Bindings source.
 * Admin UI → fields on Settings → General (no custom page needed for a few fields).
 *
 * @package MythemeFunctionality
 */

declare( strict_types=1 );

/**
 * Allowlist: option name => label. Only these can be bound.
 */
function mytheme_func_site_fields(): array {
	return array(
		'mytheme_phone'   => __( 'Phone number', 'mytheme-functionality' ),
		'mytheme_address' => __( 'Postal address', 'mytheme-functionality' ),
	);
}

add_action( 'init', static function (): void {
	foreach ( mytheme_func_site_fields() as $option => $label ) {
		register_setting(
			'general',
			$option,
			array(
				'type'              => 'string',
				'default'           => '',
				'sanitize_callback' => 'sanitize_text_field',
				'show_in_rest'      => true,
			)
		);
	}

	register_block_bindings_source(
		'mytheme/site-option',
		array(
			'label'              => __( 'Site details', 'mytheme-functionality' ),
			'get_value_callback' => static function ( array $source_args ) {
				$key = $source_args['key'] ?? '';
				if ( ! array_key_exists( $key, mytheme_func_site_fields() ) ) {
					return null;
				}
				$value = get_option( $key, '' );
				return '' === $value ? null : esc_html( $value );
			},
		)
	);
} );

add_action( 'admin_init', static function (): void {
	foreach ( mytheme_func_site_fields() as $option => $label ) {
		add_settings_field(
			$option,
			esc_html( $label ),
			static function () use ( $option ): void {
				printf(
					'<input type="text" class="regular-text" name="%1$s" id="%1$s" value="%2$s" />',
					esc_attr( $option ),
					esc_attr( get_option( $option, '' ) )
				);
			},
			'general'
		);
	}
} );
