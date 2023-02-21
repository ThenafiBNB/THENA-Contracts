// // scripts/upgrade-box.js
const { ethers, upgrades } = require("hardhat");
const { deployContract, contractAt, writeTmpAddresses } = require("../shared/helpers");
require("dotenv").config();

async function main() {
    await deployContract("RouterV2",
        [
            process.env.PAIRFACTORYUPGRADEABLE,
            process.env.WFTM,
        ], "deploy RouterV2");
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
