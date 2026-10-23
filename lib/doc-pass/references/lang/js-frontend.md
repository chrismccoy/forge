## Frontend rules (React, Vue, Svelte, Angular, vanilla browser JS)

### Shared

- **Components:** the doc comment says what the component renders and when, its props (each one, through the props interface or `@param props.x`), the events it emits or callbacks it calls, the slots / children it accepts, the context or store it reads or provides, and its side effects (data fetching, subscriptions, timers, focus management, `localStorage`).
- **State:** stores (Redux slices, Zustand, Pinia, Svelte stores, signals, NgRx): the state shape (follow the shapes list), each action or mutation, what persists and where, and which components depend on it.
- **Data fetching:** each client call names the server route it hits (follow the route map: `Calls GET /api/notes/:id (routes/notes.js).`), the cache key or query key, invalidation, and how errors and loading are shown.
- **Effects and watchers** (`useEffect`, `useLayoutEffect`, `watch`, `watchEffect`, `$effect`, `onMount`): a comment before each non-trivial one says what it syncs with, why its dependency list is what it is, and what its cleanup undoes.
- **Security-relevant sinks:** before `dangerouslySetInnerHTML`, `v-html`, `{@html}`, `innerHTML`, `insertAdjacentHTML` or `bypassSecurityTrust*`, say where the HTML comes from and what sanitizes it. If nothing does, state that as a fact and put it in the bug report.
- **Client-exposed config:** values from `import.meta.env.VITE_*`, `process.env.NEXT_PUBLIC_*`, `NUXT_PUBLIC_*` or `PUBLIC_*` ship to the browser. Say so where they are read.

### Client routes

- Follow the client part of the route map. Route records and route arrays (React Router `createBrowserRouter`, `<Route>` trees, TanStack Router route files, Vue Router records, Angular `Routes`) get a comment per route: its path, the component (or lazy chunk) it renders, its guards, and the data it loads (`loader`, `beforeEnter`, `resolve`, `meta`).
- Guards and resolvers (`beforeEach`, `CanActivateFn`, `ResolveFn`, React Router `loader` redirects): what they check, where they redirect, and what they put on the route.

### Vanilla browser scripts (`public/js/*.js`, no bundler)

- The file header says which page or pages load it (the view or template that includes the `<script>` tag), which DOM elements it expects (ids, `data-*` attributes), which globals it reads or defines, and which server routes it calls.
- Event handlers registered with `addEventListener` and a block body get a doc comment or a `//` comment before the statement (event, element, what it does).
- An IIFE wrapper that is the file's first statement is documented by the file header: don't stack a second comment on it.

### React

- Function components: summary, props, `@returns`. Wrapped components (`forwardRef`, `memo`, HOCs) are documented at the binding (`export const Button = forwardRef(…)`) and say which ref they forward.
- Custom hooks: the summary starts `Hook that …` or matches the project's voice; document arguments, the returned value or tuple, and the rules for callers (stable callbacks, must run inside a provider).
- Context: the provider documents the value shape and the default; consumers reference it.

### Vue (`.vue` single-file components)

- Only the top-level `<script>` and `<script setup>` blocks are edited. The component header goes at the top of the first script block that has code. `lang="ts"` blocks follow the TSDoc style; others follow the JSDoc style.
- `<script setup>`: document `defineProps` (through the props interface or type literal members), `defineEmits` (each event and payload), `defineModel`, `defineExpose`, and each composable call whose role isn't plain.
- Options API: the exported object's `props`, `data`, and each method in `methods`, `computed`, `watch` and lifecycle hooks.
- Composables (`useX()` in `composables/`): arguments, returned refs and functions, and their reactivity (what is a `ref`, `computed`, `readonly`).
- vue-docgen / Storybook read these comments as component docs: write them for that reader.

### Svelte (`.svelte`)

- Only the top-level `<script>` and `<script context="module">` / `<script module>` blocks are edited. Never add `<!-- @component -->` or any other markup comment.
- Props: every `export let x` (Svelte 4) or each field of the `$props()` type (Svelte 5) gets a doc comment. Document `createEventDispatcher` events, runes (`$state`, `$derived`, `$effect`) whose role isn't plain, and stores used with `$store`.

### Angular

- Components, directives and pipes: the selector, inputs (`@Input`, `input()`, `input.required()`, `model()`), outputs (`@Output`, `output()`), queries (`viewChild()`, `@ViewChild`), the change-detection strategy if not default, and lifecycle hooks implemented. Templates (`.html`) and styles are out of scope; an inline `template:` string is code.
- `inject()` fields need no doc comment, like constructor injection.
- Services: `providedIn` scope, what they inject, and the observables or signals they expose (when they emit, whether they complete, whether they replay).
- Functional guards, resolvers and interceptors (`CanActivateFn`, `ResolveFn`, `HttpInterceptorFn`): what they read, what they allow, redirect to or add to requests, and the errors they map.
