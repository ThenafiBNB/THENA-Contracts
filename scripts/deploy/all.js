// // scripts/upgrade-box.js
const { ethers, upgrades } = require("hardhat");
const { deployContract, deployProxyContract } = require("../shared/helpers");

async function main() {
    const theContract = await deployContract("Thena", []);
    await sendTxn(theContract.mint("0x595622cBd0Fc4727DF476a1172AdA30A9dDf8F43", ethers.utils.parseUnits("10000", 18)), "VoterV2_1.mint");

    //Mint theNFT
    const thenianContract = await deployContract("Thenian", [3000, ethers.utils.parseUnits("25", 17), 1669993200]);
    await sendTxn(thenianContract.reserveNFTs("0x595622cBd0Fc4727DF476a1172AdA30A9dDf8F43", 5), "VoterV2_1.mint");
    await sendTxn(thenianContract.reserveNFTs("0x95ece85B9c5B9bAa46100BE2B1bd4fC64aBc696A", 15), "VoterV2_1.mint");

    // Multicall
    await deployContract("Multicall2", []);

    // Pairfactory
    const pairFactoryContract = await deployProxyContract("PairFactoryUpgradeable", []);
    // DIBS contract, tạm thời để admin nhận fee
    await sendTxn(pairFactoryContract.setDibs(process.env.PUBLICKEY), "PairFactoryUpgradeable.setDibs");

    // RouterV2
    await deployContract("RouterV2",
        [
            pairFactoryContract.address,
            process.env.WFTM
        ], "deploy RouterV2");

    // Ve Art
    const veArtProxyUpgradeableContract = await deployProxyContract("VeArtProxyUpgradeable", []);

    // VE
    const veContract = await deployContract("VotingEscrow",
        [
            theContract.address,
            veArtProxyUpgradeableContract.address
        ]);
    await sendTxn(veContract.isApprovedOrOwner("0x595622cBd0Fc4727DF476a1172AdA30A9dDf8F43", 1), "VoterV2_1.isApprovedOrOwner");

    // RewardsDistributor
    const rewardsDistributorContract = await deployContract("RewardsDistributor", [
        veContract.address
    ], "deploy RewardsDistributor");

    // 
    const gaugeFactoryContract = await deployProxyContract("GaugeFactoryV2", []);

    const bribeFactoryContract = await deployProxyContract("BribeFactoryV2", []);
    //set lai votev2_1


    // VoterV2_1
    const voterContract = await deployProxyContract("VoterV2_1",
        [
            veContract.address,
            pairFactoryContract.address,
            gaugeFactoryContract.address,
            bribeFactoryContract.address,
        ]);
    await sendTxn(voterContract.whitelist(process.env.USDT), "VoterV2_1.whitelist");
    await sendTxn(voterContract.setMinter(process.env.PUBLICKEY), "VoterV2_1.setMinter");
    let tx = await bribeFactoryContract.setVoter(voterContract.address);
    await tx.wait();

    // MinterUpgradeable
    await deployProxyContract("MinterUpgradeable",
        [
            voterContract.address,
            veContract.address,
            rewardsDistributorContract.address
        ], "deploy MinterUpgradeable");

    const pairApiContract = await deployProxyContract("PairAPI", [voterContract.address]);

    // veNFTAPI
    await deployProxyContract("veNFTAPI", [voterContract.address, rewardsDistributorContract.address, pairApiContract.address, pairFactoryContract.address]);

    // RewardAPI
    await deployProxyContract("RewardAPI", [voterContract.address]);

    // Staking
    const stakingContract = await deployContract("MasterChef",
        [
            process.env.WFTM,
            thenianContract.address,
        ]);

    await sendTxn(stakingContract.addKeeper([process.env.PUBLICKEY]), "MasterChef.addKeeper");
    await sendTxn(stakingContract.setDistributionRate(ethers.utils.parseUnits("10", 18)), "MasterChef.setDistributionRate");

    // Royalties
    const royaltyContract = await deployContract("Royalties",
        [
            process.env.WFTM,
            thenianContract.address,
        ], "deploy Royalties");

    await sendTxn(royaltyContract.setDepositor(process.env.PUBLICKEY), "Royalties.setDepositor");

    // airdrop
    const airdropClaimContract = await deployContract("AirdropClaim", [theContract.address, veContract.address]);

    await deployContract("MerkleTree", [airdropClaimContract.address]);

    const airdropClaimNftContract = await deployContract("AirdropClaimTheNFT", [theContract.address, veContract.address]);
    
    await deployContract("MerkleTree", [airdropClaimNftContract.address]);

}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });