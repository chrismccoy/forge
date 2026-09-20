# Appendix: `setup-test-site.sh`

The throwaway-WordPress test harness. Copy the fenced block below out of this file
**by line range**, unchanged, into a new file outside the theme - never retype it:

```
script=$(mktemp --suffix=.sh)
sed -n '18,579p' "${CLAUDE_PLUGIN_ROOT}/lib/wp-demo-content/references/setup-test-site.md" > "$script"
sha256sum "$script"   # must print dcf0a8158e53ad0b8d526dc7c15b61e50e38d0926a33914e41a13ebbfd30b1a2
```

Lines 18-579 are the script itself - the opening fence is line 17 and the closing fence
line 580. If the hash does not match, the copy differs from this appendix: write the file
again in one go. **Never edit the script to make the hash pass, and never edit the script
at all.**

````bash
#!/usr/bin/env bash
# Build a throwaway WordPress test site (SQLite) for a theme, fully isolated in one temp folder.
#
# Usage: setup-test-site.sh <theme-dir> [port] [parent-dir]
#   theme-dir   the theme to symlink and activate
#   port        php -S port (default 8080, or 0 to auto-pick a free port)
#   parent-dir  where to create the temp folder (default: system temp)
#
# Prints the temp folder path on the last line. Then:
#   source <tmp>/env.sh       # puts `wp`, `serve`, `login`, `shot`, `teardown` on PATH
#   wp option get siteurl     # every wp call is pinned to the test site and runs from its
#                             # WordPress root, so pass file arguments as absolute paths
#   serve start | serve stop  # php -S in the background, log in <tmp>/server.log
#   login                     # admin cookie jar at <tmp>/jar for curl -b
#   serve status              # is the server running
#   shot <url> <out.png> [w] [h]  # headless Chrome screenshot (default 1440x2400), true
#                             # viewport width (390 works), capped at 1.5 GB and 90 seconds;
#                             # needs Chrome and Node.js 22+, else exits 3 (skipped)
#                             # SHOT_INIT_JS='<js>' runs before the page's own scripts
#   teardown                  # stop the server and delete the temp folder
#
# The helpers also work when called by absolute path (<tmp>/bin/wp …) without sourcing env.sh.

set -Eeuo pipefail
shopt -s inherit_errexit 2>/dev/null || true
IFS=$'\n\t'

readonly WP_CLI_PHAR_URL="https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar"
readonly WP_CLI_NIGHTLY_URL="https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli-nightly.phar"
readonly SQLITE_PLUGIN_URL="https://downloads.wordpress.org/plugin/sqlite-database-integration.latest-stable.zip"
readonly CLASSIC_EDITOR_URL="https://downloads.wordpress.org/plugin/classic-editor.latest-stable.zip"
readonly FETCH_RETRIES=3
readonly FETCH_RETRY_BASE_DELAY=2
readonly CURL_HTTP_ERROR_RC=22

SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_NAME

T=""
PORT=""
PARENT=""
THEME_DIR=""
SLUG=""
URL=""
KEEP_ON_FAILURE="${KEEP_ON_FAILURE:-0}"
VERBOSE="${VERBOSE:-0}"

