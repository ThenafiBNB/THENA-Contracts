const ether = require('@openzeppelin/test-helpers/src/ether');
const { ethers  } = require('hardhat');




async function main () {

  accounts = await ethers.getSigners();
  owner = accounts[0]

  console.log('Deploying Contract...');
  
  const minter = ethers.utils.getAddress("0xb7ED8fA63BEa18986fa78D62F33497B1acDEa1D8")
  const voter = ethers.utils.getAddress("0xC3136b6b4a25eB16C5354aBFD22e16E7242cBE96")
   

  data = await ethers.getContractFactory("EpochController");
  EpochController = await data.deploy(minter, voter);
  txDeployed = await EpochController.deployed();
  console.log("EpochController: ", EpochController.address)
  

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
