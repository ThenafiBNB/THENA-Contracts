

const { expect } = require("chai");
const { erc20Abi } = require("./Abi.js")
const { ethers, upgrades } = require("hardhat");
const { AddressZero } = require("@ethersproject/constants");
const expectEvent = require("@openzeppelin/test-helpers/src/expectEvent.js");


describe("TestUpgrades", function () {
   
    beforeEach(async () => {
        await ethers.provider.send('evm_increaseTime', [5]);
        await ethers.provider.send('evm_mine');

        const blockNumBefore = await ethers.provider.getBlockNumber();
        const blockBefore = await ethers.provider.getBlock(blockNumBefore);
        timestampBefore = blockBefore.timestamp;
    });

    it("Should load contract for test purpose (ERC20,..)", async function () {
        accounts = await ethers.getSigners();
        owner = accounts[0]
    
        adminproxyAbi = [{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"previousOwner","type":"address"},{"indexed":true,"internalType":"address","name":"newOwner","type":"address"}],"name":"OwnershipTransferred","type":"event"},{"inputs":[{"internalType":"contract TransparentUpgradeableProxy","name":"proxy","type":"address"},{"internalType":"address","name":"newAdmin","type":"address"}],"name":"changeProxyAdmin","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"contract TransparentUpgradeableProxy","name":"proxy","type":"address"}],"name":"getProxyAdmin","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"contract TransparentUpgradeableProxy","name":"proxy","type":"address"}],"name":"getProxyImplementation","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"owner","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"renounceOwnership","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"newOwner","type":"address"}],"name":"transferOwnership","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"contract TransparentUpgradeableProxy","name":"proxy","type":"address"},{"internalType":"address","name":"implementation","type":"address"}],"name":"upgrade","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"contract TransparentUpgradeableProxy","name":"proxy","type":"address"},{"internalType":"address","name":"implementation","type":"address"},{"internalType":"bytes","name":"data","type":"bytes"}],"name":"upgradeAndCall","outputs":[],"stateMutability":"payable","type":"function"}]
        adminproxy    = new ethers.Contract(ethers.utils.getAddress("0x5D120a288F1c9b9d382E7dEB64573f15E18d990e"), adminproxyAbi, owner)

        
        const recipient = ethers.utils.getAddress("0x993Ae2b514677c7AC52bAeCd8871d2b362A9D693")
        // get bnb
        const amount = ethers.utils.parseEther("1.0");  
        await owner.sendTransaction({
            to: recipient,
            value: amount,
        });
        
    });

    it("Should deploy and update ", async function () {

        const voterAddress = ethers.utils.getAddress("0x3a1d0952809f4948d15ebce8d345962a282c4fcb")
        voter = await ethers.getContractAt("contracts/VoterV3.sol:VoterV3", voterAddress);

        
        
        ve = '0xfbbf371c9b0b994eebfcc977cef603f7f31c070d'
        pairFactory = '0xafd89d21bdb66d00817d4153e055830b1c2b3970'
        gaugeFactoryV2 = '0x2c788fe40a417612cb654b14a944cd549b5bf130'
        bribeFactoryV3 = '0xd50ceab3071c61c85d04bdd65feb12fee7c91375'


        data = await ethers.getContractFactory("VoterV3");
        input = [ve, pairFactory , gaugeFactoryV2,bribeFactoryV3]
        VoterV3 = await upgrades.deployProxy(data,input, {initializer: 'initialize'});
        txDeployed = await VoterV3.deployed();
        //console.log("VoterV3_new_proxy: ", VoterV3.address)
        const VoterV3_new_impl = await upgrades.erc1967.getImplementationAddress(VoterV3.address);
        console.log("VoterV3_new_impl: ", VoterV3_new_impl)
        //console.log("GaugeFactories: ", await voter._gaugeFactories())

        impersonator = ethers.utils.getAddress("0x993Ae2b514677c7AC52bAeCd8871d2b362A9D693")
        const tokenId = 9481
        await hre.network.provider.request({method: "hardhat_impersonateAccount",params: [impersonator],});
        signer = await ethers.getSigner(impersonator)
    
        // 1. set new implementation for the voter
        const old_impl = await adminproxy.getProxyImplementation('0x3a1d0952809f4948d15ebce8d345962a282c4fcb')
        await adminproxy.connect(signer).upgrade('0x3a1d0952809f4948d15ebce8d345962a282c4fcb', VoterV3_new_impl)
        const new_impl = await adminproxy.getProxyImplementation('0x3a1d0952809f4948d15ebce8d345962a282c4fcb')

        console.log('implementation_old: ', old_impl)
        console.log('implementation_new: ', new_impl)
        expect(VoterV3_new_impl).to.be.equal(new_impl)

        //2. check and force timestmap
        const old_timestamp = await voter.lastVoted(tokenId)
        await voter.connect(signer).forceResetTo(tokenId)
        const new_timestamp = await voter.lastVoted(tokenId)

        console.log('User last time _ before: ', old_timestamp)
        console.log('User last time _ after: ', new_timestamp)
        expect(old_timestamp).to.be.below(new_timestamp)
        await hre.network.provider.request({method: "hardhat_stopImpersonatingAccount",params: [impersonator]});   
    });

        
     it("Should vote #1", async function () {

        const pool = '0xf9Cf0b2fF50D13ABa7aaD7e9314b096bfC0ACE7c'

        impersonator = '0xABd9221a59ba5c03FdD655834F07F44818979698'
        var tokenId = 49
        await hre.network.provider.request({method: "hardhat_impersonateAccount",params: [impersonator]});
        signer = await ethers.getSigner(impersonator)
        console.log('-------------------------------------------------')
        var old_timestamp = await voter.lastVoted(tokenId)
        await voter.connect(signer).reset(tokenId)
        console.log('resetted')

        await voter.connect(signer).vote(tokenId, [pool], [100])
        var new_timestamp = await voter.lastVoted(tokenId)
        
        console.log('ID: ', tokenId, '\tlast time _ before: ', old_timestamp)
        console.log('ID: ', tokenId, '\tlast time _ after: ', new_timestamp)
        expect(old_timestamp).to.be.below(new_timestamp)

        await hre.network.provider.request({method: "hardhat_stopImpersonatingAccount",params: [impersonator]});   


        impersonator = '0x993Ae2b514677c7AC52bAeCd8871d2b362A9D693'
        tokenId = 9481
        await hre.network.provider.request({method: "hardhat_impersonateAccount",params: [impersonator]});
        signer = await ethers.getSigner(impersonator)
        console.log('-------------------------------------------------')
        old_timestamp = await voter.lastVoted(tokenId)
        await voter.connect(signer).reset(tokenId)
        console.log('resetted')

        await voter.connect(signer).vote(tokenId, [pool], [100])
        new_timestamp = await voter.lastVoted(tokenId)
        console.log('ID: ', tokenId, '\tlast time _ before: ', old_timestamp)
        console.log('ID: ', tokenId, '\tlast time _ after: ', new_timestamp)
        expect(old_timestamp).to.be.below(new_timestamp)
        await hre.network.provider.request({method: "hardhat_stopImpersonatingAccount",params: [impersonator]});     


    });
   

    
    it("Should distributeAll", async function () {
        await ethers.provider.send('evm_increaseTime', [7*86400]);
        await ethers.provider.send('evm_mine');
        
        const gauge = '0x909Bd7ea6f40d8183d9F84d452F884a11243648B'  //pool: 0xf9Cf0b2fF50D13ABa7aaD7e9314b096bfC0ACE7c
        thena = await ethers.getContractAt("contracts/Thena.sol:Thena", '0xF4C8E32EaDEC4BFe97E0F595AdD0f4450a863a11');

        console.log('updating period')
        const bal_bef = await thena.balanceOf(gauge)
        const tx = await voter.distributeAll()
        const bal_aft = await thena.balanceOf(gauge)

        console.log('gauge bal before update: ', bal_bef/1e18)
        console.log('gauge bal before update: ', bal_aft/1e18)
        expect(bal_bef).to.be.below(bal_aft)

    });


    it("Should vote #2", async function () {

        const pool = '0xf9Cf0b2fF50D13ABa7aaD7e9314b096bfC0ACE7c'

        impersonator = '0xABd9221a59ba5c03FdD655834F07F44818979698'
        var tokenId = 49
        await hre.network.provider.request({method: "hardhat_impersonateAccount",params: [impersonator]});
        signer = await ethers.getSigner(impersonator)
        console.log('-------------------------------------------------')
        var old_timestamp = await voter.lastVoted(tokenId)
        await voter.connect(signer).reset(tokenId)
        console.log('resetted')

        await voter.connect(signer).vote(tokenId, [pool], [100])
        var new_timestamp = await voter.lastVoted(tokenId)
        
        console.log('ID: ', tokenId, '\tlast time _ before: ', old_timestamp)
        console.log('ID: ', tokenId, '\tlast time _ after: ', new_timestamp)
        expect(old_timestamp).to.be.below(new_timestamp)

        await hre.network.provider.request({method: "hardhat_stopImpersonatingAccount",params: [impersonator]});   


        impersonator = '0x993Ae2b514677c7AC52bAeCd8871d2b362A9D693'
        tokenId = 9481
        await hre.network.provider.request({method: "hardhat_impersonateAccount",params: [impersonator]});
        signer = await ethers.getSigner(impersonator)
        console.log('-------------------------------------------------')
        old_timestamp = await voter.lastVoted(tokenId)
        await voter.connect(signer).reset(tokenId)
        console.log('resetted')

        await voter.connect(signer).vote(tokenId, [pool], [100])
        new_timestamp = await voter.lastVoted(tokenId)
        console.log('ID: ', tokenId, '\tlast time _ before: ', old_timestamp)
        console.log('ID: ', tokenId, '\tlast time _ after: ', new_timestamp)
        expect(old_timestamp).to.be.below(new_timestamp)
        await hre.network.provider.request({method: "hardhat_stopImpersonatingAccount",params: [impersonator]});     


    });
 
    it("Should try to trick the system", async function () {
        await ethers.provider.send('evm_increaseTime', [7*86400]);
        await ethers.provider.send('evm_mine');
        
        console.log('-------------------------------------------------')
        console.log('-------------------------------------------------')
        const gauge = '0x909Bd7ea6f40d8183d9F84d452F884a11243648B'  //pool: 0xf9Cf0b2fF50D13ABa7aaD7e9314b096bfC0ACE7c
        const attackerGauge = '0x46f0AE8EB2D0FA8DFf90BF2be20718Ea2bbfeFF4' //pool: 0xE4B5493e357859FB73bE73b29B1034cF63547986
        thena = await ethers.getContractAt("contracts/Thena.sol:Thena", '0xF4C8E32EaDEC4BFe97E0F595AdD0f4450a863a11');
        minter = await ethers.getContractAt("contracts/MinterUpgradeable.sol:MinterUpgradeable", '0x86069FEb223EE303085a1A505892c9D4BdBEE996');
        
        const gauge2_preBal = await thena.balanceOf(attackerGauge)

        console.log("- Step 1: call minter.updatePeriod")
        await minter.update_period()
        console.log("\t...done")


        console.log("- Step 2: vote a pool != than 0xf9Cf0b2fF50D13ABa7aaD7e9314b096bfC0ACE7c")
        impersonator = '0x993Ae2b514677c7AC52bAeCd8871d2b362A9D693'
        tokenId = 9481
        await hre.network.provider.request({method: "hardhat_impersonateAccount",params: [impersonator]});
        signer = await ethers.getSigner(impersonator)
        console.log('-------------------------------------------------')
        old_timestamp = await voter.lastVoted(tokenId)
        await voter.connect(signer).reset(tokenId)
        console.log('resetted')
        const attackerPool = '0xE4B5493e357859FB73bE73b29B1034cF63547986'
        await voter.connect(signer).vote(tokenId, [attackerPool], [100])
        new_timestamp = await voter.lastVoted(tokenId)
        console.log('ID: ', tokenId, '\tlast time _ before: ', old_timestamp)
        console.log('ID: ', tokenId, '\tlast time _ after: ', new_timestamp)
        expect(old_timestamp).to.be.below(new_timestamp)
        await hre.network.provider.request({method: "hardhat_stopImpersonatingAccount",params: [impersonator]});     


        console.log("- Step 3: Call distributeAll, we expect to find new $the only in past epoch gauges!")
        console.log('updating period')
        const bal_bef = await thena.balanceOf(gauge)
        const tx = await voter.distributeAll()
        const bal_aft = await thena.balanceOf(gauge)
        const gauge2_aftBal = await thena.balanceOf(attackerGauge)

        console.log('gauge bal before update: ', bal_bef/1e18)
        console.log('gauge bal before update: ', bal_aft/1e18)
        console.log('attackerGauge bal before update: ', gauge2_preBal/1e18)
        console.log('attackerGauge bal after update: ', gauge2_aftBal/1e18)
        expect(bal_bef).to.be.below(bal_aft)

    });


});

