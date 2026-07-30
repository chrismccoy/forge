# Zine Style

DIY photocopied aesthetic - rough edges, cut-and-paste collage energy, misaligned text, hand-stamped labels, and raw underground publishing. Intentionally imperfect. Use when asked for "zine style".

## Typography

VT323 or Special Elite (Google Fonts) for headlines - typewriter/distressed feel. Courier New/monospace for body. Mix font sizes dramatically. Headlines can be oversized, italic, or slightly rotated. `font-bold uppercase` but with intentional misalignment.

## Colors

```
Paper:         #f0ebe0   (aged newsprint)
Ink:           #1a1008   (warm near-black)
Red stamp:     #cc1100   (rubber stamp red)
Blue stamp:    #003388
Yellow hi:     #ffd700   (highlighter yellow)
Photocopy gray:#888880
```

Or go full black/white only for maximum xerox authenticity.

## Paper Texture

```css
body {
  background: #f0ebe0;
  background-image: url("paper-noise.svg");  /* grain texture */
  /* CSS approximation: */
  background-image: repeating-linear-gradient(
    0deg, transparent, transparent 2px, rgba(0,0,0,0.015) 2px, rgba(0,0,0,0.015) 4px
  );
}
```

## Cut-and-Paste Cards

Cards look like cut paper pieces layered at angles:

```css
.zine-card {
  background: white;
  border: 2px solid #1a1008;
  transform: rotate(-1.5deg);  /* each card slightly different angle */
  box-shadow: 3px 3px 0 #1a1008;
  padding: 20px;
  position: relative;
}
.zine-card:nth-child(2) { transform: rotate(1deg); }
.zine-card:nth-child(3) { transform: rotate(-0.5deg); }
```

## Stamp / Sticker Labels

```css
.stamp {
  display: inline-block;
  border: 3px solid #cc1100;
  color: #cc1100;
  font-family: monospace; font-weight: 700; text-transform: uppercase;
  padding: 4px 10px;
  transform: rotate(-3deg);
  opacity: 0.85;
  /* Rough edge via filter: */
  filter: contrast(1.3);
}
.stamp-filled { background: #cc1100; color: white; }
```

## Highlighter Effect

```css
.highlight {
  background: linear-gradient(transparent 40%, #ffd700 40%, #ffd700 85%, transparent 85%);
  padding: 0 4px;
}
```

## Tape Strips

```css
.tape {
  background: rgba(255,230,150,0.6);
  border-top: 1px solid rgba(200,180,100,0.3);
  border-bottom: 1px solid rgba(200,180,100,0.3);
  height: 24px; width: 60px;
  transform: rotate(-3deg);
  position: absolute; top: -12px; left: 50%; transform: translateX(-50%) rotate(-3deg);
}
```

## Buttons

```css
.zine-btn {
  background: #1a1008; color: #f0ebe0;
  border: none; font-family: monospace; font-weight: 700; text-transform: uppercase;
  padding: 12px 28px;
  clip-path: polygon(2px 0, 100% 0, calc(100% - 2px) 100%, 0 100%);  /* slightly trapezoid */
}
.zine-btn:hover { background: #cc1100; }
```

## Layout

Content intentionally NOT perfectly aligned. Slight rotations, varying card sizes, grid-breaking elements. Headers can overlap visually. Use `position: relative` with small offsets.

## Implementation

- Google Fonts: Special Elite + VT323
- Embrace imperfection - intentional misalignment is the style
- `filter: contrast(1.1) brightness(0.98)` on images for photocopy feel
- `mix-blend-mode: multiply` on overlapping elements
