# Organic Style

Warm earthy tones, rounded organic shapes, natural textures, and a hand-crafted human feel. Cozy, approachable, and grounded. Use when asked for "organic style".

## Typography

Fraunces (Google Fonts, variable, weights 300-700) for headlines - it has beautiful ink-trap details. Plus Jakarta Sans or DM Sans (light weight) for body. Headlines `font-serif font-semibold` with `leading-tight`. Body `font-sans font-light leading-relaxed`.

## Colors

```
Background:   #faf7f2   (warm cream)
Surface:      #f2ede4   (warm tan card bg)
Deep surface: #e8dfd0   (darker tan)
Text:         #2c2416   (warm dark brown)
Muted:        #8a7560
Terracotta:   #c4623a   (primary accent)
Sage:         #6b8f6e   (secondary accent)
Sand:         #d4b896
Bark:         #7a5c44
```

## Background Texture

Subtle SVG noise or grain at very low opacity over the cream background. Optional: `background-image: url()` with a fine linen texture.

## Organic Shapes - Not Rectangles

All cards and containers use heavily irregular border-radius:

```css
.organic-card {
  border-radius: 30% 70% 70% 30% / 30% 30% 70% 70%;  /* blob */
  /* Or: */
  border-radius: 60px 20px 60px 20px;  /* asymmetric */
}
/* Vary each card's border-radius slightly for a handmade feel */
```

Or use SVG clip-paths for truly organic blobs.

## Section Dividers

Wavy SVG dividers between sections instead of straight lines:

```html
<svg viewBox="0 0 1440 60" preserveAspectRatio="none">
  <path d="M0,30 C360,60 1080,0 1440,30 L1440,60 L0,60 Z" fill="#f2ede4"/>
</svg>
```

## Cards

```css
.organic-card {
  background: #f2ede4;
  border-radius: 24px 8px 24px 8px;  /* slightly irregular */
  box-shadow: 4px 6px 20px rgba(44,36,22,0.08);
  border: 1px solid rgba(44,36,22,0.08);
}
.organic-card:hover { transform: rotate(-0.5deg) translateY(-4px); box-shadow: 6px 10px 28px rgba(44,36,22,0.12); }
```

Slight rotation on hover adds organic feel.

## Buttons

```css
.organic-btn {
  background: #c4623a; color: #faf7f2;
  border-radius: 100px;
  font-semibold; letter-spacing: 0.02em;
  box-shadow: 0 4px 14px rgba(196,98,58,0.3);
  border: none;
}
.organic-btn:hover { background: #b05530; transform: translateY(-2px); box-shadow: 0 6px 20px rgba(196,98,58,0.4); }
.organic-btn-outline {
  background: transparent; color: #c4623a;
  border: 2px solid #c4623a; border-radius: 100px;
}
```

## Icon Treatments

Icons inside rounded blobs with warm bg colors:

```css
.icon-blob {
  width: 56px; height: 56px;
  background: #e8dfd0;
  border-radius: 40% 60% 60% 40% / 40% 40% 60% 60%;  /* organic blob */
  display: flex; align-items: center; justify-content: center;
  color: #c4623a;
}
```

## Nav

`background: #faf7f2; border-bottom: 1px solid #e8dfd0`. Logo in serif. Links `font-light tracking-wide`. CTA: terracotta rounded button.

## Decorative Elements

- Leaf/plant SVG icons scattered as decorative accents
- Hand-drawn underlines via `border-bottom: 3px solid #c4623a` with `border-radius: 0 0 50% 50%`
- Small circular dot patterns at section edges

## Implementation

- Google Fonts: Fraunces + DM Sans
- `antialiased`
- `max-w-5xl` container (narrower, more intimate)
- `py-20 px-6` sections
- Avoid any sharp corners - even form inputs get `border-radius: 12px`
- Color accents: terracotta for CTAs/primary, sage for secondary tags/badges
