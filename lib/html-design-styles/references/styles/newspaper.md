# Newspaper Style

Black ink on off-white newsprint. Serif headlines, column grid layouts, editorial cutlines, and print-inspired decoration. Timeless and authoritative. Use when asked for "newspaper style".

## Typography

Playfair Display (headlines, weights 400-900) + Source Serif 4 or Lora (body, weights 400-600). Headlines `font-serif font-black italic tracking-tight leading-none`. Subheads `font-serif font-bold uppercase tracking-widest text-sm`. Body `font-serif text-base leading-relaxed`. Labels/captions `font-sans text-xs uppercase tracking-widest`.

## Colors

```
Paper:      #f5f0e8   (warm newsprint off-white)
Ink:        #1a1a1a   (near-black)
Rule:       #1a1a1a   (border lines)
Muted:      #6b6560   (secondary text, captions)
Red accent: #c0392b   (section flag color - used sparingly)
```

No gradients. Flat colors only, like print.

## Page Background

`background: #f5f0e8` - warm off-white throughout. Optional paper texture via SVG noise filter at very low opacity.

## Masthead / Header

Full-width `border-b-4 border-ink`. Newspaper name in massive Playfair Display italic, centered. Below: thin rule line + date/edition/tagline in `font-sans text-xs uppercase tracking-[0.3em]`. Above: `border-t-2 border-ink` and thin rule.

## Column Grid

Multi-column editorial layout using CSS columns or explicit grid:

```css
.column-grid-3 { display: grid; grid-template-columns: repeat(3, 1fr); gap: 0; }
.column-divider { border-right: 1px solid #1a1a1a; padding-right: 24px; }
/* Each column gets padding-left: 24px except first */
```

## Article Cards

No box-shadow, no radius. `border-top: 3px solid #1a1a1a` accent on top of featured articles. Headline in Playfair italic. Byline: `font-sans text-xs uppercase text-muted`. Cutline (image caption): `font-sans text-xs italic text-muted border-t border-ink pt-1 mt-1`.

## Section Flags

`background: #1a1a1a; color: #f5f0e8; font-sans font-black uppercase tracking-widest text-xs px-3 py-1` - small banner before section headings. Or red variant: `background: #c0392b`.

## Pull Quote

`border-left: 4px solid #1a1a1a; border-right: 4px solid #1a1a1a; padding: 16px 24px; font-serif font-bold text-xl italic text-center`. Top and bottom `border-top: 1px solid #1a1a1a`.

## Rule Lines

Use `<hr>` or `border-t` liberally to divide sections - 3px for major, 1px for minor, double (`border-double`) for special separators.

## Drop Cap

```css
.drop-cap::first-letter {
  float: left; font-family: 'Playfair Display'; font-size: 4.5rem;
  font-weight: 900; line-height: 0.8; margin-right: 8px; margin-top: 4px;
}
```

## Buttons

`border: 2px solid #1a1a1a; background: #1a1a1a; color: #f5f0e8; font-sans font-bold uppercase tracking-widest px-6 py-3`. Hover: `background: transparent; color: #1a1a1a`. No border-radius. No shadows.

## Implementation

- Google Fonts: Playfair Display + Lora (or Source Serif 4)
- No rounded corners anywhere - print is rectangular
- `max-w-6xl mx-auto px-6`
- `antialiased` on body
- Sections separated by rule lines, not whitespace
- Image treatments: `filter: grayscale(20%) contrast(1.1)` for print-like photos
