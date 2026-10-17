#!/usr/bin/env bash
#
# Batch ShellCheck runner (shellcheck-batch.sh) - Run ShellCheck on multiple scripts
# with summary reporting
# Version: 1.0.0
#
# Usage: ./shellcheck-batch.sh [OPTIONS] <files or directories>
#
# Options:
#   -f, --format FMT    Output format: text, json, json1, gcc, checkstyle, diff (default: text)
#   -s, --severity LVL  Minimum severity: error, warning, info, style (default: style)
#   -e, --exclude CODES Comma-separated list of codes to exclude (e.g., SC2086,SC2034)
#   -x, --external      Follow source directives (shellcheck -x)
#   -o, --output FILE   Write the ShellCheck report (in --format) to file
#   -c, --color         Force color output
#   -q, --quiet         Only show summary
#   -v, --verbose       Show detailed progress
#   --fix               Print common fix examples after the summary
#   --ci                CI-friendly output (exit code 0 if only warnings/info/style)
#   -h, --help          Show this help message
#   --version           Show version and exit
#
# Directories are searched recursively (skipping .git, node_modules, vendor)
# for *.sh/*.bash files and extensionless files with a sh/bash/dash/ksh shebang.
#
# Exit status: 0 if no findings at/above --severity (with --ci: no errors),
# 1 otherwise; ShellCheck invocation failures also exit 1.
#
# Examples:
#   ./shellcheck-batch.sh scripts/
#   ./shellcheck-batch.sh -s warning -e SC2086 *.sh
#   ./shellcheck-batch.sh --format json -o report.json src/

set -euo pipefail

# Script metadata
readonly VERSION="1.0.0"
readonly SCRIPT_NAME="${BASH_SOURCE[0]##*/}"

# Configuration
FORMAT="text"
SEVERITY="style"
EXCLUDE=""
EXTERNAL=false
OUTPUT=""
COLOR=false
QUIET=false
VERBOSE=false
SHOW_FIX=false
CI_MODE=false
declare -a PATHS=()

# Counters
TOTAL_FILES=0
PASSED_FILES=0
FAILED_FILES=0
TOOL_FAILURES=0
LAST_ISSUE_COUNT=0
declare -A ERROR_COUNTS=([error]=0 [warning]=0 [info]=0 [style]=0)

# Colors
# shellcheck disable=SC2034  # not every color is used
setup_colors() {
    if [[ -t 1 ]] || $COLOR; then
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

show_help() {
    sed -n '/^# Usage:/,/^[^#]/p' "$0" | grep '^#' | sed 's/^# //' | sed 's/^#//'
    exit 0
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -f|--format)
                FORMAT="$2"
                shift 2
                ;;
            -s|--severity)
                SEVERITY="$2"
                shift 2
                ;;
            -e|--exclude)
                EXCLUDE="$2"
                shift 2
                ;;
            -x|--external)
                EXTERNAL=true
                shift
                ;;
            -o|--output)
                OUTPUT="$2"
                shift 2
                ;;
            -c|--color)
                COLOR=true
                shift
                ;;
            -q|--quiet)
                QUIET=true
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            --fix)
                SHOW_FIX=true
                shift
                ;;
            --ci)
                CI_MODE=true
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
                PATHS+=("$1")
                shift
                ;;
        esac
    done

    if [[ ${#PATHS[@]} -eq 0 ]]; then
        PATHS=(".")
    fi

    case "$FORMAT" in
        text|tty|json|json1|gcc|checkstyle|diff|quiet) ;;
        *)
            echo "Error: Invalid format: $FORMAT" >&2
            exit 1
            ;;
    esac

    case "$SEVERITY" in
        error|warning|info|style) ;;
        *)
            echo "Error: Invalid severity: $SEVERITY (expected error, warning, info, style)" >&2
            exit 1
            ;;
    esac
}

# Check if ShellCheck is installed
check_shellcheck() {
    if ! command -v shellcheck &>/dev/null; then
        echo "${RED}Error: ShellCheck is not installed${RESET}" >&2
        echo "Install with:" >&2
        echo "  apt-get install shellcheck  # Debian/Ubuntu" >&2
        echo "  brew install shellcheck     # macOS" >&2
        exit 1
    fi

    local version
    version=$(shellcheck --version | grep -oP 'version: \K[0-9.]+' || shellcheck --version | head -2 | tail -1)
    if $VERBOSE; then
        echo "${BLUE}Using ShellCheck $version${RESET}"
    fi
}

