// // scripts/upgrade-box.js
const { ethers, upgrades } = require("hardhat");
const { deployContract, contractAt, writeTmpAddresses } = require("../shared/helpers");
require("dotenv").config();

async function main() {
  await deployContract("MasterChef",
    [
      process.env.WFTM,
      "điền address VoteV2_1",
      process.env.BRIBEFACTORYV2,
      "Thena Bribes: vAMM-BUSD/THE"
    ]);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });