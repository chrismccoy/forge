# Bento Style

Apple/macOS-inspired design system - clean, minimal, trust-building. Use when asked for "bento style".

## Typography

Plus Jakarta Sans (Google Fonts, weights 400-800). Headlines 800 weight, -0.02em letter-spacing, `clamp(28px, 4vw, 44px)`. Section labels 13px, 700 weight, 0.08em letter-spacing, uppercase. Body 16px/1.6. Apply `-webkit-font-smoothing: antialiased`.

## Colors

```css
--bg:        #f5f5f7;
--card:      #ffffff;
--text:      #1d1d1f;
--accent:    #0071e3;
--accent-dk: #0058c5;
--green:     #34c759;
--red:       #ff375f;
--muted:     #6e6e73;
--border:    rgba(0,0,0,0.07);
--shadow-sm: 0 2px 8px rgba(0,0,0,0.06), 0 8px 24px rgba(0,0,0,0.04);
--shadow-md: 0 4px 16px rgba(0,0,0,0.08), 0 16px 40px rgba(0,0,0,0.07);
--radius:    20px;
--radius-lg: 24px;
```

## Components

**.card** - white, 20px radius, `--shadow-sm`, hover `translateY(-2px)` + `--shadow-md`

**.pill variants:**
- `.pill-blue` → `rgba(0,113,227,0.1)` bg, blue text
- `.pill-green` → `rgba(52,199,89,0.12)` bg, dark green text
- `.pill-red` → `rgba(255,55,95,0.1)` bg, red text
- `.pill-gray` → `rgba(0,0,0,0.06)` bg, muted text

**.btn-blue** - `#0071e3` bg, white text, 100px radius, `0 4px 14px rgba(0,113,227,0.35)` shadow, hover darkens + lifts

**.btn-white** - white bg, dark text, `0 4px 14px rgba(0,0,0,0.15)` shadow

**.section-label** - blue uppercase micro-label above headings

## Layout Patterns

**Stats bento** - 5-column responsive grid of stat cards (big number + label)

**Features bento** - 3-column grid; cards can span 2 columns (`.wide`) for emphasis. Each card: icon box + headline + body.

**Widgets bento** - 4-column grid with `.tall` (spans 2 rows) and `.wide` (spans 2 cols) variants

**Design/archive bento** - asymmetric 2-column: large showcase card left, smaller detail cards stacked right

**Customizer bento** - featured card (`.featured`, blue gradient bg) alongside smaller option cards

**Two-column grid** - 50/50 split for comparison or two-panel sections

**Steps grid** - 3-column equal grid for numbered steps

## Header

White/translucent (`rgba(255,255,255,0.85)`), backdrop-filter blur 20px, 1px bottom border, sticky. Product name left + nav pills + CTA right. Nav pills: `rgba(0,0,0,0.06)` bg, hover `rgba(0,113,227,0.1)`.

## Purchase CTA

Full-width blue gradient: `linear-gradient(135deg, #0071e3 0%, #0058c5 100%)`. White text, `.btn-white` + outlined white button. Decorative circles in corners.

## Pricing Card

Centered, max 440px. White card, blue top accent bar. Feature list with blue checkmark bullets. Blue CTA button. One-time price badge.

## Marquee Strip

`overflow: hidden`, scrolling track with `animation: marquee 30s linear infinite`. White bg, blue icon accents, subtle top/bottom borders.

## Footer

Dark `#1d1d1f` bg, white text, 3-column layout (brand | links | social). `#3a3a3c` border on bottom bar with copyright.

## Implementation

- Single HTML file, inline CSS, CDN Tailwind, Font Awesome 6, Google Fonts
- `.container` max-width 1120px, margin auto, 24px padding
- Sections: `padding: 80px 0`
- Smooth scroll on `<html>`
- No section color alternation - entire page stays `#f5f5f7`, cards provide contrast
- Grid gaps 16px-24px consistently
- Headings use `clamp()` for responsive scaling
