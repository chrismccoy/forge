<?php
/**
 * Event Details — server render.
 *
 * @package MythemeFunctionality
 * @var array    $attributes
 * @var string   $content
 * @var WP_Block $block
 */

$post_id = $block->context['postId'] ?? get_the_ID();
if ( ! $post_id || 'event' !== get_post_type( $post_id ) ) {
	return;
}

$date   = get_post_meta( $post_id, 'event_date', true );
$venue  = get_post_meta( $post_id, 'event_venue', true );
$layout = in_array( $attributes['layout'] ?? 'card', array( 'card', 'inline' ), true ) ? $attributes['layout'] : 'card';
?>
<div <?php echo get_block_wrapper_attributes( array( 'class' => 'event-details is-layout-' . $layout ) ); ?>>
	<?php
	if ( ! empty( $attributes['bannerId'] ) ) {
		echo wp_get_attachment_image( (int) $attributes['bannerId'], 'large', false, array( 'class' => 'event-details__banner' ) );
	}
	?>
	<p class="event-details__meta">
		<?php if ( $date ) : ?>
			<time datetime="<?php echo esc_attr( $date ); ?>"><?php echo esc_html( wp_date( get_option( 'date_format' ), strtotime( $date ) ) ); ?></time>
		<?php endif; ?>
		<?php if ( $venue ) : ?>
			<span class="event-details__venue"><?php echo esc_html( $venue ); ?></span>
		<?php endif; ?>
	</p>
	<?php if ( ! empty( $attributes['showCta'] ) && ! empty( $attributes['ctaUrl'] ) ) : ?>
		<div class="wp-block-button">
			<a class="wp-block-button__link wp-element-button" href="<?php echo esc_url( $attributes['ctaUrl'] ); ?>">
				<?php echo esc_html( $attributes['ctaLabel'] ?: __( 'Register', 'mytheme-functionality' ) ); ?>
			</a>
		</div>
	<?php endif; ?>
</div>
