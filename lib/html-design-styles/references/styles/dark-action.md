# Dark Action Style

Cinematic dark aesthetic with high-contrast yellow/gold accents, Oswald display font, and a tactile martial energy. Confident and aggressive. Use when asked for "dark action style".

## Typography

Oswald (display/headlines, weight 500-700) + Inter (body, weight 400-600). Headlines: `font-display font-bold uppercase tracking-tighter`. Nav labels: `font-sans font-semibold uppercase text-xs tracking-widest`.

## Colors

```
Background:  #111111  (cobra-black)
Dark surface: #1a1a1a (cobra-dark)
Light surface: #f3f4f6
Text on dark: #ffffff
Text on light: #111111
Yellow accent: #FCD34D  (cobra-yellow / amber-300)
Gold:          #D97706
Hero gradient: linear-gradient(135deg, #111111 0%, #2a2a2a 100%)
```

## Hero Section

Dark gradient full-width, `min-h-[85vh] flex items-center justify-center`. Background: large blurred circles at 10% opacity (`bg-cobra-yellow/10 rounded-full blur-[128px]`). Centered content with `font-display text-6xl md:text-8xl uppercase tracking-tighter leading-none`. Gradient text: `bg-clip-text text-transparent bg-gradient-to-b from-white to-gray-400`.

Small top badge: `rounded-full bg-white/10 backdrop-blur-sm border border-white/20 text-xs tracking-widest uppercase text-cobra-yellow`.

## Marquee Strip

`bg-cobra-yellow`, full width, `font-display font-bold text-lg text-cobra-black uppercase whitespace-nowrap tracking-widest`. Use icon separators (Font Awesome bolt). Below the hero, acts as visual separator.

## Cards (light sections)

`rounded-2xl border border-gray-100 bg-white p-8 shadow-sm hover:shadow-2xl hover:-translate-y-2 transition-all duration-300`. Icon areas: `rounded-2xl bg-gray-50 group-hover:bg-cobra-black group-hover:text-cobra-yellow transition-colors`.

## Buttons

```css
.btn-primary { background: #FCD34D; color: #111; rounded-lg; font-display font-bold uppercase tracking-wider; }
.btn-primary:hover { box-shadow: 0 0 30px rgba(252,211,77,0.4); transform: scale(1.05); }
/* Gold pulse-glow: @keyframes pulse-glow { 0%,100% { box-shadow: 0 0 15px rgba(252,211,77,0.2) } 50% { box-shadow: 0 0 25px rgba(252,211,77,0.5) } } */
```

## Navigation

`fixed w-full bg-white/90 backdrop-blur-md border-b border-gray-200 shadow-sm`. Logo: black icon `rounded-lg text-cobra-yellow`, hover turns yellow `bg-cobra-yellow text-black`. Nav buttons: yellow or black rounded-full pills (`px-6 py-2.5 rounded-full font-semibold uppercase text-xs tracking-widest`).

## Section Structure

Alternating light/dark: hero dark → content white → dark feature → white pricing. Each `py-24 px-4`. Yellow underline accent: `w-24 h-1 bg-cobra-yellow mx-auto rounded-full` after section titles.

## Decorative Ghost Text

`text-9xl font-display font-bold text-white outline-text opacity-20 rotate-12 pointer-events-none select-none` - watermark word in hero.

## Implementation

- Google Fonts: Oswald + Inter
- Font Awesome for icons (fa-hand-fist, fa-bolt, etc.)
- `antialiased` + `transition-colors duration-300` on body
- Custom scrollbar: `bg: #f1f1f1, thumb: #111, thumb:hover: #333, border-radius: 4px`
