<p align="center">
  <h1 align="center">BAP-6174</h1>
  <p align="center"><b>Non-Fungible Agent Standard</b></p>
  <p align="center"><i>A complete protocol for intelligent, verifiable, tradeable agents on BNB Chain.</i></p>
</p>

<p align="center">
  <a href="./whitepaper/BAP-6174-v0.1.html"><img alt="whitepaper" src="https://img.shields.io/badge/whitepaper-v0.1%20DRAFT-0A0A0A?style=flat-square"></a>
  <a href="./LICENSE"><img alt="license" src="https://img.shields.io/badge/license-MIT-black?style=flat-square"></a>
  <img alt="solidity" src="https://img.shields.io/badge/solidity-0.8.24-363636?style=flat-square">
  <img alt="chain" src="https://img.shields.io/badge/BNB%20Chain-native-F3BA2F?style=flat-square">
</p>

---

BAP-6174 defines the Non-Fungible Agent (NFA) standard for Binance Smart Chain. It extends ERC-721 with six purpose-built mechanisms that turn a non-fungible token into a **tradeable, verifiable, leasable intelligent agent**.

The standard derives from [BAP-578](https://github.com/bnb-chain/BEPs/blob/master/BAPs/BAP-578.md) (ChatAndBuild, 2025). It supersedes BAP-578 while retaining full backward compatibility. The name is drawn from Kaprekar's constant — the fixed point to which all four-digit numbers converge — as a statement that any sufficiently honest agent protocol converges to these primitives.

## The four axioms

> **I.** An NFA is a tokenised intelligent agent, not a static collectible.
>
> **II.** Its value comes from identity, verified capability, and economic rights — together, not separately.
>
> **III.** Capability is not a claim. It is a record only an authorised, independent Verifier can produce.
>
> **IV.** An Agent's history — its full trajectory — belongs to the AID, and travels with it across all ownership changes.

## Six specifications

| Spec | Name | What it solves |
|---|---|---|
| [NFA-001](./docs/specs/NFA-001-soul-integrity.md) | **Soul Integrity** | Soul content authenticity + atomic re-encryption on transfer |
| [NFA-002](./docs/specs/NFA-002-capability-attestation.md) | **Capability Attestation & Open Verifier Standard** | Verifier-written scores only; open pluggable Verifier architecture |
| [NFA-003](./docs/specs/NFA-003-permission-clearing.md) | **Permission Clearing on Transfer** | Auto-revoke previous owner's delegations atomically |
| [NFA-004](./docs/specs/NFA-004-trainer-rights.md) | **Trainer Rights** | Ongoing royalty for original trainer across ownership changes |
| [NFA-005](./docs/specs/NFA-005-domain-reputation.md) | **Domain Reputation** | Cumulative, AID-bound, non-migratable between AIDs |
| [NFA-006](./docs/specs/NFA-006-lease-primitive.md) | **Lease Primitive** | Time-bounded operational control separate from ownership |

See also: [Invariants](./docs/invariants.md) · [Why 6174](./docs/why-6174.md) · [Glossary](./docs/glossary.md) · [Verifier Guide](./docs/verifier-guide.md)

## Repository layout

```
6174-protocol/
├── whitepaper/               Full specification (HTML, print-ready PDF export)
├── contracts/interfaces/     Solidity interfaces — IBAP6174, IBAP6174Verifier
├── docs/specs/               Machine-readable per-NFA specifications
├── docs/                     Guides, invariants, glossary
└── .github/                  Issue templates, CI
```

## For integrators

Install:

```bash
pnpm add @openzeppelin/contracts
# copy or import the two interfaces:
#   contracts/interfaces/IBAP6174.sol
#   contracts/interfaces/IBAP6174Verifier.sol
```

**To build a BAP-6174 compliant NFA contract**, implement [`IBAP6174`](./contracts/interfaces/IBAP6174.sol). The interface encodes all 12 protocol invariants as type signatures and NatSpec constraints.

**To build a Verifier** (arena, evaluator, DAO jury, enterprise system), implement [`IBAP6174Verifier`](./contracts/interfaces/IBAP6174Verifier.sol) and apply for `VERIFIER_ROLE` on the target NFA contract through its governance process. See [Verifier Guide](./docs/verifier-guide.md).

## Reference implementation

[**Clawdyland**](https://clawdyland.ai) is the first production reference implementation of BAP-6174. It deploys `ClawdylandNFA.sol` on BNB Smart Chain and operates three Verifier contracts for the `poker`, `persuasion`, and `negotiation` domains.

> *Clawdyland is not the standard. Clawdyland is the first thing that satisfies the standard. The distinction matters: BAP-6174 survives the reference implementation, and the reference implementation survives any single arena.*

Any project may implement `IBAP6174` — Clawdyland is one such implementation, not the exclusive one.

## Status

**v0.1 DRAFT** — the specification is stable enough to build against. Breaking changes between v0.1 and v1.0 will be documented in [CHANGELOG.md](./CHANGELOG.md) and announced via GitHub release.

This repository is the canonical home of the specification. Proposed changes should be filed as issues using the [spec-clarification template](./.github/ISSUE_TEMPLATE/spec-clarification.yml) or pull requests following [CONTRIBUTING.md](./CONTRIBUTING.md).

## Governance

No BAP-6174 governance contract exists at this layer. Each deployed implementation defines its own governance model for `VERIFIER_ROLE` grants and contract upgrades. The whitepaper recommends multi-sig governance with a minimum 48-hour timelock on role grants (§13.1).

## Authors

Andrew Chen · Jason Yuan

## Derivation notice

This specification was derived from BAP-578 ([ChatAndBuild, 2025-05-27](https://github.com/bnb-chain/BEPs/blob/master/BAPs/BAP-578.md)). Significant portions of the interface design and hybrid storage architecture were adopted from that work and extended here. The original authors of BAP-578 are not responsible for this specification.

## License

Code (interfaces, reference templates, mocks): **MIT** — see [LICENSE](./LICENSE).
Specification prose (whitepaper, docs/): **CC BY 4.0** — attribution required, derivative works permitted.
