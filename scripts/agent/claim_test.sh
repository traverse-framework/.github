#!/usr/bin/env bash
# Tests for scripts/agent/claim.sh and release.sh (.github#57). `gh` and `git`
# are replaced by stubs that answer from fixture JSON and log every mutation,
# so nothing touches GitHub.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
work="$(mktemp -d)"
trap 'rm -rf "${work}"' EXIT
mkdir -p "${work}/bin"

cat > "${work}/bin/gh" <<'STUB'
#!/usr/bin/env bash
# Answers read commands from $FAKE_* JSON (applying --jq like gh does);
# logs mutating commands to $FAKE_LOG.
jq_expr=""
args=("$@")
for ((i = 0; i < ${#args[@]}; i++)); do
  [[ "${args[i]}" == "--jq" ]] && jq_expr="${args[i + 1]}"
done
answer() { if [[ -n "${jq_expr}" ]]; then jq -r "${jq_expr}" <<<"$1"; else printf '%s\n' "$1"; fi; }
case "$1 $2" in
  "issue view") answer "${FAKE_ISSUE}" ;;
  "api graphql") answer "${FAKE_ITEMS}" ;;
  "pr list") answer "${FAKE_PRS:-[]}" ;;
  "issue edit"|"issue comment"|"project item-edit") echo "$*" >> "${FAKE_LOG}" ;;
  *) echo "unexpected gh call: $*" >&2; exit 99 ;;
esac
STUB
cat > "${work}/bin/git" <<'STUB'
#!/usr/bin/env bash
case "$1" in
  ls-remote) printf '%s' "${FAKE_HEADS:-}" ;;
  rev-parse) exit 1 ;;
  *) echo "unexpected git call: $*" >&2; exit 99 ;;
esac
STUB
chmod +x "${work}/bin/gh" "${work}/bin/git"

cat > "${work}/config.json" <<'JSON'
{
  "repo": "example/repo",
  "project_id": "PVT_project",
  "status_field_id": "PVTSSF_status",
  "status_options": { "Ready": "opt-ready", "In Progress": "opt-progress", "Blocked": "opt-blocked", "Done": "opt-done" }
}
JSON

failures=0
export PATH="${work}/bin:${PATH}" AGENT_CLAIM_CONFIG="${work}/config.json" FAKE_LOG="${work}/log"

items() { # items <status> -> graphql answer with one item on PVT_project (plus one elsewhere)
  printf '{"data":{"repository":{"issue":{"projectItems":{"nodes":[{"id":"PVTI_other","project":{"id":"PVT_elsewhere"},"fieldValueByName":{"name":"Ready"}},{"id":"PVTI_item","project":{"id":"PVT_project"},"fieldValueByName":{"name":"%s"}}]}}}}}' "$1"
}
reset() {
  export FAKE_ISSUE='{"state":"OPEN","labels":[{"name":"enhancement"}]}'
  FAKE_ITEMS="$(items Ready)"
  export FAKE_ITEMS FAKE_PRS='[]' FAKE_HEADS=''
  : > "${FAKE_LOG}"
}
ok() { echo "ok - $1"; }
bad() { echo "not ok - $1" >&2; failures=$((failures + 1)); }

# expect <name> <want-exit> <stderr-or-stdout-substring> <command...>
expect() {
  local name="$1" want="$2" text="$3" got=0
  shift 3
  "$@" > "${work}/out" 2>&1 || got=$?
  if [[ "${got}" -ne "${want}" ]]; then
    bad "${name}: exit ${got}, want ${want}: $(cat "${work}/out")"
  elif ! grep -qF -- "${text}" "${work}/out"; then
    bad "${name}: output lacks '${text}': $(cat "${work}/out")"
  else
    ok "${name}"
  fi
}
no_mutations() {
  if [[ -s "${FAKE_LOG}" ]]; then bad "$1: changed something: $(cat "${FAKE_LOG}")"; else ok "$1: changed nothing"; fi
}

claim="${root}/scripts/agent/claim.sh"
release="${root}/scripts/agent/release.sh"

reset
expect "clean claim" 0 "claimed example/repo#12 as agent:codex" bash "${claim}" 12 codex
grep -q -- "issue edit 12 --repo example/repo --add-label agent:codex" "${FAKE_LOG}" && ok "clean claim adds the label" || bad "clean claim adds the label"
grep -q -- "--id PVTI_item --field-id PVTSSF_status --single-select-option-id opt-progress" "${FAKE_LOG}" &&
  ok "clean claim sets the configured item to In Progress" || bad "clean claim sets In Progress: $(cat "${FAKE_LOG}")"
grep -q -- "issue comment 12 --repo example/repo --body Claimed by \`agent:codex\`" "${FAKE_LOG}" &&
  ok "clean claim posts the audit comment" || bad "clean claim posts the audit comment"

reset
expect "dry run" 0 "dry run: example/repo#12 can be claimed by agent:cursor" bash "${claim}" 12 cursor --dry-run
no_mutations "dry run"

reset
export FAKE_ISSUE='{"state":"OPEN","labels":[{"name":"agent:claude"}]}'
expect "already labelled" 1 "already claimed: agent:claude" bash "${claim}" 12 codex
no_mutations "already labelled"

reset
export FAKE_HEADS=$'abc\trefs/heads/cursor/issue-12-fix\n'
expect "branch from another tool" 1 "cursor/issue-12-fix" bash "${claim}" 12 claude
no_mutations "branch from another tool"

reset
export FAKE_HEADS=$'abc\trefs/heads/claude/issue-123-other\n'
expect "a branch for a longer issue number is not a match" 0 "claimed" bash "${claim}" 12 claude

reset
export FAKE_PRS='[{"number":7,"headRefName":"codex/issue-12-thing"}]'
expect "open PR" 1 "#7 codex/issue-12-thing" bash "${claim}" 12 claude
no_mutations "open PR"

reset
FAKE_ITEMS="$(items Blocked)"
export FAKE_ITEMS
expect "not Ready" 1 "is 'Blocked' on the Project, not Ready" bash "${claim}" 12 claude
no_mutations "not Ready"

reset
export FAKE_ITEMS='{"data":{"repository":{"issue":{"projectItems":{"nodes":[]}}}}}'
expect "not on the Project" 1 "has no item on the configured Project" bash "${claim}" 12 claude
no_mutations "not on the Project"

reset
export FAKE_ISSUE='{"state":"CLOSED","labels":[]}'
expect "closed issue" 1 "is CLOSED" bash "${claim}" 12 claude
no_mutations "closed issue"

reset
expect "unknown agent" 2 "agent must be claude, codex or cursor" bash "${claim}" 12 copilot
expect "missing config" 2 "claim config not found" env AGENT_CLAIM_CONFIG="${work}/nope.json" bash "${claim}" 12 claude
expect "--repo overrides the config" 0 "claimed other/repo#12" bash "${claim}" 12 claude --repo other/repo

reset
export FAKE_ISSUE='{"state":"OPEN","labels":[{"name":"agent:codex"},{"name":"bug"}]}'
expect "release" 0 "released example/repo#12 -> Done" bash "${release}" 12 Done
grep -q -- "--remove-label agent:codex" "${FAKE_LOG}" && ! grep -q -- "--remove-label bug" "${FAKE_LOG}" &&
  ok "release removes only agent labels" || bad "release removes only agent labels: $(cat "${FAKE_LOG}")"
grep -q -- "--single-select-option-id opt-done" "${FAKE_LOG}" && ok "release sets the named status" || bad "release sets the named status"

reset
export FAKE_ISSUE='{"state":"OPEN","labels":[{"name":"agent:codex"}]}'
expect "release dry run" 0 "dry run: would remove 'agent:codex'" bash "${release}" 12 Ready --dry-run
no_mutations "release dry run"
expect "release bad status" 2 "status must be" bash "${release}" 12 Shipped

if [[ "${failures}" -gt 0 ]]; then
  echo "${failures} claim/release test(s) failed" >&2
  exit 1
fi
echo "claim/release tests passed"
