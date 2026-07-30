# Maximalist Style

More is more. Layered patterns on patterns, clashing colors that somehow work, dense content, ornate details at every level, and a sense of abundant visual richness. Use when asked for "maximalist style".

## Typography

Mix two contrasting display fonts deliberately: Bebas Neue (condensed, loud) + Abril Fatface (thick, ornate). Body: DM Sans. Headlines at multiple competing sizes - intentional hierarchy chaos. `font-display` for some, `font-serif` for others.

## Colors

No palette constraints. Use everything:

```
Start with: coral #ff6b6b, gold #ffd700, teal #00cec9,
purple #6c5ce7, lime #00b894, pink #fd79a8,
navy #2d3436, cream #ffeaa7
```

Layer multiple colors on the same section. Pattern on pattern. Contrast is welcome.

## Layered Background

```css
body {
  background:
    repeating-linear-gradient(45deg, rgba(255,215,0,0.1) 0, rgba(255,215,0,0.1) 2px, transparent 0, transparent 50%),
    repeating-linear-gradient(-45deg, rgba(108,92,231,0.1) 0, rgba(108,92,231,0.1) 2px, transparent 0, transparent 50%),
    #ffeaa7;
  background-size: 20px 20px, 20px 20px;
}
```

## Cards - Stacked and Layered

```css
.maxi-card {
  background: white;
  border: 4px solid #2d3436;
  border-radius: 0;  /* or vary: 0, 20px, 50%, mixing */
  box-shadow: 8px 8px 0 #ffd700, 16px 16px 0 #6c5ce7;
  position: relative;
}
/* Decorative stripes, dots, and patterns as ::before/::after */
```

## Overlapping Elements

Use `position: absolute` and `z-index` to create intentional overlaps - text over images, cards over other cards, decorative shapes bleeding between sections.

## Bold Section Backgrounds

Each section uses a dramatically different treatment:
- Section 1: hot coral `#ff6b6b` + stripe pattern
- Section 2: dark navy with gold dots
- Section 3: lime green + geometric shapes
- Section 4: cream + layered shadows

## Typography Mix

```css
/* Section number: massive, overlapping, background watermark */
.section-num {
  font-family: 'Bebas Neue'; font-size: 20vw; opacity: 0.08;
  position: absolute; top: -0.1em; left: -0.05em; color: #2d3436;
}
/* Main headline: Abril Fatface, large */
/* Sub: DM Sans, contrasting weight */
```

## Buttons - Maximalist

Multiple button styles used simultaneously on the same page:

```css
.btn-stack { background: #ff6b6b; color: white; border: 4px solid #2d3436; box-shadow: 6px 6px 0 #2d3436, 12px 12px 0 #ffd700; }
.btn-outlined { background: transparent; border: 4px solid currentColor; }
.btn-pill { border-radius: 100px; background: #6c5ce7; color: white; }
```

## Implementation

- Google Fonts: Bebas Neue + Abril Fatface + DM Sans
- `overflow-x: hidden`
- Decorative shapes: triangles, circles, stars all present simultaneously
- Images: full bleed, large, with color overlays
- No whitespace rules - density is the goal
