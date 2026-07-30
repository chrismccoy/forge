# Dark Neon Style

Pure black background with multiple vivid neon colors bleeding and glowing simultaneously. Electric, high-energy, club/gaming aesthetic. Use when asked for "dark neon style".

## Typography

Rajdhani or Exo 2 (Google Fonts, weights 400-700) for body. Orbitron or Russo One for display headlines. Headlines `font-bold uppercase tracking-wide`. Body `font-medium leading-relaxed`.

## Colors

```
Background:  #050505   (pure near-black)
Neon pink:   #ff0090
Neon cyan:   #00f5ff
Neon green:  #39ff14
Neon purple: #bf00ff
Neon orange: #ff6600
White text:  #ffffff
```

Use 3-4 of these simultaneously. Each major feature/section gets its own neon color.

## Neon Glow System

```css
/* Per-color glow classes */
.glow-pink   { box-shadow: 0 0 5px #ff0090, 0 0 20px #ff0090, 0 0 40px #ff0090; }
.glow-cyan   { box-shadow: 0 0 5px #00f5ff, 0 0 20px #00f5ff, 0 0 40px #00f5ff; }
.glow-green  { box-shadow: 0 0 5px #39ff14, 0 0 20px #39ff14, 0 0 40px #39ff14; }
.glow-purple { box-shadow: 0 0 5px #bf00ff, 0 0 20px #bf00ff, 0 0 40px #bf00ff; }

.text-glow-pink   { text-shadow: 0 0 7px #ff0090, 0 0 20px #ff0090; }
.text-glow-cyan   { text-shadow: 0 0 7px #00f5ff, 0 0 20px #00f5ff; }
.text-glow-green  { text-shadow: 0 0 7px #39ff14, 0 0 20px #39ff14; }
```

## Background

Multiple `fixed` radial gradient blobs, very subtle:

```css
.bg-neon-1 { background: radial-gradient(ellipse at 20% 50%, rgba(255,0,144,0.15) 0%, transparent 60%); }
.bg-neon-2 { background: radial-gradient(ellipse at 80% 50%, rgba(0,245,255,0.1) 0%, transparent 60%); }
.bg-neon-3 { background: radial-gradient(ellipse at 50% 80%, rgba(191,0,255,0.1) 0%, transparent 60%); }
```

## Cards

```css
.neon-card {
  background: rgba(255,255,255,0.03);
  border: 1px solid rgba(255,255,255,0.08);
  border-radius: 12px;
}
/* Each card gets a neon color - applied as top border + subtle glow */
.neon-card-pink {
  border-top: 2px solid #ff0090;
  box-shadow: 0 0 20px rgba(255,0,144,0.15), inset 0 1px 0 rgba(255,0,144,0.1);
}
/* hover: glow intensifies, subtle translateY(-4px) */
```

## Buttons

```css
.neon-btn {
  background: transparent;
  border: 1px solid [neon-color];
  color: [neon-color];
  border-radius: 6px;
  font-weight: 600; text-transform: uppercase; letter-spacing: 0.05em;
  box-shadow: 0 0 10px [neon-color-alpha];
}
.neon-btn:hover {
  background: [neon-color-alpha-10];
  box-shadow: 0 0 20px [neon-color], 0 0 40px [neon-color-alpha];
}
/* Filled variant: */
.neon-btn-filled {
  background: [neon-color];
  color: #050505;
  box-shadow: 0 0 20px [neon-color], 0 0 40px [neon-color-alpha];
}
```

## Neon Divider Lines

```css
.neon-line {
  height: 1px;
  background: linear-gradient(to right, transparent, #ff0090, #00f5ff, transparent);
}
```

## Nav

`background: rgba(5,5,5,0.8); backdrop-filter: blur(20px); border-bottom: 1px solid rgba(255,255,255,0.05)`. Logo with neon glow. Links `text-white/60 hover:text-white` - keep nav subtle.

## Stat Numbers

Very large `text-6xl font-bold` in neon color with `text-glow-[color]`. Unit/label in `text-white/50 text-sm`.

## Implementation

- Google Fonts: Rajdhani + Orbitron (or Russo One)
- `overflow-x: hidden`
- `selection:bg-[#ff0090] selection:text-black`
- Custom scrollbar: dark track, neon pink thumb
- `antialiased` on body
- Assign one neon color per major section/feature and be consistent
