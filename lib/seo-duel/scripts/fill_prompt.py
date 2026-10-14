#!/usr/bin/env python3
"""Fill the SEO Duel judge prompt with two posts and context.

Writes two filled prompts: <out-dir>/run_ab.md (post 1 as A, post 2 as B)
and <out-dir>/run_ba.md (order swapped), for the position-bias check.

Placeholders are replaced only in the final "## Input" section, in one
pass. Placeholders that appear earlier (inside the Intake Check) stay
untouched, and placeholder-like text inside a post is never rewritten.

Usage:
  fill_prompt.py --prompt references/judge-prompt.md \
      --post1 post-1.md --post2 post-2.md --out-dir /tmp/run \
      [--keyword K] [--secondary S] [--audience A] [--goal G]

Omitted context fields keep their placeholder, which the judge prompt
treats as missing.
"""
import argparse
import pathlib
import re

INPUT_HEADING = "\n## Input\n"
PLACEHOLDERS = {
    "keyword": "[KEYWORD]",
    "secondary": '[KEYWORDS, or "none"]',
    "audience": "[WHO THE READER IS]",
    "goal": "[e.g., organic traffic, email sign-ups, product sales]",
}


def fill(template, ctx, post_a, post_b):
    i = template.rfind(INPUT_HEADING)
    if i < 0:
        raise SystemExit("template has no '## Input' section")
    head, tail = template[:i], template[i:]

    values = {"[PASTE POST A]": post_a, "[PASTE POST B]": post_b}
    for field, placeholder in PLACEHOLDERS.items():
        if ctx.get(field):
            values[placeholder] = ctx[field]
    for placeholder in values:
        if placeholder not in tail:
            raise SystemExit(f"placeholder not found in Input: {placeholder}")

    # One pass: inserted text is never scanned again.
    pattern = re.compile("|".join(re.escape(p) for p in values))
    return head + pattern.sub(lambda m: values[m.group(0)], tail)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--prompt", required=True)
    ap.add_argument("--post1", required=True)
    ap.add_argument("--post2", required=True)
    ap.add_argument("--out-dir", required=True)
    for field in PLACEHOLDERS:
        ap.add_argument(f"--{field}")
    args = ap.parse_args()

    template = pathlib.Path(args.prompt).read_text()
    p1 = pathlib.Path(args.post1).read_text().strip()
    p2 = pathlib.Path(args.post2).read_text().strip()
    if not p1 or not p2:
        raise SystemExit("a post file is empty")
    ctx = {f: getattr(args, f) for f in PLACEHOLDERS}

    out = pathlib.Path(args.out_dir)
    out.mkdir(parents=True, exist_ok=True)
    (out / "run_ab.md").write_text(fill(template, ctx, p1, p2))
    (out / "run_ba.md").write_text(fill(template, ctx, p2, p1))
    print(out / "run_ab.md")
    print(out / "run_ba.md")


if __name__ == "__main__":
    main()
