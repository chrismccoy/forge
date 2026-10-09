# Example Output

A worked REVIEW-EMAIL gate showing every output format. Plugin names, files, lines, and versions are invented for illustration. Guideline numbers must be re-verified on the live page.

## EVIDENCE STATE

Scope: REVIEW-EMAIL. Mode: EVIDENCE. Sources fetched YYYY-MM-DD: Detailed Plugin Guidelines, Common issues, readme guide, FAQ, make/plugins blog, submission page.
Plugin Check X.Y.Z (record real version), categories Plugin Repo + Security, run on the supplied ZIP.
Scope line: slug `woo-acme-export` 1.1.0; free ZIP contains all code, no excluded pro code; premium yes (license option gates export); external service yes; telemetry absent; bundled libraries none; minified files yes (`admin.min.js`, `editor.min.js`, no `src/`); notices absent; update behavior: WordPress.org updater only, license checked locally; readme present; Plugin Check yes; reviewer email yes (3 points).

## FINDINGS

| ID | Rule/source | Plugin evidence | Why it applies | Status | Smallest fix |
|---|---|---|---|---|---|
| G1 | Guideline 5; reviewer point 1 | `includes/class-export.php:42` returns early unless license valid; export logic in ZIP — CONFIRMED | Local code locked by payment | BLOCKER-FIXABLE | Remove the license check; keep paid value in remote scheduling |
| G3 | Guidelines 6 + 7; Common issues: Undocumented 3rd party; reviewer point 2 | No "External services" section; `api.php:18` sends post content — CONFIRMED | Undisclosed data transfer | BLOCKER-FIXABLE | Add readme section: service, data, trigger, terms URL, privacy URL |
| G4 | Guideline 4; Common issues: No publicly documented resource | `admin.min.js`, no `src/`, no readme link — CONFIRMED | Built file without source | BLOCKER-FIXABLE | Ship `src/` or link the public repo |
| G5 | Guideline 17; reviewer point 3 | Slug `woo-acme-export` — CONFIRMED | Slug begins with another product's term | BLOCKER-FIXABLE | Request `acme-export-for-woocommerce` in the review reply |
| G6 | Common issues: Escape | `admin/settings.php:77` echoes `$_GET['tab']` — CONFIRMED | Unescaped request data; Plugin Repo ERROR | BLOCKER-FIXABLE | `sanitize_key( wp_unslash() )`; `esc_html()` on output |
| G7 | Common issues: No GPL-compatible license declared | No `License:` header — CONFIRMED | License not declared | BLOCKER-FIXABLE | Add License and License URI to header and readme |
| G8 | Guideline 9 | Readme "No data leaves your site" vs `api.php:18` — CONFIRMED | False privacy claim | BLOCKER-FIXABLE | Remove the claim |
| G9 | Guideline 4 | `editor.min.js`; user says source is "on GitHub", no URL — UNKNOWN | Source not checkable | NEEDS-EVIDENCE | Supply the repo URL or ship `src/` |
| G11 | Common issues: Incorrect Stable Tag | Readme `Stable tag: 1.2.0` vs header `Version: 1.1.0` — CONFIRMED | Directory serves the wrong version | BLOCKER-FIXABLE | Set both to 1.2.0 |
| — | Checked, no issue | G2 SaaS (remote scheduling does real work — SUPPORTED); telemetry, credits, notices, update checker absent; prefixing, enqueue, HTTP API, `wpdb::prepare` OK — CONFIRMED | — | PASS-EVIDENCED / NOT-APPLICABLE | — |

G IDs stay stable across recovery runs, so gaps (G2 is in the grouped row, G10 was dropped) are expected.

G9 is not decisive: the baseline (G9 as PASS-EVIDENCED) is READY AFTER FIXES, and its only other plausible resolution (BLOCKER-FIXABLE) gives the same verdict.

## PLUGIN CHECK TRIAGE

| Check ID | Category | Severity | File:line | Class | Action |
|---|---|---|---|---|---|
| `WordPress.Security.EscapeOutput.OutputNotEscaped` | Plugin Repo | ERROR | `admin/settings.php:77` | PC-BLOCKING | G6 |
| `plugin_header_no_license` | Plugin Repo | ERROR | `acme.php:3` | PC-BLOCKING | G7 |
| `WordPress.WP.EnqueuedResourceParameters.NotInFooter` | Plugin Repo | WARNING | `acme.php:55` | PC-BEST-PRACTICE | Optional |
| `WordPress.DB.DirectDatabaseQuery.DirectQuery` | Plugin Repo | WARNING | `includes/report.php:120` | PC-BEST-PRACTICE (was PC-CONTEXT: hard-coded table, no user input) | None |

Clean-report form, when there are no findings: "No findings — Plugin Check X.Y.Z, categories Plugin Repo, Security."

## MONETIZATION TRACE

| Feature | Local code | Gate/check | Remote work | Unpaid/offline | Data sent | Disclosure | Label |
|---|---|---|---|---|---|---|---|
| Export to CSV | `class-export.php` | License option | None | Blocked | None | None | CONFIRMED |
| Scheduled export | Client in `api.php` | API key | Runs on `api.acme.example` | Stops | Post content | None in readme | SUPPORTED |

## README CHECKS

Field check:

| Field | Value | Rule | OK/Fix |
|---|---|---|---|
| Stable tag | 1.2.0 | Must match header Version | Fix (G11) |
| Short description | 162 characters | Recommended at most 150; longer is cut off | Fix: shorten (delta, no G#) |
| Tags | 4 | 1–5 | OK |

Claim check:

| README SAYS | CODE DOES | IMPACT | FIX |
|---|---|---|---|
| "No data leaves your site" | `api.php:18` sends post content | False claim | G8 |

## VERDICT

**READY AFTER FIXES** — rule 3. Controlling rows: G1, G3, G4, G5, G6, G7, G8, G11.

Contrast — DO NOT SUBMIT: the user states local export must stay paid-only and no remote service will be built. G1 becomes BLOCKER-MODEL. Moving the license check to a server does not help: a service that only validates licenses while features ship locally is not permitted.

Contrast — INSUFFICIENT EVIDENCE: if every BLOCKER-FIXABLE row were fixed, the baseline would be READY TO SUBMIT, and G9 resolving to BLOCKER-FIXABLE would change it to READY AFTER FIXES, so G9 would be decisive.

## REMEDIATION DELTA

| G# | Change | File |
|---|---|---|
| G1 | Delete license check around export | `includes/class-export.php:38–51` |
| G3, G8 | Add "External services" section; remove "No data leaves your site" | `readme.txt` |
| G4 | Add `src/` or repo link | ZIP root / `readme.txt` |
| G5 | Request new slug in the review reply | Review email |
| G6 | Sanitize and escape `tab` | `admin/settings.php:77` |
| G7 | Add License headers | `acme.php`, `readme.txt` |
| G11 | Set Version and Stable tag to 1.2.0 | `acme.php`, `readme.txt` |
| — | Shorten short description to 150 characters or less (recommendation; longer text is cut off) | `readme.txt` |

## RECHECK PLAN

| Artifact | Check | Pass condition |
|---|---|---|
| Rebuilt ZIP | Plugin Check, Plugin Repo + Security | No ERROR |
| `readme.txt` | Readme validator | No errors; Stable tag = Version |
| Export feature | Manual test with no license set | Export completes |

## REVIEWER REPLY

| Comment | Change | File | Evidence | Clarification |
|---|---|---|---|---|
| 1. Local features locked by license | License check removed; paid tier is remote scheduling only | `class-export.php` | Export runs unlicensed | None |
| 2. External service not disclosed | "External services" section added | `readme.txt` | Names endpoint, data, trigger, terms, privacy | None |
| 3. Slug begins with a trademark | Requesting new slug | Review email | — | None |

Email (after the user confirms the changes; reply on the original thread after uploading the new ZIP from the submission page):

> Hello,
>
> Thank you for the review. I have uploaded version 1.2.0 with these changes:
>
> 1. Licensing: CSV export now runs without a license. The paid tier only adds scheduled exports, which run on our service. (includes/class-export.php)
> 2. External services: readme.txt now has an "External services" section describing what is sent to api.acme.example, when, and links to our terms and privacy policy. I also removed the incorrect "No data leaves your site" sentence.
> 3. Slug: please change the slug to acme-export-for-woocommerce.
>
> Other changes: human-readable source for assets/js/admin.min.js is now in src/; output escaping in admin/settings.php is fixed; License headers are added; Version and Stable tag are both 1.2.0; the short description is shortened.
>
> Regards,
> [name]

Tone: factual, no persuasion, no claim that the plugin is now approved.

## NEXT EVIDENCE NEEDED

1. Confirm the business accepts free local export (G1). If not, G1 becomes BLOCKER-MODEL and the verdict becomes DO NOT SUBMIT.
2. Public repo URL for `editor.min.js` source (G9).

## FOCUSED example (readme only)

User pastes only `readme.txt` and asks "check my readme". Output: EVIDENCE STATE (mode EVIDENCE, informational; code not supplied), the Field check table, Claim check rows only where the readme contradicts itself (code not supplied, so no code comparisons), then: "Run the full gate when the ZIP is available."
