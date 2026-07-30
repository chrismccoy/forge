# Subskill 2 — Validate the clone against the original, in a loop

Goal: prove the clone renders like the original by looking at both side by side, not
by assuming the extraction was perfect. One axis only here — **fidelity**. There is
no "make it prettier" axis; a clone that looks different from the original is wrong,
not improved.

## The loop

1. **Render and screenshot the clone.** Run (`shoot.py` lives in this skill's
   directory — use its absolute path, since your working directory is the workspace,
   not the skill root):

   ```
   python <skill-dir>/scripts/shoot.py <workspace>/clone/index.html <workspace>/clone/shots/
   ```

   It writes a full-page PNG plus one per top-level section — the same shape as the
   original captures, so they compare directly. If the clone needs network for
   CORS-blocked CSS, keep the machine online while shooting.

2. **Compare clone shots against `original/` shots.** Judge fidelity on concrete
   evidence, section by section:
   - Every section present, in the right order, right proportions?
   - Fonts, colors, spacing, and images matching the original?
   - Nothing collapsed, overflowing, missing, or unstyled (a flash of unstyled
     content usually means a stylesheet failed to inline — check for
     `/* could not inline ... */` comments in `index.html`).

3. **Decide.** If it matches, done — go to Present. If not, turn each difference into
   a specific edit to `clone/index.html` and repeat from step 1.

Write a short pass/fail note per round to `<workspace>/rounds/round-N.md` with the
exact differences and fixes, so the progression is visible.

## Fixing common misses

- **Whole section unstyled / wrong** → a stylesheet didn't inline (CORS). Either add
  its absolutised `<link>` back, or paste the needed rules into an inline `<style>`.
- **Missing images** → check the `src`/`srcset` absolutised correctly; some sites
  lazy-load via `data-src` — copy `data-src` into `src`.
- **Missing content** → it rendered after capture. Re-capture with a longer wait /
  full scroll (back to `references/capture.md`), don't hand-type the content.
- **Fonts fell back** → the `@font-face` / Google Fonts link didn't resolve; keep the
  original font `<link>` absolutised in `<head>`.

Stop after ~5 rounds without meaningful progress and tell the user honestly what's
still off. Each round must move the needle; if it isn't, the diff is too vague — name
the exact element and the exact change.

## Track the workspace

```
<workspace>/
├── original/          # source screenshots (ground truth)
├── clone/
│   ├── index.html     # the extracted clone, edited in place each round
│   └── shots/         # screenshots of the current clone
└── rounds/
    ├── round-1.md
    └── ...
```

## Present

Give the user `clone/index.html` plus a one-line note of any gaps (needs network for
X stylesheet, interactivity is static, etc.). If you stopped short of a full match,
say exactly what remains.
