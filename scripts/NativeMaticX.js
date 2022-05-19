const { Framework } = require("@superfluid-finance/sdk-core");
const { ethers } = require("hardhat");
<<<<<<< HEAD

const MATICxABI = require("../test/abi/ISETHABI");
=======
const ISETHJSON = require("../artifacts/@superfluid-finance/ethereum-contracts/contracts/interfaces/tokens/ISETH.sol/ISETH.json");
const ISETHJSONABI = ISETHJSON.abi;

/**************************************************************************
 * LOGIC WRAPPED
 *************************************************************************/
>>>>>>> e1af6abd8e9e671da3f620b931211b3eefb197ab

async function MATICUpgrade(amt) {
  const ALCHEMY_API_KEY_URL = process.env.ALCHEMY_API_KEY_URL;

  // let accounts = await ethers.getSigners();

<<<<<<< HEAD
    const httpProvider = new ethers.providers.JsonRpcProvider(
        ALCHEMY_API_KEY_URL
    );

    const sf = await Framework.create({
        chainId: 80001,
        provider: httpProvider,
        customSubgraphQueriesEndpoint: "",
        dataMode: "WEB3_ONLY",
    });

    const signer = sf.createSigner({
        privateKey: 
            process.env.PRIVATE_KEY,
        provider: httpProvider,
    });

   
    const maticxAddress = 0x96B82B65ACF7072eFEb00502F45757F254c2a0D4;
    maticx = new ethers.Contract(maticxAddress, MATICxABI , signer);

    //maticx = await Framework.loadNativeAssetSuperToken("MATICx")

    await maticx.upgradeByETH({value: amt})

    console.log(maticx);

    try {
        console.log(`upgrading $${amt} MATIC to maticx`);
        const amtToUpgrade = ethers.utils.parseEther(amt.toString());
        const upgradeOperation = maticx.upgrade({
            amount: amtToUpgrade.toString()
        });
        const upgradeTxn = await upgradeOperation.exec(signer);
        await upgradeTxn.wait().then(function (tx) {
            console.log(
                `
=======
  const httpProvider = new ethers.providers.JsonRpcProvider(
    ALCHEMY_API_KEY_URL
  );

  const sf = await Framework.create({
    chainId: 80001,
    provider: httpProvider,
    customSubgraphQueriesEndpoint: "",
    dataMode: "WEB3_ONLY",
  });

  const signer = sf.createSigner({
    privateKey: process.env.PRIVATE_KEY,
    provider: httpProvider,
  });

  const maticxAddress = "0x96B82B65ACF7072eFEb00502F45757F254c2a0D4";

  const maticx = new ethers.Contract(maticxAddress, ISETHJSONABI, signer);
  await maticx.connect(signer).upgradeByETH({ value: amt });

  console.log(maticx);

  try {
    console.log(`upgrading $${amt} MATIC to maticx`);
    const amtToUpgrade = ethers.utils.parseEther(amt.toString());
    const upgradeOperation = maticx.upgrade({
      amount: amtToUpgrade.toString(),
    });
    const upgradeTxn = await upgradeOperation.exec(signer);
    await upgradeTxn.wait().then(function (tx) {
      console.log(
        `
>>>>>>> e1af6abd8e9e671da3f620b931211b3eefb197ab
        Congrats - you've just upgraded MATIC to maticx!
      `
      );
    });
  } catch (error) {
    console.error(error);
  }
}

MATICUpgrade(20);
