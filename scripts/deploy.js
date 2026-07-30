const { ethers } = require("hardhat");

async function main() {
  console.log("开始部署 WhitelistNFT...");

  const [deployer] = await ethers.getSigners();
  console.log("部署账户：", deployer.address);

  // 你的 NFT 元数据地址（可随便填）
  const baseURI = "ipfs://QmYourBaseURI/";

  const WhitelistNFT = await ethers.getContractFactory("WhitelistNFT");
  const nft = await WhitelistNFT.deploy(baseURI);

  await nft.waitForDeployment();
  const addr = await nft.getAddress();

  console.log("✅ 部署成功！地址：", addr);
  console.log("BaseURI：", baseURI);

  console.log("\n==== 下一步命令 ====");
  console.log("设置白名单根：npx hardhat set-root --root 0xXXX --network sepolia");
  console.log("开启白名单：npx hardhat set-phase --phase 1 --network sepolia");
  console.log("开启公开售：npx hardhat set-phase --phase 2 --network sepolia");
}

main();