# Blueprint Style

Deep engineering-blueprint aesthetic - midnight blue background, white grid lines, Courier Prime typeface, crosshair cursor, technical annotation details. Use when asked for "blueprint style".

## Typography

Courier Prime (Google Fonts, weights 400 + 700 + italic). Everything monospace. `font-bold uppercase tracking-tight` for headlines. `tracking-widest uppercase text-sm` for nav. Annotation micro-text at `text-[10px] uppercase`.

## Colors

```css
--bp-blue:  #003366;   /* page background */
--bp-paper: #002b55;   /* slightly darker panels */
--bp-white: #F0F8FF;   /* all text and borders */
--grid-line: rgba(255,255,255,0.15);
```

## Body Background (Grid)

```css
body {
  background-color: #003366;
  cursor: crosshair;
  background-image:
    linear-gradient(var(--grid-line) 1px, transparent 1px),
    linear-gradient(90deg, var(--grid-line) 1px, transparent 1px),
    linear-gradient(rgba(255,255,255,0.05) 2px, transparent 2px),
    linear-gradient(90deg, rgba(255,255,255,0.05) 2px, transparent 2px);
  background-size: 20px 20px, 20px 20px, 100px 100px, 100px 100px;
  background-position: -1px -1px;
}
```

## Container

`max-w-[1600px] mx-auto border-l-8 border-r-8 border-white/10` - flanked by vertical ruler lines:

```css
.ruler-line { position: fixed; top: 0; bottom: 0; width: 1px; background: rgba(255,255,255,0.2); z-index: -1; }
```

Place `.ruler-line.left-4` and `.ruler-line.right-4`.

## Navigation

`sticky top-0 border-b-2 border-white backdrop-blur-sm bg-[rgba(0,51,102,0.9)]`. Logo: `border-2 border-white px-3 py-1 hover:bg-white hover:text-[#003366]` with "Fig. 1.0" annotation + product name. Nav links: underline animation (`w-0 h-px bg-white group-hover:w-full transition-all duration-300`). CTA: `border border-white px-6 py-2 hover:bg-white hover:text-[#003366]` with bracket text `[ Get_Product ]`.

## Cards

`border border-white/60 p-6 relative hover:bg-white/5 transition-colors`. Corner decorators:

- Top-right: `absolute top-2 right-2 text-[10px] text-white/50` - drawing number (DWG-01)
- Bottom-right: `absolute -bottom-1 -right-1 w-2 h-2 bg-white` - corner dot accent

## Section Headers

`text-2xl font-bold uppercase tracking-widest border border-white px-4 py-1` label + `flex-grow border-t border-dashed border-white/50` dashed rule line + `text-xs uppercase` sheet number (Sheet 02). Pattern: `flex items-center gap-4 mb-10`.

## Hero

`border-b-2 border-white`. Corner bracket decorators: `absolute top-10 left-10 w-20 h-20 border-l border-t border-white/50` (top-left corner) and matching bottom-right. Center-aligned content. Badge: `inline-block border border-white px-4 py-1 text-xs uppercase tracking-widest`. Headline: bold, uppercase, `border-b-4 border-double border-white` on key phrase.

## Quote/Description Block

`border-l-2 border-white pl-6 relative`. End-cap marks: `absolute -left-[9px] top-0 w-4 h-px bg-white` (horizontal tick top and bottom).

## Filter Bar

`flex flex-wrap gap-px bg-white/20 p-px border border-white/30`. Each filter link: `flex-grow text-center bg-[#003366] text-white/80 hover:bg-[#0047AB] py-2 px-4 uppercase text-xs tracking-wider`.

## Selection

`::selection { background: white; color: #003366; }`

## Implementation

- Google Fonts: Courier Prime only
- `cursor: crosshair` on body
- `border-l-8 border-r-8 border-white/10` on outer container for binding-edge feel
- No color accents - pure white on blue only
- Mobile menu uses `border border-dashed border-white` buttons
