const { ethers } = require("hardhat");
async function main() {
  const addr = "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512";
  const nft = await ethers.getContractAt("ArtMintContract", addr);
  await nft.setPhase(1);
  console.log("已开启白名单铸造阶段");
}
main().catch(console.error);