// // scripts/upgrade-box.js
const { ethers, upgrades } = require("hardhat");
const { deployProxyContract } = require("../shared/helpers");

async function main() {
  await deployProxyContract("VoterV2_1",
    [
      process.env.VE_THENA,
      process.env.PAIRFACTORYUPGRADEABLE,
      process.env.GAUGEFACTORYV2,
      process.env.BRIBEFACTORYV2,
    ]);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });