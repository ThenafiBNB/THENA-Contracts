const { ethers  } = require('hardhat');




async function main () {
    accounts = await ethers.getSigners();
    owner = accounts[0]

    console.log('Deploying Contract...');
    
    const ve = '0xfBBF371C9B0B994EebFcC977CEf603F7f31c070D'
    const pairFactory =	'0xAFD89d21BdB66d00817d4153E055830B1c2B3970'
    const gaugeFactory = '0xcFe13d138D6471b827528B077EADc9330B9Fad78'

    // deploy new bribe factory (old 0x4ffcf83FEAE8a44F61575722aefC2706E73c7770)
    data = await ethers.getContractFactory("BribeFactoryV2");
    console.log('deploying...')
    BribeFactoryV2 = await upgrades.deployProxy(data,['0x0000000000000000000000000000000000000000'], {initializer: 'initialize'});
    txDeployed = await BribeFactoryV2.deployed();
    console.log('deployed b fact: ', BribeFactoryV2.address)


    console.log('deploying...')
    data = await ethers.getContractFactory("VoterV2_1");
    input = [ve, pairFactory, gaugeFactory, BribeFactoryV2.address]
    voter = await upgrades.deployProxy(data,input, {initializer: 'initialize'});
    console.log("Voter: ", voter.address)

    

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
