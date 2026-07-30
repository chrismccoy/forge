#!/usr/bin/env python3
"""Scan a Claude Code session .jsonl and emit session stats JSON.

Parses the raw transcript and computes every metric, including a cost estimate
derived from each assistant message's token `usage` times per-model pricing (the
.jsonl stores token counts, not dollars, so cost is always computed here).
"""

import argparse
import json
import os
import re
import statistics
import sys
from datetime import datetime

SYNTHETIC_PROMPT = re.compile(
    r"<command-(name|message)>|<local-command|local-command-caveat|SYSTEM NOTIFICATION|^\s*\["
)

RATE_OVERRIDES = {
    "in": os.environ.get("IN_RATE"),
    "out": os.environ.get("OUT_RATE"),
    "cache_write": os.environ.get("CW_RATE"),
    "cache_read": os.environ.get("CR_RATE"),
}

PRICING = {
    "claude-opus-4-8":   {"in": 5.0,  "out": 25.0, "cache_write": 6.25, "cache_read": 0.50},
    "claude-opus-4-7":   {"in": 5.0,  "out": 25.0, "cache_write": 6.25, "cache_read": 0.50},
    "claude-opus-4-6":   {"in": 5.0,  "out": 25.0, "cache_write": 6.25, "cache_read": 0.50},
    "claude-fable-5":    {"in": 10.0, "out": 50.0, "cache_write": 12.5, "cache_read": 1.00},
    "claude-sonnet-4-6": {"in": 3.0,  "out": 15.0, "cache_write": 3.75, "cache_read": 0.30},
    "claude-haiku-4-5":  {"in": 1.0,  "out": 5.0,  "cache_write": 1.25, "cache_read": 0.10},
}
EDIT_TOOLS = {"Edit", "Write", "MultiEdit", "NotebookEdit"}


def base_model(model):
    """Strip a trailing variant suffix like [1m] so pricing keys match."""
    if not model:
        return None
    return model.split("[")[0].strip()


def price_message(usage, model):
    if not usage:
        return 0.0
    rates = PRICING.get(base_model(model))
    if not rates:
        # Usage exists but the model has no pricing entry: cost is unknown, not zero.
        return None
    rates = {k: (float(RATE_OVERRIDES[k]) if RATE_OVERRIDES[k] else v) for k, v in rates.items()}
    inp = usage.get("input_tokens", 0) or 0
    out = usage.get("output_tokens", 0) or 0
    cw = usage.get("cache_creation_input_tokens", 0) or 0
    cr = usage.get("cache_read_input_tokens", 0) or 0
    return (
        inp * rates["in"]
        + out * rates["out"]
        + cw * rates["cache_write"]
        + cr * rates["cache_read"]
    ) / 1_000_000.0


def parse_ts(value):
    if not value:
        return None
    try:
        return datetime.fromisoformat(value.replace("Z", "+00:00"))
    except (ValueError, AttributeError):
        return None


def iter_records(path):
    with open(path, encoding="utf-8") as fh:
        for line in fh:
            line = line.strip()
            if not line:
                continue
            try:
                yield json.loads(line)
            except json.JSONDecodeError:
                continue


def scan(path):
    prompt_count = tool_calls = edit_count = 0
    sub_agents = compactions = api_errors = 0
    files = {}
    tool_counts = {}
    tok_in = tok_out = tok_cw = tok_cr = 0
    cost = 0.0
    cost_unknown = False
    timestamps = []
    model = None
    cwd = git_branch = session_id = None

    for rec in iter_records(path):
        rtype = rec.get("type")
        ts = parse_ts(rec.get("timestamp"))
        if ts:
            timestamps.append(ts)
        cwd = rec.get("cwd", cwd)
        git_branch = rec.get("gitBranch", git_branch)
        session_id = rec.get("sessionId", session_id)

        if rtype == "summary":
            compactions += 1
            continue

        msg = rec.get("message") or {}
        role = msg.get("role")
        content = msg.get("content")

        if rtype == "user" and role == "user" and not rec.get("isMeta"):
            if isinstance(content, str) and not SYNTHETIC_PROMPT.search(content):
                prompt_count += 1

        if rtype == "assistant" and role == "assistant":
            model = msg.get("model", model)
            usage = msg.get("usage") or {}
            tok_in += usage.get("input_tokens", 0) or 0
            tok_out += usage.get("output_tokens", 0) or 0
            tok_cw += usage.get("cache_creation_input_tokens", 0) or 0
            tok_cr += usage.get("cache_read_input_tokens", 0) or 0
            pm = price_message(usage, msg.get("model"))
            if pm is None:
                cost_unknown = True
            else:
                cost += pm
            if isinstance(content, list):
                for block in content:
                    if not isinstance(block, dict):
                        continue
                    if block.get("type") == "tool_use":
                        tool_calls += 1
                        name = block.get("name", "")
                        if name:
                            tool_counts[name] = tool_counts.get(name, 0) + 1
                        if name == "Task":
                            sub_agents += 1
                        if name in EDIT_TOOLS:
                            edit_count += 1
                            fp = (block.get("input") or {}).get("file_path")
                            if fp:
                                files[fp] = files.get(fp, 0) + 1
                    elif block.get("type") == "text":
                        text = block.get("text", "")
                        if "API Error" in text or "api_error" in text:
                            api_errors += 1

    duration_ms = None
    median_ms = None
    if len(timestamps) >= 2:
        timestamps.sort()
        duration_ms = int((timestamps[-1] - timestamps[0]).total_seconds() * 1000)
        deltas = [
            (timestamps[i + 1] - timestamps[i]).total_seconds() * 1000
            for i in range(len(timestamps) - 1)
        ]
        if deltas:
            median_ms = int(statistics.median(deltas))

    ratio = lambda n: round(n / prompt_count, 1) if prompt_count else 0.0

    return {
        "sessions": [
            {
                "provider": "claude-code",
                "sessionId": session_id,
                "slug": (session_id or "session")[:8],
                "project": cwd,
                "cwd": cwd,
                "gitBranch": git_branch,
                "model": base_model(model),
                "timestamp": timestamps[0].isoformat() if timestamps else None,
                "promptCount": prompt_count,
                "toolCallCount": tool_calls,
                "editCount": edit_count,
                "durationMs": duration_ms,
                "scan": {
                    "promptCount": prompt_count,
                    "toolCallCount": tool_calls,
                    "editCount": edit_count,
                    "filesModified": [
                        {"file": f, "count": c} for f, c in sorted(files.items())
                    ],
                    "toolBreakdown": [
                        {"tool": t, "count": c}
                        for t, c in sorted(tool_counts.items(), key=lambda kv: (-kv[1], kv[0]))
                    ],
                    "tokens": {
                        "input": tok_in, "output": tok_out,
                        "cacheCreated": tok_cw, "cacheRead": tok_cr,
                    },
                    "durationMs": duration_ms,
                    "costEstimate": None if cost_unknown else round(cost, 6),
                    "apiErrorCount": api_errors,
                    "compactionCount": compactions,
                    "subAgentCount": sub_agents,
                    "toolCallsPerPrompt": ratio(tool_calls),
                    "editsPerPrompt": ratio(edit_count),
                    "medianTurnDurationMs": median_ms,
                },
            }
        ]
    }


def main():
    parser = argparse.ArgumentParser(description="Scan Claude Code .jsonl -> stats JSON")
    parser.add_argument("--in", dest="infile", required=True, help="session .jsonl path")
    parser.add_argument("--out", dest="outfile", help="output JSON (default: stdout)")
    args = parser.parse_args()

    payload = scan(args.infile)
    text = json.dumps(payload, indent=2)
    if args.outfile:
        with open(args.outfile, "w", encoding="utf-8") as fh:
            fh.write(text)
        print(f"wrote {args.outfile}")
    else:
        sys.stdout.write(text + "\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
