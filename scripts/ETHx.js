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
        networkName: "kovan",
        provider: customHttpProvider
    });

    const signer = sf.createSigner({
        privateKey: process.env.PRIVATE_KEY,
        provider: customHttpProvider
    });

    //ETHx address on kovan
    //the below code will work on MATICx on mumbai/polygon as well
    const ETHxAddress = 0xdd5462a7db7856c9128bc77bd65c2919ee23c6e1;

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
        Congrats - you've just upgraded ETH to ETHx!
      `
            );
        });
    } catch (error) {
        console.error(error);
    }
    
};

ethUpgrade(2);

