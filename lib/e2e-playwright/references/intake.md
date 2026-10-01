# Intake and validation

Run this before Step 0 of the workflow in `SKILL.md`. It fills the fields of the *Inputs* table and decides whether to build at all.

## Intake

Treat the command's arguments (`$ARGUMENTS`) as the `TARGET_REPO` candidate when they name a path. Confirm it in one line and read the repository before asking anything that reading can answer - the module system, the database, the session mechanism, the environment variables, and the existing test runner's file pattern are all discoverable.

Use `AskUserQuestion` for the rest. **Ask one field at a time** so the UI stays focused, and skip any field the repository already settles.

1. **TARGET_REPO** (required) - the application root. Offer: `the current directory`, `a path I'll give you`, plus "Other". Skip when the arguments already named a readable path.
2. **DB_KIND** (required) - how the app stores data. Offer: `file database (SQLite or similar)`, `database server (Postgres, MySQL, ...)`, `read the repo and decide`, plus "Other". Skip when reading the repository settles it.
3. **UPSTREAM_API** (required) - whether the app calls a paid external API, and what to do about fixtures. Offer: `no external API`, `yes - record real response envelopes (costs money, asks first)`, `yes - hand-build the fixtures`, plus "Other".
4. **BROWSERS** (optional) - which browser projects to configure. Offer: `Chromium only`, `Chromium + Google Chrome (default)`, plus "Other". If skipped, configure both and drop the `chrome` project if its install fails.
5. **COMMIT_MODE** (optional) - how the work is landed. Offer: `branch and commit each step (default)`, `branch, no commits`, `no git - just list changed files`, plus "Other".

## Validation before building

Stop and ask, rather than inventing, when any of these hold:

- **`DB_KIND` resolves to `server`.** Read the repository first, then ask the human how the suite should get a throwaway database. Do not invent one.
- **`TARGET_REPO` is not a Node application**, or has no Express server. Say what it appears to be and stop.
- **The repository has uncommitted changes** and `COMMIT_MODE` involves git. Name them and ask whether to continue.
- **Recording upstream envelopes would spend the human's money.** Ask before the first real call. If there is no way to ask, or `CI` is set, hand-build the fixtures, mark each `TODO: re-record against the real API`, and say so in the report.
