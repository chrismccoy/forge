# Enterprise Editorial Style

White base with alternating dark sections, indigo accent, large rounded "app" cards, and a dense editorial layout with subtle grid texture. Feels like premium SaaS documentation. Use when asked for "enterprise editorial style".

## Typography

Inter (all weights 400-900). Headlines `font-black tracking-tighter leading-[0.85]`. Section labels `text-[10px] font-black uppercase tracking-[0.3em]`. Body `text-gray-500 leading-relaxed`. Very tight tracking on all headings.

## Colors

```
Background (light):  #ffffff
Background (dark):   #111827  (gray-900)
Background (darker): #030712  (gray-950)
Text:                #111827
Muted:               #6b7280  (gray-500)
Brand:               #4f46e5  (indigo-600)
Brand hover:         #4338ca  (indigo-700)
Brand light:         #e0e7ff  (indigo-100)
Shadow:              shadow-indigo-200 (colored shadows on light bg)
```

## Background Grid Texture

```css
.bg-grid {
  background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='40' height='40' viewBox='0 0 40 40'%3E%3Cpath d='M40 0H0V40H40V0ZM39 1H1V39H39V1Z' fill='%236366f1' fill-opacity='0.05'/%3E%3C/svg%3E");
}
```

Use on the light hero section only.

## Section Alternation

Light → Dark → Light → Dark. Each section `py-32`. Dark sections: `bg-gray-900 text-white`.

## Cards

Light sections: `p-10 rounded-[3rem] bg-gray-50 border border-gray-100 hover:bg-white hover:shadow-2xl transition-all duration-500`. Icon: `w-14 h-14 bg-white rounded-2xl shadow-sm`, hover `scale-110 transition-transform`.

Dark sections (app mockup): `bg-gray-800 rounded-[3rem] p-4 shadow-2xl ring-1 ring-white/10` outer frame, `bg-gray-950 rounded-[2.5rem] p-8 md:p-12` inner screen. Mac traffic lights: small circles `bg-red-500/20 border border-red-500/40`.

## Feature Rows (dark sections)

`flex gap-6` with `shrink-0 w-14 h-14 bg-indigo-500/10 rounded-2xl flex items-center justify-center text-indigo-400 ring-1 ring-indigo-500/20 group-hover:bg-indigo-500 group-hover:text-white transition-all`.

## Buttons

```css
.btn-primary { background: #111827; color: #fff; rounded-2xl; px-12 py-6; font-black uppercase tracking-widest; shadow-2xl; }
.btn-primary:hover { background: #000; }
.btn-secondary { background: #fff; border: 2px solid #f3f4f6; rounded-2xl; px-12 py-6; font-black text-transform: uppercase; }
.btn-secondary:hover { border-color: #4f46e5; }
/* Active: scale-95 */
```

Size: very large (`text-lg`, `py-6`) - editorial CTAs are prominent.

## Hero Badge

```html
<div class="inline-flex items-center gap-2 px-4 py-1.5 rounded-full bg-indigo-50 border border-indigo-100 mb-10 shadow-sm">
  <span class="relative flex h-2 w-2">
    <span class="animate-ping absolute inline-flex h-full w-full rounded-full bg-indigo-400 opacity-75"></span>
    <span class="relative inline-flex rounded-full h-2 w-2 bg-indigo-600"></span>
  </span>
  <span class="text-[10px] font-black uppercase tracking-widest text-indigo-600">Live status message</span>
</div>
```

## Social Proof Strip

Greyscale logos: `opacity-30 grayscale contrast-125`. Text labels in `text-2xl font-black italic`.

## Navigation

`sticky top-0 bg-white/90 backdrop-blur-md border-b border-gray-100`. Labels in `text-[10px] font-black uppercase tracking-[0.2em] text-gray-400`. CTA: `bg-indigo-600 text-white rounded-xl shadow-xl shadow-indigo-200`.

## Implementation

- Google Fonts: Inter only
- `selection:bg-indigo-100 selection:text-indigo-700`
- `antialiased`
- Alpine.js optional for interactive mockup elements
- Headings lead with `[0.85]` tight leading, increase to normal for body
