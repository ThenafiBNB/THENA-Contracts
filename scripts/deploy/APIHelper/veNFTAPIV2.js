// // scripts/upgrade-box.js
const { ethers, upgrades } = require("hardhat");
const { deployProxyContract, contractAt, sendTxn } = require("../../shared/helpers");

async function main() {
    // await deployProxyContract("veNFTAPI", [process.env.VOTERV2_1, process.env.REWARDSDISTRIBUTOR, process.env.PAIRAPIV2, process.env.PAIRFACTORYUPGRADEABLE]);

    const contract = await contractAt("veNFTAPI", process.env.VENFTAPIV2);
    // await sendTxn(contract.setPairFactory(process.env.PAIRFACTORYUPGRADEABLE), "veNFTAPI.setPairFactory");
    await sendTxn(contract.setPairAPI(process.env.PAIRAPIV2), "veNFTAPI.setPairAPI");
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });