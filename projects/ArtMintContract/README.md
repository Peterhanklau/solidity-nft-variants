# ArtMint NFT Hardhat Project
ERC721 NFT contract developed based on Hardhat + Ethers.js v6.
Supports local node debugging & Sepolia Testnet deployment, engineering available for external delivery.

## Project Structure
my-hardhat-project
├── contracts/ # Solidity NFT source codes
├── scripts/ # Deployment scripts & merkle root setup scripts
├── test/ # Unit test cases
├── hardhat.config.js # Network config (local + Sepolia adaptive)
├── .env.example # Env template for delivery (no private keys inside)
├── package.json
└── README.md
plaintext

## Environment Requirements
- Node.js >= 18
- npm / pnpm package manager
- Hardhat 2.x
- ethers.js v6

## Install Dependencies
```bash
npm install
Environment Configuration
Copy .env.example and rename it to .env
Fill in the configuration content:
env
PRIVATE_KEY=Your deployment wallet private key
SEPOLIA_RPC=Public Sepolia RPC endpoint
ETHERSCAN_API_KEY=API key applied from Etherscan (optional)
BASE_URI=ipfs://xxx/ IPFS prefix for NFT metadata
Execution Commands
1. Local Debug (Hardhat built-in private chain, no private key required)
bash
npx hardhat run scripts/deploy.js
2. Deploy to Ethereum Sepolia Testnet
bash
npx hardhat run scripts/deploy.js --network sepolia
Contract address will be printed after successful deployment.
3. Manual Contract Verification (solve Etherscan timeout issue in domestic network)
bash
npx hardhat verify --network sepolia CONTRACT_ADDRESS "ipfs://YourIPFSPrefix/"
Deployed Contract Address
Sepolia Testnet: 0x47c1E7569FD634f781856A700b48e3760de98D80
Delivery Specification
Deliverable files: contracts, scripts, test, hardhat.config.js, package.json, .env.example, documents.
Forbidden to deliver: .env, node_modules, cache, artifacts (prevent private key leakage).
Third parties without .env file can only run local tests, Sepolia network will not be loaded automatically.
Common Troubleshooting
RPC 404 / connection timeout: Replace with available public Sepolia RPC nodes.
Deployment succeeded but verification timed out: Remove auto-verification logic inside script, run verify command manually at midnight.
NPM vulnerability alerts: Vulnerabilities only exist in dev dependencies, no impact on on-chain contract security, no need to fix.
plaintext

# 2. README.md 中文版
```markdown
# ArtMint NFT Hardhat 项目
基于 Hardhat + Ethers.js v6 开发的 ERC721 NFT 铸造合约，支持本地节点调试、Sepolia 测试网部署，工程可对外交付。

## 项目目录结构
my-hardhat-project
├── contracts/ # Solidity NFT 合约源码
├── scripts/ # 部署脚本、白名单树根配置脚本
├── test/ # 单元测试用例目录
├── hardhat.config.js # 网络配置（本地链 + Sepolia 自适应加载）
├── .env.example # 环境变量交付模板（不含私钥）
├── package.json
└── README.md
plaintext

## 环境依赖要求
- Node.js >= 18
- npm / pnpm 包管理器
- Hardhat 2.x
- ethers.js v6

## 安装依赖
```bash
npm install
环境配置步骤
复制 .env.example 文件，重命名为 .env
填写配置内容：
env
PRIVATE_KEY=部署钱包私钥
SEPOLIA_RPC=可用的Sepolia公共RPC节点地址
ETHERSCAN_API_KEY=在Etherscan官网申请的密钥（选填）
BASE_URI=ipfs://xxx/ NFT元数据对应的IPFS前缀
运行指令
1. 本地调试（Hardhat 内置私有链，无需私钥）
bash
npx hardhat run scripts/deploy.js
2. 部署至以太坊 Sepolia 测试网
bash
npx hardhat run scripts/deploy.js --network sepolia
部署成功后控制台会输出合约地址。
3. 手动验证合约（解决国内网络访问 Etherscan 超时问题）
bash
npx hardhat verify --network sepolia 合约地址 "ipfs://YourIPFSPrefix/"
已部署合约地址
Sepolia 测试网：0x47c1E7569FD634f781856A700b48e3760de98D80
交付规范
需要交付内容：contracts、scripts、test、hardhat.config.js、package.json、.env.example、配套文档。
禁止交付：.env、node_modules、cache、artifacts，避免私钥泄露。
其他人员拿到工程若无.env 文件，仅可执行本地测试，不会加载 Sepolia 网络配置。