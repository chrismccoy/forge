# Analyzer Gaps

What `scripts/codebase_analyzer.py` misses or gets approximately right, and what to check by hand. This is the canonical list — SKILL.md points here.

The analyzer is regex-based. Treat every result as a lead and confirm it in source.

## Routes and Pages

| Gap | What to do |
|-----|------------|
| Express pages marked `inferred` (view `?`) — the handler renders through a helper the analyzer can't follow | Open the handler and confirm it returns HTML; note the template name |
| Paths built from loop variables show as `:param` (e.g. `/f/:path`) | Read the loop to get the real list of paths |
| Express `router.route('/x').get(...).post(...)` chains | Not extracted — search for `.route(` |
| Fastify: shorthand routes (`fastify.get('/x')`) are extracted, but `register(plugin, { prefix })` prefixes are not applied, and `fastify.route({ method, url })` objects are misreported as client API calls | Add plugin prefixes by hand; move `.route({` entries from client calls to endpoints |
| Express routers mounted in the same file they are defined in get no prefix; imports through TS path aliases (`@/routes`) or a `.js` specifier pointing at a `.ts` file are not resolved, so their mount prefixes are lost | Check `app.use('/prefix', ...)` lines against the reported paths |
| Route paths held in constants (`<Route path={ROUTES.USERS}>`, `path: ROUTES.X`) are missed | Read the constants file and rebuild the route list |
| Folders named `build`, `dist`, `out`, `media`, `test`, `spec`, and similar are skipped by Express, Django, and React Router extraction (file-system routers keep them) | Check for route files inside such folders |
| Remix v1 nested-folder routes (`routes/users/$id.tsx`) are dropped; SvelteKit `+page.server.ts` form actions are not reported | Read the routes folder and the `actions` exports |
| Next.js intercepting routes (`(.)photo`) are not stripped; `export { handler as GET }` reports `ANY` | Fix the path or method by hand |
| FastAPI / Flask routes | Not extracted — search for `@app.get` / `@router.post` / `@app.route` / `Blueprint` |
| Monorepos: `package.json`, `manage.py`, and requirements files are read only at the root, so a `frontend/` + `backend/` repo reports framework `unknown` and no routes | Run the analyzer once per app directory; scaffold from the main app and add the other inventories by hand |
| Route config objects (`{ path: ... }` arrays for React Router `createBrowserRouter`, Vue Router, Angular) are read only from files whose name contains `router`, `routes`, or `routing` | Search for `path:` in route arrays elsewhere |
| Nested React Router / Vue Router children are reported without their parent path (child `path="edit"` becomes `/edit`), and children with the same path under different parents merge into one | Rebuild full paths from the route tree |
| Next.js `middleware.ts` rewrites/redirects, `next.config.js` rewrites | Not applied — read them and adjust affected routes |
| Nuxt `definePageMeta({ path })`, Remix config-based `routes.ts` | Custom paths not applied — read them |
| NestJS URI versioning (`@Controller({ version: '1' })`, `enableVersioning`) | Version prefix not added — add `/v1` etc. by hand |
| Django views that render templates | Reported as backend endpoints, not pages — reclassify server-rendered views as pages |
| Django `urls/` packages (`urls/__init__.py`, `urls/api.py`) — only files named `urls.py` are read | Read the package and add its routes |
| DRF `@action` extra routes and `http_method_names` restrictions are ignored; only the six standard viewset actions are emitted | Read each viewset for `@action` and `http_method_names` |

## HTTP Methods

| Gap | What to do |
|-----|------------|
| Django function views without `@api_view` report method `ANY` | Read the view for `request.method` checks |
| Next.js Pages Router API handlers: methods come from `req.method === '...'` checks; otherwise `ANY` | Read the handler |
| Nuxt `server/api` files without a `.get.ts` / `.post.ts` suffix report `ANY` | Read the handler for `getMethod(event)` checks |

## API Calls and Mock Detection

| Gap | What to do |
|-----|------------|
| Mock labels come from signals (`mockX`, `mockData`, `faker.`, `fixtures/`, `setTimeout(... return`) within 8 lines of a call, or the file living in `__mocks__/`, `mocks/`, `fixtures/`, or `*.mock.*` | Confirm every `Mock` label before it goes in the PRD |
| Calls whose path is a variable (`fetch(url)`) are not captured | Trace the variable, or search the service layer by hand |
| Client base URLs are not applied: an axios instance `baseURL` is not prepended (`api.get('/users')` is reported as `/users` while the server route is `/api/users`), and a full-URL base constant shows up as `/:API_BASE/...` | Read the HTTP client setup and prefix the reported paths |
| Any `url:` / `endpoint:` property holding a path is reported as an API call, including Next.js metadata (`openGraph.url`) | Drop entries that aren't HTTP calls |
| GraphQL, WebSocket, and gRPC calls are not extracted | Search for `gql\``, `useQuery(` with GraphQL documents, `new WebSocket(`, `io(` |

## Models and Enums

| Gap | What to do |
|-----|------------|
| Models: Django (with fields), NestJS entities/DTOs and Pydantic (names only). Prisma, TypeORM fields, Sequelize, Mongoose, SQLAlchemy, and hand-written SQL are not parsed | Read schema files directly (`schema.prisma`, migrations, model files) |
| Django fields can be lost: fields written without the `models.` prefix are missed, and a multi-line field whose closing `)` is indented deeper can swallow the next field | Compare the field list with the model source |
| Enums: TypeScript `enum` with initializers and constant objects whose name contains `MAP`, `STATUS`, `TYPE`, `ENUM`, `OPTION`, `ROLE`, or `STATE`. Enums without initializers yield no values; nested maps (antd `valueEnum`: `{ active: { text, status } }`) yield `text`/`status` as keys; names like `initialState` or `defaultOptions` are false positives | Search for Django `choices`, Python `Enum`, union string types, and `valueEnum` configs; discard false positives |

## Coverage

- React Router, Express (server-rendered), and Django REST Framework extraction was checked against real open-source and production projects during development; the test suite uses fixtures that mirror those projects.
- Next.js, Nuxt, SvelteKit, Remix, Astro, and NestJS are covered by fixture tests only.
- Vue, Angular, and Svelte without SvelteKit have no real-project or fixture coverage beyond comment stripping.
- Comment stripping handles `//`, `/* */`, Python `#` and docstrings, and HTML `<!-- -->` in `.vue` / `.svelte` / `.astro`. A JavaScript regex literal containing `//` or `/*` can confuse it.
