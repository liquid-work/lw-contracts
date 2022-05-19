const { Framework } = require("@superfluid-finance/sdk-core");
const { ethers } = require("hardhat");
const ethxABI = require("./config")

//where the Superfluid logic takes place
async function ethUpgrade(amt) {

    const ALCHEMY_API_KEY_URL = process.env.ALCHEMY_API_KEY_URL;

    const customHttpProvider = new ethers.providers.JsonRpcProvider(
        ALCHEMY_API_KEY_URL
    );
    const sf = await Framework.create({
        networkName: "kovan",
        provider: customHttpProvider
    });

    const signer = sf.createSigner({
        privateKey:
        "0xd2ebfb1517ee73c4bd3d209530a7e1c25352542843077109ae77a2c0213375f1",
        provider: customHttpProvider
    });

    //ETHx address on kovan
    //the below code will work on MATICx on mumbai/polygon as well
    const ETHxAddress = "0xdd5462a7db7856c9128bc77bd65c2919ee23c6e1";

    const ETHx = new ethers.Contract(ETHxAddress, ethxABI, customHttpProvider);

    try {
        console.log(`upgrading $${amt} ETH to ETHx`);
        const amtToUpgrade = ethers.utils.parseEther(amt.toString());
        const upgradeOperation = ETHx.upgrade({
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

ethUpgrade(2);

