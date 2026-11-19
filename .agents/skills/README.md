# Agent skills (single source)

`.agents/skills/<skill>/` is the one committed source for agent skills (.github#58).
Codex reads it directly. `scripts/agent/sync_skills.sh` generates the Claude Code
copy (`.claude/skills/`) and the Cursor copy (`.cursor/skills/`), and
`scripts/agent/skills_drift_check.sh` fails CI when a generated copy differs.

This governance repo has no skills of its own yet. Consuming repos keep their
own `.agents/skills/` and vendor both scripts at their pinned governance
version. See `docs/ai-agent-hardening.md`.
