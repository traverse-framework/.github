#!/usr/bin/env python3
"""Fixture tests for dev_health_report.py (.github#60). Run: python3 scripts/org/dev_health_report_test.py"""
import os
import sys
import unittest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import dev_health_report as d  # noqa: E402


def run(event, conclusion, minutes, branch="feature", name="CI", status="completed"):
    return {
        "name": name, "event": event, "head_branch": branch, "status": status, "conclusion": conclusion,
        "run_started_at": "2026-11-10T10:00:00Z",
        "updated_at": f"2026-11-10T{10 + minutes // 60:02d}:{minutes % 60:02d}:00Z",
    }


class CiMeasures(unittest.TestCase):
    def test_median_p90_and_failure_rates(self):
        runs = [run("pull_request", "success", m) for m in (10, 20, 30, 40, 50, 60, 70, 80, 90)]
        runs.append(run("pull_request", "failure", 100))
        runs.append(run("push", "success", 5, branch="main"))
        runs.append(run("push", "failure", 5, branch="main"))
        m = d.ci_measures(runs, "main")
        self.assertEqual(m["runs"], 12)
        # 12 sorted durations: 5, 5, 10 ... 90, 100; nearest rank 6 and 11.
        self.assertEqual(m["median_min"], 40)
        self.assertEqual(m["p90_min"], 90)
        self.assertAlmostEqual(m["pr_fail_pct"], 10.0)
        self.assertAlmostEqual(m["main_fail_pct"], 50.0)

    def test_cancelled_skipped_and_in_progress_are_ignored(self):
        runs = [run("pull_request", "success", 10), run("pull_request", "cancelled", 1),
                run("pull_request", "skipped", 0), run("pull_request", None, 5, status="in_progress")]
        m = d.ci_measures(runs, "main")
        self.assertEqual(m["runs"], 1)
        self.assertEqual(m["pr_fail_pct"], 0.0)

    def test_push_to_other_branch_is_not_main(self):
        m = d.ci_measures([run("push", "failure", 5, branch="feature")], "main")
        self.assertIsNone(m["main_fail_pct"])

    def test_startup_failure_counts_as_failure(self):
        m = d.ci_measures([run("pull_request", "startup_failure", 0)], "main")
        self.assertEqual(m["pr_fail_pct"], 100.0)

    def test_empty(self):
        m = d.ci_measures([], "main")
        self.assertIsNone(m["median_min"])
        self.assertIsNone(m["pr_fail_pct"])


class Scheduled(unittest.TestCase):
    def test_only_all_failed_workflows_listed(self):
        runs = [run("schedule", "failure", 1, name="nightly-a"), run("schedule", "failure", 1, name="nightly-a"),
                run("schedule", "failure", 1, name="nightly-b"), run("schedule", "success", 1, name="nightly-b"),
                run("pull_request", "failure", 1, name="ci")]
        self.assertEqual(d.always_failing_scheduled(runs), ["nightly-a"])


class Prs(unittest.TestCase):
    def test_fix_share_and_tools_exclude_bots(self):
        prs = [
            {"title": "fix(#1): x", "headRefName": "claude/issue-1-x", "author": {"login": "u", "is_bot": False}},
            {"title": "feat: y", "headRefName": "codex/issue-2-y", "author": {"login": "u", "is_bot": False}},
            {"title": "Fix: z", "headRefName": "cursor/z", "author": {"login": "u", "is_bot": False}},
            {"title": "fixture refresh", "headRefName": "docs/a", "author": {"login": "u", "is_bot": False}},
            {"title": "fix(deps): bump", "headRefName": "dependabot/x", "author": {"login": "dependabot[bot]", "is_bot": True}},
        ]
        m = d.pr_measures(prs)
        self.assertEqual(m["merged"], 4)
        self.assertAlmostEqual(m["fix_pct"], 50.0)
        self.assertEqual(dict(m["tools"]), {"claude": 1, "codex": 1, "cursor": 1, "other": 1})

    def test_no_prs(self):
        self.assertIsNone(d.pr_measures([])["fix_pct"])


class Render(unittest.TestCase):
    def test_thresholds_flag_and_error_row(self):
        cfg = {"thresholds": {"ci_median_minutes": 30, "ci_p90_minutes": 60, "ci_failure_pct": 20, "fix_share_pct": 15}}
        ok = {"repo": "r1", "ci": {"runs": 3, "median_min": 45.0, "p90_min": 50.0, "pr_fail_pct": 10.0,
                                   "main_fail_pct": None, "pr_runs": 3, "main_runs": 0},
              "always_failing": ["nightly"], "prs": d.pr_measures([])}
        out = d.render([ok, {"repo": "r2", "error": "HTTP 404"}], cfg, 7, "2026-11-10")
        self.assertIn("| r1 | 3 | ⚠️ 45 | 50 | 10 | — |", out)
        self.assertIn("| r2 | error: HTTP 404 |", out)
        self.assertIn("**nightly** failed on every run", out)
        self.assertIn("not available", out)

    def test_config_file_is_valid(self):
        import json
        with open(d.DEFAULT_CONFIG, encoding="utf-8") as fh:
            cfg = json.load(fh)
        self.assertTrue(all("name" in r and "ci_workflow" in r for r in cfg["repos"]))
        self.assertEqual(set(cfg["thresholds"]), {"ci_median_minutes", "ci_p90_minutes", "ci_failure_pct", "fix_share_pct"})


if __name__ == "__main__":
    unittest.main(verbosity=1)
