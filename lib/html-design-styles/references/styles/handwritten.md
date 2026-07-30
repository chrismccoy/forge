# Handwritten Style

Sketch-like hand-drawn borders, pencil textures, slightly imperfect linework, and a warm personal studio feel. Like a designer's sketchbook brought to life. Use when asked for "handwritten style".

## Typography

Caveat or Kalam (Google Fonts, weights 400-700) for headlines and labels - authentic handwriting feel. Lato or Open Sans (light) for body - readable contrast to the expressive headings.

## Colors

```
Paper:         #fdfaf4   (warm sketch paper)
Pencil:        #2c2c2c   (near-black, not pure black)
Blue pen:      #2255aa
Red markup:    #cc3322
Yellow hi:     #f5e642
Muted:         #888880
```

## Sketchy Border Effect

Use SVG filters for a hand-drawn wobble on borders:

```css
.sketchy {
  filter: url(#sketchy);
  border-radius: 2px 8px 4px 6px / 6px 2px 8px 4px;  /* irregular */
}
/* SVG filter in page (hidden): */
/* <svg style="display:none"><filter id="sketchy">
  <feTurbulence type="turbulence" baseFrequency="0.05" numOctaves="2" result="noise"/>
  <feDisplacementMap in="SourceGraphic" in2="noise" scale="3" xChannelSelector="R" yChannelSelector="G"/>
</filter></svg> */
```

## Hand-Drawn Cards

```css
.sketch-card {
  background: white;
  border: 2px solid #2c2c2c;
  border-radius: 3px 10px 5px 8px / 8px 3px 10px 5px;  /* imperfect rounding */
  box-shadow: 3px 4px 0 #ddd, 4px 5px 0 #ccc;  /* pencil shadow */
  padding: 24px;
  position: relative;
}
/* Add a slight paper texture via ::before */
```

## Underline Sketchy Highlight

```css
.sketch-underline {
  text-decoration: none;
  background: linear-gradient(to bottom, transparent 60%, #f5e642 60%);
  padding-bottom: 2px;
}
```

## Annotation / Arrow Labels

```html
<!-- Pointing arrow annotation -->
<div class="annotation">
  <span class="font-hand text-sm text-blue-pen">← look here!</span>
</div>
```

Use `transform: rotate(-5deg)` on annotation divs.

## Buttons

```css
.sketch-btn {
  background: white; color: #2c2c2c;
  border: 2px solid #2c2c2c;
  border-radius: 4px 10px 8px 6px / 10px 4px 6px 8px;  /* irregular */
  font-family: 'Caveat'; font-weight: 700; font-size: 18px;
  padding: 10px 28px;
  box-shadow: 3px 3px 0 #2c2c2c;
}
.sketch-btn:hover { transform: rotate(-1deg); box-shadow: 5px 5px 0 #2c2c2c; }
.sketch-btn-filled { background: #2c2c2c; color: white; }
```

## Tape / Pin Accents

Small decorative elements holding cards: colored tape strips (`.tape { background: rgba(255,220,100,0.7); transform: rotate(-3deg); height: 18px; width: 48px; }`).

## Implementation

- Google Fonts: Caveat + Lato
- Apply SVG displacement filter for authentic sketch wobble
- `antialiased` off (slightly) - `font-smooth: never` for more raw feel
- Subtle paper background texture on body
- Grid lines can be sketchy: `opacity: 0.3`
