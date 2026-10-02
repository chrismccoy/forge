# JQ facts
Covers: jq 1.7 and 1.8 (1.8.2 current), .jq filter modules, --run-tests fixtures, bash wrappers and bats suites calling jq
Verified: 2026-09-29 against official documentation. Re-verify facts older than 12 months.

## Versions

### JQ-01 "jq 1.7" is not one behavior
- Trap: Filters written against the latest manual run unchanged on whatever jq the host or CI image has (1.6, 1.7.x or 1.8.x).
- Reality: 1.7 added `pick`, `abs`, `debug(msg)`, `scan($re; $flags)` and `--raw-output0`, removed `--argfile`, `leaf_paths` and `recurse_down`, and made `limit(0; f)` output nothing (1.6 emitted one item). 1.8.0 added `trim`/`ltrim`/`rtrim`, `trimstr`, `have_decnum`, and broke compatibility: `limit` errors on a negative count, `ltrimstr`/`rtrimstr` error on non-strings, `tonumber` rejects surrounding whitespace, `indices`/`index` count code points, `last(empty)` yields nothing, and `--indent 0` no longer implies `-c`.
- Detect: "jq 1.7" with `trim`, `ltrimstr` on possibly-null fields, `--argfile`, no pinned jq version in CI or packaging.
- Fix: Pin the jq version in the wrapper (`jq --version` check) and CI image, and run the fixture suite on that exact version.
- Source: jq NEWS - https://github.com/jqlang/jq/blob/master/NEWS.md ; jq 1.7 manual - https://jqlang.org/manual/v1.7/

## Data semantics

### JQ-02 Numbers are doubles once you touch them
- Trap: Large IDs, account numbers or nanosecond timestamps survive any filter exactly.
- Reality: Since 1.7, jq keeps the original literal of numbers that pass through unchanged and compares with the full precision. Any arithmetic converts to an IEEE754 double, so values beyond 2^53 lose digits. Builds with `--disable-decnum` do not preserve literals (1.8 adds `have_decnum` to check).
- Detect: `+`, `-`, `tonumber`, `add` or `sort_by` math on IDs, snowflake IDs, byte counters.
- Fix: Keep big identifiers as strings or pass them through untouched, and add a fixture with a value above 2^53.
- Source: jq manual, Identity - https://jqlang.org/manual/#identity

### JQ-03 `//` treats `false` like a missing value
- Trap: `.enabled // true` defaults only when the field is absent.
- Reality: `//` yields the left-hand values that are neither `false` nor `null`, otherwise the right-hand side. An explicit `false` becomes `true`.
- Detect: `//` defaults on boolean flags (`.enabled`, `.dry_run`, `.public`).
- Fix: Use `if has("enabled") then .enabled else true end` or `.enabled | if . == null then true else . end`.
- Source: jq manual, Alternative operator - https://jqlang.org/manual/#alternative-operator

### JQ-04 Big inputs need `--stream`, not `--slurp`
- Trap: `jq -s` over a multi-GB CloudTrail or inventory dump, or one huge array, "streams" through.
- Reality: `--slurp` reads the entire input into one array before running the filter. `--stream` emits `[path, leaf]` events (and `[path]` closers) so large inputs can be reduced incrementally with `reduce`/`foreach`, `fromstream` and `truncate_stream`.
- Detect: `-s`/`--slurp` or a top-level array on large or unbounded inputs; memory limits in the design.
- Fix: Use newline-delimited input with `-n` and `inputs`, or `--stream` with `fromstream(1 | truncate_stream(inputs))` for a huge top-level array.
- Source: jq manual, Invoking jq and Streaming - https://jqlang.org/manual/#streaming

## Invocation

### JQ-05 `input`/`inputs` need `-n`
- Trap: `jq 'reduce inputs as $x (0; . + $x.size)' *.json` sums every file.
- Reality: Without `-n`, the first input is bound to `.` and `inputs` returns only the rest, so the first document is lost. With `-n` the filter runs once with `null` input.
- Detect: `input` or `inputs` in a filter invoked without `-n`/`--null-input`.
- Fix: `jq -n 'reduce inputs as $x (0; ...)'`.
- Source: jq manual, input and inputs - https://jqlang.org/manual/#input

