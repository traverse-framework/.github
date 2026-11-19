# AI-Agent Hardening Rules

Conventions every `traverse-framework` repo encodes so AI coding agents behave consistently — and cheaply — in any repo here. The baseline governance gate warns on violations of the token-discipline rules; they become blocking in the next major governance release.

## Required in every repo

- `CLAUDE.md` — the **single canonical agent document** (see structure below)
- `AGENTS.md` — a pointer to `CLAUDE.md`, plus *only* content that is genuinely tool-coordination-specific (e.g. the multi-agent claim protocol). Never a second copy of structure/commands/style.
- `.claudeignore` — excludes build artifacts, lockfiles, coverage output, and vendor/generated trees from agent indexing
- `.governance-version` — the **only** place the adopted governance version is written

## Canonical CLAUDE.md structure

Keep it under ~6 KB. It is loaded into every agent session — every byte here is paid on every task.

1. Pointer to this governance repo (never restate its rules, never write its version number — say "see `.governance-version`")
2. The repo's product scope (what's in/out for the current milestone)
3. Build/test/run commands
4. Directory structure (top level only)
5. Repo-specific rules that exist nowhere else

## Single Source of Truth (token discipline)

- **Never duplicate between CLAUDE.md and AGENTS.md.** One canonical doc; the other points to it. Duplicates always drift, and drift means agents act on stale facts.
- **Never write version numbers in prose.** Point at `.governance-version`, `Cargo.toml`, `package.json` — the file that CI actually reads.
- **Never snapshot live state into docs.** No "approved specs" tables (that's `specs/governance/approved-specs.json`), no board-status tables (that's the Project board). Give the query instead:
  ```bash
  jq -r '.specs[].id' specs/governance/approved-specs.json
  gh project item-list <N> --owner traverse-framework --format json --limit 300 \
    --jq '.items[] | select(.status == "Ready") | .content.number'
  ```
- **Read docs lazily, by task.** Do not preload the whole governance corpus. Map:

  | Task touches | Read first |
  |---|---|
  | architecture, contracts, versioned surfaces | `constitution.md`, `docs/compatibility-policy.md` |
  | merge gates, coverage, what blocks a PR | `docs/quality-standards.md` |
  | a rule you want to break | `docs/exception-process.md` |
  | repo processes going wrong | `docs/antipatterns.md` |
  | everything else | the repo's `CLAUDE.md` and the governing spec only |

- **PR bodies use the section superset** (`## Summary`, `## Governing Spec`, `## Project Item`, `## Definition of Done`, `## Validation`) so hygiene gates pass on the first attempt — a failed gate re-run costs a full agent round-trip.
- **Bound your queries.** Always `--limit` on `gh` list commands; prefer `--jq` server-side filtering over dumping JSON into context.

## Lean Implementation Ladder (before adding any code)

1. Is the change required by the active issue and governing spec?
2. Can existing code, contracts, or config already satisfy it?
3. Can a schema, test, or doc update solve it without new abstraction?
4. Add only the minimum new structure needed.

Minimality never justifies violating a repo's architecture boundary (e.g. business logic in a UI layer).

## Code Style Rules (apply everywhere)

- No `unsafe`, no `unwrap()`, no `panic!()`, no TODO comments in production code
- 100% test coverage for core business and runtime logic
- Deterministic: same inputs must produce the same outputs
- Explicit errors over silent failure; document the failure mode

## Multi-Agent Coordination (apply everywhere)

**Claim before you code. One issue = one agent.** Before starting work: no `agent:*` label on the issue, no existing `*/issue-<N>-*` branch or open PR from any tool, and Project status is Ready. If claimed — stop and pick another ticket; never "help" a claimed ticket.

The `agent:*` label (`agent:claude`, `agent:codex`, `agent:cursor`) is the claim marker in every repo. Claim and release with the shared scripts, vendored at the pinned governance version, instead of running the steps by hand:

```bash
scripts/agent/claim.sh <issue> <claude|codex|cursor> [--dry-run]   # all checks above, then label + In Progress + audit comment
scripts/agent/release.sh <issue> <Ready|Blocked|Done> [--dry-run]   # remove agent:* labels, set status, audit comment
```

`claim.sh` changes nothing unless every check passes. Each repo keeps its Project and field ids in `.agent-claim.json` at its root (`repo`, `project_id`, `status_field_id`, `status_options` keyed by status name); the scripts hold no ids. `org-audit.yml` lists claims older than 7 days with no branch or PR (`scripts/org/stale_claims.sh`). A repo's `AGENTS.md` says to run the scripts and does not repeat the steps.

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
- Duplicate content between CLAUDE.md and AGENTS.md, or snapshot registry/board state into either
- Bypass the spec-alignment or coverage gates to make a PR pass

## Cross-Tool Review Before Merge (Decision 133)

Governed-surface PRs — exactly those the repo's change classifier sends to
full CI — need an independent review record before merge. In governance
1.3.x the reusable check warns when the record is missing; a later release
makes it required.

**Independence.** A different tool than the author (from the branch prefix
`claude/`, `codex/`, or `cursor/`) posts the record. If `needs-review` has
been on the PR for at least 4 hours, the same tool may post a fallback
record with `fallback: true`.

**Record format.** One PR comment whose body starts with this HTML comment
header (fields are fixed; the rest of the comment is free-form rubric notes):

```
<!-- traverse-review-record
tool: codex
commit: <40-char lowercase or mixed hex SHA of the head reviewed>
verdict: pass
fallback: false
-->
```

`verdict` is `pass` or `changes-requested`. The check reads the newest
record for the current head SHA only.

**Rubric (what the reviewer checks; CI already covers build/lint/coverage/spec-alignment).**

1. Diff matches the declared governing spec and contract.
2. Failure modes and error paths are explicit.
3. No gate was weakened to make the PR pass.
4. The change is the minimum needed for the issue.
5. Tests assert behavior, not only coverage numbers.

**Findings loop.** `changes-requested` blocks (or warns, in 1.3.x). The
author fixes or rebuts; the same reviewer re-checks the new head. After one
unresolved round, add `needs-enrico`.

**Exemptions.** Dependabot PRs, and version-only release PRs whose changed
paths are only version/pin/changelog files, are exempt. Human-authored PRs
use maintainer review instead of this record.

**Queue.** Authors add `needs-review`. Other tools' ops loops pick that
queue. Do not merge your own governed-surface PR without a passing record
once the check is required.
