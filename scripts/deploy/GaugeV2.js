// // scripts/upgrade-box.js
const { ethers, upgrades } = require("hardhat");
const { deployProxyContract } = require("../../shared/helpers");

async function main() {
    const rewardToken = ""
    const mainToken = ""
    const voter = ""
    const lpFeeReciever = ""
    const bribeFeeReciever = ""
    const hasClaimFee = true
    await deployProxyContract("GaugeV2", [ rewardToken, process.env.VOTINGESCROW, mainToken, voter, lpFeeReciever, bribeFeeReciever, hasClaimFee ]);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
