# Owner Setup — Manual Steps

Everything in this repo that can be automated is automated. The items below require the org owner's credentials, a browser, or a lawyer, and cannot be done by scripts running with a normal `repo`-scoped token. Check them off once done.

## Required before accepting external contributions

- [x] **Create the CLA storage PAT.** Done 2026-07-07: fine-grained PAT stored as org Actions secret `CLA_ASSISTANT_PAT`. Note: its repository-access list must include `.github` itself. If the PAT expires, the CLA gate degrades gracefully (owner/bots pass with a warning; externals fail closed) — recreate it promptly.
- [x] **Create the `cla-signatures` branch** in this repo. Done 2026-07-07.
- [ ] **Legal review of `CLA.md` and `TRADEMARK.md`.** *Deferred by owner decision (2026-07-07) — no legal spend for now.* Both files carry a draft notice stating exactly that. Re-evaluate when any of these happen: first sustained external contributor, first revenue, or any acquisition/licensing conversation. The signatures collected meanwhile still document contributor intent, which is far better than nothing.

## Required for enforcement coverage

- [ ] **Require 2FA for the org** (Org Settings → Authentication security). Currently off. Free, UI-only (no API); enable 2FA on your own account first.
- [ ] **Optionally add `ORG_AUDIT_TOKEN`** org secret (fine-grained PAT, all org repos, **Administration: read**) so the weekly audit can verify rulesets; without it the ruleset column reads `?`.
- [x] **Apply the required-checks ruleset after the rollout PRs merge.** Done 2026-07-07 — active on all repos; contexts `baseline / governance-baseline` and `cla / cla` are required on every default branch, so auto-merge waits for the gates.

## Strongly recommended for the "sell it someday" goal

*LLC and trademark registration deferred by owner decision (2026-07-07) — no spend until the project has traction. Triggers to revisit: revenue, sustained external contributors, or acquisition interest. Until then, consistent public use of the "Traverse" name (this org, the website, release history) builds common-law trademark evidence for free.*

- [ ] **Form a legal entity** (e.g. an LLC) to hold the IP: the trademark, the CLA rights ("project owner" in the CLA should ultimately name an entity), and the org itself. *(Deferred — see above.)*
- [ ] **Register the "Traverse" trademark** in key jurisdictions. The code is Apache-2.0 — the name is most of what's actually sellable. *(Deferred — see above.)*
- [x] **Keep the CLA gate on from the very first external PR.** Enforced automatically since 2026-07-07: `cla / cla` is a required check on every repo's default branch. Any contribution merged without a recorded CLA acceptance is code you cannot relicense without going back to that contributor.

## Nice to have

- [x] Delete the obsolete `v1` tag on this repo. Done 2026-07-07 — callers reference the default branch; only `vX.Y.Z` release tags are meaningful.
- [ ] Add `FUNDING.yml` in this repo if/when you set up GitHub Sponsors or similar.
- [ ] Enable GitHub Discussions on repos where open-ended questions are expected.
- [ ] Rename this repo's default branch from `bootstrap-governance` to `main` for convention (Settings → Branches → rename; GitHub redirects automatically).
