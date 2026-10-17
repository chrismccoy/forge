#!/usr/bin/env bash
#
# script-profiler.sh - Profile bash script execution with timing information
# Version: 1.0.0
#
# Usage: ./script-profiler.sh [OPTIONS] <script> [script-args...]
#
# Options:
#   -o, --output FILE   Write profile data to file (default: stdout)
#   -f, --format FMT    Output format: text, csv, json (default: text)
#   -t, --threshold MS  Only show lines taking >= MS milliseconds (default: 0)
#   -n, --top N         Show only top N slowest lines (default: all)
#   -s, --summary       Show only summary, not line-by-line
#   -c, --commands      Aggregate time per external command name instead of per line
#   -h, --help          Show this help message
#   --version           Show version and exit
#
# Requires bash >= 5.0 (uses EPOCHREALTIME for timestamps).
# Time for a traced line is measured until the next traced line starts.
# The trace goes to a dedicated fd (BASH_XTRACEFD), so the profiled script's
# own stdout/stderr pass through unchanged. Exit status 2 on usage errors.
#
# Examples:
#   ./script-profiler.sh myscript.sh arg1 arg2
#   ./script-profiler.sh -c build.sh
#   ./script-profiler.sh -n 10 -t 100 slow_script.sh
#   ./script-profiler.sh -f csv -o profile.csv build.sh

set -euo pipefail

if [[ -z "${BASH_VERSINFO[0]:-}" ]] || ((BASH_VERSINFO[0] < 5)); then
    echo "Error: ${0##*/} requires bash >= 5.0 (EPOCHREALTIME); running ${BASH_VERSION:-unknown}" >&2
    exit 1
fi

# Script metadata
readonly VERSION="1.0.0"
readonly SCRIPT_NAME="${BASH_SOURCE[0]##*/}"

# Configuration
OUTPUT=""
FORMAT="text"
THRESHOLD=0
TOP_N=0
SUMMARY_ONLY=false
PROFILE_COMMANDS=false
TARGET_SCRIPT=""
declare -a SCRIPT_ARGS=()

# Temporary files
TRACE_FILE=""
TIMING_FILE=""

# Wall-clock end of the profiled run (microseconds)
END_US=0

# Colors
# shellcheck disable=SC2034  # not every color is used
setup_colors() {
    if [[ -t 1 ]]; then
        RED=$'\033[0;31m'
        GREEN=$'\033[0;32m'
        YELLOW=$'\033[0;33m'
        BLUE=$'\033[0;34m'
        CYAN=$'\033[0;36m'
        BOLD=$'\033[1m'
        RESET=$'\033[0m'
    else
        RED='' GREEN='' YELLOW='' BLUE='' CYAN='' BOLD='' RESET=''
    fi
}

# Informational messages: stdout for text, stderr for csv/json so data stays parseable
info() {
    if [[ "$FORMAT" == "text" ]]; then
        echo "$@"
    else
        echo "$@" >&2
    fi
}

# Current time in microseconds (EPOCHREALTIME, locale radix may be '.' or ',')
now_us() {
    local t="$EPOCHREALTIME"
    local sec="${t%%[.,]*}"
    local usec="${t#*[.,]}"
    echo $((sec * 1000000 + 10#$usec))
}

# Escape a string for inclusion in a JSON string literal
json_escape() {
    local s="$1"
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    s="${s//$'\t'/\\t}"
    s="${s//$'\r'/\\r}"
    printf '%s' "$s"
}

show_help() {
    sed -n '/^# Usage:/,/^[^#]/p' "$0" | grep '^#' | sed 's/^# //' | sed 's/^#//'
    exit "${1:-0}"
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -o|--output)
                OUTPUT="$2"
                shift 2
                ;;
            -f|--format)
                FORMAT="$2"
                shift 2
                ;;
            -t|--threshold)
                THRESHOLD="$2"
                shift 2
                ;;
            -n|--top)
                TOP_N="$2"
                shift 2
                ;;
            -s|--summary)
                SUMMARY_ONLY=true
                shift
                ;;
            -c|--commands)
                PROFILE_COMMANDS=true
                shift
                ;;
            -h|--help)
                show_help
                ;;
            --version)
                echo "$SCRIPT_NAME version $VERSION"
                exit 0
                ;;
            -*)
                echo "Unknown option: $1" >&2
                exit 1
                ;;
            *)
                TARGET_SCRIPT="$1"
                shift
                SCRIPT_ARGS=("$@")
                break
                ;;
        esac
    done

    if [[ -z "$TARGET_SCRIPT" ]]; then
        echo "Error: No script specified" >&2
        show_help 2 >&2
    fi

    if [[ ! -f "$TARGET_SCRIPT" ]]; then
        echo "Error: Script not found: $TARGET_SCRIPT" >&2
        exit 1
    fi

    case "$FORMAT" in
        text|csv|json) ;;
        *)
            echo "Error: Invalid format: $FORMAT (expected text, csv, json)" >&2
            exit 1
            ;;
    esac

    if [[ ! "$THRESHOLD" =~ ^[0-9]+$ ]] || [[ ! "$TOP_N" =~ ^[0-9]+$ ]]; then
        echo "Error: --threshold and --top must be non-negative integers" >&2
        exit 1
    fi
}

# Create temporary files
setup_temp() {
    TRACE_FILE=$(mktemp)
    TIMING_FILE=$(mktemp)
}

# Cleanup
cleanup() {
    rm -f "$TRACE_FILE" "$TIMING_FILE" 2>/dev/null || true
}
trap cleanup EXIT

# Profile the script
run_profile() {
    local script="$1"
    shift

    info "${BOLD}Profiling: $script${RESET}"
    info "Arguments: $*"
    info ""

    # Set PS4 for timing information (expanded by the traced shell, no fork)
    # Format: +<sec>.<usec> <source>:<lineno>: <command>
    # shellcheck disable=SC2016  # expanded later by the traced bash
    local ps4_format='+${EPOCHREALTIME} ${BASH_SOURCE[0]:-$0}:${LINENO}: '

    # Run with tracing (same bash binary, so EPOCHREALTIME is available)
    local start_us
    start_us=$(now_us)

    # Trace goes to its own fd via BASH_XTRACEFD (honored from the environment
    # by the child bash), so the script's stderr is not captured or lost.
    # With -o FILE or csv/json, the script's stdout goes to stderr so it does
    # not corrupt the profile data.
    local trace_fd
    exec {trace_fd}>"$TRACE_FILE"
    if [[ "$FORMAT" == "text" && -z "$OUTPUT" ]]; then
        BASH_XTRACEFD="$trace_fd" PS4="$ps4_format" "$BASH" -x "$script" "$@" || true
    else
        BASH_XTRACEFD="$trace_fd" PS4="$ps4_format" "$BASH" -x "$script" "$@" >&2 || true
    fi
    exec {trace_fd}>&-

    END_US=$(now_us)

    local total_ms=$(((END_US - start_us) / 1000))

    info ""
    info "${BOLD}Total execution time: ${total_ms}ms${RESET}"
    info ""

    # Parse trace output
    parse_trace "$total_ms"
}

# Parse trace file and generate timing data
# Time between two consecutive trace lines is attributed to the earlier line.
parse_trace() {
    local total_ms="$1"
    local prev_time=0
    local prev_key=""
    local line_count=0
    local -A line_times=()    # microseconds
    local -A line_counts=()
    local -A line_sources=()
    local -A cmd_kind=()      # cache: command name -> type -t result

    info "${BOLD}Analyzing trace data...${RESET}"

    local re='^\++([0-9]+)[.,]([0-9]+) ([^:]+):([0-9]+): (.*)$'
    local line timestamp source lineno command key duration name
    local -a words

    # Parse each trace line
    while IFS= read -r line; do
        # Match: +<sec>.<usec> <source>:<lineno>: <command>  (one '+' per nesting level)
        [[ "$line" =~ $re ]] || continue

        timestamp=$((BASH_REMATCH[1] * 1000000 + 10#${BASH_REMATCH[2]}))
        source="${BASH_REMATCH[3]}"
        lineno="${BASH_REMATCH[4]}"
        command="${BASH_REMATCH[5]}"

        # Close out the previous line
        if [[ -n "$prev_key" ]]; then
            duration=$((timestamp - prev_time))
            ((duration < 0)) && duration=0
            line_times[$prev_key]=$(( ${line_times[$prev_key]:-0} + duration ))
            line_counts[$prev_key]=$(( ${line_counts[$prev_key]:-0} + 1 ))
        fi

        # Determine aggregation key for this line
        key=""
        if $PROFILE_COMMANDS; then
            read -ra words <<<"$command" || true
            name=""
            for name in "${words[@]}"; do
                # skip leading VAR=value assignments
                [[ "$name" =~ ^[A-Za-z_][A-Za-z0-9_]*= ]] || break
                name=""
            done
            if [[ -n "$name" ]]; then
                if [[ -z "${cmd_kind[$name]+set}" ]]; then
                    cmd_kind[$name]=$(type -t -- "$name" 2>/dev/null || true)
                fi
                if [[ "${cmd_kind[$name]}" == "file" ]]; then
                    key="$name"
                fi
            fi
        else
            key="${source}:${lineno}"
        fi
        # shellcheck disable=SC2034  # read via nameref in output_*
        [[ -n "$key" ]] && line_sources[$key]="$command"

        prev_key="$key"
        prev_time="$timestamp"
        line_count=$((line_count + 1))
    done < "$TRACE_FILE"

    # Last traced line runs until the script ended
    if [[ -n "$prev_key" ]]; then
        duration=$((END_US - prev_time))
        ((duration < 0)) && duration=0
        line_times[$prev_key]=$(( ${line_times[$prev_key]:-0} + duration ))
        line_counts[$prev_key]=$(( ${line_counts[$prev_key]:-0} + 1 ))
    fi

    info "Processed $line_count trace lines"
    info ""

    # Output results
    output_results line_times line_counts line_sources "$total_ms"
}

# Output profiling results
output_results() {
    local -n res_times="$1"
    # shellcheck disable=SC2034  # passed by name to output_*
    local -n res_counts="$2"
    # shellcheck disable=SC2034  # passed by name to output_*
    local -n res_sources="$3"
    local total_ms="$4"

    # Sort by time (descending)
    local -a sorted_keys=()
    for key in "${!res_times[@]}"; do
        sorted_keys+=("${res_times[$key]}:$key")
    done

    if ((${#sorted_keys[@]} > 0)); then
        mapfile -t sorted_keys < <(printf '%s\n' "${sorted_keys[@]}" | sort -t: -k1,1 -rn)
    fi

    case "$FORMAT" in
        text)
            output_text sorted_keys res_times res_counts res_sources "$total_ms"
            ;;
        csv)
            output_csv sorted_keys res_times res_counts res_sources "$total_ms"
            ;;
        json)
            output_json sorted_keys res_times res_counts res_sources "$total_ms"
            ;;
    esac
}

output_text() {
    local -n out_sorted="$1"
    local -n out_times="$2"
    local -n out_counts="$3"
    local -n out_sources="$4"
    local total_ms="$5"

    local label="Location"
    $PROFILE_COMMANDS && label="Command"

    if $SUMMARY_ONLY; then
        echo "${BOLD}Profile Summary${RESET}"
        echo "═══════════════════════════════════════════════════════════════════"
        printf "%-12s %-8s %-8s %s\n" "Time (ms)" "Calls" "Avg (ms)" "$label"
        echo "───────────────────────────────────────────────────────────────────"
    else
        echo "${BOLD}Detailed Profile${RESET}"
        echo "═══════════════════════════════════════════════════════════════════"
        printf "%-12s %-8s %-8s %-6s %s\n" "Time (ms)" "Calls" "Avg (ms)" "%Total" "$label"
        echo "───────────────────────────────────────────────────────────────────"
    fi

    local count=0
    local entry key time_us time_ms call_count avg_ms pct color
    for entry in "${out_sorted[@]}"; do
        key="${entry#*:}"
        time_us="${out_times[$key]}"
        time_ms=$((time_us / 1000))
        call_count="${out_counts[$key]}"
        avg_ms=$((time_us / call_count / 1000))
        pct=$((time_ms * 100 / (total_ms + 1)))

        # Apply threshold filter (sorted descending, so nothing further qualifies)
        if ((time_ms < THRESHOLD)); then
            break
        fi

        # Color based on time
        color=""
        if ((time_ms >= 1000)); then
            color="$RED"
        elif ((time_ms >= 100)); then
            color="$YELLOW"
        elif ((time_ms >= 10)); then
            color="$CYAN"
        fi

        if $SUMMARY_ONLY; then
            printf "%s%-12s %-8s %-8s %s%s\n" \
                "$color" "$time_ms" "$call_count" "$avg_ms" "$key" "$RESET"
        else
            printf "%s%-12s %-8s %-8s %-6s %s%s\n" \
                "$color" "$time_ms" "$call_count" "$avg_ms" "${pct}%" "$key" "$RESET"
            # Show command on next line
            printf "             └─ %s\n" "${out_sources[$key]:0:60}"
        fi

        count=$((count + 1))
        if ((TOP_N > 0 && count >= TOP_N)); then
            break
        fi
    done

    echo "═══════════════════════════════════════════════════════════════════"
}

output_csv() {
    local -n out_sorted="$1"
    local -n out_times="$2"
    local -n out_counts="$3"
    local -n out_sources="$4"
    local total_ms="$5"

    if $PROFILE_COMMANDS; then
        echo "time_ms,calls,avg_ms,pct_total,command"
    else
        echo "time_ms,calls,avg_ms,pct_total,source,lineno,command"
    fi

    local count=0
    local entry key time_us time_ms call_count avg_ms pct source lineno command
    for entry in "${out_sorted[@]}"; do
        key="${entry#*:}"
        time_us="${out_times[$key]}"
        time_ms=$((time_us / 1000))
        call_count="${out_counts[$key]}"
        avg_ms=$((time_us / call_count / 1000))
        pct=$((time_ms * 100 / (total_ms + 1)))

        if ((time_ms < THRESHOLD)); then
            break
        fi

        # CSV: embedded quotes are doubled
        command="${out_sources[$key]//\"/\"\"}"

        if $PROFILE_COMMANDS; then
            printf '%s,%s,%s,%s,"%s"\n' \
                "$time_ms" "$call_count" "$avg_ms" "$pct" "${key//\"/\"\"}"
        else
            source="${key%:*}"
            lineno="${key##*:}"
            printf '%s,%s,%s,%s,"%s",%s,"%s"\n' \
                "$time_ms" "$call_count" "$avg_ms" "$pct" "${source//\"/\"\"}" "$lineno" "$command"
        fi

        count=$((count + 1))
        if ((TOP_N > 0 && count >= TOP_N)); then
            break
        fi
    done
}

output_json() {
    local -n out_sorted="$1"
    local -n out_times="$2"
    local -n out_counts="$3"
    local -n out_sources="$4"
    local total_ms="$5"

    local list_name="lines"
    $PROFILE_COMMANDS && list_name="commands"

    echo "{"
    echo "  \"total_ms\": $total_ms,"
    echo "  \"$list_name\": ["

    local count=0
    local first=true
    local entry key time_us time_ms call_count avg_ms pct source lineno command
    for entry in "${out_sorted[@]}"; do
        key="${entry#*:}"
        time_us="${out_times[$key]}"
        time_ms=$((time_us / 1000))
        call_count="${out_counts[$key]}"
        avg_ms=$((time_us / call_count / 1000))
        pct=$((time_ms * 100 / (total_ms + 1)))

        if ((time_ms < THRESHOLD)); then
            break
        fi

        $first || echo ","
        first=false

        if $PROFILE_COMMANDS; then
            printf '    {"time_ms": %s, "calls": %s, "avg_ms": %s, "pct": %s, "command": "%s"}' \
                "$time_ms" "$call_count" "$avg_ms" "$pct" "$(json_escape "$key")"
        else
            source="${key%:*}"
            lineno="${key##*:}"
            command="$(json_escape "${out_sources[$key]}")"
            printf '    {"time_ms": %s, "calls": %s, "avg_ms": %s, "pct": %s, "source": "%s", "line": %s, "command": "%s"}' \
                "$time_ms" "$call_count" "$avg_ms" "$pct" "$(json_escape "$source")" "$lineno" "$command"
        fi

        count=$((count + 1))
        if ((TOP_N > 0 && count >= TOP_N)); then
            break
        fi
    done

    if ! $first; then
        echo ""
    fi
    echo "  ]"
    echo "}"
}

main() {
    setup_colors
    parse_args "$@"
    setup_temp

    # Run profiler
    if [[ -n "$OUTPUT" ]]; then
        run_profile "$TARGET_SCRIPT" "${SCRIPT_ARGS[@]}" > "$OUTPUT"
        echo "Profile written to: $OUTPUT" >&2
    else
        run_profile "$TARGET_SCRIPT" "${SCRIPT_ARGS[@]}"
    fi

    info ""
    info "${GREEN}${BOLD}Profiling complete.${RESET}"
}

main "$@"
