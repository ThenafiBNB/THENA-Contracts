require("@nomiclabs/hardhat-waffle");
require('@openzeppelin/hardhat-upgrades');
require("@nomiclabs/hardhat-etherscan");
require("@nomiclabs/hardhat-web3");
require("dotenv").config({ path: ".env" });

const tdly = require("@tenderly/hardhat-tenderly");

tdly.setup({ automaticVerifications: false });

module.exports = {
  // latest Solidity version
  solidity: {
    compilers: [
      {
        version: "0.8.13",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
    ]
  },
  defaultNetwork: "ftmTestnet",
  networks: {
    bsc: {
      url: "https://bsc-dataseed1.binance.org",
      chainId: 56,
      accounts: [process.env.PRIVATEKEY]
    },

    bscTestnet: {
      url: "https://data-seed-prebsc-1-s1.binance.org:8545",
      chainId: 97,
      accounts: [process.env.PRIVATEKEY]
    },

    ftmTestnet: {
      url: "https://rpc.ankr.com/fantom_testnet",
      chainId: 4002,
      accounts: [process.env.PRIVATEKEY]
    },

    hardhat: {
      forking: {
        url: "https://bsc-dataseed1.binance.org",
        chainId: 56,
      },
      //accounts: []
    }

  },
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts",
  },
  mocha: {
    timeout: 100000000
  }

};