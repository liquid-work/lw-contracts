const { Framework } = require("@superfluid-finance/sdk-core");
const { ethers } = require("hardhat");
const ethxABI = require("../test/abi/ETHxABI")

//where the Superfluid logic takes place
async function ethUpgrade(amt) {

    const ALCHEMY_API_KEY_URL = process.env.ALCHEMY_API_KEY_URL;

    const customHttpProvider = new ethers.providers.JsonRpcProvider(
        ALCHEMY_API_KEY_URL
    );

    const sf = await Framework.create({
        chainId: 80001,
        provider: customHttpProvider,
        customSubgraphQueriesEndpoint: "",
        dataMode: "WEB3_ONLY",
    });

    const signer = sf.createSigner({
        privateKey: process.env.PRIVATE_KEY,
        provider: customHttpProvider
    });

    //ETHx address on kovan
    //the below code will work on MATICx on mumbai/polygon as well
    const fDAIx = "0x5D8B4C2554aeB7e86F387B4d6c00Ac33499Ed01f";

    const ETHx = new ethers.Contract(fDAIx, ethxABI, customHttpProvider);
    console.log(ETHx);

    try {
        console.log(`upgrading $${amt} DAI to daix`);
        const amtToUpgrade = ethers.utils.parseEther(amt.toString());
        const upgradeOperation = ETHx.upgrade({
            amount: amtToUpgrade.toString()
        });
        const upgradeTxn = await upgradeOperation.exec(signer);
        await upgradeTxn.wait().then(function (tx) {
            console.log(
                `

        Congrats - you've just upgraded DAI to daix!
      `
      );
    });
  } catch (error) {
    console.error(error);
  }

   
   
}

ethUpgrade(2);

