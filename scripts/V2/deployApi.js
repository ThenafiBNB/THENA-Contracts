const { ethers  } = require('hardhat');

const { ZERO_ADDRESS } = require("@openzeppelin/test-helpers/src/constants.js");



async function main () {

    accounts = await ethers.getSigners();
    owner = accounts[0]

    const voter = ethers.utils.getAddress("0x3a1d0952809f4948d15ebce8d345962a282c4fcb")
    const rewDistro = ethers.utils.getAddress("0xE9fE83aA430Ace4b703C299701142f9dFdde730E")
    
   // deploy
   data = await ethers.getContractFactory("PairAPI");        
   input = [voter]
   PairAPI = await upgrades.deployProxy(data,input, {initializer: 'initialize'});
   txDeployed = await PairAPI.deployed();
   console.log("PairAPI: ", PairAPI.address)


   // deploy
   data = await ethers.getContractFactory("RewardAPI");        
   input = [voter]
   RewardAPI = await upgrades.deployProxy(data,input, {initializer: 'initialize'});
   txDeployed = await RewardAPI.deployed();
   console.log("RewardAPI: ", RewardAPI.address)

   // deploy
   data = await ethers.getContractFactory("veNFTAPI");        
   input = [voter, rewDistro, PairAPI.address]
   veNFTAPI = await upgrades.deployProxy(data,input, {initializer: 'initialize'});
   txDeployed = await veNFTAPI.deployed();
   console.log("veNFTAPI: ", veNFTAPI.address)

   /*const data = await ethers.getContractFactory('PairAPI');
   console.log('PairAPI...');
   await upgrades.upgradeProxy('0xE89080cEb6CAEb9Eba5a0d4Aa13686eFcB78A32E', data);
   console.log('PairAPI upgraded');*/
    

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
