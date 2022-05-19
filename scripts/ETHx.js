const { Framework } = require("@superfluid-finance/sdk-core");
const ethxABI = require("../test/abi/ETHxABI")
const { ethers, providers } = require("ethers");


//where the Superfluid logic takes place
async function ethUpgrade(amt) {
  const provider = new providers.AlchemyProvider(
    "rinkeby",
    ALCHEMY_API_KEY_URL.process.env
  );
  const sf = await Framework.create({
    networkName: "rinkeby",
    provider: provider
  });

  const signer = sf.createSigner({
    privateKey:
      "5034f6fc81f0fb42429875413da341faf69888122913159b2aa15d3e98f37bb9",
    provider: provider
  });

  //ETHx address on kovan
  //the below code will work on MATICx on mumbai/polygon as well
  const ETHxAddress = "0xdd5462a7db7856c9128bc77bd65c2919ee23c6e1";

  const ETHx = new ethers.Contract(ETHxAddress, ethxABI, provider);

  try {
    console.log(`upgrading ${amt} ETH to ETHx`);

    const amtToUpgrade = ethers.utils.parseEther(amt.toString());
    const reciept = await ETHx.connect(signer).upgradeByETH({
      value: amtToUpgrade
    });
    await reciept.wait().then(function (tx) {
      console.log(
        `
        Congrats - you've just upgraded ETH to ETHx!
      `
      );
    });
  } catch (error) {
    console.error(error);
  }
}

ethUpgrade(2);