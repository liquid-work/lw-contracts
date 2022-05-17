const deployFramework = require("@superfluid-finance/ethereum-contracts/scripts/deploy-framework");
const deployTestToken = require("@superfluid-finance/ethereum-contracts/scripts/deploy-test-token");
const deploySuperToken = require("@superfluid-finance/ethereum-contracts/scripts/deploy-super-token");
const { Framework } = require("@superfluid-finance/sdk-core");

const { expect } = require("chai");
const { ethers, web3 } = require("hardhat");

const SuperLiquidWork = artifacts.require("SuperLiquidWork");
let accounts;

const errorHandler = (err) => {
  if (err) throw err;
};

describe("Testing Deployment", async () => {
  let deployedLW;
  let sf;
  let dai;
  let daix;
  let superSigner;

  before(async () => {
    console.log("dsadsa");

    accounts = await web3.eth.getAccounts();

    await deployFramework(errorHandler, {
      web3,
      from: accounts[0].address,
    });

    let fDAIAddress = await deployTestToken(errorHandler, [":", "fDAI"], {
      web3,
      from: accounts[0].address,
    });
    let fDAIxAddress = await deploySuperToken(errorHandler, [":", "fDAI"], {
      web3,
      from: accounts[0].address,
    });

    sf = await Framework.create({
      networkName: "custom",
      provider: web3,
      dataMode: "WEB3_ONLY",
      resolverAddress: process.env.RESOLVER_ADDRESS,
      protocolReleaseVersion: "test",
    });

    superSigner = await sf.createSigner({
      signer: accounts[0],
      provider: web3,
    });
    daix = await sf.loadSuperToken("fDAIx");
    let daiAddress = daix.underlyingToken.address;
    // dai = new ethers.Contract(daiAddress, daiABI, accounts[0]);
  });

  it("Deploys SuperLiquidWork Contract", async () => {
    const SuperLiquidWork = await ethers.getContractFactory("SuperLiquidWork");
    console.log("superLiquidWork:", superLiquidWork);
    const superLiquidWork = await SuperLiquidWork.deploy();
    await superLiquidWork.deployed();
    expect(superLiquidWork.address);
    deployedLW = superLiquidWork;
  });
});
