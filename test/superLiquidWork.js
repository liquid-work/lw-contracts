const deployFramework = require("@superfluid-finance/ethereum-contracts/scripts/deploy-framework");
const deployTestToken = require("@superfluid-finance/ethereum-contracts/scripts/deploy-test-token");
const deploySuperToken = require("@superfluid-finance/ethereum-contracts/scripts/deploy-super-token");
const { Framework } = require("@superfluid-finance/sdk-core");

const { expect } = require("chai");
const { ethers, web3 } = require("hardhat");
const daiABI = require("../abi/fDAIABI");
const { BigNumber } = require("ethers");

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
      provider: web3,
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
  const deposit = ethers.utils.parseEther("1.0");
  const flowRate = "100000000";
  const instanceId = "testInstanceId";
  const userData = web3.eth.abi.encodeParameter("string", instanceId);

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

  it("User can make a deposit", async () => {
    await deployedLW.deposit("testInstanceId", {
      value: deposit,
    });

    const contractBalance = await ethers.provider.getBalance(
      deployedLW.address
    );
    expect(contractBalance.eq(BigNumber.from(deposit)));
  });

  it("User can create a flow", async () => {
    const createFlowOperation = sf.cfaV1.createFlow({
      receiver: deployedLW.address,
      superToken: daix.address,
      flowRate: flowRate,
      userData,
    });

    await createFlowOperation.exec(signer);
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
    expect(appFlowRate).to.eq(-senderFlowRate + "");
  });

  it("Smart contract emits agreementCreated event", async () => {
    deployedLW.on("agreementCreated", (sender, id, fRate, amount) => {
      expect(sender).to.eq(signerAddress);
      expect(id).to.eq(instanceId);
      expect(amount.eq(BigNumber.from(deposit)));
    });
  });

  it("User can stop a flow", async () => {
    const createFlowOperation = sf.cfaV1.deleteFlow({
      receiver: deployedLW.address,
      sender: signerAddress,
      superToken: daix.address,
      flowRate: flowRate,
      userData,
    });

    await createFlowOperation.exec(signer);

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
    expect(appFlowRate).to.eq(senderFlowRate);
  });

  it("Smart contract emits agreementTerminated event", async () => {
    deployedLW.on("agreementTerminated", (sender, id, fRate, amount) => {
      expect(sender).to.eq(signerAddress);
      expect(id).to.eq(instanceId);
      expect(amount.eq(BigNumber.from(deposit)));
      expect(fRate.eq(BigNumber.from(0)));
    });
  });
});
