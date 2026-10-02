#!/usr/bin/env bash
#
# static-checks.sh
#
# Read-only static checks for a classic WordPress theme, or for a migrated block
# theme and its companion plugin. Writes nothing.
#
# USAGE
#   static-checks.sh <theme-dir> <plugin-dir> <block-namespace> [plugin-function-prefix]
#
#   theme-dir               Theme folder to check.
#   plugin-dir              Companion plugin folder. For a classic theme that has no
#                           plugin yet, pass an empty folder. For a theme-bundled
#                           migration, pass <theme-dir>/inc/functionality.
#   block-namespace         The plugin's block namespace and pattern slug prefix,
#                           for example "mytheme".
#   plugin-function-prefix  Prefix of plugin-only PHP functions.
#                           Default: "<block-namespace>_func_".
#
# MODES
#   Each mode that applies prints one "MODE: ..." line at the top of stdout.
#
#   classic        <theme-dir>/templates/index.html does not exist. Syntax checks
#                  run, checks 4, 4b, 11 and 12 print their findings as INFO lines
#                  (they never fail the run), checks 5-10 and 13-19 are skipped,
#                  and a "Gate 0 signals" table is printed at the end.
#
#   theme-bundled  <plugin-dir> is inside <theme-dir>. That folder is excluded when
#                  the theme is scanned, and is still scanned as the plugin.
#
# STDOUT
#   One section per check. Each section starts with a blank line and
#   "### <number>. <title>", then prints one of:
#     - findings, one per line ("path:line:text" or "label: detail")
#     - "(none)" or "(ok)"
#     - "files=N errors=M" for the syntax checks
#   Paths are printed as found, without quoting.
#   The last section is "### RESULT" followed by "ALL CHECKS PASSED" or
#   "SOME CHECKS FAILED".
#
# EXIT CODES
#   0  All checks passed.
#   1  At least one check failed, or a required argument is missing. A missing
#      argument also prints bash's "${var:?}" message on stderr.
#   2  <theme-dir> or <plugin-dir> is not a directory, or php, python3 or node
#      is not installed. One line on stderr says which; nothing is checked.
#
# REQUIREMENTS
#   bash, GNU grep (the patterns use \s and \b with -E), find, sort, sed, awk,
#   php, python3, node, perl. Without perl, check 16 reports that it could not
#   run and fails.
#
# PATHS IN OUTPUT
#   Paths printed on their own ("BAD <path>", "INFO: BOM in <path>",
#   "INFO: invalid JSON <path>", "MISSING <path> (from block.json)", the
#   theme-bundled MODE line) use bash's %q quoting: ordinary paths print
#   unchanged, and spaces or shell characters are escaped ("sp\ theme/a.json").
#   Paths at the start of grep findings ("path:line:text") are printed as found.
#
set -u


# ============================================================================
# Constants
# ============================================================================

# Folders that code greps never scan: development tooling and dependencies.
CODE_GREP_EXCLUDES=(
    --exclude-dir=demo
    --exclude-dir=tools
    --exclude-dir=tests
    --exclude-dir=node_modules
    --exclude-dir=vendor
)

# Folders skipped by the dequeue-handle scan in check 4.
DEQUEUE_GREP_EXCLUDES=(
    --exclude-dir=demo
    --exclude-dir=tools
)

# Maximum INFO lines printed per classic-mode section before a "... N more" line.
INFO_LINE_LIMIT=25

# Maximum lines printed by the block-validation risk scan in check 18.
RISK_LINE_LIMIT=20


# ============================================================================
# Arguments
# ============================================================================

# Required arguments. "${n:?message}" makes bash print the message on stderr and
# exit 1 when the argument is missing or empty.
T="${1:?theme dir}"
P="${2:?plugin dir}"
NS="${3:?block namespace}"

# Optional plugin function prefix, defaulting to "<namespace>_func_".
FP="${4:-${NS}_func_}"

# Both folders must exist; otherwise every check would scan nothing and pass.
for _dir in "$T" "$P"; do
    if [ ! -d "$_dir" ]; then
        echo "static-checks.sh: not a directory: $_dir" >&2
        exit 2
    fi
done

# Required tools. Without them every file would be reported as an error.
# perl is optional: check 16 reports when it is missing.
for _tool in php python3 node; do
    if ! command -v "$_tool" >/dev/null 2>&1; then
        echo "static-checks.sh: required tool not found: $_tool" >&2
        exit 2
    fi
done

# Set to 1 by any check that fails. Becomes the exit code.
fail=0


# ============================================================================
# Mode detection
# ============================================================================

# Classic mode: the theme has no block templates yet.
CLASSIC=0
[ -f "$T/templates/index.html" ] || CLASSIC=1

# Theme-bundled mode: the "plugin" folder lives inside the theme (for example
# inc/functionality). When the theme is scanned, that folder is excluded through
# this single grep option; it is still scanned when the plugin is scanned.
EXCL=""
case "$(cd "$P" 2>/dev/null && pwd)/" in
    "$(cd "$T" && pwd)/"*)
        EXCL="--exclude-dir=$(basename "$P")"
        printf 'MODE: theme-bundled (%q inside the theme)\n' "$P"
        ;;
esac

if [ $CLASSIC -eq 1 ]; then
    echo "MODE: classic (no templates/index.html) — Gate 0 signals are INFO; post-migration checks N/A"
fi

# In classic mode, checks 4, 4b, 11 and 12 report findings as INFO instead of
# failing the run.
if [ $CLASSIC -eq 1 ]; then
    report_info=1
else
    report_info=0
fi


# ============================================================================
# Helpers
# ============================================================================

# Print a section header: a blank line, then "### <title>".
hdr() {
    printf '\n### %s\n' "$*"
}

# Search PHP files for an extended regex.
#
# Usage: code_grep <pattern> <dir> [<dir> ...]
#
# - Skips the folders listed in CODE_GREP_EXCLUDES.
# - When scanning the theme in theme-bundled mode, also skips the bundled plugin
#   folder.
# - Drops comment lines (//, *, /*, #) so explanatory comments never count as
#   code.
# - Drops lines that contain "static-checks:allow", which marks a deliberate,
#   recorded exception (for example an admin-only post type that keeps
#   show_in_rest false).
code_grep() {
    local pat="$1"
    local d
    local x
    shift

    for d in "$@"; do
        x=""
        if [ "$d" = "$T" ]; then
            x="$EXCL"
        fi
        # $x stays unquoted on purpose: it is either empty or a single
        # "--exclude-dir=<name>" token.
        grep -rnE "$pat" --include='*.php' $x "${CODE_GREP_EXCLUDES[@]}" "$d" 2>/dev/null
    done | grep -vE ':[0-9]+:\s*(//|\*|/\*|#)' | grep -v 'static-checks:allow'
}

# Report the result of a check that can fail.
#
# Usage: report "<findings>"
#
# Prints the findings and marks the run as failed, or prints "(none)" when the
# findings are empty.
report() {
    if [ -n "$1" ]; then
        echo "$1"
        fail=1
    else
        echo "(none)"
    fi
}

# Report the result of a check that is informational in classic mode.
#
# Usage: rep4 "<findings>"
#
# Classic mode: prints each non-empty finding prefixed with "INFO: ", at most
# INFO_LINE_LIMIT lines followed by a "... N more" line, and never fails the run.
# Otherwise: behaves exactly like report().
rep4() {
    if [ $report_info -eq 1 ]; then
        local t
        local n
        t=$(printf "%s\n" "$1" | grep -v "^$")
        if [ -n "$t" ]; then
            n=$(printf "%s\n" "$t" | wc -l)
            printf "%s\n" "$t" | head -"$INFO_LINE_LIMIT" | sed "s/^/INFO: /"
            if [ "$n" -gt "$INFO_LINE_LIMIT" ]; then
                echo "INFO: … $((n - INFO_LINE_LIMIT)) more (see Gate 0 signals for per-kind counts)"
            fi
        else
            echo "(none)"
        fi
    else
        report "$1"
    fi
}

# Print one row of the Gate 0 signals table.
#
# Usage: sig "<label>" "<pattern>"
#
# Columns: the label (34 characters), the number of matching code lines in the
# theme, and the first two locations with the theme path removed, cut to 90
# characters each and joined on one line.
sig() {
    local hits
    hits=$(code_grep "$2" "$T")
    printf "%-34s %4s  %s\n" \
        "$1" \
        "$(printf "%s" "$hits" | grep -c .)" \
        "$(printf "%s" "$hits" | head -2 | sed -E "s#^$T/##; s/:[[:space:]]+/: /" | cut -c1-90 | tr "\n" " ")"
}


# ============================================================================
# Check 1: PHP syntax
# ============================================================================
# Every PHP file in the theme and the plugin must pass "php -l". The first two
# lines of each failure are printed.

hdr "1. php -l"
bad=0
n=0
while IFS= read -r f; do
    n=$((n + 1))
    if ! php -l "$f" >/dev/null 2>&1; then
        bad=$((bad + 1))
        php -l "$f" 2>&1 | head -2
    fi
done < <(find "$T" "$P" -name '*.php' -not -path '*/node_modules/*' -not -path '*/vendor/*' | sort -u)
echo "files=$n errors=$bad"
[ $bad -eq 0 ] || fail=1


# ============================================================================
# Check 2: JSON syntax and theme.json version
# ============================================================================
# Every JSON file must parse (a UTF-8 byte order mark is allowed and reported as
# INFO). In classic mode, invalid JSON other than theme.json is INFO only.
# Afterwards, theme.json must declare version 3 or higher (INFO in classic mode).

hdr "2. JSON valid"
bad=0
n=0
while IFS= read -r f; do
    n=$((n + 1))

    # Report a byte order mark at the start of the file.
    head -c3 "$f" | grep -q $'\xef\xbb\xbf' && printf 'INFO: BOM in %q\n' "$f"

    if ! python3 -c "import json,sys; json.load(open(sys.argv[1], encoding='utf-8-sig'))" "$f" >/dev/null 2>&1; then
        if [ $CLASSIC -eq 1 ] && [ "$(basename "$f")" != theme.json ]; then
            printf 'INFO: invalid JSON %q\n' "$f"
        else
            bad=$((bad + 1))
            printf 'BAD %q\n' "$f"
        fi
    fi
done < <(find "$T" "$P" -name '*.json' -not -path '*/node_modules/*' | sort -u)
echo "files=$n errors=$bad"
[ $bad -eq 0 ] || fail=1

if [ -f "$T/theme.json" ]; then
    # Read the "version" key; an unreadable file leaves v empty.
    v=$(python3 -c "import json,sys;print(json.load(open(sys.argv[1], encoding='utf-8-sig')).get('version',0))" "$T/theme.json" 2>/dev/null)
    if [ "${v:-0}" -ge 3 ] 2>/dev/null; then
        echo "theme.json version $v"
    elif [ $CLASSIC -eq 1 ]; then
        echo "INFO: classic theme.json version ${v:-?} — read as input (locks = guardrails), upgrade to 3"
    else
        echo "theme.json version ${v:-?} (expected 3)"
        fail=1
    fi
fi


# ============================================================================
# Check 3: JavaScript syntax
# ============================================================================
# Every JavaScript file (except build output and minified files) must pass
# "node --check".

hdr "3. node --check"
bad=0
n=0
while IFS= read -r f; do
    n=$((n + 1))
    if ! node --check "$f" 2>/dev/null; then
        bad=$((bad + 1))
        printf 'BAD %q\n' "$f"
    fi
done < <(find "$T" "$P" -name '*.js' -not -path '*/node_modules/*' -not -path '*/build/*' -not -name '*.min.js' | sort -u)
echo "files=$n errors=$bad"
[ $bad -eq 0 ] || fail=1


# ============================================================================
# Check 4: block-feature sabotage
# ============================================================================
# Code that switches off what a block theme needs: block editor filters, dequeued
# block styles, unhooked global styles, a removed oEmbed route, an unregistered
# Block widget, or a Content-Security-Policy header.

hdr "4. Block-feature sabotage (expect none)"

# Lines in files that dequeue or deregister styles and name a block style handle
# anywhere in the file (this also catches handles listed in arrays and loops).
dequeued_block_style_handles() {
    local f
    while IFS= read -r f; do
        grep -nE "['\"](wp-block-library|global-styles|classic-theme-styles|wp-block-library-theme)['\"]" "$f" \
            | grep -vE ":\s*(//|\*|#)" \
            | sed "s#^#$f:#"
    done < <(grep -rlE "wp_(dequeue|deregister)_style" --include='*.php' "${DEQUEUE_GREP_EXCLUDES[@]}" "$T" "$P" 2>/dev/null)
}

# All sabotage findings, de-duplicated.
sabotage_findings() {
    {
        {
            dequeued_block_style_handles
            code_grep "wp_global_styles_render_svg_filters|wp_enqueue_classic_theme_styles" "$T" "$P"
        } | sort -u
        code_grep "use_block_editor_for_post|use_widgets_block_editor|gutenberg_use_widgets_block_editor|wp_dequeue_style\(\s*'(wp-block-library|global-styles|classic-theme-styles)'|remove_action\([^)]*(wp_enqueue_global_styles|wp_oembed_register_route)|['\"]WP_Widget_Block['\"]|Content-Security-Policy" "$T" "$P"
    } | sort -u
}

rep4 "$(sabotage_findings)"


# ============================================================================
# Check 4b: post types and taxonomies hidden from the block editor
# ============================================================================
# "show_in_rest => false" keeps a post type or taxonomy out of the block editor.
# Files that also contain "public => false" get a review note, because record
# types (rows created by code) may legitimately stay on the classic screen.

hdr "4b. Post types / taxonomies hidden from the block editor (show_in_rest false)"
bad=""
while IFS= read -r f; do
    # Arguments arrays often come before the register_* call, so match anywhere in
    # a file that registers post types or taxonomies.
    hit=$(grep -nE "show_in_rest['\"]?[[:space:]]*=>[[:space:]]*false" "$f" \
        | grep -vE ':[0-9]+:\s*(//|\*|#)' \
        | grep -v 'static-checks:allow' \
        | sed "s#^#$f:#")

    if [ -n "$hit" ]; then
        if grep -qE "['\"]public['\"][[:space:]]*=>[[:space:]]*false" "$f"; then
            hit=$(printf '%s\n' "$hit" | sed 's/$/   [review: record type (code-created rows) may stay; staff-authored or form-only CPTs — see plugin-extraction.md]/')
        fi
        bad="$bad$hit"$'\n'
    fi
done < <(grep -rlE 'register_(post_type|taxonomy)' --include='*.php' "$T" "$P" 2>/dev/null)
rep4 "$bad"


# ============================================================================
# Checks 5-10: block markup in the theme (block themes only)
# ============================================================================

if [ $CLASSIC -eq 0 ]; then

    # ------------------------------------------------------------------------
    # Check 5: untranslatable text in .html templates and parts.
    # Element text and text-like block attributes cannot be translated in .html
    # files; such text belongs in patterns.
    # ------------------------------------------------------------------------
    hdr "5. User-facing text in .html (element text and block-attribute labels)"
    report "$(
        {
            grep -rnE --include='*.html' \
                '<(p|h[1-6]|a|span|li|button|label)[^>]*>[^<{]*[A-Za-z]{3,}' \
                "$T/templates" "$T/parts" 2>/dev/null
            grep -rnoE --include='*.html' \
                '"(placeholder|label|buttonText|ariaLabel|moreText|text|content|prefix|suffix|summary|linkLabel|showMoreText|showLessText)":"[^"]*[A-Za-z]{3,}[^"]*"' \
                "$T/templates" "$T/parts" 2>/dev/null
        }
    )"

    # ------------------------------------------------------------------------
    # Check 6: hardcoded theme asset paths in .html templates and parts.
    # ------------------------------------------------------------------------
    hdr "6. Theme asset paths in .html"
    report "$(grep -rn 'wp-content/themes' "$T/templates" "$T/parts" 2>/dev/null)"

    # ------------------------------------------------------------------------
    # Check 7: every wp:pattern slug used in the theme has a pattern file with a
    # matching "Slug:" header.
    # ------------------------------------------------------------------------
    hdr "7. Every wp:pattern slug exists"
    miss=""
    for s in $(grep -rhoE "\"slug\":\"$NS/[a-z0-9-]+\"" "$T/templates" "$T/parts" "$T/patterns" 2>/dev/null \
            | cut -d'"' -f4 \
            | sort -u); do
        if ! grep -lqE "Slug:\s*$s\s*$" "$T"/patterns/*.php 2>/dev/null; then
            miss="$miss MISSING $s"$'\n'
        fi
    done
    report "$miss"

    # ------------------------------------------------------------------------
    # Check 8: every template has exactly one <main> (a Group block with
    # "tagName":"main"). Occurrences are counted, so two on one line count as 2.
    # ------------------------------------------------------------------------
    hdr "8. Exactly one <main> per template"
    bad=""
    for f in "$T"/templates/*.html; do
        if [ ! -f "$f" ]; then
            bad="no templates/*.html (not a block theme yet)"
            break
        fi
        c=$(grep -o '"tagName":"main"' "$f" | wc -l)
        [ "$c" = 1 ] || bad="$bad$(basename "$f"): $c"$'\n'
    done
    report "$bad"

    # ------------------------------------------------------------------------
    # Check 9: hardcoded hex colors and raw sizes in block markup. Presets
    # should be used instead. A "0" spacing value is allowed.
    # ------------------------------------------------------------------------
    hdr "9. Hex colours / raw sizes in block markup"
    report "$(
        {
            grep -rnE '#[0-9a-fA-F]{3,8}\b' "$T/templates" "$T/parts" "$T/patterns" 2>/dev/null \
                | grep -v 'Slug:'
            grep -rnE '"fontSize":"[0-9]|"(top|bottom|left|right|blockGap)":"([1-9]|0[.0-9])' \
                "$T/templates" "$T/parts" "$T/patterns" 2>/dev/null
        }
    )"

    # ------------------------------------------------------------------------
    # Check 10: templates/ and parts/ contain no PHP files and no PHP code.
    # ------------------------------------------------------------------------
    hdr "10. No PHP in templates/ or parts/"
    report "$(
        {
            find "$T/templates" "$T/parts" -name '*.php' 2>/dev/null
            grep -rln '<?php' "$T/templates" "$T/parts" 2>/dev/null
        } | sort -u
    )"

fi


# ============================================================================
# Check 11: plugin territory in the theme
# ============================================================================
# Business logic that belongs in the companion plugin (or the bundled folder):
# post types, taxonomies, metaboxes, shortcodes, REST routes, AJAX handlers,
# settings, rewrites, feeds, headers, admin pages, cron, lifecycle hooks, widgets,
# user profile fields, upload handling.

hdr "11. No plugin territory in the theme"
PT="add_rewrite_endpoint|register_post_type|register_taxonomy|add_meta_box|add_shortcode|register_rest_route|wp_ajax_|admin_post_|register_post_meta|register_setting|add_feed|add_rewrite_rule|add_rewrite_tag|wp_headers|send_headers|add_menu_page|add_submenu_page|add_theme_page|wp_add_dashboard_widget|wp_schedule_event|wp_schedule_single_event|after_switch_theme|switch_theme|(^|[^_[:alnum:]])register_widget|show_user_profile|personal_options_update|wp_handle_upload"
rep4 "$(code_grep "$PT" "$T")"


# ============================================================================
# Check 12: theme supports, menus and sidebars a block theme does not need
# ============================================================================

hdr "12. Redundant supports / menus / sidebars in the theme"
rep4 "$(code_grep "add_theme_support\( *'(post-thumbnails|responsive-embeds|editor-styles|html5|automatic-feed-links|title-tag|custom-header|custom-background|widgets|align-wide|customize-selective-refresh-widgets)'|register_nav_menus?\b|register_sidebar" "$T")"


# ============================================================================
# Checks 13-19: theme and plugin consistency (block themes only)
# ============================================================================

if [ $CLASSIC -eq 0 ]; then

    # ------------------------------------------------------------------------
    # Check 13: WordPress never enqueues a theme stylesheet by itself, so the
    # theme must call wp_enqueue_style, and add_editor_style for the editor.
    # ------------------------------------------------------------------------
    hdr "13. Theme enqueues a stylesheet and an editor style"
    m=""
    # $EXCL keeps the bundled plugin folder out of this theme-side search; it
    # stays unquoted because it is empty or a single --exclude-dir=<name> token.
    grep -rqE 'wp_enqueue_style' --include='*.php' $EXCL "$T" || m="$m wp_enqueue_style"
    grep -rqE 'add_editor_style' --include='*.php' $EXCL "$T" || m="$m add_editor_style"
    if [ -z "$m" ]; then
        echo "(ok)"
    else
        echo "missing:$m"
        fail=1
    fi

    # ------------------------------------------------------------------------
    # Check 14: the theme never calls plugin-only functions (prefix $FP).
    # ------------------------------------------------------------------------
    hdr "14. Theme never calls plugin functions ($FP*)"
    report "$(code_grep "\b${FP}[a-z0-9_]+\s*\(" "$T")"

    # ------------------------------------------------------------------------
    # Check 15: every plugin function the plugin calls is defined in the plugin.
    # "php -l" does not catch calls to undefined functions.
    # ------------------------------------------------------------------------
    hdr "15. Every called $FP* function is defined"
    defs=$(grep -rhoE "function +${FP}[a-z0-9_]+" --include='*.php' "$P" \
        | awk '{print $2}' \
        | sort -u)
    calls=$(grep -rhoE "\b${FP}[a-z0-9_]+\s*\(" --include='*.php' "$P" \
        | sed -E 's/\s*\($//' \
        | sort -u)
    und=""
    for c in $calls; do
        printf '%s\n' "$defs" | grep -qx "$c" || und="$und UNDEFINED $c"$'\n'
    done
    report "$und"

    # ------------------------------------------------------------------------
    # Check 16: every opening block comment has a closing one. PHP inside block
    # attributes (in patterns) is removed first, because it can contain ">".
    # Without perl the counts would be 0/0, so the check reports and fails.
    # ------------------------------------------------------------------------
    hdr "16. Block comment balance"
    bad=""
    if ! command -v perl >/dev/null 2>&1; then
        bad="perl not installed: block comment balance not checked"$'\n'
    fi
    for f in "$T"/templates/*.html "$T"/parts/*.html "$T"/patterns/*.php; do
        [ -f "$f" ] || continue
        body=$(perl -0pe 's/<\?php.*?\?>//gs' "$f")
        open=$(printf '%s' "$body" | grep -oE '<!-- wp:[a-z0-9/-]+( [^>]*[^/])? -->' | wc -l)
        close=$(printf '%s' "$body" | grep -oE '<!-- /wp:[a-z0-9/-]+ -->' | wc -l)
        [ "$open" = "$close" ] || bad="$bad$(basename "$f"): open=$open close=$close"$'\n'
    done
    report "$bad"

    # ------------------------------------------------------------------------
    # Check 17: every plugin block the theme uses (<!-- wp:<namespace>/... -->)
    # has a block.json with that name in the plugin.
    # ------------------------------------------------------------------------
    hdr "17. Plugin blocks used by the theme exist in the plugin"
    miss=""
    for b in $(grep -rhoE "<!-- wp:$NS/[a-z0-9-]+" "$T" 2>/dev/null \
            | sed "s#<!-- wp:$NS/##" \
            | sort -u); do
        if ! grep -rlq "\"name\": *\"$NS/$b\"" "$P" --include=block.json; then
            miss="$miss MISSING $NS/$b"$'\n'
        fi
    done
    report "$miss"

    # ------------------------------------------------------------------------
    # Check 18: block-validation risk. Informational only, never fails.
    #   - Column "width" attributes that do not match the flex-basis styles.
    #   - More "anchor" attributes than id= attributes.
    #   - Files referenced by block.json ("file:./...") that do not exist.
    # ------------------------------------------------------------------------
    hdr "18. Block-validation risk (review manually; not a failure)"
    for f in "$T"/templates/*.html "$T"/parts/*.html "$T"/patterns/*.php; do
        [ -f "$f" ] || continue

        w=$(grep -oE '"width":"[0-9.]+%"' "$f" | grep -oE '[0-9.]+' | sort -u | tr '\n' ' ')
        b=$(grep -oE 'flex-basis:[0-9.]+%' "$f" | grep -oE '[0-9.]+' | sort -u | tr '\n' ' ')
        [ "$w" != "$b" ] && echo "$(basename "$f"): column width attrs [$w] vs flex-basis [$b]"

        a=$(grep -cE '"anchor":"' "$f")
        i2=$(grep -cE '<[a-z]+[^>]* id="' "$f")
        [ "$a" -gt "$i2" ] && echo "$(basename "$f"): $a anchor attrs but $i2 id= attributes"
    done | head -"$RISK_LINE_LIMIT"

    while IFS= read -r bj; do
        d=$(dirname "$bj")
        while IFS= read -r ref; do
            [ -n "$ref" ] || continue
            [ -f "$d/$ref" ] || printf 'MISSING %q (from block.json)\n' "$d/$ref"
        done < <(grep -oE '"file:\./[^"]+"' "$bj" | sed -E 's/"file:\.\/([^"]+)"/\1/')
    done < <(find "$P" -name block.json -not -path '*/node_modules/*' 2>/dev/null)

    # ------------------------------------------------------------------------
    # Check 19: a class on a <main> Group must not also be used on another
    # element. A shared class makes <main> inherit that element's CSS rules.
    # ------------------------------------------------------------------------
    hdr "19. Class on <main> also used on another element (expect none)"
    bad=""
    mains=$(grep -rhoE '"tagName":"main"[^}]*"className":"[^"]+"|"className":"[^"]+"[^}]*"tagName":"main"' "$T/templates" 2>/dev/null \
        | grep -oE '"className":"[^"]+"' \
        | cut -d'"' -f4 \
        | tr ' ' '\n' \
        | sort -u)
    for c in $mains; do
        # Occurrences of the class anywhere except on a <main> element itself.
        hits=$(grep -rnE "(class=\"|\"className\":\")([^\"]* )?${c}( [^\"]*)?\"" "$T/templates" "$T/parts" "$T/patterns" "$P" 2>/dev/null \
            | grep -vE '"tagName":"main"|<main ' \
            | head -3)
        [ -n "$hits" ] && bad="$bad class '$c' is on <main> and on other elements:"$'\n'"$hits"$'\n'
    done
    report "$bad"

fi


# ============================================================================
# Gate 0 signals (classic mode only)
# ============================================================================
# Counts of WordPress features found in the classic theme, with the first two
# locations of each. Used to plan the migration; never fails the run.

if [ $CLASSIC -eq 1 ]; then
    hdr "Gate 0 signals (INFO: count — first locations)"

    sig "post types / taxonomies"            "register_post_type|register_taxonomy"
    sig "REST routes"                        "register_rest_route"
    sig "settings (register_setting)"        "register_setting"
    sig "post/term/user meta registration"   "register_(post_|term_)?meta"
    sig "WP-CLI commands"                    "WP_CLI::add_command"
    sig "privacy exporters/erasers"          "wp_privacy_personal_data_(exporters|erasers)|wp_add_privacy_policy_content"
    sig "capabilities (map_meta_cap)"        "map_meta_cap|add_cap\\("
    sig "cron"                               "wp_schedule_(single_)?event|wp_next_scheduled"
    sig "theme lifecycle"                    "after_switch_theme|[^_]switch_theme"
    sig "admin pages"                        "add_(menu|submenu|theme|options)_page"
    sig "dashboard widgets"                  "wp_add_dashboard_widget"
    sig "query changes"                      "pre_get_posts|posts_clauses|.the_posts."
    sig "nav walkers"                        "extends[[:space:]]+Walker|Walker_Nav_Menu"
    sig "template_redirect / redirects"      "template_redirect|wp_redirect"
    sig "comment hooks"                      "add_(action|filter)\\(\\s*.(comment_post|preprocess_comment|comment_form_|wp_insert_comment|comment_reply_link|comment_text|get_avatar)"
    sig "Customizer"                         "customize_register"
    sig "widgets (register)"                 "(^|[^_[:alnum:]])register_widget|register_sidebar"
    sig "metaboxes"                          "add_meta_box"
    sig "AJAX handlers"                      "wp_ajax_|admin_post_"
    sig "shortcodes"                         "add_shortcode"
    sig "content / excerpt filters"          "add_filter\\(\\s*.(the_content|the_excerpt|get_the_excerpt|excerpt_length|excerpt_more)"
    sig "head output (SEO/JSON-LD)"          "['\"]wp_head['\"]"
    sig "user profile fields"                "show_user_profile|personal_options_update"
    sig "uploads"                            "wp_handle_upload|upload_mimes"
    sig "rewrites / endpoints / feeds"       "add_rewrite_rule|add_rewrite_tag|add_rewrite_endpoint|add_feed"
    sig "security headers"                   "wp_headers|send_headers|Content-Security-Policy"
    sig "hook-injected UI"                   "add_action\\(\\s*.(wp_footer|wp_body_open)"
    sig "nav menu filters / caching"         "add_filter\\(\\s*.(nav_menu_link_attributes|nav_menu_css_class|wp_nav_menu_items|pre_wp_nav_menu|wp_nav_menu)."
    sig "nav item meta"                      "wp_nav_menu_item_custom_fields|wp_update_nav_menu_item"
    sig "term meta forms"                    "_add_form_fields|_edit_form_fields|(created|edited)_[a-z_]+.,"
    sig "media output filters"               "wp_video_shortcode|wp_audio_shortcode|wp_playlist_shortcode|post_gallery|post_thumbnail_html|embed_oembed_html|oembed_dataparse|render_block_core/"
    sig "option_* filters"                   "add_filter\\(\\s*.option_"
    sig "uploads writes"                     "wp_upload_dir|wp_mkdir_p"
    sig "custom tables"                      "dbDelta|CREATE TABLE"
    sig "public hooks (apply_filters/do_action)" "(apply_filters|do_action)\\(\\s*.${NS}_"
    sig "early the_content passes (<10)"     "add_filter\\(\\s*.the_content.\\s*,[^,]+,\\s*[0-9]\\s*[,)]"
    sig "wp_localize_script"                 "wp_localize_script"

    # Admin JavaScript tied to the classic editor (TinyMCE / Quicktags).
    printf "%-34s %4s\n" \
        "TinyMCE coupling (admin JS files)" \
        "$(grep -rlE 'tinymce|tinyMCE|QTags' --include='*.js' "$T" --exclude-dir=node_modules 2>/dev/null | wc -l)"
fi


# ============================================================================
# Result
# ============================================================================

hdr "RESULT"
if [ $fail -eq 0 ]; then
    echo "ALL CHECKS PASSED"
else
    echo "SOME CHECKS FAILED"
fi
exit $fail
