#!/usr/bin/env python3
"""Collect what a skill needs to run: runtimes, packages, external programs,
network domains, Claude tool capabilities, and companion skills.

Static and read-only: Python is inspected with ast.parse, everything else with
patterns. Nothing in the target is executed. Plugin-level files the skill uses
are included as "<plugin>/path". Every item carries file:line evidence and a
confidence label: "verified" (stated or used in a file) or "inferred" (follows
from a signal, e.g. a match statement implies Python 3.10+).

Usage:
    python3 -I -B scan_requirements.py [--format md|json] [--heading-level N] -- <skill_dir | SKILL.md>

json: {"skill_dir", "declared": {...}, "runtime": [...], "packages": [...],
       "binaries": [...], "network": [...], "docs_links": n, "tools": [...],
       "companions": [...], "findings": [...]}
Each list item: item, confidence, hits, sources (first 3 file:line), detail.
Findings: id, severity (warn|info), message. Leads only: read the cited lines.
"""
import argparse
import ast
import json
import os
import itertools
import re
import sys
from collections import OrderedDict

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))  # this skill's scripts/ only
import _common as C  # noqa: E402
from lint_skill import python_imports  # noqa: E402

BINARIES = ["git", "gh", "curl", "wget", "ffmpeg", "ffprobe", "yt-dlp", "youtube-dl", "pandoc", "chromium",
            "google-chrome", "playwright", "puppeteer", "libreoffice", "soffice", "tesseract", "magick",
            "convert", "npx", "npm", "pnpm", "yarn", "bun", "deno", "uv", "uvx", "pip", "pip3", "pipx", "docker",
            "rsync", "jq", "yq", "sqlite3", "psql", "mysql", "cairosvg", "inkscape", "rg", "fd", "make", "cmake",
            "cargo", "go", "java", "node", "ruby", "perl", "php", "aws", "gcloud", "az", "kubectl", "terraform",
            "pdftotext", "qpdf", "ghostscript", "gs", "exiftool", "imagemagick", "wkhtmltopdf", "zip", "unzip",
            "awk", "sed", "find", "sort", "comm", "df", "touch", "chmod", "xargs", "tar", "gzip", "diff", "patch",
            "grep", "mv", "cp", "cmp", "python3", "composer", "bundle", "gem", "dotnet"]
CORE_TOOLS = {"sed", "grep", "sort", "find", "awk", "df", "comm", "touch", "chmod", "cp", "mv", "cmp", "diff", "xargs",
              "patch"}  # POSIX tools (compatibility.md); tar, gzip, zip, unzip are not POSIX and are listed
BIN_RE = re.compile(r"(?:^|[\s`(|&;$\"'\[,])(" + "|".join(re.escape(b) for b in BINARIES) + r")(?=[\s`)|&;\"',\]]|$)")
INSTALL_RE = re.compile(
    r"\b(pip3?\s+install|uv\s+pip\s+install|uv\s+sync|pipx\s+install|poetry\s+install|npm\s+(?:i|install|ci)|"
    r"pnpm\s+(?:add|install)|yarn\s+(?:add|install)|npx\s+-y|apt(?:-get)?\s+install|brew\s+install|"
    r"cargo\s+(?:install|fetch)|go\s+(?:install|mod\s+download)|gem\s+install|bundle\s+install|"
    r"composer\s+(?:install|require)|playwright\s+install|conda\s+install|dotnet\s+(?:restore|add\s+package)|"
    r"nuget\s+install)\b([^\n`|&;,]{0,100})")
# Default registries for install commands that name no domain (labelled inferred).
REGISTRY_FOR = [(r"^(pip|uv|pipx|poetry)", "pypi.org"), (r"^(npm|pnpm|yarn|npx)", "registry.npmjs.org"),
                (r"^cargo", "crates.io"), (r"^go\b", "proxy.golang.org"), (r"^(gem|bundle)", "rubygems.org"),
                (r"^composer", "packagist.org"), (r"^brew", "formulae.brew.sh"), (r"^playwright", "playwright.azureedge.net"),
                (r"^conda", "conda.anaconda.org"), (r"^(dotnet|nuget)", "api.nuget.org"),
                (r"^apt", "the distribution's package mirrors")]
DOMAIN_RE = re.compile(r"https?://([A-Za-z0-9.-]+\.[A-Za-z]{2,})(?::\d+)?")
REGISTRIES = ("pypi.org", "files.pythonhosted.org", "registry.npmjs.org", "npmjs.com", "registry.yarnpkg.com",
              "github.com", "raw.githubusercontent.com", "objects.githubusercontent.com", "crates.io",
              "rubygems.org", "proxy.golang.org", "deb.debian.org", "archive.ubuntu.com")
PY_FLOOR_IMPORTS = {"tomllib": ("3.11", "tomllib import"), "graphlib": ("3.9", "graphlib import"),
                    "zoneinfo": ("3.9", "zoneinfo import")}
PY_FLOOR_ATTRS = {"removeprefix": ("3.9", "str.removeprefix"), "removesuffix": ("3.9", "str.removesuffix"),
                  "stdlib_module_names": ("3.10", "sys.stdlib_module_names"), "TaskGroup": ("3.11", "asyncio.TaskGroup")}
