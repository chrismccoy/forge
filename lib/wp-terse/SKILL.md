# WordPress terse comments

Act as a senior WordPress developer who writes documentation for someone new to
the codebase (not just other senior engineers). Convert verbose PHPDoc/JSDoc
blocks in the target files into terse, plain-English comments, while preserving
all behavior and code exactly as-is (no logic changes).

`<skill-dir>` below is `${CLAUDE_PLUGIN_ROOT}/lib/wp-terse`, the folder that contains this procedure file; every relative `references/…` path below is inside it.

## Fresh Runs

Treat each request as a fresh, independent run. A run starts at the user message
that invoked `/wp-terse`, and that message counts as an answer. Do NOT reuse or
assume answers from any earlier run in this conversation, even if the files or
questions look similar. For each new request to convert files, ask every intake
question again from scratch, even if this procedure is already loaded.

## Protected Comments

Never change, move, or delete these, whatever the intake answers say. Programs
read them, so removing one can change how the code runs or is checked. If the
user asks for one to be removed, state exactly what will break and get
confirmation first. A "your call" answer is not confirmation: keep the comment.

- WordPress plugin and theme headers (`Plugin Name:`, `Theme Name:`,
  `Template Name:`, `Requires PHP:` and similar).
- WP-CLI command doc blocks (`## OPTIONS`, `## EXAMPLES`, `@when`, `@subcommand`,
  `@alias`). WP-CLI reads them while running.
- `translators:` comments, which must stay directly above the translation call
  they describe.
- Linter and analyzer instructions: `phpcs:`, `eslint-`, `@ts-`, `@phpstan-`,
  `@psalm-`, `/* global */`, `@codeCoverageIgnore`, `istanbul ignore`.
- Build and test instructions: `webpackChunkName`, `@dataProvider`.
- `@deprecated` tags, and `TODO` / `FIXME` notes.

If a comment looks machine-read and is not listed, keep it and flag it in the
summary. If type doc blocks (`@typedef`, `@param` types) are checked by a tool in
this file, such as `// @ts-check`, say so before removing them.

## Workflow

If a reference file cannot be read, stop and tell the user.

1. Read `<skill-dir>/references/intake-questions.md`. Ask the questions one at a time, in
   order. Right after question 1, read the target files.
2. Once all questions are answered, read `<skill-dir>/references/conversion-rules.md` and
   convert the files.
3. With file access, copy each original to a temp folder first and edit by hand,
   not with regex or bulk replacement. Then check that only comments changed:
   for PHP, compare `token_get_all` output without comment and whitespace tokens,
   and run `php -l`. Confirm each protected comment is still in place. If a check
   cannot run, say so.
4. Without file access, output the full converted files with nothing shortened or
   left out, and end with: "Not checked by a tool. Run a diff before committing."
5. Finish with a short bullet list summarizing what was condensed, dropped, or
   kept and why.

## Additional Resources

- **`references/intake-questions.md`** - The six intake questions
- **`references/conversion-rules.md`** - Writing and conversion rules
