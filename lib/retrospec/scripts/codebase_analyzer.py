#!/usr/bin/env python3
"""Analyze any codebase (frontend, backend, or fullstack) and extract routes, APIs, models, and structure.

Route extraction: React Router, Next.js, Nuxt, SvelteKit, Remix, Astro, Express, NestJS,
Django / DRF. Framework detection also covers Vue, Angular, Svelte, FastAPI, and Flask.
Stdlib only — no third-party dependencies. Outputs JSON for downstream PRD generation.

Output is a set of leads, not ground truth: extraction is regex-based, so always
confirm routes, APIs, and models against source before documenting them.

Usage:
    python3 codebase_analyzer.py /path/to/project
    python3 codebase_analyzer.py /path/to/project --output prd-analysis.json
    python3 codebase_analyzer.py /path/to/project --format markdown
"""

import argparse
import json
import os
import re
import sys
from collections import defaultdict
from pathlib import Path
from typing import Any, Dict, List, Optional, Set, Tuple

IGNORED_DIRS = {
    ".git", "node_modules", ".next", "dist", "build", "coverage",
    "venv", ".venv", "__pycache__", ".nuxt", ".output", ".cache",
    ".turbo", ".vercel", "out", "storybook-static",
    ".tox", ".mypy_cache", ".pytest_cache", "htmlcov", "staticfiles",
    "media", "migrations",
}

# Test code describes routes but doesn't define them — skip it entirely
TEST_DIRS = {"test", "tests", "__tests__", "e2e", "spec", "specs", "cypress", "playwright"}
TEST_FILE_RE = re.compile(
    r"[._-](?:test|spec|e2e)\.[cm]?[jt]sx?$|^test_.*\.py$|_test\.py$|^conftest\.py$"
)

FRAMEWORK_SIGNALS = {
    "react": ["react", "react-dom"],
    "next": ["next"],
    "vue": ["vue"],
    "nuxt": ["nuxt"],
    "angular": ["@angular/core"],
    "svelte": ["svelte"],
    "sveltekit": ["@sveltejs/kit"],
    "solid": ["solid-js"],
    "astro": ["astro"],
    "remix": ["@remix-run/react"],
    "nestjs": ["@nestjs/core"],
    "express": ["express"],
    "fastify": ["fastify"],
}

FRONTEND_FRAMEWORKS = {"react", "next", "vue", "nuxt", "angular", "svelte", "sveltekit",
                       "solid", "astro", "remix"}
BACKEND_FRAMEWORKS = {"django", "fastapi", "flask", "nestjs", "express", "fastify"}

ROUTE_DIR_PATTERNS = [
    "pages", "views", "routes", "app",
    "src/pages", "src/views", "src/routes", "src/app",
]

API_DIR_PATTERNS = [
    "api", "services", "requests", "endpoints", "client",
    "src/api", "src/services", "src/requests",
]

STATE_DIR_PATTERNS = [
    "store", "stores", "models", "context", "state",
    "src/store", "src/stores", "src/models", "src/context",
]

STATE_DEPS = {"redux", "@reduxjs/toolkit", "zustand", "mobx", "recoil", "jotai",
              "vuex", "pinia", "@ngrx/store", "xstate", "valtio"}

I18N_DIR_PATTERNS = [
    "locales", "i18n", "lang", "translations", "messages",
    "src/locales", "src/i18n", "src/lang",
]

# Backend-specific directory patterns
CONTROLLER_DIR_PATTERNS = [
    "controllers", "src/controllers", "src/modules",
]

MODEL_DIR_PATTERNS = [
    "models", "entities", "src/entities", "src/models",
]

DTO_DIR_PATTERNS = [
    "dto", "dtos", "src/dto", "serializers",
]

# Server-rendered template files (Express views, Django templates)
VIEW_EXTENSIONS = {".ejs", ".pug", ".hbs", ".handlebars", ".njk", ".mustache", ".html"}

# Mock signals are checked within MOCK_WINDOW_LINES of each call, not file-wide,
# so one helper returning fake data doesn't mark every real call in the file
MOCK_SIGNALS = [
    r"setTimeout\s*\(.*\breturn\b",
    r"mockData",
    r"mock[A-Z]",
    r"faker\.",
    r"fixtures?/",
]
MOCK_WINDOW_LINES = 8
MOCK_PATH_RE = re.compile(r"\.mock\.|__mocks__|(?:^|/)(?:mocks?|fixtures?)/")

REAL_API_SIGNALS = [
    r"\baxios\b",
    r"\bfetch\s*\(",
    r"httpGet|httpPost|httpPut|httpDelete|httpPatch",
    r"\.(?:get|post|put|delete|del|patch)\s*\(\s*['\"`/]",
    r"useSWR|useQuery|useMutation",
    r"\$http\.",
    r"this\.http\.",
    r"XMLHttpRequest",
]

HTTP_METHOD_NAMES = {"GET", "POST", "PUT", "PATCH", "DELETE", "HEAD", "OPTIONS"}
PAGE_FILE_EXTENSIONS = {".tsx", ".jsx", ".ts", ".js", ".mdx", ".md"}
EXPORTED_METHOD_RE = re.compile(
    r"export\s+(?:async\s+)?(?:function\s+|const\s+|let\s+)(GET|POST|PUT|PATCH|DELETE|HEAD|OPTIONS)\b"
)
REQ_METHOD_RE = re.compile(
    r"\b(?:req|request)\.method\s*={2,3}\s*['\"](\w+)['\"]|\bcase\s+['\"](GET|POST|PUT|PATCH|DELETE)['\"]"
)
HAS_DEFAULT_EXPORT_RE = re.compile(r"export\s+default\b")
REMIX_EXPORT_RE = re.compile(r"export\s+(?:async\s+)?(?:function\s+|const\s+)(loader|action)\b")
JS_EXTENSIONS = {".ts", ".tsx", ".js", ".jsx", ".mjs", ".cjs", ".vue", ".svelte", ".astro"}
COMPONENT_EXTENSIONS = {".tsx", ".jsx", ".vue", ".svelte", ".astro"}
CODE_EXTENSIONS = JS_EXTENSIONS | {".py"}
MODULE_SUFFIXES = (".js", ".mjs", ".cjs", ".ts", ".jsx", ".tsx")



def path_literal(group: int) -> str:
    """Regex for a quoted URL path whose opening quote is capture group `group`.

    The host of an absolute URL is dropped; the path itself is capture group `group + 1`.
    """
    return rf"(['\"`])(?:https?://[^/'\"`]+)?(/(?:\\.|(?!\{group}).)*?)\{group}"

# React Router / Vue Router / Angular route config
ROUTE_ELEMENT_RE = re.compile(r"<Route\b[^>]*?\bpath\s*=\s*\{?\s*([\"'])([^\"']+)\1")
ROUTE_CONFIG_RE = re.compile(r"\bpath\s*:\s*([\"'])([^\"']*)\1")

# Client-side API calls
CLIENT_VERB_RE = re.compile(  # receiver=1, verb=2, paren=3, path=5
    r"\b([\w$]+)\.(get|post|put|patch|delete|del)\s*(?:<[^>()]*>)?\s*(\()\s*" + path_literal(4)
)
FETCH_RE = re.compile(r"\bfetch\s*(\()\s*" + path_literal(2))  # paren=1, path=3
XHR_RE = re.compile(r"\.open\s*(\()\s*['\"](\w+)['\"]\s*,\s*" + path_literal(3))  # paren=1, method=2, path=4
URL_PROP_RE = re.compile(r"\b(?:url|endpoint)\s*:\s*" + path_literal(1))  # path=2
METHOD_PROP_RE = re.compile(r"\bmethod\s*:\s*['\"`](\w+)['\"`]")

# Express / Fastify
EXPRESS_VERBS = "get|post|put|delete|patch|all|options|head"
EXPRESS_ROUTE_RE = re.compile(r"\b([\w$]+)\.(" + EXPRESS_VERBS + r")\s*(\()\s*(['\"`])((?:\\.|(?!\4).)*?)\4")
USE_RE = re.compile(r"\b([\w$]+)\.use\s*(\()")
SERVER_INSTANCE_RE = re.compile(
    r"(?:const|let|var)\s+([\w$]+)\s*=\s*(?:new\s+)?(?:express\s*\(|express\.Router\s*\(|Router\s*\(|fastify\s*\()"
)
NON_PAGE_WORDS = {"download", "export", "file", "files", "raw", "zip", "csv", "json", "xml",
                  "rss", "feed", "sitemap", "health", "logout", "thumb", "thumbnail"}
RENDER_RE = re.compile(r"\.render\s*\(\s*['\"`]([^'\"`]+)['\"`]")
NON_PAGE_RESPONSE_RE = re.compile(r"\.(?:json|send|sendFile|download|redirect|attachment|end|sendStatus|pipe)\s*\(")
PATH_CONSTANT_RE = re.compile(r"(?:const|let|var)\s+([A-Z][A-Z0-9_]*)\s*=\s*['\"`](/[^'\"`]*)['\"`]")

# JS module imports — map local names to module specifiers
IMPORT_DEFAULT_RE = re.compile(r"import\s+([\w$]+)\s*(?:,\s*\{[^}]*\})?\s*from\s*['\"]([^'\"]+)['\"]")
IMPORT_NAMED_RE = re.compile(r"import\s*\{([^}]*)\}\s*from\s*['\"]([^'\"]+)['\"]")
REQUIRE_DEFAULT_RE = re.compile(r"(?:const|let|var)\s+([\w$]+)\s*=\s*require\s*\(\s*['\"]([^'\"]+)['\"]\s*\)")
REQUIRE_NAMED_RE = re.compile(r"(?:const|let|var)\s*\{([^}]*)\}\s*=\s*require\s*\(\s*['\"]([^'\"]+)['\"]\s*\)")
FACTORY_ALIAS_RE = re.compile(r"(?:const|let|var)\s+([\w$]+)\s*=\s*([\w$]+)\s*\(")

# NestJS decorators
NEST_CONTROLLER_RE = re.compile(
    r"@Controller\s*\(\s*(?:['\"`]([^'\"`]*)['\"`]|\{[^}]*?\bpath\s*:\s*['\"`]([^'\"`]*)['\"`])?"
)
NEST_GLOBAL_PREFIX_RE = re.compile(r"setGlobalPrefix\s*\(\s*['\"`]([^'\"`]+)['\"`]")
NEST_METHOD_RE = re.compile(r"@(Get|Post|Put|Delete|Patch|Head|Options|All)\s*\(\s*(?:['\"`]([^'\"`]*)['\"`])?\s*\)")

# NestJS entity/DTO patterns
NEST_MODEL_PATTERNS = [
    r"@Entity\s*\(.*?\)\s*(?:export\s+)?class\s+(\w+)",
    r"class\s+(\w+(?:Dto|DTO|Entity|Schema))\b",
]

# Django URL config
DJANGO_URL_CALL_RE = re.compile(r"(?<![\w.])(url|re_path|path)\s*(\()")
DJANGO_REGISTER_RE = re.compile(r"([\w]+)\.register\s*\(\s*[rRuU]?['\"]([^'\"]*)['\"]\s*,\s*([\w.]+)")
DJANGO_ROUTER_URLS_RE = re.compile(r"urlpatterns\s*\+?=\s*([\w]+)\.urls")
PY_CLASS_RE = re.compile(r"^([ \t]*)class\s+(\w+)\s*(?:\(([^)]*)\))?\s*:", re.M)
PY_DEF_RE = re.compile(r"^[ \t]+def\s+(\w+)\s*\(", re.M)
API_VIEW_DECORATOR_RE = re.compile(r"@api_view\s*\(\s*\[([^\]]*)\]\s*\)\s*(?:@[^\n]*\n\s*)*def\s+(\w+)")

HTTP_METHODS = ("get", "post", "put", "patch", "delete")

# DRF / Django generic class-based views → HTTP methods they serve
GENERIC_VIEW_METHODS = {
    "ListAPIView": ["GET"],
    "CreateAPIView": ["POST"],
    "RetrieveAPIView": ["GET"],
    "DestroyAPIView": ["DELETE"],
    "UpdateAPIView": ["PUT", "PATCH"],
    "ListCreateAPIView": ["GET", "POST"],
    "RetrieveUpdateAPIView": ["GET", "PUT", "PATCH"],
    "RetrieveDestroyAPIView": ["GET", "DELETE"],
    "RetrieveUpdateDestroyAPIView": ["GET", "PUT", "PATCH", "DELETE"],
    "ListView": ["GET"],
    "DetailView": ["GET"],
    "TemplateView": ["GET"],
    "RedirectView": ["GET"],
    "FormView": ["GET", "POST"],
    "CreateView": ["GET", "POST"],
    "UpdateView": ["GET", "POST"],
    "DeleteView": ["GET", "POST"],
}

# DRF viewset actions: name → (collection|detail, HTTP method)
VIEWSET_ACTIONS = {
    "list": ("collection", "GET"),
    "create": ("collection", "POST"),
    "retrieve": ("detail", "GET"),
    "update": ("detail", "PUT"),
    "partial_update": ("detail", "PATCH"),
    "destroy": ("detail", "DELETE"),
}
VIEWSET_BASE_ACTIONS = {
    "ListModelMixin": ["list"],
    "CreateModelMixin": ["create"],
    "RetrieveModelMixin": ["retrieve"],
    "UpdateModelMixin": ["update", "partial_update"],
    "DestroyModelMixin": ["destroy"],
    "ModelViewSet": ["list", "create", "retrieve", "update", "partial_update", "destroy"],
    "ReadOnlyModelViewSet": ["list", "retrieve"],
}

DJANGO_MODEL_ROOTS = {"Model", "AbstractUser", "AbstractBaseUser"}


# ---------------------------------------------------------------------------
# Source reading helpers
# ---------------------------------------------------------------------------

_JS_TOKEN_RE = re.compile(
    r"'(?:\\.|[^'\\\n])*'|\"(?:\\.|[^\"\\\n])*\"|`(?:\\.|[^`\\])*`|//[^\n]*|/\*.*?\*/", re.S
)
_PY_TOKEN_RE = re.compile(
    r'"""(?:\\.|[^\\])*?"""|\'\'\'(?:\\.|[^\\])*?\'\'\'|\'(?:\\.|[^\'\\\n])*\'|"(?:\\.|[^"\\\n])*"|#[^\n]*',
    re.S,
)


def _blank(text: str) -> str:
    """Replace everything but newlines with spaces, so line numbers survive."""
    return re.sub(r"[^\n]", " ", text)


def strip_comments(content: str, suffix: str) -> str:
    """Blank out comments (and Python docstrings) while keeping string literals."""
    if suffix == ".py":
        return _PY_TOKEN_RE.sub(
            lambda m: _blank(m.group(0)) if m.group(0).startswith(("#", '"""', "'''")) else m.group(0),
            content,
        )
    if suffix in {".vue", ".svelte", ".astro"}:
        content = re.sub(r"<!--.*?-->", lambda m: _blank(m.group(0)), content, flags=re.S)
    if suffix in JS_EXTENSIONS:
        return _JS_TOKEN_RE.sub(
            lambda m: _blank(m.group(0)) if m.group(0).startswith(("//", "/*")) else m.group(0),
            content,
        )
    return content


def balanced(content: str, open_idx: int) -> str:
    """Return the text inside the bracket at open_idx up to its matching close."""
    depth = 0
    quote = None
    i = open_idx
    while i < len(content):
        c = content[i]
        if quote:
            if c == "\\":
                i += 2
                continue
            if c == quote:
                quote = None
        elif c in "'\"`":
            quote = c
        elif c in "([{":
            depth += 1
        elif c in ")]}":
            depth -= 1
            if depth == 0:
                return content[open_idx + 1:i]
        i += 1
    return content[open_idx + 1:]


def split_args(args: str, sep: str = ",") -> List[str]:
    """Split call arguments (or a `+` concatenation) on a top-level separator."""
    parts, depth, quote, start, i = [], 0, None, 0, 0
    while i < len(args):
        c = args[i]
        if quote:
            if c == "\\":
                i += 2
                continue
            if c == quote:
                quote = None
        elif c in "'\"`":
            quote = c
        elif c in "([{":
            depth += 1
        elif c in ")]}":
            depth -= 1
        elif c == sep and depth == 0:
            parts.append(args[start:i].strip())
            start = i + 1
        i += 1
    tail = args[start:].strip()
    if tail:
        parts.append(tail)
    return parts


def string_literal(arg: str) -> Optional[str]:
    """Return the body of a lone string literal argument, else None."""
    m = re.fullmatch(r"\s*[rRuUbB]{0,2}(['\"`])(.*)\1\s*", arg, re.S)
    return m.group(2) if m else None


def concat_literal(arg: str) -> Optional[str]:
    """`"/a/" + id + "/b"` → `/a/${id}/b`; None unless the first piece is a string literal."""
    pieces = split_args(arg, "+")
    if not pieces or string_literal(pieces[0]) is None:
        return None
    out = ""
    for piece in pieces:
        lit = string_literal(piece)
        out += lit if lit is not None else "${" + piece + "}"
    return out


def _last_ident(expr: str) -> str:
    names = re.findall(r"[A-Za-z_$][\w$]*", expr)
    return names[-1] if names else "param"


def normalize_path(path: str, constants: Optional[Dict[str, str]] = None) -> str:
    """Resolve ${...} segments, drop query strings, and normalize slashes."""
    constants = constants or {}

    def sub(m):
        expr = m.group(1).strip()
        if expr in constants:
            return constants[expr]
        needs_slash = m.start() > 0 and m.string[m.start() - 1] != "/"
        return ("/" if needs_slash else "") + ":" + _last_ident(expr)

    path = re.sub(r"\$\{([^}]*)\}", sub, path)
    path = path.split("?")[0].split("#")[0]
    if not path.startswith("/"):
        path = "/" + path
    path = re.sub(r"/{2,}", "/", path)
    if len(path) > 1:
        path = path.rstrip("/")
    return path


def line_of(content: str, idx: int) -> int:
    return content.count("\n", 0, idx) + 1


# ---------------------------------------------------------------------------
# Project inventory
# ---------------------------------------------------------------------------

def detect_framework(project_root: Path) -> Dict[str, Any]:
    """Detect framework from package.json (Node.js) or project files (Python)."""
    detected = []
    all_deps = {}
    pkg_name = ""
    pkg_version = ""

    # Node.js detection via package.json
    pkg_path = project_root / "package.json"
    if pkg_path.exists():
        try:
            with open(pkg_path, encoding="utf-8") as f:
                pkg = json.load(f)
            pkg_name = pkg.get("name", "")
            pkg_version = pkg.get("version", "")
            for key in ("dependencies", "devDependencies", "peerDependencies"):
                all_deps.update(pkg.get(key, {}))
            for framework, signals in FRAMEWORK_SIGNALS.items():
                if any(s in all_deps for s in signals):
                    detected.append(framework)
        except (json.JSONDecodeError, IOError):
            pass

    # Python backend detection via project files and imports
    if (project_root / "manage.py").exists():
        detected.append("django")
    for req_file in ["requirements.txt", "pyproject.toml", "setup.py", "Pipfile"]:
        req_path = project_root / req_file
        if req_path.exists():
            try:
                content = req_path.read_text(encoding="utf-8", errors="replace").lower()
            except IOError:
                continue
            for name in ("django", "fastapi", "flask"):
                if name in content and name not in detected:
                    detected.append(name)

    # Prefer specific over generic
    priority = [
        "sveltekit", "next", "nuxt", "remix", "astro",  # fullstack JS
        "nestjs", "express", "fastify",                   # backend JS
        "django", "fastapi", "flask",                     # backend Python
        "angular", "svelte", "vue", "react", "solid",     # frontend JS
    ]
    framework = "unknown"
    for fw in priority:
        if fw in detected:
            framework = fw
            break

    return {
        "framework": framework,
        "name": pkg_name or project_root.name,
        "version": pkg_version,
        "detected_frameworks": detected,
        "dependency_count": len(all_deps),
        "all_deps": all_deps,
        "key_deps": {k: v for k, v in all_deps.items()
                     if any(s in k for s in ["router", "redux", "vuex", "pinia", "zustand",
                                              "mobx", "recoil", "jotai", "tanstack", "swr",
                                              "axios", "tailwind", "material", "ant",
                                              "chakra", "shadcn", "i18n", "intl",
                                              "typeorm", "prisma", "sequelize", "mongoose",
                                              "passport", "jwt", "class-validator",
                                              "ejs", "pug", "handlebars", "nunjucks"])},
    }


def find_dirs(root: Path, patterns: List[str]) -> List[Path]:
    """Find directories matching common patterns."""
    found = []
    for pattern in patterns:
        candidate = root / pattern
        if candidate.is_dir():
            found.append(candidate)
    return found


def is_test_file(path: Path) -> bool:
    return bool(TEST_FILE_RE.search(path.name))


def walk_files(root: Path, extensions: Set[str] = CODE_EXTENSIONS) -> List[Path]:
    """Walk project tree, skip ignored and test dirs/files, return files matching extensions."""
    results = []
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [d for d in dirnames
                       if d not in IGNORED_DIRS and d not in TEST_DIRS and not d.endswith(".egg-info")]
        for fname in filenames:
            path = Path(dirpath) / fname
            if path.suffix in extensions and not is_test_file(path):
                results.append(path)
    return sorted(results)


class SourceCache:
    """Comment-stripped file contents, read once."""

    def __init__(self):
        self._cache: Dict[Path, str] = {}

    def __call__(self, path: Path) -> str:
        if path not in self._cache:
            try:
                raw = path.read_text(encoding="utf-8", errors="replace")
            except IOError:
                raw = ""
            self._cache[path] = strip_comments(raw, path.suffix)
        return self._cache[path]


# ---------------------------------------------------------------------------
# Frontend routes
# ---------------------------------------------------------------------------

def extract_route_elements(filepath: Path, content: str) -> List[Dict[str, Any]]:
    """React Router <Route path="..."> elements, in any component file."""
    return [{
        "path": normalize_path(m.group(2)),
        "source": str(filepath),
        "line": line_of(content, m.start()),
    } for m in ROUTE_ELEMENT_RE.finditer(content)]


def extract_route_config(filepath: Path, content: str) -> List[Dict[str, Any]]:
    """`path: '...'` entries in router config files (Vue Router, Angular, RR objects)."""
    routes = []
    for m in ROUTE_CONFIG_RE.finditer(content):
        path = m.group(2)
        if path.startswith("http") or len(path) > 200:
            continue
        routes.append({
            "path": normalize_path(path),
            "source": str(filepath),
            "line": line_of(content, m.start()),
        })
    return routes


def _fs_files(directory: Path):
    """Code and content files under a routing directory, skipping test files.

    Folder names like `build/`, `media/`, or `test/` are real URL segments here,
    so only node_modules and dot-folders are skipped, not IGNORED_DIRS/TEST_DIRS.
    """
    for path in sorted(directory.rglob("*")):
        rel = path.relative_to(directory).parts
        if (path.is_file() and not is_test_file(path)
                and not any(p == "node_modules" or p.startswith(".") for p in rel)):
            yield path, rel


def _fs_segment(seg: str) -> Optional[str]:
    """One file-system route segment → URL segment; None drops it (route groups, slots)."""
    if seg.startswith("(") and seg.endswith(")") or seg.startswith("@"):
        return None
    seg = re.sub(r"\[\[?\.\.\.(\w+)\]?\]", r"*\1", seg)
    seg = re.sub(r"\[\[(\w+)\]\]", r":\1", seg)
    return re.sub(r"\[(\w+)\]", r":\1", seg)


def _fs_path(parts) -> str:
    parts = list(parts)
    if parts and parts[-1] == "index":
        parts = parts[:-1]
    return normalize_path("/".join(s for s in (_fs_segment(p) for p in parts) if s))


def _fs_page(path: str, f: Path) -> Dict[str, Any]:
    return {"path": path, "source": str(f), "filesystem": True}


def _fs_endpoints(path: str, methods, f: Path) -> List[Dict[str, Any]]:
    return [{"path": path, "method": m, "source": str(f), "line": 1,
             "type": "backend", "filesystem": True} for m in methods]


def _exported_methods(content: str) -> List[str]:
    return sorted(set(EXPORTED_METHOD_RE.findall(content))) or ["ANY"]


def next_routes(root: Path, read: SourceCache) -> Tuple[List[Dict[str, Any]], List[Dict[str, Any]]]:
    """App Router (page.* / route.*) and Pages Router (pages/**, pages/api/**)."""
    pages, endpoints = [], []
    for d in (root / "app", root / "src" / "app"):
        if not d.is_dir():
            continue
        for f, rel in _fs_files(d):
            if any(p.startswith("_") for p in rel[:-1]):  # private folders
                continue
            if f.stem == "page" and f.suffix in PAGE_FILE_EXTENSIONS:
                pages.append(_fs_page(_fs_path(rel[:-1]), f))
            elif f.stem == "route" and f.suffix in JS_EXTENSIONS:
                endpoints += _fs_endpoints(_fs_path(rel[:-1]), _exported_methods(read(f)), f)
    for d in (root / "pages", root / "src" / "pages"):
        if not d.is_dir():
            continue
        for f, rel in _fs_files(d):
            if f.suffix not in PAGE_FILE_EXTENSIONS:
                continue
            path = _fs_path(rel[:-1] + (f.stem,))
            if rel[0] == "api":
                content = read(f)
                methods = {a or b for a, b in REQ_METHOD_RE.findall(content)}
                if not methods or "405" not in content:
                    methods.add("ANY")
                endpoints += _fs_endpoints(path, sorted(methods), f)
            elif not f.stem.startswith("_"):
                pages.append(_fs_page(path, f))
    return pages, endpoints


def nuxt_routes(root: Path, read: SourceCache) -> Tuple[List[Dict[str, Any]], List[Dict[str, Any]]]:
    """pages/**.vue, plus server/api/** (prefixed /api) and server/routes/** with name.<method>.ts."""
    pages, endpoints = [], []
    for d in (root / "pages", root / "app" / "pages"):
        if d.is_dir():
            pages += [_fs_page(_fs_path(rel[:-1] + (f.stem,)), f)
                      for f, rel in _fs_files(d) if f.suffix == ".vue"]
    for d, prefix in ((root / "server" / "api", ("api",)), (root / "server" / "routes", ())):
        if not d.is_dir():
            continue
        for f, rel in _fs_files(d):
            if f.suffix not in JS_EXTENSIONS:
                continue
            name, _, method = f.stem.rpartition(".")
            if method.upper() not in HTTP_METHOD_NAMES:
                name, method = f.stem, "ANY"
            endpoints += _fs_endpoints(_fs_path(prefix + rel[:-1] + (name,)), [method.upper()], f)
    return pages, endpoints


def sveltekit_routes(root: Path, read: SourceCache) -> Tuple[List[Dict[str, Any]], List[Dict[str, Any]]]:
    """src/routes/**/+page.svelte and +server.(ts|js)."""
    pages, endpoints = [], []
    d = root / "src" / "routes"
    if d.is_dir():
        for f, rel in _fs_files(d):
            if f.name == "+page.svelte":
                pages.append(_fs_page(_fs_path(rel[:-1]), f))
            elif f.stem == "+server" and f.suffix in JS_EXTENSIONS:
                endpoints += _fs_endpoints(_fs_path(rel[:-1]), _exported_methods(read(f)), f)
    return pages, endpoints


def _remix_segment(seg: str) -> Optional[str]:
    if seg == "_index" or seg.startswith("_"):  # index route / pathless layout
        return None
    seg = seg.rstrip("_")
    if seg == "$":
        return "*"
    seg = re.sub(r"^\(\$(\w+)\)$", r":\1", seg)  # optional param
    return re.sub(r"^\$(\w+)$", r":\1", seg)


def remix_routes(root: Path, read: SourceCache) -> Tuple[List[Dict[str, Any]], List[Dict[str, Any]]]:
    """app/routes flat routes (users.$id.tsx) and folder routes (users.$id/route.tsx).

    Files with a default export are pages; files exporting only loader/action are resource routes.
    """
    pages, endpoints = [], []
    d = root / "app" / "routes"
    if not d.is_dir():
        return pages, endpoints
    for f, rel in _fs_files(d):
        if f.suffix not in JS_EXTENSIONS:
            continue
        if len(rel) > 1 and f.stem != "route":  # colocated helper files inside a route folder
            continue
        name = ".".join(rel[:-1]) if len(rel) > 1 else f.stem
        segments = [s for s in (_remix_segment(seg) for seg in name.split(".")) if s]
        path = normalize_path("/".join(segments))
        content = read(f)
        if HAS_DEFAULT_EXPORT_RE.search(content):
            pages.append(_fs_page(path, f))
        else:
            exports = set(REMIX_EXPORT_RE.findall(content))
            methods = (["GET"] if "loader" in exports else []) + (["POST"] if "action" in exports else [])
            endpoints += _fs_endpoints(path, methods or ["ANY"], f)
    return pages, endpoints


def astro_routes(root: Path, read: SourceCache) -> Tuple[List[Dict[str, Any]], List[Dict[str, Any]]]:
    """src/pages/** — .astro/.md/.mdx/.html are pages, .ts/.js are endpoints."""
    pages, endpoints = [], []
    d = root / "src" / "pages"
    if d.is_dir():
        for f, rel in _fs_files(d):
            path = _fs_path(rel[:-1] + (f.stem,))
            if f.suffix in {".astro", ".md", ".mdx", ".html"}:
                pages.append(_fs_page(path, f))
            elif f.suffix in {".ts", ".js"}:
                endpoints += _fs_endpoints(path, _exported_methods(read(f)), f)
    return pages, endpoints


FILESYSTEM_ROUTERS = {
    "next": next_routes,
    "nuxt": nuxt_routes,
    "sveltekit": sveltekit_routes,
    "remix": remix_routes,
    "astro": astro_routes,
}


# ---------------------------------------------------------------------------
# Client API calls
# ---------------------------------------------------------------------------

def server_receivers(content: str) -> Set[str]:
    """Names bound to an Express/Fastify app or router in this file."""
    return {"app", "router", "server", "fastify"} | set(SERVER_INSTANCE_RE.findall(content))


def full_path_arg(content: str, paren_idx: int, position: int, fallback: str) -> str:
    """The call argument at `position`, with string concatenation folded into one path."""
    args = split_args(balanced(content, paren_idx))
    joined = concat_literal(args[position]) if len(args) > position else None
    if not joined:
        return fallback
    return re.sub(r"^https?://[^/]+", "", joined)


def extract_apis_from_file(filepath: Path, content: str, constants: Dict[str, str],
                           root: Optional[Path] = None) -> List[Dict[str, Any]]:
    """Extract client-side API calls (fetch, axios-style wrappers, XHR) from a JS file."""
    if filepath.suffix not in JS_EXTENSIONS:
        return []

    is_real = any(re.search(p, content) for p in REAL_API_SIGNALS)
    rel = filepath.relative_to(root) if root and filepath.is_absolute() else filepath
    mock_file = bool(MOCK_PATH_RE.search("/" + str(rel).replace("\\", "/")))
    lines = content.split("\n")

    def is_mock(idx: int) -> bool:
        if mock_file:
            return True
        line = line_of(content, idx) - 1
        window = "\n".join(lines[max(0, line - MOCK_WINDOW_LINES):line + MOCK_WINDOW_LINES + 1])
        return any(re.search(p, window) for p in MOCK_SIGNALS)

    skip_receivers = server_receivers(content)
    found: List[Tuple[str, str, int]] = []

    for m in CLIENT_VERB_RE.finditer(content):
        if m.group(1) in skip_receivers:
            continue
        method = "DELETE" if m.group(2) == "del" else m.group(2).upper()
        found.append((method, full_path_arg(content, m.start(3), 0, m.group(5)), m.start()))

    for m in FETCH_RE.finditer(content):
        options = balanced(content, m.start(1))
        method_m = METHOD_PROP_RE.search(options)
        path = full_path_arg(content, m.start(1), 0, m.group(3))
        found.append((method_m.group(1).upper() if method_m else "GET", path, m.start()))

    for m in XHR_RE.finditer(content):
        found.append((m.group(2).upper(), full_path_arg(content, m.start(1), 1, m.group(4)), m.start()))

    for m in URL_PROP_RE.finditer(content):
        nearby = content[max(0, m.start() - 150):m.end() + 150]
        method_m = METHOD_PROP_RE.search(nearby)
        found.append((method_m.group(1).upper() if method_m else "UNKNOWN", m.group(2), m.start()))

    return [{
        "path": normalize_path(path, constants),
        "method": method,
        "source": str(filepath),
        "line": line_of(content, idx),
        "integrated": is_real and not is_mock(idx),
        "mock_detected": is_mock(idx),
    } for method, path, idx in found if len(path) < 200]


def extract_enums(filepath: Path, content: str) -> List[Dict[str, Any]]:
    """Extract enum/constant definitions."""
    enums = []

    # TypeScript enums
    for match in re.finditer(r"enum\s+(\w+)\s*\{([^}]+)\}", content):
        name = match.group(1)
        body = match.group(2)
        values = re.findall(r"(\w+)\s*=\s*['\"]?([^,'\"\n]+)", body)
        enums.append({
            "name": name,
            "type": "enum",
            "values": {k.strip(): v.strip().rstrip(",") for k, v in values},
            "source": str(filepath),
        })

    # Object constant maps (const STATUS_MAP = { ... })
    for match in re.finditer(
        r"(?:const|export\s+const)\s+(\w*(?:MAP|STATUS|TYPE|ENUM|OPTION|ROLE|STATE)\w*)\s*[:=]\s*\{([^}]+)\}",
        content, re.IGNORECASE
    ):
        name = match.group(1)
        body = match.group(2)
        values = re.findall(r"['\"]?(\w+)['\"]?\s*:\s*['\"]([^'\"]+)['\"]", body)
        if values:
            enums.append({
                "name": name,
                "type": "constant_map",
                "values": dict(values),
                "source": str(filepath),
            })

    return enums


# ---------------------------------------------------------------------------
# Express / Fastify
# ---------------------------------------------------------------------------

def resolve_js_module(from_file: Path, spec: str) -> Optional[Path]:
    """Resolve a relative import specifier to a file."""
    if not spec.startswith("."):
        return None
    base = (from_file.parent / spec)
    candidates = [base]
    candidates += [base.with_name(base.name + s) for s in MODULE_SUFFIXES]
    candidates += [base / ("index" + s) for s in MODULE_SUFFIXES]
    for c in candidates:
        if c.is_file():
            return c.resolve()
    return None


def js_imports(filepath: Path, content: str) -> Dict[str, Path]:
    """Map local identifiers to the project files they were imported from."""
    imports: Dict[str, Path] = {}

    def add(name: str, spec: str):
        target = resolve_js_module(filepath, spec)
        if target:
            imports[name.strip()] = target

    for m in IMPORT_DEFAULT_RE.finditer(content):
        add(m.group(1), m.group(2))
    for m in REQUIRE_DEFAULT_RE.finditer(content):
        add(m.group(1), m.group(2))
    for regex in (IMPORT_NAMED_RE, REQUIRE_NAMED_RE):
        for m in regex.finditer(content):
            for part in m.group(1).split(","):
                if part.strip():
                    add(re.split(r"\s+as\s+|\s*:\s*", part.strip())[-1], m.group(2))

    # const ctrl = buildController(deps) → ctrl resolves to buildController's module
    for m in FACTORY_ALIAS_RE.finditer(content):
        alias, factory = m.group(1), m.group(2)
        if factory in imports and alias not in imports:
            imports[alias] = imports[factory]
    return imports


def find_function_body(content: str, name: str) -> Optional[str]:
    """Find the body of a function/method named `name` (declaration, shorthand, or arrow)."""
    n = re.escape(name)
    patterns = [
        rf"(?:^|[\s,{{;])(?:async\s+)?(?:function\s*\*?\s*)?{n}\s*\([^)]*\)\s*\{{",
        rf"\b{n}\s*[:=]\s*(?:async\s*)?(?:function\s*)?\([^)]*\)\s*(?:=>\s*)?\{{",
        rf"\b{n}\s*[:=]\s*(?:async\s+)?[\w$]+\s*=>\s*\{{",
    ]
    for p in patterns:
        m = re.search(p, content)
        if m:
            return balanced(content, m.end() - 1)
    return None


def handler_body(handler: str, filepath: Path, content: str,
                 imports: Dict[str, Path], read: SourceCache) -> Optional[str]:
    """Best-effort source text for a route handler argument."""
    handler = handler.strip()
    if re.match(r"(?:async\s*)?(?:function\b|\(|[\w$]+\s*=>)", handler):
        return handler
    m = re.fullmatch(r"([\w$]+)\.([\w$]+)", handler)
    if m:
        target = imports.get(m.group(1))
        return find_function_body(read(target), m.group(2)) if target else None
    m = re.fullmatch(r"[\w$]+", handler)
    if m:
        target = imports.get(handler)
        if target:
            return find_function_body(read(target), handler) or read(target)
        return find_function_body(content, handler)
    return None


def express_mount_edges(filepath: Path, content: str, imports: Dict[str, Path]) -> List[Tuple[str, Path]]:
    """`x.use('/prefix', ..., routerModule)` → [(prefix, routerFile)]."""
    edges = []
    receivers = server_receivers(content)
    for m in USE_RE.finditer(content):
        if m.group(1) not in receivers:
            continue
        args = split_args(balanced(content, m.start(2)))
        if not args:
            continue
        prefix = string_literal(args[0])
        rest = args[1:] if prefix is not None else args
        for arg in rest:
            req = re.search(r"require\s*\(\s*['\"]([^'\"]+)['\"]\s*\)", arg)
            target = resolve_js_module(filepath, req.group(1)) if req else None
            if not target:
                lead = re.match(r"\s*([\w$]+)", arg)
                target = imports.get(lead.group(1)) if lead else None
            if target:
                edges.append((prefix or "", target))
    return edges


def compose_prefixes(node: Path, parents: Dict[Path, List[Tuple[Path, str]]],
                     seen: Tuple[Path, ...] = ()) -> List[str]:
    """All full prefixes for a router/urlconf file, walking mount edges up to the roots."""
    if node not in parents:
        return [""]
    out = []
    for parent, prefix in parents[node]:
        if parent in seen or parent == node:
            continue
        for upper in compose_prefixes(parent, parents, seen + (node,)):
            out.append(upper + "/" + prefix)
    return out or [""]


def name_words(text: str) -> Set[str]:
    """Split identifiers and paths into lowercase words: `downloadAll /c/:token` → {download, all, c, token}."""
    spaced = re.sub(r"([a-z0-9])([A-Z])", r"\1 \2", text)
    return {w.lower() for w in re.split(r"[^A-Za-z0-9]+", spaced) if w}


def extract_express(files: List[Path], read: SourceCache, constants: Dict[str, str],
                    has_views: bool) -> Tuple[List[Dict[str, Any]], List[Dict[str, Any]]]:
    """Return (pages, endpoints) for an Express/Fastify project."""
    parents: Dict[Path, List[Tuple[Path, str]]] = defaultdict(list)
    defs: List[Tuple[Path, str, str, int, Optional[str], str]] = []

    js_files = [f.resolve() for f in files if f.suffix in JS_EXTENSIONS]
    for f in js_files:
        content = read(f)
        imports = js_imports(f, content)
        for prefix, target in express_mount_edges(f, content, imports):
            parents[target].append((f, prefix))

        receivers = server_receivers(content)
        for m in EXPRESS_ROUTE_RE.finditer(content):
            receiver, verb, path = m.group(1), m.group(2), m.group(5)
            if receiver not in receivers or not path.startswith(("/", "${", "*")):
                continue
            args = split_args(balanced(content, m.start(3)))
            body = handler_body(args[-1], f, content, imports, read) if len(args) > 1 else None
            defs.append((f, verb.upper(), path, line_of(content, m.start()), body, args[-1]))

    pages, endpoints, seen = [], [], set()
    for f, method, path, line, body, handler in defs:
        for prefix in compose_prefixes(f, parents):
            full = normalize_path(prefix + "/" + path, constants)
            if (method, full) in seen:
                continue
            seen.add((method, full))
            entry = {"path": full, "method": method, "source": str(f), "line": line}

            view_m = RENDER_RE.search(body) if body else None
            unknown = body is None or (not view_m and not NON_PAGE_RESPONSE_RE.search(body))
            if unknown and NON_PAGE_WORDS & name_words(handler + " " + full):
                unknown = False
            is_page = method == "GET" and (
                view_m or (unknown and has_views and not full.startswith("/api"))
            )
            if is_page:
                entry["view"] = view_m.group(1) if view_m else None
                if not view_m:
                    entry["inferred"] = True
                pages.append(entry)
            else:
                entry["type"] = "backend"
                endpoints.append(entry)
    return pages, endpoints


# ---------------------------------------------------------------------------
# NestJS
# ---------------------------------------------------------------------------

def extract_nest_routes(filepath: Path, content: str, global_prefix: str = "") -> List[Dict[str, Any]]:
    """Routes from setGlobalPrefix + @Controller prefix + @Get/@Post/... method decorators."""
    controller = NEST_CONTROLLER_RE.search(content)
    prefix = (controller.group(1) or controller.group(2) or "") if controller else ""
    return [{
        "path": normalize_path(global_prefix + "/" + prefix + "/" + (m.group(2) or "")),
        "method": m.group(1).upper(),
        "source": str(filepath),
        "line": line_of(content, m.start()),
        "type": "backend",
    } for m in NEST_METHOD_RE.finditer(content)]


# ---------------------------------------------------------------------------
# Django
# ---------------------------------------------------------------------------

def python_classes(files: List[Path], read: SourceCache) -> Dict[str, Dict[str, Any]]:
    """name → {bases, body, source} for every class in the given Python files."""
    classes = {}
    for f in files:
        content = read(f)
        for m in PY_CLASS_RE.finditer(content):
            indent = len(m.group(1).expandtabs())
            body_lines = []
            for line in content[m.end():].split("\n")[1:]:
                if line.strip() and len(line) - len(line.lstrip()) <= indent:
                    break
                body_lines.append(line)
            bases = [b.strip().split(".")[-1] for b in split_args(m.group(3) or "") if b.strip()]
            classes.setdefault(m.group(2), {
                "bases": bases,
                "body": "\n".join(body_lines),
                "source": str(f),
                "indent": indent,
            })
    return classes


def _own_defs(cls: Dict[str, Any]) -> Set[str]:
    return set(PY_DEF_RE.findall(cls["body"]))


def view_methods(name: str, classes: Dict[str, Dict[str, Any]],
                 func_methods: Dict[str, List[str]], seen: Optional[Set[str]] = None) -> List[str]:
    """HTTP methods a Django/DRF view serves, from handler defs, generic bases, or @api_view."""
    if name in func_methods:
        return func_methods[name]
    seen = seen or set()
    if name in seen or name not in classes:
        return []
    seen.add(name)
    cls = classes[name]
    methods = {d.upper() for d in _own_defs(cls) if d in HTTP_METHODS}
    for base in cls["bases"]:
        methods.update(GENERIC_VIEW_METHODS.get(base, []))
        methods.update(view_methods(base, classes, func_methods, seen))
    return sorted(methods)


def viewset_actions(name: str, classes: Dict[str, Dict[str, Any]], seen: Optional[Set[str]] = None) -> Set[str]:
    seen = seen or set()
    if name in seen or name not in classes:
        return set(VIEWSET_BASE_ACTIONS.get(name, []))
    seen.add(name)
    cls = classes[name]
    actions = {d for d in _own_defs(cls) if d in VIEWSET_ACTIONS}
    for base in cls["bases"]:
        actions |= viewset_actions(base, classes, seen)
    return actions


def django_path(raw: str, is_regex: bool) -> str:
    """Convert a Django url()/re_path() regex or path() pattern to /a/:param form."""
    if is_regex:
        p = raw.lstrip("^").replace("$", "")
        p = re.sub(r"\(\?P<(\w+)>[^)]*\)", r":\1", p)
        p = re.sub(r"/\?(?=/|$)", "", p)
        return p
    return re.sub(r"<(?:\w+:)?(\w+)>", r":\1", raw)


def find_urlconf(module: str, urls_files: List[Path], root: Path) -> Optional[Path]:
    suffix = module.replace(".", "/") + ".py"
    for f in urls_files:
        if str(f.relative_to(root)).replace("\\", "/").endswith(suffix):
            return f
    return None


def extract_django(files: List[Path], read: SourceCache, root: Path) -> Tuple[List[Dict[str, Any]], bool]:
    """Return (endpoints, has_admin) for a Django project."""
    py_files = [f for f in files if f.suffix == ".py"]
    urls_files = [f for f in py_files if f.name == "urls.py"]
    classes = python_classes(py_files, read)

    func_methods: Dict[str, List[str]] = {}
    for f in py_files:
        for m in API_VIEW_DECORATOR_RE.finditer(read(f)):
            func_methods[m.group(2)] = [s.strip().strip("'\"").upper() for s in m.group(1).split(",") if s.strip()]

    parents: Dict[Path, List[Tuple[Path, str]]] = defaultdict(list)
    entries: List[Tuple[Path, str, str, str, int]] = []  # (file, path, kind, target, line)
    registrations: Dict[Tuple[Path, str], List[Tuple[str, str]]] = defaultdict(list)
    has_admin = False

    for f in urls_files:
        content = read(f)
        for m in DJANGO_REGISTER_RE.finditer(content):
            registrations[(f, m.group(1))].append((m.group(2), m.group(3).split(".")[-1]))

        for m in DJANGO_URL_CALL_RE.finditer(content):
            args = split_args(balanced(content, m.start(2)))
            if len(args) < 2:
                continue
            raw = string_literal(args[0])
            if raw is None:
                continue
            path = django_path(raw, m.group(1) != "path")
            target = args[1].strip()
            line = line_of(content, m.start())
            if target.startswith("admin.site.urls"):
                has_admin = True
            elif target.startswith("include"):
                inner = split_args(balanced(target, target.index("(")))
                module = string_literal(inner[0]) if inner else None
                if module:
                    child = find_urlconf(module, urls_files, root)
                    if child:
                        parents[child].append((f, path))
                elif inner and inner[0].endswith(".urls"):
                    entries.append((f, path, "router", inner[0][:-5], line))
            else:
                view = re.sub(r"\.as_view\s*\(.*$", "", target, flags=re.S).split(".")[-1]
                entries.append((f, path, "view", view, line))

        for m in DJANGO_ROUTER_URLS_RE.finditer(content):
            entries.append((f, "", "router", m.group(1), line_of(content, m.start())))

    endpoints, seen = [], set()

    def emit(method: str, path: str, f: Path, line: int):
        path = normalize_path(path)
        if (method, path) not in seen:
            seen.add((method, path))
            endpoints.append({"path": path, "method": method, "source": str(f),
                              "line": line, "type": "backend"})

    for f, path, kind, target, line in entries:
        for prefix in compose_prefixes(f, parents):
            base = prefix + "/" + path
            if kind == "view":
                for method in view_methods(target, classes, func_methods) or ["ANY"]:
                    emit(method, base, f, line)
            elif kind == "router":
                for reg_prefix, viewset in registrations[(f, target)]:
                    cls = classes.get(viewset, {"body": ""})
                    lookup = re.search(r"lookup_(?:url_kwarg|field)\s*=\s*['\"](\w+)['\"]", cls["body"])
                    lookup_name = lookup.group(1) if lookup else "pk"
                    for action in sorted(viewset_actions(viewset, classes)):
                        scope, method = VIEWSET_ACTIONS[action]
                        tail = "" if scope == "collection" else f"/:{lookup_name}"
                        emit(method, f"{base}/{reg_prefix}{tail}", f, line)
    return endpoints, has_admin


def extract_django_models(files: List[Path], read: SourceCache) -> List[Dict[str, Any]]:
    """Django models, including ones that inherit from abstract or custom base models."""
    model_files = [f for f in files if f.name == "models.py" or "models" in f.parts]
    classes = python_classes(model_files, read)
    models: Set[str] = set()
    changed = True
    while changed:
        changed = False
        for name, cls in classes.items():
            if name not in models and any(b in DJANGO_MODEL_ROOTS or b in models for b in cls["bases"]):
                models.add(name)
                changed = True

    result = []
    for name in sorted(models):
        cls = classes[name]
        own_body = "\n".join(
            line for line in cls["body"].split("\n")
            if len(line) - len(line.lstrip()) <= cls["indent"] + 4 or not line.strip()
        )
        fields = [{
            "name": fm.group(1),
            "type": fm.group(2),
            "args": fm.group(3).strip()[:100],
        } for fm in re.finditer(r"^\s*(\w+)\s*=\s*models\.(\w+)\s*\(([^)]*)\)", own_body, re.M)]
        model = {"name": name, "source": cls["source"], "framework": "django", "fields": fields}
        if re.search(r"^\s*abstract\s*=\s*True", cls["body"], re.M):
            model["abstract"] = True
        result.append(model)
    return result


def extract_models(filepath: Path, content: str, framework: str) -> List[Dict[str, Any]]:
    """Pydantic / NestJS model and entity definitions."""
    if framework in ("fastapi", "flask"):
        patterns = [r"class\s+(\w+)\s*\(.*?BaseModel\)"]
    else:
        patterns = NEST_MODEL_PATTERNS
    return [{
        "name": m.group(1),
        "source": str(filepath),
        "framework": framework,
        "fields": [],
    } for p in patterns for m in re.finditer(p, content)]


def count_components(files: List[Path]) -> Dict[str, int]:
    """Count components by type."""
    counts: Dict[str, int] = defaultdict(int)
    for f in files:
        if f.suffix in COMPONENT_EXTENSIONS:
            counts["components"] += 1
        elif f.suffix in {".ts", ".js"}:
            counts["modules"] += 1
    return dict(counts)


def merge_api_calls(apis: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    """One entry per (path, method). Integrated if any call is real; Mock only if every call is mock.

    `source` is the first non-mock caller (else the first caller); `sources` lists every caller.
    """
    groups: Dict[Tuple[str, str], List[Dict[str, Any]]] = defaultdict(list)
    for a in apis:
        groups[(a["path"], a["method"])].append(a)
    merged = []
    for key in sorted(groups):
        calls = groups[key]
        primary = next((c for c in calls if not c["mock_detected"]), calls[0])
        entry = dict(primary)
        entry["integrated"] = any(c["integrated"] for c in calls)
        entry["mock_detected"] = all(c["mock_detected"] for c in calls)
        entry["sources"] = list(dict.fromkeys(c["source"] for c in calls))
        merged.append(entry)
    return merged


def _dedupe(items: List[Dict[str, Any]], key) -> List[Dict[str, Any]]:
    seen, out = set(), []
    for item in items:
        k = key(item)
        if k not in seen:
            seen.add(k)
            out.append(item)
    return out


def analyze_project(project_root: Path) -> Dict[str, Any]:
    """Run full analysis on a frontend, backend, or fullstack project."""
    root = Path(project_root).resolve()
    if not root.is_dir():
        return {"error": f"Not a directory: {root}"}

    # 1. Framework detection
    framework_info = detect_framework(root)
    fw = framework_info["framework"]
    detected = set(framework_info["detected_frameworks"])
    has_frontend_fw = bool(detected & FRONTEND_FRAMEWORKS)

    # 2. File inventory
    all_files = walk_files(root)
    component_counts = count_components(all_files)
    read = SourceCache()
    view_files = walk_files(root, VIEW_EXTENSIONS)
    has_views = any("views" in f.relative_to(root).parts or "templates" in f.relative_to(root).parts
                    for f in view_files)

    # 3. Directory structure
    route_dirs = find_dirs(root, ROUTE_DIR_PATTERNS)
    api_dirs = find_dirs(root, API_DIR_PATTERNS)
    state_dirs = find_dirs(root, STATE_DIR_PATTERNS)
    i18n_dirs = find_dirs(root, I18N_DIR_PATTERNS)

    constants: Dict[str, str] = {}
    for f in all_files:
        if f.suffix in JS_EXTENSIONS:
            for name, value in PATH_CONSTANT_RE.findall(read(f)):
                constants.setdefault(name, value)

    # 4. Routes
    frontend_routes: List[Dict[str, Any]] = []
    backend_routes: List[Dict[str, Any]] = []
    has_admin = False

    if has_frontend_fw:
        for f in all_files:
            if f.suffix in JS_EXTENSIONS:
                frontend_routes.extend(extract_route_elements(f, read(f)))
                if any(p in f.name.lower() for p in ("router", "routes", "routing")):
                    frontend_routes.extend(extract_route_config(f, read(f)))

    if fw in FILESYSTEM_ROUTERS:
        pages, endpoints = FILESYSTEM_ROUTERS[fw](root, read)
        frontend_routes.extend(pages)
        backend_routes.extend(endpoints)

    if fw in ("express", "fastify"):
        pages, endpoints = extract_express(all_files, read, constants, has_views)
        frontend_routes.extend(pages)
        backend_routes.extend(endpoints)
    elif fw == "nestjs":
        global_prefix = next((m.group(1) for f in all_files
                              for m in [NEST_GLOBAL_PREFIX_RE.search(read(f))] if m), "")
        for f in all_files:
            if ".controller." in f.name:
                backend_routes.extend(extract_nest_routes(f, read(f), global_prefix))
    elif fw == "django":
        endpoints, has_admin = extract_django(all_files, read, root)
        backend_routes.extend(endpoints)

    frontend_routes = sorted(_dedupe(frontend_routes, lambda r: r["path"]), key=lambda r: r["path"])
    backend_routes = sorted(_dedupe(backend_routes, lambda r: (r["method"], r["path"])),
                            key=lambda r: (r["path"], r["method"]))
    routes = frontend_routes + backend_routes

    # 5. API calls
    apis = []
    for f in all_files:
        apis.extend(extract_apis_from_file(f, read(f), constants, root))
    apis = merge_api_calls(apis)

    # 6. Enums
    enums = []
    for f in all_files:
        enums.extend(extract_enums(f, read(f)))

    # 7. Models/entities (backend)
    models: List[Dict[str, Any]] = []
    if fw == "django":
        models = extract_django_models(all_files, read)
    elif fw in ("fastapi", "flask", "nestjs"):
        for f in all_files:
            if fw != "nestjs" or ".entity." in f.name or ".dto." in f.name:
                models.extend(extract_models(f, read(f), fw))
    models = sorted(_dedupe(models, lambda m: m["name"]), key=lambda m: m["name"])

    # Report sources relative to the project root so local paths never leak into PRD docs
    def relative(source: str) -> str:
        src = Path(source)
        if src.is_absolute():
            try:
                return str(src.resolve().relative_to(root))
            except ValueError:
                pass
        return source

    for collection in (frontend_routes, backend_routes, apis, enums, models):
        for item in collection:
            if "source" in item:
                item["source"] = relative(item["source"])
            if "sources" in item:
                item["sources"] = [relative(s) for s in item["sources"]]

    # Backend-specific directories
    controller_dirs = find_dirs(root, CONTROLLER_DIR_PATTERNS)
    model_dirs = find_dirs(root, MODEL_DIR_PATTERNS)
    dto_dirs = find_dirs(root, DTO_DIR_PATTERNS)

    # 8. Summary
    mock_count = sum(1 for a in apis if a.get("mock_detected"))
    real_count = sum(1 for a in apis if a.get("integrated"))
    if fw in BACKEND_FRAMEWORKS:
        stack_type = "fullstack" if frontend_routes else "backend"
    else:
        stack_type = "fullstack" if backend_routes else "frontend"
    # State dirs like models/ only mean client state when there is a frontend framework
    has_state = (bool(STATE_DEPS & set(framework_info["all_deps"]))
                 or (has_frontend_fw and (bool(state_dirs) or any(f.stem == "store" for f in all_files))))

    analysis = {
        "project": {
            "root": str(root),
            "name": framework_info.get("name", root.name),
            "framework": fw,
            "detected_frameworks": framework_info.get("detected_frameworks", []),
            "key_dependencies": framework_info.get("key_deps", {}),
            "stack_type": stack_type,
        },
        "structure": {
            "total_files": len(all_files),
            "components": component_counts,
            "route_dirs": [str(d.relative_to(root)) for d in route_dirs],
            "api_dirs": [str(d.relative_to(root)) for d in api_dirs],
            "state_dirs": [str(d.relative_to(root)) for d in state_dirs],
            "i18n_dirs": [str(d.relative_to(root)) for d in i18n_dirs],
            "controller_dirs": [str(d.relative_to(root)) for d in controller_dirs],
            "model_dirs": [str(d.relative_to(root)) for d in model_dirs],
            "dto_dirs": [str(d.relative_to(root)) for d in dto_dirs],
            "view_templates": [str(f.relative_to(root)) for f in view_files],
            "django_admin": has_admin,
        },
        "routes": {
            "count": len(routes),
            "frontend_pages": frontend_routes,
            "backend_endpoints": backend_routes,
            "pages": routes,  # backward compat
        },
        "apis": {
            "total": len(apis),
            "integrated": real_count,
            "mock": mock_count,
            "endpoints": apis,
        },
        "enums": {
            "count": len(enums),
            "definitions": enums,
        },
        "models": {
            "count": len(models),
            "definitions": models,
        },
        "summary": {
            "pages": len(frontend_routes),
            "backend_endpoints": len(backend_routes),
            "api_endpoints": len(apis),
            "api_integrated": real_count,
            "api_mock": mock_count,
            "enums": len(enums),
            "models": len(models),
            "has_i18n": len(i18n_dirs) > 0,
            "has_state_management": has_state,
            "stack_type": stack_type,
        },
    }

    return analysis


def format_markdown(analysis: Dict[str, Any]) -> str:
    """Format analysis as markdown summary."""
    lines = []
    proj = analysis["project"]
    summary = analysis["summary"]
    stack = summary.get("stack_type", "frontend")

    lines.append(f"# Codebase Analysis: {proj['name'] or 'Project'}")
    lines.append("")
    lines.append("> Leads only — regex-based extraction. Confirm every route, API, and model in source.")
    lines.append("")
    lines.append(f"**Framework:** {proj['framework']}")
    lines.append(f"**Stack type:** {stack}")
    lines.append(f"**Total files:** {analysis['structure']['total_files']}")
    if summary.get("pages"):
        lines.append(f"**Frontend pages:** {summary['pages']}")
    if summary.get("backend_endpoints"):
        lines.append(f"**Backend endpoints:** {summary['backend_endpoints']}")
    lines.append(f"**API calls detected:** {summary['api_endpoints']} "
                 f"({summary['api_integrated']} integrated, {summary['api_mock']} mock)")
    lines.append(f"**Enums:** {summary['enums']}")
    if summary.get("models"):
        lines.append(f"**Models/entities:** {summary['models']}")
    lines.append(f"**i18n:** {'Yes' if summary['has_i18n'] else 'No'}")
    lines.append(f"**State management:** {'Yes' if summary['has_state_management'] else 'No'}")
    if analysis["structure"].get("django_admin"):
        lines.append("**Django admin:** Yes — check admin.py for business rules")
    lines.append("")

    if analysis["routes"]["frontend_pages"]:
        lines.append("## Pages")
        lines.append("")
        lines.append("| # | Route | View | Source |")
        lines.append("|---|-------|------|--------|")
        for i, r in enumerate(analysis["routes"]["frontend_pages"], 1):
            src = r.get("source", "")
            fs = " (fs)" if r.get("filesystem") else ""
            view = r.get("view") or ("? (inferred)" if r.get("inferred") else "—")
            lines.append(f"| {i} | `{r['path']}` | {view} | {src}{fs} |")
        lines.append("")

    if analysis["routes"]["backend_endpoints"]:
        lines.append("## Backend Endpoints")
        lines.append("")
        lines.append("| # | Method | Path | Source |")
        lines.append("|---|--------|------|--------|")
        for i, r in enumerate(analysis["routes"]["backend_endpoints"], 1):
            src = r.get("source", "")
            lines.append(f"| {i} | {r['method']} | `{r['path']}` | {src} |")
        lines.append("")

    if analysis["apis"]["endpoints"]:
        lines.append("## Client API Calls")
        lines.append("")
        lines.append("| Method | Path | Status | Source |")
        lines.append("|--------|------|--------|--------|")
        for a in analysis["apis"]["endpoints"]:
            src = a.get("source", "")
            status = "Mock" if a.get("mock_detected") else "Integrated" if a.get("integrated") else "Unknown"
            lines.append(f"| {a['method']} | `{a['path']}` | {status} | {src} |")
        lines.append("")

    if analysis["enums"]["definitions"]:
        lines.append("## Enums & Constants")
        lines.append("")
        for e in analysis["enums"]["definitions"]:
            lines.append(f"### {e['name']} ({e['type']})")
            if e["values"]:
                lines.append("| Key | Value |")
                lines.append("|-----|-------|")
                for k, v in e["values"].items():
                    lines.append(f"| {k} | {v} |")
            lines.append("")

    if analysis.get("models", {}).get("definitions"):
        lines.append("## Models / Entities")
        lines.append("")
        for m in analysis["models"]["definitions"]:
            abstract = ", abstract" if m.get("abstract") else ""
            lines.append(f"### {m['name']} ({m.get('framework', '')}{abstract})")
            if m.get("fields"):
                lines.append("| Field | Type | Args |")
                lines.append("|-------|------|------|")
                for fld in m["fields"]:
                    lines.append(f"| {fld['name']} | {fld['type']} | {fld.get('args', '')} |")
            lines.append("")

    if proj.get("key_dependencies"):
        lines.append("## Key Dependencies")
        lines.append("")
        for dep, ver in sorted(proj["key_dependencies"].items()):
            lines.append(f"- `{dep}`: {ver}")
        lines.append("")

    return "\n".join(lines)


def main():
    # Non-UTF-8 consoles (e.g. Windows cp1252) can't print every character in the output
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(errors="replace")
    parser = argparse.ArgumentParser(
        description="Analyze any codebase (frontend, backend, fullstack) for PRD generation"
    )
    parser.add_argument("project", help="Path to project root")
    parser.add_argument("-o", "--output", help="Output file (default: stdout)")
    parser.add_argument(
        "-f", "--format",
        choices=["json", "markdown"],
        default="json",
        help="Output format (default: json)",
    )
    args = parser.parse_args()

    analysis = analyze_project(Path(args.project))
    if "error" in analysis:
        print(f"Error: {analysis['error']}", file=sys.stderr)
        raise SystemExit(1)

    if args.format == "markdown":
        output = format_markdown(analysis)
    else:
        output = json.dumps(analysis, indent=2, ensure_ascii=False)

    if args.output:
        Path(args.output).write_text(output, encoding="utf-8")
        print(f"Written to {args.output}")
    else:
        print(output)


if __name__ == "__main__":
    main()
