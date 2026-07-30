# Dark SaaS Style

Polished dark SaaS landing page. Slate-950 base, sky blue accent, staggered reveal animations, clean minimal layout. Use when asked for "dark saas style".

## Typography

System-ui / Tailwind default. Headlines `font-black tracking-tighter leading-none`. Subtext `text-slate-400 leading-relaxed`. Accent label `text-sky-400 font-semibold text-sm uppercase tracking-widest`.

## Colors

```
Background:  #020617  (slate-950)
Nav bg:      slate-950/80  (translucent)
Surface:     #0f172a  (slate-900)
Border:      #1e293b  (slate-800)
Text:        #f1f5f9  (slate-100)
Muted:       #94a3b8  (slate-400)
Brand:       #0ea5e9  (sky-500)
Brand hover: #38bdf8  (sky-400)
Green check: #4ade80  (green-400)
```

## Stagger Animations

```css
@keyframes fadeUp { "0%": { opacity: 0, transform: "translateY(24px)" }, "100%": { opacity: 1, transform: "translateY(0)" } }
.animate-fade-up { animation: fadeUp 0.6s ease-out forwards; }
.stagger-1 { animation-delay: 0.1s; opacity: 0; }
.stagger-2 { animation-delay: 0.2s; opacity: 0; }
/* ... up to stagger-6 */
```

Apply to hero headline, subtext, CTAs, trust chips in sequence.

## Background Glows

```html
<div class="absolute top-0 left-1/2 -translate-x-1/2 w-[800px] h-[500px] bg-sky-500/10 rounded-full blur-3xl"></div>
<div class="absolute top-20 left-1/2 -translate-x-1/2 w-[400px] h-[300px] bg-blue-600/10 rounded-full blur-2xl"></div>
```

## Cards

`bg-slate-900 border border-slate-800 rounded-2xl p-6`. Hover: `translateY(-4px)` + `box-shadow: 0 20px 40px -12px rgba(14,165,233,0.15)`. Feature icon: `w-10 h-10 rounded-lg bg-gradient-to-br from-sky-400 to-blue-600 flex items-center justify-center`.

## Trust Chips (below hero CTA)

`flex items-center gap-2 bg-slate-900 border border-slate-800 px-4 py-2 rounded-full text-sm`. Green check + `text-slate-300` description. Displayed in flex-wrap row.

## Buttons

```css
.btn-primary { background: #0ea5e9; color: #fff; rounded-xl; font-bold; shadow-lg shadow-sky-500/20; }
.btn-primary:hover { background: #38bdf8; }
.btn-secondary { border: 1px solid #334155; color: #cbd5e1; rounded-xl; }
.btn-secondary:hover { border-color: #475569; }
```

## Nav

`fixed bg-slate-950/80 backdrop-blur-md border-b border-slate-800`. Logo left, text links center (`text-sm text-slate-400 hover:text-white`), sky CTA right.

## Inline Code

`bg-slate-800 text-sky-400 px-1.5 py-0.5 rounded text-base font-mono` - for config filenames, commands.

## Accent Label Pattern

`text-sky-400 font-semibold text-sm uppercase tracking-widest mb-3` above every section heading. Consistent rhythm.

## Implementation

- No custom fonts needed
- `antialiased` on body
- Max-width: `max-w-6xl`
- Sections alternate: dark hero → feature grid → dark CTA → pricing
- `animate-pulse` on status dot in hero badge
