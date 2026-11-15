#!/usr/bin/env python3
"""Static security scan of every text file in a skill directory.

Read-only pattern matching: never executes, imports, or sources anything in
the target. Walks vendored dirs (node_modules, .venv, ...) too; only .git
internals are skipped. Symlinks are reported, never followed. Secrets and
invisible characters are redacted/escaped in all output.

Usage:
    python3 -I scan_security.py <skill_dir | SKILL.md> [--format md|json] [--heading-level N]

json: {"skill_dir", "findings": [...], "counts": {...},
       "suppressed": {rule: {"count": n, "locations": ["file:line (severity)", ...]}},
       "not_covered": [...]}. Findings are sorted by severity, then at most 10 per
       (rule, file) are listed; the rest appear as locations in "suppressed".
       "counts" covers every hit, listed or not. Plugin-level files appear as
       "<plugin>/path".
Each finding: rule, severity (high|medium|low), category, file, line, description, excerpt.
A match is a lead, not a verdict: an analyzer skill may quote "ignore previous
instructions" on purpose, and a scanner's own rule table matches itself. Read
the line in context before reporting it.
"""
import argparse
import collections
import bisect
import json
import os
import itertools
import re
import sys
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))  # this skill's scripts/ only
import _common as C  # noqa: E402

# (rule id, severity, category, regex, description) - applied to logical lines
# (backslash-continued lines are joined first).
RULES = [
    ("SEC-RCE-1", "high", "remote-exec", r"\b(curl|wget|iwr|Invoke-WebRequest)\b[^\n|]{0,400}\|\s*(?:(?!(?:sudo\s|(?:ba|z|da|k)?sh\b|python|node|perl|ruby|php|pwsh))[\w./-]{1,40}(?:[ \t][^\n|]{0,80})?\|\s*){0,3}(sudo(\s+-\S{1,20}){0,5}\s+)?(?:/[\w.+-]{1,64}){0,8}/?(ba|z|da|k|)sh\b|\b(ba|z|)sh\s+-c\s+[\"']?\$\((curl|wget)\b", "pipes a download into a shell"),
    ("SEC-RCE-2", "high", "remote-exec", r"\bInvoke-Expression\b|\|\s*iex\b|(?<![\w>])iex\s*[($'\"]", "PowerShell expression execution"),
    ("SEC-RCE-4", "high", "remote-exec", r"\b(curl|wget)\b[^\n|]{0,400}\|\s*(?:(?!(?:sudo\s|(?:ba|z|da|k)?sh\b|python|node|perl|ruby|php|pwsh))[\w./-]{1,40}(?:[ \t][^\n|]{0,80})?\|\s*){0,3}(sudo\s+)?(python[0-9.]*|node|perl|ruby|php|pwsh)\b|\b(ba|z|)sh\s+<\(\s*(curl|wget)\b|\b(source|\.)\s+<\(\s*(curl|wget)\b", "pipes or process-substitutes a download into an interpreter"),
    ("SEC-RCE-5", "high", "remote-exec", r"\beval\s+[\"']?\$\(\s*(curl|wget)\b|\b(python[0-9.]*|node|perl|ruby|php|deno|bun)\s+(-\w+\s+)*-[ce]\s+[\"']?\$\(\s*(curl|wget)\b|\b(python[0-9.]*|node|perl|ruby|php)\s+<\(\s*(curl|wget)\b", "runs downloaded code"),
    ("SEC-RCE-3", "high", "remote-exec", r"\bbase64\s+(-d|--decode|-D)\b[^\n]{0,400}\|\s*(ba|z|)sh\b", "decodes a payload into a shell"),
    ("SEC-DEL-1", "high", "destructive", r"\brm\s+-[a-zA-Z]{0,12}r[a-zA-Z]{0,12}f|\brm\s+-[a-zA-Z]{0,12}f[a-zA-Z]{0,12}r|\brm(\s+-[a-zA-Z]{1,12}){0,4}\s+-[a-zA-Z]{0,12}[rR]\b(\s+-[a-zA-Z]{1,12}){0,4}\s+-[a-zA-Z]{0,12}f|\brm\s+(--\w+\s+)*--(recursive|force)\b|[\"']rm[\"']\s*,\s*[\"']-[a-zA-Z]*[rf]|\bfind\b[^\n|;]{0,300}\s-delete\b", "recursive forced delete"),
    ("SEC-DEL-2", "medium", "destructive", r"\bshutil\.rmtree\b|\bfs\.rm(Sync)?\(|\brimraf\b|\b(rmSync|rmdirSync|rm|rmdir)\s*\([^)]{0,200}recursive\s*:\s*true|\b(remove|delete)s?\s+(any\s+|all\s+|the\s+|a\s+new\s+)?untracked\s+files?\b|\buntracked\s+files?\s+(is|are|gets?)\s+(removed|deleted)\b|\bgit\s+clean\b", "recursive delete API or removal of untracked files"),
    ("SEC-DEL-3", "high", "destructive", r"\bgit\s+(?:-C\s+\S+\s+)?(push\s+[^\n]{0,400}--force|reset\s+--hard|clean\s+-[a-z]*f|restore\b(?![^\n]{0,80}--staged\b)|checkout\s+(?:\S+\s+)?--\s)", "destructive git command (discards changes)"),
    ("SEC-DEL-4", "high", "destructive", r"\b(mkfs|dd\s+if=|DROP\s+(TABLE|DATABASE)|TRUNCATE\s+TABLE)\b", "destructive system/DB command"),
    ("SEC-FS-1", "medium", "file-delete", r"\bos\.(remove|unlink|rmdir)\s*\(|\.unlink\s*\(|\bfs\.unlink(Sync)?\(", "deletes files"),
    ("SEC-FS-2", "low", "file-write", r"\bopen\([^)]{0,400},\s*['\"][wax]b?\+?['\"]|\.write_text\(|\.write_bytes\(|\bfs\.writeFile", "writes files: check where"),
    ("SEC-EXEC-1", "medium", "code-exec", r"(?<![.\w])(eval|exec)\s*\(", "dynamic code evaluation"),
    ("SEC-EXEC-2", "medium", "code-exec", r"\bos\.(system|popen|exec[lv]p?e?)\s*\(|shell\s*=\s*True|\b(?:execSync|execFileSync|spawnSync|execFile|spawn)\s*\(|\b(shell_exec|passthru|proc_open|pcntl_exec|popen)\s*\(|(?<![\w>:$])system\s*\(", "shell execution from code"),
    ("SEC-EXEC-8", "medium", "code-exec", r"\$_(GET|POST|REQUEST|COOKIE|SERVER)\s*\[|\b(assert|create_function|preg_replace)\s*\([^)]{0,400}/e['\"]|\binclude(_once)?\s*\(?\s*\$|\brequire(_once)?\s*\(?\s*\$", "PHP request input or dynamic include/eval"),
    ("SEC-EXEC-3", "medium", "code-exec", r"(^|\s)!`[^`]+`|^\s*```!", "dynamic context injection: runs a command when the skill loads"),
    ("SEC-EXEC-4", "medium", "code-exec", r"\bsubprocess\.(run|call|check_call|check_output|Popen|getoutput|getstatusoutput)\s*\(", "spawns a subprocess: check the command"),
    ("SEC-EXEC-5", "medium", "code-exec", r"\b(bash|sh|zsh|python[0-9.]*|pwsh)\s+-c\b|\b(node|perl|ruby|php|deno)\s+-[er]\b", "inline interpreter command"),
    ("SEC-EXEC-6", "medium", "code-exec", r"(^|[;&|(]\s*|\s)eval\s+[\"'$`]|(^|[;&|]\s*)(source|\.)\s+[\"']?[\w$~./-]+\.(sh|bash|env)\b", "shell eval/source"),
    ("SEC-EXEC-7", "low", "code-exec", r"\b__import__\s*\(|\bimportlib\.import_module\s*\(|\brequire\s*\(\s*[^'\"\s)]", "dynamic import"),
    ("SEC-DESER-1", "medium", "deserialization", r"\b(pickle|cPickle|dill|marshal)\.loads?\s*\(|\byaml\.(unsafe_)?load\s*\((?![^)]{0,400}SafeLoader)|\byaml\.load_all\s*\(", "unsafe deserialization"),
    ("SEC-NET-1", "low", "network", r"\b(?:requests\.\w+|urllib\.request|urlopen|from urllib import request|http\.client|import socket|socket\.socket|Invoke-WebRequest|Invoke-RestMethod)\b|\b(?:httpx|aiohttp|axios)\.\w|\b(?:import|from)\s+(?:httpx|aiohttp)\b|\b(?:require\(\s*|from\s+)['\"]axios['\"]|(?<![\w.])(?<!def )(?<!function )(?:fetch|axios)\s*\(", "network API call"),
    ("SEC-NET-2", "low", "network", r"\b(curl|wget|nc|netcat|scp|ftp)\s|\brsync\s(?=[^\n]{0,300}(?:\w:[^\s\\]|::|rsync://))", "network command"),
    ("SEC-NET-3", "medium", "exfiltration", r"\b(curl|wget)\b[^\n]{0,400}\s(-d|--data[\w-]*|-F|--form|--upload-file|-T)\b", "uploads data to a remote host"),
    ("SEC-NET-5", "medium", "network", r"<script\b[^>\n]{0,200}\bsrc\s*=\s*[\"']?(?:https?:)?//", "loads a remote script into a page (runs third-party code there)"),
    ("SEC-NET-4", "medium", "exfiltration", r"\b(requests|httpx|session|client)\.(post|put|patch)\s*\(|\bmethod\s*[:=]\s*['\"](POST|PUT)", "sends data to a remote host from code"),
    ("SEC-PRIV-1", "medium", "privilege", r"\bsudo\b|\bchmod\s+(-R\s+)?[0-7]?777\b|\bchown\s+-R\b|\bsetuid\b", "privilege change"),
    ("SEC-PERS-1", "medium", "persistence", r"\bcrontab\b|\blaunchctl\b|\bsystemctl\s+(enable|start)\b|\.(bash|zsh)rc\b|\.profile\b|\bLaunchAgents\b", "persistence or shell startup change"),
    ("SEC-PERS-2", "medium", "persistence", r"(\.claude/settings(\.local)?\.json|CLAUDE\.md|\.mcp\.json|\.claude/hooks)", "touches Claude Code config, memory, or hooks"),
    ("SEC-PATH-1", "medium", "sensitive-path", r"(~|\$HOME|expanduser\([^)]{0,400})/?\.(ssh|aws|gnupg|kube|docker|netrc|npmrc|pypirc)\b|\bid_(rsa|ed25519)\b|/etc/(passwd|shadow|sudoers)\b|(^|[\s/\"'])\.env\b|Library/Keychains|\bsecurity\s+find-(generic|internet)-password\b|credentials\.json", "reads a sensitive location"),
    ("SEC-PATH-3", "medium", "sensitive-path", r"~/Downloads/|\$HOME/Downloads/", "reads or moves a file in the user's Downloads folder (a stale or planted file can be picked up)"),
    ("SEC-FS-3", "medium", "file-write", r"\bchmod\s+(-[a-zA-Z]*R[a-zA-Z]*|--recursive)\b", "recursive permission change"),
    ("SEC-FS-4", "medium", "secret", r"\b(rsync|cp|scp|tar|zip)\b[^\n|;&]{0,200}(^|[\s/'\"])\.env\b", "copies a .env file (secrets) somewhere else"),
    ("SEC-PATH-2", "low", "portability", r"/(home|Users)/[A-Za-z0-9._-]+/", "hardcoded user home path"),
    ("SEC-PKG-1", "low", "supply-chain", r"\b(pip3?|uv\s+pip|pipx)\s+install\b|\bnpm\s+(i|install|ci)\b|\b(pnpm|yarn)\s+(install|add)\b|\b(composer|bundle)\s+install\b|\bnpx\s(?!--no-install)|\bgem\s+install\b|\bbrew\s+install\b|\bgo\s+install\b|\bcargo\s+install\b", "package install command: confirm whether it runs or is only shown (docs, help text)"),
    ("SEC-INJ-1", "medium", "prompt-injection", r"\b(ignore|disregard|forget|override)\s+((all|any|the|your|these|my|of)\s+)*(previous|prior|above|earlier|preceding|system)(\s+(instructions|rules|prompts?|guidelines|directions|messages?))?\b", "instruction-override phrase"),
    ("SEC-INJ-2", "medium", "prompt-injection", r"\b(do not|don't|never)\s+(tell|inform|mention (this )?to|reveal (this )?to|show)\s+the\s+user\b|\bwithout\s+(asking|telling|informing|notifying)\s+the\s+user\b", "hides actions from the user"),
    ("SEC-INJ-3", "low", "prompt-injection", r"\byou are now\b|\bnew system prompt\b|\bdeveloper mode\b|\bjailbreak\b", "persona/jailbreak phrase"),
    ("SEC-INJ-4", "medium", "prompt-injection", r"\b(skip|bypass|disable)\s+(the\s+)?(permission|confirmation|approval|safety|sandbox)\b|--dangerously|dangerouslyDisableSandbox|bypassPermissions|--no-verify\b", "bypasses permissions, safety, or hooks"),
]
class DownloadThenRun:
    """SEC-RCE-5's download-then-run form, found in linear time: anchor on each '&&' or ';', check that a shell or
    interpreter runs right after it, then look back at most 600 characters for a curl/wget that saves a file."""
    AFTER = re.compile(r"\s*(sudo\s+)?((ba|z|)sh|python[0-9.]*|node|chmod\s+\+x)\s", re.I)

    def finditer(self, text):
        n = tries = 0
        text = mask_quotes(text)  # '&' or ';' inside a quoted URL is not a separator; offsets stay the same
        for sep in re.finditer(r"&&|;", text):
            if not self.AFTER.match(text, sep.end()):
                continue  # decoy separators cost one cheap check each and never count toward the cap
            lo = max(0, sep.start() - 600)
            seg = text[lo:sep.start()]
            # The download must sit in the last piece before this separator: cut at the previous newline,
            # ';', '&', or '|' so earlier commands (and decoys) are never searched again.
            cut = max(seg.rfind(c) for c in "\n;&|") + 1
            lo, seg = lo + cut, seg[cut:]
            if "curl" not in seg.lower() and "wget" not in seg.lower():
                continue
            tries += 1
            if tries > 5000:  # bound the regex work per file whatever the hit count
                return
            m = FETCH_WORD_RE.search(seg)  # linear: the fetch word, then (for curl) an output flag after it
            if m and not (m.group(0).lower() == "wget" or OUTPUT_FLAG_RE.search(seg, m.end())):
                m = None
            if m:
                n += 1  # only real download-then-run hits count toward the cap
                if n > 400:
                    return
                yield _Hit(lo + m.start(), sep.end())


_QUOTED_RE = re.compile(r"\"[^\"\n]{0,2000}\"|'[^'\n]{0,2000}'")


def mask_quotes(text):
    """Replace the inside of each quoted string with 'x', keeping its length, so separators inside quotes are
    not seen as separators and every offset still points at the original text."""
    return _QUOTED_RE.sub(lambda m: m.group(0)[0] + "x" * (len(m.group(0)) - 2) + m.group(0)[-1], text)


class _Hit:
    def __init__(self, s, e):
        self._s, self._e = s, e

    def start(self):
        return self._s

    def end(self):
        return self._e


OUTPUT_FLAG_RE = re.compile(r"\s(?:-[A-Za-z]{0,10}[oO]|--output|>)\s*['\"]?([^\s'\";&|>]{1,200})")  # -o, -O, -fsSLo
WGET_URL_RE = re.compile(r"\bwget\s+(?:-[^\sO]\S{0,40}\s+){0,4}(https?://\S{1,300})", re.I)
FETCH_WORD_RE = re.compile(r"\b(?:curl|wget)\b", re.I)


def save_targets(line, masked):
    """File names a curl/wget on this line saves to. Linear: each output flag looks back at most 300 characters,
    to the last separator, for the download command (a regex from every curl would rescan 300 characters each)."""
    out = []
    for m in OUTPUT_FLAG_RE.finditer(masked):
        lo = max(0, m.start() - 300)
        back = masked[lo:m.start()]
        cut = max(back.rfind(c) for c in "\n;&|") + 1
        if FETCH_WORD_RE.search(back, cut):
            out.append(line[m.start(1):m.end(1)].strip("'\"").rstrip("/").rsplit("/", 1)[-1].split("?")[0])
    for m in WGET_URL_RE.finditer(masked):
        out.append(line[m.start(1):m.end(1)].rstrip("/").rsplit("/", 1)[-1].split("?")[0])
    return out


