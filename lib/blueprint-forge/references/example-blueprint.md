# APP BLUEPRINT
<!-- blueprint-format: 2 | generated-by: scan-prompt v2.6 | scope: full | source: example/taskapp -->

## 1. Project Summary
A simple task management web app where users can sign up, create projects,
and add/complete tasks within them. Includes basic auth and a REST API
backing a React frontend.

## 2. Tech Stack
- Language: TypeScript 5.4 (lockfile)
- Runtime: Node 20 (manifest range, `engines.node: ">=20"`)
- Backend: Express 4.19.2 (lockfile)
- Frontend: React 18.3.1 (lockfile) + Vite 5.2.11 (lockfile)
- Routing (frontend): react-router-dom 6.23.1 (lockfile)
- Database: PostgreSQL 15 (inferred from `postgres:15` image in
  docker-compose.yml)
- ORM: Prisma 5.14.0 (lockfile)
- Auth: jsonwebtoken 9.0.2 + bcrypt 5.1.1 (lockfile)
- Package manager: npm (package-lock.json, lockfileVersion 3)
- Styling: Tailwind CSS 3.4.3 (lockfile)
- Testing: Vitest 1.6.0 (frontend), Jest 29.7.0 + Supertest 7.0.0
  (backend) (lockfile)
- Deployment: Dockerized, deployed on Railway (inferred from
  `railway.json`)

## 3. Architecture

```
React SPA (Vite)
      |
      v  (fetch / REST, JSON over HTTPS)
Express API Server
      |
      v  (Prisma Client)
PostgreSQL Database
```

Monolithic API with a separate SPA frontend. The frontend calls the API
through thin fetch wrappers in `client/src/api`. The API is stateless;
all persistent state lives in PostgreSQL.

## 4. Auth & State
- Authentication: email + password. On signup/login the server returns a
  JWT signed with `JWT_SECRET` (HS256, expires in 7 days). No refresh
  token flow.
- Token storage: client stores the JWT in `localStorage` under key
  `token` and sends it as `Authorization: Bearer <token>`.
- Authorization: Express middleware validates the JWT on all
  `/api/projects` and `/api/tasks` routes. Route handlers check that the
  project belongs to the requesting user (`ownerId === userId`) and return
  404 otherwise.
- Client state: React Context (`AuthContext`) for the current user and
  token. Data fetched per page with `useEffect`; no global cache library.
- Server-side state: none (no caches, queues, or background jobs).

## 5. Folder Structure

```
repo-root/
  client/          - React frontend (Vite app)
    src/
      pages/       - Route-level components (Login, Signup, Dashboard, Project)
      components/  - Reusable UI components (TaskCard, ProjectCard, Navbar, Modal)
      hooks/       - Custom hooks (useAuth, useProjects)
      api/         - Fetch wrappers for backend endpoints
  server/          - Express backend
    src/
      routes/      - Route handlers (auth.ts, projects.ts, tasks.ts)
      middleware/  - Auth middleware, error handler
      prisma/      - schema.prisma, migrations/
    tests/         - Jest + Supertest route tests
    package.json
  docker-compose.yml
  Dockerfile
  railway.json
```

### Module Map
- `server/src/index.ts` — no exports; loads env, calls `createApp()`, listens on `PORT`
- `server/src/app.ts` — `createApp(deps?: { prisma?: PrismaClient }): express.Application`
- `server/src/middleware/auth.ts` — `requireAuth(req: Request, res: Response, next: NextFunction): void` (sets `req.userId: string`; 401 on missing/invalid token)
- `server/src/middleware/errors.ts` — `errorHandler(err: Error, req, res, next): void` (500 JSON `{ error: string }`)
- `server/src/routes/auth.ts` — `authRouter: express.Router`; `signToken(userId: string): string`
- `server/src/routes/projects.ts` — `projectsRouter: express.Router`
- `server/src/routes/tasks.ts` — `tasksRouter: express.Router`
- `client/src/api/client.ts` — `apiFetch<T>(path: string, init?: RequestInit): Promise<T>` (adds Bearer token, throws `ApiError { status: number; message: string }`)
- `client/src/api/projects.ts` — `listProjects(): Promise<Project[]>`; `createProject(name: string): Promise<Project>`
- `client/src/api/tasks.ts` — `listTasks(projectId: string): Promise<Task[]>`; `createTask(projectId: string, title: string): Promise<Task>`; `setTaskCompleted(id: string, completed: boolean): Promise<Task>`; `deleteTask(id: string): Promise<void>`
- `client/src/hooks/useAuth.ts` — `AuthProvider({ children }): JSX.Element`; `useAuth(): { user: PublicUser | null; token: string | null; login(email: string, password: string): Promise<void>; logout(): void }`
- `client/src/hooks/useProjects.ts` — `useProjects(): { projects: Project[]; loading: boolean; error: string | null; refresh(): Promise<void> }`

