# Athletic Style

Bold diagonal cuts, high-energy color blocks, condensed impact typography, and the visual language of sports branding. Powerful, direct, and physical. Use when asked for "athletic style".

## Typography

Barlow Condensed or Oswald (Google Fonts, weights 400-800). `font-bold uppercase tracking-wider`. All headlines in condensed caps. Body: Barlow (normal width). `font-medium leading-snug`.

## Colors

Choose a team-style dual palette:

```
Primary:    #e61e2b   (red - or customize to brand)
Secondary:  #f5e642   (gold/yellow)
Dark:       #1a1a1a
Light:      #f5f5f5
White:      #ffffff
```

Two accent colors max. Hard contrast. No pastels.

## Diagonal Cut Sections

```css
.diagonal-cut {
  clip-path: polygon(0 0, 100% 0, 100% 85%, 0 100%);
  /* or: */
  clip-path: polygon(0 5%, 100% 0, 100% 95%, 0 100%);
}
.diagonal-bg {
  position: relative;
}
.diagonal-bg::after {
  content: ''; position: absolute; bottom: -2px; left: 0; right: 0;
  height: 60px;
  background: [next-section-color];
  clip-path: polygon(0 100%, 100% 0, 100% 100%);
}
```

## Color Block Layout

Large full-width sections alternating: dark → light → primary color → dark. No gradients - flat solid color blocks, hard edges.

## Jersey Number / Big Stat

```css
.jersey-num {
  font-family: 'Barlow Condensed'; font-weight: 800;
  font-size: clamp(80px, 20vw, 200px);
  text-transform: uppercase; line-height: 1;
  color: rgba(255,255,255,0.08);  /* giant watermark */
  position: absolute;
}
```

## Cards

```css
.athletic-card {
  background: white;
  border-top: 4px solid #e61e2b;
  border-radius: 0;
  padding: 24px;
  box-shadow: 0 4px 20px rgba(0,0,0,0.1);
}
.athletic-card:hover { transform: translateY(-4px); box-shadow: 0 12px 32px rgba(0,0,0,0.2); }
```

## Buttons

```css
.sport-btn {
  background: #e61e2b; color: white;
  border: none; border-radius: 0;
  font-family: 'Barlow Condensed'; font-weight: 700;
  text-transform: uppercase; letter-spacing: 0.1em; font-size: 16px;
  padding: 14px 36px;
  clip-path: polygon(6px 0, 100% 0, calc(100% - 6px) 100%, 0 100%);
  box-shadow: 0 4px 16px rgba(230,30,43,0.4);
}
.sport-btn:hover { background: #cc1a26; box-shadow: 0 8px 24px rgba(230,30,43,0.5); }
.sport-btn-gold { background: #f5e642; color: #1a1a1a; }
```

## Marquee / Ticker

`background: #e61e2b; color: white; font-family: 'Barlow Condensed'; text-transform: uppercase; letter-spacing: 0.15em`. Items separated by `//` or `|`.

## Implementation

- Google Fonts: Barlow Condensed + Barlow
- `overflow: hidden`
- No border-radius on structural elements
- `clip-path` for diagonal cuts - always include a fallback
- Jersey number watermarks behind section content
- Font Awesome for trophy, lightning bolt, fire icons
