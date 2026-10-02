<?php
/**
 * One-time WP-CLI migration: copies legacy underscore-prefixed meta values
 * to the new public meta keys registered via register_post_meta().
 * Run once after activating this plugin, before deactivating the classic theme.
 *
 * Usage: wp mytheme migrate-meta [--dry-run]
 *
 * @package MythemeFunctionality
 */

declare( strict_types=1 );

if ( ! defined( 'WP_CLI' ) || ! WP_CLI ) {
	return;
}

WP_CLI::add_command( 'mytheme migrate-meta', static function ( array $args, array $assoc_args ): void {
	$map = array(
		// old key => new key.
		'_event_venue' => 'event_venue',
	);
	$dry_run = isset( $assoc_args['dry-run'] );

	$post_ids = get_posts(
		array(
			'post_type'   => 'event',
			'numberposts' => -1,
			'post_status' => 'any',
			'fields'      => 'ids',
		)
	);

	$migrated = 0;
	foreach ( $post_ids as $post_id ) {
		foreach ( $map as $old_key => $new_key ) {
			$old_value = get_post_meta( $post_id, $old_key, true );
			if ( '' === $old_value ) {
				continue;
			}
			if ( ! $dry_run ) {
				update_post_meta( $post_id, $new_key, $old_value );
			}
			++$migrated;
		}
	}

	WP_CLI::success( sprintf( '%s%d values across %d events.', $dry_run ? '[dry run] would migrate ' : 'Migrated ', $migrated, count( $post_ids ) ) );
} );

/*
 * Repeater migration: serialized `_event_sessions` meta → mytheme/event-sessions inner blocks
 * appended to post_content. Leaves the old meta in place (delete it after verification).
 *
 * Usage: wp mytheme migrate-sessions [--dry-run]
 */
WP_CLI::add_command( 'mytheme migrate-sessions', static function ( array $args, array $assoc_args ): void {
	$dry_run  = isset( $assoc_args['dry-run'] );
	$post_ids = get_posts(
		array(
			'post_type'   => 'event',
			'numberposts' => -1,
			'post_status' => 'any',
			'fields'      => 'ids',
		)
	);

	$converted = 0;
	foreach ( $post_ids as $post_id ) {
		$sessions = get_post_meta( $post_id, '_event_sessions', true );
		if ( empty( $sessions ) || ! is_array( $sessions ) ) {
			continue;
		}

		$content = (string) get_post_field( 'post_content', $post_id, 'raw' );
		if ( has_block( 'mytheme/event-sessions', $content ) ) {
			WP_CLI::log( "Skip {$post_id}: already has a sessions block." );
			continue;
		}

		$children = array();
		foreach ( $sessions as $session ) {
			$children[] = array(
				'blockName'    => 'mytheme/event-session',
				'attrs'        => array(
					'time'    => sanitize_text_field( $session['time'] ?? '' ),
					'title'   => sanitize_text_field( $session['title'] ?? '' ),
					'speaker' => sanitize_text_field( $session['speaker'] ?? '' ),
				),
				'innerBlocks'  => array(),
				'innerHTML'    => '',
				'innerContent' => array(),
			);
		}

		$blocks   = parse_blocks( $content );
		$blocks[] = array(
			'blockName'    => 'mytheme/event-sessions',
			'attrs'        => array(),
			'innerBlocks'  => $children,
			'innerHTML'    => '',
			// One null placeholder per inner block tells serialize_blocks() where children go.
			'innerContent' => array_fill( 0, count( $children ), null ),
		);

		if ( ! $dry_run ) {
			$result = wp_update_post(
				wp_slash( array( 'ID' => $post_id, 'post_content' => serialize_blocks( $blocks ) ) ),
				true
			);
			if ( is_wp_error( $result ) ) {
				WP_CLI::warning( "Post {$post_id}: " . $result->get_error_message() );
				continue;
			}
		}
		++$converted;
	}

	WP_CLI::success( sprintf( '%s%d of %d events.', $dry_run ? '[dry run] would convert ' : 'Converted ', $converted, count( $post_ids ) ) );
} );

