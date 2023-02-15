// // scripts/upgrade-box.js
const { ethers, upgrades } = require("hardhat");
const { deployContract } = require("../../shared/helpers");

async function main() {
    const tokenAddress = process.env.THE

    await deployContract("AirdropClaim", [tokenAddress, process.env.VOTINGESCROW]);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });