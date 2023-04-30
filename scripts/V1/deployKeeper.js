const ether = require('@openzeppelin/test-helpers/src/ether');
const { ethers  } = require('hardhat');




async function main () {

  accounts = await ethers.getSigners();
  owner = accounts[0]

  console.log('Deploying Contract...');
  
  const minter = ethers.utils.getAddress("0xd478081C307Cf86218c0D88cC8ED11a0f1271780")
  const voter = ethers.utils.getAddress("0xb594c0337580Bd06AFf6aB50973A7eF228616cbD")
   

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