PY_FLOOR_NAMES = {"ExceptionGroup": ("3.11", "ExceptionGroup")}
PHP_FLOOR_PATTERNS = [
    (r"\bmatch\s*\(", "8.0", "match expression"),
    (r"\?->", "8.0", "nullsafe operator"),
    (r"\b(str_contains|str_starts_with|str_ends_with)\s*\(", "8.0", "str_contains/starts_with"),
    (r"^\s*enum\s+\w+", "8.1", "enum"),
    (r"\breadonly\s+(public|private|protected|class)\b", "8.1", "readonly property"),
    (r"\bfn\s*\(", "7.4", "arrow function"),
]
NODE_BUILTINS = {"fs", "path", "os", "child_process", "http", "https", "url", "util", "crypto", "stream", "events",
                 "zlib", "net", "tls", "dns", "readline", "process", "buffer", "assert", "worker_threads", "module"}
SHELL_LANGS = {"bash", "sh", "shell", "zsh", "console", "shell-session", "powershell", "ps1", "cmd"}
NET_CALL_RE = re.compile(r"\b(curl|wget|fetch\(|requests\.|httpx\.|urlopen|urllib|http\.client|axios|Invoke-WebRequest|"
                         r"iwr|git\s+clone|aiohttp|WebFetch|web_fetch)\b", re.I)
NODE_FLOOR_PATTERNS = [
    (r"(?<![\w.])fetch\s*\(", "18", "global fetch"),
    (r"from\s+['\"]node:|require\(\s*['\"]node:", "16", "node: prefixed import"),
    (r"\bstructuredClone\s*\(", "17", "structuredClone"),
    (r"\bcpSync\s*\(|\bfs(?:\.promises)?\.cp\s*\(", "16.7", "fs.cp / cpSync"),
]
# Claude capabilities the instructions rely on. Patterns run on SKILL.md (the instructions) only.
TOOL_SIGNALS = OrderedDict([
    ("shell", [r"```(?:bash|sh|shell|zsh)\b", r"\bBash`? tool\b", r"\brun (?:this|the following) command"]),
    ("file read", [r"\bRead`? tool\b", r"\b(?:with|use|using|via) (?:the )?`?Read\b"]),
    ("file write", [r"\b(?:Write|Edit)`? tool\b", r"\b(?:edit|modif|updat|rewrit|chang|fix)\w* (?:[\w'-]+ ){0,4}in[- ]place\b(?! of)",
                    r"\bedits? (?:every|each|all|the) (?:source )?files?\b", r"\b(?:with|use|using|via) (?:the )?`?(?:Write|Edit)\b",
                    r"\bedits? (?:the )?(?:project |source |repo(?:sitory)? |user's )?(?:files?|code) in place\b",
                    r"\b(?:writes?|saves?) (?:it|the (?:result|output|file|report)) (?:to|as|next to)\b", r"\bcreate_file\b", r"\bstr_replace\b", r"\bsave (?:it |the \w+ )?(?:to|as) (?:a )?(?:file|`)"]),
    ("file delivery", [r"\bpresent_files\b", r"\bSendUserFile\b", r"/mnt/user-data/outputs", r"\bdeliver the file\b"]),
    ("image viewing (vision)", [r"\blook at the (?:render|screenshot|image|output|page)\b", r"\bview the (?:render|screenshot|image)\b",
                                r"\bvisually (?:check|compare|inspect|verify)\b", r"\bcontact sheet\b", r"\btake a screenshot\b",
                                r"\brender[- ]and[- ]look\b", r"\bscreenshot\b"]),
    ("web access", [r"\bWebFetch\b", r"\bWebSearch\b", r"\bweb_search\b", r"\bweb_fetch\b", r"\bsearch the web\b", r"\bfetch the (?:url|page)\b"]),
    ("subagents", [r"\bAgent`? tool\b", r"\bTask`? tool\b", r"\bsubagents?\b", r"\bspawn (?:an? )?agents?\b", r"\bin parallel\b",
                   r"\blaunch (?:one|an?|\w+) [\w-]{0,30} ?agents?\b", r"\bgeneral-purpose agents?\b"]),
    ("MCP connector", [r"\bmcp__[\w-]+", r"\bClaude in Chrome\b", r"\bclaude-in-chrome\b", r"\bMCP server\b", r"\bconnector\b"]),
    ("artifacts", [r"\bArtifact tool\b", r"\bpublish (?:an? )?artifact\b", r"\bHTML artifact\b"]),
    ("memory", [r"\bmemory_(?:read|write)\b", r"\bpersistent memory\b"]),
    ("user uploads", [r"/mnt/user-data/uploads", r"\buploaded files?\b"]),
    ("asking the user mid-task", [r"\bAskUserQuestion\b", r"\bwait for (the |the user's |their )?(reply|replies|answer)\b",
                                  r"\bask(?:s|ing)?\b[^.\n]{0,40}\bquestions?\b", r"\buntil the user repl(?:y|ies)\b",
                                  r"\bask the user\b", r"\bstop and ask\b",
                                  r"\bconfirm with the user\b", r"\bintake\b", r"\bask (?:them|which|whether)\b"]),
    ("display / headed browser", [r"\bheaded\b", r"\bheadless\s*=\s*False\b", r"\bopen the browser\b", r"\bDISPLAY=\b"]),
])
CLAUSE_SPLIT_RE = re.compile(r"(?<=[.!?;])\s+|\s+(?:--|\u2014)\s+|,\s+(?=(?:but|and then|then|unless|or)\b)")
NEGATION_RE = re.compile(r"(?i)\b(?:don'?t|do not|never|without|no need to)\b")
TOOL_COMPILED = [(k, [re.compile(p, re.I if k != "shell" else 0) for p in v]) for k, v in TOOL_SIGNALS.items()]
SKILL_NAME_RE = re.compile(r"`([a-z][a-z0-9]*(?:[-:][a-z0-9]+){0,6})`")  # matched only against real skill names
ROUTING_RE = re.compile(r"\b(?:use|see|run|invoke|hand(?:s)? off to|feeds?|consumes?(?: output of)?)\s+(?:the\s+)?`?([a-z][a-z0-9]*(?:[-:][a-z0-9]+){0,6})`?\s+skill\b|\b(?:use|hand(?:s)? off to|feeds?)\s+`([a-z][a-z0-9]*(?:[-:][a-z0-9]+){0,6})`", re.I)



_KEY_LINES = {}  # id(lines) -> {key: first line}, built once per manifest


def key_line(lines, key):
    """1-based line of a JSON key in a manifest (the first '"key":' match), or 1. One pass per manifest."""
    m = _KEY_LINES.get(id(lines))
    if m is None or m[0] is not lines:
        found = {}
        for n, ln in enumerate(lines, 1):
            if '":' not in ln and '" :' not in ln:
                continue
            for k in re.findall(r'"([^"\\\n]{1,200})"\s*:', ln[:20000]):  # one step per character
                found.setdefault(k, n)
        _KEY_LINES.clear()
        m = _KEY_LINES[id(lines)] = (lines, found)
    return m[1].get(str(key), 1)

class Collector:
    def __init__(self):
        self.axes = {k: OrderedDict() for k in ("runtime", "packages", "binaries", "network", "tools", "companions")}
        self.docs_links = 0

    def add(self, axis, item, src, confidence, detail=""):
        item = C.excerpt(item, 120)  # redacts before shortening
        e = self.axes[axis].get(item)
        if e is None:  # build the detail excerpt once per item, not once per hit
            e = self.axes[axis][item] = {"item": item, "confidence": confidence, "hits": 0, "sources": [],
                                         "detail": C.excerpt(detail, 120)}
        e["hits"] += 1
        if confidence == "verified":
            e["confidence"] = "verified"
        if len(e["sources"]) < 3 and src not in e["sources"]:
            e["sources"].append(src)

    def result(self):
        out = {}
        for axis, items in self.axes.items():
            if axis == "tools" and any(k.startswith("MCP connector: ") for k in items):
                items = OrderedDict((k, v) for k, v in items.items() if k != "MCP connector")  # named beats generic
            out[axis] = sorted(items.values(), key=lambda e: (e["confidence"] != "verified", -e["hits"], e["item"]))[:40]
        return out


def py_floors(src):
    """Return [(floor, reason, line)] from Python syntax. ast only; executes nothing."""
    out = []
    try:
        tree = ast.parse(src)
    except Exception:
        return out
    for node in ast.walk(tree):
        name = type(node).__name__
        if isinstance(node, ast.Import):
            for a in node.names:
                if a.name.split(".")[0] in PY_FLOOR_IMPORTS:
                    f, why = PY_FLOOR_IMPORTS[a.name.split(".")[0]]
                    out.append((f, why, node.lineno))
        elif isinstance(node, ast.ImportFrom) and node.module and node.module.split(".")[0] in PY_FLOOR_IMPORTS:
            f, why = PY_FLOOR_IMPORTS[node.module.split(".")[0]]
            out.append((f, why, node.lineno))
        elif isinstance(node, ast.Attribute) and node.attr in PY_FLOOR_ATTRS:
            f, why = PY_FLOOR_ATTRS[node.attr]
            out.append((f, why, node.lineno))
        elif isinstance(node, ast.Name) and node.id in PY_FLOOR_NAMES:
            f, why = PY_FLOOR_NAMES[node.id]
            out.append((f, why, node.lineno))
        elif name == "Match":
            out.append(("3.10", "match statement", node.lineno))
        elif name == "TryStar":
            out.append(("3.11", "except* clause", node.lineno))
        elif name == "NamedExpr":
            out.append(("3.8", "walrus operator", node.lineno))
        elif name == "TypeAlias":
            out.append(("3.12", "type statement", node.lineno))
    return out


def files_to_scan(skill_dir, entries, plugin):
    """Yield (label, full_path) for regular text-ish files in the skill and its plugin dependencies."""
    for e in entries:
        if e["kind"] == "file" and not C.is_credential_path(e["path"]):  # never read credential files
            yield e["path"], os.path.join(skill_dir, e["path"])
    if plugin and plugin.get("root"):
        for pf in plugin["files"]:
            if pf["kind"] == "file" and not C.is_credential_path(pf["path"]):  # plugin .env files too
                yield "<plugin>/" + pf["path"], os.path.join(plugin["root"], pf["path"])


