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
  console.log(await contract.bribefactory());
  // await sendTxn(contract.whitelist(process.env.USDT), "VoterV2_1.whitelist");
  // await sendTxn(contract.vote(1, ["0xeFF810955BF332a094b9A1B17e3a8bc468407457"], [100]), "VoterV2_1.whitelist");
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });