#!/usr/bin/env bash
# Run phpcs with only the sniffs that find real bugs (no code-style rules): escaping, nonces, input sanitizing,
# safe redirects, prepared SQL, text domain, deprecated WordPress functions and parameters, and PHP compatibility.
#
# Usage: phpcs-correctness.sh <tools> <theme-dir> <text-domain> <oldest-wordpress> <php-range> <out-dir>
#   e.g. phpcs-correctness.sh "$tools" "$theme" scroll-to 6.7 8.1-8.5 "$work/phpcs"
# AUDIT_EXCLUDE_DIRS (space-separated) leaves folders the theme doesn't ship out of the scan.
# Writes <out-dir>/ruleset.xml, <out-dir>/phpcs.json (full report), and <out-dir>/summary.txt (counts per sniff).
#
# Output (stdout): the first line of summary.txt, "errors <n>, warnings <n>". Exit 0 once phpcs ran, whatever it
# found. When phpcs crashes (no usable JSON report), stdout is empty, summary.txt is empty, stderr gets one line
# pointing at <out-dir>/phpcs.err, and the exit code is still 0: an empty stdout line means "no result", never
# "no problems". Exit 1 when phpcs isn't installed or <theme-dir> doesn't exist. Needs php and python3.

set -uo pipefail
# Bash 5.2+ treats & in ${x//a/b} replacements as the matched text; xml_escape needs it literal.
shopt -u patsub_replacement 2>/dev/null || true

tools="${1:?usage: phpcs-correctness.sh <tools> <theme-dir> <text-domain> <oldest-wordpress> <php-range> <out-dir>}"
theme_arg="${2:?theme dir}"
domain="${3:?text domain}"
min_wp="${4:?oldest WordPress version}"
php_range="${5:?PHP range, e.g. 8.1-8.5}"
out="${6:?out dir}"
theme="$(cd "$theme_arg" 2>/dev/null && pwd -P)"
[[ -n "$theme" ]] || { printf 'phpcs-correctness: theme dir not found: %s\n' "$theme_arg" >&2; exit 1; }
phpcs="$tools/vendor/bin/phpcs"
[[ -x "$phpcs" ]] || { printf 'phpcs-correctness: %s not found; run install-tools.sh first\n' "$phpcs" >&2; exit 1; }
mkdir -p "$out"

# xml_escape <text>: the text safe inside an XML attribute value.
xml_escape() {
	local text="${1//&/&amp;}"
	text="${text//</&lt;}"
	text="${text//>/&gt;}"
	printf '%s' "${text//\"/&quot;}"
}

# exclude_patterns: one <exclude-pattern> line per AUDIT_EXCLUDE_DIRS entry (split on whitespace, no globbing).
exclude_patterns() {
	local dirs=() dir
	read -r -d '' -a dirs <<< "${AUDIT_EXCLUDE_DIRS:-}" || true
	for dir in "${dirs[@]}"; do
		printf '\t<exclude-pattern>%s/%s/*</exclude-pattern>\n' "$(xml_escape "$theme")" "$(xml_escape "$dir")"
	done
}

cat > "$out/ruleset.xml" <<XML
<?xml version="1.0"?>
<ruleset name="Theme bug audit: correctness only">
	<exclude-pattern>*/vendor/*</exclude-pattern>
	<exclude-pattern>*/node_modules/*</exclude-pattern>
	<exclude-pattern>*/audit/*</exclude-pattern>
	<exclude-pattern>*/.git/*</exclude-pattern>
	<exclude-pattern>*.min.js</exclude-pattern>
$(exclude_patterns)
	<arg name="extensions" value="php"/>
	<config name="minimum_wp_version" value="$(xml_escape "$min_wp")"/>
	<config name="testVersion" value="$(xml_escape "$php_range")"/>
	<rule ref="WordPress.Security"/>
	<rule ref="WordPress.DB.PreparedSQL"/>
	<rule ref="WordPress.DB.PreparedSQLPlaceholders"/>
	<rule ref="WordPress.WP.I18n">
		<properties>
			<property name="text_domain" type="array">
				<element value="$(xml_escape "$domain")"/>
			</property>
		</properties>
	</rule>
	<rule ref="WordPress.WP.DeprecatedFunctions"/>
	<rule ref="WordPress.WP.DeprecatedParameters"/>
	<rule ref="WordPress.WP.DeprecatedClasses"/>
	<rule ref="PHPCompatibilityWP"/>
</ruleset>
XML

php "$phpcs" --standard="$out/ruleset.xml" --report=json -q "$theme" > "$out/phpcs.json" 2> "$out/phpcs.err"
python3 - "$out/phpcs.json" > "$out/summary.txt" <<'PY'
import collections, json, sys
try:
    with open(sys.argv[1]) as handle:
        data = json.load(handle)
    totals = data['totals']
    errors, warnings = int(totals['errors']), int(totals['warnings'])
except (OSError, ValueError, KeyError, TypeError):
    sys.exit(1)
by_sniff = collections.Counter()
for info in data.get('files', {}).values():
    for m in info.get('messages', []):
        by_sniff[m.get('source')] += 1
print('errors %d, warnings %d' % (errors, warnings))
for sniff, count in by_sniff.most_common():
    print('%5d  %s' % (count, sniff))
PY
[[ -s "$out/summary.txt" ]] || printf 'phpcs-correctness: phpcs wrote no usable JSON report; see %s/phpcs.err\n' "$out" >&2
head -1 "$out/summary.txt"
