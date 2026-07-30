# Rating Rubric

Overall rating is a weighted average of the 10 scorecard areas, weighted toward Security, Performance, and Correctness. Map the overall score to these tiers:

- **9-10** - Production-ready enterprise quality. OOP, namespaced, tested, fully escaped/sanitized, Settings API, proper enqueue, i18n loaded, uninstall.php, readme complete, multisite-aware, accessible.
- **7-8** - Solid. Minor gaps (missing tests, some procedural code, incomplete i18n) but secure and performant.
- **5-6** - Functional but dated. Procedural, missing Settings API, inline assets, no tests, weak sanitization patterns, but no critical security holes.
- **3-4** - Significant issues. Security gaps, performance anti-patterns, magic strings, no architecture, but generally works.
- **1-2** - Critical vulnerabilities or broken on modern WP. SQL injection, XSS, missing nonces, deprecated APIs, breaks PHP 8+.