say()   { printf '== %s\n' "$*" >&2; }
warn()  { printf 'WARN: %s\n' "$*" >&2; }
die()   { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
debug() { [ "$VERBOSE" = "1" ] && printf 'DEBUG: %s\n' "$*" >&2 || true; }

on_exit() {
	local status=$?
	trap - EXIT INT TERM

	if [ "$status" -ne 0 ] && [ -n "$T" ] && [ -d "$T" ]; then
		if [ "$KEEP_ON_FAILURE" = "1" ]; then
			say "Failed (exit $status). Left temp dir for inspection: $T"
			exit "$status"
		fi
		say "Failed (exit $status). Removing temp dir: $T"
		if [ -f "$T/server.pid" ]; then
			kill "$(cat "$T/server.pid")" 2>/dev/null || true
		fi
		rm -rf -- "$T"
	fi
	exit "$status"
}
trap on_exit EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

require_cmd() {
	command -v "$1" >/dev/null 2>&1 || die "required command not found: $1"
}

check_deps() {
	local cmd
	if (( BASH_VERSINFO[0] < 4 || ( BASH_VERSINFO[0] == 4 && BASH_VERSINFO[1] < 4 ) )); then
		die "bash 4.4 or newer is required (found $BASH_VERSION)"
	fi

	for cmd in curl php unzip mktemp timeout; do
		require_cmd "$cmd"
	done

	php -m 2>/dev/null | grep -qi '^pdo_sqlite$' \
		|| die "php is missing the pdo_sqlite extension (needed by the SQLite integration plugin)"
}

port_in_use() {
	local port="$1"
	if command -v lsof >/dev/null 2>&1; then
		lsof -iTCP:"$port" -sTCP:LISTEN >/dev/null 2>&1 && return 0
	elif command -v ss >/dev/null 2>&1; then
		ss -ltn 2>/dev/null | awk '{print $4}' | grep -q ":${port}\$" && return 0
	elif command -v nc >/dev/null 2>&1; then
		nc -z 127.0.0.1 "$port" 2>/dev/null && return 0
	else
		die "no lsof/ss/nc found; cannot verify port availability (install one, or pass 0 as the port)"
	fi
	return 1
}

pick_free_port() {
	# shellcheck disable=SC2016
	php -r '
		$s = stream_socket_server("tcp://127.0.0.1:0", $e, $m);
		if (!$s) { fwrite(STDERR, "$m\n"); exit(1); }
		$name = stream_socket_get_name($s, false);
		echo substr($name, strrpos($name, ":") + 1);
	'
}

usage() {
	cat >&2 <<EOF
Usage: $SCRIPT_NAME <theme-dir> [port] [parent-dir]

  A port of 0 auto-selects a free port instead of failing on collision.

Env:
  KEEP_ON_FAILURE=1  leave the temp dir in place if the build fails
  VERBOSE=1          print debug tracing
EOF
	exit 1
}

fetch() {
	local url="$1" out="$2" attempt=1 delay="$FETCH_RETRY_BASE_DELAY"
	local tmp_out="${out}.part"
	local curl_rc

	while true; do
		curl_rc=0
		curl -fsSL --retry 0 --connect-timeout 10 --max-time 300 \
			-o "$tmp_out" "$url" || curl_rc=$?
		if [ "$curl_rc" -eq 0 ]; then
			mv -- "$tmp_out" "$out"
			return 0
		fi
		rm -f -- "$tmp_out"

		if [ "$curl_rc" -eq "$CURL_HTTP_ERROR_RC" ]; then
			die "download returned an HTTP error (won't retry): $url"
		fi

		if [ "$attempt" -ge "$FETCH_RETRIES" ]; then
			die "failed to download after $attempt attempts: $url"
		fi
		warn "download failed (attempt $attempt/$FETCH_RETRIES): $url — retrying in ${delay}s"
		sleep "$delay"
		attempt=$((attempt + 1))
		delay=$((delay * 2))
	done
}

parse_args() {
	[ "$#" -ge 1 ] || usage
	[ "$#" -le 3 ] || usage

	local theme_dir_raw="$1"
	PORT="${2:-8080}"
	PARENT="${3:-${TMPDIR:-/tmp}}"

	[[ "$PORT" =~ ^[0-9]+$ ]] || die "port must be numeric: $PORT"

	if [ "$PORT" -eq 0 ]; then
		PORT="$(pick_free_port)" || die "could not obtain a free port from the kernel"
		say "Auto-selected free port: $PORT"
	else
		[ "$PORT" -ge 1 ] && [ "$PORT" -le 65535 ] || die "port out of range: $PORT"
		port_in_use "$PORT" && die "port $PORT is already in use"
	fi

	[ -d "$theme_dir_raw" ] || die "theme dir not found: $theme_dir_raw"
	[ -d "$PARENT" ] || die "parent dir not found: $PARENT"
	[ -w "$PARENT" ] || die "parent dir not writable: $PARENT"

	THEME_DIR="$(cd "$theme_dir_raw" && pwd -P)"
	SLUG="$(basename "$THEME_DIR")"

	[[ "$SLUG" =~ ^[A-Za-z0-9._-]+$ ]] \
		|| die "theme directory name has unsafe characters: $SLUG"

	URL="http://127.0.0.1:${PORT}"
}

make_workspace() {
	T="$(mktemp -d -p "$PARENT" wp-test-XXXXXX)"
	chmod 700 "$T"
	mkdir -p "$T"/{bin,wp-cli-cache,wp-cli-packages,tmp,wordpress}
	: > "$T/wp-cli.yml"
}

write_env_file() {
	cat > "$T/env.sh" <<ENV
# shellcheck shell=bash
export WP_TEST_DIR="$T"
export WP_TEST_URL="$URL"
export WP_TEST_PORT="$PORT"
export WP_CLI_CACHE_DIR="$T/wp-cli-cache"
export WP_CLI_PACKAGES_DIR="$T/wp-cli-packages"
export WP_CLI_CONFIG_PATH="$T/wp-cli.yml"
export TMPDIR="$T/tmp"
export PATH="$T/bin:\$PATH"
ENV
	chmod 600 "$T/env.sh"
}

helper_header() {
	printf '#!/usr/bin/env bash\nset -euo pipefail\n# shellcheck source=/dev/null\nsource %q\n' "$T/env.sh"
}

install_wp_cli() {
	# The stable build prints Deprecated lines on PHP 8.5+ even when `core install` shows none.
	if php -r 'exit( PHP_VERSION_ID >= 80500 ? 0 : 1 );'; then
		say "Downloading WP-CLI (nightly: PHP 8.5+ detected)"
		fetch "$WP_CLI_NIGHTLY_URL" "$T/bin/wp-cli.phar"
	else
		say "Downloading WP-CLI"
		fetch "$WP_CLI_PHAR_URL" "$T/bin/wp-cli.phar"
	fi
	php "$T/bin/wp-cli.phar" --version >/dev/null 2>&1 \
		|| die "downloaded wp-cli.phar failed to execute"

	{ helper_header; cat <<'WP'
cd "$WP_TEST_DIR/wordpress"
exec php "$WP_TEST_DIR/bin/wp-cli.phar" --path="$WP_TEST_DIR/wordpress" "$@"
WP
	} > "$T/bin/wp"
	chmod +x "$T/bin/wp"
}

download_wordpress() {
	say "Downloading WordPress"
	wp core download >/dev/null
}

configure_wordpress() {
	say "Configuring"
	wp config create --dbname=wp --dbuser=wp --dbpass=wp --skip-check >/dev/null

	local c
	for c in WP_DEBUG WP_DEBUG_LOG WP_DEBUG_DISPLAY DISABLE_WP_CRON; do
		wp config set "$c" true --raw >/dev/null
	done
}

install_sqlite_integration() {
	say "Installing SQLite integration"
	local zip="$T/sqlite.zip"
	fetch "$SQLITE_PLUGIN_URL" "$zip"

	unzip -q -t "$zip" >/dev/null 2>&1 || die "downloaded sqlite plugin zip is corrupt: $zip"
	unzip -q -o "$zip" -d "$T/wordpress/wp-content/plugins"

	local dropin="$T/wordpress/wp-content/plugins/sqlite-database-integration/db.copy"
	[ -f "$dropin" ] || die "sqlite plugin layout unexpected; db.copy not found"
	cp "$dropin" "$T/wordpress/wp-content/db.php"
	rm -f -- "$zip"
}

switch_to_nightly_wp_cli() {
	say "Stable WP-CLI prints Deprecated lines on this PHP; switching to nightly"
	fetch "$WP_CLI_NIGHTLY_URL" "$T/bin/wp-cli.phar"
}

run_core_install() {
	local -a args=(
		core install --url="$URL" --title="Demo Test"
		--admin_user=admin --admin_password=admin
		--admin_email=admin@example.com --skip-email
	)
	local out rc attempt

	for attempt in 1 2; do
		if out="$(wp "${args[@]}" 2>&1)"; then
			rc=0
		else
			rc=$?
		fi

		if [ "$rc" -eq 0 ] && ! grep -q 'Deprecated' <<<"$out"; then
			return 0
		fi

		if [ "$attempt" -eq 2 ] && [ "$rc" -eq 0 ]; then
			warn "nightly WP-CLI still prints Deprecated notices; install succeeded, continuing"
			return 0
		fi

		printf '%s\n' "$out" >&2

		if [ "$attempt" -eq 1 ] && grep -q 'Deprecated' <<<"$out"; then
			switch_to_nightly_wp_cli
			continue
		fi

		if [ "$attempt" -eq 1 ]; then
			die "wp core install failed"
		fi
		die "wp core install failed (after nightly retry)"
	done
}

install_wordpress() {
	say "Installing WordPress"
	run_core_install

	local got
	got="$(wp option get siteurl)"
	[ "$got" = "$URL" ] || die "siteurl is $got, expected $URL"

	wp rewrite structure '/%postname%/' >/dev/null
}

install_classic_editor() {
	say "Installing Classic Editor"
	local zip="$T/classic-editor.zip"
	fetch "$CLASSIC_EDITOR_URL" "$zip"

	unzip -q -t "$zip" >/dev/null 2>&1 || die "downloaded Classic Editor zip is corrupt: $zip"
	unzip -q -o "$zip" -d "$T/wordpress/wp-content/plugins"
	rm -f -- "$zip"
	wp plugin activate classic-editor >/dev/null
}

activate_theme() {
	say "Activating theme $SLUG"
	local link="$T/wordpress/wp-content/themes/$SLUG"
	if [ -L "$link" ]; then
		local target
		target="$(readlink "$link")"
		[ "$target" = "$THEME_DIR" ] \
			|| die "theme symlink exists but points elsewhere: $link -> $target"
	else
		ln -s "$THEME_DIR" "$link"
	fi
	wp theme activate "$SLUG" >/dev/null
}

write_helper_scripts() {
	{ helper_header; cat <<'SERVE'
T="$WP_TEST_DIR"
URL="$WP_TEST_URL"
PORT="$WP_TEST_PORT"

is_running() {
	[ -f "$T/server.pid" ] && kill -0 "$(cat "$T/server.pid")" 2>/dev/null
}

case "${1:-start}" in
	start)
		is_running && { echo "already running (pid $(cat "$T/server.pid"))" >&2; exit 0; }
		rm -f "$T/server.pid"
		nohup php -d memory_limit=512M -S "127.0.0.1:$PORT" -t "$T/wordpress" >>"$T/server.log" 2>&1 &
		disown
		echo $! > "$T/server.pid"

		for _ in $(seq 1 100); do
			is_running || { echo "server process died immediately; see $T/server.log" >&2; exit 1; }
			curl -fs -o /dev/null "$URL/wp-login.php" && exit 0
			sleep 0.1
		done
		echo "server did not become ready in time; see $T/server.log" >&2
		exit 1
		;;
	stop)
		if [ -f "$T/server.pid" ]; then
			pid="$(cat "$T/server.pid")"
			kill "$pid" 2>/dev/null || true
			for _ in $(seq 1 30); do
				kill -0 "$pid" 2>/dev/null || break
				sleep 0.1
			done
			kill -9 "$pid" 2>/dev/null || true
			rm -f "$T/server.pid"
		fi
		;;
	status)
		is_running && { echo "running (pid $(cat "$T/server.pid"))"; exit 0; }
		echo "stopped"; exit 1
		;;
	*)
		echo "usage: serve {start|stop|status}" >&2
		exit 1
		;;
esac
SERVE
	} > "$T/bin/serve"

	{ helper_header; cat <<'LOGIN'
T="$WP_TEST_DIR"
URL="$WP_TEST_URL"

rm -f "$T/jar"
old_jar="$(mktemp "$T/jar.XXXXXX")"
curl -fs -o /dev/null -c "$old_jar" -b 'wordpress_test_cookie=WP%20Cookie%20check' \
	-d "log=admin&pwd=admin&testcookie=1&redirect_to=$URL/wp-admin/" "$URL/wp-login.php"

if grep -q wordpress_logged_in "$old_jar"; then
	mv "$old_jar" "$T/jar"
	chmod 600 "$T/jar"
else
	rm -f "$old_jar"
	echo "login failed" >&2
	exit 1
fi
LOGIN
	} > "$T/bin/login"

	cat > "$T/bin/shot.mjs" <<'MJS'
// Screenshot through the DevTools protocol: headless Chrome won't size a window below 500px,
// so the viewport is set with Emulation.setDeviceMetricsOverride instead.
import { spawn } from 'node:child_process';
import { readFileSync, writeFileSync, existsSync, rmSync } from 'node:fs';

const [url, out, w = '1440', h = '2400', chrome, profile] = process.argv.slice(2);
const width = parseInt(w, 10);
const height = parseInt(h, 10);
const data = `${profile}/data`;
rmSync(`${data}/DevToolsActivePort`, { force: true });
const proc = spawn(chrome, [
	'--headless=new', '--disable-gpu', '--no-sandbox', '--hide-scrollbars', '--mute-audio',
	'--remote-debugging-port=0', `--user-data-dir=${data}`, `--window-size=${Math.max(width, 500)},${Math.max(height, 500)}`,
	'about:blank',
], { stdio: 'ignore', detached: true, env: { ...process.env, TMPDIR: '/tmp' } });
const stop = (code, msg) => {
	if (msg) console.error(`shot: ${msg}`);
	try { process.kill(-proc.pid, 'SIGKILL'); } catch {}
	process.exit(code);
};
setTimeout(() => stop(1, 'timed out'), 80000);
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

