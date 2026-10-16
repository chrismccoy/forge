#!/usr/bin/env bash
# scan-blocks.sh - Quick candidate scan for WordPress block review.
#
# Usage: scan-blocks.sh [path]   (default: current directory)
#
# Prints candidate findings grouped by severity. Every hit is a CANDIDATE:
# open the file and confirm before reporting. Skips node_modules, vendor,
# build, dist, .git, and test dirs (compiled output and tests are not reviewed).
# Requires bash (3.2+ works). Uses ripgrep (rg) when present; falls back to grep -r.
# Set SCAN_NO_RG=1 to force the grep fallback.

set -u
# Byte-order collation so sort and comm agree.
export LC_ALL=C
ROOT="${1:-.}"

if [ ! -d "$ROOT" ]; then
	echo "Error: '$ROOT' is not a directory" >&2
	exit 1
fi

EXCLUDES=( node_modules vendor build dist .git tests test __tests__ e2e e2e-tests )

HAVE_RG=0
if [ -z "${SCAN_NO_RG:-}" ] && command -v rg >/dev/null 2>&1; then HAVE_RG=1; fi

if [ "$HAVE_RG" -eq 1 ]; then
	RG_EXCL=()
	for d in "${EXCLUDES[@]}"; do RG_EXCL+=( -g "!$d/" ); done
	# search PATTERN GLOB  -> file:line:match
	search_raw() { rg -n --no-heading "${RG_EXCL[@]}" -g "$2" -g '!*.min.js' -g '!*.min.css' -e "$1" "$ROOT" 2>/dev/null | awk 'length($0) < 400'; }
	# files GLOB          -> list of matching file paths
	files_raw() { rg --files "${RG_EXCL[@]}" -g "$1" "$ROOT" 2>/dev/null; }
else
	GREP_EXCL=()
	for d in "${EXCLUDES[@]}"; do GREP_EXCL+=( --exclude-dir="$d" ); done
	# Expand brace globs like *.{js,jsx} into one --include per extension.
	incl() {
		local g="$1"
		if [[ "$g" == *"{"*"}"* ]]; then
			local pre="${g%%\{*}" body="${g#*\{}"; body="${body%\}*}"
			local IFS=,; for e in $body; do printf -- '--include=%s%s\n' "$pre" "$e"; done
		else
			printf -- '--include=%s\n' "$g"
		fi
	}
	# --include must precede --exclude: grep includes unmatched files when the first option is --exclude.
	search_raw() { local inc=() l; while IFS= read -r l; do inc+=( "$l" ); done < <(incl "$2"); grep -rnE "${GREP_EXCL[@]}" "${inc[@]}" --exclude='*.min.js' --exclude='*.min.css' -e "$1" "$ROOT" 2>/dev/null | awk 'length($0) < 400'; }
	files_raw() { find "$ROOT" \( -name node_modules -o -name vendor -o -name build -o -name dist -o -name .git -o -name tests -o -name test -o -name __tests__ -o -name e2e -o -name e2e-tests \) -prune -o -type f -name "$1" -print 2>/dev/null; }
fi

# Compiled-only distribution: no source block.json, but built ones in build/ or dist/ (any depth).
BUILT_BJ=""
if [ -z "$(files_raw 'block.json' | head -1)" ]; then
	BUILT_BJ="$(find "$ROOT" -maxdepth 6 \( -name node_modules -o -name vendor -o -name .git -o -name src \) -prune -o -type f -name block.json -path '*/build/*' -print -o -type f -name block.json -path '*/dist/*' -print 2>/dev/null | sort)"
fi
files() {
	# Sorted so rg and find (grep fallback) give identical, deterministic output.
	if [ "$1" = "block.json" ] && [ -n "$BUILT_BJ" ]; then echo "$BUILT_BJ"; else files_raw "$1" | sort; fi
}
search() {
	# Pseudo-globs that need several patterns (nested braces are not portable).
	local g
	case "$2" in
		__DEPR__) for g in '*deprecat*.{js,jsx,ts,tsx}' '*oldVersion*.{js,jsx,ts,tsx}' '*old-version*.{js,jsx,ts,tsx}' '*legacy*.{js,jsx,ts,tsx}'; do search_raw "$1" "$g"; done | sort -u; return ;;
		__SAVEDEPR__) for g in 'save.*' '*deprecat*.{js,jsx,ts,tsx}' '*oldVersion*.{js,jsx,ts,tsx}'; do search_raw "$1" "$g"; done | sort -u; return ;;
	esac
	if [ "$2" = "block.json" ] && [ -n "$BUILT_BJ" ]; then
		echo "$BUILT_BJ" | while IFS= read -r f; do grep -nE -e "$1" "$f" | sed "s#^#$f:#"; done
	else
		search_raw "$1" "$2"
	fi
}

# missing FILE_GLOB PATTERN -> files matching glob that do NOT contain pattern
missing() {
	files "$1" | while IFS= read -r f; do
		grep -qE -e "$2" "$f" || echo "$f"
	done
}

section() { printf '\n=== %s ===\n' "$1"; }
check() {
	# check LABEL COMMAND...  (more than 6 result lines: count + first 3)
	local label="$1"; shift
	local out n
	out="$("$@")"
	[ -z "$out" ] && return
	n="$(echo "$out" | wc -l | tr -d ' ')"
	if [ "$n" -gt 6 ]; then
		printf -- '--- %s: %s items\n%s\n  ...\n' "$label" "$n" "$(echo "$out" | head -3)"
	else
		printf -- '--- %s\n%s\n' "$label" "$out"
	fi
}

JS='*.{js,jsx,ts,tsx}'

# Vendored third-party files: permissive license header in the first 30 lines.
VENDORED="$(find "$ROOT" \( -name node_modules -o -name vendor -o -name .git -o -name build -o -name dist \) -prune -o -type f \( -name '*.php' -o -name '*.js' \) -print 2>/dev/null \
	| while IFS= read -r f; do head -30 "$f" | grep -qE 'MIT License|@license[[:space:]]+(MIT|BSD|Apache)|Licensed under the (MIT|Apache|BSD)|SPDX-License-Identifier:[[:space:]]*(MIT|BSD|Apache)' && echo "$f"; done)"
grouped() {
	# grouped LABEL  (reads file:line:text on stdin; drops vendored files)
	local label="$1" data
	data="$(cat)"
	[ -n "$VENDORED" ] && data="$(echo "$data" | grep -vF -f <(echo "$VENDORED" | sed 's/$/:/'))"
	[ -z "$data" ] && return
	echo "--- $label"
	local nfiles
	nfiles="$(echo "$data" | cut -d: -f1 | sort -u | wc -l | tr -d ' ')"
	echo "$data" | cut -d: -f1 | sort | uniq -c | sort -rn | head -8 | while read -r n f; do
		echo "  $f ($n hits)"
		echo "$data" | grep -F "$f:" | head -5 | cut -d: -f2- | sed 's/^/    /' | cut -c1-160
	done
	[ "$nfiles" -gt 8 ] && echo "  ... $((nfiles - 8)) more file(s), $(echo "$data" | wc -l | tr -d ' ') hits total"
}

