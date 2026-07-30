#!/usr/bin/env python3
"""Render session stats JSON as a self-contained dark-theme HTML page.

Consumes a metrics JSON object (as produced by scan_jsonl.py) and produces a
stats-only document: KPI cards + per-tool usage table + token-bucket table.
"""

import argparse
import html
import json
import os
import sys


def esc(value):
    return html.escape(str(value), quote=True)


def fmt_duration(ms):
    if ms is None:
        return "N/A"
    seconds = ms / 1000.0
    if seconds < 60:
        return f"{seconds:.1f}s"
    minutes = int(seconds // 60)
    rem = int(round(seconds - minutes * 60))
    return f"{minutes}m {rem}s"


def fmt_cost(value):
    if value is None:
        return "N/A"
    try:
        return f"${float(value):.2f}"
    except (TypeError, ValueError):
        return "N/A"


def fmt_int(value):
    if value is None:
        return "N/A"
    try:
        return f"{int(value):,}"
    except (TypeError, ValueError):
        return esc(value)


def pick_session(payload, session_filter):
    if isinstance(payload, dict) and "sessions" in payload:
        sessions = payload["sessions"]
    elif isinstance(payload, list):
        sessions = payload
    elif isinstance(payload, dict):
        sessions = [payload]
    else:
        sessions = []

    if not sessions:
        return None

    if session_filter:
        for sess in sessions:
            sid = str(sess.get("sessionId", ""))
            slug = str(sess.get("slug", ""))
            if sid.startswith(session_filter) or slug.startswith(session_filter):
                return sess
        return None

    return sessions[0]


def get_metric(session, key, default=None):
    scan = session.get("scan") or {}
    if key in scan and scan[key] is not None:
        return scan[key]
    return session.get(key, default)


def build_content(session):
    scan = session.get("scan") or {}

    project = session.get("project") or session.get("cwd") or "unknown"
    model = session.get("model") or "N/A"
    ts = session.get("timestamp") or "N/A"
    date = ts.split("T")[0] if isinstance(ts, str) and "T" in ts else ts

    prompts = get_metric(session, "promptCount")
    tools = get_metric(session, "toolCallCount")
    edits = get_metric(session, "editCount")
    duration = get_metric(session, "durationMs")
    cost = scan.get("costEstimate")
    tokens = scan.get("tokens") or {}
    out_tokens = tokens.get("output")
    breakdown = scan.get("toolBreakdown") or []

    kpis = [
        ("Duration", fmt_duration(duration)),
        ("Prompts", fmt_int(prompts)),
        ("Tool calls", fmt_int(tools)),
        ("Files written/edited", fmt_int(edits)),
        ("Output tokens", fmt_int(out_tokens) if out_tokens is not None else "N/A"),
        ("Est. cost", fmt_cost(cost)),
    ]
    kpi_cards = "\n".join(
        f'    <div class="kpi"><div class="value">{esc(val)}</div>'
        f'<div class="label">{esc(label)}</div></div>'
        for label, val in kpis
    )

    # Tool usage table (per-tool counts + share bar), omitted when no tools ran.
    tool_section = ""
    total_tc = sum(b.get("count", 0) for b in breakdown)
    if breakdown and total_tc > 0:
        tool_rows = "\n".join(
            f'        <tr><td>{esc(b.get("tool", "?"))}</td>'
            f'<td class="num">{fmt_int(b.get("count"))}</td>'
            f'<td class="share"><span class="bar" style="width:{round(b.get("count", 0) / total_tc * 100)}%"></span></td>'
            f'<td class="num pct">{round(b.get("count", 0) / total_tc * 100)}%</td></tr>'
            for b in breakdown
        )
        tool_section = f"""
  <h2 class="section">Tool usage</h2>
  <table class="t">
    <thead><tr><th>Tool</th><th class="num">Calls</th><th class="share">Share</th><th class="num">%</th></tr></thead>
    <tbody>
{tool_rows}
    </tbody>
  </table>"""

    # Tokens table, omitted when the scan carries no token buckets.
    token_section = ""
    if tokens:
        token_data = [
            ("Input", tokens.get("input")),
            ("Output", tokens.get("output")),
            ("Cache created", tokens.get("cacheCreated")),
            ("Cache read", tokens.get("cacheRead")),
        ]
        token_rows = "\n".join(
            f'        <tr><td>{esc(label)}</td>'
            f'<td class="num">{fmt_int(val) if val is not None else "N/A"}</td></tr>'
            for label, val in token_data
        )
        token_section = f"""
  <h2 class="section">Tokens</h2>
  <table class="t">
    <thead><tr><th>Bucket</th><th class="num">Tokens</th></tr></thead>
    <tbody>
{token_rows}
    </tbody>
  </table>"""

    meta_line = (
        f'  <p class="meta"><b>{esc(model)}</b> &middot; '
        f'<code>{esc(project)}</code> &middot; {esc(date)}</p>'
    )

    return f"""  <h1>Session Stats</h1>
{meta_line}

  <div class="kpi-grid">
{kpi_cards}
  </div>{tool_section}{token_section}"""


def main():
    parser = argparse.ArgumentParser(description="session stats JSON -> dark HTML")
    parser.add_argument("--in", dest="infile", help="JSON file (default: stdin)")
    parser.add_argument("--out", dest="outfile", required=True, help="output .html path")
    parser.add_argument("--session", help="sessionId/slug prefix to select")
    parser.add_argument("--template", help="template.html path (default: ../assets/template.html)")
    args = parser.parse_args()

    raw = open(args.infile, encoding="utf-8").read() if args.infile else sys.stdin.read()
    try:
        payload = json.loads(raw)
    except json.JSONDecodeError as exc:
        print(f"error: input is not valid JSON: {exc}", file=sys.stderr)
        return 1

    session = pick_session(payload, args.session)
    if session is None:
        print("error: no matching session in input", file=sys.stderr)
        return 1

    template_path = args.template or os.path.join(
        os.path.dirname(os.path.abspath(__file__)), "..", "assets", "template.html"
    )
    if not os.path.exists(template_path):
        print(f"error: template not found at {template_path}", file=sys.stderr)
        return 2
    template = open(template_path, encoding="utf-8").read()

    document = template.replace("  <!-- CONTENT -->", build_content(session), 1)

    with open(args.outfile, "w", encoding="utf-8") as fh:
        fh.write(document)

    print(f"wrote {args.outfile} for session {session.get('slug') or session.get('sessionId')}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
