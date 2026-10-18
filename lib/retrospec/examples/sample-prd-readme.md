# My App — Product Requirements Document

## System Overview

My App is an internal user management platform. Administrators and team managers use it to onboard staff, assign roles, and suspend or deactivate accounts. A dashboard gives managers an at-a-glance view of account counts and recent activity.

Primary users are internal operations staff. Access is role-based: what a user can see and change depends on whether they are an Admin, Manager, or regular User.

The dashboard's metrics are not yet backed by a real data source — see [Dashboard](./pages/02-dashboard.md) for the suggested API spec.

## Module Overview

| Module | Pages | Core Functionality |
|--------|-------|--------------------|
| Dashboard | Dashboard | Account metrics, recent activity feed |
| User Management | User List, User Detail | Create, view, edit, delete users; assign roles; change account status |
| Settings | Settings | System-wide configuration |

## Page Inventory

| # | Page Name | Route | Module | Doc Link |
|---|-----------|-------|--------|----------|
| 1 | Home | / | — | [→](./pages/01-home.md) |
| 2 | Dashboard | /dashboard | Dashboard | [→](./pages/02-dashboard.md) |
| 3 | User List | /users | User Management | [→](./pages/03-user-list.md) |
| 4 | User Detail | /users/:id | User Management | [→](./pages/04-user-detail.md) |
| 5 | Settings | /settings | Settings | [→](./pages/05-settings.md) |
| 6 | Users Endpoints | /api/users | User Management | [→](./pages/06-users-endpoints.md) |

Full endpoint list: [API Inventory](./appendix/api-inventory.md). Status and role values: [Enum Dictionary](./appendix/enum-dictionary.md). Navigation map: [Page Relationships](./appendix/page-relationships.md).

## Global Notes

### Permission Model

Three roles (see [UserRole](./appendix/enum-dictionary.md#userrole)):

| Role | Access |
|------|--------|
| Admin | Full access, including deleting users and changing settings |
| Manager | View, create, and edit non-Admin users; cannot delete users, assign Admin, or change settings |
| User | Read-only; cannot open User Management |

Pages a role cannot access are hidden from navigation. Visiting one directly redirects to the Dashboard.

### Common Interaction Patterns

- Every delete asks for confirmation first.
- Lists sort newest first by creation date and show 20 rows per page.
- Form errors appear inline under the field that failed.
- Successful saves show a short confirmation toast at the top right.
- Any request that fails because the session expired sends the user to the login page.
