#!/usr/bin/env bash
#
# example-task: one-line description of what this script does across every
# WordPress install under a sites root.
#
# Usage: example-task.sh [options]
#   -r DIR   sites root to scan           (default: $HOME/webapps, env SITES_ROOT)
#   -s SITE  only this site: a folder name under the root, or a path
#   -m N     max depth to look for wp-config.php (default: 2, env MAX_DEPTH)
#   -f       apply changes (without -f the script is a dry run)
#   -y       skip the confirmation prompt (for cron; only with -f)
#   -q       quiet: only warnings, errors and the summary
#   -h       help
#
# Exit codes: 0 all good, 1 usage or setup error, 2 one or more sites failed.

set -euo pipefail

readonly PROG="${0##*/}"

SITES_ROOT="${SITES_ROOT:-$HOME/webapps}"
MAX_DEPTH="${MAX_DEPTH:-2}"
WP_CLI="${WP_CLI:-wp}"
ONLY_SITE=""
APPLY=0
ASSUME_YES=0
QUIET=0
INTERRUPTED=0
LOCK_DIR=""

SUMMARY_ROWS=()
FOUND=0
CHANGED=0
UNCHANGED=0
FAILED=0

if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
  C_RED=$'\033[0;31m' C_GREEN=$'\033[0;32m' C_YELLOW=$'\033[0;33m'
  C_CYAN=$'\033[0;36m' C_BOLD=$'\033[1m' C_RESET=$'\033[0m'
else
  C_RED='' C_GREEN='' C_YELLOW='' C_CYAN='' C_BOLD='' C_RESET=''
fi

log()  { (( QUIET )) || printf '%s[INFO]%s  %s\n' "$C_CYAN" "$C_RESET" "$*" >&2; }
ok()   { (( QUIET )) || printf '%s[OK]%s    %s\n' "$C_GREEN" "$C_RESET" "$*" >&2; }
warn() { printf '%s[WARN]%s  %s\n' "$C_YELLOW" "$C_RESET" "$*" >&2; }
die()  { printf '%s[ERROR]%s %s\n' "$C_RED" "$C_RESET" "$*" >&2; exit 1; }

usage() {
  sed -n '6,15p' "$0" | sed 's/^# \{0,1\}//'
  exit "${1:-0}"
}

add_row() { SUMMARY_ROWS+=("$(printf '%s\t%s' "$1" "$2")"); }

print_summary() {
  local row site status header="SUMMARY"
  (( INTERRUPTED )) && header="SUMMARY (interrupted, partial results)"
  printf '\n%s%s%s\n' "$C_BOLD" "$header" "$C_RESET"
  printf '%-32s %s\n' "SITE" "STATUS"
  printf '%-32s %s\n' "--------------------------------" "------"
  for row in ${SUMMARY_ROWS[@]+"${SUMMARY_ROWS[@]}"}; do
    IFS=$'\t' read -r site status <<< "$row"
    printf '%-32s %s\n' "$site" "$status"
  done
  printf '\nsites: %d | %s: %d | unchanged: %d | failed: %d\n' \
    "$FOUND" "$( (( APPLY )) && echo changed || echo 'would change')" \
    "$CHANGED" "$UNCHANGED" "$FAILED"
  (( APPLY )) || printf '%sDry run: nothing was changed. Re-run with -f to apply.%s\n' "$C_YELLOW" "$C_RESET"
}

SUMMARY_ARMED=0

# One EXIT trap does everything: print the summary once the site loop has
# started, then release the lock. A second `trap ... EXIT` would replace it.
on_exit() {
  local rc=$?
  (( SUMMARY_ARMED )) && print_summary
  [[ -n "$LOCK_DIR" && -d "$LOCK_DIR" ]] && rmdir "$LOCK_DIR" 2>/dev/null
  return "$rc"
}
on_interrupt() { INTERRUPTED=1; warn "interrupted, finishing with a partial summary"; }
trap on_exit EXIT
trap on_interrupt INT TERM

acquire_lock() {
  local key
  key="$(printf '%s' "$SITES_ROOT" | cksum | cut -d' ' -f1)"
  LOCK_DIR="${TMPDIR:-/tmp}/${PROG}.${key}.lock"
  mkdir "$LOCK_DIR" 2>/dev/null \
    || { LOCK_DIR=""; die "another $PROG run holds the lock. Remove ${TMPDIR:-/tmp}/${PROG}.${key}.lock if stale."; }
}

# Run WP-CLI against one install. Output on stdout, errors on stderr, exit
# status preserved. Add --skip-plugins/--skip-themes only for tasks that do
# not need them loaded (see references/fleet.md).
wp_run() {
  local wp_path="$1"; shift
  local -a flags=(--path="$wp_path" --no-color --quiet)
  (( EUID == 0 )) && flags+=(--allow-root)
  "$WP_CLI" "$@" "${flags[@]}"
}

# Print one install root per line, shallowest first, skipping copies that
# live inside dependency, backup, or cache folders.
find_installs() {
  find "$SITES_ROOT" -maxdepth "$MAX_DEPTH" -type f -name wp-config.php \
    -not -path '*/node_modules/*' -not -path '*/vendor/*' \
    -not -path '*/backup*/*' -not -path '*/.git/*' 2>/dev/null \
    | awk -F/ '{ print NF "\t" $0 }' | sort -n | cut -f2- \
    | while IFS= read -r cfg; do dirname "$cfg"; done
}

resolve_site() {
  local target="$1"
  [[ "$target" == /* ]] || target="${SITES_ROOT}/${target}"
  [[ -f "${target}/wp-config.php" ]] || die "no wp-config.php in $target"
  (cd "$target" && pwd)
}

# The task itself. Return 0 = changed (or would change), 1 = failed,
# 3 = nothing to do. Never exit from here; the loop must keep going.
process_site() {
  local wp_path="$1" site current
  site="$(basename "$wp_path")"

  if ! current="$(wp_run "$wp_path" option get blog_public 2>/dev/null)"; then
    warn "[$site] could not read blog_public"
    add_row "$site" "FAILED (wp-cli error)"
    return 1
  fi

  if [[ "$current" == "0" ]]; then
    add_row "$site" "unchanged (already private)"
    return 3
  fi

  if (( ! APPLY )); then
    log "[$site] would set blog_public $current -> 0"
    add_row "$site" "would change (blog_public $current -> 0)"
    return 0
  fi

  if ! wp_run "$wp_path" option update blog_public 0 >/dev/null; then
    warn "[$site] update failed"
    add_row "$site" "FAILED (update error)"
    return 1
  fi

  # Verify: read the value back rather than trusting the write.
  if [[ "$(wp_run "$wp_path" option get blog_public 2>/dev/null)" != "0" ]]; then
    warn "[$site] update reported success but blog_public is not 0"
    add_row "$site" "FAILED (not verified)"
    return 1
  fi
  ok "[$site] blog_public set to 0 (verified)"
  add_row "$site" "changed, verified (blog_public $current -> 0)"
  return 0
}

main() {
  local opt wp_path rc
  local -a installs=()

  while getopts ':r:s:m:fyqh' opt; do
    case "$opt" in
      r) SITES_ROOT="$OPTARG" ;;
      s) ONLY_SITE="$OPTARG" ;;
      m) MAX_DEPTH="$OPTARG" ;;
      f) APPLY=1 ;;
      y) ASSUME_YES=1 ;;
      q) QUIET=1 ;;
      h) usage 0 ;;
      :) die "option -$OPTARG needs a value" ;;
      \?) warn "unknown option -$OPTARG"; usage 1 ;;
    esac
  done
  shift $((OPTIND - 1))
  (( $# == 0 )) || { warn "unexpected argument: $1"; usage 1; }

  [[ "$MAX_DEPTH" =~ ^[0-9]+$ ]] || die "-m must be a whole number"
  command -v "$WP_CLI" >/dev/null 2>&1 || die "wp-cli not found (set WP_CLI to its path)"
  [[ -d "$SITES_ROOT" ]] || die "sites root not found: $SITES_ROOT"
  SITES_ROOT="$(cd "$SITES_ROOT" && pwd)"

  if [[ -n "$ONLY_SITE" ]]; then
    installs=("$(resolve_site "$ONLY_SITE")")
  else
    mapfile -t installs < <(find_installs)
  fi
  (( ${#installs[@]} > 0 )) || die "no WordPress installs found under $SITES_ROOT (depth $MAX_DEPTH)"

  if (( APPLY && ! ASSUME_YES )); then
    [[ -t 0 ]] || die "refusing to apply without a terminal; add -y to confirm"
    printf '%sThis will change %d site(s) under %s.%s\nType yes to continue: ' \
      "$C_RED" "${#installs[@]}" "$SITES_ROOT" "$C_RESET" >&2
    read -r reply
    [[ "$reply" == "yes" ]] || { log "cancelled, nothing changed"; exit 0; }
  fi

  acquire_lock
  SUMMARY_ARMED=1

  local total=${#installs[@]} n=0
  for wp_path in "${installs[@]}"; do
    (( INTERRUPTED )) && break
    n=$((n + 1))
    log "[$n/$total] $(basename "$wp_path")"
    if ! wp_run "$wp_path" core is-installed >/dev/null 2>&1; then
      warn "[$(basename "$wp_path")] not an installed WordPress (or DB error), skipped"
      add_row "$(basename "$wp_path")" "SKIPPED (not installed / DB error)"
      continue
    fi
    FOUND=$((FOUND + 1))
    rc=0
    process_site "$wp_path" || rc=$?
    case "$rc" in
      0) CHANGED=$((CHANGED + 1)) ;;
      3) UNCHANGED=$((UNCHANGED + 1)) ;;
      *) FAILED=$((FAILED + 1)) ;;
    esac
  done

  (( FAILED == 0 )) || exit 2
}

main "$@"
