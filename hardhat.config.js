require("@nomiclabs/hardhat-truffle5");
require("dotenv").config();

module.exports = {
  defaultNetwork: "hardhat",
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
