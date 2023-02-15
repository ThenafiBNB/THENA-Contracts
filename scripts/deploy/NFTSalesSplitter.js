const { ethers, upgrades } = require("hardhat");
const { deployProxyContract, contractAt, writeTmpAddresses } = require("../shared/helpers");
require("dotenv").config();

async function main() {
  await deployProxyContract("NFTSalesSplitter",
    [
      process.env.WFTM,
      process.env.STAKINGCONVERTER,
      process.env.ROYALTIES
    ], "deploy NFTSalesSplitter");
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });