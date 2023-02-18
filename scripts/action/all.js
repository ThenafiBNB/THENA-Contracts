// // scripts/upgrade-box.js
const { ethers, upgrades } = require("hardhat");
const { deployContract, deployProxyContract, sendTxn } = require("../shared/helpers");

async function main() {
    //Thena(THE)
    const theContract = await deployContract("Thena", []);
    await sendTxn(theContract.mint(process.env.PUBLICKEY, ethers.utils.parseUnits("1000000000", 18)), "theContract.mint");

    //Mint theNFT
    const thenianContract = await deployContract("Thenian", [3000, ethers.utils.parseUnits("25", 17), 1669993200]);
    await sendTxn(thenianContract.reserveNFTs(process.env.PUBLICKEY, 15), "thenianContract.reserveNFTs");

    // Multicall
    await deployContract("Multicall2", []);

    // Pairfactory
    const pairFactoryContract = await deployProxyContract("PairFactoryUpgradeable", []);
    await sendTxn(pairFactoryContract.setStakingFeeAddress(process.env.PUBLICKEY), "PairFactoryUpgradeable.setDibs");
    await sendTxn(pairFactoryContract.setDibs(process.env.PUBLICKEY), "PairFactoryUpgradeable.setDibs");

    // RouterV2
    const routerContract = await deployContract("RouterV2",
        [
            pairFactoryContract.address,
            process.env.WFTM
        ], "deploy RouterV2");

    // Ve Art
    const veArtProxyUpgradeableContract = await deployProxyContract("VeArtProxyUpgradeable", []);

    // VE Voting Escrow
    const veContract = await deployContract("VotingEscrow",
        [
            theContract.address,
            veArtProxyUpgradeableContract.address
        ]);

    // RewardsDistributor
    const rewardsDistributorContract = await deployContract("RewardsDistributor", [
        veContract.address
    ], "deploy RewardsDistributor");

    // Gauge Factory
    const gaugeFactoryContract = await deployProxyContract("GaugeFactoryV2", []);

    // Bribe Factory
    const bribeFactoryContract = await deployProxyContract("BribeFactoryV2", [process.env.PUBLICKEY]);

    // VoterV2_1
    const voterContract = await deployProxyContract("VoterV2_1",
        [
            veContract.address,
            pairFactoryContract.address,
            gaugeFactoryContract.address,
            bribeFactoryContract.address,
        ]);

    // set voter for Bribe factory
    await sendTxn(bribeFactoryContract.setVoter(voterContract.address), "BribeFactoryV2.setVoter");

    // Set Voter for VE contract
    await sendTxn(veContract.setVoter(voterContract.address), "VoterV2_1.setVoter");

    // MinterUpgradeable
    const minterContract = await deployProxyContract("MinterUpgradeable",
        [
            voterContract.address,
            veContract.address,
            rewardsDistributorContract.address
        ], "deploy MinterUpgradeable");

    // Set minter and whitelist for Voter contract
    await sendTxn(voterContract._initialize([
        process.env.THE,
        process.env.USDT,
        process.env.BTC,
        process.env.ETH,
        process.env.BUSD,
        process.env.USDC,
    ], minterContract.address), "VoterV2_1._initialize");

    await sendTxn(rewardsDistributorContract.setDepositor(minterContract.address), "rewardsDistributorContract.setDepositor");

    const pairApiContract = await deployProxyContract("PairAPI", [voterContract.address]);

    // veNFTAPI
    await deployProxyContract("veNFTAPI", [voterContract.address, rewardsDistributorContract.address, pairApiContract.address, pairFactoryContract.address]);

    // RewardAPI
    await deployProxyContract("RewardAPI", [voterContract.address]);

    //Deploy NFTSALESSPLITTER

    // Staking NFT
    let stakingNFTcontract = await deployContract("StakingNFTFeeConverter", [
        process.env.WFTM,
    ], "deploy StakingNFTFeeConverter");

    await sendTxn(stakingNFTcontract.setPairFactory(pairFactoryContract.address), "StakingNFTFeeConverter.setPairFactory");
    await sendTxn(stakingNFTcontract.setRouter(routerContract.address), "StakingNFTFeeConverter.setRouter");
    await sendTxn(stakingNFTcontract.setKeeper(process.env.PUBLICKEY), "StakingNFTFeeConverter.setKeeper");

    // MasterChef
    const masterChefContract = await deployContract("MasterChef",
        [
            process.env.WFTM,
            thenianContract.address,
        ]);

    await sendTxn(masterChefContract.addKeeper([process.env.PUBLICKEY]), "MasterChef.addKeeper");
    await sendTxn(masterChefContract.setDistributionRate(ethers.utils.parseUnits("10", 18)), "MasterChef.setDistributionRate");

    // Set masterchef for staking nft contract
    await sendTxn(stakingNFTcontract.setMasterchef(masterChefContract.address), "StakingNFTFeeConverter.setMasterchef");

    // Royalties
    const royaltyContract = await deployContract("Royalties",
        [
            process.env.WFTM,
            thenianContract.address,
        ], "deploy Royalties");

    await sendTxn(royaltyContract.setDepositor(process.env.PUBLICKEY), "Royalties.setDepositor");

    // NFT Sales Splitter
    const nftSalesSplitterContract = await deployProxyContract("NFTSalesSplitter",
        [
            process.env.WFTM,
            stakingNFTcontract.address,
            royaltyContract.address
        ], "deploy NFTSalesSplitter");

    // set keeper for staking NFT
    await sendTxn(stakingNFTcontract.setKeeper(nftSalesSplitterContract.address), "StakingNFTFeeConverter.setKeeper");

    // airdrop
    const airdropClaimContract = await deployContract("AirdropClaim", [theContract.address, veContract.address]);

    await deployContract("MerkleTree", [airdropClaimContract.address]);

    const airdropClaimNftContract = await deployContract("AirdropClaimTheNFT", [theContract.address, veContract.address]);

    await deployContract("MerkleTreeTHENFT", [airdropClaimNftContract.address]);

}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });