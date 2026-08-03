<?php
/**
 * Plugin Name: Menu Icon Picker
 * Description: Adds a Font Awesome icon picker to every WordPress menu item and stores the chosen class as menu item meta for you to render in your theme.
 * Version: 1.0.0
 * Author: Chris McCoy
 * Text Domain: menu-icon-picker
 * Domain Path: /languages
 * Requires PHP: 7.4
 * Requires at least: 5.0
 *
 * @package MenuIconPicker
 */

// Prevent direct access.
if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

define( 'MIP_VERSION', '1.0.0' );
define( 'MIP_URL', plugin_dir_url( __FILE__ ) );

/*
 * Meta key the Font Awesome class is stored under.
 */
if ( ! defined( 'MIP_META_KEY' ) ) {
	define( 'MIP_META_KEY', '_mip_icon' );
}

/**
 * Menu Icon Picker.
 */
final class Menu_Icon_Picker {

	/**
	 * Post meta key the Font Awesome class is stored under.
	 */
	private static function get_meta_key() {
		return MIP_META_KEY;
	}

	/**
	 * Register hooks.
	 */
	public function __construct() {
		add_action( 'wp_nav_menu_item_custom_fields', array( $this, 'render_menu_item_field' ), 10, 2 );
		add_action( 'wp_update_nav_menu_item', array( $this, 'save_menu_item_icon' ), 10, 2 );
		add_action( 'admin_enqueue_scripts', array( $this, 'enqueue_nav_menu_assets' ) );
		add_action( 'admin_footer-nav-menus.php', array( $this, 'render_icon_picker_modal' ) );
	}

	/**
	 * Output the icon field on a nav menu item.
	 */
	public function render_menu_item_field( $item_id, $menu_item ) {
		$icon = get_post_meta( $item_id, self::get_meta_key(), true );
		$icon = is_string( $icon ) ? $icon : '';
		?>
		<p class="field-mip-icon description description-wide mip_field">
			<label class="mip_field-label" for="mip-icon-<?php echo esc_attr( $item_id ); ?>">
				<?php esc_html_e( 'Font Awesome Icon', 'menu-icon-picker' ); ?>
			</label>
			<span class="mip_field-row">
				<span class="mip_input-wrap<?php echo $icon ? ' mip_has-icon' : ''; ?>">
					<i class="mip_input-icon <?php echo esc_attr( self::resolve_icon_classes( $icon ) ); ?>" aria-hidden="true"></i>
					<input type="text"
						id="mip-icon-<?php echo esc_attr( $item_id ); ?>"
						name="mip_icon[<?php echo esc_attr( $item_id ); ?>]"
						value="<?php echo esc_attr( $icon ); ?>"
						placeholder="<?php esc_attr_e( 'No icon selected', 'menu-icon-picker' ); ?>"
						class="mip_icon-input"
						readonly>
				</span>
				<button type="button" class="button button-primary mip_open-picker" data-item-id="<?php echo esc_attr( $item_id ); ?>">
					<?php esc_html_e( 'Pick', 'menu-icon-picker' ); ?>
				</button>
				<button type="button" class="button button-primary mip_clear-icon" data-item-id="<?php echo esc_attr( $item_id ); ?>">
					<?php esc_html_e( 'Clear', 'menu-icon-picker' ); ?>
				</button>
			</span>
		</p>
		<?php
	}

	/**
	 * Save the icon class for a menu item.
	 */
	public function save_menu_item_icon( $menu_id, $menu_item_db_id ) {
		if ( ! current_user_can( 'edit_theme_options' ) ) {
			return;
		}

		if ( ! isset( $_POST['update-nav-menu-nonce'] )
			|| ! wp_verify_nonce( sanitize_text_field( wp_unslash( $_POST['update-nav-menu-nonce'] ) ), 'update-nav_menu' )
		) {
			return;
		}

		if ( ! isset( $_POST['mip_icon'][ $menu_item_db_id ] ) ) {
			return;
		}

		$raw   = wp_unslash( $_POST['mip_icon'][ $menu_item_db_id ] );
		$class = self::sanitize_icon_class( $raw );

		if ( '' === $class ) {
			delete_post_meta( $menu_item_db_id, self::get_meta_key() );
			return;
		}

		update_post_meta( $menu_item_db_id, self::get_meta_key(), $class );
	}

	/**
	 * Convert input to a safe Font Awesome class list.
	 */
	private static function sanitize_icon_class( $value ) {
		$value = is_string( $value ) ? $value : '';
		$value = preg_replace( '/[^A-Za-z0-9 _-]/', '', $value );
		$value = preg_replace( '/\s+/', ' ', $value );
		return sanitize_text_field( trim( $value ) );
	}

	/**
	 * Get a stored value to a renderable Font Awesome class string
	 */
	private static function resolve_icon_classes( $icon ) {
		$icon = self::sanitize_icon_class( $icon );
		if ( '' === $icon ) {
			return '';
		}

		$parts     = explode( ' ', $icon );
		$styles    = array( 'fa', 'fas', 'far', 'fab', 'fal', 'fad', 'fa-solid', 'fa-regular', 'fa-brands', 'fa-light', 'fa-thin', 'fa-duotone' );
		$has_style = (bool) array_intersect( $styles, $parts );
		if ( ! $has_style ) {
			$icon = 'fa-solid ' . $icon;
		}

		return $icon;
	}

	/**
	 * Enqueue assets on the nav menus screen only.
	 */
	public function enqueue_nav_menu_assets( $hook ) {
		if ( 'nav-menus.php' !== $hook ) {
			return;
		}

		wp_enqueue_style(
			'mip-font-awesome',
			'https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.2/css/all.min.css',
			array(),
			'6.5.2'
		);

		wp_enqueue_style(
			'mip-admin',
			MIP_URL . 'assets/css/admin.css',
			array( 'mip-font-awesome' ),
			MIP_VERSION
		);

		wp_enqueue_script(
			'mip-admin',
			MIP_URL . 'assets/js/admin.js',
			array( 'jquery' ),
			MIP_VERSION,
			true
		);

		wp_localize_script(
			'mip-admin',
			'mipPicker',
			array(
				'i18n' => array(
					'noResults' => esc_html__( 'No icons found.', 'menu-icon-picker' ),
				),
			)
		);
	}

	/**
	 * Add the icon picker modal in the nav menus admin footer.
	 */
	public function render_icon_picker_modal() {
		?>
		<div id="mip_icon-picker-modal" class="mip_modal-overlay" style="display:none;">
			<div class="mip_modal-box">
				<div class="mip_modal-header">
					<h3><?php esc_html_e( 'Select Icon', 'menu-icon-picker' ); ?></h3>
					<button type="button" class="mip_modal-close" aria-label="<?php esc_attr_e( 'Close', 'menu-icon-picker' ); ?>">&times;</button>
				</div>
				<div class="mip_modal-search">
					<input type="text" id="mip_icon-search-input" placeholder="<?php esc_attr_e( 'Search icons... (e.g. home, user, cart)', 'menu-icon-picker' ); ?>">
				</div>
				<div class="mip_modal-body">
					<div id="mip_icon-grid" class="mip_icon-grid"></div>
				</div>
			</div>
		</div>
		<?php
	}
}

new Menu_Icon_Picker();
