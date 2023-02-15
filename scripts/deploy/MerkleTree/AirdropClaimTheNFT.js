// // scripts/upgrade-box.js
const { ethers, upgrades } = require("hardhat");
const { deployProxyContract } = require("../../shared/helpers");

async function main() {
    const tokenAddress = ""

    await deployProxyContract("AirdropClaimTheNFT", [tokenAddress, process.env.VOTINGESCROW]);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });