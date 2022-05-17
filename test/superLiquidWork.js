const deployFramework = require("@superfluid-finance/ethereum-contracts/scripts/deploy-framework");
const deployTestToken = require("@superfluid-finance/ethereum-contracts/scripts/deploy-test-token");
const deploySuperToken = require("@superfluid-finance/ethereum-contracts/scripts/deploy-super-token");
const { Framework } = require("@superfluid-finance/sdk-core");

const { expect } = require("chai");
const { ethers, web3 } = require("hardhat");
const daiABI = require("./abi/fDAIABI");

let accounts;
let deployedLW;
let sf;
let dai;
let daix;
let superSigner;
let signer;

const errorHandler = (err) => {
  if (err) throw err;
};

describe("Testing Deployment", () => {
  it("Loads network", async () => {
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
    const daiAddress = daix.underlyingToken.address;
    signer = ethers.provider.getSigner();
    dai = new ethers.Contract(daiAddress, daiABI, signer);
  });

  it("Deploys SuperLiquidWork Contract", async () => {
    const SuperLiquidWork = await ethers.getContractFactory("SuperLiquidWork");
    const superLiquidWork = await SuperLiquidWork.deploy(
      sf.host.hostContract.address
    );
    await superLiquidWork.deployed();
    expect(superLiquidWork.address);
    deployedLW = superLiquidWork;
  });
});

describe("Testing flows", async () => {
  before(async () => {
    await dai
      .connect(accounts[0])
      .mint(accounts[0].address, ethers.utils.parseEther("1000"));

    await dai
      .connect(accounts[0])
      .approve(daix.address, ethers.utils.parseEther("1000"));

    const daixUpgradeOperation = daix.upgrade({
      amount: ethers.utils.parseEther("1000"),
    });

    await daixUpgradeOperation.exec(accounts[0]);

    const daiBal = await daix.balanceOf({
      account: accounts[0].address,
      providerOrSigner: accounts[0],
    });
    console.log("daix bal for acct 0: ", daiBal);
  });

  it("User can stream money to SuperLiquidWork", async () => {
    const flowRate = "100000000";
    const appInitialBalance = await daix.balanceOf({
      account: deployedLW.address,
      providerOrSigner: accounts[0],
    });
    const createFlowOperation = sf.cfaV1.createFlow({
      receiver: deployedLW.address,
      superToken: daix.address,
      flowRate: "100000000",
    });

    await createFlowOperation.exec(accounts[0]);

    const appFlowRate = await sf.cfaV1.getNetFlow({
      superToken: daix.address,
      account: deployedLW.address,
      providerOrSigner: superSigner,
    });
    const appBalance = await daix.balanceOf({
      account: deployedLW.address,
      providerOrSigner: signer,
    });
    expect(appFlowRate).to.equal(flowRate);
    expect(appBalance > appInitialBalance);
  });
});
