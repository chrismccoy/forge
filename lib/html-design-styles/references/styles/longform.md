# Longform Style

Rich magazine editorial layout - full-bleed hero photography, typographic hierarchy for long reads, pull quotes, drop caps, sidebar annotations, and immersive scrolling narrative. Use when asked for "longform style".

## Typography

Merriweather (body - optimized for reading, 300-700) + Playfair Display (headlines - editorial drama). Subheads: `font-sans font-semibold uppercase tracking-widest text-sm`. Body: `font-serif font-light text-lg leading-[1.9]`. Headlines: `font-serif font-bold tracking-tight leading-none`.

## Colors

```
Background:    #ffffff
Text:          #1a1a1a
Muted:         #6b6b6b
Accent:        #c0392b   (editorial red - for section markers, pull quotes)
Border:        #e8e8e8
Hero overlay:  rgba(0,0,0,0.4)
Byline gray:   #888888
```

## Full-Bleed Hero

```css
.hero-fullbleed {
  height: 90vh; min-height: 600px;
  background-size: cover; background-position: center;
  position: relative;
  display: flex; align-items: flex-end;
}
.hero-fullbleed::after {
  content: ''; position: absolute; inset: 0;
  background: linear-gradient(to top, rgba(0,0,0,0.8) 0%, transparent 60%);
}
/* Headline overlaid on bottom of image */
.hero-headline {
  position: relative; z-index: 1; color: white;
  padding: 48px; max-width: 800px;
}
```

## Reading Column

```css
.reading-col {
  max-width: 680px; margin: 0 auto;
  padding: 48px 24px;
  font-family: 'Merriweather'; font-size: 19px; line-height: 1.9;
}
```

## Drop Cap

```css
.drop-cap::first-letter {
  float: left;
  font-family: 'Playfair Display'; font-size: 5.5rem; font-weight: 700;
  line-height: 0.75; margin-right: 12px; margin-top: 8px;
  color: #1a1a1a;
}
```

## Pull Quote

```css
.pull-quote {
  border-top: 3px solid #c0392b;
  border-bottom: 1px solid #e8e8e8;
  padding: 24px 0;
  margin: 48px 0;
  font-family: 'Playfair Display'; font-style: italic;
  font-size: clamp(22px, 3vw, 32px);
  font-weight: 400; line-height: 1.4;
  color: #1a1a1a;
}
```

## Section Header (chapter-style)

```css
.chapter-head {
  font-family: 'Merriweather'; font-size: 11px;
  font-weight: 700; text-transform: uppercase; letter-spacing: 0.25em;
  color: #c0392b; padding-bottom: 12px;
  border-bottom: 1px solid #e8e8e8; margin-bottom: 32px;
}
```

## Image Caption

`font-sans text-sm text-muted leading-snug border-top border-[#e8e8e8] pt-2 mt-2`.

## Sidebar Annotation

```css
.annotation {
  position: absolute; right: -200px; width: 180px;
  font-sans font-normal text-sm text-muted line-height-[1.5];
  border-left: 2px solid #c0392b; padding-left: 12px;
}
```

## Byline / Meta

`font-sans text-sm text-muted uppercase tracking-widest` for author. `•` separator. Date.

## Implementation

- Google Fonts: Merriweather (300, 400, 700) + Playfair Display (400, 700)
- `antialiased`
- Single reading column `max-w-[680px]` for body text
- Wide-format callouts break out of column via negative margins: `margin: 0 -80px`
- Image treatment: editorial, slightly high-contrast
- No sidebar nav - this is immersive, distraction-free reading
