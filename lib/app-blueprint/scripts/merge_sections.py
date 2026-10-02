#!/usr/bin/env python3
"""Swap repaired sections from a REVIEW or SCAFFOLD output into a blueprint.

Usage:
  merge_sections.py blueprint.v1.md review-1.md --out blueprint.v2.md
  merge_sections.py blueprint.v2.md review-2.md --report-only

Reads part B of the review or scaffold output (from the "## B." heading to
the "## C." heading), takes every "## N. TITLE" section in it, and replaces
the section with the same number in the blueprint. A section ends at the
next "## " heading, a "Repair map:" line or a "Not re-emitted" line.
Headings inside fenced code blocks are ignored.

--part-out D:file writes any one part (e.g. a scaffold's part D, NOT
VERIFIED, for the spike stage). --previous-out writes part A plus the Repair map (the PREVIOUS input of a
follow-up REVIEW pass); --verify-out writes part C (the VERIFY input of SPIKE).

Also prints the severity counts from the findings tables in parts A and B
(REVIEW puts them in A, SCAFFOLD in B), whether the output says the
follow-up pass is clean, and any sections part B says it could not re-emit.

Exit code 0: merged, or nothing to merge (no --out file is written then, so
the input stays the newest version). Exit code 2: a repaired heading did not
match. A section whose number matches but whose title differs IS replaced
and written; a section number absent from the blueprint is NOT merged.
Check both by hand.
"""
import argparse
import re
import sys
from pathlib import Path

SECTION = re.compile(r"^## (\d+)\.\s")
FENCE = re.compile(r"^\s*(```+|~~~+)")
# Markers that end a repaired section, however the model decorates them
# ("Repair map:", "**Repair map:**", "### Repair map").
REPAIR_MAP = re.compile(r"^[#*_\s]*Repair map\b", re.I)
NOT_REEMITTED = re.compile(r"^[#*_\s]*Not re-emitted\b", re.I)


def split_sections(lines):
    """Return (preamble, {number: [lines]}) for '## N.' sections outside fences."""
    preamble, sections, current, fence = [], {}, None, None
    for line in lines:
        mark = FENCE.match(line)
        if mark:
            token = mark.group(1)[0] * 3
            fence = None if fence == token else (fence or token)
        heading = None if fence else SECTION.match(line)
        if heading:
            current = int(heading.group(1))
            if current in sections:
                sys.exit(f"error: section {current} appears twice in the blueprint (line {line!r}). "
                         "Fold any '§N (repaired)' block into its section, then merge again.")
            sections[current] = [line]
        elif current is None:
            preamble.append(line)
        else:
            sections[current].append(line)
    return preamble, sections


def part(lines, letter, next_letter):
    """Lines between '## <letter>.' and '## <next_letter>.' headings."""
    out, inside = [], False
    for line in lines:
        if re.match(rf"^## {letter}\.", line):
            inside = True
            continue
        if inside and re.match(rf"^## {next_letter}\.", line):
            break
        if inside:
            out.append(line)
    return out


def repaired_sections(part_b):
    sections, current, fence = {}, None, None
    for line in part_b:
        mark = FENCE.match(line)
        if mark:
            token = mark.group(1)[0] * 3
            fence = None if fence == token else (fence or token)
        if not fence:
            heading = SECTION.match(line)
            if heading:
                current = int(heading.group(1))
                sections[current] = [line]
                continue
            if line.startswith("## ") or REPAIR_MAP.match(line) or NOT_REEMITTED.match(line):
                current = None
                continue
        if current is not None:
            sections[current].append(line)
    for number, body in sections.items():
        while body and not body[-1].strip():
            body.pop()
        body.append("")
    return sections


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("blueprint", type=Path)
    parser.add_argument("review", type=Path, help="REVIEW.md or SCAFFOLD.md output")
    parser.add_argument("--out", type=Path, help="merged blueprint (never overwrites the input)")
    parser.add_argument("--report-only", action="store_true")
    parser.add_argument("--previous-out", type=Path, help="write part A + Repair map here")
    parser.add_argument("--verify-out", type=Path, help="write part C here")
    parser.add_argument("--part-out", action="append", default=[], metavar="LETTER:FILE",
                        help="write any part (e.g. D:not-verified.md for a scaffold's part D)")
    args = parser.parse_args()
    if args.out and args.out.resolve() == args.blueprint.resolve():
        sys.exit("error: --out must differ from the input blueprint; keep each version")

    review = args.review.read_text().splitlines()
    part_a = part(review, "A", "B")
    tables = part_a + part(review, "B", "C")
    counts = {sev: sum(1 for l in tables if re.match(rf"^\|[^|]*\|\s*\**{sev}\**\s*\|", l))
              for sev in ("BLOCKER", "MAJOR", "MINOR")}
    print("findings: " + ", ".join(f"{k} {v}" for k, v in counts.items()))
    text = "\n".join(review)
    if "Follow-up pass clean" in text:
        print("follow-up pass clean: yes")
    skipped = re.search(r"Not re-emitted[^:]*:[*_\s]*(.+)", text, re.I)
    if skipped:
        print(f"NOT RE-EMITTED (ask for these): {skipped.group(1).strip()}")

    if args.previous_out:
        repair_map, inside = [], False
        for line in part(review, "B", "C"):
            inside = inside or bool(REPAIR_MAP.match(line))
            if inside:
                repair_map.append(line)
        args.previous_out.write_text("## A. FINDINGS\n" + "\n".join(part_a).strip() + "\n\n"
                                     + "\n".join(repair_map).strip() + "\n")
        print(f"wrote {args.previous_out}")
    if args.verify_out:
        part_c = [l for l in review[next((i for i, l in enumerate(review) if re.match(r"^## C\.", l)), len(review)):]]
        args.verify_out.write_text("\n".join(part_c).strip() + "\n")
        print(f"wrote {args.verify_out}")
    for item in args.part_out:
        letter, _, path = item.partition(":")
        letter = letter.strip().upper()
        start = next((i for i, l in enumerate(review) if re.match(rf"^## {letter}\.", l)), None)
        if start is None:
            print(f"no part {letter} in {args.review}")
            continue
        end = next((i for i in range(start + 1, len(review)) if re.match(r"^## [A-Z]\.", review[i])), len(review))
        Path(path).write_text("\n".join(review[start:end]).strip() + "\n")
        print(f"wrote {path}")

    repairs = repaired_sections(part(review, "B", "C"))
    if not repairs:
        print(f"no repaired sections in part B; nothing to merge - {args.blueprint} stays the newest version")
        return 0

    preamble, sections = split_sections(args.blueprint.read_text().splitlines())
    status = 0
    for number in sorted(repairs):
        old = sections.get(number)
        new_heading = repairs[number][0].strip()
        if old is None:
            print(f"§{number}: not in blueprint - '{new_heading}'")
            status = 2
            continue
        if old[0].strip() != new_heading:
            print(f"§{number}: heading mismatch - blueprint '{old[0].strip()}' vs repair '{new_heading}'")
            status = 2
        print(f"§{number}: replaced ({len(old)} -> {len(repairs[number])} lines)")
        sections[number] = repairs[number]

    if args.report_only:
        return status
    if not args.out:
        sys.exit("error: pass --out (or --report-only)")
    merged = preamble + [l for n in sorted(sections) for l in sections[n]]
    args.out.write_text("\n".join(merged).rstrip() + "\n")
    print(f"wrote {args.out}")
    return status


if __name__ == "__main__":
    sys.exit(main())
