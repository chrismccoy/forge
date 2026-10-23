## Backend rules (Node servers, NestJS, workers, CLIs)

### Node HTTP servers (Express, Fastify, Koa, Hapi, Hono, Elysia, plain `http`)

- **Entry file** (`server.js`, `app.ts`, `index.js`): the header says what it builds and starts (the app, middleware order, routers mounted and their prefixes, error handlers, static folders, the port and host it listens on), which environment variables it needs, and what happens on shutdown signals.
- **Middleware order is behavior.** In the entry file, an inline comment before each group says why it sits where it does (security headers before routes, body parsers before CSRF, session before auth, the 404 handler and error handler last).
- **Routers:** the file header lists the routes it defines with their full paths (mount prefix included, from the route map), and the middleware applied to all of them. Each route registration gets a doc comment before the statement (method, full path, auth, inputs and validation, responses and status codes, errors passed to `next()`, the view it renders). `router.param()` callbacks say which parameter they load and what they put on `req`.
- **Rendered views:** when a handler calls `res.render( 'view', locals )` (or `reply.view`, `ctx.render`), its doc comment names the view and lists each local it passes, with its type. Server templates (`.ejs`, `.pug`, `.hbs`, `.njk`, `.liquid`, `.eta`) are **out of scope**: their comment syntax can reach the output and their whitespace is real markup. Read them for facts only.
- **Middleware factories** (`createRateLimiter( opts )`, `requireAdmin`): what the returned middleware checks, what it reads from and adds to `req` / `res.locals` / `ctx.state`, when it ends the response (status and body) instead of calling `next()`, and its options with defaults.
- **Error handlers** (`( err, req, res, next )`): which error types they map to which status and view or JSON shape, what they log, and what they hide from the client in production.
- **Fastify:** plugins say what they register and whether they are wrapped with `fastify-plugin` (shared scope) or encapsulated; `decorate` / `decorateRequest` / `decorateReply` say what they add to the instance, request or reply. A route's `schema` object is code: with `@fastify/swagger`, its `description` and `summary` strings are the published spec, so never touch them and don't repeat them in comments beyond one line.
- **Validation schemas** (zod, valibot, yup, joi, TypeBox): a schema used as a shared shape is described once on the schema; types derived from it (`z.infer<typeof Note>`) reference it. `.describe( '…' )` strings are code.
- **Request augmentation:** a property a middleware adds (`req.user`, `req.skill`) is documented once, where it is set, or in the `declare module` / `@typedef` the shapes list names, and referenced elsewhere.

### Data layer (knex, Prisma, Drizzle, TypeORM, Sequelize, Mongoose, raw drivers)

- Repositories and models: the table or collection, the columns or fields read and written, and the meaning of each returned shape (follow the shapes list).
- Every query function says whether it runs in a transaction, what it locks, whether it is soft-delete aware, and what it returns when nothing matches (`undefined`, `null`, empty array, throws).
- **Migrations and seeds:** the file header says what the migration changes and whether `down` fully reverses it. Never edit the migration's code, name or order. Schema files that a tool generates (`schema.prisma` output, `drizzle` snapshots) are out of scope.
- **Mongoose / ODM schemas:** the collection, each field's meaning and constraints in words (the schema options are code), indexes and why they exist, virtuals, `pre` / `post` hooks (what they change and when they run), instance and static methods, and the `toJSON` transform.
- Note raw SQL or query objects built from input (operator injection such as `{ $gt: '' }`) in the bug report, not in a comment.

### GraphQL (Apollo Server, GraphQL Yoga, Mercurius, Pothos, Nexus)

- **Schema text** (`gql` / `graphql` tagged templates, `.graphql` files) is out of scope: its `#` comments and `"""` descriptions are part of the published schema. Never edit them, and never add a `/* GraphQL */` tag.
- **Resolver maps:** a doc comment on the map and on each resolver: the type and field it resolves (`Query.questions`), arguments, the data source it calls, authorization, N+1 behavior (DataLoader or not), and the errors it throws (`GraphQLError` codes). A resolver map that is not exported still gets these comments.
- **Context:** document the context factory's shape once (follow the shapes list) and reference it in resolvers.
- **Client side** (Apollo Client, urql, Relay): each `useQuery` / `useMutation` names the operation it runs, cache policy (`fetchPolicy`), and the cache updates or refetches after a mutation.

### Config and environment

- The module that reads or validates the environment (`config/env.js`, `env.ts` with zod / envalid) gets each variable documented once, following the env map: meaning, type and unit, default, whether it is required, and whether it is a secret. Other files reference the config key, not the variable.
- Never copy a value from `.env` or any secret store into a comment. Do not open `.env` files; read `.env.example` for names and defaults.

### Background work (queues, cron, workers, streams)

- Job processors (`queue.process( 'name', … )`, BullMQ `Worker`, `node-cron` schedules, `setInterval` sweepers): the job or schedule name, its payload (follow the event map), concurrency, retries and backoff, idempotency, and what it cleans up.
- Stream and file handling (uploads, zip / unzip, `pipeline`): limits enforced (size, count, path safety), where temporary files go, and who deletes them.

### NestJS

- **Modules:** what they import, provide and export, and why something is `@Global()` or dynamic (`forRoot` / `forRootAsync` options).
- **Controllers:** the class comment names the route prefix and the guards, pipes and interceptors applied to all routes. Each handler: method and full path, guards and roles, the DTO validated, the response type and status (including `@HttpCode`), and the exceptions it throws (`NotFoundException` …).
- **Providers:** scope (default singleton, `REQUEST`, `TRANSIENT`), what they inject, and lifecycle hooks (`onModuleInit`, `onApplicationShutdown`). A constructor that only declares injected dependencies needs no doc comment.
- **DTOs and entities:** each property says what it means and its constraints in words. Decorators (`@IsEmail()`, `@Column()`) are code: never duplicate them in a tag, and never add `@example` or validation tags.
- **`@nestjs/swagger` with `introspectComments: true`** (in `nest-cli.json` plugin options): the summary on DTO properties and controller methods becomes the published OpenAPI `description` / `summary`. The rules file says whether the user accepted that; if not, document those declarations with `//` comments only, which the plugin ignores, and the facts file gives the coverage command `--line-docs` for those files so the `//` comments count. Never add `@ApiProperty` text or `@example` tags.
- Guards, pipes, interceptors, filters and custom decorators: what they read from the execution context, what they allow or reject, and the exception they throw.

### tRPC

- Routers: the procedure tree they define (`notes.byId`, `notes.create`). Each procedure (`publicProcedure.input( … ).query( … )`): query, mutation or subscription; the input schema; the middleware chain (`protectedProcedure` and what it checks); what it returns; the `TRPCError` codes it throws. Put the doc comment on the router property (`byId: publicProcedure…`).
- The context factory's shape is documented once (shapes list).

### Workers, CLIs and scripts

- A CLI entry: the command, its flags and arguments, exit codes, and what it reads and writes. Help text built by `commander` / `yargs` / `oclif` is code (string literals): never touch it, and never duplicate it in comments beyond a one-line summary.
- One-off scripts (`scripts/*.js`, `demo/*.js`): the header says what the script does, how to run it, and what it needs installed or running.
