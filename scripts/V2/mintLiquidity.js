const { ethers  } = require('hardhat');

const { ZERO_ADDRESS } = require("@openzeppelin/test-helpers/src/constants.js");

const { erc20Abi, gammaProxyAbi, hypervisorAbi, CLRouterAbi, algebraRouterAbi, nonFungiblePositionAbi } = require("./Abi.js")


async function main () {

    accounts = await ethers.getSigners();
    owner = accounts[0]
    
    const nonFungiblePosition = ethers.utils.getAddress("0xa51ADb08Cbe6Ae398046A23bec013979816B77Ab")
    floki = await ethers.getContractAt(erc20Abi, '0xfb5b838b6cfeedc2873ab27866079ac55363d37e')
    nfpos = await ethers.getContractAt(nonFungiblePositionAbi, nonFungiblePosition)
    
    
    usdt = await ethers.getContractAt(erc20Abi, "0x55d398326f99059fF775485246999027B3197955")

    impersonator = '0x993Ae2b514677c7AC52bAeCd8871d2b362A9D693'

    params = {
        token0: usdt.address,
        token1: floki.address,
        tickLower: -130860,
        tickUpper: 130860,
        amount0Desired: ethers.utils.parseEther("5"),
        amount1Desired: 11283000000000,
        amount0Min: 0,
        amount1Min: 0,
        recipient: impersonator,
        deadline: 1692432968
    }

    await nfpos.mint(params)
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
