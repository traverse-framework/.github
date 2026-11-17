#!/usr/bin/env bash
# Sync .agents/skills/ into .claude/skills/ and .cursor/skills/ (.github#58).
# Generated files carry a header marking them as generated.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
src="${root}/.agents/skills"
[[ -d "$src" ]] || { echo "no .agents/skills in $root"; exit 0; }

write_copy() {
  local from="$1" to="$2" tool="$3"
  mkdir -p "$(dirname "$to")"
  {
    echo "<!-- GENERATED from .agents/skills by scripts/agent/sync_skills.sh for ${tool}. Do not edit. -->"
    echo
    cat "$from"
  } > "$to"
}

find "$src" -type f -name 'SKILL.md' | while read -r skill; do
  rel="${skill#"$src"/}"
  write_copy "$skill" "${root}/.claude/skills/${rel}" "claude"
  write_copy "$skill" "${root}/.cursor/skills/${rel}" "cursor"
done
echo "synced skills from .agents/skills"
