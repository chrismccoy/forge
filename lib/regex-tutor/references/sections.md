# Teardown Sections — Full Spec

Produce these sections in order, with these exact numbered headers.

**Scale to the pattern.** For a short or simple regex, keep each section to a
few lines. Write "Not applicable — <one-line reason>" for any section with
nothing real to say. Never pad a section to fill it.

## 1. Plain-English Summary
One or two sentences on overall purpose.

## 2. Token-by-Token Breakdown
Table: `Token | Meaning | Why it's likely there`.
Cover the entire regex left to right with no gaps. Group related tokens
(e.g. a whole character class) into one row.

## 3. Structure
The regex as numbered stages (e.g. "Stage 1: optional leading whitespace →
Stage 2: one or more digits → Stage 3: literal dash"). List every capture
group with its number or name and its purpose. If none, say "No capture
groups."

## 4. Valid Examples
Table: `Input | Why it matches`. Up to 5 strings. Aim to cover a simple case,
an edge case, a boundary case (min/max length), and a surprising match
(matches though it looks like it shouldn't). Skip a category if no honest
example exists — say which.

## 5. Invalid Examples
Table: `Input | Fails at | Reason`. Up to 5 near-miss strings (they look
plausible). "Fails at" names the specific token or stage that rejects it.

## 6. Matching Walkthrough
Trace the engine on one short example from section 4 (prefer ≤ 12
characters). Show each step: position, token tried, result. Include
backtracking only if it actually occurs on that input; if none occurs, say
so, and briefly describe an input where it would.

## 7. Pitfalls / Gotchas
Only items that apply to *this* pattern, including: greedy vs. lazy
quantifiers; anchoring (missing `^`/`$`, partial vs. full match, `$`
matching before a trailing newline); escaping; case sensitivity;
Unicode/locale (e.g. `\d` or `\w` matching non-ASCII digits/letters in some
flavors); multiline/dotall behavior; and any other pitfall this pattern or
its likely host code has.

## 8. Performance & ReDoS
Start the section with exactly one of these lines: `**Verdict: Safe**`,
`**Verdict: Caution**`, or `**Verdict: Vulnerable**`. The verdict rates the
risk of catastrophic backtracking (exponential slowdown on crafted input).
If Caution or Vulnerable, name the exact construct (nested quantifiers,
overlapping alternation, etc.) and give a concrete attack-string shape
(e.g. `"a" * 30 + "!"`). Then briefly note any other cost (unanchored scans
on long input, heavy backreferences).

## 9. Alternatives
At least one simpler, safer, or more precise version, each with its
tradeoff — or, if the current regex is already the right tool, say so and
why. If a non-regex approach (parser, library, built-in validator) is
clearly better for the use case, say so. Each alternative must compile in
every flavor listed for it. Check each construct against each flavor —
named-group syntax (`(?<n>…)` vs `(?P<n>…)`), inline flags like `(?i)`,
lookbehind, possessive quantifiers, atomic groups — and compile each
alternative with `regex_check.py compile`, using the engines for each
flavor (see SKILL.md).

## 10. Real-World Context
Where this kind of pattern usually appears, and known caveats about using
regex for that job.

## 11. Plain-English Rewrite
One short paragraph for a non-programmer, zero regex syntax, zero jargon.
Plain example strings in backticks are fine; regex tokens are not.

## File header (file destination only)
When writing `REGEX-EXPLAINED.md`, the file must start with:
1. The heading `# Regex Explained`.
2. The regex exactly as the user gave it, in a fenced code block (if the
   input had several regexes, list each one).
3. The normalized pattern, if it differs from the input, then the flavor and
   use case (each marked "assumed" if assumed).

After that header, include the intake notes, all 11 sections, and any
clarifying question.
