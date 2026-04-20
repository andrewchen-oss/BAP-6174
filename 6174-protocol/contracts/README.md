# Contracts

This directory contains the **canonical Solidity interfaces** that define BAP-6174. It does not contain production implementations — those live in downstream projects (see [Reference Implementation](../README.md#reference-implementation) in the root README).

## Files

| File | Purpose |
|---|---|
| [`interfaces/IBAP6174.sol`](./interfaces/IBAP6174.sol) | Core interface. Every compliant NFA contract MUST implement this. Extends `IERC721`. Encodes all six NFA specifications (NFA-001 through NFA-006). |
| [`interfaces/IBAP6174Verifier.sol`](./interfaces/IBAP6174Verifier.sol) | Open Verifier interface. Any arena, evaluator, enterprise system, or DAO jury that wishes to write capability and reputation scores MUST implement this interface and obtain `VERIFIER_ROLE` on the target NFA contract. |

## Importing

### Via npm/pnpm (after publication)

```bash
pnpm add bap6174
```

```solidity
import {IBAP6174}         from "bap6174/contracts/interfaces/IBAP6174.sol";
import {IBAP6174Verifier} from "bap6174/contracts/interfaces/IBAP6174Verifier.sol";
```

### Via git submodule (Foundry projects)

```bash
git submodule add <repository-url> lib/bap6174
```

```
# remappings.txt
bap6174/=lib/bap6174/
```

### Via raw file copy

The interfaces are two self-contained files with a single external dependency (`@openzeppelin/contracts/token/ERC721/IERC721.sol`). Copying them directly into your project is permitted under the MIT license.

## Compiler

- Solidity `0.8.24`
- No upper-bound pragma intentionally — the interfaces compile against every `^0.8.24` compiler up to the latest.

## Dependencies

The interfaces depend only on `@openzeppelin/contracts` for `IERC721`. No other external code is imported.

## What you will NOT find here

- Concrete `contract` implementations of `IBAP6174` or `IBAP6174Verifier`
- Proxy / upgrade scaffolding
- Deployment scripts
- Chain-specific configuration

These are deliberately out of scope. Every compliant implementation makes its own choices about upgradability, governance, storage layout, and chain targets. This repository defines the interface contract those implementations agree on — nothing more.

Implementation references: see the [Verifier Guide](../docs/verifier-guide.md) for a skeleton, and the Clawdyland reference implementation for a full example.
