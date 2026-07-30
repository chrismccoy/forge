# jq - JSON Querying and Transformation

## Overview

`jq` is the standard CLI tool for querying and reshaping JSON. This skill covers practical, expert-level usage: filtering deeply nested data, transforming structures, aggregating values, and composing `jq` into shell pipelines. Every example is copy-paste ready for real workflows.

## Workflow

1. Read the input. Identify the JSON source - pasted text, a file, or a piped command (`curl`, `kubectl`, `aws`, `gh`, `docker`).
2. Inspect the shape. Run `jq 'keys'` or `jq '.[0]'` on a sample to confirm actual field names and nesting before writing the filter.
3. Build the filter incrementally. Start from the root, add one pipe stage at a time, verifying each stage against the sample.
4. Choose output mode. Use `-r` for shell consumption, `-c` for NDJSON pipelines, default pretty-print for human reading.
5. Verify against sample input before embedding in a script. Confirm no `null`/empty surprises.
6. Deliver the final command plus a one-line explanation of each filter stage (see Output Format).

## How It Works

`jq` takes a filter expression and applies it to JSON input. Filters compose with pipes (`|`), and `jq` handles arrays, objects, strings, numbers, booleans, and `null` natively.

### Basic Selection

```bash
# Extract a field
echo '{"name":"alice","age":30}' | jq '.name'
# "alice"

# Nested access
echo '{"user":{"email":"a@b.com"}}' | jq '.user.email'

# Array index
echo '[10, 20, 30]' | jq '.[1]'
# 20

# Array slice
echo '[1,2,3,4,5]' | jq '.[2:4]'
# [3, 4]

# All array elements
echo '[{"id":1},{"id":2}]' | jq '.[]'
```

### Filtering with `select`

```bash
# Keep only matching elements
echo '[{"role":"admin"},{"role":"user"},{"role":"admin"}]' \
  | jq '[.[] | select(.role == "admin")]'

# Numeric comparison
curl -s https://api.github.com/repos/owner/repo/issues \
  | jq '[.[] | select(.comments > 5)]'

# Test a field exists and is non-null
jq '[.[] | select(.email != null)]'

# Combine conditions
jq '[.[] | select(.active == true and .score >= 80)]'
```

### Mapping and Transformation

```bash
# Extract a field from every array element
echo '[{"name":"alice","age":30},{"name":"bob","age":25}]' \
  | jq '[.[] | .name]'
# ["alice", "bob"]

# Shorthand: map()
jq 'map(.name)'

# Build a new object per element
jq '[.[] | {user: .name, years: .age}]'

# Add a computed field
jq '[.[] | . + {senior: (.age > 28)}]'

# Rename keys
jq '[.[] | {username: .name, email_address: .email}]'
```

### Aggregation and Reduce

```bash
# Sum all values
echo '[1, 2, 3, 4, 5]' | jq 'add'
# 15

# Sum a field across objects
jq '[.[].price] | add'

# Count elements
jq 'length'

# Max / min
jq 'max_by(.score)'
jq 'min_by(.created_at)'

# reduce: custom accumulator
echo '[1,2,3,4,5]' | jq 'reduce .[] as $x (0; . + $x)'
# 15

# Group by field
jq 'group_by(.department)'

# Count per group
jq 'group_by(.status) | map({status: .[0].status, count: length})'
```

### String Interpolation and Formatting

```bash
# String interpolation
jq -r '.[] | "\(.name) is \(.age) years old"'

# Format as CSV (no header)
jq -r '.[] | [.name, .age, .email] | @csv'

# Format as TSV
jq -r '.[] | [.name, .score] | @tsv'

# URL-encode a value
jq -r '.query | @uri'

# Base64 encode
jq -r '.data | @base64'
```

### Working with Keys and Paths

```bash
# List all top-level keys
jq 'keys'

# Check if key exists
jq 'has("email")'

# Delete a key
jq 'del(.password)'

# Delete nested keys from every element
jq '[.[] | del(.internal_id, .raw_payload)]'

# Recursive descent: find all values for a key anywhere in tree
jq '.. | .id? // empty'

# Get all leaf paths
jq '[paths(scalars)]'
```

### Conditionals and Error Handling

```bash
# if-then-else
jq 'if .score >= 90 then "A" elif .score >= 80 then "B" else "C" end'

# Alternative operator: use fallback if null or false
jq '.nickname // .name'

# try-catch: skip errors instead of halting
jq '[.[] | try .nested.value catch null]'

# Suppress null output with // empty
jq '.[] | .optional_field // empty'
```

### Practical Shell Integration

```bash
# Read from file
jq '.users' data.json

# Compact output (no whitespace) for further piping
jq -c '.[]' records.json | while IFS= read -r record; do
  echo "Processing: $record"
done

# Pass a shell variable into jq
STATUS="active"
jq --arg s "$STATUS" '[.[] | select(.status == $s)]'

# Pass a number
jq --argjson threshold 42 '[.[] | select(.value > $threshold)]'

# Slurp multiple JSON lines into an array
jq -s '.' records.ndjson

# Multiple files: slurp all into one array
jq -s 'add' file1.json file2.json

# Null-safe pipeline from a command
kubectl get pods -o json | jq '.items[] | {name: .metadata.name, status: .status.phase}'

# GitHub CLI: extract PR numbers
gh pr list --json number,title | jq -r '.[] | "\(.number)\t\(.title)"'

# AWS CLI: list running instance IDs
aws ec2 describe-instances \
  | jq -r '.Reservations[].Instances[] | select(.State.Name=="running") | .InstanceId'

# Docker: show container names and images
docker inspect $(docker ps -q) | jq -r '.[] | "\(.Name)\t\(.Config.Image)"'
```

### Advanced Patterns

```bash
# Transpose an object of arrays to an array of objects
# Input: {"names":["a","b"],"scores":[10,20]}
jq '[.names, .scores] | transpose | map({name: .[0], score: .[1]})'

# Flatten one level
jq 'flatten(1)'

# Unique by field
jq 'unique_by(.email)'

# Sort, deduplicate and re-index
jq '[.[] | .name] | unique | sort'

# Walk: apply transformation to every node recursively
jq 'walk(if type == "string" then ascii_downcase else . end)'

# env: read environment variables inside jq
export API_KEY=secret
jq -n 'env.API_KEY'
```

## Best Practices

- Prefer `map(f)` over `[.[] | f]` for readability
- Test filters interactively with `jq -n` and literal input before embedding in scripts

(Core rules - `-r`, `--arg`/`--argjson`, single-quoting, `null`/empty handling - are enforced in Quality Gates below.)

## Output Format

- Return a single copy-paste-ready `jq` command inside a ```bash code block.
- Follow it with a one-line plain-English explanation per filter stage (what each `|` does).
- When the input shape was inspected, show the sample command used (`jq 'keys'`, `jq '.[0]'`).
- No preamble, no restating the question. Command first, explanation second.

## Error Handling

- **Missing input:** No JSON source provided → ask the user to paste the JSON or name the file/command. Do not guess the shape.
- **Malformed JSON:** Input fails to parse → report the parse error verbatim and point at the offending line; suggest `jq` with `--stream` or a validator if truncated.
- **Ambiguous target field:** Field name unclear or appears at multiple depths → run `jq 'keys'` / `jq '[paths(scalars)]'` to enumerate, then confirm the intended path with the user before finalizing.
- **Empty / null result:** Filter returns nothing → check key casing and nesting; offer an `// empty` or `// <default>` fallback.

## Quality Gates

- [ ] Filter tested against a sample of the actual input, not assumed shape
- [ ] `-r` used when output feeds a shell variable or command
- [ ] Shell variables injected via `--arg` / `--argjson`, never string-interpolated
- [ ] Filter string single-quoted to block shell expansion
- [ ] `null`/empty edge cases handled (`// empty`, `// 0`, `add // 0`)
- [ ] Each filter stage explained in the delivered output

## Security & Safety Notes

- `jq` is read-only by design - it cannot write files or execute commands
- Avoid embedding untrusted JSON field values directly into shell commands; always quote or use `--arg`

## Common Pitfalls

- **Problem:** `jq` outputs `null` instead of the expected value
  **Solution:** Check for typos in key names; use `keys` to inspect actual field names. JSON keys are case-sensitive.

- **Problem:** Numbers are quoted as strings in the output
  **Solution:** Use `--argjson` instead of `--arg` when injecting numeric values.

- **Problem:** Filter works in the terminal but fails in a script
  **Solution:** Ensure the filter string uses single quotes in the shell to prevent variable expansion. Example: `jq '.field'` not `jq ".field"`.

- **Problem:** `add` returns `null` on an empty array
  **Solution:** Use `add // 0` or `add // ""` to provide a fallback default.

- **Problem:** Streaming large files is slow
  **Solution:** Use `jq --stream` or switch to `jstream`/`gron` for very large files.

## Companion Command

- **`../../commands/jq.md`** - `/jq` slash command with `AskUserQuestion` intake for JSON source, goal, and output mode. Walks the user through inputs, then applies this skill's workflow.

## Limitations
- Use this skill only when the task clearly matches the scope described above.
- Do not treat the output as a substitute for environment-specific validation, testing, or expert review.
- Stop and ask for clarification if required inputs, permissions, safety boundaries, or success criteria are missing.
