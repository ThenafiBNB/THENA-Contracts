// // scripts/upgrade-box.js
const { ethers, upgrades } = require("hardhat");
const { deployProxyContract, contractAt } = require("../../shared/helpers");

async function main() {
    const voterContract = await contractAt("VoterV2_1", process.env.VOTERV2_1)
    console.log(await voterContract._ve()) // 0x428382e23784377456A4864a40AB0C99444E57c0
    const rewardDisContract = await contractAt("RewardsDistributor", process.env.REWARDSDISTRIBUTOR)
    console.log(await rewardDisContract.voting_escrow()) // 0x3391D0f6E397e82EB01c7C7f1A0b34E8B49f82E7
    await deployProxyContract("veNFTAPI", [process.env.VOTERV2_1, process.env.REWARDSDISTRIBUTOR, process.env.PAIRAPIV2, process.env.PAIRFACTORY]);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });