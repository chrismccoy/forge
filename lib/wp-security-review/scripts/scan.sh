#!/usr/bin/env bash
# WordPress security quick scan.
#
# Grep-based triage for WordPress themes/plugins. Every hit is a CANDIDATE,
# not a confirmed vulnerability: open each file and confirm user input reaches
# the sink and no guard exists before reporting it. Single-line regexes miss
# flows that span several lines or functions; always follow with manual review.
#
# Usage: scan.sh [target-dir] [wp-config-path]
#   target-dir      Directory to scan (default: .)
#   wp-config-path  Optional wp-config.php to check for hardening constants.
#                   If omitted, looks for target-dir/wp-config.php.
#
# Skips vendor/, vendor-prefixed/, vendor_prefixed/, node_modules/, .git/,
# build/, dist/ and *.min.js files.
# Output lines are cut at 300 characters.
# Output groups: HIGH-RISK SINK, REVIEW, HARDENING. These are search buckets,
# not severities; final severity needs a confirmed exploit path (see SKILL.md).
# Exit code: 0 (triage tool, not a gate), or 2 if target is not a directory.

# Regexes below match literal "$" (PHP variables), so single quotes are intended.
# shellcheck disable=SC2016

set -u

TARGET="${1:-.}"
WPCONFIG_ARG="${2:-}"
WPCONFIG="${2:-$TARGET/wp-config.php}"
MAXCOL=300

if [ ! -d "$TARGET" ]; then
    echo "error: '$TARGET' is not a directory" >&2
    exit 2
fi

# Resolve wp-config before cd, then scan "." so output paths stay short.
if [ -f "$WPCONFIG" ]; then
    WPCONFIG="$(cd "$(dirname "$WPCONFIG")" && pwd)/$(basename "$WPCONFIG")"
fi
echo "WordPress security scan: $(cd "$TARGET" && pwd)"
cd "$TARGET" || exit 2
TARGET=.

EXCLUDES=(--exclude-dir=vendor --exclude-dir=node_modules --exclude-dir=.git
          --exclude-dir=build --exclude-dir=dist --exclude-dir=vendor-prefixed
          --exclude-dir=vendor_prefixed --exclude='*.min.js')
PHP=(--include='*.php')
JS=(--include='*.js' --include='*.jsx' --include='*.ts' --include='*.tsx')

# Shared awk snippet: drop "file:line:" prefix into variable `line`.
STRIP_PREFIX='line = $0; sub(/^[^:]*:[0-9]+:/, "", line)'

# emit SEVERITY LABEL OUTPUT
emit() {
    if [ -n "$3" ]; then
        printf '\n[%s] %s\n' "$1" "$2"
        printf '%s\n' "$3" | cut -c1-"$MAXCOL"
    fi
}

# grep_php / grep_js REGEX: recursive line grep with excludes.
grep_lang() {
    local regex="$1"
    shift
    grep -rnE "$@" "${EXCLUDES[@]}" -- "$regex" "$TARGET" 2>/dev/null
}

# hit SEVERITY LABEL REGEX [extra grep args...]
hit() {
    local sev="$1" label="$2" regex="$3"
    shift 3
    emit "$sev" "$label" "$(grep_lang "$regex" "$@")"
}

# hit_filtered SEVERITY LABEL REGEX EXCLUDE_REGEX [extra grep args...]
# Same as hit, but drops lines matching EXCLUDE_REGEX (same-line guard only).
hit_filtered() {
    local sev="$1" label="$2" regex="$3" exclude="$4"
    shift 4
    emit "$sev" "$label" "$(grep_lang "$regex" "$@" | grep -vE -- "$exclude")"
}

# Superglobal reads where the value is used, not only tested. Strips
# isset()/empty()/nonce-check calls from each line first, then reports the
# line if a superglobal is still present and no sanitizer is on the line.
raw_input_hits() {
    grep_lang '\$_(GET|POST|REQUEST|COOKIE)\[' "${PHP[@]}" \
    | awk "{ $STRIP_PREFIX"'
        gsub(/(isset|empty|wp_verify_nonce|check_admin_referer|check_ajax_referer)[ \t]*\([^()]*(\([^()]*\)[^()]*)*\)/, "", line)
        if (line ~ /\$_(GET|POST|REQUEST|COOKIE)\[/ &&
            line !~ /(sanitize_|absint|intval|floatval|\(int\)|\(bool\)|esc_|wp_kses)/)
            print
    }'
}

