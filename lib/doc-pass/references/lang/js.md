## JavaScript and TypeScript rules

These apply on top of the core rules to `.js`, `.jsx`, `.mjs`, `.cjs`, `.ts`, `.tsx`, `.mts`, `.cts`, `.d.ts`, the `<script>` blocks of `.vue` and `.svelte` files, and the frontmatter and `<script>` blocks of `.astro` files. The style files (`js-style-jsdoc.md`, `js-style-tsdoc.md`) set the comment form.

### Files and tools

- **In scope:** the extensions above, `.vue` / `.svelte` script blocks, and `.astro` frontmatter and script blocks. The checker parses them with Babel (`lib.mjs`); component markup outside those blocks is compared byte for byte. A self-closing `<script … />`, a script whose `type` is not JavaScript (`application/ld+json`), and an Astro script with any attribute other than `src` are markup.
- **Out of scope** (read for facts only): `.html`, `.ejs`, `.hbs`, CSS and preprocessors, JSON and YAML; `node_modules/`, `dist/`, `build/`, `.next/`, `.nuxt/`, `.svelte-kit/`, `.output/`, `coverage/`, `storybook-static/`; minified and bundled files (`*.min.js`, `*.bundle.js`) and vendored libraries in `public/` or `static/`; generated declarations (`next-env.d.ts`, `auto-imports.d.ts`, `components.d.ts`, `typed-router.d.ts`, `worker-configuration.d.ts`) and Vite temp files (`*.timestamp-*.mjs`).
- **Syntax check:** the verify run (Babel parse). Also `node --check <file>` for plain `.js` / `.mjs` / `.cjs` files without JSX; never on JSX, TypeScript or components.
- **Baselines** (project binaries only, through `npx --no-install`, so a missing tool fails instead of downloading an unrelated package):
  - Type check: `npx --no-install tsc --noEmit -p <tsconfig>` for each tsconfig the build uses (Angular: `tsconfig.app.json` and `tsconfig.spec.json`), counted per file and error code (`TS2322` …). Vue and Nuxt: `npx --no-install vue-tsc --noEmit` or `npx --no-install nuxi typecheck`. Svelte and SvelteKit: `npx --no-install svelte-check --output machine`. `tsc` never checks `.vue` / `.svelte` script blocks.
  - Declarations: when a tsconfig sets `declaration` (or `stripInternal`), `npx --no-install tsc -p <tsconfig> --declaration --emitDeclarationOnly --noEmit false --outDir <scratchpad>/dts-before`.
  - ESLint: `npx --no-install eslint -f json <files>`, counted per file and rule. `jsdoc/*` rules go down; nothing goes up. Biome: `npx --no-install biome lint --reporter=json <files>`.
  - Prettier: `npx --no-install prettier --check <files>` on the in-scope files only; record which pass. Biome: `npx --no-install biome format <files>`.
  - Tests: the `test` script in `package.json` (`npm test`, `pnpm test`), or `npx --no-install vitest run`, `npx --no-install jest --ci`, `node --test`, `npx --no-install playwright test` (needs browsers: say so when they are missing). Never pass `-u` / `--update-snapshots`.

### Placement

- Directive prologues (`'use strict'`, `'use client'`, `'use server'`, `'use cache'`) stay where they are. The file header may sit above them: comments are not statements.
- In a Vue, Svelte or Astro component, only edit inside its script blocks (Astro: the frontmatter between the `---` fences, and `<script>` tags). Never touch `<template>`, `<style>`, markup or a `<script>` inside markup (for example in `<svelte:head>`, which is page output).
- In JSX, a `{/* … */}` child is allowed only where a JSX expression container already exists; never add one.
- The file header is a `/** … */` block. In a component it goes at the top of the first `<script>` block that has code. When the file starts with a test-runner pragma docblock (`@jest-environment`, `@vitest-environment`), add the summary to that docblock instead of stacking a second one, and keep the pragma line exactly.

### Coverage

- Every class, interface, type alias, enum and named TypeScript `namespace`, and every member of an interface or of an object type alias at the top level of a file (props interfaces included).
- Every function, method, getter and class property (fields, decorated DTO properties, arrow-function properties). Exempt: a constructor that only receives injected dependencies (`constructor(private readonly users: UsersService) {}`), a field that only does (`private http = inject( HttpClient )`), the implementation after overload signatures, and a setter whose getter is documented.
- Every module-level `const` / `let` bound to a function, a class, or a call that wraps one (`forwardRef(…)`, `memo(…)`, `defineStore('id', () => …)`, `middy(async …)`); every exported binding (including framework config exports such as `export const dynamic`, `export const metadata`, `export const config`); and every exported object literal's methods (Vue options API `methods`, `computed`, `watch`, lifecycle hooks; `export default { fetch() {} }`).
- Every statement that registers a handler with a block body: routes (`app.get`, `router.post`, `fastify.route`), middleware (`app.use`), events (`emitter.on`, `socket.on`, `process.on`), hooks (`fastify.addHook`), plugins (`fastify.register`), IPC and queue workers (`ipcMain.handle`, `queue.process`), schema hooks and methods (`schema.pre( 'save', … )`, `schema.method( … )`), and subscriptions. Object-form routes (`fastify.route( { method, url, handler } )`, Hapi `server.route( { … } )`) and instance decorators (`fastify.decorate( 'db', … )`, whatever value they add) count too. Test callbacks (`describe`, `it`, `test`, `beforeEach`) need none.
- Arrow functions and callbacks with a multi-statement body or a non-obvious purpose (event handlers, `useEffect` / `watch` / `onMounted` bodies, promise chains, reducers) get a doc comment or a `//` comment before them. A trivial one-expression arrow passed inline (`(u) => u.id`) needs none. A `module.exports = { a, b }` object of names the file header already lists needs no comment of its own.
- `.d.ts` files are documented like source: every declared function, interface, member and module augmentation (`declare module 'express' { interface Request { user?: User } }` documents each added member).
- Properties of an exported config or options object get `/** … */` comments (editors show them on hover); keys nested inside a function body get `//` comments when they need one.
- A destructured parameter: document the object and each property used. `@throws` for errors thrown on purpose and for promise rejections the caller must handle.

### Shapes

- Reference a shared shape with `@type {import('../types').Note}` in JS, or the imported type in TS. Never add an alias `@typedef` for an existing class, interface or typedef.

### Comments that are code

- **Frozen** (whole comment):
  - Lint, type-check and formatter directives: `eslint-disable*` / `eslint-enable`, `/* eslint … */`, `/* global … */`, `/* exported … */`, `// @ts-check`, `// @ts-nocheck`, `// @ts-ignore`, `// @ts-expect-error`, `prettier-ignore`, `biome-ignore`, `deno-lint-ignore`, `oxlint-disable`, `stylelint-disable`, `tslint:`, `jshint`, `cspell:`, `noinspection`, `// language=`.
  - Triple-slash directives: `/// <reference … />`, `/// <amd-module />`.
  - Coverage directives: `istanbul ignore`, `c8 ignore`, `v8 ignore`.
  - Bundler and compiler hints: `/*#__PURE__*/`, `/*@__NO_SIDE_EFFECTS__*/`, webpack and Turbopack magic comments (`/* webpackChunkName: … */`, `/* turbopackIgnore: true */`), `/* @vite-ignore */`, `// @refresh reset`, JSX pragmas (`@jsx`, `@jsxRuntime`, `@jsxImportSource`, `@jsxFrag`), `// @flow`.
  - Template language hints read by codegen and editors: `/* GraphQL */`, `/* sql */`, `/* html */`, `/* css */` and the like before a template literal.
  - API spec blocks: any comment containing `@openapi`, `@swagger` or apiDoc tags (`@api {get} …`, `@apiName`, `@apiParam` …). Never add new ones.
  - i18n extraction comments: `translators:` and `i18next-extract-*`. License text, `@license`, `@preserve`, `/*! … */`, `@generated`.
- **Next-line directives** that must stay last before their code: `eslint-disable-next-line`, `@ts-expect-error`, `@ts-ignore`, `prettier-ignore`, `biome-ignore`, `deno-lint-ignore`, `noinspection`, `translators:`, `istanbul` / `c8` / `v8 ignore next` / `start` / `else` / `if`.
- **Trigger words** never to start a new comment or comment line with: `eslint`, `global`, `prettier-ignore`, `istanbul`, `c8`, `v8`, `translators:`, `@jsx…`, `@openapi`, `@swagger`, `@api…`, `@generated`, `@preserve`, `@license`.
- **Frozen tag lines:** `@jest-environment`, `@vitest-environment` (and their `-options`), `@format`, `@prettier`, `@noformat`; `@internal` (removed from `.d.ts` output under `stripInternal`), `@deprecated`, `@hidden`, `@ignore`, release tags (`@public`, `@alpha`, `@beta`, `@experimental`, read by API Extractor), and modifiers that checked JS enforces (`@private`, `@protected`, `@readonly`, `@override`, `@sealed`, `@virtual`). When the rules file says **schema tags are on** (tsoa, typescript-json-schema, ts-json-schema-generator or typia generate validation or a spec from comments), also every validation or schema tag: `@minimum`, `@maximum`, `@minLength`, `@maxLength`, `@pattern`, `@format`, `@isInt` / `@isFloat` / `@isDate` …, `@minItems`, `@maxItems`, `@uniqueItems`, `@default`, `@example(s)`, `@nullable`, `@discriminator`, `@title`, `@readOnly`, `@writeOnly`, `@TJS-*`. Never add one: it changes validation.
- **Kept:** `@since`, `@see`, `@link`, `@author`, `@packageDocumentation`, `@module`. Type-bearing tags keep their tag, `{type}` and name, and only the description may change (a type that spans lines, `@typedef {{` … `}} Row`, is joined until its braces balance, so every line of it stays): `@type`, `@typedef`, `@callback`, `@property` / `@prop`, `@template`, `@satisfies`, `@import`, `@overload`, `@enum`, `@this`, `@extends` / `@augments`, `@implements`, and, when the rules file says types are checked (checked JS), `@param {…}` / `@returns {…}` lines. You may add a type to an untyped `@param`.
- **Tools that read comments as content:** NestJS Swagger `introspectComments`, tsoa, TypeDoc, Storybook autodocs, react-docgen, vue-docgen.
- **Inline comments** worth writing: escaping before `innerHTML` / `dangerouslySetInnerHTML` / `v-html` / `{@html}`, stale-response guards, effect order, hydration constraints.

### Bug report additions

- Unvalidated `req.body` / `req.query` / route params reaching a database query, a file path, `child_process`, a redirect or an outgoing URL (SSRF).
- `innerHTML`, `dangerouslySetInnerHTML`, `v-html` or `{@html}` with data that is not escaped or sanitized.
- Secrets in client bundles: server-only env vars read in client code, or exposed through `NEXT_PUBLIC_` / `VITE_` / `PUBLIC_` / `NUXT_PUBLIC_` names.
- Floating promises (an `async` call with no `await` or `.catch`), `async` callbacks passed to `forEach` or event emitters that swallow rejections, and missing `try` / `next(err)` in Express handlers.
- Missing auth or CSRF checks on mutating routes and server actions; CORS with `origin: '*'` and credentials.
- Effects without cleanup (listeners, intervals, subscriptions), stale closures in `useEffect`, and race conditions between overlapping requests.
- Prototype pollution through unchecked object merges, `JSON.parse` on input without validation, and `eval` / `new Function` on input.
