const { MerkleTree } = require('merkletreejs');
const keccak256 = require('keccak256');

// 白名单地址
const whitelistAddresses = [
    "0xED50C5E4cEAa3B3387f59C970B49d788618DcbaC",
    "0xe6490f2A8772B96f9cf57b5667731Ce2Bab8A5F0",
    "0x70997970C51812dc3A010C7d01b50e0d17dc79C8",
];

const leaves = whitelistAddresses.map(addr => keccak256(addr));
const tree = new MerkleTree(leaves, keccak256, { sortPairs: true });
const root = tree.getRoot().toString('hex');

console.log("✅ Merkle Root: 0x" + root);
console.log("\n--- 每个地址的 Proof ---");

whitelistAddresses.forEach(addr => {
  const proof = tree.getHexProof(keccak256(addr));
  console.log("\n" + addr);
  console.log(proof);
});
