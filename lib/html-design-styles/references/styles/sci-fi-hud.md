# Sci-Fi HUD Style

Heads-up display aesthetic - transparent panels, corner targeting brackets, scanning animations, data readouts, and a sense of augmented reality overlaid on reality. Use when asked for "sci-fi hud style".

## Typography

Orbitron (Google Fonts, weights 400-700) for all display and labels. Share Tech Mono for data readouts. `uppercase` everywhere. `tracking-[0.15em]`. Labels often include `::` or `//` prefixes.

## Colors

```
Background:    #000a12   (near-black with deep blue tint)
Primary:       #00e5ff   (electric cyan)
Secondary:     #00ff9d   (green)
Warning:       #ffcc00
Danger:        #ff3366
Surface:       rgba(0,229,255,0.05)
Border:        rgba(0,229,255,0.3)
```

## Corner Bracket UI

```css
.hud-panel { position: relative; border: 1px solid rgba(0,229,255,0.2); background: rgba(0,229,255,0.03); }
.hud-panel::before, .hud-panel::after,
.hud-panel > .corner-tl, .hud-panel > .corner-br {
  content: ''; position: absolute; width: 14px; height: 14px;
  border-color: #00e5ff; border-style: solid;
}
.hud-panel::before { top: -1px; left: -1px; border-width: 2px 0 0 2px; }
.hud-panel::after  { bottom: -1px; right: -1px; border-width: 0 2px 2px 0; }
```

## Scan Line Animation

```css
@keyframes scan {
  0% { transform: translateY(-100%); }
  100% { transform: translateY(100vh); }
}
.scan-line {
  position: fixed; left: 0; right: 0; height: 2px;
  background: linear-gradient(transparent, rgba(0,229,255,0.4), transparent);
  animation: scan 4s linear infinite;
  pointer-events: none; z-index: 9999;
}
```

## Data Readout Text

```css
.data-label {
  font-family: 'Share Tech Mono'; font-size: 10px;
  color: rgba(0,229,255,0.6); text-transform: uppercase; letter-spacing: 0.2em;
}
.data-value { font-family: 'Orbitron'; color: #00e5ff; font-size: 24px; }
```

Pattern: small label above, large cyan number below.

## Targeting Reticle

```css
.reticle {
  width: 60px; height: 60px; position: relative;
  border: 1px solid rgba(0,229,255,0.3);
  border-radius: 50%;
}
.reticle::before { /* crosshairs */ }
```

## Buttons

```css
.hud-btn {
  background: transparent; color: #00e5ff;
  border: 1px solid rgba(0,229,255,0.5);
  font-family: 'Orbitron'; text-transform: uppercase; letter-spacing: 0.15em; font-size: 11px;
  padding: 12px 28px; clip-path: polygon(8px 0, 100% 0, calc(100% - 8px) 100%, 0 100%);
  box-shadow: 0 0 12px rgba(0,229,255,0.2), inset 0 0 12px rgba(0,229,255,0.05);
}
.hud-btn:hover { background: rgba(0,229,255,0.1); box-shadow: 0 0 24px rgba(0,229,255,0.5); }
```

## Progress/Health Bars

```css
.hud-bar-track { background: rgba(0,229,255,0.1); border: 1px solid rgba(0,229,255,0.3); height: 6px; }
.hud-bar-fill { background: linear-gradient(to right, #00ff9d, #00e5ff); height: 100%; }
```

## Implementation

- Google Fonts: Orbitron + Share Tech Mono
- Scan line as `fixed` element always present
- `overflow: hidden` on sections with corner brackets
- `selection:bg-[#00e5ff] selection:text-black`
- Custom scrollbar: dark track, cyan thin thumb
- All text in cyan family - no white unless for strong contrast
