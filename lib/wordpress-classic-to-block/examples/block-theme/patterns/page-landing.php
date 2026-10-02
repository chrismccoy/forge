<?php
/**
 * Title: Landing page
 * Slug: mytheme/page-landing
 * Categories: mytheme
 * Block Types: core/post-content
 * Post Types: page
 * Viewport Width: 1280
 * Description: Starter layout offered in the "Choose a pattern" modal when creating a page.
 */
?>
<!-- wp:pattern {"slug":"mytheme/hero-banner"} /-->

<!-- wp:group {"metadata":{"name":"Intro"},"layout":{"type":"constrained"}} -->
<div class="wp-block-group">
    <!-- wp:heading -->
    <h2 class="wp-block-heading"><?php esc_html_e( 'What we do', 'mytheme' ); ?></h2>
    <!-- /wp:heading -->

    <!-- wp:paragraph -->
    <p><?php esc_html_e( 'Describe the offer in two or three sentences.', 'mytheme' ); ?></p>
    <!-- /wp:paragraph -->
</div>
<!-- /wp:group -->
