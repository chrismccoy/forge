# Workflow: Analyze a Bash Script

Use this workflow when the user asks to analyze, audit, review, or lint an existing bash script or a directory of scripts, covering security, performance, portability, and best practices. `$SKILL_DIR` is this skill's folder (see SKILL.md).

## Example requests

- "Analyze backup.sh."
- "Review everything in scripts/ and tell me what is wrong."
- "Audit deploy.sh, focusing on security vulnerabilities."
- "Is build.sh POSIX compliant? Check portability."

## Arguments

Extract these from the request:

- **Target**: a file path (`backup.sh`) or a directory (`scripts/`). For a directory, analyze every `*.sh`/`*.bash` file plus extensionless files with a bash shebang. If no target is named, ask, or use the script currently under discussion.
- **Focus** (optional): phrases such as "focus on security", "check portability", "POSIX compliance", or "performance". With a focus, cover that category in depth and the others briefly. Without one, cover all four categories.

## Steps

1. Read the target files completely before judging them.
2. Run ShellCheck from the user's working directory (so their relative paths still resolve), calling the helper by absolute path:
   ```bash
   bash "$SKILL_DIR/scripts/shellcheck-batch.sh" -f gcc path/to/script.sh   # or a directory
   ```
   Keep the default severity (style), which reports everything including info-level unquoted expansions (SC2086, SC2295) and exits 1 on any finding; do not pass `-s warning`, which hides those. Use `-f json -o report.json` when the user wants a machine-readable report. `--ci` is only for a CI gate: it exits non-zero on errors alone, so it is not a lint-clean check. If `shellcheck` is not installed, say so in the report, recommend installing it, and carry out the manual review against the ShellCheck categories you know. Do not report a ShellCheck score you did not measure.
3. Run `bash -n` on each file to catch syntax errors.
4. Read `security.md` and `patterns_antipatterns.md` from this folder, and check the script against them. For portability questions also read `platform_specifics.md`; for performance findings, `text-processing-pure-bash.md`.
5. Work through the checklist below and record each finding with its file, line, severity, and a concrete fix.
6. Write the report in the format below. Offer to apply the fixes; do not edit files unless the user asks.

## Analysis Categories

### 1. Security Analysis
- Command injection vulnerabilities
- Path traversal risks
- Unsafe temporary file handling
- Unquoted variable expansions
- Privilege escalation risks
- Sensitive data exposure
- Race condition vulnerabilities

### 2. Performance Analysis
- Unnecessary subshell spawning
- Inefficient loops (UUOC, UUOG)
- External command overuse vs bash builtins
- Pipeline optimization opportunities
- Array usage efficiency
- Process substitution opportunities

### 3. Portability Analysis
- Bash version compatibility (4.x, 5.x features)
- POSIX compliance level
- Platform-specific issues (Linux/macOS/BSD)
- GNU vs BSD tool differences
- Shebang portability

### 4. Best Practices Compliance
- ShellCheck warnings (all severity levels)
- Google Shell Style Guide adherence
- Error handling patterns
- Cleanup and trap usage
- Function structure and modularity
- Documentation and comments

## Analysis Output Format

For each script analyzed, provide:

```text
## Script: <filename>

### Security Issues
- [CRITICAL] <issue description>
- [HIGH] <issue description>
- [MEDIUM] <issue description>

### Performance Issues
- [IMPACT: HIGH] <issue description>
- [IMPACT: MEDIUM] <issue description>

### Portability Issues
- [Bash 5.x required] <feature used>
- [GNU-specific] <command/flag used>

### Best Practice Violations
- [ShellCheck SC####] <description>
- [Style] <description>

### Recommendations
1. <actionable recommendation>
2. <actionable recommendation>

### Score: X/100
- Security: X/25
- Performance: X/25
- Portability: X/25
- Best Practices: X/25
```

## Analysis Checklist

When analyzing scripts, systematically check:

### Security Checklist
- [ ] All variables quoted in command arguments
- [ ] No eval with user input
- [ ] No unvalidated external input in commands
- [ ] Temp files created securely (mktemp)
- [ ] No world-readable sensitive data
- [ ] Proper file permission handling
- [ ] No symlink following vulnerabilities

### Performance Checklist
- [ ] Using bash builtins over external commands
- [ ] Avoiding unnecessary subshells
- [ ] Using arrays instead of string parsing
- [ ] Efficient file reading patterns
- [ ] Process substitution where appropriate
- [ ] Avoiding cat | grep (UUOC)
- [ ] Using mapfile for file reading

### Portability Checklist
- [ ] Shebang uses /usr/bin/env bash or /bin/bash
- [ ] Bash version requirements documented
- [ ] No undocumented bashisms
- [ ] GNU/BSD command compatibility
- [ ] Works on major platforms

### Best Practices Checklist
- [ ] set -euo pipefail at start
- [ ] trap for cleanup on EXIT
- [ ] Functions small and single-purpose (house rule; the Google Shell Style Guide sets no function length limit, but suggests a script beyond about 100 lines should probably be rewritten in a structured language)
- [ ] No `((x++))`/`((x--))` under `set -e` (status 1 when the old value is 0 aborts the script); use `((++x))` or `x=$((x + 1))`
- [ ] Proper error messages to stderr
- [ ] Meaningful exit codes
- [ ] ShellCheck passes with zero warnings
- [ ] Consistent coding style

## After the analysis

1. Deliver the report with every issue rated by severity.
2. Give a specific fix for each issue, with corrected code for anything CRITICAL or HIGH.
3. Offer to apply the fixes, then re-run `bash -n` and ShellCheck on the edited files.
4. Suggest structural changes only when the findings justify them.
