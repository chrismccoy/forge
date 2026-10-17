# Workflow: Create a Bash Script

Use this workflow when the user asks to write, create, or generate a new bash script. To review an existing script, use `workflow-analyze.md`; to speed one up, use `workflow-optimize.md`; to scaffold from a fixed template type, use `workflow-template.md`.

## Example requests

- "Write a bash script that archives /data and uploads it to S3."
- "Create a script that rotates logs older than 7 days in /var/log/myapp."
- "Generate a bash CLI that takes `--input` and `--dry-run` and renames files by date."
- "Turn these commands I run by hand into a reusable script."

## Arguments

There are no formal arguments; extract them from the request:

- **Purpose**: what the script must do (the core verb and objects).
- **Inputs**: paths, URLs, bucket names, flags the user mentions. Make them positional arguments or options rather than hard-coding them.
- **Constraints**: target platform (Linux, macOS, Git Bash/WSL), minimum bash version, required tools (aws, jq, docker), and whether it runs in CI or cron.
- **Output file name**: use the name the user gives; otherwise derive one from the purpose (`backup.sh`).

Ask only when a missing detail changes the design (for example, which platform or which cloud CLI). Otherwise pick a sensible default and state it.

## Steps

1. Read the references that match the task before writing code:
   - Always: `best_practices.md` and `patterns_antipatterns.md`.
   - Handles user input, paths, temp files, or secrets: `security.md`.
   - Larger script structure, argument parsing, logging: `in-depth-patterns.md`.
   - Must run on macOS/BSD or Windows: `platform_specifics.md` (and `windows-git-bash-paths.md` for Git Bash).
   - Processes many items concurrently: `parallel-processing.md`.
2. Write the script with:
   - `#!/usr/bin/env bash` and `set -euo pipefail`.
   - A header comment with purpose and usage.
   - Input validation with clear errors on stderr and non-zero exit codes.
   - `mktemp` for temporary files and a `trap ... EXIT` cleanup.
   - Small, single-purpose functions and a `main "$@"` entry point.
   - Declaration and command-substitution assignment on separate lines (`local x; x="$(cmd)"`) so failures are not masked (SC2155).
3. Save the file and validate it:
   ```bash
   bash -n path/to/script.sh
   shellcheck path/to/script.sh
   ```
   Fix every finding, then re-run. If `shellcheck` is not installed, say so and recommend installing it; do not claim the script is lint-clean.
4. If it is safe to do so, run the script with `--help` or against a harmless input to confirm it behaves as described.
5. Report the file path, how to run it, assumptions you made, and any external dependencies.

## Example output

```bash
#!/usr/bin/env bash
#
# backup.sh - Archive a directory and upload it to S3
# Usage: backup.sh <source_dir> <s3_bucket>

set -euo pipefail

SCRIPT_NAME="${BASH_SOURCE[0]##*/}"
readonly SCRIPT_NAME

TEMP_DIR=""

die() {
    printf '%s: error: %s\n' "$SCRIPT_NAME" "$1" >&2
    exit "${2:-1}"
}

cleanup() {
    if [[ -n "$TEMP_DIR" ]]; then
        rm -rf -- "$TEMP_DIR"
    fi
}
trap cleanup EXIT

main() {
    if (($# != 2)); then
        die "usage: $SCRIPT_NAME <source_dir> <s3_bucket>" 2
    fi
    local source_dir="$1"
    local s3_bucket="$2"

    [[ -d "$source_dir" ]] || die "source directory not found: $source_dir"
    command -v aws >/dev/null 2>&1 || die "aws CLI not found in PATH"

    TEMP_DIR="$(mktemp -d)"

    local stamp archive
    stamp="$(date +%Y%m%d-%H%M%S)"
    archive="$TEMP_DIR/backup-$stamp.tar.gz"

    tar -czf "$archive" -C "$source_dir" . || die "failed to create archive"
    aws s3 cp "$archive" "s3://$s3_bucket/" || die "failed to upload to S3"

    printf 'Backup uploaded: s3://%s/%s\n' "$s3_bucket" "${archive##*/}"
}

main "$@"
```

This example passes `bash -n` and `shellcheck` with no findings.

## Standards applied

- **ShellCheck**: no findings at the default severity; fix rather than suppress, and justify any `# shellcheck disable=` with a comment.
- **Strict mode**: `set -euo pipefail`, with its known caveats (for example, use `((++n))` or `n=$((n + 1))` rather than `((n++))`, which returns status 1 when `n` is 0 and aborts under `set -e`).
- **Structure**: keep functions small and single-purpose (a house rule, not a Google Shell Style Guide limit). The Google guide does advise that a script growing beyond roughly 100 lines, or with complex control flow, should probably be rewritten in a more structured language; mention this when a request is heading that way.
- **Security**: quote expansions, validate input, never `eval` user data, use `mktemp`.
- **Portability**: note GNU-only flags and bash 4+/5+ features when the target includes macOS or older systems.