def known_skill_names(skill_dir, plugin):
    names = set()
    parent = os.path.dirname(os.path.abspath(skill_dir))
    # Siblings count only inside a skills collection (a "skills" folder, or one holding several
    # SKILL.md folders), never e.g. ~/Downloads.
    def is_collection(d):
        if os.path.basename(d) == "skills":
            return True
        try:
            subs = [n for n in os.listdir(d)[:300] if not n.startswith(".")]
        except OSError:
            return False
        return sum(1 for n in subs if os.path.isfile(os.path.join(d, n, "SKILL.md"))) >= 2
    dirs = ([parent] if is_collection(parent) else []) + [
        os.path.expanduser("~/.claude/skills"), os.path.join(os.getcwd(), ".claude", "skills")]
    for d in dirs:
        try:
            names |= {n for n in os.listdir(d) if not n.startswith(".")}
        except OSError:
            pass
    if plugin and plugin.get("components"):
        for comp in plugin["components"].values():
            names |= {os.path.splitext(n)[0] for n in comp}
    return names


def sibling_skills(skill_dir, limit=100):
    """Names and descriptions of other skills in the same collection, for collision checks.

    Reads only each sibling's frontmatter (first 16 KB of its SKILL.md), never its body or files.
    """
    parent = os.path.dirname(os.path.abspath(skill_dir))
    out = []
    try:
        names = sorted(os.listdir(parent))
    except OSError:
        return out
    cands = [n for n in names if n != os.path.basename(os.path.abspath(skill_dir)) and not n.startswith(".")
             and not os.path.islink(os.path.join(parent, n))]  # a linked sibling folder is never followed
    if os.path.basename(parent) != "skills" and sum(
            1 for n in cands[:300] if os.path.isfile(os.path.join(parent, n, "SKILL.md"))) < 1:
        # Same rule as known_skill_names: a "skills" folder, or a folder holding the target and another skill.
        return out
    for n in cands:
        md = os.path.join(parent, n, "SKILL.md")
        if os.path.islink(md) or not os.path.isfile(md):
            continue
        try:
            raw, _ = C.read_bytes(md, C.MAX_FRONTMATTER)
        except OSError:
            continue
        _, fm = C.frontmatter_for_audit(C.decode(raw))
        desc = str(fm.get("description") or "")
        out.append({"name": C.escape_invisible(C.safe_cut(str(fm.get("name") or n), 64)), "description": C.excerpt(desc, 1000)})
        if len(out) >= limit:
            break
    return out


def siblings_check(target):
    """Separate check so large collections do not bloat the requirements output."""
    skill_dir, _ = C.resolve_target(target)
    return {"skill_dir": skill_dir, "siblings": sibling_skills(skill_dir, limit=300)}


def siblings_markdown(res, level=2):
    out = [C.heading(level, "Sibling skills"), ""]
    if not res.get("siblings"):
        return "\n".join(out + ["None: the target is not in a collection of skills."])
    out += ["| Name | Description |", "|---|---|"]
    out += ["| {} | {} |".format(C.md_cell(x["name"]), C.md_cell(x["description"])) for x in res.get("siblings", [])]
    return "\n".join(out)


def scan(target):
    skill_dir, _ = C.resolve_target(target)
    entries = C.walk(skill_dir)
    plugin = C.plugin_context(skill_dir, entries)
    col, findings = Collector(), []
    own_name = None
    fm = {}
    try:
        raw, _ = C.read_bytes(os.path.join(skill_dir, "SKILL.md"))
        _, fm = C.frontmatter_for_audit(C.decode(raw))
        own_name = str(fm.get("name") or os.path.basename(skill_dir))
    except OSError:
        pass
    known = known_skill_names(skill_dir, plugin) - {own_name, os.path.basename(skill_dir)}
    install_notes = []

    meta_re = re.compile(r"^(readme|changelog|license|licence|contributing|notice|benchmarks?)(\.|$)", re.I)
    read_total, over_budget = 0, 0
    for label, full in files_to_scan(skill_dir, entries, plugin):
        if meta_re.match(os.path.basename(label)):
            continue  # metadata describes the skill; it does not define what the skill needs
        if read_total > C.MAX_TOTAL_SCAN:  # same total budget as the security scan
            over_budget += 1
            continue
        try:
            data, cut = C.read_bytes(full, C.MAX_READ_CODE)
        except OSError:
            continue
        read_total += len(data)
        enc, text = C.to_text(data, cut)
        if text is None:
            continue
        text = C.normalize_newlines(text)
        base = os.path.basename(label)
        ext = os.path.splitext(base)[1].lower()
        lines = text.split("\n")
        is_md = ext in (".md", ".markdown", ".txt")
        # Browser-side scripts (DOM access, no Node modules) do not imply a Node.js runtime.
        browser_js = ext in (".js", ".mjs", ".ts") and re.search(r"\b(document|window)\.", text) is not None and \
            not re.search(r"require\(|from\s+['\"]node:|process\.(argv|env|exit)", text)
        flags = C.fenced_flags(lines)[0] if is_md else [True] * len(lines)
        shell_line = [not is_md] * len(lines)
        if is_md:
            lang, fence = None, None
            for idx, ln in enumerate(lines):
                m = C.FENCE_RE.match(ln)
                if m and fence is None:
                    fence, lang = m.group(1), ln.strip()[len(m.group(1)):].strip().split(" ")[0].lower()
                    continue
                if m and fence and ln.strip() == m.group(1) and m.group(1)[0] == fence[0] and len(m.group(1)) >= len(fence):
                    fence = lang = None
                    continue
                # An untagged fence counts as shell only on lines that start with a known program.
                shell_line[idx] = fence is not None and (lang in SHELL_LANGS or (
                    lang == "" and BIN_RE.match(" " + re.sub(r"^\$\s+", "", ln.strip())) is not None))

        # --- manifests
        if base == "package.json":
            try:
                pkg = json.loads(text)
            except Exception:  # ValueError, RecursionError
                pkg = {}
            if isinstance(pkg, dict):
                eng = pkg.get("engines") or {}
                for k, v in (eng.items() if isinstance(eng, dict) else []):
                    col.add("runtime", "{} {}".format(k, v), "{}:{}".format(label, key_line(lines, k)), "verified",
                            "package.json engines")
                for sect in ("dependencies", "peerDependencies"):
                    deps = pkg.get(sect)
                    for dep in (deps if isinstance(deps, dict) else {}):
                        col.add("packages", "npm:" + str(dep), "{}:{}".format(label, key_line(lines, dep)),
                                "verified", "package.json " + sect)
        elif base in ("requirements.txt", "requirements-dev.txt"):
            for i, ln in enumerate(lines, 1):
                s = ln.split("#", 1)[0].strip()
                if s and not s.startswith("-"):
                    col.add("packages", "py:" + re.split(r"[<>=!~\[; ]", s, 1)[0], "{}:{}".format(label, i), "verified", s)
        elif base == "pyproject.toml":
            for i, ln in enumerate(lines, 1):
                m = re.match(r'\s*requires-python\s*=\s*"([^"]+)"', ln)
                if m:
                    col.add("runtime", "python " + m.group(1), "{}:{}".format(label, i), "verified", "requires-python")
            m = re.search(r"(?m)^dependencies\s*=\s*\[([^\]]{0,20000})\]", text)
            if m:
                ln0 = text[:m.start()].count("\n") + 1
                for dep in re.findall(r'"([^"]+)"', m.group(1)):
                    col.add("packages", "py:" + re.split(r"[<>=!~\[; ]", dep, 1)[0], "{}:{}".format(label, ln0),
                            "verified", dep)
        elif base == "composer.json":
            try:
                comp_json = json.loads(text)
            except Exception:
                comp_json = {}
            req = comp_json.get("require") if isinstance(comp_json, dict) else None
            for dep, ver in (req.items() if isinstance(req, dict) else []):
                if dep == "php":
                    col.add("runtime", "php " + str(ver), label + ":1", "verified", "composer.json require")
                elif dep.startswith("ext-"):
                    col.add("packages", "php-ext:" + dep[4:], label + ":1", "verified", "composer.json require")
                else:
                    col.add("packages", "composer:" + dep, label + ":1", "verified", "composer.json require")
        elif base in (".nvmrc", ".node-version", ".python-version"):
            col.add("runtime", ("node " if "node" in base or "nvm" in base else "python ") + C.safe_cut(text.strip(), 20),
                    label + ":1", "verified", base)

        # --- per-line signals
        fm_end = 0  # tool needs come from the SKILL.md body; frontmatter is read separately below
        if label == "SKILL.md" and lines and lines[0].strip() == "---":
            fm_end = next((j for j in range(1, min(len(lines), 400)) if lines[j].rstrip() == "---"), 0) + 1
        for i, line in enumerate(lines, 1):
            src = "{}:{}".format(label, i)
            if i == 1 and line.startswith("#!"):
                col.add("runtime", line[2:].strip().replace("/usr/bin/env ", ""), src, "verified", "shebang")
            # Commands: shell fences, inline spans that start with a command, or code files.
            # Inline `cmd args` spans count in SKILL.md and references/ (instructions); elsewhere (README, other
            # docs) they are usually prose.
            if shell_line[i - 1] or not is_md:
                cmd_bits = [line]
            elif label == "SKILL.md" or label.startswith("references/"):  # inline `cmd args` spans, one by one
                cmd_bits = [sp for sp in re.findall(r"`([^`]+)`", line) if " " in sp.strip() and any(
                    BIN_RE.match(" " + re.sub(r"^[\s(]*(?:\w+=\S*\s+)*", "", seg))
                    for seg in re.split(r"&&|\|\||[;|]|<\(|\$\(", sp))]
            else:
                cmd_bits = []
            cmd_text = " ; ".join(cmd_bits) if is_md else ""
            cmd_bits = [C.redact(b, C.find_secrets(b)) for b in cmd_bits]  # a credential in an install URL never shows
            for m in (mm for bit in cmd_bits for mm in INSTALL_RE.finditer(bit)):
                args_ = re.split(r"\s+(?:then|and|or)\s+|&&|\|\||[;|]", m.group(2).strip())[0].strip()
                args_ = args_.rstrip("\"'`,)").strip()  # a command quoted in a string keeps its closing quote
                if not args_ and not re.search(r"\b(ci|sync|install|fetch|download|restore)$", m.group(1)):
                    continue
                cmd = (m.group(1) + " " + args_).strip()
                reg = next((r for pat, r in REGISTRY_FOR if re.match(pat, m.group(1))), None)
                if reg and not DOMAIN_RE.search(line) and not re.search(r"--offline\b", cmd):
                    col.add("network", "{} (install)".format(reg), src, "inferred", "default registry for " + m.group(1))
                col.add("packages", "install: " + " ".join(cmd.split()), src, "verified", line)
                install_notes.append(cmd)
            if cmd_text and is_md:
                bin_text = re.sub(r"\bgit\s+(diff|grep|archive|patch)\b", "git", cmd_text[:20000])
                for m in itertools.islice(BIN_RE.finditer(bin_text), 300):
                    if re.search(r"\binstall\s+(?:-\S+\s+){0,5}$", bin_text[max(0, m.start(1) - 120):m.start(1)]):
                        continue  # an install argument (playwright install chromium), not a binary the skill runs
                    if m.group(1) in CORE_TOOLS:
                        continue  # POSIX tools every Bash surface has (compatibility.md: leave them out)
                    col.add("binaries", m.group(1), src, "verified", line)
                if re.search(r"<\(", bin_text):
                    col.add("runtime", "bash (process substitution <(...))", src, "verified", line)
            elif ext in (".sh", ".bash", ".zsh", ".ps1") or (ext == "" and lines[0].startswith("#!") and
                                                              re.search(r"\b(ba|z|da|)sh\b", lines[0])):
                for m in itertools.islice(BIN_RE.finditer(line[:20000]), 300):
                    if not line.lstrip().startswith("#") and m.group(1) not in CORE_TOOLS:
                        col.add("binaries", m.group(1), src, "verified", line)
            elif ext in (".py", ".js", ".mjs", ".cjs", ".ts", ".php"):
                if re.search(r"subprocess|os\.system|Popen|shutil\.which|check_output|spawn|execSync|execFile|"
                             r"shell_exec|passthru|proc_open|\bexec\s*\(|\bsystem\s*\(|`", line):
                    for m in re.finditer(r"['\"](" + "|".join(re.escape(b) for b in BINARIES) + r")(?=['\" ])", line):
                        col.add("binaries", m.group(1), src, "verified", line)
            page_doms = {d.lower() for d in re.findall(
                r"(?:<script[^>]{0,200}src\s*=\s*[\"']?|@import\s+(?:url\()?[\"']?)https?://([A-Za-z0-9.-]+)", line[:20000], re.I)}
            line_install = bool(INSTALL_RE.search(line[:20000]))
            line_install_word = bool(re.search(r"\binstall\b|clone", line[:20000]))
            for m in itertools.islice(DOMAIN_RE.finditer(line[:20000]), 200):  # bounded: one pass per line
                dom = m.group(1).lower()
                if dom in page_doms:
                    col.add("network", dom + " (runtime)", src, "verified", line)
                    continue
                if line_install or (dom.endswith(REGISTRIES) and line_install_word):
                    col.add("network", dom + " (install)", src, "verified", line)
                elif (shell_line[i - 1] and (is_md or ext in (".sh", ".bash", ".zsh", ".ps1", ""))) or \
                        (not is_md and NET_CALL_RE.search(line)):
                    col.add("network", dom + " (runtime)", src, "verified", line)
                else:
                    col.docs_links += 1
            if ext == ".php":
                for pat, floor, why in PHP_FLOOR_PATTERNS:
                    if re.search(pat, line):
                        col.add("runtime", "php {}+".format(floor), src, "inferred", why)
                if re.search(r"vendor/autoload\.php", line):
                    col.add("packages", "composer (vendor/autoload.php)", src, "verified", line)
            if ext in (".js", ".mjs", ".cjs", ".ts") and not browser_js:
                for pat, floor, why in NODE_FLOOR_PATTERNS:
                    if re.search(pat, line):
                        col.add("runtime", "node {}+".format(floor), src, "inferred", why)
                for mm in re.finditer(r"(?:from\s+['\"]|require\(\s*['\"]|\bimport\(\s*['\"])([^'\"./][^'\"]*)['\"]", line):
                    mod = mm.group(1)
                    if not mod.startswith("node:") and mod.split("/")[0] not in NODE_BUILTINS:
                        col.add("packages", "npm:" + (mod if mod.startswith("@") else mod.split("/")[0]), src,
                                "verified", line)
            if label == "SKILL.md" and i > fm_end and not line.lstrip().startswith("#"):
                # Tool needs come from the instructions themselves. Headings are weak evidence, and so is a
                # negated sentence or clause ("never use subagents"); the other sentences on its line still count.
                for clause in CLAUSE_SPLIT_RE.split(line[:20000]):
                    if NEGATION_RE.search(clause):
                        continue
                    for tool, pats in TOOL_COMPILED:
                        if any(p.search(clause) for p in pats):
                            col.add("tools", tool, src, "inferred", line)
            if is_md:
                for mm in list(SKILL_NAME_RE.finditer(line)) + list(ROUTING_RE.finditer(line)):
                    name = (mm.group(1) or mm.group(mm.lastindex or 1) or "").split(":")[-1]
                    # Single-word names (`jq`, `refactor`, `blueprint`) collide with ordinary words and
                    # programs: they count only when the line also says "skill".
                    if not name or ("-" not in name and ":" not in mm.group(0) and
                                    not re.search(r"\bskills?\b", line, re.I)):
                        continue
                    if name in known and name != own_name:
                        col.add("companions", name, src, "verified", line)

        if ext == ".py":
            imports, err = python_imports(text)
            stdlib = getattr(sys, "stdlib_module_names", None)
            local = {os.path.splitext(os.path.basename(e["path"]))[0] for e in entries if e["path"].endswith(".py")}
            local |= {e["path"].split("/")[-2] for e in entries if e["path"].endswith("/__init__.py")}
            for mod, ln, guarded in imports:
                if stdlib and mod not in stdlib and mod not in local and mod != "__future__":
                    col.add("packages", "py:" + mod + (" (optional)" if guarded else ""),
                            "{}:{}".format(label, ln), "verified", "import " + mod)
            for floor, why, ln in py_floors(text):
                col.add("runtime", "python {}+".format(floor), "{}:{}".format(label, ln), "inferred", why)

    # --- declared tools from frontmatter
    for t in C.parse_tools(fm.get("allowed-tools")):
        if t.startswith("Bash"):
            col.add("tools", "shell", "SKILL.md:frontmatter", "verified", "allowed-tools: " + t)
        elif t.startswith(("Write", "Edit")):
            col.add("tools", "file write", "SKILL.md:frontmatter", "verified", "allowed-tools: " + t)
        elif t.startswith(("WebFetch", "WebSearch")):
            col.add("tools", "web access", "SKILL.md:frontmatter", "verified", "allowed-tools: " + t)
        elif t.startswith("mcp__"):
            server = t.split("__")[1] if t.count("__") >= 2 else t
            col.add("tools", "MCP connector: " + server, "SKILL.md:frontmatter", "verified", "allowed-tools: " + t)
        elif t.startswith("AskUserQuestion"):
            col.add("tools", "asking the user mid-task", "SKILL.md:frontmatter", "verified", "allowed-tools: " + t)
        elif t.startswith(("Read", "Glob", "Grep")):
            col.add("tools", "file read", "SKILL.md:frontmatter", "verified", "allowed-tools: " + t)
        elif t.startswith(("Agent", "Task")):
            col.add("tools", "subagents", "SKILL.md:frontmatter", "verified", "allowed-tools: " + t)
    if fm.get("context") == "fork":
        col.add("tools", "subagents", "SKILL.md:frontmatter", "verified", "context: fork")

    res = col.result()
    declared = {"compatibility": C.scrub(fm.get("compatibility")) if fm.get("compatibility") else None,
                "allowed_tools": C.scrub(C.parse_tools(fm.get("allowed-tools")))}

    # --- findings: declared vs detected
    needs = []
    if res["tools"]:
        needs.append("tools")
    third_party = [p for p in res["packages"] if p["item"].startswith(("py:", "npm:")) and "(optional)" not in p["item"]]
    if third_party or res["binaries"] or any(n["item"].endswith("(runtime)") for n in res["network"]):
        needs.append("packages/network")
    comp = declared["compatibility"]
    if comp is not None and not isinstance(comp, str):
        findings.append({"id": "REQ008", "severity": "warn",
                         "message": "compatibility is a {}, not a one-line string".format(type(comp).__name__)})
        comp = json.dumps(comp, default=str)
    comp = comp or ""
    if not comp and needs:
        findings.append({"id": "REQ001", "severity": "info",
                         "message": "No 'compatibility' frontmatter field, but the skill needs: " + ", ".join(
                             sorted({t["item"] for t in res["tools"]} | {p["item"] for p in third_party[:5]} |
                                    {b["item"] for b in res["binaries"][:5]}))})
    if comp:
        low = comp.lower()
        checks = [("image viewing (vision)", ("vision", "image")), ("shell", ("bash", "shell", "terminal", "command line", "cli", "node", "npm", "python", "git")),
                  ("MCP connector", ("mcp", "connector", "chrome")), ("subagents", ("subagent", "agent"))]
        try:
            skill_text = C.decode(C.read_bytes(os.path.join(skill_dir, "SKILL.md"))[0])
        except OSError:
            skill_text = ""
        has_fallback = {"subagents": re.search(r"(?i)(without|no|if no|unavailable)\W+(\w+\W+){0,3}(subagents?|agents)\b|"
                                               r"(subagents?|agents)\b[^.\n]{0,80}\b(serial(ly)?|sequentially|one by one)",
                                               skill_text)}
        for tool, words in checks:
            # A named connector ("MCP connector: playwright") replaces the generic item; its server name counts
            # as a mention too.
            found = [t["item"] for t in res["tools"] if t["item"] == tool or t["item"].startswith(tool + ": ")]
            words = tuple(words) + tuple(i.split(": ", 1)[1].lower() for i in found if ": " in i)
            if found and not any(re.search(r"\b" + re.escape(w) + r"\b", low) for w in words) \
                    and not has_fallback.get(tool):
                findings.append({"id": "REQ002", "severity": "warn",
                                 "message": "compatibility field does not mention '{}', which the instructions "
                                            "rely on".format(tool)})
        if ": " in comp:
            findings.append({"id": "REQ003", "severity": "warn",
                             "message": "compatibility value contains ': ' (breaks unquoted YAML)"})
        if len(comp) > 500:
            findings.append({"id": "REQ004", "severity": "warn",
                             "message": "compatibility is {} chars; spec max is 500".format(len(comp))})
    install_blob = " ".join(install_notes).lower()
    for p in third_party:
        name = p["item"].split(":", 1)[1].split(" ")[0].lower()
        kind = p["item"].split(":", 1)[0]
        manifests = {"py": {"requirements.txt", "pyproject.toml", "setup.py", "setup.cfg", "Pipfile"},
                     "npm": {"package.json"}, "composer": {"composer.json"}}.get(kind, set())
        if name not in install_blob and not any(os.path.basename(e["path"]) in manifests for e in entries):
            findings.append({"id": "REQ005", "severity": "warn",
                             "message": "Package '{}' is imported ({}) but no install command or manifest names "
                                        "it".format(name, ", ".join(p["sources"]))})
    for n in res["network"]:
        if n["item"].endswith("(runtime)"):
            findings.append({"id": "REQ006", "severity": "info",
                             "message": "Runtime network access to {}: blocked on surfaces with domain allowlists "
                                        "unless allowlisted".format(n["item"].split(" ")[0])})
    names = {os.path.basename(e["path"]) for e in entries}
    if any(n.startswith("install: npm ci") for n in col.axes["packages"]) and "package-lock.json" not in names \
            and "npm-shrinkwrap.json" not in names:
        findings.append({"id": "REQ010", "severity": "warn",
                         "message": "'npm ci' is used but no package-lock.json ships: npm ci fails without a lockfile"})
    if getattr(sys, "stdlib_module_names", None) is None and any(e["path"].endswith(".py") for e in entries):
        findings.append({"id": "REQ011", "severity": "info",
                         "message": "Python package detection skipped: the checker needs Python 3.10+ to tell "
                                    "standard-library imports from third-party ones; files using newer syntax "
                                    "(match, except*) may not parse, so their version floors are missing too"})
    if over_budget:
        findings.append({"id": "REQ012", "severity": "warn",
                         "message": "{} files not read: the {} MB total budget was reached; check them by hand".format(
                             over_budget, C.MAX_TOTAL_SCAN // (1024 * 1024))})
    by_runtime = {}
    for r in res["runtime"]:
        if r["confidence"] == "inferred":
            by_runtime.setdefault(r["item"].split(" ")[0], []).append(r)
    for rt, floors in sorted(by_runtime.items()):  # compare floors within one runtime only
        top = max(floors, key=lambda r: [int(x) for x in re.findall(r"\d+", r["item"])][:2] or [0])
        findings.append({"id": "REQ007", "severity": "info",
                         "message": "Highest inferred {} floor: {} ({} at {})".format(
                             rt, top["item"], top["detail"], top["sources"][0])})

    try:
        status, _fm_text, _, _ = C.split_frontmatter(C.decode(C.read_bytes(os.path.join(skill_dir, "SKILL.md"))[0]))
    except OSError:
        status, _fm_text = "missing", None
    if status == "ok" and _fm_text is not None and \
            any(not e.startswith("NOTE") for e in C.parse_frontmatter(_fm_text)[1]):
        declared["unparsed"] = True  # values recovered from broken YAML: Claude Code would drop them
        findings.append({"id": "REQ009", "severity": "warn",
                         "message": "Frontmatter YAML is broken: the declared values above were recovered for audit, "
                                    "but Claude Code would ignore them"})
    sibs = sibling_skills(skill_dir)
    out = {"skill_dir": skill_dir, "declared": declared, "in_collection": bool(sibs), "siblings": [x["name"] for x in sibs],
           "siblings_note": "names only; run --only siblings for descriptions (paged)" if sibs else ""}
    out.update(res)
    out["docs_links"] = col.docs_links
    out["findings"] = findings
    return out


def to_markdown(res, level=2):
    out = [C.heading(level, "Requirements"), ""]
    if res.get("siblings"):
        out.append("Sibling skills in this collection (for collision checks): " +
                   ", ".join(C.md_cell(x) for x in res["siblings"][:40]) +
                   (" ..." if len(res["siblings"]) > 40 else ""))
        out.append("")
    d = res.get("declared")  # first page only when paging
    if d is not None:
        out.append("Declared compatibility: " + ("`{}`".format(C.safe_name(str(d["compatibility"])))
                                                 if d["compatibility"] else "none"))
        out.append("")
    out += ["| Axis | Item | Confidence | Hits | Evidence |", "|---|---|---|---|---|"]
    for axis in ("runtime", "packages", "binaries", "network", "tools", "companions"):
        items = res.get(axis) or []
        if not items:
            out.append("| {} | - | - | - | nothing detected |".format(axis))
        for e in items[:25]:
            out.append("| {} | `{}` | {} | {} | {} |".format(
                axis, C.safe_name(e["item"]), e["confidence"], e["hits"],
                ", ".join("`{}`".format(C.safe_name(s)) for s in e["sources"])))
    out += ["", "URLs not used by a command or network call (documentation, schema ids, examples): {}".format(
        res.get("docs_links", 0))]
    if res["findings"]:
        out += ["", "| Sev | ID | Message |", "|---|---|---|"]
        out += ["| {} | {} | {} |".format(f["severity"], f["id"], C.md_cell(f["message"])) for f in res["findings"]]
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
    res = scan(args.target)
    print(json.dumps(res, indent=2, default=str) if args.format == "json" else to_markdown(res, args.heading_level))
    return 0


if __name__ == "__main__":
    sys.exit(main())
