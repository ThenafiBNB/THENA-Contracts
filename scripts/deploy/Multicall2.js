// // scripts/upgrade-box.js
const { ethers, upgrades } = require("hardhat");
const { deployContract, contractAt, writeTmpAddresses } = require("../shared/helpers");
const { bigNumberify } = require("../shared/utilities");
require("dotenv").config();

async function main() {
  await deployContract("Multicall2", []);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });