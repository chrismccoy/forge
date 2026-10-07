# Scoring Rubric

Score each dimension as the sum of its sub-checks, then apply caps. A cap
sets the highest score the dimension can receive when its condition holds.
When several caps hold, apply the lowest. Partial credit only when a layer
is present but incomplete.

Caps marked **(CRITICAL)** make the finding 🔴 CRITICAL in the fix list.
All other caps are 🟡 IMPORTANT.

Every deduction follows the citation rule in SKILL.md.

---

## 1. Role & Authority — /10

- Expert persona defined (0–3)
- Domain expertise credibly specified (0–3)
- Operational boundaries defined — what the role does not do (0–2)
- Authority level fits the task (0–2)

Caps:
- Vague role ("you are an expert") → max 7
- No role, or generic "helpful assistant" → max 4 **(CRITICAL)**. Both
  count the same: a generic label gives no more direction than none.

## 2. Task Clarity — /15

- Primary task is unambiguous (0–4)
- Constraints are explicit and stated as firm rules (0–4). Clear wording
  earns the points; all-caps or MUST emphasis earns nothing extra.
- Edge cases addressed — empty input, off-topic, conflicting input (0–4)
- Scope bounded (0–3)

Caps:
- No explicit constraints → max 9
- Task readable two or more ways → max 9
- No boundaries of any kind → max 7

## 3. Output Architecture — /15

- Output format explicitly defined (0–4)
- Length / depth specified and fits the task (0–3)
- Structure locked ("use exactly these sections"), not suggested (0–4)
- Example or template of the output provided (0–4)

Caps:
- Format undefined → max 9
- "Answer naturally" or equivalent → max 7
- No structure and no format → max 5 **(CRITICAL)**

## 4. Accuracy — /10

- Claims traceable — no unsupported stats, sources, guarantees (0–4)
- No contradictions between sections (0–3)
- No fabricated capabilities — browsing, memory, tools the model lacks
  (0–3). Any fabricated capability is **(CRITICAL)**.

Investment / finance flag: also deduct under "claims traceable" when the
prompt lacks a not-financial-advice disclaimer (−2) or promises returns or
outcomes (−2).

## 5. Structure — /10

- Layer completeness: role, context, task, constraints, output (0–5).
  Structure checks only that each section exists and is separate; the
  quality of the role is scored under Role & Authority.
- Logical ordering — context before task, rules before format (0–3)
- No duplicated or conflicting sections (0–2)

## 6. Language — /10

- Blocked words: start at 5, −1 per distinct hit from the Step 3 scan,
  floor 0 (0–5)
- Natural human cadence, not robotic (0–3)
- Precise without jargon overload (0–2)

## 7. Protection — /15

- Injection resistance — user input treated as data (0–5)
- Scope-creep prevention — refuses off-task requests (0–5)
- Output validation layer — before emitting, the model checks its output
  against the prompt's rules and format (0–5)

No-input prompts: when the prompt takes no free-form user input (a
single-shot template whose only inputs are short `[VARIABLE]` fills counts
as having input; a fixed prompt run with no user text does not), mark
injection resistance and scope-creep prevention N/A and rescale:
`Protection = round(points earned ÷ (5 × applicable sub-checks) × 15)`.

Caps (skip a cap whose sub-check is N/A):
- No scope limits → max 8
- No injection defense → max 9
- No guardrails of any kind → max 5 **(CRITICAL)**

## 8. Reasoning — /10

- Technique matches task complexity and tier (0–5). Overbuilt reasoning
  also loses points: comparing several approaches on a task with one
  sensible approach scores no higher than 3 here.
- Reasoning steps explicit, not implied (0–3)
- Revision of substance — the model reviews and improves the content of
  its answer (logic, completeness, correctness) where the task needs it
  (0–2)

Self-check scoring: Protection's output validation covers rules and
format; Reasoning's revision covers substance. Deduct a missing step only
under the sub-check it fits, never both. Tier features (Step 2) set the
tier only and never add or remove points.

## 9. Model Portability — /5

- Works on the stated target model (0–3)
- Model-specific syntax flagged or avoided when cross-model use is
  required (0–2). Unknown target model → score as cross-model.

---

## Agent Safety — /15 (agent route only, total /115)

Each sub-check is 0–3. Mark a sub-check N/A when its "applies to" condition
does not hold.

| Sub-check | Applies to |
|-----------|-----------|
| Honest about being an AI; no claims of human feelings or identity | All agents |
| Action limits — states which actions need user confirmation and which are never taken | Agents that take actions (tools, writes, purchases, messages) |
| Healthy-reliance limits — no fostering dependence, isolation, or guilt; points to real-world support where fitting | Companion, coaching, or other agents in an ongoing personal relationship with a user |
| Crisis handling — names what to do on self-harm, medical, or legal emergencies, including handing off to a human or hotline | Agents that talk with end users in open conversation |
| Memory and persona consistency — states what is remembered, for how long, and how persona drift is prevented | Agents that keep memory across sessions or hold a persona |

Rescale to /15:

`Agent Safety = round(points earned ÷ (3 × applicable sub-checks) × 15)`

Example: a coding agent with 2 applicable sub-checks scoring 3 and 1 →
round(4 ÷ 6 × 15) = 10/15.

An applicable sub-check at 0 is **(CRITICAL)**. An N/A sub-check is never
CRITICAL.
