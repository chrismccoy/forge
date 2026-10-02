#!/usr/bin/env python3
"""Fill the {{TOKENS}} in a bundled prompt and write a ready-to-run copy.

Usage:
  render_prompt.py review --set BLUEPRINT=@blueprint.v1.md --set FACTS=@facts.md \
      --out review-1.prompt.md
  render_prompt.py scaffold --set BLUEPRINT=@blueprint.v2.md --set BUDGET="2 hours" \
      --set WORKDIR=/home/me/scaffold-kennelflow --out scaffold.prompt.md

The first argument is a prompt name (blueprint, review, scaffold, spike) or a
path. "@file" reads the value from a file; anything else is used literally.
Tokens left unset stay as the literal "{{TOKEN}}", which every bundled prompt
treats as "not provided", so optional inputs can simply be omitted.

Only the "### INPUTS" line for each token is filled, never other mentions of
the token in the prompt's rules, so the rules keep reading as written. A
multi-line value is placed in a fenced block under the INPUTS block and the
INPUTS line points at it.
"""
import argparse
import re
import sys
from pathlib import Path

PROMPTS = Path(__file__).resolve().parent.parent / "references" / "prompts"


def load_value(raw):
    if raw.startswith("@"):
        path = Path(raw[1:])
        if not path.is_file():
            sys.exit(f"error: {path} not found")
        return path.read_text().strip()
    return raw


def fence_for(text):
    """A backtick fence longer than any run of backticks inside the text."""
    longest = max((len(m) for m in re.findall(r"`+", text)), default=0)
    return "`" * max(4, longest + 1)


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("prompt", help="blueprint | review | scaffold | spike | path to a prompt file")
    parser.add_argument("--set", action="append", default=[], metavar="KEY=VALUE",
                        help="token value; VALUE may be @file")
    parser.add_argument("--out", type=Path, required=True)
    args = parser.parse_args()

    source = PROMPTS / f"{args.prompt}.md"
    if not source.is_file():
        source = Path(args.prompt)
    if not source.is_file():
        sys.exit(f"error: no prompt {args.prompt!r}")
    text = source.read_text()

    appendix = []
    for item in args.set:
        key, sep, raw = item.partition("=")
        if not sep:
            sys.exit(f"error: --set needs KEY=VALUE, got {item!r}")
        key = key.strip().upper()
        # The INPUTS line: "KEY<spaces>: {{KEY}}   # comment"
        line = re.compile(rf"^({re.escape(key)}\s*:\s*)\{{\{{{re.escape(key)}\}}\}}", re.M)
        if not line.search(text):
            sys.exit(f"error: {source.name} has no INPUTS line for {{{{{key}}}}}")
        value = load_value(raw)
        if "\n" in value:
            fence = fence_for(value)
            appendix.append(f"#### {key}\n{fence}text\n{value}\n{fence}\n")
            replacement = f"(see the {key} block below the INPUTS)"
        else:
            replacement = value
        text = line.sub(lambda m: m.group(1) + replacement, text, count=1)

    if appendix:
        # Insert the value blocks right after the INPUTS block (first blank line after the heading).
        head, marker, rest = text.partition("### INPUTS")
        block, blank, tail = rest.partition("\n\n")
        text = head + marker + block + "\n\n" + "\n".join(appendix) + blank + tail

    missing = sorted(set(re.findall(r"^[A-Z_]+\s*:\s*\{\{([A-Z_]+)\}\}", text, re.M)))
    args.out.write_text(text)
    print(f"wrote {args.out} ({len(text)} chars)")
    if missing:
        print("left unset (prompt treats as not provided): " + ", ".join(missing))


if __name__ == "__main__":
    main()
