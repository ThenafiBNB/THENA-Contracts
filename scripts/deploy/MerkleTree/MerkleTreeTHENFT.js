// // scripts/upgrade-box.js
const { ethers, upgrades } = require("hardhat");
const { deployContract } = require("../../shared/helpers");

async function main() {
    const airdropClaim = "0x491D87b3C30655009037Fe4dA76Db3dAb726B614" // AirdropClaimTheNFT.js
    await deployContract("MerkleTreeTHENFT", [ airdropClaim ]);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
