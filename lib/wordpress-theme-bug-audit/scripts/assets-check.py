#!/usr/bin/env python3
"""Check every stylesheet, script, and image the saved pages load from the test site.

Usage: assets-check.py <site-url> <folder-of-saved-.html-pages>

The PHP built-in test server answers some missing static files with an empty 200 page instead of a 404, so a
missing stylesheet (a theme's style-rtl.css, for example) never shows up as a 404 in the server log. This fetches
each local asset once and reports it as broken when the status isn't 200, the body is empty, or the content type
doesn't match the file type (a .css served as text/html).

Output (stdout): one line per broken asset, "<status> <bytes> <content-type> <url>  (on <n> pages, e.g. <page>)",
then a summary line "<n> assets checked; <n> broken". Exit 1 with a message when the folder doesn't exist.
<content-type> never contains spaces: whitespace is removed from real content types (text/html;charset=UTF-8),
and a request that got no response shows status 0 and "error:<reason>" with spaces as underscores.
"""
import collections
import glob
import http.client
import os
import re
import sys
import urllib.error
import urllib.parse
import urllib.request

# A <link>, <script>, or <img> start tag, and its attributes (quoted or not, in any order).
ASSET_TAG = re.compile(r'<(link|script|img)\b([^>]*)>', re.I)
ATTRIBUTE = re.compile(r'([\w:-]+)\s*=\s*(?:"([^"]*)"|\'([^\']*)\'|([^\s"\'>]+))')
EXPECTED_TYPE = {'.css': 'text/css', '.js': 'javascript'}
TIMEOUT = 30


def asset_urls(html):
    """The stylesheet hrefs, script srcs, and image srcs in a page."""
    for tag, attributes in ASSET_TAG.findall(html):
        values = {name.lower(): dq or sq or bare for name, dq, sq, bare in ATTRIBUTE.findall(attributes)}
        tag = tag.lower()
        if tag == 'link':
            if 'stylesheet' in values.get('rel', '').lower().split() and values.get('href'):
                yield values['href']
        elif values.get('src'):
            yield values['src']


def local_assets(site, folder):
    pages_by_asset = collections.defaultdict(set)
    host = urllib.parse.urlparse(site).netloc
    for path in sorted(glob.glob(folder.rstrip('/') + '/*.html')):
        try:
            html = open(path, errors='ignore').read()
        except OSError:
            continue
        for url in asset_urls(html):
            url = urllib.parse.urljoin(site + '/', url.replace('&#038;', '&').replace('&amp;', '&'))
            if urllib.parse.urlparse(url).netloc == host:
                pages_by_asset[url].add(os.path.basename(path))
    return pages_by_asset


def fetch(url):
    request = urllib.request.Request(url, headers={'User-Agent': 'theme-bug-audit assets-check'})
    try:
        with urllib.request.urlopen(request, timeout=TIMEOUT) as response:
            return response.status, len(response.read()), response.headers.get('Content-Type', '')
    except urllib.error.HTTPError as error:
        return error.code, 0, error.headers.get('Content-Type', '') if error.headers else ''
    except (urllib.error.URLError, http.client.HTTPException, OSError, ValueError) as error:
        return 0, 0, 'error:%s' % re.sub(r'\s+', '_', str(getattr(error, 'reason', error)))


def broken(url, status, size, content_type):
    if status != 200 or size == 0:
        return True
    extension = os.path.splitext(urllib.parse.urlparse(url).path)[1].lower()
    expected = EXPECTED_TYPE.get(extension)
    return bool(expected) and expected not in content_type.lower()


def main():
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    site, folder = sys.argv[1].rstrip('/'), sys.argv[2]
    if not os.path.isdir(folder):
        sys.exit('assets-check: no such folder: %s' % folder)
    assets = local_assets(site, folder)
    bad = 0
    for url in sorted(assets):
        status, size, content_type = fetch(url)
        if broken(url, status, size, content_type):
            bad += 1
            pages = sorted(assets[url])
            content_type = re.sub(r'\s+', '', content_type)
            print('%s %d %s %s  (on %d pages, e.g. %s)' % (status, size, content_type or '-', url, len(pages), pages[0]))
    print('%d assets checked; %d broken' % (len(assets), bad))


if __name__ == '__main__':
    main()
