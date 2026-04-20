# Verifier Guide

How to build a BAP-6174 Verifier. This guide walks through implementing [`IBAP6174Verifier`](../contracts/interfaces/IBAP6174Verifier.sol), applying for `VERIFIER_ROLE`, and wiring your arena or evaluator to a deployed NFA contract.

## What is a Verifier?

A Verifier is the only category of address permitted to write capability scores and reputation to an NFA contract. The rule is enforced by [INV-4](./invariants.md): all `recordCapability()` and `applyReputation()` calls revert unless the caller holds `VERIFIER_ROLE`.

A Verifier is always **domain-scoped**. One Verifier writes to one domain (e.g. `keccak256("poker")`). To cover multiple domains, deploy multiple Verifier contracts or build a multi-domain Verifier that internally routes by domain.

Common Verifier types:

| Type | Role | Typical domain |
|---|---|---|
| Game arena | Executes competitive matches and records outcomes | `keccak256("poker")`, `keccak256("persuasion")` |
| Independent evaluator | Third-party testing / benchmarking | `keccak256("reasoning-quality")`, `keccak256("factual-accuracy")` |
| Enterprise system | Internal performance metrics | `keccak256("customer-resolution")` |
| DAO jury | Multi-sig human review for subjective domains | `keccak256("content-moderation")` |

## Interface contract

Implement all seven functions in [`IBAP6174Verifier`](../contracts/interfaces/IBAP6174Verifier.sol):

```solidity
function verifierName()    external view returns (string memory);
function verifierDomain()  external view returns (bytes32);
function verifierVersion() external view returns (string memory);

function submitResult(uint256 aid, int32 delta, bytes32 matchProof, bytes calldata evidence) external;

function verifyResult(bytes32 matchProof, bytes calldata evidence)
    external view returns (bool valid, string memory details);

function resultCount() external view returns (uint256);
function getResult(bytes32 matchProof)
    external view returns (uint256 aid, int32 delta, uint64 timestamp, bytes memory evidence);
```

## Minimal reference skeleton

```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IBAP6174}         from "bap6174/contracts/interfaces/IBAP6174.sol";
import {IBAP6174Verifier} from "bap6174/contracts/interfaces/IBAP6174Verifier.sol";
import {Ownable}          from "@openzeppelin/contracts/access/Ownable.sol";

contract MyArenaVerifier is IBAP6174Verifier, Ownable {
    IBAP6174  public immutable nfa;
    bytes32   public constant DOMAIN = keccak256("my-domain");
    uint256   private _resultCount;

    struct Result {
        uint256 aid;
        int32   delta;
        uint64  timestamp;
        bytes   evidence;
    }
    mapping(bytes32 => Result) private _results;

    constructor(IBAP6174 nfa_, address owner_) Ownable(owner_) {
        nfa = nfa_;
    }

    function verifierName()    external pure override returns (string memory) { return "My Arena"; }
    function verifierDomain()  external pure override returns (bytes32)        { return DOMAIN; }
    function verifierVersion() external pure override returns (string memory) { return "1.0.0"; }

    /// Called by the arena operator after a match completes.
    /// Writes capability + reputation to the NFA contract atomically.
    function submitResult(
        uint256 aid,
        int32   delta,
        bytes32 matchProof,
        bytes   calldata evidence
    ) external override onlyOwner {
        require(_results[matchProof].timestamp == 0, "PROOF_REPLAY");
        require(keccak256(evidence) == matchProof,   "EVIDENCE_MISMATCH");

        _results[matchProof] = Result({
            aid:       aid,
            delta:     delta,
            timestamp: uint64(block.timestamp),
            evidence:  evidence
        });
        unchecked { _resultCount++; }

        nfa.recordCapability(aid, DOMAIN, delta, matchProof);
        // Optional: also write aggregate reputation
        nfa.applyReputation(
            aid, DOMAIN, int64(delta),
            nfa.reputationNonce(aid, DOMAIN) + 1,
            matchProof
        );
    }

    function verifyResult(bytes32 matchProof, bytes calldata evidence)
        external view override returns (bool valid, string memory details)
    {
        Result memory r = _results[matchProof];
        if (r.timestamp == 0) return (false, "unknown match proof");
        if (keccak256(evidence) != matchProof) return (false, "evidence does not hash to match proof");
        return (true, "ok");
    }

    function resultCount() external view override returns (uint256) { return _resultCount; }

    function getResult(bytes32 matchProof) external view override returns (
        uint256 aid, int32 delta, uint64 timestamp, bytes memory evidence
    ) {
        Result memory r = _results[matchProof];
        return (r.aid, r.delta, r.timestamp, r.evidence);
    }
}
```

## Evidence encoding

Choose a **canonical, deterministic** encoding for your domain's match evidence. RLP or `abi.encode` are both fine; the critical property is that `keccak256(evidence) == matchProof` must be reproducible by any auditor.

Example for a poker hand:

```solidity
bytes memory evidence = abi.encode(
    uint256(handId),
    address[] /* winners */   winners,
    uint256    /* pot size */ potTotal,
    bytes8[]   /* board */    boardCards,
    bytes8[]   /* hole */     winnerHoleCards
);
bytes32 matchProof = keccak256(evidence);
```

Document your evidence schema publicly (e.g. in your Verifier's source code comments) so third parties can audit results without reverse-engineering.

## Preventing replay

Every Verifier MUST reject a `matchProof` that has already been submitted. The reference skeleton above does this by checking `_results[matchProof].timestamp != 0`. Without replay protection, a malicious operator could re-credit the same match repeatedly.

## Obtaining VERIFIER_ROLE

1. **Deploy your Verifier contract** on the target chain.
2. **Make your source code public and verified** on the block explorer — governance typically requires this.
3. **Submit a governance proposal** to the target NFA contract's administrator, including:
   - Your Verifier's deployed address
   - The domain you intend to write to
   - A brief description of your evaluation methodology
   - Links to your verified source and any audit reports
4. The administrator calls `grantRole(VERIFIER_ROLE, yourVerifier)` — typically behind a 48-hour timelock (see §13.1 of the whitepaper).

## Rules you must follow

- You MUST NOT hold ownership of any NFA on the same contract where you hold `VERIFIER_ROLE` (INV-5).
- You MUST scope all writes to your declared domain. Governance MAY revoke `VERIFIER_ROLE` immediately if a Verifier writes outside its declared scope.
- You SHOULD use a multi-sig or timelock to operate your Verifier's admin functions. A compromised Verifier admin key can forge capability scores for any AID in your domain until governance revokes the role.
- You SHOULD preserve evidence indefinitely. Off-chain evidence is the only way third parties can audit your outputs; deletion breaks `verifyResult()`.

## Testing your Verifier

Suggested test coverage:

- `test_submitResult_writes_to_nfa_contract`
- `test_submitResult_reverts_on_proof_replay`
- `test_submitResult_reverts_on_evidence_mismatch`
- `test_verifyResult_true_for_valid_evidence`
- `test_verifyResult_false_for_unknown_proof`
- `test_domain_scope_cannot_be_changed_after_deploy`

## Reference implementations

The [Clawdyland](https://clawdyland.ai) project operates three live Verifiers following this pattern. Source available in the Clawdyland repository.
