# Cottagecore Style

Soft floral patterns, watercolor-inspired washes, botanical illustration accents, handwritten feel, and the warm comfort of a storybook cottage. Use when asked for "cottagecore style".

## Typography

Playfair Display (headlines, weights 400-700, italic for key phrases) + Lato Light (body, weight 300). Headlines `font-serif font-normal italic`. Body `font-sans font-light leading-loose`. Labels in `font-serif text-sm tracking-wide`.

## Colors

```
Background:    #fdf8f2   (warm cream parchment)
Sage green:    #8aaa7a
Dusty rose:    #d4848a
Lavender:      #b8a9c9
Warm tan:      #c9a87c
Blush:         #f2d4c8
Mushroom:      #b8a090
Dark text:     #3d2b1f   (warm dark brown)
Muted:         #8a7060
```

## Botanical Accent Pattern

```css
.botanical-bg {
  background-image: url("leaves.svg"), url("flowers.svg");  /* SVG botanicals */
  background-repeat: no-repeat;
  background-position: top right, bottom left;
  background-size: 200px, 180px;
  opacity: 0.15;
}
```

Simple flat SVG leaf/flower shapes at very low opacity in page corners and section edges.

## Watercolor Cards

```css
.cottage-card {
  background: #fdf8f2;
  border: 1px solid rgba(200,160,120,0.3);
  border-radius: 16px 8px 16px 8px;  /* slightly irregular */
  box-shadow: 0 4px 20px rgba(61,43,31,0.08);
  padding: 28px;
  position: relative;
}
/* Subtle watercolor wash on card ::before */
.cottage-card::before {
  content: ''; position: absolute; inset: 0; border-radius: inherit;
  background: linear-gradient(135deg, rgba(138,170,122,0.05), rgba(212,132,138,0.05));
  pointer-events: none;
}
```

## Section Dividers

SVG wavy botanical border - or simple: `border-top: 1px solid rgba(201,168,124,0.4)` with a small centered floral `✿` motif.

## Buttons

```css
.cottage-btn {
  background: #8aaa7a; color: white;
  border: none; border-radius: 100px;
  font-family: 'Playfair Display'; font-style: italic; font-size: 16px;
  padding: 14px 36px;
  box-shadow: 0 4px 16px rgba(138,170,122,0.35);
}
.cottage-btn:hover { background: #7a9a6a; transform: translateY(-2px); box-shadow: 0 8px 24px rgba(138,170,122,0.45); }
.cottage-btn-rose { background: #d4848a; box-shadow: 0 4px 16px rgba(212,132,138,0.35); }
.cottage-btn-outline { background: transparent; border: 1.5px solid #8aaa7a; color: #3d2b1f; border-radius: 100px; }
```

## Floral Tag Pills

`border-radius: 100px; border: 1px solid [color]; background: [color-tint]; padding: 4px 14px; font-serif italic`. Small `✿` before text.

## Quote / Poem Block

`border-left: 3px solid #d4848a; padding: 16px 24px; font-serif italic text-lg text-dark/70`. Attribution in `font-sans text-sm text-muted`.

## Nav

Minimal. No hard lines. `border-bottom: 1px solid rgba(201,168,124,0.3)`. Logo in Playfair italic. Links `font-serif text-sm italic text-muted hover:text-dark`. Sage CTA button.

## Implementation

- Google Fonts: Playfair Display + Lato
- `antialiased`
- Botanical SVG accents in corners (transparent, decorative only)
- `max-w-5xl` container for intimate feel
- Section padding: `py-20`
- Images: warm-toned, `filter: saturate(0.8) sepia(10%)` for cottage photo feel
