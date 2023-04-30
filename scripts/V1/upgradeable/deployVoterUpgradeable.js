const { ethers  } = require('hardhat');




async function main () {
    accounts = await ethers.getSigners();
    owner = accounts[0]

    console.log('Deploying Contract...');
    
    const ve = '0xfBBF371C9B0B994EebFcC977CEf603F7f31c070D'
    const pairFactory =	'0xeDfA2A7eED6bB11876ae94462a7238A0c515bf08'
    const gaugeFactory = '0xcFe13d138D6471b827528B077EADc9330B9Fad78'
    const bribeFactory = '0xCB78f8d9DFb78CD43Bd2dC9Ffe75E39fBE7F2820'
    //const wbribeFactory = '0x4BF5A42202927B0263D2279E509b3dA05A6235bC'

    /*data = await ethers.getContractFactory("VoterUpgradeable");
    input = [ve, pairFactory, gaugeFactory, bribeFactory, wbribeFactory]
    voter = await upgrades.deployProxy(data,input, {initializer: 'initialize'});
    console.log("Voter: ", voter.address)*/

    /*data = await ethers.getContractFactory("VoterV2");
    input = [ve, pairFactory, gaugeFactory, bribeFactory]
    voter = await upgrades.deployProxy(data,input, {initializer: 'initialize'});
    console.log("Voter: ", voter.address)*/

    /*data = await ethers.getContractFactory("VoterV2");
    console.log('upgrading...')
    VoterV2 = await upgrades.upgradeProxy('0x43659f29356b7D84f6464957db06f1fD883A706B', data);
    console.log('upgraded...')*/

    data = await ethers.getContractFactory("VoterV2_1");
    input = [ve, pairFactory, gaugeFactory, bribeFactory]
    voter = await upgrades.deployProxy(data,input, {initializer: 'initialize'});
    console.log("Voter: ", voter.address)

    

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
