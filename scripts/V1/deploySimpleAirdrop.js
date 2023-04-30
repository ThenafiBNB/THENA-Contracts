const { ethers  } = require('hardhat');




async function main () {

  accounts = await ethers.getSigners();
  owner = accounts[0]

  console.log('Deploying Contract...');
  
  /*data = await ethers.getContractFactory("SimpleAirdropFNFT2");
  SimpleAirdropFNFT = await data.deploy();
  txDeployed = await SimpleAirdropFNFT.deployed();
  console.log("SimpleAirdropFNFT: ", SimpleAirdropFNFT.address)*/

  
  data = await ethers.getContractFactory("SimpleAirdrop");
  SimpleAirdropDAO = await data.deploy();
  txDeployed = await SimpleAirdropDAO.deployed();
  console.log("SimpleAirdrop: ", SimpleAirdropDAO.address)


}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
