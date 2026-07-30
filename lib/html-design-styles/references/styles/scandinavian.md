# Scandinavian Style

Extreme restraint - cold whites, functional typography, generous negative space, subtle warm accents. Hygge meets modernism. Nothing unnecessary. Use when asked for "scandinavian style".

## Typography

Sora or Figtree (Google Fonts, weights 300-600). Never heavy. `font-light` for body, `font-medium` for headings max. Lowercase preferred for headings - no uppercase aggression. Generous `line-height: 1.8`. `tracking-normal` - no wide spacing.

## Colors

```
Background:  #f9f9f7   (barely-warm white)
Surface:     #f2f1ef
Border:      #e5e3df
Text:        #1c1c1a
Muted:       #8a8880
Warm accent: #c4854a   (terracotta - used very sparingly)
Cold accent: #4a7fa5   (slate blue - alternative)
```

One accent color only. Mostly neutrals.

## The Rule of Restraint

- Maximum 2 font weights
- Maximum 1 accent color
- Maximum 3 elements per card
- Whitespace is structural, not decorative

## Cards

```css
.scandi-card {
  background: #f2f1ef;
  border: 1px solid #e5e3df;
  border-radius: 4px;
  padding: 32px;
}
/* No shadow. No hover lift. Just the border lightening slightly. */
.scandi-card:hover { border-color: #c4854a; }
```

## Buttons

```css
.scandi-btn {
  background: #1c1c1a; color: #f9f9f7;
  border: none; border-radius: 2px;
  font-weight: 400; letter-spacing: 0.05em; font-size: 14px;
  padding: 12px 32px;
}
.scandi-btn:hover { background: #c4854a; }
.scandi-btn-ghost { background: transparent; color: #1c1c1a; border: 1px solid #e5e3df; }
.scandi-btn-ghost:hover { border-color: #1c1c1a; }
```

## Dividers

`<hr>` only. `border-top: 1px solid #e5e3df`. Never decorative dividers.

## Nav

Bare. Product name left in `font-light`. Links `text-sm font-light text-muted hover:text-dark`. CTA: `bg-dark text-white text-sm px-5 py-2`. No backdrop blur, no shadow - just a `border-bottom: 1px solid #e5e3df`.

## Whitespace as Design

- Hero: `pt-40 pb-32` minimum
- Between sections: `py-28`
- Between heading and body: `mt-8`
- Cards in a grid: `gap-10` (extra wide gap)

## Accent Usage

The single terracotta or slate blue accent appears on:
- One CTA button
- Hover states on links/cards
- One highlighted stat number
- Icon fill on 1-2 icons

Never as a background, never on text blocks.

## Implementation

- Google Fonts: Sora (weights 300, 400, 500 only)
- `antialiased`
- `max-w-4xl mx-auto` - narrow, intimate
- No Font Awesome - use inline SVGs or Unicode
- Image treatment: `filter: saturate(0.7) contrast(1.05)` for cool Scandinavian photo feel
