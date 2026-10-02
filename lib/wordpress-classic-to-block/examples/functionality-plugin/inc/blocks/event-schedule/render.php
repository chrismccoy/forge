<?php
/**
 * Server-side render for a repeater previously stored by a metabox
 * (serialized array in post meta). Block Bindings cannot handle repeaters.
 *
 * @package MythemeFunctionality
 * @var array    $attributes Block attributes.
 * @var string   $content    Inner block content (unused).
 * @var WP_Block $block      Block instance.
 */

$post_id  = $block->context['postId'] ?? get_the_ID();
$sessions = get_post_meta( $post_id, '_event_sessions', true );

if ( empty( $sessions ) || ! is_array( $sessions ) ) {
	return;
}
?>
<ul <?php echo get_block_wrapper_attributes( array( 'class' => 'event-schedule' ) ); ?>>
	<?php foreach ( $sessions as $session ) : ?>
		<li>
			<strong><?php echo esc_html( $session['time'] ?? '' ); ?></strong>
			— <?php echo esc_html( $session['title'] ?? '' ); ?>
		</li>
	<?php endforeach; ?>
</ul>
