#!/usr/bin/env bash
# Quick static scan of a WordPress theme directory.
# Prints detected theme type, then CRITICAL/WARNING/INFO candidates with file:line.
# Every hit is a candidate only: confirm each one against the source before reporting.
#
# Usage: scan-theme.sh [theme-dir] [--wporg]   (default dir: current directory)
#   --wporg   apply WordPress.org submission rules (escalates headers, fonts, files)
# Env: WPORG=1 same as --wporg; NO_JQ=1 forces the grep fallback (jq gives exact theme.json checks)

set -u
wporg=0; dir="."
for a in "$@"; do
	case "$a" in
		--wporg) wporg=1 ;;
		-*) echo "Unknown option: $a" >&2; exit 1 ;;
		*) dir="$a" ;;
	esac
done
cd "$dir" || { echo "Cannot enter $dir" >&2; exit 1; }

has_jq=0; command -v jq >/dev/null 2>&1 && [ "${NO_JQ:-0}" != 1 ] && has_jq=1
[ "${WPORG:-0}" = 1 ] && wporg=1
EXCL=(--exclude-dir=node_modules --exclude-dir=vendor --exclude-dir=.git)
# Honor .distignore: directories not shipped with the theme are not reviewed
if [ -f .distignore ]; then
	while IFS= read -r d; do
		d=${d%%#*}; d=${d%/}; d=${d#/}; d=${d//[[:space:]]/}
		[ -n "$d" ] && [ -d "$d" ] && EXCL+=(--exclude-dir="$d")
	done < .distignore
fi

CRIT=""; WARN=""; INFO=""
add() { # severity, message
	case "$1" in
		CRITICAL) CRIT+="$2"$'\n' ;;
		WARNING) WARN+="$2"$'\n' ;;
		*) INFO+="$2"$'\n' ;;
	esac
}
# Add one finding per grep hit: severity, label, grep args...
hits() {
	local sev="$1" label="$2"; shift 2
	local out line n=0
	out=$(grep -rnHE "${EXCL[@]}" "$@" 2>/dev/null) || return 0
	if [ -n "${SKIP_RE:-}" ]; then out=$(grep -vE "$SKIP_RE" <<<"$out") || return 0; fi
	while IFS= read -r line; do
		line=${line#./}
		n=$((n + 1))
		[ $n -le 15 ] && add "$sev" "${line%%:*}:$(cut -d: -f2 <<<"$line"): $label"
	done <<<"$out"
	[ $n -gt 15 ] && add "$sev" "  (+$((n - 15)) more: $label)"
	return 0
}
# First line number matching a regex in a file, or 1
line_of() { local l; l=$(grep -nE "$2" "$1" 2>/dev/null | head -1 | cut -d: -f1); echo "${l:-1}"; }
jqr() { jq -r "$2" "$1" 2>/dev/null; }

# --- Theme type -----------------------------------------------------------
tdir=templates; [ ! -d templates ] && [ -d block-templates ] && tdir=block-templates
pdir=parts; [ ! -d parts ] && [ -d block-template-parts ] && pdir=block-template-parts
type="unknown"
if [ -f "$tdir/index.html" ]; then type="block"
elif [ -f index.php ] && [ -f theme.json ]; then type="hybrid"
elif [ -f index.php ]; then type="classic"
fi
child=0
[ -f style.css ] && grep -qE '^[[:space:]*]*Template:' style.css && child=1
if [ "$type" = "unknown" ] && [ $child -eq 1 ]; then
	if [ -d "$tdir" ] || [ -d "$pdir" ]; then type="block"
	elif [ -f theme.json ]; then type="block-or-hybrid"
	fi
fi

# --- Required files / style.css -------------------------------------------
if [ ! -f style.css ]; then
	add CRITICAL "style.css: missing"
else
	grep -q 'Theme Name:' style.css || add CRITICAL "style.css:1: missing Theme Name header"
	for h in 'Text Domain' 'Version'; do
		grep -q "$h:" style.css || add "$([ $wporg -eq 1 ] && echo CRITICAL || echo WARNING)" "style.css:1: missing '$h' header"
	done
	for h in 'Requires at least' 'Tested up to' 'Requires PHP'; do
		grep -q "$h:" style.css || add "$([ $wporg -eq 1 ] && echo CRITICAL || echo INFO)" "style.css:1: missing '$h' header"
	done
	if [ $wporg -eq 1 ]; then
		for h in 'Author' 'Description' 'License' 'License URI'; do
			grep -qE "^[[:space:]*]*$h:" style.css || add CRITICAL "style.css:1: missing '$h' header (WordPress.org)"
		done
	fi
fi
if [ $wporg -eq 1 ]; then
	[ -f readme.txt ] || add CRITICAL "readme.txt: missing (WordPress.org)"
	[ -f screenshot.png ] || [ -f screenshot.jpg ] || add CRITICAL "screenshot.png: missing (WordPress.org)"
fi
[ "$type" = "unknown" ] && [ $child -eq 0 ] && add CRITICAL "theme root: no templates/index.html (block) or index.php (classic)"
[ "$type" = "block" ] && [ $child -eq 0 ] && [ ! -f theme.json ] && add WARNING "theme.json: missing in block theme (works, but no design configuration)"
[ "$type" = "classic" ] && [ $child -eq 0 ] && add INFO "theme.json: classic theme could add one (hybrid)"

# --- theme.json -----------------------------------------------------------
CORE_FONT='["small","medium","large","x-large","xx-large"]'
CORE_SPACE='["20","30","40","50","60","70","80"]'
if [ -f theme.json ] && [ $has_jq -eq 1 ]; then
	if ! jq empty theme.json >/dev/null 2>&1; then
		add CRITICAL "theme.json:1: invalid JSON (jq parse error; all other theme.json checks skipped)"
	else
		ver=$(jqr theme.json '.version | if . == null then "missing" elif type == "number" and . == floor then (floor | tostring) elif type == "string" then "string:\(.)" else "invalid:\(.)" end')
		vl=$(line_of theme.json '"version"')
		case "$ver" in
			missing) add CRITICAL "theme.json:1: missing version (core discards the file contents)" ;;
			1) add WARNING "theme.json:$vl: version 1 (deprecated; upgrade to 3)" ;;
			2) add WARNING "theme.json:$vl: version 2 (upgrade to 3)" ;;
			3)
				fc=$(jqr theme.json "if (.settings.typography.fontSizes != null) and (.settings.typography.defaultFontSizes != false) then ([.settings.typography.fontSizes[].slug] - ([.settings.typography.fontSizes[].slug] - $CORE_FONT) | join(\",\")) + \"|y\" else \"\" end")
				if [ -n "$fc" ]; then
					l=$(line_of theme.json '"fontSizes"')
					if [ "$fc" != "|y" ]; then add CRITICAL "theme.json:$l: fontSizes slugs (${fc%|y}) collide with core defaults; set \"defaultFontSizes\": false or theme values are ignored"
					else add WARNING "theme.json:$l: custom fontSizes without \"defaultFontSizes\": false (duplicate Default group in UI)"; fi
				fi
				sc=$(jqr theme.json "if ((.settings.spacing.spacingSizes != null) or ((.settings.spacing.spacingScale.steps // 0) > 0)) and (.settings.spacing.defaultSpacingSizes != false) then (([.settings.spacing.spacingSizes[]?.slug] - ([.settings.spacing.spacingSizes[]?.slug] - $CORE_SPACE)) + (if (.settings.spacing.spacingScale.steps // 0) > 0 then [\"spacingScale\"] else [] end) | join(\",\")) + \"|y\" else \"\" end")
				if [ -n "$sc" ]; then
					l=$(line_of theme.json '"spacing(Sizes|Scale)"')
					if [ "$sc" != "|y" ]; then add CRITICAL "theme.json:$l: spacing presets (${sc%|y}) collide with core defaults; set \"defaultSpacingSizes\": false or theme values are ignored"
					else add WARNING "theme.json:$l: custom spacingSizes without \"defaultSpacingSizes\": false (duplicate Default group in UI)"; fi
				fi ;;
			string:*) add WARNING "theme.json:$vl: version is a string (${ver#string:}); use an integer (verify how core handles it)" ;;
			*) add CRITICAL "theme.json:$vl: unknown version ($ver)" ;;
		esac
		pad_type=$(jqr theme.json '.styles.spacing.padding | type')
		pad_lr=$(jqr theme.json '.styles.spacing.padding | if type == "object" then (has("left") or has("right")) elif type == "string" then true else false end')
		rpaa=$(jqr theme.json '.settings.useRootPaddingAwareAlignments // false')
		pl=$(line_of theme.json '"padding"')
		[ "$pad_type" = "string" ] && [ "$rpaa" = "true" ] && add CRITICAL "theme.json:$pl: useRootPaddingAwareAlignments with shorthand string padding (use object)"
		[ "$pad_lr" = "true" ] && [ "$rpaa" != "true" ] && add WARNING "theme.json:$pl: root left/right padding without useRootPaddingAwareAlignments"
		if [ "$type" = "block" ] && [ $child -eq 0 ]; then
			[ "$(jqr theme.json '(.settings.layout.contentSize != null) and (.settings.layout.wideSize != null)')" = "true" ] \
				|| add WARNING "theme.json:1: settings.layout.contentSize/wideSize missing (wide/full widths undefined)"
		fi
		[ "$(jqr theme.json 'has("$schema")')" = "false" ] && add INFO "theme.json:1: missing \$schema"
		# Registered template parts: name format and file existence (parent provides files for child themes)
		while IFS= read -r p; do
			[ -z "$p" ] && continue
			l=$(line_of theme.json "\"name\"[[:space:]]*:[[:space:]]*\"$p\"")
			case "$p" in *.html) add WARNING "theme.json:$l: templateParts name '$p' must not include .html"; continue ;; esac
			[ $child -eq 0 ] && [ ! -f "$pdir/$p.html" ] && add WARNING "theme.json:$l: templateParts registers '$p' but $pdir/$p.html missing"
		done < <(jqr theme.json '.templateParts[]?.name // empty')
		registered=$(jqr theme.json '[.templateParts[]?.name] | join(" ")')
		for f in "$pdir"/*.html; do
			[ -f "$f" ] && [ $child -eq 0 ] || continue
			n=$(basename "$f" .html)
			[[ " $registered " == *" $n "* ]] || add INFO "$f:1: template part not registered in theme.json templateParts"
		done
		customs=$(jqr theme.json '[.customTemplates[]?.name] | join(" ")')
		# page-*/single-* can be hierarchy or custom; they are skipped (check customTemplates by hand)
		HIER='^(index|home|front-page|singular|single|page|archive|author|category|tag|taxonomy|date|search|404|attachment|image|video|audio|application|text|embed|privacy-policy)(-.+)?$'
		for f in "$tdir"/*.html; do
			[ -f "$f" ] && [ $child -eq 0 ] || continue
			n=$(basename "$f" .html)
			[[ "$n" =~ $HIER ]] && continue
			[[ " $customs " == *" $n "* ]] || add INFO "$f:1: non-hierarchy template not registered in customTemplates"
		done
	fi
elif [ -f theme.json ]; then
	vl=$(line_of theme.json '"version"')
	grep -q '"version"' theme.json || add CRITICAL "theme.json:1: missing version (core discards the file contents)"
	grep -qE '"version"[[:space:]]*:[[:space:]]*[12][[:space:]]*[,}]' theme.json && add WARNING "theme.json:$vl: version 1 or 2 (upgrade to 3)"
	grep -qE '"version"[[:space:]]*:[[:space:]]*"' theme.json && add WARNING "theme.json:$vl: version is a string; use an integer"
	grep -qE '"version"[[:space:]]*:[[:space:]]*([04-9]|[1-9][0-9])' theme.json && add CRITICAL "theme.json:$vl: unknown version"
	if grep -qE '"version"[[:space:]]*:[[:space:]]*3[[:space:]]*[,}]' theme.json; then
		grep -q '"fontSizes"' theme.json && ! grep -qE '"defaultFontSizes"[[:space:]]*:[[:space:]]*false' theme.json \
			&& add WARNING "theme.json:$(line_of theme.json '"fontSizes"'): fontSizes without \"defaultFontSizes\": false (CRITICAL if slugs collide with core: small/medium/large/x-large/xx-large)"
		grep -qE '"(spacingSizes|spacingScale)"' theme.json && ! grep -qE '"defaultSpacingSizes"[[:space:]]*:[[:space:]]*false' theme.json \
			&& add WARNING "theme.json:$(line_of theme.json '"spacing(Sizes|Scale)"'): spacing presets without \"defaultSpacingSizes\": false (CRITICAL if spacingSizes slugs collide with core 20-80 or spacingScale.steps > 0)"
	fi
	grep -q '"\$schema"' theme.json || add INFO "theme.json:1: missing \$schema"
	add INFO "theme.json: jq unavailable; validity, padding, layout and template part checks skipped (verify by hand)"
fi

# --- Style variations (incl. 6.6 partials in subfolders) ------------------
while IFS= read -r s; do
	if [ $has_jq -eq 1 ] && ! jq empty "$s" >/dev/null 2>&1; then add CRITICAL "$s:1: invalid JSON"; continue; fi
	grep -q '"version"' "$s" || add CRITICAL "$s:1: missing version (core discards the variation)"
	grep -q '"title"' "$s" || add INFO "$s:1: missing title (filename shown instead)"
done < <(find styles -name '*.json' 2>/dev/null)

# --- Patterns: headers read like core get_file_data() (first 8 KB, any comment) ---
for f in patterns/*.php; do
	[ -f "$f" ] || continue
	head_block=$(head -c 8192 "$f")
	grep -qE '^([[:space:]]*<\?php)?[[:space:]/*#@]*Title:' <<<"$head_block" || add CRITICAL "$f:1: missing Title header"
	grep -qE '^([[:space:]]*<\?php)?[[:space:]/*#@]*Slug:' <<<"$head_block" || add CRITICAL "$f:1: missing Slug header"
done

# --- Block templates, parts and patterns ----------------------------------
while IFS= read -r -d '' f; do
	# Openers = all '<!-- wp:' minus self-closing '/-->'. Robust to PHP ('?>') and multi-line JSON in attributes.
	all=$(grep -oE '<!-- wp:[a-z]' "$f" | wc -l)
	selfc=$(grep -oE '/-->' "$f" | wc -l)
	opens=$((all - selfc))
	closes=$(grep -oE '<!-- /wp:[a-z0-9/-]+ -->' "$f" | wc -l)
	[ "$opens" -ne "$closes" ] && add CRITICAL "$f:1: unbalanced block delimiters ($opens open, $closes close)"
	case "$f" in *.html)
		grep -qE '<\?(php|=)' "$f" && add CRITICAL "$f:$(line_of "$f" '<\?(php|=)'): PHP in .html template (never executes; use a PHP pattern via wp:pattern)" ;;
	esac
done < <(find "$tdir" "$pdir" -name '*.html' -print0 2>/dev/null; find patterns -name '*.php' -print0 2>/dev/null)
mk=$(ls -d "$tdir" "$pdir" patterns 2>/dev/null)
if [ -n "$mk" ]; then
	# Raw values only: preset-based block-serialized styles (var(--wp--preset--...)) are valid.
	# Fragment links such as href="#add" can match; confirm each hit.
	# Cover overlay colors are auto-sampled from the image by the editor: not a hand-picked value
	SKIP_RE='customOverlayColor|wp-block-cover__background' \
	hits WARNING "raw hex color (use palette preset)" --include='*.html' --include='*.php' '(^|[^&])#([0-9a-fA-F]{8}|[0-9a-fA-F]{6}|[0-9a-fA-F]{3,4})\b' $mk
	hits WARNING "raw px font size (use fontSizes preset)" --include='*.html' --include='*.php' 'font-?[sS]ize"?[[:space:]]*:[[:space:]]*"?[0-9.]+px' $mk
fi
# Comment lines (docblocks, usage notes) are not runtime paths
SKIP_RE='^[^:]+:[0-9]+:[[:space:]]*(\*|//|#)' \
hits WARNING "hardcoded /wp-content/themes/ path (use get_theme_file_uri())" --include='*.php' --include='*.html' --include='*.css' 'wp-content/themes/' .

# --- PHP ------------------------------------------------------------------
php_files=$(find . -name '*.php' -not -path './node_modules/*' -not -path './vendor/*' 2>/dev/null)
if [ "$type" = "block" ] && [ -n "$php_files" ]; then
	hits WARNING "add_theme_support() that belongs in theme.json" --include='*.php' \
		"add_theme_support\([[:space:]]*['\"](editor-color-palette|editor-font-sizes|editor-gradient-presets|custom-line-height|custom-spacing|custom-units|align-wide)['\"]" .
fi
if { [ "$type" = "classic" ] || [ "$type" = "hybrid" ]; } && [ $child -eq 0 ]; then
	grep -rqE "${EXCL[@]}" --include='*.php' 'wp_head\(' . || add CRITICAL "theme PHP: wp_head() never called"
	grep -rqE "${EXCL[@]}" --include='*.php' 'wp_footer\(' . || add CRITICAL "theme PHP: wp_footer() never called"
	grep -rqE "${EXCL[@]}" --include='*.php' 'wp_body_open\(' . || add WARNING "theme PHP: wp_body_open() never called"
fi

# --- Theme PHP (all theme types): security candidates, legacy APIs ----------
orgsev() { [ $wporg -eq 1 ] && echo CRITICAL || echo "$1"; }
# Request data echoed without an escaping function: reflected XSS candidate
SKIP_RE='esc_(html|attr|url|js|textarea)|sanitize_|absint|intval|\(int\)|wp_kses' \
hits CRITICAL "request data echoed unescaped (XSS; hand off to /wp-sec-review)" --include='*.php' \
	'(echo|print|<\?=)[^;]*\$_(GET|POST|REQUEST|SERVER|COOKIE)\[' .
# Files that read POST/REQUEST data AND save something, but never verify a nonce
WRITES='update_option|add_option|set_theme_mod|update_(post|user|term|comment)_meta|add_(post|user|term)_meta|wp_(insert|update|delete)_(post|user|term)|\$wpdb->(insert|update|delete|query|replace)'
while IFS= read -r f; do
	f=${f#./}
	grep -qE "$WRITES" "$f" || continue
	grep -qE 'wp_verify_nonce|check_admin_referer|check_ajax_referer' "$f" \
		|| add WARNING "$f:$(line_of "$f" '\$_(POST|REQUEST)\['): saves POST/REQUEST data with no nonce check (CSRF; hand off to /wp-sec-review)"
done < <(grep -rlE "${EXCL[@]}" --include='*.php' '\$_(POST|REQUEST)\[' . 2>/dev/null)
DEPRECATED='attribute_escape|wp_specialchars|js_escape|clean_url|sanitize_url|get_settings|get_userdatabylogin|get_currentuserinfo|wp_get_links|get_links|wp_list_cats|list_cats|dropdown_cats|get_profile|get_theme_data|get_themes|get_current_theme|add_custom_background|add_custom_image_header|screen_icon|like_escape|get_page_by_title|the_author_ID|get_the_author_ID|the_author_(email|url|description|login)|get_the_author_(email|url|description|login)'
n=0
while IFS= read -r m; do
	n=$((n + 1)); [ $n -gt 25 ] && continue
	m=${m#./}; fn=$(sed -E 's/^[^:]+:[0-9]+:[^a-zA-Z_]*//; s/[[:space:]]*\($//' <<<"$m")
	add WARNING "$(cut -d: -f1-2 <<<"$m"): deprecated $fn() (see Code Reference for replacement)"
done < <(grep -rnoHE "${EXCL[@]}" --include='*.php' "(^|[^a-zA-Z0-9_\$>:])($DEPRECATED)[[:space:]]*\(" . 2>/dev/null | grep -vE ':[^:]*function[[:space:]]')
[ $n -gt 25 ] && add WARNING "  (+$((n - 25)) more deprecated calls)"
if [ "$type" = "classic" ] || [ "$type" = "hybrid" ]; then
	if grep -rqE "${EXCL[@]}" --include='*.php' '<title' . && ! grep -rqE "${EXCL[@]}" --include='*.php' "add_theme_support\([[:space:]]*['\"]title-tag" .; then
		hits "$(orgsev WARNING)" "hardcoded <title> (add theme support 'title-tag', remove the tag)" --include='*.php' '<title' .
	fi
fi
hits "$(orgsev WARNING)" "hardcoded stylesheet/script tag (use wp_enqueue_style/script)" --include='*.php' \
	"<link[^>]+rel=['\"]stylesheet|<script[^>]+src=" .
hits "$(orgsev WARNING)" "translation call without text domain" --include='*.php' \
	"(^|[^a-zA-Z0-9_])(__|_e|_x|esc_html__|esc_html_e|esc_attr__|esc_attr_e)\([[:space:]]*('[^']*'|\"[^\"]*\")[[:space:]]*\)" .
[ -f functions.php ] && ! grep -qE "defined\([[:space:]]*['\"]ABSPATH['\"]" functions.php && add INFO "functions.php:1: no ABSPATH guard"
hits "$([ $wporg -eq 1 ] && echo CRITICAL || echo INFO)" "Google Fonts CDN (bundle fonts via fontFace)" \
	--include='*.php' --include='*.css' --include='*.json' --include='*.html' 'fonts\.(googleapis|gstatic)\.com' .

# --- Output ---------------------------------------------------------------
echo "== Theme type: $type$([ $child -eq 1 ] && echo ' (child theme)')$([ $wporg -eq 1 ] && echo ' [WordPress.org rules]')"
[ $has_jq -eq 0 ] && echo "== jq not available: theme.json checks use grep, verify by hand"
for sev in CRITICAL WARNING INFO; do
	case $sev in CRITICAL) body=$CRIT ;; WARNING) body=$WARN ;; INFO) body=$INFO ;; esac
	[ -z "$body" ] && continue
	printf '\n== %s (%d)\n' "$sev" "$(printf '%s' "$body" | grep -c '^[^ ]')"
	printf '%s' "$body" | sed 's/^/  /'
done
exit 0
