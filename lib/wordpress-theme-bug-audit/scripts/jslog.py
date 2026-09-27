#!/usr/bin/env python3
"""Summarize the JS errors, axe violations, and theme 404s that capture.js sent to the test server.

Usage: jslog.py <tmp>/server.log [theme-slug]

Prints how many pages finished axe, the most common JS errors (with example pages), the most common axe
violations (rule|impact, with an example page and element), and 404s on the theme's own files.
"""
# Output (stdout), always these four sections in this order, even when empty:
#   pages where axe finished: <n>
#   JS errors:            then "  <count>  <message, digits as N>  e.g. [<up to 2 pages>]"   (top 30)
#   axe violations:       then "  <count>  <rule>|<impact>  e.g. [<up to 2 'page :: element'>]" (top 30)
#   404s on theme files:  then "  <count>  <requested path>"                                   (top 10)
# Wrong arguments print the docstring above to stderr and exit 1; an unreadable log exits 1 with a one-line stderr
# message and no stdout. Without a theme slug, 404s on any theme count. Runs on Python 3.7+ (standard library only).
from __future__ import annotations

import collections
import re
import sys
import urllib.parse
from pathlib import Path

# A capture.js beacon: /__<kind>?p=<page>&m=<message>, both URL-encoded. `ix` beacons are matched but not reported.
BEACON = re.compile(r'/__(jserr|axe|axedone|axetimeout|ix)\?p=([^& ]*)&m=([^ \]]*)')
# A 404 in the PHP built-in server's log.
NOT_FOUND = re.compile(r'\[404\]')
# The requested path in a php -S 404 line: "[404]: GET /path".
NOT_FOUND_PATH = re.compile(r'\[404\]: \w+ (\S+)')
# Digits are replaced so the same error on different lines and columns groups together.
DIGITS = re.compile(r'\d+')
# capture.js's placeholder for an error with no message or location.
EMPTY_JS_ERROR = '@:'
THEMES_PATH = '/wp-content/themes/'
# Lengths kept for grouping and display.
JS_KEY_CHARS = 170
AXE_ELEMENT_CHARS = 90
NOT_FOUND_TAIL_CHARS = 120
# Rows printed per section, and example pages per row.
TOP_JS = 30
TOP_AXE = 30
TOP_404 = 10
EXAMPLES = 2


def read_lines(path: Path) -> list[str]:
    """The log's lines; exits 1 with a one-line message when it can't be read."""
    try:
        return path.read_text(errors='ignore').splitlines()
    except OSError as error:
        sys.exit('jslog: cannot read %s: %s' % (path, error.strerror or error))


def main() -> None:
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    slug = sys.argv[2] if len(sys.argv) > 2 else ''
    lines = read_lines(Path(sys.argv[1]))
    js: collections.Counter[str] = collections.Counter()
    js_pages: dict[str, set[str]] = collections.defaultdict(set)
    axe: collections.Counter[str] = collections.Counter()
    axe_pages: dict[str, set[str]] = collections.defaultdict(set)
    axe_done = 0
    axe_timeout_pages: set[str] = set()
    theme_404: collections.Counter[str] = collections.Counter()
    for line in lines:
        match = BEACON.search(line)
        if match:
            kind = match.group(1)
            page = urllib.parse.unquote(match.group(2))
            message = urllib.parse.unquote(match.group(3))
            if kind == 'jserr':
                if message.strip() == EMPTY_JS_ERROR:
                    continue
                key = DIGITS.sub('N', message)[:JS_KEY_CHARS]
                js[key] += 1
                js_pages[key].add(page)
            elif kind == 'axe':
                # rule|impact|<unused>|element; padded so short messages don't raise.
                parts = message.split('|') + ['', '', '']
                axe[parts[0] + '|' + parts[1]] += 1
                axe_pages[parts[0]].add(page + ' :: ' + parts[3][:AXE_ELEMENT_CHARS])
            elif kind == 'axedone':
                axe_done += 1
            elif kind == 'axetimeout':
                axe_timeout_pages.add(page)
        elif NOT_FOUND.search(line) and THEMES_PATH + slug in line:
            found = NOT_FOUND_PATH.search(line)
            theme_404[found.group(1) if found else line[-NOT_FOUND_TAIL_CHARS:]] += 1
    print('pages where axe finished:', axe_done)
    if axe_timeout_pages:
        print('pages where axe timed out (rerun with __AUDIT_AXE_CONTEXT):', ', '.join(sorted(axe_timeout_pages)[:TOP_JS]))
    print('JS errors:')
    for key, count in js.most_common(TOP_JS):
        print('  %4d  %s  e.g. %s' % (count, key, sorted(js_pages[key])[:EXAMPLES]))
    print('axe violations:')
    for key, count in axe.most_common(TOP_AXE):
        print('  %4d  %s  e.g. %s' % (count, key, sorted(axe_pages[key.split('|')[0]])[:EXAMPLES]))
    print('404s on theme files:')
    for key, count in theme_404.most_common(TOP_404):
        print('  %4d  %s' % (count, key))


if __name__ == '__main__':
    main()
