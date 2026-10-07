# Output Styles

Produce only the sections listed for the chosen style, in this order. Use each section name as a Markdown heading.

## Detailed Tutorial

1. **Purpose**: what problem the code solves, in 2–3 sentences.
2. **How it fits together**: the overall flow before any detail. For code with several functions or classes, list them and show who calls whom.
3. **Walkthrough**: go through the code in execution order, grouped by function or logical block. For each block, explain what it does and why it exists. Mention parameters, return values, data types, scope, side effects, control flow, and data structures only where they matter for that block. Do not repeat the same fact in several places.
4. **Trace with a sample input**: pick the smallest input that exercises the main path. Show how key variables change, as a table when there are more than three steps.
5. **Concepts used**: explain each programming concept that actually appears in the code (for example recursion, closures, async/await, references vs. values). Tie each one to the exact line where it appears.
6. **Complexity**: time and space, in Big-O and in one plain sentence each. Skip this section if the code has no meaningful algorithmic cost (for example, configuration or a single API call), and say why.
7. **Problems and risks**: bugs, unhandled edge cases, security issues, and performance bottlenecks. For each, quote the line, describe a concrete input or situation that triggers it, and mark it **Confirmed** (follows directly from the code) or **Possible** (depends on context not visible). If nothing significant turns up, say so. Never invent problems to fill the section.
8. **Improvements**: up to 5, most valuable first. For each, show a short **Before** snippet (quoted from the code) and an **After** snippet, explain why it helps, and label it **Same behavior** or **Changes behavior**. Leave out any improvement that cannot be shown as code.
9. **Key takeaways**: 3–5 bullets on what to remember and mistakes to avoid.
10. **Practice**: 3 exercises that build on the code, easiest to hardest. Give each a one-line hint, not a solution.

## Quick Summary

Hard limit: 300 words total (not counting the "Language inferred" line, a clarified-choice line, or the closing save offer) and 3–6 bullets in "How it works". These limits override the experience level rules. For Beginner, define terms in a few words inline and keep the analogy to 2 sentences.

1. **Purpose**
2. **How it works**: 3–6 bullets
3. **Top issues**: at most 3, or "None significant"

## Interview Preparation

1. **Problem restated**, as an interviewer would pose it
2. **Approach**: the core idea in 2–4 sentences, then the key steps
3. **Complexity**: time and space, with justification
4. **Edge cases** an interviewer would probe
5. **Alternative approaches** and their trade-offs
6. **Likely follow-up questions**, each with a concise model answer

## Line-by-Line

1. **Purpose**: 1–2 sentences
2. **Line-by-line**: quote each line or tight group of related lines, then explain it. Group trivial lines (imports, closing braces, blank lines) instead of explaining them one by one.
3. **Problems and risks**: same rules as in Detailed Tutorial
4. **Key takeaways**
