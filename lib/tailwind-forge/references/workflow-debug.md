# Tailwind CSS Debug Workflow

**Contents:** Triage Order · Report the Fix

Diagnose Tailwind problems in this order. Each step links to a section heading in debugging.md. Stop at the first step that explains the symptom.

## Triage Order

1. **Check for an exact error message first.** If the build, browser console, or editor shows one, match it in "Error Messages".

2. **Classify the symptom in DevTools.** Inspect the element and check whether the rule is missing, crossed out, or active. See debugging.md, "Classes Not Applying".

3. **Confirm the build runs.** Check that `@import "tailwindcss";` is in a `.css` entry imported by the app, and that exactly one of `@tailwindcss/vite` or `@tailwindcss/postcss` is configured. See "PostCSS and Vite Setup (v3 to v4)".

4. **Rule missing: check class names.** Search the source for interpolated class strings (`bg-${...}`). See "Dynamic Class Names".

5. **Rule still missing: check scanning.** Look for files outside the project root, gitignored packages, or monorepo layouts. See "Content Detection and @source".

6. **Confirm with compiled output.** Compile once and grep for the class. See "Inspecting Generated CSS".

7. **Rule crossed out: check layers.** Look for unlayered custom CSS or third-party styles. See "Cascade Layers and Specificity".

8. **Rule active but looks wrong after upgrading.** Check border color, ring, hover on touch, variant order, `space-*`, button cursor, and placeholder. See "v4 Behavior Changes".

9. **Feature-specific failures:**
   - `dark:` not toggling: "Dark Variant Issues".
   - `prose` or form styles: "Plugin Issues".
   - `@apply` failing in `<style>` blocks or CSS modules: "Framework @reference Errors".
   - Responsive variant not matching a parent's width: "Classes Not Applying", which links to container queries.

10. **Changes not showing up.** Restart the dev server and clear caches. See "HMR and Cache".

11. **Editor-only problems** (no completions, `@theme` flagged): "IntelliSense".

## Report the Fix

Give the user:

1. The diagnosis, naming the triage step that found it.
2. The root cause in one sentence.
3. The minimal change (file and code).
4. How to verify: the class appears in compiled CSS and DevTools shows the rule active.

Use the "Checklist" in debugging.md for a final pass when the cause is still unclear.
