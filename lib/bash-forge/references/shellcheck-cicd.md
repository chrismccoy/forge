# ShellCheck CI/CD Integration

## ShellCheck: Treat It as a Required Check

Run ShellCheck on every change to shell scripts, locally and in CI. Check which version you have with `shellcheck --version`; the notes below were verified against v0.11.0.

## Contents

- [What's in v0.11.0](#whats-in-v0110)
- [Installation](#installation)
- [GitHub Actions Integration](#github-actions-integration)
- [Azure DevOps Integration](#azure-devops-integration)
- [Git Hooks (Pre-Commit)](#git-hooks-pre-commit)
- [VS Code Integration](#vs-code-integration)
- [Docker Build Integration](#docker-build-integration)
- [Common ShellCheck Rules](#common-shellcheck-rules)
- [Script Size and Structure](#script-size-and-structure)
- [Enforce in CI/CD](#enforce-in-cicd)
- [Error Handling Trio](#error-handling-trio)
- [Best Practices](#best-practices)
- [Resources](#resources)

### What's in v0.11.0

v0.11.0 (released 2025-08-03) includes, among other changes:
- Bash 5.3 parsing support (`${ cmd; }`, `${| cmd; }` and `source -p`)
- **New checks SC2327/SC2328**: capturing the output of a command whose output is redirected elsewhere (see [below](#sc2327sc2328-command-substitution-output-redirected-away))
- **New check SC2332**: `[ ! -o opt ]` is always true in Bash
- **POSIX.1-2024**: SC3013 removed (`-ot`/`-nt`/`-ef` in `[ ]` are now POSIX)
- SC2002 (useless use of cat) is now disabled by default; re-enable with `--enable=useless-use-of-cat`

See the [ShellCheck changelog](https://github.com/koalaman/shellcheck/blob/master/CHANGELOG.md) for the full list.

### Why Require It?

- Catches subtle bugs (quoting, word splitting, masked exit codes) before production
- Flags common security problems such as unquoted expansions passed to commands
- Enforces consistent code quality across contributors
- Cheap to run: a single static binary with no runtime dependencies

## Installation

```bash
# Ubuntu/Debian (also WSL with an Ubuntu/Debian distribution)
sudo apt-get install shellcheck

# macOS
brew install shellcheck

# Alpine (Docker)
apk add shellcheck

# Windows (native, e.g. for Git Bash): Chocolatey or Scoop
choco install shellcheck
scoop install shellcheck

# Or download a release binary (Linux x86_64)
wget https://github.com/koalaman/shellcheck/releases/latest/download/shellcheck-stable.linux.x86_64.tar.xz
tar -xf shellcheck-stable.linux.x86_64.tar.xz
sudo cp shellcheck-stable/shellcheck /usr/local/bin/
```

Distribution packages can lag behind the latest release; use the release binary (or pin a version in CI) if you need specific checks.

## GitHub Actions Integration

### Required Pre-Merge Check

```yaml
# .github/workflows/shellcheck.yml
name: ShellCheck

on:
  pull_request:
    paths:
      - '**.sh'
      - '**Dockerfile'
  push:
    branches: [main]

permissions:
  contents: read
  pull-requests: write   # only needed for the PR comment step

jobs:
  shellcheck:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4

    - name: Run ShellCheck
      # Pin to a release tag (or a commit SHA), never @master
      uses: ludeeus/action-shellcheck@2.0.0
      with:
        severity: warning
        format: gcc  # or: tty, checkstyle
        scandir: './scripts'
        ignore_paths: 'node_modules'
      # Any finding at or above `severity` fails this step

    # Make this check required in branch protection to block merges
    - name: Comment on PR
      if: failure() && github.event_name == 'pull_request'
      uses: actions/github-script@v7
      with:
        script: |
          await github.rest.issues.createComment({
            issue_number: context.issue.number,
            owner: context.repo.owner,
            repo: context.repo.repo,
            body: 'ShellCheck validation failed. Fix issues before merging.'
          })
```

## Azure DevOps Integration

ShellCheck has no JUnit output, so there is nothing for `PublishTestResults` to consume. Fail the step on ShellCheck's exit code, and keep a checkstyle report as a pipeline artifact if you want one.

```yaml
# azure-pipelines.yml
trigger:
- main

pr:
- main

stages:
- stage: Validate
  jobs:
  - job: ShellCheck
    pool:
      vmImage: 'ubuntu-24.04'

    steps:
    - script: |
        sudo apt-get update
        sudo apt-get install -y shellcheck
      displayName: 'Install ShellCheck'

    # -print0 / -0 handle spaces and newlines in filenames;
    # -r skips running shellcheck when no files are found
    - script: |
        find . -name '*.sh' -type f -print0 \
          | xargs -0 -r shellcheck --format=gcc --severity=warning
      displayName: 'Run ShellCheck'

    - script: |
        mkdir -p "$(Build.ArtifactStagingDirectory)"
        find . -name '*.sh' -type f -print0 \
          | xargs -0 -r shellcheck --format=checkstyle \
          > "$(Build.ArtifactStagingDirectory)/shellcheck-checkstyle.xml" || true
      displayName: 'Generate checkstyle report'
      condition: always()

    - task: PublishPipelineArtifact@1
      condition: always()
      inputs:
        targetPath: '$(Build.ArtifactStagingDirectory)/shellcheck-checkstyle.xml'
        artifact: 'shellcheck-report'
```

## Git Hooks (Pre-Commit)

The shebang must be the first line of the hook file:

```bash
#!/usr/bin/env bash
# .git/hooks/pre-commit
set -o errexit
set -o nounset
set -o pipefail

# Find all staged .sh files
mapfile -t STAGED_SH < <(git diff --cached --name-only --diff-filter=ACMR | grep '\.sh$' || true)

if [[ ${#STAGED_SH[@]} -eq 0 ]]; then
  exit 0
fi

echo "Running ShellCheck on staged files..."

# Test the command directly: under errexit a bare failing command would
# exit before a later `$?` check could run.
if ! shellcheck --format=gcc --severity=warning "${STAGED_SH[@]}"; then
  echo "ShellCheck failed. Fix issues before committing." >&2
  exit 1
fi

echo "ShellCheck passed"
```

**Install the hook:**
```bash
chmod +x .git/hooks/pre-commit
```

**Or use the pre-commit framework:**
```yaml
# .pre-commit-config.yaml
repos:
- repo: https://github.com/shellcheck-py/shellcheck-py
  rev: v0.11.0.1
  hooks:
  - id: shellcheck
    args: ['--severity=warning']
```

```bash
pip install pre-commit
pre-commit install
```

## VS Code Integration

```json
// .vscode/settings.json
{
  "shellcheck.enable": true,
  "shellcheck.run": "onType",
  "shellcheck.executablePath": "/usr/local/bin/shellcheck",
  "shellcheck.exclude": ["SC1090", "SC1091"],  // Optional excludes
  "shellcheck.customArgs": [
    "-x",  // Follow source files
    "--severity=warning"
  ]
}
```

## Docker Build Integration

```dockerfile
# Dockerfile with ShellCheck validation
FROM alpine:3.19 AS builder

# Install ShellCheck
RUN apk add --no-cache shellcheck bash

# Copy scripts
COPY scripts/ /scripts/

# Validate all scripts before continuing
RUN find /scripts -name "*.sh" -type f -exec shellcheck --severity=warning {} +

# Final stage
FROM alpine:3.19
COPY --from=builder /scripts/ /scripts/
RUN chmod +x /scripts/*.sh

ENTRYPOINT ["/scripts/entrypoint.sh"]
```

## Common ShellCheck Rules

Severity matters when you filter with `--severity`: several common checks (SC2086, SC2295) are reported at `info` level and are hidden by `--severity=warning`.

### SC2327/SC2328: Command Substitution Output Redirected Away

New in v0.11.0. A command substitution captures standard output; if the command inside redirects that output elsewhere, the substitution is always empty. SC2327 (warning) flags the substitution, SC2328 (error) flags the redirection.

```bash
# Wrong: output goes to the file, so $result is always empty
result=$(generate_report > report.txt)

# Wrong: output discarded, so $match is always empty
match=$(grep "pattern" input.txt > /dev/null)

# Correct: write the file AND capture the output
result=$(generate_report | tee report.txt)

# Correct: if you only need the exit status, don't use a substitution
if grep -q "pattern" input.txt; then
  echo "found"
fi
```

### SC2294: eval Negates Array Benefits

(Added in v0.8.0.)

```bash
# Wrong: eval re-splits the array elements, defeating array safety
eval "command ${array[@]}"

# Correct: direct array usage
command "${array[@]}"
```

### SC2295: Quote Expansions Inside ${..} Separately

Unquoted expansions inside a `${var#...}`/`${var%...}`/`${var/...}` pattern are treated as glob patterns, not literal strings.

```bash
# Wrong: $prefix is used as a pattern (e.g. "a*" matches "abc...")
echo "${path#$prefix}"

# Correct: quote the inner expansion to match it literally
echo "${path#"$prefix"}"
```

### SC2086: Quote Variables

```bash
# Wrong
file=$1
cat $file  # Fails if filename has spaces

# Correct
file=$1
cat "$file"
```

### SC2046: Quote Command Substitution

```bash
# Wrong: the output is word-split and globbed
rm $(find . -name "*.tmp")

# Correct: let find pass the names safely
find . -name "*.tmp" -exec rm -- {} +
```

(Looping over `for f in $(find ...)` is a related problem, flagged as SC2044; use `find ... -print0 | while IFS= read -r -d '' f; do ...; done`.)

### SC2155: Separate Declaration and Assignment

```bash
# Wrong
local result=$(command)  # Hides command exit code

# Correct
local result
result=$(command)
```

### SC2164: Use cd || exit

```bash
# Wrong
cd /some/directory
./script.sh  # Runs in wrong dir if cd fails

# Correct
cd /some/directory || exit 1
./script.sh
```

## Script Size and Structure

The [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html) says that if a script is more than 100 lines long, or uses non-straightforward control flow logic, it should probably be rewritten in a more structured language. It sets no limit on function length.

A reasonable house rule on top of that: keep functions small and single-purpose, and split shared helpers into sourced libraries so ShellCheck (with `-x`) can analyze each piece.

```bash
# lib/logging.sh
log_info()  { echo "[INFO] $*"; }
log_error() { echo "[ERROR] $*" >&2; }

# lib/validation.sh
validate_input() {
  [[ $# -ge 1 ]] || { log_error "usage: main.sh <file>"; return 1; }
}
check_dependencies() {
  command -v jq >/dev/null || { log_error "jq is required"; return 1; }
}

# main.sh
# shellcheck source=lib/logging.sh
source "$(dirname "$0")/lib/logging.sh"
# shellcheck source=lib/validation.sh
source "$(dirname "$0")/lib/validation.sh"

main() {
  validate_input "$@"
  check_dependencies
  # ... core logic ...
}

main "$@"
```

## Enforce in CI/CD

### Fail Build on Issues

```yaml
# Strict enforcement
- name: ShellCheck (Strict)
  run: |
    shellcheck --severity=warning scripts/*.sh
  # Exit code 1 fails the build

# Advisory only (warnings but don't fail)
- name: ShellCheck (Advisory)
  run: |
    shellcheck --severity=warning scripts/*.sh || true
  # Logs warnings but doesn't fail
```

### Generate Reports

```bash
# JSON format for parsing
shellcheck --format=json scripts/*.sh > shellcheck-report.json

# Checkstyle XML (for tools that ingest checkstyle reports)
shellcheck --format=checkstyle scripts/*.sh > shellcheck-checkstyle.xml

# One line per finding: file:line:col: severity: message [SCxxxx]
shellcheck --format=gcc scripts/*.sh

# Human-readable
shellcheck --format=tty scripts/*.sh
```

Available formats: `checkstyle`, `diff`, `gcc`, `json`, `json1`, `quiet`, `tty`.

## Error Handling Trio

Use together with ShellCheck validation:

```bash
#!/usr/bin/env bash

set -o errexit   # Exit on command failure
set -o nounset   # Exit on undefined variable
set -o pipefail  # Exit on pipe failure

main() {
  local config_file="${1:?Config file required}"

  if [[ ! -f "$config_file" ]]; then
    echo "Error: Config file not found: $config_file" >&2
    return 1
  fi

  # Separate declaration and assignment (SC2155)
  local result
  result=$(process_config "$config_file")

  echo "$result"
}

main "$@"
```

ShellCheck does not flag `((count++))` exiting under `set -e` when `count` is 0; see [Post-Increment Under set -e](./patterns_antipatterns.md#anti-pattern-post-increment-under-set--e).

## Best Practices

1. **Run ShellCheck in CI/CD** as a required check
2. **Use pre-commit hooks** to catch issues early
3. **Pin ShellCheck and action versions** so new checks don't break builds unexpectedly
4. **Keep scripts short and functions small**; per the Google Shell Style Guide, consider another language once a script grows past about 100 lines
5. **Use the error handling trio** (errexit, nounset, pipefail)
6. **Fix all warnings** before merging
7. **Document any disabled rules** with reasoning
8. **Integrate with your editor** for real-time feedback

## Resources

- [ShellCheck](https://www.shellcheck.net)
- [ShellCheck Changelog](https://github.com/koalaman/shellcheck/blob/master/CHANGELOG.md)
- [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)
- [ShellCheck GitHub Action](https://github.com/ludeeus/action-shellcheck)
