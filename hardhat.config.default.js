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
        ],
    },
    defaultNetwork: "arbitrum",
    networks: {
        arbitrum: {
            url: "https://arb1.arbitrum.io/rpc",
            chainId: 42161,
            accounts: [ process.env.PRIVATEKEY ],
        },

        hardhat: {
            forking: {
                url: "https://eth.llamarpc.com",
                chainId: 1,
            },
            accounts: [ process.env.PRIVATEKEY ],
        },

    },
    paths: {
        sources: "./contracts",
        tests: "./test",
        cache: "./cache",
        artifacts: "./artifacts",
    },
    mocha: {
        timeout: 100000000,
    },

};
