
const { ethers  } = require('hardhat');




async function main () {

  accounts = await ethers.getSigners();
  owner = accounts[0]

  //------------------------------------------------------------------------------------------------------------
  data = await ethers.getContractFactory("NFTSalesSplitter");
  input = []
  NFTSalesSplitter = await upgrades.deployProxy(data,input, {initializer: 'initialize'});
  txDeployed = await NFTSalesSplitter.deployed();
  console.log("NFTSalesSplitter: ", NFTSalesSplitter.address)
   
  //------------------------------------------------------------------------------------------------------------
  data = await ethers.getContractFactory("NFTSplitAutomation");
  input = [NFTSalesSplitter.address,'0x0000000000000000000000000000000000000000']
  NFTSplitAutomation = await upgrades.deployProxy(data,input, {initializer: 'initialize'});
  txDeployed = await NFTSplitAutomation.deployed();
  console.log("NFTSplitAutomation: ", NFTSplitAutomation.address) 
  
  //------------------------------------------------------------------------------------------------------------        
  data = await ethers.getContractFactory("EpochNFTSplitManager");
  input = [NFTSplitAutomation.address, NFTSplitAutomation.address]
  EpochNFTSplitManager = await upgrades.deployProxy(data,input, {initializer: 'initialize'});
  txDeployed = await EpochNFTSplitManager.deployed();
  console.log("EpochNFTSplitManager: ", EpochNFTSplitManager.address)  

  
  /*await NFTSplitAutomation.setCaller(EpochNFTSplitManager.address)
  await NFTSalesSplitter.setSplitter(NFTSplitAutomation.address, true)

  royaltiesContract = await ethers.getContractAt("contracts/Royalties.sol:Royalties", ethers.utils.getAddress("0xbe3B34b69b9d7a4A919A7b7da1ae34061e46c49D"));
  await royaltiesContract.setDepositor(NFTSalesSplitter.address)*/


}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
