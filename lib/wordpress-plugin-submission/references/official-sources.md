# Official Sources and Guideline Index

This file is a **pointer list**. It is not the current rule text. Fetch the live page, record the access date in EVIDENCE STATE, and quote or paraphrase from the live page only. If the Detailed Plugin Guidelines page cannot be fetched, the mode is RESTRICTED. If another page fails, mark only its dependent rows NEEDS-EVIDENCE.

Items below are tagged **[verified YYYY-MM-DD]** when checked against a live official page, or **[verify]** when they come from memory and must be checked before citing.

## Primary sources to fetch

Core set (fetch on every gate): Detailed Plugin Guidelines, Common issues, Plugin Developer FAQ, How readme.txt works, Plugin Review Team blog. Fetch the rest when relevant.

| Purpose | URL |
|---|---|
| Detailed Plugin Guidelines (binding rules) | https://developer.wordpress.org/plugins/wordpress-org/detailed-plugin-guidelines/ |
| Common issues seen in review | https://developer.wordpress.org/plugins/wordpress-org/common-issues/ |
| Plugin Developer FAQ | https://developer.wordpress.org/plugins/wordpress-org/plugin-developer-faq/ |
| How readme.txt works | https://developer.wordpress.org/plugins/wordpress-org/how-your-readme-txt-works/ |
| Readme validator | https://wordpress.org/plugins/developers/readme-validator/ |
| Header requirements | https://developer.wordpress.org/plugins/plugin-basics/header-requirements/ |
| Block Specific Plugin Guidelines | https://developer.wordpress.org/plugins/wordpress-org/block-specific-plugin-guidelines/ |
| Plugin Check plugin | https://wordpress.org/plugins/plugin-check/ |
| Plugin Check source and check list | https://github.com/WordPress/plugin-check |
| Submission form | https://wordpress.org/plugins/developers/add/ |
| Plugin Review Team blog (policy changes) | https://make.wordpress.org/plugins/ |
| Plugin Check + 2FA mandatory post | https://make.wordpress.org/plugins/2024/10/01/plugin-check-and-2fa-now-mandatory-for-new-plugin-submissions/ |
| Plugin Check on all updates post | https://make.wordpress.org/plugins/2025/10/29/plugin-check-plugin-now-creates-automatic-security-reports-update/ |

If a URL has moved, search from https://developer.wordpress.org/plugins/wordpress-org/ and record the new location.

## Submission policy facts

- New submissions are first run through Plugin Check's **Plugin Repo** category; an error-level item blocks the submission until fixed. Plugin Check does not replace manual review, and false positives are possible. The Security category was announced as a future requirement. **[verified 2026-10-09, make/plugins 2024-10-01 post]** Re-check the make/plugins blog for later changes.
- Plugin Check now runs on all plugin updates, new and already approved. Reports are internal, and emailing them to authors is a stated goal. **[verified 2026-10-09, make/plugins 2025-10-29 post]** The post does not say updates are blocked.
- Two-factor authentication is required on the WordPress.org account that submits a new plugin, and on all plugin owner and committer accounts. **[verified 2026-10-09, same post]**
- Submission ZIP must be under 10 MB. **[verified 2026-10-09, FAQ]**
- Reviewers email issues; reply on the original thread. Updated files can be uploaded from the submission page at any time. A review not complete after three months is rejected. **[verified 2026-10-09, FAQ]**
- Official/company plugins should be submitted from the organization's account; a personal email may be flagged for trademark concerns. **[verified 2026-10-09, FAQ]**
- The slug can be changed once before review begins, from the submission page. Once the plugin is under review, request the change by replying to the review email. After approval it cannot be renamed. **[verified 2026-10-09, FAQ and submission page]**
- Some names are restricted and blocked from slugs entirely. **[verified 2026-10-09, submission page]**

## Guideline index

Titles checked against the live page on 2026-10-09; titles change. Section numbers refer to this skill.

| # | Topic (short) | Skill section most affected |
|---|---|---|
| 1 | GPL-compatible license for code, data, and images | 03, 04 |
| 2 | Developer is responsible for contents and actions | 01, 03 |
| 3 | Stable version available from the directory page | 04 |
| 4 | Code must be (mostly) human readable | 01, 04 |
| 5 | Trialware is not permitted | 03 |
| 6 | Software as a Service is permitted (a service that only validates licenses while features ship locally is not) | 03 |
| 7 | No user tracking without consent | 03, 04 |
| 8 | No executable code sent via third-party systems | 03 |
| 9 | Nothing illegal, dishonest, or morally offensive | 03, 04 |
| 10 | No external links or credits on the public site without permission | 03 |
| 11 | Do not hijack the admin dashboard | 03 |
| 12 | Public-facing pages (readmes) must not spam | 04 |
| 13 | Use WordPress' default libraries | 01, 02, 03 |
| 14 | Avoid frequent commits | post-approval |
| 15 | Increment version numbers for each release | 04, post-approval |
| 16 | Complete plugin at submission | 01, 06 |
| 17 | Respect trademarks, copyrights, and project names; slugs may not begin with another product's term | 03, 04 |
| 18 | WordPress.org reserves the right to maintain the directory | — |

## Common review surfaces

Walk this list on every full gate. Each item with an issue becomes a 05 row; the rest go in the grouped "Checked, no issue" row. Items tagged **[engineering]** are good practice, not cited rules: use REVIEW-RISK unless a live official source is found.

**Security** — from Common issues **[verified 2026-10-09]** unless tagged:
- input sanitized and validated, output escaped late; escape functions not used to sanitize;
- nonces unslashed and sanitized before `wp_verify_nonce`; only needed request keys read, not whole superglobals;
- `wpdb::prepare()` on SQL, one placeholder per array item;
- `wp_handle_upload` instead of `move_uploaded_file()`; no `ALLOW_UNFILTERED_UPLOADS`;
- no heredoc/nowdoc output; `ABSPATH` check on PHP files that execute code;
- REST routes with a real `permission_callback` **[engineering, not on Common issues]**;
- `wp_ajax_nopriv_` handlers checked for capability/nonce needs **[engineering, not on Common issues]**;
- no `unserialize` on user input **[engineering, not on Common issues]**.

**Compatibility** — **[verified 2026-10-09]** unless tagged:
- unique prefixes for functions, classes, defines, options; no reserved `wp_`, `__`, `_`;
- full `<?php` tags; no global `ini_set`, timezone change, or permanent `error_reporting`;
- main file name matches folder and slug; complete headers in the main file only;
- WordPress HTTP API instead of raw cURL; `wp_enqueue_*` and inline-script functions instead of echoed `<script>`/`<style>`;
- no bundled copies of libraries core ships (for example jQuery);
- text domain is a literal string matching the slug; gettext arguments are literals (Common issues: Internationalization);
- no direct loading of `wp-load.php` or core files **[engineering, not on Common issues]**;
- data written to uploads, not the plugin folder **[engineering, not on Common issues]**.

**Compliance** — **[verified 2026-10-09]** unless tagged:
- no changing other plugins' activation status;
- no custom update checker or interference with the built-in updater; check any `Update URI` header for this **[verify]**;
- no `eval` or remote `include` of code from external servers (Guideline 8);
- locally shipped features not gated only by a license key (Guideline 5);
- external services documented in readme with links, terms, and privacy policy;
- no dev tools, unneeded vendor folders, demos, unit tests, or atypical file types in the ZIP;
- no premium-licensed code in the free plugin;
- no non-GPL-compatible code; public, documented source for compressed JS/CSS; `composer.json` included when Composer is used;
- remote asset calls (CDNs) only for approved services; bundle assets locally;
- bundled libraries are stable, maintained, and current;
- slug does not begin with another product's term; Guideline 17 also covers "wordpress" in slugs **[verified 2026-10-09]**; treatment of "WP" in names **[verify]**;
- admin notices must be dismissible or self-dismiss (Guideline 11) **[verified 2026-10-09]**;
- affiliate links disclosed and linking directly to the affiliate service, not redirected or cloaked (Guideline 12) **[verified 2026-10-09]**;
- review/rating nags limited **[engineering, not on Common issues]**;
- SDK telemetry and deactivation surveys opt-in (follows from Guideline 7; not named on Common issues);
- "Powered by" links on the front end not enabled by default (Guideline 10) **[verified 2026-10-09]**.

**Readme** — from How readme.txt works **[verified 2026-10-09]**:
- Contributors are case-sensitive WordPress.org usernames;
- Tested up to and Requires PHP are numbers only; Tested up to ignores minor versions;
- Stable tag is the plugin version, numbers and periods only, and matches the header Version;
- short description at most 150 characters, no markup;
- 1–5 tags, no competitor plugin names;
- License is GPLv2-or-later compatible and matches the header; License URI strongly recommended for rarer licenses;
- readme `=== Plugin Name ===` is used before the header name, so they should match.

**Headers** — from Header requirements **[verified 2026-10-09]**:
- `Requires Plugins` uses WordPress.org slugs only (`my-plugin`, not `my-plugin/my-plugin.php`);
- `License` and `License URI` are header fields; the requirement to declare a GPL-compatible license in header and readme comes from Common issues, and the text-domain match comes from Common issues: Internationalization, not this page.
