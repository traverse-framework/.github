#!/usr/bin/env bash
# List issues that have carried agent:* for >7 days with no branch/PR activity (.github#57).
set -euo pipefail
ORG="${1:-traverse-framework}"
cutoff_epoch=$(( $(date -u +%s) - 7*24*3600 ))
echo "# Stale agent claims (>7 days, no branch/PR)"
echo
gh search issues --owner "$ORG" --label 'agent:claude','agent:codex','agent:cursor' --state open --limit 50 \
  --json repository,number,title,labels,updatedAt \
  --jq '.[] | [.repository.nameWithOwner, (.number|tostring), .updatedAt, .title] | @tsv' \
  | while IFS=$'\t' read -r repo number updated title; do
      updated_epoch="$(python3 -c "from datetime import datetime; print(int(datetime.fromisoformat('${updated}'.replace('Z','+00:00')).timestamp()))")"
      if [[ "$updated_epoch" -gt "$cutoff_epoch" ]]; then
        continue
      fi
      if git ls-remote --heads "https://github.com/${repo}.git" 2>/dev/null | grep -E "issue-${number}-" >/dev/null; then
        continue
      fi
      if gh pr list --repo "$repo" --state open --search "${number}" --json number --jq 'length' | grep -vq '^0$'; then
        continue
      fi
      echo "- ${repo}#${number} (updated ${updated}): ${title}"
    done
