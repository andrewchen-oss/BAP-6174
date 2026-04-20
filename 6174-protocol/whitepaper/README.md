# BAP-6174 Whitepaper

This directory contains the canonical long-form specification.

## Current version

- **[`BAP-6174-v0.1.html`](./BAP-6174-v0.1.html)** — v0.1 DRAFT · April 2026

Open in any modern browser. The document is designed to be read on screen and printed to PDF (use your browser's Print → Save as PDF, with "Background graphics" enabled for correct typography).

## Contents

The whitepaper is the authoritative long-form source. Each section has a short companion document in [`../docs/specs/`](../docs/specs/) for easier browsing and linking:

| § | Topic | Short form |
|---|---|---|
| § 0 | Abstract — The Core Thesis | README hero |
| § 1 | Motivation | — |
| § 2 | Terminology | [glossary](../docs/glossary.md) |
| § 3 | Architecture Overview | — |
| § 4 | Core Interface — IBAP6174 | [`IBAP6174.sol`](../contracts/interfaces/IBAP6174.sol) |
| § 5 | NFA-001 Soul Integrity | [spec](../docs/specs/NFA-001-soul-integrity.md) |
| § 6 | NFA-002 Capability Attestation & Open Verifier Standard | [spec](../docs/specs/NFA-002-capability-attestation.md) |
| § 7 | NFA-003 Permission Clearing on Transfer | [spec](../docs/specs/NFA-003-permission-clearing.md) |
| § 8 | NFA-004 Trainer Rights | [spec](../docs/specs/NFA-004-trainer-rights.md) |
| § 9 | NFA-005 Domain Reputation | [spec](../docs/specs/NFA-005-domain-reputation.md) |
| § 10 | NFA-006 Lease Primitive | [spec](../docs/specs/NFA-006-lease-primitive.md) |
| § 11 | Protocol Invariants | [invariants](../docs/invariants.md) |
| § 12 | Economic Layer | — |
| § 13 | Security Considerations | [SECURITY.md](../SECURITY.md) |
| § 14 | Backward Compatibility | — |
| § 15 | Reference Implementation — Clawdyland | — |
| App. A | Why 6174 | [why-6174](../docs/why-6174.md) |
| App. B | Notation and Key Words | [glossary](../docs/glossary.md) |
| App. C | Domain Registry | — |
| App. D | References | — |

## When the whitepaper and the short-form docs disagree

The whitepaper is normative. Short-form documents in `../docs/` are derived; any discrepancy is a bug against the short-form document. Open a [spec-clarification issue](../.github/ISSUE_TEMPLATE/spec-clarification.yml).

## Versioning

Whitepaper filenames include the version (`BAP-6174-v0.1.html`). Older versions are preserved in this directory when new versions ship, so external links never break.

Breaking changes are announced in [`CHANGELOG.md`](../CHANGELOG.md) and flagged in the document's revision history.
