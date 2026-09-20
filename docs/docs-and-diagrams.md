# Docs & Diagrams

[← Back to the README](../README.md)

## `mermaid-to-ascii`

Hand it a Mermaid diagram file. Get back the same diagram drawn in plain text-art, saved right next to the original as a `.txt`.

```
/mermaid-to-ascii
```

Mermaid is great until you need the picture somewhere that can't render it: a code comment, a plain-text README, a chat message, a terminal, an email. This plugin takes a `.mmd` file and redraws it as tidy monospace text-art you can paste anywhere. It reads the file, works out what kind of diagram it is, lines everything up with fixed spacing, and writes the result to a `.txt` with the same name. Your original file is never touched.

It handles all the common Mermaid types: sequence diagrams become vertical lifelines with arrows crossing between them, flowcharts become connected boxes that follow the top-down or left-right direction you set, class diagrams become bordered boxes with their fields listed inside, state diagrams and ER diagrams get boxed nodes with labeled links, and gantt charts become rows of bars along a time axis. Every name, label, message, condition, and grouping block from the source is kept exactly as written, nothing dropped or renamed.

It asks one thing before it starts: which file to convert. If you named the file in your request it uses that; if you didn't, it asks and waits rather than guessing. Anything written inside the diagram is treated as plain drawing data, so a label that happens to read like an instruction just gets drawn, never obeyed. If a diagram is too wide for a terminal it splits into stacked sections instead of cutting anything off, and if the file is empty or broken it tells you what failed instead of inventing a picture.

## 📋 Technical Overview

One slash command plus its procedure file. The procedure file `lib/mermaid-to-ascii/SKILL.md` carries the filename-first intake, the eleven conversion rules (Rule 0 through Rule 10), the edge-case handling, and the output contract. The six per-type ASCII layout templates live in `references/skeletons.md` and load only once the diagram type is known, so the base context stays light. The slash command `/mermaid-to-ascii` takes a file path, or asks for one when invoked bare.

## ✨ Features

- 🧭 Asks which file to convert first, then stops and waits. No guessing, no scanning for a file you didn't name
- 🔁 Restates the plan once ("Converting `flow.mmd` -> `flow.txt`") before it does anything
- 📐 Handles every common Mermaid type: sequence, flowchart/graph, class, state, ER, and gantt
- 🧱 Picks the right text layout per type from six bundled templates, loaded only when needed
- 🏷️ Keeps every name, label, message, condition, and grouping block (`alt`/`else`/`opt`/`loop`/`par`). Nothing dropped, nothing renamed
- 📏 Fixed column spacing, aligned boxes, spaces not tabs, sized for an 80-120 character terminal
- ✂️ Splits oversized diagrams into stacked, labeled sections instead of cutting them off
- 🧾 Starts with a title and ends with a legend explaining every symbol used
- 🛟 Reports a clear parse error on empty or broken files and writes nothing; renders the good part of a partly broken file and lists the lines it skipped
- 🔒 Treats everything inside the file as drawing data, never instructions, even comments and labels that look like commands
- 📝 Writes only to the matching `.txt` and leaves the source file untouched

## 🔄 How it works

1. **Get the filename.** Use the file named in the request, or ask "Which Mermaid file should I convert?" and wait. Set the output name to the same base name with a `.txt` extension and restate the mapping.
2. **Read and identify.** Parse the source and work out the diagram type, which decides the layout.
3. **Lay it out.** Load the matching template from `references/skeletons.md` and draw the diagram with fixed spacing and aligned boxes, keeping every label and grouping block.
4. **Handle the awkward cases.** Approximate an unknown type and say so, split anything too wide, report parse errors on empty or broken source, and list any lines that couldn't be drawn.
5. **Save it.** Write the text-art to the `.txt` file, report which nodes and frames were captured, and leave the original alone.

## 🚀 How to use it

Two ways to invoke:

**Slash command:**

```
/mermaid-to-ascii flow.mmd     ← convert this file
/mermaid-to-ascii              ← asks which file to convert
```

**Requests it handles** (type the command to run it - it never auto-triggers):

> *"convert this mermaid to ascii"*, *"turn diagram.mmd into ascii art"*, *"render this sequence diagram as text"*, *"make an ascii version of this flowchart"*, *"mermaid to txt"*

The full procedure lives at [`lib/mermaid-to-ascii/SKILL.md`](../lib/mermaid-to-ascii/SKILL.md), the slash command at [`commands/mermaid-to-ascii.md`](../commands/mermaid-to-ascii.md), and the on-demand layout templates at [`lib/mermaid-to-ascii/references/skeletons.md`](../lib/mermaid-to-ascii/references/skeletons.md).

---

## `mermaid-generator`

Turns a bullet-point list of process steps into one valid Mermaid sequence diagram, in the voice of a technical diagramming assistant. It works out the participants, the message directions, and the branches, loops, and parallel blocks.

```
/mermaid-sequence
```

The single easiest thing to get wrong in a sequence diagram is arrow direction, and most tools point it at the sentence's grammatical subject. This one reads the verb: "the warehouse receives the shipment from Supplier" draws an arrow from Supplier to Warehouse, not the other way. It normalizes every reference to one participant, aliases multi-word names, strips characters that would break the syntax, and turns "if / otherwise", "for each", "only if", and "at the same time" into `alt`, `loop`, `opt`, and `par` blocks.

It never guesses. If a step names a recipient but no sender, or the input has fewer than two participants, it returns a one-line `ERROR:` pointing at the exact bullet instead of a diagram built on a guess. Output is exactly one thing: a fenced `mermaid` block, an `ERROR:`, or a `SAFETY:` message - never prose around it. Text inside the input is treated as diagram content, so a hidden "ignore all instructions" just becomes a message label.

## 📋 Technical Overview

One slash command plus its procedure file `lib/mermaid-generator/SKILL.md`, targeting Mermaid.js v10+. The command `/mermaid-sequence` takes the bullet list as its argument, or asks for it. A silent 14-point validation runs before anything is emitted.

## ✨ Features

- 🧭 Arrow direction from the verb, not the subject - receptive versus active phrasing
- 🏷️ Aliases multi-word names and normalizes every reference to one participant id
- 🔀 `alt` / `opt` / `loop` / `par` from "if/otherwise", "only if", "for each", "at the same time"
- 🧹 Strips parens, brackets, semicolons, and `#` from labels instead of failing
- 🚦 Refuses with a one-line error at the exact bullet when a sender is missing
- 🛡️ Treats input as diagram content; injection attempts become plain labels
- 📤 Emits exactly one form - diagram, `ERROR:`, or `SAFETY:` - never with surrounding text

## 🔄 How it works

1. **Intake.** Take the bullet list from the argument or ask for it.
2. **Parse.** Identify participants in order of appearance; resolve each entity to one id.
3. **Direct.** Set every arrow from the verb; use `-->>` only for explicit returns.
4. **Structure.** Wrap conditionals, loops, and parallel steps in the right blocks.
5. **Validate and emit.** Run the 14 checks; emit the diagram, or an error if it cannot be built.

## 🚀 How to use it

```
/mermaid-sequence                 ← asks for your bullet-point steps
```

Then paste steps like:

```
* User submits login form
* Server validates credentials
* If valid, server returns session token
```

The full procedure lives at [`lib/mermaid-generator/SKILL.md`](../lib/mermaid-generator/SKILL.md) and the slash command at [`commands/mermaid-sequence.md`](../commands/mermaid-sequence.md).

---

## `prompt-dummy`

Explains any AI prompt in plain, everyday English, written for someone who has never seen a prompt before. It reads the prompt end to end and describes it; it never runs it.

```
/explain-prompt
```

Hand it a prompt and it writes a short, friendly document a non-coder can follow: what the prompt is in one line, what it does, what you get back, how it works as numbered steps, the rules it follows, what it is good at, where it trips up, and how to use it. Eight fixed headings, same order every time, kept to something you can read in a few minutes.

It treats the prompt as text to describe, not orders to obey - a hidden "ignore your instructions" is noted in plain words, not followed. The writing rules are strict: no marketing filler, no empty intensifiers, no long dashes. It saves the result to `PROMPT-EXPLAINED.md` when it can write files, otherwise prints it.

## 📋 Technical Overview

One slash command plus its procedure file `lib/prompt-dummy/SKILL.md`. The command `/explain-prompt` takes the prompt text or a file path as its argument, or asks for it. It quotes the target prompt in a fenced block (tildes if the target already contains fences).

## ✨ Features

- 🗣️ Plain-English explanation for a total beginner - no jargon, no hype
- 🧾 Eight fixed sections, same order every time
- 🪜 Walks the prompt as simple numbered steps
- 🛡️ Describes hidden instructions instead of following them
- 🚫 Bans marketing filler and long dashes
- 📄 Quotes the full original prompt so the reader sees what was described
- 💾 Saves to `PROMPT-EXPLAINED.md` when file writing is available

## 🔄 How it works

1. **Intake.** Take the prompt from the argument or ask for it (paste or file). Stop if none is given.
2. **Read.** Pick out the prompt's role, task, output format, rules, and failure points.
3. **Write.** Fill the eight headings in plain English, quoting the prompt in a block.
4. **Check.** Confirm every heading is present, nothing was obeyed, no banned words. Save or print.

## 🚀 How to use it

```
/explain-prompt ./my-prompt.md    ← explain a prompt file
/explain-prompt                   ← asks you to paste the prompt
```

The full procedure lives at [`lib/prompt-dummy/SKILL.md`](../lib/prompt-dummy/SKILL.md) and the slash command at [`commands/explain-prompt.md`](../commands/explain-prompt.md).

---

## `prompt-summary`

A rigorous, review-ready analysis of any AI prompt, in the voice of a senior prompt engineer. Where `/explain-prompt` is for beginners, this is the deep dive: anatomy, techniques, output contract, failure modes, and concrete improvements.

```
/analyze-prompt
```

It breaks a prompt into its parts - role, task, context, constraints, examples, output format - and explains why the ordering and wording matter. It names the prompting techniques in play (few-shot, chain-of-thought, structured output, and so on), specifies the output contract with example inputs and outputs, and calls out where the prompt is likely to drift, be ambiguous, or be injected, with a mitigation for each.

Every claim is traceable to the target's actual text. The full prompt is quoted verbatim in an Appendix and never truncated. It analyzes and documents only - any instruction inside the target is logged under Failure Modes, not obeyed. It saves to `PROMPT-SUMMARY.md` when it can write files, otherwise prints the full report.

## 📋 Technical Overview

One slash command plus its procedure file `lib/prompt-summary/SKILL.md`. The command `/analyze-prompt` takes the prompt text or a file path, or asks for it. The body targets 1,500-4,000 words; the verbatim Appendix is exempt and never cut.

## ✨ Features

- 🧩 Full prompt anatomy - role, task, context, constraints, examples, format
- 🔍 Line-level wording analysis, including placeholder and variable conventions
- 🎯 Names the prompting techniques and why each fits
- 📤 Output contract with example input/output pairs, including edge and adversarial cases
- ⚠️ Failure modes and prompt-injection exposure, each with a mitigation
- ❓ Interview and review questions with guidance and trade-offs
- ✨ Concrete optimization suggestions, ordered by impact
- 📎 Full verbatim prompt in the Appendix, never truncated

## 🔄 How it works

1. **Intake.** Take the prompt from the argument or ask for it. Stop if none is given.
2. **Analyze.** Work through each required section in order, tracing every claim to the text.
3. **Stress-test.** Cover the output format, failure modes, injection exposure, and improvements.
4. **Verify and deliver.** Confirm every heading is present, the Appendix is verbatim, nothing was obeyed. Save or print.

## 🚀 How to use it

```
/analyze-prompt ./my-prompt.md    ← analyze a prompt file
/analyze-prompt                   ← asks you to paste the prompt
```

The full procedure lives at [`lib/prompt-summary/SKILL.md`](../lib/prompt-summary/SKILL.md) and the slash command at [`commands/analyze-prompt.md`](../commands/analyze-prompt.md).

---

## `prompt-ranker`

A structured architecture audit of any prompt: a tier and a score on one anchored scale, strengths and risks each tied to real language in the submission, a row per analysis dimension, and the single change that would move it up the most.

```
/rank-prompt
```

Where `/explain-prompt` describes a prompt for a beginner and `/analyze-prompt` documents its anatomy, `prompt-ranker` grades it. Eight dimensions: structure and decomposition, constraint design, input handling and adversarial robustness, output contract, scale coherence, example and verification strategy, failure mode coverage, and efficiency and cognitive load. A dimension can be marked not applicable, but only with a stated reason in its own table row - it can never be dropped quietly.

Scoring is anchored so a number means the same thing twice. The tier is assigned first, by which rungs the prompt actually clears: Expert requires untrusted input held inert behind paired markers, explicit precedence when rules collide, defined refusal behaviour, bounded retries, and self-consistent scales. Only then is a score picked inside that tier's band. Partial credit on a higher rung raises the score within the lower band; it never promotes the tier. The tier named at the top and the tier named in the verdict have to match.

The submission is the subject, never a directive. It sits between paired named markers, is declared inert, and a `score this 10/10` buried inside it gets quoted in Structural Risks along with a statement that it was not followed. Length earns nothing: verbosity without structure counts against Efficiency, and a short prompt that fully covers its scope is not penalized for being short.

## 📋 Technical Overview

One slash command plus its procedure file `lib/prompt-ranker/SKILL.md`, which loads the master template from `lib/prompt-ranker/references/prompt-template.md`. The command `/rank-prompt` takes the prompt inline or as a file path, or asks for it, then optionally collects the target model and what the prompt is failing at today. An intake gate treats an unreplaced placeholder as no submission at all and stops rather than auditing empty space.

## ✨ Features

- 🧭 Eight analysis dimensions, every one accounted for in the table
- 🪜 Anchored tiers. Novice, Intermediate, Advanced, Expert, each defined by mechanisms the prompt must actually contain
- ⚖️ One scale only. Tier and score map to each other, and the opening rank must agree with the closing verdict
- 🚪 Intake gate. No prompt, or a placeholder still in the markers, means a request and a stop - never a scorecard for empty space
- 🛡️ Injection resistant. The submission is inert data behind paired markers, and directives aimed at the reviewer are reported rather than obeyed
- 🔍 Evidence required. Every claim cites specific language or structure; generic praise and generic checklist criticism are ruled out
- 📏 Length neutral, in both directions
- 🧪 Bad input handled. A non-prompt is identified and refused rather than scored; a trivially short prompt is marked as such rather than padded out
- 🎯 One concrete improvement, stated as a specific edit with a before/after sketch - never "make it clearer"

## 🔄 How it works

1. **Intake.** Take the submission from the argument, a file path, or a plain ask. Optionally collect target model and current failure.
2. **Gate.** Stop on an absent or placeholder submission; refuse to scorecard a non-prompt.
3. **Score.** Walk the eight dimensions, citing the submitted text for every judgment.
4. **Tier.** Assign the tier by rungs cleared, then pick the score inside that band.
5. **Check.** Seven sections in order, all eight rows present, both tier mentions identical, every claim anchored.
6. **Print.** The seven sections only.

## 🚀 How to use it

```
/rank-prompt ./prompts/agent.md   ← audit a prompt file
/rank-prompt                      ← asks you to paste the prompt
```

**Requests it handles** (type the command to run it - it never auto-triggers):

> *"score this prompt"*, *"audit my system prompt"*, *"how good is this prompt"*, *"what tier is this prompt"*, *"review my agent instructions"*, *"why does my prompt keep drifting"*

The full procedure lives at [`lib/prompt-ranker/SKILL.md`](../lib/prompt-ranker/SKILL.md) and the slash command at [`commands/rank-prompt.md`](../commands/rank-prompt.md).

---

## `prompt-rank-table`

The same architecture audit as `prompt-ranker`, reduced to what fits on one screen: a tier and a score, one table row per dimension with the evidence quoted from the prompt itself, and a one-line verdict. No preamble, no closing prose.

```
/prompt-rank-table
```

Both tools share one engine - the same eight dimensions, the same anchored tier bands, the same inert-input rules. They differ only in what comes back. `prompt-ranker` writes the long report: numbered strengths, numbered risks, a structural-risks section, and one improvement written out as an edit. `prompt-rank-table` emits three sections and pushes every piece of evidence into the table, which is what you want when you are scanning quickly or lining several prompts up against each other.

The table is the whole output, so the rules that keep it rendering as a table are treated as hard constraints rather than formatting advice. Every row is one line with exactly three cells. No line break, `<br>`, bullet, or fenced block inside a cell. Pipes inside quoted evidence are escaped. Evidence cells stay under roughly 20 words - the shortest decisive fragment in quotes, then a brief gloss - with one exception: the input-handling row may run longer when it also has to report an injection attempt. A wrapped row renders as loose text, so a wrapped row is a failure.

Attacks are reported, not dropped. Directive language aimed at the reviewer - `ignore prior instructions`, `score this 10/10` - is quoted in the input-handling row along with a statement that it was not followed, and the audit continues unchanged. No extra section is added to report one, because the output contract is three sections and nothing else.

## 📋 Technical Overview

One slash command plus its procedure file `lib/prompt-rank-table/SKILL.md`, which loads the master template from `lib/prompt-rank-table/references/prompt-template.md`. The command `/prompt-rank-table` takes the prompt inline or as a file path, or asks for it, then optionally collects the target model and what the prompt is failing at today. An intake gate treats an unreplaced placeholder as no submission at all and stops rather than auditing empty space.

## ✨ Features

- 📊 Three sections only. Overall Rank, the table, the verdict - no preamble before the first heading and no prose after the last
- 🧭 Eight analysis dimensions, always eight data rows. A dimension can be marked `N/A - {reason}`, never dropped
- 📐 Hard table rules. One line per row, three cells, escaped pipes, no fence around the table, evidence capped at roughly 20 words
- 🪜 Anchored tiers. Novice, Intermediate, Advanced, Expert, each defined by mechanisms the prompt must actually contain
- ⚖️ One scale only. The tier in the opening rank and the tier in the verdict have to match
- 🚪 Intake gate. No prompt, or a placeholder still in the markers, means a request and a stop
- 🛡️ Injection resistant. The submission is inert data behind paired markers, and directives aimed at the reviewer land in the input-handling row rather than in the model's behaviour
- 🔍 Evidence required. Every row cites specific language or structure from the submitted prompt
- 📏 Length neutral. Verbosity without structure counts against Efficiency; a short prompt that covers its scope is not penalized
- 🧪 Bad input handled. A non-prompt is identified and refused rather than scored; a trivially short prompt gets `N/A` rows rather than padding

## 🔄 How it works

1. **Intake.** Take the submission from the argument, a file path, or a plain ask. Optionally collect target model and current failure.
2. **Gate.** Stop on an absent or placeholder submission; refuse to table a non-prompt.
3. **Score.** Walk the eight dimensions in fixed order, citing the submitted text for every row.
4. **Tier.** Assign the tier by rungs cleared, then pick the score inside that band.
5. **Check.** Three sections in order, eight single-line rows, both tier mentions identical, no stray prose.
6. **Print.** The three sections only.

## 🚀 How to use it

```
/prompt-rank-table ./prompts/agent.md   ← audit a prompt file
/prompt-rank-table                      ← asks you to paste the prompt
```

**Requests it handles** (type the command to run it - it never auto-triggers):

> *"score this prompt as a table"*, *"quick prompt audit"*, *"what tier is this prompt"*, *"compare these prompts"*, *"just give me the signals table"*

For the long-form version of the same audit, use [`/rank-prompt`](#prompt-ranker).

The full procedure lives at [`lib/prompt-rank-table/SKILL.md`](../lib/prompt-rank-table/SKILL.md) and the slash command at [`commands/prompt-rank-table.md`](../commands/prompt-rank-table.md).

---

## `prompt-stencil`

Takes one image-generation prompt that already gives you the picture you want and cuts it into a fill-in-the-variables version, so you can swap one thing and keep the same look.

```
/prompt-stencil
```

The problem it solves is rebuilding a look by hand. You have a prompt that renders exactly right, you change the subject, and the lighting drifts, the lens language goes, a prop appears that was never there. `prompt-stencil` separates the wording that makes the look from the wording that describes the thing, locks the first, and turns at most three dimensions of the second into `{TOKEN}` slots threaded through every clause that depends on them - and no others.

You get eight sections: the locks, the variable surface with source-derived defaults, the style-lock block to copy verbatim, a copy-ready template in four labelled blocks (`[STYLE LOCK]`, `[VARIABLE BODY]`, `[NEGATIVE]`, `[PARAMETERS]`), a propagation map saying which clauses each token rewrites and which it must never touch, at least two filled proofs with materially different values, drift guards listing what must never creep in, and short usage notes.

Model syntax is preserved, never translated. `--ar 3:2`, `--style raw`, weights, and flags stay in the source's own wording and go in `[PARAMETERS]`, whichever dialect they came from. Nothing is generated or verified: the proofs demonstrate token substitution, not visual outcome, and a stencil cut from a Midjourney prompt is not portable to another generator without translating the parameters yourself.

## 📋 Technical Overview

One slash command plus its procedure file `lib/prompt-stencil/SKILL.md`, which loads the master template from `lib/prompt-stencil/references/prompt-template.md`. The command `/prompt-stencil` collects the source prompt, the dimension to make reusable, and up to two optional constraints. It asks at most one clarifying question overall, and only when the dimension is missing while a usable source prompt is present.

## ✨ Features

- 🔒 Locks first. Composition, background, lighting, lens, palette, materials, style, negatives, and ratio are separated out before anything is cut
- 🎚️ Minimal variable surface. At most three dimensions, each chosen for the widest reuse, and never a lock the user did not ask to change
- 🧵 Dependency threading. A token rewrites only the clauses that logically depend on it; unrelated locks are left alone
- 📋 Copy-ready template in four labelled blocks, with no notes, ellipses, or advice inside the code block
- 🗺️ Propagation map. One row per token: what it rewrites, what it must never touch
- 🧪 At least two filled proofs with materially different values and identical locks
- 🚧 Drift guards kept separate from locks - guards say what to keep out, locks say what to keep
- 🧰 Model syntax preserved verbatim, never translated between dialects
- 🩹 Seam repair. A source that is itself a filled template gets its doubled articles and stranded prepositions fixed, and the notes say how
- 🚫 Three named failure states instead of a half-built artifact: Missing Material, Variable Conflict, Capability Boundary

## 🔄 How it works

1. **Intake.** Source prompt, the dimension to make swappable, optional constraints.
2. **Parse.** Break the source into visual clauses and mark each invariant, variable-dependent, or conflict-sensitive.
3. **Select.** Pick the minimal safe variable surface, at most three dimensions.
4. **Thread.** Run each variable through its dependent clauses and leave the rest untouched.
5. **Cut and assemble.** Style-lock block and drift guards from the invariants, then the four-block template.
6. **Prove and check.** Build the filled variants, then verify the artifact against the source and the request.

## 🚀 How to use it

```
/prompt-stencil ./prompts/product-hero.txt   ← cut a saved prompt
/prompt-stencil                              ← asks for the prompt, then what to vary
```

**Requests it handles** (type the command to run it - it never auto-triggers):

> *"make this image prompt reusable"*, *"turn this into a template"*, *"I want to swap the subject and keep the look"*, *"variables for my Midjourney prompt"*, *"stop my prompt drifting when I change the product"*

The full procedure lives at [`lib/prompt-stencil/SKILL.md`](../lib/prompt-stencil/SKILL.md) and the slash command at [`commands/prompt-stencil.md`](../commands/prompt-stencil.md).
