# Pure Brutalist Style

Strict black-and-white brutalism - no color, no rounding, no softness. Raw, confrontational, structural. Use when asked for "pure brutalist style".

## Typography

System monospace stack: `ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, "Courier New", monospace`. All text. Headlines uppercase, tracking-widest. Labels in `text-xs font-bold uppercase tracking-widest`.

## Colors

```
Background:  #ffffff
Text:        #000000
Border:      #000000
Shadow:      #000000
Muted text:  rgba(0,0,0,0.72)
```

No color accents. Pure black and white only.

## Shadow System

Three sizes, all hard black offset shadows - no blur:

```css
--shadow-lg: 8px 8px 0 0 #000;
--shadow-sm: 5px 5px 0 0 #000;
--shadow-xs: 3px 3px 0 0 #000;
```

Cards: `border: 2px solid #000` + `--shadow-lg`
Buttons: `border: 2px solid #000` + `--shadow-xs`, hover `translate(0.5px, 0.5px)` + shadow shrinks

## Cards

```css
.card { border: 2px solid #000; box-shadow: 8px 8px 0 0 #000; background: #fff; }
```

No border-radius (or minimal: 0px). Section panels use `border-4 border-black`. Headers use `border-b-4 border-black`.

## Buttons

```css
.btn { border: 2px solid #000; background: #fff; font-weight: 900; text-transform: uppercase; box-shadow: 3px 3px 0 0 #000; }
.btn-primary { background: #000; color: #fff; }
/* hover: translate(0.5px, 0.5px), shadow none */
/* active: translate(2px, 2px), shadow none */
```

## Layout & Details

- Sticky header: `border-b-4 border-black bg-white`
- Small utility bar above nav: `border-b-4 border-black bg-white text-xs uppercase tracking-widest` showing version/status
- Grids use `gap-px bg-black` to create 1px black grid lines between cells
- Section dividers: `border-b-4 border-black`
- Hero: 2-column grid (8-col left content, 4-col right terminal/visual), min-h-600px
- Feature grids: items divided by `border-r border-black`, hover `bg-neutral-50`
- Stats: `text-4xl font-light` numbers + `text-sm font-bold uppercase tracking-widest` labels
- Toasts/modals: `border-4 border-black shadow-brutal bg-white`, icon areas `bg-black text-white`
- Background: plain `#ffffff` - no textures, no gradients

## Footer

`bg-neutral-100`, `border-t border-black`. 4-column grid divided by `divide-x divide-black border border-black`. Links prefixed with `>`. Bottom bar `bg-white border-t border-black`, 10px copyright text.

## Implementation

- Tailwind CDN only - no custom fonts needed (use system monospace)
- No `border-radius` on structural elements
- Everything uppercase for labels and nav
- `selection:bg-black selection:text-white`
- `antialiased` on body
