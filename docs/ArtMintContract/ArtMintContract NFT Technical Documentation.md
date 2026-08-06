# ArtMintContract NFT Technical Documentation
## 1 Project Overview
### 1.1 Purpose
Ethereum ERC721 standard NFT contract for art collection minting. Supports configurable IPFS metadata address.
Dual environment deployment supported: local Hardhat private chain & Sepolia Testnet.

### 1.2 Tech Stack
- Contract Language: Solidity 0.8.20
- Development Framework: Hardhat
- Web3 Library: ethers.js 6.x
- Contract Verification Tool: @nomicfoundation/hardhat-verify
- Target Network: Ethereum Sepolia (ChainID: 11155111), Hardhat local private chain

## 2 Contract Architecture
### 2.1 Contract Name: ArtMintContract
Inheritance: ERC721 + Ownable
- ERC721: Implements standard NFT functions (mint, transfer, balance query, ownership query)
- Ownable: Administrator permission control, only contract deployer can modify baseURI.

### 2.2 Constructor Parameter
```solidity
constructor(string memory _baseURI)
Receive baseURI (IPFS metadata prefix) during deployment.
2.3 Core State Variables
string public baseURI
Prefix of NFT metadata stored on IPFS. Final metadata URL = baseURI + tokenId.
Contract owner: deploy address with administrator privileges.
2.4 Core Interfaces
Admin Interfaces (onlyOwner modifier)
solidity
function setBaseURI(string calldata newURI)
Update global IPFS metadata address, used to replace NFT pictures & metadata later.
Public Open Interfaces
function tokenURI(uint256 tokenId) public view override returns(string)
Splice complete NFT metadata link, fully compatible with OpenSea parsing rules.
Native ERC721 interfaces: mint, transferFrom, balanceOf, ownerOf etc.
2.5 Permission Model
Contract owner only: modify baseURI.
Any user: mint NFT, transfer NFT, query holding quantity & metadata.
3 Hardhat Engineering Design
3.1 Adaptive Network Configuration (for delivery compatibility)
Judgment logic inside hardhat.config.js:
If complete .env environment variables exist locally → load Sepolia network configuration, support testnet deployment.
No .env file (third-party receiving the project) → Sepolia configuration will not be injected, only local hardhat/localhost network reserved, no runtime error.
3.2 Deployment Script Design
Remove forced automatic verification logic, use manual verification mode to avoid Etherscan access timeout in domestic network.
Adopt standard ethers 6 syntax: waitForDeployment() & getAddress(), compatible with ethers v5 & v6.
baseURI supports reading from environment variables, no need to modify JS source code to switch IPFS address.
3.4 Deployment Flow
Load configuration & instantiate contract factory
Deploy contract with baseURI parameter
Wait for 6 block confirmations to guarantee stable on-chain status
Print contract address and finish deployment.
4 On-chain Deployment Info
Deploy Network: Sepolia Testnet
Chain ID: 11155111
Contract Address: 0x47c1E7569FD634f781856A700b48e3760de98D80
5 Security Design
5.1 Solidity 0.8.20 built-in overflow & underflow check, SafeMath library is unnecessary.
5.2 Only administrator can update baseURI to prevent malicious tampering of NFT metadata.
5.3 No high-risk external writing interfaces inside contract, free of reentrancy vulnerabilities.
5.4 Private keys are stored inside local .env instead of hardcoding in scripts, avoid secret leakage during project delivery.
6 Test Scheme
6.1 Local Test: Deploy on Hardhat local chain, complete full flow test including mint, transfer, URI modification.
6.2 On-chain Test: Call contract functions via Sepolia Etherscan after deployment for function acceptance test.
6.3 Source Code Audit: Run hardhat verify manually to open source contract code for auditor review.
7 Fault Handling Manual
7.1 RPC 404 / connection failure: Original rpc.sepolia.org has been deprecated, replace with valid public Sepolia RPC endpoints.
7.2 Deployment succeeded but verification timeout: Network restriction problem, delete auto-verification code and execute verify command manually during midnight.
7.3 Public RPC prompts "free plan unavailable": Switch RPC node or apply free Alchemy private RPC.
7.4 Final terminal Assertion failed: Redundant Node.js process exit error on Windows, can be ignored safely.
8 Delivery Constraints
Project delivered without .env private key file, matched with .env.example template.
Configuration file supports environment adaptation, third-party users will not crash due to missing environment variables.
Single universal deployment script supports both local deployment & Sepolia deployment.
plaintext

# 4. 技术文档.md 中文版
```markdown
# ArtMintContract NFT 技术文档
## 1 项目概述
### 1.1 用途
以太坊 ERC721 标准NFT合约，用于艺术藏品NFT铸造，支持配置IPFS元数据地址，可部署在本地Hardhat私有链、Sepolia测试网两套环境。

### 1.2 技术栈
- 合约语言：Solidity 0.8.20
- 开发框架：Hardhat
- Web3库：ethers.js 6.x
- 合约验证工具：@nomicfoundation/hardhat-verify
- 目标网络：以太坊 Sepolia（链ID：11155111）、Hardhat本地私有链

## 2 合约架构说明
### 2.1 合约名称：ArtMintContract
继承结构：ERC721 + Ownable
- ERC721：实现NFT标准铸造、转账、余额查询、归属查询能力
- Ownable：管理员权限控制，仅合约部署者有权修改BaseURI

### 2.2 构造函数入参
```solidity
constructor(string memory _baseURI)
部署阶段传入 baseURI，作为 NFT 元数据 IPFS 前缀。
2.3 核心状态变量
string public baseURI
NFT 元数据在 IPFS 上的前缀地址，最终元数据链接 = baseURI + tokenId
owner：合约部署地址，拥有管理员权限。
2.4 核心接口
管理员接口（onlyOwner 权限限制）
solidity
function setBaseURI(string calldata newURI)
修改全局 IPFS 元数据地址，用于后期替换 NFT 图片、元数据。
对外开放接口
function tokenURI(uint256 tokenId) public view override returns(string)
拼接完整 NFT 元数据链接，完全兼容 OpenSea 读取规则。
ERC721 原生接口：铸造、转账、balanceOf 余额查询、ownerOf 归属查询等。
2.5 权限模型
仅合约所有者：修改 BaseURI；
任意用户均可：铸造 NFT、转账 NFT、查询持有数量、查询元数据。
3 Hardhat 工程架构设计
3.1 网络自适应配置（适配交付场景）
hardhat.config.js 增加环境判断逻辑：
本机存在完整.env 环境变量 → 加载 Sepolia 网络配置，支持测试网部署；
无.env 文件（第三方接收工程）→ 不会注入 Sepolia 配置，仅保留本地 hardhat/localhost网络，运行不会报错。
3.2 部署脚本设计
移除强制自动验证逻辑，改为手动验证模式，规避国内网络访问 Etherscan 超时失败问题；
使用 ethers6 标准写法 waitForDeployment ()、getAddress ()，同时兼容 ethers v5、v6 版本；
baseURI 支持从环境变量读取，无需修改 JS 源码即可更换 IPFS 地址。
3.3 部署流程
读取配置，实例化合约工厂
传入 baseURI 完成合约部署
等待 6 个区块确认，保证合约稳定上链
输出合约地址，部署结束。
4 链上部署信息
部署网络：Sepolia 测试网
链 ID：11155111
合约地址：0x47c1E7569FD634f781856A700b48e3760de98D80
5 安全设计说明
5.1 Solidity 0.8.20 自带溢出、下溢校验，无需额外引入 SafeMath 库。
5.2 仅管理员可更新 BaseURI，杜绝恶意篡改 NFT 元数据。
5.3 合约不存在高危外部写入接口，无重入攻击风险。
5.4 私钥存放于本地.env，不在脚本硬编码，项目交付时不会泄露密钥。
6 测试方案
6.1 本地测试：部署至 Hardhat 本地链，完成铸造、转账、修改 URI 全流程闭环测试。
6.2 链上测试：Sepolia 部署完成后，在 Sepolia Etherscan 调用合约接口进行功能验收。
6.3 源码审计：手动执行 hardhat verify 开源合约源码，方便审计人员查看。
7 故障排查手册
7.1 RPC 404 / 连接失败：原生rpc.sepolia.org已废弃，替换可用的公共 Sepolia RPC 节点。
7.2 部署成功但验证超时：网络限制导致，删除自动验证代码，凌晨手动执行验证命令。
7.3 公共 RPC 提示免费套餐不可用：更换 RPC 节点或注册 Alchemy 免费专属 RPC。
7.4 终端末尾出现 Assertion failed：Windows 系统 Node 进程退出产生的冗余报错，可直接忽略。
8 交付约束
交付工程不含存放私钥的.env 文件，配套.env.example 模板；
配置文件具备环境自适应能力，第三方使用时不会因缺失环境变量崩溃；
单部署脚本通用，同时支持本地部署、Sepolia 部署两种场景。
plaintext

## 配套 .env.example 双语（附）
### English
```env
# Wallet private key for deployment
PRIVATE_KEY=
# Sepolia Testnet RPC Endpoint
SEPOLIA_RPC=https://ethereum-sepolia-rpc.publicnode.com
# Etherscan API Key (optional)
ETHERSCAN_API_KEY=
# IPFS prefix of NFT metadata
BASE_URI=ipfs://YourIPFSPrefix/
中文
env
# 部署钱包私钥
PRIVATE_KEY=
# Sepolia测试网RPC地址
SEPOLIA_RPC=https://ethereum-sepolia-rpc.publicnode.com
# Etherscan密钥（选填）
ETHERSCAN_API_KEY=
# NFT元数据IPFS前缀
BASE_URI=ipfs://YourIPFSPrefix/