const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deployer Wallet:", deployer.address);

  const NFTContractFactory = await ethers.getContractFactory("NFTStakeToken");
  // 只传构造参数：名称、符号、初始URI，不要多加任何多余参数
  const nft = await NFTContractFactory.deploy("StakeNFT", "SNFT", "");
  await nft.waitForDeployment();
  const nftAddr = await nft.getAddress();

  console.log(`✅ NFT 部署完成，合约地址：${nftAddr}`);
  console.log("⚠️ 复制上面地址填入 deploy-stake 质押部署脚本");
}

main()
  .catch((err) => {
    console.error(err);
    process.exitCode = 1;
  });