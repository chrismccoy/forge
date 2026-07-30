# Monolith Style

Clean white brutalism with a dark navy shadow system, thick top border, monospace font, and no color accents - raw and serious. Use when asked for "monolith style".

## Typography

System monospace (`font-mono` Tailwind default). All headings forced `font-weight: 900`. `uppercase tracking-tighter leading-none` for display headings. `uppercase tracking-wide` for card headings. Body text `text-dark` (`#111827`).

## Colors

```css
--color-dark:   #111827;   /* text, borders, shadows */
--color-light:  #ffffff;   /* background */
--color-medium: #4b5563;   /* muted text, secondary */
```

No color accents whatsoever - strictly dark/light/medium.

## Top Border

`border-t-8 border-dark` on `<body>` - thick top edge is the defining visual signature.

## Shadow System

```css
.shadow-monolith    { box-shadow: 4px 4px 0px #111827; }
.shadow-monolith-lg { box-shadow: 8px 8px 0px #111827; }
.shadow-monolith-hover:hover { box-shadow: 6px 6px 0px #111827; transform: translate(-2px, -2px); }
```

## Buttons

```css
.brutal-btn {
  border: 2px solid #111827;
  box-shadow: 3px 3px 0px #111827;
  transition: all 0.1s ease-out;
}
.brutal-btn:hover  { box-shadow: 4px 4px 0px #111827; transform: translate(-1px, -1px); }
.brutal-btn:active { box-shadow: 1px 1px 0px #111827; transform: translate(2px, 2px); }
```

Primary: `bg-dark text-light`. Secondary: `bg-light text-dark`. Both use `.brutal-btn`. Text `font-extrabold uppercase`.

## Cards

`border-4 border-dark shadow-monolith`. Icon area: `bg-dark p-4 inline-block border-2 border-dark shadow-monolith` - dark square with light icon inside. Card headings: `font-extrabold uppercase tracking-wide`.

## Section Headings

`text-4xl md:text-5xl font-extrabold uppercase text-center border-b-4 border-medium pb-4` - bottom border on section titles in medium gray.

## Hero

`border-b-4 border-dark shadow-monolith-lg`. 2-column grid (headline + visual panel). Headline: `border-b-4 border-dark pb-4`. Subtext: `border-l-4 border-medium pl-4`. Visual panel: `border-4 border-dark shadow-monolith-lg` with `absolute inset-0 grid grid-cols-3 grid-rows-3` grid overlay at 20% opacity.

## Pricing/CTA Cards

`border-4 border-dark shadow-monolith-lg` panels. Highlight row: `bg-dark text-light` header bar. Feature lists with `border-b border-medium` row separators.

## Implementation

- No Google Fonts - system monospace
- `antialiased leading-tight`
- `max-w-7xl mx-auto px-4`
- Section padding: `py-16 md:py-24`
- Font Awesome for icons (dark square icon boxes: `bg-dark p-4 inline-block`)
