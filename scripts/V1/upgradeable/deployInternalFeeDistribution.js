


const { ethers  } = require('hardhat');

const { ZERO_ADDRESS } = require("@openzeppelin/test-helpers/src/constants.js");



async function main () {

    accounts = await ethers.getSigners();
    owner = accounts[0]

    console.log('Deploying Contract...');

    data = await ethers.getContractFactory("BribesDistribution");
    BribesDistribution = await upgrades.deployProxy(data, ['0x62ee96e6365ab515ec647c065c2707d1122d7b26'], {initializer: 'initialize'});
    txDeployed = await BribesDistribution.deployed();
    console.log("BribesDistribution: ", BribesDistribution.address)


}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
