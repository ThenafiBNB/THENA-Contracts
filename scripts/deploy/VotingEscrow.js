// // scripts/upgrade-box.js
const { ethers, upgrades } = require("hardhat");
const { deployContract } = require("../shared/helpers");
require("dotenv").config();

async function main() {
  await deployContract("VotingEscrow",
    [
      process.env.THE,
      process.env.VE_ART_PROXY
    ]);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });