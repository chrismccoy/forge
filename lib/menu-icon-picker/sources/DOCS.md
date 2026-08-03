# Menu Icon Picker — theme integration

Menu Icon Picker saves a Font Awesome class per menu item. It renders nothing on the
front end. You read the value in your theme and print the icon.

These examples assume **Font Awesome is already enqueued by your theme.**

## Where the class is stored

Menu items are posts of type `nav_menu_item`. The chosen class is stored in
post meta under:

```
_mip_icon
```

The stored value is exactly what was picked, e.g. `fa-house`, or
`fa-brands fa-facebook`. Bare names (`fa-house`) have **no style prefix**, so
add `fa-solid` when one is missing before rendering (see the helper below).

> If you overrode the meta key with `define( 'MIP_META_KEY', '…' )`, use
> that key instead. It defaults to the constant when available:
> `defined( 'MIP_META_KEY' ) ? MIP_META_KEY : '_mip_icon'`.

## Read the class for one item

```php
$icon = get_post_meta( $item_id, '_mip_icon', true );

if ( $icon ) {
	printf( '<i class="%s" aria-hidden="true"></i>', esc_attr( $icon ) );
}
```

## Helper: normalise the class

A picked value may be a bare `fa-house`. Font Awesome needs a style class
(`fa-solid`, `fa-regular`, `fa-brands`, …) to draw the glyph. This helper adds
`fa-solid` when no style is present:

```php
/**
 * Return a renderable Font Awesome class string for a stored Menu Icon Picker value.
 */
function mytheme_mip_class( $icon ) {
	$icon = trim( (string) $icon );

	if ( '' === $icon ) {
		return '';
	}

	$styles = array( 'fa', 'fas', 'far', 'fab', 'fal', 'fad', 'fa-solid', 'fa-regular', 'fa-brands', 'fa-light', 'fa-thin', 'fa-duotone' );

	if ( ! array_intersect( $styles, explode( ' ', $icon ) ) ) {
		$icon = 'fa-solid ' . $icon;
	}

	return $icon;
}
```

## Option A — filter every menu item title

Simplest drop-in. Prepends the icon to every menu link, no walker needed.

```php
add_filter( 'nav_menu_item_title', function ( $title, $item ) {
	$icon = mytheme_mip_class( get_post_meta( $item->ID, '_mip_icon', true ) );

	if ( $icon ) {
		$title = '<i class="' . esc_attr( $icon ) . '" aria-hidden="true"></i> ' . $title;
	}

	return $title;
}, 10, 2 );
```

## Option B — custom nav walker

Use this when you want full control over the markup, or icons on one menu only.

```php
/**
 * Nav walker that prepends the Menu Icon Picker icon to each menu item.
 */
class Mytheme_Icon_Nav_Walker extends Walker_Nav_Menu {

	public function start_el( &$output, $item, $depth = 0, $args = null, $id = 0 ) {
		$icon = mytheme_mip_class( get_post_meta( $item->ID, '_mip_icon', true ) );

		if ( $icon ) {
			// The core walker outputs the title as HTML, so an <i> here is safe.
			$item->title = '<i class="' . esc_attr( $icon ) . '" aria-hidden="true"></i> ' . $item->title;
		}

		parent::start_el( $output, $item, $depth, $args, $id );
	}
}
```

Use it when rendering a menu:

```php
wp_nav_menu( array(
	'theme_location' => 'primary',
	'walker'         => new Mytheme_Icon_Nav_Walker(),
) );
```

Put `mytheme_mip_class()` and the walker class in your theme's
`functions.php` (or an included file).

## Styling

Size and colour are up to your theme — Menu Icon Picker stores only the class.
Target the injected `<i>` inside menu links:

```css
.primary-menu a > i.fa-solid,
.primary-menu a > i.fa-brands,
.primary-menu a > i.fa-regular {
	margin-right: 0.4em;
	font-size: 1em;
	color: inherit;
}
```
