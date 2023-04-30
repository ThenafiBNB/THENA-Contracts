const { ethers  } = require('hardhat');

const { ZERO_ADDRESS } = require("@openzeppelin/test-helpers/src/constants.js");



async function main () {

  accounts = await ethers.getSigners();
  owner = accounts[0]

  console.log('Deploying Contract...');

  const _token = ethers.utils.getAddress("0xF4C8E32EaDEC4BFe97E0F595AdD0f4450a863a11")
  const _ve = ethers.utils.getAddress("0xfBBF371C9B0B994EebFcC977CEf603F7f31c070D")

  /*data = await ethers.getContractFactory("AirdropClaimTheNFT");
  airdropTheNFT = await data.deploy(_token, _ve);
  txDeployed = await airdropTheNFT.deployed();
  console.log("airdropTheNFT: ", airdropTheNFT.address)*/

  data = await ethers.getContractFactory("MerkleTreeTHENFT");
  merkleTreeTHENFT = await data.deploy('0xf04ca87Fe55f413b027cE01d8c9DCd662495Fed4');
  txDeployed = await merkleTreeTHENFT.deployed();
  console.log("MerkleTreeTHENFT: ", merkleTreeTHENFT.address)



}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
