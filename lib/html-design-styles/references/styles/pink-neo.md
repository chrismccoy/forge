# Pink Neo Style

Hot pink dotted background with a floating white content container, Archivo Black + Space Mono fonts, and a pink/yellow/blue neon palette. Archive/directory-style layout. Use when asked for "pink neo style".

## Typography

Archivo Black (`font-head`) for all headings and display text. Space Mono (`font-mono`) for body, labels, and nav. Headlines `font-head uppercase tracking-tighter leading-none`. All caps on section titles.

## Colors

```
Page background: #FF90E8  (hot pink - the entire page)
neo-pink:        #FF90E8
neo-yellow:      #FFC900
neo-blue:        #23A6F0
neo-black:       #1a1a1a
neo-white:       #fafafa
```

## Dotted Background

```css
body {
  background-color: #FF90E8;
  background-image: radial-gradient(#000000 1px, transparent 1px);
  background-size: 20px 20px;
}
```

## Border System

```css
.neo-border { border: 3px solid #000000; }
```

Used on all cards, panels, and containers.

## Shadow System

```css
shadow-neo:       5px 5px 0px 0px #000000;
shadow-neo-sm:    3px 3px 0px 0px #000000;
shadow-neo-hover: 2px 2px 0px 0px #000000;
```

## Main Container / Header Card

`bg-neo-white neo-border shadow-neo p-6 md:p-10 flex flex-col md:flex-row justify-between items-center gap-6 relative overflow-hidden`. Ghost letters watermark: `absolute -right-10 -top-10 text-[200px] text-neo-pink opacity-20 font-head select-none pointer-events-none`.

## Cards

`bg-white neo-border shadow-neo`. Card header bar: `border-b-3 border-black p-2 bg-neo-black text-white font-bold text-xs text-center uppercase`. Hover: `group-hover:translate-x-1 transition-transform`. Sticker badge: `absolute -top-3 -right-3 bg-neo-pink border-2 border-black px-2 py-1 text-xs font-bold transform rotate-12 z-20`.

## Link/Tag Buttons

```css
/* Each gets an accent color bg */
.tag-yellow { background: #FFC900; border: 2px solid black; }
.tag-blue   { background: #23A6F0; color: white; border: 2px solid black; }
.tag-pink   { background: white; border: 2px solid black; }
.tag-black  { background: #1a1a1a; color: white; border: 2px solid black; }
/* All: px-3 py-2 font-bold text-xs uppercase */
/* hover: bg-neo-pink text-black -translate-y-1 shadow-neo-sm transition-all */
```

## Content List Rows

`divide-y-2 divide-black`. Each row: date badge `bg-neo-black text-white px-3 py-1 border-2 border-transparent group-hover:border-black group-hover:bg-neo-pink group-hover:text-black` + title (hover: `text-neo-blue translate-x-1`) + source domain `text-[10px] text-gray-500 font-bold uppercase tracking-widest` + arrow `→` fades in on hover.

## Mac Traffic Lights

`h-3 w-3 rounded-full border border-white` - pink/yellow/blue dots in card headers for decoration.

## Layout

Content wrapped in `max-w-7xl mx-auto` with `p-2 md:p-8` body padding. Full-width sections as separate cards. Sidebar+main: `lg:col-span-1` sidebar sticky, `lg:col-span-3` main.

## Partner/Tag Strip

`bg-white neo-border shadow-neo p-4 md:p-6`. Section title: `font-head text-xl uppercase border-b-4 border-black inline-block`. Tags in `flex flex-wrap gap-3`.

## Scrollbar

```css
::-webkit-scrollbar { width: 12px; }
::-webkit-scrollbar-track { background: #FF90E8; border-left: 3px solid black; }
::-webkit-scrollbar-thumb { background: #000; border: 2px solid #FF90E8; }
```

## Implementation

- Google Fonts: Archivo Black + Space Mono
- `selection:bg-neo-yellow selection:text-black`
- Body: `p-2 md:p-8 min-h-screen flex flex-col`
- Font Awesome optional for icons