BLOCK_JSON_COUNT="$(files 'block.json' | sed '/^$/d' | wc -l | tr -d ' ')"
echo "Block scan: $ROOT"
if [ -n "$BUILT_BJ" ]; then
	echo "block.json files found: $BLOCK_JSON_COUNT (BUILT only, no source block.json)"
else
	echo "block.json files found: $BLOCK_JSON_COUNT"
fi
files 'block.json' | head -15 | sed 's/^/  /'
[ "$BLOCK_JSON_COUNT" -gt 15 ] && echo "  ... ($((BLOCK_JSON_COUNT - 15)) more)"

# No-build mode: no package.json and no ES imports from @wordpress/*.
# Scripts then use wp.* globals and hand-written *.asset.php dependency lists.
NO_BUILD=0
COMPILED_ONLY=0
BUNDLER_CONFIG="$(find "$ROOT" -maxdepth 2 \( -name node_modules -prune \) -o -type f \( -name 'webpack.config*' -o -name 'vite.config*' -o -name 'rollup.config*' \) -print 2>/dev/null | head -1)"
if [ -n "$BUILT_BJ" ] && [ ! -d "$ROOT/src" ]; then
	COMPILED_ONLY=1
	echo "Mode: COMPILED-ONLY (built output shipped, JS source absent: edit/save/deprecation checks NOT VERIFIABLE; block.json checks use built metadata)"
elif [ ! -f "$ROOT/package.json" ] && [ -z "$BUNDLER_CONFIG" ] && [ -z "$(search "^[[:space:]]*import .*['\"]@wordpress/" "$JS")" ]; then
	NO_BUILD=1
	echo "Mode: NO-BUILD (wp.* globals expected; deps from *.asset.php or wp_register_script; load references/legacy-js-blocks.md)"
else
	echo "Mode: BUILD (@wordpress/scripts or other bundler expected)"
	[ ! -f "$ROOT/package.json" ] && echo "WARNING: bundler config ${BUNDLER_CONFIG:-or ES imports} found but no package.json (incomplete source distribution?)"
fi

# Collection registration: manifest path must exist (when built) and the build must generate it.
COLLECTION_REG="$(search "wp_register_block_(types_from_)?metadata_collection[[:space:]]*\(" '*.php')"
if [ -n "$COLLECTION_REG" ]; then
	echo "Registration: block metadata collection (blocks-manifest.php)"
	# Resolve __DIR__ against the directory of the file that registers the collection.
	echo "$COLLECTION_REG" | while IFS= read -r line; do
		src="${line%%:*}"
		echo "$line" | grep -oE "__DIR__[[:space:]]*\.[[:space:]]*'[^']+manifest[^']*'" | sed -E "s/.*'([^']+)'/\1/" | while IFS= read -r rel; do
			mf="$(dirname "$src")$rel"
			if [ ! -f "$mf" ] && [ -d "$(dirname "$mf")" ]; then
				echo "WARNING: $src registers $rel but it does not exist in the build output (no blocks register)"
			fi
		done
	done
	if [ -f "$ROOT/package.json" ] && ! grep -qE 'blocks-manifest|build-blocks-manifest' "$ROOT/package.json"; then
		echo "WARNING: collection registration used but package.json scripts never generate blocks-manifest.php (--blocks-manifest)"
	fi
fi

# Legacy PHP registration: register_block_type( 'ns/name', ... ) with a string name.
# Name may sit on the next line, so read each call plus one line.
LEGACY_PHP="$(search 'register_block_type[[:space:]]*\(' '*.php' | cut -d: -f1 | sort -u | while IFS= read -r f; do
	# First argument is a quoted ns/name, on the call line or alone on the next line.
	awk -v f="$f" '
		/register_block_type[[:space:]]*\(/ {
			if ($0 ~ /register_block_type[[:space:]]*\([[:space:]]*["\047][a-z0-9-]+\/[a-z0-9-]+["\047]/) { print f ": " $0; next }
			if ($0 ~ /register_block_type[[:space:]]*\([[:space:]]*$/) { pending = 1; next }
		}
		pending { if ($0 ~ /^[[:space:]]*["\047][a-z0-9-]+\/[a-z0-9-]+["\047][[:space:]]*,/) print f ": " $0; pending = 0 }
	' "$f"
done)"
if [ -n "$LEGACY_PHP" ]; then
	echo "Legacy PHP-registered blocks: $(echo "$LEGACY_PHP" | wc -l | tr -d ' ') call(s) (attributes declared in PHP; load references/render-security.md)"
fi
HAS_JS_REG="$(search '(^|[^a-zA-Z_])registerBlockType' "$JS" | head -1)"
HAS_PHP_REG="$(search 'register_block_type(_from_metadata)?[[:space:]]*\(|wp_register_block_(types_from_)?metadata_collection' '*.php' | head -1)"
if [ "$BLOCK_JSON_COUNT" -eq 0 ] && [ -z "$HAS_JS_REG" ] && [ -z "$HAS_PHP_REG" ]; then
	echo "SCOPE: no blocks registered (no block.json, registerBlockType, or register_block_type)."
	echo "       Editor-extension plugin: block checks mostly N/A. Review only block-editor integration"
	echo "       (registerPlugin, editor/blocks filters, patterns, style variations, inserted block markup)."
elif [ "$BLOCK_JSON_COUNT" -eq 0 ] && [ -z "$HAS_JS_REG" ]; then
	echo "No JS block source found (compiled only?): mark edit/save checks NOT VERIFIABLE"
fi

if [ -n "$VENDORED" ]; then
	echo "Vendored third-party files (license header; excluded from line heuristics, review only how the plugin calls them):"
	echo "$VENDORED" | head -10 | sed 's/^/  /'
fi

# Files that call registerBlockType with edit/save defined inline (no edit.* sibling).
inline_block_files() {
	search '(^|[^a-zA-Z_])registerBlockType(<[^>]*>)?[[:space:]]*\(' "$JS" | cut -d: -f1 | sort -u | while IFS= read -r f; do
		d="$(dirname "$f")"
		ls "$d"/edit.* >/dev/null 2>&1 && continue
		# Registration wrappers (helper that forwards options) define no edit/save of their own.
		grep -qE '(^|[^a-zA-Z_])(edit|save)[[:space:]]*(:|\()' "$f" || continue
		echo "$f"
	done
}
INLINE_FILES="$(inline_block_files)"

# apiVersion 1 when no block.json declares 2+ and no JS registration passes apiVersion.
API_V1=0
if [ -z "$(search '"apiVersion"[[:space:]]*:[[:space:]]*[23]' 'block.json')" ] && [ -z "$(search 'apiVersion[[:space:]]*:[[:space:]]*[23]' "$JS")" ] && [ -n "$(search 'registerBlockType' "$JS")" ]; then
	API_V1=1
	echo "apiVersion: 1 (no block.json or JS apiVersion 2+): useBlockProps checks skipped; load references/legacy-js-blocks.md"
fi
[ -n "$INLINE_FILES" ] && printf 'Inline edit/save files (checked like edit.*/save.*):\n%s\n' "$(echo "$INLINE_FILES" | sed 's/^/  /')"

# missing_inline PATTERN [SKIP_IF] -> inline block files that do NOT contain pattern
# (files matching SKIP_IF are exempt).
missing_inline() {
	[ -z "$INLINE_FILES" ] && return
	echo "$INLINE_FILES" | while IFS= read -r f; do
		[ -n "${2:-}" ] && tr '\n\t' '  ' < "$f" | grep -qE -e "$2" && continue
		grep -qE -e "$1" "$f" || echo "$f"
	done
}
# Save returning null (dynamic or placeholder block): no useBlockProps.save() needed.
SAVE_NULL='[sS]ave[[:space:]]*:[[:space:]]*\([^)]*\)[[:space:]]*=>[[:space:]]*(null|<InnerBlocks\.Content[[:space:]]*/>|\{[^}]*return[[:space:]]+null)|[sS]ave[[:space:]]*\([^)]*\)[[:space:]]*\{[[:space:]]*return[[:space:]]+(null|<InnerBlocks\.Content[[:space:]]*/>)'
# Placeholder blocks that swap themselves out render no wrapper.
PLACEHOLDER='replaceBlocks?[[:space:]]*\('


section "CRITICAL candidates"
check "wp_kses_post() on \$content (breaks embeds)" \
	search 'wp_kses_post[[:space:]]*\([[:space:]]*\$content[[:space:]]*\)' '*.php'
if [ "$BLOCK_JSON_COUNT" -gt 0 ] && [ -z "$(search 'register_block_type(_from_metadata)?[[:space:]]*\(|wp_register_block_(types_from_)?metadata_collection' '*.php')" ]; then
	echo "--- No block registration found in PHP (register_block_type or metadata collection)"
fi
search '<InnerBlocks[[:space:]>/]|useInnerBlocksProps' "$JS" \
	| grouped "InnerBlocks used (confirm save returns <InnerBlocks.Content />, not null)"
check "save() returning null (cross-check with InnerBlocks list above)" \
	search 'return[[:space:]]+null' 'save.*'
if [ "$API_V1" -eq 0 ]; then
	# Dynamic saves (null or bare InnerBlocks.Content) need no wrapper props.
	missing_save() {
		files 'save.*' | while IFS= read -r f; do
			tr '\n\t' '  ' < "$f" | grep -qE -e "$SAVE_NULL" && continue
			grep -qE 'useBlockProps\.save' "$f" || echo "$f"
		done
	}
	check "Save files without useBlockProps.save() (apiVersion 2+ static blocks)" missing_save
fi
if [ "$API_V1" -eq 0 ]; then
	check "Inline block files without useBlockProps.save() (apiVersion 2+ static blocks)" \
		missing_inline 'useBlockProps\.save' "$SAVE_NULL"
fi
if [ "$NO_BUILD" -eq 1 ]; then
	check "JSX or ES import in unbuilt script (browser cannot parse; block never registers)" \
		search "^[[:space:]]*import[[:space:]]|return[[:space:]]*\(?[[:space:]]*<[A-Za-z]" "$JS"
	# Compare wp.* globals used in each script against its sibling *.asset.php.
	files '*.asset.php' | while IFS= read -r asset; do
		js="${asset%.asset.php}.js"
		[ -f "$js" ] || continue
		used="$(grep -oE '\bwp\.[a-zA-Z0-9]+' "$js" | sed -E 's/^wp\.//; s/([A-Z])/-\1/g' | tr 'A-Z' 'a-z' | sed 's/^/wp-/' | sort -u)"
		declared="$(grep -oE "['\"]wp-[a-z0-9-]+['\"]" "$asset" | tr -d "'\"" | sort -u)"
		miss="$(comm -23 <(echo "$used") <(echo "$declared") | sed '/^$/d')"
		extra="$(comm -13 <(echo "$used") <(echo "$declared") | sed '/^$/d')"
		[ -n "$miss" ] && printf -- '--- Globals used but not in %s dependencies (undefined at load):\n%s\n' "$asset" "$miss"
		[ -n "$extra" ] && printf -- '--- INFO: %s declares unused dependencies:\n%s\n' "$asset" "$extra"
	done
	files 'block.json' | while IFS= read -r bj; do
		d="$(dirname "$bj")"
		grep -oE '"(editorScript|script|viewScript)"[[:space:]]*:[[:space:]]*"file:\./[^"]+\.js"' "$bj" | sed -E 's/.*file:\.\/([^"]+)\.js"/\1/' | while IFS= read -r base; do
			[ -f "$d/$base.asset.php" ] || echo "--- No $d/$base.asset.php: script registers with NO dependencies (wp.* undefined at load)"
		done
	done
fi

# PHP render heuristics. Grouped per file, first 5 hits shown.
ESC_OK='esc_(html|attr|url|textarea|js)|wp_kses|sanitize_|absint|intval|\(int\)|\(float\)|wp_json_encode|get_block_wrapper_attributes|_e\(|printf\([[:space:]]*esc'
search "(<[a-zA-Z/]|=[[:space:]]*\\?[\"'])[^;]*\\\$(attributes|attrs|atts|attr)\\[" '*.php' | grep -vE "$ESC_OK" \
	| grouped "Attribute value concatenated into HTML without esc_*/kses (confirm context)"
search "^[[:space:]]*\\\$(attributes|attrs|atts|attr)\\[[^]]+\\][[:space:]]*,?[[:space:]]*\\)?;?[[:space:]]*$" '*.php' \
	| grouped "Bare attribute passed as sprintf/printf argument (confirm escaping)"
search "<[[:space:]]*['\"]?[[:space:]]*\\.[[:space:]]*\\\$|\"<\\\$[a-zA-Z_]|'<'[[:space:]]*\\.[[:space:]]*\\\$" '*.php' | grep -v 'in_array' \
	| grouped "Tag name built from a variable (needs allowlist)"
search 'u003c|u003e|u0022' '*.php' \
	| grouped "Unicode-escape decoder (CRITICAL if it runs after kses)"
search "=\\\\?'%s\\\\?'|=\\\\?'\\\"?[[:space:]]*\\.[[:space:]]*(wp_)?json_encode" '*.php' \
	| grouped "Single-quoted HTML attribute holding %s or JSON (json_encode does not escape ')"
# Quote-breakout: raw variable inside a quoted HTML attribute. Core kses leaves '"' in tag-free strings alone.
RAWATTR=$'=\\\\?"\'[[:space:]]*\\.[[:space:]]*\\$[a-zA-Z_]'
search "$RAWATTR" '*.php' | grep -vE "$ESC_OK" \
	| grouped "Raw variable concatenated into a quoted HTML attribute (quote breakout; kses does not strip \")"
search "(^|[^_a-zA-Z])json_encode[[:space:]]*\(" '*.php' | grep -vE "esc_attr|<script|wp_send_json|header\(|echo[[:space:]]+json_encode[[:space:]]*\([^)]*\);[[:space:]]*(exit|die|wp_die)|return[[:space:]]+json_encode" \
	| grouped "json_encode() output (in an HTML attribute use esc_attr( wp_json_encode() ); json_encode does not escape \" for HTML)"
search "register_block_type_from_metadata[[:space:]]*\([[:space:]]*(['\"][a-z0-9-]+/[a-z0-9-]+['\"]|\\\$[a-zA-Z_]*(type_id|block_name|blockName)[[:space:]]*,)" '*.php' \
	| grouped "register_block_type_from_metadata() given a block name, not a path (returns false; block never registers server-side)"
# Raw echo of a variable in render code (render files and files with render callbacks).
RENDER_SET="$( { files 'render.php'; search 'render_callback' '*.php' | cut -d: -f1; } | sort -u | sed '/^$/d')"
if [ -n "$RENDER_SET" ]; then
	echo "$RENDER_SET" | while IFS= read -r f; do
		grep -nE '(echo|print|<\?=)[[:space:]]+\$[a-zA-Z_][a-zA-Z0-9_]*(\[[^]]*\]|->[a-zA-Z_]+)*[[:space:]]*;' "$f" \
			| grep -vE '\$(wrapper_attributes|wrapper|block_wrapper|content|inner_blocks|inner_content|block_content|html|output|markup|svg|icon)[[:space:]]*;' \
			| sed "s#^#$f:#"
	done | grouped "Raw echo of a variable in render code (escape at output: esc_html / esc_attr / esc_url / wp_kses_post)"
	echo "$RENDER_SET" | while IFS= read -r f; do
		grep -qE '\$post[[:space:]]*=[[:space:]]*get_post[[:space:]]*\([[:space:]]*\)|global[[:space:]]+\$post' "$f" || continue
		grep -qE 'instanceof[[:space:]]+WP_Post|!?[[:space:]]*\$post[[:space:]]*\)|empty[[:space:]]*\([[:space:]]*\$post|is_null[[:space:]]*\([[:space:]]*\$post|null[[:space:]]*===[[:space:]]*\$post' "$f" && continue
		grep -nE '\$post->' "$f" | head -1 | sed "s#^#$f:#"
	done | grouped "\$post used without a null check in render code (fatal in widgets, REST previews, templates)"
fi
search "[a-zA-Z-]=<\?(php|=)" '*.php' \
	| grouped "Unquoted HTML attribute value from PHP (attr=<?php ...): breaks on spaces, injectable"
search "json_decode[[:space:]]*\\([^)]*\\\$_(POST|GET|REQUEST)" '*.php' \
	| grouped "json_decode of request data (CRITICAL if it builds WP_Query args in a public handler)"
search "wp_ajax_nopriv_" '*.php' \
	| grouped "Public AJAX handlers (check nonce and server-built query args)"

section "WARNING candidates"
check "block.json with apiVersion missing or below 2" \
	missing 'block.json' '"apiVersion"[[:space:]]*:[[:space:]]*[23]'
if [ "$NO_BUILD" -eq 0 ]; then
	n_glob="$(search '(window\.)?\bwp\.(blocks|blockEditor|editor|components|element|data|i18n|apiFetch|compose)\b' "$JS" | cut -d: -f1 | sort -u | wc -l | tr -d ' ')"
	[ "$n_glob" -gt 0 ] && echo "--- wp.* global access in a build project: $n_glob file(s) (use @wordpress/* imports + dependency extraction)"
fi
# JSX props anywhere; object-key form (createElement props) only in files that use Button.
{ search '\bis(Small|Large|Primary|Secondary|Tertiary|Link)\b[[:space:]]*($|=|/?>|\{)' "$JS"
  search '\bis(Small|Large|Primary|Secondary|Tertiary|Link)[[:space:]]*:' "$JS" | while IFS= read -r l; do grep -qE '\bButton\b' "${l%%:*}" && echo "$l"; done; } | sort -u \
	| grouped "Deprecated Button props (isSmall, isLarge, isPrimary, isSecondary, isTertiary, isLink)"
check "Deprecated wp.editor / @wordpress/editor block components (use block-editor)" \
	search "wp\.editor\.(RichText|InspectorControls|BlockControls|InnerBlocks|MediaUpload|PlainText|AlignmentToolbar)|from ['\"]@wordpress/editor['\"]|=[[:space:]]*wp\\.editor[[:space:]]*;" "$JS"
check "Attribute source: meta (deprecated, use useEntityProp)" \
	search '"source"[[:space:]]*:[[:space:]]*"meta"' 'block.json'
if [ "$API_V1" -eq 0 ]; then
	check "Edit files without useBlockProps (apiVersion 2+)" \
		missing 'edit.*' 'useBlockProps'
	check "Inline block files without useBlockProps (apiVersion 2+; edit may be delegated to an imported component: confirm there)" \
		missing_inline 'useBlockProps[[:space:]]*\(' "$PLACEHOLDER"
else
	echo "--- apiVersion 1 blocks (upgrade to 3 needs useBlockProps in edit/save plus deprecations)"
fi
check "render.php without get_block_wrapper_attributes()" \
	missing 'render.php' 'get_block_wrapper_attributes'
check "render.php without ABSPATH guard" \
	missing 'render.php' "defined[[:space:]]*\([[:space:]]*['\"]ABSPATH"
check "Non-deterministic save (Math.random / Date.now / new Date)" \
	search 'Math\.random|Date\.now|new Date\(' 'save.*'
search "\\b(__|_x|_n|esc_html__|esc_attr__)\\([[:space:]]*['\"][^'\"]*['\"][[:space:]]*\\)" "$JS" \
	| grouped "JS i18n calls without text domain ('default' domain: plugin translations never apply)"
check "Deprecated attribute source children/node (use html / rich-text)" \
	search "source['\"]?[[:space:]]*:[[:space:]]*['\"](children|node)['\"]" "$JS"
search "['\"]wp-edit-post['\"]" '*.php' | grep -vE 'unset|array_search|array_diff|in_array' \
	| grouped "Editor script depends on wp-edit-post (triggers _doing_it_wrong in widgets/site editor)"
search 'has_block[[:space:]]*\(' '*.php' | grep -vE '^[^:]+:[0-9]+:[[:space:]]*(\*|//)' \
	| grouped "Frontend assets enqueued via has_block() (misses blocks in widgets, templates, patterns, synced patterns)"
if [ "$NO_BUILD" -eq 0 ] && [ -z "$(find "$ROOT" \( -name node_modules -o -name vendor -o -name .git \) -prune -o -type f -name '*.asset.php' -print -quit 2>/dev/null)" ]; then
	# Hand-registered editor script in a build project: diff globals vs declared deps.
	deps_line="$(search "array\\([[:space:]]*'wp-[a-z0-9-]+'.*'wp-blocks'|'wp-blocks'.*'wp-[a-z0-9-]+'" '*.php' | head -1)"
	if [ -n "$deps_line" ]; then
		used="$(search '\bwp\.[a-zA-Z0-9]+' "$JS" | grep -oE '\bwp\.[a-zA-Z0-9]+' | sed -E 's/^wp\.//; s/([A-Z])/-\1/g' | tr 'A-Z' 'a-z' | sed 's/^/wp-/' | sort -u)"
		declared="$(echo "$deps_line" | grep -oE "'wp-[a-z0-9-]+'" | tr -d "'" | sort -u)"
		miss="$(comm -23 <(echo "$used") <(echo "$declared") | sed '/^$/d' | tr '\n' ' ')"
		[ -n "$miss" ] && echo "--- Globals used in src/ but not in editor script deps ($(echo "$deps_line" | cut -d: -f1-2)): $miss(works only if loaded transitively)"
	fi
fi
# Text domains used in JS/PHP i18n calls that differ from block.json textdomain / plugin header.
want="$( { files 'block.json' | while IFS= read -r f; do grep -oE '"textdomain"[[:space:]]*:[[:space:]]*"[^"]+"' "$f"; done | sed -E 's/.*"([^"]+)"$/\1/'; \
	search 'Text Domain:' '*.php' | sed -E 's/.*Text Domain:[[:space:]]*//' | tr -d '\r '; } | sort -u | sed '/^$/d')"
if [ -n "$want" ]; then
	search "\b(__|_e|_x|_n|_nx|esc_html__|esc_html_e|esc_attr__|esc_attr_e)[[:space:]]*\(.*['\"],[[:space:]]*['\"][a-z0-9_-]+['\"][[:space:]]*\)" "*.{php,js,jsx,ts,tsx}" \
		| while IFS= read -r line; do
			# Domain = last argument of each complete i18n call on the line.
			bad="$(echo "$line" | grep -oE "\b(__|_e|_x|_n|_nx|esc_html__|esc_html_e|esc_attr__|esc_attr_e)[[:space:]]*\(([^()]|\([^()]*\))*,[[:space:]]*['\"][a-z0-9_-]+['\"][[:space:]]*\)" \
				| sed -E "s/.*['\"]([a-z0-9_-]+)['\"][[:space:]]*\)$/\1/" | while IFS= read -r dom; do
					echo "$want" | grep -qxF "$dom" || [ "$dom" = "default" ] || echo "$dom"
				done)"
			[ -n "$bad" ] && echo "$line"
		done | grouped "i18n text domain not matching block.json textdomain / plugin header ($(echo "$want" | tr '\n' ' '))"
fi
hdr_dom="$(search 'Text Domain:' '*.php' | head -1 | sed -E 's/.*Text Domain:[[:space:]]*//' | tr -d '\r ')"
bj_dom="$(files 'block.json' | while IFS= read -r f; do grep -oE '"textdomain"[[:space:]]*:[[:space:]]*"[^"]+"' "$f"; done | sed -E 's/.*"([^"]+)"$/\1/' | sort -u | tr '\n' ' ' | sed 's/ $//')"
if [ -n "$hdr_dom" ] && [ -n "$bj_dom" ] && [ "$bj_dom" != "$hdr_dom" ]; then
	echo "--- block.json textdomain ($bj_dom) differs from plugin header Text Domain ($hdr_dom): block.json strings and JS translations load under a different domain"
fi
# block.json "style": file:./style-index.css needs a style.(s)css source next to it.
files 'block.json' | while IFS= read -r f; do
	d="$(dirname "$f")"
	case "$f" in */build/*|*/dist/*) continue ;; esac
	if grep -qE '"file:\./style-index\.css"' "$f" && [ -z "$(find "$d" -type f \( -name 'style.css' -o -name 'style.scss' -o -name 'style.sass' \) | head -1)" ]; then
		echo "--- $f declares style-index.css but no style.(s)css exists under $d (wp-scripts only emits style-index.css for imported style.* files)"
	fi
done
# Requires at least vs features used.
req="$( { search 'Requires at least:' '*.php'; [ -f "$ROOT/readme.txt" ] && grep -n 'Requires at least:' "$ROOT/readme.txt"; } | grep -oE '[0-9]+\.[0-9]+' | sort -t. -k1,1n -k2,2n | head -1)"
if [ -n "$req" ]; then
	need=""
	[ -n "$(search '"apiVersion"[[:space:]]*:[[:space:]]*3' 'block.json')" ] && need="6.3 (apiVersion 3)"
	[ -n "$( { search 'viewScriptModule' 'block.json'; search 'data-wp-interactive|wp_interactivity_' '*.php'; search "from[[:space:]]+['\"]@wordpress/interactivity" "$JS"; } )" ] && need="6.5 (Interactivity API / viewScriptModule)"
	if [ -n "$need" ]; then
		nv="${need%% *}"
		awk -v a="$req" -v b="$nv" 'BEGIN { split(a,x,"."); split(b,y,"."); exit !((x[1]<y[1]) || (x[1]==y[1] && x[2]<y[2])) }' \
			&& echo "--- Plugin header Requires at least: $req, but code needs $need"
	fi
fi
search "navigator\.language|\.toLocale(String|DateString|TimeString)\(|Intl\.(DateTimeFormat|NumberFormat)" "$JS" \
	| grouped "Locale/timezone-dependent output (validation error if reachable from a static save)"
search "default[[:space:]]*:[[:space:]]*(__|_x|sprintf)[[:space:]]*\(" "$JS" \
	| grouped "Translated attribute default (defaults are not serialized: saved markup changes with editor locale)"
# Deprecation hygiene.
search "^[[:space:]]*import[[:space:]].*from[[:space:]]+['\"]\./(components|edit|editor|block|save)[a-zA-Z/]*['\"]|from[[:space:]]+['\"](\.\./)+(common|inc|components)" "__DEPR__" \
	| grouped "Deprecation file imports live shared code (frozen markup changes when that code changes)"
search "parent[[:space:]]*:[[:space:]]*(__|_x)?\(?['\"]" "$JS" \
	| grouped "Block 'parent' set to a string, not an array (restriction ignored)"
search "Object\.assign[[:space:]]*\([[:space:]]*(props\.)?attributes[[:space:]]*," "$JS" \
	| grouped "Mutating attributes in place (use setAttributes)"
search "\b(__|_x|_n)\([[:space:]]*\`" "$JS" \
	| grouped "Template literal in i18n call (not extractable by makepot)"
search "\b(__|_x|_n)\([[:space:]]*['\"](show|hide|more|less|expand|collapse|copy|copied)['\"]" "__SAVEDEPR__" \
	| grouped "__() in save/deprecation output (saved markup depends on editor locale)"
search "applyFilters[[:space:]]*\(" "$JS" \
	| grouped "applyFilters() in JS (validation error if reachable from a static save: markup changes when a filter is added/removed)"
search "wp_set_script_translations[[:space:]]*\([[:space:]]*['\"][a-z0-9-]+/[a-z0-9-]+['\"]" '*.php' \
	| grouped "INFO: wp_set_script_translations() given a block name, not a script handle (no-op; block.json textdomain already covers editorScript)"
search "block-editor-warning" "$JS" \
	| grouped "Code touching .block-editor-warning (hiding or relabelling block validation errors?)"
# registerBlockType files that import block.json and also redeclare attributes/title.
search "(^|[^a-zA-Z_])registerBlockType(<[^>]*>)?[[:space:]]*\(" "$JS" | cut -d: -f1 | sort -u | while IFS= read -r f; do
	grep -qE "from[[:space:]]+['\"][^'\"]*block\.json['\"]" "$f" || continue
	grep -qE "\.\.\.[a-zA-Z_]*([mM]etadata|[cC]onfig|[jJ]son|[bB]lock)[a-zA-Z_]*[[:space:]]*,?$" "$f" || continue
	grep -nE "^(	|  |    )(attributes[[:space:]]*:[[:space:]]*\{|title[[:space:]]*:[[:space:]]*(__|_x)?\(?['\"])" "$f" | sed "s#^#$f:#"
done | grouped "registerBlockType() redeclares attributes/title already in block.json (schemas drift; server sees block.json only)"
# Static save with no deprecated array anywhere.
if [ -n "$(search "save[[:space:]]*[:(=]" "$JS" | grep -v "return null\|=> null")" ] && [ -z "$(search "deprecated" "$JS")" ] && [ -n "$(search 'registerBlockType' "$JS")" ]; then
	STATIC_NO_DEPR=1
fi
# REST routes whose files write options without sanitize/args schema.
search "register_rest_route|::post[[:space:]]*\(" '*.php' | cut -d: -f1 | sort -u | while IFS= read -r f; do
	grep -nE "update_option[[:space:]]*\(|update_user_meta[[:space:]]*\(|update_post_meta[[:space:]]*\(" "$f" | sed "s#^#$f:#"
done | grep -vE "sanitize_|absint|intval|wp_kses" \
	| grouped "REST handler writes options/meta without visible sanitizing (check permission_callback capability and args schema)"
search "file_get_contents[[:space:]]*\([^)]*(build|dist)/" '*.php' \
	| grouped "file_get_contents() of build output at runtime (no existence check; disk read per request)"
check "Hardcoded label/title strings in JS (confirm __() wrap)" \
	search "(label|title|placeholder)[[:space:]]*[:=][[:space:]]*['\"][A-Z]" "$JS"
search "register_block_type(_from_metadata)?[[:space:]]*\(" '*.php' | cut -d: -f1 | sort -u | while IFS= read -r f; do
	grep -qE "__DIR__|dirname|/build|/dist|_PATH|plugin_dir_path" "$f" || continue
	grep -nE "['\"]attributes['\"][[:space:]]*=>" "$f" | sed "s#^#$f:#"
done | grouped "Server-side 'attributes' passed when registering from block.json (replaces block.json schema; drift and array/object type resets)"
search "extract[[:space:]]*\\([[:space:]]*\\\$(attributes|attrs|atts|attr)" '*.php' \
	| grouped "extract() on block attributes"
search "add_filter[[:space:]]*\\([[:space:]]*['\"](wp_kses_allowed_html|safe_style_css)" '*.php' \
	| grouped "kses allowlist widened via filter (WARNING if added during render)"
RENDER_FILES="$( { search 'render_callback' '*.php'; files 'render.php' | sed 's/$/:/'; } | cut -d: -f1 | sort -u)"
if [ -n "$RENDER_FILES" ]; then
	echo "$RENDER_FILES" | while IFS= read -r f; do
		grep -nE "wp_(safe_)?remote_(get|post|request)|media_handle_sideload|wp_insert_term|wp_insert_post[[:space:]]*\\(|update_post_meta|update_option|query_posts" "$f" | sed "s#^#$f:#"
	done | grouped "Possible render side effects in files with render callbacks (confirm call is in render path)"
	echo "$RENDER_FILES" | while IFS= read -r f; do
		grep -nE "(posts_per_page|numberposts)['\"]?[[:space:]]*=>[[:space:]]*-1" "$f" | sed "s#^#$f:#"
	done | grouped "Unbounded query in files with render callbacks"
fi
check "block.json without supports" \
	missing 'block.json' '"supports"'

section "INFO candidates"
[ "${STATIC_NO_DEPR:-0}" -eq 1 ] && echo "--- Static save with no deprecated array (risk note only: matters once markup has shipped and changed)"
check "apiVersion 2 (upgrade to 3 available)" \
	search '"apiVersion"[[:space:]]*:[[:space:]]*2' 'block.json'
check "block.json without \$schema" \
	missing 'block.json' '"\$schema"'
check "block.json without keywords" \
	missing 'block.json' '"keywords"'
if [ "$BLOCK_JSON_COUNT" -gt 0 ]; then
	search 'render_callback' '*.php' | grep -vE '^[^:]+:[0-9]+:[[:space:]]*(\*|//|#)' \
		| grouped "render_callback in PHP (render file in block.json preferred)"
else
	n_rc="$(search 'render_callback' '*.php' | wc -l | tr -d ' ')"
	[ "$n_rc" -gt 0 ] && echo "--- $n_rc render_callback(s) with no block.json (block.json migration is a long-term INFO, not per-block)"
fi
search 'useSelect[[:space:]]*\(' "$JS" | cut -d: -f1 | sort -u | while IFS= read -r f; do
	n="$(grep -oE 'useSelect[[:space:]]*\(' "$f" | wc -l | tr -d ' ')"
	[ "$n" -gt 1 ] && echo "--- Repeated useSelect ($n calls, consider one combined call): $f"
done

# check_paths BUILT_BLOCK_JSON: every file: path (scripts, styles, render) must exist.
# Missing script/render breaks the block (CRITICAL); missing stylesheet only drops styles (WARNING).
check_paths() {
	local bb="$1" d kv field rel hint
	d="$(dirname "$bb")"
	grep -oE '"[a-zA-Z]+"[[:space:]]*:[[:space:]]*(\[[^]]*\]|"file:\./[^"]+")' "$bb" | while IFS= read -r kv; do
		field="$(echo "$kv" | sed -E 's/^"([a-zA-Z]+)".*/\1/')"
		echo "$kv" | grep -oE 'file:\./[^"]+' | sed 's#^file:\./##' | while IFS= read -r rel; do
			[ -e "$d/$rel" ] && continue
			case "$field" in
				style|editorStyle|viewStyle) echo "--- WARNING: $bb $field file:./$rel missing in $d (stylesheet silently not registered)" ;;
				viewScriptModule|scriptModule)
					hint=""
					[ -f "$ROOT/package.json" ] && ! grep -q 'experimental-modules' "$ROOT/package.json" && hint="; package.json build/start scripts lack --experimental-modules, so wp-scripts never emits script modules"
					echo "--- CRITICAL: $bb $field file:./$rel missing in $d (script module never loads$hint)" ;;
				*) echo "--- CRITICAL: $bb $field file:./$rel missing in $d (script or render never loads)" ;;
			esac
		done
	done
}

# check_build OUT_DIR: compare compiled output with src/.
check_build() {
	local OUT_DIR="$1" sb rel bb d ref cutoff newer_src assets declared imported miss
	norm() { tr -d ' \t\n\r' < "$1"; }
	mtime() { stat -c %Y "$1" 2>/dev/null || stat -f %m "$1"; }

	# Staleness, content first: built block.json must match src/block.json (ignoring whitespace).
	while IFS= read -r sb; do
		rel="${sb#"$ROOT/src/"}"
		bb="$OUT_DIR/$rel"
		[ -f "$bb" ] || bb="$OUT_DIR/block.json"
		if [ ! -f "$bb" ]; then
			echo "--- No built block.json for $sb in $OUT_DIR"
		elif [ "$(norm "$sb")" != "$(norm "$bb")" ]; then
			echo "--- $bb differs from $sb (stale build)"
		fi
	done < <(find "$ROOT/src" -name block.json)

	# Timestamp fallback against the NEWEST built file (webpack skips rewriting unchanged
	# outputs, so older entries keep old mtimes), with 120 s slack for copies and unzips.
	ref=""; local best=0 m f
	while IFS= read -r f; do
		m="$(mtime "$f")"; [ "$m" -gt "$best" ] && { best="$m"; ref="$f"; }
	done < <(find "$OUT_DIR" -type f \( -name '*.asset.php' -o -name '*.js' \))
	if [ -z "$ref" ]; then
		echo "--- $OUT_DIR has no compiled JS"
	else
		cutoff=$(( $(mtime "$ref") + 120 ))
		newer_src="$(find "$ROOT/src" -type f \( -name '*.js' -o -name '*.jsx' -o -name '*.ts' -o -name '*.tsx' -o -name '*.scss' -o -name 'block.json' \) | while IFS= read -r f; do [ "$(mtime "$f")" -gt "$cutoff" ] && echo "$f"; done | head -5)"
		[ -n "$newer_src" ] && printf -- '--- src/ files modified >2 min after %s (stale build?):\n%s\n' "$ref" "$newer_src"
	fi

	while IFS= read -r bb; do check_paths "$bb"; done < <(find "$OUT_DIR" -name block.json)

	# blocks-manifest.php must list exactly the built blocks.
	if [ -f "$OUT_DIR/blocks-manifest.php" ]; then
		local man_keys built_dirs man_names built_names
		man_keys="$(grep -oE "^(	|  |    )'[^']+'[[:space:]]*=>[[:space:]]*array" "$OUT_DIR/blocks-manifest.php" | sed -E "s/^[[:space:]]*'([^']+)'.*/\1/" | sort -u)"
		built_dirs="$(find "$OUT_DIR" -mindepth 2 -name block.json | sed "s#^$OUT_DIR/##; s#/block.json\$##" | sort -u)"
		miss="$(comm -13 <(echo "$man_keys") <(echo "$built_dirs") | sed '/^$/d' | tr '\n' ' ')"
		[ -n "$miss" ] && echo "--- CRITICAL: built blocks missing from blocks-manifest.php (never registered by the collection): $miss"
		miss="$(comm -23 <(echo "$man_keys") <(echo "$built_dirs") | sed '/^$/d' | tr '\n' ' ')"
		[ -n "$miss" ] && echo "--- WARNING: blocks-manifest.php lists blocks with no built block.json (stale manifest): $miss"
		man_names="$(grep -oE "'name'[[:space:]]*=>[[:space:]]*'[^']+'" "$OUT_DIR/blocks-manifest.php" | sed -E "s/.*'([^']+)'$/\1/" | sort -u)"
		built_names="$(find "$OUT_DIR" -mindepth 2 -name block.json -exec grep -ohE '"name"[[:space:]]*:[[:space:]]*"[^"]+"' {} + | sed -E 's/.*"([^"]+)"$/\1/' | sort -u)"
		[ "$man_names" != "$built_names" ] && echo "--- WARNING: block names in blocks-manifest.php differ from built block.json files (stale manifest: rebuild with --blocks-manifest)"
	fi

	# @wordpress/* imports in src must appear in some *.asset.php (wp-scripts bundles a few packages itself).
	assets="$(find "$OUT_DIR" -name '*.asset.php')"
	if [ -n "$assets" ]; then
		# Classic assets list 'wp-x'; script-module assets list '@wordpress/x'.
		declared="$(echo "$assets" | while IFS= read -r f; do grep -oE "'(wp-|@wordpress/)[a-z0-9-]+'" "$f"; done | tr -d "'" | sed 's#^@wordpress/#wp-#' | sort -u)"
		bad_pkg="$(search "from[[:space:]]+['\"]@wordpress/[a-zA-Z0-9-]*[A-Z]" "$JS" | grep -oE "@wordpress/[a-zA-Z0-9-]+" | sort -u | tr '\n' ' ')"
		[ -n "$bad_pkg" ] && echo "--- Invalid @wordpress package name (camelCase; not externalized, may break build): $bad_pkg"
		imported="$(search "from[[:space:]]+['\"]@wordpress/[a-z0-9-]+['\"/]" "$JS" | grep -oE "@wordpress/[a-z0-9-]+" | sed 's#@wordpress/#wp-#' | sort -u \
			| grep -vxE 'wp-(icons|interface|sync|undo-manager|upload-media|fields|dataviews|scripts|dependency-extraction-webpack-plugin|e2e-test-utils-playwright|env|eslint-plugin|prettier-config|stylelint-config|babel-preset-default|base-styles)')"
		miss="$(comm -23 <(echo "$imported") <(echo "$declared") | sed '/^$/d' | tr '\n' ' ')"
		[ -n "$miss" ] && echo "--- Imported in src/ but absent from every *.asset.php (stale build or bundled copy): $miss"
	fi
	return 0
}

# Interactivity API cross-checks (run only when directives exist).
interactivity_checks() {
	local php_ns js_ns state_ns refs defined miss bj d rp vs
	[ -z "$(search 'data-wp-interactive' '*.php' | head -1)" ] && return
	section "Interactivity API cross-checks (load references/interactivity-api-guide.md)"

	# 1. Namespaces: directives vs store() vs wp_interactivity_state().
	php_ns="$(search "data-wp-interactive" '*.php' | grep -oE "data-wp-interactive=[\"'][^\"']+" | sed -E "s/.*=[\"']//; s/.*\"namespace\":\"//" | sed '/^{/d' | sort -u)"
	js_ns="$(search "(^|[^a-zA-Z_.])store[[:space:]]*\([[:space:]]*['\"][a-zA-Z0-9_/-]+['\"]" "$JS" | grep -oE "store[[:space:]]*\([[:space:]]*['\"][a-zA-Z0-9_/-]+" | sed -E "s/.*['\"]//" | sort -u)"
	state_ns="$(search "wp_interactivity_(state|config)[[:space:]]*\([[:space:]]*['\"]" '*.php' | grep -oE "wp_interactivity_(state|config)[[:space:]]*\([[:space:]]*['\"][a-zA-Z0-9_/-]+" | sed -E "s/.*['\"]//" | sort -u)"
	miss="$(comm -23 <(echo "$php_ns") <(echo "$js_ns") | sed '/^$/d' | tr '\n' ' ')"
	[ -n "$miss" ] && echo "--- WARNING: data-wp-interactive namespace(s) with no store() in JS: $miss(directives do nothing)"
	miss="$(comm -23 <(echo "$state_ns") <(echo "$js_ns" | cat - <(echo "$php_ns") | sort -u) | sed '/^$/d' | tr '\n' ' ')"
	[ -n "$miss" ] && echo "--- WARNING: wp_interactivity_state()/config() namespace(s) unused by any store or directive: $miss"

	# 2 + 3. Per block: directives need supports.interactivity; interactivity code needs viewScriptModule.
	files 'block.json' | while IFS= read -r bj; do
		d="$(dirname "$bj")"
		rp="$(find "$d" -maxdepth 1 -name 'render.php' | head -1)"
		if [ -n "$rp" ] && grep -qE 'data-wp-' "$rp" && ! grep -qE '"interactivity"[[:space:]]*:[[:space:]]*(true|\{)' "$bj"; then
			echo "--- WARNING: $rp has data-wp-* directives but $bj lacks supports.interactivity"
		fi
		grep -oE '"viewScript"[[:space:]]*:[[:space:]]*(\[[^]]*\]|"[^"]+")' "$bj" | grep -oE 'file:\./[^"]+' | sed 's#^file:\./##' | while IFS= read -r vs; do
			src="$(find "$d" -maxdepth 2 -name "$(basename "${vs%.*}").*" \( -name '*.js' -o -name '*.ts' -o -name '*.tsx' -o -name '*.jsx' \) | head -1)"
			[ -n "$src" ] && grep -qE "from[[:space:]]+['\"]@wordpress/interactivity" "$src" \
				&& echo "--- CRITICAL: $bj loads $vs as viewScript but it imports @wordpress/interactivity (needs viewScriptModule)"
		done
	done

	# 4. Directive references must exist in a store (JS) or server state (PHP).
	refs="$(search "data-wp-[a-z-]+(--[a-zA-Z0-9_-]+)?=[\"']!?(actions|state|callbacks)\." '*.php' \
		| grep -oE "(actions|state|callbacks)\.[a-zA-Z_][a-zA-Z0-9_]*" | sort -u)"
	if [ -n "$refs" ]; then
		defined="$( { search "@wordpress/interactivity" "$JS" | cut -d: -f1 | sort -u | while IFS= read -r f; do
				grep -oE "(^|[^a-zA-Z0-9_])(get[[:space:]]+)?[a-zA-Z_][a-zA-Z0-9_]*[[:space:]]*(:|\()" "$f" | grep -oE "[a-zA-Z_][a-zA-Z0-9_]*[[:space:]]*(:|\()" | grep -oE "^[a-zA-Z_][a-zA-Z0-9_]*"
			done
			search "wp_interactivity_state" '*.php' | cut -d: -f1 | sort -u | while IFS= read -r f; do
				grep -oE "['\"][a-zA-Z_][a-zA-Z0-9_]*['\"][[:space:]]*=>" "$f" | grep -oE "[a-zA-Z_][a-zA-Z0-9_]*"
			done; } | sort -u)"
		miss="$(echo "$refs" | while IFS= read -r r; do echo "$defined" | grep -qxF "${r#*.}" || echo "$r"; done | tr '\n' ' ')"
		[ -n "$miss" ] && echo "--- WARNING candidates: directive references not defined in any store or server state: $miss(typo, or defined dynamically: confirm)"
	fi

	# 6. Router without a router region.
	if [ -n "$(search "@wordpress/interactivity-router" "$JS" | head -1)" ] && [ -z "$( { search 'data-wp-router-region' '*.php'; search 'data-wp-router-region' '*.html'; } | head -1)" ]; then
		echo "--- WARNING: @wordpress/interactivity-router used but no data-wp-router-region (navigate() relies on the full-page navigation experiment)"
	fi
	# 7. Synchronous event access without withSyncEvent (WP 6.8+).
	search "@wordpress/interactivity" "$JS" | cut -d: -f1 | sort -u | while IFS= read -r f; do
		grep -q 'withSyncEvent' "$f" && continue
		grep -nE '\.(preventDefault|stopPropagation|stopImmediatePropagation)[[:space:]]*\(|event\.currentTarget' "$f" | sed "s#^#$f:#"
	done | grouped "Event used synchronously in an action without withSyncEvent() (6.8+ deprecation; default action may run)"
	# 8. Click handlers on non-interactive elements.
	search "<(div|span|li|img)[^>]*data-wp-on(-async)?--(click|keydown|keyup)" '*.{php,html}' \
		| grouped "data-wp-on click/key handler on a non-interactive element (use <button type=\"button\">)"

	# 5. Hand-written context JSON.
	search "data-wp-context=['\"]?[[:space:]]*(\{|'[[:space:]]*\{)" '*.php' | grep -v "wp_interactivity_data_wp_context" \
		| grouped "Hand-written data-wp-context JSON (use wp_interactivity_data_wp_context(); quoting and escaping break)"
	return 0
}
interactivity_checks

section "Build"
if [ "$COMPILED_ONLY" -eq 1 ]; then
	echo "--- Compiled-only distribution: verifying built block.json file: paths"
	echo "$BUILT_BJ" | while IFS= read -r bb; do check_paths "$bb"; done
elif [ "$NO_BUILD" -eq 1 ]; then
	echo "--- No-build plugin: package.json and build/ not required"
elif [ -f "$ROOT/package.json" ]; then
	grep -q '@wordpress/scripts' "$ROOT/package.json" || echo "--- package.json without @wordpress/scripts"
	grep -qE '"build"[[:space:]]*:' "$ROOT/package.json" || echo "--- package.json without build script"
else
	echo "--- No package.json at root"
fi
if [ "$NO_BUILD" -eq 0 ] && [ -d "$ROOT/src" ]; then
	OUT_DIR=""
	for d in build dist; do [ -d "$ROOT/$d" ] && { OUT_DIR="$ROOT/$d"; break; }; done
	if [ -z "$OUT_DIR" ]; then
		# Nested output dir (public/build, assets/build, ...) that holds compiled assets.
		OUT_DIR="$(find "$ROOT" -mindepth 2 -maxdepth 3 \( -name node_modules -o -name vendor -o -name .git \) -prune -o -type d \( -name build -o -name dist \) -print 2>/dev/null \
			| while IFS= read -r d; do [ -n "$(find "$d" -maxdepth 2 \( -name '*.asset.php' -o -name '*.js' \) -print -quit)" ] && echo "$d"; done | head -1)"
		[ -n "$OUT_DIR" ] && echo "--- Build output found in subdirectory: $OUT_DIR"
	fi
	if [ -z "$OUT_DIR" ]; then
		if [ -f "$ROOT/.gitignore" ] && grep -qE '^/?(build|dist)/?$' "$ROOT/.gitignore"; then
			echo "--- Source checkout: build/ is gitignored and absent (run npm run build to check output; not a finding)"
		else
			echo "--- src/ exists but no build/ or dist/ output directory"
		fi
	else
		check_build "$OUT_DIR"
	fi
fi

echo
echo "Done. Confirm each candidate in source before reporting."
