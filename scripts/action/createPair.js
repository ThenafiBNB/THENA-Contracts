// // scripts/upgrade-box.js
const { ethers, upgrades } = require("hardhat");
const { deployProxyContract, contractAt, sendTxn } = require("../shared/helpers");

async function main() {
    const pairFactory = await contractAt("PairFactory", process.env.PAIRFACTORY)
    let txn = await sendTxn(pairFactory.createPair(process.env.THE, process.env.USDT, false, {gasLimit: 6000000}), "pairFactory.createPair");
    console.log(txn);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });