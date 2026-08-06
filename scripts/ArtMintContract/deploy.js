const { ethers } = require("hardhat");
const hre = require("hardhat");

async function main() {
  console.log("部署 ArtMintContract");
  const baseURI = "ipfs://YourIPFSPrefix/";
  const ArtMintContract = await ethers.getContractFactory("ArtMintContract");
  const nft = await ArtMintContract.deploy(baseURI);

  await nft.waitForDeployment();
  const contractAddress = await nft.getAddress();
  console.log("合约地址：", contractAddress);

  // 等待区块确认
  await nft.deploymentTransaction().wait(6);

  // 自动验证
  await hre.run("verify:verify", {
    address: contractAddress,
    constructorArguments: [baseURI],
  });
  console.log("合约验证完成");
}

main().catch(err => {
  console.error(err);
  process.exit(1);
});