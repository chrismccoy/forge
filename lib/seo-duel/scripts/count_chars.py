#!/usr/bin/env python3
"""Check a title tag and meta description against their length limits.

Usage:
  count_chars.py <<'EOF'
  title tag text
  ===
  meta description text
  EOF

The first block is the title tag (must be under 60 characters), the second
is the meta description (must be under 155). Blocks are separated by a line
holding only ===. Surrounding newlines are ignored. Counts are Unicode code
points. Exit code is 1 if either is over its limit or a block is missing.
"""
import sys

LIMITS = [("title tag", 60), ("meta description", 155)]
SEPARATOR = "==="


def main():
    blocks, current = [], []
    for line in sys.stdin.read().split("\n"):
        if line.strip() == SEPARATOR:
            blocks.append("\n".join(current))
            current = []
        else:
            current.append(line)
    blocks.append("\n".join(current))
    blocks = [b.strip("\n") for b in blocks]

    if len(blocks) != 2 or not all(blocks):
        print("expected two blocks: title tag, ===, meta description")
        return 1

    failed = False
    for (name, limit), text in zip(LIMITS, blocks):
        n = len(text)
        if n < limit:
            print(f"{name}: {n} characters, under {limit} OK")
        else:
            print(f"{name}: {n} characters, OVER (must be under {limit})")
            failed = True
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
