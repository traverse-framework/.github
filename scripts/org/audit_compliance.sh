#!/usr/bin/env bash
# Org-wide governance compliance audit.
#
# For every active (non-archived, non-exempt) repo in the org, checks the
# governance artifacts, the baseline branch ruleset, and the drift rules from
# docs/ai-agent-hardening.md (.github#59):
#   - .governance-version pins the latest governance release tag
#   - AGENTS.md exists and points at CLAUDE.md
#   - CLAUDE.md is within the size cap
#   - no governance version number is written in prose in CLAUDE.md, AGENTS.md,
#     the constitution file or the comments of .github/workflows/*.yml
#   - no local copy of the org constitution
# Prints a markdown report to stdout (used as the GitHub job summary by
# org-audit.yml) and exits non-zero if any repo is non-compliant.
#
# Usage: scripts/org/audit_compliance.sh
# Env:   AUDIT_ORG (default traverse-framework)
#        AUDIT_EXEMPT_FILE (default scripts/org/audit_exempt.txt)
# Requires: gh CLI. Ruleset checks need admin read; without it they report "?".
# Exits 2 (audit incomplete) if the GitHub API fails with anything other than
# 404, so a transient error never turns a check green.
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
ORG="${AUDIT_ORG:-traverse-framework}"
EXEMPT_FILE="${AUDIT_EXEMPT_FILE:-${here}/audit_exempt.txt}"
RULESET_NAME="traverse-governance-baseline"
CLAUDE_MD_CAP=6144
CONSTITUTION_FILE=".specify/memory/constitution.md"
# Principle headings a local file may share with the org constitution before
# it counts as a copy.
SHARED_HEADING_LIMIT=1
FAILURES=0

ERR_FILE="$(mktemp)"
trap 'rm -f "$ERR_FILE"' EXIT

api_failed() { # what -> exit 2 unless the last gh call was a 404
  grep -q 'HTTP 404' "$ERR_FILE" && return 0
  echo "audit incomplete: GitHub API error reading $1: $(tr '\n' ' ' < "$ERR_FILE")" >&2
  exit 2
}

has_file() { # repo path -> 0 if present, 1 if absent (404); exits 2 on other errors
  gh api "repos/$ORG/$1/contents/$2" --jq .path >/dev/null 2>"$ERR_FILE" && return 0
  api_failed "$1/$2"
  return 1
}

fetch() { # var repo path -> sets var to the file bytes; 1 if absent (404); exits 2 on other errors
  local out
  if out="$(gh api -H "Accept: application/vnd.github.raw" "repos/$ORG/$2/contents/$3" 2>"$ERR_FILE")"; then
    printf -v "$1" '%s' "$out"
    return 0
  fi
  api_failed "$2/$3"
  printf -v "$1" '%s' ""
  return 1
}

workflow_comments() { # repo -> comment lines of .github/workflows/*.yml|*.yaml on stdout
  local names name body
  names="$(gh api "repos/$ORG/$1/contents/.github/workflows" --jq '.[].name' 2>"$ERR_FILE")" || { api_failed "$1/.github/workflows"; return 0; }
  for name in $names; do
    case "$name" in *.yml|*.yaml) ;; *) continue ;; esac
    fetch body "$1" ".github/workflows/$name" || continue
    printf '%s\n' "$body" | grep -E '^[[:space:]]*#' || true
  done
}

cells() { # yes|no ... -> sets ROW to " ✅ | ❌ |..." and counts each "no" in FAILURES
  ROW=""
  for v in "$@"; do
    if [ "$v" = "yes" ]; then ROW="$ROW ✅ |"; else ROW="$ROW ❌ |"; FAILURES=$((FAILURES + 1)); fi
  done
}

# A governance version written in prose: a vX.Y.Z or X.Y.Z shortly after
# "governance" or ".github" in the same sentence, or directly before it
# ("v1.3.0 of governance"). Four-part numbers (IP addresses) are not versions.
prose_versions() { # stdin -> matching fragments
  local text; text="$(cat)"
  printf '%s\n' "$text" \
    | grep -oiE '(governance|\.github`?)[^0-9|.]{0,40}v?[0-9]+\.[0-9]+\.[0-9]+(\.[0-9]+)?' \
    | grep -vE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' || true
  printf '%s\n' "$text" \
    | grep -oiE '(^|[^0-9.])v?[0-9]+\.[0-9]+\.[0-9]+ +(of +)?(the +)?(org +)?`?(traverse-framework/)?(governance|\.github)' || true
}

exempt_reason() { # repo -> reason on stdout if exempt
  [ -f "$EXEMPT_FILE" ] || return 1
  awk -v r="$1" '$1 == r { $1 = ""; sub(/^[ \t]*#?[ \t]*/, ""); print; found = 1 } END { exit !found }' "$EXEMPT_FILE"
}

tags="$(gh api "repos/$ORG/.github/tags" --paginate --jq '.[].name' 2>"$ERR_FILE")" || api_failed ".github tags"
latest="$(printf '%s\n' "$tags" | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | sort -V | tail -1 || true)"
if [ -z "$latest" ]; then
  echo "cannot determine the latest governance release tag of $ORG/.github" >&2
  exit 2
fi
org_constitution=""
fetch org_constitution .github constitution.md || true
org_headings="$(printf '%s\n' "$org_constitution" | grep -E '^### ' || true)"
if [ -z "$org_headings" ]; then
  echo "cannot read principle headings from $ORG/.github constitution.md" >&2
  exit 2
fi

echo "# Governance compliance report — $ORG"
echo
echo "_Generated $(date -u +%Y-%m-%dT%H:%M:%SZ); latest governance release ${latest}_"
echo
echo "| repo | version pin | pin is ${latest} | dependabot | CLA wf | governance wf | agent docs | AGENTS.md → CLAUDE.md | CLAUDE.md ≤ 6 KB | no prose versions | no constitution copy | needs-review label | ruleset |"
echo "|---|---|---|---|---|---|---|---|---|---|---|---|---|"

repos=()
while IFS= read -r r; do repos+=("$r"); done \
  < <(gh repo list "$ORG" --limit 200 --json name,isArchived --jq '.[] | select(.isArchived | not) | .name')

exempt_rows=()
for repo in "${repos[@]}"; do
  if reason="$(exempt_reason "$repo")"; then
    exempt_rows+=("- \`$repo\`: ${reason:-exempt}")
    continue
  fi

  ver="no"; pin_current="no"
  if fetch pin "$repo" .governance-version; then
    ver="yes"
    [ "$(printf '%s' "$pin" | tr -d '[:space:]')" = "$latest" ] && pin_current="yes"
  fi
  dep="no"; has_file "$repo" ".github/dependabot.yml" && dep="yes"
  cla="no"; has_file "$repo" ".github/workflows/cla.yml" && cla="yes"
  gov="no"; has_file "$repo" ".github/workflows/governance.yml" && gov="yes"

  claude_md="" agents_md="" constitution=""
  has_claude="no"; fetch claude_md "$repo" CLAUDE.md && has_claude="yes"
  has_agents="no"; fetch agents_md "$repo" AGENTS.md && has_agents="yes"
  fetch constitution "$repo" "$CONSTITUTION_FILE" || true
  wf_comments="$(workflow_comments "$repo")"

  agent="no"; { [ "$has_claude" = "yes" ] || [ "$has_agents" = "yes" ]; } && agent="yes"
  agents_points="no"
  # The pointer must resolve: AGENTS.md names CLAUDE.md and CLAUDE.md exists.
  [ "$has_agents" = "yes" ] && [ "$has_claude" = "yes" ] && printf '%s' "$agents_md" | grep -q 'CLAUDE\.md' && agents_points="yes"
  claude_size="yes"
  [ "$has_claude" = "yes" ] && [ "$(printf '%s' "$claude_md" | wc -c)" -gt "$CLAUDE_MD_CAP" ] && claude_size="no"
  no_prose="yes"
  [ -n "$(printf '%s\n%s\n%s\n%s\n' "$claude_md" "$agents_md" "$constitution" "$wf_comments" | prose_versions)" ] && no_prose="no"
  no_copy="yes"
  if [ -n "$constitution" ]; then
    shared="$(printf '%s\n' "$constitution" | grep -E '^### ' | grep -cxF -- "$org_headings" || true)"
    [ "$shared" -gt "$SHARED_HEADING_LIMIT" ] && no_copy="no"
  fi

  needs_review="no"
  if gh label list --repo "$ORG/$repo" --limit 500 --json name --jq '.[].name' 2>/dev/null | grep -qx "needs-review"; then
    needs_review="yes"
  fi

  ruleset_cell="?"
  rulesets="$(gh api "repos/$ORG/$repo/rulesets" --jq '.[].name' 2>/dev/null || echo "__unreadable__")"
  if [ "$rulesets" != "__unreadable__" ]; then
    if echo "$rulesets" | grep -qx "$RULESET_NAME"; then ruleset_cell="✅"; else ruleset_cell="❌"; FAILURES=$((FAILURES + 1)); fi
  fi

  cells "$ver" "$pin_current" "$dep" "$cla" "$gov" "$agent" "$agents_points" "$claude_size" "$no_prose" "$no_copy" "$needs_review"
  echo "| $repo |$ROW $ruleset_cell |"
done

if [ "${#exempt_rows[@]}" -gt 0 ]; then
  echo
  echo "## Exempt repos"
  echo
  printf '%s\n' "${exempt_rows[@]}"
fi

echo
echo "## Stale agent claims"
echo
if [ -x "${here}/stale_claims.sh" ]; then
  "${here}/stale_claims.sh" "$ORG" || true
else
  echo "_stale_claims.sh not present_"
fi
echo
if [ "$FAILURES" -gt 0 ]; then
  echo "**$FAILURES check(s) failing.** Run \`scripts/org/rollout_governance.sh\` and \`scripts/org/apply_rulesets.sh\` from traverse-framework/.github to remediate."
  exit 1
fi
echo "All repos compliant."
