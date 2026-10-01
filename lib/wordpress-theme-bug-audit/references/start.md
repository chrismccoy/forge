# Section 0: find the theme, intake, and the start confirmation

Read this in full before section 0, and again after any context compaction before continuing it. `<scripts>` is the `scripts/` folder beside `SKILL.md` (`${CLAUDE_PLUGIN_ROOT}/lib/wordpress-theme-bug-audit/scripts`). The rule "Never start without answers" in `SKILL.md` applies to every question below.

## Find the theme

Before anything else, work out which theme to audit. A theme is a folder whose `style.css` starts with a comment block containing `Theme Name:`.

- **Where to look:** check the current directory first. If it isn't a theme, look for theme folders below it, up to three levels deep, skipping `node_modules/`, `vendor/`, and `.git/`: this covers being started in a `themes/` folder, `wp-content/`, a WordPress root, or a repository that keeps the theme in a subfolder (`theme/`, `src/`, `<slug>/`). Also check whether the current directory is inside a theme (a parent folder with a theme `style.css`).
- **One theme found:** use it, and treat its folder as the theme directory everywhere below.
- **Several found, or none:** stop and ask the user which to audit, listing each candidate's path and `Theme Name`. Never guess, and never audit more than one theme per run.
- **A zip file instead of a folder:** if the only candidate is a theme zip, unzip it into a scratch folder outside the current directory, audit that copy, and say in the report that deliverables were written to the copy, with its path.
- **Child theme:** if `style.css` has a `Template:` header, it's a child theme and its parent must be installed on the test site. Look for the parent folder beside it (same parent directory, folder name equal to `Template:`). If it isn't there, stop and ask the user for its path. The audit covers the child theme's own files; read the parent only where the child overrides, extends, or calls into it, and report parent bugs separately under a `## Parent theme` heading at the end of the bug file.
- **Record the theme's identity** from its files: `Theme Name`, folder name (the slug WordPress uses), `Text Domain` (and whether it matches the slug), `Version`, `Requires at least`, `Tested up to`, `Requires PHP`, `Template` (child themes), `License`, and whether `readme.txt` agrees with `style.css`. Record whether it's a classic, block, or hybrid theme (`templates/index.html` means block), whether it has a build step (`package.json`, `composer.json`), and whether it's a git repository, with the current branch and any uncommitted changes.
- **Announce it** before starting section 1: one short block with the theme's name, version, path, type, and the numbers above, so the user can stop the run if it picked the wrong theme. A mismatch between headers (a `Text Domain` that isn't the slug, `readme.txt` and `style.css` disagreeing on versions) is a Low bug.
- Every later mention of "the theme directory", "the theme's slug", and "the theme's `audit/` folder" mean this theme.

## Resume check

Right after announcing the theme, look for `<work>/state.json`. If it records a finished run, or a run from a different prompt version that you won't resume, move everything in `<work>` except `tools/` into `<work>/_prev-<YYYYmmdd-HHMM>/` without reading it, and start fresh. If it exists and not every step is finished, show when it was last written, which steps are done, and whether the prompt version or the theme's content hash has changed since, then ask one multiple-choice question: "Resume" (recommended only if neither changed), "Restart" (recommended if either changed; it clears `<work>` except `tools/`), or "Cancel". On "Resume", reuse the intake answers and file names from the state file, skip the intake questions, still ask the confirm question below, and carry on from the first unfinished step; if the test site from `<tmp>` is gone, rebuild it and rerun the saved probe scripts in `<work>/probe/` before continuing. Anything other than a clear choice means cancel.

## Intake questions

Right after announcing the theme, ask the user these questions, then wait for the answers before starting section 1. Use your multiple-choice question tool if you have one (in Claude Code, `AskUserQuestion`: up to 4 questions per call, so ask questions 1–4 in one call and questions 5–8 in a second), with the recommended option first and marked "(Recommended)"; the tool adds an "Other" option for free text. Without such a tool, ask them as one numbered list with lettered options and wait for the reply. Fill in the detected values where the options mention them. If the command's arguments already answer a question, don't ask it.

