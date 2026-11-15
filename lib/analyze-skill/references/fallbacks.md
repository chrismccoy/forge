# Fallbacks

Use these when the normal workflow cannot run: the user pasted `SKILL.md` text instead of giving a
path, Python is missing, or there is no file-writing tool.

## Pasted text

1. Make a new parent folder named `pasted-<YYYYMMDD>` (today's date from the session; add `-2`, `-3`, ... if it exists), and inside it a folder named from the
   paste's `name:` field reduced to `[a-z0-9-]` (else `pasted-skill`), so the folder name matches
   `name` (no FM006) and never reuses an existing folder.
2. Create them under the session scratchpad or the system temp directory, and Write the paste into
   the inner folder as `SKILL.md` (this scratch file is the only other file the skill writes).
3. Run Steps 2-5 of `SKILL.md` on that folder.
4. State at the top of the report that bundled files could not be discovered: `REF001` errors and
   missing File Map entries reflect the paste, not the real package.

## No Python

The checks exit 126 or 127, or `python3` is not found.

1. Do the checks with Glob and Grep, using the rule lists in `check-output.md` as a guide, and say
   in the report that the automated checks did not run. Without the inventory, treat any file
   whose name looks like a credential (`.env*`, `*.pem`, `*.key`, `id_rsa*`, `credentials*`,
   `secrets.*`, `.netrc`) as one: do not open it.
2. Build the Appendix by hand as a best effort, quoting at most the 10 most important files:
   - fence each file with one more backtick than its longest line-leading backtick run
     (minimum 3);
   - redact secrets and whole private-key bodies;
   - write invisible characters as `<U+XXXX>`.
3. Validate the report against `check-output.md` section 7 by eye, for the chosen mode.

## Append run times out

If `build_appendix.py` hits the tool's time limit (a hostile target can make the checks slow):
keep sections 1-15, append `## 16. Appendix` with one line saying it could not be built and why,
run the same command with `--check-only` to validate sections 1-15, and tell the user.

## No file-writing tool

Print the mode's sections in chat. Then give the user this command to run themselves, rather than
reprinting the Appendix:

```bash
ANALYZE_SKILL_STDOUT=1 python3 -I -B '<analyze-skill dir>/scripts/build_appendix.py' --stdout -- '<target_dir>' > appendix.md
```

`--stdout` prints only the Appendix, so it needs no `--report` or `--mode`. It refuses to run
without `ANALYZE_SKILL_STDOUT=1`: it is for the user to run, not covered by the skill's
pre-approval.
