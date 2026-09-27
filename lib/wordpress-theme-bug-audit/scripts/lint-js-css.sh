#!/usr/bin/env bash
# Lint the theme's own JS and CSS for real errors only (no style rules).
#   ESLint: @eslint/js recommended, browser and jQuery globals plus `wp`, JSX allowed, minified files skipped.
#   stylelint: stylelint-config-recommended plus unsupported-feature checks against the theme's browserslist
#   (package.json or .browserslistrc; "defaults" if it has none). Sass through postcss-scss.
#
# Usage: lint-js-css.sh <tools> <theme-dir> <out-dir> [extra-global ...]
#   Extra globals are names the theme's localized scripts define (for example themeData).
# AUDIT_EXCLUDE_DIRS (space-separated) leaves folders the theme doesn't ship out of both linters.
# Writes <out-dir>/eslint.json, <out-dir>/stylelint.json, and <out-dir>/summary.txt.
#
# Output (stdout): the contents of summary.txt:
#   ESLint: <n> problems in <n> files
#     <count>  <rule>            (top 20; parse errors show as parse-error)
#   stylelint (browsers: <query>): <n> problems
#     <count>  <rule>            (top 20)
# Exit 0 once linting ran, even with problems found; 1 when ESLint isn't installed or <theme-dir> doesn't exist.
# A linter that crashes leaves its JSON unreadable; the summary then says "<linter> CRASHED" instead of trusting
# its count. Needs python3 for the summary.

set -uo pipefail

# Paths neither linter should read: build output, dependencies, and this audit's own files.
readonly ESLINT_BASE_IGNORES='"**/*.min.js", "**/vendor/**", "**/node_modules/**", "**/audit/**", "**/.git/**",'
readonly STYLELINT_BASE_IGNORES=(--ignore-pattern '**/*.min.css' --ignore-pattern 'vendor/**' --ignore-pattern 'node_modules/**' --ignore-pattern 'audit/**')
# browserslist query used when the theme declares none.
readonly DEFAULT_BROWSERS='defaults'

tools="${1:?usage: lint-js-css.sh <tools> <theme-dir> <out-dir> [extra-global ...]}"
theme_arg="${2:?theme dir}"
out="${3:?out dir}"
shift 3
theme="$(cd "$theme_arg" 2>/dev/null && pwd -P)"
[[ -n "$theme" ]] || { printf 'lint-js-css: theme dir not found: %s\n' "$theme_arg" >&2; exit 1; }
mkdir -p "$out"
[[ -x "$tools/node_modules/.bin/eslint" ]] || { printf 'lint-js-css: ESLint not installed in %s\n' "$tools" >&2; exit 1; }

# js_string <text>: the text as a double-quoted JS/JSON string literal.
js_string() {
	local text="${1//\\/\\\\}"
	printf '"%s"' "${text//\"/\\\"}"
}

# read_exclude_dirs: AUDIT_EXCLUDE_DIRS split on whitespace into exclude_dirs, without glob expansion.
read_exclude_dirs() {
	exclude_dirs=()
	read -r -d '' -a exclude_dirs <<< "${AUDIT_EXCLUDE_DIRS:-}" || true
}

# theme_browsers <theme>: the theme's browserslist query, joined with commas, or the default.
theme_browsers() {
	local theme="$1" from_pkg=""
	if [[ -f "$theme/.browserslistrc" ]]; then
		grep -v '^#' "$theme/.browserslistrc" | grep . | paste -sd, -
		return
	fi
	if [[ -f "$theme/package.json" ]]; then
		from_pkg="$(python3 -c 'import json,sys; b=json.load(open(sys.argv[1])).get("browserslist"); print(",".join(b) if isinstance(b,list) else (b or ""))' "$theme/package.json" 2>/dev/null)"
	fi
	printf '%s\n' "${from_pkg:-$DEFAULT_BROWSERS}"
}

read_exclude_dirs
ignores=""
style_ignores=()
for dir in "${exclude_dirs[@]}"; do
	ignores="$ignores $(js_string "$dir/**"),"
	style_ignores+=(--ignore-pattern "$dir/**")
done

extra=""
for name in "$@"; do
	extra="$extra $(js_string "$name"): \"readonly\","
done

cat > "$out/eslint.config.mjs" <<JS
import js from "$tools/node_modules/@eslint/js/src/index.js";
import globals from "$tools/node_modules/globals/index.js";
export default [
	{ ignores: [$ESLINT_BASE_IGNORES$ignores] },
	js.configs.recommended,
	{
		languageOptions: {
			ecmaVersion: "latest",
			sourceType: "script",
			parserOptions: { ecmaFeatures: { jsx: true } },
			globals: { ...globals.browser, ...globals.jquery, wp: "readonly", ajaxurl: "readonly",$extra },
		},
		rules: { "no-unused-vars": ["error", { args: "none" }] },
	},
	{ files: ["**/*.mjs", "**/src/**/*.js", "**/blocks/**/*.js"], languageOptions: { sourceType: "module" } },
];
JS

browsers="$(theme_browsers "$theme")"

cat > "$out/stylelint.config.json" <<JSON
{
	"extends": ["$tools/node_modules/stylelint-config-recommended/index.js"],
	"plugins": ["$tools/node_modules/stylelint-no-unsupported-browser-features/lib/index.js"],
	"rules": {
		"plugin/no-unsupported-browser-features": [true, { "browsers": $(js_string "$browsers"), "severity": "warning" }]
	},
	"overrides": [{ "files": ["**/*.scss"], "customSyntax": "$tools/node_modules/postcss-scss/lib/scss-syntax.js" }]
}
JSON

(cd "$theme" && "$tools/node_modules/.bin/eslint" --config "$out/eslint.config.mjs" --format json . > "$out/eslint.json" 2> "$out/eslint.err")
(cd "$theme" && "$tools/node_modules/.bin/stylelint" --config "$out/stylelint.config.json" --formatter json \
	"${STYLELINT_BASE_IGNORES[@]}" "${style_ignores[@]}" \
	'**/*.{css,scss}' > "$out/stylelint.json" 2>&1)

python3 - "$out" "$browsers" > "$out/summary.txt" <<'PY'
import collections, json, sys
out, browsers = sys.argv[1], sys.argv[2]
TOP_RULES = 20  # rules listed per linter


crashed = []


def load(path, name):
    """Parsed JSON report, or [] (recorded as a crash) when the linter crashed or wrote something else."""
    try:
        with open(path) as handle:
            data = json.load(handle)
    except Exception:
        crashed.append(name)
        return []
    if not isinstance(data, list):
        crashed.append(name)
        return []
    return data


eslint = load(out + '/eslint.json', 'ESLint')
rules = collections.Counter(m.get('ruleId') or 'parse-error' for f in eslint for m in f.get('messages', []))
print('ESLint: %d problems in %d of %d files linted' % (sum(rules.values()), sum(1 for f in eslint if f.get('messages')), len(eslint)))
for rule, n in rules.most_common(TOP_RULES):
    print('  %4d  %s' % (n, rule))
stylelint = load(out + '/stylelint.json', 'stylelint')
srules = collections.Counter(w.get('rule') for f in stylelint for w in f.get('warnings', []))
print('stylelint (browsers: %s): %d problems in %d of %d files linted' % (browsers, sum(srules.values()), sum(1 for f in stylelint if f.get('warnings')), len(stylelint)))
for rule, n in srules.most_common(TOP_RULES):
    print('  %4d  %s' % (n, rule))
for name in crashed:
    print('%s CRASHED: its report is unreadable, so its count above means nothing; see eslint.err or stylelint.json' % name)
PY
cat "$out/summary.txt"
