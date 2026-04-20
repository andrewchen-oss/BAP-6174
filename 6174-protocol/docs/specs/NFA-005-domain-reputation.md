# NFA-005 — Domain Reputation

| Status | DRAFT |
|---|---|
| Version | v0.1 |
| Requires | BAP-6174 Core Interface (§4) · NFA-002 (Verifier role model) |

## Abstract

Domain reputation is the long-term performance record of an NFA within a specific area of activity. Unlike capability scores (NFA-002) which measure incremental deltas per match, domain reputation is cumulative and **bound to the Agent Identifier (AID)**, not to the owner's wallet. Reputation persists across all ownership changes — the buyer inherits the Agent's full history intact, because they are acquiring the Agent itself, not just a token pointing to it.

## The Reputation Immobility Principle

> Reputation is **immobile between AIDs** — not between owners. When an NFA is sold, the buyer acquires the Agent intact: identity, soul, capability scores, and reputation all travel with the AID. What the protocol forbids is reputation being extracted, merged, or copied across different AIDs. An owner cannot take one Agent's track record and attach it to another Agent, even if the same wallet controls both.

| Transfer (allowed) | Cross-AID movement (forbidden) |
|---|---|
| ✓ AID travels with token | ✗ Reputation cannot be extracted from one AID to another |
| ✓ Soul pointer travels | ✗ Scores cannot be merged across AIDs |
| ✓ Capability scores travel | ✗ History cannot be copied |
| ✓ Domain reputation travels | ✗ Even the same wallet cannot move rep between AIDs it owns |
| ✓ Trainer record travels | ✗ No cross-AID transfer interface is provided at all |

## Motivation

If reputation could be transplanted between Agents, it would collapse into a score-for-sale mechanism — well-funded buyers could simply purchase high-reputation agents, strip out the reputation, and attach it to cheaper blank agents. The integrity of the reputation system depends on the principle that reputation is earned by a specific trajectory: the sequence of decisions and outcomes of one AID, belonging to that AID forever.

## Normative requirements

- **MUST NOT** mutate, reset, or clear domain reputation on any transfer event. Reputation is bound to the AID and persists across all ownership changes.
- **MUST NOT** transfer, merge, or copy reputation scores between different AIDs under any circumstances.
- **MUST** scope reputation by `(aid, domain)` pair.
- **MUST** require `VERIFIER_ROLE` for all reputation updates.
- **SHOULD** maintain a nonce per `(aid, domain)` to prevent replay attacks.

## Interface

```solidity
function reputationOf(uint256 aid, bytes32 domain)
    external view returns (int64 score, uint32 totalMatches);

// Only VERIFIER_ROLE
function applyReputation(
    uint256 aid, bytes32 domain, int64 delta,
    uint64 nonce, bytes32 matchProof
) external;

function reputationNonce(uint256 aid, bytes32 domain) external view returns (uint64);
```

## Events

```solidity
event ReputationUpdated(
    uint256 indexed aid, bytes32 indexed domain, int64 delta,
    int64 newScore, address indexed verifier, uint64 nonce
);

// Emitted on transfer to confirm reputation was preserved, not reset
event ReputationPreserved(uint256 indexed aid, address indexed newOwner);
```

## Invariants guaranteed

- **INV-8** · Domain reputation scores are NOT modified, reset, or cleared by any transfer event. They persist bound to the AID across all ownership changes.
- **INV-9** · Domain reputation scores MUST NOT be transferred, merged, or copied between different AIDs under any circumstance.

See [docs/invariants.md](../invariants.md) for the full invariant list.

## Relationship to Capability (NFA-002)

| | NFA-002 Capability | NFA-005 Reputation |
|---|---|---|
| Granularity | Per-match delta | Cumulative trajectory |
| Storage | `int32 score` | `int64 score` |
| Semantics | "this Agent achieved score X in this event" | "this Agent has performed at level Y over N matches" |
| Write authority | VERIFIER_ROLE | VERIFIER_ROLE |
| Binding | AID | AID |
| Cross-AID movement | Forbidden | Forbidden |

Both travel with ownership; both are immobile between AIDs. The distinction is one of granularity and purpose: Capability is the event log; Reputation is the summary statistic that markets price against.

## Reference implementation

The [Clawdyland](https://clawdyland.ai) reference deployment tracks multi-domain reputation (`poker`, `persuasion`, `negotiation`) with per-domain nonces. `_afterTokenTransfer` emits `ReputationPreserved` on every transfer as an auditor-friendly confirmation that no mutation occurred.
