const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { expect } = require("chai");
const { ethers } = require("hardhat");
const { MerkleTree } = require("merkletreejs");

function getLeaf(userAddr) {
  const abiCoder = new ethers.AbiCoder();
  const encoded = abiCoder.encode(["address", "uint256"], [userAddr, 1]);
  return ethers.keccak256(encoded);
}

describe("ArtMintContract", function () {
  async function deployFixture() {
    const [owner, user1, user2] = await ethers.getSigners();
    const baseURI = "ipfs://test/";
    const NFTFactory = await ethers.getContractFactory("ArtMintContract");
    const nft = await NFTFactory.deploy(baseURI);
    await nft.waitForDeployment();

    const whiteListAddresses = [user1.address];
    const leaves = whiteListAddresses.map(addr => getLeaf(addr));
    const merkleTree = new MerkleTree(leaves, ethers.keccak256, { sortPairs: true });
    const root = merkleTree.getHexRoot();
    await nft.setMerkleRoot(root);

    return { nft, owner, user1, user2, merkleTree };
  }

  it("Check name and symbol", async function () {
    const { nft } = await loadFixture(deployFixture);
    expect(await nft.name()).eq("ArtMint Collection");
    expect(await nft.symbol()).eq("ARTMINT");
  });

  it("Forbid whitelist mint before opening phase", async function () {
    const { nft, user1, merkleTree } = await loadFixture(deployFixture);
    const leaf = getLeaf(user1.address);
    const proof = merkleTree.getHexProof(leaf);
    const wlPrice = ethers.parseEther("0.05");

    await expect(
      nft.connect(user1).whitelistMint(proof, 1, ethers.ZeroAddress, { value: wlPrice })
    ).to.be.revertedWithCustomError(nft, "InvalidPhase");
  });

  it("Whitelist mint normally", async function () {
    const { nft, user1, merkleTree } = await loadFixture(deployFixture);
    await nft.setPhase(1); // Phase.WHITELIST
    const leaf = getLeaf(user1.address);
    const proof = merkleTree.getHexProof(leaf);
    const wlPrice = ethers.parseEther("0.05");

    await nft.connect(user1).whitelistMint(proof, 1, ethers.ZeroAddress, { value: wlPrice });
    expect(await nft.walletMinted(user1.address)).to.equal(1);
    expect(await nft.totalSupply()).to.equal(1);
  });

  it("Single wallet limit 3 mints", async function () {
    const { nft, user1, merkleTree } = await loadFixture(deployFixture);
    await nft.setPhase(1);
    const leaf = getLeaf(user1.address);
    const proof = merkleTree.getHexProof(leaf);
    const wlPrice = ethers.parseEther("0.05");
    const pubPrice = ethers.parseEther("0.08");

    // 白名单铸造1枚（0.05ETH）
    await nft.connect(user1).whitelistMint(proof, 1, ethers.ZeroAddress, { value: wlPrice });
    expect(await nft.walletMinted(user1.address)).to.equal(1);

    // 再次白名单铸造触发 AlreadyClaimed
    await expect(
      nft.connect(user1).whitelistMint(proof, 1, ethers.ZeroAddress, { value: wlPrice })
    ).to.be.revertedWithCustomError(nft, "AlreadyClaimed");

    // 切换公开阶段，公开单价 0.08 ETH
    await nft.setPhase(2); // Phase.PUBLIC
    await nft.connect(user1).publicMint(1, ethers.ZeroAddress, { value: pubPrice });
    await nft.connect(user1).publicMint(1, ethers.ZeroAddress, { value: pubPrice });
    expect(await nft.walletMinted(user1.address)).to.equal(3);

    // 已满3枚，禁止铸造
    await expect(
      nft.connect(user1).publicMint(1, ethers.ZeroAddress, { value: pubPrice })
    ).to.be.revertedWithCustomError(nft, "ExceedsWalletLimit");
  });
});