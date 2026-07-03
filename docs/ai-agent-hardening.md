# AI-Agent Hardening Rules

These are the conventions every `traverse-framework` repo's `CLAUDE.md`/`AGENTS.md` should encode, so an AI coding agent working in any repo here behaves consistently regardless of which repo it's in.

## Required in every repo's CLAUDE.md / AGENTS.md

- A pointer to this governance repo and the pinned version it has adopted (see `constitution.md`'s Governance section on deliberate version adoption)
- The repo's own product scope (what's in/out for its current milestone) — this is repo-specific and does not belong in the shared constitution
- The repo's own build/test/run commands
- The repo's own directory structure

## Code Style Rules (apply everywhere)

- No `unsafe`, no `unwrap()`, no `panic!()`, no TODO comments in production code
- 100% test coverage for core business and runtime logic
- Deterministic: same inputs must produce the same outputs
- Explicit errors over silent failure; document the failure mode

## Governance Rules An Agent Must Follow (apply everywhere)

1. Every feature starts with a spec in that repo's `specs/` — no spec, no merge
2. Contracts are the source of truth — code conforms to contracts, not vice versa
3. The spec-alignment CI gate blocks PRs that drift from approved specs (`specs/governance/approved-specs.json`)
4. All work must be tracked: GitHub issue + Project item + PR
5. Draft specs are committed but excluded from `approved-specs.json` until formally reviewed and approved — an agent must never add a spec to the approved registry on its own judgment
6. A migration, extraction, or other material architectural change affecting contracts, runtime, registry, or versioning behavior requires a decision record (a spec or ADR), not just a code change

## What An Agent Should Never Do Unprompted

- Add a spec directly to `approved-specs.json` without explicit human review/approval
- Relicense, remove, or weaken the CLA requirement
- Duplicate this repo's governance content into a consuming repo instead of pointing to a pinned version
- Bypass the spec-alignment or coverage gates to make a PR pass
