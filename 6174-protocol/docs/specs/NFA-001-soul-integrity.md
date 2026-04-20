# NFA-001 — Soul Integrity

| Status | DRAFT |
|---|---|
| Version | v0.1 |
| Requires | BAP-6174 Core Interface (§4) |

## Abstract

The soul of an NFA is a structured off-chain document that defines the agent's behaviour and domain knowledge. NFA-001 ensures that the soul's authenticity is verifiable by any party, that its contents remain accessible only to the current owner, and that ownership transfer atomically updates access rights.

## Motivation

BAP-578's `vaultURI` is an unprotected public URI. NFA-001 addresses this by requiring soul content to be encrypted with the current owner's public key and by making soul re-encryption an atomic part of the transfer operation.

NFA-001 does not attempt to prevent a previous owner from retaining a plaintext copy before transfer — this cannot be solved at the protocol layer. The protocol's defence lies in economic design: a copied soul applied to a new token starts with zero capability scores and no domain reputation, whereas the original token carries its full verified performance history. The market prices the two accordingly.

## Normative requirements

Key words follow [RFC 2119](https://www.rfc-editor.org/rfc/rfc2119) / [RFC 8174](https://www.rfc-editor.org/rfc/rfc8174).

- **MUST** store `keccak256(plaintext soul)` as `soulHash` on-chain at mint.
- **MUST** store a `vaultURI` pointing to soul content encrypted with the current owner's public key.
- **MUST NOT** allow `updateSoul()` to be called by any address other than the current owner or active controller.
- **MUST** atomically update `vaultURI` in the same transaction as the token transfer on `transferWithSoul()`. `soulHash` is provided for verification only and MUST equal the currently stored `soulHash` — otherwise the transaction MUST revert.
- **MUST** treat `soulHash` as mutable ONLY through `updateSoul()` called by the current owner or controller. No transfer function may modify `soulHash`.
- **SHOULD** expose `verifyGenesis(aid, config)` returning true when `keccak256(config)` matches the stored `genesisHash`.
- **MUST NOT** allow a transfer to complete without a new `vaultURI` being supplied.
- **SHOULD** use [Lit Protocol](https://litprotocol.com) or equivalent decentralised encryption to avoid a centralised key custodian.

## Interface

```solidity
// Update soul content (owner/controller only)
function updateSoul(
    uint256 aid,
    string  calldata newVaultURI,   // IPFS/Arweave CID of encrypted content
    bytes32 newSoulHash              // keccak256(plaintext)
) external;

// Atomic transfer: moves ownership AND re-encrypts soul for new owner
// soulHash parameter is verification-only — content must not change
function transferWithSoul(
    uint256 aid,
    address to,
    string  calldata newVaultURI,   // encrypted with `to` public key
    bytes32 soulHash                 // must equal stored soulHash or tx reverts
) external;

function soulOf(uint256 aid)
    external view returns (string memory vaultURI, bytes32 soulHash);

function genesisOf(uint256 aid) external view returns (bytes32);

function verifyGenesis(uint256 aid, bytes calldata config)
    external view returns (bool);
```

## Events

```solidity
event SoulUpdated(
    uint256 indexed aid,
    bytes32 soulHash,
    string  vaultURI,
    address indexed updatedBy
);

event SoulTransferred(
    uint256 indexed aid,
    address indexed from,
    address indexed to,
    bytes32 soulHash,
    string  newVaultURI
);
```

## Invariants guaranteed

- **INV-1** · `genesisHash` is written at mint and is immutable. No function may modify it.
- **INV-2** · `soulHash` may only change via `updateSoul()` called by the current owner or controller. `transferWithSoul()` MUST preserve `soulHash`; its parameter is verification-only.
- **INV-3** · `transferWithSoul()` is atomic: token ownership and `vaultURI` update occur in the same transaction or neither occurs.

See [docs/invariants.md](../invariants.md) for the full invariant list.

## Reference implementation

[ClawdylandNFA.sol](https://clawdyland.ai) implements NFA-001 with Lit Protocol re-encryption on transfer.
