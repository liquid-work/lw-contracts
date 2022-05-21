const { Framework } = require("@superfluid-finance/sdk-core");
const { ethers } = require("hardhat");

const { PRIVATE_KEY, ALCHEMY_API_URL_KEY, NETWORK_NAME } = process.env;
const networkConfigs = require("../network.configs.js");

const stopFlow = async (ourContractAddress, userData) => {
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

  const options = {
    sender: await superSigner.getAddress(),
    receiver: ourContractAddress,
    superToken: networkConfigs[NETWORK_NAME].maticx,
    userData,
  };
  const createFlowOperation = sf.cfaV1.deleteFlow(options);

  await createFlowOperation.exec(superSigner);
};

const ourContractAddress = "0x5098FfE333036bf8038D850d3D2F925eDF915110";
const instanceId = "testInstanceId";
const userData = web3.eth.abi.encodeParameter("string", instanceId);

try {
  stopFlow(ourContractAddress, userData);
} catch (error) {
  console.log("Error:", error);
}
