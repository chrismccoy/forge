# Tutorial Writing Guide

Detailed craft guidance for the tutorial-builder skill. Load this file before drafting any tutorial section. The hard gates (runnable-or-labeled code, expected output, checkable exercises, link honesty) stay in SKILL.md and always apply.

## Core Expertise

1. **Pedagogical Design**: Understanding how developers learn and retain information
2. **Progressive Disclosure**: Breaking complex topics into digestible, sequential steps
3. **Hands-On Learning**: Creating practical exercises that reinforce concepts
4. **Error Anticipation**: Predicting and addressing common mistakes
5. **Multiple Representations**: Teach each hard concept more than one way (prose + diagram + runnable code) so it lands regardless of how the reader thinks. (Not "learner styles" — that theory is unsupported; the win is redundant encodings of the same idea.)

**Learning Retention Shortcuts:**
Apply these evidence-based patterns to maximize retention:

| Pattern | Effect | How to Apply |
|---------|--------|--------------|
| Learn by Doing | Strongest retention driver | Every concept → immediate practice |
| Callback / Spaced Repetition | Reinforces recall | Within one tutorial: call back to earlier concepts in later steps. Across a Workshop Series: reopen prior-session concepts at the start of each session. |
| Worked Examples | Boosts comprehension | Show complete solution before practice |
| Immediate Feedback | Speeds correction | Checkpoints with expected output |
| Analogies | Aids understanding | Connect to familiar concepts |

## Writing Principles

**Speed Rules:** Apply these heuristics to write faster with better outcomes.

| Principle | Fast Application | Example |
|-----------|------------------|---------|
| Show, Don't Tell | Code first, explain after | Show function → then explain parameters |
| Fail Forward | Include a few intentional errors per tutorial | "What happens if we remove this line?" |
| Incremental Complexity | Each step adds ≤1 new concept | Previous code + new feature = working |
| Frequent Validation | Run code every few steps | "Run this now. Expected output: ..." |
| Multiple Perspectives | Explain same concept multiple ways | Analogy + diagram + code |

**Cognitive Load Management:**
- **One-concept rule:** one new concept per step at most, a few per section
- **One Screen Rule:** Code examples should fit without scrolling (or use collapsible sections)
- **No Forward References:** Don't mention concepts before explaining them
- **Signal vs Noise:** Remove decorative code; every line should teach something

## Content Elements

### Code Examples
**Checklist before publishing:**
- [ ] Code is written to run unmodified — complete, no undefined names, no elided `...`. You cannot execute it, so trace it line by line; if you can't get it to a state you're confident runs, label it as pseudocode in that language's comment syntax (`// pseudocode`, `# pseudocode`) and never present it as tested.
- [ ] All dependencies are listed
- [ ] Expected output is shown
- [ ] Errors are explained if intentional

- Start with complete, runnable examples
- Use meaningful variable and function names (`user_name` not `x`)
- Include inline comments for non-obvious logic (not every line)
- Show both correct and incorrect approaches (with explanations)
- **Format:** Language tag + filename comment + code + expected output

### Explanations
**The 4-MAT Model:** Apply all four in each major section.

- Use analogies to familiar concepts ("Think of middleware like a security checkpoint...")
- Provide the "why" behind each step (not just what/how)
- Connect to real-world use cases (production scenarios)
- Anticipate and answer questions (FAQ boxes)
- **Rule:** For every block of code, provide a couple of sentences of explanation

### Visual Aids
Match the visual to the content: flowcharts for logic, sequence diagrams for
event/API flow, before/after for refactors, architecture diagrams for system
overviews, progress bars for multi-step paths. Full visual-type → tool table in
`${CLAUDE_PLUGIN_ROOT}/lib/tutorial-builder/references/implementation-playbook.md`.

## Behavior Heuristics

**Efficiency Heuristics:**

| Situation | Apply This Rule |
|-----------|-----------------|
| Reader stuck | Add checkpoint with expected state |
| Concept too abstract | Add analogy + concrete example |
| Exercise too hard | Add scaffolding (hints, partial solution) |
| Tutorial too long | Split into Part 1, Part 2 |
| Low engagement | Add story, real-world scenario |

**Calibration by Audience:**

| Audience | Adjustments |
|----------|-------------|
| Beginners | More analogies, smaller steps, more exercises, hand-holding setup |
| Intermediate | Assume basics, focus on patterns and best practices |
| Advanced | Skip introductions, dive into edge cases and optimization |
| Mixed | Provide "Skip Ahead" and "Need More Context?" callout boxes |

**Common Pitfalls to Avoid:**

| Pitfall | Fix |
|---------|-----|
| Wall of text | Break into steps with headings |
| Mystery code | Explain every non-obvious line |
| Broken examples | Test before publishing |
| No exercises | Add at least one exercise per few concepts |
| Unclear goals | State objectives at start of each section |
| Abrupt ending | Add summary + next steps |

## Accessibility

**Accessibility Checklist:**
- [ ] Alt text on all images
- [ ] Color not sole indicator (use labels + color)
- [ ] Code has sufficient contrast
- [ ] Headings are hierarchical (H1 → H2 → H3)
