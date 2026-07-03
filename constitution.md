# Traverse Ecosystem Constitution

This is the shared, org-wide constitution for every repo under `traverse-framework`. It defines the engineering and governance principles that apply identically across `traverse`, `registry`, `reference-apps`, `website`, and any future repo.

Repo-specific scope (what a given repo's v-current milestone includes/excludes) does **not** live here — each repo declares its own product scope in its own foundational spec (e.g. `traverse`'s `specs/001-foundation-v0-1/spec.md`, `registry`'s `specs/001-registry-foundation/spec.md`). This document only covers what is true regardless of which repo you're in.

Provenance: this constitution was forked from `traverse`'s repo-local constitution v1.2.0 when governance was consolidated into this shared repo. Repo-local product-constraint sections were intentionally left behind in each repo rather than copied here.

## Core Principles

### I. Capability-First Boundaries
Every feature MUST be modeled as one or more business capabilities, not as UI flows, transport handlers, CRUD wrappers, storage-first modules, or framework-specific components. A valid capability MUST represent one meaningful business action, define clear inputs and outputs, document side effects, name an owner, and be reusable across more than one workflow. Capabilities that are too small, too technical, or too broad MUST be rejected, split, or reframed before implementation.

### II. Contracts Are the Source of Truth
Every capability and event MUST be defined by an explicit contract before implementation begins. Contracts MUST describe identity, versioning, lifecycle state, inputs, outputs, preconditions, postconditions, side effects, dependencies, ownership, permissions, execution constraints, emitted events, consumed events, and policy-relevant metadata. Code, generated artifacts, and runtime behavior MUST conform to the contract; when code and contract disagree, the contract wins until formally amended. Published contracts SHOULD be treated as immutable records with provenance and validation evidence.

Contracts MUST NOT become publishable by automation alone. Publication candidates MUST pass required automated validation and MUST also receive explicit manual approval before publication.

### III. Specs Are Versioned, Immutable, and Merge-Gating
Formal specs MUST be versioned artifacts and MUST be treated as immutable sources of truth once approved for implementation. Code generation, manual implementation, and test design MUST align with the approved spec version. Pull requests MUST fail validation when implementation, contracts, tests, or generated artifacts drift from the governing spec. No code change may be merged if it is not validated against the relevant approved spec.

### IV. Portability Over Host Coupling
Business logic MUST remain portable across execution environments and MUST NOT be tightly coupled to a specific app shell, framework, cloud runtime, or infrastructure vendor. Environment-specific concerns MUST be isolated behind explicit runtime interfaces and adapters.

### V. Discoverability and Governance by Default
Capabilities and events MUST be discoverable through registries and a queryable metadata model, not only through code knowledge or static wiring. Ownership, lifecycle state, versioning, classification, and other governance metadata MUST be explicit and machine-readable. Event contracts MUST be treated as first-class assets, parallel to capability contracts, with the same expectations for discoverability, governance, and evolution.

### VI. Runtime Decisions Must Be Explainable
Runtime behavior MUST be formed through explicit evaluation of contracts, constraints, policies, and context. Constraints determine validity, policies determine preference, and traces MUST record how a decision was formed, including rejected alternatives and execution failures when relevant.

### VII. Small, Verifiable Slices
Every repo MUST stay focused on the smallest demonstrable slice of its own scope at any given time. Work that introduces distributed orchestration, advanced placement optimization, full AI planning, full workflow engines, federated registries, or UI-heavy surfaces beyond what a repo's own approved spec calls for is out of scope unless that repo's foundational spec is formally amended. Every increment MUST be testable end-to-end through stable, documented entry points (CLI, API, or equivalent).

## Non-Functional Requirements

The following non-functional qualities are mandatory for all in-scope work, in every repo:

- Reliability: runtime, registries, and validation flows MUST fail predictably and expose actionable error states.
- Determinism: core decision logic, validation, and trace generation MUST behave deterministically for the same inputs and governing artifacts.
- Traceability: behavior, validation outcomes, and merge-gating decisions MUST produce inspectable evidence.
- Portability: capability implementations MUST preserve portability and avoid accidental host coupling.
- Testability: core logic MUST be designed for full automated verification.
- Maintainability: architecture, naming, and boundaries MUST support long-term evolution without hidden coupling.
- Security and trust: signed, versioned, validated, and provenance-aware artifacts are the expected direction.
- Performance: local execution and interactive workflows MUST remain responsive enough for development and demonstration use.
- Reproducibility: builds, tests, and generated artifacts SHOULD be reproducible from pinned inputs, toolchains, and commands.
- Observability: validation and merge-gating flows MUST emit structured evidence suitable for diagnosis and audit.
- Compatibility discipline: versioned surfaces MUST define and preserve explicit backward-compatibility rules.

## Non-Negotiable Quality Standards

The following are non-negotiable and must block merge when violated, in every repo:

- Approved spec alignment
- Contract alignment
- Production-grade code quality
- 100% coverage for core business and runtime logic
- Passing automated validation and test flows
- No silent ambiguity in runtime or resolution behavior
- No hidden bypass of contract, policy, constraint, or trace mechanisms
- No unreviewed exception to portability or host-coupling rules
- No unreviewed architectural change without a decision record when the change affects core contracts, runtime behavior, registry behavior, versioning, or quality gates

## Enterprise Quality Standards

Required for enterprise-grade engineering quality, in every repo:

- Architecture decision records for material technical decisions affecting contracts, runtime, registries, versioning, security, or quality gates
- Dependency policy with pinned versions, minimized dependency footprint, and review of new dependencies for security and licensing impact
- Reproducible build and validation commands documented and used consistently in CI
- Static analysis gates appropriate to the stack, including formatting, linting, and dependency/security checks
- Security baseline with strong input validation, explicit exception handling for unsafe or privileged code paths, and a path toward provenance and artifact trust
- Structured observability with execution identifiers, structured evidence, and actionable error taxonomy
- Compatibility policy for spec versions, contract versions, and public surfaces
- Test taxonomy covering unit, contract, integration, end-to-end, and regression or golden-path validation where applicable
- Documentation standards for public modules, artifacts, failure modes, and examples
- Explicit exception process requiring owner, rationale, and review for any deviation from portability, quality, coverage, or merge-gating standards

## Development Workflow

All substantive work, in every repo, MUST follow this sequence:

1. Clarify the business action and validate that the proposed capability boundary is meaningful.
2. Define or amend the governing versioned spec.
3. Define or amend the relevant capability and event contracts.
4. Define required constraints, policies, and lifecycle assumptions.
5. Specify how the capability will be registered, validated, discovered, and executed.
6. Add or update tests for contract validation, spec alignment, registry behavior, execution, trace output, and graph or event interactions as applicable.
7. Implement the smallest change that satisfies the spec, contract, and the repo's current milestone scope.

Every spec, plan, and task list MUST explicitly state:

- Which capability or event is being introduced or changed
- Which spec version governs the change
- Why the boundary is correct
- What contract fields are required
- What governance metadata is required
- Which constraints and policies apply
- Whether the change is in or out of the repo's current milestone scope
- How the behavior will be verified from a stable entry point
- What trace or validation evidence should exist after execution

All meaningful work, in every repo, MUST be tracked through:

- a GitHub issue
- a Project item (that repo's own Project board)
- a pull request

These three artifacts are the required minimum traceability model unless an approved exception is documented (see `exception-process.md`).

## Contributor License

All contributions to any repo under `traverse-framework` are governed by the CLA in `CLA.md`. A contribution may not be merged until the CLA is accepted.

## Governance

This constitution overrides convenience-based implementation decisions, hidden coupling, and speculative architecture growth, in every repo that adopts it.

All reviews MUST check for:

- Spec/version alignment and drift risk
- Capability boundary quality
- Capability and event contract completeness
- Portability risks
- Hidden host or framework coupling
- Discoverability and governance metadata quality
- Correct separation of constraints, policies, and execution logic
- Adequate verification of registry, contract, runtime, trace, and graph behavior
- Scope creep beyond the repo's current milestone

Amendments require documenting:

- The rule being changed
- The reason the current rule is insufficient
- The migration or compatibility impact
- The new version of this constitution

Repos consume this constitution at a pinned version (see each repo's `CLAUDE.md` for which version it has adopted). Adopting a new version is a deliberate, explicit step in the consuming repo — not automatic.

**Version**: 1.0.0 | **Ratified**: 2026-07-03
