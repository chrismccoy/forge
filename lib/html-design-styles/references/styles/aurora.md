# Aurora Style

Flowing silk-like color gradients - aurora borealis colors blending softly. Light, dreamy, and ethereal. Use when asked for "aurora style".

## Typography

Manrope or Cabinet Grotesk (Google Fonts, weights 200-700). Headlines `font-bold tracking-tight`. Body `font-light leading-relaxed`. The gradients do the heavy lifting - type stays elegant and clean.

## Colors

No fixed palette - always multiple blending gradients. Example aurora set:

```
Green-teal:  #00f5a0
Blue-purple: #7b2ff7
Pink:        #f72585
Gold:        #f5a623
Cyan:        #00d4ff
```

Background is always a flowing gradient - never flat.

## Gradient Background

```css
body {
  background: linear-gradient(135deg, #0d1117 0%, #1a0533 30%, #0a1628 60%, #001a12 100%);
  min-height: 100vh;
}
/* Animated aurora blobs */
.aurora-blob {
  position: fixed; border-radius: 50%; filter: blur(80px); opacity: 0.6;
  animation: drift 8s ease-in-out infinite alternate;
}
.aurora-1 { width: 600px; height: 400px; background: #7b2ff7; top: -100px; left: -100px; }
.aurora-2 { width: 500px; height: 300px; background: #00f5a0; bottom: 0; right: -50px; animation-delay: 2s; }
.aurora-3 { width: 400px; height: 400px; background: #f72585; top: 40%; left: 30%; animation-delay: 4s; opacity: 0.3; }

@keyframes drift {
  from { transform: translate(0, 0) scale(1); }
  to   { transform: translate(40px, 30px) scale(1.1); }
}
```

## Glass Cards

Same as Glassmorphism but with aurora-tinted borders:

```css
.aurora-card {
  background: rgba(255,255,255,0.06);
  backdrop-filter: blur(24px);
  border: 1px solid rgba(255,255,255,0.12);
  border-radius: 20px;
  box-shadow: 0 8px 32px rgba(0,0,0,0.3);
}
```

## Gradient Text

```css
.aurora-text {
  background: linear-gradient(90deg, #00f5a0, #7b2ff7, #f72585, #00d4ff);
  background-size: 200% auto;
  -webkit-background-clip: text; -webkit-text-fill-color: transparent;
  animation: aurora-shift 4s linear infinite;
}
@keyframes aurora-shift { to { background-position: 200% center; } }
```

## Gradient Buttons

```css
.aurora-btn {
  background: linear-gradient(135deg, #7b2ff7, #f72585);
  color: white; border: none; border-radius: 100px;
  box-shadow: 0 4px 24px rgba(123,47,247,0.4);
  font-weight: 600; padding: 14px 32px;
}
.aurora-btn:hover { box-shadow: 0 8px 40px rgba(123,47,247,0.6); transform: translateY(-2px); }
.aurora-btn-outline {
  background: transparent;
  border: 1px solid rgba(255,255,255,0.2);
  color: white; border-radius: 100px;
  backdrop-filter: blur(10px);
}
```

## Divider Lines

```css
.aurora-line {
  height: 1px;
  background: linear-gradient(to right, transparent, #7b2ff7, #00f5a0, #f72585, transparent);
  opacity: 0.5;
}
```

## Implementation

- Google Fonts: Manrope (weights 200, 400, 600, 700)
- All body text white or `white/80`
- Aurora blobs: `pointer-events: none; z-index: 0` - content at `z-index: 1`+
- `antialiased`
- `selection:bg-[#7b2ff7] selection:text-white`
- Avoid hard borders - let gradients define edges
