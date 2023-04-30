const { ethers  } = require('hardhat');




async function main () {
    accounts = await ethers.getSigners();
    owner = accounts[0]

    console.log('Deploying Contract...');
    
    const ve = '0xfBBF371C9B0B994EebFcC977CEf603F7f31c070D'
    const voter =	'0x62ee96e6365ab515ec647c065c2707d1122d7b26'
    const rewDistro = '0xE9fE83aA430Ace4b703C299701142f9dFdde730E'

    data = await ethers.getContractFactory("MinterUpgradeable");
    input = [voter, ve, rewDistro]
    minter = await upgrades.deployProxy(data,input, {initializer: 'initialize'});
    console.log("Minter: ", minter.address)

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
