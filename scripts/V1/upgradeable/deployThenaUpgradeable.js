const ether = require('@openzeppelin/test-helpers/src/ether');
const { ethers  } = require('hardhat');




async function main () {
    accounts = await ethers.getSigners();
    owner = accounts[0]

    console.log('Deploying Contract...');
    
    
    /*data = await ethers.getContractFactory("Thena");
    thena = await data.deploy();
    txDeployed = await thena.deployed();
    console.log("thena Address: ", thena.address)*/

    data = await ethers.getContractFactory("VeArtProxyUpgradeable");
    veArtProxy = await upgrades.deployProxy(data,[], {initializer: 'initialize'});
    txDeployed = await veArtProxy.deployed();
    console.log("veArtProxy Address: ", veArtProxy.address)

    const thena = ethers.utils.getAddress("0xF4C8E32EaDEC4BFe97E0F595AdD0f4450a863a11")

    data = await ethers.getContractFactory("VotingEscrow");
    veThena = await data.deploy(thena, veArtProxy.address);
    txDeployed = await veThena.deployed();
    console.log("veThena Address: ", veThena.address);

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