RUN_SAVED_RE = re.compile(r"^\s*(?:\$\s+)?(?:sudo\s+)?(?:(?:ba|z|da|k)?sh|python[0-9.]*|node|perl|ruby|php|pwsh|source|\.|"
                          r"chmod\s+\+?[0-7x+]+)\s+\S|^\s*(?:\$\s+)?\./\S", re.I)


class UploadAfterFetch:
    """SEC-NET-3 in linear time: find each upload flag once, then look back (same line, at most 400
    characters) for a curl/wget before it. A regex starting at every curl would rescan 400 characters
    per occurrence, so a line of repeated "curl " costs quadratic time."""
    FLAG = re.compile(r"\s(-d|--data[\w-]*|-F|--form|--upload-file|-T)\b")
    TOOL = re.compile(r"\b(curl|wget)\b", re.I)

    def finditer(self, text):
        tools = [m.start() for m in self.TOOL.finditer(text)]
        if not tools:
            return
        for f in self.FLAG.finditer(text):
            k = bisect.bisect_left(tools, f.start()) - 1
            if k < 0:
                continue
            t = tools[k]
            # the nearest tool before the flag; any earlier one on the line would be farther away
            if f.start() - t <= 405 and "\n" not in text[t:f.start()]:
                # report from the first tool within reach on this line, like the regex did
                j = k
                while j > 0 and f.start() - tools[j - 1] <= 405 and "\n" not in text[tools[j - 1]:t]:
                    j -= 1
                    if k - j > 50:
                        break
                yield _Hit(tools[j], f.end())


COMPILED = [(r, s, c, re.compile(p, re.I | re.M), d) for r, s, c, p, d in RULES]
COMPILED = [(r, s, c, UploadAfterFetch() if r == "SEC-NET-3" else rx, d) for r, s, c, rx, d in COMPILED]
COMPILED.insert(next(i for i, x in enumerate(COMPILED) if x[0] == "SEC-RCE-5") + 1,
                ("SEC-RCE-5", "high", "remote-exec", DownloadThenRun(), "download then execute"))
HIDDEN = C.HIDDEN_CLASSES
BLANKS = {c: " " for c in [0x00A0, 0x1680, 0x202F, 0x205F, 0x2800, 0x3000, 0x3164, 0xFFA0] + list(range(0x2000, 0x200B))}
BASE64_RE = re.compile(r"[A-Za-z0-9+/]{200,}={0,2}")
LINKREF_COMMENT_RE = re.compile(r"^[ \t]{0,3}\[[^\]\n]{0,300}\]:[ \t]*(#|<>)[ \t]*[(\"']", re.M)
CSS_HIDDEN_RE = re.compile(r"display\s*:\s*none|visibility\s*:\s*hidden|font-size\s*:\s*0|<details\b", re.I)
DOWN = {"high": "medium", "medium": "low", "low": "low"}
# Generic credential shapes: in reference docs these are usually example values. Provider-format
# keys (SEC-KEY-1..6, 10..13, 16) stay high everywhere.
GENERIC_SECRET_RULES = {"SEC-KEY-7", "SEC-KEY-8", "SEC-KEY-14", "SEC-KEY-15", "SEC-KEY-17", "SEC-KEY-18"}
TEMP_CLEANUP_RE = re.compile(r"rm\s+-[a-zA-Z]+\s+(--\s+)?\"\$\{?(?P<var>[A-Za-z_][A-Za-z0-9_]*)(:\?[^}]*)?\}?\""
                             r"(?=\s*(?:$|[;)'\n]|&&|\|\||&\s|\|\s))")  # the variable must be the last argument
RUN_VERB_RE = re.compile(r"\b(run|runs|execute|exec|call|invoke|type|paste|use|start|launch|install|read|reads|see|"
                         r"load|open|consult|check|follow|apply|before|first|according to|as described in)\b", re.I)
DISCUSSION_RE = re.compile(r"\b(e\.g\.|for example|such as|like|phrases?|attack|injection|jailbreak|example|"
                           r"watch for|flag|detect|never follow|do not follow|ignore them)\b", re.I)
UNSAFE_VARS = {"HOME", "PWD", "OLDPWD", "USER", "TMPDIR", "XDG_CONFIG_HOME", "XDG_DATA_HOME", "CLAUDE_PROJECT_DIR"}
ORDER = {"high": 0, "medium": 1, "low": 2}
NEVER_DOWNGRADE = {"remote-exec", "exfiltration", "secret", "hidden-text"}
KEEP_LOCATIONS = {"exfiltration", "prompt-injection", "permissions", "remote-exec", "secret", "hidden-text"}
DOC_DOWNGRADE = {"destructive", "file-delete", "file-write", "code-exec", "deserialization", "network",
                 "privilege", "persistence", "sensitive-path", "supply-chain"}
MAX_PER_RULE = 10   # hits listed per (rule, file); the rest are listed as locations in "suppressed"
MAX_PER_RULE_TOTAL = 50  # hits listed per rule across all files (highs first); the rest go to "suppressed" too
MAX_LINE_B64 = 20_000  # chars of a line checked for base64 blobs
MAX_LINE_RULES = 20_000  # chars of a logical line checked by RULES (keeps the scan linear-time)
MAX_RAW_PER_RULE_FILE = 200  # hits collected per (rule, file); later ones are only counted
SCAN_SECONDS = 60  # wall-clock budget for one security scan; later files get SEC-BIG-5
MAX_RAW_KEEP_LOCATIONS = 2000  # the same for KEEP_LOCATIONS categories (at most 200 locations are listed)
MAX_LOGICAL = 50  # max physical lines joined into one logical line

NOT_COVERED = [
    "Files a target hides from a Grep that respects .gitignore, .ignore, or .rgignore, or hidden dot-files a Grep may skip: compare Grep hits with the inventory",
    "Logic spread across files or functions (a URL built in one place and fetched in another)",
    "Obfuscation beyond long base64 runs: string concatenation, chr()/hex building, rot13, compression",
    "Python implicit line continuation inside brackets (only backslash continuations are joined)",
    "Behavior of binaries, archives, or vendored packages (listed, not decompiled)",
    "Prompt injection phrased in other languages or paraphrased beyond the phrase list",
    "Instructions in reference files that contradict SKILL.md without using override phrases",
    "Network targets or data sensitivity: a network hit says a call exists, not what it sends",
    "Homoglyphs (Cyrillic or Greek letters posing as Latin) in names, URLs, or commands",
    "Sanitizers that strip <script> but keep on* handlers, javascript: URLs, or iframes (read browser-side extractors)",
    "Which path a recursive delete gets: a caller-supplied or swapped argument is not traced",
    "Unsafe deserialization through a bare imported name (from yaml import load; load(data)): only qualified calls match",
    "What frontmatter hooks, plugin hooks, MCP servers, and load-time commands actually do: they are listed, not traced",
    "Plugin files the skill does not name via ${CLAUDE_PLUGIN_ROOT} (other skills, agents, commands are listed only)",
]


def logical_lines(lines, with_parts=False):
    """Yield (start_line_no, joined_text) joining lines that end with a backslash (with with_parts, also
    the physical pieces that were joined with single spaces)."""
    buf, start = [], None
    for ln, line in enumerate(lines, 1):
        if start is None:
            start = ln
        if line.rstrip().endswith("\\") and len(buf) < MAX_LOGICAL:
            buf.append(line.rstrip()[:-1])
            continue
        buf.append(line)
        yield (start, " ".join(buf), buf) if with_parts else (start, " ".join(buf))
        buf, start = [], None
    if buf:
        yield (start, " ".join(buf), buf) if with_parts else (start, " ".join(buf))


def secret_spans(logical, parts):
    """Secret hits in a joined logical line: its own matches plus each physical piece's (shifted), so a
    line-anchored rule that matches only on its own physical line is still found."""
    hits = list(C.find_secrets(logical))
    if len(parts) > 1:
        off = 0
        for part in parts:
            hits += [(a + off, b + off, r, d) for a, b, r, d in C.find_secrets(part)]
            off += len(part) + 1
    return hits


APOSTROPHE_RE = re.compile(r"(?<=\w)'(?=\w)")  # don't, it's - not quotes


_QCACHE = {}


def quoted(line, start, end, reach=200, quotes=('"', "`", "'")):
    """True when [start, end) sits inside a tight pair of the given quotes (within `reach` chars)."""
    if _QCACHE.get("line") is not line:  # one cleanup and one quote index per line, not per match
        clean = APOSTROPHE_RE.sub("_", line)
        _QCACHE.update(line=line, clean=clean,
                       pos={q: [i for i, ch in enumerate(clean) if ch == q] for q in ('"', "`", "'")})
    clean, pos = _QCACHE["clean"], _QCACHE["pos"]
    lo = max(0, start - reach)
    before, after = clean[lo:start], clean[end:end + reach]
    for q in quotes:
        if q in before and q in after and bisect.bisect_left(pos[q], start) % 2 == 1:
            return True
    return '"' in quotes and "\u201c" in before and "\u201d" in after and before.count("\u201c") > before.count("\u201d")


def _all_inside_literal(line, positions):
    """True when every index in positions (ascending) sits inside a quoted string or a regex literal.
    One left-to-right pass: quotes tracked with backslash escapes; a '#' or '//' outside quotes starts a
    comment, which is not a literal."""
    positions = list(positions)
    if not positions:
        return False
    quote, regex_end, i, k, n = None, -1, 0, 0, len(line)
    while i < n and k < len(positions):
        if i == positions[k]:
            if not (quote or i < regex_end):
                return False
            k += 1
            continue
        ch = line[i]
        if quote:
            if ch == "\\":
                i += 1
                if i < n and k < len(positions) and i == positions[k]:
                    continue  # an escaped hidden character is still inside the string
            elif ch == quote:
                quote = None
        elif i >= regex_end:
            if ch in "\"'`":
                quote = ch
            elif ch == "#" or line.startswith("//", i):
                return False
            elif ch == "/" and (i == 0 or line[i - 1] in "=(,: \t"):
                m = re.match(r"/[^/\s][^/\n]{0,500}/", line[i:i + 503])
                if m:
                    regex_end = i + m.end() - 1
        i += 1
    return k == len(positions)


_DEADLINE = [float("inf")]  # set by scan(); scan_text() checks it every 50 lines


def _out_of_time(add, rel, ln, what):
    """When the scan's time budget is spent mid-file, report where the scan stopped and return True."""
    if time.monotonic() <= _DEADLINE[0]:
        return False
    add("SEC-BIG-5", "high", "coverage", rel, ln, rel, "scan time budget ({} s) reached inside this file: {} rules "
        "stopped at line {}; cover the rest by hand".format(SCAN_SECONDS, what, ln))
    return True


class LineFacts:
    """Whole-line facts classify() needs, each computed at most once per line (not once per match)."""
    _STEP_RE = re.compile(r"\b(run|execute|paste|type|then|first|next)\b", re.I)
    _ITEM_RE = re.compile(r"\s*([-*+]|\d+[.)])\s")

    def __init__(self, window):
        self.window, self._c = window, {}

    def _get(self, key, fn):
        if key not in self._c:
            self._c[key] = fn()
        return self._c[key]

    @property
    def discussion(self):
        return self._get("d", lambda: bool(DISCUSSION_RE.search(self.window)))

    @property
    def checklist(self):
        return self._get("c", lambda: bool(CHECKLIST_CUE_RE.search(self.window)))

    @property
    def list_item(self):
        return self._get("l", lambda: bool(self._ITEM_RE.match(self.window)))

    @property
    def step_verb(self):
        return self._get("s", lambda: bool(self._STEP_RE.search(self.window)))

    @property
    def table_row(self):
        return self._get("t", lambda: self.window.lstrip().startswith("|"))


def classify(rule, sev, cat, desc, window, m, prose, is_skill_md, is_ref_doc, followed=False, facts=None):
    """Return (severity, description) for one match. At most one downgrade ever applies.

    SKILL.md is the instructions Claude follows, so no downgrade applies there.
    """
    facts = facts if facts is not None and facts.window is window else LineFacts(window)
    if (cat == "prompt-injection" and prose and is_ref_doc and quoted(window, m.start(), m.end(), reach=60)
            and facts.discussion):
        # Only short quotes in teaching docs that visibly discuss attacks; never code, SKILL.md, or followed refs.
        return "low", desc + " (quoted in a discussion of attacks)"
    if rule == "SEC-DEL-1":
        tm = TEMP_CLEANUP_RE.match(window, m.start())
        if tm and tm.group("var").upper() not in UNSAFE_VARS and not is_skill_md:
            return "medium", "recursive delete of a quoted variable (temp-dir cleanup idiom): confirm it is always set"
    if prose and not is_skill_md and not followed and cat not in ("secret", "hidden-text", "prompt-injection"):
        lo, hi = window.rfind("`", 0, m.start()), window.find("`", m.end())
        if lo != -1 and hi != -1 and re.fullmatch(r"[\w.-]+", window[lo + 1:hi]):
            # A bare command name in backticks ("never use `Invoke-Expression`") cannot run as-is.
            return DOWN[sev], desc + " (bare command name in prose)"
    if (prose and not is_skill_md and cat not in ("prompt-injection", "secret", "hidden-text")
            and (not followed or facts.checklist)  # in a followed doc: only a list of bad patterns
            and facts.list_item
            and quoted(window, m.start(), m.end(), quotes="`")
            and not facts.step_verb):  # "..., then" is a step
        # A followed reference's list item that names a pattern to report ("- `iwr | iex` without a checksum")
        # is a checklist entry, not a step: one level down, and the description says so.
        return DOWN[sev], desc + " (named in a checklist item; confirm it is not a step)"
    if cat in NEVER_DOWNGRADE:
        return sev, desc
    if is_skill_md:
        return sev, desc
    if prose and not followed and cat != "prompt-injection" and facts.table_row:
        return DOWN[sev], desc + " (in a Markdown table, not a command to run)"
    if prose and not followed and cat != "prompt-injection" and quoted(window, m.start(), m.end(), quotes="`"):
        return DOWN[sev], desc + " (named in prose, not a command to run)"
    if is_ref_doc and cat in DOC_DOWNGRADE:
        return DOWN[sev], desc + " [reference doc]"
    return sev, desc


def html_comments(text):
    """Yield (start_offset, content, closed) for each HTML comment; linear time."""
    pos = 0
    while True:
        i = text.find("<!--", pos)
        if i < 0:
            return
        j = text.find("-->", i + 4)
        if j < 0:
            tail = C.safe_cut(text[i + 4:i + 4 + 200000], 4400)  # redacted before the cut: no partial secret
            yield i, tail, False
            return
        yield i, text[i + 4:j], True
        pos = j + 3


CHECKLIST_CUE_RE = re.compile(r"\b(without|on (downloaded|input|user|untrusted)|from (user )?input|unescaped|unsanitized|"
                              r"unvalidated|untrusted|avoid|flag|report|vulnerab\w*|unsafe|insecure|bug)\b", re.I)
PROCEDURE_REFS = set()  # reference files SKILL.md tells Claude to run or follow: no doc downgrade


def procedure_refs(skill_md_text, doc_paths=()):
    """Docs named on a SKILL.md line that also has a run-type verb, by path or by file name."""
    out = set()
    names = {}
    for p in doc_paths:
        names.setdefault(p.rsplit("/", 1)[-1], []).append(p)
    token_re = re.compile(r"(?<![\w./-])([\w.-]{1,200})(?![\w-])")  # each name-like token, looked up in a dict
    globs = set()
    carry = False  # a verb line ending in ':' covers the table or list right below it
    for line in skill_md_text.split("\n"):
        stripped = line.strip()
        if carry and not (stripped.startswith("|") or re.match(r"([-*+]|\d+[.)])\s", stripped) or not stripped):
            carry = False
        verb = RUN_VERB_RE.search(line) or re.search(r"\bfollow\b", line, re.I)
        if verb and stripped.endswith(":"):
            carry = True
        if verb or carry:
            out |= set(re.findall(r"references/[A-Za-z0-9_./-]+\.(?:md|markdown|mdx|txt)", line))
            # Plugin docs named through ${CLAUDE_PLUGIN_ROOT} use the scan's "<plugin>/..." labels.
            out |= {"<plugin>/" + x for x in re.findall(
                r"\$\{CLAUDE_PLUGIN_ROOT\}/([A-Za-z0-9_./-]+\.(?:md|markdown|mdx|txt))", line)}
            # Patterns name a family of docs: references/lang/<language>.md, references/*.md
            for pat in re.findall(r"[A-Za-z0-9_./-]{0,200}(?:<[^<>\s]{1,40}>|\*)[A-Za-z0-9_./<>*-]{0,200}\.(?:md|markdown|mdx|txt)",
                                  line[:20000]):
                if len(globs) < 200:  # deduplicated and capped; matched once below
                    globs.add(re.sub(r"<[^<>\s]{1,40}>", "*", pat))
            if names:
                for m in token_re.finditer(line[:20000]):
                    out |= set(names.get(m.group(1), ()))
    if globs and doc_paths:  # a glob matches the whole path or any tail after a '/'
        work = 0
        for p in doc_paths:
            work += len(globs) * (p.count("/") + 1)
            if work > 2_000_000:  # bounded: globs x paths; the rest are judged without the procedure exemption
                break
            tails = [p] + [p[i + 1:] for i, ch in enumerate(p) if ch == "/"]
            if any(C.glob_match(t, g) for g in globs for t in tails):
                out.add(p)
    return out


def scan_text(add, rel, text, code):
    """Run every text rule over one file's text. Linear in file size."""
    if re.search("\r(?!\n)", text):
        add("SEC-HID-6", "medium", "hidden-text", rel, None, rel,
            "lone carriage return: a terminal overwrites the start of the line with what follows")
    text = C.normalize_newlines(text)
    lines = text.split("\n")
    is_md = rel.endswith((".md", ".markdown", ".mdx"))
    is_skill_md = rel.rsplit("/", 1)[-1] == "SKILL.md"
    is_ref_doc = (is_md and not is_skill_md and (rel.startswith("references/") or "/references/" in rel and rel.startswith("<plugin>/")
                                                    or rel.startswith("<plugin>/skills/"))
                  and rel not in PROCEDURE_REFS)
    fenced = C.fenced_flags(lines)[0] if is_md else [False] * len(lines)
    nl = [i for i, ch in enumerate(text) if ch == "\n"]

    def line_of(off):
        return bisect.bisect_right(nl, off - 1) + 1 if off else 1
    # Values on the line after their key: hidden in the line list itself, so no rule's excerpt can show them.
    split = C.split_secrets(lines)
    for k_, h_ in split.items():
        lines[k_] = C.redact(lines[k_], h_)
    for ln, line in enumerate(lines, 1):
        if ln % 50 == 0 and _out_of_time(add, rel, ln, "hidden-character and secret"):
            break
        body = line[1:] if ln == 1 and line.startswith("\ufeff") else line
        for kind, rx in HIDDEN.items():
            hits = rx.findall(body)
            if hits and set(hits) <= {"\u200d", "\ufe0f"} and all(
                    (i > 0 and (C.EMOJI_RE.match(body[i - 1]) or body[i - 1] == "\ufe0f")) and
                    (ch == "\ufe0f" or (i + 1 < len(body) and C.EMOJI_RE.match(body[i + 1])))
                    or (ch == "\ufe0f" and i + 1 < len(body) and body[i + 1] == "\u20e3")  # keycap: 1<FE0F><20E3>
                    for i, ch in enumerate(body) if ch in "\u200d\ufe0f"):  # every joiner sits between emoji
                add("SEC-HID-1", "low", "hidden-text", rel, ln, line,
                    "zero-width joiner / variation selector inside an emoji sequence (normal emoji)")
                continue
            if hits:
                cps = ", ".join(sorted({"U+%04X" % ord(h) for h in hits}))
                # Only plain zero-width characters inside a code string may be intentional. Bidi controls
                # (Trojan Source), tag characters, and anything in SKILL.md are never downgraded.
                in_literal = (kind == "zero-width / filler" and code and not is_skill_md and
                              _all_inside_literal(body, (m_.start() for m_ in rx.finditer(body))))  # every one in a literal
                add("SEC-HID-1", "medium" if in_literal else "high", "hidden-text", rel, ln, line,
                    "{} characters ({}) {}".format(kind, cps, "inside a string or character class in code: "
                                                    "confirm it is intentional" if in_literal
                                                    else "can hide text from human reviewers"))
        vs = C.VARIATION_RE.findall(C.EMOJI_FE0F_RE.sub("", body))  # an FE0E/FE0F right after an emoji is normal
        supp = [c for c in vs if ord(c) >= 0xE0100]  # supplementary selectors: no emoji needs them
        if len(vs) >= 3:
            add("SEC-HID-3", "high", "hidden-text", rel, ln, line,
                "{} variation selectors in one line: a known way to smuggle hidden data".format(len(vs)))
        elif supp:
            add("SEC-HID-3", "medium", "hidden-text", rel, ln, line,
                "supplementary variation selector (U+E0100-E01EF): never needed for emoji; may smuggle data")
        elif vs:  # FE0E/FE0F right after an emoji were removed above, so any left are unattached
            add("SEC-HID-3", "low", "hidden-text", rel, ln, line, "variation selector not attached to an emoji")
        for _s, _e, rule, desc in split.get(ln - 1, [])[:1]:
            add(rule, "high", "secret", rel, ln, line, desc)
        by_rule, line_hits = {}, C.find_secrets(line)
        for s_, e_, rule, desc in line_hits:  # one finding per rule per line, with a hit count
            by_rule.setdefault(rule, [s_, e_, desc, 0])[3] += 1
        for rule, (s_, e_, desc, n) in by_rule.items():
            a_, b_ = max(0, s_ - 60), e_ + 80
            for hs, he, _, _ in line_hits:  # never cut another secret: widen to cover it, so excerpt() redacts it
                if hs < a_ < he:
                    a_ = hs
                if hs < b_ < he:
                    b_ = he
            piece = line[a_:b_]
            more = "" if n == 1 else " ({} hits on this line)".format(n)
            if rule in GENERIC_SECRET_RULES and is_md and not is_skill_md and \
                    (rel.startswith("references/") or rel.startswith("<plugin>/skills/")):
                add(rule, "medium", "secret", rel, ln, piece, desc + more + " in a reference doc (generic key "
                                                                         "name: likely an example value; confirm)")
            else:
                add(rule, "high", "secret", rel, ln, piece, desc + more)
        if BASE64_RE.search(line[:MAX_LINE_B64]):
            head_ = C.safe_cut(line, MAX_LINE_B64)  # redacted before the cut and before the blob shortening
            add("SEC-OBF-1", "medium", "obfuscation", rel, ln,
                BASE64_RE.sub(lambda b: b.group(0)[:12] + "...[blob]", head_),
                "long base64-like blob; decode and review it")
    for ln, logical, parts in logical_lines(lines, with_parts=True):
        if _out_of_time(add, rel, ln, "pattern"):  # every logical line: their start lines can skip any modulus
            break
        # Blank look-alikes (Braille blank, no-break and other Unicode spaces) read as spaces, one char for one, so
        # "Ignore<U+2800>all<U+2800>previous" still meets the phrase rules and every offset stays the same.
        window = logical[:MAX_LINE_RULES].translate(BLANKS)
        spans, hits_ = None, []  # secret spans on this line, found only when a rule matches
        facts = LineFacts(window)
        for rule, sev, cat, rx, desc in COMPILED:
            best = None  # judge every match on the line; the most severe classification wins, and the
            # excerpt starts at that match, so decoys anywhere around a real hit cannot lower it or hide it
            for m in rx.finditer(window):
                cand = classify(rule, sev, cat, desc, window, m, is_md and not fenced[ln - 1], is_skill_md, is_ref_doc,
                                rel in PROCEDURE_REFS, facts) + (m.start(),)
                if best is None or ORDER[cand[0]] < ORDER[best[0]]:
                    best = cand
                if best[0] == sev:
                    break
            if best:
                # Excerpt from just before the match, so the matched text is visible even on long lines. The cut
                # never splits a secret: both ends move out to cover any secret they would cut, so excerpt()
                # still recognizes and redacts it.
                if spans is None:
                    hits_ = secret_spans(logical, parts)
                    spans = [(a, b) for a, b, _, _ in hits_]
                start = 0 if best[2] < 60 else best[2] - 40
                end = start + 400
                for a, b in spans:
                    if a < start < b:
                        start = a
                    if a < end < b:
                        end = b
                piece = logical[start:end]
                inside = [(max(a, start) - start, min(b, end) - start, r, d_) for a, b, r, d_ in hits_
                          if a < end and b > start]
                if inside:  # redact here: excerpt() sees one joined line, where line anchors no longer hold
                    piece = C.redact(piece, inside)
                add(rule, best[0], cat, rel, ln, ("..." if start else "") + piece, best[1])
        if len(logical) > MAX_LINE_RULES:
            add("SEC-BIG-3", "medium", "coverage", rel, ln, logical,
                "line over {} chars; only its start was checked by the rules".format(MAX_LINE_RULES))
    # Download on one line, run on a later one (within 20 lines): "curl -o /tmp/i.sh URL" then "bash /tmp/i.sh".
    saved = []  # (line number, file name) of recent downloads
    for ln, line in enumerate(lines, 1):
        if ln % 50 == 0 and _out_of_time(add, rel, ln, "download-then-run"):
            break
        if len(line) > MAX_LINE_RULES:
            continue
        if saved and RUN_SAVED_RE.match(line):
            for dl_ln, name in saved:
                if ln - dl_ln <= 20 and name in line:
                    window = line
                    sev, desc = classify("SEC-RCE-5", "high", "remote-exec", "download saved to a file, then run on a "
                                         "later line (line {})".format(dl_ln), window, _Hit(0, len(window)),
                                         is_md and not fenced[ln - 1], is_skill_md, is_ref_doc, rel in PROCEDURE_REFS)
                    add("SEC-RCE-5", sev, "remote-exec", rel, ln, line, desc)
                    break
        if "curl" in line or "wget" in line:
            masked = mask_quotes(line)  # a quoted URL's '&' must not stop the look for -o; names come from line
            for name in save_targets(line, masked):
                if len(name) >= 3:
                    saved.append((ln, name))
            saved = saved[-20:]
    if rel.endswith((".md", ".markdown", ".mdx", ".html", ".htm")):
        tick_state = [0, 0, 0]  # line, column counted up to, backticks so far
        for off, content, closed in html_comments(text):
            content = content.strip()
            if is_md and fenced[line_of(off) - 1]:
                if content:
                    add("SEC-HID-2", "low", "hidden-text", rel, line_of(off), C.safe_cut(content, 200000),
                        "HTML comment inside a code block (shown as code; confirm the fence renders)")
                continue
            ln = line_of(off)
            ln_text = lines[ln - 1]
            col = off - (nl[ln - 2] + 1 if ln > 1 else 0)
            # Backticks before the comment on its line, counted incrementally (many comments on one long
            # line must not each recount the line).
            if tick_state[0] != ln or tick_state[1] > col:
                tick_state[:] = [ln, 0, 0]
            tick_state[2] += ln_text.count("`", tick_state[1], col)
            tick_state[1] = col
            if closed and tick_state[2] % 2 == 1:
                if content:
                    add("SEC-HID-2", "low", "hidden-text", rel, line_of(off), ln_text,
                        "HTML comment inside inline code (shown as code)")
                continue
            if content or not closed:
                add("SEC-HID-2", "medium", "hidden-text", rel, line_of(off), C.redact_text(content),
                    "HTML comment: invisible when rendered but read by the model" +
                    ("" if closed else " (UNCLOSED: hides the rest of the file)"))
        for m in LINKREF_COMMENT_RE.finditer(text):
            add("SEC-HID-2", "medium", "hidden-text", rel, line_of(m.start()),
                lines[line_of(m.start()) - 1], "Markdown link-reference comment: invisible when rendered")
        for m in CSS_HIDDEN_RE.finditer(text):
            add("SEC-HID-4", "low", "hidden-text", rel, line_of(m.start()),
                lines[line_of(m.start()) - 1], "content hidden or collapsed when rendered")