### JQ-06 `--arg` is always a string, `--slurpfile` is always an array
- Trap: `--arg limit 100` gives a number, and `--slurpfile rules rules.json` gives the object in the file.
- Reality: `--arg` binds a string (`"100"`); use `--argjson` for JSON values. `--slurpfile` binds an array of every JSON value in the file, so a single object is `$rules[0]`. `--rawfile` binds the text. `--argfile` was removed in 1.7.
- Detect: numeric comparisons on `$var` from `--arg`; `$map.key` on a `--slurpfile` variable.
- Fix: Use `--argjson` for numbers and booleans, and `$var[0]` (or a single-object check) for `--slurpfile`.
- Source: jq manual, Invoking jq - https://jqlang.org/manual/#invoking-jq

### JQ-07 jq exits 0 on null or empty results
- Trap: A wrapper runs `jq '.items[] | select(.bad)' && alert`, or treats exit 0 as "the rule found nothing".
- Reality: jq exits 0 when the program ran, whatever it output. `-e` sets 1 if the last output was `false`/`null` and 4 if there was no output. Usage or system errors exit 2, compile errors 3, and `halt_error` defaults to 5.
- Detect: exit codes used as rule verdicts without `-e`; wrappers that do not distinguish 2/3 from findings.
- Fix: Use `-e` when the verdict is boolean, or emit an explicit result object, and treat 2, 3 and 5 as tool errors.
- Source: jq manual, Invoking jq (--exit-status) - https://jqlang.org/manual/#invoking-jq

### JQ-08 Shell and CSV output need format strings
- Trap: `jq -r '"rm \(.path)"' | sh` or `jq -r '[.a,.b] | join(",")'` produce safe commands and valid CSV.
- Reality: String interpolation does not escape. `@sh` quotes for a POSIX shell, `@csv` quotes strings and doubles embedded quotes, and `@tsv` escapes tabs, newlines and backslashes. `-r` prints only strings raw; `--raw-output0` (1.7+) separates outputs with NUL and fails if a value contains NUL.
- Detect: jq output piped to `sh`, `xargs` or `eval`; `join(",")` for CSV; `-r` output split on newlines when values may contain them.
- Fix: Use `@sh "cmd \(.path)"`, `@csv`/`@tsv`, and `--raw-output0` with `xargs -0`.
- Source: jq manual, Format strings and escaping - https://jqlang.org/manual/#format-strings-and-escaping

## Modules and tests

### JQ-09 `-L` replaces the default module path
- Trap: `import "lib/rules" as r;` resolves relative to the calling script, and `-L ./lib` adds to the defaults.
- Reality: Modules are `.jq` files. The default search path is `["~/.jq", "$ORIGIN/../lib/jq", "$ORIGIN/../lib"]`; with `-L`, no default path is used. Only paths starting with `./` are relative to the including file (the current directory for a command-line program). `foo/bar` is searched as `foo/bar.jq` and `foo/bar/bar.jq`. A `~/.jq` file is auto-sourced into every program. `import "x" as $x;` loads `x.json` as `$x::x`.
- Detect: wrappers run from cron or other directories with relative imports and no `-L`; developer `~/.jq` files; data imports read as `$x`.
- Fix: Always pass `-L "$(dirname "$0")/lib"` (or an absolute path) from the wrapper and tests, and run CI with an empty HOME.
- Source: jq manual, Modules - https://jqlang.org/manual/#modules

### JQ-10 `--run-tests` has a strict, unstable format
- Trap: `--run-tests` is a stable test framework that accepts any options after it.
- Reality: Each test is a program line, one input line, one line per expected output, then a blank line; `#` lines are comments; `%%FAIL` blocks expect a compile error message. The option must be last, does not honor all preceding options, and "can change backwards-incompatibly".
- Detect: fixtures with multi-line JSON inputs, options placed after `--run-tests`, no pinned jq version (JQ-01).
- Fix: Keep inputs and outputs on single lines (`jq -c`), put `-L` before `--run-tests`, and pin jq. Use bats for wrapper-level behavior (exit codes, arguments).
- Source: jq manual, Invoking jq (--run-tests) - https://jqlang.org/manual/#invoking-jq
