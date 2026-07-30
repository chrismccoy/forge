# Neumorphism Style

Soft extruded UI - elements appear pushed out of or pressed into the same-color background. No hard borders, only dual light/dark shadows. Tactile and ethereal. Use when asked for "neumorphism style".

## Typography

Poppins or Nunito (Google Fonts, weights 300-600). Never heavy - the softness of the shadows IS the design. `font-medium` for headings, `font-light` for body. Letter spacing normal.

## Colors

```
Background:    #e0e5ec   (the defining color - everything matches it)
Text:          #4a5568
Muted:         #8898aa
Accent:        #6c63ff   (soft purple - or any single accent)
Shadow light:  #ffffff
Shadow dark:   #a3b1c6
```

The background, card backgrounds, and input backgrounds are ALL the same `#e0e5ec`. The shadows create all the depth.

## The Core Shadow Mechanic

```css
/* Raised / protruding element */
.neu-raised {
  background: #e0e5ec;
  border-radius: 16px;
  box-shadow: 6px 6px 12px #a3b1c6, -6px -6px 12px #ffffff;
}
/* Pressed / inset element */
.neu-pressed {
  background: #e0e5ec;
  border-radius: 16px;
  box-shadow: inset 4px 4px 8px #a3b1c6, inset -4px -4px 8px #ffffff;
}
/* Flat (hover state - subtle) */
.neu-flat {
  background: #e0e5ec;
  border-radius: 16px;
  box-shadow: 3px 3px 6px #a3b1c6, -3px -3px 6px #ffffff;
}
```

## Cards

Same as `.neu-raised`. No border. The shadow IS the card edge. Padding `24px-32px`. On hover: shadow grows slightly.

## Buttons

```css
.neu-btn {
  background: #e0e5ec;
  border: none; border-radius: 50px;
  box-shadow: 5px 5px 10px #a3b1c6, -5px -5px 10px #ffffff;
  color: #6c63ff; font-weight: 600;
  padding: 14px 32px;
  transition: all 0.2s ease;
}
.neu-btn:hover { box-shadow: 7px 7px 14px #a3b1c6, -7px -7px 14px #ffffff; }
.neu-btn:active { box-shadow: inset 4px 4px 8px #a3b1c6, inset -4px -4px 8px #ffffff; }
/* Accent variant */
.neu-btn-accent { background: #6c63ff; color: white; box-shadow: 5px 5px 10px rgba(108,99,255,0.4), -2px -2px 8px rgba(255,255,255,0.3); }
```

## Toggle / Switch

Oval track in `.neu-pressed` state. Circular thumb in `.neu-raised`. When active, thumb moves right and accent color appears.

## Input Fields

```css
.neu-input {
  background: #e0e5ec;
  border: none; border-radius: 12px;
  box-shadow: inset 4px 4px 8px #a3b1c6, inset -4px -4px 8px #ffffff;
  padding: 14px 18px; color: #4a5568;
}
.neu-input:focus { outline: none; box-shadow: inset 5px 5px 10px #a3b1c6, inset -5px -5px 10px #ffffff, 0 0 0 2px #6c63ff; }
```

## Progress Bar

Track: `.neu-pressed`. Fill: gradient from accent color, `border-radius: 50px`, no box-shadow on fill.

## Icon Circles

`width: 56px; height: 56px; border-radius: 50%` with `.neu-raised`. Accent-colored icon inside.

## Nav

Same background as page. Logo and links floating on the surface. Active link gets `.neu-pressed` treatment as a pill.

## Implementation

- Google Fonts: Poppins
- `background: #e0e5ec` on `html` AND `body` - every surface must match
- Never use hard borders or background color differences for cards
- Light source always top-left: light shadow top-left (`-x -y`), dark shadow bottom-right (`+x +y`)
- Works poorly on dark backgrounds - keep light
