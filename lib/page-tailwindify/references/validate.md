# Subskill — Validate the Tailwind rewrite against the original, in a loop

Goal: prove the Tailwind rewrite renders like the original by looking at both, not by
trusting the translation. One axis — **fidelity**. There is no "make it nicer" axis;
the design is fixed, only the class system changed. A rewrite that looks different is
wrong, not improved.

## The loop

1. **Render and screenshot the rewrite** (`shoot.py` lives in this skill's directory —
   use its absolute path; your working directory is the workspace, not the skill root):

   ```
   python <skill-dir>/scripts/shoot.py <workspace>/tailwind/index.html <workspace>/tailwind/shots/
   ```

   Full-page PNG + one per section. Section slicing is best-effort — if the rewrite
   wraps content in `<main>` or uses `<div>`s instead of `<section>`, the slice count
   may not line up with the original captures. Treat the full-page diff as the
   reliable axis; use section shots as directional zoom-ins.

2. **Compare `tailwind/shots/` against `original/` shots**, section by section:
   - Type: size, weight, family, line-height, letter-spacing matching?
   - Color: text, background, borders, gradients matching the real hex?
   - Spacing: padding, margins, gaps at the right rhythm (the usual translation
     miss — an off-by-one on the spacing scale)?
   - Layout: flex/grid alignment, wrapping, container max-width matching?
   - Radius, shadows, borders present and right?

3. **Resize-check breakpoints.** Re-shoot at a narrow width to confirm the `@media` →
   `md:`/`lg:` translation holds:

   ```
   python <skill-dir>/scripts/shoot.py <workspace>/tailwind/index.html <workspace>/tailwind/shots-mobile/ --width 390
   ```

   Compare against a mobile capture of the original if you took one.

4. **Decide.** Matches → done, go to Present. Otherwise turn each difference into a
   specific class fix in `tailwind/index.html` and repeat from step 1.

Log each round to `<workspace>/rounds/round-N.md` with the exact mismatch and fix.

## Common translation misses

- **Spacing off by one step** → wrong Tailwind number; read the exact px from
  `computed.json` and use the right step or an arbitrary `[value]`.
- **Color slightly off** → snapped to a Tailwind default palette token instead of the
  real hex; switch to `[#hex]`.
- **Font fell back** → the web-font `<link>`/`@font-face` wasn't carried over, or the
  `font-[...]` family name is wrong.
- **Breakpoint wrong** → `@media` mapped to the wrong `sm/md/lg`, or base vs prefixed
  classes swapped (Tailwind is mobile-first: base = smallest screen).
- **Hover/transition missing** → pull the `:hover` rule from the real CSS into a
  `hover:` variant.

Stop after ~5 rounds without progress and report honestly what's still off. Each round
must move the needle; vague diffs stall the loop — name the exact element and change.

## Workspace

```
<workspace>/
├── original/          # screenshots + computed.json (ground truth)
├── clone/index.html   # page-cloner's faithful extract (the spec)
├── tailwind/
│   ├── index.html     # the Tailwind rewrite, edited in place
│   └── shots/
└── rounds/round-N.md
```

## Present

Give the user `tailwind/index.html` plus a one-line note on any remaining gaps and on
how many arbitrary `[values]` were needed (a signal of how bespoke the original was).
If you stopped short of a full match, say exactly what remains.
