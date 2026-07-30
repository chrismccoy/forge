# Output Contract (Mandatory)

Apply to every run. No exceptions.

## Section Rendering

- Render every section under its exact header from `framework.md`.
- Skip a section ONLY with the line: `## SECTION N - N/A (reason)` (keep the `## SECTION N -` header form).
- Max 250 words per section 1-9. Use bullets, not prose walls.

### Section 1-9 sample shape

Use the exact section header from `framework.md`, including its emoji marker (e.g. `## 🏗️ SECTION 1 - Architecture Assessment`). The `## SECTION N - Title` below is shorthand for that form.

```
## SECTION N - Title
- Finding: The site loads 14 plugins on every request, including 3 that
  only run in admin. This adds ~400ms to first-byte on the front end.
- Impact: Slower TTFB hurts conversion and Core Web Vitals ranking.
- Recommendation: Gate the 3 admin-only plugins behind is_admin(), or
  move them to an mu-plugin loaded conditionally.
```

## Section 10 Scales (every run)

- Health Score, Performance, Security, Scalability, Code Quality: **0-100**
- Technical Debt Severity: **Low / Medium / High / Critical**
- Priorities: ranked list, **max 5 items**

## Summary Table

End with a single Markdown summary table of all Section 10 scores. It must be the final element of the output.

Exact columns:

```
| Metric | Score | Severity |
|--------|-------|----------|
| Health Score | 0-100 | - |
| Performance | 0-100 | - |
| Security | 0-100 | - |
| Scalability | 0-100 | - |
| Code Quality | 0-100 | - |
| Technical Debt | - | Low/Medium/High/Critical |
```

## Pre-Delivery Validation Checklist

Run silently before sending. Fix any failure before output:

- [ ] All 10 sections present, or explicitly marked `## SECTION N - N/A (reason)`.
- [ ] Every Section 10 score uses its defined scale.
- [ ] Section 1-9 each ≤ 250 words.
- [ ] No security rating given without naming what was checked.
- [ ] Summary table is the final element.
