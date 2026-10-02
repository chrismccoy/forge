#!/usr/bin/env python3
"""Count characters in GitHub bios and flag any over the 160-character limit.

Usage:
  count_chars.py FILE [FILE ...]    one bio per file
  count_chars.py < bios.txt         several bios on stdin, separated by a line holding only ===

A single trailing newline on each bio is ignored. Counts are Unicode code points,
so a joined emoji such as a person-with-laptop counts as more than one character.
Exit code is 1 if any bio is over the limit.
"""
import sys

LIMIT = 160
SEPARATOR = "==="


def bios_from_stdin():
    bios, current = [], []
    for line in sys.stdin.read().split("\n"):
        if line.strip() == SEPARATOR:
            bios.append("\n".join(current))
            current = []
        else:
            current.append(line)
    bios.append("\n".join(current))
    return [(f"bio {i}", b.strip("\n")) for i, b in enumerate(bios, 1) if b.strip()]


def bios_from_files(paths):
    out = []
    for path in paths:
        with open(path, encoding="utf-8") as f:
            text = f.read()
        if text.endswith("\n"):
            text = text[:-1]
        out.append((path, text))
    return out


def main(args):
    bios = bios_from_files(args) if args else bios_from_stdin()
    if not bios:
        sys.exit(__doc__)
    over = False
    for name, text in bios:
        count = len(text)
        status = "OK" if count <= LIMIT else f"OVER by {count - LIMIT}"
        print(f"{name}: {count}/{LIMIT} {status}")
        over = over or count > LIMIT
    return 1 if over else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
