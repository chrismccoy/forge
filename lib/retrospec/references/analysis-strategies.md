# Analysis Strategies

Per-page-type focus areas, interaction coverage, and common pitfalls for Phase 2 analysis. Framework-specific file locations live in `framework-patterns.md`.

## Page Type Strategies

### Frontend Pages

| Page Type | Focus Areas |
|-----------|------------|
| **List / Table** | Search conditions, columns, row actions, pagination, bulk ops |
| **Form / Create-Edit** | Every field, validation, interdependencies, post-submit behavior |
| **Detail / View** | Displayed info, tab/section organization, available actions |
| **Modal / Drawer** | Describe as part of the triggering page — not a separate file. Document content fully |
| **Dashboard** | Data cards, charts, metric meaning, filter dimensions, refresh frequency |

### Backend Endpoints (NestJS / Django / Express / FastAPI)

| Endpoint Type | Focus Areas |
|---------------|------------|
| **CRUD resource** | All fields (from DTO/serializer), validation rules, permissions, pagination, filtering, sorting |
| **Auth endpoints** | Login/register flow, token format, refresh logic, password reset, OAuth providers |
| **File upload** | Accepted types, size limits, storage destination, processing pipeline |
| **Webhook / event** | Trigger conditions, payload shape, retry policy, idempotency |
| **Background job** | Trigger, schedule, input/output, failure handling, monitoring |
| **Admin views** (Django) | Registered models, list_display, search_fields, filters, inline models, custom actions |

## Interaction Coverage Checklist

Cover every applicable interaction type per page:

- Page load / initialization (default queries, preloaded data)
- Search / filter / reset
- CRUD operations (create, read, update, delete)
- Table: pagination, sorting, row selection, bulk actions
- Form submission & validation
- Status transitions (e.g. approval flows: pending → approved → rejected)
- Import / export
- Field interdependencies (selecting value A changes options in field B)
- Permission controls (buttons/fields visible only to certain roles)
- Polling / auto-refresh / real-time updates

## Hidden Logic to Hunt For

Code often contains logic stakeholders don't know exists:

- Field interdependencies (type A shows field X; type B shows field Y)
- Conditional button visibility
- Data formatting (currency with 2 decimals, date formats, status label mappings)
- Default sort order and page size
- Debounce/throttle on user input
- Polling / auto-refresh intervals

## Common Pitfalls

| Pitfall | Fix |
|---------|-----|
| Using component names as page names | `UserManagementTable` → "User Management List" |
| Skipping modals and drawers | They contain critical business logic — document fully |
| Missing i18n field names | Check translation files, not just component JSX |
| Ignoring dynamic route params | `/order/:id` = page requires an order ID to load |
| Forgetting permission controls | Document which roles see which buttons/pages |
| Assuming all APIs are real | Check for mock data patterns before documenting endpoints |
| Skipping Django admin customization | `admin.py` often contains critical business rules (list filters, custom actions, inlines) |
| Missing NestJS guards/pipes | `@UseGuards`, `@UsePipes` contain auth and validation logic that affects behavior |
| Ignoring database constraints | Model field constraints (unique, max_length, choices) are validation rules for the PRD |
| Overlooking middleware | Auth middleware, rate limiters, and CORS config define system-wide behavior |
