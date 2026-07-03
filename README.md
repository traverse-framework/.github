# traverse-framework/.github

Shared governance for every repo under the `traverse-framework` GitHub organization: constitution, non-functional requirements, quality standards, antipatterns, compatibility policy, exception process, contributor license agreement, issue/PR templates, the shared spec-alignment CI gate script, and AI-agent hardening rules.

## What Lives Here

| File | Purpose |
|---|---|
| [`constitution.md`](constitution.md) | Org-wide engineering/governance principles |
| [`docs/quality-standards.md`](docs/quality-standards.md) | Merge-blocking quality gates |
| [`docs/antipatterns.md`](docs/antipatterns.md) | Common repo-governance mistakes to avoid |
| [`docs/compatibility-policy.md`](docs/compatibility-policy.md) | Semver/compatibility rules for versioned surfaces |
| [`docs/exception-process.md`](docs/exception-process.md) | How to document and review an exception to a rule |
| [`docs/ai-agent-hardening.md`](docs/ai-agent-hardening.md) | Conventions every repo's `CLAUDE.md`/`AGENTS.md` should encode |
| [`CLA.md`](CLA.md) | Contributor License Agreement (draft — see notice in the file) |
| [`scripts/ci/spec_alignment_check.sh`](scripts/ci/spec_alignment_check.sh) | Canonical spec-alignment CI gate script, vendored into consuming repos |
| `.github/ISSUE_TEMPLATE/`, `PULL_REQUEST_TEMPLATE.md` | Default templates GitHub falls back to for any repo in this org that doesn't define its own |

## How Consuming Repos Use This

Each repo (`traverse`, `registry`, etc.) vendors a pinned copy of the content it needs (constitution, docs, CI script) rather than duplicating and independently maintaining it. A repo's own `CLAUDE.md` states which version of this governance it has adopted. Adopting a new version is a deliberate step — never automatic or silent.

This repo does **not** have its own GitHub Project board — governance work here is tracked via issues and PRs only.
