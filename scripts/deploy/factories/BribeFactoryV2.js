// // scripts/upgrade-box.js
const { ethers, upgrades } = require("hardhat");
const { deployProxyContract, contractAt } = require("../../shared/helpers");

async function main() {
  await deployProxyContract("BribeFactoryV2", []);

  //set lai votev2_1
  const contract = await contractAt("BribeFactoryV2", process.env.BRIBEFACTORYV2);
  let tx = await contract.setVoter(process.env.VOTERV2_1);
  await tx.wait();
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });