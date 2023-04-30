const { ethers  } = require('hardhat');

const { ZERO_ADDRESS } = require("@openzeppelin/test-helpers/src/constants.js");



async function main () {

  accounts = await ethers.getSigners();
  owner = accounts[0]

  console.log('Deploying Contract...');

  data = await ethers.getContractFactory("MerkleTreeC98");
  MerkleTreeC98 = await data.deploy();
  txDeployed = await MerkleTreeC98.deployed();
  console.log("MerkleTreeC98: ", MerkleTreeC98.address)



}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
