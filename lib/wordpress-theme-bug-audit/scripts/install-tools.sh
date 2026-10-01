#!/usr/bin/env bash
# Install the audit's PHP and JS tools into <tools> (never globally, never with sudo).
#
# Usage: install-tools.sh <tools>
#
# PHP (Composer): phpcs with WordPress Coding Standards and PHPCompatibility, PHPStan with the WordPress extension.
#   Composer's allow-plugins list is written into composer.json before anything installs; otherwise Composer blocks
#   phpstan/extension-installer and the WordPress stubs never load (every WordPress function shows as "not found").
#   PHPCompatibility 9.x has no PHP 8 sniffs, so the 10.x line is tried first (alpha if no stable release exists).
# JS (npm): ESLint, stylelint with browser-support checks, axe-core, and the vnu HTML validator (needs Java to run).
# Prints one line per tool with its version, or MISSING; the audit marks the checks that need a missing tool BLOCKED.
#
# Output (stdout), always these 8 lines in this order, exit 0 even when installs fail:
#   phpcs <x.y.z|MISSING>          phpcompatibility <version|MISSING>   phpstan <x.y.z|MISSING>
#   phpstan-wordpress <loaded|MISSING>   eslint <vX.Y.Z|MISSING>   stylelint <x.y.z|MISSING>
#   axe-core <x.y.z|MISSING>       vnu <jar present|MISSING>
# Install failures are reported on stderr; details go to <tools>/composer.log and <tools>/npm.log.
# Without a global composer, composer.phar is downloaded and checked against its published SHA-256.

set -uo pipefail

readonly COMPOSER_PHAR_URL='https://getcomposer.org/download/latest-stable/composer.phar'
readonly COMPOSER_SHA_URL='https://getcomposer.org/download/latest-stable/composer.phar.sha256'
# Composer packages that must always install.
readonly COMPOSER_PACKAGES=(
	squizlabs/php_codesniffer wp-coding-standards/wpcs
	phpstan/phpstan szepeviktor/phpstan-wordpress phpstan/extension-installer
)
# PHPCompatibility 10.x (PHP 8 sniffs), and the 9.x fallback when 10.x can't resolve.
readonly PHPCOMPAT_10_PACKAGES=("phpcompatibility/php-compatibility:^10.0@alpha" "phpcompatibility/phpcompatibility-wp:*@alpha")
readonly PHPCOMPAT_FALLBACK_PACKAGE='phpcompatibility/phpcompatibility-wp'
readonly NPM_PACKAGES=(
	eslint @eslint/js globals axe-core stylelint stylelint-config-recommended
	stylelint-no-unsupported-browser-features postcss-scss vnu-jar
)
# First x.y.z in a tool's --version output.
readonly SEMVER_PATTERN='[0-9]+\.[0-9]+\.[0-9]+'

tools="${1:?usage: install-tools.sh <tools>}"
mkdir -p "$tools"
tools="$(cd "$tools" && pwd -P)" || exit 1
cd "$tools" || exit 1

# download_composer_phar: fetch composer.phar into the current folder, keeping it only if its checksum matches.
download_composer_phar() {
	local expected actual
	if ! curl -fsSL -o composer.phar "$COMPOSER_PHAR_URL"; then
		printf 'install-tools: composer.phar download failed\n' >&2
		rm -f composer.phar
		return 1
	fi
	expected="$(curl -fsSL "$COMPOSER_SHA_URL" | cut -d' ' -f1)"
	actual="$(sha256sum composer.phar | cut -d' ' -f1)"
	if [[ -z "$expected" || "$expected" != "$actual" ]]; then
		printf 'install-tools: composer.phar checksum mismatch\n' >&2
		rm -f composer.phar
		return 1
	fi
}

write_composer_json() {
	cat > composer.json <<'JSON'
{
    "minimum-stability": "alpha",
    "prefer-stable": true,
    "config": {
        "allow-plugins": {
            "dealerdirect/phpcodesniffer-composer-installer": true,
            "phpstan/extension-installer": true
        }
    }
}
JSON
}

# install_php_tools <composer command...>
install_php_tools() {
	local composer=("$@")
	write_composer_json
	"${composer[@]}" require --no-interaction --no-progress "${COMPOSER_PACKAGES[@]}" >/dev/null 2>composer.log \
		|| printf 'install-tools: Composer install failed; see %s/composer.log\n' "$tools" >&2
	if ! "${composer[@]}" require --no-interaction --no-progress --with-all-dependencies \
		"${PHPCOMPAT_10_PACKAGES[@]}" >/dev/null 2>>composer.log; then
		if "${composer[@]}" require --no-interaction --no-progress "$PHPCOMPAT_FALLBACK_PACKAGE" >/dev/null 2>>composer.log; then
			printf 'install-tools: only PHPCompatibility 9.x installed; phpcs checks nothing newer than PHP 7.4\n' >&2
		else
			printf 'install-tools: PHPCompatibility install failed; see %s/composer.log\n' "$tools" >&2
		fi
	fi
}

install_js_tools() {
	npm install --prefix "$tools" --no-audit --no-fund --silent "${NPM_PACKAGES[@]}" >/dev/null 2>npm.log \
		|| printf 'install-tools: npm install failed; see %s/npm.log\n' "$tools" >&2
}

# report <name> <version>: one output line; an empty version means the tool isn't usable.
report() {
	local name="$1" version="$2"
	if [[ -n "$version" ]]; then
		printf '%s %s\n' "$name" "$version"
	else
		printf '%s MISSING\n' "$name"
	fi
}

# first_semver: read --version output on stdin, print the first x.y.z in it.
first_semver() {
	grep -oE "$SEMVER_PATTERN" | head -1
}

phpcompat_version() {
	# shellcheck disable=SC2016  # PHP code, not shell.
	php -r '$l=json_decode(@file_get_contents("composer.lock"),true); foreach(($l["packages"]??[]) as $p) if($p["name"]==="phpcompatibility/php-compatibility") echo $p["version"];' 2>/dev/null
}

phpstan_wordpress_status() {
	local config=vendor/phpstan/extension-installer/src/GeneratedConfig.php
	[[ -f "$config" ]] && grep -q szepeviktor "$config" && printf 'loaded'
}

axe_version() {
	[[ -f node_modules/axe-core/axe.min.js ]] && node -p 'require("./node_modules/axe-core/package.json").version' 2>/dev/null
}

vnu_status() {
	command -v java >/dev/null 2>&1 && [[ -f node_modules/vnu-jar/build/dist/vnu.jar ]] && printf 'jar present'
}

if command -v composer >/dev/null 2>&1; then
	composer=(composer)
else
	[[ -f composer.phar ]] || download_composer_phar
	composer=(php composer.phar)
fi

if [[ -f composer.phar ]] || command -v composer >/dev/null 2>&1; then
	install_php_tools "${composer[@]}"
fi

if command -v npm >/dev/null 2>&1; then
	install_js_tools
fi

report phpcs "$(php vendor/bin/phpcs --version 2>/dev/null | first_semver)"
report phpcompatibility "$(phpcompat_version)"
report phpstan "$(php vendor/bin/phpstan --version 2>/dev/null | first_semver)"
report phpstan-wordpress "$(phpstan_wordpress_status)"
report eslint "$(node_modules/.bin/eslint --version 2>/dev/null)"
report stylelint "$(node_modules/.bin/stylelint --version 2>/dev/null)"
report axe-core "$(axe_version)"
report vnu "$(vnu_status)"
