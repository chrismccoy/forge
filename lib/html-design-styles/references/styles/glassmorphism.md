# Glassmorphism Style

Frosted glass cards floating over vivid gradient mesh backgrounds. Translucent surfaces, soft blurs, glowing borders. Feels futuristic and airy. Use when asked for "glassmorphism style".

## Typography

Outfit or DM Sans (Google Fonts, weights 300-800). Headlines `font-extrabold tracking-tight`. Body `font-light leading-relaxed`. Labels `font-semibold text-xs uppercase tracking-widest`.

## Colors

```
No fixed palette - the gradient mesh provides color.
Text on glass:  rgba(255,255,255,0.95)  (primary)
Text muted:     rgba(255,255,255,0.6)
Glass surface:  rgba(255,255,255,0.08) to rgba(255,255,255,0.15)
Glass border:   rgba(255,255,255,0.2)
```

Background is always a vivid gradient mesh - never a flat color.

## Background Gradient Mesh

Layer multiple large blurred blobs over a deep base color:

```css
body { background: #0f0f1a; }  /* deep base */

/* Mesh blobs - position freely */
.blob-1 { position:fixed; width:600px; height:600px; border-radius:50%; background: radial-gradient(circle, #7c3aed, transparent 70%); top:-200px; left:-100px; opacity:0.6; filter:blur(80px); }
.blob-2 { position:fixed; width:500px; height:500px; border-radius:50%; background: radial-gradient(circle, #06b6d4, transparent 70%); bottom:-100px; right:-100px; opacity:0.5; filter:blur(80px); }
.blob-3 { position:fixed; width:400px; height:400px; border-radius:50%; background: radial-gradient(circle, #ec4899, transparent 70%); top:40%; left:40%; opacity:0.3; filter:blur(100px); }
```

Choose a color story: purple+cyan, pink+orange, blue+green, etc.

## Glass Cards

```css
.glass-card {
  background: rgba(255,255,255,0.08);
  backdrop-filter: blur(20px);
  -webkit-backdrop-filter: blur(20px);
  border: 1px solid rgba(255,255,255,0.15);
  border-radius: 24px;
  box-shadow: 0 8px 32px rgba(0,0,0,0.3), inset 0 1px 0 rgba(255,255,255,0.15);
}
.glass-card:hover {
  background: rgba(255,255,255,0.12);
  border-color: rgba(255,255,255,0.25);
  transform: translateY(-4px);
}
```

## Glass Buttons

```css
.glass-btn {
  background: rgba(255,255,255,0.15);
  backdrop-filter: blur(10px);
  border: 1px solid rgba(255,255,255,0.25);
  border-radius: 100px;
  color: white; font-weight: 600;
  box-shadow: 0 4px 15px rgba(0,0,0,0.2), inset 0 1px 0 rgba(255,255,255,0.2);
}
.glass-btn-accent {
  background: rgba(124,58,237,0.7);  /* tinted with brand color */
  backdrop-filter: blur(10px);
  border: 1px solid rgba(255,255,255,0.2);
}
```

## Nav

`backdrop-filter: blur(20px); background: rgba(0,0,0,0.2); border-bottom: 1px solid rgba(255,255,255,0.1)`. Logo icon: small glass card. Links: `text-white/60 hover:text-white`.

## Icon Boxes

`background: rgba(255,255,255,0.1); backdrop-filter: blur(10px); border: 1px solid rgba(255,255,255,0.15); border-radius: 14px` - tinted with the feature's accent color at low opacity.

## Stat Numbers

Large frosted number cards. Number in white, label in `text-white/60`. Each card optionally tinted differently.

## Input Fields

```css
.glass-input {
  background: rgba(255,255,255,0.06);
  border: 1px solid rgba(255,255,255,0.15);
  border-radius: 12px; color: white;
}
.glass-input:focus { border-color: rgba(255,255,255,0.4); background: rgba(255,255,255,0.1); outline: none; }
```

## Implementation

- Google Fonts: Outfit or DM Sans
- `pointer-events-none` and `fixed inset-0` on all blob elements
- All body text `text-white` or `text-white/[opacity]`
- `selection:bg-white/20 selection:text-white`
- `antialiased` on body
- Sections: `py-24 px-6`, max-width `max-w-6xl`
- Avoid sharp edges - everything rounded-2xl or higher
