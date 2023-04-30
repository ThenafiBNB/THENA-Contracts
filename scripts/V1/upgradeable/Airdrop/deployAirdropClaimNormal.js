const { ethers  } = require('hardhat');

const { ZERO_ADDRESS } = require("@openzeppelin/test-helpers/src/constants.js");



async function main () {

  accounts = await ethers.getSigners();
  owner = accounts[0]

  console.log('Deploying Contract...');

  const _token = ethers.utils.getAddress("0xF4C8E32EaDEC4BFe97E0F595AdD0f4450a863a11")
  const _ve = ethers.utils.getAddress("0xfBBF371C9B0B994EebFcC977CEf603F7f31c070D")

  /*data = await ethers.getContractFactory("AirdropClaim");
  AirdropClaim = await data.deploy(_token, _ve);
  txDeployed = await AirdropClaim.deployed();
  console.log("AirdropClaim: ", AirdropClaim.address)*/

  data = await ethers.getContractFactory("MerkleTree");
  MerkleTree = await data.deploy('0xf780FDE07fA56A881fB9566C7bDf9653471Ac70A');
  txDeployed = await MerkleTree.deployed();
  console.log("MerkleTree: ", MerkleTree.address)



}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
