# Swiss Style

Pure International Typographic Style. Helvetica/system-sans, strict mathematical grid, black and red only, zero decorative elements. Function is the only form. Use when asked for "swiss style".

## Typography

System-ui / `-apple-system` (mimics Helvetica). Or load Inter at very low weights. Headlines `font-bold` (not black - 700 max). `tracking-tight`. Body: `font-normal text-sm leading-[1.5]`. Labels: `font-bold text-[11px] uppercase tracking-[0.15em]`. Numbers: `font-bold tabular-nums`.

## Colors

```
White:   #ffffff
Black:   #000000
Red:     #e60000   (one accent color only - use sparingly)
Gray:    #f4f4f4   (background sections)
```

Nothing else. Ever. If you feel the urge to add a color, remove it.

## Grid System

Everything aligns to a strict baseline grid. Use `gap-px bg-black` technique to create visible grid lines:

```css
.swiss-grid { display: grid; gap: 1px; background: #000; }
.swiss-grid > * { background: white; }
```

Columns: always mathematical (2, 3, 4, or 6). Never asymmetric.

## Borders and Rules

Only `1px solid #000` or `2px solid #000`. No rounding. No shadows. A thick `4px solid #e60000` rule is the maximum decoration allowed.

## Cards

No card visual treatment. Content sits directly in the grid cell: `padding: 24px; background: white`. The grid gap creates the borders.

## Typography Scale

```
Display:  clamp(48px, 8vw, 96px), font-bold, tracking-tight
H1:       48px, font-bold
H2:       32px, font-bold
H3:       20px, font-bold
Body:     14px, font-normal, leading-[1.6]
Label:    11px, font-bold, uppercase, tracking-[0.15em]
```

## Red Accent - Used For

- One featured stat number
- A single CTA button
- Section flag/label on the most important section
- Never on more than 2 elements per page

## Buttons

```css
.swiss-btn {
  background: #000; color: #fff;
  border: none; border-radius: 0;
  font-bold; text-transform: uppercase; tracking-[0.1em]; font-size: 12px;
  padding: 12px 32px;
}
.swiss-btn:hover { background: #e60000; }
.swiss-btn-outline { background: transparent; color: #000; border: 2px solid #000; }
.swiss-btn-outline:hover { background: #000; color: #fff; }
```

## Nav

Pure white, `border-bottom: 2px solid #000`. Logo: just the product name in `font-bold uppercase tracking-tight`. Links: `font-bold text-xs uppercase tracking-[0.15em]`. No icons, no pills, no rounding.

## Section Structure

Large, bold section numbers: `text-[120px] font-bold text-black leading-none opacity-10` as background watermark. Section heading left-aligned, body text in a narrower column.

## Pull Quote / Stat

Single very large number: `text-[80px] font-bold leading-none`. A `4px solid #e60000` rule above it. Label below in `text-xs uppercase tracking-[0.2em]`.

## Implementation

- No Google Fonts - use system-ui stack
- `max-w-7xl mx-auto` - full use of available width
- Section padding: `py-24`
- No `box-shadow` anywhere - ever
- No `border-radius` anywhere - ever
- `antialiased` on body
