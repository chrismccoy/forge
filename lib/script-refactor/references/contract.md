# The contract

Read this before changing any script. The observable behavior below is the contract. A refactor must leave it
exactly as it was.

## What counts as observable behavior

1. **CLI:** the same positional arguments, flags, option meanings, defaults, and environment variables read.
2. **stdout:** the same lines, in the same order, with the same field separators, whitespace, quoting, and trailing
   newline. No new banners, progress lines, colors, or blank lines.
3. **Exit codes:** the same code for the same outcome. On failure paths, at minimum keep zero vs nonzero, and keep
   the exact code wherever a caller checks it.
4. **stderr:** if the caller relies on stderr text, keep every message word for word. Otherwise messages may be
   tightened, but each stays one line, and multi-line usage text appears only where the script already printed it.
   Never add stderr output to the success path.
5. **Side effects:** the same files created, changed, or deleted, at the same paths, with the same permissions, and
   the same network calls.
6. **Dependencies:** no new packages or binaries beyond the Python standard library and the tools the script
   already calls. Name any exception in the report.
7. **Runtime:** no syntax or library feature newer than the minimum runtime. Examples: `list[str]` needs Python
   3.9, `X | None` needs 3.10, `${var,,}` needs bash 4, and `[[ ]]` and `local` are not POSIX sh.

On the success path the output must be byte for byte identical.

## The approval rule

The refactored script keeps the original behavior, even where that behavior is a bug. This includes code that
contradicts its own header comment, and safety bugs. Never apply a fix that changes stdout, stderr, exit codes,
or side effects. List it under "Behavior changes needing approval" instead, and apply it only after the user
names its number.

## Precedence

When rules conflict, the higher item wins. Skip the losing improvement and list it under "Skipped" with the rule
that blocked it.

1. Known quirks from intake (for example "must always exit 0")
2. The contract above
3. Language and runtime version limits
4. Improvements (see `improvements.md`)

## Intake fields and defaults

| Field | How to fill it when the user did not say |
|---|---|
| Scripts | The files the user named or pointed at. Ask if none. |
| Language | The shebang, then the file extension. Ask only if both are missing or they disagree. |
| Minimum runtime | The oldest version the existing code already runs on. Never raise it. |
| Treat as a batch | Yes when there is more than one script. |
| Priority order | The order the user listed them in. |
| Caller relies on | Search the repo for callers first (see SKILL.md). If nothing is found, assume all of stdout, stderr text, exit codes, and files written. |
| Known quirks | None. |

Ask about missing scripts or an unresolvable language in one message, one short line per question. Never ask
about the defaulted fields; state the value used in the report.
