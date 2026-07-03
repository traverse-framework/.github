# Contributing

Thanks for contributing to a `traverse-framework` project.

## Before You Start

Please read:

- [constitution.md](constitution.md)
- [docs/quality-standards.md](docs/quality-standards.md)
- [docs/antipatterns.md](docs/antipatterns.md)
- [docs/compatibility-policy.md](docs/compatibility-policy.md)
- [docs/exception-process.md](docs/exception-process.md)
- [docs/ai-agent-hardening.md](docs/ai-agent-hardening.md)
- [CLA.md](CLA.md) — required before any contribution can be merged

## Core Rules

- Approved specs are versioned, immutable, and merge-gating.
- Contracts are the source of truth for runtime behavior.
- Core runtime and business logic require 100% automated coverage.
- Material architecture changes require an ADR.
- Portability exceptions must be explicit and reviewed.
- All contributions are governed by the CLA in `CLA.md`.

## Workflow

1. Start from the governing approved spec in the repo you're contributing to.
2. Confirm whether an issue already exists.
3. Open or link the work item in that repo's own GitHub Project board.
4. If needed, add or update an ADR before implementation.
5. Implement with tests and validation evidence.
6. Make sure the change passes the required validation flow, including the spec-alignment gate.

## Pull Requests

Every pull request should:

- reference the governing spec version
- reference the relevant issue or work item
- explain any contract changes
- explain any compatibility impact
- explain any exception being used, if any

Pull requests should not merge if:

- implementation drifts from spec
- required tests or checks fail
- a required ADR is missing
- the CLA has not been accepted by the contributor

## Issues

Use the issue templates when possible so work lands cleanly on the repo's Project board.
