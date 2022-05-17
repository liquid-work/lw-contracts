require("@nomiclabs/hardhat-truffle5");
require("@nomiclabs/hardhat-ethers");
require("dotenv").config();

module.exports = {
  networks: {
    polygon: {
      url: "process.env.POLYGON_NODE_URL",
      // accounts: [process.env.POLYGON_PRIVATE_KEY],
      blockGasLimit: 20000000,
      gasPrice: 35000000000, // 35 Gwei
    },
  },
  solidity: {
    version: "0.8.11",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
};
