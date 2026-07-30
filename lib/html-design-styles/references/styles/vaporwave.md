# Vaporwave Style

Pastel purples and pinks over a retro grid floor, synthwave sun, glitch effects, and nostalgic 80s/early-internet energy. Dreamy, surreal, and deeply aesthetic. Use when asked for "vaporwave style".

## Typography

Audiowide or Orbitron (Google Fonts) for headlines. VT323 (Google Fonts) for body, captions, and terminal/retro text - VT323 is the default body font. Audiowide is display-only and unreadable below ~18px. Or: any bold italic serif for that early-web aesthetic. Headlines often in gradient or with neon glow.

## Colors

```
Background:    #0d0015   (very dark purple-black)
Primary pink:  #ff71ce
Primary blue:  #01cdfe
Purple:        #b967ff
Teal/cyan:     #05ffa1
Yellow:        #fffb96
Grid line:     rgba(179,103,255,0.3)
```

## Background - Retro Grid Floor + Sunset

```css
body { background: #0d0015; }

/* Retro perspective grid */
.retro-grid {
  position: fixed; bottom: 0; left: 0; right: 0; height: 50vh;
  background-image:
    linear-gradient(rgba(179,103,255,0.3) 1px, transparent 1px),
    linear-gradient(90deg, rgba(179,103,255,0.3) 1px, transparent 1px);
  background-size: 40px 40px;
  transform: perspective(300px) rotateX(60deg);
  transform-origin: bottom center;
  pointer-events: none;
}

/* Synthwave sun */
.synth-sun {
  position: fixed; bottom: 45vh; left: 50%; transform: translateX(-50%);
  width: 200px; height: 100px;
  background: linear-gradient(#ff71ce, #fffb96);
  border-radius: 100px 100px 0 0;
  /* Horizontal stripe cutouts - the sun lines */
  -webkit-mask-image: repeating-linear-gradient(
    to top, black 0px, black 8px, transparent 8px, transparent 14px
  );
  pointer-events: none;
}
```

## Gradient Text

```css
.vw-headline {
  background: linear-gradient(135deg, #ff71ce 0%, #b967ff 50%, #01cdfe 100%);
  -webkit-background-clip: text; -webkit-text-fill-color: transparent;
  background-clip: text;
}
```

## Neon Glow

```css
.neon-pink  { text-shadow: 0 0 7px #ff71ce, 0 0 20px #ff71ce, 0 0 40px #ff71ce; }
.neon-blue  { text-shadow: 0 0 7px #01cdfe, 0 0 20px #01cdfe, 0 0 40px #01cdfe; }
.neon-box   { box-shadow: 0 0 10px #b967ff, 0 0 30px #b967ff, inset 0 0 10px rgba(185,103,255,0.2); }
```

## Cards

```css
.vw-card {
  background: rgba(13,0,21,0.8);
  border: 1px solid rgba(255,113,206,0.4);
  border-radius: 4px;
  box-shadow: 0 0 20px rgba(185,103,255,0.2), inset 0 0 20px rgba(185,103,255,0.05);
}
.vw-card:hover { border-color: #ff71ce; box-shadow: 0 0 30px rgba(255,113,206,0.4); }
```

## Glitch Effect

```css
@keyframes glitch {
  0%,100% { clip-path: inset(0 0 100% 0); transform: translate(0); }
  20% { clip-path: inset(30% 0 50% 0); transform: translate(-4px, 2px); }
  40% { clip-path: inset(60% 0 20% 0); transform: translate(4px, -2px); }
  60% { clip-path: inset(10% 0 70% 0); transform: translate(-2px, 1px); }
}
.glitch { position: relative; }
.glitch::before, .glitch::after {
  content: attr(data-text); position: absolute; top: 0; left: 0;
  animation: glitch 4s infinite;
}
.glitch::before { color: #ff71ce; }                       /* pink layer */
.glitch::after  { color: #01cdfe; animation-delay: 0.1s; } /* cyan layer, offset */
```

## Buttons

```css
.vw-btn {
  border: 1px solid #ff71ce;
  background: transparent;
  color: #ff71ce;
  border-radius: 2px;
  box-shadow: 0 0 10px rgba(255,113,206,0.4), inset 0 0 10px rgba(255,113,206,0.1);
  font-family: 'Audiowide';
  text-transform: uppercase;
  letter-spacing: 0.1em;
}
.vw-btn:hover { background: rgba(255,113,206,0.1); box-shadow: 0 0 20px rgba(255,113,206,0.8); }
```

## Scanlines

Subtle horizontal line repeat at 2px interval as a fixed full-screen overlay:

```css
body::after {
  content: '';
  position: fixed; inset: 0;
  background: repeating-linear-gradient(
    0deg, rgba(0,0,0,0.15) 0px, rgba(0,0,0,0.15) 1px, transparent 1px, transparent 2px
  );
  opacity: 0.3;
  pointer-events: none;
  z-index: 9999;
}
```

## Implementation

- Google Fonts: Audiowide + VT323
- `overflow-x: hidden`
- All sections layered on top of `fixed` background elements (grid + sun)
- Text colors: white, pink, cyan - never black on dark
- `selection:bg-[#b967ff] selection:text-white`
- Custom scrollbar: purple track, pink thumb
