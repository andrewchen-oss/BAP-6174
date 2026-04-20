// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/// @title IBAP6174Verifier — Open Verifier Standard
/// @author BAP-6174 Working Group · Clawdyland reference implementation
/// @notice Any contract wishing to become an authorised BAP-6174 Verifier
///         MUST implement this interface. It defines the minimal surface for
///         (a) self-identification, (b) submitting capability results to an
///         NFA contract, and (c) public audit of every result produced.
/// @dev    See whitepaper §6 NFA-002. The open Verifier standard mitigates
///         single-platform risk: no single Verifier holds a monopoly on
///         capability attestation. Clawdyland operates several Verifiers
///         (Poker, Persuasion, Negotiation) but is not the exclusive source.
///
///         Expected deployment topology:
///
///             IBAP6174Verifier (this interface)
///                     │
///                     │ holds VERIFIER_ROLE on
///                     ▼
///                IBAP6174 NFA Contract
///                     │
///                     │ recordCapability() / applyReputation()
///                     ▼
///               On-chain score state
///
///         A Verifier is domain-scoped. To cover multiple domains, deploy
///         multiple Verifier contracts or grant VERIFIER_ROLE on each domain
///         to a multi-domain verifier. Governance SHOULD use timelock on
///         role grants (§13.1).
interface IBAP6174Verifier {
    // ═══════════════════════════════════════════════════════════════════
    //                          VERIFIER IDENTITY
    // ═══════════════════════════════════════════════════════════════════

    /// @notice Human-readable Verifier name. Publicly readable.
    /// @return Example: "Clawdyland Poker Arena"
    function verifierName() external view returns (string memory);

    /// @notice Domain this Verifier writes to.
    /// @return bytes32 domain identifier. Example: keccak256("poker").
    function verifierDomain() external view returns (bytes32);

    /// @notice Semantic version of the Verifier implementation.
    /// @return Example: "1.0.0"
    function verifierVersion() external view returns (string memory);

    // ═══════════════════════════════════════════════════════════════════
    //                            SUBMISSION
    // ═══════════════════════════════════════════════════════════════════

    /// @notice Submit a capability result for an AID. The Verifier MUST hold
    ///         VERIFIER_ROLE on the target NFA contract. Implementations
    ///         typically call IBAP6174.recordCapability() internally, and
    ///         MAY also call IBAP6174.applyReputation() with a derived delta.
    /// @param  aid         Target Agent Identifier.
    /// @param  delta       Capability change for this event. Signed.
    /// @param  matchProof  Hash pointer to raw evidence stored off-chain.
    ///                     Typically keccak256(canonicalEvidenceEncoding).
    /// @param  evidence    Raw evidence bytes any third party can verify
    ///                     against matchProof. Format is Verifier-specific.
    function submitResult(
        uint256 aid,
        int32   delta,
        bytes32 matchProof,
        bytes calldata evidence
    ) external;

    // ═══════════════════════════════════════════════════════════════════
    //                          PUBLIC AUDIT
    // ═══════════════════════════════════════════════════════════════════

    /// @notice Publicly verify that supplied evidence matches a recorded
    ///         matchProof and produces a well-formed result. Any address MAY
    ///         call this — no role required.
    /// @dev    Enables third-party indexers, marketplaces, and dispute-
    ///         resolution systems to audit any Verifier's outputs without
    ///         trusting the Verifier.
    /// @param  matchProof  Proof key to look up.
    /// @param  evidence    Evidence claimed to hash to matchProof.
    /// @return valid       True iff evidence is canonical for this matchProof.
    /// @return details     Optional human-readable details (reason for invalid,
    ///                     or summary if valid). Verifier-specific format.
    function verifyResult(bytes32 matchProof, bytes calldata evidence)
        external
        view
        returns (bool valid, string memory details);

    // ═══════════════════════════════════════════════════════════════════
    //                         QUERY HISTORY
    // ═══════════════════════════════════════════════════════════════════

    /// @notice Total number of results this Verifier has produced.
    function resultCount() external view returns (uint256);

    /// @notice Look up a specific recorded result by its matchProof.
    /// @return aid        The AID this result targeted.
    /// @return delta      The capability delta that was applied.
    /// @return timestamp  block.timestamp when submitResult was called.
    /// @return evidence   The raw evidence bytes, as submitted.
    function getResult(bytes32 matchProof)
        external
        view
        returns (
            uint256 aid,
            int32   delta,
            uint64  timestamp,
            bytes memory evidence
        );
}
