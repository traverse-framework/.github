#!/usr/bin/env bash
# Weekly development-health report per active repo (.github#60).
set -euo pipefail
ORG="${1:-traverse-framework}"
DAYS="${2:-7}"
echo "# Development health — last ${DAYS} days"
echo
echo "| repo | CI median (min) | CI p90 (min) | PR fail % | main fail % | fix-titled % | by tool (claude/codex/cursor/other) |"
echo "|---|---|---|---|---|---|---|"

repos=(traverse registry reference-apps website)
for repo in "${repos[@]}"; do
  gh api "repos/${ORG}/${repo}/actions/runs?per_page=50" --jq \
    --arg days "$DAYS" '
      .workflow_runs
      | map(select(.name=="CI" or .name=="ci" or (.path|test("ci.yml"))))
      | map(select(.status=="completed"))
      | . as $all
      | ($all | map(select(.event=="pull_request")) | length) as $pr_n
      | ($all | map(select(.event=="pull_request" and .conclusion!="success" and .conclusion!="skipped")) | length) as $pr_fail
      | ($all | map(select(.head_branch=="main" or .head_branch=="bootstrap-governance")) | length) as $main_n
      | ($all | map(select((.head_branch=="main" or .head_branch=="bootstrap-governance") and .conclusion!="success" and .conclusion!="skipped")) | length) as $main_fail
      | [
          ($all | map( ((.updated_at|fromdateiso8601) - (.created_at|fromdateiso8601)) / 60 ) | sort) as $durs
          | if ($durs|length)==0 then [0,0]
            else
              [ $durs[(($durs|length)/2|floor)], $durs[((($durs|length)*9/10)|floor)] ]
            end
        ] as $stats
      | "\($stats[0])|\($stats[1])|\(if $pr_n==0 then 0 else ($pr_fail*100/$pr_n) end)|\(if $main_n==0 then 0 else ($main_fail*100/$main_n) end)"
    ' 2>/dev/null | {
      IFS='|' read -r median p90 prfail mainfail || true
      median=${median:-?}
      p90=${p90:-?}
      prfail=${prfail:-?}
      mainfail=${mainfail:-?}
      # Merged PRs
      merged="$(gh pr list --repo "$ORG/$repo" --state merged --limit 50 --json title,headRefName,mergedAt --jq '
        map(select(.mergedAt != null)) | .[0:40]
      ' 2>/dev/null || echo '[]')"
      stats="$(python3 -c "
import json,sys
prs=json.loads('''$merged'''.replace(\"'''\",\"\"\") if False else '''${merged}''')
" 2>/dev/null || true)"
      # Simpler python via file
      printf '%s\n' "$merged" > /tmp/merged-prs.json
      read -r fix_pct tools < <(python3 - <<'PY'
import json
prs=json.load(open('/tmp/merged-prs.json'))
n=len(prs) or 1
fix=sum(1 for p in prs if p.get('title','').lower().startswith('fix'))
from collections import Counter
c=Counter()
for p in prs:
    h=p.get('headRefName') or ''
    if h.startswith('claude/'): c['claude']+=1
    elif h.startswith('codex/'): c['codex']+=1
    elif h.startswith('cursor/'): c['cursor']+=1
    else: c['other']+=1
print(f"{fix*100//n} {c['claude']}/{c['codex']}/{c['cursor']}/{c['other']}")
PY
)
      echo "| $repo | ${median} | ${p90} | ${prfail} | ${mainfail} | ${fix_pct} | ${tools} |"
    }
done
echo
echo "_Review-queue metrics (cross-tool vs fallback, median wait) land once Decision 133 records are required._"
