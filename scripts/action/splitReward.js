// // scripts/upgrade-box.js
const { ethers, upgrades } = require("hardhat");
const { deployProxyContract, contractAt, sendTxn } = require("../shared/helpers");

async function main() {
    const contract = await contractAt("NFTSalesSplitter", process.env.NFTSALESSPLITTER)
    let txn = await sendTxn(contract.split({gasLimit: 6000000}), "NFTSalesSplitter.split");
    // console.log(txn);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });