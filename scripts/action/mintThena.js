// // scripts/upgrade-box.js
const { ethers, upgrades } = require("hardhat");
const { deployProxyContract, contractAt, sendTxn } = require("../shared/helpers");

async function main() {
    const thena = await contractAt("Thena", process.env.THE)
    let txn = await sendTxn(thena.mint(process.env.PUBLICKEY, ethers.utils.parseUnits("100000000", 18),{gasLimit: 6000000}), "thena.mint");
    // console.log(txn);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });