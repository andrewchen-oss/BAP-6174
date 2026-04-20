# NFA-003 — Permission Clearing on Transfer

| Status | DRAFT |
|---|---|
| Version | v0.1 |
| Requires | BAP-6174 Core Interface (§4) |

## Abstract

When an NFA is transferred, all vault access permissions granted by the previous owner are automatically revoked. The new owner begins with a clean permission state.

## Motivation

BAP-578's `VaultPermissionManager` tracks delegated rights by `(tokenId, delegate)`. ERC-721 transfer does not trigger any cleanup. After a sale, the previous owner's `WRITE` delegation persists until manually revoked — an unacceptable property for a secondary market. NFA-003 closes this gap with a single transfer hook.

## Normative requirements

- **MUST** override ERC-721's `_afterTokenTransfer` to clear all delegated vault permissions on transfer.
- **MUST NOT** revoke `FULL_CONTROL` permissions granted by governance.
- **MUST** emit `PermissionsCleared` in the same transaction as the transfer.

## Reference implementation pattern

```solidity
function _afterTokenTransfer(
    address from, address to, uint256 firstTokenId, uint256 batchSize
) internal virtual override {
    super._afterTokenTransfer(from, to, firstTokenId, batchSize);
    if (from != address(0)) {
        _vaultPermissions.revokeAllBelow(firstTokenId, PermissionLevel.FULL_CONTROL);
        emit PermissionsCleared(firstTokenId, from);
    }
}
```

## Events

```solidity
event PermissionsCleared(uint256 indexed aid, address indexed previousOwner);
```

## Invariants guaranteed

- **INV-6** · After any ERC-721 transfer, no address holds a vault permission granted by the previous owner (except `FULL_CONTROL` from governance).

See [docs/invariants.md](../invariants.md) for the full invariant list.

## Notes on off-chain state

Implementations that route agent actions through off-chain infrastructure (webhooks, API endpoints, cached credentials) SHOULD listen for the `PermissionsCleared` event and clear any corresponding off-chain state atomically. The on-chain event serves as the canonical signal.

## Reference implementation

The [Clawdyland](https://clawdyland.ai) backend subscribes to `PermissionsCleared` events and clears the transferred NFA's cached webhook URL and any signed attestations from the previous owner.
