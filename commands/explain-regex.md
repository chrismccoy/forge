---
description: Explain one regular expression via guided intake - verified 11-section plain-English teardown with examples, pitfalls, ReDoS verdict, and alternatives, in chat or REGEX-EXPLAINED.md.
argument-hint: "[regex] [optional flavor, use case, chat|file]"
allowed-tools: AskUserQuestion, Read, Write, Bash(python3 ${CLAUDE_PLUGIN_ROOT}/lib/regex-tutor/scripts/regex_check.py:*)
disable-model-invocation: true
---

> **Load first.** Read `${CLAUDE_PLUGIN_ROOT}/lib/regex-tutor/SKILL.md` in full before
> anything else - intake, tool calls, or output. That file is the authoritative
> procedure for this command; every mention of "the `regex-tutor` procedure" below
> refers to it. It is not auto-loaded, so this read is mandatory.

# /explain-regex - Regex Tutor

Run the `regex-tutor` procedure. Collect the regex and up to three optional fields, then produce one verified 11-section teardown: plain-English summary, token-by-token breakdown, structure, valid and invalid examples, matching walkthrough, pitfalls, performance and ReDoS verdict, alternatives, real-world context, and a plain-English rewrite.

Every example, alternative, and ReDoS claim is checked against real engines with `${CLAUDE_PLUGIN_ROOT}/lib/regex-tutor/scripts/regex_check.py`, run by absolute path. Never `cd` into the bundle - `REGEX-EXPLAINED.md` belongs in the user's working directory.

User input: $ARGUMENTS

## Intake Procedure

Parse `$ARGUMENTS` first. Treat the first pattern-like token (a bare pattern, a `/pattern/flags` literal, or a quoted host-language string) as the **regex**. Treat any remaining words as optional context: a flavor name (`JavaScript`, `Python`, `PCRE`, `PHP`, `Perl`, `.NET`, `Java`, `Ruby`, `Go`, `POSIX ERE`), a use case in plain words, or an output destination (`chat` or `file`).

1. **Regex** (required) - not a menu. If `$ARGUMENTS` holds no regex, or only a placeholder such as `PASTE REGEX HERE`, ask for it and STOP for the reply. Never guess or invent one.
2. **Output** - if the user has not said chat or file, use `AskUserQuestion` with two options: `Chat - print the teardown here` and `File - save to REGEX-EXPLAINED.md`. Ask it before any analysis and wait for the answer. If the regex is also missing, ask for both in the same turn.
3. **Flavor** - optional. Never block on it. When blank, assume the common subset of PCRE / JavaScript / Python and say so in one line, unless the syntax clearly points to one flavor, in which case name the clue.
4. **Use case** - optional. Never block on it. When blank, state a best-guess use case as an explicit assumption; add one clarifying question at the very end only if a different use case would meaningfully change the analysis.

## Validation Before Generation

Normalize the input and state the exact pattern under analysis: strip delimiters and flags and note what each flag changes, undo host-language string escaping and say which reading was chosen if ambiguous, and analyze each regex separately when more than one is given.

Run the checker's `compile` subcommand with `--engines` set to the flavor, per the mapping table in the procedure. If the pattern does not compile in the stated or assumed flavor, say so first, point to the exact broken token, give the most likely intended fix, then analyze the fixed version.

## Generation

After intake and validation:

1. Read `${CLAUDE_PLUGIN_ROOT}/lib/regex-tutor/references/sections.md` for the full spec of all 11 sections and the file header.
2. Verify every example for sections 4 and 5 with the checker's `test` subcommand against the entire pattern, including anchors and flags. Read every per-engine result, not only the exit code.
3. For a Caution or Vulnerable ReDoS verdict, run attack strings only through the checker with its timeout, against the original pattern, and confirm growth with a shorter and a longer input.
4. Compile every alternative in section 9 in each flavor claimed for it.
5. Deliver: for **chat**, print all 11 sections with the exact numbered headers. For **file**, write `REGEX-EXPLAINED.md` in the current working directory (overwriting any existing file) with the required header, then reply with only the path, the one-sentence summary, the ReDoS verdict line, and the clarifying question if there is one. If files cannot be written, print in chat and say so in one line.

## Hard Rules

- NEVER guess or invent a regex when none was given.
- NEVER start the analysis before the chat-or-file question is answered.
- NEVER list an example as matching or not matching without running it through the checker; mark it "(unverified)" when the flavor's engine is unavailable.
- NEVER run an attack string without a timeout.
- NEVER call a pattern invalid because `go` rejected lookaround or backreferences in a non-Go flavor.
- NEVER `cd` into the bundle directory; run the checker by absolute path.
- NEVER trade accuracy for simplicity, and never just restate symbols - explain intent and behavior.
- ALWAYS label assumptions as assumptions, name the flavor wherever engines differ, and define each unavoidable technical term on first use.
- ALWAYS deliver all 11 sections in order, scaled to the pattern, using "Not applicable - <one-line reason>" instead of padding.

$ARGUMENTS
