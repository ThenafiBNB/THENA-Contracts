
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

/*

    This test unit has some commented section. Uncomment everything and then run test. Hardhat could fail to recognize function with same name.
    Hardhat could fail calls sometimes. Moving to Foundry in next release.

*/


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

    it("Should deploy PermissionsRegistry.sol", async function() {

        // deploy
        data = await ethers.getContractFactory("PermissionsRegistry");
        PermissionsRegistry = await data.deploy();
        txDeployed = await PermissionsRegistry.deployed();

        expect(await PermissionsRegistry.thenaTeamMultisig()).to.equal(owner.address);

        await PermissionsRegistry.setRoleFor(owner.address, "GOVERNANCE")
        expect(await PermissionsRegistry.hasRole(await PermissionsRegistry.__helper_stringToBytes("GOVERNANCE"), owner.address)).to.equal(true)
        await PermissionsRegistry.setRoleFor(owner.address, "VOTER_ADMIN")
        expect(await PermissionsRegistry.hasRole(await PermissionsRegistry.__helper_stringToBytes("VOTER_ADMIN"), owner.address)).to.equal(true)
        await PermissionsRegistry.setRoleFor(owner.address, "GAUGE_ADMIN")
        expect(await PermissionsRegistry.hasRole(await PermissionsRegistry.__helper_stringToBytes("GAUGE_ADMIN"), owner.address)).to.equal(true)
        await PermissionsRegistry.setRoleFor(owner.address, "BRIBE_ADMIN")
        expect(await PermissionsRegistry.hasRole(await PermissionsRegistry.__helper_stringToBytes("BRIBE_ADMIN"), owner.address)).to.equal(true)
        await PermissionsRegistry.setRoleFor(owner.address, "FEE_MANAGER")
        expect(await PermissionsRegistry.hasRole(await PermissionsRegistry.__helper_stringToBytes("FEE_MANAGER"), owner.address)).to.equal(true)
        await PermissionsRegistry.setRoleFor(owner.address, "CL_FEES_VAULT_ADMIN")
        expect(await PermissionsRegistry.hasRole(await PermissionsRegistry.__helper_stringToBytes("CL_FEES_VAULT_ADMIN"), owner.address)).to.equal(true)


    });

    it("Should deploy BribeFactoryV3.sol", async function() {

        // deploy
        data = await ethers.getContractFactory("BribeFactoryV3");
        input = [ZERO_ADDRESS, PermissionsRegistry.address]
        BribeFactoryV3 = await upgrades.deployProxy(data,input, {initializer: 'initialize'});

        txDeployed = await BribeFactoryV3.deployed();
        expect(await BribeFactoryV3.owner()).to.equal(owner.address);

    });

    
    it("Should deploy GaugeFactoryV2.sol", async function() {

        // deploy
        data = await ethers.getContractFactory("GaugeFactoryV2");
        input = [PermissionsRegistry.address]
        GaugeFactoryV2 = await upgrades.deployProxy(data,input, {initializer: 'initialize'});

        txDeployed = await GaugeFactoryV2.deployed();
        expect(await GaugeFactoryV2.owner()).to.equal(owner.address);

    });

    it("Should deploy GaugeFactoryV2_CL.sol", async function() {

        // deploy
        data = await ethers.getContractFactory("GaugeFactoryV2_CL");
        input = [PermissionsRegistry.address, thenaDeployer]
        GaugeFactoryV2_CL = await upgrades.deployProxy(data,input, {initializer: 'initialize'});

        txDeployed = await GaugeFactoryV2_CL.deployed();
        //console.log("gaugeFactory: ", GaugeFactoryV2_CL.address)
        expect(await GaugeFactoryV2_CL.owner()).to.equal(owner.address);

    });

    
    it("Should deploy Voter.sol", async function() {

        // deploy
        data = await ethers.getContractFactory("VoterV3");
        input = [vethena.address, pairFactoryAddress , GaugeFactoryV2.address,BribeFactoryV3.address]
        voter = await upgrades.deployProxy(data,input, {initializer: 'initialize'});

        txDeployed = await voter.deployed();
        expect(await voter.owner()).to.equal(owner.address);
    });
    
   
    
    it("Should set all", async function() {
        //voter
        await voter._init([usdc.address, usdt.address], PermissionsRegistry.address, minterAddress)
        expect(await voter.isWhitelisted(usdc.address)).to.equal(true)
        expect(await voter.permissionRegistry()).to.equal(PermissionsRegistry.address)
        await voter.addFactory(algebraFactoryAddress, GaugeFactoryV2_CL.address)
        expect(await voter.isFactory(algebraFactoryAddress)).to.equal(true)

        // bribe factory
        await BribeFactoryV3.setVoter(voter.address)
        expect(await BribeFactoryV3.voter()).to.equal(voter.address)

    });

    
});


