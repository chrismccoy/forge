<?php
/**
 * Title: Header — centered
 * Slug: mytheme/header-centered
 * Categories: header
 * Block Types: core/template-part/header
 * Description: Alternate header layout offered when replacing the header template part.
 */
?>
<!-- wp:group {"layout":{"type":"constrained"}} -->
<div class="wp-block-group">

    <!-- wp:group {"style":{"spacing":{"padding":{"top":"var:preset|spacing|30","bottom":"var:preset|spacing|30"}}},"layout":{"type":"flex","orientation":"vertical","justifyContent":"center"}} -->
    <div class="wp-block-group" style="padding-top:var(--wp--preset--spacing--30);padding-bottom:var(--wp--preset--spacing--30)">
        <!-- wp:site-logo {"width":120} /-->
        <!-- wp:site-title {"level":0} /-->
        <!-- wp:navigation {"fontSize":"small","overlayMenu":"mobile","layout":{"type":"flex","justifyContent":"center"}} /-->
    </div>
    <!-- /wp:group -->

</div>
<!-- /wp:group -->
