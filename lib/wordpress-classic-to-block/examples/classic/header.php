<!DOCTYPE html>
<html <?php language_attributes(); ?>>
<head>
    <meta charset="<?php bloginfo( 'charset' ); ?>">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <?php wp_head(); ?>
</head>
<body <?php body_class(); ?>>
<?php wp_body_open(); ?>
<header class="site-header">
    <div class="container">
        <a class="site-logo" href="<?php echo esc_url( home_url( '/' ) ); ?>">
            <?php
            if ( has_custom_logo() ) {
                the_custom_logo();
            } else {
                echo '<span class="site-title">' . esc_html( get_bloginfo( 'name' ) ) . '</span>';
            }
            ?>
        </a>
        <nav class="main-navigation" aria-label="<?php esc_attr_e( 'Primary menu', 'mytheme' ); ?>">
            <?php
            wp_nav_menu( array(
                'theme_location' => 'primary',
                'menu_class'     => 'primary-menu',
                'container'      => false,
            ) );
            ?>
        </nav>
    </div>
</header>