describe("Thena - LP Section", function () {
   
    beforeEach(async () => {
        await ethers.provider.send('evm_increaseTime', [5]);
        await ethers.provider.send('evm_mine');

        const blockNumBefore = await ethers.provider.getBlockNumber();
        const blockBefore = await ethers.provider.getBlock(blockNumBefore);
        timestampBefore = blockBefore.timestamp;
    });

      
    it("Should add Liquidity", async function () {

        impersonator = BigHolder
        await hre.network.provider.request({method: "hardhat_impersonateAccount",params: [impersonator],});
        signer = await ethers.getSigner(impersonator)


        const amount0 = ethers.utils.parseEther("10");
        const amount1 = ethers.utils.parseEther("10");
        const amountIn0 =  await gammaproxy.getDepositAmount(hypervisor.address, usdc.address, amount0)
        const amountIn1 =  await gammaproxy.getDepositAmount(hypervisor.address, usdt.address, amount1)
        //console.log("get depositAmount0:", amountIn0) // [startValue, EndValue]
        //console.log("get depositAmount1:", amountIn1)

        expect(await hypervisor.balanceOf(impersonator)).to.be.equal(0)

        await usdc.connect(signer).approve(hyperUSDCUSDTAddress, ethers.utils.parseEther("100"))
        await usdt.connect(signer).approve(hyperUSDCUSDTAddress, ethers.utils.parseEther("100"))
        await gammaproxy.connect(signer).deposit(amountIn0[0], amount0, impersonator, hyperUSDCUSDTAddress ,[0,0,0,0])

        LPBalanceDeposited = await hypervisor.balanceOf(impersonator)
        expect(LPBalanceDeposited).to.be.above(0)
        //console.log('Balance: ', LPBalanceDeposited)
                
        await hre.network.provider.request({method: "hardhat_stopImpersonatingAccount",params: [impersonator],});
        

    });
});

