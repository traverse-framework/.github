# Changelog

All notable changes to the org-wide governance in this repository are documented here. Consuming repos pin a released version of this governance (recorded in their `.governance-version` file) and adopt new versions deliberately.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow [Semantic Versioning](https://semver.org/): a **major** bump means a rule change that can newly block merges in consuming repos; **minor** adds rules or tooling that are backwards-compatible; **patch** is clarification only.

## [1.0.1] - 2026-07-06

### Fixed

- `reusable-governance.yml` no longer executes the vendored spec-alignment script directly (it needs PR-context inputs and runs in each repo's own CI); it now verifies the script is wired into a workflow instead
- Org scripts made portable to the bash 3.2 shipped with macOS (no `mapfile`)
- `rollout_governance.sh` now declares governing specs in the PR body and links a tracking issue, satisfying consuming repos' spec-alignment and traceability gates

### Changed

- Caller workflows reference the reusable workflows at this repo's default branch instead of a moving `v1` tag; release tags (`vX.Y.Z`) remain the pin points for adopted governance content

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
