# Skeuomorphic Style

Design that mimics real physical materials - brushed metal, leather, stitched fabric, paper, wood grain. Realistic depth, textures, and tactile shadows. Use when asked for "skeuomorphic style".

## Typography

SF Pro / system-ui for controls and labels. Georgia or a humanist serif for document-style content. Headlines `font-medium` (not too heavy - the materials carry the visual weight).

## Colors

No single palette - material determines color. Common materials and their values:

```
Metal (silver): background: linear-gradient(145deg, #e0e0e0, #c8c8c8); border: 1px solid #aaa;
Metal (dark):   background: linear-gradient(145deg, #4a4a4a, #2a2a2a);
Leather (tan):  background: #8B6914; texture via noise overlay
Paper:          background: #f9f6f0; subtle noise texture
Wood:           background: linear-gradient(90deg, #8B5E3C, #6B4423, #8B5E3C);
```

## Realistic Shadow System

```css
/* Raised / embossed element */
.raised {
  box-shadow:
    0 1px 0 rgba(255,255,255,0.6) inset,  /* top highlight */
    0 -1px 0 rgba(0,0,0,0.2) inset,       /* bottom inner shadow */
    0 4px 8px rgba(0,0,0,0.3),            /* drop shadow */
    0 1px 3px rgba(0,0,0,0.4);
}
/* Pressed / inset element */
.pressed {
  box-shadow:
    0 1px 0 rgba(255,255,255,0.3),
    0 2px 4px rgba(0,0,0,0.3) inset,
    0 1px 2px rgba(0,0,0,0.5) inset;
}
```

## Metal Button

```css
.metal-btn {
  background: linear-gradient(145deg, #e8e8e8 0%, #c0c0c0 50%, #d8d8d8 100%);
  border: 1px solid #999;
  border-radius: 8px;
  box-shadow: 0 1px 0 rgba(255,255,255,0.8) inset, 0 -1px 0 rgba(0,0,0,0.15) inset, 0 3px 6px rgba(0,0,0,0.25);
  color: #333; font-weight: 500; text-shadow: 0 1px 0 rgba(255,255,255,0.6);
}
.metal-btn:active { box-shadow: 0 1px 2px rgba(0,0,0,0.4) inset; transform: translateY(1px); }
```

## Stitched Edge

```css
.stitched {
  border: 2px solid rgba(0,0,0,0.2);
  outline: 3px dashed rgba(255,255,255,0.25);
  outline-offset: -8px;
}
```

## Paper Texture

```css
.paper {
  background: #f9f6f0;
  background-image: url("data:image/svg+xml,...");  /* SVG noise filter */
  box-shadow: 0 2px 4px rgba(0,0,0,0.1), 0 0 0 1px rgba(0,0,0,0.05);
  border-radius: 2px;
}
/* Page curl effect on corner: use ::after pseudo with gradient */
```

## Progress Bar

```css
.skeuo-progress-track {
  background: linear-gradient(to bottom, #b0b0b0, #d0d0d0);
  border-radius: 10px;
  box-shadow: 0 1px 3px rgba(0,0,0,0.4) inset;
  border: 1px solid #999;
}
.skeuo-progress-fill {
  background: linear-gradient(to bottom, #4a90d9, #2d6fba);
  border-radius: 10px;
  box-shadow: 0 1px 0 rgba(255,255,255,0.4) inset;
}
```

## Toggle / Switch

Raised oval track, circular thumb with gloss highlight. All via `box-shadow` and `border-radius`.

## Implementation

- No Google Fonts required - system-ui for controls
- Every interactive element needs both a rest state (raised) and active state (pressed)
- Use `text-shadow: 0 1px 0 rgba(255,255,255,0.6)` on light buttons, `text-shadow: 0 -1px 0 rgba(0,0,0,0.3)` on dark
- Avoid flat colors - everything should have a gradient or texture
- Consistent light source: top-left. All highlights top-left, all shadows bottom-right.
