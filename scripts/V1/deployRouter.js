const { ethers  } = require('hardhat');




async function main () {
    accounts = await ethers.getSigners();
    owner = accounts[0]

    console.log('Deploying Contract...');

    const pairFactory = '0x27DfD2D7b85e0010542da35C6EBcD59E45fc949D'
    const wBNB = '0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c'

    data = await ethers.getContractFactory("Router");
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
