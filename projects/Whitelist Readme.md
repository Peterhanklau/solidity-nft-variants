# Genesis NFT - Merkle Tree Whitelist Presale System
📖 English Version
## Overview
Genesis NFT is an ERC721 NFT presale system powered by Merkle Tree whitelist verification.
The contract supports three mint phases: Closed / Whitelist Presale / Public Sale.
Only the Merkle root hash is stored on-chain to save gas, avoiding storing all whitelist addresses.
Project Info
- Project Name: Genesis NFT (GNFT)
- Standard: ERC-721
- Solidity: 0.8.20
- Framework: Hardhat
- Local Deployment Address: `0x5FbDB2315678afecb367f032d93F642f64180aa3`
- Sepolia Testnet Address: To be filled after deployment

## Core Features
✅ Merkle Tree Whitelist Mint
Store only merkleRoot on-chain; off-chain script generates proof for each whitelisted wallet
✅ Multi-stage Mint Control
MintPhase: CLOSED → WHITELIST → PUBLIC, controlled by contract owner
✅ Separate pricing
Whitelist Price: 0.05 ETH | Public Price: 0.08 ETH
✅ Wallet mint limit: Max 3 NFTs per wallet
✅ Total Supply Cap: 1000 NFTs
✅ Owner-only ETH withdrawal function
✅ ReentrancyGuard anti-reentrancy protection
✅ Ownable administrator permission control
✅ Gas optimized mint functions

## Tech Stack
- Language: Solidity ^0.8.20
- Dev Framework: Hardhat
- Dependencies: OpenZeppelin Contracts, ethers.js, merkletreejs, keccak256, dotenv
- Test: Mocha + Chai
- Network: Hardhat Local Node / Sepolia Testnet

## Project Structure
├── contracts/
│ └── WhitelistNFT.sol # Main ERC721 NFT contract
├── scripts/
│ ├── deploy.js # Deployment script(local + sepolia)
│ └── generate-whitelist.js # Off-chain script: generate merkle root & proof
├── test/
│ └── WhitelistNFT.test.js # Unit test cases
├── hardhat.config.js
├── .env # Environment variables(gitignore)
└── README.md
plaintext

## Environment Variables (.env)
```bash
PRIVATE_KEY=YOUR_WALLET_PRIVATE_KEY
SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/XXX
ETHERSCAN_API_KEY=YOUR_KEY
Quick Start
bash
# Clone repository
git clone [YOUR_GITHUB_URL]
cd genesis-nft-merkle-whitelist

# Install dependencies
npm install

# Compile smart contracts
npx hardhat compile

# Run all unit tests
npx hardhat test

# Start local hardhat private chain
npx hardhat node

# Deploy contract to local network
npx hardhat run scripts/deploy.js --network localhost

# Deploy to Sepolia Testnet
npx hardhat run scripts/deploy.js --network sepolia

# Verify contract on Etherscan
npx hardhat verify --network sepolia CONTRACT_ADDRESS
Off-chain Whitelist Operation
Run script to generate merkle root and individual proof for each address:
bash
node scripts/generate-whitelist.js
After getting root hash, admin calls setMerkleRoot(bytes32) to update on-chain root.
Core Contract Functions
setMerkleRoot(bytes32 _merkleRoot) Owner | Update whitelist merkle root
setPhase(MintPhase _phase) Owner | Switch mint sale stage
whitelistMint(bytes32[] calldata _proof) Payable | Whitelist presale mint
publicMint() Payable | Public sale mint
withdraw() Owner | Withdraw all ETH inside contract
Deliverables
✅ Annotated WhitelistNFT.sol source code
✅ Complete unit test scripts
✅ Dual-network deployment script
✅ Merkle tree whitelist generation script
✅ Hardhat operation guide
✅ Gas optimization report
✅ ABI json file
📖 中文版本
Genesis NFT - 基于 Merkle 树的 NFT 白名单预售系统
项目概述
Genesis NFT 是一套采用 Merkle 树实现白名单校验的 ERC721 NFT 预售智能合约系统。
合约分为三种铸造阶段：关闭状态 / 白名单预售 / 公开售卖。
仅将 Merkle 树根哈希存储在链上，极大节省 Gas，不需要在合约内存放全部白名单地址。
项目信息
项目名称：Genesis NFT（GNFT）
代币标准：ERC-721
Solidity 版本：0.8.20
开发框架：Hardhat
本地部署合约地址：0x5FbDB2315678afecb367f032d93F642f64180aa3
Sepolia 测试网地址：部署后填写
核心功能
✅ Merkle 树白名单铸造
链上仅保存 merkleRoot，链下脚本批量生成每个钱包对应的 Proof 证明
✅ 多阶段铸造管控
铸造阶段：关闭 → 白名单预售 → 公开售卖，由合约管理员切换
✅ 阶梯定价
白名单售价：0.05 ETH | 公开售价：0.08 ETH
✅ 单钱包铸造上限：最多铸造 3 枚 NFT
✅ 总量上限：1000 枚
✅ 管理员提款函数，提取合约内全部 ETH
✅ ReentrancyGuard 防重入攻击
✅ Ownable 管理员权限隔离
✅ 铸造函数 Gas 优化
技术栈
语言：Solidity ^0.8.20
开发框架：Hardhat
依赖库：OpenZeppelin 合约库、ethers.js、merkletreejs、keccak256、dotenv
单元测试：Mocha + Chai
运行网络：Hardhat 本地私有链 / Sepolia 以太坊测试网
项目目录结构
plaintext
├── contracts/
│   └── WhitelistNFT.sol       # ERC721主合约
├── scripts/
│   ├── deploy.js              # 部署脚本（本地链+Sepolia）
│   └── generate-whitelist.js  # 链下脚本：生成Merkle树根与地址证明
├── test/
│   └── WhitelistNFT.test.js   # 单元测试用例
├── hardhat.config.js
├── .env                       # 环境变量（禁止提交git）
└── README.md
环境变量配置 (.env)
bash
PRIVATE_KEY=你的钱包私钥
SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/XXX
ETHERSCAN_API_KEY=你的Etherscan密钥
快速部署命令
bash
# 克隆仓库
git clone [你的GitHub仓库地址]
cd genesis-nft-merkle-whitelist

# 安装依赖
npm install

# 编译合约
npx hardhat compile

# 执行单元测试
npx hardhat test

# 启动Hardhat本地私有链
npx hardhat node

# 部署到本地网络
npx hardhat run scripts/deploy.js --network localhost

# 部署Sepolia测试网
npx hardhat run scripts/deploy.js --network sepolia

# Etherscan自动验证合约
npx hardhat verify --network sepolia 合约地址
白名单操作流程
运行脚本批量导入地址，自动生成 Merkle Root 与每个地址对应的 Proof 数组：
bash
node scripts/generate-whitelist.js
获取树根哈希后，管理员调用 setMerkleRoot(bytes32) 更新链上树根。
合约核心函数
setMerkleRoot(bytes32 _merkleRoot) 管理员权限 | 更新白名单 Merkle 树根
setPhase(MintPhase _phase) 管理员权限 | 切换铸造阶段
whitelistMint(bytes32[] calldata _proof) 付费 | 白名单铸造
publicMint() 付费 | 公开铸造
withdraw() 管理员权限 | 提取合约全部 ETH
项目交付物清单
✅ 完整注释智能合约 WhitelistNFT.sol
✅ 全套单元测试脚本
✅ 双网络部署脚本
✅ Merkle 白名单树根生成脚本
✅ Hardhat 控制台交互操作手册
✅ Gas 优化分析报告
✅ ABI 文件