def scan_file(add, full, rel, vendored=False):
    """Read one regular file safely and scan it."""
    try:
        st = os.lstat(full)
        data, truncated = C.read_bytes(full, C.MAX_READ_CODE)
    except OSError as exc:
        add("SEC-READ-1", "low", "coverage", rel, None, str(exc), "could not read file")
        return
    enc, text = C.to_text(data, truncated)
    code = C.is_code(rel) or (bool(st.st_mode & 0o111) and (text or "").startswith("#!"))
    # Only a real code suffix makes it "code with a credential-type name"; scripts/.env stays a credential file
    if rel.endswith(C.CODE_SUFFIXES) and C.CREDENTIAL_FILE_RE.search(rel) and not C.is_credential_path(rel):
        add("SEC-PATH-4", "high" if re.search(r"(^|/)(id_(rsa|dsa|ecdsa|ed25519)|[^/]*\.(pem|key|p12|pfx))[^/]*$", rel)
            else "medium", "sensitive-path", rel, None, rel,
            "code file with a credential-type name: it is read and quoted as code; check it is not a renamed secret")
    if st.st_nlink > 1 and not vendored:
        add("SEC-LINK-2", "medium", "symlink", rel, None, "{} links".format(st.st_nlink),
            "hardlinked file: the same content may be shared with a file outside the skill; the Appendix quotes it "
            "with pattern redaction only, so check it before sharing")
    if text is None:
        sev = "medium" if code or rel.startswith("scripts/") or rel.endswith((".so", ".dll", ".dylib", ".exe", ".bin")) \
            else "low"
        add("SEC-BIN-1", sev, "opaque-binary", rel, None, rel, "binary content cannot be reviewed as text")
        return
    if enc == "nul-text":
        add("SEC-HID-5", "medium", "hidden-text", rel, None, rel,
            "text file containing NUL bytes: many tools treat it as binary and skip it")
    elif enc == "utf-16":
        add("SEC-ENC-1", "low", "coverage", rel, None, rel, "UTF-16 text: decoded and scanned; grep-based tools miss it")
    if truncated:
        add("SEC-BIG-1", "high" if code else "low", "coverage", rel, None, rel,
            "only the first {} bytes were scanned".format(C.MAX_READ_CODE))
    scan_text(add, rel, text, code)


WORKER_KEEP = 2000  # hits of one rule in one file sent from the worker; the rest are counted
FILE_SECONDS = 20  # hard limit for one file: a pattern that runs away is killed, not waited on


