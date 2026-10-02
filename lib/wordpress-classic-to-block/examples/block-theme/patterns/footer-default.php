<?php
/**
 * Title: Footer
 * Slug: mytheme/footer-default
 * Categories: footer
 * Block Types: core/template-part/footer
 * Inserter: no
 */
?>
<!-- wp:group {"layout":{"type":"constrained"}} -->
<div class="wp-block-group">

    <!-- wp:group {"layout":{"type":"flex","flexWrap":"wrap","justifyContent":"space-between"}} -->
    <div class="wp-block-group">
        <!-- wp:site-title {"level":0} /-->

        <!-- wp:paragraph {"fontSize":"small"} -->
        <p class="has-small-font-size"><?php
            printf(
                /* translators: %s: WordPress link. */
                esc_html__( 'Proudly powered by %s', 'mytheme' ),
                '<a href="' . esc_url( __( 'https://wordpress.org', 'mytheme' ) ) . '" rel="nofollow">WordPress</a>'
            );
        ?></p>
        <!-- /wp:paragraph -->
    </div>
    <!-- /wp:group -->

</div>
<!-- /wp:group -->
