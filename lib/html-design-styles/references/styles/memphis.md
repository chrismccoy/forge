# Memphis Style

Bold 80s/90s geometric shapes, confetti patterns, bright pastels, and playful squiggles. Chaotic but joyful. Use when asked for "memphis style".

## Typography

Fredoka One or Righteous (Google Fonts) for headlines. Nunito or Quicksand for body. Headlines `font-display font-bold` with no letter-spacing - friendly and rounded. Never rigid or cold.

## Colors

Memphis uses 5-6 simultaneously:

```
Background:   #fef9f0   (warm cream)
Hot pink:     #ff6b9d
Yellow:       #ffd93d
Turquoise:    #4ecdc4
Purple:       #a855f7
Coral:        #ff6b35
Mint:         #95e1d3
Black:        #2d2d2d   (outlines)
```

Rotate colors across cards, shapes, and accents. No single dominant brand color.

## Geometric Background Shapes

Scatter decorative SVG/CSS shapes across the page - none are interactive:

```css
/* Diagonal stripe block */
.stripe-block {
  background: repeating-linear-gradient(
    45deg, #ffd93d, #ffd93d 4px, transparent 4px, transparent 20px
  );
}
/* Dot pattern */
.dot-pattern {
  background-image: radial-gradient(#ff6b9d 2px, transparent 2px);
  background-size: 20px 20px;
}
/* Squiggle: use SVG inline or background-image */
```

Place these as `absolute` decorative elements behind content.

## Cards

```css
.memphis-card {
  background: white;
  border: 3px solid #2d2d2d;
  border-radius: 16px;
  box-shadow: 6px 6px 0px #2d2d2d;
  position: relative; overflow: hidden;
}
/* Top accent bar - different color per card */
.memphis-card::before {
  content: ''; position: absolute; top: 0; left: 0; right: 0;
  height: 6px; background: var(--card-accent);
}
```

## Buttons

```css
.memphis-btn {
  border: 3px solid #2d2d2d;
  border-radius: 100px;
  font-weight: 800; text-transform: uppercase;
  box-shadow: 4px 4px 0px #2d2d2d;
}
.memphis-btn:hover { transform: translate(-2px, -2px); box-shadow: 6px 6px 0px #2d2d2d; }
.memphis-btn:active { transform: translate(2px, 2px); box-shadow: 2px 2px 0px #2d2d2d; }
```

Each button gets a different pastel background.

## Pills / Tags

`border: 2px solid #2d2d2d; border-radius: 100px; font-weight: 700; padding: 4px 12px` - each a different pastel bg color.

## Section Rotation

Each section gets a different background from the palette:
- Hero: `#fef9f0` (cream)
- Features: `#fff0f5` (pink tint)
- Stats: `#fffde7` (yellow tint)
- CTA: `#f0fffe` (turquoise tint)

## Icon Treatment

Icons inside `rounded-2xl` boxes, each a different pastel bg. Slightly rotated: `transform: rotate(5deg)` or `-rotate(3deg)`.

## Decorative Elements

- Scattered geometric shapes: triangles, circles, stars, diamonds - all `absolute`, `pointer-events-none`, varying opacities
- Zigzag dividers between sections
- Hand-drawn-style underlines: `border-bottom: 3px solid #ff6b9d; border-radius: 0 0 50% 50%`

## Implementation

- Google Fonts: Fredoka One + Nunito
- `antialiased`
- `overflow-x: hidden` on body
- Generous padding: `py-20 px-6`
- Card grids: `gap-6`, `grid-cols-1 md:grid-cols-2 lg:grid-cols-3`
- Never use more than 3 shapes per section or it becomes unreadable
