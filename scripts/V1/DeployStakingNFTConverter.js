const { ethers  } = require('hardhat');




async function main () {

  accounts = await ethers.getSigners();
  owner = accounts[0]

  console.log('Deploying Contract...');

  data = await ethers.getContractFactory("StakingNFTFeeConverter");
  StakingNFTFeeConverter = await data.deploy();
  txDeployed = await StakingNFTFeeConverter.deployed();
  console.log("StakingNFTFeeConverter: ", StakingNFTFeeConverter.address)  






}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
