// // scripts/upgrade-box.js
const { ethers, upgrades } = require("hardhat");
const { deployContract, contractAt, writeTmpAddresses, sendTxn } = require("../shared/helpers");
require("dotenv").config();

async function main() {
  let contract = await deployContract("MasterChef",
    [
      process.env.WFTM,
      process.env.THENIAN,
    ]);

  await sendTxn(contract.addKeeper([process.env.PUBLICKEY]), "MasterChef.addKeeper");
  await sendTxn(contract.setDistributionRate(ethers.utils.parseUnits("1000000000", 18)), "MasterChef.setDistributionRate");
  // more
  // hoặc dùng hàm setRewardPerSecond

}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });