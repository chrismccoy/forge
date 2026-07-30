# Grunge Style

Distressed textures, worn edges, splatter marks, rough typography, and a raw underground aesthetic. Feels printed, aged, and weathered. Use when asked for "grunge style".

## Typography

Bebas Neue (Google Fonts) for display - tall, condensed, bold. Courier New/monospace for body text - typewriter worn. Headlines `uppercase tracking-widest`. Mix sizes aggressively.

## Colors

```
Paper:        #d4c9b0   (aged, yellowed)
Ink:          #1a1208   (warm near-black)
Rust:         #8b3a1a
Olive:        #4a5c2a
Cream:        #f0e8d8
Blood:        #6b0f0f
Distressed:   #888070
```

## Texture Overlays

```css
/* Grain texture */
body::before {
  content: ''; position: fixed; inset: 0; pointer-events: none; z-index: 9999;
  background-image: url("grain.svg");
  opacity: 0.25; mix-blend-mode: multiply;
}
/* Aged paper background */
body {
  background: #d4c9b0;
  background-image:
    url("paper-texture.png"),
    radial-gradient(ellipse at 30% 20%, rgba(139,58,26,0.08) 0%, transparent 60%);
}
```

## Distressed Borders

```css
.grunge-border {
  border: 3px solid #1a1208;
  /* Rough edge via filter displacement */
  filter: url(#roughen);
  /* Or: use box-shadow for torn look */
  box-shadow: 2px 2px 0 #888070, 4px 4px 0 #666050;
}
```

## Splatter Element

```css
/* Ink splatter as ::before positioned absolutely */
.splatter::before {
  content: ''; position: absolute;
  background: #1a1208;
  clip-path: polygon(50% 0%, 62% 20%, 90% 10%, 75% 35%, 100% 50%, 75% 55%, 85% 85%, 60% 70%, 55% 100%, 40% 75%, 15% 90%, 35% 60%, 0 50%, 30% 40%, 10% 15%, 40% 25%);
  width: 40px; height: 40px; opacity: 0.15;
}
```

## Cards

```css
.grunge-card {
  background: #f0e8d8;
  border: 2px solid #1a1208;
  box-shadow: 4px 4px 0 #888070;
  padding: 24px;
  position: relative;
  transform: rotate(-0.5deg);  /* slight lean */
}
```

## Buttons

```css
.grunge-btn {
  background: #1a1208; color: #d4c9b0;
  border: 2px solid #1a1208;
  font-family: 'Bebas Neue'; font-size: 18px; text-transform: uppercase; letter-spacing: 0.1em;
  padding: 12px 32px;
  box-shadow: 3px 3px 0 #888070;
}
.grunge-btn:hover { background: #8b3a1a; transform: translate(-1px, -1px); box-shadow: 5px 5px 0 #666050; }
.grunge-btn-outline { background: transparent; color: #1a1208; border: 2px solid #1a1208; }
```

## Stamp Marks

`background: [color]; color: white; font-weight: 900; text-transform: uppercase; letter-spacing: 0.2em; padding: 4px 12px; transform: rotate(-8deg); opacity: 0.7; filter: contrast(1.5)` - applied to "SOLD", "FEATURED", "NEW" labels.

## Implementation

- Google Fonts: Bebas Neue
- Apply SVG displacement filter for roughened edges where possible
- `mix-blend-mode: multiply` on texture overlays
- Images: `filter: grayscale(30%) contrast(1.2) sepia(20%)` for aged photo look
- `overflow-x: hidden`
