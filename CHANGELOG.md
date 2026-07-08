# Changelog

All notable changes to the org-wide governance in this repository are documented here. Consuming repos pin a released version of this governance (recorded in their `.governance-version` file) and adopt new versions deliberately.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow [Semantic Versioning](https://semver.org/): a **major** bump means a rule change that can newly block merges in consuming repos; **minor** adds rules or tooling that are backwards-compatible; **patch** is clarification only.

## [1.1.1] - 2026-07-08

### Fixed

- Baseline gate: the spec-alignment wiring requirement now applies only once a repo has approved specs — the gate script refuses an empty registry, so templates and brand-new repos could never satisfy it
- Baseline gate: the doc-duplication warning accepts a substantial AGENTS.md that declares CLAUDE.md canonical (coordination-only content)

## [1.1.0] - 2026-07-07

### Added

- Token-discipline rules in `docs/ai-agent-hardening.md`: single canonical agent doc (CLAUDE.md canonical, AGENTS.md = pointer + tool-coordination only), no version numbers in prose (point at `.governance-version`), no state snapshots in docs (live queries instead), `.claudeignore` required, lazy doc-reading map, PR-body section superset, bounded `gh` queries, org-wide lean-implementation ladder and claim-before-you-code rule
- Baseline gate emits **warnings** (non-blocking) for: missing `.claudeignore`, hardcoded governance versions that drift from `.governance-version`, substantial CLAUDE.md+AGENTS.md duplication, CLAUDE.md over 8KB. These become blocking checks in the next **major** release.

## [1.0.2] - 2026-07-07

### Fixed

- CLA gate degrades gracefully while `CLA_ASSISTANT_PAT` is unset: allowlisted authors (owner and `*[bot]`) pass with a warning instead of everyone failing at action startup; non-allowlisted authors still fail closed. With `cla / cla` now a required check org-wide, the previous behavior blocked every PR including the owner's and Dependabot's.
- CLA allowlist covers the owner's coding-agent identities (`claude`, `cursoragent`, and the owner's unlinked local git identity) so agent-authored PRs aren't asked to sign the owner's own CLA.

## [1.0.1] - 2026-07-06

### Fixed

- `reusable-governance.yml` no longer executes the vendored spec-alignment script directly (it needs PR-context inputs and runs in each repo's own CI); it now verifies the script is wired into a workflow instead
- Org scripts made portable to the bash 3.2 shipped with macOS (no `mapfile`)
- `rollout_governance.sh` now declares governing specs in the PR body and links a tracking issue, satisfying consuming repos' spec-alignment and traceability gates

### Changed

- Caller workflows reference the reusable workflows at this repo's default branch instead of a moving `v1` tag; release tags (`vX.Y.Z`) remain the pin points for adopted governance content
- CODEOWNERS is no longer a required governance file (solo-maintainer, agent-driven mode): removed from the baseline gate, the audit, and the rollout. Human-approval requirements stay at zero; enforcement is automated checks only. Reintroduce CODEOWNERS when a second maintainer joins.

### Added (1.0.1)

- `governance/rulesets/required-checks-ruleset.json` — requires `baseline / governance-baseline` and `cla / cla` on default branches, so auto-merge waits for the gates; apply only after every repo carries the caller workflows (see docs/owner-setup.md)
- `apply_rulesets.sh` applies every ruleset JSON in `governance/rulesets/` (or a single one via `-f`)

## [1.0.0] - 2026-07-06

First versioned governance release.

### Added

- Constitution, quality standards, antipatterns, compatibility policy, exception process, AI-agent hardening rules
- Contributor License Agreement (`CLA.md`) with automated enforcement via the reusable CLA workflow
- Governance and ownership model (`GOVERNANCE.md`)
- Trademark policy (`TRADEMARK.md`) and Apache-2.0 `NOTICE`
- Org-wide community health defaults: `CODE_OF_CONDUCT.md` (Contributor Covenant 2.1), `SECURITY.md`, `SUPPORT.md`, issue/PR templates
- Reusable workflows: `reusable-cla.yml`, `reusable-governance.yml`
- Scheduled org-wide compliance audit (`org-audit.yml` + `scripts/org/audit_compliance.sh`)
- Canonical baseline branch ruleset (`governance/rulesets/baseline-branch-ruleset.json`) and `scripts/org/apply_rulesets.sh`
- Governance rollout script for consuming repos (`scripts/org/rollout_governance.sh`)
- Workflow templates for new repos (`workflow-templates/`)
- Canonical spec-alignment CI gate script (`scripts/ci/spec_alignment_check.sh`)
