# Tutorial Implementation Playbook

Detailed reference for the `tutorial-builder` skill. Load this when a task needs
a full worked example, per-format depth, or a ready exercise bank - content the
lean SKILL.md only summarizes.

---

## Worked Example - a complete mini-tutorial

Use this as a concrete target shape. Generated tutorials should match this
structure, not just the abstract template in SKILL.md.

````markdown
# Debounce a Search Input in Vanilla JS

> What You'll Learn: build a debounce wrapper; stop firing a fetch on every keystroke
> Prerequisites: JS functions, setTimeout, addEventListener
> Time: 10 minutes | Level: Beginner

## Setup (1 minute)

Create `index.html` with an `<input id="q">` and a `<script src="app.js">`.

## Section 1: Why Debounce

Typing "hello" fires five requests. Debounce waits until typing pauses, then
fires once - like an elevator holding the door for late arrivers.

```js
// app.js
function debounce(fn, ms) {
  let t;
  return (...args) => {
    clearTimeout(t);
    t = setTimeout(() => fn(...args), ms);
  };
}
const search = debounce((v) => console.log("fetch:", v), 300);
document.querySelector("#q").addEventListener("input", (e) => search(e.target.value));
// Output: after typing stops for 300ms → fetch: hello
```

### Try It Yourself

Make the delay configurable per input via a `data-ms` attribute.

**Success:** an input with `data-ms="500"` debounces at 500ms; one with no attribute falls back to 300ms.

<details>
<summary>Solution</summary>

`const ms = Number(el.dataset.ms) || 300;` then `debounce(fn, ms)`.

</details>

## Troubleshooting

┌──────────────────────┬─────────────────────────┬──────────────────────────┐
│ Symptom              │ Cause                   │ Fix                      │
├──────────────────────┼─────────────────────────┼──────────────────────────┤
│ Fires on every key   │ Timer not cleared       │ clearTimeout before set  │
│ Never fires          │ ms too large / no event │ Check listener is bound  │
└──────────────────────┴─────────────────────────┴──────────────────────────┘

## Summary

- Debounce collapses a burst of events into one trailing call.
- clearTimeout + setTimeout is the whole mechanism.
- Tune the delay to the interaction (search ≈ 300ms).

## Next Steps

1. Add a leading-edge variant (fire immediately, then wait).
2. Compare with throttle (fire at a steady rate).
````

---

## Format Deep-Dives

Expanded guidance for each format the SKILL.md formats section names.

| Format | Length | Depth | Best For |
|--------|--------|-------|----------|
| Quick Start | Short | Surface | First-time setup, hello world |
| Deep Dive | Medium | Comprehensive | Complex topics, best practices |
| Workshop Series | Long (multi-session) | Multi-part | Bootcamps, team training |
| Cookbook Style | Short each | Problem-solution | Recipe collections, patterns |
| Interactive Labs | Variable | Hands-on | Sandboxes, hosted environments |

### Quick Start
- One feature, zero config. Reader runs working code before any theory.
- Cut every optional step. If it is not required to see output, remove it.
- End at the first success, not at mastery.

### Deep Dive
- Layer: minimal example → why it works → edge cases → production concerns.
- Insert a checkpoint after each layer so a reader can stop cleanly.
- Budget one exercise per major concept.

### Workshop Series
- Split by natural rest points, not by word count.
- Each part restates prerequisites and ends with a runnable artifact.
- Carry a single running project across parts so context compounds.

### Cookbook Style
- Independent problem→solution pairs, indexed by task.
- Each recipe self-contained: no "see recipe 4 first".
- Lead with the finished snippet, then explain the parts.

### Interactive Labs
- Pin the environment to a real, supplied Replit/GitPod/CodeSandbox link so setup cannot drift — never fabricate the URL; if none exists, give exact setup commands instead.
- Provide checkpoints as failing tests the reader makes pass.

---

## Exercise Bank

Ready-to-adapt exercise scaffolds by difficulty, mapped to the SKILL.md
Exercise Types section.

**Difficulty Calibration:**

| Type | Time | Cognitive Load | When to Use |
|------|------|----------------|-------------|
| Fill-in-the-Blank | Short | Low | Early sections, confidence building |
| Debug Challenges | Short-Medium | Medium | After concept introduction |
| Extension Tasks | Medium | Medium-High | Mid-tutorial application |
| From Scratch | Long | High | Final challenge or capstone |
| Refactoring | Medium-Long | Medium-High | Advanced tutorials, best practices |

1. **Fill-in-the-Blank**: Complete partially written code (provide word bank if needed)
2. **Debug Challenges**: Fix intentionally broken code (show error message first)
3. **Extension Tasks**: Add features to working code (provide requirements, not solution)
4. **From Scratch**: Build based on requirements (provide test cases for self-check)
5. **Refactoring**: Improve existing implementations (before/after comparison)

### Fill-in-the-Blank (Low load)
- Provide complete code with one expression blanked and a word bank.
- Success criterion: named output for a named input.

### Debug Challenge (Medium load)
- Show the error message first, then the broken code.
- Break exactly one thing. Multi-bug puzzles overload beginners.

### Extension Task (Medium-High load)
- Give working code plus a requirement, withhold the solution.
- State the acceptance test, not the implementation.

### From Scratch (High load)
- Provide only requirements plus test cases for self-check.
- Reserve for capstones after scaffolded practice.

### Refactoring (Medium-High load)
- Give a working-but-ugly version and a target property (faster, smaller, testable).
- Require a before/after diff so the improvement is visible.

---

## Visual Aids - type → tool

| Visual Type | Best For | Tool Suggestions |
|-------------|----------|------------------|
| Flowchart | Data flow, decision logic | Mermaid, Excalidraw |
| Sequence Diagram | API calls, event flow | Mermaid, PlantUML |
| Before/After | Refactoring, transformations | Side-by-side code blocks |
| Architecture Diagram | System overview | Draw.io, Figma |
| Progress Bar | Multi-step tutorials | Markdown checklist |

Also useful: diagrams of data flow, before/after comparisons, decision trees for
choosing approaches, and progress indicators for multi-step processes.

---

## Review Rubric (expanded)

Apply after drafting, before publishing. Fail any hard gate → do not ship.

**Hard gates:**
- Every code block is written to run unmodified — complete, no undefined names, no elided `...`. You cannot execute it, so trace it; if unsure it runs, label it pseudocode in that language's comment syntax and never present it as tested.
- No concept used before it is introduced.
- Each exercise has a checkable success criterion.
- No fabricated URLs or images — cite only real canonical links, else name the resource without a link.

**Quality signals:**
- Analogy present for each abstract concept.
- Expected output shown after each runnable step.
- Opening objectives mirror closing summary.
- Time estimate within a reader's plausible range.
