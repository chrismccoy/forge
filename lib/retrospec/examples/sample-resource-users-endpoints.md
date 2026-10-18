# Users Endpoints

> **Route:** `/api/users`
> **Module:** User Management
> **Source:** `app/api/users/route.ts`, `app/api/users/[id]/route.ts`
> **Generated:** 2026-03-17

## Overview

Server endpoints behind the [User List](./03-user-list.md) and [User Detail](./04-user-detail.md) pages. They let Admins and Managers find, create, view, edit, and delete user accounts. Every call requires a logged-in session; what a caller may change depends on their role (see [UserRole](../appendix/enum-dictionary.md#userrole)).

## Endpoints

| Method | Path | Auth | Notes |
|--------|------|------|-------|
| GET | `/api/users` | Admin, Manager | Paginated, filterable list |
| POST | `/api/users` | Admin, Manager | Managers cannot create Admins |
| GET | `/api/users/:id` | Admin, Manager | Single user |
| PUT | `/api/users/:id` | Admin; Manager for non-Admin users | Email cannot change |
| DELETE | `/api/users/:id` | Admin only | Soft delete; cannot delete self |

## Fields

### User (response)

| Field | Type | Required | Validation | Notes |
|-------|------|----------|------------|-------|
| id | String | Yes | — | Assigned by the server |
| name | String | Yes | 1–50 characters | Full name |
| email | String | Yes | Valid email; unique | Login identifier; fixed after creation |
| role | Enum | Yes | `admin`, `manager`, `user` | See [UserRole](../appendix/enum-dictionary.md#userrole) |
| status | Enum | Yes | `active`, `inactive`, `suspended` | See [STATUS_MAP](../appendix/enum-dictionary.md#status_map) |
| createdAt | Date-time | Yes | — | Used for default sort |

### List query parameters (`GET /api/users`)

| Field | Type | Required | Validation | Notes |
|-------|------|----------|------------|-------|
| page | Integer | No | ≥ 1 | Default 1 |
| size | Integer | No | 10, 20, or 50 | Default 20 |
| keyword | String | No | Ignored under 2 characters | Matches name or email |
| role | Enum | No | `admin`, `manager`, `user` | Omit for all |
| status | Enum | No | `active`, `inactive`, `suspended` | Omit for all |
| sort | String | No | `name`, `email`, `createdAt`, with optional `-` prefix for descending | Default `-createdAt` |

## Interactions

### GET `/api/users`
- **Purpose:** Load one page of users for the User List table.
- **Request:** Query parameters above. Filters combine with AND.
- **Side effects:** None.
- **Response:** `{ items: User[], total, page, size }`. Soft-deleted users are never returned.

### POST `/api/users`
- **Purpose:** Create an account from the User List create modal.
- **Request:** `name`, `email`, `role` required; `status` optional (default `active`).
- **Side effects:** Stores the user. [TBC] No invitation email is sent from this route; whether one is sent elsewhere is not visible in the code.
- **Response:** `201` with the created User. `409` "Email already in use" on a duplicate email; `422` with per-field messages on validation failure; `403` when a Manager sets `role: admin`.

### GET `/api/users/:id`
- **Purpose:** Load one user for User Detail and the edit modal.
- **Request:** `id` in the path.
- **Side effects:** None.
- **Response:** The User. `404` if not found or soft-deleted.

### PUT `/api/users/:id`
- **Purpose:** Save changes from the edit modal.
- **Request:** `name`, `role`, `status`. An `email` value in the body is ignored.
- **Side effects:** Updates the user.
- **Response:** The updated User. `403` when a Manager edits an Admin or assigns `role: admin`; `404` if not found; `422` on validation failure.

### DELETE `/api/users/:id`
- **Purpose:** Remove a user from the User List.
- **Request:** `id` in the path.
- **Side effects:** Sets `deletedAt`; the user can no longer log in and disappears from lists. The record is kept.
- **Response:** `204`. `403` for non-Admins or when deleting one's own account; `404` if not found.

## Page Relationships
- **Called by:** [User List](./03-user-list.md) (list, create, edit, delete), [User Detail](./04-user-detail.md) (get).
- **Downstream:** None found. Dashboard user counts are `Mock` and do not read from these endpoints yet.

## Business Rules
- Email is the unique login identifier and cannot be changed after creation.
- Managers cannot create, promote to, or edit Admin accounts.
- Only Admins can delete users, and no one can delete their own account.
- Deletion is soft: the record stays with `deletedAt` set. [TBC] No restore endpoint exists.
