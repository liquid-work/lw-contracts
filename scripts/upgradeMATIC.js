const { Framework } = require("@superfluid-finance/sdk-core");
const { ethers } = require("ethers");
const networkConfigs = require("../network.configs");
const MATICXABI = require("../abi/MATICX");

const { PRIVATE_KEY, ALCHEMY_API_URL_KEY, MATICX_ADDRESS, NETWORK_NAME } =
  process.env;

async function upgradeMATIC(amount) {
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

  const signer = sf.createSigner({
    privateKey: PRIVATE_KEY,
    provider: ethersProvider,
  });
  let maticx;
  maticx = new ethers.Contract(MATICX_ADDRESS, MATICXABI, signer);
  await maticx.connect(signer).upgradeByETH({ value: amount });
}
try {
  const amountToUpgrade = ethers.utils.parseEther("0.2");
  upgradeMATIC(amountToUpgrade);
} catch (error) {
  console.log("Error:", error);
}

async function downgradeToETH(amount) {
  const ethersProvider = new ethers.providers.JsonRpcProvider(
    ALCHEMY_API_URL_KEY,
    {
      name: NETWORK_NAME,
      chainId: networkConfigs[NETWORK_NAME],
    }
  );
  const sf = await Framework.create({
    networkName: NETWORK_NAME,
    provider: ethersProvider,
    chainId: networkConfigs[NETWORK_NAME],
  });

  const signer = sf.createSigner({
    privateKey: PRIVATE_KEY,
    provider: ethersProvider,
  });
  let maticx;
  maticx = new ethers.Contract(MATICX_ADDRESS, MATICXABI, signer);
  await maticx.connect(signer).downgradeToETH({ value: amount });
}
