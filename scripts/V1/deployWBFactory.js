const { ethers  } = require('hardhat');




async function main () {

  accounts = await ethers.getSigners();
  owner = accounts[0]
    
  const voter = ethers.utils.getAddress("0xb594c0337580Bd06AFf6aB50973A7eF228616cbD")


  console.log('Deploying Contract...');
  data = await ethers.getContractFactory("WrappedExternalBribeFactory");
  wBribeFactory = await data.deploy(voter);
  txDeployed = await wBribeFactory.deployed();
  console.log("wBribeFactory: ", wBribeFactory.address)

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
