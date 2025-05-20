import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import PRIVATE_KEYS from "./ignition/accounts";
require('hardhat-docgen');

const config: HardhatUserConfig | {docgen: {}} = {
  solidity: {
    version: "0.8.28",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  networks: {
    localhost: {
      url: "http://127.0.0.1:8545",
      accounts: PRIVATE_KEYS,
    }
  },
  docgen: {
    path: './docs',
    clear: true,
    except: [
      "contracts/test_helpers/TestERC20Token.sol",
      "contracts/test_helpers/TestERC721Token.sol",
      "contracts/test_helpers/TestTreasuryWrapper.sol"
    ]
    // runOnCompile: true,
  }
};

export default config;
