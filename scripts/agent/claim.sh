#!/usr/bin/env bash
# Claim a Ready Project 1 issue for one agent (.github#57).
# Usage: scripts/agent/claim.sh <issue-number> <agent> [--repo OWNER/REPO] [--project-item-id ID]
set -euo pipefail

ISSUE="${1:?usage: claim.sh <issue> <agent> [--repo OWNER/REPO]}"
AGENT="${2:?usage: claim.sh <issue> <agent> [--repo OWNER/REPO]}"
shift 2
REPO="${TRAVERSE_CLAIM_REPO:-traverse-framework/traverse}"
ITEM_ID="${TRAVERSE_PROJECT_ITEM_ID:-}"
PROJECT_ID="${TRAVERSE_PROJECT_ID:-PVT_kwDOEbiBt84Bbyp1}"
STATUS_FIELD="${TRAVERSE_STATUS_FIELD_ID:-PVTSSF_lADOEbiBt84Bbyp1zhWglqM}"
IN_PROGRESS_OPTION="${TRAVERSE_IN_PROGRESS_OPTION_ID:-47fc9ee4}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo) REPO="$2"; shift 2 ;;
    --project-item-id) ITEM_ID="$2"; shift 2 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

case "$AGENT" in
  claude|codex|cursor) ;;
  *) echo "agent must be claude, codex, or cursor" >&2; exit 2 ;;
esac

labels_json="$(gh issue view "$ISSUE" --repo "$REPO" --json labels,state --jq '{state, labels: [.labels[].name]}')"
state="$(jq -r .state <<<"$labels_json")"
if [[ "$state" != "OPEN" ]]; then
  echo "issue #$ISSUE is $state" >&2
  exit 1
fi
if jq -e '.labels[] | select(startswith("agent:"))' <<<"$labels_json" >/dev/null; then
  echo "issue #$ISSUE already has an agent:* label" >&2
  jq -r '.labels[] | select(startswith("agent:"))' <<<"$labels_json" >&2
  exit 1
fi

owner="${REPO%%/*}"
name="${REPO#*/}"
if git ls-remote --heads "https://github.com/${REPO}.git" 2>/dev/null | grep -E "refs/heads/[^/]+/issue-${ISSUE}-" >/dev/null; then
  echo "a remote issue-${ISSUE}-* branch already exists" >&2
  git ls-remote --heads "https://github.com/${REPO}.git" | grep -E "refs/heads/[^/]+/issue-${ISSUE}-" >&2
  exit 1
fi
if gh pr list --repo "$REPO" --state open --json headRefName --jq '.[].headRefName' | grep -E "(^|/)[^/]+/issue-${ISSUE}-" >/dev/null; then
  echo "an open PR already exists for issue-${ISSUE}" >&2
  exit 1
fi

gh issue edit "$ISSUE" --repo "$REPO" --add-label "agent:${AGENT}"
if [[ -n "$ITEM_ID" ]]; then
  gh project item-edit --project-id "$PROJECT_ID" --id "$ITEM_ID" \
    --field-id "$STATUS_FIELD" --single-select-option-id "$IN_PROGRESS_OPTION"
fi

branch="${AGENT}/issue-${ISSUE}-work"
gh issue comment "$ISSUE" --repo "$REPO" --body "Claimed by \`agent:${AGENT}\` at $(date -u +%Y-%m-%dT%H:%MZ). Suggested branch: \`${branch}\`."
echo "claimed #$ISSUE as agent:${AGENT}"
