# Groovy Style

Warm 70s design - muted oranges, mustard yellows, avocado greens, earthy browns, rounded bubble lettering, psychedelic wave patterns, and retro warmth. Use when asked for "groovy style".

## Typography

Righteous or Baloo 2 (Google Fonts) for headlines - round and bubbly. DM Sans for body. Headlines `font-display font-bold` with no tight tracking - let it breathe wide. Very rounded feel.

## Colors

```
Background:   #fdf6e3   (warm cream)
Orange:       #e8621a
Mustard:      #d4a017
Avocado:      #6b7c35
Brown:        #8b4513
Rust:         #b7410e
Cream:        #fdf6e3
Dark text:    #2d1b00
```

## Wavy / Organic Shapes

```css
/* Wavy divider between sections */
.wave-divider {
  background: url("wavy.svg") repeat-x;
  height: 40px; width: 100%;
}
/* Wavy border on cards */
.wavy-card {
  border-radius: 60% 40% 70% 30% / 40% 60% 40% 60%;
}
/* Or use SVG path borders */
```

## Pattern Backgrounds

```css
.groovy-bg {
  background-color: #fdf6e3;
  background-image: url("retro-pattern.svg");  /* circles/swirls repeat */
  /* CSS circles pattern: */
  background-image: radial-gradient(circle at 50% 50%, #e8621a22 0%, transparent 60%),
                    radial-gradient(circle at 20% 80%, #d4a01722 0%, transparent 50%);
}
```

## Cards

```css
.groovy-card {
  background: white;
  border: 3px solid #2d1b00;
  border-radius: 40px 20px 40px 20px;  /* irregular retro rounding */
  box-shadow: 6px 6px 0 #2d1b00;
  padding: 32px;
}
```

## Buttons

```css
.groovy-btn {
  background: #e8621a; color: white;
  border: 3px solid #2d1b00;
  border-radius: 100px;
  font-family: 'Righteous'; font-size: 16px;
  box-shadow: 5px 5px 0 #2d1b00;
  padding: 14px 36px;
}
.groovy-btn:hover { transform: translate(-2px, -2px); box-shadow: 7px 7px 0 #2d1b00; }
.groovy-btn-mustard { background: #d4a017; color: #2d1b00; }
```

## Retro Badge / Sticker

`border: 3px solid #2d1b00; border-radius: 50%; padding: 12px 16px; background: #d4a017; font-family: 'Righteous'; font-size: 13px; text-transform: uppercase; transform: rotate(-8deg)`.

## Section Rotation

Alternate warm section backgrounds: cream → orange-tint (#fff3e0) → mustard-tint (#fffde7) → green-tint (#f1f8e9).

## Implementation

- Google Fonts: Righteous + DM Sans
- `antialiased`
- Decorative retro sun/star/circle SVGs scattered as accents
- `overflow-x: hidden`
- Card grids: `gap-8`, generous padding
- Avoid anything that reads "modern tech" - no system fonts, no flat blues