class FileRunner:
    """Scan files in a forked worker, so one file that runs too long is killed (SEC-BIG-5), not waited on.

    The worker records each add() call; the parent replays them, so caps and ordering stay the same. Where fork
    is unavailable (Windows), files are scanned in this process with only the per-line time checks.
    """

    def __init__(self):
        self.proc = self.conn = None
        try:
            import multiprocessing
            self.ctx = multiprocessing.get_context("fork") if hasattr(os, "fork") else None
        except (ImportError, ValueError):
            self.ctx = None

    def _start(self):
        parent, child = self.ctx.Pipe()
        self.proc = self.ctx.Process(target=self._worker, args=(child,), daemon=True)
        self.proc.start()
        child.close()
        self.conn = parent

    @staticmethod
    def _worker(conn):
        while True:
            try:
                task = conn.recv()
            except EOFError:
                return
            if task is None:
                return
            calls, seen, over = [], {}, {}

            def rec(rule, sev, cat, rel, ln, text, desc):
                # Excerpts are built here, and past WORKER_KEEP hits of one rule in one file only a count is sent
                # (a flood of hits costs the parent nothing).
                n = seen[(rule, rel)] = seen.get((rule, rel), 0) + 1
                if n <= WORKER_KEEP:
                    calls.append((rule, sev, cat, rel, ln, C.excerpt(text), desc))
                else:
                    over[(rule, sev, cat, rel)] = over.get((rule, sev, cat, rel), 0) + 1
            scan_deadline = _DEADLINE[0]
            if task[1] == "SKILL.md":  # SKILL.md always gets a full file budget, even when the scan's is spent
                _DEADLINE[0] = max(scan_deadline, time.monotonic() + FILE_SECONDS)
            try:
                scan_file(rec, *task)
            except Exception as exc:  # report, never kill the scan
                calls.append(("SEC-READ-1", "low", "coverage", task[1], None, repr(exc)[:200], "scan error in this file"))
            finally:
                _DEADLINE[0] = scan_deadline  # the extension is for SKILL.md only
            calls += [("__COUNT__",) + k + (n,) for k, n in over.items()]
            conn.send(calls)

    def run(self, add, full, rel, vendored=False, limit=FILE_SECONDS, count=None):
        if self.ctx is None:
            return scan_file(add, full, rel, vendored)
        if self.proc is None or not self.proc.is_alive():
            self._start()
        try:
            self.conn.send((full, rel, vendored))
        except (BrokenPipeError, OSError):  # the worker died between the liveness check and the send: restart once
            self._start()
            self.conn.send((full, rel, vendored))
        if self.conn.poll(max(1.0, limit)):
            try:
                for a in self.conn.recv():
                    if a[0] == "__COUNT__":
                        if count:
                            count(*a[1:])
                    else:
                        add(*a)
                return
            except (EOFError, OSError):
                crashed = True
            else:
                crashed = False
        else:
            crashed = not self.proc.is_alive()
        if crashed:
            self.proc.join(1)
            self.proc = None
            add("SEC-BIG-5", "high", "coverage", rel, None, rel, "the scan worker stopped while scanning this file "
                "(out of memory or a crash): review the file by hand")
            return
        self.proc.kill()
        self.proc.join(5)
        self.proc = None
        add("SEC-BIG-5", "high", "coverage", rel, None, rel, "scanning this file took over {:.0f} s and was stopped; "
            "a pattern may have run away on it: review the file by hand".format(max(1.0, limit)))

    def close(self):
        if self.proc is not None and self.proc.is_alive():
            try:
                self.conn.send(None)
            except OSError:
                pass
            self.proc.join(2)
            if self.proc.is_alive():
                self.proc.kill()


def scan(target):
    skill_dir, _ = C.resolve_target(target)
    raw, per_raw, dropped, counts_extra, rule_cats = [], {}, {}, {}, {}

    def add(rule, sev, cat, rel, ln, text, desc):
        rule_cats[rule] = cat
        if C.is_credential_path(rel):  # never show lines of credential files
            text = "[excerpt withheld: credential file]"
        key = (rule, rel)
        per_raw[key] = per_raw.get(key, 0) + 1
        cap = MAX_RAW_KEEP_LOCATIONS if cat in KEEP_LOCATIONS else MAX_RAW_PER_RULE_FILE
        if per_raw[key] > cap and sev != "high":  # bound work
            dropped[key] = dropped.get(key, 0) + 1
            counts_extra[sev] = counts_extra.get(sev, 0) + 1
            return
        if C.in_skipped_dir(rel):
            desc += " [in vendored dir]"
        raw.append({"rule": rule, "severity": sev, "category": cat, "file": rel, "line": ln,
                    "description": desc, "excerpt": C.excerpt(text)})

    entries = C.walk(skill_dir, include_skipped=True)
    # SKILL.md first: it is the file that must never be starved by the time budget
    entries.sort(key=lambda e: e["path"] != "SKILL.md")
    vendored_counts = {}
    PROCEDURE_REFS.clear()
    docs = [e["path"] for e in entries if e["kind"] == "file" and e["path"] != "SKILL.md"
            and e["path"].endswith((".md", ".markdown", ".mdx", ".txt")) and not C.in_skipped_dir(e["path"])]
    deadline = time.monotonic() + SCAN_SECONDS  # bounds the scan work; the folder walk above has its own caps
    _DEADLINE[0] = deadline
    try:
        PROCEDURE_REFS.update(procedure_refs(C.decode(C.read_bytes(os.path.join(skill_dir, "SKILL.md"))[0]), docs))
    except OSError:
        pass
    scanned_bytes, over_budget, over_time = 0, [], []
    def count(rule, sev, cat, rel, n):  # hits the worker only counted
        rule_cats[rule] = cat
        per_raw[(rule, rel)] = per_raw.get((rule, rel), 0) + n
        dropped[(rule, rel)] = dropped.get((rule, rel), 0) + n
        counts_extra[sev] = counts_extra.get(sev, 0) + n
    runner = FileRunner()  # forked after PROCEDURE_REFS and the deadline are set, so the worker shares them

    def file_limit():  # never past the scan budget, but SKILL.md (scanned even late) gets the full file limit
        # 3 s of grace past the budget, so the worker's own in-file check stops it first and its findings so far
        # come back (only a file stuck inside one pattern is killed)
        return min(FILE_SECONDS, max(FILE_SECONDS if time.monotonic() > deadline else 1.0, deadline - time.monotonic() + 3))
    for e in entries:
        rel = e["path"]
        if e["kind"] == "skipped-dir":  # only .git reaches here
            add("SEC-GIT-1", "low", "vcs", rel, None, "{} files".format(e["file_count"]),
                ".git directory present; not scanned (check .git/hooks if the skill is a cloned repo)")
        elif e["kind"] in ("symlink", "dir-symlink"):
            add("SEC-LINK-1", "high" if e["points_outside"] else "low", "symlink", rel, None,
                "-> " + e["symlink_target"],
                "{} symlink{}".format("directory" if e["kind"] == "dir-symlink" else "file",
                                      " pointing OUTSIDE the skill; never read through it" if e["points_outside"] else ""))
        elif e["kind"] in ("unreadable", "unreadable-dir"):
            add("SEC-READ-1", "medium", "coverage", rel, None, e.get("error", ""),
                "unreadable {}; its contents were not scanned".format("directory" if e["kind"].endswith("dir") else "file"))
        elif e["kind"] == "special":
            add("SEC-SPEC-1", "medium", "special-file", rel, None, rel, "FIFO/device/socket in a skill; not read")
        else:
            vend = next((p for p in rel.split("/")[:-1] if p in C.SKIP_DIRS), None)
            if vend:
                top = rel.split(vend + "/", 1)[0] + vend
                vendored_counts[top] = vendored_counts.get(top, 0) + 1
                if vendored_counts[top] > C.MAX_VENDORED_FILES:
                    continue
            try:
                size = os.lstat(os.path.join(skill_dir, rel)).st_size
            except OSError:
                size = 0
            if scanned_bytes + min(size, C.MAX_READ_CODE) > C.MAX_TOTAL_SCAN:
                over_budget.append(rel)
                continue
            if rel != "SKILL.md" and time.monotonic() > deadline:  # output must arrive before a tool timeout
                over_time.append(rel)
                continue
            scanned_bytes += min(size, C.MAX_READ_CODE)
            runner.run(add, os.path.join(skill_dir, rel), rel, bool(vend), file_limit(), count)
    for top, n in vendored_counts.items():
        if n > C.MAX_VENDORED_FILES:
            add("SEC-BIG-2", "medium", "coverage", top + "/", None, top,
                "vendored dir has {} files; only the first {} were scanned".format(n, C.MAX_VENDORED_FILES))

    # Plugin-level files the skill depends on (and plugin hooks / MCP servers).
    plugin = C.plugin_context(skill_dir, [e for e in entries if not C.in_skipped_dir(e["path"])])
    if plugin and plugin["root"]:
        for pf in plugin["files"]:
            label = "<plugin>/" + pf["path"]
            full = os.path.join(plugin["root"], pf["path"])
            if pf["kind"] == "file":
                try:
                    size = min(os.lstat(full).st_size, C.MAX_READ_CODE)
                except OSError:
                    size = 0
                if scanned_bytes + size > C.MAX_TOTAL_SCAN:  # plugin files share the scan budget
                    over_budget.append(label)
                    continue
                if time.monotonic() > deadline:
                    over_time.append(label)
                    continue
                scanned_bytes += size
                runner.run(add, full, label, False, file_limit(), count)
            elif pf["kind"] == "symlink":
                target_real = os.path.realpath(full)
                outside = not C.inside(target_real, plugin["root"])
                add("SEC-LINK-1", "high" if outside else "low", "symlink", label, None, "-> " + os.readlink(full),
                    "plugin file symlink" + (" pointing OUTSIDE the plugin" if outside else "") +
                    "; not followed, so any hook or MCP commands behind it were not read")
        for cmd in plugin["hook_commands"]:
            add("SEC-HOOK-2", "high", "code-exec", "<plugin>/hooks", None, cmd,
                "plugin hook command: runs on matching events whenever the plugin is enabled")
        for cmd in plugin["mcp_commands"]:
            if cmd.startswith("REMOTE "):
                add("SEC-MCP-2", "medium", "network", "<plugin>/.mcp.json", None, cmd[7:],
                    "remote MCP server: tool calls and their data go to this URL whenever the plugin is enabled")
            else:
                add("SEC-MCP-1", "medium", "code-exec", "<plugin>/.mcp.json", None, cmd,
                    "plugin MCP server command: starts a process whenever the plugin is enabled")
        for cmd in plugin.get("other_commands", []):
            add("SEC-MCP-1", "medium", "code-exec", "<plugin>/plugin.json", None, cmd,
                "plugin-declared command (not a hook or MCP server): starts a process when the plugin uses it")
    if over_time:
        add("SEC-BIG-5", "high", "coverage", over_time[0], None, "{} files".format(len(over_time)),
            "scan time budget ({} s) reached; {} files were not scanned, starting here (listed in suppressed): "
            "cover them by hand".format(SCAN_SECONDS, len(over_time)))
        for rel_ in over_time[1:]:
            add("SEC-BIG-5", "high", "coverage", rel_, None, rel_, "not scanned: time budget reached")
    if over_budget:
        add("SEC-BIG-4", "medium", "coverage", over_budget[0], None, "{} files".format(len(over_budget)),
            "scan budget ({} MB) reached; {} files were not scanned, starting here: cover them by hand".format(
                C.MAX_TOTAL_SCAN // (1024 * 1024), len(over_budget)))

    skill_md = os.path.join(skill_dir, "SKILL.md")
    try:
        raw_md, _ = C.read_bytes(skill_md)
    except OSError:
        raw_md = b""
    try:  # a frontmatter the auditor cannot handle costs this part only, never the whole scan
        status, fm = C.frontmatter_for_audit(C.decode(raw_md))  # broken YAML still audited for intent
        if status == "ok":
            for cmd in C.hook_commands(fm.get("hooks")):
                add("SEC-HOOK-1", "high", "code-exec", "SKILL.md", C.frontmatter_line(C.decode(raw_md), "hooks"), cmd,
                    "frontmatter hook command: runs on invocation, before or around any model judgment")
            if fm.get("hooks") and not C.hook_commands(fm.get("hooks")):
                add("SEC-HOOK-1", "medium", "code-exec", "SKILL.md", None, "hooks: ...",
                    "frontmatter hooks present but no command parsed; read the block by hand")
            tools = C.parse_tools(fm.get("allowed-tools"))
            tl = C.frontmatter_line(C.decode(raw_md), "allowed-tools")
            for tool, sev, reason in C.risky_tools(tools):
                add("SEC-TOOL-1", sev, "permissions", "SKILL.md", tl, "allowed-tools: " + tool, reason)
            net = [t for t in tools if t.startswith(("WebFetch", "WebSearch")) or
                   re.match(r"^mcp__[\w-]*(chrome|browser|playwright|puppeteer|fetch|http|web)[\w-]*(__|$)", t, re.I)]
            shell = [t for t in tools if t.startswith("Bash")]
            if net and shell:
                add("SEC-TOOL-2", "high" if any("*" in t for t in net + shell) else "medium", "permissions", "SKILL.md", tl,
                    "allowed-tools: " + " ".join(net + shell),
                    "pre-approves network access (web tools or a browser MCP) and shell together: a page or result can "
                    "steer reads and send data out with no prompt")

    except Exception as exc:
        add("SEC-READ-1", "medium", "coverage", "SKILL.md", None, type(exc).__name__,
            "frontmatter not audited (hooks and allowed-tools): the auditor failed on it; read it by hand")

    # Severity first, then cap per (rule, file) so decoys cannot push real hits out.
    order = {"high": 0, "medium": 1, "low": 2}
    raw.sort(key=lambda f: (order[f["severity"]], f["file"] != "SKILL.md", f["file"], f["line"] or 0, f["rule"]))
    findings, per, per_rule, suppressed = [], {}, {}, {}
    for f in raw:
        key = (f["rule"], f["file"])
        per[key] = per.get(key, 0) + 1
        per_rule[f["rule"]] = per_rule.get(f["rule"], 0) + 1
        if per[key] > MAX_PER_RULE or per_rule[f["rule"]] > MAX_PER_RULE_TOTAL:  # bounded output, so paging ends
            suppressed.setdefault(f["rule"], []).append("{}:{} ({})".format(f["file"], f["line"] or "-", f["severity"]))
        else:
            findings.append(f)
    counts = {"high": 0, "medium": 0, "low": 0}
    for f in raw:
        counts[f["severity"]] += 1
    for sev, n in counts_extra.items():
        counts[sev] += n
    extra_by_rule = {}  # counts kept as numbers: a file name can never be mistaken for one
    for (rule, rel), n in dropped.items():
        suppressed.setdefault(rule, []).append("{}: +{} more hits not located".format(rel, n))
        extra_by_rule[rule] = extra_by_rule.get(rule, 0) + n
    # Bounded: per rule, the hit count, severities, and the first 20 locations (highs first).
    sup_out = {}
    for k, v in suppressed.items():
        located = len(v) - sum(1 for (rule, _rel) in dropped if rule == k)
        extra = extra_by_rule.get(k, 0)
        rule_cat = rule_cats.get(k, "")
        keep = 200 if rule_cat in KEEP_LOCATIONS else 20
        sup_out[k] = {"count": located + extra, "locations": v[:keep]}
    runner.close()
    return {"skill_dir": skill_dir, "findings": findings, "counts": counts,
            "suppressed": sup_out, "not_covered": NOT_COVERED}


def to_markdown(res, level=2):
    c = res["counts"]
    out = [C.heading(level, "Security scan"), "", "High: {high} - Medium: {medium} - Low: {low}".format(**c), ""]
    if res["findings"]:
        out += ["| Sev | Rule | Location | Finding | Excerpt |", "|---|---|---|---|---|"]
        for f in res["findings"]:
            loc = C.safe_name(f["file"]) + (":{}".format(f["line"]) if f["line"] else "")
            ex = f["excerpt"].replace("|", "\\|").replace("`", "'")
            out.append("| {} | {} | `{}` | {} | `{}` |".format(f["severity"], f["rule"], loc, f["description"], ex))
    else:
        out.append("No pattern matches.")
    if res.get("suppressed"):
        out += ["", "More hits not listed (cap {} per rule and file):".format(MAX_PER_RULE), ""]
        out += ["- {} ({} more): {}".format(k, v["count"], ", ".join("`{}`".format(C.safe_name(x)) for x in v["locations"]) +
                                            (" ..." if v["count"] > len(v["locations"]) else ""))
                for k, v in sorted(res["suppressed"].items())]
    if "not_covered" in res:  # first page only when paging
        out += ["", "Not covered by this scan (check by hand):", ""] + ["- " + n for n in res["not_covered"]]
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
    print(json.dumps(res, indent=2) if args.format == "json" else to_markdown(res, args.heading_level))
    return 0


if __name__ == "__main__":
    sys.exit(main())