describe("Thena - Gauge Section", function () {

    beforeEach(async () => {
        await ethers.provider.send('evm_increaseTime', [5]);
        await ethers.provider.send('evm_mine');

        const blockNumBefore = await ethers.provider.getBlockNumber();
        const blockBefore = await ethers.provider.getBlock(blockNumBefore);
        timestampBefore = blockBefore.timestamp;
    });


    it("Should create Gauge for Concentrated liqudity", async function () {

        await voter.createGauges([hypervisor.address], [1])
        const gaugeAddress = await voter.gauges(hypervisor.address)
        const ext_bribeAddress = await voter.external_bribes(gaugeAddress)
        const int_bribeAddress = await voter.internal_bribes(gaugeAddress)
        expect(gaugeAddress).not.to.equal(ZERO_ADDRESS)
        expect(ext_bribeAddress).not.to.equal(ZERO_ADDRESS)
        expect(int_bribeAddress).not.to.equal(ZERO_ADDRESS)

        
        gauge = await ethers.getContractAt("contracts/GaugeV2_CL.sol:GaugeV2_CL", gaugeAddress);
        feevault = await ethers.getContractAt("contracts/CLFeesVault.sol:CLFeesVault", await gauge.feeVault());
        ext_bribe = await ethers.getContractAt("contracts/Bribes.sol:Bribe", ext_bribeAddress);
        int_bribe = await ethers.getContractAt("contracts/Bribes.sol:Bribe", int_bribeAddress);
        //console.log("symbol: ", await int_bribe.TYPE())


    });

    it("Should deploy extra rewarder for hypervisor gauge", async function() {

        // deploy
        data = await ethers.getContractFactory("GaugeExtraRewarder");
        GaugeExtraRewarder = await data.deploy(usdc.address, gauge.address)

        txDeployed = await GaugeExtraRewarder.deployed();
        expect(await GaugeExtraRewarder.owner()).to.equal(owner.address);

        
        await GaugeFactoryV2_CL.setGaugeRewarder([gauge.address], [GaugeExtraRewarder.address])

        impersonator = BigHolder
        await hre.network.provider.request({method: "hardhat_impersonateAccount",params: [impersonator]});
        signer = await ethers.getSigner(impersonator)       
        const amountIn = ethers.utils.parseEther("10000")
        expect(await usdc.balanceOf(GaugeExtraRewarder.address)).to.be.equal(0)
        await usdc.connect(signer).transfer(GaugeExtraRewarder.address,amountIn)
        expect(await usdc.balanceOf(GaugeExtraRewarder.address)).to.be.equal(amountIn)   
        await hre.network.provider.request({method: "hardhat_stopImpersonatingAccount",params: [impersonator]});

        await GaugeExtraRewarder.setDistributionRate(ethers.utils.parseEther("0.015"))

    });


    it("Should create 2 Gauge Classic", async function () {
        pool1 = '0x34B897289fcCb43c048b2Cea6405e840a129E021'
        await voter.createGauges(['0x34B897289fcCb43c048b2Cea6405e840a129E021'], [0])
        const gaugeAddress = await voter.gauges(hypervisor.address)
        const ext_bribeAddress = await voter.external_bribes(gaugeAddress)
        const int_bribeAddress = await voter.internal_bribes(gaugeAddress)
        expect(gaugeAddress).not.to.equal(ZERO_ADDRESS)
        expect(ext_bribeAddress).not.to.equal(ZERO_ADDRESS)
        expect(int_bribeAddress).not.to.equal(ZERO_ADDRESS)

        gauge_classic = await ethers.getContractAt("contracts/GaugeV2_CL.sol:GaugeV2_CL", gaugeAddress);
        //feevault_classic = await ethers.getContractAt("contracts/CLFeesVault.sol:CLFeesVault", await gauge.feeVault());
        ext_bribe_classic = await ethers.getContractAt("contracts/Bribes.sol:Bribe", ext_bribeAddress);
        int_bribe_classic = await ethers.getContractAt("contracts/Bribes.sol:Bribe", int_bribeAddress);

        pool2 = '0xF760185e1a55805c8ea928DA7f942aF2E7835757'
        await voter.createGauges(['0xF760185e1a55805c8ea928DA7f942aF2E7835757'], [0])
        const gaugeAddress2 = await voter.gauges(hypervisor.address)
        const ext_bribeAddress2 = await voter.external_bribes(gaugeAddress)
        const int_bribeAddress2 = await voter.internal_bribes(gaugeAddress)
        expect(gaugeAddress).not.to.equal(ZERO_ADDRESS)
        expect(ext_bribeAddress).not.to.equal(ZERO_ADDRESS)
        expect(int_bribeAddress).not.to.equal(ZERO_ADDRESS)

        gauge_classic2 = await ethers.getContractAt("contracts/GaugeV2_CL.sol:GaugeV2_CL", gaugeAddress);
        //feevault_classic = await ethers.getContractAt("contracts/CLFeesVault.sol:CLFeesVault", await gauge.feeVault());
        ext_bribe_classic2 = await ethers.getContractAt("contracts/Bribes.sol:Bribe", ext_bribeAddress);
        int_bribe_classic2 = await ethers.getContractAt("contracts/Bribes.sol:Bribe", int_bribeAddress);


    });



    it("Should deposit into the gauge", async function () {

        impersonator = BigHolder
        await hre.network.provider.request({method: "hardhat_impersonateAccount",params: [impersonator]});
        signer = await ethers.getSigner(impersonator)       

        expect(await gauge.balanceOf(impersonator)).to.be.equal(0)
        await hypervisor.connect(signer).approve(gauge.address, LPBalanceDeposited)
        await gauge.connect(signer).depositAll()
        expect(await gauge.balanceOf(impersonator)).to.be.above(0)
        
        
        await hre.network.provider.request({method: "hardhat_stopImpersonatingAccount",params: [impersonator]});
    })


    it("Should send fees to vault", async function () {

        impersonator = BigHolder
        await hre.network.provider.request({method: "hardhat_impersonateAccount",params: [impersonator]});
        signer = await ethers.getSigner(impersonator)       
        const amountIn = ethers.utils.parseEther("100")
        expect(await usdc.balanceOf(feevault.address)).to.be.equal(0)
        expect(await usdt.balanceOf(feevault.address)).to.be.equal(0)
        await usdc.connect(signer).transfer(feevault.address,amountIn)
        await usdt.connect(signer).transfer(feevault.address, amountIn)
        expect(await usdc.balanceOf(feevault.address)).to.be.equal(amountIn)
        expect(await usdt.balanceOf(feevault.address)).to.be.equal(amountIn)
        await usdc.connect(signer).transfer(feevault.address,amountIn)
                
        
        await hre.network.provider.request({method: "hardhat_stopImpersonatingAccount",params: [impersonator]});
    })

    it("Should claim fees from vault", async function () {
        
        //console.log(await usdc.balanceOf(int_bribe.address) /1e18)
        //console.log(await usdc.balanceOf(thenaDeployer) /1e18)
        expect(await usdc.balanceOf(int_bribe.address)).to.equal(0)
        await voter.distributeFees([gauge.address])
        expect(await usdc.balanceOf(int_bribe.address)).to.above(0)
        //console.log(await usdc.balanceOf(int_bribe.address)/1e18)
        //console.log(await usdc.balanceOf(thenaDeployer)/1e18)
        
    })

    
});

