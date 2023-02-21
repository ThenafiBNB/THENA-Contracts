// // scripts/upgrade-box.js
const { ethers, upgrades } = require("hardhat");
const { deployContract, contractAt, writeTmpAddresses, sendTxn } = require("../shared/helpers");
require("dotenv").config();

async function main() {
    // let contract = await deployContract("Royalties",
    //   [
    //     process.env.WFTM,
    //     process.env.THENIAN,
    //   ], "deploy Royalties");

    let contract = await contractAt("Royalties", process.env.ROYALTIES);
    // Quan trọng
    await sendTxn(contract.setDepositor(process.env.NFTSALESSPLITTER), "Royalties.setDepositor");
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
