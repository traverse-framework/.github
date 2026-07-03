# Quality Standards

This document defines the operational quality standards shared across every `traverse-framework` repo. It works together with `../constitution.md` and each repo's own approved feature specs. If there is a conflict, the constitution and approved governing spec take precedence.

## Core Rule

Code is not considered mergeable unless it is:

- aligned with the approved governing spec
- aligned with capability, event, and workflow contracts
- validated by the required automated checks
- maintainable at production quality

## Engineering Standards

All in-scope code must meet these standards:

- Clear module boundaries
- Clear ownership of responsibilities
- Deterministic behavior where practical
- Actionable error handling
- Structured runtime and validation evidence
- Testability by design
- No hidden contract bypasses
- No demo-only hacks in foundation code

## Required Validation Gates

The default validation flow should include:

- spec-alignment validation
- contract validation
- formatting
- linting
- tests
- coverage checks for core logic
- dependency/security checks
- required work-traceability through issue, project item, and pull request linkage where applicable
- ticket-level definition of done and validation instructions for meaningful work

Spec-alignment gate implementation (vendored into each consuming repo at the same relative path):

- approved spec registry: `specs/governance/approved-specs.json`
- workflow job: `spec-alignment`
- script: `scripts/ci/spec_alignment_check.sh` (canonical copy lives in this repo, at `scripts/ci/spec_alignment_check.sh`)

## Coverage Standard

Required:

- `100%` automated coverage for core business and runtime logic

Core logic includes, where applicable to the repo:

- contract validation
- semver enforcement
- registry behavior
- discovery logic
- ambiguity handling
- workflow traversal
- runtime state machine
- trace generation

Coverage outside core logic should remain appropriate for risk and maintainability.

The coverage gate is merge-safe even before core logic exists. It passes when no protected crates/modules are configured, and becomes enforcing as soon as core paths are added to that repo's coverage-target list.

## Reproducibility Standard

Build and validation flows should be reproducible from pinned inputs:

- pinned toolchain
- pinned dependencies
- documented commands
- CI using the same default validation flow expected locally

## Documentation Standard

Public modules and surfaces should document:

- purpose
- inputs and outputs
- major constraints
- failure modes
- examples when useful

## Merge Blocking Conditions

A change must not merge when any of the following are true:

- spec drift is detected
- contract drift is detected
- tests fail
- required validation gates fail
- required coverage for core logic fails
- an unreviewed portability exception exists
- a material architecture change lacks a required ADR
- the change lacks the required traceability artifacts (issue + Project item + PR)

## Problem Handling Rule

When active work reveals a problem:

- must-fix issues must be resolved in the current PR when they are required for correctness, mergeability, governance, or stated acceptance criteria
- nice-to-have improvements and non-blocking follow-ups must be captured as `future` tickets instead of being left implicit
