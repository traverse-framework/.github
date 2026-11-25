# Traverse Framework

**Governed capability runtime.** Value loop: **discover → execute → trace**.
**The agent proposes; the runtime decides.**

Traverse governs portable business capabilities — pricing, eligibility,
authorization, escalation — as contracts with sandboxed artifacts and a
verifiable trace. Usual authoring is skill-first plain English via
[`traverse-capability-author`](https://github.com/traverse-framework/claude-skills/tree/main/skills/traverse-capability-author)
(interview → registry check → contract → WASM → human-reviewed PR). You do
**not** need to write Rust for that path; manual authoring still uses
Rust→WASM under the hood.

**One shared `runtime.wasm`.** Browser, native desktop, CLI, and MCP are
**clients / embedders**, not different Traverse runtimes. Shipped consumers
today: JS/TS (`traverse-embedder-web`), Rust (`traverse-embedder`), agents via
`traverse-mcp`. Web loads the bundle's digest-checked `runtime/runtime.wasm`;
the Rust embedder links `traverse-runtime` natively and ships no separate
runtime-WASM artifact — same contract/ABI
([Q&A](https://traverse-framework.com/questions/does-the-rust-embedder-use-the-same-runtime-wasm.html)).
Python works by shelling out to
`traverse-cli capability-package execute` — **no Python SDK**. Swift (xcframework
on `swift-host-v*` releases), Kotlin (Maven Central
`com.traverse-framework:traverse-embedder` 0.17.1), and .NET (nuget.org
`TraverseEmbedder` 0.17.1) are published, pre-1.0, and not Certified. Edge is
planned; cloud placement is an explicit non-goal for v0.1. Cite
[what is real today](https://traverse-framework.com/what-is-real-today.html) and
[Platforms](https://traverse-framework.com/platforms.html) before assuming a
host.

Specs and CI gates stay in Governance below — honesty hygiene, not the pitch.
Working implementation of
[Universal Microservices Architecture](https://www.universalmicroservices.com/).

### Required reading (agents / cold eval)

1. [What is real today](https://traverse-framework.com/what-is-real-today.html)
2. [The agent freestyled a $2.4M wire. The runtime said no.](https://traverse-framework.com/blog/agent-freestyle-blocked.html)
   (deny + trace)
3. Deny / multi-host direction (blog-first): [agent freestyle, blocked](https://traverse-framework.com/blog/agent-freestyle-blocked.html)
   · [same-wasm multi-host](https://traverse-framework.com/blog/same-wasm-multi-host.html)
   · [signed exact-ref digits](https://traverse-framework.com/blog/signed-exact-ref-digits.html)
   · [agent MCP exact-ref](https://traverse-framework.com/blog/agent-mcp-exact-ref.html)
   · [catalog model.execute](https://traverse-framework.com/blog/catalog-model-execute.html)
   · [agent + real traverse-mcp](https://traverse-framework.com/blog/agent-mcp-real-server.html)
   · [one audit fingerprint, every host](https://traverse-framework.com/blog/hash-converges.html)
   · [v0.16.0: same input, same output, on every host](https://traverse-framework.com/blog/traverse-0-16-0-same-input-same-output.html)
   · [one model capability, three published hosts, same answer](https://traverse-framework.com/blog/model-execute-on-published-packages.html)
   · [five hosts, one set of rules for compatible capabilities](https://traverse-framework.com/blog/compatible-lifecycle-one-rulebook.html) (on main, not released)
   · [We measured our own LLM-assisted capabilities. The bar was not met.](https://traverse-framework.com/blog/we-measured-our-llm-assisted-capabilities.html) (registry evaluation, bar not met; not a release)
   · [catalog model.execute on the published Browser and Node path](https://traverse-framework.com/blog/product-path-model-execute.html) (Nov 6 weekly demo, v0.16.2)
   · [a governed model call you can actually stop](https://traverse-framework.com/blog/kill-switch.html) (Nov 13 weekly demo, v0.17.0 tag tree; v0.17.1 published Nov 15)
   · [the browser skips Ollama and picks the signed pin](https://traverse-framework.com/blog/browser-skips-ollama-picks-signed-pin.html)
   · [the host result names the model it ran](https://traverse-framework.com/blog/host-result-names-the-model-it-ran.html)
   · [How do I run the deny demo?](https://traverse-framework.com/questions/how-do-i-run-the-agent-blocked-weekly-demo.html)
   (every weekly demo is public in [`weekly-demos`](https://github.com/traverse-framework/weekly-demos))
4. Where business logic lives (hosts stay thin; non-UI domain logic in capabilities;
   apps-not-ready ≠ host-forever):
   [Q&A](https://traverse-framework.com/questions/where-does-business-logic-live-in-traverse.html)
   · [blog](https://traverse-framework.com/blog/where-business-logic-lives.html)
5. Print-support domain pack (living pack; none of `print.*` published yet;
   apps-not-ready ≠ no packs):
   [Q&A](https://traverse-framework.com/questions/what-is-the-print-support-capability-pack.html)
   · [blog](https://traverse-framework.com/blog/print-support-domain-pack.html)
6. Published capability versions are never edited (deprecate / revoke instead):
   [blog](https://traverse-framework.com/blog/you-dont-edit-a-published-capability.html)
   · [Q&A](https://traverse-framework.com/questions/what-happens-when-a-capability-version-is-revoked.html)
7. Model rights are data, not a README:
   [blog](https://traverse-framework.com/blog/model-rights-are-data.html)
   · [Q&A](https://traverse-framework.com/questions/does-the-registry-record-model-rights.html)

→ [traverse-framework.com](https://traverse-framework.com) ·
[`llms.txt`](https://traverse-framework.com/llms.txt) ·
[start here](https://traverse-framework.com/blog/what-is-real-today-start-here.html) ·
start in [`traverse`](https://github.com/traverse-framework/traverse)

---

## The org at a glance

| Repo | What it is |
|---|---|
| [`traverse`](https://github.com/traverse-framework/traverse) | Core runtime, CLI, contracts, and MCP surface. Discover a governed capability, execute known behavior, and produce a trace. Latest release **[`v0.17.1`](https://github.com/traverse-framework/traverse/releases/tag/v0.17.1)** (published Nov 15, 2026, Mountain time). Lockstep patch, and the first crates.io and product release of the v0.17.0 changes. The v0.17.0 crates.io publish failed ([#1849](https://github.com/traverse-framework/traverse/issues/1849), fixed by [#1850](https://github.com/traverse-framework/traverse/pull/1850)). Breaking changes: one compatible lifecycle on every host via `runtime.wasm` (Decisions 127-129, Spec 072 1.1.0); Rust embedder input is raw JSON text (Decision 129); guests receive only the submitted input (Decision 124). Seven crates are on crates.io at **`0.17.1`** (`traverse-contracts`, `traverse-runtime`, `traverse-embedder`, `traverse-cli-rs`, `traverse-mcp`, `traverse-registry-sync`, `traverse-expedition-wasm`; Rust ≥ 1.95). The shared `runtime.wasm` is a release asset on [`runtime-wasm-v0.17.1`](https://github.com/traverse-framework/traverse/releases/tag/runtime-wasm-v0.17.1). Also published at 0.17.1: npm `traverse-embedder-web`, Maven Central `com.traverse-framework:traverse-embedder`, nuget.org `TraverseEmbedder`, [`swift-host-v0.17.1`](https://github.com/traverse-framework/traverse/releases/tag/swift-host-v0.17.1), [`traverse-mcp-v0.17.1`](https://github.com/traverse-framework/traverse/releases/tag/traverse-mcp-v0.17.1), [`onnx-runner-v0.17.1`](https://github.com/traverse-framework/traverse/releases/tag/onnx-runner-v0.17.1). `Package.swift` on the v0.17.1 tag pins `swift-host-v0.17.0`; `main` pins `swift-host-v0.17.1` ([traverse#1862](https://github.com/traverse-framework/traverse/pull/1862)). Previous product release: v0.16.2 (Nov 4, 2026). The separate `traverse-registry` client crate is **0.31.0** on crates.io. |
| [`registry`](https://github.com/traverse-framework/registry) | The public capability registry — a git-based, PR-published catalog of governed capabilities. Live catalog: [registry.traverse-framework.com](https://registry.traverse-framework.com) (counts change; treat the site as source of truth). |
| [`reference-apps`](https://github.com/traverse-framework/reference-apps) | UI shells for the same Traverse capabilities: Web, macOS, iOS, Android, Windows, Linux, CLI, plus MCP façades for Claude, Cursor, ChatGPT, and Grok. |
| [`claude-skills`](https://github.com/traverse-framework/claude-skills) | Claude Skills for building on Traverse — primary authoring on-ramp (`traverse-capability-author`), plus extractor and workflow-planner. Check the registry before authoring; validate against the real CLI. |
| [`weekly-demos`](https://github.com/traverse-framework/weekly-demos) | Runnable weekly demos, public, one folder per week. Start with `2026-09-18-agent-blocked`: the agent freestyles, the runtime denies it and writes a trace. |
| [`website`](https://github.com/traverse-framework/website) | The public site and documentation. |
| [`.github`](https://github.com/traverse-framework/.github) | *(this repo)* Org-wide governance — constitution, NFRs, quality standards, CI gates, CLA, and AI-agent hardening rules shared by every repo above. |
| [`repo-template`](https://github.com/traverse-framework/repo-template) | Starting point for a new org repo — compliant with governance from the first commit. |

**Platform reach:** five embedder SDKs on one `embedder-api/1.1.0` contract and
one CI conformance suite. Rust and Web/TypeScript are published (crates.io /
npm `traverse-embedder-web@0.17.1`). Swift (iOS/macOS, `wasmi`) ships via
`swift-host-v*` release assets (currently [`swift-host-v0.17.1`](https://github.com/traverse-framework/traverse/releases/tag/swift-host-v0.17.1);
`Package.swift` on the v0.17.1 tag pins `swift-host-v0.17.0`, and `main` pins
`swift-host-v0.17.1` ([traverse#1862](https://github.com/traverse-framework/traverse/pull/1862))). Kotlin
(Android, Chicory) is on Maven Central `com.traverse-framework:traverse-embedder`
0.17.1. .NET (Windows, Wasmtime) is on nuget.org `TraverseEmbedder` 0.17.1. All
three natives are published, pre-1.0, and not Certified under Spec 529 (no host
is Certified yet). Signed exact-ref model packages now run on every embedder
(Rust, browser, Swift, Kotlin/Android, .NET) with model rights enforced on
every host. Apple hosts can opt into a signed Core ML variant under the same
policy and evidence rules. Governed-path iPhone evidence shipped in v0.16.0
([traverse#1630](https://github.com/traverse-framework/traverse/issues/1630)):
BirdNET on one iPhone 14 Pro Max at p95 141 ms per 3 s clip on Core ML
(needs manifest schema 2.3.0, new in v0.16.0).
Edge is planned; cloud placement is an explicit non-goal for
v0.1 — see [Platforms](https://traverse-framework.com/platforms.html).

### Consumers / clients (honest)

| Surface | Status |
|---|---|
| JS/TS | Published npm `traverse-embedder-web@0.17.1` (catalog `model.execute` via `activateMediatedConnector` + `submitAsync`) |
| Rust | Published crates.io `traverse-embedder@0.17.1` (Rust ≥ 1.95). `submit` and `start_compatible` take raw JSON text (Decision 129) |
| AI agents | **`traverse-mcp` v0.17.1 released**: prebuilt binaries for four targets with `SHA256SUMS` and build-provenance attestations on [`traverse-mcp-v0.17.1`](https://github.com/traverse-framework/traverse/releases/tag/traverse-mcp-v0.17.1) (`traverse-mcp sync`, `prepare-cache`, `stdio --cache`; [setup](https://traverse-framework.com/docs/guides/mcp-setup.html)). stdio, own line-delimited command protocol. crates.io `traverse-mcp` 0.17.1 |
| Python | Works today by shelling out to `traverse-cli capability-package execute` — **no Python SDK** |
| Swift | Published xcframework on [`swift-host-v0.17.1`](https://github.com/traverse-framework/traverse/releases/tag/swift-host-v0.17.1). `Package.swift` on the v0.17.1 tag pins `swift-host-v0.17.0`; `main` pins `swift-host-v0.17.1` ([traverse#1862](https://github.com/traverse-framework/traverse/pull/1862)). Pre-1.0, not Certified |
| Kotlin | Published Maven Central `com.traverse-framework:traverse-embedder` 0.17.1; pre-1.0, not Certified |
| .NET | Published nuget.org `TraverseEmbedder` 0.17.1; pre-1.0, not Certified |

---

## Why it matters

The same business rule now has to run in a web client, on a server, and
inside an AI agent a user is talking to — and teams often invent a fourth
copy for each new host. Copies drift; behavior stops being one thing.
Traverse’s answer is one governed capability on the hosts that have actually
shipped (not an unbounded “anywhere,” and not cloud orchestration).
Before v0.16.0, hosts didn't agree on the exact input bytes they handed a
capability, so input-hashing outputs could differ across host types. v0.16.0
fixes this (every host feeds RFC 8785 canonical JSON input; a breaking change)
([#1722](https://github.com/traverse-framework/traverse/issues/1722),
[write-up](https://traverse-framework.com/blog/same-wasm-two-hashes.html);
rerun on the v0.16.0 release packages:
[same input, same output](https://traverse-framework.com/blog/traverse-0-16-0-same-input-same-output.html)).

AI coding agents make this sharper: an agent asked to "add the discount logic"
re-derives it from scratch every session — unversioned, unreviewed, and
authoritative only because it ran last. Traverse's position is the opposite:
a capability is a contract, an immutable version, a signature, and a WASM
artifact; the runtime validates inputs/outputs against schemas, isolates
execution in a sandbox, and emits an auditable trace. The agent's job is to
**find and compose** existing capabilities — not to be the source of truth for
what the business does. The public registry already holds dozens of them, so
that logic is a lookup, not a regeneration.

---

## Governance

Specs and CI gates are how we stay honest — not the product. Approved specs are
versioned and merge-gating; contracts are the source of truth for runtime
behavior.

See [`constitution.md`](../constitution.md) for the full rules,
[`GOVERNANCE.md`](../GOVERNANCE.md) for the ownership and decision model, and
each repo's own `CLAUDE.md` / `AGENTS.md` for what's specific to it. One CLA
signature covers every repo in the org.
