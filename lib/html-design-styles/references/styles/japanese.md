# Japanese Style

Wabi-sabi imperfection, generous negative space treated as structure, ink brush strokes, asymmetric balance, and the visual philosophy that emptiness carries meaning. Use when asked for "japanese style".

## Typography

Cormorant Garamond (headlines - elegant, high contrast strokes) + Source Sans 3 (body, weight 300). Headlines `font-serif font-light tracking-[0.3em] uppercase`. Sometimes vertical text via `writing-mode: vertical-rl`. Large single characters as decorative elements.

## Colors

```
Washi white:   #f7f4ef   (warm, slightly textured)
Sumi black:    #1a1612   (warm near-black, like ink)
Persimmon:     #d9603b   (one accent - Japanese persimmon red)
Bamboo:        #7a9966
Midnight:      #1e2440
Muted:         #8a8070
Gold:          #c9922a   (optional second accent - gold leaf)
```

## Washi Paper Texture

```css
body {
  background: #f7f4ef;
  background-image: url("washi-grain.svg");
  /* CSS approximation: subtle noise */
  background-image: repeating-linear-gradient(
    0deg, transparent 0px, transparent 3px,
    rgba(0,0,0,0.01) 3px, rgba(0,0,0,0.01) 4px
  );
}
```

## Negative Space as Structure

Sections deliberately asymmetric. Content floated to one side, large empty space on the other. Never centered - always slightly off-balance in a considered way.

## Ink Brush Dividers

```css
.brush-line {
  height: 2px;
  background: linear-gradient(to right, #1a1612, #1a1612 60%, transparent 100%);
  border-radius: 0 0 50% 50%;
  /* Simulates brush stroke ending that feathers out */
}
```

## Large Kanji / Character Watermark

```css
.kanji-watermark {
  font-family: serif; font-size: 20vw; line-height: 1;
  color: rgba(26,22,18,0.04);
  position: absolute; right: -0.1em; top: 0;
  writing-mode: vertical-rl; user-select: none;
  pointer-events: none;
}
```

Use a Japanese character or a Roman letter with extreme scale.

## Cards

```css
.wabi-card {
  background: white;
  border-top: 2px solid #d9603b;  /* persimmon top accent only */
  padding: 32px 28px;
  box-shadow: 0 2px 12px rgba(26,22,18,0.06);
  border-radius: 2px;  /* almost no rounding */
}
```

## Buttons

```css
.japan-btn {
  background: transparent; color: #d9603b;
  border: 1px solid #d9603b;
  border-radius: 2px;
  font-family: 'Source Sans 3'; font-weight: 300;
  letter-spacing: 0.3em; text-transform: uppercase; font-size: 12px;
  padding: 12px 36px;
}
.japan-btn:hover { background: #d9603b; color: white; }
.japan-btn-filled { background: #1a1612; color: #f7f4ef; border-color: #1a1612; }
```

## Vertical Text Accent

```css
.vertical-label {
  writing-mode: vertical-rl; text-orientation: mixed;
  font-family: 'Cormorant Garamond'; font-size: 11px;
  letter-spacing: 0.3em; text-transform: uppercase;
  color: #8a8070;
}
```

Used as section labels running vertically along the left margin.

## Implementation

- Google Fonts: Cormorant Garamond + Source Sans 3 (weight 300)
- `antialiased`
- `max-w-5xl mx-auto` - restraint in width
- Sections: `py-32` - generous vertical space
- Images: `filter: saturate(0.6) contrast(1.1)` - muted, contemplative
- Never use bold - `font-light` or `font-normal` maximum
