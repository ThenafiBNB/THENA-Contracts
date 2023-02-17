// // scripts/upgrade-box.js
const { ethers, upgrades } = require("hardhat");
const { deployProxyContract, sendTxn, contractAt } = require("../../shared/helpers");
require("dotenv").config();

async function main() {
  // let contract = await deployProxyContract("PairFactoryUpgradeable", []);

  const contract = await contractAt("PairFactoryUpgradeable", process.env.PAIRFACTORYUPGRADEABLE);
  await sendTxn(contract.setDibs(process.env.PUBLICKEY), "PairFactoryUpgradeable.setDibs");
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });