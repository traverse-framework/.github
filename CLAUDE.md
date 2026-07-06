# CLAUDE.md

This is `traverse-framework/.github` — the org-wide governance repo. Every other repo in the org pins a release of this governance (`.governance-version`) and calls the reusable workflows here.

Rules for working in this repo:

- Read [constitution.md](constitution.md), [docs/quality-standards.md](docs/quality-standards.md), and [docs/ai-agent-hardening.md](docs/ai-agent-hardening.md) before changing anything.
- Changes to rules that can block merges in consuming repos are **major** governance releases — see the versioning policy in [CHANGELOG.md](CHANGELOG.md). Every rule change gets a CHANGELOG entry.
- Reusable workflows (`.github/workflows/reusable-*.yml`) are referenced by other repos at the `v1` tag. Breaking their inputs/secrets contract requires a new major tag, not an edit in place.
- The canonical ruleset lives in [governance/rulesets/](governance/rulesets); apply changes with [scripts/org/apply_rulesets.sh](scripts/org/apply_rulesets.sh), never by hand in the GitHub UI.
- Manual owner-only steps are tracked in [docs/owner-setup.md](docs/owner-setup.md) — keep it current when automation changes.
- The `cla-signatures` branch is CLA signature storage. Never rewrite, rebase, or delete it.
