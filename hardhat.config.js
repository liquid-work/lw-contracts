require("dotenv").config();
require("@nomiclabs/hardhat-truffle5");
require("@nomiclabs/hardhat-ethers");

const {
  ALCHEMY_API_URL_KEY,
  PRIVATE_KEY,
  POLYSCAN_API_KEY
} = process.env;

module.exports = {
  defaultNetwork: "hardhat",
  networks: {
    mumbai: {
      url: ALCHEMY_API_URL_KEY,
      accounts: [PRIVATE_KEY],
    },
    polygon: {
      url: ALCHEMY_API_URL_KEY,
      accounts: [PRIVATE_KEY],
    },
  },
  solidity: {
    version: "0.8.7",
    settings: {
      optimizer: {
        enabled: true,
      },
    },
  },
  etherscan: {
    apiKey: {
      mumbai: POLYSCAN_API_KEY || "",
      polygon: POLYSCAN_API_KEY || "",
    },
  },
};
