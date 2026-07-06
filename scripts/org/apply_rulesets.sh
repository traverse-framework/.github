#!/usr/bin/env bash
# Apply the canonical baseline branch ruleset to every repo in the org.
#
# The org is on the GitHub Free plan, where org-level rulesets are not
# available, so the same ruleset JSON is applied per-repo. Repo-level
# rulesets are free on public repositories. Rulesets layer on top of any
# classic branch protection a repo already has; the strictest rule wins,
# so repos like `traverse` keep their stronger settings.
#
# Idempotent: updates the ruleset in place when one with the same name
# already exists.
#
# Usage: scripts/org/apply_rulesets.sh [repo ...]   (default: all org repos)
# Requires: gh CLI authenticated with admin access to the repos.
set -euo pipefail

ORG="traverse-framework"
RULESET_FILE="$(cd "$(dirname "$0")/../.." && pwd)/governance/rulesets/baseline-branch-ruleset.json"
RULESET_NAME="$(jq -r .name "$RULESET_FILE")"

if [ "$#" -gt 0 ]; then
  repos=("$@")
else
  mapfile -t repos < <(gh repo list "$ORG" --limit 200 --json name --jq '.[].name')
fi

for repo in "${repos[@]}"; do
  existing_id="$(gh api "repos/$ORG/$repo/rulesets" --jq \
    ".[] | select(.name == \"$RULESET_NAME\") | .id" 2>/dev/null || true)"
  if [ -n "$existing_id" ]; then
    gh api -X PUT "repos/$ORG/$repo/rulesets/$existing_id" --input "$RULESET_FILE" >/dev/null
    echo "updated ruleset '$RULESET_NAME' on $ORG/$repo (id $existing_id)"
  else
    gh api -X POST "repos/$ORG/$repo/rulesets" --input "$RULESET_FILE" >/dev/null
    echo "created ruleset '$RULESET_NAME' on $ORG/$repo"
  fi
done
