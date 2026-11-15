#!/usr/bin/env python3
"""Inventory every file in a skill directory.

Static and read-only: never executes, imports, or follows anything inside the
target skill. Symlinks (file and directory) are reported, never followed.
Vendored/cache directories are listed with file counts instead of walked.

Usage:
    python3 -I inventory.py <skill_dir | SKILL.md> [--format md|json] [--heading-level N]

json: {"skill_dir", "tree", "files": [...], "skipped_dirs": [...], "totals": {...}, "grep_exclude": "!{...}"}
Each entry in "files": path, kind (file | symlink | dir-symlink | special |
unreadable | unreadable-dir), category, bytes, lines, words, binary, executable,
shebang, generated (lockfile/minified by name), large (> 100 KB), code (code suffix, file in scripts/, or
executable with a shebang), encoding (utf-8 | nul-text | utf-16 | binary), hardlinked, referenced (named by SKILL.md), truncated, quote_fence (fence string
that safely quotes the file verbatim), plus symlink_target/points_outside for
links and error for unreadable entries.
"plugin" (or null): when the skill sits in a plugin or uses ${CLAUDE_PLUGIN_ROOT},
the plugin root, name, plugin-level files the skill depends on (each described
like a skill file, plus "reason"), unresolved references, hook and MCP server
commands, and the plugin's other skills/agents/commands.
"""
import argparse
import json
import os
import re
import stat
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))  # this skill's scripts/ only
import _common as C  # noqa: E402
from lint_skill import collect_refs, referenced_by  # noqa: E402

CATEGORIES = {"references", "scripts", "assets", "examples", "templates"}


def category_for(rel):
    if rel == "SKILL.md":
        return "skill"
    if "/" not in rel:
        return "meta" if rel.lower().startswith(("readme", "license", "changelog")) else "root-other"
    top = rel.split("/", 1)[0]
    return top if top in CATEGORIES else "other-dir"


def build_tree(paths):
    lines, seen = [], set()
    for p in sorted(paths):
        parts = p.rstrip("/").split("/")
        for depth in range(len(parts) - 1):
            d = "/".join(parts[: depth + 1])
            if d not in seen:
                seen.add(d)
                lines.append("    " * depth + parts[depth] + "/")
        lines.append("    " * (len(parts) - 1) + parts[-1] + ("/" if p.endswith("/") else ""))
    return "\n".join(lines)


def skill_md_refs(skill_dir):
    try:
        data, _ = C.read_bytes(os.path.join(skill_dir, "SKILL.md"))
    except OSError:
        return None, ""
    body = C.split_frontmatter(C.decode(data))[2]
    return collect_refs(body), body


_BUDGET = [0]  # bytes read in this inventory run


def describe(full, rel, category, referenced):
    """Describe one regular file. Never follows links; never executes."""
    entry = {"path": rel, "kind": "file", "category": category}
    try:
        st = os.lstat(full)
    except OSError as exc:
        entry.update(kind="unreadable", error=str(exc.strerror or exc))
        return entry
    entry["bytes"] = st.st_size
    if st.st_nlink > 1:
        entry["hardlinked"] = True
    executable = bool(st.st_mode & (stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH))
    entry["executable"] = executable
    entry["referenced"] = referenced
    entry["generated"] = C.is_generated(rel)
    if C.is_credential_path(rel):
        entry["credential"] = True  # never Read it in full; the Appendix omits it
    entry["large"] = st.st_size > C.LARGE_FILE
    if _BUDGET[0] > C.MAX_TOTAL_SCAN:  # past the total budget: list the file, do not read it
        entry.update(encoding="not read (total budget reached)", code=C.is_code(rel) and not entry.get("credential"),
                     shebang=None)
        return entry
    try:
        data, truncated = C.read_bytes(full, C.MAX_READ_CODE)
    except OSError as exc:
        entry.update(kind="unreadable", error=str(exc.strerror or exc))
        return entry
    _BUDGET[0] += len(data)
    enc, text = C.to_text(data, truncated)
    first = (text or "").split("\n", 1)[0]
    entry["shebang"] = C.excerpt(first, 200) if first.startswith("#!") and not entry.get("credential") else None
    # Executable bit alone is not trusted (some mounts mark everything executable).
    entry["code"] = (C.is_code(rel) or bool(executable and entry["shebang"])) and not entry.get("credential")
    entry["truncated"] = truncated
    entry["encoding"] = enc
    entry["binary"] = text is None
    if text is not None:
        text = C.normalize_newlines(text)
        entry["lines"] = text.count("\n") + (0 if text.endswith("\n") or not text else 1)
        entry["words"] = len(text.split())
        entry["quote_fence"] = C.quote_fence(text)
    return entry


def inventory(target):
    _BUDGET[0] = 0
    skill_dir, _ = C.resolve_target(target)
    files, skipped = [], []
    refs, body = skill_md_refs(skill_dir)
    entries = C.walk(skill_dir)
    for e in entries:
        rel = e["path"]
        if e["kind"] == "skipped-dir":
            skipped.append({"path": rel, "file_count": e["file_count"]})
            continue
        if e["kind"] != "file":
            entry = {"path": rel, "kind": e["kind"], "category": category_for(rel)}
            for k in ("error", "symlink_target", "points_outside"):
                if k in e:
                    entry[k] = e[k]
            files.append(entry)
            continue
        referenced = rel == "SKILL.md" or bool(refs and referenced_by(rel, refs, body))
        files.append(describe(os.path.join(skill_dir, rel), rel, category_for(rel), referenced))
    text_files = [f for f in files if f["kind"] == "file" and not f.get("binary")]
    totals = {
        "files": len(files),
        "text_files": len(text_files),
        "binary_files": sum(1 for f in files if f.get("binary")),
        "symlinks": sum(1 for f in files if f["kind"] in ("symlink", "dir-symlink")),
        "special_files": sum(1 for f in files if f["kind"] == "special"),
        "unreadable": sum(1 for f in files if f["kind"].startswith("unreadable")),
        "skipped_dir_files": sum(s["file_count"] for s in skipped),
        "bytes": sum(f.get("bytes", 0) for f in files),
        "words": sum(f.get("words", 0) for f in text_files),
        "has_skill_md": any(f["path"] == "SKILL.md" and f["kind"] == "file" for f in files),
        "code_referenced_words": sum(f.get("words", 0) for f in text_files if f.get("code") or f.get("referenced")),
        "by_category": {},
    }
    for f in files:
        c = totals["by_category"].setdefault(f["category"], {"files": 0, "words": 0})
        c["files"] += 1
        c["words"] += f.get("words", 0)
    tree = build_tree([f["path"] + ("/" if f["kind"] == "dir-symlink" else "") for f in files] +
                      [s["path"] for s in skipped])
    tree_lines = tree.split("\n")
    if len(tree_lines) > 300:  # keep JSON output bounded; "files" has every path anyway
        tree = "\n".join(tree_lines[:300] + ["... {} more lines".format(len(tree_lines) - 300)])

    plugin = C.plugin_context(skill_dir, entries)
    if plugin and plugin["root"]:
        described = []
        for pf in plugin["files"]:
            if pf["kind"] == "file":
                d = describe(os.path.join(plugin["root"], pf["path"]), pf["path"], "plugin", True)
            else:
                d = {"path": pf["path"], "kind": pf["kind"], "category": "plugin"}
                full = os.path.join(plugin["root"], pf["path"])
                if pf["kind"] == "symlink":
                    d["symlink_target"] = C.excerpt(os.readlink(full), 300)
                    d["points_outside"] = not C.inside(os.path.realpath(full), plugin["root"])
            d["reason"] = pf["reason"]
            described.append(d)
        plugin["files"] = described
    # The exact Grep exclusion for this target: the standard credential names plus every file marked
    # credential. Pass it as the Grep tool's glob (Grep does not follow symlinks).
    excl = ["**/.env*", "**/*.env", "**/.envrc", "**/*.pem", "**/*.key", "**/*.p8", "**/*.p12", "**/*.pfx",
            "**/*.jks", "**/*.ppk", "**/*.kdbx", "**/*.tfvars", "**/*.tfstate", "**/id_rsa", "**/id_rsa.pub", "**/id_dsa", "**/id_dsa.pub",
            "**/id_ecdsa", "**/id_ecdsa.pub", "**/id_ecdsa_sk", "**/id_ed25519", "**/id_ed25519.pub", "**/id_ed25519_sk", "**/.netrc", "**/.npmrc", "**/.pypirc", "**/.pgpass",
            "**/.git-credentials", "**/.htpasswd", "**/token.json", "**/secrets.json", "**/secrets.y*ml",
            "**/client_secret*.json", "**/kubeconfig", "**/kubeconfig.yaml", "**/kubeconfig.yml", "**/kubeconfig.json", "**/secrets.toml", "**/*.keystore", "**/.credentials*",
            "**/*service*account*.json", "**/credentials", "**/credentials.json", "**/credentials.y*ml",
            "**/credentials.toml", "**/credentials.ini", "**/credentials.cfg", "**/credentials.conf",
            "**/credentials.xml", "**/credentials.properties", "**/credentials.env",
            "**/secret.json", "**/secret.y*ml", "**/secret.key",
            "**/secrets.txt", "**/secrets.ini", "**/secrets.cfg", "**/secrets.conf",
            "**/secrets.properties", "**/secret.txt", "**/.vault-token", "**/.s3cfg", "**/.dockercfg",
            "**/.terraformrc"]
    # (Narrow names only: a doc named credentials.md or secrets-handling.md must stay searchable. Credential
    # files the inventory found are added by path below.)
    # Names with glob metacharacters (a comma splits the brace list) cannot be listed safely: flag them instead.
    cred = [f["path"] for f in files if f.get("credential")]
    # Vendored folders are not inventoried, but Grep still searches them: their credential names count too
    # (names only; nothing there is read).
    for e in C.walk(skill_dir, include_skipped=True):
        if len(cred) >= 400:
            break
        if e["kind"] in ("file", "symlink") and C.in_skipped_dir(e["path"]) and C.is_credential_path(e["path"]):
            cred.append(e["path"])
    safe = [p for p in cred if not re.search(r"[,{}\[\]*?!\\\s]", p)]  # whitespace may split the argument too
    # By base name under **/, so the glob still matches when Grep runs from a subfolder of the target.
    if plugin and plugin.get("root"):  # plugin files the skill uses are searched too
        cred += [f["path"] for f in plugin.get("files", []) if C.is_credential_path(f["path"])]
        safe = [p for p in cred if not re.search(r"[,{}\[\]*?!\\\s]", p)]
    names = list(dict.fromkeys(p.rsplit("/", 1)[-1] for p in safe))
    def glob_name(n):  # a credential-shaped part of a file name is globbed out, never quoted (".env.ghp_*")
        hits = C.find_secrets(n)
        for s_, e_, _r, _d in sorted(hits, reverse=True):
            n = n[:s_] + "*" + n[e_:]
        return n
    excl += ["**/" + glob_name(n) for n in names[:200]]
    # Past 200 names, or past the 400-file look into vendored folders, the glob is incomplete: say so, never drop
    overflow = [n for n in names[200:] if not any(C.fnmatch_path(n, g[3:]) for g in excl if g.startswith("**/"))]
    grep_unsafe = ([C.safe_name(p) for p in cred if p not in safe] + [C.safe_name(n) for n in overflow])[:50]
    if len(overflow) > 50 or len(cred) >= 400:
        grep_unsafe.append("(more credential files than the glob can name: Grep named files only)")
    grep_exclude = "!{" + ",".join(dict.fromkeys(excl)) + "}"
    return {"skill_dir": skill_dir, "tree": tree, "files": files, "skipped_dirs": skipped, "totals": totals,
            "grep_exclude": grep_exclude,
            "grep_exclude_misses": grep_unsafe,  # credential files the glob cannot name: Grep named files only
            "plugin": plugin}


def plugin_markdown(plugin, level):
    out = [C.heading(level, "Plugin context"), ""]
    if not plugin["root"] and plugin.get("refused"):
        out.append("The plugin root was refused and not read: " + C.safe_name(plugin["refused"]))
        return out
    if not plugin["root"]:
        out.append("SKILL.md uses `${CLAUDE_PLUGIN_ROOT}` but no plugin root was found (expected "
                   "`<root>/skills/<name>/` with `<root>/.claude-plugin/plugin.json`). Unresolved: " +
                   (", ".join("`{}`".format(C.safe_name(m)) for m in plugin.get("missing", [])) or "-"))
        return out
    out.append("Plugin `{}` at `{}`.".format(C.safe_name(plugin["name"] or ""), C.safe_name(plugin["root"])))
    out += ["", "| Plugin file | Kind | Lines | Bytes | Why included |", "|---|---|---|---|---|"]
    for f in plugin["files"]:
        out.append("| `{}` | {} | {} | {} | {} |".format(C.safe_name(f["path"]), f["kind"], f.get("lines", "-"),
                                                       f.get("bytes", "-"), C.md_cell(f["reason"])))
    if plugin.get("missing"):
        out += ["", "Unresolved `${CLAUDE_PLUGIN_ROOT}` references: " +
                ", ".join("`{}`".format(C.safe_name(m)) for m in plugin["missing"])]
    for label, key in (("Hook commands", "hook_commands"), ("MCP server commands", "mcp_commands"),
                       ("Other plugin commands", "other_commands")):
        if plugin.get(key):
            out += ["", label + ":", ""] + ["- `{}`".format(C.safe_name(c)) for c in plugin[key]]
    if plugin.get("components"):
        out += ["", "Other components: " + "; ".join(
            "{}: {}".format(C.md_cell(k), ", ".join(C.md_cell(x) for x in v)) for k, v in plugin["components"].items())]
    if plugin["truncated"]:
        out += ["", "Plugin file list capped at {} entries.".format(C.MAX_PLUGIN_FILES)]
    return out


