#!/usr/bin/env python3
"""Mechanical final check for a blog post written with the `human` skill.

Usage:
    python3 -I check_post.py POST [--source SOURCE] [--grave] [--allow WORD]...

POST and SOURCE are text files; use "-" for stdin. The first line of POST is
the title; everything after it is the body.

Checks:
  - title is one plain-text line
  - body paragraphs with more than 4 sentences
  - body markup: headings, bullet or numbered lists, bold
  - emphasis: doubled ?? or !! and all-caps words. Want 2-4 in total, with
    at least one doubled mark and at least one separate all-caps word. A caps
    word glued to a doubled mark ("SO???") counts once, as the doubled mark.
    All-caps tokens that also appear in the source (acronyms) are ignored.
    With --grave, want no caps and no expressive punctuation.
  - banned words, including inflections (--allow exempts the literal subject)
  - word count of the body and ratio to the source

Exit code is 0 when every check passes, 1 otherwise. Fact coverage is not
checked; reread the source for that.
"""
import argparse
import re
import sys

# name -> pattern. --allow matches the name or any word the pattern matches.
BANNED = {
    "delve": r"\bdelv\w*",
    "navigate": r"\bnavigat\w*",
    "expertise": r"\bexpertise\b",
    "tapestry": r"\btapestr\w*",
    "realm": r"\brealms?\b",
    "landscape": r"\blandscapes?\b",
    "journey": r"\bjourney\w*",
    "unlock": r"\bunlock\w*",
    "elevate": r"\belevat\w*",
    "leverage": r"\bleverag\w*",
    "robust": r"\brobust\w*",
    "seamless": r"\bseamless\w*",
    "game-changer": r"\bgame[- ]?changer\w*",
    "in today's fast-paced world": r"\bin today's fast-paced world\b",
    "it's important to note": r"\bit's important to note\b",
    "at the end of the day": r"\bat the end of the day\b",
    "dive in": r"\b(dive|diving|dove) in(to)?\b",
    "embark": r"\bembark\w*",
    "folks": r"\bfolks\b",
    "fam": r"\bfam\b",
}
WORD = re.compile(r"\w+")
DOUBLED = re.compile(r"\?{2,}|!{2,}|[?!]*\?![?!]*|[?!]*!\?[?!]*")
CAPS_THEN_DOUBLED = re.compile(r"(\w+)(?=\?{2,}|!{2,}|\?!|!\?)")
ANY_EXPRESSIVE = re.compile(r"[?!]{2,}|‽")
ABBREV = re.compile(r"\b(e\.g|i\.e|p\.m|a\.m|vs|etc|Dr|Mr|Mrs|Ms|Sr|Sra|St|No|U\.S|U\.K)\.|\b[A-Z]\.(?=\s*[A-Z])")
SENT_END = re.compile(r"[.!?…‽]+[\"'”’)»]*(?=\s|$)")
BODY_MARKUP = re.compile(r"^\s*(#|[-*•]\s|\d+[.)]\s)|\*\*|__", re.M)


def read(path):
    if path == "-":
        return sys.stdin.read()
    with open(path, encoding="utf-8") as f:
        return f.read()


def sentences(par):
    return max(1, len(SENT_END.findall(ABBREV.sub("X", par.strip()))))


def is_caps(tok):
    return len(tok) >= 2 and tok.isupper() and not any(c.isdigit() for c in tok)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("post")
    ap.add_argument("--source")
    ap.add_argument("--grave", action="store_true", help="grave topic: no emphasis allowed")
    ap.add_argument("--allow", action="append", default=[], help="banned word allowed as the literal subject (repeatable)")
    args = ap.parse_args()

    post = read(args.post).strip()
    title, _, body = post.partition("\n")
    source = read(args.source) if args.source else ""
    paras = [p for p in re.split(r"\n\s*\n", body) if p.strip()]
    ok = True

    def fail(msg):
        nonlocal ok
        ok = False
        print("FAIL " + msg)

    # Title
    if re.match(r"\s*(#|\*\*|__)", title):
        fail("title uses markup; use plain text")
    if body and body[:1].strip():
        fail("title is not alone on its line; add a blank line after it")

    # Paragraph length
    long_paras = [(i + 1, sentences(p)) for i, p in enumerate(paras) if sentences(p) > 4]
    for n, s in long_paras:
        fail(f"body paragraph {n} has {s} sentences (max 4)")
    if not long_paras:
        print("ok   paragraphs: all 4 sentences or fewer")

    # Body markup
    markup = BODY_MARKUP.findall(body)
    if markup:
        fail("body has headings, lists, or bold")
    else:
        print("ok   body markup: none")

    # Emphasis
    source_caps = {t for t in WORD.findall(source) if is_caps(t)}
    glued = {m.start() for m in CAPS_THEN_DOUBLED.finditer(post)}
    doubled = DOUBLED.findall(post)
    caps = [m.group() for m in WORD.finditer(post)
            if is_caps(m.group()) and m.group() not in source_caps and m.start() not in glued]
    found = doubled + caps
    if args.grave:
        expressive = ANY_EXPRESSIVE.findall(post)
        if caps or expressive:
            fail(f"grave topic has emphasis: {expressive + caps}")
        else:
            print("ok   grave topic: no emphasis")
    else:
        problems = []
        if not 2 <= len(found) <= 4:
            problems.append(f"count {len(found)} (want 2-4)")
        if not doubled:
            problems.append("no doubled ?? or !!")
        if not caps:
            problems.append("no separate all-caps word")
        if problems:
            fail(f"emphasis: {', '.join(problems)}; found {found}")
        else:
            print(f"ok   emphasis: {len(found)} {found}")

    # Banned words
    plain = post.replace("’", "'")
    allowed = {w.lower() for w in args.allow}
    hits = []
    for name, pattern in BANNED.items():
        if name in allowed or any(re.fullmatch(pattern.replace(r"\b", ""), a) for a in allowed):
            continue
        hits += [m.group() for m in re.finditer(pattern, plain, re.I)]
    if hits:
        fail(f"banned words: {hits}")
    else:
        print("ok   banned words: none")

    # Length
    words = len(body.split())
    if args.source:
        src = len(source.split())
        print(f"info body words: {words} (source {src}, ratio {words / max(src, 1):.2f})")
    else:
        print(f"info body words: {words}")

    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
