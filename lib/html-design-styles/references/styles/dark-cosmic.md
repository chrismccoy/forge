# Dark Cosmic Style

Deep dark background with glowing indigo/cyan accents, radial dot grid texture, and glassmorphism cards. Feels like SaaS infrastructure. Use when asked for "dark cosmic style".

## Typography

Default system-ui (Tailwind default). Headlines `font-bold tracking-tight`. Body `text-slate-200/300`. Very clean and readable against dark.

## Colors

```
Background:  #020617  (slate-950)
Surface:     #0f172a  (slate-900)
Border:      rgba(255,255,255,0.1)
Text:        #e2e8f0  (slate-200)
Muted:       #94a3b8  (slate-400)
Brand 500:   #6366f1  (indigo)
Brand 400:   #818cf8
Cyan accent: #06b6d4
Glow shadow: 0 0 0 1px rgba(99,102,241,.25), 0 20px 60px -20px rgba(99,102,241,.45)
```

## Background Layers

Three layers stacked `fixed inset-0 pointer-events-none`:

1. Large top blurred blob: `absolute -top-24 left-1/2 h-[32rem] w-[60rem] -translate-x-1/2 rounded-full bg-brand-600/25 blur-3xl`
2. Bottom-right cyan blob: `absolute -bottom-24 right-[-10rem] h-[28rem] w-[48rem] rounded-full bg-cyan-500/10 blur-3xl`
3. Dot grid: `absolute inset-0 bg-[radial-gradient(circle_at_1px_1px,rgba(148,163,184,.18)_1px,transparent_0)] [background-size:22px_22px] opacity-40`

## Cards

```css
.glass-card {
  background: rgba(15,23,42,0.6);   /* slate-900/60 */
  border-radius: 16px;
  border: 1px solid rgba(255,255,255,0.1);
  backdrop-filter: blur(12px);
  box-shadow: 0 0 0 1px rgba(99,102,241,.25), 0 20px 60px -20px rgba(99,102,241,.45);
}
```

Feature icon containers: `rounded-xl bg-brand-600/20 ring-1 ring-brand-500/30` with glow shadow.

## Buttons

```css
.btn-primary { background: #fff; color: #0f172a; rounded-xl; font-semibold; }
.btn-primary:hover { background: #f1f5f9; }
/* White on dark bg reads as high-contrast and premium */
.btn-ghost { rounded-xl; px-3 py-2; text-slate-200; hover:text-white; }
```

## Header

`mx-auto flex max-w-7xl items-center justify-between px-6 py-5`. No sticky panel - floats on the dark bg. Logo: icon in `rounded-xl bg-brand-600/20 ring-1 ring-brand-500/30`. Right: ghost "Sign in" + white "Start free" button.

Mobile menu: `rounded-2xl bg-slate-900/60 ring-1 ring-white/10 backdrop-blur p-4` dropdown.

## Glow Chip (hero badge)

```html
<span class="grid h-10 w-10 place-items-center rounded-xl bg-brand-600/20 ring-1 ring-brand-500/30 shadow-glow">
  [icon]
</span>
```

## Feature Icons

Always use the glowing icon box pattern. Never plain colored circles.

## Implementation

- No Google Fonts needed - system font works perfectly on dark
- All text in `slate-200` or `slate-300` for body, `white` for headings
- Hover states: `hover:text-white` on muted links
- Focus rings: `focus:ring-2 focus:ring-brand-400 focus:ring-offset-2 focus:ring-offset-slate-950`
- Section max-width: `max-w-7xl`
