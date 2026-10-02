#!/usr/bin/env python3
"""Pick the fact sheets a blueprint review needs, and optionally bundle them.

Rules follow references/facts/README.md: always the stack sheet, plus
DATA.md, SERVICES.md, A11Y.md and CICD.md when the blueprint uses a data
store, a hosted service, has accessibility requirements, or a pipeline.

Usage:
  select_facts.py --language "TypeScript" --tech-stack "Next.js + Prisma"
  select_facts.py --blueprint blueprint.v1.md --out facts.md
  select_facts.py --stack WP --db --services --out facts.md
  select_facts.py --stack PYTHON --stack TYPESCRIPT --blueprint blueprint.v1.md --out facts.md

Language values may carry confirmation tags such as "(assumed)"; they are
ignored. A language with no sheet (a "(custom)" one such as Scala) gets
shared sheets only, as does --stack NONE.

Stack precedence: --stack (repeatable, for polyglot plans), then --language,
then a WordPress mention, then keyword hints in the text. Pass --language and
--tech-stack from the confirmed inputs whenever they are known: text hints
are order-dependent and a fallback only. Shared sheets are detected from
--tech-stack and --blueprint text; explicit flags add to what is detected. Prints the chosen
sheets with the reason for each, warns about sheets whose Verified: date is
older than 12 months, and with --out writes them concatenated to one file.
"""
import argparse
import datetime
import re
import sys
from pathlib import Path

FACTS = Path(__file__).resolve().parent.parent / "references" / "facts"

# Language names as PROMPT.md lists them, lowercased, to sheet stems.
LANGUAGES = {
    "typescript": "TYPESCRIPT", "javascript": "JAVASCRIPT", "javascript (node.js)": "JAVASCRIPT",
    "node.js": "JAVASCRIPT", "node": "JAVASCRIPT", "python": "PYTHON", "go": "GO", "golang": "GO",
    "rust": "RUST", "c": "C", "c++": "CPP", "cpp": "CPP", "java": "JAVA", "c#": "CSHARP",
    "csharp": "CSHARP", "php": "PHP", "ruby": "RUBY", "perl": "PERL", "kotlin": "KOTLIN",
    "swift": "SWIFT", "dart": "DART", "haskell": "HASKELL", "clojure": "CLOJURE",
    "erlang": "ERLANG", "elixir": "ELIXIR", "julia": "JULIA", "lua": "LUA", "bash": "BASH",
    "powershell": "POWERSHELL", "jq": "JQ",
}

# Shared sheets: keywords that signal each one in a blueprint or tech stack.
SHARED = {
    "DATA": r"postgres|mysql|mariadb|sqlite|redis|kafka|rabbitmq|timescale|clickhouse"
            r"|elasticsearch|opensearch|pgbouncer|database",
    "SERVICES": r"stripe|vercel|fly\.io|render\.com|on render\b|\baws\b|\bs3\b|\bses\b|lambda|\bsqs\b"
                r"|twilio|sendgrid|postmark|mailgun|resend|supabase|firebase|\bfcm\b"
                r"|cloud run|expo push|push notification",
    "A11Y": r"wcag|accessib|\bada\b|section 508|\baria\b|aria-|screen reader",
    "CICD": r"github actions|\.github/workflows|gitlab ci|ci/cd|pipeline|circleci",
}

# Section-1 / §6 words that pin the stack when no language is given.
STACK_HINTS = [
    ("WP", r"wordpress|woocommerce"),
    ("TYPESCRIPT", r"typescript|next\.js|nestjs|prisma"),
    ("ELIXIR", r"elixir|phoenix|liveview|ecto"),
    ("RUBY", r"\bruby\b|\brails\b"),
    ("PHP", r"laravel|symfony|\bphp\b"),
    ("PYTHON", r"python|django|fastapi|flask"),
    ("KOTLIN", r"kotlin|jetpack compose|ktor"),
    ("JAVA", r"spring boot|\bjava\b|quarkus|micronaut"),
    ("CSHARP", r"asp\.net|\.net|c#|blazor|maui"),
    ("SWIFT", r"swiftui|\bswift\b"),
    ("DART", r"flutter|\bdart\b"),
    ("GO", r"\bgolang\b|\bgo\s*[(+]|\bgin\b|chi router|net/http"),
    ("RUST", r"\brust\b|axum|tokio"),
    ("JAVASCRIPT", r"express|fastify|node\.js|javascript"),
]


# Tags the blueprint prompt's confirmation block may append to an input value.
TAGS = re.compile(r"\s*\((custom|reconciled|assumed|approx|sanitized)\)", re.I)


