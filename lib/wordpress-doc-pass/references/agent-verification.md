## Agent verification

Each agent checks only its own files:

- Syntax: `php -l` for PHP, `node --check` for `.js` / `.mjs` / `.cjs` files without JSX, and the checker's Babel parse for `.jsx` / `.tsx` / `.ts` (and for any `.js` file that contains JSX). Never run `node --check` on JSX or TypeScript. The verify script reports a file that fails to parse as `CODE CHANGED: <file>: parse error …`.
- The verify script on its files. If another agent is editing in parallel, it looks only at its own files in the output.
- No line exceeds the project's line limit.
- If phpcs is available, phpcs on its files, compared with the baseline per `(file, source)`: **no new** violation counts, and comment-related counts should go down.

It follows the **Failure protocol** on any failure. It reports the files done, any files left undocumented and why, the verification result, and the code smells it noticed.
