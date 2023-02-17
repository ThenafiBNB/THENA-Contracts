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
  const contract = await contractAt("VoterV2_1", process.env.VOTERV2_1);
  // await sendTxn(contract.whitelist(process.env.USDT), "VoterV2_1.whitelist");
  await sendTxn(contract.setMinter(process.env.PUBLICKEY), "VoterV2_1.setMinter");
  // await sendTxn(contract.vote(1, ["0xeFF810955BF332a094b9A1B17e3a8bc468407457", "0x33094b36d872897440dd93768375843b1Ac64Dfb"], [70, 30], { gasLimit: 6000000 }), "VoterV2_1.whitelist");
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });