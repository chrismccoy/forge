#!/usr/bin/env python3
"""
Analyze Next.js project structure and provide optimization suggestions.

Scans `app/` and `src/app/` (and notes `pages/` / `src/pages/`), plus
proxy.ts / middleware.ts at the project root or in `src/`. Exits non-zero if
no app or pages directory is found.

Usage:
    python nextjs-analyzer.py --path ./my-nextjs-app
    python nextjs-analyzer.py --path ./my-nextjs-app --report json
    python nextjs-analyzer.py --path ./my-nextjs-app --check-version
"""

import argparse
import json
import os
import re
import sys
from pathlib import Path
from typing import Dict, List, Any, Optional

# File patterns to analyze
PATTERNS = {
    "pages": ["page.tsx", "page.ts", "page.jsx", "page.js"],
    "layouts": ["layout.tsx", "layout.ts", "layout.jsx", "layout.js"],
    "loading": ["loading.tsx", "loading.ts", "loading.jsx", "loading.js"],
    "error": ["error.tsx", "error.ts", "error.jsx", "error.js"],
    "route": ["route.tsx", "route.ts", "route.jsx", "route.js"],
    "middleware": ["middleware.ts", "middleware.js"],
    "proxy": ["proxy.ts", "proxy.js"],
}

ROUTER_DIR_CANDIDATES = {
    "app": ["app", "src/app"],
    "pages": ["pages", "src/pages"],
}

SOURCE_EXTS = ["*.ts", "*.tsx", "*.js", "*.jsx"]

# Shared component directories counted in the client/server ratio
COMPONENT_DIR_CANDIDATES = ["components", "src/components"]

# 'use client' must be the first statement; only comments/blank lines may precede it
USE_CLIENT_RE = re.compile(
    r"^\ufeff?\s*(?:(?://[^\n]*|/\*.*?\*/)\s*)*['\"]use client['\"]", re.S
)

# Files whose params/searchParams props are Promises in Next.js 16
ASYNC_PARAMS_STEMS = (
    "page", "layout", "route", "default", "template",
    "opengraph-image", "twitter-image", "icon", "apple-icon",
)

# A single `key: string` / `key?: string[]` entry in an inline params type
_PARAM_ENTRY = r"\s*[\w$]+\??\s*:\s*string(?:\[\])?\s*"

# Legacy (pre-15) synchronous type annotations, params AND searchParams:
#   params: { slug: string }   /   searchParams: { [key: string]: string | ... }
LEGACY_PARAMS_TYPE_RE = re.compile(
    r"(?<![\w$.])params\??\s*:\s*\{" + _PARAM_ENTRY
    + r"(?:[;,]" + _PARAM_ENTRY + r")*[;,]?\s*\}"
    r"|(?<![\w$.])searchParams\??\s*:\s*\{\s*\[\s*\w+\s*:\s*string\s*\]\s*:"
)
ASYNC_PARAMS_TYPE_RE = re.compile(r"(?<![\w$.])(?:params|searchParams)\??\s*:\s*Promise<")

# Functions whose params stay synchronous in Next.js 16 (their signatures are ignored)
SYNC_PARAMS_FUNC_RE = re.compile(
    r"(?<![\w$.])(?:generateStaticParams|generateImageMetadata)\s*(?::[^=(]*)?=?\s*"
    r"(?:async\s*)?(?:function\s*)?(?:<[^>()]*>)?\s*\("
)


def find_router_dirs(project_path: Path, kind: str = "app") -> List[Path]:
    """Return existing router directories of the given kind ('app' or 'pages')."""
    return [
        project_path / d
        for d in ROUTER_DIR_CANDIDATES[kind]
        if (project_path / d).is_dir()
    ]


def iter_source_files(dirs: List[Path]):
    """Yield source files (.ts/.tsx/.js/.jsx) under dirs, skipping node_modules."""
    seen = set()
    for d in dirs:
        for ext in SOURCE_EXTS:
            for file_path in d.rglob(ext):
                if "node_modules" in file_path.parts or file_path in seen:
                    continue
                seen.add(file_path)
                yield file_path


def find_next_config(project_path: Path) -> Optional[Path]:
    """Find Next.js config file."""
    config_names = [
        "next.config.ts",
        "next.config.mjs",
        "next.config.js",
        "next.config.cjs",
    ]
    for name in config_names:
        config_path = project_path / name
        if config_path.exists():
            return config_path
    return None


def get_next_version(project_path: Path) -> Optional[str]:
    """Get Next.js version from package.json."""
    package_json = project_path / "package.json"
    if not package_json.exists():
        return None

    try:
        with open(package_json, "r", encoding="utf-8") as f:
            data = json.load(f)
            deps = data.get("dependencies", {})
            dev_deps = data.get("devDependencies", {})
            return deps.get("next") or dev_deps.get("next")
    except (json.JSONDecodeError, IOError):
        return None


def analyze_file_patterns(project_path: Path) -> Dict[str, List[str]]:
    """Analyze App Router file patterns."""
    app_dirs = find_router_dirs(project_path, "app")
    if not app_dirs:
        return {"error": "No app/ or src/app/ directory found - not an App Router project"}

    results = {
        "app_dirs": [str(d.relative_to(project_path)) for d in app_dirs],
        "pages": [],
        "layouts": [],
        "loading_states": [],
        "error_boundaries": [],
        "route_handlers": [],
        "pages_with_loading": [],
        "pages_with_error": [],
        "dynamic_routes": [],
        "parallel_routes": [],
        "intercepting_routes": [],
        "route_groups": [],
    }

    for root, dirs, files in (w for app_dir in app_dirs for w in os.walk(app_dir)):
        dirs[:] = [d for d in dirs if d != "node_modules"]
        rel_path = Path(root).relative_to(project_path)
        path_str = str(rel_path)

        # Check for special route patterns
        dir_name = Path(root).name

        # Parallel routes (@folder)
        if dir_name.startswith("@"):
            results["parallel_routes"].append(path_str)

        # Intercepting routes: (.)x, (..)x, (..)(..)x, (...)x
        if re.match(r"^\(\.{1,3}\)", dir_name):
            results["intercepting_routes"].append(path_str)

        # Route groups
        elif dir_name.startswith("(") and dir_name.endswith(")"):
            results["route_groups"].append(path_str)

        # Dynamic routes
        if "[" in dir_name:
            results["dynamic_routes"].append(path_str)

        for file in files:
            file_path = f"{path_str}/{file}"

            if file in PATTERNS["pages"]:
                results["pages"].append(file_path)
            elif file in PATTERNS["layouts"]:
                results["layouts"].append(file_path)
            elif file in PATTERNS["loading"]:
                results["loading_states"].append(file_path)
            elif file in PATTERNS["error"]:
                results["error_boundaries"].append(file_path)
            elif file in PATTERNS["route"]:
                results["route_handlers"].append(file_path)

    # A loading.tsx / error.tsx covers its own segment and every nested one,
    # so a page is covered if its directory or any ancestor has the file.
    def covered(page: str, boundary_files: List[str]) -> bool:
        boundary_dirs = {str(Path(f).parent) for f in boundary_files}
        return any(str(d) in boundary_dirs for d in Path(page).parents)

    results["pages_with_loading"] = [
        p for p in results["pages"] if covered(p, results["loading_states"])
    ]
    results["pages_with_error"] = [
        p for p in results["pages"] if covered(p, results["error_boundaries"])
    ]

    return results


def check_client_components(project_path: Path) -> Dict[str, Any]:
    """Analyze 'use client' directive usage."""
    app_dirs = find_router_dirs(project_path, "app")
    if not app_dirs:
        return {"error": "No app/ or src/app/ directory found"}

    client_components = []
    server_components = []

    component_dirs = [
        project_path / d for d in COMPONENT_DIR_CANDIDATES if (project_path / d).is_dir()
    ]
    tsx_files = list(iter_source_files(app_dirs + component_dirs))

    for file_path in tsx_files:
        try:
            with open(file_path, "r", encoding="utf-8") as f:
                content = f.read()
                rel_path = str(file_path.relative_to(project_path))

                # Only a directive as the first statement makes a Client Component
                if USE_CLIENT_RE.match(content):
                    client_components.append(rel_path)
                else:
                    server_components.append(rel_path)
        except (IOError, UnicodeDecodeError):
            continue

    return {
        "client_components": client_components,
        "server_components": server_components,
        "client_ratio": len(client_components) / max(len(tsx_files), 1) * 100,
    }


def check_caching_patterns(project_path: Path) -> Dict[str, Any]:
    """Check for caching patterns and directives."""
    results = {
        "use_cache_files": [],
        "unstable_cache_files": [],
        "revalidate_calls": [],
        "cache_tags": [],
        "issues": [],
    }

    search_dirs = [
        project_path / d for d in ["app", "lib", "src"] if (project_path / d).is_dir()
    ]

    for file_path in iter_source_files(search_dirs):
        try:
            with open(file_path, "r", encoding="utf-8") as f:
                content = f.read()
                rel_path = str(file_path.relative_to(project_path))

                # Check for 'use cache' directive (Next.js 16)
                if "'use cache'" in content or '"use cache"' in content:
                    results["use_cache_files"].append(rel_path)

                # unstable_cache still works but is superseded by 'use cache'
                if "unstable_cache" in content:
                    results["unstable_cache_files"].append(rel_path)
                    results["issues"].append(
                        f"{rel_path}: Uses unstable_cache - superseded by 'use cache' "
                        f"when cacheComponents is enabled"
                    )

                # Check for revalidation
                if "revalidatePath" in content or "revalidateTag" in content:
                    results["revalidate_calls"].append(rel_path)

                # Check for cache tags
                cache_tag_matches = re.findall(r"cacheTag\(['\"]([^'\"]+)['\"]\)", content)
                results["cache_tags"].extend(cache_tag_matches)

        except (IOError, UnicodeDecodeError):
            continue

    results["cache_tags"] = list(set(results["cache_tags"]))
    return results


def blank_sync_param_signatures(content: str) -> str:
    """Replace the parameter lists of generateStaticParams/generateImageMetadata with spaces."""
    for m in list(SYNC_PARAMS_FUNC_RE.finditer(content)):
        depth, i = 0, m.end() - 1
        while i < len(content):
            if content[i] == "(":
                depth += 1
            elif content[i] == ")":
                depth -= 1
                if depth == 0:
                    break
            i += 1
        content = content[:m.end()] + " " * (i - m.end()) + content[i:]
    return content


def check_async_params(project_path: Path) -> Dict[str, Any]:
    """Check for async params pattern (Next.js 16 requirement)."""
    results = {
        "correct_pattern": [],
        "legacy_pattern": [],
        "needs_migration": [],
    }

    app_dirs = find_router_dirs(project_path, "app")
    for file_path in iter_source_files(app_dirs):
        if file_path.stem not in ASYNC_PARAMS_STEMS:
            continue

        try:
            with open(file_path, "r", encoding="utf-8") as f:
                content = f.read()
                rel_path = str(file_path.relative_to(project_path))

                # Blank out generateStaticParams/generateImageMetadata parameter
                # lists: their params are synchronous by design.
                content = blank_sync_param_signatures(content)

                # Legacy synchronous type annotation for params or searchParams,
                # e.g. `params: { slug: string }` - not arbitrary `params: {` literals
                if LEGACY_PARAMS_TYPE_RE.search(content):
                    results["legacy_pattern"].append(rel_path)
                    results["needs_migration"].append(rel_path)
                # Promise<...> typed params (correct)
                elif ASYNC_PARAMS_TYPE_RE.search(content):
                    results["correct_pattern"].append(rel_path)

        except (IOError, UnicodeDecodeError):
            continue

    return results


