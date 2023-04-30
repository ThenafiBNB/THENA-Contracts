const { ethers  } = require('hardhat');

const { ZERO_ADDRESS } = require("@openzeppelin/test-helpers/src/constants.js");



async function main () {

  accounts = await ethers.getSigners();
  owner = accounts[0]

  console.log('Deploying Contract...');

  data = await ethers.getContractFactory("EpochController");
  EpochController = await upgrades.deployProxy(data,[], {initializer: 'initialize'});
  txDeployed = await EpochController.deployed();
  console.log("EpochController: ", EpochController.address)

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
