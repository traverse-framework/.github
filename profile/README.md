# Traverse Framework

**Define once. Run anywhere.**

Traverse is a contract-driven WebAssembly runtime and a governed registry for
**portable business capabilities**. You write a rule — pricing, eligibility,
authorization, escalation — once, as a capability with a machine-readable
contract, and the same signed WASM artifact runs on Linux, macOS, and Windows,
in the browser, on a server, and inside an AI agent — producing a verifiable
execution trace when the governed path runs.

Mobile embedders and reference-app shells for iOS and Android exist and are
advancing (Swift/`wasmi`, Kotlin/Chicory), but they are not yet certified
public releases the way native desktop and the published Web/TypeScript
embedder are. No reimplementation per environment. No agent free-handing your
business rules. One behavior, governed, everywhere it is actually shipping.
It's the working implementation of
[Universal Microservices Architecture](https://www.universalmicroservices.com/):
**the agent proposes, the runtime decides.**

→ [traverse-framework.com](https://traverse-framework.com) ·
start in [`traverse`](https://github.com/traverse-framework/traverse)

---

## The org at a glance

| Repo | What it is |
|---|---|
| [`traverse`](https://github.com/traverse-framework/traverse) | Core runtime, CLI, contracts, and MCP surface. Rust, published crates at **`v0.10.1`**, **147** approved specs, **6** crates on crates.io (`traverse-contracts`, `traverse-runtime`, `traverse-embedder`, `traverse-cli-rs`, `traverse-mcp`, plus registry client), ~723 commits. |
| [`registry`](https://github.com/traverse-framework/registry) | The public capability registry — a git-based, CI-validated, PR-published catalog. **82** capabilities across **31** domains (**185** signed versions; **147** non-deprecated) live at [registry.traverse-framework.com](https://registry.traverse-framework.com). |
| [`reference-apps`](https://github.com/traverse-framework/reference-apps) | UI shells for the same Traverse capabilities: Web, macOS, iOS, Android, Windows, Linux, CLI, plus MCP façades for Claude, Cursor, ChatGPT, and Grok. |
| [`claude-skills`](https://github.com/traverse-framework/claude-skills) | Claude Skills for building on Traverse — check the registry before authoring, compose capabilities, validate against the real CLI. |
| [`website`](https://github.com/traverse-framework/website) | The public site and documentation. |
| [`.github`](https://github.com/traverse-framework/.github) | *(this repo)* Org-wide governance — constitution, NFRs, quality standards, CI gates, CLA, and AI-agent hardening rules shared by every repo above. |
| [`repo-template`](https://github.com/traverse-framework/repo-template) | Starting point for a new org repo — compliant with governance from the first commit. |

**Platform reach:** five embedder SDKs on one `embedder-api/1.0.0` contract and
one CI conformance suite — Rust and Web/TypeScript published (crates.io /
npm `traverse-embedder-web`); Swift (iOS/macOS, `wasmi`), Kotlin (Android,
Chicory), and .NET (Windows, Wasmtime) ship from `traverse/packages/` and are
usable in-tree / via reference apps, with public package certification still
open. Cloud and edge placement targets are specified and on the roadmap, not
yet shipped.

---

## Why it matters

The same business rule now has to run in a web client, on a server, at the
edge, and inside an AI agent a user is talking to. Teams answer that by
rewriting the rule in each stack; the copies drift and the behavior stops
being one thing.

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

Every repo in this org follows the same spec-driven governance model: approved
specs are versioned, immutable, and merge-gating; contracts are the source of
truth for runtime behavior; core logic holds 100% automated coverage; a
deterministic spec-alignment gate runs on every PR.

See [`constitution.md`](../constitution.md) for the full rules,
[`GOVERNANCE.md`](../GOVERNANCE.md) for the ownership and decision model, and
each repo's own `CLAUDE.md` / `AGENTS.md` for what's specific to it. One CLA
signature covers every repo in the org.
