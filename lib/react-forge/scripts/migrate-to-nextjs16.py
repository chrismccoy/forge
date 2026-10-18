#!/usr/bin/env python3
"""
Migration helper for Next.js 16 breaking changes.

Focuses on the async params migration which is the primary breaking change.
Scans both `app/` and `src/app/`. Only rewrites patterns it can migrate safely
(Server Component pages/layouts, opengraph-image/twitter-image/icon/apple-icon,
generateMetadata/generateViewport and route handlers declared with
`export function`). generateStaticParams and generateImageMetadata keep
synchronous params in Next.js 16 and are never rewritten or reported. Client Components ('use client')
and anything else ambiguous are reported for manual migration instead.

--apply writes a `<file>.bak` copy of every file before modifying it (and
refuses to touch a file whose .bak already exists). Committing or stashing
your work in git first is still recommended.

Usage:
    python migrate-to-nextjs16.py --path ./my-nextjs-app --check
    python migrate-to-nextjs16.py --path ./my-nextjs-app --dry-run
    python migrate-to-nextjs16.py --path ./my-nextjs-app --apply
    python migrate-to-nextjs16.py --path ./my-nextjs-app --json

Official alternative (run from the project root):
    npx @next/codemod@canary upgrade latest
"""

import argparse
import difflib
import re
import shlex
from pathlib import Path
from typing import List, Optional, Tuple
import json
import sys


# Candidate App Router directories, relative to the project root
APP_DIR_CANDIDATES = ['app', 'src/app']

# A single `key: string` / `key?: string[]` entry in an inline params type
_PARAM_ENTRY = r'\s*[\w$]+\??\s*:\s*string(?:\[\])?\s*'

# Patterns to detect and migrate: (compiled regex, replacement, description)
LEGACY_PARAMS_PATTERNS = [
    # params: { slug: string } / { slug: string[] } / { a: string; b: string[] }
    (
        re.compile(
            r'(?<![\w$.])params(\??)\s*:\s*\{(' + _PARAM_ENTRY
            + r'(?:[;,]' + _PARAM_ENTRY + r')*[;,]?\s*)\}'
        ),
        r'params\1: Promise<{\2}>',
        'params type'
    ),
    # searchParams: { [key: string]: string | string[] | undefined }
    (
        re.compile(
            r'(?<![\w$.])searchParams(\??)\s*:\s*(\{\s*\[\s*\w+\s*:\s*string\s*\]\s*:'
            r'\s*string\s*\|\s*string\[\]\s*\|\s*undefined\s*;?\s*\})'
        ),
        r'searchParams\1: Promise<\2>',
        'searchParams type'
    ),
]

# const { slug } = params;   (not already awaited, not params.x / params[...])
DESTRUCTURE_RE = re.compile(
    r'((?:const|let)\s*\{[^{}]*\}\s*=\s*)(params|searchParams)(?=\s*(?:;|\n|\r|$))'
)

# `params: {` / `searchParams: {` - a nested destructuring pattern when it sits
# inside a parameter-list pattern (see find_nested_param_destructuring)
NESTED_DESTRUCTURE_RE = re.compile(r'(?<![\w$.])(params|searchParams)\s*:\s*\{')

# A `{` that starts a parameter: right after `(` or `,`
PARAM_PATTERN_OPEN_RE = re.compile(r'[(,]\s*(\{)')

# What follows a destructuring parameter pattern: its type annotation, a
# default value, or the end of the parameter list followed by `=>` / a body /
# a return type. (A call argument `f({ params: { ... } })` is followed by
# `)` and then `;` or similar, so it is not matched.)
PARAM_PATTERN_END_RE = re.compile(r'\s*(?::|=(?![=>])|\)\s*(?:=>|\{|:))')

# Synchronous member access: params.slug, params?.slug, searchParams.foo, params['x']
ACCESS_RE = re.compile(r'(?<![\w$])(params|searchParams)\s*(?:\?\.|\.|\[)\s*([\w$]*)')

# URLSearchParams methods - `searchParams.get(...)` etc. is not the page prop
URLSEARCHPARAMS_METHODS = {
    'get', 'getAll', 'has', 'set', 'append', 'delete', 'entries', 'keys',
    'values', 'forEach', 'toString', 'size', 'sort',
}

# Exported functions that receive params/searchParams as a Promise in Next.js 16
# (plus the default export: page/layout/default/template and image generators)
ASYNC_TARGETS = {
    'generateMetadata', 'generateViewport',
    'GET', 'HEAD', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS',
}

# Functions whose `params` stay SYNCHRONOUS in Next.js 16. Their params types and
# accesses are never rewritten or reported. (nextjs.org version-16 upgrade guide:
# "The generateImageMetadata function continues to receive synchronous params";
# generateStaticParams receives the parent segments' params synchronously.)
SYNC_PARAMS_FUNCS = ('generateStaticParams', 'generateImageMetadata')
SYNC_FUNC_RE = re.compile(
    r'(?<![\w$.])(?:function\s*\*?\s*(?:' + '|'.join(SYNC_PARAMS_FUNCS) + r')\s*(?:<[^>()]*>)?\s*\('
    r'|(?:' + '|'.join(SYNC_PARAMS_FUNCS) + r')\s*(?::[^=]+)?=\s*(?:async\s*)?(?:function\s*)?\()'
)

FUNC_RE = re.compile(
    r'export\s+(default\s+)?(async\s+)?function\s*([\w$]*)\s*(?:<[^>()]*>)?\s*\('
)

# Tolerates a leading UTF-8 BOM (as nextjs-analyzer.py does)
USE_CLIENT_RE = re.compile(r'^\ufeff?\s*(?:(?://[^\n]*|/\*.*?\*/)\s*)*[\'"]use client[\'"]', re.S)

# Files to analyze (by stem; any of these extensions). The metadata image files
# get async `params` (and `id`) in Next.js 16 per the official upgrade guide.
# sitemap is not listed: its change is an async `id`, not params.
TARGET_STEMS = {
    'page', 'layout', 'route', 'default', 'template',
    'opengraph-image', 'twitter-image', 'icon', 'apple-icon',
}
TARGET_EXTS = {'.tsx', '.ts', '.jsx', '.js'}


class MigrationFile:
    """Represents a file that needs migration (automatic and/or manual)."""

    def __init__(self, path: Path, original: str, migrated: str,
                 changes: List[str], manual: Optional[List[str]] = None):
        self.path = path
        self.original = original
        self.migrated = migrated
        self.changes = changes
        self.manual = manual or []

    @property
    def is_manual(self) -> bool:
        return bool(self.manual)


def find_app_dirs(project_path: Path) -> List[Path]:
    """Return existing App Router directories (app/ and/or src/app/)."""
    return [project_path / d for d in APP_DIR_CANDIDATES if (project_path / d).is_dir()]


def is_client_file(content: str) -> bool:
    """True if the file starts with a 'use client' directive."""
    return bool(USE_CLIENT_RE.match(content))


def _skip_trivia(text: str, i: int) -> int:
    """If text[i] starts a comment or single-line string, return index after it; else i."""
    ch = text[i]
    nxt = text[i + 1] if i + 1 < len(text) else ''
    if ch == '/' and nxt == '/':
        end = text.find('\n', i)
        return len(text) if end == -1 else end
    if ch == '/' and nxt == '*':
        end = text.find('*/', i + 2)
        return len(text) if end == -1 else end + 2
    if ch in ('"', "'", '`'):
        j = i + 1
        while j < len(text):
            if text[j] == '\\':
                j += 2
                continue
            if text[j] == ch:
                return j + 1
            if text[j] == '\n' and ch != '`':
                break  # unterminated on this line - e.g. an apostrophe in JSX text
            j += 1
        return i
    return i


def _find_matching(text: str, open_idx: int, open_ch: str, close_ch: str) -> int:
    """Return index of the bracket matching text[open_idx], or -1."""
    depth = 0
    i = open_idx
    while i < len(text):
        skipped = _skip_trivia(text, i)
        if skipped != i:
            i = skipped
            continue
        if text[i] == open_ch:
            depth += 1
        elif text[i] == close_ch:
            depth -= 1
            if depth == 0:
                return i
        i += 1
    return -1


def _find_body(content: str, paren_close: int) -> Optional[Tuple[int, int]]:
    """
    Given the index of a parameter list's closing paren, return (body_start,
    body_end) of the function body's braces, skipping a return type annotation
    (Promise<{ ... }> etc. are skipped by matching angle brackets).
    """
    i = paren_close + 1
    while i < len(content) and content[i] != '{':
        if content[i] == '<':
            close = _find_matching(content, i, '<', '>')
            if close == -1:
                break
            i = close
        i += 1
    if i >= len(content):
        return None
    body_end = _find_matching(content, i, '{', '}')
    if body_end == -1:
        return None
    return i, body_end