def to_markdown(inv, level=2):
    out = [C.heading(level, "Inventory"), ""]
    if "tree" in inv:  # absent under --brief and on pages after the first
        out += ["```", C.safe_name(os.path.basename(inv["skill_dir"])) + "/"]
        out += ["    " + C.safe_name(line) for line in inv["tree"].splitlines()]
        out += ["```", ""]
    out += ["| Path | Kind | Category | Lines | Words | Bytes | Exec | Notes |",
            "|---|---|---|---|---|---|---|---|"]
    for f in inv["files"]:
        notes = []
        if f.get("error"):
            notes.append("unreadable: " + str(f["error"]))
        if "symlink_target" in f:
            notes.append("-> {}{}".format(C.safe_name(f["symlink_target"]),
                                          " (OUTSIDE skill)" if f["points_outside"] else ""))
        if f.get("binary"):
            notes.append("binary")
        if f.get("hardlinked"):
            notes.append("hardlinked")
        if f.get("credential"):
            notes.append("credential file: do not read")
        if f.get("encoding") in ("utf-16", "nul-text"):
            notes.append(f["encoding"])
        if f.get("generated"):
            notes.append("generated")
        if f.get("large"):
            notes.append("large")
        if f.get("referenced") and f["path"] != "SKILL.md":
            notes.append("referenced")
        if f.get("truncated"):
            notes.append("read capped")
        if f.get("shebang"):
            notes.append("shebang `" + C.safe_name(f["shebang"]) + "`")
        out.append("| `{}` | {} | {} | {} | {} | {} | {} | {} |".format(
            C.safe_name(f["path"]), f["kind"], f["category"], f.get("lines", "-"), f.get("words", "-"),
            f.get("bytes", "-"), "yes" if f.get("executable") else "no", C.md_cell("; ".join(notes))))
    for s in inv["skipped_dirs"]:
        out.append("| `{}` | skipped-dir | - | - | - | - | - | {} files not inventoried (security scan still "
                   "covers them, except .git) |".format(C.safe_name(s["path"]), s["file_count"]))
    t = inv["totals"]
    out += ["", "Totals: {files} entries ({text_files} text, {binary_files} binary, {symlinks} symlinks, "
            "{special_files} special, {unreadable} unreadable), {words} words, {bytes} bytes; {skipped_dir_files} files in skipped "
            "dirs.".format(**t)]
    if not t["has_skill_md"]:
        out.append("**No `SKILL.md` found at the skill root.**")
    if inv.get("plugin"):
        out += [""] + plugin_markdown(inv["plugin"], level + 1)
    return "\n".join(out)


def main():
    C.safe_stdout()
    ap = argparse.ArgumentParser(description=__doc__.split("\n", 1)[0])
    ap.add_argument("target", help="skill directory or SKILL.md path")
    ap.add_argument("--format", choices=["md", "json"], default="md")
    ap.add_argument("--heading-level", type=int, default=2)
    args = ap.parse_args()
    skill_dir, _ = C.resolve_target(args.target)
    if not os.path.isdir(skill_dir):
        print("error: not a skill directory or SKILL.md: " + args.target, file=sys.stderr)
        return 2
    inv = inventory(args.target)
    print(json.dumps(inv, indent=2) if args.format == "json" else to_markdown(inv, args.heading_level))
    return 0


if __name__ == "__main__":
    sys.exit(main())
