#!/usr/bin/env bash
# Apply the canonical branch rulesets to every repo in the org.
#
# The org is on the GitHub Free plan, where org-level rulesets are not
# available, so the same ruleset JSON is applied per-repo. Repo-level
# rulesets are free on public repositories. Rulesets layer on top of any
# classic branch protection a repo already has; the strictest rule wins,
# so repos like `traverse` keep their stronger settings.
#
# Applies every governance/rulesets/*.json by default. The required-checks
# ruleset must only be applied once the `cla`/`governance` caller workflows
# exist on each repo's default branch — otherwise the named checks never
# run and every PR is blocked. Use -f to apply a single ruleset file.
#
# Idempotent: updates a ruleset in place when one with the same name exists.
#
# Usage: scripts/org/apply_rulesets.sh [-f ruleset.json] [repo ...]
#        (default: all ruleset files, all org repos)
# Requires: gh CLI authenticated with admin access to the repos.
set -euo pipefail

ORG="traverse-framework"
RULESET_DIR="$(cd "$(dirname "$0")/../.." && pwd)/governance/rulesets"

files=()
if [ "${1:-}" = "-f" ]; then
  files=("$2")
  shift 2
else
  while IFS= read -r f; do files+=("$f"); done \
    < <(ls "$RULESET_DIR"/*.json)
fi

if [ "$#" -gt 0 ]; then
  repos=("$@")
else
  repos=()
  while IFS= read -r r; do repos+=("$r"); done \
    < <(gh repo list "$ORG" --limit 200 --json name --jq '.[].name')
fi

for file in "${files[@]}"; do
  name="$(jq -r .name "$file")"
  for repo in "${repos[@]}"; do
    existing_id="$(gh api "repos/$ORG/$repo/rulesets" --jq \
      ".[] | select(.name == \"$name\") | .id" 2>/dev/null || true)"
    if [ -n "$existing_id" ]; then
      gh api -X PUT "repos/$ORG/$repo/rulesets/$existing_id" --input "$file" >/dev/null
      echo "updated ruleset '$name' on $ORG/$repo (id $existing_id)"
    else
      gh api -X POST "repos/$ORG/$repo/rulesets" --input "$file" >/dev/null
      echo "created ruleset '$name' on $ORG/$repo"
    fi
  done
done
