# Y2K Style

Early internet nostalgia - Windows 95/98 beveled UI, system gray, pixel-perfect chunky buttons, dialog boxes, taskbars, and everything that felt futuristic in 1999. Use when asked for "y2k style".

## Typography

System UI stack (mimics MS Sans Serif). Or load VT323 for more retro flavor. Headlines in `font-bold text-sm uppercase tracking-widest`. Everything feels like a dialog box label.

## Colors

```
Window bg:    #c0c0c0   (classic Windows gray)
Button face:  #d4d0c8
Title bar:    linear-gradient(to right, #000080, #1084d0)  (blue gradient)
Title text:   #ffffff
Sunken:       #808080 (dark edge) / #ffffff (light edge)  /* inset bevel */
Raised:       #ffffff (top/left) / #808080 (bottom/right) /* outset bevel */
Desktop teal: #008080
Text:         #000000
```

## The Bevel System

```css
/* Raised button / panel */
.win-raised {
  background: #d4d0c8;
  border-top: 2px solid #ffffff;
  border-left: 2px solid #ffffff;
  border-right: 2px solid #808080;
  border-bottom: 2px solid #808080;
}
/* Sunken / pressed / input */
.win-sunken {
  background: #ffffff;
  border-top: 2px solid #808080;
  border-left: 2px solid #808080;
  border-right: 2px solid #ffffff;
  border-bottom: 2px solid #ffffff;
}
/* Outer bevel (window frame) */
.win-window {
  border: 2px solid #000;
  outline: 2px solid #dfdfdf;
}
```

## Title Bar

```css
.win-titlebar {
  background: linear-gradient(to right, #000080, #1084d0);
  color: white; font-weight: 700; font-size: 12px;
  padding: 4px 6px;
  display: flex; align-items: center; justify-content: space-between;
  user-select: none;
}
.win-titlebar-btn {
  width: 16px; height: 14px;
  background: #d4d0c8;
  border-top: 1px solid #fff; border-left: 1px solid #fff;
  border-right: 1px solid #808080; border-bottom: 1px solid #808080;
  font-size: 10px; display: flex; align-items: center; justify-content: center;
}
```

## Window / Dialog

```css
.win-dialog {
  background: #d4d0c8;
  border: 2px solid #dfdfdf;
  outline: 2px solid #000;
  padding: 0;
  /* Contains: .win-titlebar + content area */
}
```

## Buttons

```css
.win-btn {
  background: #d4d0c8;
  border-top: 2px solid #fff; border-left: 2px solid #fff;
  border-right: 2px solid #808080; border-bottom: 2px solid #808080;
  padding: 4px 16px; font-size: 12px; font-weight: 400;
  min-width: 80px;
}
.win-btn:active {
  border-top: 2px solid #808080; border-left: 2px solid #808080;
  border-right: 2px solid #fff; border-bottom: 2px solid #fff;
}
.win-btn-default { outline: 2px solid #000; }  /* default button gets outer border */
```

## Progress Bar

`win-sunken` container, inner fill in royal blue `#000080`, chunky, no border-radius.

## Desktop Taskbar

`height: 32px; background: #d4d0c8; border-top: 2px solid #fff` - start button, open windows, clock.

## Start Button

`font-bold; background: #d4d0c8` with Windows logo and "Start" text. Raised bevel.

## Implementation

- No Google Fonts - system-ui stack only
- `cursor: default` - use system cursor
- All interactive elements need raised/sunken bevel state
- `font-size: 12px` for labels - small, system-like
- Page background: `#008080` (teal) for full desktop effect, or `#c0c0c0` for clean
