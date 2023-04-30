const { ethers  } = require('hardhat');




async function main () {
    accounts = await ethers.getSigners();
    owner = accounts[0]

    console.log('Deploying Contract...');
    
    
    data = await ethers.getContractFactory("Thena");
    thena = await data.deploy();
    txDeployed = await thena.deployed();
    console.log("thena Address: ", thena.address)

    data = await ethers.getContractFactory("VeArtProxy");
    veArtProxy = await data.deploy();
    txDeployed = await veArtProxy.deployed();
    console.log("veArtProxy Address: ", veArtProxy.address)

    data = await ethers.getContractFactory("VotingEscrow");
    veThena = await data.deploy(thena.address, veArtProxy.address);
    txDeployed = await veThena.deployed();
    console.log("veThena Address: ", veThena.address)

    data = await ethers.getContractFactory("RewardsDistributor");
    RewardsDistributor = await data.deploy(veThena.address);
    txDeployed = await RewardsDistributor.deployed();
    console.log("RewardsDistributor Address: ", RewardsDistributor.address)


}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
