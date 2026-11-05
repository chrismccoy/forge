# Walkthrough Mode

Produce the sections below, in order, for one problem.

## Method glossary

- *Algebraic manipulation*: equation rearrangement, substitution, factoring.
- *Geometric reasoning*: diagrams, spatial relationships, visual proof.
- *Symbolic/graphical interpretation*: function behavior, graphs, or symbolic
  structure (for example, limits, derivatives as slopes).
- *Numerical approximation*: estimation, iteration, or computed approximation
  rather than exact closed form.

## Depth by complexity

Use the complexity tiers defined in the procedure's `${CLAUDE_PLUGIN_ROOT}/lib/math-tutor/SKILL.md`.

| Tier | Restate and frame | Misconception notes | Explanation sections | Practice items | Checklist items |
|---|---|---|---|---|---|
| Low | One line | One sentence | Merged | Two: similar and extension | Two |
| Standard | Short | Concise | Separate, brief | Three | Three |
| High | Full | Full | Separate | Three | Three |

**Step granularity:** A step is *simple* if it performs one routine operation
and introduces no new rule, theorem, or decision point (basic arithmetic,
isolating a term, simplifying a fraction). Compress the sub-elements of a simple
step into inline parentheticals. Use the full breakdown for a step that
introduces a new rule or theorem, a branching decision (choosing a sign, a
domain restriction, a case split), or a likely non-obvious error.

**Merged explanation sections:** Combine Intuitive explanation, Why this works,
and Memory aid into one 2-3 sentence block that keeps all three ideas, placed
at section 5.

## Sections

1. **Restate and frame:** Restate the problem in one sentence, then list
   assumptions, givens, symbols, units, and definitions. When several
   interpretations exist, state the one chosen and why.

2. **Approach overview:** Describe the strategy in 2-3 lines, including why the
   method suits the stated constraints. When the student sent only the problem,
   end with one line: "To try it yourself first, stop here and ask for a hint."

3. **Step-by-step solution:** Number the steps. Give each step:
   - The operation performed.
   - A short justification naming the rule, theorem, or principle.
   - `Possible misconception:` one concise note naming the type of common
     mistake here (sign error, order-of-operations slip, overlooked domain
     restriction, unit mismatch), and how to avoid it.
   - Unit handling or domain checks when applicable.

   Include a mid-solution check at a natural midpoint: a quick validation
   (estimation, sign check, boundary check, or dimensional analysis) that
   intermediate results make sense. For a one-step problem, use a single check
   at the end.

4. **Final answer:** Present it on its own line, per the math rendering rule,
   with units as constraints require.

5. **Intuitive explanation:** Give a 2-3 sentence plain-language mental model,
   avoiding heavy symbolism.

6. **Why this works:** Connect the procedure to the underlying concept, and
   show how it transfers to similar problems. State the limits of any general
   claim.

7. **Practice items:** Write the count for the tier (easier, similar, extension
   when there are three), unless `[Constraints]` says otherwise.

8. **Diagnostic check:** Write two multiple-choice questions on conceptual
   understanding, not computation. Make every wrong choice false, not merely
   off-target. Base each on a concept covered in the
   solution or explanations. Replace a question that is not, unless its concept
   is essential to this problem type. In that case keep it, flag it, and
   recommend one targeted micro-lesson.

9. **Memory aid:** Offer one brief trick, heuristic, or mnemonic for recalling
   the method under exam pressure.

10. **Alternate approach:** Include a compact alternate only if all three hold:
    it uses a glossary category other than the method used (two algebraic
    rearrangements do not qualify), it is more efficient or more illuminating,
    and `[Constraints]` does not prohibit extra content. Otherwise omit the
    section.

11. **What I should now be able to do:** Give a checklist of action-oriented
    self-assessment items, with the count for the tier.

12. **Answer key:** For each practice item, give the final answer, a 1-2 line
    solution sketch, and the concept it reinforces. For each diagnostic
    question, give the correct choice and a one-line explanation.
