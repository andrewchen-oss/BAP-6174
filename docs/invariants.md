# Protocol Invariants

The following invariants MUST hold in every BAP-6174-compliant implementation. They are the smallest set of statements whose preservation is sufficient to call an implementation compliant.

> *"Protocols are judged by the invariants they preserve, not by how many files they are split across."*

| ID | Invariant | Source |
|---|---|---|
| **INV-1** | `genesisHash` is written at mint and is immutable. No function may modify it. | §4 `mint()` |
| **INV-2** | `soulHash` may only change via `updateSoul()` called by the current owner or controller. `transferWithSoul()` MUST preserve `soulHash`; its parameter is verification-only. | [NFA-001](./specs/NFA-001-soul-integrity.md) |
| **INV-3** | `transferWithSoul()` is atomic: token ownership and `vaultURI` update occur in the same transaction or neither occurs. | [NFA-001](./specs/NFA-001-soul-integrity.md) |
| **INV-4** | `recordCapability()` and `applyReputation()` may only be called by addresses holding `VERIFIER_ROLE`. | [NFA-002](./specs/NFA-002-capability-attestation.md), [NFA-005](./specs/NFA-005-domain-reputation.md) |
| **INV-5** | No address holding owner-level control of any NFA may also hold `VERIFIER_ROLE`. | [NFA-002](./specs/NFA-002-capability-attestation.md) |
| **INV-6** | After any ERC-721 transfer, no address holds a vault permission granted by the previous owner (except `FULL_CONTROL` from governance). | [NFA-003](./specs/NFA-003-permission-clearing.md) |
| **INV-7** | `trainerAddress` and `trainerRoyaltyBps` are immutable after mint, except for the one-way `renounceTrainer()` path that zeroes `trainerRoyaltyBps`. | [NFA-004](./specs/NFA-004-trainer-rights.md) |
| **INV-8** | Domain reputation scores are NOT modified, reset, or cleared by any transfer event. They persist bound to the AID across all ownership changes. | [NFA-005](./specs/NFA-005-domain-reputation.md) |
| **INV-9** | Domain reputation scores MUST NOT be transferred, merged, or copied between different AIDs under any circumstance. | [NFA-005](./specs/NFA-005-domain-reputation.md) |
| **INV-10** | `controllerOf(aid)` returns the lessee when `block.timestamp < lease.expiry`; returns the owner in all other cases. | [NFA-006](./specs/NFA-006-lease-primitive.md) |
| **INV-11** | At most one lease may be active per NFA at any time. | [NFA-006](./specs/NFA-006-lease-primitive.md) |
| **INV-12** | `protocolFeeBps + trainerRoyaltyBps` MUST NOT exceed 2000 (20% total). The payout router MUST revert if this sum is exceeded at the time of distribution. | [NFA-004](./specs/NFA-004-trainer-rights.md), §12 |

## Verification checklist for implementors

An implementation's test suite SHOULD cover each invariant explicitly. Suggested test names:

- `test_INV1_genesisHash_immutable_after_mint`
- `test_INV2_transferWithSoul_reverts_on_hash_mismatch`
- `test_INV3_transferWithSoul_atomic_or_revert`
- `test_INV4_recordCapability_reverts_without_role`
- `test_INV4_applyReputation_reverts_without_role`
- `test_INV5_owner_cannot_hold_verifier_role`
- `test_INV6_transfer_clears_vault_permissions`
- `test_INV7_trainer_record_immutable_after_mint`
- `test_INV7_renounceTrainer_one_way_only`
- `test_INV8_reputation_preserved_across_transfer`
- `test_INV9_no_cross_aid_reputation_interface_exists`
- `test_INV10_controllerOf_returns_lessee_during_lease`
- `test_INV11_cannot_create_second_lease`
- `test_INV12_distributeEarnings_reverts_if_fees_exceed_2000bps`

## Rationale

The invariant registry exists as a **minimum verification contract** between the specification and its implementors. Any implementation that satisfies INV-1 through INV-12 and implements the normative interface surfaces in [IBAP6174](../contracts/interfaces/IBAP6174.sol) can claim compliance. Any implementation that violates a single invariant is non-compliant, regardless of how well it implements the rest.

Adding, removing, or modifying an invariant between versions constitutes a breaking change and MUST be called out in [CHANGELOG.md](../CHANGELOG.md) and in the whitepaper revision log.
