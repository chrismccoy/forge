#!/usr/bin/env bash
# Print SHOT_INIT_JS code that logs `shot` in as the user whose cookies are in a curl cookie jar, then opens a
# target URL. `shot` can't send cookies itself: point it at any front-end URL with ?audit_target=<url>, and this code
# sets the auth cookies and navigates there once (guarded so it can't loop).
#
# Usage: SHOT_INIT_JS="$(login-js.sh <tmp>/jar)$(cat capture.js)" \
#          shot "$WP_TEST_URL/?audit_target=$(printf %s "$WP_TEST_URL/wp-admin/post.php?post=5&action=edit" | jq -sRr @uri)" out.png
# Make the jar first with the site's `login` helper (or curl against wp-login.php for other users).
#
# Output (stdout): one line of JavaScript. Exit 1 with a one-line stderr message when the jar is missing or holds
# no wordpress* cookies. Cookie values are inserted as-is inside single quotes; WordPress URL-encodes its cookie
# values, so they never contain a quote.

set -euo pipefail

# Netscape cookie-jar columns (tab-separated): 3 = path, 6 = name, 7 = value.
readonly JAR_MIN_FIELDS=7
# Cookie names WordPress uses for auth (wordpress_<hash>, wordpress_logged_in_<hash>, wordpress_sec_<hash>).
readonly WP_COOKIE_PREFIX='wordpress'

jar="${1:?usage: login-js.sh <cookie-jar>}"
[[ -f "$jar" ]] || { printf 'login-js: no cookie jar at %s\n' "$jar" >&2; exit 1; }

# cookie_statements <jar>: one document.cookie='name=value; path=...'; statement per WordPress cookie in the jar.
cookie_statements() {
	awk -F'\t' -v min="$JAR_MIN_FIELDS" -v prefix="^$WP_COOKIE_PREFIX" \
		'NF >= min && $6 ~ prefix { printf "document.cookie=%c%s=%s; path=%s%c;", 39, $6, $7, $3, 39 }' "$1"
}

cookies="$(cookie_statements "$jar")"
[[ -n "$cookies" ]] || { printf 'login-js: no WordPress cookies in %s\n' "$jar" >&2; exit 1; }

cat <<JS
(function(){var t=new URLSearchParams(location.search).get('audit_target');if(!t||sessionStorage.getItem('audit_login_done'))return;sessionStorage.setItem('audit_login_done','1');${cookies}document.cookie='wordpress_test_cookie=WP%20Cookie%20check; path=/';location.href=t;})();
JS
