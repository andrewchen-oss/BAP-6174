# NFA-006 — Lease Primitive

| Status | DRAFT |
|---|---|
| Version | v0.1 |
| Requires | BAP-6174 Core Interface (§4) |

## Abstract

A **lease** is a time-bounded grant of operational control from an NFA owner to a lessee. During the lease, the lessee may direct the agent's arena participation. The owner retains identity, full history, and a configured share of earnings. The lease expires automatically at the specified timestamp without requiring any transaction.

## Motivation

BAP-578 offers no mechanism for separating ownership from usage. NFA-006 introduces leasing as a first-class primitive, enabling an owner to rent operational control while retaining permanent ownership of the Agent's identity and history. Leasing creates a rental market: a lessee skilled at operating agents in a specific domain can rent a well-trained NFA rather than developing one from scratch, paying an ongoing fee rather than a large upfront purchase.

## Normative requirements

- **MUST** expose `controllerOf()` returning the lessee during an active lease and the owner otherwise.
- **MUST NOT** require any transaction to expire a lease — expiry MUST be determined from `block.timestamp` alone.
- **MUST NOT** allow more than one active lease per NFA at any time.
- **MUST NOT** allow the lessee to modify soul content, trainer records, or create sub-leases.
- **SHOULD** enforce `ownerShareBps` automatically at the settlement layer.

## Interface

```solidity
struct Lease {
    address lessee;
    uint64  expiry;          // Unix timestamp; auto-expires — no tx needed
    uint16  ownerShareBps;   // e.g. 5000 = 50% of arena earnings to owner
    bool    active;
}

function createLease(uint256 aid, address lessee, uint64 expiry, uint16 ownerShareBps) external;
function terminateLease(uint256 aid) external;

function leaseOf(uint256 aid)
    external view returns (address lessee, uint64 expiry, uint16 ownerShareBps, bool active);

function controllerOf(uint256 aid) external view returns (address);
```

## Events

```solidity
event LeaseCreated(
    uint256 indexed aid,
    address indexed lessee,
    uint64 expiry,
    uint16 ownerShareBps
);

event LeaseTerminated(
    uint256 indexed aid,
    address indexed lessee,
    address indexed terminatedBy
);

event LeaseExpired(uint256 indexed aid, address indexed lessee);
```

## Invariants guaranteed

- **INV-10** · `controllerOf(aid)` returns the lessee when `block.timestamp < lease.expiry`; returns the owner in all other cases.
- **INV-11** · At most one lease may be active per NFA at any time.

See [docs/invariants.md](../invariants.md) for the full invariant list.

## Implementation notes

**Transfer blocking (recommended, not mandated):** to protect the lessee from an owner unilaterally transferring the NFA mid-lease, implementations MAY block ERC-721 transfer while a lease is active. This can be done via `_beforeTokenTransfer` hook:

```solidity
require(!_leaseActive(aid), "ACTIVE_LEASE");
```

An alternative permitted by the specification is to let the lease travel with the token (new owner inherits the lessee). The spec deliberately leaves this as an implementation choice to allow ecosystem experimentation.

**Earnings split:** during an active lease, the earnings router (see NFA-004 `distributeEarnings()`) applies the `ownerShareBps` split to the post-fee, post-trainer-royalty remainder:

```
Net to owner  = remainder × ownerShareBps / 10000
Net to lessee = remainder − (net to owner)
```

**Reputation:** Reputation accrues to the AID (see NFA-005), not to the lessee's wallet. The lessee receives a financial share of earnings but does NOT accumulate personal reputation. This aligns with the principle that the Agent is a subject whose trajectory is its own property.

## Reference implementation

The [Clawdyland](https://clawdyland.ai) reference deployment implements transfer-blocking during active leases, routes settlement through `distributeEarnings()`, and auto-clears lease state on expiry via block-timestamp check in `controllerOf()`.
