import * as dotenv from "dotenv";

import { HardhatUserConfig, task } from "hardhat/config";
// This adds support for typescript paths mappings
// import "tsconfig-paths/register";

import "@nomiclabs/hardhat-etherscan";
import "@nomiclabs/hardhat-waffle";
import "@nomiclabs/hardhat-web3";
import "@nomiclabs/hardhat-ethers";
import "@openzeppelin/hardhat-upgrades";
import "hardhat-contract-sizer";
import "hardhat-gas-reporter";
import "@nomiclabs/hardhat-etherscan";
import "@typechain/hardhat";
import "solidity-coverage";
import { ethers } from "ethers";

dotenv.config();

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.4",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  

networks: {
  polygon: {
    url: process.env.POLYGON_NODE_URL,
    // accounts: [process.env.POLYGON_PRIVATE_KEY],
    blockGasLimit: 20000000,
    gasPrice: 35000000000 // 35 Gwei
  },
},
mocha: {
  timeout: 0,
},
etherscan: {
  // Your API key for Etherscan
  // Obtain one at https://etherscan.io/
  apiKey: process.env.POLYGONSCAN_API_KEY,
},
contractSizer: {
  alphaSort: true,
  runOnCompile: true,
  disambiguatePaths: false,
},

// Configuration from the old Rex-Bank repository
// networks: {
//   hardhat: {
// forking: {
//   url: `https://green-nameless-water.matic.quiknode.pro/${process.env.QUICKNODE_ENDPOINT}/`,
// accounts: [process.env.MATIC_PRIVATE_KEY],
// blockNumber: parseInt(`${process.env.FORK_BLOCK_NUMBER}`),
// gasPrice: 50000000000,
// network_id: 137,
//   },
// }
};



