const { ethers  } = require('hardhat');

const { ZERO_ADDRESS } = require("@openzeppelin/test-helpers/src/constants.js");
const { erc20Abi, CLRouterAbi, algebraRouterAbi } = require("./Abi.js")



async function main () {

    accounts = await ethers.getSigners();
    owner = accounts[0]

    usdc = await ethers.getContractAt(erc20Abi, "0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d")
    impersonator = '0x993Ae2b514677c7AC52bAeCd8871d2b362A9D693'
    
    const algebraRouterAddress = ethers.utils.getAddress("0x327Dd3208f0bCF590A66110aCB6e5e6941A4EfA0")
    algebrarouter = await ethers.getContractAt(algebraRouterAbi, algebraRouterAddress)

    const parameters = {
        tokenIn: usdc.address,
        tokenOut: '0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c',
        recipient: impersonator,
        deadline: 1681727850,
        amountIn: ethers.utils.parseEther("0.5"),
        amountOutMinimum: ethers.utils.parseEther("0"),
        limitSqrtPrice: 0
    }
    

    await algebrarouter.exactInputSingle(parameters)   


}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
