// // scripts/upgrade-box.js
const { ethers, upgrades } = require("hardhat");
const { deployProxyContract } = require("../shared/helpers");

async function main() {
    await deployProxyContract("MinterUpgradeable",
        [
            process.env.VOTERV2_1,
            process.env.VOTINGESCROW,
            process.env.REWARDSDISTRIBUTOR,
        ], "deploy MinterUpgradeable");

    // More
    // _initialize
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
