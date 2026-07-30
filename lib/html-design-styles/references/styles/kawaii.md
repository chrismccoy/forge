# Kawaii Style

Super cute pastel design - bubble-soft rounding, cheerful character mascot accents, candy colors, bouncy animations, and irresistible friendliness. Use when asked for "kawaii style".

## Typography

Nunito (Google Fonts, weight 700-900) - round and bouncy. Or Baloo 2. Headlines very rounded, large, cheerful. `font-extrabold`. Body `font-bold` - even body text feels punchy and expressive.

## Colors

```
Background:   #fff5f9   (blush white)
Pink:         #ffb3c6
Lavender:     #c9b8ff
Mint:         #b8f0d0
Yellow:       #ffe66d
Peach:        #ffcba4
Sky:          #bde8ff
Dark text:    #3d2c5e   (deep purple - friendlier than black)
```

## Kawaii Shapes

```css
/* Blob card shape */
.kawaii-card {
  background: white;
  border-radius: 50% 50% 50% 50% / 40% 40% 60% 60%;
  /* Or: extremely rounded rectangle */
  border-radius: 40px;
  border: 3px solid #3d2c5e;
  box-shadow: 5px 5px 0 #3d2c5e;
  padding: 28px;
}
/* Speech bubble */
.speech-bubble {
  border-radius: 24px;
  position: relative;
}
.speech-bubble::after {
  content: ''; position: absolute; bottom: -16px; left: 24px;
  border: 8px solid transparent;
  border-top-color: #ffb3c6;
}
```

## Bounce Animation

```css
@keyframes bounce {
  0%, 100% { transform: translateY(0); }
  50% { transform: translateY(-8px); }
}
.bounce { animation: bounce 2s ease-in-out infinite; }
@keyframes wiggle {
  0%,100% { transform: rotate(-3deg); }
  50% { transform: rotate(3deg); }
}
.wiggle { animation: wiggle 1s ease-in-out infinite; }
```

## Buttons

```css
.kawaii-btn {
  background: #ffb3c6; color: #3d2c5e;
  border: 3px solid #3d2c5e;
  border-radius: 100px;
  font-weight: 800; font-size: 16px;
  box-shadow: 4px 4px 0 #3d2c5e;
  padding: 12px 28px;
}
.kawaii-btn:hover { transform: translate(-2px, -2px) scale(1.05); box-shadow: 6px 6px 0 #3d2c5e; }
.kawaii-btn:active { transform: translate(2px, 2px); box-shadow: 2px 2px 0 #3d2c5e; }
/* Each button gets a different candy color */
```

## Character/Mascot Accents

Simple emoji or flat SVG character faces used decoratively: `text-4xl` positioned absolutely. Stars and sparkles: `✦ ★ ✿` in candy colors.

## Pill Tags

`border-radius: 100px; border: 2px solid #3d2c5e; background: [pastel]; font-weight: 800; padding: 4px 14px` - each a different pastel.

## Section Backgrounds

Rotate through candy-colored sections: pink → lavender → mint → yellow → peach → sky.

## Star Rating

`★★★★☆` in large yellow, with `font-size: 24px` - cheerful and prominent.

## Implementation

- Google Fonts: Nunito (700, 800, 900)
- `antialiased`
- Character accents: large emoji or flat SVG faces as decorative elements
- Card grids: `gap-6`, `grid-cols-2 md:grid-cols-3`
- Bounce/wiggle animations on hero elements and mascots
- Never use sharp corners - minimum `border-radius: 20px`
