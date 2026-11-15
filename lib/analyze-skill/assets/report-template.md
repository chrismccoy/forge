# Skill Summary: `<skill-name>`

> Target: `<absolute path to skill dir>` - Files: <n> - Analyzed: <today's date, YYYY-MM-DD>
> Report mode: <full | security | explain | interview | improve | compat>
> Depth: <full read | context budget applied | mode-scoped read | pasted text only - bundled files not verified>
> Plugin: <plugin name and root, with N plugin-level files reviewed | none>
> Runs on: <surfaces row, short form, blockers included: "claude.ai partial (no display)">
> Spec facts: analyze-skill's own references/skill-spec.md, verified <date in that file>
> Save path: <path> (user-specified)     <- only when the user named the path
> Skimmed: <files read partly>           <- only when the context budget applied

<Delete this line and every section the mode does not use (report-sections.md section 0). For a
mode other than full, change the title line, for example "# Skill Security Review: <name>".>

## 1. Executive Summary

<what it does, who invokes it, deliverable>

<shape: prose-only / script-backed / hybrid; workflow in one sentence>

<verdict: top strengths and risks>

| Dimension | Score | Reason |
|---|---|---|
| Triggering | /3 | |
| Frontmatter validity | /3 | |
| Structure & disclosure | /3 | |
| Instruction clarity | /3 | |
| Resources & scripts | /3 or N/A | |
| Safety & permissions | /3 | |
| Output contract | /3 | |
| Testability & robustness | /3 | |
| **Total** | **<score>/<max> (<pct>%)** | <verdict> |

<Scorecard: full and improve keep all 8 rows after the paragraphs; security writes, in order, its
"Verdict:" line, this table with only the Safety row (no Total row), then its paragraphs; other
modes delete the table.>

## 2. Skill Purpose & Trigger Conditions

Description (`SKILL.md:<line>`, <n> chars), quoted verbatim:

```text
<description>
```

- What it does: <...>
- When to use: <...>
- Invoker: <user / model / both>
- Done: <...>
- Trigger phrases: <every quoted phrase in the description, in order>
- Collisions: <installed (skill listing, session) or sibling skills that overlap, and which wins>

| Prompt | Should trigger? | Predicted | Why |
|---|---|---|---|

## 3. Frontmatter & Metadata Analysis

| Field | Value | Effect | Valid? | Notes |
|---|---|---|---|---|

## 4. Skill Body Structure

## 5. Script / Reference File Map

| File | Role in skill | Language/type | Invoked by / invokes | Inputs | Outputs & side effects | Risk notes |
|---|---|---|---|---|---|---|

<Prose-only skills: delete "### Per-file notes" and its text; keep "### Dependency map" (one line) and "### Missing and orphan files". Security mode: rename Per-file notes to "What each file can do".>

### Per-file notes

### Dependency map

### Missing and orphan files

## 6. Instruction & Wording Analysis

## 7. Techniques & Patterns Used

## 8. Invocation & Execution Flow

## 9. Output & Format Specification

## 10. Security & Permissions Review

| Risk | Evidence | Severity | Scenario | Mitigation |
|---|---|---|---|---|

**Scanner hits judged false positives:**

**Blind spots checked by hand:**

## 11. Evaluation / Testing / Behavior

**Triggering:** see section 2.

| Input | Expected output | Notes |
|---|---|---|

**Script tests:** <prose-only skill: replace this table with "None (prose-only skill).">

| Script | Fixture / input | Expected result |
|---|---|---|

## 12. Failure Modes & Robustness

| Mode | Where | Likelihood / impact | Symptom | Mitigation |
|---|---|---|---|---|

## 13. Dependencies, Compatibility & Pipeline

| Axis | Requirement | Confidence | Evidence |
|---|---|---|---|
| **Surfaces** | Claude Code <mark> · Cowork <mark> · claude.ai <mark> · Chrome <mark> · API <mark> | | |
| **Runtime** | | | |
| **Packages** | | | |
| **Tools** | | | |
| **Network** | | | |
| **Model** | | | |
| **Companions** | | | |
| **Degrades to** | | | |

<name the blocker after each ⚠️ or ❌ in the Surfaces row above, then delete this line>

**Declared vs detected:**

```yaml
compatibility: <suggested one-line value>
```

**Pipeline:**

## 14. Potential Interview / Review Questions

## 15. Optimization / Improvements

| # | Change | Where | Why / expected impact | Effort |
|---|---|---|---|---|

## 16. Appendix
