const { ethers  } = require('hardhat');




async function main () {

  accounts = await ethers.getSigners();
  owner = accounts[0]


    
  const voter = ethers.utils.getAddress("0xb594c0337580Bd06AFf6aB50973A7eF228616cbD")
  const wbribe = ethers.utils.getAddress("0x99443A69d163aEabadcB00C3D04a0AC544De8962")
  const rewDistro = ethers.utils.getAddress("0x3eb5EF1eF1C85AF63d0d4B0856803732239196e9")
  const pairFactory = ethers.utils.getAddress("0x27DfD2D7b85e0010542da35C6EBcD59E45fc949D")
  const pairapi = ethers.utils.getAddress("0x2b481d200c6679840435c9997dc2499fda752e09");

  console.log('Deploying Contract...');

  /*data = await ethers.getContractFactory("PairAPI");
  pairApi = await data.deploy(voter,wbribe);
  txDeployed = await pairApi.deployed();
  console.log("pairApi: ", pairApi.address)*/


  /*data = await ethers.getContractFactory("veNFTAPI");
  veNFTAPI = await data.deploy(voter, rewDistro, pairApi.address, pairFactory);
  txDeployed = await veNFTAPI.deployed();
  console.log("veNFTAPI: ", veNFTAPI.address)*/

  // deploy
  data = await ethers.getContractFactory("veNFTAPI");
  input = [voter, rewDistro, pairapi, pairFactory]
  venftapi = await upgrades.deployProxy(data,input, {initializer: 'initialize'});
  txDeployed = await venftapi.deployed();
  console.log("veNFTAPI: ", venftapi.address)

  /*data = await ethers.getContractFactory("veNFTAPI");
  console.log('upgrading...')
  venftapi = await upgrades.upgradeProxy('0x190b166Edf30Baa8C1cdBF6653107Cec1020D36D', data);
  console.log('upgraded...')*/

  


}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
