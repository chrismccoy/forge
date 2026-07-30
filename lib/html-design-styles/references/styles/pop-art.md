# Pop Art Style

Vivid cyan/pink/yellow on a loud background, housed in a floating bordered container. Energetic and physical. Use when asked for "pop art style".

## Typography

IBM Plex Mono (headlines/labels) + Inter (body). Bold everywhere. Headlines `font-black uppercase tracking-tighter italic`.

## Colors

```
Page bg:      #5CE1E6   (cyan - the whole page is this color)
Container bg: #ffffff
pop-cyan:     #5CE1E6
pop-yellow:   #FFDE59
pop-pink:     #FF90E8
pop-black:    #000000
```

## Container Layout

The entire design lives inside a max-width floating box with thick borders:

```css
.container-main {
  max-width: 1280px; margin: 32px auto;
  background: white;
  border: 4px solid #000;            /* or border-x-4 */
  box-shadow: 10px 10px 0 0 #000;
  min-height: 100vh;
}
```

## Cards & Buttons

**Cards** use the "backing shadow" pattern: `relative group` wrapper with `absolute inset-0 bg-black translate-x-2 translate-y-2 group-hover:translate-x-3 group-hover:translate-y-3` behind `relative bg-white border-4 border-black`.

**Buttons**:

```css
.btn-primary { background: #FF90E8; border: 4px solid #000; font-weight: 900; text-transform: uppercase; }
.btn-secondary { background: #fff; border: 4px solid #000; }
/* Both use backing shadow pattern */
/* hover: -translate-x-1 -translate-y-1 */
/* active: translate-x-1 translate-y-1 */
```

## Decorative Details

- Angled "sticker" labels: `border-4 border-black px-4 py-2 font-black uppercase shadow-hard-xl transform rotate-6` (absolute positioned near hero visual)
- Inline tags: `bg-gray-100 border-2 border-black px-2 py-1 text-xs font-bold uppercase` with a small colored square indicator
- Section headers: `inline-block` badge with accent bg + border + hard shadow

## Header

`border-b-4 border-black bg-white sticky top-0`. Logo uses backing shadow pattern. Nav links: `hover:bg-[accent] px-2 py-1 border-2 border-transparent hover:border-black`. CTA: backing shadow button.

## Marquee

`bg-black text-white border-b-4 border-black`, monospace font, items with `✦` separators or brackets `[ITEM]`.

## Feature Cards

3-column grid of `border-2 border-black bg-white` cards. Hover: `-translate-x-1 -translate-y-1 shadow-hard`. Icon emoji top-left, yellow highlight on h3 hover.
