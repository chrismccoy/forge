#!/usr/bin/env bash
# wp-sec-scan.sh - fast candidate finder for WordPress security review.
#
# Usage: wp-sec-scan.sh [path]      path = directory or single file (default: .)
#
# Prints hits grouped by check, tagged with the default severity, CRITICAL first.
# Only checks with hits are printed. Every hit is a CANDIDATE: confirm it by
# reading the surrounding code. Line-based grep cannot see most multi-line
# constructs, so REST route arrays and hook callback bodies still need a manual read.
#
# If phpcs with the WordPress standard is installed, also runs the
# WordPress security / DB sniffs (AST-aware, fewer false positives).
#
# Exit status: 0 = no CRITICAL candidates, 1 = CRITICAL candidates found,
#              2 = usage or environment error (including unreadable files:
#                  results are then incomplete).
# Requires GNU grep (PCRE, -P). On macOS: `brew install grep` (provides ggrep).
#
# Severity tags are candidate defaults. Heuristic checks that often match safe
# code (is_admin/is_user_logged_in guards, token ==, weak randomness, public GET
# routes, non-echo output sinks, unescaped variable echoes) are reported as WARNING even where SKILL.md rates
# the confirmed issue CRITICAL. Escalate after reading the code.
#
# wp-config.php: checked when [path] is a directory containing it, or is the
# file itself. Set WP_SEC_SCAN_PARENT_CONFIG=1 to also check [path]/../wp-config.php.

set -u
ROOT="${1:-.}"
[ -e "$ROOT" ] || { echo "No such file or directory: $ROOT" >&2; exit 2; }

CFG=""
if [ -f "$ROOT" ] && [ "$(basename "$ROOT")" = wp-config.php ]; then
  CFG="$ROOT"
elif [ -f "$ROOT/wp-config.php" ]; then
  CFG="$ROOT/wp-config.php"
elif [ "${WP_SEC_SCAN_PARENT_CONFIG:-0}" = 1 ] && [ -f "$ROOT/../wp-config.php" ]; then
  CFG="$ROOT/../wp-config.php"
fi

# --- GNU grep with PCRE is required; fail loudly instead of reporting nothing.
GREP=""
for cand in grep ggrep; do
  if command -v "$cand" >/dev/null 2>&1 && echo 'ab' | "$cand" -qP 'a(?=b)' 2>/dev/null; then
    GREP="$cand"; break
  fi
done
[ -n "$GREP" ] || { echo "GNU grep with -P (PCRE) is required. macOS: brew install grep" >&2; exit 2; }

EXCL=(--exclude-dir=vendor --exclude-dir=node_modules --exclude-dir=.git)
PHP_INC=(--include='*.php' --include='*.inc' --include='*.phtml')
JS_INC=(--include='*.js' --include='*.jsx' --include='*.ts' --include='*.tsx' --exclude='*.min.js'
        --exclude-dir=build --exclude-dir=dist)

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
CRIT_FILE="$TMP/crit"; ERR_FILE="$TMP/err"; EMPTY_FILE="$TMP/empty"
: > "$CRIT_FILE"; : > "$ERR_FILE"; : > "$EMPTY_FILE"

# grep wrappers: -I skips binaries; errors are collected, not discarded.
php()       { "$GREP" -rIHnP "${PHP_INC[@]}" "${EXCL[@]}" "$@" "$ROOT" 2>>"$ERR_FILE"; }
js()        { "$GREP" -rIHnP "${JS_INC[@]}" "${EXCL[@]}" "$@" "$ROOT" 2>>"$ERR_FILE"; }
php_files() { "$GREP" -rIlP  "${PHP_INC[@]}" "${EXCL[@]}" "$@" "$ROOT" 2>>"$ERR_FILE"; }

# report SEVERITY TITLE   (reads hits on stdin; runs in a pipeline subshell,
# so state is kept in files)
report() {
  local sev="$1" title="$2" out
  out="$(LC_ALL=C sort -t: -k1,1 -k2,2n)"
  if [ -z "$out" ]; then echo x >> "$EMPTY_FILE"; return; fi
  printf '\n== [%s] %s\n%s\n' "$sev" "$title" "$out"
  [ "$sev" = CRITICAL ] && printf '%s\n' "$out" >> "$CRIT_FILE"
  return 0
}

# Operand that is not wrapped in an escaping/casting function.
NOESC='(?!(?:esc_\w+|wp_kses\w*|absint|intval|floatval|wp_json_encode|number_format_i18n|count|get_the_ID|sanitize_\w+)\s*\(|\((?:int|float|bool)\))'
# Variables that hold only generated placeholders (IN clauses), not user data.
PLACEHOLDER_VARS='(?:\w*placeholders?|in|\w*_in|\w*formats?|\w*table\w*|wpdb->)\b'

# ============================== CRITICAL ==============================

# Drop hits where the argument is a bare $var assigned from $wpdb->prepare() within 10 lines above.
drop_prepared() {
  local l f n var
  while IFS= read -r l; do
    if [[ $l =~ ^(.*):([0-9]+):.*\$wpdb-\>[a-z_]+[[:space:]]*\([[:space:]]*\$([A-Za-z_][A-Za-z0-9_]*)[[:space:]]*[,\)] ]]; then
      f="${BASH_REMATCH[1]}"; n="${BASH_REMATCH[2]}"; var="${BASH_REMATCH[3]}"
      # Exact name match ($sql, not $sql_safe); any later "$sql =" or "$sql .=" re-taints it.
      if awk -v s=$(( n > 10 ? n - 10 : 1 )) -v e="$n" -v v="$var" '
           NR >= s && NR < e {
             if ($0 ~ ("\\$" v "[ \t]*=[ \t]*\\$wpdb->prepare[ \t]*\\(")) found = 1
             else if ($0 ~ ("\\$" v "[ \t]*\\.?=[^=>]")) found = 0
           }
           END { exit !found }' "$f"; then
        continue
      fi
    fi
    printf '%s\n' "$l"
  done
}

php '\$wpdb->(query|get_results|get_var|get_row|get_col)\s*\(\s*+(?!\$wpdb->prepare\b)(?=[^;]*(?<!absint\()(?<!absint\( )(?<!intval\()(?<!intval\( )(?<!\(int\))(?<!\(int\) )\$(?!wpdb->))' \
  | drop_prepared | report CRITICAL "SQL: \$wpdb query with a variable and no inline prepare() (verify how \$sql was built)"

php "\\\$wpdb->prepare\\s*\\(\\s*\"[^\"]*\\\$(?!$PLACEHOLDER_VARS)|\\\$wpdb->prepare\\s*\\(\\s*([\"'])(?:(?!\\1).)*\\1\\s*\\.\\s*\\\$(?!$PLACEHOLDER_VARS)" \
  | report CRITICAL "SQL: variable interpolated/concatenated into prepare() format string"

# Multi-line prepare( ... with the format string on the next line
while IFS= read -r f; do
  awk -v F="$f" '
    pending { t=$0; gsub(/\$wpdb->/, "", t)
              gsub(/\$[A-Za-z_]*([Pp]laceholders?|[Ff]ormats?|_in)([^A-Za-z0-9_]|$)/, "", t)
              gsub(/\$in([^A-Za-z0-9_]|$)/, "", t); fmt=""
              if (match(t, /"[^"]*"/)) fmt=substr(t, RSTART, RLENGTH)
              if (fmt ~ /\$/ || t ~ /^[ \t]*["\047][^"\047]*["\047][ \t]*\.[ \t]*\$/) print F ":" NR ": " $0
              pending=0; next }
    /\$wpdb->prepare[ \t]*\([ \t]*$/ { pending=1 }
  ' "$f"
done < <(php_files '\$wpdb->prepare\s*\(\s*$') | report CRITICAL "SQL: multi-line prepare() with interpolated/concatenated format string"

# Multi-line $wpdb->query( / get_*( with a string-built query on the next line
while IFS= read -r f; do
  awk -v F="$f" '
    pending { if ($0 ~ /^[ \t]*$/) next
              t = $0; gsub(/\$wpdb->/, "", t); fmt = ""
              if (t !~ /^[ \t]*prepare/ && match(t, /"[^"]*"/)) fmt = substr(t, RSTART, RLENGTH)
              if (t !~ /^[ \t]*prepare/ && (fmt ~ /\$/ || t ~ /["\047][ \t]*\.[ \t]*\$/)) print F ":" NR ": " $0
              pending = 0; next }
    /\$wpdb->(query|get_results|get_var|get_row|get_col)[ \t]*\([ \t]*$/ { pending = 1 }
  ' "$f"
done < <(php_files '\$wpdb->(query|get_results|get_var|get_row|get_col)\s*\(\s*$') | report CRITICAL "SQL: multi-line \$wpdb query built from variables without prepare()"

php '(=|\bIN\s*\(|\bLIMIT|\bOFFSET)\s*["\x27]\s*\.\s*esc_sql\s*\(' \
  | report CRITICAL "SQL: esc_sql() on unquoted value (still injectable)"

php '\b(echo|print)\s+\$_(GET|POST|REQUEST|COOKIE|SERVER)\b|\b(echo|print)\b[^;]*[.,]\s*\$_(GET|POST|REQUEST|COOKIE|SERVER)\b|\b(wp_die|_e|_ex|printf|die|exit)\s*\(\s*\$_(GET|POST|REQUEST|COOKIE|SERVER)\b' \
  | report CRITICAL "XSS: superglobal output directly"

php '\b(echo|print)\b\s*\(?\s*(?:[^;]*?[.,]\s*)?"[^"]*\{?\$_(GET|POST|REQUEST|COOKIE|SERVER)\b' \
  | report CRITICAL "XSS: superglobal interpolated in a double-quoted echo string"


php '(\becho|\bprint|<\?=)[^;]*(?<!esc_url\()(?<!esc_url\( )(?<!esc_attr\()(?<!esc_attr\( )\b(add_query_arg|remove_query_arg)\s*\(' \
  | report CRITICAL "XSS: add_query_arg()/remove_query_arg() output echoed without esc_url()"

php '(\becho|\bprint|<\?=)[^;]*(?<!esc_url\()(?<!esc_url\( )(?<!esc_attr\()(?<!esc_attr\( )(?<!esc_html\()(?<!esc_html\( )\$_SERVER\s*\[\s*["\x27](REQUEST_URI|PHP_SELF|HTTP_REFERER|QUERY_STRING)' \
  | report CRITICAL "XSS: REQUEST_URI/PHP_SELF/HTTP_REFERER echoed without escaping"

php '^(?!\s*(//|\*|#|/\*))(?!.*["\x27][^"\x27]*\b(system|exec)\s*\([^"\x27]*["\x27]).*(?<![\w>:$])(eval|assert|exec|shell_exec|system|passthru|popen|proc_open|create_function)\s*\(' \
  | report CRITICAL "Code/command execution functions"

php '(?<![\w>:$])extract\s*\(\s*\$_(GET|POST|REQUEST|COOKIE)' \
  | report CRITICAL "extract() on superglobal"

php "preg_replace\s*\(\s*([\"'])(?:([^\w\s\\\\{(\[<])[^,]*?\2|\{[^,]*?\}|\([^,]*?\)|\[[^,]*?\]|<[^,]*?>)[a-zA-Z]*e[a-zA-Z]*\1" \
  | report CRITICAL "preg_replace() with /e modifier (legacy)"

php '^(?!.*\$wpdb)(?!\s*(//|\*|#)).*(?:^|=|\(|,|\.|\breturn)\s*`[^`]*\$[^`]*`' \
  | report CRITICAL "Backtick shell execution"

php '\b(maybe_)?unserialize\s*\([^;]*\$_(GET|POST|REQUEST|COOKIE)' \
  | report CRITICAL "Object injection: unserialize on user input"

php '\b(include|require)(_once)?\b[^;]*\$_(GET|POST|REQUEST|COOKIE)|\b(get_template_part|locate_template|load_template)\s*\([^;]*\$_(GET|POST|REQUEST|COOKIE)' \
  | report CRITICAL "File inclusion from user input (include/require/template functions)"

php 'move_uploaded_file\s*\(' \
  | report CRITICAL "Raw move_uploaded_file()"

while IFS= read -r f; do
  "$GREP" -HnP "^(?!.*\bunset\s*\().*[\"']svgz?[\"']\s*(\]|=>)" "$f" 2>>"$ERR_FILE"
done < <(php_files 'upload_mimes') | report CRITICAL "SVG enabled in upload_mimes (needs sanitizer)"

while IFS= read -r f; do
  r=$("$GREP" -c 'register_rest_route' "$f"); m=$("$GREP" -cP "[\"']methods[\"']\s*=>" "$f")
  p=$("$GREP" -c 'permission_callback' "$f"); [ "$m" -gt "$r" ] && r=$m
  [ "$p" -lt "$r" ] && echo "$f: $r endpoints (routes or 'methods' keys), $p permission_callback"
done < <(php_files 'register_rest_route\s*\(') | report CRITICAL "REST: files with fewer permission_callback keys than endpoints"

# Always-true permission callbacks, classified by the methods of the enclosing
# endpoint array (searched up to 15 lines either side; no methods = GET default).
while IFS= read -r f; do
  awk -v F="$f" '
    { L[NR]=$0 }
    END {
      for (i = 1; i <= NR; i++) {
        if (L[i] !~ /permission_callback/) continue
        if (L[i] !~ /__return_true|return[ \t]+true|=>[ \t]*true/) continue
        meth = ""
        for (j = i; j >= 1 && j >= i - 15; j--) {
          if (L[j] ~ /methods/) { meth = meth " " L[j] }
          if (j < i && L[j] ~ /register_rest_route|^[ \t]*(array[ \t]*\(|\[)[ \t]*$/) break
        }
        for (j = i + 1; j <= NR && j <= i + 15; j++) {
          if (L[j] ~ /register_rest_route|^[ \t]*\)[ \t]*,?[ \t]*$|^[ \t]*\][ \t]*,?[ \t]*$|\)[ \t]*\)[ \t]*;/) break
          if (L[j] ~ /methods/) { meth = meth " " L[j] }
        }
        ro = (meth == "" || (meth ~ /GET|READABLE/ && meth !~ /POST|PUT|PATCH|DELETE|EDITABLE|CREATABLE|DELETABLE|ALLMETHODS/))
        print (ro ? "R" : "W") "\t" F ":" i ":" L[i]
      }
    }' "$f"
done < <(php_files 'permission_callback') > "$TMP/rest"
"$GREP" -P '^W\t' "$TMP/rest" | cut -f2- \
  | report CRITICAL "REST: always-true permission on a write route"

php '(\bisset|!\s*empty)\s*\(\s*\$_(POST|GET|REQUEST)\[[^\]]+\]\s*\)\s*&&\s*!\s*wp_verify_nonce' \
  | report CRITICAL "Nonce bypass: check skipped when the field is omitted"

php '^\s*wp_verify_nonce\s*\(' \
  | report CRITICAL "Nonce bypass: wp_verify_nonce() return value ignored"

php '\bcheck_admin_referer\s*\(\s*(\)|-1\s*[,)])' \
  | report CRITICAL "Nonce bypass: check_admin_referer() without action (forged _wp_http_referer passes)"

php '\bupdate_option\s*\(\s*[^,]*\$_(GET|POST|REQUEST|COOKIE)' \
  | report CRITICAL "Privilege escalation: update_option() with user-controlled option name"

php '\b(update|add)_(user|post|term|comment)_meta\s*\(\s*[^,]+,\s*[^,]*\$_(GET|POST|REQUEST|COOKIE)' \
  | report CRITICAL "Privilege escalation: meta write with user-controlled meta key"

php "\b(wp_insert_user|wp_create_user|wp_update_user)\s*\(.*\\\$_(GET|POST|REQUEST)|[\"']role[\"']\s*=>\s*[^,;]*\\\$_(GET|POST|REQUEST)" \
  | report CRITICAL "Privilege escalation: user created/updated with request data (check role)"

php '\b(wp_insert_post|wp_update_post)\s*\(\s*(wp_unslash\s*\(\s*)?\$_(GET|POST|REQUEST)|\$wpdb->(insert|update|replace)\s*\([^,]+,\s*(wp_unslash\s*\(\s*)?\$_(GET|POST|REQUEST)' \
  | report CRITICAL "Mass assignment: request array passed to wp_insert/update_post or \$wpdb->insert/update/replace"

php '\b(wp_set_auth_cookie|wp_set_current_user)\s*\([^;]*\$_(GET|POST|REQUEST|COOKIE)' \
  | report CRITICAL "Auth bypass: login as a user ID taken from the request"

php 'LIBXML_NOENT|LIBXML_DTDLOAD' \
  | report CRITICAL "XXE: libxml external entity flags (dangerous on user-supplied XML)"

php '["\x27]phar://|\b(file_exists|is_file|is_dir|filesize|filemtime|getimagesize|fopen|file_get_contents|md5_file)\s*\(\s*(wp_unslash\s*\(\s*)?\$_(GET|POST|REQUEST|COOKIE)' \
  | report CRITICAL "phar:// deserialization / filesystem call on raw user path"

php '\b(unlink|wp_delete_file|readfile|file_get_contents|file_put_contents|copy|rename|fopen)\s*\([^;]*\$_(GET|POST|REQUEST|COOKIE)' \
  | report CRITICAL "File read/write/delete with user-controlled path"

php '\b(call_user_func(_array)?|do_action|apply_filters|do_shortcode)\s*\(\s*[^,;)]*\$_(GET|POST|REQUEST|COOKIE)|\$_(GET|POST|REQUEST|COOKIE)\[[^\]]+\]\s*\(' \
  | report CRITICAL "Arbitrary function/hook/shortcode execution from request data"

js '\b(innerHTML|outerHTML)\s*[+]?=(?!=)|document\.write(ln)?\s*\(|\bset(Timeout|Interval)\s*\(\s*[\x27"`]|insertAdjacentHTML\s*\(|dangerouslySetInnerHTML|\beval\s*\(|\bnew\s+Function\s*\(' \
  | report CRITICAL "JS: DOM XSS sinks / eval"

js '(\.html|(\)|\$\w+)\.(append|prepend|before|after|replaceWith))\s*\(\s*+((?![\x27"`)]|\$\(|jQuery\(|document\.create)|[\x27"][^\x27"]*[\x27"]\s*\+|`[^`]*\$\{)' \
  | report CRITICAL "JS: jQuery HTML sink with non-literal or concatenated argument"

[ -n "$CFG" ] && "$GREP" -HnP "put your unique phrase here" "$CFG" 2>>"$ERR_FILE" \
  | report CRITICAL "wp-config.php: default placeholder keys/salts"

# ============================== WARNING ==============================

php "<\\?(?:php\\s+echo|=)\\s*+\\(?\\s*+(?:[^?;]*?[.,]\\s*+)?$NOESC\\\$\\w|^(?!.*<\\?(php\\s+echo|=))\\s*(?:echo|print)\\b\\s*+\\(?\\s*+(?:[^;]*?[.,]\\s*+)?$NOESC\\\$\\w" \
  | report WARNING "echo/print/<?= with an unescaped variable operand (may be pre-escaped; phpcs EscapeOutput is more precise)"

php '\b(echo|print)\b\s*\(?\s*(?:[^;]*?[.,]\s*)?"[^"]*(?<!\\)\{?\$(?!_(GET|POST|REQUEST|COOKIE|SERVER)\b)\w' \
  | report WARNING "Variable interpolated in a double-quoted echo string"

php "\\\$wpdb->prepare\\s*\\(\\s*\"[^\"]*\\{?\\\$\\w*table\\w*" \
  | report WARNING "prepare() with an interpolated table variable: confirm it is built from \$wpdb->prefix, or use %i"

php "\\b(printf|vprintf|_e|_ex|wp_die|die|exit)\\s*\\(\\s*+(?:[^;]*?[.,]\\s*+)?$NOESC\\\$\\w" \
  | report WARNING "Non-echo output sink with an unescaped variable (printf/_e/wp_die/die/exit)"

php "^(?!.*\\bin_array\\s*\\([^;]*,\\s*true\\s*\\)).*\\bin_array\\s*\\([^;]*\\\$\\w*(allow|white|valid|permit|role|type|cap|status)\\w*" \
  | report WARNING "Non-strict in_array() allow-list (pass true as third argument)"

php '(\$\w*(token|nonce|secret|key|hash)\b\s*(==|!=)[^=]|(==|!=)\s*\$\w*(token|nonce|secret|key|hash)\b)' \
  | report WARNING "Token compared with ==/!= (use hash_equals)"

php '\b(rand|mt_rand|uniqid|md5\s*\(\s*(time|microtime|rand|mt_rand))\s*\(' \
  | report WARNING "Weak randomness (use wp_generate_password / random_bytes for tokens)"

php '(?i)(api[_-]?key|secret|passw(or)?d|token|bearer)\w*["\x27]?\s*(=>|=|,)\s*["\x27][A-Za-z0-9_\-\.]{16,}["\x27]|\b(sk_live_[0-9a-zA-Z]{10,}|AKIA[0-9A-Z]{16})' \
  | report WARNING "Possible hardcoded secret"

php '(upload_dir|uploads|basedir)[^;]*\.(csv|sql|zip|log|json|txt|xml|bak|gz)["\x27]|\.(csv|sql|zip|log|bak|gz)["\x27][^;]*(upload_dir|uploads)' \
  | report WARNING "File written to uploads with a fixed extension: check name is unguessable and access is controlled"

php '^(?!.*current_user_can).*\bif\s*\(.*\bis_admin\s*\(\s*\)' \
  | report WARNING "is_admin() in a condition (CRITICAL if it guards a privileged action)"

php '^(?!.*current_user_can).*\bif\s*\(.*\bis_user_logged_in\s*\(\s*\)' \
  | report WARNING "is_user_logged_in() in a condition (CRITICAL if it guards a privileged action)"

php 'check_ajax_referer\s*\([^;]*,\s*false\s*\)' \
  | report WARNING "check_ajax_referer(..., false): confirm the return value is checked"

php '\b(wp_create_nonce|wp_nonce_field|wp_nonce_url|check_ajax_referer)\s*\(\s*\)' \
  | report WARNING "Nonce call without an action (defaults to -1, shared across actions)"

"$GREP" -P '^R\t' "$TMP/rest" | cut -f2- \
  | report WARNING "REST: public GET route (OK only if every returned field is already public; else CWE-200)"

php '\bupdate_option\s*\(\s*\$' \
  | report WARNING "update_option() with variable option name: confirm allow-list"

# Redirect not followed by exit/die/return within two lines after the call closes
while IFS= read -r f; do
  awk -v F="$f" '
    function done_(t) { sub(/\/\/.*/, "", t); sub(/#.*$/, "", t); sub(/\/\*.*/, "", t)
                        return t ~ /(^|[^a-zA-Z_])(exit|die|return)([^a-zA-Z_]|$)/ }
    function depth(t,  o, c) { o = gsub(/\(/, "(", t); c = gsub(/\)/, ")", t); return o - c }
    open > 0 { open += depth($0); if (done_($0)) { open = 0; left = 0; next }
               if (open <= 0) { open = 0; left = 2 } ; next }
    left > 0 { if ($0 ~ /^[ \t]*$/) next; if (done_($0)) { left = 0; next }
               left--; if (left == 0) print hit; next }
    /(^|[^a-zA-Z_])wp_(safe_)?redirect[ \t]*\(/ {
      if (done_($0)) next
      hit = F ":" NR ":" $0; d = depth($0)
      if (d > 0) { open = d } else { left = 2 }
    }
    END { if (left > 0 || open > 0) print hit }
  ' "$f"
done < <(php_files '\bwp_(safe_)?redirect\s*\(') | report WARNING "Redirect without exit (CRITICAL if it is an access check)"

php '\bunzip_file\s*\(' \
  | report WARNING "unzip_file(): core blocks ../ entries, but check that .php files cannot land in a web-served directory"

php '\b(extractTo|PclZip)\s*\(|new\s+PclZip\b' \
  | report WARNING "Raw ZipArchive/PclZip extraction: check entry names (Zip Slip), capability, and source"

php 'HTTP_(X_FORWARDED_FOR|CLIENT_IP|X_REAL_IP|FORWARDED)' \
  | report WARNING "Client-controlled IP header (spoofable; use REMOTE_ADDR unless behind trusted proxy)"

php 'Access-Control-Allow-(Origin|Credentials)' \
  | report WARNING "CORS headers: check for reflected Origin with credentials"

php '\bwp_redirect\s*\(' \
  | report WARNING "Open redirect candidates (prefer wp_safe_redirect)"

php '\b(wp_remote_(get|post|request|head)|wp_safe_remote_(get|post|request|head)|file_get_contents|curl_init)\s*\(' \
  | report WARNING "SSRF candidates (check URL source; wp_safe_remote_* does not block 169.254.169.254)"

php '^(?!.*(sanitize_|absint|intval|floatval|\(int\)|\(float\)|wp_verify_nonce|check_(admin|ajax)_referer|esc_)).*\$_(GET|POST|REQUEST|COOKIE|SERVER|FILES)\[' \
  | report WARNING "Superglobal read without obvious sanitizer (isset/empty-only lines are noise)"

php '^(?!.*esc_).*\$(atts|attributes)\s*\[' \
  | report WARNING "Shortcode/block attributes used without esc_* on the same line"

php "add_action\s*\(\s*[\"'](admin_post_|admin_post_nopriv_|wp_ajax_|wp_ajax_nopriv_|admin_init|init|wp_loaded|template_redirect)" \
  | report WARNING "Handler/state hooks: read each callback for nonce + capability checks"

js '\b(window\.|document\.)?location(\.href)?\s*=(?!=)\s*+(?![\x27"`])' \
  | report WARNING "JS: location assigned from a variable (javascript: URL / open redirect)"

if [ -n "$CFG" ]; then
  {
    "$GREP" -HnP "define\s*\(\s*['\"]WP_DEBUG_DISPLAY['\"]\s*,\s*true" "$CFG" 2>>"$ERR_FILE"
    if "$GREP" -qP "define\s*\(\s*['\"]WP_DEBUG['\"]\s*,\s*true" "$CFG" \
       && ! "$GREP" -qP "define\s*\(\s*['\"]WP_DEBUG_DISPLAY['\"]\s*,\s*false" "$CFG"; then
      echo "$CFG: WP_DEBUG is true and WP_DEBUG_DISPLAY is not false (display defaults to on)"
    fi
  } | report WARNING "wp-config.php: debug output displayed (CWE-215)"
fi

if [ -d "$ROOT" ] && [ -f "$ROOT/wp-content/debug.log" ]; then
  echo "$ROOT/wp-content/debug.log exists (public unless blocked; CWE-532)" | report WARNING "Debug log in web root"
fi

# ============================== INFO ==============================

php '\bbase64_decode\s*\(\s*(wp_unslash\s*\(\s*)?\$_(GET|POST|REQUEST|COOKIE)' \
  | report INFO "base64_decode() on user input (severity follows the sink)"

"$GREP" -rILE "${PHP_INC[@]}" "${EXCL[@]}" 'ABSPATH|WPINC' "$ROOT" 2>>"$ERR_FILE" \
  | report INFO "PHP files without ABSPATH/WPINC guard (class-only files are lower risk)"

if [ -n "$CFG" ]; then
  for c in DISALLOW_FILE_EDIT FORCE_SSL_ADMIN DISALLOW_UNFILTERED_HTML; do
    "$GREP" -qP "define\s*\(\s*['\"]$c['\"]\s*,\s*true" "$CFG" || echo "$CFG: $c not set to true"
  done | report INFO "wp-config.php: hardening constants"
fi

# ============================== PHPCS ==============================

if command -v phpcs >/dev/null 2>&1 && phpcs -i 2>/dev/null | "$GREP" -q 'WordPress'; then
  printf '\n== [PHPCS] WordPress security sniffs\n'
  phpcs -q --report=emacs --extensions=php,inc,phtml --ignore='*/vendor/*,*/node_modules/*' \
    --standard=WordPress \
    --sniffs=WordPress.Security.EscapeOutput,WordPress.Security.NonceVerification,WordPress.Security.ValidatedSanitizedInput,WordPress.Security.SafeRedirect,WordPress.DB.PreparedSQL,WordPress.DB.PreparedSQLPlaceholders \
    "$ROOT"
else
  printf '\n(phpcs with WordPress standard not found; skipped AST-aware sniffs. Install: composer global require wp-coding-standards/wpcs)\n'
fi

CRIT=$(wc -l < "$CRIT_FILE" | tr -d ' ')
EMPTY=$(wc -l < "$EMPTY_FILE" | tr -d ' ')
printf '\n%d CRITICAL candidate line(s). %d check(s) had no hits.\n' "$CRIT" "$EMPTY"
if [ -s "$ERR_FILE" ]; then
  printf '\n== [ERROR] grep reported errors; results are incomplete:\n' >&2
  sort -u "$ERR_FILE" | head -20 >&2
  exit 2
fi
[ "$CRIT" -gt 0 ] && exit 1
exit 0
