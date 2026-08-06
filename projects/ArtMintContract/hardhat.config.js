require("@nomicfoundation/hardhat-ethers");
require("@nomiclabs/hardhat-etherscan");
require("dotenv").config();

const PRIVATE_KEY = process.env.PRIVATE_KEY;
const SEPOLIA_RPC = process.env.SEPOLIA_RPC;
const ETHERSCAN_KEY = process.env.ETHERSCAN_API_KEY;

const networksConfig = {
  // 本地 localhost 节点（npx hardhat node 启动用）
  localhost: {
    url: "http://127.0.0.1:8545"
  },
  // hardhat内置临时网络，默认运行脚本时使用
  hardhat: {}
};

// 仅当环境变量齐全时，才注入 sepolia 配置
if (PRIVATE_KEY && SEPOLIA_RPC && ETHERSCAN_KEY) {
  networksConfig.sepolia = {
    url: SEPOLIA_RPC,
    accounts: [PRIVATE_KEY],
    chainId: 11155111,
    gasPrice: 8000000000
  };
}

module.exports = {
  solidity: {
    version: "0.8.20",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  networks: networksConfig,
  etherscan: {
    apiKey: ETHERSCAN_KEY || ""
  }
};