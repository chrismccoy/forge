# Reference - formulas, bands and named rules

Lookup tables, not reading order. Stages consult these; nothing here changes the stage
order in `SKILL.md`. **Where any other section disagrees with a named rule, the named
rule wins.**

| Rule | Defined in |
|---|---|
| `RULE precedence` | `SKILL.md`, Edge Cases preamble |
| `RULE precision` | Rendering rules, below |
| `RULE residual` | Rendering rules, below |
| `RULE conditionals` | Rendering rules, below |
| `RULE verify-retry` | Procedural rules, below |
| `RULE repair` | Procedural rules, below |

## Formulas, letter values and bands

```
TOTAL              = input + output + cache_create + cache_read
share(x)           = x / TOTAL × 100
input_efficiency   = input / (input + cache_read) × 100     [lower better]
cache_ratio        = cache_read / cache_create              [higher better]
cache_share        = (cache_read + cache_create) / TOTAL × 100
output_discipline  = output / TOTAL × 100                   [lower better]
io_ratio           = input / output                         [healthy 10–100]
weighted           = 0.50×cache_grade + 0.30×input_grade
                     + 0.20×output_grade
```

**Letter values:** A=4, B=3, C=2, D=1, F=0. `cache_grade`,
`input_grade` and `output_grade` are these numeric values of the three
area letters — **not** `cache_ratio`, `cache_share` or any other raw
metric. Grade first, then weight the grades. A component whose metric
is undefined still enters `weighted` at the numeric value of the
letter forced by its Edge Cases row. No component is ever dropped and
the weights are never renormalized.

**Bands** — bounds are inclusive at the stated precision, so every
value lands in exactly one band.

| Grade | Input efficiency % | Cache ratio | Output discipline % | Weighted |
|---|---|---|---|---|
| A | 0.0–10.0 | ≥10.00 | 0.0–2.0 | ≥3.50 |
| B | 10.1–20.0 | 5.00–9.99 | 2.1–5.0 | 2.50–3.49 |
| C | 20.1–35.0 | 2.00–4.99 | 5.1–10.0 | 1.50–2.49 |
| D | 35.1–55.0 | 1.00–1.99 | 10.1–20.0 | 0.50–1.49 |
| F | 55.1–100.0 | <1.00 or none | 20.1–100.0 | <0.50 |

**Interpretation.** `io_ratio` below 10 suggests bloated generation;
above 100 means paying to resend context for little returned work. A
high `cache_share` is good provided input and output are lean —
context reused, not resent.

## Rendering rules

Single source of truth for every rule that touches both calculation and
output.

**`RULE precision`.** Compute at full precision, round **once**, **half away
from zero** (9.995 → 10.00, never 9.99). Never banker's rounding: band
edges sit adjacent to whole numbers and half-even would silently shift
a B into an A.

| Value | Rounded to |
|---|---|
| Every percentage — the four shares, `input_efficiency`, `output_discipline`, `cache_share` | 1 decimal |
| `io_ratio`, `cache_ratio`, `weighted` | 2 decimals |

A value is banded and printed at the **same** rounded figure. Nothing
is compared at one precision and displayed at another, and a value that
is only displayed still rounds by this table.

**`RULE residual`.** Independently rounding four shares to 1 decimal
does **not** reliably sum to 100.0 — `144182 / 124973 / 104206 / 167627`
rounds to 26.7 / 23.1 / 19.3 / 31.0, which sums to 100.1. So: round each
share independently, then add the residual (100.0 minus that sum, so
here −0.1) to the largest share among rows 1, 3 and 4 — the cache read
row, printed 30.9 rather than 31.0, and the column sums to 100.0. This
adjustment is the one case where a printed figure differs from its
independently rounded value, and it overrides independent rounding for
that one cell.

Never apply the residual to row 2 (`OUTPUT_TOKENS`). Its share *is*
`output_discipline`, a banded metric, and shifting it would print a
value that disagrees with the band it was graded in.

Row 5 is derived, overlaps rows 1 and 4, and carries its share for
reference only — never part of that sum, never a residual target. Row 6
always prints 100.0.

**`RULE conditionals`.** Lines marked `{…}` in the skeleton are emitted
only when their condition holds and omitted whole otherwise — no
placeholder, no blank line left behind. "Nothing else" forbids added
commentary; it does not forbid these.

A marker's position in the skeleton **is** its insertion point, and is
normative: `{TOTAL_GAP}` goes directly beneath the TOTAL row, before
the blank line preceding RATIOS; `{FALLBACK_NOTE}` goes last, after the
RECOMMENDATION text. Never relocate one, never merge one into adjacent
prose, never emit one outside the skeleton.

| Marker | Emitted when |
|---|---|
| `{TOTAL_GAP}` | a supplied `TOTAL_TOKENS` disagreed with the computed sum |
| `{FALLBACK_NOTE}` | Edge Cases row 9 fired |

## Procedural rules

**`RULE verify-retry`.** If VERIFY finds the arithmetic or a letter
disagreeing with its band row, re-run stages 3 and 4 **once**. If the
second pass still disagrees with the first, do not guess and do not
silently correct: HALT with `verification failed — <metric>`. This is
the only HALT originating outside the Edge Cases table.

**`RULE repair`.** If rendered output deviates from the Output Contract
template, repair it **once** and emit. Never re-validate or recalculate
during repair — repair is a formatting pass, not a second chance at the
numbers.

## Worked Examples

**Ordinary run.** `40000 / 4000 / 20000 / 180000` → TOTAL 244000.
Shares 16.4 / 1.6 / 8.2 / 73.8. io_ratio 40000÷4000 = 10.00.
cache_ratio 180000÷20000 = 9.00 → B. input_efficiency
40000÷220000 = 18.2 → B. output_discipline 1.6 → A.
weighted 0.50×3 + 0.30×3 + 0.20×4 = 3.20 → **B**.

**Edge run.** `12000 / 0 / 0 / 0` → TOTAL 12000. Row 7 fires: io_ratio
undefined, output discipline F. Row 8 also applies: cache strategy F.
input_efficiency 12000÷12000 = 100.0 → F. weighted
0.50×0 + 0.30×0 + 0.20×0 = 0.00 → **F**. STATUS is OK, not HALT — the
values are valid, the workflow is not.

**Rounding boundary.** `1005 / 100 / 500 / 8995` → input_efficiency
1005÷10000 = 10.05 → rounds to **10.1** → B, not A. Rounding decides
the band; it is applied once, at comparison.

**HALT precedence.** A block with an unknown key `CACHE_TOKENS=5` and
a conflicting `INPUT_TOKENS` matches row 3 before row 4. Emit the row 3
HALT naming `CACHE_TOKENS` only — one HALT per run.

**Volunteered total.** `40000 / 4000 / 20000 / 180000` with
`TOTAL_TOKENS=250000` is not a duplicate-key HALT. Note the 6000-token
gap in one line, then run on the computed 244000.