let port = '';
for (let i = 0; i < 100 && !port; i++) {
	if (existsSync(`${data}/DevToolsActivePort`)) port = readFileSync(`${data}/DevToolsActivePort`, 'utf8').split('\n')[0];
	else await sleep(100);
}
if (!port) stop(1, 'Chrome did not start');
let page;
for (let i = 0; i < 50 && !page; i++) {
	try { page = (await (await fetch(`http://127.0.0.1:${port}/json/list`)).json()).find((t) => t.type === 'page'); } catch { await sleep(100); }
}
if (!page) stop(1, 'no page target');
const ws = new WebSocket(page.webSocketDebuggerUrl);
await new Promise((r) => ws.addEventListener('open', r, { once: true }));
let id = 0;
const waiters = new Map();
let loaded = false;
ws.addEventListener('message', (e) => {
	const m = JSON.parse(e.data);
	if (m.id && waiters.has(m.id)) { waiters.get(m.id)(m); waiters.delete(m.id); }
	else if ('Page.loadEventFired' === m.method) loaded = true;
});
const send = (method, params = {}) => new Promise((r) => { const i = ++id; waiters.set(i, r); ws.send(JSON.stringify({ id: i, method, params })); });

await send('Page.enable');
if (process.env.SHOT_INIT_JS) await send('Page.addScriptToEvaluateOnNewDocument', { source: process.env.SHOT_INIT_JS });
await send('Emulation.setDeviceMetricsOverride', { width, height, deviceScaleFactor: 1, mobile: width < 768 });
await send('Page.navigate', { url });
for (let i = 0; i < 300 && !loaded; i++) await sleep(100);
await sleep(3000);
const shot = await send('Page.captureScreenshot', { format: 'png' });
if (!shot.result) stop(1, 'capture failed');
writeFileSync(out, Buffer.from(shot.result.data, 'base64'));
stop(0);
MJS

	{ helper_header; cat <<'SHOT'
T="$WP_TEST_DIR"

if [ "$#" -lt 2 ]; then
	echo "usage: shot <url> <out.png> [width] [height]" >&2
	exit 1
fi

url="$1" out="$2" width="${3:-1440}" height="${4:-2400}"

chrome=""
for candidate in google-chrome google-chrome-stable chromium chromium-browser; do
	if command -v "$candidate" >/dev/null 2>&1; then
		chrome="$(command -v "$candidate")"
		break
	fi
done
skip() {
	echo "shot: skipped, $1. Take no screenshots; report the screenshot step as SKIPPED with this reason." >&2
	exit 3
}
[ -n "$chrome" ] || skip "no Chrome or Chromium found"
command -v node >/dev/null 2>&1 || skip "Node.js 22 or newer is required and node was not found"
node -e 'process.exit(parseInt(process.versions.node, 10) >= 22 ? 0 : 1)' \
	|| skip "Node.js 22 or newer is required, found $(node --version)"
mkdir -p "$T/chrome"

# A runaway page can push Chrome past 5 GB, so cap its memory where systemd allows it.
cap=()
if systemd-run --user --scope -q -p MemoryMax=1500M true >/dev/null 2>&1; then
	cap=(systemd-run --user --scope -q -p MemoryMax=1500M -p MemorySwapMax=0)
else
	echo "warning: systemd-run is unavailable, so Chrome runs without a memory cap" >&2
fi

timeout 90 "${cap[@]}" node "$T/bin/shot.mjs" "$url" "$out" "$width" "$height" "$chrome" "$T/chrome"

[ -s "$out" ] || { echo "screenshot was not produced: $out" >&2; exit 1; }
SHOT
	} > "$T/bin/shot"

	{ helper_header; cat <<'TEARDOWN'
T="$WP_TEST_DIR"
"$T/bin/serve" stop || true
cd /
rm -rf -- "$T"
TEARDOWN
	} > "$T/bin/teardown"

	chmod +x "$T/bin"/{serve,login,shot,teardown}
}

