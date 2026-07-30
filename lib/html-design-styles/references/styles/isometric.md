# Isometric Style

3D isometric grid with flat-color objects giving depth without perspective. Layered, structural, and playful. Use when asked for "isometric style".

## Typography

IBM Plex Sans or Inter (clean geometric sans). Headlines `font-bold tracking-tight`. Labels `font-mono text-xs uppercase`. The typography is secondary - the isometric illustrations carry the design.

## Colors

```
Background:   #f0f4ff   (soft blue-white)
Top face:     #7c9dff   (lightest - light source)
Left face:    #4a6fe8   (medium)
Right face:   #2a4db5   (darkest - shadow)
Accent top:   #a78bfa
Accent left:  #7c3aed
Accent right: #5b21b6
Neutral top:  #e2e8f0
Neutral left: #94a3b8
Neutral right:#64748b
```

## The Isometric Transform

```css
.iso-scene {
  transform: rotateX(60deg) rotateZ(-45deg);
  transform-style: preserve-3d;
}
/* Or use pure CSS clip-paths for flat isometric faces */
```

## Flat Isometric Cube (CSS)

```css
.iso-cube { position: relative; width: 60px; height: 60px; }
.iso-top {
  position: absolute;
  width: 60px; height: 60px;
  background: #7c9dff;
  transform: rotate(210deg) skewX(-30deg) scaleY(0.864);
}
.iso-left {
  position: absolute; bottom: 0; left: 0;
  width: 60px; height: 40px;
  background: #4a6fe8;
  transform: rotate(90deg) skewX(-30deg) scaleY(0.864) translateY(-50%);
}
.iso-right {
  position: absolute; bottom: 0; right: 0;
  width: 60px; height: 40px;
  background: #2a4db5;
  transform: skewX(-30deg) scaleY(0.864);
}
```

## Cards

Flat cards with an isometric-style top-left shadow that mimics 3D:

```css
.iso-card {
  background: white; border-radius: 12px;
  box-shadow: -6px 6px 0 #2a4db5, -4px 4px 0 #4a6fe8;
}
.iso-card:hover { transform: translate(3px, -3px); box-shadow: -9px 9px 0 #2a4db5, -6px 6px 0 #4a6fe8; }
```

## Buttons

```css
.iso-btn {
  background: #4a6fe8; color: white;
  border-radius: 8px;
  box-shadow: -4px 4px 0 #2a4db5;
  font-weight: 600;
}
.iso-btn:hover { transform: translate(2px, -2px); box-shadow: -6px 6px 0 #2a4db5; }
.iso-btn:active { transform: translate(-2px, 2px); box-shadow: -2px 2px 0 #2a4db5; }
```

## Grid Pattern Background

```css
body::before {
  content: ''; position: fixed; inset: 0; pointer-events: none; opacity: 0.4;
  background-image: url("isometric-grid.svg");  /* SVG isometric grid */
  /* Or use CSS: rotated grid */
  background-image: linear-gradient(60deg, #c7d2fe 1px, transparent 1px),
                    linear-gradient(120deg, #c7d2fe 1px, transparent 1px),
                    linear-gradient(to right, #c7d2fe 1px, transparent 1px);
  background-size: 40px 40px;
}
```

## Implementation

- Google Fonts: IBM Plex Sans
- Illustrations are the centerpiece - build 2-3 isometric feature illustrations
- `overflow: hidden` on sections containing iso scenes
- Neutral page background so the colored faces pop
- Card hover should slide in the iso shadow direction
