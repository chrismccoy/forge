---
name: page-cloner
description: Clones a live web page into a single self-contained working HTML file that looks and lays out like the original, then validates the clone against the original in a loop until it matches. Use whenever a user points at a live URL and wants a faithful copy with NO redesign — phrasings like "clone this page to working HTML", "copy this page exactly", "save this page as a standalone HTML file", "make me a working copy of this site", "scrape this page into one HTML file", or "clone this page as-is". Reproduces the real markup, styles, and assets verbatim, keeping the original selectors and raw CSS — it does not restyle, improve, or rewrite anything. For the same look rewritten as clean semantic Tailwind (generated selectors replaced with real utility classes), use page-tailwindify; for a rebuilt and restyled version, use page-redesigner. Requires Claude in Chrome for capturing the source page.
---

# Page Cloner

This skill turns a live web page into one self-contained working HTML file that
reproduces the original faithfully — same layout, same styles, same content — with
**no redesign**. It extracts the page's actual rendered markup and CSS rather than
rebuilding from a screenshot, so the clone matches by construction, then it checks
that match by comparing the clone back against the original and fixing any drift.

The goal is a faithful copy, not an improvement. If the output looks different from
the original in any way that isn't a captured asset failing to load, something went
wrong. Two sibling skills share the capture step but differ in output: use
`page-tailwindify` to keep the exact look but replace the generated selectors with
clean Tailwind classes, and `page-redesigner` to keep the layout but upgrade the
visuals. This skill is the verbatim one — it keeps the original markup and CSS as-is.

## The two parts

1. **`references/capture.md` — capture + extract.** Drive Claude in Chrome to load
   the live URL, screenshot it as ground truth, then run `scripts/extract.js` in the
   page to produce a self-contained HTML document (rendered DOM, inlined CSS,
   absolutised assets, scripts stripped). Save it as the raw clone.
2. **`references/validate.md` — validate in a loop.** Screenshot the clone with
   `scripts/shoot.py`, compare it section-by-section against the original captures,
   and fix any differences. Repeat until it matches.

Read each reference file when you reach that part; don't load them both upfront.

## Workflow

### 1. Capture and extract

Follow `references/capture.md`. Requires Claude in Chrome — if it isn't available,
stop and tell the user; a real clone needs the real rendered page, and guessing from
memory or view-source produces a fake with nothing truthful to validate against.

Output of this step: `<workspace>/clone/index.html` (the raw extraction) and
`<workspace>/original/` screenshots (full page + per section) as ground truth.

### 2. Validate in a loop — this is where fidelity is won

Follow `references/validate.md`. Render the clone with `scripts/shoot.py`, compare it
against the original captures on a single axis — **fidelity** — and turn every
difference into a specific edit to `index.html`. Loop until it matches or ~5 rounds
pass without progress, then report honestly what's still off.

There is only one axis here, unlike page-redesigner. Do not "improve" anything: no
new type scale, no color changes, no spacing tweaks beyond matching the original. A
change that makes the clone diverge from the original is a regression.

## What a faithful clone can and can't do

- **Static, not interactive.** Scripts are stripped, so JS-driven behaviour (sliders,
  tabs, dropdowns, animations) freezes in whatever state the DOM held at capture.
- **May need network.** Same-origin and CORS-readable CSS is inlined; a CORS-blocked
  top-level stylesheet stays as a live `<link>` (a CORS-blocked `@import` is dropped —
  see `references/capture.md`), and images/fonts are referenced by absolute URL rather
  than embedded. Self-contained as one file, but not guaranteed fully offline.
- **Captures what rendered.** Auth-gated or lazy content only appears if it was on
  screen at capture — scroll the full page first (see `references/capture.md`).

If the user needs a fully-offline bundle (every asset embedded as a data URI) or a
production build, note that as a follow-up — this skill's deliverable is one working
preview file.

## Notes

- **Don't skip the loop.** The raw extraction is a draft; the comparison is what
  proves it's a real clone. An extraction that was never checked against the original
  is unverified, not done.
- **Extract, don't retype.** If content or styling is missing, re-capture with a
  longer wait or full scroll — never hand-write the page's content or guess its CSS.
- **Be specific in fixes.** "Looks off" isn't a fix. "Hero background image 404s —
  the `src` kept a relative path; absolutise it to the origin URL" is.
