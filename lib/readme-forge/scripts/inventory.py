#!/usr/bin/env python3
"""List the markdown files in a folder for readme-forge.

Prints JSON with the bio file, one entry per project file (title, word
count, links), the default project order, duplicate titles, and the
recommended mode. Standard library only.

Usage:
    python3 inventory.py FOLDER [--bio FILE] [--exclude FILE ...]
"""
import argparse
import json
import re
import sys
from pathlib import Path

# In order of preference.
BIO_NAMES = ["bio.md", "about.md", "about-me.md", "me.md", "profile.md", "author.md", "resume.md"]
DEFAULT_EXCLUDE = {"readme.md"}
COMPACT_THRESHOLD = 25
# Section names the README uses. A project with one of these titles gets
# its filename stem added, so the heading stays unique.
FIXED_SECTIONS = {"table of contents", "summary", "links", "projects", "other"}
EMOJI = re.compile("[\U0001F000-\U0001FAFF☀-➿️⭐⬆↔-⇿‍]")
# A closing "#" sequence needs a space before it, so "C#" keeps its "#".
HEADING = re.compile(r"^#{1,6}\s+(.+?)(?:\s+#+)?\s*$", re.M)
SETEXT = re.compile(r"^(\S.*)\n(=+|-+)\s*$", re.M)
FRONT_MATTER = re.compile(r"\A---\s*\n(.*?)\n---\s*\n", re.S)
URL = re.compile(r"https?://[^\s)>\]`\"',]+")
MD_LINK = re.compile(r"\]\(([^)\s]+)")
# Keep LOCAL in sync with check_readme.py.
LOCAL = re.compile(r"https?://(localhost|127\.|0\.0\.0\.0|10\.|192\.168\.|172\.(1[6-9]|2\d|3[01])\.)", re.I)


def title_for(path, text):
    """First heading of any level, emojis removed, subtitle after a colon
    or spaced dash dropped. Falls back to the filename in Title Case."""
    fm = FRONT_MATTER.match(text)
    body = text[fm.end():] if fm else text
    fm_title = re.search(r"^title:\s*['\"]?(.+?)['\"]?\s*$", fm.group(1), re.M) if fm else None
    body = strip_code(body)
    candidates = [m for m in (HEADING.search(body), SETEXT.search(body)) if m]
    m = min(candidates, key=lambda x: x.start()) if candidates else None
    raw = fm_title.group(1) if fm_title else (m.group(1) if m else None)
    if raw:
        title = re.sub(r"!\[[^\]]*\]\([^)]*\)", "", raw)  # images and badges
        title = re.sub(r"\[([^\]]*)\]\([^)]*\)", r"\1", title)  # links keep their text
        title = EMOJI.sub("", title)
        # Remove emphasis markers that wrap text, keep underscores in names.
        title = re.sub(r"(\*\*|\*)(.+?)\1", r"\2", title)
        title = re.sub(r"(?<!\w)(__|_)(.+?)\1(?!\w)", r"\2", title).replace("`", "")
        # Drop a subtitle after a colon or a spaced dash.
        title = re.split(r":|\s[\u2014\u2013-]\s", title)[0].strip()
        if title:
            return title
    return " ".join(w.capitalize() for w in re.split(r"[-_\s]+", path.stem) if w)


def strip_code(text):
    return re.sub(r"^(`{3,}|~{3,}).*?^\1\s*$", "", text, flags=re.M | re.S)


def links_for(text):
    absolute, local, relative = set(), set(), set()
    for u in URL.findall(text):
        u = u.rstrip(".;:")
        (local if LOCAL.match(u) else absolute).add(u)
    for target in MD_LINK.findall(text):
        if not re.match(r"^(https?:|mailto:|#)", target):
            relative.add(target)
    return sorted(absolute), sorted(local), sorted(relative)


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("folder")
    ap.add_argument("--bio", help="bio filename, if not one of the usual bio names")
    ap.add_argument("--exclude", action="append", default=[], help="a filename to skip; repeat for each")
    args = ap.parse_args()
    sys.stdout.reconfigure(encoding="utf-8")

    folder = Path(args.folder).expanduser()
    if not folder.is_dir():
        sys.exit(f"error: not a folder: {folder}")
    exclude = DEFAULT_EXCLUDE | {e.lower() for e in args.exclude}
    # Top-level .md files only, in any case.
    files = sorted(p for p in folder.iterdir()
                   if p.is_file() and p.suffix.lower() == ".md" and p.name.lower() not in exclude)

    bio = None
    if args.bio:
        bio = next((p for p in files if p.name.lower() == args.bio.lower()), None)
        if bio is None:
            sys.exit(f"error: bio file not found in {folder}: {args.bio}")
    bio_like = sorted((p for p in files if p.name.lower() in BIO_NAMES),
                      key=lambda p: BIO_NAMES.index(p.name.lower()))
    if bio is None and bio_like:
        bio = bio_like[0]
    # A bio chosen with --bio is final, so there is nothing left to ask.
    other_bio_candidates = [] if args.bio else [p.name for p in bio_like if p != bio]

    projects = []
    for p in files:
        if p == bio:
            continue
        text = p.read_text(encoding="utf-8", errors="replace")
        words = len(text.split())
        absolute, local, relative = links_for(text)
        projects.append({
            "file": p.name,
            "title": title_for(p, text),
            "words": words,
            "possibly_empty": words < 5,
            "links": absolute,
            "local_links_to_drop": local,
            "relative_links_to_drop": relative,
        })

    # Give clashing titles the filename stem in parentheses.
    for proj in projects:
        if proj["title"].lower() in FIXED_SECTIONS:
            proj["title"] = f"{proj['title']} ({Path(proj['file']).stem})"
    seen = {}
    for proj in projects:
        seen.setdefault(proj["title"].lower(), []).append(proj)
    duplicates = []
    for group in seen.values():
        if len(group) > 1:
            for proj in group:
                proj["title"] = f"{proj['title']} ({Path(proj['file']).stem})"
            duplicates.append([g["file"] for g in group])

    order = sorted(projects, key=lambda x: (-x["words"], x["title"].lower()))
    count = len(projects)
    result = {
        "folder": str(folder),
        "bio": bio.name if bio else None,
        "other_bio_candidates": other_bio_candidates,
        "project_count": count,
        "recommended_mode": "compact" if count > COMPACT_THRESHOLD else "full",
        "default_order": [p["file"] for p in order],
        "duplicate_titles": duplicates,
        "possibly_empty": [p["file"] for p in projects if p["possibly_empty"]],
        "projects": order,
    }
    json.dump(result, sys.stdout, indent=2, ensure_ascii=False)
    print()


if __name__ == "__main__":
    main()
