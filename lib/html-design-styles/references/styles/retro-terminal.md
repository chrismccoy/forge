# Retro Terminal Style

Green phosphor text on a near-black screen. CRT scanlines, blinking cursors, glowing text, monospace typefaces. Feels like a 1980s computer terminal. Use when asked for "retro terminal style".

## Typography

System monospace or JetBrains Mono / Share Tech Mono (Google Fonts). Everything monospace. `uppercase` for labels and nav. Text at reduced opacity for depth: primary `opacity-90`, secondary `opacity-60`, dim `opacity-40`.

## Colors

```
Screen bg:       #0a0e0a   (near-black with green tint)
Phosphor green:  #00ff41   (bright CRT green)
Dim green:       #00b32d   (medium green)
Dark green:      #003b00   (very dark green, borders)
Amber variant:   #ffb000   (alternative amber terminal)
```

Pick one: green or amber. Don't mix.

## Body Background + Scanlines

```css
body {
  background-color: #0a0e0a;
  color: #00ff41;
  font-family: monospace;
}
/* CRT scanline overlay */
body::after {
  content: '';
  position: fixed; inset: 0;
  background: repeating-linear-gradient(
    0deg, rgba(0,0,0,0.15) 0px, rgba(0,0,0,0.15) 1px, transparent 1px, transparent 2px
  );
  pointer-events: none; z-index: 9999;
}
```

## Phosphor Glow

```css
.glow-text { text-shadow: 0 0 7px #00ff41, 0 0 14px #00ff41, 0 0 21px #00ff41; }
.glow-sm   { text-shadow: 0 0 4px #00ff41; }
.glow-box  { box-shadow: 0 0 8px #00ff41, 0 0 2px #00ff41 inset; }
```

Apply `.glow-text` to headlines. `.glow-sm` to body text. `.glow-box` to bordered elements.

## Screen Vignette

```css
body::before {
  content: ''; position: fixed; inset: 0; pointer-events: none; z-index: 9998;
  background: radial-gradient(ellipse at center, transparent 60%, rgba(0,0,0,0.7) 100%);
}
```

## Cards / Panels

```css
.terminal-panel {
  border: 1px solid #00ff41;
  box-shadow: 0 0 8px rgba(0,255,65,0.3), inset 0 0 8px rgba(0,255,65,0.05);
  background: rgba(0,255,65,0.03);
  border-radius: 0;
}
```

Panel headers: `background: #00ff41; color: #0a0e0a; font-weight: 700; padding: 4px 12px; text-transform: uppercase; letter-spacing: 0.1em`.

## Prompt / Code Lines

```
> SYSTEM ONLINE...
> LOADING MODULES [████████░░] 80%
> PRESS ANY KEY TO CONTINUE_
```

Progress bars: `[████████░░]` or CSS: `background: #00ff41` fill on `background: #003b00` track, `border: 1px solid #00ff41`.

## Blinking Cursor

```css
.cursor::after { content: '█'; animation: blink 1s step-end infinite; }
@keyframes blink { 0%,100%{opacity:1} 50%{opacity:0} }
```

## Buttons

```css
.term-btn {
  border: 1px solid #00ff41; background: transparent; color: #00ff41;
  font-family: monospace; text-transform: uppercase; letter-spacing: 0.1em;
  box-shadow: 0 0 6px rgba(0,255,65,0.4);
}
.term-btn:hover { background: #00ff41; color: #0a0e0a; box-shadow: 0 0 16px rgba(0,255,65,0.8); }
```

## Nav

No background - floats on the dark screen. Links separated by ` // ` or `|`. Active link: `.glow-text`. Logo: `[PRODUCT_NAME]` in brackets.

## Boot Sequence Hero

Simulate a terminal boot: staggered lines of text appearing with delays, a progress bar, then the main headline "unlocks". Use `@keyframes fadeIn` with increasing `animation-delay` values.

## Implementation

- Google Fonts: Share Tech Mono or JetBrains Mono (optional - system mono works)
- `overflow-x: hidden`
- Custom scrollbar: `scrollbar-color: #00ff41 #0a0e0a; scrollbar-width: thin`
- `selection::bg: #00ff41; color: #0a0e0a`
- No border-radius anywhere
- All section padding via `padding: 80px 0`
