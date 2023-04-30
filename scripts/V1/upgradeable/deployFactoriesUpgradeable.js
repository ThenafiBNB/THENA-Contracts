const { ethers  } = require('hardhat');

const { ZERO_ADDRESS } = require("@openzeppelin/test-helpers/src/constants.js");



async function main () {

  accounts = await ethers.getSigners();
  owner = accounts[0]

  console.log('Deploying Contract...');

  /*data = await ethers.getContractFactory("BribeFactoryUpgradeable");
  bribeFactory = await upgrades.deployProxy(data,[], {initializer: 'initialize'});
  txDeployed = await bribeFactory.deployed();
  console.log("BribeFactoryUpgradeable: ", bribeFactory.address)

  data = await ethers.getContractFactory("WrappedExternalBribeFactoryUpgradeable");
  wrappedbribeFactory = await upgrades.deployProxy(data,[ZERO_ADDRESS], {initializer: 'initialize'});
  txDeployed = await wrappedbribeFactory.deployed();
  console.log("wrappedbribeFactory: ", wrappedbribeFactory.address)*/

  data = await ethers.getContractFactory("PairFactoryUpgradeable");
  pairFactory = await upgrades.deployProxy(data,[], {initializer: 'initialize'});
  txDeployed = await pairFactory.deployed();
  console.log("pairFactory: ", pairFactory.address)

 /* data = await ethers.getContractFactory("GaugeFactoryUpgradeable");
  gaugeFactory = await upgrades.deployProxy(data,[], {initializer: 'initialize'});
  txDeployed = await gaugeFactory.deployed();
  console.log("gaugeFactory: ", gaugeFactory.address)*/

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
