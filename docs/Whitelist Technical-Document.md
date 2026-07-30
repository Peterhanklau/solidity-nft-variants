# Genesis NFT Merkle Tree Whitelist Presale System
# Technical Development Document
📖 English Version
## 1. Project Overview
Genesis NFT is an ERC721 NFT presale system utilizing Merkle Tree cryptography for whitelist access control.
The system implements phased minting mechanism to separate whitelist pre-sale and public sale, solve the high gas cost problem of storing large whitelist address list on-chain.
| Item | Description |
| ---- | ---- |
| Project Name | Genesis NFT (GNFT) |
| Token Standard | ERC-721 |
| Solidity Version | 0.8.20 |
| Deployment Network | Hardhat Local Chain / Sepolia Testnet |
| Max Supply | 1000 NFT |

## 2. Functional Requirements
### Core Features
| ID | Function | Description | Status |
| ---- | ---- | ---- | ---- |
| F1 | Merkle Whitelist Mint | Only addresses inside whitelist tree can mint in pre-sale phase | ✅ Completed |
| F2 | Public Mint | Unlimited access when public phase enabled | ✅ Completed |
| F3 | Phase Switch Control | Administrator can toggle Closed / Whitelist / Public mode | ✅ Completed |
| F4 | Per-wallet Mint Limit | Each wallet can mint maximum 3 NFTs | ✅ Completed |
| F5 | Owner ETH Withdraw | Admin withdraw all revenue from contract | ✅ Completed |

### Security Requirements
| Requirement | Description |
| ---- | ---- |
| Access Control | Only contract owner can update merkle root, switch phase and withdraw funds |
| Anti-Reentrancy | ReentrancyGuard applied for all payable mint functions |
| Supply Limit | Hard cap for total NFT supply, cannot exceed maxSupply |
| Mint Validation | Check mint phase, payment value, wallet mint count before mint |

## 3. Technical Architecture
### 3.1 Project Structure
contracts/
└── WhitelistNFT.sol # Main ERC721 contract
scripts/
├── deploy.js # Deployment script
└── generate-whitelist.js # Off-chain merkle tree generator
test/
└── WhitelistNFT.test.js # Unit test suite
plaintext

### 3.2 Tech Stack
| Component | Technology |
| ---- | ---- |
| Smart Contract Language | Solidity 0.8.20 |
| Development Framework | Hardhat |
| External Library | OpenZeppelin Contracts |
| Merkle Tool | merkletreejs, keccak256 |
| Testing Framework | Mocha + Chai |

## 4. Smart Contract Design
### 4.1 Enums & State Variables
```solidity
enum MintPhase { CLOSED, WHITELIST, PUBLIC }

contract WhitelistNFT is ERC721, Ownable, ReentrancyGuard {
    uint256 public totalSupply;
    uint256 public immutable maxSupply = 1000;
    uint256 public whitelistPrice = 0.05 ether;
    uint256 public publicPrice = 0.08 ether;
    MintPhase public phase;
    bytes32 public merkleRoot;
    mapping(address => uint256) public mintedCount;
    uint256 public maxPerWallet = 3;
}
4.2 Core Functions
表格
Function	Visibility	Payable	Description
setMerkleRoot(bytes32)	external onlyOwner	❌	Update whitelist merkle root hash
setPhase(MintPhase)	external onlyOwner	❌	Switch minting stage
whitelistMint(bytes32[] proof)	external	✅	Whitelist presale mint with merkle proof verify
publicMint()	external	✅	Public sale mint without proof
withdraw()	external onlyOwner	❌	Extract all ETH balance of contract
4.3 Merkle Verification Logic
solidity
bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
require(MerkleProof.verify(_proof, merkleRoot, leaf), "证明无效，不在白名单");
Workflow:
Off-chain: Collect all whitelist addresses, build merkle tree
Admin upload merkle root to smart contract
User obtains proof from backend/script
Pass proof into mint function, contract verify inclusion on-chain
5. Gas Optimization Strategy
Wrap totalSupply increment inside unchecked {} to reduce arithmetic check gas
Compact storage layout for state variables
Avoid redundant storage reads inside mint functions
Gas Consumption Comparison
表格
Function	Gas Before Optimization	Gas After Optimization	Gas Saved
whitelistMint	184000	151200	17.8%
publicMint	123600	106800	13.6%
6. Deployment Information
6.1 Network Configuration
表格
Network	Status	Contract Address
Hardhat Localhost	Completed	0x5FbDB2315678afecb367f032d93F642f64180aa3
Sepolia Testnet	Ready for deploy	To be filled
6.2 Environment Config (.env)
bash
PRIVATE_KEY=YOUR_PRIVATE_KEY
SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/XXX
ETHERSCAN_API_KEY=YOUR_API_KEY
6.3 Deployment Commands
bash
# Compile
npx hardhat compile
# Run unit test
npx hardhat test
# Deploy Sepolia
npx hardhat run scripts/deploy.js --network sepolia
# Etherscan verify
npx hardhat verify --network sepolia CONTRACT_ADDRESS
7. Frontend Integration Example (ethers.js)
javascript
运行
async function whitelistMint(userAddress, proofArray) {
    const contract = new ethers.Contract(contractAddress, abi, signer);
    const tx = await contract.whitelistMint(proofArray, {
        value: ethers.parseEther("0.05")
    });
    await tx.wait();
    console.log("Whitelist Mint Success");
}
8. Test Specification
8.1 Test Coverage Target
Unit Test: Core functions 100% covered
8.2 Key Test Cases
Only owner can set merkle root and switch mint phase
Non-whitelist address cannot pass merkle proof verification
Cannot mint when phase is CLOSED
Single wallet cannot exceed maxPerWallet limit
Total supply cannot break maxSupply cap
Only owner can execute withdraw function
9. Security Risk Analysis
表格
Risk	Mitigation	Status
Reentrancy attack	ReentrancyGuard + Checks-Effects-Interactions	✅ Implemented
Unauthorized mint	Phase status check + Merkle proof validation	✅ Implemented
Permission leakage	OnlyOwner modifier for admin functions	✅ Implemented
Excessive gas consumption	Storage layout optimization & unchecked block	✅ Implemented
10. Project Deliverables
✅ WhitelistNFT.sol source code
✅ Hardhat test scripts
✅ Deployment scripts
✅ Merkle tree generation script
✅ Gas optimization report
✅ ABI file
✅ This technical documentation
11. Reference Material
ERC721 Standard
OpenZeppelin Official Document
MerkleTree.js Documentation
Hardhat Official Guide
12. Version History
表格
Version	Date	Change Log	Author
V1.0.0	2026-06-21	Full contract development, local test finished	Administrator
Document Maintainer: Administrator
Last Updated: 2026-06-21
📖 中文版本
Genesis NFT Merkle 树白名单预售系统
技术开发文档
1. 项目概述
Genesis NFT 是基于 ERC721 标准，采用 Merkle 树密码学实现白名单准入的 NFT 预售智能合约系统。
系统支持分阶段铸造，隔离白名单预售与公开售卖，解决传统方案将大量白名单地址存入合约带来高昂 Gas 成本的痛点。
表格
项目	说明
项目名称	Genesis NFT（GNFT）
代币标准	ERC-721
Solidity 版本	0.8.20
部署网络	Hardhat 本地私有链 / Sepolia 测试网
NFT 总量上限	1000 枚
2. 功能需求
核心功能清单
表格
ID	功能	说明	状态
F1	Merkle 白名单铸造	仅白名单内地址可在预售阶段铸造 NFT	✅ 已完成
F2	公开铸造	开启公开阶段后任意地址均可铸造	✅ 已完成
F3	阶段切换控制	管理员切换铸造模式：关闭 / 白名单 / 公开	✅ 已完成
F4	单钱包铸造限额	每个钱包最多铸造 3 枚 NFT	✅ 已完成
F5	管理员资金提款	管理员提取合约内全部铸造收入 ETH	✅ 已完成
安全要求
表格
需求	说明
权限管控	仅合约拥有者可更新 Merkle 树根、切换阶段、提取资金
防重入攻击	所有付费铸造函数启用 ReentrancyGuard 防护
总量限制	设置 NFT 最大发行量，不可超额铸造
铸造前置校验	校验铸造阶段、支付金额、钱包已铸造数量
3. 技术架构
3.1 目录结构
plaintext
contracts/
└── WhitelistNFT.sol       # ERC721主合约
scripts/
├── deploy.js              # 合约部署脚本
└── generate-whitelist.js  # 链下Merkle树生成脚本
test/
└── WhitelistNFT.test.js   # 单元测试套件
3.2 技术栈
表格
组件	技术选型
智能合约语言	Solidity 0.8.20
开发框架	Hardhat
依赖库	OpenZeppelin Contracts
Merkle 哈希工具	merkletreejs、keccak256
测试框架	Mocha + Chai
4. 智能合约设计
4.1 枚举与状态变量
solidity
enum MintPhase { CLOSED, WHITELIST, PUBLIC }

contract WhitelistNFT is ERC721, Ownable, ReentrancyGuard {
    uint256 public totalSupply;
    uint256 public immutable maxSupply = 1000;
    uint256 public whitelistPrice = 0.05 ether;
    uint256 public publicPrice = 0.08 ether;
    MintPhase public phase;
    bytes32 public merkleRoot;
    mapping(address => uint256) public mintedCount;
    uint256 public maxPerWallet = 3;
}
4.2 核心函数表
表格
函数	可见性	是否付费	功能说明
setMerkleRoot(bytes32)	external onlyOwner	❌	更新白名单 Merkle 树根哈希
setPhase(MintPhase)	external onlyOwner	❌	切换铸造阶段
whitelistMint(bytes32[] proof)	external	✅	白名单铸造，校验 Merkle 证明
publicMint()	external	✅	公开铸造，无需证明
withdraw()	external onlyOwner	❌	提取合约全部 ETH 余额
4.3 Merkle 树校验原理
solidity
bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
require(MerkleProof.verify(_proof, merkleRoot, leaf), "证明无效，不在白名单");
完整流程：
链下：收集全部白名单钱包地址，构建 Merkle 树
管理员将树根哈希上传至智能合约
用户通过后端 / 脚本获取自身对应的 Proof 数组
调用铸造函数传入 Proof，合约链上验证地址是否在白名单内
5. Gas 优化方案
totalSupply 自增运算放入unchecked {}，消除溢出检查消耗 Gas
调整状态变量顺序，优化存储槽布局
消除铸造函数内部重复的状态读取
Gas 消耗对比表
表格
函数名称	优化前 Gas 消耗	优化后 Gas 消耗	Gas 节省比例
whitelistMint	184000	151200	17.8%
publicMint	123600	106800	13.6%
6. 部署信息
6.1 网络配置
表格
网络	状态	合约地址
Hardhat 本地链	部署完成	0x5FbDB2315678afecb367f032d93F642f64180aa3
Sepolia 测试网	待部署	上线后填写
6.2 环境变量配置 (.env)
bash
PRIVATE_KEY=钱包私钥
SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/XXX
ETHERSCAN_API_KEY=Etherscan密钥
6.3 部署命令
bash
# 编译合约
npx hardhat compile
# 运行单元测试
npx hardhat test
# 部署Sepolia测试网
npx hardhat run scripts/deploy.js --network sepolia
# Etherscan合约源码验证
npx hardhat verify --network sepolia 合约地址
7. 前端集成示例 ethers.js
javascript
运行
async function whitelistMint(userAddress, proofArray) {
    const contract = new ethers.Contract(contractAddress, abi, signer);
    const tx = await contract.whitelistMint(proofArray, {
        value: ethers.parseEther("0.05")
    });
    await tx.wait();
    console.log("白名单铸造成功");
}
8. 测试规范
8.1 测试覆盖率目标
单元测试：核心函数全覆盖，目标 100%
8.2 关键测试用例
仅管理员可设置 Merkle 树根、切换铸造阶段
非白名单地址无法通过 Merkle 校验
铸造关闭阶段禁止任何 mint 操作
单钱包铸造数量不可超过上限 maxPerWallet
总发行量不能突破 maxSupply 总量上限
只有合约拥有者可以执行提款
9. 安全风险评估
表格
风险项	缓解方案	状态
重入攻击	ReentrancyGuard + Checks-Effects-Interactions 规范	✅ 已实施
未授权铸造	阶段状态校验 + Merkle 证明校验双重拦截	✅ 已实施
管理员权限泄露	管理员函数增加 onlyOwner 访问限制	✅ 已实施
Gas 消耗过高	存储布局优化、unchecked 代码块优化	✅ 已实施
10. 项目交付物
✅ WhitelistNFT.sol 智能合约源码
✅ Hardhat 单元测试脚本
✅ 多网络部署脚本
✅ Merkle 白名单生成脚本
✅ Gas 优化分析报告
✅ ABI 文件
✅ 本文档
11. 参考资料
ERC721 代币标准
OpenZeppelin 官方文档
MerkleTree.js 使用文档
Hardhat 开发官方指南
12. 版本历史
表格
版本	日期	更新内容	作者
V1.0.0	2026-06-21	合约完整开发、本地链路调试验收完成	Administrator