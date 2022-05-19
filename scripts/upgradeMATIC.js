require("dotenv").config();
const { Framework } = require("@superfluid-finance/sdk-core");
const { ethers, providers } = require("ethers");

const MATICXABI = require("../test/abi/MATICX");
const { PRIVATE_KEY_MUMBAI, ALCHEMY_API_KEY_URL, MATICX_ADDRESS_MUMBAI } =
  process.env;

async function MATICUpgrade(amt) {
  const httpProvider = new providers.AlchemyProvider(
    "matic",
    ALCHEMY_API_KEY_URL
  );

  const privateKeySigner = new ethers.Wallet(PRIVATE_KEY_MUMBAI, httpProvider);
  console.log("here");
  const sf = await Framework.create({
    chainId: 80001,
    provider: httpProvider,
  });
  const signer = sf.createSigner({
    signer: privateKeySigner,
    privateKey: PRIVATE_KEY_MUMBAI,
    provider: httpProvider,
  });

  const maticx = new ethers.Contract(MATICX_ADDRESS_MUMBAI, MATICXABI, signer);
  maticx.connect(signer).upgradeByETH({ value: amt });
}

MATICUpgrade(0.1);
