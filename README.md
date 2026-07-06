# traverse-framework/.github

Shared governance for every repo under the `traverse-framework` GitHub organization: constitution, non-functional requirements, quality standards, ownership and trademark policy, contributor license agreement with automated enforcement, community health defaults, reusable CI gates, branch-protection rulesets, and an org-wide compliance audit.

## What Lives Here

| File | Purpose |
|---|---|
| [`constitution.md`](constitution.md) | Org-wide engineering/governance principles |
| [`GOVERNANCE.md`](GOVERNANCE.md) | Ownership model (single owner), decision process, transfer rights |
| [`CLA.md`](CLA.md) | Contributor License Agreement (draft — see notice in the file) |
| [`TRADEMARK.md`](TRADEMARK.md) | Trademark policy — the code license does not grant the name |
| [`NOTICE`](NOTICE) | Apache-2.0 attribution notice |
| [`CODE_OF_CONDUCT.md`](CODE_OF_CONDUCT.md), [`SECURITY.md`](SECURITY.md), [`SUPPORT.md`](SUPPORT.md) | Org-wide community health defaults (inherited by every repo) |
| [`docs/quality-standards.md`](docs/quality-standards.md) | Merge-blocking quality gates |
| [`docs/antipatterns.md`](docs/antipatterns.md) | Common repo-governance mistakes to avoid |
| [`docs/compatibility-policy.md`](docs/compatibility-policy.md) | Semver/compatibility rules for versioned surfaces |
| [`docs/exception-process.md`](docs/exception-process.md) | How to document and review an exception to a rule |
| [`docs/ai-agent-hardening.md`](docs/ai-agent-hardening.md) | Conventions every repo's `CLAUDE.md`/`AGENTS.md` should encode |
| [`docs/owner-setup.md`](docs/owner-setup.md) | Manual steps only the org owner can perform |
| [`CHANGELOG.md`](CHANGELOG.md) | Versioned governance releases (repos pin these) |
| [`.github/workflows/reusable-cla.yml`](.github/workflows/reusable-cla.yml) | Reusable CLA gate; signatures stored centrally on the `cla-signatures` branch |
| [`.github/workflows/reusable-governance.yml`](.github/workflows/reusable-governance.yml) | Reusable baseline gate: version pin, required files, spec-alignment |
| [`.github/workflows/org-audit.yml`](.github/workflows/org-audit.yml) | Weekly org-wide compliance audit; opens an issue when drift is found |
| [`governance/rulesets/baseline-branch-ruleset.json`](governance/rulesets/baseline-branch-ruleset.json) | Canonical branch ruleset applied to every repo |
| [`scripts/org/apply_rulesets.sh`](scripts/org/apply_rulesets.sh) | Applies the baseline ruleset to all org repos (idempotent) |
| [`scripts/org/rollout_governance.sh`](scripts/org/rollout_governance.sh) | Opens PRs adding the shared gates/files to consuming repos |
| [`scripts/org/audit_compliance.sh`](scripts/org/audit_compliance.sh) | The audit logic behind `org-audit.yml`; also runnable locally |
| [`scripts/ci/spec_alignment_check.sh`](scripts/ci/spec_alignment_check.sh) | Canonical spec-alignment CI gate script, vendored into consuming repos |
| [`workflow-templates/`](workflow-templates) | Starter workflows offered in every org repo's Actions tab |
| `.github/ISSUE_TEMPLATE/`, `PULL_REQUEST_TEMPLATE.md` | Default templates GitHub falls back to for any repo in this org that doesn't define its own |

## How Consuming Repos Use This

Each repo (`traverse`, `registry`, etc.) adopts governance three ways:

1. **Pinned version.** A `.governance-version` file records which release of this repo (see [`CHANGELOG.md`](CHANGELOG.md)) the repo has adopted. Vendored content (constitution, docs, the spec-alignment script) comes from that release. Adopting a new version is a deliberate PR — never automatic or silent.
2. **Shared gates.** Thin caller workflows (`cla.yml`, `governance.yml`) reference the reusable workflows here at the `v1` tag, so gate logic updates centrally.
3. **Enforced rulesets.** Every repo carries the baseline branch ruleset (PRs required, no force-push, no deletion, linear history, conversation resolution). Repos may be stricter, never looser. The weekly [`org-audit`](.github/workflows/org-audit.yml) catches drift.

New repos start from the [`repo-template`](https://github.com/traverse-framework/repo-template) template repository, which ships compliant.

This repo does **not** have its own GitHub Project board — governance work here is tracked via issues and PRs only.
