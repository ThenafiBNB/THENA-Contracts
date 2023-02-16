// // scripts/upgrade-box.js
const { ethers, upgrades } = require("hardhat");
const { deployContract, contractAt, sendTxn } = require("../shared/helpers");
require("dotenv").config();

async function main() {
  // await deployContract("VotingEscrow",
  //   [
  //     process.env.THE,
  //     process.env.VE_ART_PROXY
  //   ]);

  const contract = await contractAt("VotingEscrow", process.env.VOTINGESCROW);
  await sendTxn(contract.isApprovedOrOwner("0x595622cBd0Fc4727DF476a1172AdA30A9dDf8F43", 1), "VoterV2_1.isApprovedOrOwner");
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });