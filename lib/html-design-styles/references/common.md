# Common Implementation Patterns

Cross-cutting conventions used across the design styles in this catalog. Load this once at the start of a session, then load the specific style file for the chosen aesthetic.

These patterns appear in many - but not all - styles. The per-style file is authoritative when it specifies a different value. Where this document and a style file conflict, follow the style file.

---

## Asset Loading

### Google Fonts

Most styles in this catalog rely on Google Fonts. Load them in `<head>` before any inline CSS that references them:

```html
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;600;700;800&display=swap" rel="stylesheet">
```

Always include `&display=swap` so text remains visible during font load.

A handful of styles intentionally use the system font stack and need NO Google Fonts - including: Pure Brutalist, Utility Terminal, Dark Cosmic, Dark SaaS, Dark Mono, Monolith, Soft Modern, Swiss, Skeuomorphic, Y2K. The per-style file calls this out explicitly.

### Tailwind CDN

Most demo HTML in this catalog uses the Tailwind CDN for prototyping:

```html
<script src="https://cdn.tailwindcss.com"></script>
```

If a style requires custom Tailwind config (custom font families, custom colors, custom shadows), define it inline immediately after the CDN script:

```html
<script>
  tailwind.config = {
    theme: {
      extend: {
        fontFamily: { display: ['Oswald', 'sans-serif'] },
        colors:     { brand: '#FCD34D' },
      },
    },
  };
</script>
```

### Font Awesome

Several styles call for Font Awesome 6 icons. When needed:

```html
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">
```

Some styles (Luxury, Scandinavian, Handwritten) explicitly avoid Font Awesome and prefer Unicode symbols or inline SVGs.

---

## Body / Page Defaults

### Font Smoothing

Apply `-webkit-font-smoothing: antialiased` (or Tailwind `antialiased`) on `<body>` for almost every style. Exceptions: Pixel and Handwritten styles deliberately turn smoothing off (`font-smooth: never`) for a rougher feel.

### Horizontal Overflow Guard

Many styles use oversized decorative elements (blobs, watermark text, marquees, animated backgrounds). Add `overflow-x: hidden` on `<body>` to prevent runaway horizontal scroll. Required by: Acid Brutalist, Dark Cinema, Vaporwave, Dark Neon, Memphis, Maximalist, Athletic, Psychedelic, Grunge, and any style with fixed-position decorative blobs.

### Smooth Scroll

`scroll-behavior: smooth` on `<html>` is the default for the catalog unless a style calls for a more rigid feel.

---

## Container & Layout Conventions

### Max-Width Defaults

| Width | Tailwind | Used For |
|-------|----------|----------|
| `max-w-4xl` (896px) | narrow | Art Deco, Scandinavian - formal/intimate |
| `max-w-5xl` (1024px) | medium-narrow | Luxury, Organic, Cottagecore, Japanese |
| `max-w-6xl` (1152px) | medium | Soft Modern, Glassmorphism, Tropical, Corporate, Dark SaaS |
| `max-w-7xl` (1280px) | wide | Dark Cosmic, Swiss, Monolith, Pink Neo, Dot Grid |
| `max-w-[1600px]` | extra wide | Utility Terminal, Blueprint |
| `max-w-[680px]` | reading | Longform body column only |

When in doubt, use `max-w-7xl mx-auto px-4` (or `px-6`).

### Section Padding

| Padding | When |
|---------|------|
| `py-14 md:py-20` | Soft Modern, compact friendly layouts |
| `py-16 md:py-24` | Monolith and most utilitarian styles |
| `py-20` | Memphis, Tropical, Corporate, Cottagecore - common default |
| `py-24` | Swiss, Dark SaaS - generous default |
| `py-32` | Enterprise Editorial, Japanese - dense/contemplative |
| `py-32 md:py-48` | Luxury - extreme whitespace |
| `padding: 80px 0` | Bento, Clay, Acid Brutalist, Retro Terminal - fixed |

### Container Pattern

```css
.container { max-width: 1120px; margin: 0 auto; padding: 0 24px; }
```

Or via Tailwind: `max-w-6xl mx-auto px-6`. Bento and Clay both use 1120px.

---

## Selection State

A `::selection` rule signals the style's accent color and is used in nearly every style:

```css
::selection { background: <accent>; color: <contrast-color>; }
```

Common patterns:
- Pure Brutalist / Utility Terminal: `bg-black text-white`
- Neobrutalist: `bg-neo-black text-neo-green`
- Acid Brutalist / Cyberpunk: `bg-[#FFFF00]` / `bg-[#f5e642]` on black
- Dark Mono / Sci-Fi HUD / Retro Terminal: cyan/green selection on dark text
- Glassmorphism / Aurora / Psychedelic: `bg-white/20 text-white` (translucent)
- Enterprise Editorial: `bg-indigo-100 text-indigo-700`

If the per-style file does not specify, choose a high-contrast accent from the style's palette.

---

## Focus & Keyboard Accessibility

Use `focus-visible` to scope focus rings to keyboard navigation only:

```css
a:focus-visible, button:focus-visible {
  outline: 2px solid <accent>;
  outline-offset: 2px;
  border-radius: 4px;
}
```

Tailwind equivalent:

```html
class="focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[accent] focus-visible:ring-offset-2"
```

Soft Modern, Dot Grid, Dark Mono, and Dark Cosmic specify focus rings explicitly. Apply the same pattern to every interactive element in any style - never strip outlines without replacing them.

---

## Reduced-Motion Fallback

Wrap any non-trivial animation, including infinite marquees, parallax blobs, glitch effects, and morphing shapes:

```css
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
    scroll-behavior: auto !important;
  }
}
```

The Soft Modern style specifies this explicitly; apply the same protection to any style that uses motion.

---

## Skip Link & Landmarks

Every full-page output should include a skip link as the first focusable element after `<body>`:

```html
<a href="#main"
   class="sr-only focus:not-sr-only focus:fixed focus:top-4 focus:left-4 focus:z-50
          focus:bg-black focus:text-white focus:px-4 focus:py-2 focus:rounded">
  Skip to main content
</a>
```

Use semantic landmarks: `<header>`, `<nav>`, `<main id="main">`, `<aside>`, `<footer>`. Add `aria-label` to `<nav>` elements when more than one is present (e.g. `aria-label="Primary"` and `aria-label="Footer"`). Add `aria-label` to icon-only buttons.

---

## Marquee Pattern

Several styles use scrolling marquee strips (Bento, Clay, Acid Brutalist, Pop Art, Athletic, Cyberpunk, Pink Neo, Neobrutalist):

```css
@keyframes marquee {
  from { transform: translateX(0); }
  to   { transform: translateX(-50%); }
}
.marquee-track {
  display: flex;
  gap: 40px;
  animation: marquee 30s linear infinite;
  white-space: nowrap;
}
```

Wrap the track in `overflow: hidden` and duplicate the content list so the loop reads seamlessly. Speed: 28s-36s is standard.

---

## Custom Scrollbar

Several dark/cinematic styles call for a colored scrollbar:

```css
::-webkit-scrollbar { width: 6px; }
::-webkit-scrollbar-track { background: <bg>; }
::-webkit-scrollbar-thumb { background: <accent>; border-radius: 3px; }
::-webkit-scrollbar-thumb:hover { background: <accent-hover>; }
/* Firefox */
* { scrollbar-color: <accent> <bg>; scrollbar-width: thin; }
```

Used by: Acid Brutalist, Dark Action, Dark Cinema, Vaporwave, Dark Neon, Cyberpunk, Sci-Fi HUD, Pink Neo.

---

## Common "Backing Shadow" Pattern

A frequent neobrutalist mechanic: a solid black `<div>` is positioned behind the card, offset by a few pixels. On hover, the offset grows so the card appears to lift:

```html
<div class="relative group">
  <div class="absolute inset-0 bg-black translate-x-2 translate-y-2
              group-hover:translate-x-3 group-hover:translate-y-3 transition-transform"></div>
  <div class="relative bg-white border-4 border-black p-6">
    <!-- card content -->
  </div>
</div>
```

Used by: Neobrutalist, Pop Art, Pink Neo, Dot Grid (variant). The same effect can be approximated with `box-shadow: Npx Npx 0 0 #000` for a flatter implementation.
