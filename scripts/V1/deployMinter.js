const { ethers  } = require('hardhat');




async function main () {
    accounts = await ethers.getSigners();
    owner = accounts[0]

    console.log('Deploying Contract...');
    
    const ve = '0xd9693EfEbD93133e1cd406d6d516F2d610ADae7c'
    const voter =	'0xb594c0337580Bd06AFf6aB50973A7eF228616cbD'
    const rewDistro = '0x3eb5EF1eF1C85AF63d0d4B0856803732239196e9'

    data = await ethers.getContractFactory("Minter");
    Minter = await data.deploy(voter, ve, rewDistro);
    txDeployed = await Minter.deployed();
    console.log("Minter: ", Minter.address)

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
