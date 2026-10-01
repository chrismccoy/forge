#!/usr/bin/env bash
# Find the theme's media folders: folders that hold at least 10 MB, are at least 90% media files by size and by count,
# and contain no code at all (no PHP, JS, CSS, JSON, HTML, SVG, or template files, except a placeholder index.php of
# under 200 bytes), so linking a folder can never hide code from the audit. The audit never reads these file by file
# and never copies them: test sites link each one as a single folder.
# Only the topmost matching folder is listed (a matching folder inside another matching folder isn't listed again).
#
# Usage: media-dirs.sh <theme-dir> [--report]
#   Prints the folders as space-separated paths relative to the theme, ready for AUDIT_MEDIA_DIRS.
#   With --report, prints one line per folder instead: <path> <size> <file count> <share that is media>.
#
# Media: images (jpg, jpeg, png, gif, webp, avif, bmp, ico, tif, tiff, psd), video (mp4, webm, mov, m4v, ogv, avi),
# audio (mp3, ogg, oga, wav, m4a, flac), and fonts (woff, woff2, ttf, otf, eot). SVG is left out: it's text, can hold
# script, and is usually small enough to read.
#
# Output: without --report, exactly one line, empty when no folder matches (so an empty line is a valid answer).
# Exit 1 with a one-line stderr message when <theme-dir> doesn't exist; a missing argument exits 1 (bash's
# ${1:?} behaviour, like the other scripts). .git folders are skipped at any depth; node_modules, vendor, and audit
# only at the theme's top level (nested inside a candidate folder they hold code and count against it).
# Symlinks are ignored. Needs python3. An index.php under 200 bytes is skipped only when it holds nothing but the
# opening tag, whitespace, comments, and an optional closing tag.
# A matching folder whose path contains whitespace is left out (the list is space-separated, so it couldn't be
# parsed back); one stderr line names it, and test sites copy it instead of linking it.

set -uo pipefail

theme_arg="${1:?usage: media-dirs.sh <theme-dir> [--report]}"
mode="${2:-}"
theme="$(cd "$theme_arg" 2>/dev/null && pwd -P)"
[[ -n "$theme" ]] || { printf 'media-dirs: theme dir not found: %s\n' "$theme_arg" >&2; exit 1; }

python3 - "$theme" "$mode" <<'PY'
import os
import re
import sys

theme, mode = sys.argv[1], sys.argv[2]
# File extensions counted as media (images, video, audio, fonts).
MEDIA = {
    'jpg', 'jpeg', 'png', 'gif', 'webp', 'avif', 'bmp', 'ico', 'tif', 'tiff', 'psd',
    'mp4', 'webm', 'mov', 'm4v', 'ogv', 'avi', 'mp3', 'ogg', 'oga', 'wav', 'm4a', 'flac',
    'woff', 'woff2', 'ttf', 'otf', 'eot',
}
# Folder names never walked, at any depth.
SKIP = {'.git', 'node_modules', 'vendor', 'audit'}
# File extensions that disqualify a folder: linking it would hide code from the audit.
CODE = {'php', 'js', 'mjs', 'cjs', 'ts', 'jsx', 'tsx', 'css', 'scss', 'sass', 'less', 'json', 'html', 'htm', 'svg', 'twig', 'xml', 'inc', 'phtml', 'vue',
        'php3', 'php4', 'php5', 'php7', 'php8', 'pht', 'phar', 'htaccess'}
# An index.php smaller than this is a "silence is golden" placeholder, not code.
PLACEHOLDER_MAX_BYTES = 200
# A placeholder holds only an opening tag, whitespace, comments, and an optional closing tag. Each part matches only
# one way (no catastrophic backtracking); a line comment holding "?" counts as code, since "?>" ends it.
PLACEHOLDER_BODY = re.compile(
    br'\s*<\?php(?:\s|//[^\n?]*(?=\n|\Z)|#[^\n?]*(?=\n|\Z)|/\*(?:[^*]|\*(?!/))*\*/)*(?:\?>\s*)?\Z')
# Smallest folder worth linking.
MIN_BYTES = 10 * 1024 * 1024
# Share of the folder, by size and by file count, that must be media.
SHARE = 0.9
MEGABYTE = 1048576


def is_placeholder(path):
    """True for an index.php that only holds comments; an unreadable file counts as code."""
    try:
        with open(path, 'rb') as handle:
            return PLACEHOLDER_BODY.match(handle.read()) is not None
    except OSError:
        return False


def walk_bottom_up(top):
    """os.walk with SKIP folders pruned at the theme's top level, yielded children first.

    Only the top level is pruned: a vendor/ or node_modules/ nested inside a candidate folder holds code, and must
    count against it. .git is pruned everywhere. os.walk(topdown=False) ignores changes to `dirs`, so walk top-down
    (where pruning works) and reverse.
    """
    entries = []
    for root, dirs, files in os.walk(top):
        if root == top:
            dirs[:] = [d for d in dirs if d not in SKIP]
        else:
            dirs[:] = [d for d in dirs if d != '.git']
        entries.append((root, dirs, files))
    return reversed(entries)


totals = {}
for root, dirs, files in walk_bottom_up(theme):
    rel = os.path.relpath(root, theme)
    size = count = media_size = media_count = code = 0
    for name in files:
        path = os.path.join(root, name)
        if os.path.islink(path):
            continue
        try:
            n = os.path.getsize(path)
        except OSError:
            continue
        if name == 'index.php' and n < PLACEHOLDER_MAX_BYTES and is_placeholder(path):
            continue
        size += n
        count += 1
        ext = name.rsplit('.', 1)[-1].lower()
        if ext in MEDIA:
            media_size += n
            media_count += 1
        elif ext in CODE:
            code += 1
    for d in dirs:
        child = totals.get(os.path.join(rel, d) if rel != '.' else d)
        if child:
            size += child[0]
            count += child[1]
            media_size += child[2]
            media_count += child[3]
            code += child[4]
    totals[rel] = (size, count, media_size, media_count, code)

found = []
for rel in sorted(totals, key=lambda r: r.count(os.sep)):
    if rel == '.':
        continue
    if any(rel == f or rel.startswith(f + os.sep) for f in found):
        continue
    size, count, media_size, media_count, code = totals[rel]
    if code == 0 and size >= MIN_BYTES and count and media_size >= SHARE * size and media_count >= SHARE * count:
        if any(c.isspace() for c in rel):
            sys.stderr.write('media-dirs: skipped, path has whitespace: %s\n' % rel)
            continue
        found.append(rel)

if mode == '--report':
    for rel in found:
        size, count, media_size, media_count, code = totals[rel]
        print('%s %.0fMB %d files %d%% media' % (rel, size / MEGABYTE, count, 100 * media_size / size))
else:
    print(' '.join(found))
PY
