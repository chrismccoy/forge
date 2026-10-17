#!/usr/bin/env bash
# Quick heuristic scan of a WordPress plugin directory.
# Prints candidate findings grouped by severity. Every hit needs manual
# confirmation before it goes in a review report.
#
# Usage: scan.sh <plugin-dir>
# Requires: rg (ripgrep), awk, xargs

set -u

dir="${1:-.}"
if [ ! -d "$dir" ]; then
    echo "error: '$dir' is not a directory" >&2
    exit 2
fi
command -v rg >/dev/null || { echo "error: rg (ripgrep) not installed" >&2; exit 2; }

# The PHP helpers need the CLI with the tokenizer extension (they exit 3 without it).
has_tokenizer=false
command -v php >/dev/null 2>&1 && php -r 'exit(function_exists("token_get_all") ? 0 : 3);' 2>/dev/null && has_tokenizer=true

# Globs with a slash anchor to the search root, so use **/ to also skip nested vendor dirs.
# --no-ignore --hidden: a plugin's own .gitignore must not hide files that ship.
RG=(rg --no-heading --color never --no-ignore --hidden -g '*.php' -g '!**/vendor/**' -g '!**/node_modules/**' -g '!**/tests/**' -g '!.git/**')

section() { printf '\n=== %s ===\n' "$1"; }
check()   { printf '\n--- %s\n' "$1"; }

# PHP files with no namespace declaration, NUL-separated (safe for spaces).
global_files() { "${RG[@]}" -0 --files-without-match '^\s*namespace\s+' "$dir"; }

# Header lines match core's get_file_data(): optional "<?php", then any of " \t/*#@",
# then "Field:" (case-insensitive). Values lose a trailing "*/" or "?>" like core's cleanup.
HDR='^(?:[ \t]*<\?php)?[ \t/*#@]*'
# Main plugin file = top-level PHP file with a "Plugin Name:" header.
main_file=$(rg -l -i --no-ignore --hidden --max-depth 1 -g '*.php' "${HDR}Plugin Name:" "$dir" 2>/dev/null | head -n 1)
header_val() {
    [ -n "$main_file" ] || return 0
    rg -o -i --no-filename "${HDR}$1:\s*(.+)$" -r '$1' "$main_file" | head -n 1 | tr -d '\r' \
        | sed -E 's/[[:space:]]*(\*\/|\?>).*$//; s/[[:space:]]*$//'
}

slug=$(basename "$(cd "$dir" && pwd)")
case "$slug" in
    *-main|*-master|*-trunk|*-develop|*-[0-9]*.[0-9]*) slug_note="  (looks like a checkout folder; confirm the real WordPress.org slug)";;
    *) slug_note="";;
esac
domain=$(header_val 'Text Domain')

section "CONTEXT"
echo "plugin dir:   $dir"
echo "main file:    ${main_file:-NONE FOUND (missing Plugin Name header, or drop-in/mu-plugin)}"
echo "text domain:  ${domain:-<none in header, defaults to slug>}"
echo "folder slug:  $slug$slug_note"
readme=$(find "$dir" -maxdepth 1 -iname 'readme.txt' -print -quit)
[ -n "$readme" ] && echo "readme.txt:   present ($(basename "$readme"))" || echo "readme.txt:   absent (required only for WordPress.org)"
# i18n checks compare against the header domain, or the slug when no header.
domain="${domain:-$slug}"

section "CRITICAL candidates"

check "PHP files without ABSPATH / WPINC / WP_UNINSTALL_PLUGIN guard (PLG-03)"
echo "(executes code = CRITICAL candidate; definition-only = INFO. Confirm by reading the file.)"
unguarded=$("${RG[@]}" --files-without-match "defined\s*\(\s*['\"](ABSPATH|WPINC|WP_UNINSTALL_PLUGIN)['\"]\s*\)" "$dir")
if [ -n "$unguarded" ]; then
    # Preferred: PHP tokenizer finds code or HTML outside every function/class body
    # (files are tokenized, never executed). Fallback: line-based regex heuristic.
    toplevel="$(dirname "$0")/toplevel.php"
    classified=""
    if $has_tokenizer; then
        classified=$(printf '%s\n' "$unguarded" | tr '\n' '\0' | xargs -0 php "$toplevel" 2>/dev/null)
    fi
    if [ -n "$classified" ]; then
        echo "(classified with PHP tokenizer)"
        printf '%s\n' "$classified" | awk -F'\t' '
            $2 == "executes"   { print $1 "  [executes code, line " $3 "]" }
            $2 == "definition" { print $1 "  [definition-only]" }
            $2 == "unknown"    { print $1 "  [unparseable; read manually]" }'
    else
        echo "(php tokenizer unavailable; regex heuristic, HTML inside methods may be misread as executing)"
        printf '%s\n' "$unguarded" | while IFS= read -r f; do
            # Unindented statements run when the file is requested directly: hook calls,
            # includes, output, assignments, and bare calls (mypl_boot();, MyPL::instance();).
            # declare(strict_types=1) looks like a call but executes nothing, so drop it.
            # Template output counts too: HTML after "?>" (but not "?><?php"), or a line
            # starting with a tag.
            if { rg '^(add_(action|filter|shortcode)|register_|require|include|echo|print|do_action|new |\$[A-Za-z_]+|if\s*\(|[A-Za-z_\\][A-Za-z0-9_\\]*(::[A-Za-z_][A-Za-z0-9_]*)?\s*\()' "$f" \
                    | rg -q -v '^declare\s*\('; } \
                || rg -U -q '\?>\s*([^\s<]|<[A-Za-z!/])' "$f" \
                || rg -q '^\s*<[A-Za-z!/]' "$f"; then
                echo "$f  [executes code?]"
            else
                echo "$f  [definition-only?]"
            fi
        done
    fi
fi

check "Global functions grouped by first name segment (PLG-04) - look for unprefixed groups"
global_files | xargs -0 -r rg --no-filename -o '^\s*function\s+&?\s*([A-Za-z0-9_]+)\s*\(' -r '$1' \
    | awk -F_ '{print $1"_*"}' | sort | uniq -c | sort -rn
echo "(methods declared without a visibility keyword also match; confirm global scope)"

check "Global define() constants - look for unprefixed names (PLG-04; define() ignores namespaces)"
"${RG[@]}" -n "^\s*define\s*\(\s*['\"][A-Za-z0-9_]+['\"]" "$dir"

check "Global classes in non-namespaced files (PLG-04; names starting with the slug are already prefixed and omitted)"
# Smooth_Scroll_Up or Smooth_Scroll_Up_Admin for slug smooth-scroll-up: the slug is the prefix.
slug_class=$(printf '%s' "$slug" | tr '-' '_')
global_files | xargs -0 -r rg -H -n '^\s*(abstract\s+|final\s+)?class\s+[A-Za-z0-9_]+' \
    | rg -i -v "class\s+${slug_class}(_|\b)"

check "Text domain vs slug (PLG-11)"
[ "$domain" != "$slug" ] && echo "Text Domain '$domain' != folder slug '$slug'"
case "$domain" in *_*) echo "Text Domain '$domain' contains underscores (must use dashes)";; esac

check "i18n calls using a text domain other than '$domain' (PLG-11, heuristic: lines that also contain the right domain are hidden)"
"${RG[@]}" -n "(__|_e|_x|_ex|_n|_nx|esc_html__|esc_html_e|esc_html_x|esc_attr__|esc_attr_e|esc_attr_x)\s*\(.*,\s*['\"][a-z0-9_-]+['\"]\s*\)" "$dir" \
    | rg -v "['\"]${domain}['\"]\s*\)"

check "flush_rewrite_rules calls - confirm each is in activation/deactivation only (PLG-06)"
"${RG[@]}" -n 'flush_rewrite_rules\s*\(' "$dir"

check "Files where register_rest_route count exceeds permission_callback count (PLG-13; multi-endpoint routes: check each endpoint by hand)"
"${RG[@]}" -l 'register_rest_route\s*\(' "$dir" | while IFS= read -r f; do
    routes=$(rg -c 'register_rest_route\s*\(' "$f")
    perms=$(rg -c 'permission_callback' "$f" || echo 0)
    [ "${perms:-0}" -lt "$routes" ] && echo "$f: $routes routes, ${perms:-0} permission_callback"
done

check "Post type keys over 20 chars / taxonomy names over 32 chars (PLG-06, PLG-07)"
# Output is path:line:key; the key is the text after the last colon.
"${RG[@]}" -n -H -o "register_post_type\s*\(\s*['\"]([^'\"]+)['\"]" -r '$1' "$dir" \
    | awk '{k=$0; sub(/^.*:/, "", k); if (length(k) > 20) print $0 "  (post type, " length(k) " chars)"}'
"${RG[@]}" -n -H -o "register_taxonomy\s*\(\s*['\"]([^'\"]+)['\"]" -r '$1' "$dir" \
    | awk '{k=$0; sub(/^.*:/, "", k); if (length(k) > 32) print $0 "  (taxonomy, " length(k) " chars)"}'

check "eval / obfuscation (WordPress.org rejection)"
"${RG[@]}" -n '\beval\s*\(|gzinflate\s*\(|str_rot13\s*\(' "$dir"

check "Hook callbacks: accepted_args too low, filters returning null (PLG-10), admin-only calls on front-end hooks (PLG-08)"
if $has_tokenizer; then
    # Resolves named functions, class methods, and closures across all files (tokenized, never run).
    # One php process via stdin keeps a single callback index across all files.
    hook_hits=$("${RG[@]}" -0 --files "$dir" | php "$(dirname "$0")/hooks.php" - 2>/dev/null)
    rc=$?
    if [ "$rc" -ne 0 ]; then
        echo "(hooks.php failed with exit $rc; check accepted_args and filter returns by hand)"
    elif [ -n "$hook_hits" ]; then
        printf '%s\n' "$hook_hits"
    else
        echo "(no candidates; callbacks it could not resolve were skipped)"
    fi
else
    echo "(php tokenizer unavailable; check accepted_args and filter returns by hand)"
fi

section "WARNING candidates"

check "Uninstall guard and cleanup (PLG-05)"
if [ -f "$dir/uninstall.php" ]; then
    rg -q "WP_UNINSTALL_PLUGIN" "$dir/uninstall.php" \
        && echo "uninstall.php present with WP_UNINSTALL_PLUGIN guard" \
        || echo "uninstall.php present WITHOUT WP_UNINSTALL_PLUGIN guard (CRITICAL)"
    rg -qi 'delete_option|delete_site_option|DROP TABLE|delete_metadata|delete_transient|delete_site_transient|delete_post_meta_by_key|delete_user_meta|wp_delete_post|DELETE FROM' "$dir/uninstall.php" \
        || echo "uninstall.php contains no data-removal calls (delete_option, DROP TABLE, delete_*meta*, DELETE FROM, ...)"
else
    "${RG[@]}" -n 'register_uninstall_hook\s*\(' "$dir" || echo "no uninstall.php and no register_uninstall_hook"
fi

check "Lifecycle hooks (PLG-01) - empty means none registered"
"${RG[@]}" -n 'register_(activation|deactivation)_hook\s*\(' "$dir"

check "Files with CREATE TABLE but no dbDelta (PLG-16)"
"${RG[@]}" -l 'CREATE\s+TABLE' "$dir" | while IFS= read -r f; do
    rg -q 'dbDelta\s*\(' "$f" || echo "$f"
done

check "CREATE TABLE IF NOT EXISTS - dbDelta reads the table name as 'IF' (PLG-16)"
"${RG[@]}" -n -i 'CREATE\s+TABLE\s+IF\s+NOT\s+EXISTS' "$dir"

