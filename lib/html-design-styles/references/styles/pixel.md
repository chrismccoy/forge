# Pixel Style

8-bit retro game aesthetic - pixelated fonts, chunky bordered UI panels, sprite-like icons, and classic game interface elements. Nostalgic and playful. Use when asked for "pixel style".

## Typography

Press Start 2P (Google Fonts) - the quintessential pixel font. Use sparingly at small sizes (it reads poorly above 24px in paragraph form). Body text at `text-xs leading-loose` because the font is dense. Headlines at `text-2xl md:text-4xl`.

## Colors

Classic game palettes - choose one:

```
NES palette:    #0f0f0f, #fcfcfc, #f83800, #0070ec, #fbbc00
Game Boy:       #0f380f, #306230, #8bac0f, #9bbc0f  (4 greens only)
CGA palette:    #000000, #ffffff, #ff5555, #55ffff   (high contrast)
Modern pixel:   #1a1c2c, #5d275d, #b13e53, #ef7d57, #ffcd75, #a7f070, #38b764
```

## Pixel Border

```css
/* CSS pixel border using box-shadow */
.pixel-border {
  box-shadow:
    0 -4px 0 0 #000,   /* top */
    0 4px 0 0 #000,    /* bottom */
    -4px 0 0 0 #000,   /* left */
    4px 0 0 0 #000;    /* right */
  /* Or use image-rendering: pixelated on border images */
}
/* Panel style */
.pixel-panel {
  border: 4px solid #000;
  outline: 4px solid #fff;
  outline-offset: -8px;
  background: #1a1c2c;
  image-rendering: pixelated;
}
```

## Buttons

```css
.pixel-btn {
  background: #38b764; color: #000;
  border: 4px solid #000;
  font-family: 'Press Start 2P'; font-size: 10px; text-transform: uppercase;
  padding: 12px 20px;
  box-shadow: 4px 4px 0 #000;
  image-rendering: pixelated;
}
.pixel-btn:hover { transform: translate(-2px, -2px); box-shadow: 6px 6px 0 #000; }
.pixel-btn:active { transform: translate(2px, 2px); box-shadow: 2px 2px 0 #000; }
/* Health bar style CTA */
.pixel-btn-red { background: #b13e53; color: white; }
```

## Health/Progress Bar

```css
.pixel-bar {
  border: 4px solid #000; background: #1a1c2c;
  height: 20px; padding: 2px;
  image-rendering: pixelated;
}
.pixel-bar-fill {
  height: 100%; background: #38b764;
  image-rendering: pixelated;
  /* Animate: from 0 to value */
}
```

## Dialogue Box

```css
.pixel-dialogue {
  border: 4px solid #fff; outline: 4px solid #000; outline-offset: -8px;
  background: #1a1c2c; color: #fff;
  font-family: 'Press Start 2P'; font-size: 10px; line-height: 2;
  padding: 20px;
}
.pixel-dialogue::after { content: '▼'; animation: blink 1s step-end infinite; }
```

## Stars/Score Display

`★★★★☆` in pixel font. XP/points in large pixel numbers.

## Implementation

- Google Fonts: Press Start 2P only
- `image-rendering: pixelated` on all game elements
- `cursor: default` or a custom pixel cursor
- Background: dark with pixel grid `background-size: 4px 4px` at 1px lines
- Avoid anti-aliasing: `font-smooth: never`
- `letter-spacing: 0.1em` on Press Start 2P to aid readability
