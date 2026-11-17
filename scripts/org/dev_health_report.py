#!/usr/bin/env python3
"""Weekly development-health report per active repo (.github#60).

Fetches with bounded `gh api` calls, computes each measure with pure
functions (tested in dev_health_report_test.py), and prints a markdown
table. A repo whose data cannot be fetched gets an error row and a
workflow warning; the script never hides a failed query.

Usage: dev_health_report.py [--config PATH] [--days N] [--now ISO8601]
"""
from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
from collections import Counter, defaultdict
from datetime import datetime, timedelta, timezone

HERE = os.path.dirname(os.path.abspath(__file__))
DEFAULT_CONFIG = os.path.join(HERE, "dev_health_config.json")

FAILED = {"failure", "timed_out", "startup_failure"}
# Cancelled runs (superseded by concurrency) and skipped runs say nothing
# about health, so they are left out of failure rates and durations.
COUNTED = FAILED | {"success"}
TOOLS = ("claude", "codex", "cursor")


def parse_ts(value: str | None) -> datetime | None:
    if not value:
        return None
    return datetime.fromisoformat(value.replace("Z", "+00:00"))


def nearest_rank(sorted_values: list[float], pct: float) -> float | None:
    if not sorted_values:
        return None
    rank = max(1, -(-len(sorted_values) * pct // 100))  # ceil
    return sorted_values[int(rank) - 1]


def ci_measures(runs: list[dict], default_branch: str) -> dict:
    counted = [r for r in runs if r.get("status") == "completed" and r.get("conclusion") in COUNTED]
    durations = []
    for r in counted:
        start = parse_ts(r.get("run_started_at") or r.get("created_at"))
        end = parse_ts(r.get("updated_at"))
        if start and end and end >= start:
            durations.append((end - start).total_seconds() / 60.0)
    durations.sort()

    def fail_pct(subset: list[dict]) -> float | None:
        if not subset:
            return None
        return 100.0 * sum(1 for r in subset if r["conclusion"] in FAILED) / len(subset)

    pr_runs = [r for r in counted if r.get("event") == "pull_request"]
    main_runs = [r for r in counted if r.get("event") == "push" and r.get("head_branch") == default_branch]
    return {
        "runs": len(counted),
        "median_min": nearest_rank(durations, 50),
        "p90_min": nearest_rank(durations, 90),
        "pr_fail_pct": fail_pct(pr_runs),
        "pr_runs": len(pr_runs),
        "main_fail_pct": fail_pct(main_runs),
        "main_runs": len(main_runs),
    }


def always_failing_scheduled(runs: list[dict]) -> list[str]:
    by_name: dict[str, list[str]] = defaultdict(list)
    for r in runs:
        if r.get("event") == "schedule" and r.get("status") == "completed" and r.get("conclusion") in COUNTED:
            by_name[r.get("name") or r.get("path") or "?"].append(r["conclusion"])
    return sorted(name for name, results in by_name.items() if results and all(c in FAILED for c in results))


def is_fix_title(title: str) -> bool:
    t = title.strip().lower()
    return t.startswith("fix") and (len(t) == 3 or t[3] in "(:! ")


def pr_measures(prs: list[dict]) -> dict:
    humans = [p for p in prs if not (p.get("author") or {}).get("is_bot") and not (p.get("author") or {}).get("login", "").endswith("[bot]")]
    tools: Counter = Counter()
    for p in humans:
        prefix = (p.get("headRefName") or "").split("/", 1)[0]
        tools[prefix if prefix in TOOLS else "other"] += 1
    fixes = sum(1 for p in humans if is_fix_title(p.get("title") or ""))
    return {
        "merged": len(humans),
        "fix_pct": (100.0 * fixes / len(humans)) if humans else None,
        "tools": tools,
    }


def fmt(value: float | None, digits: int = 0) -> str:
    return "—" if value is None else f"{value:.{digits}f}"


def flag(value: float | None, limit: float | None) -> str:
    text = fmt(value)
    if value is not None and limit is not None and value > limit:
        return f"⚠️ {text}"
    return text


def render(rows: list[dict], cfg: dict, days: int, since: str) -> str:
    t = cfg.get("thresholds", {})
    out = [
        f"# Development health — last {days} days (since {since})",
        "",
        "| repo | CI runs | CI median (min) | CI p90 (min) | PR CI fail % | main CI fail % | merged PRs | fix-titled % | claude/codex/cursor/other | review measures |",
        "|---|---|---|---|---|---|---|---|---|---|",
    ]
    failing_lines = []
    for row in rows:
        if "error" in row:
            out.append(f"| {row['repo']} | error: {row['error']} | | | | | | | | |")
            continue
        ci, pr = row["ci"], row["prs"]
        tools = "/".join(str(pr["tools"].get(k, 0)) for k in (*TOOLS, "other"))
        out.append(
            f"| {row['repo']} | {ci['runs']} | {flag(ci['median_min'], t.get('ci_median_minutes'))} | "
            f"{flag(ci['p90_min'], t.get('ci_p90_minutes'))} | {flag(ci['pr_fail_pct'], t.get('ci_failure_pct'))} | "
            f"{flag(ci['main_fail_pct'], t.get('ci_failure_pct'))} | {pr['merged']} | "
            f"{flag(pr['fix_pct'], t.get('fix_share_pct'))} | {tools} | not available |"
        )
        for name in row["always_failing"]:
            failing_lines.append(f"- ⚠️ `{row['repo']}`: scheduled workflow **{name}** failed on every run")
    out.append("")
    out.append("**Scheduled workflows failing on every run:**")
    out.extend(failing_lines or ["- none"])
    out.append("")
    out.append(
        "_Thresholds from `scripts/org/dev_health_config.json`; ⚠️ marks a value above its limit. "
        "Failure rates leave out cancelled and skipped runs. Review measures (cross-tool vs fallback, "
        "`needs-review` wait) are not available yet._"
    )
    return "\n".join(out)


def gh_lines(args: list[str]) -> list[dict]:
    proc = subprocess.run(["gh", *args], capture_output=True, text=True, check=False)
    if proc.returncode != 0:
        raise RuntimeError((proc.stderr or proc.stdout).strip().splitlines()[-1] if (proc.stderr or proc.stdout).strip() else f"gh exited {proc.returncode}")
    return [json.loads(line) for line in proc.stdout.splitlines() if line.strip()]


RUN_FIELDS = "{name, path, event, head_branch, status, conclusion, run_started_at, created_at, updated_at}"


def fetch_repo(org: str, repo: dict, since: str, cap: int) -> dict:
    name = repo["name"]
    meta = gh_lines(["api", f"repos/{org}/{name}", "--jq", "{default_branch}"])[0]
    ci_runs = gh_lines([
        "api", "--paginate",
        f"repos/{org}/{name}/actions/workflows/{repo['ci_workflow']}/runs?created=>={since}&per_page=100",
        "--jq", f".workflow_runs[] | {RUN_FIELDS}",
    ])[:cap]
    scheduled = gh_lines([
        "api", "--paginate",
        f"repos/{org}/{name}/actions/runs?event=schedule&created=>={since}&per_page=100",
        "--jq", f".workflow_runs[] | {RUN_FIELDS}",
    ])[:cap]
    prs = gh_lines([
        "pr", "list", "--repo", f"{org}/{name}", "--state", "merged",
        "--search", f"merged:>={since}", "--limit", str(cap),
        "--json", "title,headRefName,author", "--jq", ".[]",
    ])
    return {
        "repo": name,
        "ci": ci_measures(ci_runs, meta["default_branch"]),
        "always_failing": always_failing_scheduled(scheduled),
        "prs": pr_measures(prs),
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--config", default=DEFAULT_CONFIG)
    parser.add_argument("--days", type=int)
    parser.add_argument("--now")
    args = parser.parse_args()

    with open(args.config, encoding="utf-8") as fh:
        cfg = json.load(fh)
    days = args.days or cfg.get("days", 7)
    now = parse_ts(args.now) if args.now else datetime.now(timezone.utc)
    since = (now - timedelta(days=days)).date().isoformat()
    cap = int(cfg.get("max_items_per_query", 1000))

    rows = []
    for repo in cfg["repos"]:
        try:
            rows.append(fetch_repo(cfg["org"], repo, since, cap))
        except (RuntimeError, json.JSONDecodeError, KeyError, IndexError) as exc:
            print(f"::warning::dev health: {repo['name']}: {exc}", file=sys.stderr)
            rows.append({"repo": repo["name"], "error": str(exc)[:120]})
    print(render(rows, cfg, days, since))
    return 0


if __name__ == "__main__":
    sys.exit(main())
