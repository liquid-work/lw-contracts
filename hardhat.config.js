require("dotenv").config();
require("@nomiclabs/hardhat-truffle5");
require("@nomiclabs/hardhat-ethers");

const { ALCHEMY_API_URL_KEY, PRIVATE_KEY } = process.env;

module.exports = {
  defaultNetwork: "hardhat",
  networks: {
    mumbai: {
      url: ALCHEMY_API_URL_KEY,
      accounts: [`${PRIVATE_KEY}`],
    },
  },
  solidity: {
    version: "0.8.11",
    settings: {
      optimizer: {
        enabled: true,
      },
    },
  },
};
