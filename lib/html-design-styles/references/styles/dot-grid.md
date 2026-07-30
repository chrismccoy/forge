# Dot Grid Style

Gray dotted-pattern background, Archivo Black display font, Space Mono body, hot pink accent, and large hard black shadows. Content-dense portal layout. Use when asked for "dot grid style".

## Typography

Archivo Black (display/headlines, `font-display`) + Space Mono (body/labels, `font-mono`). Headlines `font-display text-4xl md:text-6xl leading-none tracking-tight`. Labels: `font-mono font-bold uppercase text-xs tracking-widest`.

## Colors

```
Background:    #e5e7eb  (gray-200, dotted)
Text:          #000000
Accent:        #F5276C  (hot pink)
White surface: #ffffff
Black:         #000000
```

## Dotted Background

```css
body {
  background-color: #e5e7eb;
  background-image: radial-gradient(black 1px, transparent 0);
  background-size: 25px 25px;
}
```

## Shadow System

```css
shadow-hard:    10px 10px 0px 0px #000000;
shadow-hard-sm:  5px 5px 0px 0px #000000;
```

## Cards / Panels

`border-4 border-black bg-white shadow-hard`. Header bars within cards: `bg-black text-white font-bold uppercase text-xs` bar across the top. Logo/header card: `border-4 border-black bg-white shadow-hard p-6 md:p-10` with `overflow-hidden relative`. Ghost watermark text: `absolute -right-10 -top-10 text-[150px] opacity-20 font-display select-none pointer-events-none`.

## Buttons (Nav)

```css
.btn-primary { border: 2px solid black; background: black; color: white; font-bold; }
.btn-primary:hover { background: #F5276C; color: black; }
.btn-secondary { border: 2px solid black; background: white; }
.btn-secondary:hover { background: #F5276C; }
```

No border-radius. All buttons rectangular with `px-3 py-2 text-sm font-bold`.

## Link Items

```css
a.link-item {
  text-decoration: underline;
  text-underline-offset: 4px;
  text-decoration-thickness: 2px;
  text-decoration-color: #d1d5db;
}
a.link-item:hover { background-color: #F5276C; color: black; text-decoration: none; }
```

## Content Grid

12-column grid: main panel `lg:col-span-8`, sidebar `lg:col-span-4`. Main: `border-4 border-black bg-white shadow-hard`. Content rows: `divide-y-2 divide-black`. Each row: date badge + title + source domain.

## Status Badge

`inline-flex items-center gap-2 bg-black px-2 py-1 text-xs text-white` - "STATUS THING / ONLINE" inline chip.

## Section Labels

`font-display text-4xl leading-none tracking-tight` headline + `h-px flex-grow` dashed rule line layout.

## Implementation

- Google Fonts: Archivo Black + Space Mono
- `selection:bg-[#F5276C] selection:text-black` or yellow
- No border-radius - all rectangular
- `focus-visible:ring-4 focus-visible:ring-[accent]` for accessibility
- Font Awesome for any icons needed
