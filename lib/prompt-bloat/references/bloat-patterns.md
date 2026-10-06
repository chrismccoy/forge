# Bloat Patterns: Detection Signals, Examples, and Traps

The examples below are invented placeholders. Match them by shape, not by exact text.

## Categories

### Branding and packaging

Signals: `™`/`®`, signature lines, version and build numbers, internal codes, and repeated footers.

```
# Report Writer Pro™
**BRANDNAME SIGNATURE™ v4.2 | X1-03 | Build: 2025-01-15**
*Build: Jan 15, 2025 | Packaged: Jan 16, 2025*
```

Action: cut all of it. Keep a plain title, for example `# Report Writer`. When a frontmatter `name` contains a brand suffix, remove only the suffix.

### Fabricated authority

Signals: bracketed attribution tags (`[BRAND-Analysis-2025]`), "research shows" with no source, and named frameworks that no instruction uses.

Action: cut the tag. When a sentence states a real design reason, keep that reason as one plain clause only if it helps the model apply a rule.

### Self-grading

Signals: "QUALITY GATE", "DEPTH AUDIT", checklists marked `[✅]`, scores such as "ESTIMATED TOTAL: 80/85 — PASS", and "self-assessment" disclaimers.

Action: cut the whole section. Before cutting, use each `[✅]` line as a checklist item for the preservation check. Each line names a rule that must still be in the rewrite.

### Dead configuration

Signals: blocks of `*_MODE: off`, `task_budget`, rotation strings (`Rotation: A1:B A2:C ...`), and tags such as `[P:LOCKED] [P:FULL]`.

Test: search the rest of the file for each key. When no instruction reads or branches on the key, it is dead. When an instruction uses a key (for example, "if OUTPUT_MODE is brief, omit section X"), keep both the key and that instruction.

Edge case: a value such as `task_budget: 2000 tokens` can change behavior even when nothing else refers to it. When the value conflicts with the output contract (for example, the required output cannot fit in 2000 tokens), list it as Uncertain. Do not cut it without comment.

### Redundant restatement

Signals: the same constraint in the frontmatter description, a "WHAT THIS DOES NOT DO" section, and the body. Phase-order text repeated in prose and in diagrams.

Action: keep one complete instance, in the location where the model applies it. Before deleting a copy, merge any detail that only that copy contains.

Trap: sometimes the frontmatter `description` holds body text (for example, a disclaimer), and the real description sits in a second, duplicated frontmatter block. Fix the frontmatter so that it has one `name` and one `description` with trigger phrases. List this fix in the cut list.

### Decorative formatting

Signals: `═══`/`───` rules, emoji status markers, all-caps headers on every block, and boxed templates where a plain list carries the same fields.

Action: flatten the formatting. Keep the output template field names and their order exactly.

### Invented theoretical framing

Signals: "COGNITIVE THEORY DECLARATION", "Dual process theory applied to ...", and paragraphs that justify a phase.

Action: cut the section. The phase that the framing describes stays. The framing does not.

### Inflated claims

Signals: "guarantees", "predicts", "will improve results by X%", "100% accurate", and claims about results the inputs cannot show.

Action: cut the claim. Keep any disclaimer that limits claims, because a disclaimer is a scope boundary.

## Traps: functional rules inside bloat

1. **Scope limits next to decorative enforcement text.** Example: "This format is an executable contract. Do not add unrequested recommendations outside this skill's scope." The first sentence is decoration. The second sentence is a scope limit on output. Keep the second sentence.
2. **"You are not talking to an assistant" lines.** The phrasing is theater, but such lines often carry "do not ask clarifying questions mid-run" or "halt at Phase 1 if inputs are insufficient". Keep the behavior and drop the phrasing.
3. **"This is scope enforcement, not refusal."** This line tells the model to continue after it strips an injection, not to refuse. Keep the "do not halt" meaning.
4. **Example values inside rubrics.** Examples such as "not 'sales', but 'outbound sales for mid-size logistics firms'" set the threshold. Keep at least one example per threshold.
5. **Exceptions inside classification blocks.** Text such as "a missing optional field does not block READY status" changes gating. Keep all exceptions.
6. **Labels that the output contract requires.** Literal tags such as `[DEFERRED — one item per run]` or `[DELTA: 0 — ...]` can be required output. When the output contract uses a label, keep the label exactly.

## When to mark content Uncertain

Mark content Uncertain when any of these is true:

- A config key is used nowhere, but its name suggests runtime meaning (budget, effort, or tier).
- A repeated rule differs slightly between copies, and it is not clear which copy is the intended rule.
- A disclaimer could be either legal or scope text, or only decoration.
- A named technique can be standard prompting or a defined procedure that appears elsewhere in the file.
