# Dark Mono Style

Dark zinc blog/dashboard with a monospace terminal feel, cyan + pink color pops, and a subtle scanline texture. Compact, readable, and techy. Use when asked for "dark mono style".

## Typography

System monospace: `ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace`. Everything monospace. Headlines `font-black tracking-tighter`. Labels `text-[10px] font-bold uppercase tracking-widest`. Small `border-radius: 6px` ("sharp") used everywhere instead of large rounding.

## Colors

```css
surface: #09090b;   /* page background - near-black zinc */
panel:   #18181b;   /* card/component background */
subtle:  #27272a;   /* borders */
muted:   #71717a;   /* muted text */
accent:  #a1a1aa;   /* secondary text */
bright:  #fafafa;   /* primary text */
pop:     #22d3ee;   /* cyan - primary accent */
warm:    #f472b6;   /* pink - secondary accent */
```

## Scanline Texture

Applied to `body` via a class:

```css
.scanline {
  background-image: repeating-linear-gradient(
    0deg, transparent, transparent 1px,
    rgba(255,255,255,0.015) 1px, rgba(255,255,255,0.015) 2px
  );
}
```

## Nav Pills

Small `rounded-sharp` (6px) pill buttons:

- Active/current: `bg-pop text-surface` (cyan bg, dark text)
- Inactive: `border border-subtle bg-panel text-accent hover:text-pop hover:border-pop/30 transition-colors`
- All: `px-3 py-1.5 text-[11px] font-black uppercase tracking-wider inline-flex items-center gap-2`
- Include a tiny Font Awesome icon at `text-[9px]`

## Cards / Panels

`border border-subtle bg-panel rounded-sharp`. Inner content uses `text-bright` for titles, `text-accent` for meta, `text-muted` for body. Breadcrumb tags: `rounded-sharp bg-panel border border-subtle px-2 py-1 text-[10px] font-bold uppercase tracking-widest`.

## Forms / Inputs

`rounded-sharp border border-subtle bg-panel text-bright placeholder:text-muted`. Focus: `box-shadow: 0 0 0 2px #22d3ee` (no outline, custom glow). Search icon inside left padding.

## Section Headings

`border-b border-subtle pb-2 mb-4 text-bright font-black uppercase tracking-tight` - subtle bottom border under each section title.

## Sidebar Layout

2-column: `sidebar-sticky` (`position: sticky; top: 60px`) on the sidebar. Main content `lg:col-span-8` or `3`, sidebar `lg:col-span-4` or `1`.

## Status/Pulse Indicator

Inline `animate-pulse` dot in cyan next to the logo: `h-1.5 w-1.5 rounded-full bg-pop animate-pulse`.

## Selection

`::selection { background: #22d3ee; color: #09090b; }`

## Focus Ring

`a:focus-visible { outline: 2px solid #22d3ee; outline-offset: 2px; border-radius: 4px; }`

## Implementation

- Font Awesome 6 for small nav icons
- `border-radius: sharp` = 6px, used via Tailwind `rounded-sharp` custom config
- `antialiased` on body
- `max-w-7xl` container, `px-4`
- No Google Fonts - system monospace only
