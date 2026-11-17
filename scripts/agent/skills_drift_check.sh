#!/usr/bin/env bash
# Fail when generated Claude/Cursor skill copies drift from .agents/skills (.github#58).
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
src="${root}/.agents/skills"
[[ -d "$src" ]] || { echo "no .agents/skills; nothing to check"; exit 0; }

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
cp -R "$src" "$tmpdir/src"
# Rebuild expected copies into tmp
mkdir -p "$tmpdir/out/.claude/skills" "$tmpdir/out/.cursor/skills"
find "$tmpdir/src" -type f -name 'SKILL.md' | while read -r skill; do
  rel="${skill#"$tmpdir/src"/}"
  for tool_dir in .claude/skills .cursor/skills; do
    tool="${tool_dir%%/*}"
    dest="$tmpdir/out/${tool_dir}/${rel}"
    mkdir -p "$(dirname "$dest")"
    {
      echo "<!-- GENERATED from .agents/skills by scripts/agent/sync_skills.sh for ${tool#.} -->"
      # normalize tool name in header to match sync script
    } >/dev/null
  done
done

# Prefer comparing by re-running sync into a temp checkout of the repo files
mkdir -p "$tmpdir/repo/.agents"
cp -R "$src" "$tmpdir/repo/.agents/skills"
# copy existing generated trees if present for comparison after sync into temp
[[ -d "$root/.claude/skills" ]] && cp -R "$root/.claude/skills" "$tmpdir/before-claude" || mkdir -p "$tmpdir/before-claude"
[[ -d "$root/.cursor/skills" ]] && cp -R "$root/.cursor/skills" "$tmpdir/before-cursor" || mkdir -p "$tmpdir/before-cursor"

(
  cd "$tmpdir/repo"
  # minimal sync inline
  find .agents/skills -type f -name 'SKILL.md' | while read -r skill; do
    rel="${skill#.agents/skills/}"
    for pair in "claude:.claude/skills" "cursor:.cursor/skills"; do
      tool="${pair%%:*}"
      dest="${pair#*:}/${rel}"
      mkdir -p "$(dirname "$dest")"
      {
        echo "<!-- GENERATED from .agents/skills by scripts/agent/sync_skills.sh for ${tool}. Do not edit. -->"
        echo
        cat "$skill"
      } > "$dest"
    done
  done
)

drift=0
if [[ -d "$root/.claude/skills" ]]; then
  if ! diff -ru "$tmpdir/repo/.claude/skills" "$root/.claude/skills" >/tmp/skills-claude-drift.txt; then
    echo "Claude skill copies drifted from .agents/skills:" >&2
    cat /tmp/skills-claude-drift.txt >&2
    drift=1
  fi
fi
if [[ -d "$root/.cursor/skills" ]]; then
  if ! diff -ru "$tmpdir/repo/.cursor/skills" "$root/.cursor/skills" >/tmp/skills-cursor-drift.txt; then
    echo "Cursor skill copies drifted from .agents/skills:" >&2
    cat /tmp/skills-cursor-drift.txt >&2
    drift=1
  fi
fi
exit "$drift"