def sheet_path(stem):
    path = FACTS / f"{stem}.md"
    if not path.is_file():
        sys.exit(f"error: no fact sheet {path.name} in {FACTS}")
    return path


def detect_stack(text):
    """WordPress wins over its language; otherwise the first hint that hits."""
    lowered = text.lower()
    for stem, pattern in STACK_HINTS:
        if re.search(pattern, lowered):
            return stem
    return None


def verified_age_days(path):
    match = re.search(r"^Verified:\s*(\d{4}-\d{2}-\d{2})", path.read_text(), re.M)
    if not match:
        return None
    verified = datetime.date.fromisoformat(match.group(1))
    return (datetime.date.today() - verified).days


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--stack", action="append", default=[],
                        help="sheet stem, e.g. WP, TYPESCRIPT, CSHARP; repeat for several stacks; "
                             "NONE for shared sheets only")
    parser.add_argument("--language", help="LANGUAGE input, e.g. 'C#' or 'JavaScript (Node.js)'")
    parser.add_argument("--tech-stack", default="", help="TECH_STACK input text")
    parser.add_argument("--blueprint", type=Path, help="blueprint file to detect sheets from")
    parser.add_argument("--db", action="store_true", help="force DATA.md")
    parser.add_argument("--services", action="store_true", help="force SERVICES.md")
    parser.add_argument("--a11y", action="store_true", help="force A11Y.md")
    parser.add_argument("--cicd", action="store_true", help="force CICD.md")
    parser.add_argument("--out", type=Path, help="write the chosen sheets, concatenated, to this file")
    args = parser.parse_args()

    text = TAGS.sub("", args.tech_stack)
    if args.blueprint:
        text += "\n" + args.blueprint.read_text()

    language = TAGS.sub("", args.language or "").strip()
    tech_stack = TAGS.sub("", args.tech_stack)
    no_stack_sheet = False
    chosen = [(stem.upper(), "--stack") for stem in args.stack if stem.upper() != "NONE"]  # (stem, reason)
    if args.stack and not chosen:
        no_stack_sheet = True  # --stack NONE: shared sheets only
    if not chosen and not no_stack_sheet and language:
        stack = LANGUAGES.get(language.lower())
        if stack and not (stack == "PHP" and re.search(r"wordpress|woocommerce", tech_stack, re.I)):
            chosen.append((stack, f"language {language!r}"))
        elif not stack:
            no_stack_sheet = True
            print(f"note: no fact sheet for language {language!r}; shared sheets only")
    # WordPress gets WP.md whatever the language: a PHP plugin, or a headless backend.
    if not no_stack_sheet and re.search(r"wordpress|woocommerce", tech_stack, re.I):
        chosen.append(("WP", "WordPress in the tech stack"))
    if not chosen and not no_stack_sheet and re.search(r"wordpress|woocommerce", text, re.I):
        chosen.append(("WP", "WordPress named"))
    if not chosen and not no_stack_sheet and text:
        stack = detect_stack(text)
        if stack:
            chosen.append((stack, "detected from text - confirm, or pass --language"))
    if not chosen and not no_stack_sheet:
        print("note: could not determine the stack; shared sheets only (pass --stack or --language)")

    forced = {"DATA": args.db, "SERVICES": args.services, "A11Y": args.a11y, "CICD": args.cicd}
    for stem, pattern in SHARED.items():
        hit = re.search(pattern, text, re.I)
        if any(stem == c for c, _ in chosen):
            continue
        if forced[stem]:
            chosen.append((stem, "flag"))
        elif hit:
            chosen.append((stem, f"mentions {hit.group(0)!r}"))

    seen = set()
    chosen = [(c, r) for c, r in chosen if not (c in seen or seen.add(c))]
    if not chosen:
        sys.exit("error: no sheets selected; pass --stack, --language, or a shared-sheet flag")

    total = 0
    for stem, why in chosen:
        path = sheet_path(stem)
        size = path.stat().st_size
        total += size
        age = verified_age_days(path)
        stale = f"  WARNING: verified {age} days ago, re-check before relying on it" if age and age > 365 else ""
        print(f"{path.name:16} {size:6} bytes  ({why}){stale}")
    print(f"total {total} bytes in {len(chosen)} sheets")

    if args.out:
        parts = [sheet_path(stem).read_text().rstrip() + "\n" for stem, _ in chosen]
        args.out.write_text("\n---\n\n".join(parts))
        print(f"wrote {args.out}")


if __name__ == "__main__":
    main()
