const { ethers  } = require('hardhat');

const { ZERO_ADDRESS } = require("@openzeppelin/test-helpers/src/constants.js");



async function main () {

    accounts = await ethers.getSigners();
    owner = accounts[0]
    

    console.log('Deploying Contracts...');
    
    
    data = await ethers.getContractFactory("GaugeExtraRewarder");
    GaugeExtraRewarder = await data.deploy('0xCdC3A010A3473c0C4b2cB03D8489D6BA387B83CD','0xe2C96A636C64322d444C58dE20e599B3ce9c6116');
    txDeployed = await GaugeExtraRewarder.deployed();
    console.log("GaugeExtraRewarder: ", GaugeExtraRewarder.address)




}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
