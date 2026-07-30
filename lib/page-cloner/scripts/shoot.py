#!/usr/bin/env python3
"""Render a local HTML file to PNG screenshots for the validation loop.

Produces a full-page screenshot plus one screenshot per <section>
(or, if the page has none, per direct child of <body>), so the clone can be
compared against the original section-by-section. Section slicing is a best-effort
directional aid — the full-page shot is the reliable comparison axis.

Usage:
    python shoot.py <path/to/index.html> <output_dir> [--width 1280]

Requires Playwright:
    pip install playwright --break-system-packages && playwright install chromium
"""
import argparse
import pathlib
import sys


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("html", help="Path to the local HTML file to screenshot")
    ap.add_argument("out", help="Output directory for PNGs")
    ap.add_argument("--width", type=int, default=1280, help="Viewport width (px)")
    args = ap.parse_args()

    html_path = pathlib.Path(args.html).resolve()
    if not html_path.exists():
        print(f"error: {html_path} does not exist", file=sys.stderr)
        return 1

    out_dir = pathlib.Path(args.out)
    out_dir.mkdir(parents=True, exist_ok=True)

    try:
        from playwright.sync_api import sync_playwright
    except ImportError:
        print(
            "error: playwright not installed. Run:\n"
            "  pip install playwright --break-system-packages && playwright install chromium",
            file=sys.stderr,
        )
        return 2

    with sync_playwright() as p:
        browser = p.chromium.launch()
        # device_scale_factor=1 keeps pixel dims comparable to a 1x original capture.
        page = browser.new_page(viewport={"width": args.width, "height": 900},
                                device_scale_factor=1)
        page.goto(html_path.as_uri())
        try:
            page.wait_for_load_state("networkidle", timeout=15000)
        except Exception:
            # A hanging asset (CORS-kept <link>, slow font/CDN) shouldn't abort the
            # whole screenshot step — fall back to the basic load state and continue.
            page.wait_for_load_state("load")

        # Full page — the layout map.
        full = out_dir / "full.png"
        page.screenshot(path=str(full), full_page=True)
        print(f"wrote {full}")

        # Per-section shots — for spacing/type-level comparison. Sections are often
        # nested under <main>, so look there too before falling back to body children.
        selector = "main > section, body > section"
        count = page.locator(selector).count()
        if count == 0:
            selector = "section"  # sections wrapped in a container div
            count = page.locator(selector).count()
        if count == 0:
            selector = "body > *"
            count = page.locator(selector).count()

        shot = 0
        for i in range(count):
            el = page.locator(selector).nth(i)
            try:
                if not el.is_visible():
                    continue
                box = el.bounding_box()
                if not box or box["height"] < 8:  # skip scripts, hidden nodes
                    continue
                shot += 1
                dest = out_dir / f"section-{shot:02d}.png"
                el.screenshot(path=str(dest))
                print(f"wrote {dest}")
            except Exception as e:  # noqa: BLE001 — best-effort per section
                print(f"skip section {i}: {e}", file=sys.stderr)

        browser.close()

    print(f"done: {shot} section shot(s) + full page in {out_dir}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
