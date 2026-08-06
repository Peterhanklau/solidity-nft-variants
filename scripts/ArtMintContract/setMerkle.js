const { ethers } = require("hardhat");
const { MerkleTree } = require("merkletreejs");

async function main() {
  const contractAddr = "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512";
  const nftContract = await ethers.getContractAt("ArtMintContract", contractAddr);
  const [admin, user1] = await ethers.getSigners();

  // 白名单就填本地两个测试账号
  const whiteList = [admin.address, user1.address];

  const leaves = whiteList.map((addr) => {
    const addrBytes = ethers.zeroPadValue(addr, 32);
    const numBytes = ethers.zeroPadValue("0x01", 32);
    const packed = ethers.concat([addrBytes, numBytes]);
    return ethers.keccak256(packed);
  });

  const merkleTree = new MerkleTree(leaves, ethers.keccak256, { sortPairs: true });
  const root = merkleTree.getHexRoot();
  await nftContract.setMerkleRoot(root);
  console.log("✅ 树根部署完毕:", root);

  // 顺便打印 user1 的铸造凭证
  const targetAddr = user1.address;
  const addrBytes = ethers.zeroPadValue(targetAddr, 32);
  const numBytes = ethers.zeroPadValue("0x01", 32);
  const leaf = ethers.keccak256(ethers.concat([addrBytes, numBytes]));
  const proof = merkleTree.getHexProof(leaf);
  console.log("user1 对应的 Proof =", proof);
}

main().catch(e => {
  console.error(e);
  process.exit(1);
} );