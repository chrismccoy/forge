<?php
/**
 * Values the classic save_post handler computed from other fields.
 * REST saves never run that handler, so recompute on meta-change hooks instead.
 * These hooks also fire for WP-CLI migrations and any other update_post_meta() call.
 *
 * @package MythemeFunctionality
 */

declare( strict_types=1 );

/**
 * File size and format derived from the download attachment.
 */
function mytheme_func_sync_file_meta( $meta_id, int $post_id, string $meta_key, $value ): void {
	if ( 'mytheme_filename' !== $meta_key ) {
		return;
	}
	// Mirrors the classic handler: recompute only when the file exists; a missing file
	// keeps the previous values. Clearing the ID (deleted_post_meta below) clears them.
	$path = $value ? get_attached_file( (int) $value ) : '';
	if ( $path && file_exists( $path ) ) {
		update_post_meta( $post_id, 'mytheme_file_size', size_format( (int) filesize( $path ) ) );
		update_post_meta( $post_id, 'mytheme_file_format', strtoupper( pathinfo( $path, PATHINFO_EXTENSION ) ) );
	}
}
add_action( 'added_post_meta', 'mytheme_func_sync_file_meta', 10, 4 );
add_action( 'updated_post_meta', 'mytheme_func_sync_file_meta', 10, 4 );

add_action( 'deleted_post_meta', static function ( $meta_ids, int $post_id, string $meta_key ): void {
	if ( 'mytheme_filename' === $meta_key ) {
		delete_post_meta( $post_id, 'mytheme_file_size' );
		delete_post_meta( $post_id, 'mytheme_file_format' );
	}
}, 10, 3 );

/**
 * Store-or-delete on the server. The classic handler deleted empty values; REST
 * clients, WP-CLI, imports, and update_post_meta() calls would otherwise store ''.
 */
function mytheme_func_delete_empty_meta( $meta_id, int $post_id, string $meta_key, $value ): void {
	if ( ! array_key_exists( $meta_key, mytheme_func_product_fields() ) ) {
		return;
	}
	$is_attachment = 'attachment' === mytheme_func_product_fields()[ $meta_key ]['type'];
	$empty         = '' === $value || array() === $value || ( $is_attachment && 0 === (int) $value );
	if ( $empty ) {
		delete_post_meta( $post_id, $meta_key );
	}
}
add_action( 'added_post_meta', 'mytheme_func_delete_empty_meta', 20, 4 );
add_action( 'updated_post_meta', 'mytheme_func_delete_empty_meta', 20, 4 );

/**
 * Cache invalidation. Keep the classic save_post flush (title, category, status, and
 * trash changes never touch meta) AND flush on meta hooks (REST writes meta after
 * save_post; migrations never fire save_post).
 */
add_action( 'save_post_post', static function (): void {
	delete_transient( 'mytheme_downloads' );
} );
function mytheme_func_flush_product_cache( $meta_id, int $post_id, string $meta_key ): void {
	if ( array_key_exists( $meta_key, mytheme_func_product_fields() ) ) {
		delete_transient( 'mytheme_downloads' );
	}
}
add_action( 'added_post_meta', 'mytheme_func_flush_product_cache', 10, 3 );
add_action( 'updated_post_meta', 'mytheme_func_flush_product_cache', 10, 3 );
add_action( 'deleted_post_meta', static function ( $meta_ids, int $post_id, string $meta_key ): void {
	mytheme_func_flush_product_cache( 0, $post_id, $meta_key );
}, 10, 3 );
