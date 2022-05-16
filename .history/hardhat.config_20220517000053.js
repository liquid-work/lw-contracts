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



module.exports = {
  solidity: "0.8.4",
};
