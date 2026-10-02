<?php
/**
 * Event Sessions — wraps the rendered child blocks.
 *
 * @package MythemeFunctionality
 * @var array    $attributes
 * @var string   $content    Rendered mytheme/event-session children.
 * @var WP_Block $block
 */

if ( '' === trim( $content ) ) {
	return;
}
?>
<ul <?php echo get_block_wrapper_attributes( array( 'class' => 'event-sessions' ) ); ?>>
	<?php echo $content; // phpcs:ignore WordPress.Security.EscapeOutput -- rendered blocks. ?>
</ul>