## 6. Data Models / Schema

User
- id: uuid, primary key, default uuid()
- email: string, unique
- passwordHash: string
- createdAt: datetime, default now()

Project
- id: uuid, primary key, default uuid()
- name: string
- ownerId: uuid, foreign key -> User.id, on delete cascade
- createdAt: datetime, default now()

Task
- id: uuid, primary key, default uuid()
- title: string
- completed: boolean, default false
- projectId: uuid, foreign key -> Project.id, on delete cascade
- createdAt: datetime, default now()

Relationships:
- User 1--many Project
- Project 1--many Task

Migrations: Prisma Migrate (`server/src/prisma/migrations/`). No seed data.

## 7. API Endpoints

| Method | Path                    | Purpose                      | Auth |
|--------|-------------------------|------------------------------|------|
| POST   | /api/auth/signup        | Create new user account      | No   |
| POST   | /api/auth/login         | Log in, returns JWT          | No   |
| GET    | /api/projects           | List current user's projects | Yes  |
| POST   | /api/projects           | Create a new project         | Yes  |
| GET    | /api/projects/:id/tasks | List tasks for a project     | Yes  |
| POST   | /api/projects/:id/tasks | Create a task in a project   | Yes  |
| PATCH  | /api/tasks/:id          | Toggle task completed state  | Yes  |
| DELETE | /api/tasks/:id          | Delete a task                | Yes  |

Request/response types:
- `type PublicUser = { id: string; email: string; createdAt: string }`
- POST /api/auth/signup: `body: { email: string; password: string }` ->
  `201 { token: string; user: PublicUser }`; `409` if email exists;
  `400` if password shorter than 8 characters
- POST /api/auth/login: `body: { email: string; password: string }` ->
  `200 { token: string; user: PublicUser }`; `401` on bad credentials
- GET /api/projects -> `200 { projects: Project[] }`
- POST /api/projects: `body: { name: string }` -> `201 { project: Project }`
- GET /api/projects/:id/tasks -> `200 { tasks: Task[] }`; `404` if not owner
- POST /api/projects/:id/tasks: `body: { title: string }` ->
  `201 { task: Task }`; `404` if not owner
- PATCH /api/tasks/:id: `body: { completed: boolean }` ->
  `200 { task: Task }`; `404` if not owner
- DELETE /api/tasks/:id -> `204`; `404` if not owner
- All protected routes return `401` if the token is missing or invalid.

## 8. Core Features

1. **Authentication** — Signup/login with email+password. Passwords hashed
   with bcrypt (10 rounds). JWT expires after 7 days. No refresh token
   flow implemented.
2. **Project Management** — Users can create projects they own. No sharing
   or collaboration between users (single-owner model only).
3. **Task Management** — Tasks belong to a project, can be marked complete
   via a checkbox, and deleted. No due dates or priority fields.
4. **Route Protection** — Frontend redirects to /login if no valid JWT is
   found in localStorage. Backend middleware validates JWT on all
   /api/projects and /api/tasks routes.

## 9. UI Structure

Pages:
- /login — Login form
- /signup — Signup form
- /dashboard — List of user's projects, "New Project" button
- /projects/:id — Task list for a project, add/complete/delete tasks

Components:
- Navbar — top bar with logout button
- ProjectCard — used on dashboard
- TaskCard — checkbox + title + delete button
- Modal — generic modal used for "New Project" and "New Task" forms

Styling: Tailwind utility classes throughout, no custom design system.

States handled: loading spinners on data fetch, empty state ("No projects
yet") on dashboard, inline error messages on failed login/signup.

## 10. Environment Variables

- DATABASE_URL — PostgreSQL connection string — no default
  (`.env` value: `[REDACTED]`)
- JWT_SECRET — secret used to sign/verify JWTs — no default
  (`.env` value: `[REDACTED]`)
- PORT — server port — default `4000`
- VITE_API_URL — base URL the frontend uses to call the backend API —
  default `http://localhost:4000`

## 11. Config Files

- `server/tsconfig.json` — `strict: true`, target ES2022, CommonJS output
  to `dist/`
- `client/vite.config.ts` — React plugin; dev server proxies `/api` to
  `http://localhost:4000`
- `client/tailwind.config.js` — content globs `./index.html`,
  `./src/**/*.{ts,tsx}`; no theme extensions
- `.eslintrc.cjs` (root) — `eslint:recommended` +
  `@typescript-eslint/recommended` + `react-hooks` plugin
- `.prettierrc` — `singleQuote: true`, `semi: true`, `printWidth: 100`
- `docker-compose.yml` — services `db` (`postgres:15`, port 5432, named
  volume) and `app` (built from Dockerfile, depends on `db`)
- `Dockerfile` — multi-stage: build client and server, run
  `node server/dist/index.js`
- `railway.json` — Dockerfile builder; start command runs
  `npx prisma migrate deploy` before the server

## 12. Testing & Tooling

- Backend: Jest + Supertest, `npm test --workspace server`. Covers auth
  routes (signup, login, bad credentials) and project/task ownership
  checks. Uses a separate test database via `DATABASE_URL` in `.env.test`.
- Frontend: Vitest + Testing Library, `npm test --workspace client`.
  Covers TaskCard toggle/delete and the Login form error state.
- Lint/format: `npm run lint` (ESLint), `npm run format` (Prettier).
- CI: none found. UNKNOWN: whether tests or lint gate merges.

## 13. Open Questions

- ASSUMPTION: No password reset flow exists. Evidence: no reset route, no
  email library in dependencies.
- UNKNOWN: Whether tests or lint gate merges (no CI config in repo).

## 14. Step-by-Step Rebuild Instructions

1. Init a new Node project with npm workspaces: `client` (Vite + React +
   TS) and `server` (Express + TS).
2. Install backend deps: express, prisma, @prisma/client, bcrypt,
   jsonwebtoken, cors, dotenv. Dev deps: typescript, jest, ts-jest,
   supertest.
3. Install frontend deps: react, react-dom, react-router-dom, tailwindcss.
   Dev deps: vitest, @testing-library/react.
4. Add the config files from section 11 (tsconfig, vite config, tailwind,
   ESLint, Prettier).
5. Define the Prisma schema with User, Project, Task models as described in
   section 6. Run a migration to create the PostgreSQL tables.
6. Build auth routes (signup/login) with bcrypt hashing and JWT signing.
7. Build auth middleware that validates the Bearer token on protected
   routes.
8. Build projects and tasks routes per the API table in section 7,
   including ownership checks and status codes.
9. Scaffold React pages: Login, Signup, Dashboard, Project.
10. Build `AuthContext` and `useAuth` to store/retrieve the JWT from
    localStorage and gate protected routes.
11. Build API wrapper functions in `client/src/api` to call each backend
    endpoint.
12. Style pages/components with Tailwind per section 9.
13. Add `.env.example` with the four variables from section 10.
14. Write the Dockerfile + docker-compose.yml for local Postgres + app.
15. Add tests per section 12 (Jest + Supertest for backend routes, Vitest
    for key components).
16. Deploy: build the Docker image, push to Railway (or equivalent), set
    env vars in the host dashboard.
