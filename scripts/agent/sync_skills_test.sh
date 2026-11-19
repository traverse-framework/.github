#!/usr/bin/env bash
# Tests for scripts/agent/sync_skills.sh and skills_drift_check.sh (.github#58).
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
sync="${here}/sync_skills.sh"
check="${here}/skills_drift_check.sh"
work="$(mktemp -d)"
trap 'rm -rf "${work}"' EXIT
failures=0
ok() { echo "ok - $1"; }
bad() { echo "not ok - $1" >&2; failures=$((failures + 1)); }

fresh() { # fresh repo with two skills
  rm -rf "${work}/repo"
  mkdir -p "${work}/repo/.agents/skills/ops/references" "${work}/repo/.agents/skills/ship"
  printf -- '---\nname: ops\ndescription: Run ops.\n---\n\n# Ops\n\nBody.\n' > "${work}/repo/.agents/skills/ops/SKILL.md"
  printf 'Reference text.\n' > "${work}/repo/.agents/skills/ops/references/notes.md"
  printf -- '---\nname: ship\ndescription: Ship it.\n---\n# Ship\n' > "${work}/repo/.agents/skills/ship/SKILL.md"
}
run() { SKILLS_ROOT="${work}/repo" bash "$@" > "${work}/out" 2>&1; }
expect_check() { # expect_check <name> <want-exit> <text>
  local got=0
  run "${check}" || got=$?
  if [[ "${got}" -ne "$2" ]]; then bad "$1: exit ${got}, want $2: $(cat "${work}/out")"
  elif ! grep -qF -- "$3" "${work}/out"; then bad "$1: output lacks '$3': $(cat "${work}/out")"
  else ok "$1"; fi
}

fresh
expect_check "copies missing before the first sync" 1 "missing: .claude/skills"
run "${sync}" && ok "sync writes copies" || bad "sync writes copies: $(cat "${work}/out")"
expect_check "in sync" 0 "skill copies match"

for tool in .claude .cursor; do
  copy="${work}/repo/${tool}/skills/ops/SKILL.md"
  [[ "$(head -1 "${copy}")" == "---" ]] && ok "${tool}: frontmatter stays on line 1" || bad "${tool}: frontmatter stays on line 1"
  grep -q "^<!-- GENERATED from .agents/skills" "${copy}" && ok "${tool}: generated marker present" || bad "${tool}: marker"
  [[ "$(sed -n 5,6p "${copy}")" == $'\n<!-- GENERATED from .agents/skills by scripts/agent/sync_skills.sh. Edit the source, then re-run the script. -->' ]] &&
    ok "${tool}: marker sits right after the frontmatter" || bad "${tool}: marker placement: $(sed -n 1,8p "${copy}")"
  cmp -s "${work}/repo/.agents/skills/ops/references/notes.md" "${work}/repo/${tool}/skills/ops/references/notes.md" &&
    ok "${tool}: non-SKILL files are copied verbatim" || bad "${tool}: references copied"
done
diff <(grep -v "GENERATED from" "${work}/repo/.claude/skills/ops/SKILL.md" | sed '5{/^$/d;}') "${work}/repo/.agents/skills/ops/SKILL.md" >/dev/null &&
  ok "the copy equals the source apart from the marker" || bad "the copy equals the source apart from the marker"

echo "hand edit" >> "${work}/repo/.claude/skills/ops/SKILL.md"
expect_check "a hand-edited copy is drift" 1 "drifted: .claude/skills/ops/SKILL.md"

run "${sync}"
rm "${work}/repo/.cursor/skills/ship/SKILL.md"
expect_check "a deleted copy is drift" 1 "missing in .cursor/skills"

run "${sync}"
mkdir -p "${work}/repo/.claude/skills/claude-only"
printf -- '---\nname: x\n---\n' > "${work}/repo/.claude/skills/claude-only/SKILL.md"
expect_check "a copy with no source is drift" 1 "extra in .claude/skills (no source)"
run "${sync}"
[[ ! -e "${work}/repo/.claude/skills/claude-only" ]] && ok "sync removes copies with no source" || bad "sync removes copies with no source"

echo "new line" >> "${work}/repo/.agents/skills/ship/SKILL.md"
expect_check "a source edit without a sync is drift" 1 "drifted: .cursor/skills/ship/SKILL.md"

fresh
printf '# No frontmatter\n' > "${work}/repo/.agents/skills/ship/SKILL.md"
got=0; run "${sync}" || got=$?
[[ "${got}" -ne 0 ]] && grep -q "must start with YAML frontmatter" "${work}/out" &&
  ok "a SKILL.md without frontmatter is rejected" || bad "frontmatter required: exit ${got} $(cat "${work}/out")"

rm -rf "${work}/repo" && mkdir -p "${work}/repo"
expect_check "a repo without .agents/skills passes" 0 "nothing to sync"

if [[ "${failures}" -gt 0 ]]; then
  echo "${failures} skill-sync test(s) failed" >&2
  exit 1
fi
echo "skill-sync tests passed"