def find_target_functions(content: str) -> List[Tuple[int, int, int, int, bool]]:
    """
    Locate exported functions that receive async params.

    Returns (function_keyword_index, paren_close, body_start, body_end, is_async) tuples.
    """
    spans = []
    for m in FUNC_RE.finditer(content):
        is_default = bool(m.group(1))
        name = m.group(3)
        if not is_default and name not in ASYNC_TARGETS:
            continue
        paren_open = m.end() - 1
        paren_close = _find_matching(content, paren_open, '(', ')')
        if paren_close == -1:
            continue
        body = _find_body(content, paren_close)
        if body is None:
            continue
        func_kw = content.index('function', m.start())
        spans.append((func_kw, paren_close, body[0], body[1], bool(m.group(2))))
    return spans


def find_sync_param_ranges(content: str) -> List[Tuple[int, int]]:
    """
    Return (start, end) spans of generateStaticParams / generateImageMetadata,
    from the name through the end of the body. Their params stay synchronous
    in Next.js 16, so nothing inside these spans is rewritten or reported.
    """
    ranges = []
    for m in SYNC_FUNC_RE.finditer(content):
        paren_open = m.end() - 1
        paren_close = _find_matching(content, paren_open, '(', ')')
        if paren_close == -1:
            # Unparseable: protect to the end of the file rather than rewrite it
            ranges.append((m.start(), len(content)))
            continue
        end = paren_close
        arrow = re.compile(r'\s*(?::[^=]*?)?=>\s*([(\[])').match(content, paren_close + 1)
        if arrow:
            # Arrow with an expression body: `=> ({ ... })` / `=> [ ... ]`
            open_ch = arrow.group(1)
            close = _find_matching(content, arrow.start(1), open_ch, ')' if open_ch == '(' else ']')
            end = close if close != -1 else len(content)
        else:
            body = _find_body(content, paren_close)
            if body is not None:
                end = body[1]
        ranges.append((m.start(), end + 1))
    return ranges


def _in_ranges(idx: int, ranges: List[Tuple[int, int]]) -> bool:
    return any(start <= idx < end for start, end in ranges)


def _top_level_blocks(content: str) -> List[Tuple[int, int]]:
    """(open, close) indices of every top-level {...} block (function bodies etc.)."""
    blocks = []
    i = 0
    while i < len(content):
        skipped = _skip_trivia(content, i)
        if skipped != i:
            i = skipped
            continue
        if content[i] == '{':
            close = _find_matching(content, i, '{', '}')
            if close == -1:
                break
            blocks.append((i, close))
            i = close + 1
            continue
        i += 1
    return blocks


def find_sync_access(content: str) -> List[str]:
    """
    Find synchronous `params.x` / `searchParams.x` access that needs manual work.

    An access is only excused when the name was rebound to the awaited value
    (`const params = await props.params`) EARLIER IN THE SAME top-level function
    body; a rebinding in another function does not cover it. Accesses inside
    generateStaticParams / generateImageMetadata are synchronous by design.
    """
    found = []
    sync_ranges = find_sync_param_ranges(content)
    blocks = _top_level_blocks(content)
    for m in ACCESS_RE.finditer(content):
        name, member = m.group(1), m.group(2)
        if name == 'searchParams' and member in URLSEARCHPARAMS_METHODS:
            continue
        if _in_ranges(m.start(), sync_ranges):
            continue
        block = next(((b0, b1) for b0, b1 in blocks if b0 < m.start() < b1), None)
        if block is not None and re.search(
                r'(?:const|let|var)\s+' + name + r'\s*=\s*(?:await\b|use\s*\()',
                content[block[0]:m.start()]):
            continue
        found.append(m.group(0).strip())
    return sorted(set(found))


def find_nested_param_destructuring(content: str) -> List[str]:
    """
    Find `({ params: { slug } }: ...)` - params/searchParams destructured in a
    function's parameter list. The type can be rewritten to Promise<...>, but
    `slug` would then be read off the Promise, so these need manual work.
    Type annotations (`: { params: { slug: string } }`) are not matched: they
    follow a `:`, not a `(` or `,`.
    """
    found = []
    sync_ranges = find_sync_param_ranges(content)
    for m in PARAM_PATTERN_OPEN_RE.finditer(content):
        open_idx = m.start(1)
        if _in_ranges(open_idx, sync_ranges):
            continue
        close_idx = _find_matching(content, open_idx, '{', '}')
        if close_idx == -1 or not PARAM_PATTERN_END_RE.match(content, close_idx + 1):
            continue
        for n in NESTED_DESTRUCTURE_RE.finditer(content, open_idx + 1, close_idx):
            found.append(n.group(1))
    return sorted(set(found))


def _sub_outside(pattern, replacement: str, content: str) -> Tuple[str, int]:
    """pattern.subn(), skipping matches inside synchronous-params functions."""
    ranges = find_sync_param_ranges(content)
    count = 0

    def repl(m):
        nonlocal count
        if _in_ranges(m.start(), ranges):
            return m.group(0)
        count += 1
        return m.expand(replacement)

    return pattern.sub(repl, content), count


def migrate_file_content(content: str) -> Tuple[str, List[str], List[str]]:
    """
    Migrate file content to Next.js 16 patterns.

    Returns (migrated_content, automatic_changes, manual_issues). When
    manual_issues is non-empty the migrated content must NOT be written:
    the file is only partially understood and is left for manual migration.
    """
    changes = []
    manual = []

    if is_client_file(content):
        ranges = find_sync_param_ranges(content)
        legacy_type = any(not _in_ranges(m.start(), ranges)
                          for p, _, _ in LEGACY_PARAMS_PATTERNS for m in p.finditer(content))
        destructure = any(not _in_ranges(m.start(), ranges)
                          for m in DESTRUCTURE_RE.finditer(content))
        if legacy_type or destructure or find_sync_access(content) \
                or find_nested_param_destructuring(content):
            manual.append(
                "'use client' file: Client Components cannot be async. Type params as "
                "Promise<...> and unwrap with `const { x } = use(params)` "
                "(import { use } from 'react'), or use useParams()/useSearchParams()"
            )
        return content, [], manual

    migrated = content

    # Migrate type definitions (not inside generateStaticParams/generateImageMetadata,
    # whose params stay synchronous)
    for pattern, replacement, desc in LEGACY_PARAMS_PATTERNS:
        migrated, n = _sub_outside(pattern, replacement, migrated)
        if n:
            changes.append(f"Updated {desc} to Promise pattern ({n}x)")

    # Add await to destructuring inside exported page/layout/metadata/route functions,
    # processing from the end so earlier offsets stay valid.
    for func_kw, paren_close, body_start, body_end, is_async in \
            reversed(find_target_functions(migrated)):
        body = migrated[body_start:body_end]
        new_body, n = DESTRUCTURE_RE.subn(r'\1await \2', body)
        if not n:
            continue
        migrated = migrated[:body_start] + new_body + migrated[body_end:]
        changes.append(f"Added await to params/searchParams destructuring ({n}x)")
        if not is_async:
            # An async function must return Promise<T>: wrap an explicit return type
            ret = migrated[paren_close + 1:body_start]
            ret_match = re.match(r'^(\s*:\s*)(.*?)(\s*)$', ret, re.S)
            if ret_match and ret_match.group(2) and not ret_match.group(2).startswith('Promise<'):
                new_ret = f"{ret_match.group(1)}Promise<{ret_match.group(2)}>{ret_match.group(3)}"
                migrated = migrated[:paren_close + 1] + new_ret + migrated[body_start:]
                changes.append(f"Wrapped return type in Promise<{ret_match.group(2)}>")
            migrated = migrated[:func_kw] + 'async ' + migrated[func_kw:]
            fname = re.match(r'function\s*([\w$]*)', migrated[func_kw + 6:])
            changes.append(f"Made function {fname.group(1) if fname and fname.group(1) else '(default)'} async")

    # Anything left over cannot be migrated safely by this script
    sync_ranges = find_sync_param_ranges(migrated)
    leftover = [m for m in DESTRUCTURE_RE.finditer(migrated)
                if not _in_ranges(m.start(), sync_ranges)]
    if leftover:
        manual.append(
            "params/searchParams destructured outside an `export function` "
            "(arrow function or helper) - await or use() it manually"
        )
    nested = find_nested_param_destructuring(migrated)
    if nested:
        manual.append(
            "Nested destructuring of " + ', '.join(f'`{n}: {{ ... }}`' for n in nested)
            + " in a parameter list - destructure only `{ params }`, then "
            "`const { x } = await params` in the body"
        )
    access = find_sync_access(migrated)
    if access:
        manual.append(
            "Synchronous access " + ', '.join(access[:5])
            + " - first `const p = await params` (or `await searchParams`) and use that"
        )

    return migrated, changes, manual


def analyze_project(project_path: Path, app_dirs: List[Path]) -> List[MigrationFile]:
    """Analyze project for files needing migration."""
    files_to_migrate = []

    for app_dir in app_dirs:
        for file_path in sorted(app_dir.rglob('*')):
            if file_path.stem not in TARGET_STEMS or file_path.suffix not in TARGET_EXTS:
                continue
            if 'node_modules' in file_path.parts or not file_path.is_file():
                continue

            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    content = f.read()
            except (IOError, UnicodeDecodeError) as e:
                print(f"Warning: Could not read {file_path}: {e}")
                continue

            migrated, changes, manual = migrate_file_content(content)

            if changes or manual:
                files_to_migrate.append(MigrationFile(
                    path=file_path,
                    original=content,
                    migrated=migrated,
                    changes=changes,
                    manual=manual,
                ))

    return files_to_migrate


def _print_manual(file: MigrationFile, project_path: Path):
    rel_path = file.path.relative_to(project_path)
    print(f"  ! {rel_path}  (MANUAL - not modified)")
    for issue in file.manual:
        print(f"      - {issue}")


def print_check_report(files: List[MigrationFile], project_path: Path):
    """Print check report without making changes."""
    print("\n" + "=" * 70)
    print("NEXT.JS 16 MIGRATION CHECK")
    print("=" * 70)

    auto = [f for f in files if not f.is_manual]
    manual = [f for f in files if f.is_manual]

    if not files:
        print("\nNo legacy params/searchParams patterns found in the scanned files.")
        return

    if auto:
        print(f"\n{len(auto)} file(s) can be migrated automatically:\n")
        for i, file in enumerate(auto, 1):
            print(f"{i}. {file.path.relative_to(project_path)}")
            for change in file.changes:
                print(f"   - {change}")
            print()

    if manual:
        print(f"\n{len(manual)} file(s) need MANUAL migration:\n")
        for file in manual:
            _print_manual(file, project_path)
        print()

    print("-" * 70)
    print("Run with --dry-run to see proposed changes")
    print("Run with --apply to apply migrations (writes <file>.bak backups)")
    print("=" * 70 + "\n")


def print_dry_run_report(files: List[MigrationFile], project_path: Path):
    """Print detailed dry run report with diffs."""
    print("\n" + "=" * 70)
    print("NEXT.JS 16 MIGRATION - DRY RUN")
    print("=" * 70)

    if not files:
        print("\nNo files need migration.")
        return

    auto = [f for f in files if not f.is_manual]
    for file in auto:
        rel_path = str(file.path.relative_to(project_path))
        print(f"\n{'─' * 70}")
        print(f"File: {rel_path}")
        print(f"Changes: {', '.join(file.changes)}")
        print("─" * 70)

        diff = difflib.unified_diff(
            file.original.splitlines(),
            file.migrated.splitlines(),
            fromfile=rel_path,
            tofile=rel_path,
            lineterm='',
        )
        for line in diff:
            print(line)

    manual = [f for f in files if f.is_manual]
    if manual:
        print(f"\n{'─' * 70}")
        print("Files requiring MANUAL migration (will not be modified):")
        for file in manual:
            _print_manual(file, project_path)

    print("\n" + "=" * 70)
    print(f"Files to migrate automatically: {len(auto)}; manual: {len(manual)}")
    print("Run with --apply to apply these changes (writes <file>.bak backups)")
    print("=" * 70 + "\n")


def apply_migrations(files: List[MigrationFile], project_path: Path) -> int:
    """Apply migrations to files, writing a .bak backup of each first."""
    applied = 0
    errors = []
    backups_written: List[Path] = []
    auto = [f for f in files if not f.is_manual]

    for file in auto:
        rel_path = file.path.relative_to(project_path)
        backup = file.path.with_name(file.path.name + '.bak')
        if backup.exists():
            errors.append(f"{rel_path}: backup {backup.name} already exists - "
                          f"remove it first; file not modified")
            continue
        try:
            backup.write_text(file.original, encoding='utf-8')
            backups_written.append(backup.relative_to(project_path))
            with open(file.path, 'w', encoding='utf-8') as f:
                f.write(file.migrated)
            applied += 1
            print(f"✓ Migrated: {rel_path}  (backup: {backup.name})")
            for change in file.changes:
                print(f"  - {change}")
        except IOError as e:
            errors.append(f"{rel_path}: {e}")

    print(f"\nMigrated {applied}/{len(auto)} file(s)")

    manual = [f for f in files if f.is_manual]
    if manual:
        print(f"\n{len(manual)} file(s) need MANUAL migration (not modified):")
        for file in manual:
            _print_manual(file, project_path)

    if errors:
        print("\nErrors:")
        for error in errors:
            print(f"  ✗ {error}")

    if backups_written:
        print("\nBackups written (NOT git-ignored):")
        for backup_path in backups_written:
            print(f"  {backup_path}")
        print("\nNext steps:")
        print("  1. Review the changes (e.g. `git diff`) and run a type check / build.")
        print("  2. Delete exactly these backups once satisfied (run from the project root):")
        print("       rm -- " + " ".join(shlex.quote(str(b)) for b in backups_written))

    return applied


def generate_codemod_command(project_path: Path) -> str:
    """Generate the official codemod command (run from the project root)."""
    return "npx @next/codemod@canary upgrade latest"


def main():
    parser = argparse.ArgumentParser(
        description="Migration helper for Next.js 16 async params breaking change."
    )
    parser.add_argument(
        "--path",
        "-p",
        default=".",
        help="Path to Next.js project (default: current directory)",
    )
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument(
        "--check",
        "-c",
        action="store_true",
        help="Check which files need migration (no changes)",
    )
    mode.add_argument(
        "--dry-run",
        "-d",
        action="store_true",
        help="Show proposed changes as a diff without applying them",
    )
    mode.add_argument(
        "--apply",
        "-a",
        action="store_true",
        help="Apply migrations (writes <file>.bak before modifying each file)",
    )
    parser.add_argument(
        "--json",
        "-j",
        action="store_true",
        help="Output results as JSON",
    )

    args = parser.parse_args()
    project_path = Path(args.path).resolve()

    if not project_path.exists():
        print(f"Error: Path does not exist: {project_path}")
        return 1

    # Check for package.json
    if not (project_path / "package.json").exists():
        print(f"Warning: No package.json found at {project_path}")

    app_dirs = find_app_dirs(project_path)
    if not app_dirs:
        msg = (f"Error: No App Router directory found at {project_path} "
               f"(looked for: {', '.join(APP_DIR_CANDIDATES)}). Nothing was checked.")
        if args.json:
            print(json.dumps({"error": msg}, indent=2))
        else:
            print(msg)
        return 1

    if not args.json:
        print(f"Analyzing project at: {project_path}")
        print(f"Scanning: {', '.join(str(d.relative_to(project_path)) for d in app_dirs)}")

    files = analyze_project(project_path, app_dirs)

    if args.json:
        result = {
            "project_path": str(project_path),
            "scanned_dirs": [str(d.relative_to(project_path)) for d in app_dirs],
            "files_to_migrate": len([f for f in files if not f.is_manual]),
            "files_manual": len([f for f in files if f.is_manual]),
            "files": [
                {
                    "path": str(f.path.relative_to(project_path)),
                    "changes": f.changes if not f.is_manual else [],
                    "manual": f.manual,
                }
                for f in files
            ],
            "codemod_command": generate_codemod_command(project_path)
        }
        print(json.dumps(result, indent=2))
        return 0

    if args.apply:
        if not files:
            print("No files need migration.")
            return 0
        print("\nNote: a <file>.bak backup is written before each change. "
              "A clean git working tree is still recommended.")
        print(f"\nApplying migrations...\n")
        apply_migrations(files, project_path)
    elif args.dry_run:
        print_dry_run_report(files, project_path)
    else:  # --check or default
        print_check_report(files, project_path)

    # Always show the official codemod option
    if files:
        print("\nAlternatively, use the official codemod (from the project root):")
        print(f"  {generate_codemod_command(project_path)}")
        print()

    return 0


if __name__ == "__main__":
    sys.exit(main())
