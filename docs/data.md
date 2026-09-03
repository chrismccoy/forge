# Data

[← Back to the README](../README.md)

## `excel-formula-troubleshooter`

Debug, fix, and optimize broken Excel and Google Sheets formulas.

```
/fix-formula
```

A broken formula is rarely broken where it looks broken. `=VLOOKUP(A2,Sheet2!A:B,3,0)` throws `#REF!` not because the syntax is wrong but because the column index counts inside the range, and `A:B` only has two columns. The `excel-formula-troubleshooter` skill traces the formula like a spreadsheet engine does. function by function, parentheses balance, argument count and order, range references, data types (text vs number, dates as serials), circular references. then names the exact root cause, returns a copy-paste-ready corrected formula, explains the fix in plain bullets, and where it helps, suggests a modern alternative (`XLOOKUP` over `VLOOKUP`, `IFERROR` to mask error values).

Output is locked to four sections so every answer reads the same: ❌ The Issue, ✅ Corrected Formula, 🛠️ How the Fix Works, 🚀 Better Alternative (omitted when none applies). Function names come back UPPERCASE, ready to paste. Scope is locked to spreadsheet-formula troubleshooting. it does not answer general spreadsheet or data questions outside a broken formula.

## ✨ Features

- 🔎 Silent pre-answer trace. function-by-function, parentheses balance, argument count/order, range references, data types, circular references. the reasoning never clutters the output
- 🎯 Exact root cause. mismatched parentheses, wrong syntax, text-vs-number mismatch, circular reference, incorrect range, wrong column index. not "consider checking your ranges"
- 📋 Copy-paste-ready corrected formula with UPPERCASE function names
- 🧾 Beginner-friendly bulleted explanation of why the fix works
- 🚀 Optional modern alternative. `XLOOKUP` over `VLOOKUP`, `INDEX/MATCH`, `IFERROR` to mask `#N/A`. omitted cleanly when nothing better applies
- 📦 Locked 4-section output format. identical layout on every answer
- 🚪 Asks for the issue instead of guessing when only a formula is supplied
- 🔒 Scope lock. spreadsheet-formula troubleshooting only

## 🔄 How it works

1. **Intake**: the `/fix-formula` slash command parses the broken formula and the issue. pipe-separated (`formula | issue`), tag-wrapped (`<broken_formula>` / `<issue>`), or interactive prompt when either is missing
2. **Silent trace**: walks the formula function-by-function, checking parentheses, arguments, ranges, data types, and circular references. reasoning is not shown
3. **Diagnose**: names the single exact root cause
4. **Emit**: the locked four-section answer. The Issue, Corrected Formula, How the Fix Works, optional Better Alternative

## 🚀 How to use it

**Slash command** (explicit):

```
/fix-formula =VLOOKUP(A2,Sheet2!A:B,3,0) | returns #REF!   ← formula | issue
/fix-formula =VLOOKUP(A2,Sheet2!A:B,3,0)                   ← asks for the issue
/fix-formula                                               ← full intake (formula + issue)
```

**Requests it handles** (type the command to run it - it never auto-triggers):

> *"fix my Excel formula"*, *"why does my formula return #REF!"*, *"debug this spreadsheet formula"*, *"troubleshoot a Google Sheets formula"*, *"my VLOOKUP isn't working"*, *"correct this formula"*

The full procedure lives at [`lib/excel-formula-troubleshooter/SKILL.md`](../lib/excel-formula-troubleshooter/SKILL.md), and the slash command at [`commands/fix-formula.md`](../commands/fix-formula.md).

---

## `sql-breakdown`

Review one SQL query without running it: a validation check, a clause-by-clause explanation, the business question it answers, a quality scorecard, efficiency and risk notes, and a plain-English summary for someone who has never seen SQL.

```
/explain-sql
```

