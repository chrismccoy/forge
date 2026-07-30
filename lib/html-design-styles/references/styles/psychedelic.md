# Psychedelic Style

Melting, swirling, mind-bending design. Organic shapes that warp and pulse, rainbow color cycling, distorted typography, and a sense of visual reality dissolving. Use when asked for "psychedelic style".

## Typography

Boogaloo or Lobster (Google Fonts) for headlines - fluid and rounded, almost liquid. Body text `font-sans font-medium`. Headlines can be curved using SVG `textPath`. Random slight rotations on elements.

## Colors

The full rainbow, cycling. Never static:

```
Red:     #ff0040
Orange:  #ff6600
Yellow:  #ffcc00
Green:   #00dd44
Cyan:    #00ddff
Blue:    #4400ff
Violet:  #cc00ff
Pink:    #ff0088
```

Gradients always cycle through 3+ colors.

## Animated Gradient Background

```css
body {
  background: linear-gradient(0deg, #ff0040, #ff6600, #ffcc00, #00dd44, #00ddff, #4400ff, #cc00ff, #ff0040);
  background-size: 100% 800%;
  animation: psyche 8s linear infinite;
}
@keyframes psyche {
  0%   { background-position: 0% 0%; }
  100% { background-position: 0% 100%; }
}
```

## Morphing Blob Shapes

```css
@keyframes morph {
  0%,100% { border-radius: 60% 40% 30% 70% / 60% 30% 70% 40%; }
  25%     { border-radius: 30% 60% 70% 40% / 50% 60% 30% 60%; }
  50%     { border-radius: 50% 60% 30% 60% / 30% 40% 70% 60%; }
  75%     { border-radius: 60% 40% 60% 30% / 60% 70% 30% 40%; }
}
.morphing-blob { animation: morph 8s ease-in-out infinite; }
```

## Wavy/Distorted Text

```css
@keyframes wave-text {
  0% { transform: skewX(0deg) skewY(0deg); }
  25% { transform: skewX(3deg) skewY(-1deg); }
  50% { transform: skewX(-2deg) skewY(2deg); }
  75% { transform: skewX(1deg) skewY(-2deg); }
  100% { transform: skewX(0deg) skewY(0deg); }
}
.wavy-text { animation: wave-text 4s ease-in-out infinite; display: inline-block; }
```

## Cards

```css
.psyche-card {
  background: rgba(255,255,255,0.15);
  backdrop-filter: blur(10px);
  border: 2px solid rgba(255,255,255,0.3);
  border-radius: 60% 40% 50% 30% / 40% 50% 60% 50%;  /* blob */
  animation: morph 10s ease-in-out infinite;
  padding: 32px;
}
```

## Buttons

```css
.psyche-btn {
  background: linear-gradient(135deg, #ff0088, #4400ff, #00ddff);
  background-size: 200% auto;
  animation: aurora-shift 3s linear infinite;
  color: white; border: none; border-radius: 100px;
  font-weight: 700; padding: 14px 32px;
}
```

## Rainbow Text

```css
.rainbow {
  background: linear-gradient(90deg, #ff0040, #ff6600, #ffcc00, #00dd44, #00ddff, #4400ff, #cc00ff);
  background-size: 200% auto;
  -webkit-background-clip: text; -webkit-text-fill-color: transparent;
  animation: aurora-shift 3s linear infinite;
}
```

## Implementation

- Google Fonts: Boogaloo + Open Sans
- `overflow: hidden` on body - blobs bleed edges
- All animations run indefinitely - the page breathes
- White text on animated background
- `selection:bg-white/30 selection:text-white`
