#!/usr/bin/env bash
# Grep triage pass for WordPress performance anti-patterns.
# TRIAGE ONLY — it ranks where to look first. It never replaces the
# full-file read pass; patterns with no literal signature are invisible to it.
# Usage: wp-perf-scan.sh [target-dir]

set -uo pipefail

TARGET="${1:-.}"
EXCLUDES=( --exclude-dir=node_modules --exclude-dir=vendor --exclude-dir=.git
           --exclude-dir=dist --exclude-dir=build --exclude-dir=coverage
           --exclude=*.min.js --exclude=*.min.css )

hits=0

scan() {
  local severity="$1" label="$2" pattern="$3"
  local out
  out=$(grep -rnE "${EXCLUDES[@]}" -- "$pattern" "$TARGET" 2>/dev/null)
  [ -z "$out" ] && return 0
  echo "[$severity] $label"
  printf '%s\n' "$out" | sed 's/^/  /'
  echo
  hits=$((hits + $(printf '%s\n' "$out" | wc -l)))
}

echo "=== CRITICAL ==="
scan CRITICAL "Unbounded query"            "(posts_per_page|numberposts)[^;]*-1"
scan CRITICAL "query_posts()"              "query_posts[[:space:]]*\("
scan CRITICAL "PHP session (cache bypass)" "session_start[[:space:]]*\("
scan CRITICAL "Polling / self-DDoS"        "setInterval[^;]*(fetch|ajax|\\\$\.)"

echo "=== WARNING ==="
scan WARNING "Option writes (check for frontend context)" "(update_option|add_option)[[:space:]]*\("
scan WARNING "Uncached expensive core calls" "(url_to_postid|attachment_url_to_postid|count_user_posts|wp_oembed_get)[[:space:]]*\("
scan WARNING "External HTTP (check caching + timeout)" "(wp_remote_get|wp_remote_post|file_get_contents[[:space:]]*\([[:space:]]*['\"]https?)"
scan WARNING "Cookies / cache bypass"      "setcookie[[:space:]]*\("
scan WARNING "Query cache disabled"        "cache_results[^;]*false"
scan WARNING "Leading-wildcard LIKE"       "LIKE[[:space:]]*['\"]?%"
scan WARNING "post__not_in exclusion"      "post__not_in"
scan WARNING "meta_query value comparison" "'value'[[:space:]]*=>"
scan WARNING "Dynamic transient keys"      "set_transient[[:space:]]*\([^)]*\\\$"
scan WARNING "Cron schedule without guard" "wp_schedule_event[[:space:]]*\("
scan WARNING "Full lodash import"          "import[[:space:]]+.*from[[:space:]]*['\"]lodash['\"]"
scan WARNING "AJAX POST for reads"         "\\\$\.post[[:space:]]*\("
scan WARNING "admin-ajax.php"              "admin-ajax\.php"
scan WARNING "Heredoc/nowdoc output"       "<<<[A-Z']"
scan WARNING "Block styles (iframe per style)" "registerBlockStyle"

echo "=== INFO ==="
scan INFO "Asset enqueue (verify conditional + version)" "wp_enqueue_(script|style)[[:space:]]*\("
scan INFO "in_array without strict flag"   "in_array[[:space:]]*\([^)]*\)"
scan INFO "get_template_part (check loops)" "get_template_part[[:space:]]*\("

echo "=== TRIAGE SUMMARY ==="
echo "  candidate lines: $hits"
echo "  Grep is triage. Proceed to the full-file read pass — N+1 loops,"
echo "  request-context mistakes, and missing caching have no grep signature."
