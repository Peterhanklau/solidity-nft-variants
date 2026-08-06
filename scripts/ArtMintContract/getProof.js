const { ethers } = require("hardhat");
const { MerkleTree } = require("merkletreejs");

async function main() {
  const whiteList = [
    "0x90F79bf6EB2c4f870365E785982E1f101E93b906",
    "0x15d34AAf5426A8D70Ec59b75d985F82892f057Cb"
  ];
  const targetAddress = "0x90F79bf6EB2c4f870365E785982E1f101E93b906";

  const leaves = whiteList.map((addr) => {
    const addrBytes = ethers.zeroPadValue(addr, 32);
    const numBytes = ethers.zeroPadValue("0x01", 32);
    const packed = ethers.concat([addrBytes, numBytes]);
    return ethers.keccak256(packed);
  });

  const tree = new MerkleTree(leaves, ethers.keccak256, { sortPairs: true });
  const addrBytes = ethers.zeroPadValue(targetAddress, 32);
  const numBytes = ethers.zeroPadValue("0x01", 32);
  const leaf = ethers.keccak256(ethers.concat([addrBytes, numBytes]));
  const proof = tree.getHexProof(leaf);

  console.log("铸造Proof:", proof);
}

main().catch(console.error);