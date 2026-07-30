---
name: page-tailwindify
description: Clones a live web page's exact look into clean, semantic Tailwind — same design, but the framework-generated selectors (css-1a2b3c, sc-bdfBwQ, jsx-hashes) are replaced with real Tailwind utility classes — then validates the rewrite against the original in a loop until it matches. Use whenever a user points at a live URL and wants the SAME design rebuilt in readable Tailwind classes, not a restyle — phrasings like "rebuild this page in Tailwind but keep the exact look", "convert this React app's styling to Tailwind classes", "clone this design into clean Tailwind", "same look, real Tailwind classes, not the hashed ones", or "de-obfuscate this page's classes into Tailwind". For a byte-exact clone that KEEPS the original ugly selectors, use page-cloner. For a redesign that changes the look, use page-redesigner. Requires Claude in Chrome for capturing the source page.
---

# Page Tailwindify

This skill reproduces a live page's **exact look** in clean, semantic Tailwind. The
original's framework-generated class hashes (`css-1a2b3c`, `sc-bdfBwQ`, `jsx-1234`)
are gone, replaced by real utility classes (`flex gap-4 rounded-lg px-6 hover:bg-…`).
The design does not change — colors, type, spacing, and layout stay identical. Only
the styling *system* changes, from opaque generated selectors to readable Tailwind.

The accuracy trick: don't guess Tailwind from a screenshot, and don't rely on
`getComputedStyle` alone (one state — loses `@media`, `:hover`, breakpoints). Drive
the rewrite from the page's **real markup and CSS** plus a dump of **real computed
values**, so every Tailwind class comes from an actual number, not an eyeball.

This sits between its two sibling skills: `page-cloner` keeps the exact look but keeps
the ugly selectors (byte-exact extract); `page-redesigner` rebuilds and changes the
look. This one keeps the look, cleans the selectors.

## The parts

1. **Capture ground truth** — reuse `page-cloner` to extract the faithful DOM + real
   CSS, plus screenshots; dump `scripts/computed.js` values *if* translating. See
   `references/capture-notes.md` for the capture gotchas.
2. **Detect, then branch** into one of two modes:
   - **`references/rehost.md`** — already-Tailwind page: swap the inlined compiled CSS
     for the Tailwind CDN. Nothing to translate.
   - **`references/rewrite.md`** (+ **`references/mapping.md`**) — hashed / CSS-in-JS
     page: translate real CSS + `computed.json` values into semantic HTML + Tailwind,
     section by section.
3. **`references/validate.md` — validate in a loop.** Screenshot the result, compare
   against the original on the single fidelity axis, fix drift, repeat.

Read each reference file when you reach that part; don't load them all upfront.

## Workflow

### 1. Capture ground truth

Requires Claude in Chrome — if unavailable, stop and tell the user; the rewrite needs
the real rendered page, and guessing produces a fake with nothing to validate against.

- **Extract the faithful clone.** Invoke the `page-cloner` skill (its
  `references/capture.md`) to produce `<workspace>/clone/index.html` — the real
  rendered DOM with real CSS inlined. This is the structural + CSS spec the rewrite
  reads from (it carries `@media`, `:hover`, fonts — things a screenshot can't).
- **Dump computed values** — *only if step 2's detection finds hashed / CSS-in-JS
  styling*; an already-Tailwind page skips this. Evaluate `scripts/computed.js` and
  save the array to `<workspace>/original/computed.json` — exact per-element values to
  map onto Tailwind. **Capture it at the SAME viewport width you validate at (1280).**
- **Screenshot the original** (full page + per section, and one narrow-width shot for
  breakpoint checking) to `<workspace>/original/`, as the human-eye yardstick.

Real capture has several non-obvious failure modes (tool-output content filter,
`resize_window` not shrinking the window, Chrome blocking the second download). Read
`references/capture-notes.md` before capturing — it has the workarounds.

### 2. Detect the styling system, then branch

Before touching anything, check what the page is built with. Grep the markup in
`clone/index.html` for hashed selectors:
`grep -oE '(css-[a-z0-9]+|sc-[a-zA-Z]+|jsx-[0-9]+|[A-Za-z]+_[A-Za-z0-9]{5,}__?[A-Za-z0-9]+)' clone/index.html`
(the last alternative catches CSS-Modules names like `Button_button__3xYz1`).

- **Already Tailwind** — utility classes present (`grid`, `lg:grid-cols-2`,
  `bg-[#c1ff72]`, `font-sans`) and the grep returns nothing → **2a, rehost mode**. The
  markup already IS clean Tailwind; there's nothing to translate.
- **Hashed / CSS-in-JS** — classes look like `css-1a2b3c`, `sc-bdfBwQ`, `jsx-1234`, or
  styling lives in a compiled stylesheet keyed by opaque selectors → **2b, translate
  mode**. This is the case the skill is built for.
- **Mixed** — Tailwind utilities *and* hashed selectors together (common with
  component libraries): treat as **2b**, but leave the already-Tailwind portions as-is
  and only translate the hashed ones.

#### 2a. Rehost-on-CDN mode

Follow `references/rehost.md`. Strip the inlined compiled-Tailwind `<style>`, keep the
markup, add the Tailwind CDN + the real font link. Produces a much smaller
`<workspace>/tailwind/index.html` with byte-identical classes. `computed.json` is not
needed for this mode.

#### 2b. Translate mode

Follow `references/rewrite.md`, mapping with `references/mapping.md`. Section by
section, turn the real markup + CSS + `computed.json` values into semantic markup with
Tailwind classes. Produces one self-contained `<workspace>/tailwind/index.html`
(Tailwind CDN is fine for a preview): generated hashes stripped, fonts and assets
preserved.

### 3. Validate in a loop — one axis: fidelity

Follow `references/validate.md`. Render with `scripts/shoot.py`, compare against the
original captures section by section (and at a narrow width for breakpoints), and turn
every difference into a specific class fix. Loop until it matches or ~5 rounds pass
without progress, then report honestly what's still off.

There is exactly one axis: does it look like the original? Do **not** improve
anything — no new type scale, no palette cleanup, no spacing tweaks beyond matching.
A change that makes the rewrite diverge from the original is a regression, not a win.

## What this can and can't do

- **Static.** Scripts are stripped in the extract, so JS-driven behaviour freezes at
  capture state. Scroll/expand everything before capturing.
- **Arbitrary values are expected.** A bespoke design won't sit on Tailwind's default
  scale; faithful classes like `text-[17px]` and `bg-[#0b5fff]` are correct here.
  Accuracy first; normalising onto tokens is a separate later pass if the user wants.
- **Approximate where the loop can't see.** Rare pseudo-states or JS-injected styles
  may not survive. Byte-exact isn't the goal — clean-and-identical-looking is. For
  byte-exact, use `page-cloner`.

## Notes

- **Real numbers, not screenshots.** Every class should trace to a value in
  `computed.json` or a rule in `clone/index.html`. If you're guessing from a PNG,
  you'll drift.
- **Don't skip the loop.** The first rewrite is a draft; the comparison is what makes
  it faithful.
- **Be specific in fixes.** "Spacing off" isn't a fix. "Section padding is `py-10`,
  computed.json says 48px → use `py-12`" is.