# $wpdb query methods called without prepare() on the same line. Prints
# "C<TAB>line" when a variable is interpolated or concatenated (HIGH-RISK SINK
# candidate) or "W<TAB>line" when the only argument is one variable such as
# $sql (REVIEW: confirm it came from prepare()). Hardcoded SQL is dropped.
raw_query_hits() {
    grep_lang '\$wpdb->(query|get_results|get_var|get_row|get_col)\s*\(' "${PHP[@]}" \
    | grep -vE 'prepare\s*\(' \
    | awk "{ $STRIP_PREFIX"'
        single = (line ~ /\$wpdb->(query|get_results|get_var|get_row|get_col)[ \t]*\([ \t]*\$[a-zA-Z_][a-zA-Z0-9_]*[ \t]*[,)]/)
        gsub(/\{?\$wpdb->[a-zA-Z_]+\}?/, " ", line)
        if (line !~ /\$[a-zA-Z_{]/) next
        print (single ? "W" : "C") "\t" $0
    }'
}

# prepare() calls with a variable in the format string, or SQL string lines
# (multi-line prepare/query calls) holding a variable. Strips trusted
# $wpdb->table properties first so "FROM {$wpdb->posts}" is not reported.
prepare_interp_hits() {
    grep_lang '(prepare\s*\(|^\s*"(SELECT|UPDATE|DELETE|INSERT|REPLACE)\b)' "${PHP[@]}" \
    | awk -v q="'" "
    BEGIN {
        sq_concat = \"prepare[ \\t]*\\\\([ \\t]*\" q \"[^\" q \"]*\" q \"[ \\t]*\\\\.[ \\t]*\\\\$\"
    }
    { $STRIP_PREFIX"'
        # Properties only: a name followed by "(" is a method call, keep it.
        gsub(/\{?\$wpdb->[a-zA-Z_]+\}?([^a-zA-Z_(]|$)/, " ", line)
        if (line ~ /prepare[ \t]*\([ \t]*"[^"]*\$[a-zA-Z_{]/ ||
            line ~ /prepare[ \t]*\([ \t]*"[^"]*"[ \t]*\.[ \t]*\$/ ||
            line ~ sq_concat ||
            line ~ /^[ \t]*"(SELECT|UPDATE|DELETE|INSERT|REPLACE)[^"]*\$[a-zA-Z_{]/)
            print
    }'
}

# include/require with a variable path, after removing safe base paths.
# Lines already reported by the HIGH-RISK "include from request data" check
# are skipped. SG is defined before this function runs.
include_var_hits() {
    grep_lang "(^|[^a-zA-Z0-9_'\"])(include|require)(_once)?(\s|\()[^;]*\\\$" "${PHP[@]}" \
    | grep -vE "(^|[^a-zA-Z0-9_'\"])(include|require)(_once)?(\\s|\\()[^;]*${SG}" \
    | awk "{ $STRIP_PREFIX"'
        gsub(/(__DIR__|__FILE__|ABSPATH|WPINC|WP_PLUGIN_DIR|WP_CONTENT_DIR|plugin_dir_path[ \t]*\([^)]*\)|dirname[ \t]*\([^)]*\)|get_template_directory[ \t]*\([ \t]*\)|get_stylesheet_directory[ \t]*\([ \t]*\))/, "", line)
        if (line ~ /(include|require)(_once)?[ \t(][^;]*\$[a-zA-Z_]/) print
    }'
}

# JS requests whose nonce is not within the next 8 lines (multi-line calls).
js_nonce_hits() {
    local f
    while IFS= read -r f; do
        awk -v f="$f" '
        { L[NR] = $0 }
        END {
            for (i = 1; i <= NR; i++) {
                if (L[i] !~ /(fetch[ \t]*\(|\$\.(ajax|post)[ \t]*\(|jQuery\.(ajax|post)[ \t]*\()/) continue
                ok = 0
                for (j = i; j <= i + 8 && j <= NR; j++)
                    if (L[j] ~ /(nonce|X-WP-Nonce|apiFetch)/) { ok = 1; break }
                if (!ok) print f ":" i ":" L[i]
            }
        }' "$f"
    done < <(grep -rlE "${JS[@]}" "${EXCLUDES[@]}" -- '(fetch\s*\(|\$\.(ajax|post)\s*\(|jQuery\.(ajax|post)\s*\()' "$TARGET" 2>/dev/null)
}

php_files() {
    grep -rlE "${PHP[@]}" "${EXCLUDES[@]}" -- '<\?php' "$TARGET" 2>/dev/null
}

SG='\$_(GET|POST|REQUEST|COOKIE)'
ESCAPED='(esc_(html|attr|url|js|textarea|xml)|wp_kses|wp_json_encode|absint|intval|floatval|number_format|count\s*\()'

echo "Candidates only. Verify data flow before reporting."

# --- HIGH-RISK SINK -------------------------------------------------------

rq=$(raw_query_hits)
emit "HIGH-RISK SINK" "SQL query without prepare(), variable in SQL (CWE-89)" \
    "$(printf '%s\n' "$rq" | awk -F'\t' '$1 == "C" { print $2 }')"
rq_warn=$(printf '%s\n' "$rq" | awk -F'\t' '$1 == "W" { print $2 }')

emit "HIGH-RISK SINK" "Variable inside prepare() format string or SQL string; confirm user-controlled (CWE-89)" \
    "$(prepare_interp_hits)"

hit_filtered "HIGH-RISK SINK" "Request data echoed (CWE-79)" \
    "(^|[^a-zA-Z0-9_])(echo|print|printf)\b[^;]*${SG}" "$ESCAPED" "${PHP[@]}"

emit "HIGH-RISK SINK" "Variable echoed without esc_* / wp_kses; confirm not trusted (CWE-79)" \
    "$(grep_lang '((^|[^a-zA-Z0-9_])(echo|print|printf)\b[^;]*\$[a-zA-Z_]|<\?=\s*\$)' "${PHP[@]}" \
        | grep -vE "$ESCAPED" | grep -vE "$SG")"

hit "HIGH-RISK SINK" "eval() (CWE-95)" '(^|[^a-zA-Z0-9_>:$])eval\s*\(' "${PHP[@]}" "${JS[@]}"

hit "HIGH-RISK SINK" "Shell execution function (CWE-78)" \
    '(^|[^a-zA-Z0-9_>:$])(exec|shell_exec|system|passthru|popen|proc_open)\s*\(' "${PHP[@]}"

# PHP backticks interpolate $var; JS template literals use ${...}.
hit_filtered "HIGH-RISK SINK" "Backtick shell execution (CWE-78)" \
    '=\s*`[^`]*\$[a-zA-Z_]' '\$\{' "${PHP[@]}"

# Unquoted esc_sql() is often used plugin-wide; past 30 hits, print per-file
# counts and the first 15 lines so the output stays readable.
escsql_out="$(grep_lang "(=|<|>|\\bIN\\s*\\(|\\bLIMIT|\\bOFFSET)\\s*[\"']\\s*\\.\\s*esc_sql\\s*\\(" "${PHP[@]}")"
if [ "$(printf '%s' "$escsql_out" | grep -c .)" -gt 30 ]; then
    escsql_out="$(printf '%s\n' "$escsql_out" | cut -d: -f1 | sort | uniq -c | sort -rn
                  echo "first 15:"; printf '%s\n' "$escsql_out" | head -n 15)"
fi
emit "HIGH-RISK SINK" "esc_sql() value outside quotes; esc_sql escapes quotes only; trace which ids come from requests (CWE-89)" "$escsql_out"

hit "HIGH-RISK SINK" "unserialize on request data (CWE-502)" \
    "(unserialize|maybe_unserialize)\s*\(\s*(wp_unslash\s*\(\s*)?(base64_decode\s*\(\s*)?${SG}" "${PHP[@]}"

hit "HIGH-RISK SINK" "Decoded data passed to eval/unserialize/include/file write (CWE-95/CWE-502)" \
    '(^|[^a-zA-Z0-9_>:$])(eval|unserialize|maybe_unserialize|file_put_contents|include|require)(_once)?\s*\(?[^;]*base64_decode\s*\(' "${PHP[@]}"

hit "HIGH-RISK SINK" "wp_handle_upload test_type disabled (CWE-434)" \
    "test_type['\"]\]?\s*=>?\s*(false|0)\b" "${PHP[@]}"

hit "HIGH-RISK SINK" "Raw move_uploaded_file(), use wp_handle_upload() (CWE-434)" \
    'move_uploaded_file\s*\(' "${PHP[@]}"

hit "HIGH-RISK SINK" "Dynamic include from request data (CWE-22)" \
    "(^|[^a-zA-Z0-9_'\"])(include|require)(_once)?(\s|\()[^;]*${SG}" "${PHP[@]}"

hit "HIGH-RISK SINK" "File read/delete with request data in path (CWE-22/CWE-73)" \
    "(^|[^a-zA-Z0-9_>:])(file_get_contents|readfile|fopen|file|unlink|wp_delete_file|rmdir|copy|rename)\s*\([^;]*${SG}" "${PHP[@]}"

hit "HIGH-RISK SINK" "update_option() name from request data (CWE-269)" \
    "update_(site_)?option\s*\(\s*([a-z_]+\s*\(\s*)*${SG}" "${PHP[@]}"

hit "HIGH-RISK SINK" "Role or capabilities set from request data (CWE-269)" \
    "((set_role|add_role|add_cap)\s*\([^;]*${SG}|['\"]role['\"]\s*=>\s*[^,)]*${SG}|capabilities['\"]?\s*,[^;]*${SG})" "${PHP[@]}"

hit "HIGH-RISK SINK" "DOM XSS sink (CWE-79)" \
    '(\.(inner|outer)HTML\s*\+?=[^=]|dangerouslySetInnerHTML|document\.write\s*\(|insertAdjacentHTML\s*\(|\.html\s*\(\s*[^)[:space:]])' "${JS[@]}"

hit "HIGH-RISK SINK" "new Function() code construction (CWE-95)" 'new\s+Function\s*\(' "${JS[@]}"

hit "HIGH-RISK SINK" "permission_callback => null (route is public) (CWE-862)" \
    "permission_callback['\"]\s*=>\s*null" "${PHP[@]}"

# REST routes: args span many lines, so compare counts per file. One route can
# hold several endpoints, so count 'methods' keys too and use the larger.
rest_out=""
while IFS= read -r f; do
    routes=$(grep -cE 'register_rest_route\s*\(' "$f")
    methods=$(grep -cE "['\"]methods['\"]\s*=>" "$f")
    endpoints=$(( methods > routes ? methods : routes ))
    perms=$(grep -E "['\"]permission_callback['\"]\s*=>" "$f" | grep -cvE '=>\s*null')
    if [ "$perms" -lt "$endpoints" ]; then
        rest_out+="$f: $endpoints endpoint(s), $perms non-null permission_callback"$'\n'
    fi
done < <(grep -rlE "${PHP[@]}" "${EXCLUDES[@]}" -- 'register_rest_route\s*\(' "$TARGET" 2>/dev/null)
emit "HIGH-RISK SINK" "REST endpoint(s) possibly missing permission_callback (CWE-862)" "$rest_out"

# --- REVIEW ---------------------------------------------------------------

emit REVIEW "SQL query called with one variable; confirm it came from prepare() (CWE-89)" "$rq_warn"

hit REVIEW "permission_callback => __return_true (OK only on public GET routes)" \
    "permission_callback['\"]\s*=>\s*['\"]__return_true" "${PHP[@]}"

hit_filtered REVIEW "check_ajax_referer(..., false) with result not tested on same line (CWE-352)" \
    'check_ajax_referer\s*\([^;]*,\s*false\s*\)' '(if\s*\(|!\s*check_ajax_referer)' "${PHP[@]}"

hit REVIEW "is_admin() check; OK for loading admin code, CRITICAL if it gates a state change (true on admin-ajax.php)" \
    'if\s*\(\s*!?\s*is_admin\s*\(\s*\)' "${PHP[@]}"

emit REVIEW "Request data used without sanitize_* / cast on same line (CWE-20)" "$(raw_input_hits)"

hit REVIEW "Public AJAX handler (wp_ajax_nopriv_); nonce is not protection, confirm rate limit/CAPTCHA" \
    "add_action\s*\(\s*['\"]wp_ajax_nopriv_" "${PHP[@]}"

# Files that register handlers but never check capability or nonce.
handler_out=""
while IFS= read -r f; do
    has_cap=$(grep -cE 'current_user_can\s*\(' "$f")
    has_nonce=$(grep -cE '(wp_verify_nonce|check_admin_referer|check_ajax_referer)\s*\(' "$f")
    if [ "$has_cap" -eq 0 ] || [ "$has_nonce" -eq 0 ]; then
        handler_out+="$f: current_user_can=$has_cap nonce_checks=$has_nonce"$'\n'
    fi
done < <(grep -rlE "${PHP[@]}" "${EXCLUDES[@]}" -- "add_action\s*\(\s*['\"](wp_ajax_|admin_post_)" "$TARGET" 2>/dev/null)
emit REVIEW "Handler file with no capability check or no nonce check (CWE-352/CWE-862)" "$handler_out"

hit_filtered REVIEW "LIKE wildcard concatenated without esc_like()" \
    "['\"]%['\"]\s*\.\s*\\\$" 'esc_like' "${PHP[@]}"

hit_filtered REVIEW "unserialize() on stored data; check who can write the value (second-order, CWE-502)" \
    '(^|[^a-zA-Z0-9_])(maybe_)?unserialize\s*\(' "(${SG}|base64_decode)" "${PHP[@]}"

emit REVIEW "include/require with variable path; confirm not user-controlled (CWE-22)" "$(include_var_hits)"

emit REVIEW "JS request with no nonce in next 8 lines (CWE-352)" "$(js_nonce_hits)"

# --- HARDENING ------------------------------------------------------------

# PHP files lacking an ABSPATH guard in their first 30 lines.
abspath_out=""
while IFS= read -r f; do
    if ! head -n 30 "$f" | grep -qE 'ABSPATH|WPINC|WP_UNINSTALL_PLUGIN'; then
        abspath_out+="$f"$'\n'
    fi
done < <(php_files)
emit HARDENING "PHP file without ABSPATH/WPINC/WP_UNINSTALL_PLUGIN guard in first 30 lines" "$abspath_out"

hit_filtered HARDENING "base64_decode() (possible backdoor indicator; CRITICAL if output reaches eval/unserialize/include)" \
    'base64_decode\s*\(' '(eval|unserialize|include|require|file_put_contents)' "${PHP[@]}"

# print_r( $x, true ) and var_export( $x, true ) return a string; not output.
hit HARDENING "Debug output left in code" \
    '(var_dump\s*\(|(print_r|var_export)\s*\([^,)]*\))' "${PHP[@]}"

if [ -n "$WPCONFIG_ARG" ] && [ ! -f "$WPCONFIG" ]; then
    printf '\n[HARDENING] wp-config not found: %s (constants not checked)\n' "$WPCONFIG_ARG"
fi

if [ -f "$WPCONFIG" ]; then
    # Ignore commented-out lines.
    active=$(grep -vE '^\s*(//|#|/?\*)' "$WPCONFIG")
    defined_true() {
        printf '%s\n' "$active" | grep -qiE "define\s*\(\s*['\"]$1['\"]\s*,\s*true"
    }
    defined_false() {
        printf '%s\n' "$active" | grep -qiE "define\s*\(\s*['\"]$1['\"]\s*,\s*false"
    }
    missing=""
    for c in DISALLOW_FILE_EDIT FORCE_SSL_ADMIN DISALLOW_UNFILTERED_HTML; do
        defined_true "$c" || missing+=" $c"
    done
    if printf '%s\n' "$active" | grep -q 'put your unique phrase here'; then
        printf '\n[HARDENING] %s: placeholder auth keys/salts (wp_salt() falls back to DB salts; set explicit keys)\n' "$WPCONFIG"
    fi
    if [ -n "$missing" ]; then
        printf '\n[HARDENING] %s: hardening constants not set to true:%s\n' "$WPCONFIG" "$missing"
    fi
    if defined_true WP_DEBUG && ! defined_false WP_DEBUG_DISPLAY; then
        printf '\n[HARDENING] %s: WP_DEBUG on without WP_DEBUG_DISPLAY false; errors print to pages (WARNING on production)\n' "$WPCONFIG"
    fi
    if defined_true WP_DEBUG_LOG; then
        printf '\n[HARDENING] %s: WP_DEBUG_LOG true writes web-readable wp-content/debug.log; use a path outside web root\n' "$WPCONFIG"
    fi
fi

echo
echo "Scan done."