A query can be syntactically perfect and still return the wrong numbers. `COUNT(*)` after a join counts joined rows, not distinct orders. A filter with no upper bound quietly reports "this month" as "everything since the first of the month". The `sql-breakdown` skill validates first - syntax, then logic in execution order, then completeness against what the business context actually asked for - and tags the result `✅ VALID`, `⚠️ HAS WARNINGS`, or `❌ LIKELY BROKEN` before it explains a single clause.

Everything after that is pitched at whoever the report is for. Tell it the reader is a data engineer and it writes peer-level with correct terminology; tell it the reader is a CFO and it drops the jargon and glosses every SQL term the first time it appears. Section 6 goes further and re-explains the whole query with no SQL terms in it at all.

Nothing is executed. A `✅ VALID` verdict means no error was found by reading, not that the query ran, and the efficiency section states an expected effect and the reason for it rather than a speed figure it cannot measure. Paste a `DELETE`, `UPDATE`, or `DROP` and the full report still ships, but every fix is described in words and no runnable version is printed anywhere.

## 📋 Technical Overview

One slash command plus its procedure file `lib/sql-breakdown/SKILL.md`, which loads the master template from `lib/sql-breakdown/references/prompt-template.md`. The command `/explain-sql` collects four fields - the query, the recipient role, the business context, and the dialect - of which only the query is required; the other three have defined defaults that are stated in the report when used. All four are substituted into a paired-marker block and treated as data, including text inside SQL comments and string literals.

## ✨ Features

- 🚦 Validation before explanation. Syntax, logic in execution order, and completeness against the business context, each with its own verdict
- 🎯 One register, chosen for the reader. Peer-level where the role writes SQL daily, plain business language where it does not, and it says which it took when either could apply
- 🧩 Clause by clause, with the rules that matter. Subqueries explained inner and outer, window frames contrasted with regular aggregation, `HAVING` distinguished from `WHERE`
- 📊 Anchored scorecard. Readability, Efficiency, Accuracy Confidence, and Business Clarity out of 10 each, totalled out of 40, with the verdict capping Accuracy Confidence so scores cannot contradict the validation
- ⚠️ At least two data risk flags, each as what could go wrong, when it would bite, and how to prevent it - never invented to fill a quota
- 🔒 Non-read statements handled, never handed back runnable. `DELETE`, `UPDATE`, `DROP` and friends get all seven sections with every fix in words only
- 🧠 Assumptions named, not hidden. With no schema supplied it names the grain or key-uniqueness assumption a finding rests on rather than asserting a join is wrong
- 📖 Section 6 in plain English with no SQL terms at all, closing with a comprehension confidence score
- 🛡️ Inputs are inert. Directives inside comments or string literals are ignored, and the input block closes only at the final marker

## 🔄 How it works

1. **Intake.** Collect the query, then the role, context, and dialect. Apply the stated default for anything skipped and say so.
2. **Classify.** Decide whether this is a read query or a non-read statement, and switch the per-section substitutions accordingly.
3. **Draft internally.** Settle the verdict, complexity rating, four scores, and risk flags as one set, holding competing readings side by side and committing to the one the inputs support.
4. **Check.** Confirm the verdict, rating, scores, and flags agree with each other and with the query as submitted, and that every finding points at real text.
5. **Print.** The seven sections, and nothing before the title that the rules did not require.

## 🚀 How to use it

```
/explain-sql SELECT ... FROM orders JOIN customers ...   ← query passed inline
/explain-sql ./reports/monthly_revenue.sql               ← query from a file
/explain-sql                                             ← full intake, four fields
```

**Requests it handles** (type the command to run it - it never auto-triggers):

> *"explain this SQL query"*, *"what does this query actually do"*, *"review this query before I ship it"*, *"is this join going to double-count"*, *"explain this query for a non-technical stakeholder"*, *"score this query"*

The full procedure lives at [`lib/sql-breakdown/SKILL.md`](../lib/sql-breakdown/SKILL.md), and the slash command at [`commands/explain-sql.md`](../commands/explain-sql.md).
