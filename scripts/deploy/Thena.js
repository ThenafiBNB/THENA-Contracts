// // scripts/upgrade-box.js
const { ethers, upgrades } = require("hardhat");
const { deployContract, contractAt, sendTxn } = require("../shared/helpers");
require("dotenv").config();

async function main() {
  // await deployContract("Thena", []);

  const contract = await contractAt("Thena", process.env.THE);
  await sendTxn(contract.mint("0x595622cBd0Fc4727DF476a1172AdA30A9dDf8F43", ethers.utils.parseUnits("10000", 18)), "VoterV2_1.mint");
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });