const { Framework } = require("@superfluid-finance/sdk-core");
const { BigNumber } = require("ethers");
const { ethers } = require("hardhat");
const ABI_LW =
  require("../artifacts/contracts/SuperLiquidWork.sol/SuperLiquidWork.json").abi;
const ABI_MATICX = require("../abi/MATICX");

const { PRIVATE_KEY, ALCHEMY_API_URL_KEY, NETWORK_NAME } = process.env;
const networkConfigs = require("../network.configs.js");

const createFlow = async (
  ourContractAddress,
  amountToUpgrade,
  deposit,
  flowRate,
  instanceId,
  userData
) => {
  const ethersProvider = new ethers.providers.JsonRpcProvider(
    ALCHEMY_API_URL_KEY,
    {
      name: NETWORK_NAME,
      chainId: networkConfigs[NETWORK_NAME].chainId,
    }
  );
  const sf = await Framework.create({
    networkName: NETWORK_NAME,
    provider: ethersProvider,
    chainId: networkConfigs[NETWORK_NAME].chainId,
  });

  const superSigner = sf.createSigner({
    privateKey: PRIVATE_KEY,
    provider: ethersProvider,
  });

  let maticx;
  maticx = new ethers.Contract(
    networkConfigs[NETWORK_NAME].maticx,
    ABI_MATICX,
    superSigner
  );
  const y = await maticx
    .connect(superSigner)
    .upgradeByETH({ value: amountToUpgrade });
  const receipt = await y.wait();
  console.log("receipt", receipt);
  const signer = ethers.provider.getSigner();
  const signerAddress = await signer.getAddress();
  const lwContract = new ethers.Contract(ourContractAddress, ABI_LW, signer);
  await lwContract.deposit(instanceId, {
    value: deposit,
  });

  const contractBalance = await ethers.provider.getBalance(ourContractAddress);
  const options = {
    receiver: ourContractAddress,
    superToken: maticx.address,
    flowRate: flowRate,
    userData,
  };
  const createFlowOperation = sf.cfaV1.createFlow(options);
  const maticxBalance = await maticx.getBalance(signerAddress);
  console.log("maticxBalance:", maticxBalance);

  await createFlowOperation.exec(superSigner);
};

const ourContractAddress = "0x5098FfE333036bf8038D850d3D2F925eDF915110";
const amountToUpgrade = 10;
const deposit = ethers.utils.parseEther("0.00002");
const flowRate = "100";
const instanceId = "testInstanceId";
const userData = web3.eth.abi.encodeParameter("string", instanceId);

try {
  createFlow(
    ourContractAddress,
    amountToUpgrade,
    deposit,
    flowRate,
    instanceId,
    userData
  );
} catch (error) {
  console.log("Error:", error);
}
