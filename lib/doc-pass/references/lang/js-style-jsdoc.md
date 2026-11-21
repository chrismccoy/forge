## JSDoc style (`.js`, `.jsx`, `.mjs`, `.cjs`, and `<script>` blocks without `lang="ts"`)

- **Pick the dialect** from the project, in this order:
  1. `eslint-plugin-jsdoc` configured: follow its rules and settings (`settings.jsdoc.tagNamePreference`, `mode`), which must pass if ESLint is installed.
  2. Type-checked JS (`// @ts-check`, or `checkJs: true` in `tsconfig.json` / `jsconfig.json`): JSDoc types are read by `tsc`. Use TypeScript-flavored types (`import('./types').Note`, `Record<string, Note>`, `Promise<void>`, `{ id: string, tags?: string[] }`), and expect step 4's `tsc` comparison to catch a wrong type.
  3. Otherwise, match the existing doc comments; with none, use the defaults below.
- **Voice:** a third-person summary ending in a period (`Loads the note by ID.`), unless the project's existing comments use the imperative.
- **Tags:** `@param {Type} name Description.` for every parameter, with `[name]` for optional ones, `[name=default]` for defaults, `{...Type}` for rest parameters, and dotted names (`props.title`, `options.retries`) for each destructured property used. `@returns {Type} Description.` (or `@return` when the project uses it); omit it for a function that returns nothing unless the dialect requires `{void}`. `@throws {ErrorType} When …`. `@async` is not needed: write `{Promise<T>}`.
- **Types:** in braces. Prefer precise types from the code (`'draft' | 'published'`, `Array<Note>`), never `{*}` / `{any}` / `{Object}` when the shape is known. For shapes used in more than one file, follow the shapes list: `@typedef` once, then `@type {import('./types.js').Note}` or the typedef's name elsewhere. Use `@import` (TS 5.5+) only if the project already does.
- **React and JSX:** document a component's props as `@param {Object} props Component props.` plus one `@param` per prop used (`props.title`), and `@returns {React.JSX.Element}` (or `{React.ReactNode}` when it can return null or strings; in checked JS write `{import('react').JSX.Element}`, since React 19 types drop the global `JSX` namespace). Custom hooks: what they subscribe to, their dependencies, and the shape they return.
- **CommonJS:** document `module.exports = …` and `exports.name = …` like exports. A file header names what the module exports.
- **ES5 / jQuery legacy:** document `var`-style functions, prototype methods, `$.fn` plugins (`@memberof jQuery.fn`), and `$(function () { … })` bodies. Don't suggest ES6 rewrites in comments.
- **Inline comments:** `//` full sentences ending in a period.

### Terse form

- **Form:** one line, `/** Loads the note by ID. */`. A second sentence only for a side effect, an error path, auth or a why. No `@param`, `@returns` or `@throws`: say the thrown error in the sentence.
- **Checked JS** (`checkJs: true`, or `// @ts-check` in the file with per-file mode on, so `--checked-types` is on for it): an existing typed `@param {T} name` or `@returns {T}` stays, one line, and its description may shrink. Never add a new one (`TERSE TAG ADDED`). Untyped `@param` lines go. Unchecked JS drops all of them, typed or not.
- **Always stay:** `@type`, `@template`, `@satisfies`, `@this`, `@enum`, `@augments`, `@extends`, `@implements`, `@import`, `@overload`. They are casts and generics, not boilerplate.
- **Typedef family** (`@typedef`, `@callback`, `@property`, `@prop`): follow the Typedefs answer (collapse to one line, keep, remove) unless the typedef is on the shapes map; with checked types they all stay. The `Collapse to one line` form is `/** @typedef {{ maxLength?: number, separator?: string }} SlugOptions Settings for slugify. */`: the inline object literal is allowed only when checked types are off. With checked types the typedef stays as it is. With per-file mode on, a JS file without `// @ts-check` counts as unchecked.
- **Doc tools:** editors, TypeDoc and Storybook show the summary line, so one line is enough. A comment-reading generator (tsoa, typescript-json-schema) means schema tags are on: those lines are frozen.
