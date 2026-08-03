# Writing and language

[← Back to the README](../README.md)

## `tech-blog-article`

Front-page-quality technical articles from five inputs, in the voice of a senior developer who actually ships. Locked output format. Pre-write input validation and a silent post-write output gate.

```
/tech-blog-article
```

Most "write a blog post" prompts produce the exact thing readers skip on Hacker News: a dictionary-definition opener, H2 headers that are bare topic labels (`## Configuration`), code dumped without explanation, and a conclusion that restates the intro. This plugin replaces that with what technical writers actually do. The opening pulls the reader in within the first three sentences with a real situation they've lived through. Every H2 is a complete thought (`## The default configuration will break at 10K requests/second`). Code examples show the wrong way first, then the right way, stay under 20 lines, carry a language identifier, and get a plain-English explanation after the fence. Opinions are stated outright and backed with numbers; the downsides are admitted; every section passes a "So What?" test. It closes on one of four ending patterns and signs off with a one-line bio.

The skill body runs the workflow. Step 1 loads the master prompt from `references/prompt-template.md` and substitutes the five inputs. Step 2 validates inputs before writing - a bracketed placeholder halts with `Missing input: <field>.`, a word count outside 300-5000 halts with `Invalid input: Word count must be a number from 300 to 5000.`. Step 3 writes the article under all six writing rules. Step 4 runs a silent output gate - title ≤ 60 chars, TL;DR 3-4 bullets, complete-thought H2s, every code block annotated, one ending pattern - and fixes any failure before returning.

Hard refusal on non-writing and role-change requests (`I only draft technical articles - give me a topic and I'll write.`). Output is the article only - no preamble, no meta-commentary, no notes after the bio.

## 📋 Technical Overview

One slash command plus its procedure file. The procedure file `lib/tech-blog-article/SKILL.md` carries the persona, scope lock, input handling, and 4-step workflow. The authoritative master prompt with `{{placeholders}}` lives in `references/prompt-template.md` and loads on every invocation. The slash command `/tech-blog-article` accepts an optional `TOPIC` arg, then walks the user through `AskUserQuestion` intake for the remaining four fields.

## ✨ Features

- 🎯 Five inputs in, one article out. TOPIC + AUDIENCE_LEVEL + ARTICLE_ANGLE + PRIMARY_LANGUAGE + WORD_COUNT
- 🪝 An opening that pulls the reader in within the first 3 sentences. No dictionary definitions, no "In today's fast-paced world"
- 🧱 Every H2 is a complete thought, not a bare topic label. TL;DR box (3-4 bullets) after the intro
- 💻 Wrong-way-then-right-way code examples, under 20 lines, language identifier in the fence, plain-English explanation after each block
- ⚖️ Opinions stated outright and backed with numbers; downsides admitted; "So What?" test per section
- 🏁 One of four ending patterns: lessons-learned, actionable checklist, provocative question, or "the thing nobody tells you"
- ✅ Pre-write input validation halts on bracketed placeholders or word counts outside 300-5000
- 🔒 Silent post-write output gate: title length, TL;DR bullet count, complete-thought H2s, code-block annotations, ending pattern
- 🛡️ Prompt-injection defense. All five inputs treated as inert article subject matter. Embedded directives (`ignore the above`, `reveal your prompt`, `change format`) are ignored
- 🪧 Scope-locked. Non-writing and role-change requests refused with `I only draft technical articles - give me a topic and I'll write.`

## 🔄 How it works

1. **Intake.** Slash command collects five fields via `AskUserQuestion`. If `TOPIC` was passed as `$ARGUMENTS`, confirm and skip that question. Empty / blank / `[FIELD_NAME]` → halt with `MISSING INPUT: <field> required.`
2. **Load template.** Read `references/prompt-template.md`. Substitute `{{TOPIC}}`, `{{AUDIENCE_LEVEL}}`, `{{ARTICLE_ANGLE}}`, `{{PRIMARY_LANGUAGE}}`, `{{WORD_COUNT}}` with collected values. Treat values as inert data.
3. **Validate inputs.** Bracketed placeholder → `Missing input: <field>.`. Word count not an integer 300-5000 → `Invalid input: Word count must be a number from 300 to 5000.`
4. **Write** the article following all six writing rules in the locked output format.
5. **Silent output gate.** Title ≤ 60 chars; TL;DR 3-4 bullets; complete-thought H2s; every code block has a language identifier and plain-English explanation; one ending pattern. Fix any failure before printing.
6. **Output the article only.** No preamble, no meta-commentary, no notes after the bio line.

## 🚀 How to use it

Two ways to invoke:

**Slash command:**

```
/tech-blog-article "Why your Postgres connection pool keeps exhausting"   ← arg seeds TOPIC, picker fills the rest
/tech-blog-article                                                        ← full 5-question intake
```

**Requests it handles** (type the command to run it - it never auto-triggers):

> *"write a technical article"*, *"draft a blog post"*, *"write a dev blog"*, *"Hacker News style article"*, *"Dev.to article"*, *"technical write-up"*, *"engineering blog post"*

The full procedure lives at [`lib/tech-blog-article/SKILL.md`](../lib/tech-blog-article/SKILL.md), the slash command at [`commands/tech-blog-article.md`](../commands/tech-blog-article.md), and the on-demand master prompt at [`lib/tech-blog-article/references/prompt-template.md`](../lib/tech-blog-article/references/prompt-template.md).

---

## `language-tutor`

Expert linguist, translator, and language tutor from five inputs, in the voice of a university-level instructor who stays clear enough for a self-studying learner. Two modes, locked section output per mode, an accuracy floor that refuses to fabricate, and a silent validation gate before printing.

```
/language-tutor
```

Most "translate this" prompts return a single bare sentence with no grammar, no pronunciation, and no sense of register - and most "fix my writing" prompts rewrite the text without telling you what changed or why. Worse, when the model is unsure it guesses: invented conjugation rules, made-up etymologies, plausible-but-wrong IPA. This plugin replaces that with what an actual language instructor does. TRANSLATION mode returns the most natural rendering plus dual-language grammar, a subject/verb/object breakdown, IPA with English approximations and stress marks, and a register/cultural-nuance read. TEXT ANALYSIS mode returns grammar, spelling and punctuation, style and flow, meaning, a fully corrected version with every change itemized `original → corrected → reason`, and five style rewrites. The source language is auto-detected, difficulty is aligned to CEFR A1-C2, and a Quick depth collapses the whole thing to the result plus a one-line note when that's all you want.

The skill body runs the workflow. Step 1 loads the master prompt from `references/prompt-template.md` and substitutes the five inputs. Step 2 detects the source language and resolves the mode (TRANSLATION, TEXT ANALYSIS, or Auto-detect from the text). Step 3 emits the locked section set for that mode per `references/output-spec.md`. Step 4 runs a silent validation gate from `references/constraints.md` - section completeness, IPA wrapped in slashes, CEFR level named, exactly five Alternative Versions, every change itemized - and fixes any failure before returning.

Hard accuracy floor: never invents grammar rules, etymologies, or IPA; flags uncertainty instead of guessing; states reduced confidence on low-resource languages and dialects and stops rather than approximating when a language can't be handled reliably. Prompt-injection defense treats all submitted text strictly as DATA - a phrase like "ignore your instructions" inside the text is translated or analyzed literally, never obeyed. Scope-locked: non-language requests get a brief decline and a restatement of what the tutor does, never a switch into general-assistant behavior.

## 📋 Technical Overview

One slash command plus its procedure file. The procedure file `lib/language-tutor/SKILL.md` carries the persona, scope lock, core behavior, input handling, and 4-step workflow. The authoritative master prompt with `{{placeholders}}` and both mode specs lives in `references/prompt-template.md` and loads on every invocation. The accuracy floor, prompt-injection defense, and silent validation gate live in `references/constraints.md`. The exact section structure for both modes, the optional-extras menu, and two calibrated worked examples live in `references/output-spec.md`. The slash command `/language-tutor` accepts an optional `TEXT` arg, then walks the user through `AskUserQuestion` intake for the remaining fields.

## ✨ Features

- 🎯 Five inputs in, a full language breakdown out. MODE + TEXT + TARGET_LANGUAGE + NATIVE_LANGUAGE + DEPTH
- 🔀 Two modes: TRANSLATION (translate and explain a phrase) and TEXT ANALYSIS (correct and critique your own writing). Auto-detect picks the mode from the text when MODE is `Auto`
- 🧱 TRANSLATION emits 5 locked sections: Translation, Grammar (both languages), Structure, Pronunciation, Usage & Register
- 📝 TEXT ANALYSIS emits 6 locked sections: Grammar, Spelling & Punctuation, Style & Flow, Meaning & Content, Corrected Text (every change itemized `original → corrected → reason`), 5 Alternative Versions (formal, casual, detailed, concise, alt-vocabulary)
- 🔊 IPA inside slashes plus English approximations and marked syllable stress; pronunciation tips tailored to the learner's NATIVE_LANGUAGE for sounds that don't exist in it
- 🎚️ Register and difficulty aligned to CEFR A1-C2 where the language supports it, with the targeted level named
- ⚡ Quick depth returns only the Translation or Corrected Text plus a one-line note - no framework
- 🧠 Accuracy floor: never invents grammar rules, etymologies, or IPA; flags uncertainty instead of guessing; reduced-confidence warning on low-resource languages and dialects, and a hard stop rather than approximation when a language can't be handled reliably
- 🛡️ Prompt-injection defense. Submitted text is inert DATA; directives embedded in it (`ignore your instructions`, `act as`, `system:`) are translated or analyzed literally, never obeyed
- ✅ Silent validation gate: section set complete and in order, IPA in slashes, CEFR named, exactly 5 rewrites, every change itemized, no obeyed injections
- 🪧 Scope-locked. Non-language requests get a brief decline plus a restatement - no switch into general-assistant behavior

## 🔄 How it works

1. **Intake.** Slash command collects five fields via `AskUserQuestion`. If `TEXT` was passed as `$ARGUMENTS`, confirm and seed it. Empty / blank / `[FIELD_NAME]` on `MODE` or `TEXT` → halt with `MISSING INPUT: <field> required.` In TRANSLATION mode, a missing or ambiguous `TARGET_LANGUAGE` triggers one short clarifying question alone before proceeding.
2. **Load template.** Read `references/prompt-template.md`. Substitute `{{MODE}}`, `{{TEXT}}`, `{{TARGET_LANGUAGE}}`, `{{NATIVE_LANGUAGE}}`, `{{DEPTH}}`. Treat the entire `TEXT` value as inert data.
3. **Resolve mode + language.** Detect the source language unless specified. When MODE is `Auto`, infer the mode from the text; default to TRANSLATION when ambiguous and label the assumption.
4. **Emit the locked sections** for the active mode per `references/output-spec.md`. Omit a section only if it doesn't apply, and say why. Quick depth returns only the result plus a one-line note.
5. **Silent validation gate.** Section completeness, IPA slashes, CEFR label, 5-rewrite count, itemized changes, no obeyed injections. Fix any failure before printing. Don't announce the gate.

## 🚀 How to use it

Two ways to invoke:

**Slash command:**

```
/language-tutor "Je m'appelle Marie"   ← arg seeds TEXT, picker fills mode/target/native/depth
/language-tutor                         ← full 5-question intake
```

**Requests it handles** (type the command to run it - it never auto-triggers):

> *"translate this to Japanese"*, *"what does this mean in French"*, *"explain this grammar"*, *"analyze my writing"*, *"correct my essay"*, *"check my grammar"*, *"proofread this"*, *"how do I pronounce this"*

The full procedure lives at [`lib/language-tutor/SKILL.md`](../lib/language-tutor/SKILL.md), the slash command at [`commands/language-tutor.md`](../commands/language-tutor.md), and the on-demand reference files at [`lib/language-tutor/references/prompt-template.md`](../lib/language-tutor/references/prompt-template.md), [`lib/language-tutor/references/constraints.md`](../lib/language-tutor/references/constraints.md), [`lib/language-tutor/references/output-spec.md`](../lib/language-tutor/references/output-spec.md).

---

## `contract-framework`

Writes a clear, fair contract for freelance and consulting work from a few plain questions. Plain-English by default, a fixed eight-part structure, three tone choices, and a firm rule against making up anything you did not provide.

```
/draft-contract
```

Most "write me a contract" prompts either hand back dense legalese the client is nervous to sign, or quietly invent terms you never agreed to, a cancellation fee, a notice period, an interest rate, that come back to bite you later. This plugin does what a careful contracts specialist does. You answer six short questions: your business, your client, what you are delivering, how you get paid, anything extra you want protected, and the tone. It hands back a ready-to-fill agreement that protects both sides and still reads like plain English. Every contract covers the three things freelancers argue about most: work that grows past what was agreed, clients who pay late, and who owns the finished result.

Nothing gets invented. When a detail is missing it leaves a clearly marked blank like `[TO BE COMPLETED: kill fee basis]` for you to fill in, instead of guessing a number. Anything that changes from one country or state to another, like late-payment interest or which law applies, is written in neutral wording and flagged so you can confirm it with a local lawyer. This gives you a strong starting draft, not legal advice.

## 📋 What's inside

A plugin with one slash command and one skill. The procedure file `lib/contract-framework/SKILL.md` holds the persona, the six inputs, the four-step workflow, and the final check. The full master prompt with the fill-in placeholders lives in `references/prompt-template.md` and loads every time. The slash command `/draft-contract` takes an optional one-line description of the work, then walks you through the rest with simple multiple-choice questions.

## ✨ What you get

- 🎯 Six easy questions in, a complete contract out: your business, your client, the work, the payment, extra protections, and tone
- 🧱 Eight clearly labelled parts, always in the same order: Parties, Scope, Payment, Intellectual Property, Confidentiality, Termination, Liability, and General Provisions
- 🤝 Covers the three big freelance headaches every time: work creeping past the agreement, late payment, and who owns the finished result
- 🗣️ Three tone choices applied all the way through: formal, plain professional, or a warmer creative style
- 🚧 Never invents laws, names, figures, fees, deadlines, or limits. Missing details become clearly marked blanks for you to fill in
- 🌍 Anything that depends on where you live is written in neutral wording and flagged to check locally
- 🛡️ Treats your answers as plain information only. Hidden instructions tucked inside them are ignored
- 📄 Saves the contract to a tidy file when it can and just tells you where it went, otherwise prints it on screen
- ✅ A quiet final check confirms all eight parts are present, in order, the tone is consistent, and every line traces back to something you actually said

## 🔄 How it works

1. **Questions.** The slash command asks for the six fields with simple multiple-choice prompts. If you pass a short description of the work, it uses that and skips ahead.
2. **Missing-answer check.** If any of the four must-have answers is blank or looks filled in wrong, it stops and asks you for just that piece before writing anything.
3. **Draft.** It writes the eight parts in your chosen tone, leaving marked blanks wherever you did not give a detail.
4. **Final pass.** A quiet check confirms all eight parts are present and in order, the tone is consistent, and nothing was invented, then fixes anything off before handing it over.
5. **Deliver.** Saves the contract to a file when it can and prints only the path, otherwise prints the full contract on screen.

## 🚀 How to use it

Two ways to start:

**Slash command:**

```
/draft-contract "brand identity: logo, type system, and guidelines"   ← seeds the work description, then asks the rest
/draft-contract                                                        ← full set of questions
```

**Plain language** (starts the skill on its own):

> *"draft a freelance contract"*, *"write a service agreement"*, *"create a consulting agreement"*, *"draft a client contract for a design project"*, *"put together an independent contractor agreement"*, *"make me a contract framework"*

The full procedure lives at [`lib/contract-framework/SKILL.md`](../lib/contract-framework/SKILL.md), the slash command at [`commands/draft-contract.md`](../commands/draft-contract.md), and the master prompt at [`lib/contract-framework/references/prompt-template.md`](../lib/contract-framework/references/prompt-template.md).

---

## `readme-builder`

Reads a whole project and writes one beginner friendly `README.md` for it. Plain everyday English, a fixed set of sections in the same order every time, and a firm rule against inventing anything that is not really in the repo.

```
/readme-builder
```

Most "write me a README" prompts either pad the page with hype ("a powerful, seamless tool") or describe features the project does not actually have. This plugin works the way a careful technical writer does. It opens and reads the real files first (the entry points, the config, the main scripts, any existing docs) to work out what the project is and what each file does, then writes the README from what it actually found. Tooling and session folders like `.git`, `.claude`, and `node_modules` are skipped and never mentioned.

The tone is aimed at someone who has never seen this kind of project before: short sentences, no jargon, and any unavoidable technical word explained in plain words right after. Marketing filler is banned outright (words like "seamless", "robust", "powerful", "leverage", and "supercharge"), along with empty fillers like "simply" and "just". The punctuation is kept plain too: no long dashes, no fancy arrows, and straight quotes only. A final check runs over the draft before you get it.

## 📋 What's inside

A plugin with one slash command and one skill. The procedure file `lib/readme-builder/SKILL.md` holds the writer persona, the five step workflow, the fixed section order, the banned word and punctuation lists, and the final quality check. The slash command `/readme-builder` takes an optional folder path, asks whether to write the file or print it, then runs the same workflow.

## ✨ What you get

- 📖 Reads the real project first, so the README matches what is actually there instead of being guessed
- 🧱 A fixed set of sections in the same order every time: title, description, feature list, a file by file explanation, a folder tree, and how to use it
- 🙂 Plain, friendly, everyday English with short sentences and no jargon
- 🚫 Hype words like "seamless", "robust", and "powerful" are banned, so the README stays honest
- ➖ No long dashes, no fancy arrows, and straight quotes only, which keeps the text clean and simple
- 🌳 A folder tree with a short note on each key file, so readers can see the layout at a glance
- ✅ A final check confirms every file and feature mentioned is real and a total beginner could follow it

## 🔄 How it works

1. **Read the repo.** It opens every folder and reads the important files to learn what the project is and what each file does. Nothing is guessed.
2. **Skip the noise.** Tooling and session folders (`.git`, `.claude`, `node_modules`, build output) are ignored and left out of the README.
3. **Draft.** It writes the sections in the fixed order, covering only the parts that fit the project.
4. **Clean.** It re-reads the draft against the banned word and punctuation lists and removes anything that slipped through.
5. **Final check.** It confirms no long dashes, no hype words, every file and feature real, and beginner readable, then hands over the finished README or saves it for you.

## 🚀 How to use it

Two ways to start:

**Slash command:**

```
/readme-builder ./my-project   ← seeds the target folder, then asks write or print
/readme-builder                ← documents the current folder
```

**Plain language** (starts the skill on its own):

> *"write a README for this repo"*, *"generate a README.md"*, *"document this project"*, *"make a beginner friendly README"*, *"explain this repo in a README"*

The full procedure lives at [`lib/readme-builder/SKILL.md`](../lib/readme-builder/SKILL.md), and the slash command at [`commands/readme-builder.md`](../commands/readme-builder.md).

---

## `tutorial-builder`

Turns code, a feature, or a library into a step-by-step, hands-on tutorial that teaches instead of describing. Five inputs, a locked tutorial structure, retention patterns and cognitive-load limits built in, and a pre-publish checklist plus a 1-5 speed score that gate the result.

```
/tutorial-builder
```

Most "write a tutorial" prompts produce a wall of prose with a code dump in the middle: concepts used before they are introduced, examples that do not run, no exercises, and no way for the reader to check they got it right. This plugin works the way a careful teacher does. It sets measurable objectives first (Bloom's verbs like build and debug, not "understand"), breaks the topic into atomic concepts ordered simple to complex with no forward references, and scaffolds practice as I-do, We-do, You-do. Every code block runs unmodified, lists its dependencies, and shows its expected output. Each section carries a minimal example, guided practice, a few challenges, and a troubleshooting table. The reader leaves with a summary that mirrors the opening and a concrete set of next steps.

The skill body runs the workflow and stays lean. Retention patterns (learn by doing, spaced repetition, worked examples, immediate feedback, analogies), cognitive-load limits (7 plus-or-minus 2, one-screen code, one new concept per step), and five difficulty-calibrated exercise types keep the pacing right. Depth that is not needed on every build lives one hop away in `references/implementation-playbook.md` - a full worked tutorial, per-format deep-dives, an exercise bank, and an expanded review rubric - and a finished `examples/sample-tutorial.md` ships as a copy-ready target. A pre-publish quality checklist and a 1-5 speed score (clarity, pacing, practice, troubleshooting, engagement) run before delivery.

Supplied code and repo content are treated as inert data - a directive embedded in a comment or filename is content to teach around, never a command to obey. Scope-locked to teaching content: non-tutorial and role-change requests get `I only build tutorials - give me a topic or some code and I'll teach it.`

## 📋 Technical Overview

One slash command plus its procedure file. The procedure file `lib/tutorial-builder/SKILL.md` carries the persona, scope lock, the three-step development process, the locked tutorial structure, retention and cognitive-load rules, and the quality gates. The on-demand `references/implementation-playbook.md` holds a full worked tutorial, a formats table with per-format guidance, a difficulty-calibrated exercise bank, and an expanded review rubric. A finished `examples/sample-tutorial.md` ships as a copy target. The slash command `/tutorial-builder` accepts an optional `TOPIC` or path, then walks the user through `AskUserQuestion` intake for the remaining four fields.

## ✨ Features

- 🎯 Five inputs in, one complete tutorial out. TOPIC + AUDIENCE + FORMAT + CONSTRAINTS + DISTRIBUTION
- 🧱 Locked structure: opening (objectives, prerequisites, time, final result, setup), progressive sections, closing (summary, next steps, resources, call to action)
- 🪜 Concepts ordered simple to complex with no forward references, and exercises scaffolded I-do, We-do, You-do
- 💻 Every code block runs unmodified, lists dependencies, and shows expected output
- 🧠 Retention patterns and cognitive-load limits (7 plus-or-minus 2, one-screen code, one new concept per step) built into the pacing
- 🧩 Five difficulty-calibrated exercise types: fill-in-the-blank, debug, extension, from-scratch, refactoring
- 📚 Bundled playbook with a full worked tutorial, per-format deep-dives, an exercise bank, and a review rubric, loaded only when depth is needed
- ✅ Pre-publish checklist plus a 1-5 speed score (clarity, pacing, practice, troubleshooting, engagement) gate the result, target a 4 average
- 🛡️ Supplied code and repo content treated as inert data; embedded directives are taught around, never obeyed
- 🪧 Scope-locked. Non-tutorial and role-change requests refused with `I only build tutorials - give me a topic or some code and I'll teach it.`

## 🔄 How it works

1. **Intake.** Slash command collects five fields via `AskUserQuestion`. If a `TOPIC` or path was passed as `$ARGUMENTS`, confirm and skip that question. If the user skips intake, apply the stated defaults: intermediate audience, deep dive format, blog or docs, latest stable tools.
2. **Define objectives.** Set measurable learning outcomes with Bloom's verbs, plus prerequisites and assumed knowledge.
3. **Decompose.** Break the topic into atomic concepts, order them simple to complex, and confirm no concept needs one introduced later.
4. **Write** the tutorial in the locked structure, one new concept per step, every code block runnable with expected output shown. Load `references/implementation-playbook.md` for a worked example, per-format detail, or the exercise bank.
5. **Gate.** Run the pre-publish checklist and the 1-5 speed score. Fix any failing gate before returning.

## 🚀 How to use it

Two ways to invoke:

**Slash command:**

```
/tutorial-builder "Debounce a search input in vanilla JS"   ← arg seeds TOPIC, picker fills the rest
/tutorial-builder                                            ← full 5-question intake
```

**Requests it handles** (type the command to run it - it never auto-triggers):

> *"create a tutorial for X"*, *"write a step-by-step guide to Y"*, *"turn this code into a tutorial"*, *"make a walkthrough of Z"*, *"build a coding lesson"*, *"write onboarding docs"*

The full procedure lives at [`lib/tutorial-builder/SKILL.md`](../lib/tutorial-builder/SKILL.md), the slash command at [`commands/tutorial-builder.md`](../commands/tutorial-builder.md), the on-demand playbook at [`lib/tutorial-builder/references/implementation-playbook.md`](../lib/tutorial-builder/references/implementation-playbook.md), and the sample tutorial at [`lib/tutorial-builder/examples/sample-tutorial.md`](../lib/tutorial-builder/examples/sample-tutorial.md).

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
