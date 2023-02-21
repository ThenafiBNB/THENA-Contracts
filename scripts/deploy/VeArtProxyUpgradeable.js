// // scripts/upgrade-box.js
const { ethers, upgrades } = require("hardhat");
const { deployProxyContract } = require("../shared/helpers");

async function main() {
    await deployProxyContract("VeArtProxyUpgradeable", []);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
