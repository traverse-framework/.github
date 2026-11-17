#!/usr/bin/env bash
# Release a claimed issue (.github#57).
# Usage: scripts/agent/release.sh <issue-number> <status> [--repo OWNER/REPO] [--project-item-id ID]
# status: Ready | Blocked | Done
set -euo pipefail

ISSUE="${1:?usage: release.sh <issue> <Ready|Blocked|Done>}"
STATUS="${2:?usage: release.sh <issue> <Ready|Blocked|Done>}"
shift 2
REPO="${TRAVERSE_CLAIM_REPO:-traverse-framework/traverse}"
ITEM_ID="${TRAVERSE_PROJECT_ITEM_ID:-}"
PROJECT_ID="${TRAVERSE_PROJECT_ID:-PVT_kwDOEbiBt84Bbyp1}"
STATUS_FIELD="${TRAVERSE_STATUS_FIELD_ID:-PVTSSF_lADOEbiBt84Bbyp1zhWglqM}"

case "$STATUS" in
  Ready) OPTION=f75ad846 ;;
  "In Progress") OPTION=47fc9ee4 ;;
  Done) OPTION=98236657 ;;
  Blocked) OPTION=294b89f5 ;;
  *) echo "status must be Ready, Blocked, Done, or In Progress" >&2; exit 2 ;;
esac

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo) REPO="$2"; shift 2 ;;
    --project-item-id) ITEM_ID="$2"; shift 2 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

for label in claude codex cursor; do
  gh issue edit "$ISSUE" --repo "$REPO" --remove-label "agent:${label}" 2>/dev/null || true
done

if [[ -n "$ITEM_ID" ]]; then
  gh project item-edit --project-id "$PROJECT_ID" --id "$ITEM_ID" \
    --field-id "$STATUS_FIELD" --single-select-option-id "$OPTION"
fi

gh issue comment "$ISSUE" --repo "$REPO" --body "Released claim; Project status set to \`${STATUS}\` at $(date -u +%Y-%m-%dT%H:%MZ)."
echo "released #$ISSUE -> $STATUS"
