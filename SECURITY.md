# Security Policy

## Scope

This repository hosts the **specification** and **reference interfaces** for BAP-6174. It does not contain production contract implementations. Security issues are therefore grouped into two classes:

1. **Specification issues** — ambiguities, inconsistencies, or unstated invariants in the whitepaper or spec documents that could lead to unsafe implementations.
2. **Interface issues** — problems in `contracts/interfaces/*.sol` that would propagate to every compliant implementation.

For vulnerabilities in any specific deployed implementation (e.g. `ClawdylandNFA`), please report directly to the maintainers of that implementation. This repository cannot patch third-party deployments.

## Reporting a vulnerability

**Do not open a public GitHub issue for security reports.**

Reach the BAP-6174 working group by **direct message to the official X (Twitter) account** linked in this repository's profile description. Vulnerability reports sent via public channels may be front-run by adversaries before a fix ships.

Please include:

- Type of issue (spec ambiguity / interface flaw / invariant violation / other)
- Full paths of affected files
- The location of the affected code (line number or section number)
- A step-by-step reproduction or concrete example
- Impact — what compliant implementations could suffer
- Your proposed fix, if any

We will acknowledge receipt within **72 hours** and aim to provide a status update within **7 days**.

## Disclosure timeline

- **Day 0** — report received; acknowledgement sent
- **Day 1-7** — triage and severity classification
- **Day 7-30** — fix drafted and reviewed
- **Day 30-60** — coordinated disclosure with known implementors (Clawdyland and any other `implementations/` registry entries)
- **Day 60+** — public disclosure via GitHub Security Advisory, CHANGELOG, and whitepaper revision

Timeline may be accelerated if the vulnerability is being actively exploited or is already public.

## Protocol-level safe defaults

Implementations SHOULD follow these hardening practices in addition to the normative MUSTs of the specification:

- **Multi-sig governance** with minimum 3-of-5 signatories for all role management.
- **Timelock of ≥48 hours** on every `VERIFIER_ROLE` grant. Revocations MAY be immediate.
- **Pull-payment** pattern for all earnings distribution (§13.3).
- **ReentrancyGuard** on every state-mutating external function.
- **Pause switch** (`Pausable`) on mint and Verifier writes for emergency response.
- **Explicit invariant tests** covering INV-1 through INV-12 in the implementation's test suite.

## Hall of thanks

Security researchers who report valid issues will be credited here (with consent) and in the whitepaper's Acknowledgements section.
