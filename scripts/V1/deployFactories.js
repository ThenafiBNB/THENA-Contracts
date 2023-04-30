const { ethers  } = require('hardhat');




async function main () {

  accounts = await ethers.getSigners();
  owner = accounts[0]

  console.log('Deploying Contract...');

  data = await ethers.getContractFactory("PairFactory");
  pairFactory = await data.deploy();
  txDeployed = await pairFactory.deployed();
  console.log("pairFactory: ", pairFactory.address)

  data = await ethers.getContractFactory("GaugeFactory");
  gaugeFactory = await data.deploy();
  txDeployed = await gaugeFactory.deployed();
  console.log("gaugeFactory: ", gaugeFactory.address)

  data = await ethers.getContractFactory("BribeFactory");
  bribeFactory = await data.deploy();
  txDeployed = await bribeFactory.deployed();
  console.log("bribeFactory: ", bribeFactory.address)

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
