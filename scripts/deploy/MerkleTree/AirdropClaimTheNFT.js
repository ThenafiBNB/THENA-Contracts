// // scripts/upgrade-box.js
const { ethers, upgrades } = require("hardhat");
const { deployContract } = require("../../shared/helpers");

async function main() {
    const tokenAddress = process.env.THE

    await deployContract("AirdropClaimTheNFT", [ tokenAddress, process.env.VOTINGESCROW ]);
    // 0x491D87b3C30655009037Fe4dA76Db3dAb726B614
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
