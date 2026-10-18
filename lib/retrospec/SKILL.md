# Retrospec - codebase to PRD

Reverse-engineer a frontend, backend, or fullstack codebase into a complete Product Requirements Document. Work as a senior product analyst and technical architect: read the code, understand each page's business purpose, and write it up in product-manager-friendly language.

Paths in this file that start with `references/`, `examples/`, `assets/`, or `scripts/` are relative to `${CLAUDE_PLUGIN_ROOT}/lib/retrospec/`, the folder that contains this procedure file.

## Audience and Goal

Write for two readers at once:

1. **Product managers / business stakeholders** — need *what* the system does, not *how*.
2. **Engineers / AI agents** — need enough detail to **fully reconstruct** every page's fields, interactions, and relationships.

Describe functionality in non-technical language without omitting any business detail.

For **backend-only** projects, a "page" maps to an **API resource group** or **admin view**. The same three phases apply: routes become endpoints, components become controllers/views, interactions become request/response flows.

## Helper Scripts

Two stdlib-only scripts speed up Phase 1 and Phase 3. Their output is **leads, not ground truth** — confirm every route, API, and model in source before documenting it.

The scripts live in `${CLAUDE_PLUGIN_ROOT}/lib/retrospec/scripts/`, next to this procedure file. Call each one by that full path, run it from the **target project root** so output lands in the project, not the plugin, and run it as a command of its own (not chained with `;`, `&&`, or a pipe), so the pre-approved tool rules match. Write the analysis JSON to a temp path (e.g. `/tmp/prd-analysis.json`, or the platform's temp directory) so it never lands in the user's repo. For a monorepo, run the analyzer once per app directory — it only reads framework files at the path it is given:

```bash
python3 ${CLAUDE_PLUGIN_ROOT}/lib/retrospec/scripts/codebase_analyzer.py . -f markdown                  # quick summary
python3 ${CLAUDE_PLUGIN_ROOT}/lib/retrospec/scripts/codebase_analyzer.py . -o /tmp/prd-analysis.json    # JSON for scaffolder
python3 ${CLAUDE_PLUGIN_ROOT}/lib/retrospec/scripts/prd_scaffolder.py /tmp/prd-analysis.json --dry-run  # preview files
python3 ${CLAUDE_PLUGIN_ROOT}/lib/retrospec/scripts/prd_scaffolder.py /tmp/prd-analysis.json -o prd/ -n "<Project Name>"
```

The analyzer reports:
- **Pages:** React Router `<Route>` elements and router config files; file-system routes (Next.js App and Pages Router, Nuxt, SvelteKit, Remix, Astro); Express server-rendered GET routes, with the view template when resolvable.
- **Endpoints with HTTP methods:** Express and Fastify shorthand routes (Express mount prefixes resolved), NestJS (controller and global prefixes), Django/DRF (`include()` and router prefixes, generic views, viewsets), and file-system API routes.
- **Client API calls:** fetch, axios-style wrappers, XHR, template-literal and concatenated paths, each labelled Integrated or Mock.
- **Models and enums:** Django models with fields; NestJS entity/DTO and Pydantic class names; TypeScript enums and constant maps.

It skips test files and commented-out code, and reports paths relative to the project root.

**Before relying on the output**, read **`references/analyzer-gaps.md`** — the list of what the analyzer misses and what to check by hand.

**If the scaffolder exits with "No pages or endpoints found"** (FastAPI, Flask, or a monorepo root), skip it: build the inventory by hand in Phase 1 and create `prd/` from `references/output-templates.md`.

**Scaffold once.** The scaffolder refuses to write into a non-empty directory. Never pass `--force` over a `prd/` that already holds analysis work — it overwrites the README, appendices, and same-named stubs, and re-creates the original stubs beside any renamed ones.

**After scaffolding:** rename cryptic stubs to business names (`02-c-detail.md` → `02-collection-share.md`) and update README links. For server-rendered apps, fold form-post endpoints into the page that owns the form instead of keeping a separate resource stub.

---

## Phase 1 — Global Scan

Build global context before analyzing individual pages.

### 1. Identify Framework and Structure

Detect the framework from `package.json` (Node.js), `manage.py` (Django), or `requirements.txt` / `pyproject.toml` (Python). Routing, component, and state patterns differ by framework — consult **`references/framework-patterns.md`** for where each framework keeps routes, state, API calls, forms, permissions, and models.

Locate these areas:

- **Frontend:** pages/routes, components, route config, API/service layer, state management, i18n files (display names often live here).
- **Backend:** modules/apps, controllers/views, services, DTOs/serializers/forms, entities/models, guards/pipes/middleware, admin config, templates.

### 2. Build the Page Inventory

Extract every page into an inventory:

| Field | Description |
|-------|-------------|
| Route path | e.g. `/user/list`, `/order/:id` |
| Page title | From route config, breadcrumbs, or page component |
| Module / menu level | Position in navigation |
| Component file path | Source file(s) implementing the page |

For file-system routing (Next.js, Nuxt, SvelteKit, Remix, Astro), infer routes from the directory tree.

For backend projects, build an **endpoint inventory** instead: path, HTTP method, controller/view, owning module/app, auth requirement.

### 3. Map Global Context

Capture before page analysis, for reference throughout:

- Global state — user info, permissions, feature flags, config
- Shared components — layout, nav, auth guards, error boundaries
- Enums & constants — status codes, type mappings, role definitions
- API base config — base URL, interceptors, auth headers, error handling
- Backend: database models and relationships, middleware, DTO/serializer shapes. Django `admin.py`, NestJS guards/pipes, and model constraints often hold business rules — read them.

---

## Phase 2 — Page-by-Page Analysis

Analyze every page in the inventory. Each page produces its own Markdown file. Modals and drawers belong to their triggering page.

For focus areas by page type (list, form, detail, dashboard, CRUD resource, auth, webhook, job, admin), the full interaction checklist, and common pitfalls, consult **`references/analysis-strategies.md`**.

### A. Overview
State what the page does in one sentence, where it fits, and what scenario brings a user here.

### B. Layout & Regions
Identify major regions (search area, table, detail panel, action bar, tabs) and their spatial arrangement.

### C. Field Inventory — be exhaustive
- **Form pages:** every field with type, required, default, validation, business description.
- **List pages:** search/filter fields (with enum options), table columns (format, sortable, filterable), row actions.

Resolve display names in this priority order:
1. Hardcoded display text
2. i18n translation values
3. `placeholder` / `label` / `title` props
4. Variable names (last resort — derive a readable name)

### D. Interaction Logic
Describe each interaction as **user action → system response**: trigger, response, validation, API call, success and failure behavior. Work through the interaction coverage checklist in `references/analysis-strategies.md` for every page.

### E. API Dependencies

**Integrated APIs** (real HTTP calls): list name, method, path, trigger, key params, notes.

**Mock APIs**: when the page uses hardcoded fixtures, `setTimeout` / `Promise.resolve()` stubs, `*.mock.*` files, or `__mocks__/`, the API isn't real yet. Reverse-engineer the required spec from the page's data shape and label it `Mock`, using the "Mock API Specification" format in `references/output-templates.md`. Detection patterns: `references/framework-patterns.md` → "Mock Detection".

### F. Page Relationships
- **Inbound:** which pages link here, with what params
- **Outbound:** where users go next, with what params
- **Data coupling:** pages that share data or trigger refreshes in each other

---

## Phase 3 — Generate Documentation

Write output into `prd/` (or the user-specified directory): `README.md`, one file per page under `pages/`, and `appendix/` with `enum-dictionary.md`, `page-relationships.md`, and `api-inventory.md`.

Use the README, per-page, backend-variant, and appendix templates in **`references/output-templates.md`**. Match the depth and tone of the completed samples in `examples/`.

Before finishing, validate the output against **`references/prd-quality-checklist.md`**.

---

## Key Principles

1. **Business language first.** Not "calls `useState` to manage loading state" — instead "search button shows a spinner to prevent duplicate submissions." Keep technical details only where they affect product behavior: API paths, validation rules, permission conditions.
2. **Surface hidden logic.** Code holds rules stakeholders don't know exist — see "Hidden Logic to Hunt For" in `references/analysis-strategies.md`.
3. **List enums exhaustively.** Every value and its meaning, gathered from constants files, `valueEnum` configs, model `choices`, and response mappers.
4. **Mark uncertainty — never guess.** When business meaning can't be determined from code, mark it `[TBC]` and record what was observed and why it is unclear.
5. **Keep page files self-contained.** Reading one page file alone gives full understanding. Link other pages and appendix entries with relative links.

## Execution Pacing

- **≤15 pages:** complete all analysis in one pass.
- **>15 pages:** finish the README and page inventory first, then work in batches of 3–5 pages per module. Present each batch for user review before continuing.

---

## Additional Resources

### Scripts
- **`scripts/codebase_analyzer.py`** — scan a project and emit JSON or markdown (`-o FILE`, `-f markdown`)
- **`scripts/prd_scaffolder.py`** — build the `prd/` skeleton from analyzer JSON (`-o DIR`, `-n NAME`, `--validate-only`, `--dry-run`, `--force`)

### References
- **`references/framework-patterns.md`** — per-framework locations for routes, state, APIs, forms, permissions, models; mock detection patterns
- **`references/analyzer-gaps.md`** — what the analyzer misses and how to check it by hand
- **`references/analysis-strategies.md`** — page-type focus areas, interaction checklist, hidden logic, pitfalls
- **`references/output-templates.md`** — README, per-page, backend resource, and appendix templates
- **`references/prd-quality-checklist.md`** — completeness, accuracy, readability checks

### Examples
Completed samples from one PRD. Their relative links assume the full `prd/` tree, so they don't resolve inside `examples/`.
- **`examples/sample-prd-readme.md`** — completed system README
- **`examples/sample-page-user-list.md`** — completed list-page document
- **`examples/sample-resource-users-endpoints.md`** — completed backend resource document
- **`examples/sample-enum-dictionary.md`** — completed enum appendix

### Assets
- **`assets/sample-analysis.json`** — real analyzer output for a small Next.js app (the "My App" in the examples)
