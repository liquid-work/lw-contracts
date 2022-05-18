const deployFramework = require("@superfluid-finance/ethereum-contracts/scripts/deploy-framework");
const deployTestToken = require("@superfluid-finance/ethereum-contracts/scripts/deploy-test-token");
const deploySuperToken = require("@superfluid-finance/ethereum-contracts/scripts/deploy-super-token");
const { Framework } = require("@superfluid-finance/sdk-core");

const { expect } = require("chai");
const { ethers, web3 } = require("hardhat");
const daiABI = require("./abi/fDAIABI");

const provider = web3;

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

    //deploy the framework
    await deployFramework(errorHandler, {
      web3,
      from: signerAddress,
    });

    // deploy a fake erc20 token
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
      provider: provider,
      dataMode: "WEB3_ONLY",
      resolverAddress: process.env.RESOLVER_ADDRESS,
      protocolReleaseVersion: "test",
    });

    superSigner = await sf.createSigner({
      signer: signer,
    });

    daix = await sf.loadSuperToken("fDAIx");
    let daiAddress = daix.underlyingToken.address;
    dai = new ethers.Contract(daiAddress, daiABI, signer);
  });

  it("Deploys SuperLiquidWork Contract", async () => {
    const SuperLiquidWork = await ethers.getContractFactory(
      "SuperLiquidWork",
      signer
    );
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
    console.log(daixBal);
  });

  it("User can stream money to SuperLiquidWork", async () => {
    const flowRate = "100000000";
    const superTokenBalance = await daix.balanceOf({
      account: signerAddress,
      providerOrSigner: signer,
    });
    console.log("superTokenBalance:", superTokenBalance);
    const createFlowOperation = sf.cfaV1.createFlow({
      receiver: deployedLW.address,
      superToken: daix.address,
      flowRate: flowRate,
    });

    const txn = await createFlowOperation.exec(signer);

    const senderFlowRate = await sf.cfaV1.getNetFlow({
      account: signerAddress,
      superToken: daix.address,
      providerOrSigner: superSigner,
    });
    const appFlowRate = await sf.cfaV1.getNetFlow({
      account: deployedLW.address,
      superToken: daix.address,
      providerOrSigner: superSigner,
    });

    const appBalance = await daix.balanceOf({
      account: deployedLW.address,
      providerOrSigner: signer,
    });

    console.log("appFlowRate:", appFlowRate);
    console.log("senderFlowRate:", senderFlowRate);
    console.log("appBalance after stream started", appBalance);
  });
});
