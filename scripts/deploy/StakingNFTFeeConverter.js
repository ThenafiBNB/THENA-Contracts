// // scripts/upgrade-box.js
const { ethers, upgrades } = require("hardhat");
const { deployContract, contractAt, writeTmpAddresses, sendTxn } = require("../shared/helpers");
require("dotenv").config();

async function main() {
  // let contract =  await deployContract("StakingNFTFeeConverter",[
  //   process.env.WFTM,
  // ],"deploy StakingNFTFeeConverter");

  await sendTxn(contract.setPairFactory(process.env.PAIRFACTORYUPGRADEABLE), "StakingNFTFeeConverter.setPairFactory");
  await sendTxn(contract.setRouter(process.env.ROUTERV2), "StakingNFTFeeConverter.setRouter");
  await sendTxn(contract.setMasterchef(process.env.MASTERCHEF), "StakingNFTFeeConverter.setMasterchef");
  await sendTxn(contract.setKeeper(process.env.PUBLICKEY), "StakingNFTFeeConverter.setKeeper");

  // More
  // setPair
  let contract = await contractAt("StakingNFTFeeConverter", process.env.STAKINGCONVERTER);
  // await sendTxn(contract.setRouter(process.env.ROUTERV2), "StakingNFTFeeConverter.setRouter");
  await sendTxn(contract.setMasterchef(process.env.MASTERCHEF), "StakingNFTFeeConverter.setMasterchef");
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });