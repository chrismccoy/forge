# Rating Rubric

Overall rating is a weighted average of the 10 scorecard areas, weighted toward Security, Performance, and Correctness. Round the overall score to the nearest whole number (x.5 rounds down, to score conservatively) and map it to these tiers. In the Tier line, the tier name is the lead phrase after the range (e.g. "Solid") and the tier meaning is the rest of that bullet, condensed to one clause:

- **9-10** - Production-ready enterprise quality. OOP, namespaced, tested, fully escaped/sanitized, Settings API, proper enqueue, i18n loaded, uninstall.php, readme complete, multisite-aware, accessible.
- **7-8** - Solid. Minor gaps (missing tests, some procedural code, incomplete i18n) but secure and performant.
- **5-6** - Functional but dated. Procedural, missing Settings API, inline assets, no tests, weak sanitization patterns, but no critical security holes.
- **3-4** - Significant issues. Security gaps, performance anti-patterns, magic strings, no architecture, but generally works.
- **1-2** - Critical vulnerabilities or broken on modern WP. SQL injection, XSS, missing nonces, deprecated APIs, breaks PHP 8+.
