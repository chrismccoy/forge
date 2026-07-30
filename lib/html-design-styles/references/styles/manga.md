# Manga Style

Bold ink outlines, dynamic speed lines, dramatic panel composition, halftone dot patterns, and high-contrast black/white with occasional color pop. Use when asked for "manga style".

## Typography

Bangers (Google Fonts) for display and sound effects - comic book energy. Nunito or Bold system-sans for body. Headlines `font-display uppercase tracking-wide`. Sound effects at oversized sizes and dramatic angles.

## Colors

```
White:       #ffffff
Black:       #0a0a0a
Halftone:    #f0f0f0
Red pop:     #e8001a   (the ONE accent color - used for critical moments)
Yellow:      #ffe600   (highlight - secondary)
```

90% black and white. Red used for the single most important element per section.

## Speed Lines

```css
.speed-lines {
  background: repeating-conic-gradient(
    from 0deg at 50% 50%,
    transparent 0deg, transparent 3deg,
    rgba(0,0,0,0.08) 3deg, rgba(0,0,0,0.08) 4deg
  );
}
```

## Halftone Pattern

```css
.halftone {
  background-image: radial-gradient(circle, #0a0a0a 1.5px, transparent 1.5px);
  background-size: 8px 8px;
  opacity: 0.1;
}
```

## Panel Cards

```css
.manga-panel {
  background: white;
  border: 4px solid #0a0a0a;
  position: relative;
  overflow: hidden;
}
/* Action panel - skewed border */
.manga-panel-action {
  border: 4px solid #0a0a0a;
  clip-path: polygon(0 0, 95% 0, 100% 100%, 5% 100%);  /* parallelogram */
}
```

## Sound Effect Text

```css
.sfx {
  font-family: 'Bangers'; font-size: clamp(60px, 15vw, 140px);
  color: #e8001a;
  -webkit-text-stroke: 3px #0a0a0a;
  text-shadow: 6px 6px 0 #0a0a0a;
  transform: rotate(-5deg);
  display: inline-block;
}
```

## Buttons

```css
.manga-btn {
  background: #0a0a0a; color: white;
  border: 3px solid #0a0a0a;
  font-family: 'Bangers'; font-size: 20px; text-transform: uppercase; letter-spacing: 0.05em;
  padding: 10px 28px;
  clip-path: polygon(4px 0, 100% 0, calc(100% - 4px) 100%, 0 100%);
  box-shadow: 4px 4px 0 #888;
}
.manga-btn:hover { background: #e8001a; box-shadow: 6px 6px 0 #0a0a0a; }
.manga-btn-outline { background: transparent; color: #0a0a0a; border-color: #0a0a0a; }
```

## Thought Bubble

`border-radius: 50%; border: 3px solid #0a0a0a; padding: 20px; background: white; position: relative` - with smaller circles as the bubble trail below.

## Implementation

- Google Fonts: Bangers + Nunito
- `overflow: hidden` on sections with speed lines
- Panel borders are always thick `4px solid black`
- Images: `filter: contrast(1.3) grayscale(100%)` for manga photo treatment
- Red used ONCE per page for maximum impact
