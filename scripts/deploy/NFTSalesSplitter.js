// // scripts/upgrade-box.js
const { ethers, upgrades } = require("hardhat");
const { prototype } = require("mocha");
const { env } = require("process");
const { deployProxyContract, contractAt, writeTmpAddresses } = require("../shared/helpers");
const { bigNumberify } = require("../shared/utilities");
require("dotenv").config();

async function main() {
  await deployProxyContract("NFTSalesSplitter", [process.env.WFTM, process.env.STAKINGCONVERTER, process.env.ROYALTIES], "deploy NFTSalesSplitter");
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });