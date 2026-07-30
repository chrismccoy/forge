# Acid Brutalist Style

Pure black background, acid yellow + brutal red accents, Anton/Bebas Neue display fonts, noise grain overlay. Loud, chaotic, punk energy. Use when asked for "acid brutalist style".

## Typography

Anton (huge display numbers/headlines) + Bebas Neue (section titles) + Space Mono (body/labels/code). All caps for display. `letter-spacing: 0.05em` on Space Mono.

## Colors

```
Background:   #0A0A0A  (near-black)
Text:         #F5F5F0  (off-white chalk)
Acid yellow:  #FFFF00
Brutal red:   #FF2D00
```

## Noise Grain Overlay

Fixed `::before` pseudo-element, full screen, `pointer-events: none; z-index: 9999`:

```css
body::before {
  content: '';
  position: fixed; inset: 0;
  background-image: url("data:image/svg+xml,%3Csvg viewBox='0 0 256 256' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='noise'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.9' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23noise)' opacity='0.03'/%3E%3C/svg%3E");
  pointer-events: none; z-index: 9999; opacity: 0.4;
}
```

## Shadow System

Colored offset shadows (no blur):

```css
.brut-box     { box-shadow: 6px 6px 0px #FFFF00; }
.brut-box-red { box-shadow: 6px 6px 0px #FF2D00; }
.brut-box-white { box-shadow: 6px 6px 0px #F5F5F0; }
.brut-box-lg  { box-shadow: 10px 10px 0px #FFFF00; }
```

## Cards

`border: 3px solid #F5F5F0; background: #0A0A0A`. Hover: `border-color: #FFFF00; transform: translate(-4px, -4px); box-shadow: 4px 4px 0px #FFFF00`.

## Buttons

```css
.brut-btn {
  background: #FFFF00; color: #0A0A0A;
  font-family: 'Space Mono'; font-weight: 700; text-transform: uppercase; letter-spacing: 0.05em;
  border: 3px solid #0A0A0A;
  box-shadow: 5px 5px 0px #0A0A0A;
}
.brut-btn:hover { transform: translate(3px, 3px); box-shadow: 2px 2px 0px #0A0A0A; }

.brut-btn-outline {
  background: transparent; color: #FFFF00;
  border: 3px solid #FFFF00; box-shadow: 5px 5px 0px #FFFF00;
}
.brut-btn-outline:hover { transform: translate(3px, 3px); box-shadow: 2px 2px 0px #FFFF00; }
```

## Decorative Patterns

```css
/* Diagonal stripe background */
.stripe-bg {
  background-image: repeating-linear-gradient(
    -45deg, #FFFF00 0px, #FFFF00 4px, transparent 4px, transparent 24px
  );
}
```

Use sparingly as section backgrounds or dividers.

## Code Block

```css
.code-block {
  background: #111; border: 2px solid #333; border-left: 4px solid #FFFF00;
  font-family: 'Space Mono'; color: #FFFF00; padding: 20px 24px; line-height: 1.8;
}
.code-block .comment { color: #555; }
.code-block .cmd { color: #F5F5F0; }
```

## Section Labels

`font-family: 'Space Mono'; font-size: 0.7rem; letter-spacing: 0.25em; text-transform: uppercase; color: #FFFF00; border-left: 3px solid #FFFF00; padding-left: 10px;`

## Stack Pills

`border: 2px solid #FFFF00; color: #FFFF00; font-family: 'Space Mono'; text-transform: uppercase; letter-spacing: 0.08em`. Hover: `background: #FFFF00; color: #0A0A0A`.

## Watermark Numbers

`font-family: 'Anton'; font-size: clamp(5rem, 15vw, 12rem); color: #FFFF00; opacity: 0.12; position: absolute; top: -0.1em; left: -0.05em; pointer-events: none; user-select: none;` - behind section content.

## Scroll Reveal Animation

```css
.reveal { opacity: 0; transform: translateY(30px); transition: opacity 0.5s ease, transform 0.5s ease; }
.reveal.visible { opacity: 1; transform: none; }
```

Triggered via IntersectionObserver JS.

## Blink Cursor

`@keyframes blink { 0%,100%{opacity:1} 50%{opacity:0} }` `.blink { animation: blink 1s step-end infinite; }` - use on terminal prompts.

## Marquee

`background: #111; border-top: 2px solid #FFFF00; border-bottom: 2px solid #FFFF00`. Inner track: `animation: marquee 28s linear infinite`.

## Implementation

- Google Fonts: Anton + Bebas Neue + Space Mono
- `overflow-x: hidden` on body
- Custom scrollbar: `6px, track #0a0a0a, thumb #FFFF00`
- Red tags for warnings: `background: #FF2D00; color: #F5F5F0; font-family: Space Mono; font-size: 0.7rem; text-transform: uppercase; padding: 3px 8px`
