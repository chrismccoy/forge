## Agent verification

Each agent checks only its own files:

- Syntax: `php -l` for PHP, `node --check` for `.js` / `.mjs` / `.cjs` files without JSX, and the checker's Babel parse for `.jsx` / `.tsx` / `.ts` (and for any `.js` file that contains JSX). Never run `node --check` on JSX or TypeScript. The verify script reports a file that fails to parse as `CODE CHANGED: <file>: parse error …`.
- The verify script on its files. If another agent is editing in parallel, it looks only at its own files in the output.
- No line exceeds the project's line limit.
- If phpcs is available, phpcs on its files, compared with the baseline per `(file, source)`: **no new** violation counts, and comment-related counts should go down.

It follows the **Failure protocol** on any failure. It reports the files done, any files left undocumented and why, the verification result, and the code smells it noticed.

In terse style also:

- Run verify with `--terse [--max-doc-lines <n>]` (the facts give the value; the default is 3 lines for a doc comment and 6 for a file header), plus `--checked-php` when the facts say `PHP checked types: on` and `--checked-js` when they say `JS checked types: on`. It prints `LONG DOC COMMENT: <file>:<line> (<k> > <n> lines)` for a doc comment over the limit, which you shorten, and `TERSE TAG ADDED: <file>:<line> <tag>` for a typed tag that did not exist before, which you remove. Frozen and Kept lines never count toward the limit. Carried untyped or unchecked tag lines count toward the limit; remove them. Exempt, and never to be shortened or removed: a docblock whose next code is a hook call (`do_action*` / `apply_filters*`), a `This … is documented in …` line, and the `@var` lines of a template header. They neither count toward the limit nor trigger `TERSE TAG ADDED`.
- Run the coverage scan with `--terse`.
- Add a **Terse counts** section to the report: doc comments condensed, tags dropped, comments removed as restating the code, and lines kept (Frozen, Kept, hook docblocks, template headers).
