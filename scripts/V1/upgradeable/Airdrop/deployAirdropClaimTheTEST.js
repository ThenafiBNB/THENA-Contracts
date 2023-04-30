const { ethers  } = require('hardhat');

const { ZERO_ADDRESS } = require("@openzeppelin/test-helpers/src/constants.js");



async function main () {

  accounts = await ethers.getSigners();
  owner = accounts[0]

  console.log('Deploying Contract...');

  const _token = ethers.utils.getAddress("0x08132180AFc971ddFDEcD2d6034794E7F20D486D")
  const _ve = ethers.utils.getAddress("0xd9693EfEbD93133e1cd406d6d516F2d610ADae7c")

  data = await ethers.getContractFactory("AirdropClaimTheNFTTest");
  airdropTheNFT = await data.deploy(_token, _ve);
  txDeployed = await airdropTheNFT.deployed();
  console.log("airdropTheNFT: ", airdropTheNFT.address)

  data = await ethers.getContractFactory("MerkleTreeTHENFTTest");
  merkleTreeTHENFT = await data.deploy(airdropTheNFT.address);
  txDeployed = await merkleTreeTHENFT.deployed();
  console.log("MerkleTreeTHENFT: ", merkleTreeTHENFT.address)



}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
