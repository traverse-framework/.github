# Owner Setup — Manual Steps

Everything in this repo that can be automated is automated. The items below require the org owner's credentials, a browser, or a lawyer, and cannot be done by scripts running with a normal `repo`-scoped token. Check them off once done.

## Required before accepting external contributions

- [ ] **Create the CLA storage PAT.** Create a [fine-grained PAT](https://github.com/settings/personal-access-tokens/new): resource owner `traverse-framework`, repository access limited to `.github`, permission **Contents: read and write**, long expiry. Then add it as an **organization Actions secret** named `CLA_ASSISTANT_PAT` (Org Settings → Secrets and variables → Actions), available to all repositories. Until this exists, the CLA check fails closed — external PRs stay blocked, which is the safe direction, but sign-offs can't be recorded.
- [ ] **Create the `cla-signatures` branch** in this repo (the CLA action can create it, but pre-creating keeps the ruleset story clean): `git switch --orphan cla-signatures && git commit --allow-empty -m "CLA signature storage" && git push origin cla-signatures`.
- [ ] **Legal review of `CLA.md` and `TRADEMARK.md`.** Both are drafts. A buyer's lawyers will scrutinize exactly these documents; review them before the first external contribution, not after.

## Required for enforcement coverage

- [ ] **Require 2FA for the org** (Org Settings → Authentication security). Currently off.
- [ ] **Optionally add `ORG_AUDIT_TOKEN`** org secret (fine-grained PAT, all org repos, **Administration: read**) so the weekly audit can verify rulesets; without it the ruleset column reads `?`.
- [ ] **Apply the required-checks ruleset after the rollout PRs merge.** Run `scripts/org/apply_rulesets.sh -f governance/rulesets/required-checks-ruleset.json` once every repo has the `cla`/`governance` workflows on its default branch. It requires the observed contexts `baseline / governance-baseline` and `cla / cla` — this is what makes auto-merge wait for the gates. Applying it earlier blocks all PRs, because the named checks never run.

## Strongly recommended for the "sell it someday" goal

- [ ] **Consider forming a legal entity** (e.g. an LLC) to hold the IP: the trademark, the CLA rights ("project owner" in the CLA should ultimately name an entity), and the org itself. Selling assets held by an entity is far cleaner than selling personally-held rights.
- [ ] **Consider registering the "Traverse" trademark** in your key jurisdictions. The code is Apache-2.0 — the name is most of what's actually sellable.
- [ ] **Keep the CLA gate on from the very first external PR.** Any contribution merged without a recorded CLA acceptance is code you cannot relicense without going back to that contributor.

## Nice to have

- [ ] Delete the obsolete `v1` tag on this repo (`git push origin :refs/tags/v1`) — callers now reference the default branch; only `vX.Y.Z` release tags are meaningful.
- [ ] Add `FUNDING.yml` in this repo if/when you set up GitHub Sponsors or similar.
- [ ] Enable GitHub Discussions on repos where open-ended questions are expected.
- [ ] Rename this repo's default branch from `bootstrap-governance` to `main` for convention (Settings → Branches → rename; GitHub redirects automatically).
