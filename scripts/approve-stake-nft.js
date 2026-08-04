const { ethers } = require("hardhat");
const NFT_ADDR = "你的NFT合约地址";
const STAKE_CONTRACT = "你的质押合约地址";

async function main() {
  const [signer] = await ethers.getSigners();
  const nft = await ethers.getContractAt("NFTStakeToken", NFT_ADDR, signer);

  const tx = await nft.setApprovalForAll(STAKE_CONTRACT, true);
  await tx.wait();
  console.log(`✅ 已授权质押合约托管全部NFT`);
}

main().catch(err => {
  console.error(err);
  process.exit(1);
});