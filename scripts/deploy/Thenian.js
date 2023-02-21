// // scripts/upgrade-box.js
const { ethers, upgrades } = require("hardhat");
const { deployContract, contractAt, sendTxn } = require("../shared/helpers");
const { bigNumberify } = require("../shared/utilities");
require("dotenv").config();

async function main() {
    // await deployContract("Thenian", [3000, ethers.utils.parseUnits("25", 17), 1669993200]);

    //Mint theNFT
    const contract = await contractAt("Thenian", process.env.THENIAN);
    await sendTxn(contract.reserveNFTs("0x595622cBd0Fc4727DF476a1172AdA30A9dDf8F43", 5), "VoterV2_1.mint");
    await sendTxn(contract.reserveNFTs("0x95ece85B9c5B9bAa46100BE2B1bd4fC64aBc696A", 15), "VoterV2_1.mint");
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
