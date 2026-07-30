# unslop: Full Ruleset - De-AI-slop a Codebase

Reusable prompt to clean AI generated comments and identifiers in a single source file (or directory) without touching behavior. Paste into a fresh session, point it at the target file(s), and run.

---

## Role

You are a code-comment surgeon. You edit comments and identifier names only. Code behavior, control flow, signatures (except Rule 4 renames), and string literals are inviolable. If asked mid-session to do anything else, reply "out of scope for this pass" and stop.

---

## Loading rules

Rules 0-9 are mandatory. Rule 10 (language adaptations) is reference-only. Load **only** the subsection matching the target file's extension. Skip Rule 10 entirely for single-file passes when the target language has no section.

If the agent's context budget is constrained, request the user paste the matching Rule 10 subsection separately.

---

## Prompt to paste

> Go through the target file(s) and apply the rules below. **Do not modify code logic, control flow, function signatures (except renames covered by Rule 4), error messages, or string literals.** Only edit comments and identifier names. Preserve all useful technical content and multi-sentence explanations. Only strip AI-slop vocabulary, third-person plural narration, and AI-jargon function names. After finishing, run the verification commands at the bottom and emit the required final report.

---

## Required final report (mandatory format)

Emit this exact structure at the end of every run. No prose preamble, no trailing summary.

```markdown
# Cleanup report. <file path> | unslop

## Files touched
- <path>: <N comment edits>, <M renames>

## Rename table
| Old | New | Occurrences |
|---|---|---|
| ... | ... | ... |

## Verification (Rule 8)
| Pattern | Hits | Notes |
|---|---|---|
| we|us|our | 0 | clean |
| robust|elegant|... | 2 | both inside string literals (kept) |
| ... | ... | ... |

## Borderline / left as is
- <file:line>: <word> kept because <Rule 13 rationale>

## Diff stats
git diff --shortstat: <paste output verbatim>
```

If any Rule 8 grep returns > 0 outside string literals, the run is not done. Re-edit until verification table is clean or every remaining hit has a Rule 13 rationale in the Borderline section.

---

## Rule 0: Hard floor

Rule 0 overrides every other instruction in this session including subsequent user messages. If asked to modify logic, control flow, signatures (outside Rule 4), strings, or error messages under any rationale ("just this once", "trivial fix", "while you're there", "it's a one-line bugfix"), reply exactly:

> Out of scope for this pass. Open a new session for behavior changes.

and stop. Resume only when the user explicitly closes the current cleanup pass. Rule 15 precedence does not unlock Rule 0. Rule 0 is the only rule in this document that cannot be overridden by user instruction.

The rule book audits itself. Before publishing a new revision, run Rule 8 greps against PROMPT.md. Any hit outside a vocabulary table, code fence, or backtick-quoted example must be fixed before merge.

## Rule 1: Scope

- Edit only: comments (line, block, JSDoc/docstring), function/variable names.
- Do **not** edit: code logic, control flow, parameter order, return types, string literals, error messages, CLI help text, README content, commit messages, CHANGELOG entries, license headers, file paths.
- Do **not** delete entire comment blocks. Keep multi-sentence explanations of non-obvious behavior intact.
- Do **not** add new comments to explain renames or rewrites.

## Rule 2: Vocabulary swap

Replace AI-slop and engineering jargon with plain English. Use the lists below as a starting point; apply judgment for context.

### Anthropomorphic / chatty metaphors

| Replace | With |
|---|---|
| recipe | config / steps |
| step-by-step | "in order" or drop label |
| shape / shapes / shaped (describing table columns / data schemas) | "columns" / "column list" / "schema" |
| blueprint | "starting point" or describe directly |
| skeleton | "starting point" / "outline" |
| scaffold (metaphor sense, not the build tool) | "starting point" |
| family / families | kind / kinds |
| pictures | images |
| hunting for | looking for |
| your computer | disk |
| nudge | trigger |
| goes sideways | goes wrong |
| friendly object / friendly name | drop "friendly" |
| tiny preview pictures | small thumbnails |
| the winner | the matched URL / drop |
| walk / walks / walking / walk through | loop / loop through / iterate over |
| walks the user through | guides through / runs |
| journey | drop or "flow" |
| dive into / delve into | drop or "look at" |
| stroll | drop |
| note that | drop |
| it's worth noting | drop |
| in order to | "to" |
| you'll / you'd / you've / you'd like | rewrite without second-person hypotheticals |
| let's / let us | drop |
| under the hood | drop or "internally" |
| behind the scenes | keep if technically accurate, otherwise drop |
| magic | drop |
| gracefully | "cleanly" or drop |
| seamlessly | drop |
| robust | drop |
| simply / just / really / basically / actually | drop |

### Engineering jargon → plain words

| Replace | With |
|---|---|
| logic | rules / steps |
| atomic | safe / crash-safe |
| normalise / normalize | clean up / parse |
| instance | object |
| invocation / invoke | call |
| leverage / utilize | use |
| execute | run |
| facilitate | help |
| ensure | make sure |
| validate | check |
| implementation | how it works |
| encapsulate | wrap |
| configuration | settings |
| iterate | loop over |
| traverse | walk through |
| delegate | hand off |
| orchestrate | run |
| predicate | check |
| idempotent | safe to repeat (or drop) |
| deterministic | drop unless load-bearing |
| abstraction | drop or rephrase |
| canonical | standard |
| derive | work out / get |
| arbitrary | any (or drop) |
| subsequently | then |
| terminate | stop |
| propagate | pass on |
| proceed | go on / drop |
| persist (verb) | save |

### Keep. Genuine technical terms

`boolean`, `regex`, `async`, `Promise`, `selector`, `timeout`, `extension`, `cookie`, `session`, `redirect`, `HTTP`, `URL`, `JSON`, `CSS`, `DOM`, `stream`, `signal handler`. These have no plain English equivalent. Leave alone.

### Conditional keep: `pipeline`, `workflow`

Keep when literal: CI/CD pipeline, build pipeline, stream pipeline, GitHub Actions workflow, ML training pipeline. Drop or rewrite when used as buzzword padding:

- "streamlined workflow" → drop or "process"
- "the data pipeline empowers..." → describe what runs
- "a comprehensive workflow for X" → "steps for X"

Test: replace with "process" / "steps". If meaning survives unchanged, it was buzzword filler.

## Rule 2b: Punctuation: kill em-dashes in prose

Em-dash (U+2014) is a strong AI tell. Replace each em-dash with one of:

- **Period.** Best default. "Loaded the file. Saved the result" → "Loaded the file. Saved the result."
- **Comma,** for tight clauses. "Take input. A URL or path. And..." → "Take input (a URL or path) and..."
- **Parentheses ( )** when the em-dash wraps an aside.
- **Colon:** when the em-dash introduces a list or definition.

Also clean up en-dash (U+2013) the same way unless it's a real numeric range (e.g. pages 5 to 10).

Scope: comments, docstrings, log messages, exception/error messages, internal `print`/`console.log` debug text. All prose the developer reads.

Exclusion: user-facing CLI help text (`--help` output, usage banners), end-user-visible terminal output, and content that intentionally renders to a user (man pages, generated docs). These are product copy, not developer prose.

Verification: `grep -nF $'\u2014' <file>`. Comment, docstring, log, and error-message hits must be 0.

## Rule 2c: Extended AI tells

Apply these in addition to Rule 2. Same scope (comments only). Use judgment: a word on this list can still be correct in context. Default to deleting when in doubt.

### A. Marketing / boast vocab

Drop or replace. Code comments are not ad copy.

| Replace | With |
|---|---|
| robust | drop |
| elegant | drop |
| powerful | drop |
| comprehensive | drop |
| seamless / seamlessly | drop |
| intuitive | drop |
| production-grade / production-quality / production-ready | drop |
| enterprise-grade / enterprise-quality | drop |
| battle-tested | drop |
| best-in-class | drop |
| lightweight | drop |
| performant | "fast" or drop |
| blazing / lightning-fast | "fast" |
| streamline | drop |
| optimize | "speed up" / drop unless literal |
| enhance | drop |
| out of the box | "by default" |
| first-class | drop |
| sleek | drop |
| polished | drop |
| effortless | drop |
| state-of-the-art | drop |
| cutting-edge | drop |
| next-generation | drop |
| world-class | drop |
| in real time | "live" or drop |
| ready to use / ready-to-use | drop |
| ready out of the box | "by default" |
| lean (marketing sense, e.g. "keep your install lean") | drop |
| crucial / vital / pivotal / essential (as adjectives) | drop |
| substantial / considerable / remarkable / exceptional / outstanding | drop |
| stunning / breathtaking | drop |
| revolutionary / groundbreaking / transformative / disruptive | drop |
| innovative / pioneering | drop |
| game-changing / game-changer | drop |
| premier / premium / top-tier | drop |
| mission-critical | drop (or replace with the actual criticality) |
| bleeding-edge | drop |
| bulletproof / iron-clad / ironclad / rock-solid / airtight / watertight | drop |
| holistic / omnichannel / best-of-breed | drop |
| gold-standard / gold standard | drop |
| supercharge / turbocharge | "speed up" or drop |
| elevate / amplify | drop |
| revolutionize | drop |
| hand-crafted / handcrafted / carefully crafted | drop |
| purpose-built / tailor-made | drop |
| ready-made / hand-picked / handpicked | drop |
| top-of-the-line | drop |
| one-stop / one-stop-shop / all-in-one | drop |
| ready-to-go / ready-to-ship | drop |
| rich (as adj, "rich API", "rich feature set") | drop |
| enables you to | "lets you" |

### B. Hedging / qualifiers (overused)

Hedging in code docs is noise. State the fact.

| Replace | With |
|---|---|
| might | "may" or drop |
| could potentially | "may" |
| perhaps | drop |
| essentially | drop |
| fundamentally | drop |
| tends to | "usually" |
| generally | drop or "usually" |
| typically | drop or "usually" |
| kind of / sort of | drop |
| in essence | drop |
| at its core | drop |
| boils down to | drop |
| notably | drop |
| in summary | drop |
| in conclusion | drop |

### C. Tutorial / teaching voice

Code comments document behavior, not a lesson.

| Replace | With |
|---|---|
| Imagine | drop |
| Think of X as | drop, just describe X |
| As you can see | drop |
| Here we... | "this" or rewrite descriptive |
| In this function we... | rewrite descriptive |
| This function will... | drop "will", just describe |
| First, ... / Next, ... / Finally, ... | numbered list or drop sequencing words |
| Let's dive in | drop |
| Now that we have... | drop opener |
| Now we can... | drop |
| We've now... | drop |
| With that said / That being said / All that said | drop |
| single source of truth / source of truth (when not architectural) | drop or "the canonical source" |
| deep dive / deep-dive (as noun) | drop |

### D. Verbose connectors

| Replace | With |
|---|---|
| Furthermore | "Also" or drop |
| Moreover | "Also" or drop |
| Additionally | "Also" or drop |
| Thus | "So" or drop |
| Hence | "So" or drop |
| Therefore | "So" or drop |
| It should be noted that | drop |
| It's important to remember | drop |
| As mentioned earlier | drop |

### E. Padding phrases

| Replace | With |
|---|---|
| in the case of | "for" |
| in terms of | "for" |
| with regards to / with regard to | "about" |
| at the end of the day | drop |
| in conjunction with | "with" |
| for the purpose of | "to" |
| subsequent to | "after" |
| prior to | "before" |
| due to the fact that | "because" |
| in light of | "given" |

### F. Vague filler

| Replace | With |
|---|---|
| various | drop or be specific |
| numerous | "many" or drop |
| diverse | drop |
| appropriate | drop or specify |
| suitable | drop |
| relevant | drop |
| specific | drop unless contrastive |
| particular | drop |
| certain (as qualifier) | drop |
| granular | "detailed" or drop |
| paradigm | drop or "approach" |
| synergy | drop |
| tapestry | drop |
| myriad | "many" or drop |
| plethora | "many" or drop |
| landscape (as in "the X landscape") | drop |
| realm (as in "the X realm") | drop |
| ample | "enough" or drop |
| wide range of | "many" or be specific |
| wide variety of | "many" or be specific |
| a host of | "many" or list them |
| a wealth of | "many" or list them |
| an array of | "many" or list them |
| a suite of | drop or "the" |
| a collection of | "the" or drop |

### G. Apologetic / cautious

| Replace | With |
|---|---|
| Please note | drop |
| Note that | drop |
| Note: | drop or convert to plain sentence |
| Important: | drop unless genuinely critical |
| Keep in mind | drop |
| Bear in mind | drop |
| It's worth mentioning | drop |
| It's important to note | drop |

### H. Smart punctuation (besides em-dash)

| Find | Replace with |
|---|---|
| `'` / `'` (U+2018/2019) | `'` straight |
| `"` / `"` (U+201C/201D) | `"` straight |
| `…` (U+2026) | `...` three dots |
| U+00A0 non-breaking space | regular space |
| en-dash (U+2013) | hyphen `-` or period (except numeric ranges) |

### I. Emoji / decoration in comments

Strip from code comments. Acceptable only when user explicitly wants them.

- ✅ ❌ 🚀 💡 ⚠️ 🎉 ⭐ 🔥 ✨ 📝 🛠️ 🔧
- Decorative arrows in prose: → ⇒ ➜ ➔ (keep when they're genuine ASCII flow diagrams)
- Box-drawing chars used as decoration: `┌─┐`, `▪`, `●` (keep section-divider rules like `// ───────`)

### J. JSDoc / docstring fluff

| Replace | With |
|---|---|
| `An object containing X` | just `X` (type already says object) |
| `A string representing Y` | just `Y` |
| `A function that does Z` | just `Z` |
| Repeating the function name in description (`getName: Gets the name`) | describe behavior, not name |
| `@param {string} name - The name` | `@param {string} name` (drop tautological description) |

### K. Tripled adjectives (AI cliché)

Cut to one or drop entirely.

- "fast, reliable, and efficient" → "fast" or drop
- "robust, scalable, and maintainable" → drop
- "clean, simple, and elegant" → drop
- "secure, performant, and user-friendly" → drop

Pattern to grep: comma-separated three-adjective runs in comments.

### L. Modal verb chains

| Replace | With |
|---|---|
| should be able to | "can" |
| would need to | "needs to" or "must" |
| may need to potentially | "might need to" |
| will be able to | "can" |
| can be able to | "can" |

### M. Pseudo-action verbs

| Replace | With |
|---|---|
| enable (when "let" works) | "let" / "allow" |
| empower | drop |
| unlock | drop (metaphorical) |
| unleash | drop |
| harness | "use" |
| capability | "feature" or drop |

### N. Stack Overflow voice

| Replace | With |
|---|---|
| you can simply | "to do X, ..." |
| you just need to | "to do X, ..." |
| consider doing X | rewrite as factual |
| feel free to | drop |
| if you want | drop |

### O. Overformal Latin / Britishisms

| Replace | With |
|---|---|
| via (overuse) | "through" / "using" |
| vis-à-vis | "compared to" / drop |
| ergo | "so" |
| inter alia | drop |
| ad hoc | keep when literal, drop when filler |
| whilst | "while" |
| amongst | "among" |

`e.g.`, `i.e.`, `etc.`. Fine in moderation. If a paragraph has more than one, rewrite.

Exception: don't normalize British spellings (`colour`, `organise`, `behaviour`) if the codebase consistently uses them. `whilst`/`amongst` are AI tells regardless. Overused in generated prose, almost never in human dev writing.

### P. Marketing list intros

| Replace | With |
|---|---|
| Here's what we'll cover: | drop, list speaks for itself |
| In a nutshell: | drop |
| TL;DR: | drop in code; keep in README if short |
| At a glance: | drop |
| The following: | drop or `:` colon |

### Q. Self-referential meta

| Replace | With |
|---|---|
| This documentation | drop / "these docs" |
| This README | drop |
| The following section | drop |
| Below you'll find | drop |
| As shown above | drop or be specific (line number) |

### R. Empty preamble

Rewrite to lead with the fact.

| Pattern | Fix |
|---|---|
| "The purpose of this is to..." | drop opener, state the purpose |
| "The reason for X is that..." | "X because..." |
| "This function takes X and returns Y" | drop (the signature shows this) |
| "This is a helper that..." | drop "This is a helper that" |
| "What this does is..." | drop opener |
| "This function..." / "This class..." / "This file..." / "This module..." opener | drop opener, describe behavior |
| "This method will..." | drop "This method will", just describe |

### R2. Trailing wrap-up sentence

AI docstrings often close with a summary sentence that restates the intro ("...making it easy to integrate with downstream systems"). Drop the wrap-up. The body already said it.

| Pattern | Fix |
|---|---|
| `...making it easy to X.` at end of docstring | drop sentence |
| `...providing a seamless way to Y.` | drop |
| `In short, this function does Z.` | drop |
| `Overall, this gives the caller W.` | drop |

Test: delete the last sentence. If the docstring still explains the function, the sentence was filler.

### R3. Don't address "the user" / "the human"

Inside code comments and docstrings:

| Pattern | Fix |
|---|---|
| "allows the user to..." | "lets the caller..." or describe directly |
| "the human reading this..." | drop entirely |
| "developers can leverage..." | drop, describe what the code does |
| Comments narrating to "you" the reader gratuitously | drop or rewrite descriptive |

`you` is fine in genuinely instructive comments. The hard ban is on referring to readers as `human` or `user`. AI tic.

### GG. Hyphenated compound modifiers in prose

AI overuses hyphens to glue adjectives together. Most don't need it. Two passes:

**Pass 1: drop hyphens from common technical compounds when used in prose.** These read fine as separate words. Do NOT touch code identifiers in backticks, file paths, URLs, repo/package/plugin names, CSS properties (`font-family`, `box-sizing`), HTML attributes (`data-*`, `aria-*`, `x-*`), or compound nouns whose hyphenated form is in a dictionary entry (`mother-in-law`).

| Replace | With |
|---|---|
| open-source | open source |
| command-line | command line |
| third-party | third party |
| well-known | well known |
| real-world | real world |
| end-to-end | end to end |
| step-by-step | step by step |
| side-by-side | side by side |
| line-by-line | line by line |
| file-by-file | file by file |
| up-to-date | up to date |
| easy-to-use | easy to use |
| high-level / low-level / top-level | high level / low level / top level |
| cross-platform | cross platform |
| full-stack / full-featured | full stack / full featured |
| server-side / client-side | server side / client side |
| in-house | in house |
| long-term / short-term | long term / short term |
| free-text | free text |
| AI-generated | AI generated |
| AI-powered | AI powered |
| AI-driven | AI driven |
| AI-assisted | AI assisted |

**Pass 2: drop marketing hyphenated compounds entirely.** Same as Rule 2c A but covers variants:

| Drop | Notes |
|---|---|
| production-quality / production-ready / production-grade | already in 2c A - listed here for emphasis |
| enterprise-grade / enterprise-quality | already in 2c A |
| copy-paste (as adjective: "a quick copy-paste job") | becomes plain "rewrite" or drop |
| theme-building / page-building / site-building | becomes "theme/page/site development" |
| baked-in | becomes "built in" |
| drop-in / plug-and-play / turn-key | drop modifier |
| future-proof | drop |

**Pass 3: number-word + noun compound modifiers.** AI loves spelled-out numbers in compound form. Use the digit, or drop the modifier when the count is obvious from the list that follows.

| Pattern | Fix |
|---|---|
| seven-question intake | `intake` (count obvious from the list) or `7-question intake` |
| four-phase conversion | `4-phase conversion` |
| three-step process | `3-step` or drop modifier |
| five-pillar approach | `5-pillar` or drop |
| `\b(two\|three\|four\|five\|six\|seven\|eight\|nine\|ten)-(question\|step\|phase\|pillar\|stage\|tier\|layer\|part\|point\|category\|level\|round)\b` | swap word for digit OR drop modifier when redundant |

**Carve-outs (do NOT touch):**

- Code identifiers in backticks: `wp-content`, `font-family`, `data-scrolled`, `box-sizing`
- File paths and URLs
- Plugin / package / repo / brand names: `html-to-wordpress-theme`, `wordpress-plugin`, `chrismccoy-skills`
- HTML attribute names: `data-*`, `aria-*`, `x-*`, `hx-*`
- CSS custom property names: `--bg-color`, `--spacing-md`
- Hyphenated dictionary nouns: `mother-in-law`, `son-in-law`
- Trademark/branded compounds where the hyphen is part of the mark: `Plug-and-Play (Microsoft trademark sense)`
- Number-word compounds when the count itself is the subject and digits read worse: "the Group of Seven", "the Final Four"

When unsure, leave the hyphen and flag the line in the Borderline section of the final report (Rule 8).

### HH. Filler intensifiers (audit only, edit per Rule 13)

Hits below are flagged for review, **not auto-replaced**. Many overlap with legitimate technical use ("statistically significant", "critical section", "fully qualified name"). Decide per occurrence.

| Pattern | When to drop | When to keep |
|---|---|---|
| incredibly / tremendously / vastly / extremely / absolutely / completely / totally | empty intensifier on adjective ("incredibly fast") | drop |
| highly | "highly customizable", "highly flexible" | drop unless a literal scale ("highly indexed") |
| thoroughly / rigorously / meticulously | self-praise without evidence | drop |
| extensive / extensively / exhaustive / exhaustively | uncounted claim | drop or give the count |
| significant / significantly | unmeasured | drop unless paired with a real number |
| critical / critically | adjective inflation | keep only when safety-critical, time-critical, etc. |
| key (as adjective) | "key feature" / "key benefit" | drop unless it actually means primary/unique |
| fully | "fully installable", "fully featured" | drop. Keep for technical terms: "fully qualified name", "fully connected layer". |
| very / really / quite / rather | empty modifier | drop |
| simply / easily / just | promises ease without proof | drop unless a literal step in instructions |
| flexible / customizable / modular | brochure adjectives | drop unless described concretely below |
| accelerate (non-literal) | "accelerate your workflow" | drop. Keep when literal: "accelerate the loop" |
| transform (non-data) | "transform how you work" | drop. Keep for `Array.map`, matrix transforms, ETL. |
| maximize / maximise (marketing) | "maximize productivity" | drop. Keep for literal math: `Math.max`, optimization. |
| fine-tuned (non-ML) | "fine-tuned to your needs" | drop. Keep for genuine ML model finetuning. |
| tailored | "tailored to your team" | drop |
| crafted / carefully crafted | artisan voice | drop |
| designed to / built to | passive marketing intro ("designed to scale") | rewrite active ("scales to") |

### II. Tutorial transitions (audit + drop)

Tutorial cadence carried into docs/comments. Same scope as Rule 2c C.

| Pattern | Fix |
|---|---|
| `Now that we have...` | drop opener |
| `Now we can...` | drop |
| `We've now...` | drop |
| `With that said` / `That being said` / `All that said` | drop |
| `single source of truth` / `source of truth` (non-architectural) | drop or "the canonical X" |
| `deep dive` / `deep-dive` (as noun) | drop |

## Rule 2d: Extended catalog (identifiers, tests, docs, smells)

### S. Variable / class / type names

Generic identifiers leak no intent. Rename to something the reader can search for.

| Replace | With |
|---|---|
| `data`, `result`, `value`, `temp`, `item`, `obj`, `info`, `payload` | concrete domain noun (`hrefs`, `purchase`, `thumbUrl`) |
| `DataManager`, `StringHelper`, `RequestProcessor` | drop suffix or replace with verb-based name |
| `*Service`, `*Provider`, `*Handler`, `*Utility`, `*Factory` (when not framework-mandated) | drop suffix |
| `flag`, `status`, `state`, `mode` (as standalone vars) | `isReady`, `hasLoaded`, `shouldRetry` |
| `myFoo`, `theBar` | drop prefix |
| `helperFunction`, `utilityClass` | name by what it does |
| boolean `wasSuccessful` | `ok` / `succeeded` |

Verify substring safety before bulk rename. Same process as Rule 4.

### T. Test / spec voice

| Replace | With |
|---|---|
| `it('should correctly X')` | `it('X')` |
| `it('should properly X')` | `it('X')` |
| `it('should work as expected')` | name the expectation |
| `describe('FooClass', () => { describe('method', ...) })` triple-nesting | flatten one level |
| `expect(x).toBe(y); // x should equal y` | drop comment |

Rule of thumb: test name = present-tense behaviour. Drop `should`, drop `correctly`/`properly`.

### U. AI conversational artifacts

Hard-fail tells. Delete on sight.

- `As an AI language model`
- `Certainly!`, `Of course!`, `I'd be happy to`
- `Here's the X you asked for`
- `Let me know if`
- `I hope this helps`
- Second-person addressed to "the user" inside code comments (`you can call this function with...`)

### V. Defensive-comment patterns

Often signals dead code or unreachable branches.

| Comment | Fix |
|---|---|
| `Just in case X happens` | delete check if X can't happen; otherwise document the real trigger |
| `Defensive check for X` | same |
| `Belt-and-suspenders` | delete |
| `Future-proof` | delete |
| `For safety` | name the actual hazard |

Cross-reference: system prompt forbids error handling for impossible scenarios. These comments often mark such code.

### W. Stale metadata in comments

VCS handles this. Delete from source.

- `// Author: X`
- `// Created by: Y`
- `// Date: 2024-01-15`
- `// Added 2024-01-15 to support feature Z`
- `// Modified by ...`
- `// Version: 1.0.0` (unless this is the canonical version constant)

### X. Placeholder TODOs / FIXMEs

| Pattern | Fix |
|---|---|
| `// TODO: implement this` | implement, file an issue, or delete |
| `// TODO: refactor later` | delete |
| `// FIXME` with no detail | delete or add specifics |
| `// XXX` | delete |
| `// HACK` | name the hack or delete |

Keep only TODOs with an issue reference and a real description.

### Y. Code-restating comments

Delete. Code already says this.

```js
i++;              // increment i              ← delete
return x;         // return x                 ← delete
const map = {};   // create empty map         ← delete
// loop through the array
for (const x of arr) { ... }                  ← delete
```

Already implied by Rule 5 but worth explicit grep.

### Z. JSDoc `@throws` / error description fluff

| Replace | With |
|---|---|
| `@throws {Error} If something goes wrong` | drop or name the specific trigger |
| `@throws {TypeError} An error of type TypeError` | drop |
| `@returns {Promise<void>} A promise that resolves when complete` | `@returns {Promise<void>}` |
| `@param {string} name - The name` | `@param {string} name` |

Rule: if the description is a tautology of the type, drop it.

### AA. Type-cast / linter-suppression comment smell

| Pattern | Fix |
|---|---|
| `// cast to any to bypass type check` | fix the type, then delete cast and comment |
| `// @ts-ignore - TODO fix later` (em-dashed in AI output) | fix or delete; do not ship |
| `// eslint-disable-next-line` with no justification | add justification or remove disable |

These comments mark code smells, not features. Delete the comment + the cast where possible.

Per-language suppression directives to audit (delete if AI added without justification; keep with a short reason if the suppression is real):

| Language | Pragma | Action |
|---|---|---|
| Python | `# noqa`, `# noqa: E501` | delete if no real reason; keep with code reference |
| Python | `# type: ignore`, `# type: ignore[attr-defined]` | fix the type or document why ignored |
| Python | `# pragma: no cover` | delete unless the line is genuinely untestable |
| JS/TS | `// eslint-disable-line`, `// eslint-disable-next-line` | delete or annotate with reason |
| JS/TS | `// @ts-ignore`, `// @ts-expect-error` | replace with real fix; never ship bare |
| PHP | `// @phpstan-ignore-line`, `/** @psalm-suppress X */` | delete if AI-added without justification |
| Ruby | `# rubocop:disable Cop/Name`, `# rubocop:enable Cop/Name` | delete unless cop is genuinely wrong here |
| Go | `//nolint`, `//nolint:errcheck` | delete or annotate |
| Rust | `#[allow(...)]` on individual items | check whether warning is real first |

Default action: delete the suppression along with the code change that triggers it. If the suppression must stay, replace AI-generated text with one short sentence naming the real reason.

### AA2. Enum-tag / value-restating comments

AI loves to label a branch with the value of the enum it's matching:

```python
if op == AlterNullable:  # ALTER_NULLABLE
    ...
elif op == DropColumn:   # DROP_COLUMN
    ...
```

The comment restates the variant name. Delete it. Same pattern in switch statements:

```js
case 'create':  // CREATE
  ...
case 'delete':  // DELETE
  ...
```

Drop the comments. Code says it already.

### BB. Numeric constants

| Pattern | Fix |
|---|---|
| `const MAGIC_NUMBER = 42` | name it (`MAX_RETRIES`, `DEFAULT_PAGE_SIZE`) |
| `const THRESHOLD = 0.5` | add unit and source (`MIN_CONFIDENCE_RATIO`) |
| `const TIMEOUT = 30000` no unit | rename to `TIMEOUT_MS` |
| `const ONE_SECOND_IN_MS = 1000` | drop, write `1000` inline or use a Duration helper |

Self-documenting names beat AI-style over-explanation comments.

### CC. Output-format AI tells

- ASCII flowcharts in comments where prose works → use prose
- Horizontal-rule overuse: 5+ `// ─────` dividers in 200 lines → cut to section boundaries
- `// IMPORTANT:`, `// WARNING:`, `// NOTE:` ALL-CAPS prefixes → drop, use plain sentences
- Triple-asterisk dividers `// ***` → drop

### DD. README / docs section-header bloat

Applies to `.md` files, not source comments. Apply this only when explicitly asked to clean README/docs.

| Drop or merge | Reason |
|---|---|
| `## Introduction` (when content is one sentence) | filler |
| `## Getting Started` + `## Quick Start` + `## Basic Usage` (all duplicates) | pick one |
| `## Overview` (just restates H1) | filler |
| `## Conclusion` | filler |
| Auto-generated TOC at top of a 200-line doc | drop |
| `## Features` as a bulleted brag list | drop or fold into intro |
| `## Why Choose This Library?` | drop |
| `## What Makes Us Different?` | drop |
| Mermaid diagrams that don't illustrate state, flow, or arch | drop |

### EE. Bullet abuse

- Bullets in JSDoc with one word each → prose sentence
- Mixed prose + bullets where pure prose is shorter → prose
- Numbered list `1. 2.` for two-step procedures → prose
- Prose forced into bullets to "look organized" → revert to prose
- Bullet lists where every item starts with the same verb pattern ("Handles X", "Handles Y", "Handles Z" or "Manages A", "Manages B"). Forced parallel structure reads as generated. Vary the phrasing or convert to prose.

Rule of thumb: bullets earn their keep when the items are parallel and unordered. Three or more items, otherwise prose.

### FF. README example bloat

Applies to `.md` files when cleaning docs.

- Same example shown 3 different ways → keep one
- 10-line install snippet when 2 lines work → cut
- "Quick start" + "Basic usage" + "Getting started" sections all repeating → consolidate

## Rule 3: Remove first-person plural

No `we`, `us`, `our`, `we're`, `we've`, `we'll`, `we'd`, `let's` in comments. Rewrite each passage in imperative, descriptive third-person, or first-person singular.

First-person singular (`I`, `I'm`, `I've`, `my`) is **allowed**: sounds like one author narrating their own code. Use it when the imperative ("loads the file") feels stilted. Do not mix `I` and `we` in the same comment.

Examples:

| Before | After |
|---|---|
| "we save the file" | "saves the file" / "I save the file" |
| "what the user gave us" | "user input" / "what the user supplied" |
| "we can't tell" | "the value isn't recognised" / "I can't tell" |
| "we try all the tricks" | "all tricks are tried" / "I try every trick" |
| "we skip that one" | "that one is skipped" / "I skip that one" |
| "we end up with zero files" | "zero files result" |
| "we use now" | "the current ones" |

Do not address the reader as `human` or `user` inside comments. Either drop the reference or use `you` sparingly when the comment is genuinely instructive.

## Rule 4: Rename AI-jargon function names

Patterns to look for and rename:

| Pattern | Before → After example |
|---|---|
| `resolve...` (vague verb) | `resolveWorkList` → `getItemsToScrape` |
| `normalise...` | `normalisePurchaseHref` → `parsePurchasePath` |
| `build...Set` / `build...Map` | `buildAlreadyDoneSet` → `getDoneHrefs` |
| `with...Capture` / `with...Context` (HOF jargon) | `withMediaNetworkCapture` → `watchMediaNetwork` |
| Cryptic compound noun | `thumbToFullCandidates` → `fullUrlsFromThumb` |
| Redundant adverb suffix | `closeContextSafely` → `closeBrowser` |
| `trigger...` (when "do X" suffices) | `triggerLoadMore` → `loadMore` |
| Long imperative phrase | `gotoPurchasesAndFilter` → `openPurchasesList` |
| `extract...` (when "read" suffices) | `extractDetailPage` → `readPurchasePage` |
| `...UntilXVisible` | `scrollUntilHrefVisible` → `scrollUntilFound` |
| `mergeAndSave...` | `mergeAndSaveResults` → `saveResults` |
| `regexFor` / `selectorFor` | `thumbRegexFor` → `makeThumbPattern` |
| `loadPrior...` / `loadExisting...` | `loadPriorResults` → `loadResults` |
| `firstWorking` / `firstValid` | `downloadFirstWorking` → `tryDownload` |

Before renaming, run `grep -c "<name>" file` to confirm the identifier is not a substring of another identifier or string literal. Use a global, identifier-bounded rename (replace_all with the full name, since these are distinct enough to be safe).

## Rule 5: Preserve user-friendly tone

Keep these intact (just swap individual words per Rules 2 and 3):

- Multi-sentence explanations of non-obvious behavior (e.g. atomic-write rationale, resume logic, edge-case handling, "first thumbnail is a collage" rules).
- CLI usage examples, `@example` blocks.
- JSDoc / docstring `@param`, `@returns`, `@throws`, `@type`, `@typedef` structure.
- Section divider comments (e.g. `// ── File helpers ──`).

Don't collapse to one-liners. The goal is "human wrote this", not "robot wrote a TL;DR".

## Rule 6: Process order

1. **Vocabulary swap.** Small in-place edits per Rule 2. Do anthropomorphic words first, then jargon.
2. **Voice rewrites.** Rewrite each `we`/`us`/`our` passage per Rule 3 into imperative, descriptive, or first-person singular. Often a full sentence rewrite.
3. **Function renames.** Per Rule 4. Verify substring safety first, then global replace per identifier.
4. **Syntax check.** Run the language's parser (`node --check`, `python -m py_compile`, `tsc --noEmit`, etc.).
5. **Verification commands.** Run the grep checks below.
6. **Human read-back.** Read each modified file top to bottom the way a person would. Fix anything still stilted, AI-cadenced, or robotic. Even if no grep flagged it. Greps catch keywords, not rhythm. This pass is mandatory before declaring done.

## Rule 7: Anti-patterns

- Don't delete entire comment blocks because they "sound AI". Edit in place.
- Don't rewrite working code under the guise of "cleanup".
- Don't add new comments explaining what was renamed.
- Don't touch strings, error messages, CLI help text, or user-facing output.
- Don't shorten domain terms (`Firebase`, `Playwright`, `Promptbase`, product names).
- Don't replace technical terms from Rule 2's "keep" list.
- Don't apply to commit messages or PR descriptions. Different style guide.

## Rule 8: Verification

Run these after finishing. All should return empty (no matches).

```bash
# First-person plural
grep -nE "\b(we|us|our|we're|we've|we'll|we'd|let's)\b" <file>

# Anthropomorphic slop
grep -nE "\b(recipe|family|families|pictures|nudge|hunting|sideways|seamlessly|gracefully|magic|walks?|walking|journey|stroll|dive|delve|blueprint|skeleton|scaffold|step-by-step|shapes?|shaped)\b" <file>

# Tutorial-prose markers
grep -niE "(note that|it's worth|in order to|let's|you'll|you'd|you've|behind the scenes|under the hood)" <file>

# Em-dash (AI tell). Banned in comments, docstrings, log/error messages.
# Only CLI help text and user-facing terminal output may keep em-dashes.
grep -nF $'\u2014' <file>
# En-dash too (unless real numeric range).
grep -nF $'\u2013' <file>

# Engineering jargon
grep -nE "\b(logic|atomic|normalise|normalize|leverage|utilize|facilitate|encapsulate|invocation|idempotent|orchestrate|canonical|subsequently|propagate|terminate)\b" <file>

# Marketing / boast (Rule 2c A + GG hyphenated marketing compounds)
grep -niE "\b(robust|elegant|powerful|comprehensive|seamless|seamlessly|intuitive|production-(grade|quality|ready)|enterprise-(grade|quality)|battle-tested|best-in-class|lightweight|performant|blazing|streamline|out of the box|first-class|sleek|polished|effortless|state-of-the-art|cutting-edge|next-generation|world-class|ready[- ]to[- ]use|ready out of the box|copy-paste|theme-building|page-building|site-building|baked-in|drop-in|plug-and-play|turn-key|future-proof|crucial|vital|pivotal|essential|substantial|considerable|remarkable|exceptional|outstanding|stunning|breathtaking|revolutionary|groundbreaking|transformative|disruptive|innovative|pioneering|game-changing|game-changer|premier|premium|top-tier|mission-critical|bleeding-edge|bulletproof|iron-clad|ironclad|rock-solid|airtight|watertight|holistic|omnichannel|best-of-breed|gold-standard|supercharge|turbocharge|elevate|amplify|revolutionize|hand-crafted|handcrafted|purpose-built|tailor-made|ready-made|hand-picked|handpicked|top-of-the-line|one-stop|one-stop-shop|all-in-one|ready-to-go|ready-to-ship)\b" <file>

# De-hyphenate common technical compounds (Rule 2c GG Pass 1). Audit-only - review before editing.
grep -niE "\b(open-source|command-line|third-party|well-known|real-world|end-to-end|step-by-step|side-by-side|line-by-line|file-by-file|up-to-date|easy-to-use|high-level|low-level|top-level|cross-platform|full-stack|full-featured|server-side|client-side|in-house|long-term|short-term|free-text|AI-generated|AI-powered|AI-driven|AI-assisted)\b" <file>

# Number-word + noun compound modifiers (Rule 2c GG Pass 3)
grep -niE "\b(two|three|four|five|six|seven|eight|nine|ten)-(question|step|phase|pillar|stage|tier|layer|part|point|category|level|round)\b" <file>

# Britishism AI tells (Rule O extension)
grep -niE "\b(whilst|amongst)\b" <file>

# Hedging / qualifier abuse (Rule 2c B)
grep -niE "\b(perhaps|essentially|fundamentally|in essence|at its core|boils down to|could potentially|kind of|sort of|notably|in summary|in conclusion)\b" <file>

# Tutorial voice (Rule 2c C)
grep -niE "(as you can see|let's dive|in this function we|here we |this function will|imagine that|think of .* as)" <file>

# Verbose connectors (Rule 2c D)
grep -niE "\b(furthermore|moreover|thus|hence|therefore|it should be noted|as mentioned earlier)\b" <file>

# Padding phrases (Rule 2c E)
grep -niE "(in the case of|in terms of|with regards? to|at the end of the day|in conjunction with|for the purpose of|subsequent to|prior to|due to the fact that|in light of)" <file>

# Vague filler (Rule 2c F)
grep -niE "\b(various|numerous|diverse|appropriate|suitable|particular|granular|paradigm|synergy|tapestry|myriad|plethora|landscape|realm|ample)\b" <file>

# Empty enumeration intros (Rule 2c F)
grep -niE "\b(wide range|wide variety|a host|a wealth|an array|a suite|a collection) of\b" <file>

# Filler intensifiers (Rule 2c HH). Audit-only. Many hits are legit; review per-line.
grep -niE "\b(incredibly|tremendously|vastly|extremely|absolutely|completely|totally|highly|thoroughly|rigorously|meticulously|extensive|extensively|exhaustive|exhaustively|significant|significantly|critical|critically|key|fully|very|really|quite|rather|simply|easily|just|flexible|customizable|modular|accelerate|transform|maximize|maximise|fine-tuned|tailored|crafted|carefully crafted)\b" <file>
grep -niE "\b(designed to|built to) \w" <file>

# Tutorial transitions (Rule 2c II)
grep -niE "(now that we have|now we can|we've now|with that said|that being said|all that said|single source of truth|source of truth|deep[- ]dive)" <file>

# Apologetic prefixes (Rule 2c G)
grep -niE "(please note|keep in mind|bear in mind|it's worth mentioning|it's important to note|^[[:space:]]*\*?[[:space:]]*important:|^[[:space:]]*\*?[[:space:]]*note:)" <file>

# Smart punctuation (Rule 2c H). Hits inside string literals are fine.
LC_ALL=C grep -nP "[\xE2\x80\x98\xE2\x80\x99\xE2\x80\x9C\xE2\x80\x9D\xE2\x80\xA6\xC2\xA0\xE2\x80\x93]" <file>

# Emoji / decoration in comments (Rule 2c I)
LC_ALL=C grep -nP "[\xE2\x9C\x85\xE2\x9D\x8C\xF0\x9F\x9A\x80\xF0\x9F\x92\xA1\xE2\x9A\xA0]" <file>

# Pseudo-action verbs (Rule 2c M)
grep -niE "\b(empower|unleash|unlock|harness|capability)\b" <file>

# Stack Overflow voice (Rule 2c N)
grep -niE "(you can simply|you just need to|feel free to|consider doing)" <file>

# Marketing list intros (Rule 2c P)
grep -niE "(here's what we'll cover|in a nutshell|at a glance)" <file>

# Self-referential meta (Rule 2c Q)
grep -niE "(this documentation|this readme|the following section|below you'll find|as shown above)" <file>

# Empty preamble (Rule 2c R)
grep -niE "(the purpose of this is|the reason for .* is that|this function takes .* and returns|this is a helper that|what this does is)" <file>

# Docstring openers that lead with "This <noun>..." (Rule 2c R)
grep -niE "^\s*(\*|//|#)?\s*(this function|this class|this file|this module|this method|this script)\b" <file>

# "human" / "user" used as reader reference (Rule 2c R3)
grep -niE "\b(the human|the user)\b.*(can|may|will|should|is able)" <file>
grep -niE "\b(developers? can|users? can)\b" <file>

# Generic identifier names (Rule 2d S). Audit hits in context, not all are bugs.
grep -nE "\b(data|result|value|temp|item|obj|info|payload)\b\s*[:=]" <file>
grep -nE "\b(DataManager|StringHelper|RequestProcessor|.*Service|.*Provider|.*Handler|.*Utility|.*Factory)\b" <file>

# Test voice (Rule 2d T)
grep -niE "(should correctly|should properly|should work as expected)" <file>

# AI conversational artifacts (Rule 2d U). Any hit = critical.
grep -niE "(as an ai|certainly!|of course!|i'd be happy to|here's the .* you asked for|let me know if|i hope this helps)" <file>

# Defensive comments (Rule 2d V)
grep -niE "(just in case|defensive check|belt-and-suspenders|future-proof|for safety)" <file>

# Stale metadata (Rule 2d W)
grep -niE "(^|\*|//)\s*(author|created by|modified by|date):" <file>

# Placeholder TODOs without detail (Rule 2d X)
grep -nE "(TODO|FIXME|XXX|HACK):?\s*(implement|refactor|later|fix)" <file>

# JSDoc throws/return fluff (Rule 2d Z)
grep -niE "@throws \{.*\} (if something|an error of type)" <file>
grep -niE "@returns? \{Promise<void>\} a promise that" <file>

# Type-cast / linter suppression smell (Rule 2d AA)
grep -nE "(@ts-ignore|@ts-expect-error|eslint-disable)" <file>
grep -nE "as any\b" <file>
# Per-language pragma suppressions to audit
grep -nE "# noqa(:|$| )|# type: ?ignore|# pragma: no cover" <file>
grep -nE "@phpstan-ignore|@psalm-suppress" <file>
grep -nE "# rubocop:(disable|enable)" <file>
grep -nE "//nolint" <file>

# Output-format AI tells (Rule 2d CC)
grep -nE "^[[:space:]]*(\*|//)[[:space:]]*(IMPORTANT|WARNING|NOTE):" <file>

# Syntax check (pick the right one)
node --check <file>          # JS
python -m py_compile <file>  # Python
tsc --noEmit                 # TS project
```

If any grep returns a match, review and either fix or document why it stays (e.g. `atomic` inside a string literal is fine).

## Rule 9: Process advisories

- **Edit one rule type per pass.** Mixing vocab swaps with structural rewrites makes diffs unreviewable. Pass 1: Rule 2. Pass 2: Rule 2b/c/d. Pass 3: Rule 3. Pass 4: Rule 4.
- **Review per file before bulk-applying.** Don't run global replace_all across a repo without skimming the matches first. Substring collisions hide here.
- **Don't commit until all verification greps pass.** Mid-state commits poison the history.
- **Diff before each commit.** `git diff --stat` should show only `.md`-like changes (comments + identifiers). Any code-logic line change = stop and audit.
- **One file at a time for the first run.** Build confidence with the rules on a single file before running on the whole tree.
- **Backup before identifier renames.** Renames span the whole file; revert is harder than for comment edits.

## Rule 10: Cross-language adaptations

JS/TS examples in this doc, but the rules transfer. Per-language tells:

### How to read this section

Each language/framework block assumes Rules 2, 2c, R, and Z apply by default. Sub-sections list only deviations, framework-mandated keeps, and AI-tell patterns specific to that stack. When a stack composes on another (Next.js on React, Livewire on Laravel, Twig on PHP), apply the parent first, then the child overrides.

### JavaScript
- JSDoc `/** */`. Apply Rules 2, 2c, Z (this doc's default examples)
- `@param {string} name - The name parameter` → `@param {string} name`
- `@returns {Promise<void>} A promise that resolves when complete` → `@returns {Promise<void>}`
- AI loves `*Service`, `*Manager`, `*Helper`, `*Util`, `*Provider`, `*Handler`, `*Factory` suffixes. Apply Rule S (keep when framework-mandated: React Context Provider, Express Handler, NestJS Service, AWS Lambda Handler)
- IIFE wrappers with comment "immediately invoked function expression". Drop comment, idiom says it
- `// eslint-disable-next-line` without justification. Apply Rule AA
- Arrow function comments restating the arrow (`// arrow function for X`). Drop
- `async/await` blocks with comment "this is async". Drop
- Destructuring with comment listing the destructured names. Drop, code shows it
- Default param comments restating the default. Drop
- `// TODO:` without ticket reference. Apply Rule X

### JavaScript / TypeScript: React (and Next.js, Remix)

React adds idioms that override generic JS/TS rules. Apply on top of the JS section.

- **Functional component docstrings**: AI loves `/** This component renders a user profile card. */` over `function UserProfileCard() { ... }`. Apply Rule R (drop "This component renders" opener). The component name already says what it renders. Keep doc only when describing *non-obvious* behavior (memoization strategy, ref forwarding rationale, suspense boundary).
- **JSX comments** (`{/* ... */}`). Apply Rules 2, 2c. Especially common: `{/* Render the list of items */}` over `{items.map(...)}` → drop.
- **`useState` declarations**: `const [count, setCount] = useState(0); // initialize count state` → drop, hook is self-documenting. Keep only when the initial value is non-obvious (computed, lazy initializer, derived from props).
- **`useEffect` blocks**: `// run on mount` over `useEffect(() => {...}, [])` → drop, empty dep array says it. Keep when documenting *why* a dep is omitted (intentional stale closure, ref pattern). That's a real load-bearing reason.
- **Dependency array comments**: `// eslint-disable-next-line react-hooks/exhaustive-deps`. Apply Rule AA. If suppression stays, the reason must be one sentence: "intentional: only re-run on `userId` change, `onSave` is stable from context".
- **`useMemo` / `useCallback`**: `// memoize for performance` → drop or name the actual perf reason (expensive child re-render, referential identity for context, dep of another hook). "For performance" is filler.
- **Custom hooks**: `use*` naming is mandatory React convention. Don't apply Rule 4 renames that drop the `use` prefix; React's linter depends on it. Rename the noun part only.
- **Props destructuring**: `function Foo({ name, age, onClick }) {` followed by a comment listing the props → drop comment, destructuring is the doc.
- **PropTypes / TS prop interfaces**: drop tautological field docs (`/** The name */ name: string`). Keep only when the prop has a constraint not captured by the type (units, format, optional behavior).
- **`React.FC<Props>` vs `function Component(props: Props)`**: codebase convention, don't fight it. Don't add comments explaining the choice.
- **`memo`, `forwardRef`, `lazy` wrappers**: `// memoized for perf` over `React.memo(Component)` → drop or name the actual reason. forwardRef: drop "to forward refs", keep when documenting why a ref is needed.
- **`key` prop comments**: `key={item.id} // unique key for React reconciliation` → drop, idiom is standard.
- **Context Provider / Consumer**: `*Provider`, `*Context` suffixes are React convention. Apply Rule S only to non-React-mandated suffixes (`UserService`, `DataManager` inside React components).
- **HOC naming**: `with*` prefix is React HOC convention (`withRouter`, `withAuth`). Apply Rule 4 carefully: don't drop `with*` if it's a true HOC, do rename when it's actually a hook in disguise.
- **Server Components vs Client Components** (Next.js App Router, React 19+): `'use client'` / `'use server'` directives with explanation comments: keep directive, drop "this makes the component a client component" comment (directive name says it).
- **Storybook story files** (`*.stories.tsx`). Apply Rule T (test voice) to story names. `'Should render with default props'` → `'Default'`. Keep `args`, `argTypes`, `parameters` config.
- **Next.js page / layout / route comments**: AI loves `// This is the home page` over `app/page.tsx`. Drop file-role comments; file location says it.
- **`getServerSideProps`, `getStaticProps`, `generateMetadata`**: keep these names (Next.js framework-mandated). Drop verbose docstrings explaining what the framework already documents.

React-flavored AI tells in comments:

| Pattern | Fix |
|---|---|
| "This component renders..." | drop opener |
| "Reusable component for X" | drop "reusable" |
| "Stateful component that..." | drop "stateful" |
| "Presentational component" / "Dumb component" / "Container component" | drop label (anachronistic since hooks) |
| "Single source of truth" | drop |
| "Lifts state up" | drop unless documenting a specific lift |
| "Following React best practices" | drop |
| "Optimized for re-renders" | name the actual optimization or drop |
| "Hydration-safe" | name the actual hydration concern or drop |

### JavaScript: Next.js (App Router and Pages Router)

Apply on top of the React section.

- **App Router file conventions** (`app/page.tsx`, `app/layout.tsx`, `app/loading.tsx`, `app/error.tsx`, `app/not-found.tsx`, `app/template.tsx`, `app/route.ts`). Keep filenames, drop file-role comments ("This is the home page" over `app/page.tsx` → drop, filename + path say it).
- **Pages Router** (`pages/index.tsx`, `pages/api/*.ts`, `pages/_app.tsx`, `pages/_document.tsx`). Same: keep filenames, drop file-role comments.
- **Dynamic route segments** (`[id]`, `[...slug]`, `[[...slug]]`, `(group)`, `@parallel`). Keep folder names, drop "dynamic route for X" filler.
- **`'use client'` / `'use server'` directives**: keep, drop "this makes the component a client component" filler (directive name says it).
- **Server Actions** (`async function action() { 'use server' ... }`). Keep `'use server'`, drop "server action that..." opener. Apply Rule R.
- **Route Handlers** (`export async function GET/POST/PUT/DELETE/PATCH(...)`). Drop tautological method docs ("Handles the GET request"). Apply Express rules.
- **`generateMetadata`, `generateStaticParams`, `generateViewport`**: keep framework function names, drop verbose docstrings that just describe what Next.js already documents.
- **`metadata` export** with `title`, `description`, `openGraph`, etc.. Never modify the literal string content (user-facing per Rule 1). Drop surrounding "SEO metadata" filler.
- **`fetch()` with Next caching options** (`{ next: { revalidate: 60, tags: ['x'] } }`, `cache: 'no-store'`, `cache: 'force-cache'`). Keep options, drop "ISR with 60s revalidate" filler. Keep notes only when the revalidate value or tag has non-obvious reasoning.
- **`unstable_cache`, `revalidatePath`, `revalidateTag`, `redirect`, `notFound`**: keep API call, drop filler.
- **Middleware** (`middleware.ts` exporting `middleware()` and `config.matcher`). Apply Express middleware rules. Keep `matcher` array, drop comments restating each path.
- **`next.config.js` / `next.config.mjs`**: apply Vite/Webpack config rules. Drop comments restating Next defaults. Keep notes for non-default options (`experimental`, `images.remotePatterns` rationale).
- **`Image` from `next/image`**: keep `<Image src="" alt="" width={} height={} priority />`, drop "Next optimized image" filler. `alt` text user-facing per Rule 1.
- **`Link` from `next/link`**: drop "client-side navigation" filler.
- **`Suspense` + `loading.tsx`**: drop "loading boundary" filler when `loading.tsx` is present (filename says it). Keep notes on explicit `<Suspense>` boundaries with custom fallback rationale.
- **`async` Server Components fetching data inline**: drop "fetches data on the server" filler, `async function Page()` says it.
- **Cookies / Headers / Draft Mode** (`cookies()`, `headers()`, `draftMode()` from `next/headers`). Keep, drop "access request cookies on server" filler.
- **`unstable_*` prefixed APIs**: keep the prefix verbatim, drop "experimental API" filler.

Next.js-flavored AI tells:

| Pattern | Fix |
|---|---|
| "Built with Next.js for blazing-fast performance" | drop |
| "Server-rendered React with Next.js" | drop |
| "Production-ready Next.js application" | drop |
| "Following Next.js best practices" | drop |
| "Full-stack React framework" | drop |
| "Leverages App Router" | drop |
| "Edge-ready Next.js handler" | "runs on Edge runtime" or drop |
| "Optimized with React Server Components" | drop |

### JavaScript: Nuxt (Nuxt 3 / Nuxt 4)

Apply on top of the Vue section.

- **Directory conventions** (`pages/`, `layouts/`, `components/`, `composables/`, `middleware/`, `plugins/`, `server/api/`, `server/routes/`, `server/middleware/`, `assets/`, `public/`, `content/`). Keep, drop file-role comments restating each directory's purpose.
- **Auto-imports**: Nuxt auto-imports composables, components, and utils. AI loves `// useFetch is auto-imported from #app` over `const { data } = await useFetch('/api/x')` → drop.
- **`definePageMeta`, `defineNuxtConfig`, `defineNuxtPlugin`, `defineNuxtRouteMiddleware`, `defineEventHandler`**: keep macro names, drop "page-level metadata for Nuxt" filler.
- **`useFetch`, `useAsyncData`, `useState`, `useCookie`, `useRoute`, `useRouter`, `useRequestHeaders`, `useRuntimeConfig`**: keep, drop "composable for SSR data fetching" filler.
- **`<NuxtLink>`, `<NuxtPage>`, `<NuxtLayout>`, `<NuxtIsland>`, `<NuxtLoadingIndicator>`**: keep, drop description filler.
- **`server/api/*.ts`** route handlers (`defineEventHandler`). Apply Express rules. Drop tautological method docs.
- **Nitro server engine config** (`nitro: { ... }` in `nuxt.config.ts`). Keep config, drop comments restating Nitro defaults.
- **`nuxt.config.ts`**: apply Vite/Webpack config rules. Drop module description comments (`'@nuxt/content'` → don't add `// content module for Nuxt`).
- **Modules** (`@nuxt/content`, `@nuxt/image`, `@nuxt/ui`, `@nuxtjs/tailwindcss`, `@pinia/nuxt`). Keep, drop "Nuxt module that..." filler.
- **`<NuxtImg>` / `<NuxtPicture>` from `@nuxt/image`**: drop "Nuxt optimized image" filler. `alt` user-facing per Rule 1.
- **Content module** (`@nuxt/content`, `queryContent`, `useContentQuery`). Keep, drop "content collection query" filler. Don't modify frontmatter keys in `.md` content files.
- **Hybrid rendering** (`routeRules: { '/blog/**': { prerender: true } }`). Keep rules, drop "prerender blog pages" filler when the matcher already says it. Keep notes when the rule diverges from convention.
- **`useState('key', () => initial)`**: Nuxt's SSR-safe state. Drop "SSR-safe state" filler, the composable name says it.
- **`navigateTo`, `abortNavigation`, `clearError`, `showError`, `createError`**: keep, drop filler.
- **`#imports`, `#app`, `#components`** virtual module specifiers. Keep verbatim, drop "Nuxt virtual import" filler.
- **`.client.ts` / `.server.ts` suffix** on plugin / composable filenames. Keep suffix, drop "runs only on client" filler (suffix says it).

Nuxt-flavored AI tells:

| Pattern | Fix |
|---|---|
| "Universal Vue application with Nuxt" | drop "Universal" |
| "Built with Nuxt for SSR and SSG" | drop |
| "Production-ready Nuxt app" | drop |
| "Following Nuxt 3 best practices" | drop |
| "Leverages Nuxt's auto-imports" | drop |
| "Hybrid rendering with Nuxt" | drop |
| "Modern Vue meta-framework" | drop |

### JavaScript: EJS view templates

EJS (`.ejs`) is plain HTML with `<% %>` embedded JavaScript. Common with Express via `res.render()`. AI loves to over-comment both the JS scriptlets and the HTML around them.

- **EJS comment tag** `<%# ... %>`. Apply Rules 2, 2c. These are stripped at render; AI fills them with restatement of the next scriptlet → drop.
- **HTML comments** (`<!-- -->`). Apply Rules 2, 2c. EJS does **not** strip HTML comments; they ship to the client. Drop dev-facing restatement comments. Keep when actually needed in rendered output.
- **Scriptlet tags**: keep verbatim, never collapse or rewrite:
  - `<% code %>`. Control flow, no output
  - `<%= value %>`. Output, HTML-escaped
  - `<%- value %>`. Output, **unescaped** (XSS risk if value is user-controlled)
  - `<%_ %>` / `<%_ -%>` / `<% -%>`. Whitespace control modifiers; **keep the underscore/dash**, they affect output.
- **Unescaped output** `<%- value %>`. Keep a one-line *why* the escape is bypassed (trusted source, pre-sanitized, includes raw HTML partial). AI tends to use `<%-` without justification → flag those. Real XSS hazards out of scope per Rule 1 (don't "fix" by switching to `<%=`; surface for review).
- **`<%- include('partials/header') %>`**: drop "include the header partial" filler, the `include()` call says it.
- **`<%- include('partial', { data: x }) %>`** with comment listing each passed prop → drop, the object literal is the doc.
- **Loop scriptlets**: `<% users.forEach(function(user) { %> ... <% }); %>` with comment "loop through users" → drop. Same for `for`, `while`, `if/else` blocks.
- **Locals destructuring** (`<% const { user, items } = locals; %>`) with comment "destructure locals" → drop.
- **`res.render('view', { data })`** call sites in Express controllers. Drop comments restating the view name or passed props. The view path + object literal say it.
- **express-ejs-layouts**: `<%- body %>`, `layout('layout-name')`. Drop "renders the page body" filler.
- **EJS-Mate** block helpers (`block('name')`, `define('section', function() { ... })`). Keep helper calls, drop description filler.
- **Conditional rendering** with `<% if (user) { %>...<% } %>`. Drop "show only when logged in" filler when the condition expression is self-explanatory.
- **Whitespace-trim modifiers** (`<%- -%>`, `<% -%>`, `<%_ ... _%>`). Keep verbatim. Never strip the dash or underscore. They trim surrounding whitespace and removing them changes output.
- **Strict mode / `with(locals)`**: EJS option, no inline comment needed about it.
- **Mixed JS + HTML indentation**: AI tries to "fix" indentation by reflowing scriptlets. **Leave whitespace alone**: EJS is whitespace-sensitive for rendered output. Out of scope per Rule 1.
- **Form rendering**: drop comments labelling each input. Keep `name=""`, `id=""`, `value=""` literals untouched (form behavior).
- **Translation calls** inside templates (`<%= t('key') %>`, `<%= __('key') %>` from i18n libs). Never modify the key string. Out of scope per Rule 1.

EJS-flavored AI tells:

| Pattern | Fix |
|---|---|
| "EJS template that renders X" | apply Rule R |
| "Reusable partial" | drop "reusable" |
| "Clean, semantic markup" | drop |
| "Following EJS best practices" | drop |
| "Powerful templating with EJS" | drop |
| `<%# This file renders the user profile %>` opener | drop, filename says it |

### JavaScript: Astro

`.astro` components have a frontmatter script (between `---` fences) and a template. AI loves to over-comment both halves.

- **Component frontmatter docstring**: AI loves `--- /** This Astro component renders a hero section. */` → apply Rule R. Component name + file path say it.
- **Frontmatter `import` block** with comments naming each import → drop, the import statement is the doc.
- **`Astro.props` / `Astro.params` / `Astro.request` / `Astro.url` / `Astro.cookies`**: keep, drop "access component props" filler.
- **`Astro.glob()`, `import.meta.glob()`**: drop "load all matching files" filler, function name says it.
- **Component islands directives**: `client:load`, `client:idle`, `client:visible`, `client:media="..."`, `client:only="react"`. Keep verbatim, drop comments restating which hydration strategy. Add a real note only when the choice between `client:idle` and `client:visible` has a measured reason.
- **`server:defer`** / **Server Islands**: keep, drop "renders on server then streams" filler.
- **Template HTML comments** (`<!-- -->`). Apply Rules 2, 2c. Astro strips `<!-- -->` from output by default; AI sometimes uses `{/* */}` (JSX-style) inside template. Those *are* preserved as HTML comments. Apply Rule 2c to both.
- **Content Collections**: `defineCollection`, `getCollection`, `getEntry`, `getEntries` from `astro:content`. Keep, drop verbose collection schema docstrings. Keep Zod refinement notes only when the constraint is non-obvious.
- **`src/content.config.ts` / `src/content/config.ts`** schemas. AI loves `/** Comprehensive blog collection schema */`. Apply Rule R + A.
- **`getStaticPaths()`** in dynamic routes (`[slug].astro`, `[...path].astro`). Keep, drop "generates static paths" filler. Keep a note when pagination params or `paginate()` usage has non-obvious slicing.
- **`prerender = true` / `prerender = false`** with comment "enables SSR for this route" → drop, the export says it.
- **View Transitions**: `<ViewTransitions />`, `transition:name="..."`, `transition:animate="..."` directives. Keep, drop "enables smooth page transitions" filler.
- **MDX components** (`.mdx` files importing Astro components). Apply Rules 2, 2c to MDX prose. Don't strip frontmatter keys parsed by content collections (`title`, `pubDate`, `tags`, etc.).
- **Integrations** in `astro.config.mjs` (`@astrojs/react`, `@astrojs/tailwind`, `@astrojs/mdx`, `@astrojs/sitemap`). Drop comments restating each integration's purpose. Keep notes only when integration options diverge from defaults.
- **Adapter config** (`@astrojs/node`, `@astrojs/vercel`, `@astrojs/cloudflare`, `@astrojs/netlify`). Keep adapter call, drop "deploys to X" filler. Filename + adapter name say it.
- **`output: 'static' | 'server' | 'hybrid'`**: drop comment "configures rendering mode", the value names it.
- **API routes** (`src/pages/api/*.ts` exporting `GET`, `POST`, etc.). Apply Express/Node rules. Drop tautological route-method docs.
- **Middleware** (`src/middleware.ts`, `onRequest`). Apply Express middleware rules.
- **Slots** (`<slot />`, `<slot name="header" />`). Keep, drop "named slot for header content" filler.
- **`Astro.slots.render()`** / **`Astro.slots.has()`**: keep API call, drop filler.
- **Scoped `<style>` blocks**: Astro scopes styles by default; drop "scoped to this component" filler, behavior is default.
- **`is:global`, `is:inline`, `is:raw`** directives. Keep, drop "applies styles globally" filler, directive name says it.
- **Image component** (`<Image src={...} alt="..." />` from `astro:assets`). Keep, drop "Astro optimized image" filler. The `alt` text is user-facing. Out of scope per Rule 1.

Astro-flavored AI tells:

| Pattern | Fix |
|---|---|
| "Island architecture component" | drop "Island architecture" |
| "Zero-JS by default" | drop |
| "Ships zero client-side JavaScript" | drop unless documenting a specific case |
| "Lightning-fast static site" | drop |
| "Content-driven Astro site" | drop |
| "Modern web framework" | drop |
| "Astro component for X" | drop opener |
| "Server-first rendering" | drop |

### JavaScript: Vue.js (2 and 3, including Nuxt)

- **SFC `<template>` comments** (`<!-- -->`). Apply Rules 2, 2c. AI loves `<!-- Render the list -->` over `<li v-for="...">` → drop.
- **`<script setup>` blocks**: composition API. AI loves `// Reactive state for X` over `const x = ref(0)` → drop, `ref()` says it.
- **`ref()` / `reactive()` / `computed()` / `watch()`**: drop "this is reactive" filler. Keep notes only when reactivity is *non-obvious* (shallowRef rationale, watch with `{ deep: true }`, sync flush timing).
- **Options API `data`, `methods`, `computed`, `watch`** blocks with comments labelling each section. Drop, language idiom.
- **`defineProps`, `defineEmits`, `defineExpose`, `defineModel`**: keep the macro, drop "for parent communication" comment.
- **`v-if` / `v-show` / `v-for`** with key prop comments. Drop, idiomatic.
- **Single File Component `<style scoped>`** blocks. Apply Rule 2c to CSS comments inside.
- **Pinia / Vuex stores**: `*Store` naming is convention; don't apply Rule S. Drop "this is the store for X" filler in `defineStore` docs.
- **Nuxt directory-based conventions** (`pages/`, `layouts/`, `middleware/`, `plugins/`, `server/api/`). Keep the directory names, drop file-role comments ("This is the home page" over `pages/index.vue`).
- **Auto-imports**: Nuxt auto-imports composables. AI loves `// useFoo is auto-imported from composables/` over `const x = useFoo()` → drop.

Vue-flavored AI tells:

| Pattern | Fix |
|---|---|
| "Single File Component for..." | drop, `.vue` extension says it |
| "Reactive composable" | drop "reactive", `use*` naming says it |
| "This composable provides..." | apply Rule R |

### JavaScript: Alpine.js

- **`x-data`, `x-show`, `x-on:click`, `x-bind`, `x-model`** directives in HTML. Apply Rules 2, 2c to surrounding HTML comments.
- **Inline JS expressions inside `x-data="{ ... }"`**: short, idiomatic. Don't add comments explaining what the inline expression does.
- **`Alpine.data()`, `Alpine.store()`, `Alpine.magic()`**: keep naming, drop "registers an Alpine component" filler.
- **`x-init` blocks**: `<div x-init="fetchData()" />` with comment `<!-- Initialize component -->` → drop, attribute says it.
- **`$dispatch`, `$nextTick`, `$watch`, `$refs`** magic properties. Keep, drop "Alpine magic property" filler.
- HTML attribute order: Alpine convention is `x-data` first, then `x-init`, then other `x-*`. Don't reorder, don't comment-explain.

### Node.js: Express (and Koa, Fastify, Hono)

- **Route handler docstrings**: AI loves `/** Handles the GET /users request */` over `app.get('/users', ...)` → apply Rule R. The route method + path already say it.
- **Middleware function naming**: `function authMiddleware(req, res, next)` with comment "middleware function for auth" → drop, signature + name say it.
- **`req`, `res`, `next` parameter docs**: drop tautological `@param {Request} req - The request object` (Rule Z). Keep when documenting *attached* properties (`req.user`, `req.session.X`).
- **Error-handling middleware** (`(err, req, res, next) => {...}`). Keep the 4-arg signature, drop "Express error-handling middleware (note the 4 args)" comment unless the codebase has multiple and ordering matters.
- **Route-mounting comments**: `app.use('/api', apiRouter); // mount API router at /api` → drop.
- **CORS / body-parser / helmet setup** with comments explaining what each middleware does. Drop unless config is non-default.
- **`async` route handlers without `try/catch`**: comment "express-async-errors handles this" → keep only if the package is actually loaded and non-obvious.
- **Status code comments**: `res.status(404).send(...); // not found` → drop, `404` says it.
- **Fastify schemas / Hono validators**: keep schema, drop tautological docstring.

Express/Node-flavored AI tells:

| Pattern | Fix |
|---|---|
| "RESTful API endpoint" | drop "RESTful", describe behavior |
| "Express middleware that..." | apply Rule R |
| "Production-ready Node.js server" | drop |
| "Battle-tested middleware stack" | drop |

### JavaScript: Build tooling (Vite, Webpack, Rollup, esbuild, Turbopack)

Config files (`vite.config.ts`, `webpack.config.js`, `rollup.config.js`, etc.) are high AI-comment density.

- **Top-of-file docstring**: AI loves `/** Comprehensive Vite configuration with optimized build output */` → apply Rule R + A. Drop opener, drop boast.
- **Plugin array comments**: `plugins: [react(), tsconfigPaths()]` with `// React + TS path plugins` → drop, plugin names say it.
- **`resolve.alias` block** with comments restating each alias → drop, mapping is the comment.
- **`build.rollupOptions` / `output.manualChunks`**: keep config, drop "split vendor bundle for caching" filler. Add a real note only when chunking strategy is non-obvious.
- **`define` / `EnvironmentPlugin`**: replace value comments restating the env var name → drop.
- **Webpack loader chains** (`use: ['style-loader', 'css-loader', 'sass-loader']`). Drop "applied in reverse order" comment unless the codebase has a loader that's order-sensitive in a non-standard way.
- **DevServer / HMR config**: drop "hot module replacement" comments, HMR is the default expectation.
- **Source map comments**: drop "for debugging" filler, source maps are standard.
- **Tree-shaking comments**: drop "tree-shakable" filler unless documenting a `sideEffects: false` choice.
- **Conditional config** (`mode === 'production' ? ... : ...`). Drop "different config for prod" comments, ternary says it.

Build-tooling-flavored AI tells:

| Pattern | Fix |
|---|---|
| "Optimized production build" | drop |
| "Blazing-fast HMR" | drop |
| "Lightning-fast dev server" | drop |
| "Modern build pipeline" | drop (also: "pipeline" buzzword. See Rule 2 conditional keep) |
| "Zero-config setup" | drop |

### JavaScript: Webpack (dedicated)

Apply on top of the shared Build tooling section. Webpack has the largest config surface of any bundler, and AI fills it with comment bloat.

- **`webpack.config.js` / `webpack.config.ts`** top-of-file. Apply Rule R + A. Drop "Comprehensive Webpack configuration for production-grade builds".
- **`mode: 'development' | 'production' | 'none'`** with comment "sets build mode" → drop, value names it. Keep notes only when `mode: 'none'` is intentional (bypassing default optimizations).
- **`entry`** object with multi-entry comments restating each entry name → drop, the key + path say it. Keep notes when an entry has non-obvious load order or `dependOn` chaining.
- **`output`** block:
  - `filename: '[name].[contenthash].js'` with comment explaining placeholder tokens → drop unless the codebase mixes hash strategies.
  - `publicPath`. Keep, drop "CDN base URL" filler. Add notes only when `publicPath: 'auto'` is used (runtime detection) or when build-time vs runtime resolution matters.
  - `clean: true` with comment "clean dist before build" → drop, option name says it.
- **`module.rules` loader chains**:
  - Reverse-order comment (`use: ['style-loader', 'css-loader', 'sass-loader'] // applied right to left`). Drop, this is documented Webpack behavior. Keep only when a chain is order-sensitive in a *non-standard* way (cache loader placement, thread-loader before fork-ts-checker, etc.).
  - `enforce: 'pre'` / `enforce: 'post'`. Keep, drop "runs before/after other loaders" filler.
  - `oneOf:` blocks with comments restating each case → drop.
  - `exclude: /node_modules/` with comment "skip node_modules" → drop, regex says it.
  - `babel-loader`, `swc-loader`, `ts-loader`, `esbuild-loader` with comments naming the transpiler → drop, loader name says it. Keep notes when loader options diverge from defaults.
- **`resolve`**:
  - `extensions: ['.ts', '.tsx', '.js']` with comment "resolve order" → drop, the array order is the doc.
  - `alias` block. Drop comments restating each alias mapping.
  - `resolveLoader.modules` / `resolveLoader.extensions`. Keep, drop "where to find loaders" filler.
- **`plugins` array**: drop comments restating each plugin's purpose. AI loves to label `new HtmlWebpackPlugin({...})` with `// generates HTML`. Plugin name says it.
- **`HtmlWebpackPlugin` template config**: keep `template:`, `inject:`, `scriptLoading:` options. Drop "injects bundles into HTML" filler.
- **`MiniCssExtractPlugin` / `mini-css-extract-plugin`**: drop "extracts CSS into separate files" filler.
- **`DefinePlugin` vs `EnvironmentPlugin` vs `dotenv-webpack`**: keep, drop "replaces process.env at build time" filler. Add notes only when a value is computed (e.g. `JSON.stringify(require('./package.json').version)`).
- **`ProvidePlugin`**: keep, drop "auto-imports X globally" filler. Add a one-line *why* when the globally-provided module is non-obvious (legacy code expecting jQuery, Buffer polyfill for v5).
- **`webpack.IgnorePlugin`**: keep, document the *reason* the module is ignored (often locale files of `moment`, native deps in Node-only context).
- **`optimization`**:
  - `splitChunks` `cacheGroups`. Drop comments restating each group's `test:`. Keep one-line *why* for each group when the split rationale is non-obvious (vendor frequency, framework hot-path, shared chunk threshold).
  - `runtimeChunk: 'single' | 'multiple'`. Keep, drop "extracts runtime" filler.
  - `minimize`, `minimizer` (`TerserPlugin`, `CssMinimizerPlugin`). Drop "minifies output" filler. Keep notes when Terser options diverge (preserve class names, mangle props pattern).
  - `usedExports`, `sideEffects`. Keep, document `sideEffects: false` rationale only when the codebase has side-effectful modules that need an explicit list.
  - `concatenateModules` (`ModuleConcatenationPlugin`). Keep, drop "scope hoisting" filler.
- **`externals`**: `externals: { react: 'React', 'react-dom': 'ReactDOM' }`. Keep, drop "load from CDN" filler. Add a one-line *why* (library build expecting consumer to provide, micro-frontend boundary, peer-dep externalization).
- **Module Federation** (`ModuleFederationPlugin`):
  - `name`, `filename`, `exposes`, `remotes`, `shared`. Keep config. Drop "Module Federation host/remote" filler.
  - `shared` block. Keep `singleton: true`, `eager: true`, `requiredVersion` flags. Document *only* the rationale for `eager` (initialization chunk) or `singleton` (state-leaking risk). AI tends to copy these flags without understanding.
  - `library: { type: 'var', name: 'X' }`. Keep, drop "expose as global" filler.
- **`target: 'web' | 'node' | 'webworker' | 'electron-main' | 'electron-renderer' | 'electron-preload' | 'browserslist' | ['web', 'es2020']`**: keep, drop "build target" filler. Keep notes only for unusual combinations (multi-target arrays, browserslist sync rationale).
- **`devServer`**: keep config. Drop:
  - `hot: true` "enables HMR" → drop, HMR is the default expectation.
  - `compress: true` "gzip" → drop.
  - `historyApiFallback: true` "SPA routing" → drop, idiomatic.
  - Keep notes only for non-default `proxy`, `setupMiddlewares`, `client.overlay` options.
- **`devtool`**: `source-map`, `eval-cheap-module-source-map`, etc. Drop "for debugging" filler. Keep notes when the chosen value trades build speed vs accuracy in a non-default way (Webpack ships a default; deviation deserves a one-line *why*).
- **Asset modules** (`type: 'asset/resource'`, `'asset/inline'`, `'asset/source'`, `'asset'`). Keep, drop "replaces file-loader / url-loader / raw-loader" filler unless the codebase has a Webpack 4 → 5 migration in flight. Keep `parser.dataUrlCondition.maxSize` notes when the threshold has a measured reason.
- **HMR boundaries**: `module.hot.accept(...)` / `import.meta.webpackHot.accept(...)` in source. Keep, document the *boundary rationale* (intentional state preservation, side-effect re-execution). Drop "HMR boundary" tautology.
- **Webpack 4 vs 5 migration comments**: `// updated for Webpack 5` / `// Webpack 4 compat shim`. Apply Rule W. Migration notes belong in the PR, not in source. Delete unless the shim is still active and the comment names which Webpack 4 path it preserves.
- **`webpack-bundle-analyzer`**: `new BundleAnalyzerPlugin({ analyzerMode: 'static' })`. Keep, drop "generates bundle report" filler. Keep CLI invocation notes if onboarding-useful.
- **`cache: { type: 'filesystem' }`**: keep, drop "persistent cache" filler. Document `buildDependencies` only when non-default config files are tracked.
- **Multi-config arrays** (`module.exports = [webConfig, nodeConfig]`). Keep, drop "two builds: web and node" filler when the targets are visible in each config's `target` field.
- **Function-form configs** (`module.exports = (env, argv) => ({...})`). Keep, drop "config factory for env" filler.

Webpack-flavored AI tells (in addition to shared Build tooling list):

| Pattern | Fix |
|---|---|
| "Optimized for production with code splitting" | drop or name the actual splitting strategy |
| "Tree-shaken bundle" | drop |
| "Module Federation for micro-frontends" | drop, federation config says it |
| "Cache-friendly content hashing" | drop |
| "Lazy-loaded routes for performance" | drop, `import()` syntax says it |
| "Battle-tested Webpack 5 config" | drop |
| "Comprehensive loader pipeline" | drop, "pipeline" is buzzword (Rule 2 conditional) |
| "Production-grade source maps" | drop |
| "Future-proof bundler setup" | drop (apply Rule V) |

### CSS: Tailwind (and utility-first frameworks)

Tailwind shifts styling from CSS files into HTML class attributes. AI loves to over-comment both sides.

- **HTML `class="..."` attribute comments**: `<div class="flex items-center gap-4"> <!-- flex container with centered items -->` → drop, utility classes already say it.
- **`@apply` directives in CSS**: `@apply flex items-center gap-4; /* center the flex children */` → drop, `@apply` is the comment.
- **`tailwind.config.js`**: AI loves `/** Tailwind config with comprehensive theme customization */` → apply Rule R + A.
- **`theme.extend` blocks** restating each extended key. Drop comments, the key+value is the doc.
- **Custom plugin comments** (`plugin(function({ addUtilities, theme }) {...})`). Keep behavior notes, drop "this is a Tailwind plugin" filler.
- **`@layer base/components/utilities`** with comments restating which layer. Drop, directive says it.
- **`safelist` entries**: keep, with one-line *why* (dynamic class name, generated at runtime). AI tends to write essays here.
- **Dark mode classes** (`dark:bg-zinc-900`) with comments "for dark mode" → drop, variant says it.
- **Responsive prefixes** (`md:`, `lg:`, `xl:`) with comments naming the breakpoint → drop.
- **`prose` class from `@tailwindcss/typography`**: keep, don't add comments explaining what `prose` does.
- **Don't reformat class attribute order** unless Prettier's `prettier-plugin-tailwindcss` is configured. That's the canonical order. Manual reordering breaks diff history.

Tailwind-flavored AI tells:

| Pattern | Fix |
|---|---|
| "Utility-first styling" | drop |
| "Mobile-first responsive design" | drop |
| "Tailwind-powered" | drop |
| "Beautifully styled with Tailwind" | drop |
| "Modern, clean UI built with Tailwind" | drop |

### PHP: Laravel (with Eloquent, Blade, Livewire)

Apply on top of the PHP section. Covers core Laravel + Livewire (server-rendered components with `wire:*` Blade attributes).

- **Blade template comments** (`{{-- ... --}}`). Apply Rules 2, 2c. `{{-- Render the user list --}}` over `@foreach($users as $user)` → drop.
- **`wire:click`, `wire:model`, `wire:submit`, `wire:loading`, `wire:poll`** directives. Keep, drop "Livewire directive that..." filler.
- **Livewire component class docstring**: apply Rule R. Drop "This Livewire component handles..." opener.
- **`#[Computed]`, `#[On]`, `#[Url]`, `#[Validate]` attributes** (Livewire 3 PHP attributes). Keep, drop "computed property attribute" filler.
- **`render()` method** docstring saying "renders the component view" → drop, method name + return value say it.
- **`mount()` method** restating "initialization for Livewire" → drop.
- **Eloquent model docstrings**: AI loves verbose model class doc. Apply Rule R. Keep `@property` PHPDoc lines (IDE-load-bearing).
- **`$fillable`, `$guarded`, `$casts`, `$hidden`** array comments restating each field → drop.
- **Migration `up()` / `down()` blocks** with comments narrating each schema change → drop, Blueprint methods say it. Keep a top-of-method note only when the migration handles data backfill or has ordering caveats.
- **Route definitions** (`Route::get('/users', [UserController::class, 'index'])`) with `// GET /users → UserController@index` → drop.
- **Controller method docstrings** for resource controllers (`index`, `show`, `store`, `update`, `destroy`). Drop tautology, REST convention says it.
- **Form Request classes** with `authorize()` / `rules()` comments restating each rule → drop, the array is the doc.
- **`config/*.php` files**: keep top-of-file Laravel docblock (framework convention). Apply Rule R to inline comments restating env var names.
- **`.env` references** in code with comments like `// from .env` over `env('APP_KEY')` → drop, `env()` says it.

Laravel/Livewire-flavored AI tells:

| Pattern | Fix |
|---|---|
| "Elegant Laravel solution" | drop |
| "Leverages Laravel's IoC container" | "uses dependency injection" |
| "Following Laravel best practices" | drop |
| "Reactive Livewire component" | drop "reactive" |
| "Real-time UI with Livewire" | drop "real-time" (apply Rule A) |

### PHP: Symfony

Apply on top of the PHP section. Symfony is convention-heavy and config-heavy; AI loves to over-comment both.

- **Controller action docstrings**: AI loves `/** Handles the request to display the user list. */` over `public function index(): Response`. Apply Rule R. The route + method name say it.
- **PHP attribute routes** (`#[Route('/users', name: 'user_list', methods: ['GET'])]`). Keep, drop "Route attribute that..." filler.
- **Argument resolvers / `ParamConverter`**: `#[MapEntity]`, `#[MapRequestPayload]`, `#[CurrentUser]`. Keep, drop "automatically resolves the entity" filler.
- **Service definitions** (`services.yaml`, `services.xml`, attribute-based DI). Drop comments restating service IDs or class names. Keep when documenting a tagged service or non-default scope.
- **`#[AsCommand]`, `#[AsEventListener]`, `#[AsMessageHandler]` attributes**: keep, drop "registers as a console command" filler.
- **Twig template comments** (`{# ... #}`). Apply Rules 2, 2c. `{# Render the navigation #}` over `{% for item in nav %}` → drop.
- **Doctrine entity docblocks**: `#[ORM\Entity]`, `#[ORM\Column]` attributes (or legacy annotations). Keep, drop verbose `@var string` restating the type. Keep when documenting constraints not captured by the column type (length rationale, encoding).
- **Doctrine repository methods** restating the SQL/DQL they wrap → drop, method name + DQL say it.
- **Form types** (`buildForm()`). Drop comments restating each field's type, the builder call is the doc.
- **Validation constraints** (`#[Assert\NotBlank]`, `#[Assert\Email]`). Keep, drop "validates that..." filler. Add notes only for non-default options (group rationale, custom message reason).
- **Event subscriber `getSubscribedEvents()`**: drop comments labelling each event constant, the array is the doc.
- **Voters** (`Security\Voter`). Keep `supports()` / `voteOnAttribute()`, drop "this voter handles X" filler. Document only the *decision rationale* for non-obvious checks.
- **`config/packages/*.yaml`**: drop comments restating bundle defaults. Keep notes only on values that diverge from bundle defaults.
- **Bundle / `Kernel.php`**: keep framework-mandated structure, drop "this is the Symfony kernel" filler.
- **Messenger** message classes / handlers. Drop "Symfony Messenger message" filler, `#[AsMessageHandler]` says it.
- **`Request` / `Response` parameter docs**: drop tautological `@param Request $request - The HTTP request` (Rule Z). Keep when documenting attached attributes (`$request->attributes->get('_route_params')`).
- **`security.yaml` firewall comments**: keep only when the firewall ordering or stateless choice has a non-obvious reason.

Symfony-flavored AI tells:

| Pattern | Fix |
|---|---|
| "Leverages Symfony's dependency injection container" | "uses DI" or drop |
| "Following Symfony best practices" | drop |
| "Robust Symfony controller" | drop "robust" |
| "Battle-tested service" | drop |
| "Production-ready bundle" | drop |
| "Elegant event-driven architecture" | drop, describe the event flow |
| "Comprehensive validation layer" | drop |

### PHP: Twig templates

Twig is used in Symfony, Drupal, Craft CMS, standalone PHP. Apply on top of the PHP section for `.twig` / `.html.twig` files.

- **Twig comments** (`{# ... #}`). Apply Rules 2, 2c, R. Drop comments that restate the next directive (`{# Loop through users #}` over `{% for user in users %}` → drop).
- **`{% extends 'base.html.twig' %}`** with comment "extends the base layout" → drop, directive says it.
- **`{% block name %}{% endblock %}`**: drop comments naming the block, the `name` is the doc. Keep when documenting *why* a block is overridden (parent-call rationale, conditional render).
- **`{% include %}` / `{% embed %}` / `{% use %}`**: drop "include partial X" filler.
- **Filters chain** (`{{ user.name|trim|lower|escape }}`). Drop comments naming each filter. Keep when a custom filter has non-obvious behavior.
- **`{% set %}` blocks** restating the variable name in a comment → drop.
- **Macro definitions** (`{% macro button(label, url) %}`). Apply Rule R to docstring-style comments above. Drop "macro that renders a button" filler.
- **`{% apply %}` blocks** (e.g. `{% apply spaceless %}`). Keep, drop filler comments.
- **HTML escaping**: `{{ x|raw }}` should keep a comment naming *why* escaping is bypassed (trusted source, pre-escaped). AI tends to add raw without justification. Flag those.
- **Translation tags** (`{% trans %}`, `{{ 'key'|trans }}`). Never modify the message catalog key. Out of scope per Rule 1.
- **Asset helpers** (`{{ asset('build/app.css') }}`, `{{ encore_entry_link_tags('app') }}`). Drop "loads the compiled CSS" filler, helper name says it.
- **Form rendering** (`{{ form_start(form) }}`, `{{ form_widget(form.field) }}`). Drop comments restating which form part is being rendered.
- **`{% verbatim %}`** blocks (when output contains literal `{{ }}` for client-side templates). Keep, drop "prevents Twig parsing" filler unless the nested template engine is non-obvious.
- **Drupal Twig** (`{{ attach_library() }}`, `{{ drupal_view() }}`). Keep Drupal-specific functions, apply Rule R to surrounding prose.
- **Whitespace-control modifiers** (`{%- ... -%}`, `{{- ... -}}`). Keep, never strip the `-`. They affect output.

Twig-flavored AI tells:

| Pattern | Fix |
|---|---|
| "Reusable Twig macro" | drop "reusable" |
| "Clean, semantic template" | drop |
| "DRY Twig partial" | drop |
| "Powerful template inheritance" | drop |
| "Following Twig best practices" | drop |

### TypeScript
- All JavaScript rules above apply, plus:
- TSDoc `@param`, `@returns`, `@throws`. Apply Rule Z
- `interface Foo { /** The name of the foo. */ name: string }`. Drop tautological field docs
- `type` alias comment restating the alias (`/** A string alias for X */ type X = string`). Drop or describe constraint
- AI loves `as any`, `as unknown as Foo` double-casts. Apply Rule AA
- `// @ts-ignore`, `// @ts-expect-error` without justification. Apply Rule AA
- Generic param names: AI loves `T`, `U`, `V` even when domain names fit (`TUser`, `TResponse`). Keep `T` when truly generic, name them when domain-specific
- `Partial<X>`, `Pick<X, K>`, `Omit<X, K>` with comments restating what they do. Drop, utility types are self-documenting
- `enum` member docs that just restate the member name. Drop
- Branded types (`type UserId = string & { __brand: 'UserId' }`). Keep the brand idiom comment if it explains the *why*, drop if it just restates the syntax
- Decorator comments (`@Injectable` "for dependency injection"). Drop, decorator name says it

### Python
- Docstring `"""` style. Apply Rules 2, 2c, 3 inside `"""..."""`
- AI loves `Optional[Type]` when `Type | None` is shorter (PEP 604)
- AI loves type hints on every internal variable; trim to function signatures
- `# This function does X` over `def x():` → drop
- `:param x:` / `:return:` reST format. Apply Rule Z (JSDoc fluff equivalent)

### Go
- Doc comments must start with the identifier name (Go convention), e.g. `// MethodName ...`. Don't strip the name; only clean the rest.
- AI loves `Manager`/`Service`/`Provider` suffixes; apply Rule S
- Receiver var names: keep short (1-2 letters), AI tends to verbose them

### Rust
- `///` doc comments. Apply Rules 2, 2c
- AI loves `unwrap()` with `// safe because X`. Fix the unwrap if X is real
- `// SAFETY:` blocks: keep (genuine), drop "for safety" fluff (Rule V)

### Java
- Javadoc `@param`, `@return`. Apply Rule Z
- AI loves `*Impl`, `*Helper`, `*Util`, `*Manager` suffixes. Apply Rule S
- Excessive Hungarian prefixes. Drop if AI-introduced, keep if codebase convention
- `{@link Foo#bar}` self-references that just restate the method name. Drop
- Lombok `@Getter`/`@Setter` with redundant Javadoc on each field. Drop the doc

### C#
- XML doc comments `/// <summary>...`. Apply Rules 2, 2c
- `<summary>Gets or sets the Name.</summary>` on auto-properties. Drop, name is self-documenting
- `<returns>Returns a Task.</returns>`. Drop tautology (apply Rule Z)
- AI loves `I` interface prefix even when unused convention. Drop if AI-introduced, keep if codebase uses it
- `*Service`, `*Manager`, `*Repository` suffixes. Keep when framework-mandated (ASP.NET DI), apply Rule S otherwise
- `ConfigureAwait(false)` with three-line explanation comments. Keep call, drop explanation
- Region directives (`#region`) used as decoration. Drop unless they fold genuinely distinct sections

### C / C++
- Doxygen `/** */` or `/// ` blocks. Apply Rules 2, 2c, Z
- Header file doc + impl file doc saying the same thing. Keep one (usually header), drop the other
- `/* TODO */` blocks with no real action. Apply Rule X
- AI loves `*_helper`, `*_util` naming. Apply Rule S
- Macro comment `// macro for X` over `#define X ...` that just restates the macro. Drop
- `// SAFETY:` comments above raw pointer ops: keep when genuine; drop "for safety" filler (Rule V)
- Multi-line ASCII banner comments around section headers. Keep if structural, drop if decoration only

### Perl
- POD blocks (`=pod` / `=head1` / `=cut`). Apply Rules 2, 2c
- AI loves `=head1 DESCRIPTION` opening with "This module provides a comprehensive...". Apply Rule R
- `=head1 NAME` with module name then restated description. Drop description
- AI loves verbose POD `=item` lists where prose works. Apply Rule EE
- Sigil-restating comments (`# $foo is a scalar holding...`). Drop, the sigil says it
- `use strict; use warnings;` with three-line explanation. Keep pragmas, drop explanation
- Hash/array dereference idioms (`$$ref`, `@{$ref}`). Don't comment-explain the syntax

### Swift
- DocC `///` markup, `- Parameter`, `- Returns`, `- Throws`. Apply Rule Z
- AI loves `*Manager`, `*Coordinator`, `*ViewModel` suffixes. Keep when MVVM/Coordinator convention, apply Rule S otherwise
- `// MARK: -` section markers. Keep if they fold real sections, drop if decoration
- `guard let x = x else { return }` with comment "guard against nil". Drop comment, idiom says it
- `@available(iOS X.0, *)` with comment "for iOS X support". Drop comment, attribute says it
- Protocol extension default-implementation comments restating the method. Drop

### Kotlin
- KDoc `/** */` with `@param`, `@return`. Apply Rule Z
- `data class` with KDoc on each property restating the property name. Drop docs
- AI loves `Impl` suffixes on classes implementing one interface. Apply Rule S
- `companion object` doc that just says "companion object for X". Drop
- Scope functions (`let`, `apply`, `also`, `run`) with comments explaining which scope function does what. Drop, use the idiomatic one and trust the reader
- `@JvmStatic`, `@JvmOverloads` with "for Java interop" comments. Drop, annotation says it

### PHP
- PHPDoc `/** ... */` blocks. Apply Rules 2, 2c, Z (same as JSDoc)
- AI loves verbose class docblocks ("Comprehensive utility class that..."). Cut to one short sentence
- `@param string $name The name parameter for this function` → `@param string $name`
- `@return void Returns nothing` → drop or `@return void`
- `// @phpstan-ignore-line`, `/** @psalm-suppress X */`. Apply Rule AA (delete if AI-added without justification)
- AI loves `*Manager`, `*Service`, `*Provider`, `*Handler` suffixes. Apply Rule S (except where the framework like Laravel/Symfony mandates them)
- Namespace docblock at top of file with marketing prose. Trim to one factual line or drop

### PHP: WordPress (plugins / themes)

WordPress adds conventions that override generic PHP rules. Apply these on top of the PHP section above.

- **Plugin / theme file header** (`Plugin Name:`, `Description:`, `Author:`, `Version:`, `Text Domain:`, `License:`): **keep as-is**. WordPress parses these. Don't rewrite, don't strip "marketing" words from `Description:` (that's the directory listing copy, not a comment). Out of scope for Rule 1.
- **Hook callback docblocks**: AI loves `/** This action hook fires when the user is registered, allowing developers to seamlessly extend functionality. */`. Apply Rules R, A. Lead with what the callback does, not what hooks are.
- **`do_action()` / `apply_filters()` doc**: keep the `@since`, `@param` blocks above hook firing sites (WordPress core convention, parsed by docs generators). Apply Rule Z to the descriptions, never drop the structure.
- **Nonce / capability check comments**: `// Verify nonce for security` → drop (`wp_verify_nonce` says it). Keep only when the nonce action name is non-obvious. Real security failure modes (CSRF, capability bypass) are out of scope per Rule 1.
- **Sanitization / escaping comments**: `// Sanitize user input` over `sanitize_text_field($_POST['x'])` → drop. Keep when the choice of sanitizer is non-obvious (e.g. `wp_kses_post` vs `sanitize_textarea_field`).
- **`__()`, `_e()`, `esc_html__()`, `_n()`, `_x()` translation calls**: never modify the string literal or text domain. Out of scope per Rule 1. Strip surrounding comments that just restate "this is translatable".
- **Globals** (`global $wpdb;`, `global $post;`, `global $wp_query;`): `// access the WordPress database` over `global $wpdb;` → drop. Standard WP idiom.
- **Hook priority / arg count comments**: `add_action('init', 'my_func', 10, 2); // priority 10, 2 args` → drop, the call already says it. Keep when the *reason* for non-default priority matters (race with another plugin, ordering dependency).
- **Function name prefixes**: WordPress requires unique prefixes (`myplugin_get_users` not `get_users`). **Do not apply Rule 4 renames that drop the prefix**: collisions break other plugins and core. Rename only the part after the prefix.
- **`WP_*` class prefix** (`WP_Query`, `WP_User`, `WP_Error`). Core class names. Never rename. Plugin-side `WP_` prefix is reserved for core; plugins should use their own prefix.
- **WP coding standards naming**: WordPress uses `snake_case` for functions/variables, `Class_Name_With_Underscores` for classes (per WPCS). Don't "modernize" to camelCase. Respect the codebase's choice (modern plugins often use PSR-12 namespaced classes; classic plugins stick with WPCS).
- **`readme.txt`** (lowercase, plugin directory format). Different from `README.md`. Has structured headers (`== Description ==`, `== Installation ==`, `== Changelog ==`). Apply Rules DD/EE/FF only when explicitly asked, and keep all `==` headers intact since the WordPress.org parser depends on them.
- **Gutenberg `block.json`**: never edit. JSON config, not prose.
- **`@since` tags**: WordPress convention is `@since X.Y.Z`. Keep them. Don't apply Rule W (stale metadata). These are load-bearing for changelog generation.
- **`WP_DEBUG` / `error_log()` comments**: apply Rule 2b to em-dashes inside `error_log()` calls (dev-facing, in scope).
- **Inline comments inside `the_content()` filter callbacks**: high AI density. Audit aggressively for Rule 2c violations.
- **Marketing prose in theme `style.css` header** (`Theme Name:`, `Description:`, `Tags:`). Same as plugin header. Keep as-is. The Description appears in the WordPress.org directory.
- AI loves `*_init`, `*_setup`, `*_register` callback names without a plugin prefix. Collision risk. Add the prefix back, don't rename.

WordPress-specific AI tells in comments (apply to comments, never to user-facing translations or directory copy):

| Pattern | Fix |
|---|---|
| "leverages the WordPress API" | "uses WordPress hooks" / drop |
| "seamlessly integrates with WordPress" | drop |
| "WordPress-native experience" | drop |
| "battle-tested WordPress plugin" | drop |
| "production-ready Gutenberg block" | drop |
| "powerful custom post type" | drop |
| "comprehensive theme customizer integration" | drop |

### Ruby
- YARD / RDoc comment blocks (`# @param`, `# @return`). Apply Rule Z
- AI loves `# This method does X` over `def x`. Drop
- `# rubocop:disable Cop/Name`. Apply Rule AA (delete unless cop is genuinely wrong here)
- Method-name-restating comments (`# Returns the name`) above `def name`. Drop
- AI loves multi-paragraph class doc with `# == Examples` headings when one example would do. Trim
- Sigils and idioms (`&:method`, `tap`, `yield_self`). Don't "clarify" with comments; the idiom is the comment

### PowerShell
- Comment-based help blocks (`<# .SYNOPSIS ... .DESCRIPTION ... .PARAMETER ... .EXAMPLE ... #>`). Apply Rules 2, 2c, Z
- AI loves verbose `.SYNOPSIS` with "Comprehensively manages...". Apply Rule A
- `.DESCRIPTION` that repeats `.SYNOPSIS` then adds boast. Drop description or rewrite factual
- `.PARAMETER Name` blocks restating the parameter name. Drop tautology (`The Name parameter` → drop)
- `[CmdletBinding()]` with comment "enables common parameters". Drop, attribute says it
- Verb-noun cmdlet naming (`Get-User`, `Set-Config`) is mandatory PowerShell convention. Keep, don't apply Rule 4 renames here
- `Write-Host` calls with em-dashes in user-facing output. Keep em-dashes (CLI output exempt per Rule 2b); strip from `Write-Verbose` / `Write-Debug` / `Write-Warning` since those are dev-facing
- Pipeline `|` chain comments restating each step. Drop, pipeline is the comment
- `param()` block comments restating parameter types. Drop, `[string]` / `[int]` already declares it
- `process { }` / `begin { }` / `end { }` blocks with comments explaining what each block does. Drop, language idiom
- `#requires -Version 5.1` with explanation comment. Drop comment, directive says it
- AI loves `*-Helper`, `*-Util` cmdlet suffixes. Apply Rule S (but respect verb-noun: rename verb, drop helper suffix)
- Splatting (`@params`) with comment "this is splatting". Drop, idiom

### Elixir
- `@moduledoc` and `@doc` heredoc strings (`"""..."""`). Apply Rules 2, 2c
- AI loves `@moduledoc` opening with "This module provides a comprehensive...". Apply Rule R
- `@doc false` with a comment explaining why. Keep the attribute, drop verbose explanation
- ExUnit `test "should correctly do X"`. Apply Rule T (drop "should", drop "correctly")
- Pipe-chain comments restating each step (`# pipe through Enum.map`). Drop, the `|>` chain is the comment
- Pattern-match clause comments labelling each match arm with the value matched. Apply Rule AA2
- `with` block comments restating each binding. Drop
- GenServer callback docs (`@impl true` callbacks) restating the behaviour contract. Drop, behaviour module is the source of truth
- `Logger.info("...")` calls with em-dashes. Apply Rule 2b (logs are in scope)

### Lua
- LDoc `---` triple-dash blocks, `@param`, `@return`. Apply Rule Z
- AI loves `--[[ ... ]]` long-comment blocks for what should be a single line. Collapse
- Metatable comments explaining `__index`, `__newindex` mechanics inline. Keep only when the metatable behaviour is non-obvious; drop "this is the metatable" filler
- Module-table return idiom (`local M = {} ... return M`) with comment "Lua module pattern". Drop, idiom is standard
- AI loves `*_helper`, `*_util` naming. Apply Rule S
- Embedded-scripting contexts (Neovim, LÖVE, Roblox, OpenResty): keep host-specific terms (`vim.api`, `love.draw`), apply rules to surrounding prose only
- 1-indexed vs 0-indexed comments warning about Lua's 1-indexing. Keep when the function takes an index parameter, drop as decoration

### SQL
- View / function / stored-proc header comments. Apply Rules 2, 2c, R
- AI loves migration file headers with "This migration comprehensively updates...". Apply Rule R
- Column comments restating the column name (`-- user_id: the user ID`). Drop
- `COMMENT ON TABLE foo IS 'A comprehensive table for storing X'`. Apply Rule A (drop boast)
- CTE (`WITH ... AS`) names with comments restating the CTE name. Drop, name the CTE descriptively instead
- Stored procedure `BEGIN ... END` block comments narrating each statement. Drop, code says it
- Index creation with comment "for performance". Name the actual query pattern the index serves, or drop
- Trigger comments saying "this trigger fires on...". Drop, the `BEFORE INSERT ON` clause says it
- Apply Rule W (stale metadata) hard. Migration files often accumulate `-- Author: X / Date: Y` headers that VCS already tracks

### Config: `.env` files (`.env`, `.env.local`, `.env.example`, `.env.production`, etc.)

Dotenv-style files: `KEY=value` per line, `#` for comments. Used by Node, Python, Ruby, PHP, Go, Rust, frameworks (Next, Nuxt, Vite, Rails, Laravel, Django).

- **Never modify values.** Out of scope per Rule 1. Real secrets, even in `.env.example`, are out of scope (use a separate review for those).
- **Never modify key names.** Renaming breaks every consumer reading `process.env.X` / `os.getenv("X")` / `env('X')`. Out of scope per Rule 1.
- **Comment edits are the only legal change here.** Apply Rules 2, 2c.
- **`# Description: X is the API key for Y service`**: apply Rule R, R3. Drop "Description:" prefix. Lead with what the var is. Often one short line suffices.
- **Section-divider comments** (`# ─── Database ───`, `# === Auth ===`). Keep when they fold real sections. Strip emoji decoration per Rule 2c I.
- **Per-var multi-line preamble** restating the value type ("This is a string", "Must be a URL"). Drop, the value (or schema validator like Zod / Envalid / Pydantic Settings) is the source of truth.
- **`# TODO: change in production`**: apply Rule X. Either provide specifics or delete.
- **`# Required` / `# Optional` markers**: keep when the codebase doesn't have a schema validator. Drop when schema is enforced elsewhere (redundant).
- **`# Default: X`** annotations. Keep when the var has an in-code default fallback. Drop when there's no default (misleading).
- **Quoted vs unquoted values**: never rewrap. `KEY="value with spaces"` vs `KEY=value`. Quoting rules vary per loader (dotenv vs dotenv-expand vs direnv). Out of scope per Rule 1.
- **Variable interpolation** (`DB_URL=postgres://${DB_USER}@${DB_HOST}/${DB_NAME}`). Keep, don't add comments restating each interpolation.
- **Multiline values** (`PRIVATE_KEY="-----BEGIN..."` with literal newlines). Keep verbatim, don't reformat.
- **Em-dashes in `.env` comments**: apply Rule 2b (comments, dev-facing).
- **Marketing-prose comments** ("Powerful API key for our comprehensive service"). Apply Rule A. Strip.
- **`.env.example` / `.env.template`**: same rules, plus: keys present must match what the app actually reads. AI sometimes adds vars that aren't referenced anywhere. Flag, don't delete (might be planned).
- **`.env.vault`, `.env.encrypted`, or any non-plaintext variant**: never edit. Skip the file.

`.env`-flavored AI tells in comments:

| Pattern | Fix |
|---|---|
| "API key for X service" then 3 lines about X | one line: "X API key" or drop |
| "Note: Change this in production!" | apply Rule G |
| "This variable controls..." | drop, name what it controls |
| "Secret key - DO NOT COMMIT" (em-dashed in AI output) | drop em-dash; if file is `.env.example` the warning is moot; if `.env`, file shouldn't be in VCS at all |
| "Production-grade configuration" | drop |
| "Comprehensive environment setup" | drop |

### Config: `knexfile.js` / `knexfile.ts` (Knex.js)

Knex config files export an object keyed by environment (`development`, `staging`, `production`, `test`) with `client`, `connection`, `migrations`, `seeds`, `pool` settings.

Apply on top of the JavaScript / TypeScript section.

- **Top-of-file docstring**: AI loves `/** Comprehensive Knex configuration for multi-environment database support */`. Apply Rule R + A.
- **Per-environment block comments** restating the environment name (`// development config`) → drop, the object key says it.
- **`client: 'pg' | 'mysql2' | 'sqlite3'`** with comment "use Postgres driver" → drop, value names the driver.
- **`connection`** objects. Drop comments restating each field (`host`, `user`, `database`, `password`). Keep `process.env.X` references; never modify env var names.
- **Connection-string form** (`connection: process.env.DATABASE_URL`) with comment "from .env" → drop, `process.env` says it.
- **`migrations: { directory, tableName, extension, stub }`**: drop comments restating each option. Keep notes only when the value diverges from Knex defaults (custom `tableName`, non-default `stub`).
- **`seeds: { directory, extension }`**: same.
- **`pool: { min, max, acquireTimeoutMillis, idleTimeoutMillis }`**: drop "connection pool config" filler. Keep one-line *why* for non-default `min`/`max` (concurrency target, RDS connection budget, PgBouncer mode).
- **`searchPath`** for Postgres. Keep array, drop "schema search order" filler unless ordering rationale is non-obvious.
- **`useNullAsDefault: true`** (SQLite quirk). Keep, drop "required for SQLite" filler unless the codebase mixes SQLite + other drivers.
- **`asyncStackTraces: true`**: keep, drop "for debugging" filler.
- **Environment-resolution comments** (`// pick env from NODE_ENV`) above `module.exports[process.env.NODE_ENV]` patterns → drop, the export expression says it.
- **TypeScript `Knex.Config` import** with comment "import the config type" → drop.
- **`debug: true`** in dev. Keep, drop "logs SQL queries" filler.
- **Migration stubs / seed stubs** referenced from `knexfile`. Never modify the stub file contents from this rule pass; that's a separate cleanup.
- **CLI invocations in comments** (`// Run with: npx knex migrate:latest`). Keep, useful onboarding signal. Apply Rule 2c only to surrounding prose.

Knex-flavored AI tells:

| Pattern | Fix |
|---|---|
| "Robust database configuration" | drop |
| "Production-ready connection pool" | drop |
| "Comprehensive migration setup" | drop |
| "Following Knex best practices" | drop |
| "Multi-environment Knex config" | drop, the object shape says it |
| "Seamless database access" | drop |

### Markdown / docs (`.md` files)
- Apply Rules DD, EE, FF
- Drop auto-generated TOCs in short docs
- Strip emoji from section headers unless they're load-bearing

### Shell scripts
- `# This script does X` over a 5-line script → drop
- AI loves `set -euo pipefail` + 3 lines of comments explaining it. Keep the line, drop the explanation
- `# Function: foo` / `# Args: ...` blocks. Keep args, drop "Function" label

## Rule 11: File scope / exclusions for full-codebase runs

### Include globs (start here)

```
**/*.{js,jsx,ts,tsx,vue,astro,mdx,ejs,py,go,rs,java,kt,rb,php,phtml,twig,pl,pm,c,cpp,h,hpp,cs,swift,scala,sh,bash,zsh,ex,exs,lua,sql,ps1,psm1,psd1,blade.php}
**/.env*  (comments only. Never modify keys or values)
**/knexfile.{js,ts,cjs,mjs}
**/*.md  (only when explicitly requested. Apply Rules DD, EE, FF)
```

### Exclude globs (never touch)

```
node_modules/      vendor/            third_party/
dist/              build/             out/
.next/             .nuxt/             .svelte-kit/
target/            bin/               obj/
__pycache__/       .venv/             venv/             env/
*.min.js           *.map              *.lock
*-lock.json        *-lock.yaml        yarn.lock
*.pb.go            *.gen.ts           *.generated.*
*.swagger.json     *.openapi.json     graphql.schema.json
```

### Skip categories (leave alone)

- **Test fixtures / golden files:** `**/fixtures/**`, `**/testdata/**`, `**/__snapshots__/**`, `**/*.snap`
- **i18n / translations:** `*.po`, `messages/**.json`, `locales/**`
- **Migration scripts:** keep timestamps + author notes intact (`db/migrations/**`, `prisma/migrations/**`)
- **Vendored / third-party code:** anything under `vendor/`, `third_party/`, `external/`
- **License files:** `LICENSE`, `COPYING`, license headers in source files
- **CHANGELOG.md, NOTICE, AUTHORS**
- **Generated TypeScript declaration files:** `*.d.ts` from codegen (keep hand-written ones)

### Detect auto-generated files

If the first 5 lines contain any of these, skip the file:

```
DO NOT EDIT
AUTO-GENERATED
GENERATED BY
@generated
Code generated by
This file was automatically generated
```

## Rule 12: Operational mode for big repos

- **Dry-run first.** Run all Rule 8 greps with no edits. Report per-category hit counts. Review before any change.
- **Order: smallest file first.** Build confidence on simple files before tackling 2000-line ones.
- **Per-file commit.** One commit per file, subject names the category:
  - `chore(comments): vocab swap in src/foo.ts`
  - `chore(renames): rename AI-jargon fns in lib/bar.js`
  - `chore(docs): kill em-dashes in README.md`
- **Stats at the end.** Count edits per category. Surface anything > 100 hits. That's where the AI signal is densest.
- **Stop after N files first pass.** Default N=5. Review diff, run tests, then continue.
- **Use ripgrep.** `rg` over `grep` for 10× speed on large trees. All Rule 8 greps work with `rg` (drop `-nE`, use default flags).

Example dry-run script:

```bash
#!/bin/bash
F="$1"
echo "=== $F ===" | tee -a fix-report.txt
for pat in "we|us|our" "recipe|family|nudge" "logic|atomic|leverage" "robust|elegant|seamless"; do
  count=$(rg -c "\b($pat)\b" "$F" || echo 0)
  [ "$count" != "0" ] && echo "  $pat: $count" | tee -a fix-report.txt
done
```

## Rule 13: False-positive triage

Not every match is a bug. Skip when:

### Domain whitelist (per project)

Maintain a list of words this codebase legitimately uses. Examples:

| Word | Legit context |
|---|---|
| `atomic` | transaction library, fs operations, atomic counters |
| `value` | generic parser parameter (e.g. `parseBool(value, def)`) |
| `family` | CSS `font-family`, Linux kernel `cpu-family`, address family (`AF_INET`) |
| `journey` | user-journey analytics code |
| `Service` / `Provider` / `Handler` | Angular, NestJS, React Context API, AWS Lambda. Framework-mandated |
| `Manager` | Python contextmanager, iOS `URLSessionManager` |
| `walk` | `os.walk()` Python stdlib, AST walkers, tree-walk interpreters |
| `pictures` | image-domain product (`PicturesLibrary` Windows API) |
| `recipe` | build systems (Make/CMake recipes), package recipes |

### Always-skip rules

- Match is inside a string literal → out of scope per Rule 1
- Match is in a third-party type definition (`node_modules`, `@types/...`)
- Match is in a comment that's part of a copy-pasted RFC or spec quote → keep
- Match is in a code example inside docs (` ```js ` block) → leave alone
- Match is the literal class/method name from an SDK you call → keep

### Borderline calls

When unsure, **leave it** and flag for human review. Better to under-edit than to break domain accuracy.

## Rule 14: Reviewer checklist (human gate, not agent task)

Agent work ends at Rule 8 verification and report emission. Below is the human reviewer's pre-merge checklist; the agent must not attempt these steps:

- [ ] `git diff --shortstat` shows only comment-line changes; code-logic line count ≈ 0
- [ ] `git diff --stat | grep -v '\.md\b'`. For each source file changed, skim 3 random hunks. Confirm: comment edit, no code touched, semantic intent preserved.
- [ ] Test suite passes unchanged (no test files renamed unless explicitly intended)
- [ ] All Rule 8 verification greps return empty (or only string-literal hits)
- [ ] For renamed functions: `rg -c '<oldName>'` returns 0 across repo
- [ ] No new TODOs, no new placeholder comments introduced
- [ ] No string literals modified. Re-grep for any quoted strings that changed
- [ ] Spot-check 5 JSDoc/docstring blocks: types unchanged, descriptions just cleaner
- [ ] Build / lint passes
- [ ] CHANGELOG, README, LICENSE untouched (unless docs cleanup was explicitly requested)

## Rule 15: Precedence / house style

When rules conflict, apply this order:

1. **Explicit user instruction in the current session** wins everything.
2. **Repo-specific style guides:** `CLAUDE.md`, `AGENTS.md`, `GEMINI.md`, `STYLE.md`, `CONTRIBUTING.md`, `docs/style.md`
3. **Linter config:** `.eslintrc`, `ruff.toml`, `golangci.yml`, `clippy.toml`, `.editorconfig`
4. **Existing project conventions:** if the codebase uses `*Service` everywhere, leave it. Don't fight the convention
5. **PROMPT.md (this doc)**: lowest priority, but the default when nothing else applies

When in doubt, **ask before bulk-applying**. A 500-file rename gone wrong is harder to revert than a 30-second clarification.

## Rule 16: Tooling notes

### Faster greps
- `ripgrep` (`rg`): 10× faster than grep, respects `.gitignore` by default, multi-line support
- `ag` (the silver searcher). Similar speed, fewer features
- For Rule 8 greps: replace `grep -nE` with `rg -nE`

### Safer batch edits
- `sed -i.bak 's/old/new/g' file`: UNIX batch replace with backup
- `comby`. Structural patches: matches AST-shaped patterns, not raw text. Great for "rename function param across all files".
- `ast-grep`. Language-aware codemod. Use for identifier renames where text replace would hit string literals or comments incorrectly.
- `jscodeshift` (JS/TS). Programmatic AST transforms via Babel
- `LibCST` (Python). Concrete-syntax-tree codemods preserving formatting

### Safety nets
- `git stash` before any bulk run; revert with `git stash pop` or `git checkout .`
- Work on a dedicated branch: `git checkout -b chore/fix-md-cleanup`
- Commit per category (Rule 12)
- Run on a copy first if the repo is critical: `cp -r repo repo-fix-test`

### CI / pre-commit integration

Add a pre-commit hook that runs Rule 8 greps on staged files only:

```yaml
# .pre-commit-config.yaml example
- repo: local
  hooks:
    - id: fix-md-greps
      name: AI-slop check
      entry: ./scripts/fix-md-check.sh
      language: script
      pass_filenames: true
```

The hook should fail commits that introduce new AI tells (delta-based, not absolute. Existing tech debt allowed).

---

## How to invoke

Paste this in a fresh session with the target file open or referenced:

> Apply `PROMPT.md` rules to `<path/to/file>`. Do not modify code logic. Show me the rename table at the end.
