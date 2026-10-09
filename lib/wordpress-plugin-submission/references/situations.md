# Special Situations

Load this file for POST-APPROVAL scope, or when the plugin is a block plugin or targets multisite. Reuse the G# table, statuses, and evidence labels from SKILL.md. Tags follow the convention in `official-sources.md`.

## Updates to an approved plugin

- Code pushed to SVN goes live immediately; there is no pre-review gate. **[verified 2026-10-09, FAQ]** All guidelines still apply, and violations can lead to closure.
- Plugin Check runs on all updates; reports are internal, and emailing them to authors is a stated goal. **[verified 2026-10-09, make/plugins 2025-10-29]** The post does not say updates are blocked.
- Check Guideline 14 (avoid frequent commits) and Guideline 15 (increment version for each release): header Version, readme Stable tag, and SVN tag must agree.
- The slug cannot change after approval. **[verified 2026-10-09, FAQ]**

Verdict: use the 06 rules, reading READY AFTER FIXES / READY TO SUBMIT as "ready to release after fixes" / "ready to release". Output: FULL GATE contract. Delivery: commit to SVN with a new version tag.

## Closures and reopen requests

- Plugins are closed for guideline violations, security issues, or author request. **[verified 2026-10-09, FAQ]**
- Security closure: fix the issue, then reply to the closure email. Reopening is usual unless further security or severe guideline issues exist. **[verified 2026-10-09, FAQ]**
- Plugins closed for a security vulnerability must pass Plugin Check's Security category before relisting; treat Security-category ERRORs as PC-BLOCKING for these reopen requests. **[verified 2026-10-09, make/plugins 2024-10-01]**
- Guideline closure: outcome depends on severity and nature of the violation. **[verified 2026-10-09, FAQ]**
- Every reopened plugin must pass a current standards and security review. **[verified 2026-10-09, FAQ]** Run a FULL GATE on the fixed code before replying.
- Author-requested closures are not intended to be reopened a month later. **[verified 2026-10-09, FAQ]**
- Accidental closure: email the Plugins team asking for reopening. **[verified 2026-10-09, FAQ]**

Map each point in the closure email to a G# row: BLOCKER-FIXABLE until the supplied fixed code shows it resolved, then PASS-EVIDENCED (CONFIRMED). Run the full review on the fixed code. Output: FULL GATE contract, verdicts read as "ready to request reopen (after fixes)" or "do not request reopen". Delivery: commit the fix to SVN with incremented Version, Stable tag, and SVN tag (Guideline 15), then reply to the closure email stating each fix and where it is committed. Never argue for reopening on goodwill.

## Block plugins

First establish the target. The block guidelines bind only Block Directory submissions; block plugins that do not meet them may still be submitted to the main Plugin Directory. **[verified 2026-10-09]**

- Target Block Directory: block-guideline misses are BLOCKER-FIXABLE.
- Target main directory only: block guidelines are NOT-APPLICABLE (REVIEW-RISK at most if the user wants a later Block Directory listing).
- Target unknown: ask under NEXT EVIDENCE NEEDED.

Fetch the Block Specific Plugin Guidelines (URL in `official-sources.md`) in addition to the Detailed Plugin Guidelines. Titles checked 2026-10-09:

1. Block plugins are for the Block Editor (no UI outside the editor).
2. Block plugins are separate blocks (one top-level block; children only when necessary).
3. Names reflect the block's purpose; 3a. block names unique and namespaced with an author or slug prefix.
4. Must include `block.json` with `name`, `title`, at least one of `script` or `editorScript`, and at least one of `style` or `editorStyle`.
5. Must work independently of other plugins and themes.
6. Block plugins should work seamlessly: free, no login or extra setup.
7. Server-side code kept to a minimum; prefer the REST API.
8. No advertisements or promotional notices.

Delivery and recheck for a Block Directory listing: confirm the current channel on the live Block Directory pages before advising **[verify]**; do not guess it.

These apply to Block Directory listings. A plugin that only ships blocks inside the main directory still needs `build/` source available under Guideline 4.

## Multisite

No dedicated official multisite review page was verified. Treat these as engineering REVIEW-RISK checks, not rules, unless a live source is cited **[verify]**:

- network activation path and per-site activation both work;
- capability checks use the right scope (`manage_network_options` vs `manage_options`);
- uninstall cleans up per site, not only on the main site.