describe("Thena - Voter Section", function () {

    beforeEach(async () => {
        await ethers.provider.send('evm_increaseTime', [5]);
        await ethers.provider.send('evm_mine');

        const blockNumBefore = await ethers.provider.getBlockNumber();
        const blockBefore = await ethers.provider.getBlock(blockNumBefore);
        timestampBefore = blockBefore.timestamp;
    });


    

    it("Should vote [10,10,80]", async function () {

        impersonator = '0x73ef2F1b0DbCA5b4D6828195907066cE6264af3e' //3077  (300k)
        impersonator2 = '0xD204E3dC1937d3a30fc6F20ABc48AC5506C94D1E' //10    (562k)

            
        await hre.network.provider.request({method: "hardhat_impersonateAccount",params: [impersonator]});
        signer = await ethers.getSigner(impersonator)
        
        await voter.connect(signer).vote(3077,[pool1,pool2,hypervisor.address],[10,10,80])
        //console.log(await voter.poolVote(3077))
        await hre.network.provider.request({method: "hardhat_stopImpersonatingAccount",params: [impersonator]});
        //console.log(await voter.totalWeight())
        
        
        await hre.network.provider.request({method: "hardhat_impersonateAccount",params: [impersonator2]});
        signer = await ethers.getSigner(impersonator2)
        
        await voter.connect(signer).vote(10,[pool1,pool2,hypervisor.address],[10,10,80])
        console.log(await voter.totalWeight())
        //console.log(await voter.poolVote(10))
        console.log(await voter._epochTimestamp())
        
        await hre.network.provider.request({method: "hardhat_stopImpersonatingAccount",params: [impersonator2]});
    
    
    
    });

    it("Should send rewards to voter and distribute", async function () {

        impersonator = '0x34eb1b0ebf95c751298d8dbad90f40dcb5c52827'
            
        await hre.network.provider.request({method: "hardhat_impersonateAccount",params: [impersonator]});
        signer = await ethers.getSigner(impersonator)
        
        const amountin = ethers.utils.parseEther("1000")
        await thena.connect(signer).approve(voter.address, amountin)
        await voter.connect(signer)._notifyRewardAmount(amountin)
        expect(await thena.balanceOf(voter.address)).to.equal(amountin)
        
        await hre.network.provider.request({method: "hardhat_stopImpersonatingAccount",params: [impersonator]});
        
        await ethers.provider.send('evm_increaseTime', [5 * 86400]);
        await ethers.provider.send('evm_mine');

        expect(await voter.totalWeightAt(1680134400)).to.above(0)
        expect(await thena.balanceOf(gauge.address)).to.equal(0)
        expect(await thena.balanceOf(gauge_classic.address)).to.equal(0)
        expect(await thena.balanceOf(gauge_classic2.address)).to.equal(0)

        await voter.distributeAll()

        expect(await voter.totalWeightAt(1680739200)).to.equal(0)
        expect(await thena.balanceOf(gauge.address)).to.above(0)
        expect(await thena.balanceOf(gauge_classic.address)).to.above(0)
        expect(await thena.balanceOf(gauge_classic2.address)).to.above(0)
    
    
    });

    
    it("Should vote_2 [10,10,80]", async function () {

        impersonator = '0x73ef2F1b0DbCA5b4D6828195907066cE6264af3e' //3077  (300k)
        impersonator2 = '0xD204E3dC1937d3a30fc6F20ABc48AC5506C94D1E' //10    (562k)

            
        await hre.network.provider.request({method: "hardhat_impersonateAccount",params: [impersonator]});
        signer = await ethers.getSigner(impersonator)
        
        await voter.connect(signer).vote(3077,[pool1,pool2,hypervisor.address],[10,10,80])
        //console.log(await voter.poolVote(3077))
        await hre.network.provider.request({method: "hardhat_stopImpersonatingAccount",params: [impersonator]});
        console.log(await voter.totalWeight())
        
        
        await hre.network.provider.request({method: "hardhat_impersonateAccount",params: [impersonator2]});
        signer = await ethers.getSigner(impersonator2)
        
        await voter.connect(signer).reset(10)
        console.log(await voter._epochTimestamp())
        console.log(await voter.totalWeight())

        await voter.connect(signer).vote(10,[pool1,pool2,hypervisor.address],[10,10,80])
        console.log(await voter.totalWeight())
        //console.log(await voter.poolVote(10))

                
        await hre.network.provider.request({method: "hardhat_stopImpersonatingAccount",params: [impersonator2]});
    
    
    
    });

    
});


