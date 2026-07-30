# Neobrutalist Style

Hard-edged brutalism with vivid neon color accents. CSS variable-driven with theming support. Use when asked for "neobrutalist style".

## Typography

Space Grotesk (display/body) + Space Mono (code/mono elements). Or substitute any bold sans + monospace pairing.

## Colors

```css
--neo-bg:     #f3f4f6;   /* light gray page background */
--neo-black:  #0a0a0a;   /* borders, shadows, text */
/* Accent palette - all used simultaneously: */
--neo-purple: #a855f7;
--neo-green:  #a3e635;
--neo-pink:   #fb7185;
--neo-yellow: #facc15;
--neo-blue:   #60a5fa;
```

Assign different accents to different sections/features. Use all of them.

## Shadow System

Pure black offset shadows - no blur:

```css
--shadow-neo:    5px 5px 0px 0px rgba(0,0,0,1);
--shadow-neo-lg: 8px 8px 0px 0px rgba(0,0,0,1);
--shadow-neo-sm: 3px 3px 0px 0px rgba(0,0,0,1);
```

## Cards

```css
.neo-card {
  border: 2px solid #0a0a0a;
  box-shadow: 5px 5px 0px 0px #0a0a0a;
  background: #fff;
}
/* Hover: decorative backing div (absolute, bg-black, translate-x-2 translate-y-2) grows */
/* The card itself hovers above via -translate-x-1 -translate-y-1 */
```

Use the "backing shape" pattern: sibling `div.absolute.inset-0.bg-black.translate-x-2.translate-y-2`, hovered to `translate-x-4 translate-y-4`.

## Buttons

```css
.neo-btn {
  border: 2px solid #0a0a0a;
  box-shadow: 5px 5px 0px 0px #0a0a0a;
  font-weight: 700; text-transform: uppercase;
}
/* hover: translate-x-[2px] translate-y-[2px] + shadow shrinks to 3px */
/* active: translate-x-[5px] translate-y-[5px] + shadow: none */
```

Primary buttons use a neon accent bg (e.g. `--neo-green`). Secondary use `--neo-pink` or white.

## Background

Dot grid: `bg-[radial-gradient(#0000001a_1px,transparent_1px)] [background-size:16px_16px]` or line grid: `bg-[linear-gradient(to_right,rgba(0,0,0,.10)_1px,transparent_1px),linear-gradient(to_bottom,rgba(0,0,0,.10)_1px,transparent_1px)] [background-size:24px_24px]`. Decorative oversized `nb-card` shapes rotated in corners as background accents.

## Marquee

Yellow or accent bg strip, `border-b-4 border-black`, monospace font, text like `NO LOGS • NO TRACKING • SELF-DESTRUCT •`

## Header

`border-b-4 border-black bg-white`. Logo: product name in bold uppercase. Nav links: bold uppercase, `hover:underline decoration-4 decoration-[accent-color] underline-offset-4`. CTA: accent-bg button with neo shadow.

## Version/Tag Badge

Small angled badge: `inline-block bg-black text-white px-4 py-1 font-mono text-sm font-bold -rotate-1` near headline.

## Implementation

- `selection:bg-neo-black selection:text-neo-green`
- All buttons must have the `hover:translate + shadow-shrink` mechanic
- Big step numbers: `text-6xl font-bold opacity-50 absolute font-mono` watermark in card corner
- Headings: all-caps, massive, tight tracking (`tracking-tight leading-[0.9]`)
