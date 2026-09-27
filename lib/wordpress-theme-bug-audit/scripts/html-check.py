#!/usr/bin/env python3
"""Check saved pages for structural problems the audit reports.

Usage: html-check.py <folder-of-saved-.html-pages> <out.json>

For every full HTML page in the folder (starting with <!doctype>), it records:
  errs            stray closing tags, tags left unclosed, and JSON-LD blocks that aren't valid JSON
  unclosed_end    tags still open at the end of the page (html, body, p, and li excluded)
  dup_ids         id values used more than once
  hosts           third-party hosts the page loads scripts, styles, images, frames, or media from
  ld_types        the @type values found in its JSON-LD
  imgs / noalt / nosize / first_img_lazy   image counts, images with no alt or no width/height, and whether the
                  first image is lazy-loaded (bad for the largest paint when it's above the fold)

It stands in for the vnu validator when Java isn't installed. Trace each problem to the template that caused it.
"""
# Output (stdout), one line: "<n> pages checked; <n> with structural errors". The per-page report goes to
# <out.json>, keyed by file name. Wrong arguments print the docstring above to stderr and exit 1. A page that
# can't be read is skipped with a one-line stderr note; an unwritable <out.json> exits 1 with a one-line stderr
# message and no stdout. Pages are read in the locale's encoding with undecodable bytes dropped, and hidden
# (dot) files are skipped. Runs on Python 3.7+ (standard library only).
from __future__ import annotations

import collections
import glob
import json
import os
import re
import sys
from html.parser import HTMLParser
from pathlib import Path
from typing import Any

# Elements that never have an end tag.
VOID = {'area', 'base', 'br', 'col', 'embed', 'hr', 'img', 'input', 'link', 'meta', 'param', 'source', 'track', 'wbr'}
# Elements whose end tag HTML lets authors leave out, so closing their parent implicitly closes them.
OPTIONAL_END = {'p', 'li', 'option', 'td', 'tr', 'dt', 'dd', 'th', 'tbody', 'thead'}
# Elements whose src/href loads a resource, for the third-party hosts list.
MEDIA_TAGS = {'script', 'link', 'img', 'iframe', 'source', 'video', 'audio'}
# Host of an absolute http(s) URL.
URL_HOST = re.compile(r'https?://([^/]+)')
# Hosts that are the test site itself, not third parties.
LOCAL_HOST_PREFIXES = ('127.0.0.1', 'localhost')
# Tags allowed to still be open when the page ends (browsers close them).
UNCLOSED_END_OK = ('html', 'body', 'p', 'li')
# Only full documents are checked; fragments saved by probes are skipped.
DOCTYPE_PREFIX = '<!doctype'
# PHP notices printed before the doctype push it down the page; pages with errors must still be checked.
DOCTYPE_SEARCH_CHARS = 20000
# Caps on the per-page lists in the report.
MAX_ERRORS = 10
MAX_UNCLOSED = 5
MAX_DUP_IDS = 10

Problem = tuple  # (description: str, line: int)


class PageParser(HTMLParser):
    def __init__(self) -> None:
        super().__init__()
        self.stack: list[tuple[str, int]] = []
        self.errors: list[Problem] = []
        self.ids: collections.Counter[str] = collections.Counter()
        self.json_ld: list[str] = []
        self.in_json_ld = False
        self.buffer = ''
        self.hosts: set[str] = set()
        self.images: list[dict[str, str | None]] = []

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        attrs_by_name = dict(attrs)
        if attrs_by_name.get('id'):
            self.ids[attrs_by_name['id']] += 1
        for key in ('src', 'href'):
            match = URL_HOST.match(attrs_by_name.get(key) or '')
            if match and tag in MEDIA_TAGS and not match.group(1).startswith(LOCAL_HOST_PREFIXES):
                self.hosts.add(match.group(1))
        if tag == 'img':
            self.images.append(attrs_by_name)
        if tag == 'script' and attrs_by_name.get('type') == 'application/ld+json':
            self.in_json_ld = True
            self.buffer = ''
        if tag not in VOID:
            self.stack.append((tag, self.getpos()[0]))

    def handle_startendtag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        self.handle_starttag(tag, attrs)
        if tag not in VOID:
            self.stack.pop()

    def handle_endtag(self, tag: str) -> None:
        if tag == 'script' and self.in_json_ld:
            self.in_json_ld = False
            self.json_ld.append(self.buffer)
        if tag in VOID:
            return
        if not self.stack:
            self.errors.append(('stray </%s>' % tag, self.getpos()[0]))
            return
        if self.stack[-1][0] == tag:
            self.stack.pop()
            return
        if tag in [name for name, _ in self.stack]:
            while self.stack and self.stack[-1][0] != tag:
                name, line = self.stack.pop()
                if name not in OPTIONAL_END:
                    self.errors.append(('unclosed <%s>' % name, line))
            self.stack.pop()
        else:
            self.errors.append(('stray </%s>' % tag, self.getpos()[0]))

    def handle_data(self, data: str) -> None:
        if self.in_json_ld:
            self.buffer += data


def ld_types(node: Any, found: list[str]) -> None:
    """Append every @type in a parsed JSON-LD tree to `found` (a list of types is joined with commas)."""
    if isinstance(node, dict):
        if '@type' in node:
            value = node['@type']
            if isinstance(value, str):
                found.append(value)
            elif isinstance(value, list):
                found.append(','.join(str(item) for item in value))
            else:
                found.append(str(value))
        for child in node.values():
            ld_types(child, found)
    elif isinstance(node, list):
        for child in node:
            ld_types(child, found)


def check_page(html: str) -> dict[str, Any]:
    """The report entry for one full HTML page."""
    parser = PageParser()
    parser.feed(html)
    types: list[str] = []
    for block in parser.json_ld:
        try:
            ld_types(json.loads(block), types)
        except ValueError as error:
            parser.errors.append(('JSON-LD invalid: %s' % error, 0))
    images = parser.images
    return {
        'errs': parser.errors[:MAX_ERRORS],
        'unclosed_end': [x for x in parser.stack if x[0] not in UNCLOSED_END_OK][:MAX_UNCLOSED],
        'dup_ids': [k for k, v in parser.ids.items() if v > 1][:MAX_DUP_IDS],
        'hosts': sorted(parser.hosts),
        'ld_types': sorted(set(types)),
        'imgs': len(images),
        'noalt': sum(1 for a in images if 'alt' not in a),
        'nosize': sum(1 for a in images if not a.get('width') or not a.get('height')),
        'first_img_lazy': images[0].get('loading') == 'lazy' if images else None,
    }


def page_paths(folder: str) -> list[Path]:
    """The folder's *.html files, sorted. glob.glob (not Path.glob) so dot files stay skipped."""
    return [Path(p) for p in sorted(glob.glob(folder.rstrip('/') + '/*.html'))]


def main() -> None:
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    folder, out_path = sys.argv[1], Path(sys.argv[2])
    report: dict[str, dict[str, Any]] = {}
    if not os.path.isdir(folder):
        sys.exit('html-check: no such folder: %s' % folder)
    skipped = 0
    for path in page_paths(folder):
        try:
            html = path.read_text(errors='ignore')
        except OSError as error:
            print('html-check: skipped %s: %s' % (path, error.strerror or error), file=sys.stderr)
            continue
        if DOCTYPE_PREFIX not in html[:DOCTYPE_SEARCH_CHARS].lower():
            skipped += 1
            continue
        report[path.name] = check_page(html)
    try:
        with out_path.open('w') as out:
            json.dump(report, out, indent=1)
    except OSError as error:
        sys.exit('html-check: cannot write %s: %s' % (out_path, error.strerror or error))
    with_errors = sum(1 for r in report.values() if r['errs'] or r['unclosed_end'])
    print('%d pages checked; %d with structural errors' % (len(report), with_errors))
    if skipped:
        print('html-check: %d saved files had no <!doctype> in their first %d characters and were skipped (not full pages)' % (skipped, DOCTYPE_SEARCH_CHARS), file=sys.stderr)


if __name__ == '__main__':
    main()
