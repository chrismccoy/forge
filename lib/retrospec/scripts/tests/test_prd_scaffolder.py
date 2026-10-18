"""Tests for prd_scaffolder.py.

Run: python3 -m unittest discover -s scripts/tests
"""

import contextlib
import io
import json
import os
import re
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from prd_scaffolder import main, plan_page_files, scaffold, validate_analysis  # noqa: E402


def analysis(pages=(), endpoints=(), apis=()):
    return {
        "project": {"name": "Fixture", "framework": "express"},
        "routes": {
            "frontend_pages": [{"path": p, "source": "x.js"} for p in pages],
            "backend_endpoints": [{"path": p, "method": m, "source": "r.js", "type": "backend"}
                                  for m, p in endpoints],
        },
        "apis": {"endpoints": [{"path": p, "method": m, "integrated": True} for m, p in apis]},
        "enums": {"definitions": []},
        "summary": {},
    }


def run_scaffold(data):
    out = Path(tempfile.mkdtemp())
    buf = io.StringIO()
    with contextlib.redirect_stdout(buf):
        scaffold(data, out)
    return out, buf.getvalue()


class PagePlanning(unittest.TestCase):
    def test_catch_all_route_gets_a_name(self):
        files = plan_page_files(analysis(pages=["/*", "/docs/*slug"]))
        self.assertEqual(files[0]["name"], "Catch-all")
        self.assertTrue(all(f["name"] for f in files))

    def test_list_and_detail_routes_get_distinct_names(self):
        names = [f["filename"] for f in plan_page_files(analysis(pages=["/users", "/users/:id"]))]
        self.assertEqual(len(set(names)), 2)
        self.assertIn("detail", names[1])

    def test_backend_endpoints_are_grouped_by_resource(self):
        files = plan_page_files(analysis(endpoints=[
            ("GET", "/api/users"), ("POST", "/api/users"), ("GET", "/api/users/:id"),
            ("POST", "/api/generate"),
        ]))
        self.assertEqual(len(files), 2)
        users = next(f for f in files if "users" in f["filename"])
        self.assertEqual(len(users["endpoints"]), 3)

    def test_pages_come_before_backend_groups(self):
        files = plan_page_files(analysis(pages=["/"], endpoints=[("GET", "/api/users")]))
        self.assertEqual([f["kind"] for f in files], ["page", "resource"])


class Scaffold(unittest.TestCase):
    def test_readme_links_point_at_generated_files(self):
        out, _ = run_scaffold(analysis(pages=["/", "/users", "/users/:id"],
                                       endpoints=[("POST", "/api/users")]))
        readme = (out / "README.md").read_text()
        links = re.findall(r"\]\(\./(pages/[^)]+)\)", readme)
        self.assertEqual(len(links), 4)
        for link in links:
            self.assertTrue((out / link).is_file(), link)

    def test_resource_stub_lists_its_endpoints(self):
        out, _ = run_scaffold(analysis(endpoints=[("GET", "/api/users"), ("DELETE", "/api/users/:id")]))
        stub = next((out / "pages").iterdir()).read_text()
        self.assertIn("| GET | `/api/users` |", stub)
        self.assertIn("| DELETE | `/api/users/:id` |", stub)

    def test_sources_keep_their_relative_paths(self):
        data = analysis(endpoints=[("GET", "/api/users"), ("GET", "/api/users/:id")])
        data["routes"]["backend_endpoints"][0]["source"] = "app/api/users/route.ts"
        data["routes"]["backend_endpoints"][1]["source"] = "app/api/users/[id]/route.ts"
        out, _ = run_scaffold(data)
        stub = next((out / "pages").iterdir()).read_text()
        self.assertIn("`app/api/users/route.ts`, `app/api/users/[id]/route.ts`", stub)
        inventory = (out / "appendix" / "api-inventory.md").read_text()
        self.assertIn("app/api/users/[id]/route.ts", inventory)

    def test_typescript_enum_rows_put_the_value_first(self):
        data = analysis(pages=["/"])
        data["enums"]["definitions"] = [
            {"name": "UserRole", "type": "enum", "values": {"Admin": "admin"}, "source": "types/user.ts"},
            {"name": "STATUS_MAP", "type": "constant_map", "values": {"active": "Active"}, "source": "constants/status.ts"},
        ]
        out, _ = run_scaffold(data)
        enums = (out / "appendix" / "enum-dictionary.md").read_text()
        self.assertIn("| `admin` | Admin |", enums)
        self.assertIn("| `active` | Active |", enums)
        self.assertIn("`types/user.ts`", enums)

    def test_cli_prints_completion_message_once(self):
        tmp = Path(tempfile.mkdtemp())
        src = tmp / "analysis.json"
        src.write_text(json.dumps(analysis(pages=["/"])))
        buf = io.StringIO()
        argv = sys.argv
        sys.argv = ["prd_scaffolder.py", str(src), "-o", str(tmp / "prd")]
        try:
            with contextlib.redirect_stdout(buf):
                main()
        finally:
            sys.argv = argv
        self.assertEqual(buf.getvalue().count("scaffold complete"), 1)


class Validation(unittest.TestCase):
    def test_no_pages_and_no_endpoints_is_an_error(self):
        errors = validate_analysis(analysis())
        self.assertTrue(any("no pages" in e.lower() for e in errors), errors)

    def test_backend_only_analysis_is_valid(self):
        self.assertEqual(validate_analysis(analysis(endpoints=[("GET", "/api/x")])), [])


class Cli(unittest.TestCase):
    def run_cli(self, data, *flags, out=None):
        tmp = Path(tempfile.mkdtemp())
        src = tmp / "analysis.json"
        src.write_text(json.dumps(data))
        out = out or tmp / "prd"
        script = Path(__file__).resolve().parent.parent / "prd_scaffolder.py"
        result = subprocess.run([sys.executable, "-I", str(script), str(src), "-o", str(out), *flags],
                                capture_output=True, text=True)
        return result, out

    def test_refuses_to_overwrite_a_filled_in_prd(self):
        out = Path(tempfile.mkdtemp()) / "prd"
        out.mkdir()
        (out / "README.md").write_text("KEEP")
        result, _ = self.run_cli(analysis(pages=["/"]), out=out)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("--force", result.stdout + result.stderr)
        self.assertEqual((out / "README.md").read_text(), "KEEP")

    def test_force_overwrites(self):
        out = Path(tempfile.mkdtemp()) / "prd"
        out.mkdir()
        (out / "README.md").write_text("KEEP")
        result, _ = self.run_cli(analysis(pages=["/"]), "--force", out=out)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertNotEqual((out / "README.md").read_text(), "KEEP")

    def test_dry_run_lists_planned_files_and_writes_nothing(self):
        result, out = self.run_cli(analysis(pages=["/users", "/users/:id"]), "--dry-run")
        self.assertEqual(result.returncode, 0)
        self.assertIn("pages/01-users.md", result.stdout)
        self.assertIn("pages/02-users-detail.md", result.stdout)
        self.assertFalse(out.exists())

    def test_dry_run_warns_when_output_dir_is_not_empty(self):
        out = Path(tempfile.mkdtemp()) / "prd"
        out.mkdir()
        (out / "README.md").write_text("KEEP")
        result, _ = self.run_cli(analysis(pages=["/"]), "--dry-run", out=out)
        self.assertIn("not empty", result.stdout)

    def test_scaffolds_under_a_non_utf8_locale(self):
        tmp = Path(tempfile.mkdtemp())
        src = tmp / "analysis.json"
        src.write_text(json.dumps(analysis(pages=["/"])), encoding="utf-8")
        env = {**os.environ, "LC_ALL": "C", "LANG": "C", "PYTHONUTF8": "0", "PYTHONCOERCECLOCALE": "0"}
        script = Path(__file__).resolve().parent.parent / "prd_scaffolder.py"
        result = subprocess.run([sys.executable, "-I", "-X", "utf8=0", str(script), str(src), "-o", str(tmp / "prd")],
                                capture_output=True, text=True, env=env)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("→", (tmp / "prd" / "README.md").read_text(encoding="utf-8"))

    def test_validate_only_reports_counts_and_writes_nothing(self):
        result, out = self.run_cli(analysis(pages=["/"], endpoints=[("GET", "/api/x")]), "--validate-only")
        self.assertEqual(result.returncode, 0)
        self.assertIn("1 pages, 1 endpoints", result.stdout)
        self.assertFalse(out.exists())

    def test_validate_only_fails_on_empty_inventory(self):
        result, _ = self.run_cli(analysis(), "--validate-only")
        self.assertEqual(result.returncode, 1)


if __name__ == "__main__":
    unittest.main()
