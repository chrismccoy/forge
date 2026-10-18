# Enum Dictionary

All enums, status codes, and constant mappings found in the codebase.

## UserRole
> **Source:** `types/user.ts`
> **Used in:** [User List](../pages/03-user-list.md), [User Detail](../pages/04-user-detail.md)

| Value | Label | Meaning |
|-------|-------|---------|
| `admin` | Admin | Full access, including deleting users and changing settings |
| `manager` | Manager | Can view, create, and edit non-Admin users; cannot delete users or assign the Admin role |
| `user` | User | Read-only; cannot open User Management |

## STATUS_MAP
> **Source:** `constants/status.ts`
> **Used in:** [User List](../pages/03-user-list.md), [User Detail](../pages/04-user-detail.md)

| Value | Label | Meaning | Color |
|-------|-------|---------|-------|
| `active` | Active | Normal account; can log in | Green |
| `inactive` | Inactive | Deactivated by an Admin or Manager; cannot log in until reactivated | Gray |
| `suspended` | Suspended | Blocked by an Admin or Manager, e.g. for a policy violation; cannot log in. [TBC] Code treats it the same as Inactive; the business difference is not visible | Red |
