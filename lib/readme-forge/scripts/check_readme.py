#!/usr/bin/env python3
"""Check a generated README against the readme-forge rules.

Prints one line per failed check and exits with status 1 if any check
fails, or prints "PASS" and exits with status 0. Standard library only.

Usage:
    python3 check_readme.py README --folder FOLDER --mode full|compact
        --projects N [--category NAME ...] [--allow-url URL ...]
"""
import argparse
import re
import sys
from collections import Counter
from pathlib import Path

EMOJI = re.compile("[\U0001F000-\U0001FAFF☀-➿️⭐⬆↔-⇿]")
# "harness" and "unlock" from the rules are left out here: they are also
# plain technical terms ("test harness", "unlock the vault").
BANNED = re.compile(
    r"\b(cutting[- ]edge|seamless(ly)?|leverag(e|es|ed|ing)|revolutioni[sz](e|es|ed|ing)"
    r"|empower(s|ed|ing|ment)?|robust|game[- ]changing|supercharg(e|es|ed|ing)"
    r"|elevat(e|es|ed|ing)|next[- ]level|innovative|state[- ]of[- ]the[- ]art"
    r"|delv(e|es|ed|ing)|streamlin(e|es|ed|ing)|comprehensive|showcas(e|es|ed|ing))\b", re.I)
FIXED_H2 = {"table of contents", "summary", "links", "projects"}
URL = re.compile(r"https?://[^\s)>\]`\"',|]+")
# Keep LOCAL in sync with inventory.py.
LOCAL = re.compile(r"https?://(localhost|127\.|0\.0\.0\.0|10\.|192\.168\.|172\.(1[6-9]|2\d|3[01])\.)", re.I)


def strip_code(md):
    return re.sub(r"^(`{3,}|~{3,}).*?^\1\s*$", "", md, flags=re.M | re.S)


def strip_inline_code(md):
    return re.sub(r"`[^`\n]*`", "", md)


def headings(md):
    # A closing "#" sequence needs a space before it, so "C#" keeps its "#".
    return [(len(m.group(1)), m.group(2).strip())
            for m in re.finditer(r"^(#{1,6})\s+(.+?)(?:\s+#+)?\s*$", strip_code(md), re.M)]


def slugs(heads):
    seen, out = {}, []
    for _, text in heads:
        text = re.sub(r"\[([^\]]*)\]\([^)]*\)", r"\1", text).replace("`", "")
        s = re.sub(r"[^\w\- ]", "", text.lower()).replace(" ", "-")
        n = seen.get(s, 0)
        out.append(f"{s}-{n}" if n else s)
        seen[s] = n + 1
    return out


def section(md, name):
    m = re.search(rf"^## {re.escape(name)}\s*$(.*?)(?=^## |\Z)", md, re.M | re.S)
    return m.group(1) if m else None


def table_rows(body):
    rows = [l for l in body.splitlines() if l.strip().startswith("|")]
    return rows[2:] if len(rows) >= 2 else []


def cells(row):
    return [c.strip() for c in re.split(r"(?<!\\)\|", row.strip())[1:-1]]


def norm(u):
    return u.rstrip(".;:/").removesuffix(".git")


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("readme")
    ap.add_argument("--folder", required=True, help="folder with the source .md files")
    ap.add_argument("--mode", choices=["full", "compact"], required=True)
    ap.add_argument("--projects", type=int, required=True,
                    help="number of projects written (project files minus skipped empty files)")
    ap.add_argument("--category", action="append", default=[],
                    help="a category heading used, including Other if used; repeat for each")
    ap.add_argument("--allow-url", action="append", default=[], help="a link the user supplied; repeat for each")
    args = ap.parse_args()
    sys.stdout.reconfigure(encoding="utf-8")

    readme = Path(args.readme).expanduser()
    folder = Path(args.folder).expanduser()
    if not readme.is_file():
        sys.exit(f"error: README not found: {readme}")
    if not folder.is_dir():
        sys.exit(f"error: not a folder: {folder}")
    md = readme.read_text(encoding="utf-8")
    fails = []

    # Writing rules.
    prose = strip_code(md)
    if EMOJI.search(prose):
        fails.append("emoji found: " + ", ".join(sorted(set(EMOJI.findall(prose)))))
    for dash, name in (("—", "em dash"), ("–", "en dash")):
        n = prose.count(dash)
        if n:
            fails.append(f"{name} found {n} time(s)")
    # Project names, technical terms, link text, and URLs are kept as
    # written, so remove them before the banned-word scan.
    heads = headings(md)
    plain = strip_inline_code(prose)
    for _, title in heads:
        plain = re.sub(re.escape(title), "", plain, flags=re.I)
    plain = re.sub(r"^\|([^|]*)\|", "|", plain, flags=re.M)
    plain = re.sub(r"\[[^\]]*\]\([^)]*\)", "", plain)
    plain = URL.sub("", plain)
    hits = sorted({m.group(0).lower() for m in BANNED.finditer(plain)})
    if hits:
        fails.append("banned words: " + ", ".join(hits))
    if re.search(r"<(?!https?:|mailto:)[a-zA-Z][^>]*>", strip_inline_code(prose)):
        fails.append("HTML tag found")

    # Table of contents.
    anchors = set(slugs(heads))
    toc = section(md, "Table of Contents")
    if toc is None:
        fails.append("missing '## Table of Contents'")
    else:
        targets = re.findall(r"\]\(#([^)]+)\)", toc)
        bad = [t for t in targets if t not in anchors]
        if bad:
            fails.append("ToC links with no matching heading: " + ", ".join(bad))
        h2_after = [t for lvl, t in heads if lvl == 2 and t.lower() != "table of contents"]
        toc_text = re.findall(r"^\s*[-*] \[([^\]]+)\]", toc, re.M)
        missing = [h for h in h2_after if h not in toc_text]
        if missing:
            fails.append("H2 headings missing from ToC: " + ", ".join(missing))

    # Project count and per-project limits.
    cats = [c.strip() for c in args.category if c.strip()]
    h2 = [t for lvl, t in heads if lvl == 2]
    for c in cats:
        if c not in h2:
            fails.append(f"category heading missing: '## {c}'")
    if args.mode == "full":
        if cats:
            # Count only H3 headings inside the category sections.
            titles = [t for c in cats for lvl, t in headings(section(md, c) or "") if lvl == 3]
        else:
            titles = [t for t in h2 if t.lower() not in FIXED_H2]
        bullets = 0
        worst = 0
        on = False
        for line in prose.splitlines():
            if re.match(r"^\**details:?\**:?\s*$", line.strip(), re.I):
                on, bullets = True, 0
            elif on and re.match(r"^\s*[-*] ", line):
                bullets += 1
                worst = max(worst, bullets)
            elif on and line.strip():
                on = False
        if worst > 4:
            fails.append(f"a Details list has {worst} bullets (max 4)")
    else:
        bodies = [section(md, c) or "" for c in cats] if cats else [section(md, "Projects") or ""]
        rows = [r for b in bodies for r in table_rows(b)]
        titles = [re.sub(r"\[([^\]]*)\]\([^)]*\)", r"\1", cells(r)[0]) if cells(r) else "" for r in rows]
        for r in rows:
            c = cells(r)
            if len(c) != 4:
                fails.append(f"table row without 4 cells: {r[:60]}")
                continue
            desc = re.sub(r"\(inferred\)", "", c[1]).split()
            if len(desc) > 15:
                fails.append(f"description over 15 words: {c[0]}")
            if len([s for s in c[2].split(",") if s.strip()]) > 4:
                fails.append(f"stack over 4 items: {c[0]}")
    if len(titles) != args.projects:
        fails.append(f"found {len(titles)} projects, expected {args.projects}")
    dup = [t for t, n in Counter(t.lower() for t in titles).items() if n > 1]
    if dup:
        fails.append("repeated project titles: " + ", ".join(dup))

    summary = section(md, "Summary")
    if summary is not None:
        n = len([l for l in summary.splitlines() if l.strip()])
        if n > 8:
            fails.append(f"Summary has {n} lines (max 8)")
    if section(md, "Links") is None:
        fails.append("missing '## Links'")

    # Links.
    # Never count the README itself (or any README.md) as a source.
    own = readme.resolve()
    sources = " ".join(p.read_text(encoding="utf-8", errors="replace")
                       for p in folder.iterdir()
                       if p.is_file() and p.suffix.lower() == ".md"
                       and p.resolve() != own and p.name.lower() != "readme.md")
    allowed = {norm(u) for u in URL.findall(sources)} | {norm(u) for u in args.allow_url}
    found = {norm(u) for u in URL.findall(md)}
    invented = sorted(u for u in found if u not in allowed)
    if invented:
        fails.append("links not found in the sources: " + ", ".join(invented))
    if LOCAL.search(prose) or re.search(r"\blocalhost\b", prose, re.I):
        fails.append("local address found (localhost or private IP)")
    rel = re.findall(r"\]\((?!https?://|#|mailto:)([^)]+)\)", prose)
    if rel:
        fails.append("relative links found: " + ", ".join(rel))

    if fails:
        print("\n".join(f"FAIL: {f}" for f in fails))
        sys.exit(1)
    print("PASS")


if __name__ == "__main__":
    main()
