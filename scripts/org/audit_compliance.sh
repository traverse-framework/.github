#!/usr/bin/env bash
# Org-wide governance compliance audit.
#
# For every repo in the org, checks that the governance artifacts are present
# and that the baseline branch ruleset is active. Prints a markdown report to
# stdout (used as the GitHub job summary by org-audit.yml) and exits non-zero
# if any repo is non-compliant.
#
# Usage: scripts/org/audit_compliance.sh
# Requires: gh CLI. Ruleset checks need admin read; without it they report "?".
set -euo pipefail

ORG="traverse-framework"
RULESET_NAME="traverse-governance-baseline"
FAILURES=0

has_file() { # repo path
  gh api "repos/$ORG/$1/contents/$2" --jq .path >/dev/null 2>&1
}

check() { # boolean-ish -> cell
  if [ "$1" = "yes" ]; then echo "✅"; else echo "❌"; FAILURES=$((FAILURES + 1)); fi
}

echo "# Governance compliance report — $ORG"
echo
echo "_Generated $(date -u +%Y-%m-%dT%H:%M:%SZ) against governance $(cat "$(dirname "$0")/../../CHANGELOG.md" 2>/dev/null | grep -om1 '\[[0-9.]*\]' | tr -d '[]' || echo '?')_"
echo
echo "| repo | version pin | CODEOWNERS | dependabot | CLA wf | governance wf | agent docs | ruleset |"
echo "|---|---|---|---|---|---|---|---|"

mapfile -t repos < <(gh repo list "$ORG" --limit 200 --json name --jq '.[].name')

for repo in "${repos[@]}"; do
  ver="no"; has_file "$repo" ".governance-version" && ver="yes"
  own="no"; has_file "$repo" ".github/CODEOWNERS" && own="yes"
  dep="no"; has_file "$repo" ".github/dependabot.yml" && dep="yes"
  cla="no"; has_file "$repo" ".github/workflows/cla.yml" && cla="yes"
  gov="no"; has_file "$repo" ".github/workflows/governance.yml" && gov="yes"
  agent="no"
  { has_file "$repo" "CLAUDE.md" || has_file "$repo" "AGENTS.md"; } && agent="yes"

  ruleset_cell="?"
  rulesets="$(gh api "repos/$ORG/$repo/rulesets" --jq '.[].name' 2>/dev/null || echo "__unreadable__")"
  if [ "$rulesets" != "__unreadable__" ]; then
    if echo "$rulesets" | grep -qx "$RULESET_NAME"; then ruleset_cell="✅"; else ruleset_cell="❌"; FAILURES=$((FAILURES + 1)); fi
  fi

  echo "| $repo | $(check "$ver") | $(check "$own") | $(check "$dep") | $(check "$cla") | $(check "$gov") | $(check "$agent") | $ruleset_cell |"
done

echo
if [ "$FAILURES" -gt 0 ]; then
  echo "**$FAILURES check(s) failing.** Run \`scripts/org/rollout_governance.sh\` and \`scripts/org/apply_rulesets.sh\` from traverse-framework/.github to remediate."
  exit 1
fi
echo "All repos compliant."
