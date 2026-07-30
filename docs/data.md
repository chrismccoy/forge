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

**Natural language** (auto-triggers via the skill):

> *"fix my Excel formula"*, *"why does my formula return #REF!"*, *"debug this spreadsheet formula"*, *"troubleshoot a Google Sheets formula"*, *"my VLOOKUP isn't working"*, *"correct this formula"*

The full procedure lives at [`lib/excel-formula-troubleshooter/SKILL.md`](../lib/excel-formula-troubleshooter/SKILL.md), and the slash command at [`commands/fix-formula.md`](../commands/fix-formula.md).
