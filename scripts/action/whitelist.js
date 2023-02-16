// // scripts/upgrade-box.js
const { ethers, upgrades } = require("hardhat");
const { deployProxyContract, contractAt, sendTxn } = require("../shared/helpers");

async function main() {
    const voterV2_1 = await contractAt("VoterV2_1", process.env.VOTERV2_1)
    let txn = await sendTxn(voterV2_1.whitelist([process.env.THE, process.env.USDT, process.env.WFTM], {gasLimit: 6000000}), "pairFactory.createPair");
    // console.log(txn);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });