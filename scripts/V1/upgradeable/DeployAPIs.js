const { ethers  } = require('hardhat');




async function main () {

  accounts = await ethers.getSigners();
  owner = accounts[0]
  
  const voter = ethers.utils.getAddress("0x62ee96e6365ab515ec647c065c2707d1122d7b26")
  const rewDistro = ethers.utils.getAddress("0xE9fE83aA430Ace4b703C299701142f9dFdde730E")
  const pairFactory = ethers.utils.getAddress("0xAFD89d21BdB66d00817d4153E055830B1c2B3970")
  const pairapi = ethers.utils.getAddress("0x7419477C03b0FEb9286F216b9d19E42f86B288b3");

  console.log('Deploying Contract...');

  /*data = await ethers.getContractFactory("PairAPI");
  input = [voter]
  pairApi = await upgrades.deployProxy(data,input, {initializer: 'initialize'});
  txDeployed = await pairApi.deployed();
  console.log("pairApi: ", pairApi.address)*/

  // deploy
  /*data = await ethers.getContractFactory("veNFTAPI");
  input = [voter, rewDistro, pairapi, pairFactory]
  venftapi = await upgrades.deployProxy(data,input, {initializer: 'initialize'});
  txDeployed = await venftapi.deployed();
  console.log("veNFTAPI: ", venftapi.address)*/

  // deploy
  data = await ethers.getContractFactory("RewardAPI");
  input = [voter]
  RewardAPI = await upgrades.deployProxy(data,input, {initializer: 'initialize'});
  txDeployed = await RewardAPI.deployed();
  console.log("RewardAPI: ", RewardAPI.address)


}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
