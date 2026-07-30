# Summary Block

Generate this block **last**, after all 16 sections. Place it after Section 16 under an H2 header `## Summary`.

## Required Sub-Blocks

### Top 5 Critical Issues

Five highest-priority findings drawn from Sections 1-16. Each entry must:

- Reference the section number where it was found.
- Be a real finding written above (no invention).

### File Impact Matrix

Table format:

| File | Issues Found | Priority | Sections Affected |
|---|---|---|---|

Example row:

| `src/auth/session.js` | 4 | HIGH | 2, 5, 8, 10 |

Constraints:

- List only files actually read.
- Sort by priority descending, then by issue count descending.
- Cap at 50 rows.

### Issue Summary Table

Table format:

| Issue | Section | Priority | Estimated Effort |
|---|---|---|---|

Example row:

| God class `UserManager` mixes auth + persistence + logging | 8 | CRITICAL | Moderate |

Constraints:

- Every row must map to a finding written in Sections 1-16.
- Estimated Effort uses: `Simple` / `Moderate` / `Complex`.
- Cap at 50 rows.

## Validation Before Emit

Run the STEP 17 checklist from `constraints.md` silently before emitting the report. Do not narrate the checks. Regenerate any failing section or table before output.
