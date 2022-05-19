const { ethers } = require("hardhat");
const networkConfigs = require("../network.configs");
const { NETWORK_NAME } = process.env;

const deploy = async () => {
  const SuperLiquidWork = await ethers.getContractFactory("SuperLiquidWork");
  const superLiquidWork = await SuperLiquidWork.deploy(
    networkConfigs[NETWORK_NAME].host
  );
  await superLiquidWork.deployed();

  console.log(
    `SuperLiquidWork Smart Contract ${superLiquidWork.address} deployed on ${NETWORK_NAME}`
  );
};
try {
  deploy();
} catch (error) {
  console.log(error);
}
