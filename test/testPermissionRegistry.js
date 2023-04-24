
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

        await PermissionsRegistry.setRoleFor(BigHolder, "FEE_MANAGER")
        expect(await PermissionsRegistry.hasRole(await PermissionsRegistry.__helper_stringToBytes("FEE_MANAGER"), BigHolder)).to.equal(true)

        await PermissionsRegistry.setRoleFor(owner.address, "CL_FEES_VAULT_ADMIN")
        expect(await PermissionsRegistry.hasRole(await PermissionsRegistry.__helper_stringToBytes("CL_FEES_VAULT_ADMIN"), owner.address)).to.equal(true)


    });

    it("Should rolesToString", async function() {

        console.log('rolesToString:', (await PermissionsRegistry.rolesToString()).toString())

    });

    it("Should roles", async function() {

        console.log('roles:', (await PermissionsRegistry.roles()).toString())

    });

    it("Should roleToAddresses", async function() {

        console.log('roleToAddresses:', (await PermissionsRegistry.roleToAddresses("FEE_MANAGER")).toString())

    });

    
    it("Should addressToRole", async function() {

        console.log('addressToRole:', (await PermissionsRegistry.addressToRole(owner.address)))

    });


    it("Should removeRoleFrom", async function() {
        
        console.log('removeRoleFrom:', (await PermissionsRegistry.addressToRole(BigHolder)).toString())
        console.log('removeRoleFrom:', (await PermissionsRegistry.roleToAddresses("FEE_MANAGER")).toString())

        await PermissionsRegistry.removeRoleFrom(BigHolder, "FEE_MANAGER")
        
        console.log('removeRoleFrom:', (await PermissionsRegistry.addressToRole(BigHolder)).toString())
        console.log('removeRoleFrom:', (await PermissionsRegistry.roleToAddresses("FEE_MANAGER")).toString())


    });
});



        
