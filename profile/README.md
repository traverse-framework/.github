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
`traverse-mcp`. Python works by shelling out to
`traverse-cli capability-package execute` — **no Python SDK**. Swift / Kotlin /
.NET exist in-tree, not as certified public packages. Edge is planned; cloud
placement is an explicit non-goal for v0.1. Cite
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
3. Runnable demo:
   [`weekly-demos/2026-09-18-agent-blocked`](https://github.com/traverse-framework/weekly-demos/tree/main/2026-09-18-agent-blocked)
   · more in [`weekly-demos`](https://github.com/traverse-framework/weekly-demos)

→ [traverse-framework.com](https://traverse-framework.com) ·
[`llms.txt`](https://traverse-framework.com/llms.txt) ·
start in [`traverse`](https://github.com/traverse-framework/traverse)

---

## The org at a glance

| Repo | What it is |
|---|---|
| [`traverse`](https://github.com/traverse-framework/traverse) | Core runtime, CLI, contracts, and MCP surface. Discover a governed capability → execute known behavior → produce a trace. Published crates at **`v0.12.0`** (`traverse-contracts`, `traverse-runtime`, `traverse-embedder`, `traverse-cli-rs`, `traverse-mcp`, `traverse-expedition-wasm`; registry client is the separate `traverse-registry` crate). |
| [`registry`](https://github.com/traverse-framework/registry) | The public capability registry — a git-based, PR-published catalog of governed capabilities. Live catalog: [registry.traverse-framework.com](https://registry.traverse-framework.com) (counts change; treat the site as source of truth). |
| [`reference-apps`](https://github.com/traverse-framework/reference-apps) | UI shells for the same Traverse capabilities: Web, macOS, iOS, Android, Windows, Linux, CLI, plus MCP façades for Claude, Cursor, ChatGPT, and Grok. |
| [`claude-skills`](https://github.com/traverse-framework/claude-skills) | Claude Skills for building on Traverse — primary authoring on-ramp (`traverse-capability-author`), plus extractor and workflow-planner. Check the registry before authoring; validate against the real CLI. |
| [`weekly-demos`](https://github.com/traverse-framework/weekly-demos) | Runnable weekly demos (private). Start with `2026-09-18-agent-blocked` — agent freestyle → deny / trace. |
| [`website`](https://github.com/traverse-framework/website) | The public site and documentation. |
| [`.github`](https://github.com/traverse-framework/.github) | *(this repo)* Org-wide governance — constitution, NFRs, quality standards, CI gates, CLA, and AI-agent hardening rules shared by every repo above. |
| [`repo-template`](https://github.com/traverse-framework/repo-template) | Starting point for a new org repo — compliant with governance from the first commit. |

**Platform reach:** five embedder SDKs on one `embedder-api/1.0.0` contract and
one CI conformance suite — Rust and Web/TypeScript published (crates.io /
npm `traverse-embedder-web@0.12.0`); Swift (iOS/macOS, `wasmi`), Kotlin (Android,
Chicory), and .NET (Windows, Wasmtime) ship from `traverse/packages/` and are
usable in-tree / via reference apps, with public package certification still
open. Edge is planned; cloud placement is an explicit non-goal for v0.1 — see
[Platforms](https://traverse-framework.com/platforms.html).

### Consumers / clients (honest)

| Surface | Status |
|---|---|
| JS/TS | Published npm `traverse-embedder-web@0.12.0` |
| Rust | Published crates.io `traverse-embedder@0.12.0` |
| AI agents | Published `traverse-mcp` (stdio) |
| Python | Works today by shelling out to `traverse-cli capability-package execute` — **no Python SDK** |
| Swift / Kotlin / .NET | In-tree with conformance; not first-class published package consumers yet |

---

## Why it matters

The same business rule now has to run in a web client, on a server, and
inside an AI agent a user is talking to — and teams often invent a fourth
copy for each new host. Copies drift; behavior stops being one thing.
Traverse’s answer is one governed capability on the hosts that have actually
shipped (not an unbounded “anywhere,” and not cloud orchestration).

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
