const { ethers  } = require('hardhat');




async function main () {
    accounts = await ethers.getSigners();
    owner = accounts[0]

    console.log('Deploying Contract...');
    
    const ve = '0xd9693EfEbD93133e1cd406d6d516F2d610ADae7c'

    const pairFactory =	'0x27DfD2D7b85e0010542da35C6EBcD59E45fc949D'
    const gaugeFactory = '0xb02d192540F45efB40242769b4AE81dd7b1564F4'
    const bribeFactory = '0xC577c8276378D51a3e2ECea4d649A02B8e1fBab8'

    data = await ethers.getContractFactory("Voter");
    Voter = await data.deploy(ve, pairFactory, gaugeFactory, bribeFactory);
    txDeployed = await Voter.deployed();
    console.log("Voter: ", Voter.address)



}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
