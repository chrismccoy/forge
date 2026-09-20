# Step 6 - offer to fix the theme bugs

This runs only after the report, only when `demo/BUGS.md` lists at least one bug, and
only if the developer says yes. Nothing in the theme changes otherwise.

Only after the report, and only if `demo/BUGS.md` lists at least one bug: ask the developer whether to fix them. Offer these choices: fix all of them, pick which ones, or fix none. If the answer is none, or there is no answer, stop there; don't create `demo/CHANGED.md` or change any theme file beyond the deliverables in `SKILL.md`.

If the developer agrees (all, or a chosen subset):

- **Confirm each bug first.** Before asking or fixing anything, re-read the code behind each selected bug and reproduce it where you can. If the report turns out to be wrong, or the behaviour is clearly intentional, mark it `Not a bug.` with the reason and ask nothing about it.
- **Decisions first.** If several bugs turn on one question about what the theme is meant to be (a one-page theme that renders nothing else, a deliberately stripped-down feature set), ask that question first, on its own, and apply the answer to all of them rather than asking each bug separately. Then ask about every remaining bug whose fix needs a choice, one bug at a time: a design or wording change, removing versus finishing a half-built feature, which of two defaults wins, or a behaviour the theme may have chosen on purpose. Give 2–4 concrete options, put your recommendation first and mark it "(Recommended)", and always include "Leave as is". Bugs with one obvious fix need no question; if you're unsure whether a fix is obvious, ask. Choose the recommendation this way:
  - Keep the theme's current look and wording, and fix the mechanism behind the bug.
  - A half-built feature with placeholder defaults and no front-end output: recommend removing its settings and dead code. One that is clearly part of the theme's purpose and only missing its output: recommend finishing it with the markup and classes the theme already uses.
  - When two defaults disagree, recommend the one visitors currently see, shared through one function or array.
  - Behaviour that hides or removes core WordPress features on purpose is a product decision: recommend leaving it, with the fix as an alternative.
  - Accessibility and HTML validity problems: recommend fixing them.
  - Stale compiled CSS: recommend fixing the source or build config and listing the rebuild, never editing the built file.
- **Keep the work separate.** Never stash, reset, or discard anything, and never move `demo/`.
  - In a git repository: if there are uncommitted changes outside `demo/` and `.distignore`, list them and ask the developer before continuing. If a `fix/demo-audit-bugs` branch already exists, stop and ask. Otherwise run `git switch -c fix/demo-audit-bugs` (the untracked `demo/` comes along) and leave everything uncommitted.
  - Without git: before changing anything, save a backup, including `demo/`, to `<theme's parent folder>/<slug>-backup-before-fixes-<YYYYmmdd-HHMM>.tar.gz` (never under `$TMPDIR` or `<tmp>`, which `teardown` deletes), check it with `tar tzf`, and give its absolute path in `demo/CHANGED.md`.
- **How to fix:**
  - Make the smallest fix that keeps the theme's current look and wording, in the theme's own code style.
  - Add no new code comments or docblocks. Only reword an existing comment that a fix makes wrong.
  - If the theme has a CSS build step (see `${CLAUDE_PLUGIN_ROOT}/lib/wp-demo-content/references/data-model.md`), edit only its source files, never the built output, and list the rebuild command in Still to do. If it has none, its CSS files are the source; edit them directly.
  - Run phpcs (the same ruleset as step 3) on every changed PHP file before and after; the fix must add no new violations. The ruleset has to be the same one both times, or the comparison means nothing: against the plain WordPress standard, a theme whose own style breaks a dozen rules reports every line you touch as new violations. Compare message by message, not just totals, so a violation you added isn't hidden by one you removed.
  - If a fix changes something the importer writes or reads (a renamed or removed setting, a new field), update `demo/demo-import.php` to match.
- **Test the fixes.**
  - Before editing, build a test site from the unchanged theme with the setup script in `setup-test-site.md`, import the demo, and reproduce each bug you can.
  - After fixing, build a second site. Point it at the real theme, except where a fix touches CSS that has a build step: then point it at a copy built with the theme's own command, placed at `<scratch>/<same-folder-name>/` so the theme's slug stays the same. `<scratch>` is any directory of your own outside the theme and outside `<tmp>`, which `teardown` deletes; the same one that holds the WPCS install will do. Delete the copy when the fix step is finished.
  - Prove each fix with `wp eval`, curl, and grep. For fixes with a visible effect, also take `shot` screenshots at 1440 and 390 wide, saved under `<tmp>/fix-shots/`; if `shot` exits 3, skip them and write "screenshots SKIPPED: <reason>" in that bug's Done bullet. Those shots are evidence, not deliverables, so they stay out of `demo/screenshots/`.
  - The delivered screenshots are a different matter: a fix that changes how a page looks makes them wrong. When the fixes are done and tested, run the importer's full `seed=1` import on the fixed theme and retake the screenshots from step 11 of `testing.md` of every page a fix changed, at the same widths. Delete the pair for any page a fix removed, and say in `demo/CHANGED.md` which ones you retook or deleted. If an overlay that was broken before now works, bypass it the way step 11 says.
  - `php -l` every changed PHP file. There must be no new PHP warnings or notices in the HTML, `<tmp>/server.log`, or `debug.log`. Read `debug.log` (and copy anything it holds) before `teardown`, which deletes it; a line WordPress core writes from `wp-includes/` is not the theme's, but say so in the report rather than leaving it unexplained.
  - If you changed the importer, follow the step 12 rerun rule in `testing.md` on the second site, starting from an empty site.
  - Tear both sites down when done.
- **Update `demo/BUGS.md` as you go:**
  - Every bug gets a status after its number: `### 3. Fixed. <title>`, `Not fixed.` (with the reason), or `Not a bug.` (with why the report was wrong). A fix that only takes effect after the CSS rebuild is `Fixed (needs CSS rebuild).`; a bug whose only fix is the rebuild itself is `Not fixed. Needs CSS rebuild.` Bugs the developer didn't pick: `Not fixed. Not selected.` Bugs where the developer chose "Leave as is": `Not fixed. Decision (developer's): leave as is.`
  - Add a last bullet `- **Done:** <what changed, in which file>`, starting with "Decision (developer's): …" where the developer chose an option.
- **Create `demo/CHANGED.md`:**
  - Start with `# Changed files`, one line saying which branch the changes are on (or, without git, the backup's path) and that nothing is committed, and the number of files changed (and which bugs were not fixed).
  - Then a `| File | Bug | Change |` table with one row per changed file, including `demo/demo-import.php` if you changed it.
  - End with `## Still to do`: the CSS rebuild command and what it adds or drops, strings that need a translation update, anything the developer must check by hand, and whatever they need to do before committing.
- **Report back** with fixed, not-fixed and not-a-bug counts, one line per bug, and the still-to-do list.

Do not commit.
