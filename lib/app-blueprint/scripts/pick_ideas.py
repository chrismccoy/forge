#!/usr/bin/env python3
"""Pick random example app ideas from the bundled catalogs, or show one in full.

Usage:
  pick_ideas.py --count 4                       # random across every stack
  pick_ideas.py --language "C#" --count 4       # random from one stack
  pick_ideas.py --stack WP --app-type "web app"
  pick_ideas.py --show GO:17                    # the full five-field block

Each pick prints one line: ID, title, app type and tech stack, so it fits an
AskUserQuestion option. IDs are <STEM>:<entry number>, e.g. GO:17 or MIXED:42.
--show prints the entry's five INPUTS lines exactly as the catalog has them,
ready to use as pre-filled inputs.

Catalogs live in references/ideas/: one <STEM>.md per stack (100 entries
each) and MIXED.md (100 across stacks). The language-to-stem table is the
one select_facts.py uses. A language with no catalog falls back to all of them.
"""
import argparse
import random
import re
import sys
from pathlib import Path

sys.dont_write_bytecode = True  # keep the bundle free of __pycache__
sys.path.insert(0, str(Path(__file__).resolve().parent))
from select_facts import LANGUAGES, TAGS  # noqa: E402

IDEAS = Path(__file__).resolve().parent.parent / "references" / "ideas"
ENTRY = re.compile(r"^## (\d+)\.\s+(.+?)\s*$\n+```text\n(.*?)\n```", re.M | re.S)


def load(stem):
    """Entries of one catalog as dicts: id, title, fields, block."""
    entries = []
    for number, title, block in ENTRY.findall((IDEAS / f"{stem}.md").read_text()):
        fields = dict(line.split(":", 1) for line in block.splitlines() if ":" in line)
        fields = {k.strip(): v.strip() for k, v in fields.items()}
        entries.append({"id": f"{stem}:{number}", "title": title, "fields": fields, "block": block})
    return entries


def catalogs():
    return sorted(p.stem for p in IDEAS.glob("*.md"))


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--language", help="LANGUAGE input, e.g. 'Go' or 'JavaScript (Node.js)'")
    parser.add_argument("--stack", help="catalog stem, e.g. WP, CSHARP, MIXED")
    parser.add_argument("--app-type", help="keep only this APP_TYPE, e.g. 'CLI'")
    parser.add_argument("--count", type=int, default=4)
    parser.add_argument("--seed", type=int, help="fixed seed, for repeatable picks")
    parser.add_argument("--show", nargs="+", metavar="ID", help="print these entries in full")
    args = parser.parse_args()

    available = catalogs()
    if args.show:
        for ident in args.show:
            stem, _, number = ident.upper().partition(":")
            if stem not in available:
                sys.exit(f"error: no catalog {stem}.md")
            match = [e for e in load(stem) if e["id"] == f"{stem}:{number}"]
            if not match:
                sys.exit(f"error: no entry {ident}")
            print(f"# {match[0]['id']} {match[0]['title']}\n{match[0]['block']}\n")
        return

    stems = available
    if args.stack:
        stem = args.stack.upper()
        if stem not in available:
            sys.exit(f"error: no catalog {stem}.md; have {', '.join(available)}")
        stems = [stem]
    elif args.language:
        language = TAGS.sub("", args.language).strip().lower()
        stem = LANGUAGES.get(language)
        if stem in available:
            stems = [stem]
        else:
            print(f"note: no catalog for {args.language!r}; picking across all stacks")

    pool = [e for s in stems for e in load(s)]
    if args.app_type:
        wanted = args.app_type.strip().lower()
        pool = [e for e in pool if e["fields"].get("APP_TYPE", "").lower() == wanted]
    if not pool:
        sys.exit("error: no ideas match")

    rng = random.Random(args.seed)
    for entry in rng.sample(pool, min(args.count, len(pool))):
        f = entry["fields"]
        print(f"{entry['id']}  {entry['title']}  [{f.get('APP_TYPE', '?')} | {f.get('TECH_STACK', '?')}]")


if __name__ == "__main__":
    main()
