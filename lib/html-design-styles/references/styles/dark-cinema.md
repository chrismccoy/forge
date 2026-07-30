# Dark Cinema Style

Near-black background, red accent with glow effect, Bebas Neue display font, noise texture, diagonal stripe patterns, and floating animated labels. Cinematic and visceral. Use when asked for "dark cinema style".

## Typography

Bebas Neue (headlines/display, `letter-spacing: 0.02em`) + DM Sans (body, weights 300-700). Headings: `font-display text-[clamp(72px,14vw,180px)] leading-none`. Body: `font-body text-white/60 font-light leading-relaxed`.

## Colors

```
Background:    #0a0a0a
Text:          #f0ede8   (warm off-white)
Red accent:    #dc2626   (red-600)
Red hover:     #ef4444   (red-500)
Red glow:      box-shadow: 0 0 60px rgba(220,38,38,0.35), 0 0 120px rgba(220,38,38,0.15)
Yellow float:  #facc15
Text-outline:  -webkit-text-stroke: 2px #f0ede8; color: transparent;
```

## Noise Overlay

```css
body::before {
  content: ''; position: fixed; inset: 0;
  background-image: url("data:image/svg+xml,%3Csvg viewBox='0 0 256 256' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='noise'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.9' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23noise)' opacity='1'/%3E%3C/svg%3E");
  opacity: 0.035; pointer-events: none; z-index: 9999;
}
```

## Red Glow

```css
.red-glow { box-shadow: 0 0 60px rgba(220,38,38,0.35), 0 0 120px rgba(220,38,38,0.15); }
.text-red-glow { text-shadow: 0 0 40px rgba(220,38,38,0.6); }
```

Apply `.red-glow` to CTA buttons. Apply `.text-red-glow` to red accent text in headline.

## Hero Background

```html
<!-- Layered behind hero content -->
<div class="absolute top-1/4 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[700px] h-[700px] rounded-full bg-red-900/20 blur-[140px]"></div>
<div class="absolute bottom-0 left-0 w-[400px] h-[400px] rounded-full bg-red-800/10 blur-[100px]"></div>
<!-- Subtle white grid -->
<div class="absolute inset-0 opacity-5" style="background-image: linear-gradient(to right, #fff 1px, transparent 1px), linear-gradient(to bottom, #fff 1px, transparent 1px); background-size: 80px 80px;"></div>
```

## Floating Animated Labels

Decorative elements floating around the hero (hidden on mobile):

```css
@keyframes float { 0%,100% { transform: translateY(0) rotate(-3deg); } 50% { transform: translateY(-14px) rotate(-3deg); } }
@keyframes float2 { 0%,100% { transform: translateY(0) rotate(2deg); } 50% { transform: translateY(-10px) rotate(2deg); } }
.float-1 { animation: float 5s ease-in-out infinite; }
.float-2 { animation: float2 6s ease-in-out infinite 1s; }
```

Labels: `bg-red-600 text-white font-display text-2xl px-5 py-3 rounded-2xl rotate-[-3deg] shadow-2xl`.

## Word Cycle Animation

Cycling word in headline:

```css
.word-cycle span { position: absolute; left: 0; opacity: 0; transform: translateY(20px); transition: none; }
.word-cycle span.active { opacity: 1; transform: translateY(0); transition: opacity 0.4s ease, transform 0.4s ease; }
.word-cycle span.exit { opacity: 0; transform: translateY(-20px); transition: opacity 0.3s ease, transform 0.3s ease; }
```

## Fade-Up Stagger

```css
@keyframes fadeUp { from { opacity: 0; transform: translateY(32px); } to { opacity: 1; transform: translateY(0); } }
.fade-up { opacity: 0; animation: fadeUp 0.7s ease forwards; }
.delay-1 { animation-delay: 0.1s; } /* through .delay-5 */
```

## Stat Chips (below hero CTA)

`bg-white/5 border border-white/10 rounded-lg px-4 py-2 text-sm` - colored bold value + muted label.

## Feature Cards

`feat-card`: `border border-white/10 rounded-2xl bg-white/5 p-6`. Hover: `translateY(-4px); box-shadow: 0 20px 60px rgba(0,0,0,0.5)`.

## Tape/Banner Strip

```css
.tape { background: #dc2626; transform: rotate(-1.5deg); margin: 0 -20px; }
```

Full-width red diagonal tape between sections. `border-y-4 border-red-800 py-3 overflow-hidden`.

## Zigzag Pattern

```css
.zigzag {
  background: linear-gradient(135deg, #0a0a0a 25%, transparent 25%) -20px 0,
              linear-gradient(225deg, #0a0a0a 25%, transparent 25%) -20px 0,
              linear-gradient(315deg, #0a0a0a 25%, transparent 25%),
              linear-gradient(45deg, #0a0a0a 25%, transparent 25%);
  background-size: 40px 40px; background-color: #111;
}
```

## Diagonal Stripe (section divider bg)

```css
.stripe-bg {
  background-image: repeating-linear-gradient(
    -45deg, transparent, transparent 8px, rgba(255,255,255,0.025) 8px, rgba(255,255,255,0.025) 9px
  );
}
```

## Navigation

`fixed nav-blur bg-black/60 border-b border-white/5`. Minimal: logo + text links `text-white/60 hover:text-white` + red CTA `bg-red-600 hover:bg-red-500 rounded-lg`.

## CTA Section

Large red gradient CTA: `bg-gradient-to-r from-red-900 to-red-600`. Or dark section with red glowing button.

## Implementation

- Google Fonts: Bebas Neue + DM Sans
- `overflow-x: hidden` on body
- Custom scrollbar: `6px, track #0a0a0a, thumb #dc2626, border-radius: 3px`
- Pulse dot: `@keyframes pulse-dot { 0%,100% { opacity: 1; transform: scale(1); } 50% { opacity: 0.5; transform: scale(1.5); } }`
- Text outline: `-webkit-text-stroke: 2px #f0ede8; color: transparent` for ghost headline words
