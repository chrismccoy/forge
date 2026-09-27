# Section 6: offer to fix the theme bugs

Read this in full before offering fixes, and only if intake question 5 didn't choose "Report only".

Skip this section if I chose "Report only" at intake question 5. Otherwise, only after the report, and only if the bug file lists at least one bug: ask me whether to fix them. Offer these choices: fix all of them, pick which ones, or fix none. If I say none, or don't answer, stop there; don't create the changes file or change any theme file beyond the section 5 deliverables.

If I agree (all, or the ones I pick):

- **Confirm each bug first.** Before asking or fixing anything, re-read the code behind each selected bug and reproduce it where you can. If the report turns out to be wrong, or the behaviour is clearly intentional, mark it `Not a bug.` with the reason and ask nothing about it.
- **Decisions first.** If several bugs turn on one question about what the theme is meant to be (a one-page theme that renders nothing else, a deliberately stripped-down feature set), ask that question first, on its own, and apply the answer to all of them rather than asking each bug separately. Then ask about every remaining bug whose fix needs a choice, one bug at a time: a design or wording change, removing versus finishing a half-built feature, which of two defaults wins, or a behaviour the theme may have chosen on purpose. Give 2–4 concrete options, put your recommendation first and mark it "(Recommended)", and always include "Leave as is". Bugs with one obvious fix need no question; if you're unsure whether a fix is obvious, ask. Choose the recommendation this way:
  - Keep the theme's current look and wording, and fix the mechanism behind the bug.
  - A half-built feature with placeholder defaults and no front-end output: recommend removing its settings and dead code. One that is clearly part of the theme's purpose and only missing its output: recommend finishing it with the markup and classes the theme already uses.
  - When two defaults disagree, recommend the one visitors currently see, shared through one function or array.
  - Behaviour that hides or removes core WordPress features on purpose is a product decision: recommend leaving it, with the fix as an alternative.
  - Accessibility, HTML validity, escaping, and nonce or capability problems: recommend fixing them.
  - Stale built CSS or JS: recommend fixing the source or build config and listing the rebuild, never editing the built file.
- **Keep the work separate.** Never stash, reset, or discard anything, and never move `audit/`.
  - In a git repository: if there are uncommitted changes outside `audit/` and `.distignore`, list them and ask me before continuing. If a `fix/theme-audit-bugs` branch already exists, stop and ask. Otherwise run `git switch -c fix/theme-audit-bugs` (the untracked `audit/` comes along) and leave everything uncommitted.
  - Without git: before changing anything, save a backup, including `audit/`, to `<theme's parent folder>/<slug>-backup-before-fixes-<YYYYmmdd-HHMM>.tar.gz` (never under `$TMPDIR` or `<tmp>`, which tearing a site down deletes), check it with `tar tzf`, and give its absolute path in the changes file.
- **How to fix:**
  - Make the smallest fix that keeps the theme's current look and wording, in the theme's own code style.
  - Add no new code comments or docblocks. Only reword an existing comment that a fix makes wrong.
  - If the theme has a build step (section 1), edit only its source files, never the built output. Run the build in the `<tools>/build/` copy after the fix to prove it builds and that the output contains the change, and list the rebuild command in Still to do. If it has none, its CSS and JS files are the source; edit them directly.
  - Run phpcs on every changed PHP file before and after; the fix must add no new violations. Reuse the phpcs install in `<tools>` (reinstall it the same way if it's gone). Use the theme's `phpcs.xml` or `phpcs.xml.dist` if it has one; otherwise use the WordPress standard minus the rules the theme's own code breaks in most of its PHP files, each evidenced by a count from the theme's own files. Use the same ruleset both times, and compare message by message, not just totals, so a violation you added isn't hidden by one you removed.
- **Test the fixes.**
  - Before editing, build a test site from the unchanged theme with `new-site.sh`, replay the probe scripts from `<work>/probe/`, and reproduce each bug you can.
  - After fixing, build a second site with `new-site.sh` from the fixed theme (the site gets a fresh copy of it). Where a fix touches CSS or JS that has a build step, build it in `<work>/build/<same-folder-name>/` with the theme's own command and build the site from that copy instead. Tear sites down with `site-down.sh`, and delete the build copy when the fix step is finished.
  - Prove each fix with `wp eval`, curl, and grep. For fixes with a visible effect, also take `shot` screenshots at 1440 and 390 wide, saved under `<work>/fix-shots/` (never under `<tmp>`, which tearing a site down deletes); if `shot` exits 3, skip them and write "screenshots SKIPPED: <reason>" in that bug's Done bullet. Replace any evidence screenshot for a fixed bug with the after shot, named `<bug-number>-<page>-<width>-fixed.png`.
  - `php -l` every changed PHP file. There must be no new PHP warnings or notices in the HTML, `<tmp>/server.log`, or `debug.log`. Read `debug.log` before `teardown`, which deletes it.
  - Tear both sites down when done.
- **Update the bug file as you go** (never an earlier audit's files):
  - Every bug gets a status after its number: `### 3. Fixed. <title>`, `Not fixed.` (with the reason), or `Not a bug.` (with why the report was wrong). A fix that only takes effect after the rebuild is `Fixed (needs rebuild).`; a bug whose only fix is the rebuild itself is `Not fixed. Needs rebuild.` Bugs I didn't pick: `Not fixed. Not selected.` Bugs where I chose "Leave as is": `Not fixed. Decision (yours): leave as is.`
  - Add a last bullet `- **Done:** <what changed, in which file>`, starting with "Decision (yours): …" where I chose an option.
- **Create the changes file:**
  - Start with `# Changed files`, one line saying which branch the changes are on (or, without git, the backup's path) and that nothing is committed, and the number of files changed (and which bugs were not fixed).
  - Then a `| File | Bug | Change |` table with one row per changed file.
  - End with `## Still to do`: the rebuild command and what it adds or drops, strings that need a translation update, anything I must check by hand, and whatever I need to do before committing.
- **Report back** with fixed, not-fixed and not-a-bug counts, one line per bug, and the still-to-do list.

Do not commit.
