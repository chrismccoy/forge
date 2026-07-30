# Subskill — Rehost-on-CDN mode (already-Tailwind pages)

Use this branch when step-2 detection finds the page is **already written in Tailwind**
(utility classes present, zero `css-*`/`sc-*`/`jsx-*` hashes). There is nothing to
translate — the markup already IS clean Tailwind. Running the computed.json translation
would just reproduce the existing classes. Instead, rehost.

## What the transform is

The cloner's `clone/index.html` inlines the whole compiled Tailwind stylesheet (often
150KB+). Swap that compiled CSS for the Tailwind CDN, which JIT-compiles the classes
already on the elements. Same classes, a fraction of the size, fully editable.

## Steps

Produce `<workspace>/tailwind/index.html`:

1. **Strip the inlined compiled-Tailwind `<style>` block(s)** from the clone (the big
   150KB+ blocks — measure them; keep any small hand-authored `<style>` if it holds
   non-Tailwind rules).
2. **Keep the body markup verbatim** — it already carries the Tailwind classes.
3. **Rebuild `<head>`:**
   - `<script src="https://cdn.tailwindcss.com"></script>`
   - the page's real web-font `<link>` (lift it from the original `<head>`)
   - a `tailwind.config` mapping any `font-sans` / `font-mono` / custom families the
     markup uses to the real font names
   - a small base rule for `<body>` background/color if the page set them on `<body>`
4. **Verify JIT coverage.** Arbitrary values (`bg-[#c1ff72]`, `text-[17px]`) and modern
   utilities (`size-9`, `backdrop-blur`) all compile under the CDN JIT — no config
   needed for those.

## Done when

`tailwind/index.html` exists, is dramatically smaller than the clone, and has
byte-identical utility classes on the markup. Proceed to `references/validate.md` — it
should render the same as the original on the first pass; the loop just confirms it.
