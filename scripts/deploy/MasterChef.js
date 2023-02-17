// // scripts/upgrade-box.js
const { ethers, upgrades } = require("hardhat");
const { deployContract, contractAt, writeTmpAddresses, sendTxn } = require("../shared/helpers");
require("dotenv").config();

async function main() {
  // let contract = await deployContract("MasterChef",
  //   [
  //     process.env.WFTM,
  //     process.env.THENIAN,
  //   ]);

  let contract = await contractAt("MasterChef", process.env.MASTERCHEF);

  await sendTxn(contract.addKeeper([process.env.PUBLICKEY]), "MasterChef.addKeeper");
  // QUAN TRỌNG CẦN staking fee convert
  await sendTxn(contract.addKeeper([process.env.STAKINGCONVERTER]), "MasterChef.addKeeper");
  await sendTxn(contract.setDistributionRate(ethers.utils.parseUnits("10", 18)), "MasterChef.setDistributionRate");
  // console.log(await contract.isKeeper(process.env.PUBLICKEY));
  // more
  // hoặc dùng hàm setRewardPerSecond

}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });