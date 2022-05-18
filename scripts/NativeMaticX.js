import { Framework } from "@superfluid-finance/sdk-core";
import { ethers } from "ethers";
const ISETHJSON = require("../artifacts/@superfluid-finance/ethereum-contracts/contracts/interfaces/tokens/ISETH.sol/ISETH.json");
const ISETHJSONABI = ISETHJSON.abi;


/**************************************************************************
* LOGIC WRAPPED
*************************************************************************/

async function MATICUpgrade(amt) {

    const ALCHEMY_API_KEY_URL = process.env.ALCHEMY_API_KEY_URL;

    // let accounts = await ethers.getSigners();

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


    const maticxAddress = "0x96B82B65ACF7072eFEb00502F45757F254c2a0D4";

    const maticx = new ethers.Contract(maticxAddress, ISETHJSONABI, signer);
    await maticx.connect(signer).upgradeByETH({ value: amt });


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
        Congrats - you've just upgraded MATIC to maticx!
      `
            );
        });
    } catch (error) {
        console.error(error);
    }

};

MATICUpgrade(20);