/*
 * Normalize hand-coded metabox values into the shapes the registered meta expects.
 * Every rule is a no-op for values already in the new shape, so it is safe to rerun.
 *
 * Usage: wp mytheme normalize-meta [--dry-run]
 */
WP_CLI::add_command( 'mytheme normalize-meta', static function ( array $args, array $assoc_args ): void {
	$dry_run = isset( $assoc_args['dry-run'] );

	$rules = array(
		// Checkbox stored as 'on' / 'yes' / 'true' by older forms → '1'; anything falsy → delete.
		'mytheme_featured' => static function ( $v ) {
			return in_array( strtolower( (string) $v ), array( '1', 'on', 'yes', 'true' ), true ) ? '1' : null;
		},
		// Media stored as a URL → attachment ID (null when the URL is not in the library).
		'mytheme_filename' => static function ( $v ) {
			if ( is_numeric( $v ) ) {
				return (int) $v;
			}
			$id = attachment_url_to_postid( (string) $v );
			if ( ! $id ) {
				WP_CLI::warning( "No attachment for URL: {$v}" );
			}
			return $id ?: null;
		},
	);

	// Free-text dates inside a repeater ("31/12/2024") → Y-m-d; unparseable values kept and reported.
	$repeater_dates = array( 'mytheme_changelog' => 'date' );

	$post_ids = get_posts( array( 'post_type' => 'post', 'numberposts' => -1, 'post_status' => 'any', 'fields' => 'ids' ) );
	$changed  = 0;

	foreach ( $post_ids as $post_id ) {
		foreach ( $rules as $key => $rule ) {
			if ( ! metadata_exists( 'post', $post_id, $key ) ) {
				continue;
			}
			$old = get_post_meta( $post_id, $key, true );
			$new = $rule( $old );
			if ( $new === $old ) {
				continue;
			}
			++$changed;
			if ( $dry_run ) {
				continue;
			}
			null === $new ? delete_post_meta( $post_id, $key ) : update_post_meta( $post_id, $key, $new );
		}

		foreach ( $repeater_dates as $key => $column ) {
			$rows = get_post_meta( $post_id, $key, true );
			if ( ! is_array( $rows ) ) {
				continue;
			}
			$dirty = false;
			foreach ( $rows as &$row ) {
				$raw = trim( (string) ( $row[ $column ] ?? '' ) );
				if ( '' === $raw || preg_match( '/^\d{4}-\d{2}-\d{2}$/', $raw ) ) {
					continue;
				}
				$date = DateTimeImmutable::createFromFormat( '!d/m/Y', $raw ) ?: date_create_immutable( $raw );
				if ( $date ) {
					$row[ $column ] = $date->format( 'Y-m-d' );
					$dirty          = true;
				} else {
					WP_CLI::warning( "Post {$post_id}: unparseable {$key}.{$column} '{$raw}' left as is." );
				}
			}
			unset( $row );
			if ( $dirty ) {
				++$changed;
				if ( ! $dry_run ) {
					update_post_meta( $post_id, $key, $rows );
				}
			}
		}
	}

	WP_CLI::success( sprintf( '%s%d values.', $dry_run ? '[dry run] would change ' : 'Changed ', $changed ) );
} );

/*
 * Per-post layout metabox → page template. Classic layout choices stored as meta
 * become custom templates registered in theme.json.
 *
 * Usage: wp mytheme migrate-layout [--dry-run]
 */
