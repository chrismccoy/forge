#!/usr/bin/env bash
#
# parallel-runner.sh - Execute commands in parallel with job control
# Version: 1.0.0
#
# Usage: ./parallel-runner.sh [OPTIONS] -- <command> [args...]
#        ./parallel-runner.sh [OPTIONS] -f <file>
#
# Options:
#   -j, --jobs N      Maximum parallel jobs (default: number of CPUs)
#   -f, --file FILE   Read commands from file (one per line)
#   -t, --timeout N   Timeout per command in seconds (default: none)
#   -r, --retries N   Number of retries on failure (default: 0)
#   -v, --verbose     Log each command ("Running: ...") as it starts
#   -q, --quiet       Suppress runner status/summary messages (job output and
#                     errors are still shown)
#   -d, --dry-run     Show commands without executing
#   -h, --help        Show this help message
#   --version         Show version and exit
#
# Job stdout/stderr always pass through (unbuffered, may interleave).
# -t requires timeout (GNU coreutils) or gtimeout (macOS: brew install coreutils).
#
# Inputs come from the ::: list or, if absent, from stdin (one per line).
# Each {} in the command is replaced by the input, passed to the command as
# a single quoted argument (never evaluated as shell code). If the command
# has no {}, the input is appended as the last argument (use {} explicitly
# for compound commands, e.g. 'test -f {} && wc -l {}').
# Exit status is non-zero if any job failed. Requires bash 5.1+.
#
# Examples:
#   ./parallel-runner.sh -j 4 -- echo {} ::: arg1 arg2 arg3
#   ./parallel-runner.sh -f commands.txt -j 8
#   find . -name "*.txt" | ./parallel-runner.sh -j 4 -- wc -l

set -euo pipefail

# wait -n -p (used for job tracking) needs bash 5.1+
if ((BASH_VERSINFO[0] < 5 || (BASH_VERSINFO[0] == 5 && BASH_VERSINFO[1] < 1))); then
    echo "[ERROR] ${BASH_SOURCE[0]##*/} requires bash 5.1 or newer (found $BASH_VERSION)" >&2
    exit 1
fi

# Script metadata
readonly VERSION="1.0.0"
readonly SCRIPT_NAME="${BASH_SOURCE[0]##*/}"

# Default configuration
MAX_JOBS=$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)
TIMEOUT=""
TIMEOUT_CMD=""
RETRIES=0
VERBOSE=false
QUIET=false
DRY_RUN=false
COMMAND_FILE=""
declare -a COMMAND=()
declare -a INPUTS=()

# Stats
TOTAL=0
COMPLETED=0
FAILED=0
RUNNING=0
STARTED=false

# Job tracking
declare -A JOB_PIDS=()
declare -A JOB_CMDS=()
declare -A JOB_STARTS=()

# Colors (if terminal)
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

# Logging
log_info()  { $QUIET || echo "${BLUE}[INFO]${RESET} $*" >&2; }
log_warn()  { echo "${YELLOW}[WARN]${RESET} $*" >&2; }
log_error() { echo "${RED}[ERROR]${RESET} $*" >&2; }
log_ok()    { $QUIET || echo "${GREEN}[OK]${RESET} $*" >&2; }

show_help() {
    sed -n '/^# Usage:/,/^[^#]/p' "$0" | grep '^#' | sed 's/^# //' | sed 's/^#//'
    exit 0
}

show_version() {
    echo "$SCRIPT_NAME version $VERSION"
    exit 0
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -j|--jobs)
                MAX_JOBS="$2"
                shift 2
                ;;
            -f|--file)
                COMMAND_FILE="$2"
                shift 2
                ;;
            -t|--timeout)
                TIMEOUT="$2"
                shift 2
                ;;
            -r|--retries)
                RETRIES="$2"
                shift 2
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -q|--quiet)
                QUIET=true
                shift
                ;;
            -d|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -h|--help)
                show_help
                ;;
            --version)
                show_version
                ;;
            --)
                shift
                # Everything after -- is the command template
                while [[ $# -gt 0 ]]; do
                    if [[ "$1" == ":::" ]]; then
                        shift
                        INPUTS=("$@")
                        break
                    fi
                    COMMAND+=("$1")
                    shift
                done
                break
                ;;
            *)
                log_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done

    if ! [[ "$MAX_JOBS" =~ ^[1-9][0-9]*$ ]]; then
        log_error "Invalid --jobs value: $MAX_JOBS (must be a positive integer)"
        exit 1
    fi
    if ! [[ "$RETRIES" =~ ^[0-9]+$ ]]; then
        log_error "Invalid --retries value: $RETRIES (must be a non-negative integer)"
        exit 1
    fi
    if [[ -n "$TIMEOUT" ]] && ! [[ "$TIMEOUT" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
        log_error "Invalid --timeout value: $TIMEOUT (must be a number of seconds)"
        exit 1
    fi
    if [[ -n "$TIMEOUT" ]]; then
        if command -v timeout &>/dev/null; then
            TIMEOUT_CMD=timeout
        elif command -v gtimeout &>/dev/null; then
            TIMEOUT_CMD=gtimeout
        else
            log_error "-t requires timeout (coreutils) or gtimeout"
            exit 1
        fi
    fi
}

# Build the bash -c script from the command template. Each {} becomes "$1"
# (literal text), so the input is passed as a positional argument and is
# never parsed as shell code. Without {}, the input is appended.
build_template() {
    local tmpl="${COMMAND[*]}"
    # shellcheck disable=SC2016  # literal "$1" is intended
    local placeholder='"$1"'

    if [[ "$tmpl" == *"{}"* ]]; then
        tmpl="${tmpl//\{\}/"$placeholder"}"
    else
        tmpl+=" $placeholder"
    fi
    printf '%s' "$tmpl"
}

# Human-readable form of a job (input shell-quoted) for logs and dry run
# Args: format_cmd <script> [input]
format_cmd() {
    local cmd="$1"
    if (($# > 1)); then
        local quoted
        printf -v quoted '%q' "$2"
        # shellcheck disable=SC2016  # literal "$1" is intended
        cmd="${cmd//'"$1"'/"$quoted"}"
    fi
    printf '%s' "$cmd"
}

# Execute single command with retry support
# Args: run_command <script> [input]
# The optional input is available to the script as $1.
run_command() {
    local cmd="$1"
    shift
    local attempt=0
    local max_attempts=$((RETRIES + 1))
    local exit_code=0
    local display
    display=$(format_cmd "$cmd" "$@")

    while ((attempt < max_attempts)); do
        ((++attempt))

        if $DRY_RUN; then
            echo "[DRY-RUN] $display"
            return 0
        fi

        $VERBOSE && log_info "Running: $display"

        if [[ -n "$TIMEOUT" ]]; then
            if "$TIMEOUT_CMD" "$TIMEOUT" bash -c "$cmd" _ "$@"; then
                return 0
            else
                exit_code=$?
            fi
        else
            if bash -c "$cmd" _ "$@"; then
                return 0
            else
                exit_code=$?
            fi
        fi

        if ((exit_code == 124)) && [[ -n "$TIMEOUT" ]]; then
            log_warn "Timed out after ${TIMEOUT}s: $display"
        fi

        if ((attempt < max_attempts)); then
            log_warn "Command failed (attempt $attempt/$max_attempts), retrying..."
            sleep 1
        fi
    done

    return "$exit_code"
}

# Start a new job
# Args: start_job <job_id> <script> [input]
start_job() {
    local job_id="$1"
    local cmd="$2"
    shift 2

    # Jobs must not consume the runner's stdin (input list / command file)
    run_command "$cmd" "$@" < /dev/null &
    local pid=$!

    JOB_PIDS[$job_id]=$pid
    JOB_CMDS[$job_id]=$(format_cmd "$cmd" "$@")
    JOB_STARTS[$job_id]=$(date +%s)
    ((++RUNNING))
}

# Reap exactly one finished job and record its result.
# Returns 1 if there was no child left to wait for.
reap_job() {
    local done_pid=""
    local exit_code=0

    # Status comes from this same wait call; the conditional keeps set -e quiet
    if wait -n -p done_pid; then
        exit_code=0
    else
        exit_code=$?
    fi

    # No children left (wait returned 127 without setting the pid)
    [[ -n "$done_pid" ]] || return 1

    local job_id found=""
    for job_id in "${!JOB_PIDS[@]}"; do
        if [[ "${JOB_PIDS[$job_id]}" == "$done_pid" ]]; then
            found="$job_id"
            break
        fi
    done
    # Not one of ours (should not happen); nothing to account for
    [[ -n "$found" ]] || return 0

    local elapsed=$(( $(date +%s) - ${JOB_STARTS[$found]:-0} ))

    if ((exit_code == 0)); then
        ((++COMPLETED))
        $QUIET || log_ok "Completed (${elapsed}s): ${JOB_CMDS[$found]}"
    else
        ((++FAILED))
        log_error "Failed (exit $exit_code, ${elapsed}s): ${JOB_CMDS[$found]}"
    fi

    unset "JOB_PIDS[$found]"
    unset "JOB_CMDS[$found]"
    unset "JOB_STARTS[$found]"
    RUNNING=$((RUNNING - 1))
    return 0
}

# Block until a job slot is free
wait_for_slot() {
    while ((RUNNING >= MAX_JOBS)); do
        reap_job || { RUNNING=0; break; }
    done
}

# Wait for all remaining jobs
wait_all() {
    while ((RUNNING > 0)); do
        reap_job || { RUNNING=0; break; }
    done
}

# Process commands from file
process_file() {
    local file="$1"

    if [[ ! -r "$file" ]]; then
        log_error "Cannot read command file: $file"
        exit 1
    fi

    while IFS= read -r line || [[ -n "$line" ]]; do
        # Skip empty lines and comments
        [[ -z "$line" || "$line" == \#* ]] && continue

        ((++TOTAL))
        wait_for_slot
        start_job "$TOTAL" "$line"
    done < "$file"
}

# Process stdin
process_stdin() {
    local cmd
    cmd=$(build_template)

    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ -z "$line" ]] && continue

        ((++TOTAL))
        wait_for_slot
        start_job "$TOTAL" "$cmd" "$line"
    done
}

# Process input list
process_inputs() {
    local cmd input
    cmd=$(build_template)

    for input in "${INPUTS[@]}"; do
        ((++TOTAL))
        wait_for_slot
        start_job "$TOTAL" "$cmd" "$input"
    done
}

# Print summary
# shellcheck disable=SC2329  # invoked from cleanup (trap)
print_summary() {
    local exit_code="${1:-0}"
    $QUIET && return
    $STARTED || return 0

    echo ""
    echo "================================"
    echo "Parallel Runner Summary"
    echo "================================"
    echo "Total jobs:     $TOTAL"
    echo "Completed:      $COMPLETED"
    echo "Failed:         $FAILED"
    echo "Max parallel:   $MAX_JOBS"
    echo "================================"

    if ((FAILED > 0)); then
        echo "${RED}Some jobs failed!${RESET}"
    elif ((exit_code != 0)); then
        echo "${RED}Aborted (exit $exit_code)${RESET}"
    else
        echo "${GREEN}All jobs completed successfully${RESET}"
    fi
}

# Cleanup on exit
# shellcheck disable=SC2329  # invoked via trap
cleanup() {
    local exit_code=$?
    # Run once, even if exit is called from the INT/TERM handler
    trap - EXIT INT TERM

    # Kill any remaining jobs
    for pid in "${JOB_PIDS[@]}"; do
        # Also stop the job's command (child of the run_command subshell)
        pkill -TERM -P "$pid" 2>/dev/null || true
        kill "$pid" 2>/dev/null || true
    done

    print_summary "$exit_code"
    exit "$exit_code"
}

trap cleanup EXIT INT TERM

main() {
    setup_colors
    parse_args "$@"

    log_info "Starting parallel runner with $MAX_JOBS jobs"
    STARTED=true

    if [[ -n "$COMMAND_FILE" ]]; then
        # Process commands from file
        process_file "$COMMAND_FILE"
    elif [[ ${#COMMAND[@]} -gt 0 ]]; then
        if [[ ${#INPUTS[@]} -gt 0 ]]; then
            # Process with ::: input list
            process_inputs
        elif [[ ! -t 0 ]]; then
            # Process stdin
            process_stdin
        else
            log_error "No input provided. Use ::: or pipe input."
            exit 1
        fi
    else
        log_error "No command specified. Use -- <command> or -f <file>"
        exit 1
    fi

    wait_all

    # Return failure if any job failed
    ((FAILED > 0)) && exit 1
    exit 0
}

main "$@"