1. **Scope:** how much of the audit to run?
   - Full audit (Recommended): every section and step.
   - Standard: skip step 11 (screenshots), step 12 (variations), the oldest-WordPress test in step 13, step 14 (upgrade), and line coverage. The PHP version passes in step 13 still run.
   - Code only: sections 0–2, static analysis, and the build check; no test site.
2. **PHP versions:** which PHP versions do customers run? Each one gets its own pass in step 13.
   - Every minor version from the theme's `Requires PHP` to the newest (Recommended): list them (if the header is missing, say so and start at 7.4).
   - A common hosting spread: 7.4, 8.1, 8.2, 8.3, and 8.4.
   - Versions I'll type, as "Other" (for example "7.4, 8.1, 8.2").
3. **Extra plugins:** test with plugins beyond the theme's own dependencies?
   - Only the theme's dependencies (Recommended).
   - Also common plugins: WooCommerce, Yoast SEO, Contact Form 7, and Jetpack.
   - Plugins I'll list, typed as "Other".
4. **Known issues:** do I have bug reports from customers to compare against?
   - Yes, ask me for them after the audit: don't collect them now, so they can't steer the audit.
   - No.
   (No option is marked recommended for this question.)
5. **Fixes:** what to do once the bug file is written?
   - Ask me which bugs to fix (Recommended): section 6 as written.
   - Report only: stop after section 5, with no fix offer.
6. **Marketplace:** where is the theme sold or listed, so its review rules are checked too?
   - My own site or no marketplace (Recommended if unsure): bugs only.
   - WordPress.org: also check the WordPress.org theme review requirements.
   - ThemeForest / Envato: also check the Envato WordPress theme requirements.
7. **Upgrade test:** which earlier release to upgrade from in step 14?
   - The latest earlier git tag (Recommended when one exists): fill in its name, or say none was found and drop this option.
   - A zip or folder of the previous release, typed as "Other" with its path.
   - Skip the upgrade test.
8. **WordPress versions:** which is the oldest WordPress to test against?
   - The theme's `Requires at least` (Recommended): fill in the value (if the header is missing, say so and use the current release minus two).
   - A version I'll type, as "Other".

## Confirm before starting

Once every question is answered, measure the theme cheaply, without reading file contents: the number of files that section 1 will read (after its exclusions), their total lines, and their total size in KB, with a rough estimate of the tokens needed to read them once (bytes ÷ 4), and an estimate for the whole run: about 15,000–20,000 tokens per PHP file for a full audit, and roughly half that for Standard scope (measured on real themes: about 1.9 million tokens for 120 PHP files, and about 6 million for 427). Also measure the theme's total size on disk and list the media folders `bash <scripts>/media-dirs.sh <theme-dir> --report` finds (these are linked, never copied or read, and don't count toward the read estimate or the disk space needed), and check free space on the disk that will hold `<work>` (`df -h`). The audit needs about 2 GB free for tools and test sites, plus room for the theme's code (media folders excluded); if there's less, say so plainly on the confirm question and recommend Cancel until space is freed. Also check, without installing anything yet, which tools and access the audit will have (`bash <scripts>/install-tools.sh` installs the rest after Start): `composer` or PHP able to run a downloaded `composer.phar`, `node` and `npm` (with versions), `java`, Chrome or Chromium, Xdebug or pcov, `git`, `rsync`, Docker (usable only if `docker info` succeeds without `sudo`), and network access (a `curl -sI` to `https://getcomposer.org`, `https://registry.npmjs.org`, `https://downloads.wordpress.org`, and `https://dl.static-php.dev`). For each PHP version from intake question 2, say how step 13 will run it (see PHP versions in `testing-setup.md`): the local PHP, a standalone binary, Docker, or BLOCKED with the reason; and name the primary version, the one the whole audit runs on. List the checks that will be BLOCKED or SKIPPED because of anything missing. Then ask one last multiple-choice question, showing those numbers, the theme's size and free disk space, that list, and the user's answers: "Start the audit?" with the options "Start" and "Cancel". Say plainly that a full audit uses many times the read-once estimate, because files are re-read while testing and the tests produce their own output, and that the theme is split across subagents if it has more than about 100 files. Start section 1 only on "Start". Anything else, including no answer, means cancel: stop as "Never start without answers" says.