WP_CLI::add_command( 'mytheme migrate-layout', static function ( array $args, array $assoc_args ): void {
	$dry_run = isset( $assoc_args['dry-run'] );
	$map     = array( // meta value => customTemplates slug ('' = default template).
		'full-width'    => 'full-width',
		'no-sidebar'    => 'full-width',
		'sidebar-left'  => '',
		'sidebar-right' => '',
	);

	$posts = get_posts(
		array(
			'post_type'   => array( 'post', 'page' ),
			'numberposts' => -1,
			'post_status' => 'any',
			'meta_key'    => '_mytheme_layout', // phpcs:ignore WordPress.DB.SlowDBQuery
			'fields'      => 'ids',
		)
	);
	foreach ( $posts as $post_id ) {
		$layout = (string) get_post_meta( $post_id, '_mytheme_layout', true );
		if ( ! array_key_exists( $layout, $map ) ) {
			WP_CLI::warning( "Post {$post_id}: unknown layout '{$layout}'." );
			continue;
		}
		if ( ! $dry_run && '' !== $map[ $layout ] ) {
			update_post_meta( $post_id, '_wp_page_template', $map[ $layout ] );
		}
		WP_CLI::log( "{$post_id}: {$layout} -> " . ( $map[ $layout ] ?: 'default' ) );
	}
} );

/*
 * Copy classic menu-item icons onto the Navigation block links created by
 * "Import Classic Menus". Matches links by URL; ambiguous or missing matches are reported.
 *
 * Usage: wp mytheme migrate-nav-icons <classic-menu-id> <wp_navigation-post-id> [--dry-run]
 */
WP_CLI::add_command( 'mytheme migrate-nav-icons', static function ( array $args, array $assoc_args ): void {
	[ $menu_id, $nav_id ] = array_map( 'absint', $args + array( 0, 0 ) );
	$dry_run = isset( $assoc_args['dry-run'] );

	$icons = array();
	foreach ( wp_get_nav_menu_items( $menu_id ) ?: array() as $item ) {
		$icon = (string) get_post_meta( $item->ID, '_mytheme_menu_icon', true );
		if ( '' !== $icon ) {
			$icons[ untrailingslashit( $item->url ) ] = $icon;
		}
	}

	$walk = static function ( array $blocks ) use ( &$walk, $icons ): array {
		foreach ( $blocks as &$block ) {
			if ( in_array( $block['blockName'], array( 'core/navigation-link', 'core/navigation-submenu' ), true ) ) {
				$url = untrailingslashit( (string) ( $block['attrs']['url'] ?? '' ) );
				if ( isset( $icons[ $url ] ) ) {
					$classes = array_map( static fn( $c ) => 'icon-' . $c, preg_split( '/\s+/', $icons[ $url ] ) );
					$block['attrs']['className'] = trim( ( $block['attrs']['className'] ?? '' ) . ' ' . implode( ' ', $classes ) );
				}
			}
			if ( ! empty( $block['innerBlocks'] ) ) {
				$block['innerBlocks'] = $walk( $block['innerBlocks'] );
			}
		}
		return $blocks;
	};

	$nav = get_post( $nav_id );
	if ( ! $nav || 'wp_navigation' !== $nav->post_type ) {
		WP_CLI::error( 'Second argument must be a wp_navigation post ID.' );
	}
	$content = serialize_blocks( $walk( parse_blocks( $nav->post_content ) ) );
	if ( $dry_run ) {
		WP_CLI::log( $content );
		return;
	}
	wp_update_post( wp_slash( array( 'ID' => $nav_id, 'post_content' => $content ) ) );
	WP_CLI::success( sprintf( 'Applied %d icon mappings.', count( $icons ) ) );
} );

/*
 * Widgets → blocks. Reads the widget instances of one classic sidebar and writes the
 * block markup of the template part that replaces it, as a DATABASE copy of the part
 * (instances carry site-specific IDs and URLs, so the result never belongs in a theme file).
 *
 * Timing with a new slug: on activation core's retrieve_widgets() moves every instance to
 * wp_inactive_widgets.
 *   Before the switch: --source=live (default) with --theme=<new-block-theme-slug>, or --file.
 *   After the switch:  --source=theme-mods:<old-slug> (target defaults to the active theme).
 *
 * Usage: wp mytheme migrate-widgets <sidebar-id> <part-slug> [--source=live|theme-mods:<slug>] [--theme=<target-slug>] [--file=<path>] [--dry-run]
 *   --theme  theme slug that owns the saved part (required with --source=live unless --file/--dry-run)
 *   --file   writes the markup to a file for review instead of the database.
 */
