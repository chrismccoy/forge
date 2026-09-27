<?php
/**
 * Plugin Name: Audit vendor notices (throwaway test site only)
 * Description: Counts deprecation notices from bundled vendor/ libraries instead of printing them. Never install on a real site.
 *
 * Only E_DEPRECATED and E_USER_DEPRECATED from files under a vendor/ folder are caught. Everything else, including every
 * notice from the theme's own files, falls through to PHP and WordPress as usual. Each request adds one JSON line to
 * vendor-notices.log beside the WordPress folder, with a count per distinct message and file.
 */

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

// PHP declares a top-level class before any code in the file runs, so an early "if ( class_exists() ) return;"
// guard always returns and nothing would load. Declaring the class inside the condition avoids that.
if ( ! class_exists( 'Audit_Vendor_Notices', false ) ) :

final class Audit_Vendor_Notices {

	private const WATCHED_LEVELS = E_DEPRECATED | E_USER_DEPRECATED;

	/** @var array<string,int> Counts keyed by "message in file:line". */
	private $notices = array();

	/** @var callable|null The error handler that was active before we installed ours. */
	private $previous_handler;

	public static function init(): void {
		static $instance;
		if ( ! $instance ) {
			$instance = new self();
			$instance->register();
		}
	}

	private function register(): void {
		$this->previous_handler = set_error_handler( array( $this, 'handle_error' ) );
		register_shutdown_function( array( $this, 'flush_log' ) );
	}

	public function handle_error( int $no, string $str, string $file = '', int $line = 0 ): bool {
		if ( ( self::WATCHED_LEVELS & $no ) && false !== strpos( $file, '/vendor/' ) ) {
			$key = $str . ' in ' . $file . ':' . $line;

			if ( ! isset( $this->notices[ $key ] ) ) {
				$this->notices[ $key ] = 0;
			}
			++$this->notices[ $key ];

			return true; // Suppress: don't let PHP print it.
		}

		if ( $this->previous_handler ) {
			// Defer to whatever handler (if any) was registered before us,
			// so other plugins' error handling keeps working.
			return (bool) call_user_func( $this->previous_handler, $no, $str, $file, $line );
		}

		// No previous handler: let PHP's normal error reporting take over.
		return false;
	}

	public function flush_log(): void {
		if ( empty( $this->notices ) ) {
			return;
		}

		$line = wp_json_encode(
			array(
				'url'     => $_SERVER['REQUEST_URI'] ?? 'cli',
				'notices' => $this->notices,
			)
		);

		if ( false === $line ) {
			return;
		}

		file_put_contents(
			dirname( rtrim( ABSPATH, '/' ) ) . '/vendor-notices.log',
			$line . "\n",
			FILE_APPEND | LOCK_EX
		);
	}
}

Audit_Vendor_Notices::init();

endif;
