# NFT Membership Pass - Smart Contract
# NFT会员卡 - 智能合约

[![Solidity](https://img.shields.io/badge/Solidity-0.8.20-blue)](https://soliditylang.org/)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)
[![Hardhat](https://img.shields.io/badge/Hardhat-2.19.0-yellow)](https://hardhat.org/)

---

## 📖 English Version

### Overview
A complete NFT membership card system for FitChain Gym, implementing ERC721 standard with tiered membership levels.

### Features
- ✅ **ERC721 Implementation** - Standard NFT membership cards
- ✅ **Three Membership Tiers** (Bronze/Silver/Gold)
  - Bronze: 0.05 ETH
  - Silver: 0.1 ETH
  - Gold: 0.2 ETH
- ✅ **Upgrade Mechanism** - Pay the difference to upgrade tiers
- ✅ **Annual Fee Check** - Verify membership expiration
- ✅ **Benefits Query** - Different benefits per tier

### Technical Stack
- **Language**: Solidity 0.8.20
- **Framework**: Hardhat
- **Library**: OpenZeppelin Contracts 4.9
- **Testing**: 100% coverage target

### Deliverables
1. ✅ Full smart contract code (with comments)
2. ✅ Unit test scripts (≥90% coverage)
3. ✅ Deployment scripts
4. ✅ Contract verification (Etherscan)
5. ✅ Technical documentation (ABI, functions, examples)
6. ✅ Gas optimization report

---

## 📖 中文版本

### 项目概述
为FitChain健身房开发一套完整的NFT会员卡系统，基于ERC721标准实现多等级会员管理。

### 功能特性
- ✅ **ERC721标准实现** - 标准NFT会员卡
- ✅ **三个会员等级**（青铜/白银/黄金）
  - 青铜会员：0.05 ETH
  - 白银会员：0.1 ETH
  - 黄金会员：0.2 ETH
- ✅ **升级机制** - 补差价升级会员等级
- ✅ **年费检查** - 查询会员是否过期
- ✅ **权益查询** - 根据等级返回不同权益

### 技术栈
- **语言**：Solidity 0.8.20
- **框架**：Hardhat
- **库**：OpenZeppelin Contracts 4.9
- **测试**：100%覆盖率目标

### 交付物
1. ✅ 完整智能合约代码（含注释）
2. ✅ 单元测试脚本（≥90%覆盖率）
3. ✅ 部署脚本
4. ✅ 合约验证证明（Etherscan）
5. ✅ 技术文档（函数说明、ABI、使用示例）
6. ✅ Gas优化报告

---

## 🚀 Getting Started / 快速开始

### English
```bash
# Clone the repository
git clone https://github.com/yourname/nft-membership.git

# Install dependencies
npm install

# Compile contracts
npx hardhat compile

# Run tests
npx hardhat test

# Deploy to Sepolia
npx hardhat run scripts/deploy.js --network sepolia
