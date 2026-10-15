#!/usr/bin/env python3
"""Build docs/index.html, the landing page, from tools/landing-template.html.

Reads the tool list from README.md ("Available commands" plus the quick-start taglines),
each tool's size from the SUMMARY.md tables, the version from .claude-plugin/plugin.json,
and file counts from each lib/<tool>/ folder. Stops with an error instead of writing a
page with gaps: a missing lib/ folder, tagline, size, or a category the template lacks.

Usage: tools/build_landing.py [repo root]
  arg 1: repository root (default: the folder above this script)
"""
import json, os, re, sys

ROOT = os.path.abspath(sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(__file__), ".."))
TEMPLATE = os.path.join(ROOT, "tools", "landing-template.html")
OUT = os.path.join(ROOT, "docs", "index.html")
TIERS = {"## Small": "Quick win", "## Guided": "Helper", "## Full": "Toolkit"}


def read_lines(name):
    with open(os.path.join(ROOT, name), encoding="utf-8") as f:
        return f.read().splitlines()


def taglines(readme):
    """Map command -> short tagline from the quick-start lines "/cmd   # tagline"."""
    tags = {}
    for line in readme:
        m = re.match(r"^/([\w-]+)\s+#\s+(.*)$", line)
        if m:
            tags[m.group(1)] = m.group(2)
    return tags


def tiers(summary):
    """Map lib folder -> Toolkit / Helper / Quick win from the SUMMARY.md tables."""
    tier, current = {}, None
    for line in summary:
        if line.startswith("## "):
            current = next((v for k, v in TIERS.items() if line.startswith(k)), None)
        m = re.match(r"^\| `([\w-]+)` \| `/[\w-]+`", line)
        if m and current:
            tier[m.group(1)] = current
    return tier


def folder_stats(path):
    """Count files, references, scripts, and lines of Markdown under one lib/ folder."""
    files = [os.path.join(d, f) for d, _, names in os.walk(path) for f in names]
    lines = 0
    for f in files:
        if f.endswith(".md"):
            with open(f, encoding="utf-8", errors="ignore") as fh:
                lines += sum(1 for _ in fh)
    return dict(
        lines=lines,
        refs=sum(f"{os.sep}references{os.sep}" in f for f in files),
        scripts=sum(f"{os.sep}scripts{os.sep}" in f for f in files),
        files=len(files),
    )


def collect():
    readme, summary = read_lines("README.md"), read_lines("SUMMARY.md")
    tags, tier = taglines(readme), tiers(summary)
    end = next(i for i, l in enumerate(readme) if l.startswith("## Quick start"))
    tools, errors, cat = [], [], None
    for line in readme[:end]:
        m = re.match(r"^\*\*(.+)\*\*$", line)
        if m:
            cat = m.group(1)
            continue
        m = re.match(r"^- \[`/([\w-]+)`\]\(docs/([\w-]+)\.md#([\w-]+)\)\.\s*(.*)$", line)
        if not m:
            continue
        cmd, doc, lib, desc = m.groups()
        path = os.path.join(ROOT, "lib", lib)
        if not os.path.isdir(path):
            errors.append(f"/{cmd}: no lib/{lib}/ folder")
            continue
        if cmd not in tags:
            errors.append(f"/{cmd}: no tagline in the README quick start")
        if lib not in tier:
            errors.append(f"/{cmd}: {lib} is not in any SUMMARY.md table")
        tools.append(dict(cmd=cmd, lib=lib, cat=cat, doc=doc, type=tier.get(lib, ""),
                          tag=tags.get(cmd, ""), desc=desc, **folder_stats(path)))
    return tools, errors


def main():
    tools, errors = collect()
    with open(TEMPLATE, encoding="utf-8") as f:
        template = f.read()
    known = set(re.findall(r"""name:\s*["']([^"']+)["']""", template))
    for c in sorted({t["cat"] for t in tools} - known):
        errors.append(f"category '{c}' is missing from CATS in tools/landing-template.html")
    if errors:
        sys.exit("build_landing: not written\n  " + "\n  ".join(errors))

    with open(os.path.join(ROOT, ".claude-plugin", "plugin.json"), encoding="utf-8") as f:
        version = json.load(f)["version"]
    # "</" is escaped so a description can never close the <script> block early.
    data = json.dumps(tools, ensure_ascii=False, separators=(",", ":")).replace("</", "<\\/")
    page = template.replace("__TOOLS__", data).replace("__VERSION__", version)
    with open(OUT, "w", encoding="utf-8") as f:
        f.write(page)

    by_cat = {}
    for t in tools:
        by_cat[t["cat"]] = by_cat.get(t["cat"], 0) + 1
    print(f"wrote {os.path.relpath(OUT, ROOT)}: {len(tools)} commands, v{version}")
    for c, n in by_cat.items():
        print(f"  {n:>3}  {c}")


if __name__ == "__main__":
    main()
