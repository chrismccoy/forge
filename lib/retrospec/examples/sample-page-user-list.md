# User List

> **Route:** `/users`
> **Module:** User Management
> **Source:** `app/users/page.tsx`
> **Generated:** 2026-03-17

## Overview

Shows every system user in a searchable, filterable, paginated table. Admins and Managers use it to find users, create new accounts, and edit existing ones; Admins can also delete users. Users with the User role cannot open this page.

## Layout

```
┌────────────────────────────────────────────────────────┐
│ [Keyword    ] [Role ▾] [Status ▾] [Reset]  [+ Create]  │  ← filter bar
├────────────────────────────────────────────────────────┤
│ Name │ Email │ Role │ Status │ Created │ Actions       │  ← data table
│ ...                                                    │
├────────────────────────────────────────────────────────┤
│                       ‹ 1 2 3 › · 20 / page ▾          │  ← pagination
└────────────────────────────────────────────────────────┘
```

Create and Edit open the same modal form over the page.

## Fields

### Filter Bar

| Field | Type | Required | Options / Enum | Default | Notes |
|-------|------|----------|----------------|---------|-------|
| Keyword | Text input | No | — | Empty | Matches name or email. Searches after 2+ characters, 300 ms after typing stops |
| Role | Select | No | All, Admin, Manager, User ([UserRole](../appendix/enum-dictionary.md#userrole)) | All | Applies immediately on change |
| Status | Select | No | All, Active, Inactive, Suspended ([STATUS_MAP](../appendix/enum-dictionary.md#status_map)) | All | Applies immediately on change |

### Data Table

| Column | Format | Sortable | Filterable | Notes |
|--------|--------|----------|-----------|-------|
| Name | Text | Yes | No | Full name |
| Email | Link | Yes | No | Opens User Detail |
| Role | Colored badge | No | Via Role filter | Admin = purple, Manager = blue, User = gray |
| Status | Colored badge | No | Via Status filter | Active = green, Inactive = gray, Suspended = red |
| Created | Date `YYYY-MM-DD` | Yes | No | Default sort, newest first |
| Actions | Buttons | No | No | Edit, Delete (see below) |

### Create / Edit Modal

| Field | Type | Required | Options / Enum | Default | Validation |
|-------|------|----------|----------------|---------|------------|
| Name | Text input | Yes | — | Empty (create) / current (edit) | Max 50 characters |
| Email | Text input | Yes | — | Empty / current | Valid email format; read-only in edit mode |
| Role | Select | Yes | Admin, Manager, User | None (create) / current (edit) | Managers cannot pick Admin |
| Status | Select | No | Active, Inactive, Suspended | Active (create) / current (edit) | — |

### Actions

| Button | Visibility Condition | Behavior |
|--------|---------------------|----------|
| Create | Admin, Manager | Opens empty modal |
| Reset | Always | Clears all filters |
| Edit (row) | Admin: all rows. Manager: hidden on Admin rows | Opens modal prefilled with the row's user |
| Delete (row) | Admin only; hidden on the current user's own row | Confirmation, then delete |

## Interactions

### Page Load
- Loads page 1 with 20 rows, newest first, no filters.
- Shows a loading skeleton in the table until data arrives.
- If no users match, shows "No users found" with a Create button (Admin/Manager only).

### Search and Filter
- **Trigger:** Typing in Keyword, or changing Role or Status.
- **Behavior:** Reloads the table with the combined filters and returns to page 1.
- **Special rules:** Keyword waits for 2+ characters and a 300 ms pause. Filters combine with AND.

### Reset
- **Trigger:** Click "Reset".
- **Behavior:** Clears Keyword, sets Role and Status back to All, returns to page 1 with default sort.

### Sort
- **Trigger:** Click a sortable column header.
- **Behavior:** First click sorts ascending, second descending, third returns to default sort. Returns to page 1.

### Pagination
- **Trigger:** Click a page number, next/previous, or change page size.
- **Behavior:** Loads the selected page. Page size options: 10, 20, 50. Filters and sort are kept.

### Create User
- **Trigger:** Click "Create".
- **Modal/drawer content:** Create/Edit Modal fields above, empty.
- **Validation:** Inline, on blur and on submit. Submit button disabled while saving.
- **API:** `POST /api/users`
- **On success:** Toast "User created", close modal, reload current page.
- **On failure:** Duplicate email shows "Email already in use" under Email; other errors show the server message above the form.

### Edit User
- **Trigger:** Click "Edit" on a row.
- **Modal/drawer content:** Create/Edit Modal fields, prefilled; Email is read-only.
- **Validation:** Same as create.
- **API:** `PUT /api/users/:id`
- **On success:** Toast "User updated", close modal, reload current page.
- **On failure:** Server message shown above the form; modal stays open.

### Delete User
- **Trigger:** Click "Delete" on a row.
- **Confirmation:** Dialog "Are you sure you want to delete {name}?"
- **API:** `DELETE /api/users/:id`
- **On success:** Toast "User deleted", reload current page. If that empties the page, go to the previous page.
- **On failure:** Toast with the server message.

## API Dependencies

| API | Method | Path | Trigger | Status | Notes |
|-----|--------|------|---------|--------|-------|
| List users | GET | /api/users | Load, filter, sort, paginate, after any save | Integrated | Params: `page`, `size`, `keyword`, `role`, `status`, `sort` |
| Create user | POST | /api/users | Submit create modal | Integrated | Body: `name`, `email`, `role`, `status` |
| Update user | PUT | /api/users/:id | Submit edit modal | Integrated | Body: `name`, `role`, `status` |
| Delete user | DELETE | /api/users/:id | Confirm delete | Integrated | Soft delete — see Business Rules |

## Page Relationships

- **From:** Dashboard ("View Users" link, no params); main navigation.
- **To:** User Detail (click Email; passes `id`).
- **Data coupling:** None today. Dashboard user counts are `Mock`; once that API is real, creating or deleting a user should change them.

## Business Rules

- Deleting a user is a soft delete: the account disappears from this list and can no longer log in, but its record is kept. [TBC] Code sets `deleted_at` and no restore screen exists; whether Admins can restore deleted users elsewhere is not visible in the code.
- An Admin cannot delete their own account (the Delete button is hidden on their row).
- A Manager cannot create or promote anyone to Admin, and cannot edit an existing Admin.
- Email is the unique login identifier and cannot be changed after creation.
