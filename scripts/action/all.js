// // scripts/upgrade-box.js
const { ethers, upgrades } = require("hardhat");
const { deployContract, deployProxyContract, sendTxn } = require("../shared/helpers");

async function main() {
    //StarBugToken(SBT)
    const currentBlock = await ethers.provider.getBlockNumber();
    const timestamp = (await ethers.provider.getBlock(currentBlock)).timestamp;
    const theContract = await deployContract("StarBugToken", []);
    await sendTxn(theContract.mint(process.env.PUBLICKEY, ethers.utils.parseUnits("1000000000", 18)), "theContract.mint");

    //Mint theNFT
    const thenianContract = await deployContract("Thenian", [ 3000, ethers.utils.parseUnits("25", 15), timestamp - 2 * 24 * 60 * 60 - 1, process.env.PUBLICKEY ]);
    await sendTxn(thenianContract.reserveNFTs(process.env.PUBLICKEY, 5), "thenianContract.reserveNFTs");
    await sendTxn(thenianContract.mintPublic(5, {
        value: ethers.utils.parseUnits("125", 15),
        gasLimit: "3000000",
    }), "thenianContract.mintPublic");

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
            process.env.WFTM,
        ], "deploy RouterV2");

    // Ve Art
    const veArtProxyUpgradeableContract = await deployProxyContract("VeArtProxyUpgradeable", []);

    // VE Voting Escrow
    const veContract = await deployContract("VotingEscrow",
        [
            theContract.address,
            veArtProxyUpgradeableContract.address,
        ]);

    // RewardsDistributor
    const rewardsDistributorContract = await deployContract("RewardsDistributor", [
        veContract.address,
    ], "deploy RewardsDistributor");

    // Gauge Factory
    const gaugeFactoryContract = await deployProxyContract("GaugeFactoryV3", []);

    // Bribe Factory
    const bribeFactoryContract = await deployProxyContract("BribeFactoryV3", [ process.env.PUBLICKEY ]);

    // VoterV2_1
    const voterContract = await deployProxyContract("VoterV3",
        [
            veContract.address,
            pairFactoryContract.address,
            gaugeFactoryContract.address,
            bribeFactoryContract.address,
        ]);

    // set voter for Bribe factory
    await sendTxn(bribeFactoryContract.setVoter(voterContract.address), "BribeFactoryV3.setVoter");

    // Set Voter for VE contract
    await sendTxn(veContract.setVoter(voterContract.address), "VoterV3.setVoter");

    // MinterUpgradeable
    const minterContract = await deployProxyContract("MinterUpgradeable",
        [
            voterContract.address,
            veContract.address,
            rewardsDistributorContract.address,
        ], "deploy MinterUpgradeable");

    // Set minter and whitelist for Voter contract
    await sendTxn(voterContract._initialize([
        theContract.address,
        process.env.WFTM,
        process.env.ETH,
        process.env.USDT,
        process.env.BTC,
        process.env.BUSD,
        process.env.USDC,
    ], minterContract.address), "VoterV3._initialize");

    await sendTxn(rewardsDistributorContract.setDepositor(minterContract.address), "rewardsDistributorContract.setDepositor");

    const pairApiContract = await deployProxyContract("PairAPI", [ voterContract.address ]);

    // veNFTAPI
    await deployProxyContract("veNFTAPI", [ voterContract.address, rewardsDistributorContract.address, pairApiContract.address, pairFactoryContract.address ]);

    // RewardAPI
    await deployProxyContract("RewardAPI", [ voterContract.address ]);

    //Deploy NFTSALESSPLITTER

    // Staking NFT
    const stakingNFTFeeConvertercontract = await deployContract("StakingNFTFeeConverter", [
        process.env.WFTM,
    ], "deploy StakingNFTFeeConverter");

    await sendTxn(stakingNFTFeeConvertercontract.setPairFactory(pairFactoryContract.address), "StakingNFTFeeConverter.setPairFactory");
    await sendTxn(stakingNFTFeeConvertercontract.setRouter(routerContract.address), "StakingNFTFeeConverter.setRouter");
    await sendTxn(stakingNFTFeeConvertercontract.setKeeper(process.env.PUBLICKEY), "StakingNFTFeeConverter.setKeeper");

    // NFTStaking
    const NFTStakingContract = await deployContract("NFTStaking",
        [
            process.env.WFTM,
            thenianContract.address,
        ]);

    await sendTxn(NFTStakingContract.addKeeper([ process.env.PUBLICKEY, stakingNFTFeeConvertercontract.address ]), "NFTStaking.addKeeper");
    await sendTxn(NFTStakingContract.setDistributionRate(ethers.utils.parseUnits("10", 18)), "NFTStaking.setDistributionRate");

    // Set NFTStaking for staking nft contract
    await sendTxn(stakingNFTFeeConvertercontract.setNFTStaking(NFTStakingContract.address), "StakingNFTFeeConverter.setNFTStaking");

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
            stakingNFTFeeConvertercontract.address,
            royaltyContract.address,
        ], "deploy NFTSalesSplitter");

    // set keeper for staking NFT
    await sendTxn(stakingNFTFeeConvertercontract.setKeeper(nftSalesSplitterContract.address), "StakingNFTFeeConverter.setKeeper");

    // set depositor for royalContract
    await sendTxn(royaltyContract.setDepositor(nftSalesSplitterContract.address), "Royalties.setDepositor");

    // airdrop
    const airdropClaimContract = await deployContract("AirdropClaim", [ theContract.address, veContract.address ]);

    await deployContract("MerkleTree", [ airdropClaimContract.address ]);

    const airdropClaimNftContract = await deployContract("AirdropClaimTheNFT", [ theContract.address, veContract.address ]);

    await deployContract("MerkleTreeTHENFT", [ airdropClaimNftContract.address ]);

}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
