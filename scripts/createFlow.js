const { Framework } = require("@superfluid-finance/sdk-core");
const { BigNumber } = require("ethers");
const { ethers } = require("hardhat");
const ABI_LW =
  require("../artifacts/contracts/SuperLiquidWork.sol/SuperLiquidWork.json").abi;
const ABI_MATICX = require("../abi/MATICxABI");

const { PRIVATE_KEY, ALCHEMY_API_URL_KEY, NETWORK_NAME } = process.env;
const networkConfigs = require("../network.configs.js");

const createFlow = async (
  ourContractAddress,
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

  const lwContract = new ethers.Contract(
    ourContractAddress,
    ABI_LW,
    superSigner
  );
  await lwContract.deposit(instanceId, {
    value: deposit,
  });

  const options = {
    receiver: ourContractAddress,
    superToken: networkConfigs[NETWORK_NAME].maticx,
    flowRate: flowRate,
    userData,
  };


  const createFlowOperation = sf.cfaV1.createFlow(options);
  await createFlowOperation.exec(superSigner);
  const maticxBalance = await maticx.realtimeBalanceOf(signerAddress);
  console.log("maticxBalance:", maticxBalance);

};

const ourContractAddress = "0x5098FfE333036bf8038D850d3D2F925eDF915110";
const deposit = ethers.utils.parseEther("0.00002");
const flowRate = "100";
const instanceId = "testInstanceId";
const userData = web3.eth.abi.encodeParameter("string", instanceId);

try {
  createFlow(ourContractAddress, deposit, flowRate, instanceId, userData);
} catch (error) {
  console.log("Error:", error);
}
