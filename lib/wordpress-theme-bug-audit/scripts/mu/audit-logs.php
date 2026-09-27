<?php
/**
 * Plugin Name: Audit logs (throwaway test site only)
 * Description: Logs queries, templates, and outbound requests, and blocks outbound hosts. Never install on a real site.
 *
 * Writes JSON lines beside the WordPress folder: queries.log, templates.log, requests.log.
 * Outbound requests are blocked except to WordPress.org and the site itself. Extra hosts can be allowed with the
 * AUDIT_ALLOW_HOSTS environment variable (comma-separated); AUDIT_ALLOW_HTTP=1 allows every host.
 * Written in PHP 7.4 syntax so it runs on every PHP version the audit tests.
 */

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

// PHP declares a top-level class before any code in the file runs, so an early "if ( class_exists() ) return;"
// guard always returns and nothing would load. Declaring the class inside the condition avoids that.
if ( ! class_exists( 'Audit_Logger', false ) ) :

final class Audit_Logger {

	/** @var array Default hosts that outbound requests are always allowed to reach. */
	private const DEFAULT_ALLOWED_HOSTS = array(
		'api.wordpress.org',
		'downloads.wordpress.org',
		'wordpress.org',
		'127.0.0.1',
		'localhost',
	);

	/** @var array<string,mixed> In-memory template/part trace for the current request. */
	private $template_trace = array(
		'template' => null,
		'parts'    => array(),
		'hfs'      => array(),
	);

	/** @var array<string,bool>|null Cached, lowercased allow-list. */
	private $allowed_hosts_cache;

	public static function init(): void {
		static $instance;
		if ( ! $instance ) {
			$instance = new self();
			$instance->register_hooks();
		}
	}

	private function register_hooks(): void {
		add_filter( 'template_include', array( $this, 'record_template' ), PHP_INT_MAX );
		add_action( 'get_template_part', array( $this, 'record_template_part' ), 10, 4 );

		foreach ( array( 'get_header', 'get_footer', 'get_sidebar' ) as $hook ) {
			add_action(
				$hook,
				function ( $name = null ) use ( $hook ) {
					$this->template_trace['hfs'][] = array( $hook, $name );
				}
			);
		}

		add_filter( 'pre_http_request', array( $this, 'guard_outbound_request' ), 1, 3 );
		add_action( 'http_api_debug', array( $this, 'record_request_debug' ), 10, 5 );
		add_action( 'shutdown', array( $this, 'flush_logs' ), PHP_INT_MAX );
	}

	/* ---------------------------------------------------------------------
	 * Template tracing
	 * ------------------------------------------------------------------ */

	public function record_template( $template ) {
		$this->template_trace['template'] = $template;
		return $template;
	}

	public function record_template_part( $slug, $name, $templates, $args ): void {
		$found                            = locate_template( (array) $templates, false, false );
		$this->template_trace['parts'][] = array(
			'slug' => $slug,
			'name' => $name,
			'args' => is_array( $args ) ? array_keys( $args ) : array(),
			'file' => $found ?: null,
		);
	}

	/* ---------------------------------------------------------------------
	 * Outbound request guard + logging
	 * ------------------------------------------------------------------ */

	public function guard_outbound_request( $pre, $args, $url ) {
		$args    = (array) $args;
		$url     = (string) $url;
		$host    = (string) wp_parse_url( $url, PHP_URL_HOST );
		$blocked = ! $this->is_host_allowed( $host );

		$this->write_log(
			'requests.log',
			array(
				't'         => gmdate( 'c' ),
				'page'      => $this->current_request_label(),
				'url'       => $url,
				'method'    => $args['method'] ?? '',
				'timeout'   => $args['timeout'] ?? null,
				'sslverify' => $args['sslverify'] ?? null,
				'caller'    => wp_debug_backtrace_summary( null, 3 ),
				'blocked'   => $blocked,
			)
		);

		if ( $blocked ) {
			return new WP_Error( 'audit_blocked', 'Blocked by the audit: ' . $host );
		}

		return $pre;
	}

