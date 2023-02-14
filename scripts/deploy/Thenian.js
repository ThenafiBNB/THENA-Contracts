// // scripts/upgrade-box.js
const { ethers, upgrades } = require("hardhat");
const { deployContract, contractAt, writeTmpAddresses } = require("../shared/helpers");
const { bigNumberify } = require("../shared/utilities");
require("dotenv").config();

async function main() {
  await deployContract("Thenian", [3000, ethers.utils.parseUnits("25", 17), 1669993200]);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });