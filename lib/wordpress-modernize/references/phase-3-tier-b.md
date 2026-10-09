# Phase 3: Tier B naming (camelCase methods), one class at a time

Goal: camelCase method names, renamed in small, tested steps.

- Rename snake_case methods to camelCase using the position-aware rules in Hard rule 3. Leave `__construct` and other magic methods alone.
- An interface and its implementer share method names, so rename them in the same step. The same goes for a parent class and every subclass that overrides its methods.
- Don't rename methods that override or implement a WordPress core, WP-CLI or third-party method, and check for method names built at runtime before renaming (Hard rule 3).
- **Classes that call each other's renamed methods in both directions must be renamed in one commit.** A class that only calls into another one can go in a later step: rename the callee first, and update the caller's calls in the same commit.
- Order the steps from lowest risk to highest: interfaces and small helpers, then API clients, then settings, admin and REST together if they are coupled, then the class that writes data (the importer or post writer).
- Test method names (`test_*`), `set_up` and `tear_down` keep snake_case.
- A method whose name WordPress stored in the database (for example an uninstall callback) gets renamed like the others, plus a wrapper with the old name (Hard rule 1).
- Update tests that name a renamed method in the same commit, and record each old-to-new name in `MIGRATION_LOG.md` (Hard rule 2).

After each step: grep for leftovers of the old names, run the tests (Hard rule 2), commit, tag `v3-tier-b-<class-or-group>`, and update `MIGRATION_LOG.md`.
