const { ethers  } = require('hardhat');




async function main () {

  accounts = await ethers.getSigners();
  owner = accounts[0]

  console.log('Deploying Contract...');

  data = await ethers.getContractFactory("Governor");
  governor = await data.deploy();
  txDeployed = await governor.deployed();
  console.log("governor: ", governor.address)



}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
