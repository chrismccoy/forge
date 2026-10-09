# WordPress Plugin Submission

## Mission

Decide whether a built WordPress plugin is ready for WordPress.org review, using current official guidance and plugin evidence rather than generic “best practices.”

**What would a reviewer be able to prove from this ZIP, readme, service model, and current official rules—and what must change before submission?**

SCOPE LOCK: this procedure judges directory readiness and drafts reviewer replies. It does not write or change plugin code. To scaffold a new plugin use `/wp-plugin`; to add a feature or fix code use `/wp-build`; for a general security, performance, and architecture review use `/wp-review`; for a letter grade use `/wp-grade`.

## Request scope

Choose the first that matches. When files arrive with no question, use FULL GATE.

1. **POST-APPROVAL** — the plugin is already approved: an update, a closure email, or a reopen request. Load `${CLAUDE_PLUGIN_ROOT}/lib/wordpress-plugin-submission/references/situations.md`.
2. **RECOVERY** — an earlier gate result exists in this conversation, and new reviewer feedback, guidance, or a revised ZIP arrives.
3. **REVIEW-EMAIL** — a review email for a pending submission arrives, with no earlier gate result.
4. **FOCUSED** — one surface only (for example "check my readme.txt", "is this trialware").
5. **FULL GATE** — submission readiness or a verdict.

For block or multisite plugins under any scope, also load `${CLAUDE_PLUGIN_ROOT}/lib/wordpress-plugin-submission/references/situations.md`.

## Evidence modes

Declare the first that applies:

1. **RESTRICTED** — the Detailed Plugin Guidelines page could not be fetched.
2. **SUMMARY** — no plugin code or readme was supplied; behavior is only described.
3. **EVIDENCE** — otherwise.

Fetch the core set listed in `${CLAUDE_PLUGIN_ROOT}/lib/wordpress-plugin-submission/references/official-sources.md` (Detailed Plugin Guidelines, Common issues, FAQ, readme guide, make/plugins blog) and record each fetch date. Fetch other listed pages only when relevant (for example, Block Specific Plugin Guidelines for a block plugin). If a secondary page fails, mark only its dependent rows NEEDS-EVIDENCE. Without web access, say at the start that the verdict will be INSUFFICIENT EVIDENCE unless a BLOCKER-MODEL row exists, report only code-confirmed defects (cited "(memory, unverified)"), and list what to fetch under NEXT EVIDENCE NEEDED.

A surface that applies but was not supplied (for example, minified JS whose source is "on GitHub" with no URL) is a NEEDS-EVIDENCE row. In SUMMARY mode, list unsupplied Common review surfaces in one grouped "Not supplied" NEEDS-EVIDENCE row. A surface confirmed absent from the ZIP (for example, no readme.txt) is a confirmed finding.

Label the plugin evidence in every 05 row and every 03 trace row:
**CONFIRMED** (seen directly), **SUPPORTED** (inferred from supplied evidence), **UNKNOWN** (not determinable). PASS-EVIDENCED and BLOCKER-* need CONFIRMED or SUPPORTED; UNKNOWN forces NEEDS-EVIDENCE. A reviewer's or closure email's statement about the plugin is SUPPORTED evidence for that row.

## 01 — Submission scope (internal checklist)

Before analysis, establish each surface: name/slug and version; free ZIP contents vs excluded code; premium/add-on relationship; external services; telemetry; bundled libraries and licenses; minified/built files and source; admin notices, upsells, review requests; update/license behavior; readme and headers; Plugin Check output; reviewer email. Mark each present, absent, not supplied, or not applicable. Report it as one line in EVIDENCE STATE.

## 02 — Plugin Check triage

Treat Plugin Check as evidence, not the whole review. Record version ("version: not shown" if absent), categories run, and target. If the output cannot be matched to the supplied ZIP, label derived 05 rows SUPPORTED.

Record:
Check ID → Category → Severity → File:line → Class → Action.

- **PC-BLOCKING** — an ERROR in the Plugin Repo category (new submissions run through it and errors block upload), or any finding tied to a stated requirement.
- **PC-RISK** — likely reviewer question, including Security-category ERRORs not otherwise tied to a stated requirement. Exception: for a reopen request after a security closure, Security-category ERRORs are PC-BLOCKING (see `${CLAUDE_PLUGIN_ROOT}/lib/wordpress-plugin-submission/references/situations.md`).
- **PC-BEST-PRACTICE** — engineering improvement only.
- **PC-CONTEXT** — depends on code path or service model; reclassify once resolved.

A clean report is one line: "No findings — Plugin Check <version>, categories <list>." A clean report does not replace manual review: walk the Common review surfaces in `${CLAUDE_PLUGIN_ROOT}/lib/wordpress-plugin-submission/references/official-sources.md`.

## 03 — Monetization & service boundary

Trace each paid or external feature:

Feature → Local code → Gate/check → Remote work → Unpaid/offline behavior → Data sent → Disclosure → Label.

Test against current guidance on trialware, SaaS, remote code or updates, tracking consent, notices and upsells, credits, licensing, and trademarks. A remote service that only validates a license while features ship locally is not a valid SaaS fix. For freemium plugins also check: no premium-licensed code in the free ZIP; locked pro UI; dismissible upsells; opt-in telemetry and deactivation surveys; `Requires Plugins` on add-ons.

## 04 — Readme & metadata integrity

Two tables:

- **Field check** — Field → Value → Rule → OK/Fix. Use for format rules (short description length, tag count, Stable tag, Tested up to, Contributors, License). A fix tied to a requirement gets a 05 row; a fix for a recommendation only (for example short description over 150 characters) goes in the delta as its own line with G# "—".
- **Claim check** — README SAYS → CODE DOES → IMPACT → FIX. Use where readme text contradicts code. When code is not supplied, skip code comparisons; list only places where the readme contradicts itself.

Do not invent tested versions, rights, privacy guarantees, or service terms.

## 05 — Guideline evidence map

Build last; it consolidates 01–04 and is the only input to the verdict.

ID → Rule/source → Plugin evidence (labelled) → Why it applies → Status → Smallest fix.

Create a row for every PC-BLOCKING finding, every 03 or 04 finding that conflicts with a requirement, every reviewer point, and every NEEDS-EVIDENCE surface. Cite official rules only; Plugin Check IDs are evidence, not rules.

Statuses (exactly one per row; the grouped "Checked, no issue" row is exempt and holds only PASS-EVIDENCED and NOT-APPLICABLE items):

- **PASS-EVIDENCED** — evidence supports the rule.
- **REVIEW-RISK** — likely question, no conflict with a stated requirement. Never blocks.
- **BLOCKER-FIXABLE** — conflicts with a requirement; a bounded code, readme, or packaging change resolves it.
- **BLOCKER-MODEL** — conflicts with a requirement, and the user has stated the only compliant fix is commercially unacceptable.
- **NEEDS-EVIDENCE** — decisive code, docs, terms, or rule text are missing.
- **NOT-APPLICABLE** — rule does not apply.

When a fix may be commercially sensitive and the user has not said, keep BLOCKER-FIXABLE and ask under NEXT EVIDENCE NEEDED.

A reviewer's explicit request governs that submission, even when stricter than fetched guidance: mark it BLOCKER-FIXABLE until supplied code or readme shows it resolved, then PASS-EVIDENCED (CONFIRMED). If the user disputes it, keep BLOCKER-FIXABLE and put the clarification request in the reply.

## 06 — Verdict and delivery

To test NEEDS-EVIDENCE rows, compute a baseline verdict with every NEEDS-EVIDENCE row treated as PASS-EVIDENCED. A row is **decisive** if re-statusing that row alone, to any plausible resolution, changes the baseline. BLOCKER-MODEL counts as plausible only while the commercial question is open.

First match wins:

1. Any BLOCKER-MODEL → **DO NOT SUBMIT**.
2. Mode RESTRICTED or SUMMARY, or any decisive NEEDS-EVIDENCE → **INSUFFICIENT EVIDENCE**.
3. Any BLOCKER-FIXABLE → **READY AFTER FIXES**.
4. Otherwise → **READY TO SUBMIT**.

For POST-APPROVAL, read DO NOT SUBMIT as "do not release" or "do not request reopen", and verdicts 3 and 4 as "ready to release (after fixes)" or "ready to request reopen (after fixes)".

Name every row at the triggering status. Under any verdict, list every BLOCKER-FIXABLE row in the delta.

Delivery channel:
- Not yet submitted: upload the ZIP at the submission form (2FA required on the submitting account).
- Pending submission: reply on the original review thread; upload the updated ZIP from the submission page. Request a slug change in the review reply once review has started.
- Update to an approved plugin: commit to SVN with incremented Version, Stable tag, and SVN tag.
- Closed plugin: commit the fix to SVN, then reply to the closure email.

Never promise approval.

## Recovery protocol

Keep G IDs stable. Keep every row the new evidence does not touch. Attach the new evidence, re-status touched rows, add rows for new reviewer points, then recompute the verdict. For a revised ZIP, triage any new Plugin Check output (02), re-check rows whose files changed, and add rows for new issues in changed files. Do not redo the full review.

## Response contract

**FULL GATE, REVIEW-EMAIL, POST-APPROVAL** — `##` headings in order; omit any marked "when" if empty:

1. EVIDENCE STATE — scope, mode, sources with fetch dates, 01 scope line.
2. FINDINGS — 05 rows that are not PASS-EVIDENCED or NOT-APPLICABLE, plus one grouped row "Checked, no issue: <surfaces>".
3. PLUGIN CHECK TRIAGE — when findings exist; otherwise the clean-report line in EVIDENCE STATE, or "Plugin Check: not supplied" when no output was supplied.
4. MONETIZATION TRACE — when the plugin has paid or external features.
5. README CHECKS — when 04 found anything.
6. VERDICT — verdict and controlling rows.
7. REMEDIATION DELTA — when any: G# → change → file.
8. RECHECK PLAN — when the delta is not empty: artifact → check → pass condition.
9. REVIEWER REPLY — when an email exists: plan table (Comment → change → file → evidence → clarification), then email prose listing every change, once the user confirms the changes.
10. NEXT EVIDENCE NEEDED — when any: up to three ranked artifacts or business questions.

**RECOVERY** — EVIDENCE STATE, CHANGED ROWS (old → new status, evidence), VERDICT, REMEDIATION DELTA, RECHECK PLAN, REVIEWER REPLY (when), NEXT EVIDENCE NEEDED (when).

**FOCUSED** — EVIDENCE STATE (mode is informational), the requested section's table, a one-line answer when the question is yes/no (for example "Trialware: yes", or "Trialware: undetermined (NEEDS-EVIDENCE)" when the evidence is inconclusive), and an offer to run the full gate.

## Capability boundary

This Skill analyzes supplied plugin code, readme/header text, Plugin Check output, build/source notes, service evidence, and reviewer feedback. It does not run Plugin Check, submit a plugin, inspect private WordPress.org systems, verify third-party terms, modify the ZIP, or guarantee approval unless those actions actually occurred.

## Quality gate

Before returning, confirm: every 01 surface and Common review surface was considered (in a row or the grouped "no issue" row); every 05 and 03 evidence cell has a label; the verdict follows the 06 order; every BLOCKER-FIXABLE row is in the delta; no sentence promises approval.

## Additional resources

- **`${CLAUDE_PLUGIN_ROOT}/lib/wordpress-plugin-submission/references/official-sources.md`** — URLs, submission policy, guideline index, Common review surfaces. Verify on the live page.
- **`${CLAUDE_PLUGIN_ROOT}/lib/wordpress-plugin-submission/references/example-rows.md`** — worked output for each table, verdict, delta, recheck, and reviewer reply.
- **`${CLAUDE_PLUGIN_ROOT}/lib/wordpress-plugin-submission/references/situations.md`** — post-approval, closures, block plugins, multisite.