	public function record_request_debug( $response, $context, $class, $args, $url ): void {
		$this->write_log(
			'requests.log',
			array(
				'debug'  => 1,
				'url'    => $url,
				'result' => is_wp_error( $response )
					? $response->get_error_message()
					: wp_remote_retrieve_response_code( $response ),
			)
		);
	}

	private function is_host_allowed( string $host ): bool {
		if ( getenv( 'AUDIT_ALLOW_HTTP' ) ) {
			return true;
		}

		$host = strtolower( $host );

		if ( null === $this->allowed_hosts_cache ) {
			$allowed = self::DEFAULT_ALLOWED_HOSTS;

			$extra = getenv( 'AUDIT_ALLOW_HOSTS' );
			if ( $extra ) {
				$allowed = array_merge(
					$allowed,
					array_map( 'strtolower', array_map( 'trim', explode( ',', $extra ) ) )
				);
			}

			$this->allowed_hosts_cache = array_fill_keys( $allowed, true );
		}

		return isset( $this->allowed_hosts_cache[ $host ] );
	}

	/* ---------------------------------------------------------------------
	 * Shutdown: flush query + template logs
	 * ------------------------------------------------------------------ */

	public function flush_logs(): void {
		$this->flush_query_log();
		$this->flush_template_log();
	}

	private function flush_query_log(): void {
		global $wpdb;

		if ( empty( $wpdb->queries ) ) {
			return;
		}

		if ( ! defined( 'SAVEQUERIES' ) || ! SAVEQUERIES ) {
			// $wpdb->queries is only populated when SAVEQUERIES is enabled;
			// nothing to log otherwise, and we shouldn't have gotten here.
			return;
		}

		$seen = array();
		foreach ( $wpdb->queries as $query ) {
			list( $sql, , $caller ) = $query;

			if ( ! isset( $seen[ $sql ] ) ) {
				$seen[ $sql ] = array( 'n' => 0, 'caller' => $caller );
			}
			++$seen[ $sql ]['n'];
		}

		$repeated = array();
		foreach ( $seen as $sql => $info ) {
			if ( $info['n'] > 1 ) {
				$repeated[] = array(
					'n'      => $info['n'],
					'sql'    => substr( $sql, 0, 300 ),
					'caller' => $info['caller'],
				);
			}
		}

		$this->write_log(
			'queries.log',
			array(
				'url'      => $this->current_request_label(),
				'count'    => count( $wpdb->queries ),
				'repeated' => $repeated,
			)
		);
	}

	private function flush_template_log(): void {
		if ( defined( 'WP_CLI' ) && WP_CLI ) {
			return;
		}

		$this->write_log(
			'templates.log',
			array_merge( array( 'url' => $this->current_request_label() ), $this->template_trace )
		);
	}

	/* ---------------------------------------------------------------------
	 * Helpers
	 * ------------------------------------------------------------------ */

	private function current_request_label(): string {
		if ( defined( 'WP_CLI' ) && WP_CLI ) {
			$argv = $GLOBALS['argv'] ?? array();
			return 'cli:' . implode( ' ', array_slice( $argv, 1, 6 ) );
		}

		$method = $_SERVER['REQUEST_METHOD'] ?? '';
		$uri    = $_SERVER['REQUEST_URI'] ?? '';

		return trim( $method . ' ' . $uri );
	}

	private function log_dir(): string {
		return dirname( rtrim( ABSPATH, '/' ) );
	}

	private function write_log( string $file, array $data ): void {
		$json = wp_json_encode( $data );
		if ( false === $json ) {
			return;
		}
		$line = $json . "\n";

		// LOCK_EX avoids interleaved lines when multiple requests write concurrently.
		file_put_contents( $this->log_dir() . '/' . $file, $line, FILE_APPEND | LOCK_EX );
	}
}

Audit_Logger::init();

endif;
