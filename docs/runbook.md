# Operations Runbook

How to operate the `traverse-framework` org governance. Written so any agent or human can run the system without re-deriving it. Owner-only steps live in [owner-setup.md](owner-setup.md); rules live in [../constitution.md](../constitution.md) and [quality-standards.md](quality-standards.md).

## Releasing a governance change

1. Branch off this repo's default branch; make the change; add a `CHANGELOG.md` entry (major = can newly block merges in consuming repos; minor = additive; patch = fix/clarification).
2. Open a PR with the section superset (`## Summary`, `## Governing Spec`, `## Project Item`, `## Definition of Done`, `## Validation`). Queue `gh pr merge --squash --auto` — the required `cla / cla` and `baseline / governance-baseline` checks gate it.
3. After merge: `git tag -a vX.Y.Z -m "Governance release vX.Y.Z" && git push origin vX.Y.Z`.
4. Reusable workflows deploy org-wide at merge (callers reference the default branch). Vendored/doc content deploys only when a consuming repo bumps its `.governance-version` in its own PR — deliberate adoption, never automatic.

## Adding a repo to the org

1. Create it from [`repo-template`](https://github.com/traverse-framework/repo-template) ("Use this template") — it ships compliant.
2. From this repo: `scripts/org/apply_rulesets.sh <repo>` (both rulesets).
3. Enable settings: `gh api -X PATCH repos/traverse-framework/<repo> -F allow_auto_merge=true -F delete_branch_on_merge=true`, plus `PUT .../private-vulnerability-reporting` and `PUT .../vulnerability-alerts`.
4. Confirm with `scripts/org/audit_compliance.sh`.

For a repo not born from the template, run `scripts/org/rollout_governance.sh <version> <repo>` to PR the required files in.

## Routine operation

- The weekly `org-audit` workflow audits every repo and opens/updates an issue on drift. Manual run: `scripts/org/audit_compliance.sh`.
- Dependabot PRs: the `dependabot-hygiene` reusable workflow fills their bodies with the required sections (honest governing-spec declarations computed from changed files); repo CI gates then decide. If one predates the workflow, comment `@dependabot rebase`.
- Merging is always: open PR → gates green → `gh pr merge --squash --auto`. Never disable a ruleset to land something — fix forward.

## Failure playbook (learned the hard way)

| Symptom | Cause | Fix |
|---|---|---|
| `cla / cla` fails for everyone at action startup | `CLA_ASSISTANT_PAT` missing **or the org secret's repository-access list excludes the repo** (`gh api repos/<org>/<repo>/actions/organization-secrets` to check) | Fix secret access; the gate degrades gracefully for owner/bots meanwhile |
| Check stays red after a fix merged to this repo | **GitHub re-runs pin the originally resolved reusable-workflow SHA** — `gh run rerun` never picks up new gate logic | Trigger a *new* event: push a commit, or comment `recheck` (CLA gate listens for it) |
| `no checks reported` on a PR head | Comment-triggered runs don't attach to the head commit | Push an empty commit to the PR branch (synchronize event) |
| Dependabot PR blocked on body-section gates | PR opened before dependabot-hygiene workflow existed in that repo | `@dependabot rebase` |
| CLA asks a coding agent to sign | Commit author email not linked to a GitHub account, or agent identity not allowlisted | Fix `git config user.email`; agent identities are allowlisted in `reusable-cla.yml` |
| `stress_no_fd_leak` (traverse) fails on a docs-only PR | Flaky on shared runners | Re-run the failed job once the run completes; a hardening fix is tracked |
| Governance PR blocked by the very check it fixes | Chicken-and-egg on required checks in this repo | Make the check pass legitimately (e.g. set the missing secret); as a last resort the **owner** temporarily disables the ruleset in the UI — agents must never do this |

## Constraints to remember

- GitHub Free org: **no org-level rulesets** (per-repo via `apply_rulesets.sh`), no org-secret management via `repo`-scoped tokens.
- Coding agents in this environment cannot: merge without the owner's authorization, force-push tags, create public repos, or disable rulesets. Queue the work; hand those actions to the owner.
- The `cla-signatures` branch is legal-record storage — never rewrite it.
