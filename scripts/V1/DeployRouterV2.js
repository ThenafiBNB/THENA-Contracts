const { ethers  } = require('hardhat');




async function main () {
    accounts = await ethers.getSigners();
    owner = accounts[0]

    console.log('Deploying Contract...');

    const pairFactory = '0xAFD89d21BdB66d00817d4153E055830B1c2B3970'
    const wBNB = '0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c'

    data = await ethers.getContractFactory("RouterV2");
    router = await data.deploy(pairFactory, wBNB);

    txDeployed = await router.deployed();
    console.log("router: ", router.address)
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