def check_server_actions(project_path: Path) -> Dict[str, Any]:
    """Analyze Server Actions usage."""
    results = {
        "action_files": [],
        "inline_actions": [],
        "uses_zod": False,
        "uses_safe_action": False,
        "issues": [],
    }

    search_dirs = [
        project_path / d for d in ["app", "lib", "src"] if (project_path / d).is_dir()
    ]

    for file_path in iter_source_files(search_dirs):
        try:
            with open(file_path, "r", encoding="utf-8") as f:
                content = f.read()
                rel_path = str(file_path.relative_to(project_path))

                if "'use server'" in content or '"use server"' in content:
                    # Path-segment match: actions.ts, actions/, _actions/, user.actions.ts
                    # - not "transactions.ts"
                    parts = [part.lower() for part in Path(rel_path).with_suffix("").parts]
                    if any(
                        part in ("actions", "_actions") or part.endswith(".actions")
                        for part in parts
                    ):
                        results["action_files"].append(rel_path)
                    else:
                        results["inline_actions"].append(rel_path)

                if "from 'zod'" in content or 'from "zod"' in content:
                    results["uses_zod"] = True

                if "next-safe-action" in content:
                    results["uses_safe_action"] = True

        except (IOError, UnicodeDecodeError):
            continue

    if not results["uses_zod"] and results["action_files"]:
        results["issues"].append(
            "Consider adding Zod for Server Action validation"
        )

    if not results["uses_safe_action"] and len(results["action_files"]) > 3:
        results["issues"].append(
            "Consider using next-safe-action for type-safe Server Actions"
        )

    return results


def check_proxy_middleware(project_path: Path) -> Dict[str, Any]:
    """Report proxy.ts / middleware.ts at the project root or in src/."""
    results = {"proxy": [], "middleware": [], "expected_dir": ".", "issues": []}

    uses_src = (project_path / "src" / "app").is_dir() and not (project_path / "app").is_dir()
    results["expected_dir"] = "src" if uses_src else "."

    for base in [project_path, project_path / "src"]:
        for kind in ("proxy", "middleware"):
            for name in PATTERNS[kind]:
                candidate = base / name
                if candidate.is_file():
                    results[kind].append(str(candidate.relative_to(project_path)))

    expected_prefix = "src/" if uses_src else ""
    for rel in results["proxy"] + results["middleware"]:
        in_src = rel.startswith("src/")
        if in_src != bool(expected_prefix):
            where = "src/" if uses_src else "the project root"
            results["issues"].append(
                f"{rel} is in the wrong place and is ignored - it must live in {where} "
                f"(next to the app directory)"
            )
    if results["proxy"] and results["middleware"]:
        results["issues"].append(
            "Both proxy and middleware files exist - keep only proxy.ts on Next.js 16"
        )
    return results


def parse_major_version(version: Optional[str]) -> Optional[int]:
    """Parse the major version from a semver range; None for tags like latest/canary."""
    if not version:
        return None
    match = re.match(r"^\s*[\^~>=<v\s]*(\d+)", version)
    return int(match.group(1)) if match else None


def generate_suggestions(analysis: Dict[str, Any]) -> List[str]:
    """Generate optimization suggestions based on analysis."""
    suggestions = []

    # Loading/error coverage: a page counts as covered when its segment or any
    # ancestor segment has loading.tsx / error.tsx (boundaries are inherited)
    patterns = analysis.get("file_patterns", {})
    pages_count = len(patterns.get("pages", []))
    loading_count = len(patterns.get("pages_with_loading", []))

    if pages_count > 0 and loading_count / pages_count < 0.5:
        suggestions.append(
            f"Add loading.tsx files - only {loading_count}/{pages_count} pages are under "
            f"a loading boundary (own or ancestor segment)"
        )

    error_count = len(patterns.get("pages_with_error", []))
    if pages_count > 0 and error_count / pages_count < 0.3:
        suggestions.append(
            f"Add error.tsx boundaries - only {error_count}/{pages_count} pages are under "
            f"an error boundary (own or ancestor segment)"
        )

    # Check client component ratio
    client_ratio = analysis.get("client_components", {}).get("client_ratio", 0)
    if client_ratio > 50:
        suggestions.append(
            f"High client component ratio ({client_ratio:.1f}%) - consider moving logic to Server Components"
        )

    # Check caching
    caching = analysis.get("caching", {})
    if caching.get("unstable_cache_files"):
        suggestions.append(
            "unstable_cache is superseded by the 'use cache' directive when "
            "cacheComponents is enabled (Next.js 16+)"
        )

    # proxy.ts / middleware.ts
    pm = analysis.get("proxy_middleware", {})
    suggestions.extend(pm.get("issues", []))
    if pm.get("middleware") and not pm.get("proxy"):
        pm_major = parse_major_version(analysis.get("version", ""))
        if pm_major is not None and pm_major >= 16:
            suggestions.append(
                "Rename middleware.ts to proxy.ts and export `proxy` instead of `middleware` "
                "(middleware is deprecated in Next.js 16)"
            )
        elif pm_major is None:
            suggestions.append(
                "If on Next.js 16, rename middleware.ts to proxy.ts and export `proxy` "
                "instead of `middleware` (middleware is deprecated in Next.js 16)"
            )

    # Check async params migration
    async_params = analysis.get("async_params", {})
    if async_params.get("needs_migration"):
        migration_count = len(async_params["needs_migration"])
        suggestions.append(
            f"Migrate {migration_count} file(s) to async params pattern (Next.js 16 requirement)"
        )

    # Version-specific suggestions
    version = analysis.get("version", "")
    major_version = parse_major_version(version)
    # Tags like "latest"/"canary" are unknown - no upgrade suggestion
    if major_version is not None and major_version < 16:
        suggestions.append(
            f"Consider upgrading from Next.js {version} to 16.x for Turbopack and Cache Components"
        )

    return suggestions


def analyze_project(project_path: str) -> Dict[str, Any]:
    """Run full analysis on a Next.js project."""
    path = Path(project_path)

    if not path.exists():
        return {"error": f"Path does not exist: {project_path}"}

    app_dirs = find_router_dirs(path, "app")
    pages_dirs = find_router_dirs(path, "pages")
    if not app_dirs and not pages_dirs:
        return {
            "error": f"No app/, src/app/, pages/ or src/pages/ directory found in "
                     f"{path.absolute()} - is this a Next.js project root?"
        }

    analysis = {
        "project_path": str(path.absolute()),
        "version": get_next_version(path),
        "config_file": str(find_next_config(path)) if find_next_config(path) else None,
        "file_patterns": analyze_file_patterns(path),
        "client_components": check_client_components(path),
        "caching": check_caching_patterns(path),
        "async_params": check_async_params(path),
        "server_actions": check_server_actions(path),
        "proxy_middleware": check_proxy_middleware(path),
        "app_dirs": [str(d.relative_to(path)) for d in app_dirs],
        "pages_dirs": [str(d.relative_to(path)) for d in pages_dirs],
    }

    analysis["suggestions"] = generate_suggestions(analysis)

    return analysis


def print_text_report(analysis: Dict[str, Any]):
    """Print human-readable analysis report."""
    print("\n" + "=" * 70)
    print("NEXT.JS PROJECT ANALYSIS")
    print("=" * 70)

    print(f"\nProject: {analysis['project_path']}")
    print(f"Next.js Version: {analysis['version'] or 'Unknown'}")
    print(f"Config File: {analysis['config_file'] or 'Not found'}")
    print(f"App Router dirs: {', '.join(analysis.get('app_dirs', [])) or 'None'}")
    if analysis.get("pages_dirs"):
        print(f"Pages Router dirs: {', '.join(analysis['pages_dirs'])} (not analyzed in detail)")

    # File patterns
    print("\n" + "-" * 70)
    print("FILE STRUCTURE")
    print("-" * 70)
    patterns = analysis.get("file_patterns", {})
    if isinstance(patterns, dict) and "error" not in patterns:
        print(f"  Pages: {len(patterns.get('pages', []))}")
        print(f"  Layouts: {len(patterns.get('layouts', []))}")
        pages_total = len(patterns.get('pages', []))
        print(f"  Loading States: {len(patterns.get('loading_states', []))} "
              f"(pages covered incl. inherited: {len(patterns.get('pages_with_loading', []))}/{pages_total})")
        print(f"  Error Boundaries: {len(patterns.get('error_boundaries', []))} "
              f"(pages covered incl. inherited: {len(patterns.get('pages_with_error', []))}/{pages_total})")
        print(f"  Route Handlers (route.ts): {len(patterns.get('route_handlers', []))}")
        print(f"  Dynamic Routes: {len(patterns.get('dynamic_routes', []))}")
        print(f"  Parallel Routes: {len(patterns.get('parallel_routes', []))}")
        print(f"  Intercepting Routes: {len(patterns.get('intercepting_routes', []))}")
        print(f"  Route Groups: {len(patterns.get('route_groups', []))}")

    # Component analysis
    print("\n" + "-" * 70)
    print("COMPONENT ANALYSIS")
    print("-" * 70)
    components = analysis.get("client_components", {})
    if "error" not in components:
        print(f"  Server Components: {len(components.get('server_components', []))}")
        print(f"  Client Components: {len(components.get('client_components', []))}")
        print(f"  Client Ratio: {components.get('client_ratio', 0):.1f}% "
              f"(app dir(s) + components/, src/components/)")

    # Caching
    print("\n" + "-" * 70)
    print("CACHING")
    print("-" * 70)
    caching = analysis.get("caching", {})
    print(f"  'use cache' Files: {len(caching.get('use_cache_files', []))}")
    print(f"  unstable_cache (superseded by 'use cache'): {len(caching.get('unstable_cache_files', []))}")
    print(f"  Revalidation Calls: {len(caching.get('revalidate_calls', []))}")
    print(f"  Cache Tags: {len(caching.get('cache_tags', []))}")

    # Server Actions
    print("\n" + "-" * 70)
    print("SERVER ACTIONS")
    print("-" * 70)
    actions = analysis.get("server_actions", {})
    print(f"  Action Files: {len(actions.get('action_files', []))}")
    print(f"  Inline Actions: {len(actions.get('inline_actions', []))}")
    print(f"  Uses Zod: {'Yes' if actions.get('uses_zod') else 'No'}")
    print(f"  Uses next-safe-action: {'Yes' if actions.get('uses_safe_action') else 'No'}")

    # Proxy / Middleware
    print("\n" + "-" * 70)
    print("PROXY / MIDDLEWARE")
    print("-" * 70)
    pm = analysis.get("proxy_middleware", {})
    print(f"  proxy: {', '.join(pm.get('proxy', [])) or 'none'}")
    print(f"  middleware: {', '.join(pm.get('middleware', [])) or 'none'}")
    print(f"  Expected location: {pm.get('expected_dir', '.')}/")

    # Async Params Check
    print("\n" + "-" * 70)
    print("ASYNC PARAMS (Next.js 16)")
    print("-" * 70)
    async_params = analysis.get("async_params", {})
    print(f"  Correct Pattern: {len(async_params.get('correct_pattern', []))}")
    print(f"  Legacy Pattern (needs migration): {len(async_params.get('legacy_pattern', []))}")
    for rel in async_params.get("legacy_pattern", []):
        print(f"    - {rel}")

    # Suggestions
    print("\n" + "-" * 70)
    print("SUGGESTIONS")
    print("-" * 70)
    suggestions = analysis.get("suggestions", [])
    if suggestions:
        for i, suggestion in enumerate(suggestions, 1):
            print(f"  {i}. {suggestion}")
    else:
        print("  No suggestions - project looks good!")

    print("\n" + "=" * 70 + "\n")


def main():
    parser = argparse.ArgumentParser(
        description="Analyze Next.js project structure and provide optimization suggestions."
    )
    parser.add_argument(
        "--path",
        "-p",
        default=".",
        help="Path to Next.js project (default: current directory)",
    )
    parser.add_argument(
        "--report",
        "-r",
        choices=["text", "json"],
        default="text",
        help="Output format (default: text)",
    )
    parser.add_argument(
        "--check-version",
        action="store_true",
        help="Only check Next.js version",
    )

    args = parser.parse_args()

    if args.check_version:
        version = get_next_version(Path(args.path))
        if version:
            print(f"Next.js version: {version}")
        else:
            print("Could not determine Next.js version")
        if version and parse_major_version(version) is None:
            print("  (not a numeric version - e.g. a dist-tag; treated as unknown)")
        return 0

    analysis = analyze_project(args.path)

    if "error" in analysis:
        if args.report == "json":
            print(json.dumps(analysis, indent=2))
        else:
            print(f"Error: {analysis['error']}")
        return 1

    if args.report == "json":
        print(json.dumps(analysis, indent=2))
    else:
        print_text_report(analysis)
    return 0


if __name__ == "__main__":
    sys.exit(main())
