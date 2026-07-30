# Tropical Style

Warm vacation energy - coral, turquoise, sandy whites, bold tropical colors, and a relaxed resort aesthetic. Fun, bright, and sun-soaked. Use when asked for "tropical style".

## Typography

Nunito or Quicksand (Google Fonts, weights 400-800). Rounded and friendly. Headlines `font-extrabold tracking-tight`. Body `font-medium leading-relaxed`.

## Colors

```
Background:   #fffef9   (warm white)
Coral:        #ff6b5b
Turquoise:    #00c9b1
Sandy:        #f5dfa0
Lime:         #8bc34a
Ocean blue:   #1a85c8
Dark text:    #1a2332
```

## Section Backgrounds

Rotate through warm section backgrounds:
- `#fff8f0` (warm cream)
- `#e8faf8` (light turquoise tint)
- `#fff3e0` (warm orange tint)
- `#f0f9ff` (light sky blue)

## Cards

```css
.tropical-card {
  background: white;
  border-radius: 24px;
  box-shadow: 0 8px 32px rgba(26,133,200,0.12), 0 2px 8px rgba(0,0,0,0.06);
  overflow: hidden;
}
/* Colored top bar per card, cycling through palette */
.tropical-card::before {
  content: ''; display: block; height: 6px;
  background: linear-gradient(90deg, #ff6b5b, #f5dfa0);
}
.tropical-card:hover { transform: translateY(-6px); box-shadow: 0 16px 48px rgba(26,133,200,0.2); }
```

## Buttons

```css
.trop-btn {
  background: #ff6b5b; color: white;
  border-radius: 100px; border: none;
  font-weight: 700;
  box-shadow: 0 4px 16px rgba(255,107,91,0.4);
  padding: 14px 32px;
}
.trop-btn:hover { background: #ff5543; transform: translateY(-2px); box-shadow: 0 8px 24px rgba(255,107,91,0.5); }
.trop-btn-teal { background: #00c9b1; box-shadow: 0 4px 16px rgba(0,201,177,0.4); }
.trop-btn-outline { background: transparent; border: 2px solid #ff6b5b; color: #ff6b5b; border-radius: 100px; }
```

## Decorative Elements

- Palm leaf SVG accents in corners (simple, flat-color)
- Wave SVG dividers between sections
- Sun/circle decorations: `border-radius: 50%; background: #f5dfa0; opacity: 0.3`

## Nav

`background: white; box-shadow: 0 2px 20px rgba(0,0,0,0.06)`. Logo with a coral or teal accent. Links clean `text-dark hover:text-coral`. Coral rounded CTA.

## Stat Chips

`border-radius: 100px; background: [color-tint]; border: 2px solid [color]; padding: 8px 16px`. Each stat a different tropical color tint.

## Implementation

- Google Fonts: Nunito (weights 400, 600, 700, 800)
- `antialiased`
- `max-w-6xl mx-auto px-6`
- Section padding: `py-20`
- Emoji accents welcome: 🌴🌊☀️🐠 used minimally as decorative icons
