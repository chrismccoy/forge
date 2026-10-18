# PRD Output Templates

Templates for Phase 3 document generation. `scripts/prd_scaffolder.py` produces rough stubs; treat these templates as the target format and reshape stubs to match. Completed samples live in `examples/`.

## Output Structure

Create `prd/` in the project root (or a user-specified directory):

```
prd/
├── README.md                     # System overview
├── pages/
│   ├── 01-user-list.md           # One file per page / resource group
│   ├── 02-user-detail.md
│   ├── 03-order-list.md
│   └── ...
└── appendix/
    ├── enum-dictionary.md         # All enums, status codes, type mappings
    ├── page-relationships.md      # Navigation map between pages
    └── api-inventory.md           # Complete API reference
```

Name page files `NN-<business-name>.md` in navigation order (e.g. `03-user-list.md`). Scaffolder stubs are named from route slugs (`04-users.md`, `05-users-detail.md`); rename them to business names and update README links.

## README.md Template

```markdown
# [System Name] — Product Requirements Document

## System Overview
[2-3 paragraphs: what the system does, business context, primary users]

## Module Overview

| Module | Pages | Core Functionality |
|--------|-------|--------------------|
| User Management | User List, User Detail, Role Management | CRUD users, assign roles and permissions |

## Page Inventory

| # | Page Name | Route | Module | Doc Link |
|---|-----------|-------|--------|----------|
| 1 | User List | /user/list | User Mgmt | [→](./pages/01-user-list.md) |

Full endpoint list: [API Inventory](./appendix/api-inventory.md). Status and type values: [Enum Dictionary](./appendix/enum-dictionary.md). Navigation map: [Page Relationships](./appendix/page-relationships.md).

## Global Notes

### Permission Model
[Summarize auth/role system if present in code]

### Common Interaction Patterns
[Global rules: all deletes require confirmation, lists default to created_at desc, etc.]
```

## Per-Page Document Template

```markdown
# [Page Name]

> **Route:** `/xxx/xxx`
> **Module:** [Module name]
> **Source:** `[path/to/page/component]`
> **Generated:** [Date]

## Overview
[2-3 sentences: core function and use case]

## Layout
[Region breakdown — text description or ASCII diagram]

## Fields

### [Region: e.g. "Search Filters"]
| Field | Type | Required | Options / Enum | Default | Notes |
|-------|------|----------|---------------|---------|-------|

<!-- For form regions, a `Validation` column may replace `Notes`. -->

### [Region: e.g. "Data Table"]
| Column | Format | Sortable | Filterable | Notes |
|--------|--------|----------|-----------|-------|

### [Region: e.g. "Actions"]
| Button | Visibility Condition | Behavior |
|--------|---------------------|----------|

## Interactions

### Page Load
[What happens on mount]

### [Scenario: e.g. "Search"]
- **Trigger:** [User action]
- **Behavior:** [System response]
- **Special rules:** [If any]

### [Scenario: e.g. "Create"]
- **Trigger:** ...
- **Modal/drawer content:** [Fields and logic inside]
- **Validation:** ...
- **API:** [Method + path]
- **On success:** ...
- **On failure:** ...

### [Scenario: e.g. "Delete"]
- **Trigger:** ...
- **Confirmation:** [Dialog text, or "none"]
- **API:** [Method + path]
- **On success:** ...
- **On failure:** ...

## API Dependencies

| API | Method | Path | Trigger | Status | Notes |
|-----|--------|------|---------|--------|-------|
| ... | ... | ... | ... | Integrated / Mock | ... |

## Page Relationships
- **From:** [Source pages + params]
- **To:** [Target pages + params]
- **Data coupling:** [Cross-page refresh triggers]

## Business Rules
[Anything that doesn't fit above]
```

## Backend Resource Variant

For backend-only projects, use the per-page template with these substitutions:

| Page section | Backend equivalent |
|--------------|--------------------|
| Route | Base path of the resource group (e.g. `/api/orders`) |
| Layout | Omit, or replace with "Endpoints" summary table (method, path, auth) |
| Fields | Request body / query params (from DTO, serializer, Pydantic model) and response fields |
| Actions | Endpoints with permission requirements |
| Interactions | Request → validation → side effects → response, per endpoint |
| Page Relationships | Calling clients, downstream services, emitted events/jobs |

## Interaction Notation

When a scenario is complex, use the action/response block form:

```
[Action]     User clicks "Create"
[Response]   Modal opens with form fields: ...
[Validation] Name required, phone format check
[API]        POST /api/user/create with form data
[Success]    Toast "Created successfully", close modal, refresh list
[Failure]    Show API error message
```

## Mock API Specification

When a page uses mock data, document each required API in the page's API Dependencies section with:

- Method, suggested path, trigger
- Input params (name, type, required, description)
- Output fields (name, type, description)
- Core business logic description
- Status `Mock` (use this exact label everywhere: page API tables, api-inventory, README)

## Appendix Templates

### enum-dictionary.md

```markdown
# Enum Dictionary

## [Enum name, e.g. Order Status]
> **Source:** `src/constants/order.ts`
> **Used in:** [Order List](../pages/03-order-list.md), [Order Detail](../pages/04-order-detail.md)

| Value | Label | Meaning |
|-------|-------|---------|
| 0 | Pending | Awaiting payment |
```

Add extra columns (e.g. `Color`) after `Meaning` when the UI uses them.

See `examples/sample-enum-dictionary.md` for a completed sample.

### api-inventory.md

```markdown
# API Inventory

| Method | Path | Status | Used By | Auth | Notes |
|--------|------|--------|---------|------|-------|
| GET | /api/users | Integrated | [User List](../pages/01-user-list.md) | Login | Paginated |
| GET | /api/dashboard/stats | Mock | [Dashboard](../pages/02-dashboard.md) | Login | Suggested spec in page doc |
```

Status is `Integrated` or `Mock`. The scaffolder splits client calls and server endpoints into two tables and fills "Used By" with source file paths, without an Auth column; replace the file paths with page links and add Auth before finishing.

### page-relationships.md

```markdown
# Page Relationships

## Navigation Map
User List ──(click row)──▶ User Detail (:id)
User Detail ──(Back)──▶ User List

## Cross-Page Data Dependencies

| Source Page | Target Page | Trigger | Data Passed |
|-------------|-------------|---------|-------------|
| User List | User Detail | Row click | `id` |
| User Detail | User List | Delete success | Refresh list |
```
