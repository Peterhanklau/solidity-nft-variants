ArtMint NFT Hardhat Project
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