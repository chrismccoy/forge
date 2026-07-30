# Subskill — Rewrite the extracted page into clean Tailwind, same look

Goal: one self-contained HTML file with semantic markup and Tailwind utility classes
that renders **identically** to the original. The generated selectors (`css-1a2b3c`,
`sc-bdfBwQ`) are gone; the appearance is not. This is a translation, not a redesign —
no new type scale, no color changes, no spacing "improvements".

## Inputs (all from the ground-truth capture)

- `clone/index.html` — page-cloner's faithful extract: the real rendered DOM plus the
  real inlined CSS. This is the source of truth for structure, `@media`, `:hover`,
  fonts, and exact rules.
- `original/computed.json` — per-element real computed values (from
  `scripts/computed.js`), for exact numbers to map onto Tailwind.
- `original/*.png` — the screenshots, for a final human-eye check.

## Procedure

Work **section by section** (nav, hero, each block, footer). Per section:

1. **Take the real markup** from `clone/index.html`. Keep the DOM structure and the
   real text content. Replace non-semantic wrappers with semantic tags where obvious
   (`<header>`, `<nav>`, `<main>`, `<section>`, `<footer>`, `<button>`, `<ul>`), but
   don't restructure the layout.

2. **Strip the generated class attributes** and translate their styling into Tailwind
   using `references/mapping.md`:
   - Pull the element's exact values from `computed.json` (match by tag/text/path) →
     map to the nearest Tailwind step, or an arbitrary `[value]` when off-scale.
   - Pull responsive + interactive styling from the real CSS in `clone/index.html`:
     `@media` → `md:`/`lg:`, `:hover` → `hover:`, transitions → `transition`.
   - Keep exact colors as arbitrary values (`bg-[#0b5fff]`) unless a named token is a
     true match. Don't force the brand onto Tailwind's default palette.

3. **Preserve fonts** — carry the original's web-font `<link>`/`@font-face` over and
   reference families as `font-['Family']`; a system-font fallback is a look change.
   See `references/mapping.md` "Fonts" for the exact encoding.

4. **Images/assets** keep the absolutised URLs from the extract (already working).

## Output

One file: `<workspace>/tailwind/index.html`. Tailwind via CDN
(`<script src="https://cdn.tailwindcss.com"></script>`) is fine for a preview
deliverable. Self-contained, clean, readable — it gets screenshotted and edited in
place during validation.

If arbitrary values pile up (lots of `[17px]`, `[#1a1a1a]`), that's expected for a
faithful clone of a bespoke design — accuracy first. If the user later wants it
normalised onto a token scale, that's a separate pass.

## Global mechanics: port as a small base block, not per-element utilities

Some pages carry their look in *global* rules that don't belong on any single element:
a root font-size that scales at a breakpoint, an owl-selector rhythm
(`* + * { margin-top: 1.5rem }`), a `max-width: 60ch` measure, focus-ring defaults.
Reproducing these by sprinkling `mt-6` on thirty elements is fragile and lossy. Port
them verbatim into one small `<style>`/`@layer base` block and let Tailwind utilities
handle everything component-level. That's faithful, not cheating — those rules ARE the
page's system.

**Watch the owl-margin trap.** When rhythm comes from a global adjacent-sibling margin,
the total vertical height depends on how many sibling boundaries exist. If you flatten
non-semantic wrapper `<div>`s into cleaner semantic tags, you remove sibling
boundaries, so fewer margins accumulate and the page comes out **shorter** than the
original (seen on indiepen.tech: -8.4% height from exactly this). Catch it by diffing
full-page render heights, not just per-section looks. Fix by either preserving the
wrapper nesting or adding explicit spacing utilities to compensate.

## The line you're walking

Same page, same look, clean Tailwind. If a color, size, or spacing changed, you
redesigned — go back. If the class attributes still contain `css-`/`sc-` hashes, you
didn't translate — go back.
