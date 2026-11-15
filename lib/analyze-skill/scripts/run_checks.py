#!/usr/bin/env python3
"""Run the static checks (siblings only on request) on a skill and merge the results.

Imports inventory, lint_skill, scan_security, and scan_requirements from this
file's own directory. Executes nothing from the target skill.

Usage:
    python3 -I -B run_checks.py [--format md|json] [--only inventory|lint|security|requirements|siblings]
                                [--offset N --limit N] [--heading-level N] -- <skill_dir | SKILL.md>

json: compact {"inventory": ..., "lint": ..., "security": ..., "requirements": ...}; --only limits it
      to one key so large results fit a tool's output limit. A check that crashes
      is reported as {"<check>": {"error": "..."}} and the exit code is 1.
      --offset/--limit page the main list of each selected check (inventory
      "files", lint, security, and requirements "findings"); each paged check gains
      "page": {"offset", "limit", "total"}; inventory also pages plugin.files
      and its total covers both lists. Unpaged fields (tree, suppressed,
      not_covered, plugin commands) appear on the first page only. Keep calling
      with a higher offset until offset + limit >= total.
md:   one Markdown block; the title uses --heading-level, each check one deeper.

Refuses (exit 2) a target without a regular SKILL.md at its root, and home,
root, system, or credential directories.
"""
import argparse
import json
import os
import sys
import traceback

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))  # this skill's scripts/ only
import _common as C  # noqa: E402
import inventory  # noqa: E402
import lint_skill  # noqa: E402
import scan_security  # noqa: E402
import scan_requirements  # noqa: E402

CHECKS = [
    ("inventory", inventory.inventory, inventory.to_markdown),
    ("lint", lint_skill.lint, lint_skill.to_markdown),
    ("security", scan_security.scan, scan_security.to_markdown),
    ("requirements", scan_requirements.scan, scan_requirements.to_markdown),
    ("siblings", scan_requirements.siblings_check, scan_requirements.siblings_markdown),
]
LIST_KEY = {"inventory": "files", "lint": "findings", "security": "findings", "requirements": "findings",
            "siblings": "siblings"}


def run_all(target, only=None):
    results, failed = {}, False
    for key, fn, _ in CHECKS:
        if (only and key != only) or (not only and key == "siblings"):
            continue  # siblings runs only on request (--only siblings)
        try:
            results[key] = fn(target)
        except Exception as exc:  # keep the other checks' output
            results[key] = {"error": C.excerpt("{}: {}".format(type(exc).__name__, exc), 300),
                            "trace": C.redact_text(traceback.format_exc(limit=3))[:2000]}
            failed = True
    return results, failed


def to_markdown(target, results, level=2):
    parts = [C.heading(level, "Automated checks: `{}`".format(C.safe_name(os.path.basename(C.resolve_target(target)[0])))), ""]
    for key, _, md in CHECKS:
        if key not in results:
            continue
        res = results[key]
        if "error" in res:
            parts += [C.heading(level + 1, key), "", "Check failed: `{}`".format(C.safe_name(res["error"])), ""]
        else:
            parts += [md(res, level + 1).rstrip(), ""]
    return "\n".join(parts)


def redact_tree(obj, key=None):
    """Redact secret-shaped text in every string of the output (a file or plugin named like a token).

    grep_exclude is left whole: it is a glob of file names, and a redacted name would stop excluding the file.
    """
    if isinstance(obj, str):
        if key == "grep_exclude" or len(obj) < 8:
            return obj
        hits = [h for h in C.find_secrets(obj) if "[REDACTED:" not in obj[h[0]:h[1]]]
        return C.redact(obj, hits) if hits else obj
    if isinstance(obj, dict):
        return {k: redact_tree(v, k) for k, v in obj.items()}
    if isinstance(obj, list):
        return [redact_tree(v, key) for v in obj]
    return obj


def main():
    C.safe_stdout()
    ap = argparse.ArgumentParser(description=__doc__.split("\n", 1)[0])
    ap.add_argument("target", help="skill directory or SKILL.md path")
    ap.add_argument("--format", choices=["md", "json"], default="md")
    ap.add_argument("--only", choices=[k for k, _, _ in CHECKS])
    ap.add_argument("--offset", type=int, default=0)
    ap.add_argument("--limit", type=int, default=0, help="0 = no paging")
    ap.add_argument("--heading-level", type=int, default=2)
    ap.add_argument("--brief", action="store_true",
                    help="smaller output for large skills: no tree, no item details, 1 source per item, "
                         "20 suppressed locations per rule")
    args = ap.parse_args()
    if args.offset < 0 or args.limit < 0:
        print("error: --offset and --limit must be 0 or more", file=sys.stderr)
        return 2
    if args.offset and not args.limit:
        print("error: --offset needs --limit", file=sys.stderr)
        return 2
    err = C.validate_target(args.target)
    if err:
        print("error: " + err, file=sys.stderr)
        return 2
    results, failed = run_all(args.target, args.only)
    if args.brief:
        for key, res in results.items():
            res.pop("tree", None)
            for axis in ("runtime", "packages", "binaries", "network", "tools", "companions"):
                for item in res.get(axis, []) if isinstance(res.get(axis), list) else []:
                    item.pop("detail", None)
                    item["sources"] = item.get("sources", [])[:1]
            for v in (res.get("suppressed") or {}).values():
                if isinstance(v, dict):
                    v["locations"] = v.get("locations", [])[:20]
    if args.limit > 0:
        for key, res in results.items():
            list_key = LIST_KEY[key]
            if isinstance(res.get(list_key), list):
                total = len(res[list_key])
                res[list_key] = res[list_key][args.offset:args.offset + args.limit]
                res["page"] = {"offset": args.offset, "limit": args.limit, "total": total}
            plugin = res.get("plugin") if key == "inventory" else None
            if plugin and isinstance(plugin.get("files"), list):
                ptotal = len(plugin["files"])
                plugin["files"] = plugin["files"][args.offset:args.offset + args.limit]
                plugin["page"] = {"offset": args.offset, "limit": args.limit, "total": ptotal}
                res["page"]["total"] = max(res["page"]["total"], ptotal)
            if args.offset > 0:  # heavy, unpaged fields appear on the first page only
                for k in ("tree", "suppressed", "not_covered", "declared", "frontmatter", "siblings", "grep_exclude"):
                    if k != LIST_KEY[key]:  # never drop the list being paged
                        res.pop(k, None)
                if plugin:
                    for k in ("hook_commands", "mcp_commands", "other_commands", "components", "missing"):
                        plugin.pop(k, None)
    results = redact_tree(results)
    if args.format == "json":
        print(json.dumps(results, separators=(",", ":"), default=str))
    else:
        print(to_markdown(args.target, results, args.heading_level))
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