check "Hardcoded wp_ table prefix instead of \$wpdb->prefix (PLG-16)"
"${RG[@]}" -n -i '\b(FROM|INTO|UPDATE|TABLE|JOIN|EXISTS)\s+`?wp_[a-z]' "$dir"

check "set_transient without expiration argument (PLG-18, heuristic: simple arguments only)"
"${RG[@]}" -n 'set_(site_)?transient\s*\(\s*[^,()]+,\s*[^,()]+\)' "$dir"

check "i18n calls with no text domain argument (PLG-11, heuristic: literal strings only; misses strings containing the other quote type and nested calls)"
"${RG[@]}" -n "\b(__|_e|esc_html__|esc_html_e|esc_attr__|esc_attr_e)\s*\(\s*['\"][^'\"]*['\"]\s*\)" "$dir"
"${RG[@]}" -n "\b(_x|_ex|esc_html_x|esc_attr_x)\s*\(\s*['\"][^'\"]*['\"]\s*,\s*['\"][^'\"]*['\"]\s*\)" "$dir"
"${RG[@]}" -n "\b_n\s*\(\s*['\"][^'\"]*['\"]\s*,\s*['\"][^'\"]*['\"]\s*,\s*[^,()]+\)" "$dir"

check "Variables interpolated into translatable strings (PLG-11)"
"${RG[@]}" -n '\b(__|_e|_x|_n)\s*\(\s*"[^"]*\$[A-Za-z_]' "$dir"

check "base64_decode calls - review each; legitimate uses are common, payload decoding is not"
"${RG[@]}" -n 'base64_decode\s*\(' "$dir"

check "Hardcoded wp-content paths"
"${RG[@]}" -n '/wp-content/(plugins|uploads|themes)/' "$dir"

check "register_setting without sanitize_callback in same file (PLG-08)"
"${RG[@]}" -l 'register_setting\s*\(' "$dir" | while IFS= read -r f; do
    rg -q 'sanitize_callback' "$f" || echo "$f"
done

check "wp_schedule_event without wp_next_scheduled / cron cleanup (PLG-17)"
if "${RG[@]}" -q 'wp_schedule_event\s*\(' "$dir"; then
    "${RG[@]}" -q 'wp_next_scheduled\s*\(' "$dir" || echo "no wp_next_scheduled() guard found"
    "${RG[@]}" -q 'wp_(clear|unschedule)_scheduled_hook|wp_unschedule_event' "$dir" || echo "no cron cleanup found"
fi

check "register_post_type / register_taxonomy calls - verify show_in_rest (PLG-06, PLG-07)"
"${RG[@]}" -n 'register_(post_type|taxonomy)\s*\(' "$dir"

section "INFO candidates"

check "Header fields missing from main file (PLG-02)"
if [ -n "$main_file" ]; then
    for field in 'Version' 'Requires at least' 'Requires PHP' 'Text Domain' 'Domain Path' 'License'; do
        if [ -z "$(header_val "$field")" ]; then
            case "$field" in
                License) echo "missing: License (CRITICAL on WordPress.org if no license is stated anywhere)";;
                'Requires at least'|'Requires PHP') echo "missing: $field (WARNING on WordPress.org)";;
                *) echo "missing: $field";;
            esac
        fi
    done
fi

check "Files hooking admin_* actions - confirm they load only under is_admin() (PLG-20)"
"${RG[@]}" -l "add_action\s*\(\s*['\"]admin_" "$dir"

section "READ LIST"
echo "Every PHP file the review must read (vendor/, node_modules/, tests/ excluded), with line counts:"
"${RG[@]}" -0 --files "$dir" | xargs -0 -r wc -l | sort -k2
echo
echo "Files that register hooks (read these first on a partial review):"
"${RG[@]}" -l 'add_(action|filter)\s*\(' "$dir" | sort

echo
echo "Done. Treat every hit as a candidate; confirm in code before reporting."
