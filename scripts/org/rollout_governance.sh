#!/usr/bin/env bash
# Roll the shared governance workflows and required files out to org repos.
#
# For each target repo, creates branch `governance-rollout-<version>` from the
# default branch, adds any missing governance artifacts, and opens a PR:
#   - .github/workflows/cla.yml          (calls reusable-cla.yml)
#   - .github/workflows/governance.yml   (calls reusable-governance.yml)
#   - .github/CODEOWNERS                 (if missing)
#   - .github/dependabot.yml             (if missing; ecosystems auto-detected)
#   - .governance-version                (created or updated to $VERSION)
#
# Usage: scripts/org/rollout_governance.sh <version-tag> [repo ...]
#        e.g. scripts/org/rollout_governance.sh v1.0.0 registry website
#        (default repos: all org repos except .github)
# Requires: gh CLI with push access; git.
set -euo pipefail

ORG="traverse-framework"
VERSION="${1:?usage: rollout_governance.sh <version-tag> [repo ...]}"
shift || true
BRANCH="governance-rollout-$VERSION"
WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT

if [ "$#" -gt 0 ]; then
  repos=("$@")
else
  repos=()
  while IFS= read -r r; do repos+=("$r"); done \
    < <(gh repo list "$ORG" --limit 200 --json name --jq '.[].name | select(. != ".github")')
fi

write_cla_workflow() {
  mkdir -p "$1/.github/workflows"
  cat > "$1/.github/workflows/cla.yml" <<EOF
# Org-wide CLA gate — see traverse-framework/.github (governance $VERSION).
name: cla

on:
  issue_comment:
    types: [created]
  pull_request_target:
    types: [opened, closed, synchronize]

permissions:
  actions: write
  contents: read
  pull-requests: write
  statuses: write

jobs:
  cla:
    uses: traverse-framework/.github/.github/workflows/reusable-cla.yml@v1
    secrets:
      cla-assistant-pat: \${{ secrets.CLA_ASSISTANT_PAT }}
EOF
}

write_governance_workflow() {
  mkdir -p "$1/.github/workflows"
  cat > "$1/.github/workflows/governance.yml" <<EOF
# Org-wide governance baseline gate — see traverse-framework/.github (governance $VERSION).
name: governance

on:
  pull_request: {}

permissions:
  contents: read

jobs:
  baseline:
    uses: traverse-framework/.github/.github/workflows/reusable-governance.yml@v1
EOF
}

# Print `- <spec-id>` lines for approved specs governing the workflow files
# this rollout adds, so PR bodies satisfy the repo's spec-alignment gate.
governing_specs() { # <repo-checkout-dir>
  python3 - "$1" <<'PY'
import json, sys
from pathlib import Path

reg_path = Path(sys.argv[1]) / "specs/governance/approved-specs.json"
if not reg_path.is_file():
    sys.exit(0)
try:
    registry = json.loads(reg_path.read_text())
except Exception:
    sys.exit(0)
added = [".github/workflows/cla.yml", ".github/workflows/governance.yml"]
for spec in registry.get("specs", []):
    if any(p.startswith(prefix) for prefix in spec.get("governs", []) for p in added):
        print(f"- `{spec['id']}`")
PY
}

for repo in "${repos[@]}"; do
  echo "=== $ORG/$repo ==="
  dir="$WORKDIR/$repo"
  gh repo clone "$ORG/$repo" "$dir" -- --depth 1 --quiet
  git -C "$dir" checkout -b "$BRANCH" --quiet

  write_cla_workflow "$dir"
  write_governance_workflow "$dir"
  printf '%s\n' "$VERSION" > "$dir/.governance-version"

  if [ ! -e "$dir/.github/CODEOWNERS" ]; then
    mkdir -p "$dir/.github"
    printf '* @enricopiovesan\n' > "$dir/.github/CODEOWNERS"
  fi

  if [ ! -e "$dir/.github/dependabot.yml" ]; then
    mkdir -p "$dir/.github"
    {
      echo 'version: 2'
      echo 'updates:'
      echo '  - package-ecosystem: "github-actions"'
      echo '    directory: "/"'
      echo '    schedule: { interval: "weekly" }'
      [ -e "$dir/Cargo.toml" ] && {
        echo '  - package-ecosystem: "cargo"'
        echo '    directory: "/"'
        echo '    schedule: { interval: "weekly" }'
      }
      [ -e "$dir/package.json" ] && {
        echo '  - package-ecosystem: "npm"'
        echo '    directory: "/"'
        echo '    schedule: { interval: "weekly" }'
      }
    } > "$dir/.github/dependabot.yml"
  fi

  if [ ! -e "$dir/CLAUDE.md" ] && [ ! -e "$dir/AGENTS.md" ]; then
    cat > "$dir/CLAUDE.md" <<EOF
# CLAUDE.md

This repo follows the org-wide governance in
https://github.com/traverse-framework/.github, version $VERSION
(see \`.governance-version\`). Read that repo's constitution, quality
standards, and AI-agent hardening rules before making changes here.
EOF
  fi

  if git -C "$dir" diff --quiet && [ -z "$(git -C "$dir" status --porcelain)" ]; then
    echo "already compliant, skipping"
    continue
  fi

  git -C "$dir" add -A
  git -C "$dir" commit --quiet -m "Adopt org governance $VERSION: shared CLA + governance gates, CODEOWNERS, dependabot, version pin"
  git -C "$dir" push --quiet -u origin "$BRANCH"

  issue_url="$(gh issue create --repo "$ORG/$repo" \
    --title "Adopt org governance $VERSION" \
    --body "Tracking issue for the governance rollout PR (branch \`$BRANCH\`). See https://github.com/traverse-framework/.github/blob/$VERSION/CHANGELOG.md" \
    2>/dev/null || true)"

  body_file="$WORKDIR/pr-body-$repo.md"
  sed "s/@VERSION@/$VERSION/g" > "$body_file" <<'EOF'
Adopts the org-wide governance released as [@VERSION@](https://github.com/traverse-framework/.github/blob/@VERSION@/CHANGELOG.md):

- **cla.yml** — CLA gate on every PR (contributor-assistant, signatures stored centrally in `traverse-framework/.github@cla-signatures`). Requires the `CLA_ASSISTANT_PAT` secret; until it is set, the check fails closed for external contributors.
- **governance.yml** — baseline gate: governance version pin, CODEOWNERS, dependabot config, agent docs, and the vendored spec-alignment check when present.
- **.governance-version** — pins this repo to governance @VERSION@; adopting a newer release is a deliberate PR.
- **CODEOWNERS / dependabot.yml** — added only if the repo didn't have them.

See CONTRIBUTING.md and GOVERNANCE.md in traverse-framework/.github for the rules these gates enforce.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF

  specs_lines="$(governing_specs "$dir")"
  if [ -n "$specs_lines" ]; then
    {
      echo
      echo "## Governing Spec"
      echo
      echo "$specs_lines"
    } >> "$body_file"
  fi
  if [ -n "$issue_url" ]; then
    {
      echo
      echo "Closes $issue_url"
    } >> "$body_file"
  fi

  gh pr create --repo "$ORG/$repo" \
    --head "$BRANCH" \
    --title "Adopt org governance $VERSION" \
    --body-file "$body_file" || echo "PR may already exist for $BRANCH"
done
