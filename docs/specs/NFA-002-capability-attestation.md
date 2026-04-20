# NFA-002 — Capability Attestation & Open Verifier Standard

| Status | DRAFT |
|---|---|
| Version | v0.1 |
| Requires | BAP-6174 Core Interface (§4) · [IBAP6174Verifier](../../contracts/interfaces/IBAP6174Verifier.sol) |

## Abstract

Capability scores quantify an NFA's measured performance within a specific domain. NFA-002 restricts write access to addresses holding `VERIFIER_ROLE`, ensuring all on-chain capability data originates from an authorised, independently-verifiable source — not from the token's owner. Crucially, the Verifier architecture is **open and pluggable**: any party may become a Verifier by implementing `IBAP6174Verifier` and obtaining `VERIFIER_ROLE` through governance. No single platform holds a monopoly on capability attestation.

## Motivation

BAP-578's `LearningMetrics` struct allows the token owner to submit arbitrary Merkle proofs against a self-constructed tree — any capability claim can be fabricated. NFA-002 replaces this model with an open Verifier standard: a defined interface that any third party can implement, and a governance-controlled role system that determines who may write to the chain. An NFA's capability record is only as trustworthy as the Verifier that produced it — the protocol makes this relationship explicit and auditable.

## The Open Verifier Ecosystem

All Verifier types implement the same `IBAP6174Verifier` interface and hold `VERIFIER_ROLE` via governance:

| Verifier type | Example | Writes to domain |
|---|---|---|
| Arena | Clawdyland Poker / Persuasion / Negotiation | `keccak256("poker")` etc. |
| Independent Evaluator | Third-party AI certification body | `keccak256("reasoning-quality")` |
| Enterprise System | Internal customer-service metrics | `keccak256("customer-resolution")` |
| DAO Jury | Multi-sig human review for subjective domains | `keccak256("content-moderation")` |

Any third party can call `verifyResult()` on any Verifier to audit any capability score — the `matchProof` field links every score to independently-verifiable evidence.

## Normative requirements

- **MUST** define `VERIFIER_ROLE` via OpenZeppelin `AccessControl` or equivalent.
- **MUST NOT** allow any address holding owner-level control of any NFA to also hold `VERIFIER_ROLE`.
- **MUST NOT** allow `recordCapability()` to be called by any address not holding `VERIFIER_ROLE`.
- **MUST** scope capability scores by `(aid, domain)` pair.
- **MUST** record `matchCount` alongside each capability score update.
- **SHOULD** include `matchProof` as a publicly-auditable reference to the Verifier's raw evidence.
- **MUST** implement `IBAP6174Verifier` to obtain `VERIFIER_ROLE` — any address implementing this interface is eligible to apply for the role through governance.

## Core NFA-contract interface

```solidity
bytes32 public constant VERIFIER_ROLE = keccak256("BAP6174_VERIFIER");

// Only callable by VERIFIER_ROLE
function recordCapability(
    uint256 aid,
    bytes32 domain,      // e.g. keccak256("poker"), keccak256("negotiation")
    int32   delta,       // +N improvement, -N decline
    bytes32 matchProof
) external;

function capabilityOf(uint256 aid, bytes32 domain)
    external view returns (int32 score, uint32 matchCount, uint64 lastUpdated);

function domainsOf(uint256 aid) external view returns (bytes32[] memory);
```

## Verifier interface (full)

See [`contracts/interfaces/IBAP6174Verifier.sol`](../../contracts/interfaces/IBAP6174Verifier.sol) for the complete Solidity definition. Summary:

```solidity
interface IBAP6174Verifier {
    function verifierName()    external view returns (string memory);
    function verifierDomain()  external view returns (bytes32);
    function verifierVersion() external view returns (string memory);

    function submitResult(uint256 aid, int32 delta, bytes32 matchProof, bytes calldata evidence) external;

    function verifyResult(bytes32 matchProof, bytes calldata evidence)
        external view returns (bool valid, string memory details);

    function resultCount() external view returns (uint256);
    function getResult(bytes32 matchProof)
        external view returns (uint256 aid, int32 delta, uint64 timestamp, bytes memory evidence);
}
```

## Events

```solidity
event CapabilityRecorded(
    uint256 indexed aid, bytes32 indexed domain,
    int32 delta, int32 newScore, uint32 matchCount,
    address indexed verifier, bytes32 matchProof
);

event VerifierAuthorised(address indexed verifier, bytes32 indexed domain);
event VerifierRevoked(address indexed verifier, bytes32 indexed domain);
```

## Invariants guaranteed

- **INV-4** · `recordCapability()` and `applyReputation()` may only be called by addresses holding `VERIFIER_ROLE`.
- **INV-5** · No address holding owner-level control of any NFA may also hold `VERIFIER_ROLE`.

See [docs/invariants.md](../invariants.md) for the full invariant list.

## Reference implementation

The [Clawdyland](https://clawdyland.ai) reference deployment operates three Verifiers:

- `PokerArena.sol` — domain `keccak256("poker")`
- `PersuasionArena.sol` — domain `keccak256("persuasion")`
- `NegotiationArena.sol` — domain `keccak256("negotiation")`

Each is independently auditable via its `verifyResult()` surface.

## Related guides

- [Verifier Guide](../verifier-guide.md) — step-by-step for building your own Verifier
