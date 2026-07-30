# Luxury Style

Refined, editorial, and expensive-feeling. Cream backgrounds, a single serif display font, gold/brass accents, and generous whitespace. Less is more. Use when asked for "luxury style".

## Typography

Cormorant Garamond or Bodoni Moda (Google Fonts, weights 300-700) for all display and headlines. Optionally pair with Jost or Montserrat (300-400 weight only) for body. Headlines `font-serif font-light tracking-[0.15em] uppercase`. Body `font-sans font-light leading-loose tracking-wide`. All caps labels at `text-[11px] tracking-[0.3em]`.

## Colors

```
Background:  #f8f4ef   (warm cream)
Surface:     #ffffff
Text:        #1c1917   (warm near-black)
Muted:       #78716c
Gold:        #b8942a   (brass/gold - used sparingly)
Gold light:  #d4af6a
Border:      #e5ddd3   (warm light gray)
```

## Whitespace

The defining characteristic. Sections use `py-32 md:py-48`. Cards have `p-10 md:p-14`. Hero padding `pt-40 pb-32`. Never crowd elements - breathing room is the luxury.

## Section Dividers

Thin gold lines: `border-top: 1px solid #b8942a` centered, max-width 80px, `mx-auto`. Or: `<div class="w-16 h-px bg-gold mx-auto my-12">`.

## Cards

No box-shadow. `border: 1px solid #e5ddd3; background: white`. On hover: `border-color: #d4af6a` - the gold border appears.

## Headlines

`font-serif font-light text-5xl md:text-7xl tracking-[0.1em] uppercase leading-tight`. Often split across 2 lines with intentional line breaks. Italics used for emphasis: `<em class="font-serif italic not-italic font-light">`.

## Gold Accent Elements

- Thin gold line under logo
- Gold `•` bullet separators in nav
- Gold number labels on steps/features
- Gold top border on featured cards: `border-top: 2px solid #b8942a`
- Never fill a button entirely in gold - it reads cheap

## Buttons

```css
.lux-btn {
  border: 1px solid #1c1917; background: transparent; color: #1c1917;
  font-sans; font-light; text-transform: uppercase; letter-spacing: 0.2em; font-size: 11px;
  padding: 14px 40px;
}
.lux-btn:hover { background: #1c1917; color: #f8f4ef; }
.lux-btn-gold { border-color: #b8942a; color: #b8942a; }
.lux-btn-gold:hover { background: #b8942a; color: white; }
```

No border-radius or minimal (2px). No shadows.

## Nav

No box-shadow. `border-bottom: 1px solid #e5ddd3`. Logo: brand name in serif, small. Links: `text-[11px] uppercase tracking-[0.2em] font-light`. Gold CTA button.

## Quote / Testimonial

Massive `"` character in gold at 6rem, `font-serif font-light`. Quote text in serif italic. Attribution in small caps.

## Pricing

No card. Just: price in large serif, a thin gold rule, then a feature list with `•` bullets, then a button. Centered. Maximum whitespace.

## Implementation

- Google Fonts: Cormorant Garamond (or Bodoni Moda) + Jost
- `antialiased`
- `max-w-5xl` container (narrower for luxury feel)
- Image treatment: slightly desaturated `filter: saturate(0.85) contrast(1.05)`
- No Font Awesome - use Unicode symbols (→ ← • ") or inline SVGs
- Every element should feel like it has room to breathe
