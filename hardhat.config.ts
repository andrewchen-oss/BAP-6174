import type { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox-viem";

/**
 * Minimal Hardhat config for compile-only interface verification.
 *
 * BAP-6174 is an interface-only repository. No deployment, no test networks.
 * This config exists purely so contributors can run `pnpm compile` to
 * catch syntax errors before opening a pull request.
 */
const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.24",
    settings: {
      optimizer: { enabled: true, runs: 200 },
      evmVersion: "shanghai",
    },
  },
  paths: {
    sources: "./contracts",
    artifacts: "./artifacts",
    cache: "./cache",
  },
};

export default config;