describe("Thena - Claim rewards Section", function () {

    beforeEach(async () => {
        await ethers.provider.send('evm_increaseTime', [5]);
        await ethers.provider.send('evm_mine');

        const blockNumBefore = await ethers.provider.getBlockNumber();
        const blockBefore = await ethers.provider.getBlock(blockNumBefore);
        timestampBefore = blockBefore.timestamp;
    });


    it("Should harvest from gauge + extra rewarder", async function () {

        
        impersonator = BigHolder
        await hre.network.provider.request({method: "hardhat_impersonateAccount",params: [impersonator]});
        signer = await ethers.getSigner(impersonator)

        const extraRewAmountBef = await usdc.balanceOf(impersonator)
        const amountBef = await thena.balanceOf(impersonator)

        await gauge.connect(signer).getReward()

        const amountAft = await thena.balanceOf(impersonator)
        const extraRewAmountAft = await usdc.balanceOf(impersonator)

        expect(amountBef).to.be.below(amountAft)
        //console.log("amountBef: ", amountBef/1e18)
        //console.log("amountAft: ", amountAft/1e18)
        //console.log("extraRewAmountBef: ", extraRewAmountBef/1e18)
        //console.log("extraRewAmountAft: ", extraRewAmountAft/1e18)


        await hre.network.provider.request({method: "hardhat_stopImpersonatingAccount",params: [impersonator]});      

    });

    it("Should get int bribes", async function () {

         
        await ethers.provider.send('evm_increaseTime', [8 * 86400]);
        await ethers.provider.send('evm_mine');
        await voter.distributeAll()
        await ethers.provider.send('evm_increaseTime', [8 * 86400]);
        await ethers.provider.send('evm_mine');
        await voter.distributeAll()

        impersonator = '0x73ef2F1b0DbCA5b4D6828195907066cE6264af3e' //3077  (300k)
        impersonator2 = '0xD204E3dC1937d3a30fc6F20ABc48AC5506C94D1E' //10    (562k)

        // -------- 1st voter
        await hre.network.provider.request({method: "hardhat_impersonateAccount",params: [impersonator]});
        signer = await ethers.getSigner(impersonator)

        //console.log("owner1 earned: ", await int_bribe.earned(impersonator, usdc.address))
        //console.log("tokenid1 earned: ", await int_bribe.earned(3077, usdc.address))
        
        const amountBef = await usdc.balanceOf(impersonator)
        await int_bribe.connect(signer).getReward([usdc.address])
        const amountAft = await usdc.balanceOf(impersonator)
        expect(amountBef).to.be.below(amountAft)

        //console.log("owner1_aft earned: ", await int_bribe.earned(impersonator, usdc.address))
        //console.log("tokenid1_aft earned: ", await int_bribe.earned(3077, usdc.address))
        
        //console.log("amountBef: ", amountBef/1e18)
        //console.log("amountAft: ", amountAft/1e18)

        await hre.network.provider.request({method: "hardhat_stopImpersonatingAccount",params: [impersonator]});      

        // -------- 2nd voter
        
        await hre.network.provider.request({method: "hardhat_impersonateAccount",params: [impersonator2]});
        signer = await ethers.getSigner(impersonator2)

        //console.log("owner2 earned: ", await int_bribe.earned(impersonator2, usdc.address))
        //console.log("tokenid2 earned: ", await int_bribe.earned(10, usdc.address))
        
        const amountBef2 = await usdc.balanceOf(impersonator2)
        await int_bribe.connect(signer).getReward([usdc.address])
        const amountAft2 = await usdc.balanceOf(impersonator2)
        expect(amountBef2).to.be.below(amountAft2)

        //console.log("owner2_aft earned: ", await int_bribe.earned(impersonator2, usdc.address))
        //console.log("tokenid2_aft earned: ", await int_bribe.earned(10, usdc.address))
        
        //console.log("amountBef2: ", amountBef2/1e18)
        //console.log("amountAft2: ", amountAft2/1e18)

        await hre.network.provider.request({method: "hardhat_stopImpersonatingAccount",params: [impersonator2]});   

    });

    
});

        
