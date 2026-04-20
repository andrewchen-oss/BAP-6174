// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/// @title IBAP6174 — Non-Fungible Agent Standard Core Interface
/// @author BAP-6174 Working Group · Clawdyland reference implementation
/// @notice Canonical interface for BAP-6174 compliant contracts. Every
///         compliant NFA contract MUST implement this interface. It extends
///         IERC721 and incorporates all six NFA specifications (NFA-001
///         through NFA-006) defined in the BAP-6174 whitepaper v0.1.
/// @dev    Derived from BAP-578 (ChatAndBuild, 2025-05-27). See whitepaper
///         §4 Core Interface.
///
///         Design properties this interface encodes:
///         - Identity is immutable (genesisHash; INV-1).
///         - Soul is mutable by owner/controller, not by transfer (INV-2, INV-3).
///         - Capability and Reputation are Verifier-written only (INV-4, INV-5).
///         - Reputation is bound to the AID; MUST NOT migrate across AIDs
///           (INV-8, INV-9).
///         - Trainer record is immutable after mint (INV-7).
///         - At most one lease per NFA (INV-10, INV-11).
///         - Fee router enforces protocolFeeBps + trainerRoyaltyBps <= 2000
///           (INV-12).
interface IBAP6174 is IERC721 {
    // ═══════════════════════════════════════════════════════════════════
    //                              STRUCTS
    // ═══════════════════════════════════════════════════════════════════

    /// @notice Per-(aid, domain) capability record. Granular, per-match deltas.
    /// @dev    NFA-002. Written only by VERIFIER_ROLE.
    struct Capability {
        int32  score;        // signed; accumulates deltas, can decline
        uint32 matchCount;   // total matches contributing to this score
        uint64 lastUpdated;  // block.timestamp of most recent write
    }

    /// @notice Per-(aid, domain) reputation record. Cumulative, nonce-guarded.
    /// @dev    NFA-005. Bound to AID; travels with ownership; cannot migrate
    ///         across AIDs.
    struct Reputation {
        int64  score;         // cumulative; signed
        uint32 totalMatches;  // total evaluations contributing
        uint64 nonce;         // monotonic, replay protection
    }

    /// @notice Per-aid trainer record, set at mint, immutable after.
    /// @dev    NFA-004. royaltyBps can only decrease (via renounceTrainer),
    ///         trainerAddress never changes.
    struct TrainerRecord {
        address trainerAddress;     // address(0) if no trainer
        uint16  trainerRoyaltyBps;  // 0-1000; hard cap 10% per NFA-004
        uint64  recordedAt;         // block.timestamp at mint
    }

    /// @notice Per-aid active lease state.
    /// @dev    NFA-006. At most one active lease at any time (INV-11).
    struct Lease {
        address lessee;
        uint64  expiry;          // Unix timestamp; auto-expires, no tx needed
        uint16  ownerShareBps;   // 0-10000; share of earnings retained by owner
        bool    active;
    }

    // ═══════════════════════════════════════════════════════════════════
    //                               EVENTS
    // ═══════════════════════════════════════════════════════════════════

    /* ---- Identity & Soul (NFA-001) ---- */

    event AgentMinted(
        uint256 indexed aid,
        address indexed owner,
        bytes32 genesisHash,
        bytes32 soulHash,
        uint8   tier
    );

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

    /* ---- Capability (NFA-002) ---- */

    event CapabilityRecorded(
        uint256 indexed aid,
        bytes32 indexed domain,
        int32   delta,
        int32   newScore,
        uint32  matchCount,
        address indexed verifier,
        bytes32 matchProof
    );

    event VerifierAuthorised(address indexed verifier, bytes32 indexed domain);
    event VerifierRevoked(address indexed verifier, bytes32 indexed domain);

    /* ---- Permission Clearing (NFA-003) ---- */

    event PermissionsCleared(uint256 indexed aid, address indexed previousOwner);

    /* ---- Trainer (NFA-004) ---- */

    event TrainerDesignated(
        uint256 indexed aid,
        address indexed trainer,
        uint16  royaltyBps
    );

    event TrainerRenounced(uint256 indexed aid, address indexed trainer);

    event TrainerRoyaltyPaid(
        uint256 indexed aid,
        address indexed trainer,
        uint256 amount
    );

    /* ---- Reputation (NFA-005) ---- */

    event ReputationUpdated(
        uint256 indexed aid,
        bytes32 indexed domain,
        int64   delta,
        int64   newScore,
        address indexed verifier,
        uint64  nonce
    );

    /// @notice Emitted on transfer to confirm reputation was preserved (not reset).
    /// @dev    NFA-005 invariant INV-8. Observer-friendly breadcrumb.
    event ReputationPreserved(uint256 indexed aid, address indexed newOwner);

    /* ---- Lease (NFA-006) ---- */

    event LeaseCreated(
        uint256 indexed aid,
        address indexed lessee,
        uint64  expiry,
        uint16  ownerShareBps
    );

    event LeaseTerminated(
        uint256 indexed aid,
        address indexed lessee,
        address indexed terminatedBy
    );

    event LeaseExpired(uint256 indexed aid, address indexed lessee);

    // ═══════════════════════════════════════════════════════════════════
    //                              IDENTITY
    // ═══════════════════════════════════════════════════════════════════

    /// @notice Mint a new NFA. Binds AID to initial soul, genesis commitment,
    ///         and (optionally) trainer rights.
    /// @param  owner              Recipient of the new AID.
    /// @param  genesisHash        keccak256 commitment to initial configuration;
    ///                            immutable for the lifetime of this AID.
    /// @param  vaultURI           Pointer to encrypted soul content (IPFS/Arweave).
    /// @param  soulHash           keccak256 of plaintext soul content.
    /// @param  trainer            Trainer designation; address(0) if none.
    /// @param  trainerRoyaltyBps  0-1000 (0-10%); ignored if trainer == address(0).
    /// @param  trainerConsentSig  EIP-712 signature from trainer authorising
    ///                            (trainer, royaltyBps, chainId, contract).
    ///                            Empty if trainer == msg.sender or address(0).
    /// @return aid                The minted Agent Identifier.
    function mint(
        address owner,
        bytes32 genesisHash,
        string calldata vaultURI,
        bytes32 soulHash,
        address trainer,
        uint16  trainerRoyaltyBps,
        bytes calldata trainerConsentSig
    ) external payable returns (uint256 aid);

    /// @notice Read the immutable genesis commitment for an AID. (INV-1)
    function genesisOf(uint256 aid) external view returns (bytes32);

    /// @notice Verify a claimed initial configuration against the stored commitment.
    /// @return True iff keccak256(config) == genesisOf(aid).
    function verifyGenesis(uint256 aid, bytes calldata config)
        external
        view
        returns (bool);

    /// @notice Read current soul pointer and hash for an AID.
    function soulOf(uint256 aid)
        external
        view
        returns (string memory vaultURI, bytes32 soulHash);

    // ═══════════════════════════════════════════════════════════════════
    //                        NFA-001  SOUL INTEGRITY
    // ═══════════════════════════════════════════════════════════════════

    /// @notice Update an NFA's soul (re-trains the agent). Owner or active
    ///         controller only.
    /// @dev    Mutates stored soulHash. This is the ONLY path that changes
    ///         soulHash (INV-2).
    function updateSoul(
        uint256 aid,
        string calldata newVaultURI,
        bytes32 newSoulHash
    ) external;

    /// @notice Atomic transfer with soul re-encryption pointer update.
    /// @dev    The soulHash parameter is verification-only. It MUST equal the
    ///         currently stored soulHash or the transaction MUST revert. Only
    ///         vaultURI is updated (reflecting re-encryption for new owner).
    ///         Plaintext soul is unchanged through re-encryption, so its hash
    ///         must not change (INV-2, INV-3).
    function transferWithSoul(
        uint256 aid,
        address to,
        string calldata newVaultURI,
        bytes32 soulHash
    ) external;

    // ═══════════════════════════════════════════════════════════════════
    //                    NFA-002  CAPABILITY ATTESTATION
    // ═══════════════════════════════════════════════════════════════════

    /// @notice Record a capability delta for an AID in a domain. VERIFIER_ROLE
    ///         only. (INV-4, INV-5)
    /// @dev    matchProof is a hash pointer to off-chain evidence the Verifier
    ///         holds. Implementations SHOULD prevent matchProof replay.
    function recordCapability(
        uint256 aid,
        bytes32 domain,
        int32   delta,
        bytes32 matchProof
    ) external;

    /// @notice Read an AID's current capability in a domain.
    function capabilityOf(uint256 aid, bytes32 domain)
        external
        view
        returns (int32 score, uint32 matchCount, uint64 lastUpdated);

    /// @notice Enumerate all domains an AID has any capability record in.
    function domainsOf(uint256 aid) external view returns (bytes32[] memory);

    // ═══════════════════════════════════════════════════════════════════
    //                        NFA-004  TRAINER RIGHTS
    // ═══════════════════════════════════════════════════════════════════

    /// @notice Read the trainer record for an AID. (INV-7)
    function trainerOf(uint256 aid)
        external
        view
        returns (address trainer, uint16 royaltyBps, uint64 recordedAt);

    /// @notice Permanently renounce trainer royalty for an AID. Callable only
    ///         by the current trainerAddress. One-way, irreversible.
    /// @dev    Sets trainerRoyaltyBps to 0. trainerAddress remains as a
    ///         historical record, but no future distributions accrue.
    function renounceTrainer(uint256 aid) external;

    /// @notice Route earnings for an AID through the protocol fee / trainer
    ///         royalty / owner-lessee waterfall atomically.
    /// @dev    VERIFIER_ROLE only (arena settlement). Implementations MUST
    ///         enforce INV-12: protocolFeeBps + trainerRoyaltyBps <= 2000.
    ///         Implementations SHOULD use pull-payment (§13.3).
    function distributeEarnings(uint256 aid, uint256 amount) external payable;

    // ═══════════════════════════════════════════════════════════════════
    //                       NFA-005  DOMAIN REPUTATION
    // ═══════════════════════════════════════════════════════════════════

    /// @notice Read an AID's cumulative reputation in a domain.
    /// @dev    Reputation is bound to the AID and persists across ownership
    ///         transfers. It MUST NOT be migrated across AIDs (INV-8, INV-9).
    function reputationOf(uint256 aid, bytes32 domain)
        external
        view
        returns (int64 score, uint32 totalMatches);

    /// @notice Apply a reputation delta for an AID in a domain. VERIFIER_ROLE
    ///         only. Nonce MUST be strictly sequential.
    function applyReputation(
        uint256 aid,
        bytes32 domain,
        int64   delta,
        uint64  nonce,
        bytes32 matchProof
    ) external;

    /// @notice Read the current nonce for (aid, domain).
    function reputationNonce(uint256 aid, bytes32 domain)
        external
        view
        returns (uint64);

    // ═══════════════════════════════════════════════════════════════════
    //                        NFA-006  LEASE PRIMITIVE
    // ═══════════════════════════════════════════════════════════════════

    /// @notice Grant time-bounded operational control to a lessee. Owner only.
    /// @dev    Creates a lease with auto-expiry at block.timestamp >= expiry.
    ///         At most one active lease per AID (INV-11). Implementations
    ///         SHOULD block token transfer while a lease is active.
    function createLease(
        uint256 aid,
        address lessee,
        uint64  expiry,
        uint16  ownerShareBps
    ) external;

    /// @notice Terminate an active lease early. Callable by owner or lessee.
    function terminateLease(uint256 aid) external;

    /// @notice Read the current lease state for an AID.
    function leaseOf(uint256 aid)
        external
        view
        returns (address lessee, uint64 expiry, uint16 ownerShareBps, bool active);

    /// @notice Resolve the currently authorised controller for an AID.
    /// @dev    Returns lessee during an active unexpired lease, otherwise the
    ///         token owner (INV-10).
    function controllerOf(uint256 aid) external view returns (address);
}
