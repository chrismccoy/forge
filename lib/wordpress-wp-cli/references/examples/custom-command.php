<?php
/**
 * Example custom WP-CLI command: purge users of a role who have no content.
 *
 * Load per run without installing anything on the site:
 *     wp --require=custom-command.php example purge-users --role=subscriber --dry-run
 *
 * @package Example
 */

if ( ! defined( 'WP_CLI' ) || ! WP_CLI ) {
	return;
}

/**
 * Deletes users of one role who have no posts of any type and no comments.
 */
class Example_Purge_Users_Command extends WP_CLI_Command {

	/**
	 * Delete users of a role who have no posts and no comments.
	 *
	 * ## OPTIONS
	 *
	 * --role=<role>
	 * : Role to purge. Administrators are refused.
	 *
	 * [--batch-size=<number>]
	 * : Users checked per batch.
	 * ---
	 * default: 200
	 * ---
	 *
	 * [--dry-run]
	 * : Report what would be deleted, and change nothing.
	 *
	 * ## EXAMPLES
	 *
	 *     wp example purge-users --role=subscriber --dry-run
	 *     wp example purge-users --role=subscriber --batch-size=500
	 *
	 * @param array $args       Positional arguments.
	 * @param array $assoc_args Associative arguments.
	 */
	public function __invoke( $args, $assoc_args ) {
		$role       = (string) $assoc_args['role'];
		$batch_size = absint( $assoc_args['batch-size'] );
		$dry_run    = WP_CLI\Utils\get_flag_value( $assoc_args, 'dry-run', false );

		if ( 'administrator' === $role ) {
			WP_CLI::error( 'Refusing to purge administrators.' );
		}
		if ( ! wp_roles()->is_role( $role ) ) {
			WP_CLI::error( sprintf( 'Unknown role: %s', $role ) );
		}
		if ( $batch_size < 1 ) {
			WP_CLI::error( 'Batch size must be greater than zero.' );
		}

		require_once ABSPATH . 'wp-admin/includes/user.php';

		$matched = 0;
		$kept    = 0;
		$batch   = 0;
		$offset  = 0;

		do {
			// Deleting shifts later users forward, so a live run always reads
			// from the kept count; a dry run pages through normally.
			$user_ids = get_users(
				array(
					'role'    => $role,
					'fields'  => 'ID',
					'number'  => $batch_size,
					'offset'  => $dry_run ? $offset : $kept,
					'orderby' => 'ID',
				)
			);
			++$batch;

			foreach ( $user_ids as $user_id ) {
				$user_id  = (int) $user_id;
				// Any post type, any status (drafts and private posts count as
				// content); count_user_posts() would only see published posts.
				$posts    = count(
					get_posts(
						array(
							'author'         => $user_id,
							'post_type'      => get_post_types(),
							'post_status'    => 'any',
							'posts_per_page' => 1,
							'fields'         => 'ids',
							'no_found_rows'  => true,
						)
					)
				);
				$comments = (int) get_comments(
					array(
						'user_id' => $user_id,
						'count'   => true,
					)
				);

				if ( $posts > 0 || $comments > 0 ) {
					++$kept;
					continue;
				}

				++$matched;
				if ( ! $dry_run && ! wp_delete_user( $user_id ) ) {
					WP_CLI::warning( sprintf( 'Could not delete user %d.', $user_id ) );
					++$kept;
				}
			}

			$offset += $batch_size;
			WP_CLI::log( sprintf( 'Batch %d: %d to delete, %d kept so far.', $batch, $matched, $kept ) );
		} while ( count( $user_ids ) === $batch_size );

		if ( $dry_run ) {
			WP_CLI::success( sprintf( 'Dry run: %d user(s) would be deleted, %d kept. Nothing changed.', $matched, $kept ) );
			return;
		}

		WP_CLI::success( sprintf( 'Deleted %d user(s), kept %d.', $matched, $kept ) );
	}
}

WP_CLI::add_command( 'example purge-users', 'Example_Purge_Users_Command' );
