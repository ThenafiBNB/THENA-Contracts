const { ethers  } = require('hardhat');

const { ZERO_ADDRESS } = require("@openzeppelin/test-helpers/src/constants.js");



async function main () {

    accounts = await ethers.getSigners();
    owner = accounts[0]

    // deployed on v1 
    const ve = ethers.utils.getAddress("0xfBBF371C9B0B994EebFcC977CEf603F7f31c070D")
    const pairFactory = ethers.utils.getAddress("0xAFD89d21BdB66d00817d4153E055830B1c2B3970")
    
    //const permissionRegistry = ethers.utils.getAddress("0xe3Db58904B868eFDECD374Ed4f7b75e2A0f3e0Eb")
    /*const gaugeFactoryV2 = ethers.utils.getAddress("0x2c788FE40A417612cb654b14a944cd549B5BF130")
    const bribeFactoryV3 = ethers.utils.getAddress("0xD50CEAB3071c61c85D04bDD65Feb12FEe7C91375")*/


    console.log('Deploying Contracts...');
    
    
    // PERMISSION REGISTRY
    data = await ethers.getContractFactory("PermissionsRegistry");
    PermissionsRegistry = await data.deploy();
    txDeployed = await PermissionsRegistry.deployed();
    console.log("PermissionsRegistry: ", PermissionsRegistry.address)

    // BRIBE FACTORY
    data = await ethers.getContractFactory("BribeFactoryV3");
    input = [ZERO_ADDRESS, PermissionsRegistry.address]
    BribeFactoryV3 = await upgrades.deployProxy(data,input, {initializer: 'initialize'});
    txDeployed = await BribeFactoryV3.deployed();
    console.log("BribeFactoryV3: ", BribeFactoryV3.address)

    // GAUGE FACTORY
    data = await ethers.getContractFactory("GaugeFactoryV2");
    input = [PermissionsRegistry.address]
    GaugeFactoryV2 = await upgrades.deployProxy(data,input, {initializer: 'initialize'});
    txDeployed = await GaugeFactoryV2.deployed();
    console.log("GaugeFactoryV2: ", GaugeFactoryV2.address)

    // GAUGE FACTORY _ CL
    data = await ethers.getContractFactory("GaugeFactoryV2_CL");
    input = [PermissionsRegistry.address, '0x993Ae2b514677c7AC52bAeCd8871d2b362A9D693']
    GaugeFactoryV2_CL = await upgrades.deployProxy(data,input, {initializer: 'initialize'});
    txDeployed = await GaugeFactoryV2_CL.deployed();
    console.log("GaugeFactoryV2_CL: ", GaugeFactoryV2_CL.address)


    // VOTER
    data = await ethers.getContractFactory("VoterV3");
    input = [ve, pairFactory , GaugeFactoryV2.address,BribeFactoryV3.address]
    VoterV3 = await upgrades.deployProxy(data,input, {initializer: 'initialize'});
    txDeployed = await VoterV3.deployed();
    console.log("VoterV3: ", VoterV3.address)

    




}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
