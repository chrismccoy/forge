#!/usr/bin/env python3
"""Deterministic Unicode-to-ASCII transliteration to the 7-bit US-ASCII range.

Transliterates; never interprets. Specific rules win over the catch-all, and no
character is transformed twice. Preserves line breaks, indentation, and wording.

Usage:
  strip_unicode.py --file PATH      Clean the file in place, print the report.
  strip_unicode.py --text 'STRING'  Clean the string, print cleaned text + report.
  cat file | strip_unicode.py       Clean stdin, print cleaned text + report to stderr.

The report is a Markdown table of every distinct source character that changed,
sorted by count descending, followed by the count of non-ASCII characters left.
"""

import argparse
import sys
import unicodedata

# Specific rules. Applied before the catch-all; first match wins.
SPECIFIC = {
    "—": "-",   # em dash
    "–": "-",   # en dash
    "―": "-",   # horizontal bar
    "“": '"',   # left double quote
    "”": '"',   # right double quote
    "„": '"',   # low double quote
    "‘": "'",   # left single quote
    "’": "'",   # right single quote (apostrophe)
    "‚": "'",   # low single quote
    "…": "...",  # ellipsis
    "•": "-",   # bullet
    "▪": "-",   # black small square
    "◦": "-",   # white bullet
    "⁃": "-",   # hyphen bullet
    " ": " ",   # non-breaking space
    " ": " ",   # thin space
    " ": " ",   # narrow no-break space
    "​": "",    # zero-width space
    "‌": "",    # zero-width non-joiner
    "‍": "",    # zero-width joiner
    "﻿": "",    # zero-width no-break space / BOM
    "≤": "<=",  # less-than or equal
    "≥": ">=",  # greater-than or equal
    "≠": "!=",  # not equal
    "×": "x",   # multiplication sign
    "÷": "/",   # division sign
}

REMOVED = "(removed)"


def transliterate_char(ch):
    """Return the ASCII replacement for one non-ASCII char.

    Specific rule if one exists; otherwise the nearest ASCII form via NFKD
    decomposition. Characters with no ASCII form (currency, emoji, CJK) are
    dropped and reported as (removed).
    """
    if ch in SPECIFIC:
        return SPECIFIC[ch]
    decomposed = unicodedata.normalize("NFKD", ch)
    ascii_form = decomposed.encode("ascii", "ignore").decode("ascii")
    return ascii_form  # may be "" -> removed


def clean(text):
    """Return (cleaned_text, changes) where changes maps source char -> (replacement, count)."""
    out = []
    changes = {}
    for ch in text:
        if ord(ch) < 0x80:
            out.append(ch)
            continue
        replacement = transliterate_char(ch)
        out.append(replacement)
        label = replacement if replacement != "" else REMOVED
        prev = changes.get(ch)
        changes[ch] = (label, (prev[1] if prev else 0) + 1)
    return "".join(out), changes


def report(changes, cleaned):
    """Build the Markdown report exactly as the skill specifies."""
    lines = []
    if not changes:
        lines.append("No changes - already 7-bit ASCII.")
    else:
        lines.append("| char | replaced with | count |")
        lines.append("|------|---------------|-------|")
        for ch, (label, count) in sorted(
            changes.items(), key=lambda kv: (-kv[1][1], kv[0])
        ):
            display = ch if ch not in ("​", "‌", "‍", "﻿") else "(zero-width)"
            shown = label if label != "" else REMOVED
            lines.append(f"| {display} | {shown} | {count} |")
    remaining = [c for c in cleaned if ord(c) >= 0x80]
    if remaining:
        offenders = " ".join(sorted(set(remaining)))
        lines.append(f"\nNon-ASCII remaining: {len(remaining)} ({offenders})")
    else:
        lines.append("\nNon-ASCII remaining: 0")
    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(description="Strip Unicode to 7-bit ASCII.")
    group = parser.add_mutually_exclusive_group()
    group.add_argument("--file", help="Clean this file in place.")
    group.add_argument("--text", help="Clean this literal string.")
    args = parser.parse_args()

    if args.file:
        path = args.file
        try:
            with open(path, "r", encoding="utf-8") as fh:
                original = fh.read()
        except (OSError, UnicodeDecodeError):
            print(f"Error: {path} not writable - no changes made.", file=sys.stderr)
            return 1
        cleaned, changes = clean(original)
        try:
            with open(path, "w", encoding="utf-8") as fh:
                fh.write(cleaned)
        except OSError:
            print(f"Error: {path} not writable - no changes made.", file=sys.stderr)
            return 1
        print(f"Mode: file - target {path}. Cleaned in place.")
        print(report(changes, cleaned))
        return 0

    if args.text is not None:
        source = args.text
    else:
        source = sys.stdin.read()

    cleaned, changes = clean(source)
    sys.stdout.write(cleaned)
    if not cleaned.endswith("\n"):
        sys.stdout.write("\n")
    print(report(changes, cleaned), file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
