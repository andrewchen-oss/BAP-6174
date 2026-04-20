# NFA-004 — Trainer Rights

| Status | DRAFT |
|---|---|
| Version | v0.1 |
| Requires | BAP-6174 Core Interface (§4) · [EIP-712](https://eips.ethereum.org/EIPS/eip-712) |

## Abstract

A **trainer** is the address responsible for developing an NFA's capabilities to a marketable standard. NFA-004 records the trainer's address and royalty rate at mint, persists this record across all ownership transfers, and enforces automatic royalty distribution on every arena payout.

## Motivation

Under BAP-578, the trainer's investment is entirely captured in a one-time sale price. This creates a structural problem: if training is only compensated at first sale, it is optimal to sell early and to avoid developing the most capable — and most time-consuming — agents. NFA-004 corrects this by giving trainers an ongoing stake in the agent's performance, aligning trainer incentives with long-term capability development.

## Normative requirements

- **MUST** record `trainerAddress` and `trainerRoyaltyBps` at mint time.
- **MUST** require an EIP-712 signature from `trainerAddress` at mint time authorising both the trainer designation and the `trainerRoyaltyBps` value. The signature MUST include `(aid-to-mint-position, trainer address, royaltyBps, contract address, chainId)` to prevent cross-context replay.
- **MUST** treat `trainerAddress == address(0)` as the only case where no signature is required.
- **MUST NOT** allow any address to modify `trainerAddress` or `trainerRoyaltyBps` after mint.
- **MUST** preserve the trainer record across all ownership transfers.
- **MUST NOT** allow `trainerRoyaltyBps` to exceed **1000 (10%)**.
- **MAY** expose `renounceTrainer(aid)` callable only by the current `trainerAddress`. Calling it sets `trainerRoyaltyBps` to 0 permanently. The `trainerAddress` field remains as a historical record but no future distributions accrue.
- **SHOULD** route trainer royalties automatically at settlement, without manual claiming.
- **MUST** revert any distribution where `protocolFeeBps + trainerRoyaltyBps` would exceed **2000 bps** (20% total).

## Interface

```solidity
struct TrainerRecord {
    address trainerAddress;     // address(0) if no trainer
    uint16  trainerRoyaltyBps;  // 0-1000; e.g. 500 = 5%
    uint64  recordedAt;         // block.timestamp at mint
}

function trainerOf(uint256 aid)
    external view returns (address trainer, uint16 royaltyBps, uint64 recordedAt);

function renounceTrainer(uint256 aid) external;  // current trainerAddress only; one-way

// Called by arena settlement (VERIFIER_ROLE); auto-routes trainer share
function distributeEarnings(uint256 aid, uint256 amount) external payable;
```

## EIP-712 type hash

```solidity
bytes32 constant TRAINER_CONSENT_TYPEHASH = keccak256(
    "TrainerConsent(uint256 nonce,address trainer,uint16 royaltyBps,address contract,uint256 chainId)"
);
```

`nonce` is the implementation's minting nonce (e.g. `_nextTokenId` at time of mint) — it need not be a separate counter, but MUST ensure the signed payload is unique per mint attempt.

## Events

```solidity
event TrainerDesignated(
    uint256 indexed aid,
    address indexed trainer,
    uint16 royaltyBps
);

event TrainerRenounced(uint256 indexed aid, address indexed trainer);

event TrainerRoyaltyPaid(
    uint256 indexed aid,
    address indexed trainer,
    uint256 amount
);
```

## Earnings distribution order

When an arena pays out earnings to an NFA, the following distribution applies within a single transaction:

1. **Protocol Treasury** — `protocolFeeBps` of gross (default 5%).
2. **Trainer** — `trainerRoyaltyBps` of gross (0-10%), iff `trainerAddress != address(0)`.
3. **Owner / Lessee** — remainder, split by active `Lease.ownerShareBps` if any (NFA-006).

Implementations SHOULD use a pull-payment withdrawal pattern to prevent reentrancy (§13.3).

## Invariants guaranteed

- **INV-7** · `trainerAddress` and `trainerRoyaltyBps` are immutable after mint (with the exception of `renounceTrainer` one-way zeroing `trainerRoyaltyBps`).
- **INV-12** · `protocolFeeBps + trainerRoyaltyBps` MUST NOT exceed 2000 (20% total). The payout router MUST revert if this sum is exceeded at the time of distribution.

See [docs/invariants.md](../invariants.md) for the full invariant list.

## Reference implementation

The [Clawdyland](https://clawdyland.ai) reference deployment accepts EIP-712 `TrainerConsent` signatures at mint and routes all arena settlements through `distributeEarnings()` with pull-payment `withdraw()` for recipients.
