# Gothic Style

Deep forest greens and near-blacks, ornate serif typography, candle-wax drip textures, wrought-iron motifs, and a sense of ancient dark romance. Use when asked for "gothic style".

## Typography

IM Fell English or Cinzel (Google Fonts) for display - classical, engraved. Crimson Text for body - readable serif with old character. Headlines `font-serif uppercase tracking-[0.1em]`. Body `font-serif leading-relaxed`.

## Colors

```
Background:   #0a0c0a   (near-black with green tint)
Surface:      #111811
Dark green:   #1a2e1a
Forest:       #2d4a2d
Gold:         #b8962e
Blood red:    #8b1a1a
Bone white:   #e8e4d8
Muted:        #6b7a6b
```

## Background Texture

```css
body {
  background: #0a0c0a;
  background-image:
    radial-gradient(ellipse at 50% 0%, rgba(45,74,45,0.4) 0%, transparent 70%);
}
/* Optional: SVG noise grain for parchment/stone texture */
```

## Cards / Panels

```css
.gothic-panel {
  background: #111811;
  border: 1px solid rgba(184,150,46,0.3);
  position: relative;
}
/* Ornamental corner flourish using ::before/::after */
.gothic-panel::before {
  content: '✦'; position: absolute; top: 8px; left: 12px;
  color: rgba(184,150,46,0.4); font-size: 14px;
}
```

## Ornamental Dividers

```html
<!-- Between sections -->
<div class="flex items-center gap-3 my-12">
  <div class="flex-1 h-px" style="background: linear-gradient(to right, transparent, #b8962e)"></div>
  <span class="text-gold font-serif text-xl">✦</span>
  <div class="flex-1 h-px" style="background: linear-gradient(to left, transparent, #b8962e)"></div>
</div>
```

## Drip / Candle Wax Effect

```css
.wax-drip {
  position: relative;
  border-top: 4px solid #8b1a1a;
}
.wax-drip::after {
  content: '';
  position: absolute; top: -4px; left: 20%;
  width: 12px; height: 24px;
  background: #8b1a1a;
  clip-path: polygon(0 0, 100% 0, 80% 100%, 20% 100%);  /* drip shape */
  border-radius: 0 0 50% 50%;
}
```

## Buttons

```css
.gothic-btn {
  background: transparent; color: #b8962e;
  border: 1px solid rgba(184,150,46,0.5);
  font-family: 'Cinzel'; text-transform: uppercase; letter-spacing: 0.2em; font-size: 11px;
  padding: 14px 40px;
}
.gothic-btn:hover { background: rgba(184,150,46,0.1); border-color: #b8962e; }
.gothic-btn-filled { background: #8b1a1a; color: #e8e4d8; border-color: #8b1a1a; }
```

## Nav

Dark with thin gold bottom border. Product name in Cinzel. Links `font-serif text-sm text-muted hover:text-bone`.

## Implementation

- Google Fonts: Cinzel + Crimson Text
- `antialiased`
- `selection:bg-[#8b1a1a] selection:text-[#e8e4d8]`
- Font Awesome: `fa-crow`, `fa-moon`, `fa-skull` for thematic icons
- Section backgrounds: alternate between `#0a0c0a` and `#111811`
- Gold used only for ornaments and borders - never as fill
