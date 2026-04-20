# Glossary

Key words follow [RFC 2119](https://www.rfc-editor.org/rfc/rfc2119) / [RFC 8174](https://www.rfc-editor.org/rfc/rfc8174). **MUST**, **MUST NOT**, **SHOULD**, **SHOULD NOT**, **MAY** are to be interpreted as described therein.

| Term | Definition |
|---|---|
| **NFA** | Non-Fungible Agent. A BAP-6174-compliant token representing an intelligent agent with verifiable capabilities. NFA is both the token standard and the individual token — there is no separate "NFS" designation. |
| **AID** | Agent Identifier. The ERC-721 `tokenId` — the unique, immutable on-chain identity of an NFA. |
| **Soul** | The agent's knowledge base: a structured document defining strategic behaviour, domain knowledge, and decision-making parameters. Stored off-chain; its hash is committed on-chain. |
| **soulHash** | `keccak256` of the plaintext soul content. Stored on-chain. Allows any party to verify a soul document's authenticity without accessing the encrypted content. |
| **genesisHash** | `keccak256` commitment to the agent's initial configuration at mint time. Immutable. Establishes a permanent origin record. |
| **vaultURI** | Pointer to the encrypted soul content, typically an IPFS or Arweave CID. Updated atomically on transfer to reflect re-encryption for the new owner. |
| **Domain** | `bytes32` identifier scoping a capability context. Examples: `keccak256("poker")`, `keccak256("negotiation")`, `keccak256("customer-service")`. Any arena MAY define additional domains. |
| **Arena** | Any environment — competitive, evaluative, or task-based — where agents perform and receive evaluations. Arenas submit results via an authorised Verifier contract. |
| **Verifier** | Any contract implementing [`IBAP6174Verifier`](../contracts/interfaces/IBAP6174Verifier.sol) and holding `VERIFIER_ROLE`. The only addresses permitted to call `recordCapability()` and `applyReputation()`. May be a game arena, an independent evaluation institution, an enterprise system, or a decentralised DAO jury. |
| **VERIFIER_ROLE** | `keccak256("BAP6174_VERIFIER")`. OpenZeppelin `AccessControl` role. Required to write capability and reputation. Open to any qualifying contract through governance. |
| **matchProof** | `bytes32` hash pointer supplied with every capability write, linking the on-chain record to independently-verifiable off-chain evidence held by the Verifier. Accessible via `IBAP6174Verifier.verifyResult()`. |
| **Capability** | Per-match delta record: "this Agent achieved score X in this event." Granular, per-domain, Verifier-written. Stored as `(int32 score, uint32 matchCount, uint64 lastUpdated)`. |
| **Reputation** | Cumulative trajectory record: "this Agent has performed at level Y over N matches." Aggregate, per-domain, Verifier-written. Bound to AID — travels with ownership but cannot migrate between different AIDs. Stored as `(int64 score, uint32 totalMatches, uint64 nonce)`. |
| **Reputation Immobility Principle** | Reputation is bound to the AID, not to the owner's wallet. It persists across ownership changes, but MUST NOT be extracted, merged, or copied across different AIDs. |
| **Trainer** | The address that developed an agent's capabilities before sale. Recorded at mint. Receives ongoing royalty from arena earnings via `distributeEarnings()`. Trainer record is immutable after mint except for one-way `renounceTrainer()` which zeroes the royalty. |
| **Lease** | A time-bounded grant of operational control from an NFA owner to a lessee. Owner retains identity, history, and a share of earnings. Auto-expires at the specified timestamp. |
| **Controller** | The address currently authorised to direct an NFA's actions. Equal to the owner when no lease is active; equal to the lessee during a lease. Resolved via `controllerOf(aid)`. |
| **bps** | Basis points. 1 bps = 0.01%. 10,000 bps = 100%. Used for all fee and royalty parameters. |
| **AgentMinted / SoulUpdated / CapabilityRecorded / ReputationUpdated / TrainerDesignated / LeaseCreated / ...** | Standardised events every compliant implementation emits. See per-spec documents in [docs/specs/](./specs/). |
