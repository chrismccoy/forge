# Sections 4 and 5: confirm, verify, and report

Read this in full before section 4. Screenshots and bug numbers are final only after the independent check.

## 4. Confirming a bug

- Every bug in the report is either reproduced on the test site (say how) or proven from the code alone with the exact path that fails (say which). Its Confidence bullet says which: `Reproduced`, `Proven from code`, or `Unconfirmed` (with the reason it couldn't be proven).
- Probe data that was itself invalid is not a theme bug. If a failure goes away with a valid value, drop it.
- Report each root cause once, listing every place it shows up, rather than one bug per template, and never fold unrelated root causes into one catch-all entry (except unused code, grouped by feature as CODE-03 says).
- Report every real finding, whatever its severity. If you decide a candidate isn't a bug, record it in the coverage file's `## Not reported` table with the check ID, `file:line`, what you saw, and why it isn't a bug, so a later run can re-evaluate it.
- **Independent check.** Every bug goes through this check, including bugs added later from a comparison with an earlier bug list or customer reports (check those in a second, smaller round). When the draft bug file is complete, have fresh subagents (a few bugs each, with no access to your reasoning, only the bug entry and the theme) try to disprove each bug: re-read the code, look for a guard, fallback, or caller that makes it impossible, and try the reproduction on the test site if it's still running. Each returns `Holds`, `Disproved` (with the evidence), or `Different` (the bug is real but the entry is wrong: another cause, place, or severity). Drop disproved bugs, correct the others, and count all three in the report. Without subagents, do this yourself after finishing the draft, one bug at a time, arguing against each. Run this check before the comparisons in section 5.
- **Severity.** Rate every bug by what triggers it and what it breaks, using these levels, so every run and subagent gives the same bug the same rating:
  - **Crashes and data loss:** a fatal error, white screen, or lost or corrupted data that a visitor or user reaches through default settings, a normal action, a documented setting, a core feature (a core block, the Customizer, quick edit), or any PHP or WordPress version the theme says it supports (a whole-site fatal on a supported PHP version is a crash, not an unusual setup); or a security hole that lets a visitor or a contributor read private data, change data, or run script or code.
  - **High:** the same kinds of failure when they need an uncommon but supported setup (a particular host or PHP build, a page cache, a common plugin); a feature the theme advertises that doesn't work for anyone; a security weakness that needs an editor or administrator, or an unusual condition; an update that breaks or changes existing sites.
  - **Medium:** a feature broken only for some settings, content, screen sizes, or browsers; wrong results users notice; abuse that skews counts or rankings; accessibility failures that block a task; performance problems that grow with content.
  - **Low:** cosmetic problems, edge cases with a workaround, confusing messages, unused code, and accessibility or standards problems that don't block a task.
  - Two cases sit one level lower than the table suggests: a fatal error that only happens in a background task (a cron event, a WP-CLI command) with no page or screen breaking, and lost input the user can simply re-enter on the same screen and would notice at once (a single field that didn't save), are High, not crashes and data loss. Lost or corrupted data the user can't easily see or restore stays in crashes and data loss.
  - When a bug fits two levels, take the higher one, and say in its What breaks bullet which trigger and impact set the level.

## 5. Deliverables

Everything goes in the theme's `audit/` folder. Choose the file names before writing anything. If `audit/` already holds files from an earlier audit, never edit, move, or delete them: add the date and time to every new file name instead (`BUGS-<YYYYmmdd-HHMM>.md`, and so on).
- **Bug file:** `audit/BUGS.md`.
- **Coverage file:** `audit/COVERAGE.md`.
- **Evidence screenshots:** `audit/screenshots/` (a dated folder name if that exists).
- **Changes file** (section 6 only): `audit/CHANGED.md`.

```
audit/
  BUGS.md          the bug file
  COVERAGE.md      every file, function, entry point, and check, and how each was checked
  screenshots/     evidence for visual bugs only (omitted if there are none)
  CHANGED.md       the changes file, only if I agree to fix the bugs (section 6)
```

- The bug file: every bug in the theme.
  - Open with `# <Theme name>: theme bugs` and one line saying how they were found. Group the bugs under these severity headings, in this order, leaving out empty ones: `## Crashes and data loss`, `## High`, `## Medium`, `## Low`.
  - Number the bugs in one sequence across the whole file: `### 1. <short title>`.
  - Give each bug these bullets, in this order: `- **Where:** file:line` (every place, for one root cause); `- **Check:** <check ID>`; `- **Affects PHP:**` the versions it appears on (`all tested`, `8.1 and later`, `7.4 only`), from step 13 and static analysis; `- **What breaks:**` for a visitor or admin, in technical terms; `- **Customer symptom:**` what a customer would write in a support ticket (for example "my like button stopped working after a day"), so bugs can be matched to tickets; `- **Reproduce:**` numbered steps on a fresh site, or the code path when it can't be reproduced; `- **Confidence:**` from section 4; and `- **Fix:**` with a suggested fix.
  - Open the file with the prompt version and the date of the run on the line after the title.
  - Write "None found." if there are none. Don't fix anything yet; section 6 adds each bug's status after its number and a `- **Done:**` bullet if I agree to fixes.
- **Marketplace review:** if intake question 6 chose a marketplace, add a `## Marketplace review` section after the severity groups, numbered `M1`, `M2`, and so on, with the same bullets, for rule failures that aren't also bugs.
- **Comparison with an earlier bug list:** if `audit/` holds a bug file from an earlier audit, or the message that started this run names an earlier bug list, read it only after this run's bug file is finished, and end the bug file with a `## Compared with <earlier file>` section. It holds a `| Earlier # | Title | This audit # | Result |` table with one row per earlier bug, where Result is one of: `Found by both`; `Already fixed` (the earlier file marks it fixed and the code confirms it); `Not a bug` (re-checked, and the earlier report is wrong, with why); or `Missed by the audit`. For every missed bug, re-check the code: if it's real, add it to the bug file as a new numbered bug under its severity, and say in the Result why the audit missed it (the file wasn't read, it was read but not flagged, or no step reached that code). Close with one line counting bugs found only by this audit. Never change the earlier file.
- **Known issues:** if I answered yes to intake question 4, ask me for the customer reports only after the bug file and any comparison above are finished, and save them to a scratch file outside the theme. Then end the bug file with a `## Compared with customer reports` section: a `| Report | Audit # | Result |` table with one row per report, where Result is `Found by the audit`, `Missed by the audit` (then investigate it now, add it as a new numbered bug if it's real, and say why the audit missed it), `Not reproducible` (with what you tried), or `Not a theme bug` (for example a plugin, hosting, or user-setting problem, with the evidence).
- The coverage file: open with `# <Theme name>: audit coverage`, the prompt version and run dates, and a totals line (files read and excluded; functions and entry points `Tested`, `Read only`, and `Unused`; checks run, not applicable, and skipped). Then `## Intake` with the answers; `## Checks`, a `| Check | Outcome | Bugs | Note |` table covering every check ID in section 2 (consecutive IDs with the same outcome and reason may share one row, such as `BLK-01–BLK-14 | Not applicable | 0 | no blocks`; every ID that found a bug gets its own row), where Outcome is `Checked`, `Not applicable`, or `Skipped`, and Note gives the reason for the last two; `## Verification`, the counts from the independent check; `## Not reported`, the candidates judged not to be bugs, with reasons (section 4); `## PHP versions`, a `| PHP | How it ran | WordPress | Steps run | Errors | Bugs |` table with one row per version from intake question 2 (the primary one marked), BLOCKED rows included; `## Files`, the manifest with each excluded path and its reason; `## Functions and entry points`, the inventory as a `| Name | Defined at | Runs via | Status | How checked |` table, grouped by file; and `## Scripts`, every enqueued script and style with its handle, where it loads, and whether it loaded without errors; `## Static analysis`, the counts per tool and every result dropped as a false positive, with the reason; and `## Line coverage`, the share of theme lines that ran, per file (or SKIPPED with the reason). Cite the bug number in the How checked column where a row led to a bug.
- The literal line `audit/` added to the theme's `.distignore` if it isn't there already (create the file if it doesn't exist), so the folder stays out of distributed theme zips. If the theme is packaged another way (`.gitattributes` `export-ignore`, a release workflow, a build script), say in the report that `audit/` must be excluded there too, with the exact line to add; don't edit those files.
- A report that includes:
  - The coverage totals from the coverage file, confirmation that no file or function was left unread, and the count of check IDs checked, not applicable, and skipped.
  - The data model tables, with the code and secret fields that were left untouched.
  - What the theme doesn't have, so its checks were skipped.
  - The test results with real numbers (pages fetched, fields checked, entry points run, static analysis results kept and dropped, JS and accessibility errors, line coverage), and any BLOCKED or SKIPPED steps with the reason.
  - Which audit tools were installed, with versions, and which were missing.
  - The names of the audit files you wrote, and a summary of the bug file with the count per severity, plus the comparison totals if there was an earlier bug list.
