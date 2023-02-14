// // scripts/upgrade-box.js
const { ethers, upgrades } = require("hardhat");
const { deployContract, contractAt, writeTmpAddresses, sendTxn } = require("../shared/helpers");
require("dotenv").config();

async function main() {
  let contract = await deployContract("Royalties",
    [
      process.env.WFTM,
      process.env.THENIAN,
    ], "deploy Royalties");

    await sendTxn(contract.setDepositor(process.env.PUBLICKEY), "Royalties.setDepositor");
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });