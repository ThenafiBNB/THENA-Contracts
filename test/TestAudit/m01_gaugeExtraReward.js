

const { expect } = require("chai");
const { erc20Abi } = require("../Abi.js")
const { ethers } = require("hardhat");


describe("test rewarder", function () {
   
    beforeEach(async () => {
        //await ethers.provider.send('evm_increaseTime', [5]);
        //await ethers.provider.send('evm_mine');

        const blockNumBefore = await ethers.provider.getBlockNumber();
        const blockBefore = await ethers.provider.getBlock(blockNumBefore);
        timestampBefore = blockBefore.timestamp;
    });

    it("Deploy contract", async function () {
        accounts = await ethers.getSigners();
        owner = accounts[0]
    
        
        usdc = await ethers.getContractAt(erc20Abi, "0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d")
        usdt = await ethers.getContractAt(erc20Abi, "0x55d398326f99059fF775485246999027B3197955")

        user = ethers.utils.getAddress("0x993Ae2b514677c7AC52bAeCd8871d2b362A9D693")
        depositor = ethers.utils.getAddress("0x8894E0a0c962CB723c1976a4421c95949bE2D4E3")

        
        // deploy gauge
        data = await ethers.getContractFactory("GaugeV2");
        // we care only of _token variable to let the ExtraRewarder read the total balance
        GaugeV2 = await data.deploy(usdc.address, usdc.address, usdt.address, owner.address, owner.address, owner.address, true);
        txDeployed = await GaugeV2.deployed();
        console.log("GaugeV2: ", GaugeV2.address)


        // deploy contract
        data = await ethers.getContractFactory("GaugeExtraRewarder");
        GaugeExtraRewarder = await data.deploy(usdc.address, GaugeV2.address);
        txDeployed = await GaugeExtraRewarder.deployed();
        console.log("GaugeExtraRewarder: ", GaugeExtraRewarder.address)
    });

    it("Set contracts ", async function () {
        // transfer ownership to depositor and set gaugerewarder to gauge
        await GaugeV2.setGaugeRewarder(GaugeExtraRewarder.address)
        await GaugeExtraRewarder.transferOwnership(depositor)
    
    
        // send 1k usdc as reward
        const rewardAmount = ethers.utils.parseEther("1000")
        await hre.network.provider.request({method: "hardhat_impersonateAccount",params: [depositor]});
        signer = await ethers.getSigner(depositor)
        await usdc.connect(signer).transfer(GaugeExtraRewarder.address, rewardAmount)
        await usdt.connect(signer).transfer(user, rewardAmount)
        await GaugeExtraRewarder.connect(signer).setDistributionRate(rewardAmount)
        await hre.network.provider.request({method: "hardhat_stopImpersonatingAccount",params: [depositor]});  
        console.log("Reward Per Second: ", await GaugeExtraRewarder.rewardPerSecond())
        console.log("lastDistributedTime: ", await GaugeExtraRewarder.lastDistributedTime())
        
    });

    it("User interaction", async function () {
       
        await hre.network.provider.request({method: "hardhat_impersonateAccount",params: [user]});
        signer = await ethers.getSigner(user)
        const amountToDeposit = ethers.utils.parseEther("1000")
        await usdt.connect(signer).approve(GaugeV2.address, amountToDeposit)

        // deposit for user 
        const bal_before = await usdc.balanceOf(user)
        await GaugeV2.connect(signer).depositAll()
        console.log("Pending Reward after first deposit: ", await GaugeExtraRewarder.pendingReward(user) /1e18)

        
        // user recall onReward after 3days
        await ethers.provider.send('evm_increaseTime', [3 * 86400]);
        await ethers.provider.send('evm_mine');
        console.log("Pending Reward after 3days: ", await GaugeExtraRewarder.pendingReward(user) /1e18)

        
        // user recall onReward after 6days
        await ethers.provider.send('evm_increaseTime', [3 * 86400]);
        await ethers.provider.send('evm_mine');
        console.log("Pending Reward after 6days: ", await GaugeExtraRewarder.pendingReward(user) /1e18)

        // user recall onReward after 7days
        await ethers.provider.send('evm_increaseTime', [86400]);
        await ethers.provider.send('evm_mine');
        console.log("Pending Reward after 7days: ", await GaugeExtraRewarder.pendingReward(user) /1e18)

        
        // user recall onReward after 14days
        await ethers.provider.send('evm_increaseTime', [7 * 86400]);
        await ethers.provider.send('evm_mine');
        console.log("Pending Reward after 14days: ", await GaugeExtraRewarder.pendingReward(user) /1e18)

        // user recall onReward after 21days
        await ethers.provider.send('evm_increaseTime', [7 * 86400]);
        await ethers.provider.send('evm_mine');
        console.log("Pending Reward after 21days: ", await GaugeExtraRewarder.pendingReward(user) /1e18)
        expect( await GaugeExtraRewarder.pendingReward(user)).to.above(ethers.utils.parseEther("999.99"))
        

        // withdraw to trigger the claim, check amounts and pending
        await GaugeV2.connect(signer).withdrawAll()
        expect( await GaugeExtraRewarder.pendingReward(user)).to.equal(0) 
        await ethers.provider.send('evm_increaseTime', [7 * 86400]);
        await ethers.provider.send('evm_mine');
        expect( await GaugeExtraRewarder.pendingReward(user)).to.equal(0) 

        const bal_after = await usdc.balanceOf(user)
        console.log("Start bal: ", bal_before /1e18)
        console.log("End Bal: ", bal_after /1e18)
        expect(bal_after.sub(bal_before)).to.be.above(ethers.utils.parseEther("999.99"))

        
        await hre.network.provider.request({method: "hardhat_stopImpersonatingAccount",params: [user]});  

        
    });



});

