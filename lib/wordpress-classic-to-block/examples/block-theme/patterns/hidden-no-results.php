<?php
/**
 * Title: No results
 * Slug: mytheme/hidden-no-results
 * Inserter: no
 *
 * Holds translatable text for templates/index.html, archive.html and search.html.
 * .html templates cannot call __(), so the strings live here.
 */
?>
<!-- wp:paragraph -->
<p><?php esc_html_e( 'Sorry, nothing matched. Try a different search.', 'mytheme' ); ?></p>
<!-- /wp:paragraph -->

<!-- wp:search {"label":"<?php echo esc_attr_x( 'Search', 'search form label', 'mytheme' ); ?>","showLabel":false,"buttonText":"<?php echo esc_attr_x( 'Search', 'search button text', 'mytheme' ); ?>"} /-->
