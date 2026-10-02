<?php
/**
 * Event Session — one row.
 *
 * @package MythemeFunctionality
 * @var array    $attributes
 * @var string   $content
 * @var WP_Block $block
 */

if ( '' === ( $attributes['title'] ?? '' ) ) {
	return;
}
?>
<li <?php echo get_block_wrapper_attributes( array( 'class' => 'event-session' ) ); ?>>
	<?php if ( '' !== $attributes['time'] ) : ?>
		<span class="event-session__time"><?php echo esc_html( $attributes['time'] ); ?></span>
	<?php endif; ?>
	<strong class="event-session__title"><?php echo wp_kses( $attributes['title'], array( 'em' => array(), 'a' => array( 'href' => array() ) ) ); ?></strong>
	<?php if ( '' !== $attributes['speaker'] ) : ?>
		<span class="event-session__speaker"><?php echo esc_html( $attributes['speaker'] ); ?></span>
	<?php endif; ?>
</li>