# Find all shell scripts
find_scripts() {
    local path="$1"

    if [[ -f "$path" ]]; then
        # Single file
        if is_shell_script "$path"; then
            echo "$path"
        fi
    elif [[ -d "$path" ]]; then
        # Directory - *.sh/*.bash, plus extensionless files with a shell
        # shebang; skip VCS and dependency directories
        local file
        while IFS= read -r -d '' file; do
            if [[ "$file" == *.sh || "$file" == *.bash ]]; then
                echo "$file"
            elif [[ "${file##*/}" != *.* ]] && has_shell_shebang "$file"; then
                echo "$file"
            fi
        done < <(find "$path" \( -name .git -o -name node_modules -o -name vendor \) -prune \
                    -o -type f -print0 2>/dev/null || true)
    fi
}

# True if the first line is a sh/bash/dash/ksh shebang
# (#!/bin/sh, #!/usr/bin/bash, #!/usr/bin/env bash, #!/usr/bin/env -S bash -e, ...)
has_shell_shebang() {
    local first=""
    IFS= read -r first < "$1" 2>/dev/null || [[ -n "$first" ]] || return 1
    local re='^#![[:space:]]*([^[:space:]]*/)?(env[[:space:]]+(-[^[:space:]]*[[:space:]]+)*)?(sh|bash|dash|ksh)([[:space:]]|$)'
    [[ "$first" =~ $re ]]
}

# Check if file is a shell script
is_shell_script() {
    local file="$1"

    # Check extension
    [[ "$file" == *.sh || "$file" == *.bash ]] && return 0

    # Check shebang (first line only)
    [[ -f "$file" ]] && has_shell_shebang "$file"
}

# Build ShellCheck arguments (optional arg: output format, default $FORMAT)
build_shellcheck_args() {
    local fmt="${1:-$FORMAT}"
    # "text" is this script's name for ShellCheck's default human format (tty)
    [[ "$fmt" == "text" ]] && fmt="tty"
    local args=("-f" "$fmt" "-S" "$SEVERITY")

    $EXTERNAL && args+=("-x")

    if [[ -n "$EXCLUDE" ]]; then
        local -a codes
        local code
        IFS=',' read -ra codes <<< "$EXCLUDE"
        for code in "${codes[@]}"; do
            [[ -n "$code" ]] && args+=("-e" "$code")
        done
    fi

    printf '%s\n' "${args[@]}"
}

# Run ShellCheck on a single file
# Counts come from a json1 run so they are independent of the display format.
check_file() {
    local file="$1"
    local json result
    local exit_code=0

    TOTAL_FILES=$((TOTAL_FILES + 1))
    if $VERBOSE; then
        echo "${BLUE}Checking: $file${RESET}"
    fi

    # Build arguments
    local -a args
    mapfile -t args < <(build_shellcheck_args json1)

    # Run ShellCheck (machine-readable, for counting)
    json=$(shellcheck "${args[@]}" "$file" 2>&1) || exit_code=$?

    # 0 = clean, 1 = findings, anything else = ShellCheck itself failed
    if ((exit_code > 1)); then
        TOOL_FAILURES=$((TOOL_FAILURES + 1))
        FAILED_FILES=$((FAILED_FILES + 1))
        echo "${RED}✗${RESET} $file ${RED}(shellcheck failed with exit code $exit_code)${RESET}"
        printf '%s\n' "$json" | sed 's/^/  /'
        return 1
    fi

    count_issues "$json"

    if ((LAST_ISSUE_COUNT == 0)); then
        PASSED_FILES=$((PASSED_FILES + 1))
        $QUIET || echo "${GREEN}✓${RESET} $file"
        return 0
    fi

    FAILED_FILES=$((FAILED_FILES + 1))

    if ! $QUIET; then
        echo "${RED}✗${RESET} $file"
        # Inline details for text output to the terminal; other formats and
        # -o get a single combined report (see write_report)
        if [[ "$FORMAT" == "text" && -z "$OUTPUT" ]]; then
            mapfile -t args < <(build_shellcheck_args)
            result=$(shellcheck "${args[@]}" "$file" 2>&1) || true
            printf '%s\n' "$result" | sed 's/^/  /'
        fi
    fi

    return 1
}

# Count issues by severity from ShellCheck json1 output.
# Updates ERROR_COUNTS and sets LAST_ISSUE_COUNT (no subshell, so counts persist).
count_issues() {
    local json="$1"
    local -a levels=()
    local level

    if command -v jq &>/dev/null; then
        mapfile -t levels < <(jq -r '.comments[].level' <<<"$json" 2>/dev/null || true)
    else
        mapfile -t levels < <(grep -o '"level":"[a-z]*"' <<<"$json" | cut -d'"' -f4 || true)
    fi

    for level in "${levels[@]}"; do
        case "$level" in
            error|warning|info|style)
                ERROR_COUNTS[$level]=$((ERROR_COUNTS[$level] + 1))
                ;;
        esac
    done

    LAST_ISSUE_COUNT=${#levels[@]}
}

# Write a single combined ShellCheck report in the requested format
write_report() {
    local -a args
    mapfile -t args < <(build_shellcheck_args)

    shellcheck "${args[@]}" "$@" 2>&1 || true
}

# Print summary
print_summary() {
    local total_issues=$((ERROR_COUNTS[error] + ERROR_COUNTS[warning] + ERROR_COUNTS[info] + ERROR_COUNTS[style]))

    echo ""
    echo "${BOLD}═══════════════════════════════════════${RESET}"
    echo "${BOLD}ShellCheck Summary${RESET}"
    echo "${BOLD}═══════════════════════════════════════${RESET}"
    echo ""
    echo "Files checked:    $TOTAL_FILES"
    echo "  ${GREEN}Passed:${RESET}         $PASSED_FILES"
    echo "  ${RED}Failed:${RESET}         $FAILED_FILES"
    echo ""
    echo "Issues found:     $total_issues"
    echo "  ${RED}Errors:${RESET}         ${ERROR_COUNTS[error]}"
    echo "  ${YELLOW}Warnings:${RESET}       ${ERROR_COUNTS[warning]}"
    echo "  ${CYAN}Info:${RESET}           ${ERROR_COUNTS[info]}"
    echo "  ${BLUE}Style:${RESET}          ${ERROR_COUNTS[style]}"
    echo ""

    if ((FAILED_FILES == 0)); then
        echo "${GREEN}${BOLD}All checks passed!${RESET}"
    else
        echo "${RED}${BOLD}Some checks failed.${RESET}"
    fi

    echo "${BOLD}═══════════════════════════════════════${RESET}"
}

# Show common fixes
show_common_fixes() {
    echo ""
    echo "${BOLD}Common Fixes:${RESET}"
    echo ""
    echo "SC2086 - Quote to prevent word splitting:"
    echo "  ${RED}- echo \$var${RESET}"
    echo "  ${GREEN}+ echo \"\$var\"${RESET}"
    echo ""
    echo "SC2034 - Unused variable (prefix with _ or export):"
    echo "  ${RED}- unused_var=\"value\"${RESET}"
    echo "  ${GREEN}+ _unused_var=\"value\"${RESET}"
    echo ""
    echo "SC2155 - Declare and assign separately:"
    echo "  ${RED}- local var=\$(cmd)${RESET}"
    echo "  ${GREEN}+ local var${RESET}"
    echo "  ${GREEN}+ var=\$(cmd)${RESET}"
    echo ""
}

main() {
    parse_args "$@"
    setup_colors
    check_shellcheck

    # With a machine-readable format on stdout, keep human output on stderr
    local status_fd=1
    if [[ "$FORMAT" != "text" && -z "$OUTPUT" ]]; then
        status_fd=2
    fi

    {
        echo "${BOLD}ShellCheck Batch Analysis${RESET}"
        echo "Severity: $SEVERITY | Format: $FORMAT"
        echo ""
    } >&"$status_fd"

    # Collect all files
    declare -a all_files=()
    for path in "${PATHS[@]}"; do
        while IFS= read -r file; do
            [[ -n "$file" ]] && all_files+=("$file")
        done < <(find_scripts "$path")
    done

    if [[ ${#all_files[@]} -eq 0 ]]; then
        echo "${YELLOW}No shell scripts found.${RESET}" >&"$status_fd"
        exit 0
    fi

    {
        echo "Found ${#all_files[@]} script(s) to check"
        echo ""
    } >&"$status_fd"

    # Check all files (per-file status; counts via json1)
    local file
    for file in "${all_files[@]}"; do
        check_file "$file" || true
    done >&"$status_fd"

    # Combined report for non-text formats or when writing to a file
    if [[ -n "$OUTPUT" ]]; then
        write_report "${all_files[@]}" > "$OUTPUT"
        echo "Report written to: $OUTPUT" >&"$status_fd"
    elif [[ "$FORMAT" != "text" ]]; then
        write_report "${all_files[@]}"
    fi

    # Print summary
    print_summary >&"$status_fd"

    # Show fix suggestions
    if $SHOW_FIX; then
        show_common_fixes >&"$status_fd"
    fi

    # Exit code
    if ((TOOL_FAILURES > 0)); then
        exit 1
    fi

    if $CI_MODE; then
        # In CI mode, only fail on errors (not warnings/info/style)
        if ((ERROR_COUNTS[error] > 0)); then
            exit 1
        fi
        exit 0
    else
        # Fail on any finding at or above the selected severity
        if ((FAILED_FILES > 0)); then
            exit 1
        fi
        exit 0
    fi
}

main "$@"
