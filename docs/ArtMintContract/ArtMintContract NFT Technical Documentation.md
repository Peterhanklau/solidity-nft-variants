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

## Project Delivery Materials List
•contracts/ directory: Solidity NFT contract source code (core business logic)
•scripts/ directory: Deployment scripts, merkle root setup scripts (essential for deployment/operation)
•test/ directory: Unit test cases (function verification, compliance testing)
•hardhat.config.js: Adaptive network configuration file (local + Sepolia dual-environment adaptation)
•package.json, package-lock.json: Project dependency configuration (ensure environment consistency)
•.env.example: Environment variable template (no sensitive information, for receiver configuration)
•README.md: Project usage instructions (installation, deployment, debugging guidance)
•Technical Documentation.md: Project technical architecture, contract interfaces, security instructions (for development/audit docking)
