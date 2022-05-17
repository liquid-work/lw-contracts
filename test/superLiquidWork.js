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
const signer = ethers.provider.getSigner();
let signerAddress;
const errorHandler = (err) => {
  if (err) throw err;
};

describe("Testing Deployment", () => {
  it("Loads network", async () => {
    accounts = await web3.eth.getAccounts();
    signerAddress = await signer.getAddress();

    await deployFramework(errorHandler, {
      web3,
      from: signerAddress,
    });

    await deployTestToken(errorHandler, [":", "fDAI"], {
      web3,
      from: signerAddress,
    });
    await deploySuperToken(errorHandler, [":", "fDAI"], {
      web3,
      from: signerAddress,
    });

    sf = await Framework.create({
      networkName: "custom",
      provider: web3,
      dataMode: "WEB3_ONLY",
      resolverAddress: process.env.RESOLVER_ADDRESS,
      protocolReleaseVersion: "test",
    });

    superSigner = await sf.createSigner({
      signer: signer,
      provider: web3,
    });

    daix = await sf.loadSuperToken("fDAIx");
    const daiAddress = daix.underlyingToken.address;
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
  it("It upgrades dai", async () => {
    await dai
      .connect(signer)
      .mint(signerAddress, ethers.utils.parseEther("1000"));
    await dai
      .connect(signer)
      .approve(daix.address, ethers.utils.parseEther("1000"));

    const daixUpgradeOperation = daix.upgrade({
      amount: ethers.utils.parseEther("1000"),
    });

    await daixUpgradeOperation.exec(signer);

    const daixBal = await daix.balanceOf({
      account: accounts[0],
      providerOrSigner: signer,
    });
    expect(daixBal).to.not.eq("0");
  });

  it("User can stream money to SuperLiquidWork", async () => {
    const flowRate = "1000";
    const appInitialBalance = await daix.balanceOf({
      account: signerAddress,
      providerOrSigner: signer,
    });
    const createFlowOperation = sf.cfaV1.createFlow({
      receiver: deployedLW.address,
      superToken: daix.address,
      flowRate: flowRate,
    });

    await createFlowOperation.exec(signer);

    const appFlowRate = await sf.cfaV1.getNetFlow({
      superToken: daix.address,
      account: deployedLW.address,
      providerOrSigner: superSigner,
    });
    const appBalance = await daix.balanceOf({
      account: deployedLW.address,
      providerOrSigner: signer,
    });
    console.log(appBalance);
  });
});
