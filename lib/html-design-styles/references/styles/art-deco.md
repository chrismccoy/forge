# Art Deco Style

1920s geometric glamour. Symmetrical layouts, sunburst and fan motifs, gold and black, sharp angular ornaments, and an air of opulent formality. Use when asked for "art deco style".

## Typography

Cormorant Garamond or Playfair Display (headlines, weights 300-700) for elegance. Josefin Sans (body/labels, weights 100-400) - ultra-light with wide tracking. Headlines `font-serif font-light tracking-[0.2em] uppercase`. Labels `font-sans font-light text-[11px] tracking-[0.4em] uppercase`.

## Colors

```
Background:   #0d0d0d   (near-black - or ivory #f5f0e8 for light variant)
Gold:         #c9a84c
Gold light:   #e8c97a
Gold dark:    #8b6914
Cream:        #f5f0e8
White:        #ffffff
```

Two variants: **Dark** (black + gold) or **Light** (ivory + gold). Choose one.

## Geometric Ornaments (CSS only)

```css
/* Sunburst lines radiating from center */
.sunburst {
  background: conic-gradient(
    from 0deg, transparent 0deg, transparent 8deg,
    #c9a84c 8deg, #c9a84c 9deg, transparent 9deg
  );
  border-radius: 50%;
}
/* Diamond shape */
.diamond { transform: rotate(45deg); width: 20px; height: 20px; background: #c9a84c; }
/* Fan/chevron pattern as border */
.fan-border {
  border-image: repeating-linear-gradient(
    90deg, #c9a84c 0, #c9a84c 8px, transparent 8px, transparent 16px
  ) 1;
}
```

## Section Dividers

Symmetrical ornamental dividers:

```html
<div class="flex items-center gap-4 my-8">
  <div class="flex-1 h-px bg-gold"></div>
  <div class="diamond"></div>
  <div class="w-2 h-2 rounded-full bg-gold"></div>
  <div class="diamond"></div>
  <div class="flex-1 h-px bg-gold"></div>
</div>
```

## Cards

```css
.deco-card {
  border: 1px solid #c9a84c;
  background: rgba(201,168,76,0.05);  /* dark variant */
  position: relative;
}
/* Gold corner ornaments via ::before/::after */
.deco-card::before {
  content: ''; position: absolute; top: -1px; left: -1px;
  width: 20px; height: 20px;
  border-top: 2px solid #c9a84c; border-left: 2px solid #c9a84c;
}
```

## Buttons

```css
.deco-btn {
  background: transparent; color: #c9a84c;
  border: 1px solid #c9a84c;
  font-family: 'Josefin Sans'; font-weight: 300;
  letter-spacing: 0.4em; text-transform: uppercase; font-size: 11px;
  padding: 14px 48px;
}
.deco-btn:hover { background: #c9a84c; color: #0d0d0d; }
.deco-btn-filled { background: #c9a84c; color: #0d0d0d; }
```

## Masthead / Logo Area

Large, centered product name with decorative line above and below. Flanked by symmetrical ornamental lines: `<hr class="border-gold w-32">` on each side.

## Typography Details

- All headline text centered
- `letter-spacing: 0.2em-0.4em` everywhere
- Numbers in `font-serif font-light` for elegance
- `<em>` elements in italic serif

## Implementation

- Google Fonts: Cormorant Garamond + Josefin Sans
- Strict symmetry - centered layout throughout
- `max-w-4xl mx-auto` - narrower column for formality
- `antialiased`
- Gold used only on ornaments, dividers, borders, and CTAs - never as fill backgrounds
