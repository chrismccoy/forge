# Cyberpunk Style

High-contrast yellow and black warning stripes, HUD-style corner brackets, neon magenta/cyan on near-black, and a sense of industrial danger. Dystopian and electric. Use when asked for "cyberpunk style".

## Typography

Rajdhani or Barlow Condensed (Google Fonts, weights 400-700) for body. Orbitron for display/headlines. Headlines `font-bold uppercase tracking-wider`. Labels `font-mono text-xs uppercase tracking-[0.2em]`.

## Colors

```
Background:    #0a0a0f
Surface:       #12121a
Yellow:        #f5e642   (warning/primary)
Magenta:       #ff003c
Cyan:          #00f0ff
White:         #e8e8ff   (slightly blue-tinted white)
Muted:         #4a4a6a
Danger stripe: repeating yellow/black
```

## Warning Stripe Pattern

```css
.hazard-stripe {
  background: repeating-linear-gradient(
    -45deg,
    #f5e642 0px, #f5e642 10px,
    #0a0a0f 10px, #0a0a0f 20px
  );
  height: 6px;
}
```

Use as section dividers, button borders, header accents.

## Corner Bracket Decoration

```css
.bracket-corner { position: relative; }
.bracket-corner::before, .bracket-corner::after {
  content: ''; position: absolute; width: 16px; height: 16px;
  border-color: #f5e642; border-style: solid;
}
.bracket-corner::before { top: 0; left: 0; border-width: 2px 0 0 2px; }
.bracket-corner::after  { bottom: 0; right: 0; border-width: 0 2px 2px 0; }
```

## Cards

```css
.cyber-card {
  background: #12121a;
  border: 1px solid rgba(245,230,66,0.2);
  border-radius: 4px;
  position: relative;
  clip-path: polygon(0 0, calc(100% - 16px) 0, 100% 16px, 100% 100%, 16px 100%, 0 calc(100% - 16px));
}
.cyber-card::before { /* top-right angled corner accent */ }
```

Clipped corners (diagonal cut) are the signature card shape.

## Buttons

```css
.cyber-btn {
  background: #f5e642; color: #0a0a0f;
  border: none; border-radius: 2px;
  font-family: 'Orbitron'; font-weight: 700; text-transform: uppercase; letter-spacing: 0.1em;
  clip-path: polygon(0 0, calc(100% - 8px) 0, 100% 8px, 100% 100%, 8px 100%, 0 calc(100% - 8px));
  box-shadow: 0 0 20px rgba(245,230,66,0.4);
}
.cyber-btn:hover { box-shadow: 0 0 40px rgba(245,230,66,0.8); filter: brightness(1.1); }
.cyber-btn-outline {
  background: transparent; color: #00f0ff;
  border: 1px solid #00f0ff;
  box-shadow: 0 0 10px rgba(0,240,255,0.3), inset 0 0 10px rgba(0,240,255,0.05);
}
```

## HUD Elements

- `[SYS::ONLINE]` style labels in monospace with `::before { content: '> '; color: #f5e642; }`
- Scan-line animated div: `animation: scan 3s linear infinite; background: linear-gradient(transparent, rgba(0,240,255,0.05), transparent)`
- Progress meters with `border: 1px solid #f5e642; box-shadow: 0 0 8px rgba(245,230,66,0.4)`

## Nav

`border-bottom: 1px solid rgba(245,230,66,0.3)`. Hazard stripe as 4px top bar. Logo: `[BRAND_ID]` in Orbitron. Links `font-mono text-xs uppercase tracking-[0.2em] text-white/60 hover:text-[#f5e642]`.

## Implementation

- Google Fonts: Orbitron + Rajdhani
- `clip-path` for angled corners on key elements
- Hazard stripes as borders, not fills
- `selection:bg-[#f5e642] selection:text-black`
- Custom scrollbar: dark track, yellow thumb
- `antialiased` on body
