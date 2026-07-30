# Clay Style

Playful, chunky, toy-like design system - bold shadows, rounded forms, candy colors, physical depth. Use when asked for "clay style".

## Typography

Nunito (Google Fonts, weights 400-900). Headlines 900 weight. Buttons 800 weight. Body 700 weight. Apply `-webkit-font-smoothing: antialiased`.

## Colors

```
Page background:  #f0eeff   (soft lavender)
Primary text:     #1e1b4b   (deep indigo)
Primary brand:    #7c3aed   (vivid purple)
Accent:           #f59e0b   (amber/gold)
Dark purple:      #5b21b6   (shadow color)
Footer bg:        #1e1b4b
```

## The Clay Card - Core Mechanic

Every card uses a 3-layer box-shadow for physical depth:

```css
.clay-card {
    background: #ffffff;
    border-radius: 28px;
    box-shadow:
        8px 8px 0px rgba(124,58,237,0.15),
        inset 0 -4px 0 rgba(0,0,0,0.08),
        0 20px 40px rgba(124,58,237,0.10);
    transition: transform 0.2s ease, box-shadow 0.2s ease;
}
.clay-card:hover {
    transform: translateY(-3px);
    box-shadow:
        10px 12px 0px rgba(124,58,237,0.18),
        inset 0 -4px 0 rgba(0,0,0,0.08),
        0 28px 48px rgba(124,58,237,0.14);
}
```

**.clay-card-purple** - `#7c3aed` bg, white text:

```css
box-shadow:
    8px 8px 0px rgba(91,33,182,0.4),
    inset 0 -4px 0 rgba(0,0,0,0.18),
    0 20px 40px rgba(124,58,237,0.25);
```

## Clay Buttons - Pressable Feel

Bottom-offset shadow simulates a physical press. Lift on hover, press down on `:active`.

```css
.clay-btn-purple {
    background: #7c3aed; color: #fff;
    border-radius: 100px; font-weight: 800;
    box-shadow:
        0 6px 0px #5b21b6,
        inset 0 -6px 0 rgba(0,0,0,0.15),
        0 12px 32px rgba(124,58,237,0.35);
}
/* hover: translateY(-2px), shadows grow */
/* active: translateY(2px), shadows shrink */

.clay-btn-amber { background: #f59e0b; color: #1e1b4b; /* 0 6px 0px #d97706 */ }
.clay-btn-white { background: #fff; color: #1e1b4b; /* 0 6px 0px rgba(0,0,0,0.15) */ }
```

## Section Color Rotation

Alternate section backgrounds in this order - it's the primary visual rhythm of the page:

```
bg-section-mint:   #ecfdf5
bg-section-peach:  #fff7ed
bg-section-sky:    #eff6ff
bg-section-yellow: #fefce8
bg-section-green:  #f0fdf4
bg-section-pink:   #fdf2f8
bg-section-violet: #f5f3ff
bg-section-rose:   #fff1f2
```

## Components

**.nav-pill** - pastel-colored bg pills, 100px radius, 700 weight

**.icon-box** - 48×48px, 14px radius, brand-colored bg, centered icon

**.clay-pill** - inline label/tag, 100px radius, 800 weight, pastel bg

**.check-badge** - feature list item with `#7c3aed` circle + white checkmark

**.stat-card** - clay-card with large number (`clamp(36px,5vw,56px)`, 900 weight) + label

**.num-badge** - 28×28px circle, `#7c3aed` bg, white text, 900 weight

**.feature-item** - feature row; label text has `border-bottom: 3px solid #7c3aed`, `display: inline`

**.option-card** - clay-card with 4px colored top accent bar (`border-radius: 4px 4px 0 0`)

**.archive-card** - clay-card with colored header bar, title, description

**.swatch-chip** - 28×28px circle, `border-radius: 50%`, `box-shadow: 3px 3px 0px rgba(0,0,0,0.15)`

**.clay-code** - `background: #1e1b4b`, `color: #c4b5fd`, monospace, 16px radius

## Header

White bg, `box-shadow: 0 2px 20px rgba(124,58,237,0.08)`, sticky. Logo left, colored nav pills right, amber "Buy Now" CTA.

## Hero

`background: #f0eeff`. Giant headline `clamp(56px,10vw,96px)`, 900 weight. Two CTA buttons. Stat cards row below. Optional purple marquee bar (`background: #7c3aed`, white scrolling text).

## Pricing Card

Centered, max 480px. Clay-card with gradient top stripe `linear-gradient(135deg, #7c3aed, #a855f7)`. Price in amber. `.check-badge` feature list. `.clay-btn-purple` CTA.

## Purchase CTA

Dark purple gradient: `linear-gradient(135deg, #4c1d95 0%, #7c3aed 50%, #6d28d9 100%)`. White headline, amber price, `.clay-btn-amber` primary + `.clay-btn-white` secondary. Blurred decorative circles as bg accents.

## Marquee Strip

`background: #7c3aed`, white text, `overflow: hidden`. Track: `display: flex; gap: 40px; animation: marquee 36s linear infinite`. Items separated by `•`.

## Footer

`background: #1e1b4b`. White text, `#c4b5fd` accent links. 3-column: brand | links | social. Purple border on bottom bar.

## Implementation

- Single HTML file, inline CSS, CDN Tailwind, Font Awesome 6, Google Fonts (Nunito)
- `.container` max-width 1120px, margin auto, 24px padding
- Sections: `padding: 80px 0`
- `border-radius: 28px` on all major cards
- Card grids: 2-4 columns, `gap: 24px-28px`
- ALL shadows use purple hue family `rgba(124,58,237,...)` for cohesion
- Buttons MUST have the `6px` bottom-offset shadow for the pressed-clay feel
- Font weights: 900 for stats/numbers, 800 for buttons/badges, 700 for nav/labels
- Use at least 4-5 different section background colors per page
- Smooth scroll on `<html>`
