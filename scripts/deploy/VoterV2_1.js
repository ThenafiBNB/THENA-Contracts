// // scripts/upgrade-box.js
const { ethers, upgrades } = require("hardhat");
const { deployProxyContract, upgradeContractProxy, sendTxn, contractAt } = require("../shared/helpers");

async function main() {
  //deploy contract
  // await deployProxyContract("VoterV2_1",
  //   [
  //     process.env.VOTINGESCROW,
  //     process.env.PAIRFACTORYUPGRADEABLE,
  //     process.env.GAUGEFACTORYV2,
  //     process.env.BRIBEFACTORYV2,
  //   ]);

  //upgrade contract
  const contract = await upgradeContractProxy("VoterV2_1", process.env.VOTERV2_1);
  await sendTxn(contract.setVotingEscrow(process.env.VOTINGESCROW), "VoterV2_1.setVotingEscrow");
  await sendTxn(contract._initialize(
    [
      process.env.WFTM,
      process.env.THE,
    ],
    process.env.VOTERV2_1),
    "VoterV2_1._initialize");
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });