const { ethers  } = require('hardhat');

const { ZERO_ADDRESS } = require("@openzeppelin/test-helpers/src/constants.js");



async function main () {

    accounts = await ethers.getSigners();
    owner = accounts[0]
    

    console.log('Deploying Contracts...');
    
    ve = '0xfbbf371c9b0b994eebfcc977cef603f7f31c070d'
    pairFactory = '0xafd89d21bdb66d00817d4153e055830b1c2b3970'
    gaugeFactoryV2 = '0x2c788fe40a417612cb654b14a944cd549b5bf130'
    bribeFactoryV3 = '0xd50ceab3071c61c85d04bdd65feb12fee7c91375'


    data = await ethers.getContractFactory("VoterV3");
    input = [ve, pairFactory , gaugeFactoryV2,bribeFactoryV3]
    VoterV3 = await upgrades.deployProxy(data,input, {initializer: 'initialize'});
    txDeployed = await VoterV3.deployed();

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
