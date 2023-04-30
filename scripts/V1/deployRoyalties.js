const { ethers  } = require('hardhat');




async function main () {

  accounts = await ethers.getSigners();
  owner = accounts[0]

  console.log('Deploying Contract...');

  const wbnb = ethers.utils.getAddress("0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c") 
  const nft = ethers.utils.getAddress("0x2Af749593978CB79Ed11B9959cD82FD128BA4f8d")

  data = await ethers.getContractFactory("Royalties");
  Royalties = await data.deploy(wbnb, nft);
  txDeployed = await Royalties.deployed();
  console.log("Royalties: ", Royalties.address)


}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