check_screenshot_deps() {
	local chrome_found=0 candidate
	for candidate in google-chrome google-chrome-stable chromium chromium-browser; do
		command -v "$candidate" >/dev/null 2>&1 && chrome_found=1
	done
	if [ "$chrome_found" -eq 0 ]; then
		warn "no Chrome or Chromium found: shot will skip screenshots (exit 3)"
	elif ! command -v node >/dev/null 2>&1; then
		warn "Node.js not found: shot needs Node.js 22 or newer and will skip screenshots (exit 3)"
	elif ! node -e 'process.exit(parseInt(process.versions.node, 10) >= 22 ? 0 : 1)'; then
		warn "Node.js $(node --version) is too old: shot needs 22 or newer and will skip screenshots (exit 3)"
	fi
}

main() {
	check_deps
	parse_args "$@"
	make_workspace
	write_env_file

	# shellcheck source=/dev/null
	source "$T/env.sh"
	cd "$T"

	install_wp_cli
	download_wordpress
	configure_wordpress
	install_sqlite_integration
	install_wordpress
	install_classic_editor
	activate_theme
	write_helper_scripts
	check_screenshot_deps

	say "Ready: $URL (admin / admin). Run: source $T/env.sh"
	printf '%s\n' "$T"
}

main "$@"
````