WP_CLI::add_command( 'mytheme migrate-widgets', static function ( array $args, array $assoc_args ): void {
	[ $sidebar_id, $part_slug ] = $args + array( '', '' );
	$source = $assoc_args['source'] ?? 'live';
	$target = $assoc_args['theme'] ?? '';
	if ( 'live' === $source && '' === $target && ! isset( $assoc_args['file'] ) && ! isset( $assoc_args['dry-run'] ) ) {
		WP_CLI::error( 'With --source=live the active theme is still the classic one: pass --theme=<new-block-theme-slug>, or --file / --dry-run.' );
	}
	$target = $target ?: get_stylesheet();

	if ( str_starts_with( $source, 'theme-mods:' ) ) {
		$mods     = (array) get_option( 'theme_mods_' . substr( $source, 11 ), array() );
		$sidebars = (array) ( $mods['sidebars_widgets']['data'] ?? array() );
	} else {
		$sidebars = (array) get_option( 'sidebars_widgets', array() );
	}
	if ( empty( $sidebars[ $sidebar_id ] ) ) {
		WP_CLI::error( "Sidebar '{$sidebar_id}' has no widgets in source '{$source}'." );
	}

	$block = static function ( string $name, array $attrs = array(), string $html = '' ): array {
		return array(
			'blockName'    => $name,
			'attrs'        => $attrs,
			'innerBlocks'  => array(),
			'innerHTML'    => $html,
			'innerContent' => '' === $html ? array() : array( $html ),
		);
	};
	$heading = static fn( string $t ) => $block( 'core/heading', array( 'level' => 2 ), '<h2 class="wp-block-heading">' . esc_html( $t ) . '</h2>' );
	// Wrapper with children: innerContent needs one null slot per child between the wrapper HTML.
	$group = static function ( array $children, array $attrs = array(), string $tag = 'div' ): array {
		$class = 'wp-block-group' . ( empty( $attrs['className'] ) ? '' : ' ' . $attrs['className'] );
		$open  = '<' . $tag . ' class="' . esc_attr( $class ) . '">';
		$close = '</' . $tag . '>';
		return array(
			'blockName'    => 'core/group',
			'attrs'        => $attrs + ( 'div' === $tag ? array() : array( 'tagName' => $tag ) ),
			'innerBlocks'  => $children,
			'innerHTML'    => $open . $close,
			'innerContent' => array_merge( array( $open ), array_fill( 0, count( $children ), null ), array( $close ) ),
		);
	};
	// Titles as core widgets print them: the instance title, else the widget's default.
	$title = static fn( array $i, string $default ) => $heading( '' !== ( $i['title'] ?? '' ) ? $i['title'] : $default );

	/*
	 * id_base => callable( array $instance ): array of parsed blocks. Each mapping decides
	 * its own title: some widgets print the title inside their own markup, some print a
	 * default title when empty, some (horizontal ads) never print one. Map what the
	 * classic widget actually rendered.
	 */
	$map = array(
		// Core widgets.
		'tag_cloud'    => static fn( $i ) => array( $title( $i, __( 'Tags', 'mytheme-functionality' ) ), $block( 'core/tag-cloud', array( 'taxonomy' => $i['taxonomy'] ?? 'post_tag' ) ) ),
		'recent-posts' => static fn( $i ) => array( $title( $i, __( 'Recent Posts', 'mytheme-functionality' ) ), $block( 'core/latest-posts', array( 'postsToShow' => (int) ( $i['number'] ?? 5 ) ) ) ),
		'categories'   => static fn( $i ) => array( $title( $i, __( 'Categories', 'mytheme-functionality' ) ), $block( 'core/categories', array( 'showPostCounts' => ! empty( $i['count'] ), 'displayAsDropdown' => ! empty( $i['dropdown'] ) ) ) ),
		// Shared widget chrome kept on core blocks: one wrapper group per widget, styled once.
		'mytheme_recent' => static fn( $i ) => array( $group( array( $heading( $i['label'] ?? '' ), $block( 'core/latest-posts', array( 'postsToShow' => (int) ( $i['number'] ?? 5 ) ) ) ), array( 'className' => 'is-style-widget-frame' ), 'section' ) ),
		'custom_html'  => static fn( $i ) => array( $block( 'core/html', array(), (string) ( $i['content'] ?? '' ) ) ),
		// Custom widget kinds with core targets (adapt keys to the theme's widget form fields).
		'mytheme_ad'   => static fn( $i ) => array( $block( 'core/image', array( 'id' => (int) ( $i['image_id'] ?? 0 ), 'href' => $i['url'] ?? '', 'linkDestination' => 'custom', 'className' => 'is-style-ad' ), '<figure class="wp-block-image is-style-ad"><a href="' . esc_url( $i['url'] ?? '' ) . '">' . wp_get_attachment_image( (int) ( $i['image_id'] ?? 0 ), 'full' ) . '</a></figure>' ) ),
		'mytheme_pages' => static fn( $i ) => array( $block( 'core/page-list' ) ),
		// Custom widget → plugin block that renders its own title (no heading added).
		'mytheme_social' => static fn( $i ) => array( $block( 'mytheme/social-profiles', array_intersect_key( $i, array_flip( array( 'title', 'twitter', 'github' ) ) ) ) ),
	);

	$blocks = array();
	foreach ( $sidebars[ $sidebar_id ] as $widget_id ) {
		if ( ! preg_match( '/^(.+)-(\d+)$/', $widget_id, $m ) ) {
			continue;
		}
		[ , $id_base, $number ] = $m;
		$instance = (array) ( ( (array) get_option( 'widget_' . $id_base, array() ) )[ (int) $number ] ?? array() );

		if ( isset( $map[ $id_base ] ) ) {
			array_push( $blocks, ...$map[ $id_base ]( $instance ) );
			continue;
		}
		// Interim bridge. Core's renderer reads only encoded + hash (raw is for the editor),
		// and the hash uses this site's salts: valid only in this site's database copy.
		// Renders only while the widget class is registered (the plugin must carry it).
		$serialized = serialize( $instance );
		$blocks[]   = $block( 'core/legacy-widget', array(
			'idBase'   => $id_base,
			'instance' => array( 'encoded' => base64_encode( $serialized ), 'hash' => wp_hash( $serialized ), 'raw' => $instance ),
		) );
		WP_CLI::warning( "{$widget_id}: no mapping, emitted core/legacy-widget (interim bridge)." );
	}

	$markup = serialize_blocks( $blocks );
	if ( isset( $assoc_args['file'] ) ) {
		file_put_contents( $assoc_args['file'], $markup . "\n" ) || WP_CLI::error( 'Could not write file.' );
		WP_CLI::success( "Wrote {$assoc_args['file']} for review (do not commit it into the theme)." );
		return;
	}
	if ( isset( $assoc_args['dry-run'] ) ) {
		WP_CLI::log( $markup );
		return;
	}

	// Database copy of the part for the active theme.
	$existing = get_posts( array( 'post_type' => 'wp_template_part', 'name' => $part_slug, 'post_status' => 'any', 'numberposts' => 1, 'tax_query' => array( array( 'taxonomy' => 'wp_theme', 'field' => 'name', 'terms' => $target ) ) ) );
	$post_id  = wp_insert_post( wp_slash( array(
		'ID'           => $existing ? $existing[0]->ID : 0,
		'post_type'    => 'wp_template_part',
		'post_status'  => 'publish',
		'post_name'    => $part_slug,
		'post_title'   => ucwords( str_replace( '-', ' ', $part_slug ) ),
		'post_content' => $markup,
	) ), true );
	if ( is_wp_error( $post_id ) ) {
		WP_CLI::error( $post_id->get_error_message() );
	}
	wp_set_object_terms( $post_id, $target, 'wp_theme' );
	wp_set_object_terms( $post_id, 'uncategorized', 'wp_template_part_area' );
	WP_CLI::success( sprintf( 'Saved %d blocks to template part "%s" (post %d) for theme %s.', count( $blocks ), $part_slug, $post_id, $target ) );
} );
