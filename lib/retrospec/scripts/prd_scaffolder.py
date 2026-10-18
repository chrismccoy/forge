#!/usr/bin/env python3
"""Scaffold PRD directory structure from codebase_analyzer.py output.

Reads analysis JSON and creates the prd/ directory with README.md,
per-page stubs, per-resource backend stubs, and appendix files
pre-populated with extracted data.

Stdlib only — no third-party dependencies.

Usage:
    python3 codebase_analyzer.py /path/to/project -o analysis.json
    python3 prd_scaffolder.py analysis.json
    python3 prd_scaffolder.py analysis.json --output-dir ./prd --project-name "My App"

Refuses to write into a non-empty output directory unless --force is given.
"""

import argparse
import json
import re
import sys
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, List, Optional


def slugify(text: str) -> str:
    """Convert text to a filename-safe slug."""
    text = text.strip().lower()
    text = re.sub(r"[/:{}*?\"<>|]", "-", text)
    text = re.sub(r"[^a-z0-9\-]", "-", text)
    text = re.sub(r"-+", "-", text)
    return text.strip("-")


def _is_param(segment: str) -> bool:
    return segment.startswith((":", "*")) or "{" in segment


def route_to_page_name(route: str) -> str:
    """Convert a route path to a human-readable page name."""
    if route == "/" or route == "":
        return "Home"
    parts = [p for p in route.strip("/").split("/") if p]
    # Remove dynamic segments for naming
    clean = [p for p in parts if not _is_param(p)]
    if not clean:
        clean = [p.lstrip(":*@") for p in parts]
    name = " ".join(w.capitalize() for w in "-".join(clean).replace("_", "-").split("-") if w)
    if not name:
        return "Catch-all"
    if parts and _is_param(parts[-1]) and len(clean) < len(parts):
        name += " Detail"
    return name


def resource_name(path: str) -> str:
    """First meaningful static segment: `/api/v1/users/:id` → `users`."""
    parts = [p for p in path.strip("/").split("/") if p and not _is_param(p)]
    while parts and (parts[0] == "api" or re.fullmatch(r"v\d+", parts[0])):
        parts.pop(0)
    return parts[0] if parts else "root"


def frontend_pages(analysis: Dict[str, Any]) -> List[Dict]:
    routes = analysis.get("routes", {})
    if "frontend_pages" in routes:
        return routes["frontend_pages"]
    return [r for r in routes.get("pages", []) if r.get("type") != "backend"]


def backend_endpoints(analysis: Dict[str, Any]) -> List[Dict]:
    routes = analysis.get("routes", {})
    if "backend_endpoints" in routes:
        return routes["backend_endpoints"]
    return [r for r in routes.get("pages", []) if r.get("type") == "backend"]


def plan_page_files(analysis: Dict[str, Any]) -> List[Dict[str, Any]]:
    """Decide every file under pages/: one per frontend page, then one per backend resource group.

    Each entry has kind ("page" or "resource"), name, route, filename, and either
    the page route dict or the list of grouped endpoints.
    """
    used = set()

    def unique(slug: str) -> str:
        candidate, n = slug, 2
        while candidate in used:
            candidate = f"{slug}-{n}"
            n += 1
        used.add(candidate)
        return candidate

    files: List[Dict[str, Any]] = []
    for page in frontend_pages(analysis):
        path = page.get("path", "/")
        name = route_to_page_name(path)
        files.append({"kind": "page", "name": name, "route": path, "page": page,
                      "slug": unique(slugify(name) or "page")})

    groups: Dict[str, List[Dict]] = {}
    for ep in backend_endpoints(analysis):
        groups.setdefault(resource_name(ep.get("path", "/")), []).append(ep)
    for resource, endpoints in groups.items():
        base = min((e.get("path", "/") for e in endpoints), key=len)
        name = " ".join(w.capitalize() for w in re.split(r"[-_]", resource) if w) + " Endpoints"
        files.append({"kind": "resource", "name": name, "route": base, "endpoints": endpoints,
                      "slug": unique(f"{slugify(resource) or 'root'}-endpoints")})

    for i, f in enumerate(files, 1):
        f["filename"] = f"{i:02d}-{f['slug']}.md"
    return files


def generate_readme(project_name: str, files: List[Dict[str, Any]]) -> str:
    """Generate the PRD README.md."""
    lines = [
        f"# {project_name} — Product Requirements Document",
        "",
        "## System Overview",
        "",
        f"<!-- TODO: Describe what {project_name} does, its business context, and primary users -->",
        "",
        "## Module Overview",
        "",
        "| Module | Pages | Core Functionality |",
        "|--------|-------|--------------------|",
        "| <!-- TODO: Group pages into modules --> | | |",
        "",
        "## Page Inventory",
        "",
        "| # | Page Name | Route | Module | Doc Link |",
        "|---|-----------|-------|--------|----------|",
    ]

    for i, f in enumerate(files, 1):
        lines.append(f"| {i} | {f['name']} | `{f['route']}` | <!-- TODO --> | [→](./pages/{f['filename']}) |")

    lines.extend([
        "",
        "Full endpoint list: [API Inventory](./appendix/api-inventory.md). "
        "Status and type values: [Enum Dictionary](./appendix/enum-dictionary.md). "
        "Navigation map: [Page Relationships](./appendix/page-relationships.md).",
        "",
        "## Global Notes",
        "",
        "### Permission Model",
        "<!-- TODO: Summarize auth/role system if present -->",
        "",
        "### Common Interaction Patterns",
        "<!-- TODO: Global rules — delete confirmations, default sort, etc. -->",
        "",
    ])

    return "\n".join(lines)


def generate_page_stub(entry: Dict[str, Any], date: str) -> str:
    """Generate a per-page PRD stub."""
    page = entry["page"]
    source = page.get("source", "unknown")
    view = page.get("view")
    view_line = f"\n> **View template:** `{view}`" if view else ""
    if page.get("inferred"):
        view_line = "\n> **View template:** <!-- TODO: not resolved by the analyzer; confirm this route renders a page -->"

    return f"""# {entry['name']}

> **Route:** `{entry['route']}`
> **Module:** <!-- TODO -->
> **Source:** `{source}`{view_line}
> **Generated:** {date}

## Overview
<!-- TODO: 2-3 sentences — core function and use case -->

## Layout
<!-- TODO: Region breakdown — search area, table, detail panel, action bar, etc. -->

## Fields

### Search / Filters
| Field | Type | Required | Options / Enum | Default | Notes |
|-------|------|----------|---------------|---------|-------|
| <!-- TODO --> | | | | | |

### Data Table
| Column | Format | Sortable | Filterable | Notes |
|--------|--------|----------|-----------|-------|
| <!-- TODO --> | | | | |

### Actions
| Button | Visibility Condition | Behavior |
|--------|---------------------|----------|
| <!-- TODO --> | | |

## Interactions

### Page Load
<!-- TODO: What happens on mount — default queries, preloaded data -->

### Search
- **Trigger:** <!-- TODO -->
- **Behavior:** <!-- TODO -->
- **Special rules:** <!-- TODO -->

### Create / Edit
- **Trigger:** <!-- TODO -->
- **Modal/drawer content:** <!-- TODO -->
- **Validation:** <!-- TODO -->
- **API:** <!-- TODO -->
- **On success:** <!-- TODO -->
- **On failure:** <!-- TODO -->

### Delete
- **Trigger:** <!-- TODO -->
- **Confirmation:** <!-- TODO -->
- **API:** <!-- TODO -->
- **On success:** <!-- TODO -->
- **On failure:** <!-- TODO -->

## API Dependencies

| API | Method | Path | Trigger | Status | Notes |
|-----|--------|------|---------|--------|-------|
| <!-- TODO --> | | | | Integrated / Mock | |

## Page Relationships
- **From:** <!-- TODO: Source pages + params -->
- **To:** <!-- TODO: Target pages + params -->
- **Data coupling:** <!-- TODO: Cross-page refresh triggers -->

## Business Rules
<!-- TODO: Anything that doesn't fit above -->
"""


def generate_resource_stub(entry: Dict[str, Any], date: str) -> str:
    """Generate a backend resource-group stub (backend variant of the page template)."""
    endpoints = sorted(entry["endpoints"], key=lambda e: (e.get("path", ""), e.get("method", "")))
    sources = list(dict.fromkeys(e.get("source", "unknown") for e in endpoints))  # endpoint order, deduped
    rows = "\n".join(f"| {e.get('method', '?')} | `{e.get('path', '?')}` | <!-- TODO --> | |" for e in endpoints)
    details = "\n\n".join(
        f"### {e.get('method', '?')} `{e.get('path', '?')}`\n"
        "- **Purpose:** <!-- TODO -->\n"
        "- **Request:** <!-- TODO: params / body fields, validation -->\n"
        "- **Side effects:** <!-- TODO -->\n"
        "- **Response:** <!-- TODO: success shape, error cases -->"
        for e in endpoints
    )

    return f"""# {entry['name']}

> **Route:** `{entry['route']}`
> **Module:** <!-- TODO -->
> **Source:** {', '.join(f'`{s}`' for s in sources)}
> **Generated:** {date}

## Overview
<!-- TODO: 2-3 sentences — what this resource is and who calls it -->

## Endpoints

| Method | Path | Auth | Notes |
|--------|------|------|-------|
{rows}

## Fields
<!-- TODO: Request body / query params and response fields (from DTO, serializer, or model) -->

| Field | Type | Required | Validation | Notes |
|-------|------|----------|------------|-------|
| <!-- TODO --> | | | | |

## Interactions

{details}

## Page Relationships
- **Called by:** <!-- TODO: pages or clients that use these endpoints -->
- **Downstream:** <!-- TODO: services, events, jobs triggered -->

## Business Rules
<!-- TODO: Anything that doesn't fit above -->
"""


def generate_enum_dictionary(enums: List[Dict]) -> str:
    """Generate the enum dictionary appendix."""
    lines = [
        "# Enum Dictionary",
        "",
        "All enums, status codes, and constant mappings found in the codebase.",
        "",
    ]

    if not enums:
        lines.append("*No enums detected. Manual review recommended.*")
        return "\n".join(lines)

    for e in enums:
        lines.append(f"## {e['name']}")
        lines.append(f"> **Source:** `{e.get('source', 'unknown')}`")
        lines.append("> **Used in:** <!-- TODO: link pages -->")
        lines.append("")
        if e.get("values"):
            lines.append("| Value | Label | Meaning |")
            lines.append("|-------|-------|---------|")
            for k, v in e["values"].items():
                # TS enums map Name → stored value; the stored value is what the data holds
                value, label = (v, k) if e.get("type") == "enum" else (k, v)
                lines.append(f"| `{value}` | {label} | <!-- TODO --> |")
        lines.append("")

    return "\n".join(lines)


def generate_api_inventory(apis: List[Dict], endpoints: List[Dict]) -> str:
    """Generate the API inventory appendix."""
    lines = [
        "# API Inventory",
        "",
        "Client API calls and server endpoints detected in the codebase.",
        "",
    ]

    if not apis and not endpoints:
        lines.append("*No APIs detected. Manual review recommended.*")
        return "\n".join(lines)

    if apis:
        lines.extend([
            "## Client API Calls",
            "",
            "| Method | Path | Status | Used By | Notes |",
            "|--------|------|--------|---------|-------|",
        ])
        for a in apis:
            status = "Mock" if a.get("mock_detected") else "Integrated" if a.get("integrated") else "<!-- TODO -->"
            src = a.get("source", "")
            lines.append(f"| {a.get('method', '?')} | `{a.get('path', '?')}` | {status} | {src} | |")
        lines.append("")

    if endpoints:
        lines.extend([
            "## Server Endpoints",
            "",
            "| Method | Path | Auth | Source | Notes |",
            "|--------|------|------|--------|-------|",
        ])
        for e in endpoints:
            src = e.get("source", "")
            lines.append(f"| {e.get('method', '?')} | `{e.get('path', '?')}` | <!-- TODO --> | {src} | |")
        lines.append("")

    return "\n".join(lines)


def generate_page_relationships(files: List[Dict[str, Any]]) -> str:
    """Generate page relationships appendix stub."""
    pages = [f for f in files if f["kind"] == "page"]
    lines = [
        "# Page Relationships",
        "",
        "## Navigation Map",
        "",
        "<!-- TODO: Fill in after page-by-page analysis -->",
        "",
        "```",
    ]

    for f in pages[:20]:  # Cap at 20 for readability
        lines.append(f"{f['name']} ({f['route']})")

    if len(pages) > 20:
        lines.append(f"... ({len(pages) - 20} more)")

    lines.extend([
        "```",
        "",
        "## Cross-Page Data Dependencies",
        "",
        "| Source Page | Target Page | Trigger | Data Passed |",
        "|-------------|-------------|---------|-------------|",
        "| <!-- TODO --> | | | |",
        "",
    ])

    return "\n".join(lines)


def scaffold(analysis: Dict[str, Any], output_dir: Path, project_name: Optional[str] = None):
    """Create the full PRD directory structure."""
    date = datetime.now().strftime("%Y-%m-%d")
    name = project_name or analysis.get("project", {}).get("name", "Project")
    apis = analysis.get("apis", {}).get("endpoints", [])
    enums = analysis.get("enums", {}).get("definitions", [])
    files = plan_page_files(analysis)

    # Create directories
    pages_dir = output_dir / "pages"
    appendix_dir = output_dir / "appendix"
    pages_dir.mkdir(parents=True, exist_ok=True)
    appendix_dir.mkdir(parents=True, exist_ok=True)

    # README.md
    (output_dir / "README.md").write_text(generate_readme(name, files), encoding="utf-8")
    print("  Created: README.md")

    # Per-page and per-resource stubs
    for f in files:
        content = generate_page_stub(f, date) if f["kind"] == "page" else generate_resource_stub(f, date)
        (pages_dir / f["filename"]).write_text(content, encoding="utf-8")
        print(f"  Created: pages/{f['filename']}")

    # Appendix
    (appendix_dir / "enum-dictionary.md").write_text(generate_enum_dictionary(enums), encoding="utf-8")
    print("  Created: appendix/enum-dictionary.md")

    (appendix_dir / "api-inventory.md").write_text(generate_api_inventory(apis, backend_endpoints(analysis)), encoding="utf-8")
    print("  Created: appendix/api-inventory.md")

    (appendix_dir / "page-relationships.md").write_text(generate_page_relationships(files), encoding="utf-8")
    print("  Created: appendix/page-relationships.md")


def validate_analysis(analysis: Dict[str, Any]) -> List[str]:
    """Validate analysis JSON has the required structure. Returns list of errors."""
    errors = []

    if not isinstance(analysis, dict):
        return ["Analysis must be a JSON object"]

    if "error" in analysis:
        errors.append(f"Analysis contains error: {analysis['error']}")

    required_keys = ["project", "routes", "apis"]
    for key in required_keys:
        if key not in analysis:
            errors.append(f"Missing required key: '{key}'")

    if "project" in analysis:
        proj = analysis["project"]
        if not isinstance(proj, dict):
            errors.append("'project' must be an object")
        elif "framework" not in proj:
            errors.append("'project.framework' is missing")

    if "routes" in analysis:
        routes = analysis["routes"]
        if not isinstance(routes, dict):
            errors.append("'routes' must be an object")
        elif "pages" not in routes and "frontend_pages" not in routes and "backend_endpoints" not in routes:
            errors.append("'routes' must contain 'pages', 'frontend_pages', or 'backend_endpoints'")
        elif not frontend_pages(analysis) and not backend_endpoints(analysis):
            errors.append("No pages or endpoints found — nothing to scaffold. "
                          "Build the page inventory by hand (SKILL.md Phase 1).")

    if "apis" in analysis:
        apis = analysis["apis"]
        if not isinstance(apis, dict):
            errors.append("'apis' must be an object")
        elif "endpoints" not in apis:
            errors.append("'apis.endpoints' is missing")

    return errors


def print_summary(output_dir: Path, analysis: Dict[str, Any]):
    """Print a structured summary of what was generated."""
    files = plan_page_files(analysis)
    apis = analysis.get("apis", {}).get("endpoints", [])
    enums = analysis.get("enums", {}).get("definitions", [])
    models = analysis.get("models", {}).get("definitions", [])
    stack = analysis.get("summary", {}).get("stack_type", "unknown")

    print(f"\nPRD scaffold complete: {output_dir}/")
    print(f"  Stack type:      {stack}")
    print(f"  Page stubs:      {sum(1 for f in files if f['kind'] == 'page')}")
    print(f"  Resource stubs:  {sum(1 for f in files if f['kind'] == 'resource')}")
    print(f"  API calls:       {len(apis)}")
    print(f"  Enums:           {len(enums)}")
    if models:
        print(f"  Models:          {len(models)}")
    print("\n  Next: Confirm each stub against source, then fill in the TODO sections.")


def main():
    # Non-UTF-8 consoles (e.g. Windows cp1252) can't print every character in the output
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(errors="replace")
    parser = argparse.ArgumentParser(
        description="Scaffold PRD directory from codebase analysis"
    )
    parser.add_argument("analysis", help="Path to analysis JSON from codebase_analyzer.py")
    parser.add_argument("-o", "--output-dir", default="prd", help="Output directory (default: prd/)")
    parser.add_argument("-n", "--project-name", help="Override project name")
    parser.add_argument("--validate-only", action="store_true",
                        help="Validate analysis JSON without generating files")
    parser.add_argument("--dry-run", action="store_true",
                        help="Show what would be created without writing files")
    parser.add_argument("--force", action="store_true",
                        help="Overwrite an existing, non-empty output directory")
    args = parser.parse_args()

    analysis_path = Path(args.analysis)
    if not analysis_path.exists():
        print(f"Error: Analysis file not found: {analysis_path}")
        raise SystemExit(2)

    try:
        with open(analysis_path, encoding="utf-8") as f:
            analysis = json.load(f)
    except json.JSONDecodeError as e:
        print(f"Error: Invalid JSON in {analysis_path}: {e}")
        raise SystemExit(2)

    # Validate
    errors = validate_analysis(analysis)
    if errors:
        print(f"Validation errors in {analysis_path}:")
        for err in errors:
            print(f"  - {err}")
        raise SystemExit(1)

    if args.validate_only:
        print(f"Analysis file is valid: {analysis_path}")
        print(f"  {len(frontend_pages(analysis))} pages, "
              f"{len(backend_endpoints(analysis))} endpoints, "
              f"{len(analysis.get('apis', {}).get('endpoints', []))} API calls, "
              f"{len(analysis.get('enums', {}).get('definitions', []))} enums")
        return

    output_dir = Path(args.output_dir)

    not_empty = output_dir.exists() and any(output_dir.iterdir())

    if args.dry_run:
        files = plan_page_files(analysis)
        if not_empty and not args.force:
            print(f"Warning: {output_dir}/ is not empty — a real run will refuse without --force.\n")
        print(f"Dry run — would create in {output_dir}/:\n")
        print(f"  {output_dir}/README.md")
        for f in files:
            print(f"  {output_dir}/pages/{f['filename']}")
        print(f"  {output_dir}/appendix/enum-dictionary.md")
        print(f"  {output_dir}/appendix/api-inventory.md")
        print(f"  {output_dir}/appendix/page-relationships.md")
        print(f"\n  Total: {len(files) + 4} files")
        return

    if not_empty and not args.force:
        print(f"Error: {output_dir}/ already exists and is not empty. Scaffolding would overwrite "
              f"filled-in PRD files. Choose another --output-dir, or pass --force to overwrite.")
        raise SystemExit(1)

    print(f"Scaffolding PRD in {output_dir}/...\n")
    scaffold(analysis, output_dir, args.project_name)
    print_summary(output_dir, analysis)


if __name__ == "__main__":
    main()
