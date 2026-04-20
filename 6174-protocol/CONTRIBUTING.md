# Contributing to BAP-6174

BAP-6174 is a specification, not a product. Contributions change language, diagrams, interfaces, or invariants — not a single deployed contract. This document describes how to propose changes safely.

## Types of contribution

| Type | Mechanism | Who reviews |
|---|---|---|
| **Spec clarification** — fix ambiguous wording, typo, or contradiction | GitHub issue → PR | Maintainers |
| **Interface change** — add / remove / modify functions or events in `IBAP6174.sol` / `IBAP6174Verifier.sol` | GitHub issue → design discussion → PR | Maintainers + known implementors |
| **New invariant** — add to `docs/invariants.md` and the whitepaper | GitHub issue with formal statement | Maintainers + known implementors |
| **New NFA spec** (NFA-007+) | Draft a full spec doc in `docs/specs/` via PR | Maintainers + ≥2 implementors |
| **Reference implementation submission** — list your deployed BAP-6174 contract | PR to `IMPLEMENTATIONS.md` | Maintainers (cursory review; no endorsement) |

## Before you open a PR

- For any **interface-level change**, open an issue first labelled `spec-proposal`. Discuss design before code.
- Breaking changes between versions must be announced in `CHANGELOG.md` and flagged in the whitepaper's revision log.
- Respect the specification's existing naming conventions:
  - Interfaces: `IBAP6174`, `IBAP6174Verifier` (uppercase `BAP`, matching `IERC20` / `IERC721`).
  - Role constants: `VERIFIER_ROLE = keccak256("BAP6174_VERIFIER")`.
  - Domain identifiers: `keccak256("<lowercase-ascii-name>")`, e.g. `keccak256("poker")`.
  - Spec codes: `NFA-001` through `NFA-006`; `INV-1` through `INV-12`.

## Style

- **Solidity**: pragma `0.8.24`, MIT license header, NatSpec `@title @author @notice @dev` on every contract and interface.
- **Markdown specs**: follow the template established by `docs/specs/NFA-001-soul-integrity.md`. Sections in order: Status · Abstract · Motivation · Normative · Interface · Events · Bindings · Reference Implementation.
- **RFC 2119 key words** (MUST, MUST NOT, SHOULD, SHOULD NOT, MAY) are reserved for normative clauses. Use them sparingly and correctly.

## PR checklist

- [ ] Whitepaper (`whitepaper/BAP-6174-v0.1.html`) updated to reflect the change, **or** the PR is exclusively code (interfaces / mocks / tests) and includes a note that the whitepaper does not need to change
- [ ] `docs/specs/NFA-00X-*.md` updated if the change affects spec text
- [ ] `docs/invariants.md` updated if INV-* are added, reordered, or altered
- [ ] `CHANGELOG.md` entry added under the `## Unreleased` section
- [ ] Interface compiles (`pnpm compile` or `forge build`)
- [ ] Breaking change is flagged explicitly in the PR description

## Review SLA

Maintainers aim for:

- First response on spec-clarification PRs: **within 3 working days**
- First response on interface-change PRs: **within 7 working days** (design review takes longer)
- Decision on a draft NFA spec: **within 30 days** of the design discussion closing

## Governance note

BAP-6174 has no formal governance contract. Maintainers resolve disputes by consensus, with input from known implementors. Major divergences should be resolved by forking this repository and publishing the alternative as a separate specification — precedent following the Ethereum community's handling of contentious EIPs.
