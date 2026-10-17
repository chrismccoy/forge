# Workflow: Optimize a Bash Script

Use this workflow when the user asks to make an existing bash script faster, lighter on memory, or more efficient. `$SKILL_DIR` is this skill's folder (see SKILL.md).

## Example requests

- "Optimize deploy.sh."
- "process.sh is too slow; make it faster." (target: speed)
- "large-file-handler.sh runs out of memory on big inputs." (target: memory)
- "Speed up etl-script.sh and cut its memory use." (target: both)

## Arguments

Extract these from the request:

- **Target script**: the file to optimize, plus any arguments or sample input needed to run it realistically. If the user gives no representative input, ask for one or build a safe synthetic one; do not profile against production data or side-effecting commands without permission.
- **`target: speed|memory|both`**: take it from an explicit `target:` phrase if present; otherwise infer it ("slow", "takes 5 minutes" means speed; "out of memory", "huge file" means memory). Default to `both`.

## Steps

1. Read the script fully and note anything with side effects (network calls, writes, deletes) that must be stubbed or pointed at test data before running it.
2. Measure the baseline with representative input:
   ```bash
   time ./script.sh args...
   # or, for repeated runs with statistics:
   hyperfine --warmup 2 './script.sh args...'
   ```
   Save the output so you can compare it later (`./script.sh args... > before.out`).
3. Profile to find where the time goes. Run from the user's working directory, calling the helper by absolute path:
   ```bash
   bash "$SKILL_DIR/scripts/script-profiler.sh" -n 10 ./script.sh args...
   bash "$SKILL_DIR/scripts/script-profiler.sh" -t 50 -f csv -o profile.csv ./script.sh args...
   ```
   (`-n` shows the top N slowest lines, `-t` hides lines under a threshold in milliseconds, `-f` selects text, csv, or json.)
4. Read `text-processing-pure-bash.md` (builtins versus external tools) and `parallel-processing.md` (when and how to parallelize). For memory work, also read `debugging.md` and `in-depth-patterns.md` as needed.
5. Apply changes to the hot spots only, one at a time, using the techniques below. Prefer the change that removes the most process spawns or passes over the data.
6. Verify correctness: rerun with the same input and compare outputs (`diff before.out after.out`). Run `bash -n` and `shellcheck` on the result.
7. Measure again with the same `time` or `hyperfine` command and report before and after numbers. Revert any change that does not produce a measurable gain or that harms readability for no benefit.

## Optimization Targets

### Speed Optimization
- Reduce subshell spawning
- Replace external commands with bash builtins
- Optimize loop structures
- Implement parallel processing
- Use efficient I/O patterns

### Memory Optimization
- Stream processing instead of loading files
- Efficient array usage
- Proper variable scoping
- Cleanup temporary data
- Avoid unnecessary string copies

## Optimization Techniques

### 1. Subshell Elimination

**Before:**
```bash
# Spawns subshell for each
result=$(echo "$var" | tr 'a-z' 'A-Z')
count=$(cat file.txt | wc -l)
basename=$(basename "$path")
```

**After:**
```bash
# Fewer processes
result="${var^^}"           # pure bash
count=$(wc -l < file.txt)   # drop the useless cat; wc is far faster than a bash read loop
basename="${path##*/}"      # pure bash
```

For counting lines, keep `wc -l`: a `while read` loop is much slower on anything but tiny files. The win here is removing `cat` and the extra pipe, not removing `wc`.

### 2. External Command Replacement

| External | Bash Equivalent |
|----------|-----------------|
| `basename "$p"` | `"${p##*/}"` |
| `dirname "$p"` | `"${p%/*}"` |
| `echo "$s" \| tr a-z A-Z` | `"${s^^}"` |
| `expr $a + $b` | `$((a + b))` |
| `cat file` | `< file` or `mapfile` |
| `cut -d: -f1` | `"${var%%:*}"` |
| `sed 's/a/b/g'` | `"${var//a/b}"` |

### 3. Loop Optimization

**Before:**
```bash
# Creates subshell, variables lost
count=0
cat file.txt | while read -r line; do
    count=$((count + 1))
done
echo "$count"  # Prints 0: the loop ran in a subshell
```

**After:**
```bash
# No subshell, variables preserved
count=0
while IFS= read -r line; do
    ((++count))   # not ((count++)): that returns 1 when count is 0 and aborts under set -e
done < file.txt
echo "$count"  # Correct value
```

### 4. Array vs String Processing

**Before:**
```bash
# Slow: string manipulation
files="file1.txt file2.txt file3.txt"
for f in $files; do
    process "$f"
done
```

**After:**
```bash
# Fast: array iteration
files=("file1.txt" "file2.txt" "file3.txt")
for f in "${files[@]}"; do
    process "$f"
done
```

### 5. File Reading Optimization

**Before:**
```bash
# Multiple reads of same file
grep "pattern1" file.txt > result1.txt
grep "pattern2" file.txt > result2.txt
grep "pattern3" file.txt > result3.txt
```

**After:**
```bash
# Single pass with awk: one process, same regex semantics as grep
awk '
    /pattern1/ { print > "result1.txt" }
    /pattern2/ { print > "result2.txt" }
    /pattern3/ { print > "result3.txt" }
' file.txt
```

Do not replace the greps with a `while read` loop and `[[ $line == *pattern* ]]`: a bash read loop is usually slower than three `grep` passes on large files, and glob matching is not regex matching. Only consider the multi-pass version a problem when the file is large or the pattern count is high; otherwise three greps are fine.

### 6. Parallel Processing

**Before:**
```bash
# Sequential processing
for file in *.txt; do
    process_file "$file"
done
```

**After:**
```bash
# Parallel with GNU Parallel (a shell function must be exported first)
export -f process_file
parallel -j "$(nproc)" process_file ::: *.txt

# Or with xargs (bash -c sees the function through the export above)
printf '%s\0' *.txt | xargs -0 -P "$(nproc)" -n 1 bash -c 'process_file "$1"' _

# Or with the bundled runner (timeouts and retries), from your working directory
bash "$SKILL_DIR/scripts/parallel-runner.sh" -j 4 -t 300 -r 2 -- ./process_file.sh {} ::: *.txt

# Or with job control
max_jobs=4
running=0
for file in *.txt; do
    process_file "$file" &
    if ((++running >= max_jobs)); then
        wait -n || true          # one job finished (bash 4.3+)
        running=$((running - 1))
    fi
done
wait
```

### 7. Process Substitution

**Before:**
```bash
# Temporary files
sort file1.txt > /tmp/sorted1
sort file2.txt > /tmp/sorted2
diff /tmp/sorted1 /tmp/sorted2
rm /tmp/sorted1 /tmp/sorted2
```

**After:**
```bash
# Process substitution - no temp files
diff <(sort file1.txt) <(sort file2.txt)
```

### 8. Here-String vs Echo Pipe

**Before:**
```bash
echo "$var" | command
```

**After:**
```bash
command <<< "$var"
```

## Optimization Process

When optimizing a script:

1. **Profile first** - Identify actual bottlenecks
2. **Measure baseline** - Record current execution time
3. **Apply optimizations** - Implement changes incrementally
4. **Verify correctness** - Ensure output matches original
5. **Measure improvement** - Quantify the gains

## Profiling Commands

```bash
# Time execution
time ./script.sh

# Detailed timing with bash
TIMEFORMAT='real: %R, user: %U, sys: %S'
time ./script.sh

# Statistical comparison of two versions
hyperfine --warmup 2 './script.sh' './script.optimized.sh'

# Per-line profile with the bundled helper (run from your working directory)
bash "$SKILL_DIR/scripts/script-profiler.sh" -n 10 ./script.sh

# Manual line-by-line trace with timestamps (bash 5+ for EPOCHREALTIME).
# `set -x` in the current shell does not trace a child script, so run the
# script under `bash -x` and pass PS4 through the environment:
PS4='+ ${EPOCHREALTIME} ${BASH_SOURCE}:${LINENO}: ' bash -x ./script.sh 2> trace.log

# Trace with relative timestamps (ts is from moreutils)
bash -x ./script.sh 2>&1 | ts -s '%.s'
```

## Output Format

```markdown
## Optimization Report: <script>

### Performance Profile
- Original execution time: X.XXs
- Bottlenecks identified: N

### Optimizations Applied
1. [IMPACT: HIGH] Replace `cat | grep` with direct grep
   - Before: 150ms
   - After: 20ms
   - Improvement: 87%

2. [IMPACT: MEDIUM] Use bash string manipulation
   - Replaced: external `basename`
   - With: parameter expansion

### Summary
- Total optimizations: N
- Estimated speedup: X.Xx faster
- Subshells eliminated: N
- External commands replaced: N

### Optimized Script
[Full optimized script or diff]
```

## After Optimization

1. Show the report with measured before and after timings.
2. Provide the optimized script or a diff.
3. Explain each change and why it helps.
4. Offer to apply the changes; do not overwrite the original unless the user asks.
5. Note further improvements only if profiling supports them.
