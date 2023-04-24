
const { expect } = require("chai");
const { erc20Abi, gammaProxyAbi, hypervisorAbi, CLRouterAbi, algebraRouterAbi } = require("./Abi.js")
const { ethers } = require("hardhat");
const { ZERO_ADDRESS } = require("@openzeppelin/test-helpers/src/constants.js");
const ether = require("@openzeppelin/test-helpers/src/ether.js");


// ext contract addresses
const gammaProxyAddress = ethers.utils.getAddress("0x6B3d98406779DDca311E6C43553773207b506Fa6")
const hyperUSDCUSDTAddress = ethers.utils.getAddress("0x5eeca990e9b7489665f4b57d27d92c78bc2afbf2")
const routerCL_address = ethers.utils.getAddress("0x327Dd3208f0bCF590A66110aCB6e5e6941A4EfA0")
const pairFactoryAddress = ethers.utils.getAddress("0xAFD89d21BdB66d00817d4153E055830B1c2B3970")
const minterAddress = ethers.utils.getAddress("0x86069feb223ee303085a1a505892c9d4bdbee996")
const algebraFactoryAddress = ethers.utils.getAddress("0x306F06C147f064A010530292A1EB6737c3e378e4")
const algebraRouterAddress = ethers.utils.getAddress("0x327Dd3208f0bCF590A66110aCB6e5e6941A4EfA0")
const usdcusdtPoolV3Address = ethers.utils.getAddress("0x1b9a1120a17617D8eC4dC80B921A9A1C50Caef7d")
const thenaDeployer = ethers.utils.getAddress("0x993Ae2b514677c7AC52bAeCd8871d2b362A9D693")

// users
const BigHolder = ethers.utils.getAddress("0x8894E0a0c962CB723c1976a4421c95949bE2D4E3") //used to add liquidity and swaps



describe("Thena - Deployment Section", function () {
   
    beforeEach(async () => {
        await ethers.provider.send('evm_increaseTime', [5]);
        await ethers.provider.send('evm_mine');

        const blockNumBefore = await ethers.provider.getBlockNumber();
        const blockBefore = await ethers.provider.getBlock(blockNumBefore);
        timestampBefore = blockBefore.timestamp;
    });

    it("Should load external contract for test (ERC20,LPs,..)", async function () {
        accounts = await ethers.getSigners();
        owner = accounts[0]
        
        thena = await ethers.getContractAt("contracts/Thena.sol:Thena", '0xF4C8E32EaDEC4BFe97E0F595AdD0f4450a863a11');
        vethena = await ethers.getContractAt("contracts/VotingEscrow.sol:VotingEscrow", '0xfBBF371C9B0B994EebFcC977CEf603F7f31c070D');


        gammaproxy = await ethers.getContractAt(gammaProxyAbi, gammaProxyAddress)
        algebrarouter = await ethers.getContractAt(algebraRouterAbi, algebraRouterAddress)
        hypervisor = await ethers.getContractAt(hypervisorAbi, hyperUSDCUSDTAddress)
        clrouter = await ethers.getContractAt(CLRouterAbi, routerCL_address)

        usdc = await ethers.getContractAt(erc20Abi, "0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d")
        usdt = await ethers.getContractAt(erc20Abi, "0x55d398326f99059fF775485246999027B3197955")
    
    });

    it("Should deploy GaugeExtraRewarder.sol", async function() {

        // deploy
        data = await ethers.getContractFactory("GaugeExtraRewarder");
        GaugeExtraRewarder = await data.deploy(usdt.address,'0xe2C96A636C64322d444C58dE20e599B3ce9c6116');
        txDeployed = await GaugeExtraRewarder.deployed();
        console.log("GaugeExtraRewarder: ", GaugeExtraRewarder.address)

        
        impersonator = BigHolder
        await hre.network.provider.request({method: "hardhat_impersonateAccount",params: [impersonator]});
        signer = await ethers.getSigner(impersonator)
        await usdt.connect(signer).transfer(GaugeExtraRewarder.address, ethers.utils.parseEther("100"))
        await hre.network.provider.request({method: "hardhat_stopImpersonatingAccount",params: [impersonator]});


        await GaugeExtraRewarder.setDistributionRate(ethers.utils.parseEther("100"))

        console.log(await usdc.balanceOf(GaugeExtraRewarder.address))

        await GaugeExtraRewarder.onReward(0, BigHolder, BigHolder, 0, 0);

        await GaugeExtraRewarder.stopRewarder()

        await GaugeExtraRewarder.onReward(0, BigHolder, BigHolder, 0, 0);

        await GaugeExtraRewarder.startRewarder()
        
        await GaugeExtraRewarder.onReward(0, BigHolder, BigHolder, 0, 0);


    });


    
    
});


/*
    impersonator = '0x993Ae2b514677c7AC52bAeCd8871d2b362A9D693'
    
    await hre.network.provider.request({method: "hardhat_impersonateAccount",params: [impersonator]});
    signer = await ethers.getSigner(impersonator)
    await hre.network.provider.request({method: "hardhat_stopImpersonatingAccount",params: [impersonator]});
    
    */

        
