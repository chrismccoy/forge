# Report format

Use exactly these sections, in this order.

## Intake
Each intake field with its value and its source: given, inferred (say from what), found in callers (name the
file), or default.

## One section per script, titled with its file name, in priority order
1. **Diff:** the refactor as a unified diff against the original file.
2. **Contract check:** one line each for CLI, stdout, exit codes, stderr, and side effects. Write "unchanged", or
   name the exact change and why it is safe.
3. **Comparison:** the `compare-runs.sh` cases that were run and their results, or the reason a case could not
   be run safely.
4. **Changes:** bullets, each giving what changed and the concrete risk it removes. No praise.
5. **Skipped:** improvements not applied, and the rule that blocked each one. "None" if empty.

## Behavior changes needing approval
Every fix not applied because it changes observable behavior, most severe first, with safety bugs at the top.
Number them. For each:
- the bug, with a concrete input and the traced (preferably run) result;
- the exact change, as a unified diff against the refactored script;
- what the caller will see differently, including any docs or callers that describe the old behavior.

Write "None" if empty. End with one line asking which numbers to apply.

## Cross-script findings (batches only)
Inconsistencies found, the proposed shared convention, and which ones were fixed and which only reported.
