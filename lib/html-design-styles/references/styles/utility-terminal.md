# Utility Terminal Style

Pure white, strict 1px black borders everywhere, no border-radius, monospace font, grid background. Feels like a utility dashboard or command interface. Use when asked for "utility terminal style".

## Typography

System monospace: `font-mono` (Tailwind default). Everything is monospace. No other fonts. Sizes small: `text-xs` for labels, `text-sm` for body, `text-4xl font-light` for stat numbers. Labels: uppercase with `tracking-widest`.

## Colors

```
Background:    #ffffff
Surface alt:   #f5f5f5  (neutral-100)
Surface dark:  #171717  (neutral-900 - for nav logo)
Text:          #000000
Muted:         #737373  (neutral-500)
Border:        #000000  (1px solid)
Accent:        none (black only, occasionally neutral-100 hover bg)
```

No color accents. Strictly utilitarian.

## Border System

Everything uses `border border-black` (1px). No `border-2` or `border-4` - thin lines only:

- Outer container: `border-x border-black max-w-[1600px] mx-auto shadow-2xl`
- Header: `border-b border-black`
- Sections: `border-b border-black`
- Cards: separated by `gap-px bg-black` grid (1px black gaps between cells)
- Module tags: `text-[10px] border border-black px-1`

## No Border-Radius

All elements are strictly rectangular. `border-radius: 0` everywhere. No rounding.

## Nav Header

Two-level header:

1. Utility bar: `border-b border-black bg-neutral-100 px-2 py-1 text-[10px] uppercase tracking-widest flex justify-between` - shows `sys_status: online` and `v.2.0.4 build_9912`
2. Main nav: `sticky top-0 border-b border-black bg-white/95 backdrop-blur-sm h-16`. Logo block: `w-48 border-r border-black bg-black text-white` (separate column). Right action: `w-32 border-l border-black` with `[ ACCESS ]` link.

## Hero Layout

2-column: `grid-cols-12`. Left (8 cols): tag + headline + description + 2 buttons. Right (4 cols): `border-l border-black bg-scanlines` terminal output panel.

```css
.bg-scanlines {
  background: linear-gradient(to bottom, rgba(0,0,0,0) 50%, rgba(0,0,0,0.05) 50%);
  background-size: 100% 4px;
}
```

## Background Grid

```css
.bg-grid-sm {
  background-image: linear-gradient(#e5e5e5 1px, transparent 1px),
    linear-gradient(90deg, #e5e5e5 1px, transparent 1px);
  background-size: 20px 20px;
}
```

Used on the main content area.

## Terminal Panel

Right side of hero: `p-4 border-b border-black text-xs font-bold bg-white` header + `p-6 font-mono text-xs text-neutral-500` content with `>` prefixed lines. Bottom: progress bar `h-1 w-full bg-neutral-200` with `bg-black` fill.

## Cards (feature grid)

`gap-px bg-black` parent creates 1px black grid lines. Children: `bg-white p-6 hover:bg-neutral-50 transition-colors`. Each card: bold uppercase title + `text-[10px] border border-black px-1` module tag + `text-xs text-neutral-500` description. Bullet items: `<span class="w-2 h-2 bg-black mr-2"></span>` black squares.

## Buttons

```css
.btn-utility { border: 1px solid #000; background: #fff; px-8 py-4; font-bold uppercase tracking-widest; }
.btn-utility:hover { background: #000; color: #fff; }
.btn-utility-alt { border: 1px solid #000; background: neutral-100; }
.btn-utility-alt:hover { background: neutral-200; }
```

No shadow, no transform.

## Marquee

`bg-black text-white py-3 border-b border-black`. Content: monospace uppercase tracking-widest, `///` separators.

## Module Section

`bg-neutral-100 py-16`. Header: `flex items-end justify-between border-b border-black pb-4` - title left, `text-xs font-mono` index right (e.g. `INDEX: 004-A`). Grid: `gap-px bg-black border border-black`. Each cell `bg-white hover:bg-neutral-50`.

## Footer

`bg-neutral-100 border-t border-black`. 4-column `divide-x divide-black border-b border-black`. Link lists prefixed with `>`. Bottom bar `bg-white` with `©` and status message.

## Implementation

- No Google Fonts - use Tailwind `font-mono`
- `selection:bg-black selection:text-white`
- `antialiased`
- `min-h-screen flex flex-col` on outer container
