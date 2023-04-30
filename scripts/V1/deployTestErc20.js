const { hexValue } = require('ethers/lib/utils');
const { ethers, upgrades } = require('hardhat');

const { erc20Abi } = require("../Abi.js")


async function main () {
    accounts = await ethers.getSigners();
    owner = accounts[0]

    console.log('Deploying Contract...');
    
    const name = "tBTC"
    const symbol = "tBTC"
    
    const data = await ethers.getContractFactory("ERC20Token");
    erc20TestContract = await data.deploy(name, symbol);
    txDeployed = await erc20TestContract.deployed();
    console.log("erc20TestContract Address: ", erc20TestContract.address)

    /*const _name = "tBNB"
    const _symbol = "tBNB"
    erc20TestContract2 = await data.deploy(_name, _symbol);
    txDeployed = await erc20TestContract2.deployed();
    console.log("erc20TestContract2 Address: ", erc20TestContract2.address)*/
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });