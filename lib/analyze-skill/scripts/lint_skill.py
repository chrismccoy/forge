#!/usr/bin/env python3
"""Lint a skill's SKILL.md, file references, and scripts against Claude Code and
Agent Skills conventions.

Static and read-only: never executes or imports anything inside the target.
Python scripts are inspected with ast.parse (parsing does not execute code).

Usage:
    python3 -I lint_skill.py <skill_dir | SKILL.md> [--format md|json] [--heading-level N]

json: {"skill_dir", "frontmatter", "metrics", "findings": [...]}
Each finding: id, severity (error|warn|info), message, file, line (or null).
Findings are heuristics: confirm each by reading the cited line before reporting.
"""
import argparse
import ast
import fnmatch
import itertools
import json
import os
import collections
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))  # this skill's scripts/ only
import _common as C  # noqa: E402

# Documented at code.claude.com/docs/en/skills and agentskills.io/specification.
KNOWN_FIELDS = {
    "name", "description", "when_to_use", "argument-hint", "arguments",
    "disable-model-invocation", "user-invocable", "allowed-tools", "disallowed-tools",
    "model", "effort", "context", "agent", "background", "hooks", "paths", "shell",
    "metadata", "license", "compatibility",
}
TOLERATED_FIELDS = {"version"}  # common in plugin skills; undocumented, ignored
EFFORT_VALUES = {"low", "medium", "high", "xhigh", "max"}

# Size thresholds - keep in sync with references/skill-spec.md section 7.
WORDS_TARGET, WORDS_WARN, WORDS_ERROR, LINES_WARN = 2000, 3000, 3750, 500

NAME_RE = re.compile(r"^[a-z0-9]+(-[a-z0-9]+)*$")
SECOND_PERSON_RE = re.compile(r"\b(you|your|yours|yourself|you're|you'll|you've|you'd)\b", re.I)
FIRST_PERSON_RE = re.compile(r"(?<![/\w-])(I'm|I'll|I've|I|[Mm]e|[Mm]y)(?![/\w'-])")
RES_DIRS = r"(?:references|scripts|assets|examples|templates)"
PATH_TOKEN_RE = re.compile(r"(?<![\w/.:~$-])(?:\$\{CLAUDE_SKILL_DIR\}/)?(" + RES_DIRS + r"/[A-Za-z0-9_.*?/-]*)")
MD_LINK_RE = re.compile(r"\]\(([^()\s\]]{1,512})\)")  # no '(' or ']' inside: a run of "](" fails at once
# A leftover marker ("TODO: finish", "- TBD") - not prose about markers ("never leave a TODO").
PLACEHOLDER_RE = re.compile(r"(?<!\ba )(?<!\ban )(?<!\bthe )(?<!\bto )(?<!\bno )(?<!\bany )(?<!\bor )"
                            r"(?<![`'\"])\b(TODO|FIXME|TBD|XXX)\b(?![`'\"])")
DOLLAR_ARG_RE = re.compile(r"(?<![\w\\$])\$[0-9](?![\w.,])")
ARG_USE_RE = re.compile(r"\$ARGUMENTS\b|(?<![\w\\$])\$[0-9](?![\d.,])")
DYNAMIC_RE = re.compile(r"(^|\s)!`[^`]+`")
WINDOWS_PATH_RE = re.compile(r"\b" + RES_DIRS + r"\\[A-Za-z0-9_]")
SAMPLING_RE = re.compile(r"\b(temperature|top[_ -]?p|top[_ -]?k|frequency penalty|presence penalty)\b"
                         r"\s*(of|at|=|:|~|\(|to)?\s*~?\d", re.I)
RELATIVE_SCRIPT_RE = re.compile(r"(?<![\w}/.+-])" + C.INTERPRETERS + r"(\s+-\S{1,40}){0,10}\s+[\"']?(\./)?" + RES_DIRS + r"/")
BARE_SCRIPT_RE = re.compile(r"^\s*[\"']?(\./)?scripts/\S+")
META_FILES = re.compile(r"^(readme|license|licence|changelog|contributing|notice)(\.|$)", re.I)


# ---------------------------------------------------------------- helpers

fenced_flags = C.fenced_flags



def bad_yaml_line(fm_text, error=""):
    """The SKILL.md line that breaks the YAML: the parser's own line when the error names one, else a best
    guess (a plain scalar holding ': ' or ' #')."""
    m = re.search(r"frontmatter line (\d+)", error)
    if m:
        return int(m.group(1))
    for i, ln in enumerate(fm_text.split("\n"), 2):
        m = re.match(r"^\s*[\w-]+:\s+(.*)$", ln)
        if m and m.group(1)[:1] not in "\"'|>[{" and (": " in m.group(1) or " #" in m.group(1)):
            return i
    return 1

def strip_inline_code(line):
    return re.sub(r"`[^`]*`", "", line)


def sentences(text):
    """Yield (normalized, original) sentences. Compare the normalized form; quote only the original,
    because normalizing strips the case and punctuation that secret redaction depends on."""
    text = re.sub(r"`[^`]*`", " ", text)
    for s in re.split(r"(?<=[.!?])\s+|\n\s*\n", text):
        norm = re.sub(r"\s+", " ", re.sub(r"[^a-z0-9 ]", "", s.lower())).strip()
        if len(norm.split()) >= 8:
            yield norm, s


_LINT_READ = {"bytes": 0, "skipped": 0}  # one byte budget per lint run (C.MAX_TOTAL_SCAN), like the scan's


def read_text(path):
    if _LINT_READ["bytes"] > C.MAX_TOTAL_SCAN:
        _LINT_READ["skipped"] += 1
        return None
    try:
        data, _ = C.read_bytes(path)
    except OSError:
        return None
    _LINT_READ["bytes"] += len(data)
    if C.is_binary(data):
        return None
    return C.normalize_newlines(C.decode(data))


def collect_refs(text):
    """Return {'files', 'globs', 'dirs', 'outside'} sets of paths referenced in text."""
    refs = {"files": set(), "globs": set(), "dirs": set(), "outside": set()}

    def classify(p):
        p = p.rstrip(".,;:)'\"")
        if not p:
            return
        if any(ch in p for ch in "*?"):
            if len(refs["globs"]) < 200:  # bound glob x file matching on hostile docs
                refs["globs"].add(p)
        elif p.endswith("/"):
            refs["dirs"].add(p)
        else:
            refs["files"].add(p)

    for m in PATH_TOKEN_RE.finditer(text):
        classify(m.group(1))
    for m in MD_LINK_RE.finditer(text):
        target = m.group(1).split("#", 1)[0].replace("${CLAUDE_SKILL_DIR}/", "")
        if not target or re.match(r"^[a-zA-Z][\w+.-]*:", target) or target.startswith(("/", "~")):
            continue
        norm = os.path.normpath(target).replace(os.sep, "/")
        if norm == ".." or norm.startswith("../"):
            refs["outside"].add(target)
        else:
            classify(norm + ("/" if target.endswith("/") else ""))
    return refs


def python_imports(src):
    """Return ([(module, line, guarded)], error). ast.parse only; executes nothing."""
    try:
        tree = ast.parse(src)
    except SyntaxError as exc:
        return [], "line {}: {}".format(exc.lineno, exc.msg)
    except Exception as exc:  # ValueError (NUL bytes) on older Pythons, RecursionError, MemoryError
        return [], "{}: {}".format(type(exc).__name__, exc)
    guarded = set()
    for node in ast.walk(tree):
        if isinstance(node, ast.Try):
            for child in node.body:
                for sub in ast.walk(child):
                    guarded.add(id(sub))
    out = []
    for node in ast.walk(tree):
        if isinstance(node, ast.Import):
            for a in node.names:
                out.append((a.name.split(".")[0], node.lineno, id(node) in guarded))
        elif isinstance(node, ast.ImportFrom) and node.level == 0 and node.module:
            out.append((node.module.split(".")[0], node.lineno, id(node) in guarded))
    return out, None


_TOKEN_CACHE = {}


def referenced_by(f, refs, text):
    """True when file path f is named in text (exact path, glob, or basename token)."""
    key = id(text), len(text)
    if key not in _TOKEN_CACHE:  # tokenize each text once, not once per file
        _TOKEN_CACHE.clear()
        _TOKEN_CACHE[key] = set(re.findall(r"[\w.-]+", text))
    tokens = _TOKEN_CACHE[key]
    return (f in refs["files"] or any(C.fnmatch_path(f, g) for g in refs["globs"])
            or os.path.basename(f) in tokens)


# ---------------------------------------------------------------- lint

def lint(target):
    skill_dir, skill_md = C.resolve_target(target)
    findings = []
    _LINT_READ.update(bytes=0, skipped=0)

    def add(fid, sev, msg, file="SKILL.md", line=None):
        findings.append({"id": fid, "severity": sev, "message": msg, "file": file, "line": line})

    def result(fm=None, metrics=None):
        order = {"error": 0, "warn": 1, "info": 2}
        if _LINT_READ["skipped"]:
            add("STRUCT007", "warn", "lint read budget ({} MB) reached; {} file reads were skipped, so reference and "
                "orphan checks are incomplete".format(C.MAX_TOTAL_SCAN // (1024 * 1024), _LINT_READ["skipped"]))
        if any(f["id"] == "FM000" for f in findings):
            # Broken YAML empties the parsed frontmatter; findings that only follow from that are noise.
            for f in findings:
                if f["id"] in ("FM002", "FM008", "FM014", "FM015", "ARG001", "ARG002"):
                    f["severity"] = "info"
                    f["message"] += " (follows from FM000: the YAML did not parse)"
        findings.sort(key=lambda x: (order[x["severity"]], x["id"], x["file"] or "", x["line"] or 0))
        return {"skill_dir": skill_dir, "frontmatter": fm, "metrics": metrics or {}, "findings": findings}

    if os.path.islink(skill_md) or not os.path.isfile(skill_md):
        alt = os.path.join(skill_dir, "skill.md")
        if os.path.islink(skill_md):
            why = "SKILL.md is a symlink; not followed"
        else:
            why = "SKILL.md not found at skill root" + (
                " (found lowercase skill.md; the filename must be SKILL.md)" if os.path.isfile(alt) else "")
        add("STRUCT001", "error", why, None)
        return result()

    raw, raw_truncated = C.read_bytes(skill_md)
    if C.is_binary(raw):
        add("STRUCT002", "error", "SKILL.md is not valid UTF-8 text")
        return result()
    if C.to_text(raw, len(raw) >= C.MAX_READ)[0] == "utf-16":
        add("STRUCT002", "error", "SKILL.md is UTF-16; Claude Code expects UTF-8 (save it as UTF-8)")
        return result()
    if raw_truncated:
        add("STRUCT006", "warn", "SKILL.md is over {} bytes; only its start was linted".format(C.MAX_READ))
    raw_text = C.decode(raw)
    if "\x00" in raw_text:
        add("STRUCT005", "warn", "SKILL.md contains NUL bytes", line=1)
    if raw_text.startswith("\ufeff"):
        add("STRUCT003", "warn", "SKILL.md starts with a UTF-8 BOM; frontmatter may not be detected", line=1)
    if "\r\n" in raw_text:
        add("STRUCT004", "info", "SKILL.md uses CRLF line endings; prefer LF")

    status, fm_text, body, body_start = C.split_frontmatter(raw_text)
    fm, parser = {}, None
    if status == "missing":
        add("FM001", "error", "No YAML frontmatter (file must start with a '---' line)", line=1)
    elif status == "unclosed":
        add("FM026", "error", "Frontmatter opened with '---' but never closed with a second '---' line", line=1)
    else:
        fm, errors, parser = C.parse_frontmatter(fm_text)
        for e in errors:
            if e.startswith("NOTE: "):
                add("FM031", "info", "Frontmatter note: " + e[6:], line=1)
            else:
                add("FM000", "error", "Frontmatter parse problem: " + e +
                    " (Claude Code loads the body with empty metadata when YAML is malformed)", line=bad_yaml_line(fm_text, e))
                status = "parse-error"  # delimiters found, but the YAML inside did not parse
        dup = [k for k, n_ in collections.Counter(re.findall(r"(?m)^([A-Za-z0-9_-]+)\s*:", fm_text)).items() if n_ > 1]
        if dup:
            add("FM033", "warn", "Frontmatter key(s) given twice: {} (YAML parsers keep one, or reject the file; "
                                 "keep one)".format(", ".join(dup[:5])), line=1)
        if parser == "minimal":
            add("FM027", "info", "PyYAML unavailable; the built-in parser checked the frontmatter. It catches common "
                                 "breaks, not all: verify the YAML by hand")

    dir_name = os.path.basename(skill_dir)
    name, desc, when = fm.get("name"), fm.get("description"), fm.get("when_to_use")

    # --- name
    if name is None:
        add("FM002", "info", "No 'name'; Claude Code falls back to the directory name '{}'".format(dir_name))
    else:
        name = str(name)
        if len(name) > 64:
            add("FM003", "error", "name is {} chars; Agent Skills spec max is 64".format(len(name)))
        if not NAME_RE.match(name):
            add("FM004", "warn", "name '{}' is not lowercase letters/digits/single hyphens (Agent Skills spec)".format(
                C.excerpt(name, 80)))
        if re.search("[<>\u00a0]", name) or C.INVISIBLE_RE.search(name) or "  " in name or name != name.strip():
            add("FM005", "error", "name contains characters Claude Code refuses (angle brackets, invisible, NBSP, "
                                  "or extra spaces)")
        if name != dir_name:
            add("FM006", "warn", "name '{}' differs from directory '{}' (Agent Skills spec requires a match)".format(
                C.excerpt(name, 80), C.excerpt(dir_name, 80)))
        if name == "anthropic-skills" or name.startswith("anthropic-skills:") or dir_name == "synced":
            add("FM007", "error", "name or folder uses a reserved value (anthropic-skills, synced)")

    # --- description
    if not desc:
        add("FM008", "error", "No 'description'; Claude cannot decide when to load the skill (falls back to the "
                              "first body line)")
        desc = ""
    else:
        desc = str(desc)
        whole = desc + " " + str(when or "")
        if len(desc) > 1024:
            add("FM009", "error", "description is {} chars; Agent Skills spec max is 1024".format(len(desc)))
        elif len(desc) > 600:
            add("FM028", "info", "description is {} chars; every listed skill shares ~1% of context, so trim text "
                                 "that does not help triggering".format(len(desc)))
        if len(desc) + len(str(when or "")) > 1536:
            add("FM010", "warn", "description + when_to_use exceed 1536 chars; Claude Code truncates the listing")
        if re.search(r"[<>]", whole):
            add("FM011", "warn", "Angle brackets in description/when_to_use display as &lt; &gt;; use [brackets]",
                line=C.frontmatter_line(raw_text, "description"))
        unquoted = re.sub(r"\"[^\"\n]{0,2000}\"|\u201c[^\u201d\n]{0,2000}\u201d", "", desc[:20000])  # quoted phrases are user speech
        if SECOND_PERSON_RE.search(unquoted):
            add("FM012", "warn", "description uses second person; write it in third person")
        if FIRST_PERSON_RE.search(strip_inline_code(unquoted)):
            add("FM013", "warn", "description uses first person ('I', 'my'); write it in third person")
        if not re.search(r"\b(when|whenever|if the user|use (it )?for|trigger)", whole.lower()):
            add("FM014", "warn", "description has no 'when to use' clause; triggering will rely on topic words only")
        if len(desc) < 80:
            add("FM015", "warn", "description is only {} chars; likely too vague to trigger reliably".format(len(desc)))
        if C.INVISIBLE_RE.search(whole):
            add("FM029", "error", "description contains invisible characters: " + C.excerpt(whole, 100))

    # --- other fields
    for key in fm:
        if key in TOLERATED_FIELDS:
            add("FM016", "info", "Field '{}' is not documented by Claude Code or the spec; it is ignored".format(key),
                line=C.frontmatter_line(raw_text, str(key)))
        elif key not in KNOWN_FIELDS:
            add("FM017", "warn", "Unknown frontmatter field '{}' (ignored; check for a typo)".format(
                C.excerpt(str(key), 80)), line=C.frontmatter_line(raw_text, str(key)))
    if fm.get("effort") and str(fm["effort"]) not in EFFORT_VALUES:
        add("FM018", "error", "effort '{}' not one of {}".format(C.excerpt(str(fm["effort"]), 60), sorted(EFFORT_VALUES)))
    if fm.get("context") and str(fm["context"]) != "fork":
        add("FM019", "warn", "context '{}' is not 'fork' (the only documented value)".format(C.excerpt(str(fm["context"]), 60)))
    if fm.get("agent") and fm.get("context") != "fork":
        add("FM020", "warn", "'agent' has no effect without 'context: fork'")
    if "background" in fm and fm.get("context") != "fork":
        add("FM021", "warn", "'background' has no effect without 'context: fork'")
    if fm.get("disable-model-invocation") is True and fm.get("user-invocable") is False:
        add("FM022", "error", "disable-model-invocation: true AND user-invocable: false; nothing can invoke this skill")
    if fm.get("disable-model-invocation") is True and desc:
        add("FM023", "info", "Model invocation disabled; the description only serves humans in the / menu")
    tools_src = fm if fm or status not in ("ok", "parse-error") else C.parse_yaml_minimal(fm_text[:C.MAX_FRONTMATTER])[0]  # audit intent of broken YAML
    for tool, sev, reason in C.risky_tools(C.parse_tools(tools_src.get("allowed-tools"))):
        add("FM024", "info" if sev == "low" else "warn", "allowed-tools '{}' {}".format(C.excerpt(tool, 120), reason),
            line=C.frontmatter_line(raw_text, "allowed-tools"))
    bash_tools = [t for t in C.parse_tools(tools_src.get("allowed-tools")) if re.match(r"^Bash\(\s*[\w.-]+", t)]
    all_docs = body
    if bash_tools:  # the skill's own Markdown, so a command used only in a reference still counts (not docstrings)
        for e3 in C.walk(skill_dir)[:500]:
            if e3["kind"] == "file" and e3["path"] != "SKILL.md" and not C.in_skipped_dir(e3["path"]) \
                    and not C.is_credential_path(e3["path"]) and e3["path"].endswith((".md", ".markdown", ".txt")):
                all_docs += "\n" + (read_text(os.path.join(skill_dir, e3["path"])) or "")[:200000]
    doc_words = set(re.findall(r"(?<![\w.-])[\w.-]+", all_docs)) if bash_tools else set()  # one pass, then lookups
    doc_words |= {w.split(".", 1)[0] for w in doc_words} | {w.rstrip(".") for w in doc_words}  # "foo.py", "foo."
    seen_cmds = set()
    for tool in bash_tools:
        mt = re.match(r"^Bash\(\s*([\w.-]+)", tool)  # Bash(python:*) whose command nothing in the skill mentions
        harmless = {"mkdir", "ls", "wc", "cat", "head", "tail", "grep", "find", "echo", "pwd", "sort", "uniq", "diff",
                    "file", "stat", "test", "true", "date"}
        if not mt or mt.group(1) in seen_cmds:
            continue
        seen_cmds.add(mt.group(1))
        if mt.group(1) not in harmless and mt.group(1) not in doc_words:
            add("FM032", "info", "allowed-tools '{}' pre-approves '{}', which no file in the skill uses; drop it".format(
                C.excerpt(tool, 80), mt.group(1)),
                line=C.frontmatter_line(raw_text, "allowed-tools"))
    ph_uses = collections.Counter(re.findall(r"(?<![\w])<([a-z][a-z0-9_-]{2,30})>", body))  # one pass over the body
    ph_defined = set(re.findall(r"<([a-z][a-z0-9_-]{2,30})>`?\s*(?:\)|is\b|=|:|means\b|-\s|\(the\b|stands for)", body)) | \
        set(re.findall(r"(?i)\b(?:call|called|named|as)\s+`?<([a-z][a-z0-9_-]{2,30})>", body))
    for ph, uses in sorted(ph_uses.items())[:500]:
        if uses >= 3 and ph not in ph_defined:
            add("BODY012", "info", "placeholder <{}> is used {} times but never defined; say what it stands for".format(
                ph, uses))
    hooks = tools_src.get("hooks")
    if hooks:
        cmds = C.hook_commands(hooks)
        add("FM030", "warn", "hooks registers {} command(s) that run on invocation and stay active for the "
            "session: {}".format(len(cmds), "; ".join(C.excerpt(c, 60) for c in cmds[:5]) or "(none parsed; read "
                                 "the hooks block by hand)"))
    if fm.get("allowed-tools") is not None:
        add("FM025", "info", "allowed-tools only pre-approves tools for the invoking turn; it does not restrict "
                             "others (use disallowed-tools to restrict)", line=C.frontmatter_line(raw_text, "allowed-tools"))

    # --- body
    body_lines_list = body.split("\n")
    body_words, body_lines = len(body.split()), len(body_lines_list)
    if body_words > WORDS_ERROR:
        add("BODY001", "error", "Body is {} words (> {} words, ~5,000 tokens: the spec's recommended maximum)".format(
            body_words, WORDS_ERROR))
    elif body_words > WORDS_WARN:
        add("BODY002", "warn", "Body is {} words (> {}); move detail into references/".format(body_words, WORDS_WARN))
    norm_text = C.normalize_newlines(raw_text)
    file_lines = norm_text.count("\n") + (0 if norm_text.endswith("\n") else 1)
    if file_lines > LINES_WARN:
        add("BODY003", "warn", "SKILL.md is {} lines; docs recommend under {}".format(file_lines, LINES_WARN))
    if not body.strip():
        add("BODY004", "error", "SKILL.md has no body instructions")
    flags, unclosed = fenced_flags(body_lines_list)
    if unclosed:
        add("BODY005", "error", "Unclosed code fence in SKILL.md body; the rest of the file renders as code")

    second_hits = []
    shipped_names = {os.path.basename(e["path"]) for e in C.walk(skill_dir)[:2000] if e["kind"] == "file"}
    for idx, line in enumerate(body_lines_list):
        ln, in_code = body_start + idx, flags[idx]
        clean = re.sub(r"\"[^\"]{0,2000}\"|\u201c[^\u201d]{0,2000}\u201d", "", strip_inline_code(line[:20000]))  # quoted text is not voice
        # Code and prose alike
        bare_call = not in_code and any(re.match(r"[\w-]+\.(?:m?js|py|sh)\s+\S", sp) and sp.split()[0] in shipped_names
                                         for sp in re.findall(r"`([^`]{1,300})`", line))
        if RELATIVE_SCRIPT_RE.search(line[:20000]) or (in_code and BARE_SCRIPT_RE.search(line)) or bare_call:
            add("BODY010", "warn", "Bundled file invoked by relative path; it breaks when the working directory is "
                "not the skill folder. Use ${CLAUDE_SKILL_DIR}/... (or the folder the skill copies its scripts to, "
                "if it runs them from there): " + C.excerpt(line, 90), line=ln)
        code_bits = [line] if in_code else [sp for sp in re.findall(r"`([^`]+)`", line) if " " in sp.strip()]
        if any(DOLLAR_ARG_RE.search(b) for b in code_bits):
            add("BODY011", "warn", "'$0'-'$9' inside a command: Claude Code substitutes it with a skill argument at "
                "load time (shell or awk '$0', '$1' break). Escape it as '\\$0': " + C.excerpt(line, 90), line=ln)
        if WINDOWS_PATH_RE.search(line):
            add("BODY007", "warn", "Backslash path; use forward slashes for portability", line=ln)
        if DYNAMIC_RE.search(line) or line.strip().startswith("```!"):
            add("BODY008", "warn", "Dynamic context injection (!`cmd`) runs a shell command before the skill loads: "
                + C.excerpt(line, 90), line=ln)
        if in_code:
            continue
        # Prose only
        if SECOND_PERSON_RE.search(clean):
            second_hits.append(ln)
        if PLACEHOLDER_RE.search(clean):
            add("BODY006", "warn", "Placeholder marker left in text: " + C.excerpt(line, 90), line=ln)
        if SAMPLING_RE.search(clean):
            add("BODY009", "warn", "Sampling setting in instructions; a skill cannot change temperature/top_p, so "
                "this line is not actionable: " + C.excerpt(line, 90), line=ln)
    if second_hits:
        add("STYLE001", "info", "{} prose lines use second person (lines {}{}). Imperative form is the plugin-dev "
            "convention; a deliberate 'You are ...' role line may be fine.".format(
                len(second_hits), ", ".join(map(str, second_hits[:15])), ", ..." if len(second_hits) > 15 else ""))

    # --- arguments
    named = fm.get("arguments") if isinstance(fm.get("arguments"), list) else []
    uses_args = bool(ARG_USE_RE.search(body)) or any(re.search(r"\$" + re.escape(str(a)) + r"\b", body) for a in named)
    if fm.get("argument-hint") and not uses_args:
        add("ARG001", "info", "argument-hint set but body never uses $ARGUMENTS/$N; args are appended as "
                              "'ARGUMENTS: <value>' instead")
    if uses_args and not fm.get("argument-hint"):
        add("ARG002", "info", "Body uses $ARGUMENTS or $0-$9 (a $N inside shell code counts: see BODY011) but "
                              "there is no argument-hint for autocomplete")

    # --- duplication
    seen, first = {}, {}
    for norm, orig in sentences(body):
        seen[norm] = seen.get(norm, 0) + 1
        first.setdefault(norm, orig)
    for s in [s for s, n in seen.items() if n > 1][:10]:
        add("DUP001", "info", "Sentence repeated {}x: \"{}\"".format(seen[s], C.excerpt(first[s], 70)))

    # --- references and orphans
    entries = C.walk(skill_dir)
    files = [e["path"] for e in entries if e["kind"] in ("file", "symlink", "special", "unreadable")]
    refs = collect_refs(body)

    real_skill = os.path.realpath(skill_dir)

    def exists(p):
        # Check the filesystem directly so vendored dirs and links count, without following outside.
        full = os.path.normpath(os.path.join(skill_dir, p.rstrip("/")))
        return C.inside(os.path.dirname(full), real_skill) and os.path.lexists(full)

    placeholder = re.compile(r"(^|/)(FILE|NAME|PATH|FOO|BAR|EXAMPLE|X|YOUR[-_]?\w*|<[^>]+>|\{[^}]+\})(\.\w+)?$")
    for ref in sorted(refs["files"] | refs["dirs"]):
        if placeholder.search(ref.rstrip("/")):
            continue  # a placeholder in an example, e.g. references/FILE.md
        if not exists(ref):
            if ref.endswith("/"):
                add("REF001", "info", "SKILL.md mentions folder '{}', which the skill does not ship (it may mean the "
                                      "user's project)".format(C.excerpt(ref, 200)))
            else:
                add("REF001", "error", "SKILL.md references '{}' but it does not exist".format(C.excerpt(ref, 200)))
    for g in sorted(refs["globs"]):
        if not any(C.fnmatch_path(f, g) for f in files):
            add("REF001", "warn", "SKILL.md glob '{}' matches no file".format(C.excerpt(g, 200)))
    # Bare file names listed on a line about a skill folder ("`scripts/`: `a.mjs`, `package-lock.json`").
    basenames = {os.path.basename(f) for f in files}
    for idx, line in enumerate(body_lines_list):
        if flags[idx] or not re.match(r"^\s*[-*]\s+\**`(?:\$\{CLAUDE_SKILL_DIR\}/)?(scripts|references|assets|examples)/`\**\s*[:-]", line):
            continue
        for tok in re.findall(r"`([A-Za-z0-9_.-]+\.[A-Za-z0-9]{1,8})`", line):
            if tok not in basenames and not placeholder.search(tok):
                add("REF008", "warn", "'{}' is listed with a skill folder but no such file ships".format(
                    C.excerpt(tok, 200)), line=body_start + idx)
    for e in entries:  # ${CLAUDE_SKILL_DIR} is substituted in the SKILL.md body only
        p = e["path"]
        if e["kind"] != "file" or p == "SKILL.md" or not p.endswith((".md", ".markdown", ".txt")) or C.in_skipped_dir(p) \
                or C.is_credential_path(p):  # credential files are read by the secret scan only
            continue
        t = read_text(os.path.join(skill_dir, p)) or ""
        hit = next((n for n, ln in enumerate(t.split("\n"), 1) if "${CLAUDE_SKILL_DIR}" in ln), None)
        if hit and re.search(r"\$\{CLAUDE_SKILL_DIR\}", body):
            hit = None  # SKILL.md uses it too, so Claude sees the substituted path and can resolve it in references
        if hit:
            add("REF009", "info", "'{}' uses ${{CLAUDE_SKILL_DIR}}, which is substituted only in SKILL.md; a command "
                                  "copied from here gets the literal text or an unset variable unless SKILL.md says "
                                  "what to replace it with".format(C.safe_name(p)), file=p, line=hit)
    for o in sorted(refs["outside"]):
        add("REF004", "info", "SKILL.md links outside the skill folder: '{}' (not shipped with the skill)".format(
            C.excerpt(o, 200)))

    plugin = C.plugin_context(skill_dir, entries)
    if plugin:
        if not plugin["root"] and plugin.get("refused"):
            add("REF005", "warn", "The plugin root was refused and not read ({}): its files were not checked".format(
                C.excerpt(plugin["refused"], 160)))
        elif not plugin["root"]:
            add("REF005", "warn", "Uses ${CLAUDE_PLUGIN_ROOT} but the skill is not inside a plugin "
                "(<root>/skills/<name>/ with .claude-plugin/plugin.json); these paths cannot be resolved")
        for m in plugin["missing"]:
            add("REF005", "warn", "${{CLAUDE_PLUGIN_ROOT}}/{} does not exist in the plugin (a real dependency is "
                "broken; an example in documentation is fine)".format(C.safe_name(m)))
        deps = [f for f in plugin["files"] if not f["reason"].startswith("plugin context")]
        if deps:
            add("REF006", "info", "Depends on {} plugin-level file(s) outside the skill folder: {}".format(
                len(deps), ", ".join(C.safe_name(f["path"]) for f in deps[:8]) + (" ..." if len(deps) > 8 else "")))
        if plugin["hook_commands"]:
            add("REF007", "info", "The enclosing plugin registers {} hook command(s); they run whenever the plugin "
                "is enabled, not only when this skill is used".format(len(plugin["hook_commands"])))

    def mentioned(f, r, tokens):
        # A bare directory mention ("see scripts/") does not tell Claude a file exists; handled below.
        return (f in r["files"] or any(C.fnmatch_path(f, g) for g in r["globs"])
                or os.path.basename(f) in tokens)

    kinds = {e["path"]: e["kind"] for e in entries}

    body_tokens = set(re.findall(r"[\w.-]+", body))
    resource = [f for f in files if "/" in f]
    reachable_via = {}
    docs_checked = 0
    for f in resource:
        if f.endswith((".md", ".txt")) and kinds.get(f) == "file" and not C.is_credential_path(f) \
                and mentioned(f, refs, body_tokens):
            docs_checked += 1
            if docs_checked > 300 or len(resource) > 3000:  # bound the doc x resource work on huge trees
                break
            t = read_text(os.path.join(skill_dir, f)) or ""
            r2, toks = collect_refs(t), set(re.findall(r"[\w.-]+", t))
            for g in resource:
                if g != f and mentioned(g, r2, toks):
                    reachable_via.setdefault(g, f)
    for f in resource:
        if mentioned(f, refs, body_tokens):
            continue
        if f in reachable_via:
            if f.startswith("references/"):
                add("REF002", "info", "'{}' is only reachable via '{}'; keep references one level deep from "
                                      "SKILL.md".format(f, reachable_via[f]), file=f)
            continue
        if os.path.basename(f).startswith(".") or "/tests/" in "/" + f or "/test/" in "/" + f:
            add("REF003", "info", "'{}' is never named (test or dotfile; fine if it is not meant for Claude)".format(
                C.escape_invisible(f)), file=f)
        elif any(f.startswith(d) for d in refs["dirs"]):
            add("REF003", "info", "'{}' is never named; SKILL.md only mentions its directory".format(
                C.escape_invisible(f)), file=f)
        else:
            add("REF003", "warn", "Orphan file: '{}' is never referenced, so Claude will not know it exists".format(
                C.escape_invisible(f)), file=f)
    for f in files:
        if "/" not in f and f != "SKILL.md" and not META_FILES.match(f) and f not in body_tokens:
            add("REF003", "info", "Root file '{}' is never referenced from SKILL.md".format(C.escape_invisible(f)), file=f)

    # --- scripts
    imported_names = set()  # modules other code files import: libraries, not entry points
    for e2 in entries:
        if e2["kind"] == "file" and C.is_code(e2["path"]):
            t2 = read_text(os.path.join(skill_dir, e2["path"])) or ""
            imported_names |= set(re.findall(r"\b(?:from|import\(?|require\()\s{0,5}['\"]?\.{0,2}/?(?:[\w.-]{0,100}/){0,5}([\w-]{1,100})(?:\.m?js|\.py)?['\"]?", t2[:500000]))
    py_local = {os.path.splitext(os.path.basename(f))[0] for f in files if f.endswith(".py")}
    py_local |= {f.split("/")[-2] for f in files if f.endswith("/__init__.py")}
    stdlib = getattr(sys, "stdlib_module_names", None)
    interp_cache = []

    def interp_text():
        """Text after each interpreter word in the body ("python3 scripts/x.py"), built once on first use."""
        if not interp_cache:
            interp_cache.append("\n".join(m.group(1) for m in itertools.islice(re.finditer(
                r"\b(?:node|python3?|bash|sh|deno|bun|ruby|perl|php)\s+(?=([^\n]{0,80}))", body), 20000)))
        return interp_cache[0]
    for e in entries:
        f = e["path"]
        if e["kind"] != "file" or not C.is_code(f) or C.is_credential_path(f):  # credential files are never read
            continue
        full = os.path.join(skill_dir, f)
        if _LINT_READ["bytes"] > C.MAX_TOTAL_SCAN:  # code files share the lint run's byte budget
            _LINT_READ["skipped"] += 1
            continue
        try:
            raw_code, _ = C.read_bytes(full, C.MAX_READ_CODE)
            _LINT_READ["bytes"] += len(raw_code)
        except OSError as exc:
            add("SCR008", "warn", "Code file '{}' is unreadable ({}); it was not reviewed".format(
                C.safe_name(f), exc.strerror or exc), file=f)
            continue
        if C.is_binary(raw_code):
            add("SCR001", "warn", "Binary content in code file '{}' (NUL bytes or invalid UTF-8); it cannot be "
                                  "reviewed as text".format(C.safe_name(f)), file=f)
            continue
        t = C.normalize_newlines(C.decode(raw_code))
        browser_js = f.endswith((".js", ".mjs")) and re.search(r"\b(document|window)\.", t) and \
            not re.search(r"require\(|from\s+['\"]node:|process\.(argv|env|exit)", t)
        if f.endswith((".py", ".sh", ".bash", ".js", ".mjs", ".rb", ".pl")) and not t.startswith("#!") \
                and not os.path.basename(f).startswith("_") and not browser_js \
                and os.path.splitext(os.path.basename(f))[0] not in imported_names:
            add("SCR002", "info", "No shebang in '{}'; SKILL.md must state the interpreter".format(f), file=f)
        if t.startswith("#!") and not os.access(full, os.X_OK) and os.path.basename(f) not in interp_text():
            add("SCR003", "info", "'{}' has a shebang but is not executable".format(f), file=f)
        if f.endswith(".py"):
            imports, err = python_imports(t)
            if err:
                add("SCR007", "warn", "'{}' does not parse as Python 3 ({}){}".format(
                    f, err, "" if sys.version_info >= (3, 12) else "; the checker runs Python {}.{}, so newer "
                    "syntax (match, type) can cause this - verify by reading".format(*sys.version_info[:2])), file=f)
            elif stdlib is None:
                add("SCR006", "info", "Third-party import check skipped: needs Python 3.10+", file=f)
            else:
                reported = set()
                for mod, ln, guarded in imports:
                    if mod in stdlib or mod in py_local or mod == "__future__" or mod in reported:
                        continue
                    reported.add(mod)
                    add("SCR004", "info" if guarded else "warn",
                        "'{}' imports third-party module '{}'{}".format(
                            f, mod, " (guarded by try/except)" if guarded else "; document the install step"),
                        file=f, line=ln)
        if not os.path.basename(f).startswith("_") and not re.search(r"--help|argparse|usage", t, re.I) \
                and os.path.splitext(os.path.basename(f))[0] not in imported_names and not browser_js:
            add("SCR005", "info", "'{}' has no usage text or --help".format(f), file=f)

    sections, cur = [], None
    for idx, line in enumerate(body_lines_list):
        mh = re.match(r"^(#{1,6})\s+(.+?)\s*$", line)
        if mh and not flags[idx]:
            cur = {"heading": C.excerpt(mh.group(2), 80), "line": body_start + idx, "words": 0}
            sections.append(cur)
        elif cur is not None:
            cur["words"] += len(line.split())
    metrics = {
        "parser": parser,
        "frontmatter_status": status,
        "name": C.excerpt(str(name), 120) if name is not None else None,
        "directory": dir_name,
        "description_chars": len(desc) or (len(str(C.parse_yaml_minimal(fm_text[:C.MAX_FRONTMATTER])[0].get("description") or ""))
                                           if status in ("ok", "parse-error") and fm_text else 0),
        "when_to_use_chars": len(str(when or "")),
        "quoted_trigger_phrases": len(re.findall(r"\"[^\"]{3,}\"", desc + " " + str(when or ""))),
        "body_words": body_words,
        "body_words_target": WORDS_TARGET,
        "body_lines": body_lines,
        "file_lines": file_lines,
        "second_person_lines": len(second_hits),
        "sections": sections[:80],
        "references_in_skill_md": [C.excerpt(r, 200) for r in sorted(refs["files"] | refs["dirs"] | refs["globs"])][:300],
        "files": len(files),
    }
    return result(C.scrub(fm), metrics)


def to_markdown(res, level=2):
    out = [C.heading(level, "Lint"), ""]
    m = res["metrics"]
    if m:
        out += ["| Metric | Value |", "|---|---|"]
        for k, v in m.items():
            if k == "sections" and isinstance(v, list):  # headings as "Title (line N, W words)", not raw dicts
                v = "; ".join("{} (line {}, {} words)".format(x.get("heading"), x.get("line"), x.get("words"))
                              if isinstance(x, dict) else str(x) for x in v) or "-"
            elif isinstance(v, list):
                v = ", ".join(str(x) for x in v) or "-"
            out.append("| {} | {} |".format(k, C.md_cell(str(v))))
        out.append("")
    if not res["findings"]:
        out.append("No findings.")
    else:
        out += ["| Sev | ID | Location | Message |", "|---|---|---|---|"]
        for f in res["findings"]:
            loc = C.safe_name(f["file"] or "-") + (":{}".format(f["line"]) if f["line"] else "")
            msg = C.md_cell(f["message"])
            out.append("| {} | {} | `{}` | {} |".format(f["severity"], f["id"], loc, msg))
    return "\n".join(out)


def main():
    C.safe_stdout()
    ap = argparse.ArgumentParser(description=__doc__.split("\n", 1)[0])
    ap.add_argument("target", help="skill directory or SKILL.md path")
    ap.add_argument("--format", choices=["md", "json"], default="md")
    ap.add_argument("--heading-level", type=int, default=2)
    args = ap.parse_args()
    if not os.path.exists(args.target):
        print("error: path not found: " + args.target, file=sys.stderr)
        return 2
    res = lint(args.target)
    print(json.dumps(res, indent=2, default=str) if args.format == "json" else to_markdown(res, args.heading_level))
    return 0


if __name__ == "__main__":
    sys.exit(main())
