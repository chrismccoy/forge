# Workflow: Generate a Bash Script Template

Use this workflow when the user asks for a starting template or scaffold of a known type (CLI tool, daemon, library, installer, CI script) rather than a script for one specific task. For a script that does a specific job, use `workflow-create.md`.

## Example requests

- "Give me a bash CLI tool template."
- "I need a daemon script skeleton with full features and structured logging."
- "Scaffold a minimal installer script."
- "Template for a CI script that uses Docker and runs jobs in parallel."
- "Start a function library called my-utils."

## Arguments

Extract these from the request:

- **Template type**: one of `cli`, `daemon`, `library`, `installer`, `ci`, matched from words like "command-line tool", "service", "background", "library of functions", "install script", "pipeline". If none matches, ask, or default to `cli` and say so.
- **Feature flags**: map phrases to the options in the table below. "minimal", "bare", "simple" means `--minimal`; "everything", "full-featured" means `--full`; mentions of logging, config files, parallelism, prompts/menus, Docker, AWS, or Kubernetes enable `--logging`, `--config`, `--parallel`, `--interactive`, `--docker`, `--aws`, `--k8s`.
- **Name**: a script or library name if given (`my-utils`); otherwise derive one from the type.

## Available Template Types

### 1. CLI Tool (`cli`)
Full-featured command-line tool with:
- Argument parsing (getopts/long options)
- Help and version commands
- Configuration file support
- Logging with verbosity levels
- Progress indicators
- Color output support

### 2. Daemon/Service (`daemon`)
Background service script with:
- Daemonization support
- PID file management
- Signal handling (SIGHUP, SIGTERM)
- Log rotation integration
- Systemd unit file generation
- Health check endpoint

### 3. Library (`library`)
Reusable function library with:
- Namespaced functions
- Dependency checking
- Self-documentation
- Version tracking
- Safe sourcing patterns
- Unit test integration

### 4. Installer (`installer`)
Software installation script with:
- Dependency verification
- Platform detection
- Root privilege handling
- Rollback support
- Progress reporting
- Post-install verification

### 5. CI/CD Pipeline (`ci`)
CI/CD pipeline script with:
- Environment detection
- Secret handling
- Artifact management
- Test execution
- Deployment patterns
- Notification integration

## Template Options

Specify additional options for customization:

| Option | Description |
|--------|-------------|
| `--minimal` | Basic template without advanced features |
| `--full` | All features enabled |
| `--config` | Include configuration file handling |
| `--logging` | Include structured logging |
| `--parallel` | Include parallel processing support |
| `--interactive` | Include user prompts and menus |
| `--docker` | Include Docker integration |
| `--aws` | Include AWS CLI patterns |
| `--k8s` | Include Kubernetes patterns |

## Steps

1. Read `in-depth-patterns.md` for the argument parsing, logging, locking, and signal-handling patterns the templates are built from. Also read `best_practices.md`; for `daemon` read the signal-handling material, for `installer` read `platform_specifics.md`, for `ci` read `shellcheck-cicd.md`, and for `--parallel` read `parallel-processing.md`.
2. Start from the base structure below and add the feature modules the type and flags call for. Remove placeholders the user will not need.
3. Write the file, then validate it:
   ```bash
   bash -n script-name
   shellcheck script-name
   ```
   Fix every finding and re-run until clean. If `shellcheck` is not installed, say so instead of claiming the template is lint-clean.
4. Run it once with `--help` (and with no arguments) to confirm the usage path works.
5. Report the file path, the features included, and what the user should fill in next.

## Template Structure

All templates include the following base. Every helper it calls (`die`, `show_help`, `parse_args`, `validate_environment`, `execute`) and the `ARGS` array are defined here; the feature modules below extend or replace them.

```bash
#!/usr/bin/env bash
#
# script-name - Brief description
# Version: 1.0.0
# Author: <author>
# License: MIT
#
# Usage: script-name [OPTIONS] <arguments>
#
# Description:
#   Longer description of what the script does.
#

# Strict mode
set -euo pipefail

# Script metadata
readonly VERSION="1.0.0"
readonly SCRIPT_NAME="${BASH_SOURCE[0]##*/}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR

# Configuration defaults
declare -A CONFIG=(
    [verbose]=false
    [dry_run]=false
    [config_file]="${SCRIPT_DIR}/${SCRIPT_NAME%.sh}.conf"
)

# Positional arguments collected by parse_args
declare -a ARGS=()

# Print an error and exit (default status 1)
die() {
    printf '%s: error: %s\n' "$SCRIPT_NAME" "$1" >&2
    exit "${2:-1}"
}

show_help() {
    cat <<USAGE
Usage: $SCRIPT_NAME [OPTIONS] <arguments>

Options:
  -h, --help       Show this help and exit
  -v, --version    Show version and exit
  -V, --verbose    Verbose output
  -n, --dry-run    Show what would be done without doing it
USAGE
}

# Cleanup handler: runs on every exit, including errors and signals
cleanup() {
    local exit_code=$?
    # Remove temp files, release locks, etc.
    exit "$exit_code"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help) show_help; exit 0 ;;
            -v|--version) echo "$VERSION"; exit 0 ;;
            -V|--verbose) CONFIG[verbose]=true ;;
            -n|--dry-run) CONFIG[dry_run]=true ;;
            --) shift; ARGS+=("$@"); break ;;
            -*) die "unknown option: $1 (see --help)" 2 ;;
            *) ARGS+=("$1") ;;
        esac
        shift
    done
}

validate_environment() {
    ((${#ARGS[@]} > 0)) || die "missing arguments (see --help)" 2
    # Check required commands, files, permissions here, e.g.:
    # command -v jq >/dev/null 2>&1 || die "jq is required"
}

execute() {
    local arg
    for arg in "${ARGS[@]}"; do
        if [[ "${CONFIG[dry_run]}" == true ]]; then
            printf 'would process: %s\n' "$arg"
        else
            printf 'processing: %s\n' "$arg"
        fi
    done
}

main() {
    parse_args "$@"
    validate_environment
    execute
}

main "$@"
```

## Feature Modules

Templates can include these feature modules:

### Argument Parsing

The base template's `parse_args` handles short and long options, `--`, and positional arguments collected into `ARGS`, reporting unknown options through `die`. Add an option by adding a `case` branch; for options that take a value, use `--name) CONFIG[name]="${2:?--name needs a value}"; shift ;;`.

### Logging System
```bash
declare -A LOG_LEVELS=([DEBUG]=0 [INFO]=1 [WARN]=2 [ERROR]=3)
LOG_LEVEL="${LOG_LEVEL:-INFO}"

log() {
    local level="$1"; shift
    local want="${LOG_LEVELS[$level]:-}"
    local min="${LOG_LEVELS[$LOG_LEVEL]:-1}"   # unknown LOG_LEVEL falls back to INFO

    if [[ -z "$want" ]]; then
        printf '[%s] unknown log level, message: %s\n' "$level" "$*" >&2
        return 0
    fi
    if ((want >= min)); then
        local ts
        ts=$(date '+%Y-%m-%d %H:%M:%S')
        printf '[%s] [%s] %s\n' "$ts" "$level" "$*" >&2
    fi
}

debug() { log DEBUG "$@"; }
info()  { log INFO "$@"; }
warn()  { log WARN "$@"; }
error() { log ERROR "$@"; }
```

### Color Output
```bash
setup_colors() {
    if [[ -t 2 ]] && [[ -z "${NO_COLOR:-}" ]]; then
        RED=$'\033[0;31m'
        GREEN=$'\033[0;32m'
        YELLOW=$'\033[0;33m'
        BLUE=$'\033[0;34m'
        RESET=$'\033[0m'
    else
        RED='' GREEN='' YELLOW='' BLUE='' RESET=''
    fi
}
```

### Progress Indicator
```bash
spinner() {
    local pid=$1
    local msg=$2
    local delay=0.1
    local i
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'

    while kill -0 "$pid" 2>/dev/null; do
        for ((i=0; i<${#spinstr}; i++)); do
            printf '\r%s %s' "${spinstr:i:1}" "$msg"
            sleep "$delay"
        done
    done
    printf '\rdone: %s\n' "$msg"
}
```

## Output

Deliver:

1. The complete script with the requested features.
2. Inline comments on non-obvious parts.
3. Usage examples.
4. Confirmation that `bash -n` and ShellCheck pass (or what remains and why).
5. Test patterns (for example, bats tests) when the type is `library` or the user asks for them.
