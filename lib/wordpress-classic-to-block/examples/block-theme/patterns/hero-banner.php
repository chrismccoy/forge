<?php
/**
 * Title: Hero Banner
 * Slug: mytheme/hero-banner
 * Description: Full-width hero section with heading, subtext, and CTA button.
 * Categories: mytheme, banner
 * Keywords: hero, banner, header, cta, call to action
 * Viewport Width: 1280
 * Block Types: core/cover
 * Post Types: page
 * Inserter: true
 */
?>
<!-- wp:cover {"url":"<?php echo esc_url( get_theme_file_uri( 'assets/images/hero-default.jpg' ) ); ?>","dimRatio":50,"minHeight":500,"minHeightUnit":"px","align":"full","style":{"spacing":{"padding":{"top":"var:preset|spacing|70","bottom":"var:preset|spacing|70"}}}} -->
<div class="wp-block-cover alignfull" style="padding-top:var(--wp--preset--spacing--70);padding-bottom:var(--wp--preset--spacing--70);min-height:500px">
    <span aria-hidden="true" class="wp-block-cover__background has-background-dim"></span>
    <img class="wp-block-cover__image-background" alt="" src="<?php echo esc_url( get_theme_file_uri( 'assets/images/hero-default.jpg' ) ); ?>" data-object-fit="cover"/>
    <div class="wp-block-cover__inner-container">

        <!-- wp:group {"style":{"spacing":{"blockGap":"var:preset|spacing|30"}},"layout":{"type":"constrained","contentSize":"680px"}} -->
        <div class="wp-block-group">

            <!-- wp:heading {"textAlign":"center","level":1,"style":{"typography":{"lineHeight":"1.1"}},"fontSize":"huge"} -->
            <h1 class="wp-block-heading has-text-align-center has-huge-font-size" style="line-height:1.1"><?php esc_html_e( 'Your compelling headline here', 'mytheme' ); ?></h1>
            <!-- /wp:heading -->

            <!-- wp:paragraph {"align":"center","fontSize":"large"} -->
            <p class="has-text-align-center has-large-font-size"><?php esc_html_e( 'A short supporting sentence that reinforces the headline and drives action.', 'mytheme' ); ?></p>
            <!-- /wp:paragraph -->

            <!-- wp:buttons {"layout":{"type":"flex","justifyContent":"center"}} -->
            <div class="wp-block-buttons">
                <!-- wp:button -->
                <div class="wp-block-button"><a class="wp-block-button__link wp-element-button"><?php esc_html_e( 'Get Started', 'mytheme' ); ?></a></div>
                <!-- /wp:button -->
            </div>
            <!-- /wp:buttons -->

        </div>
        <!-- /wp:group -->

    </div>
</div>
<!-- /wp:cover -->
