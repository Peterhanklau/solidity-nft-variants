const { expect } = require("chai");
const { ethers } = require("hardhat");
const { MerkleTree } = require('merkletreejs');
const keccak256 = require('keccak256');

describe("WhitelistNFT", function () {
    let nft, owner, addr1, addr2, addr3;
    let merkleTree, whitelistAddresses;
    
    beforeEach(async function () {
        [owner, addr1, addr2, addr3] = await ethers.getSigners();
        
        whitelistAddresses = [owner.address, addr1.address, addr2.address];
        const leaves = whitelistAddresses.map(addr => keccak256(addr));
        merkleTree = new MerkleTree(leaves, keccak256, { sortPairs: true });
        
        // 修复1：拼写错误 WhiteliftNFT → WhitelistNFT
        const WhitelistNFT = await ethers.getContractFactory("WhitelistNFT");
        nft = await WhitelistNFT.deploy("ipfs://baseURI/");
        await nft.waitForDeployment(); // ethersv6 替代 deployed()
        
        await nft.setMerkleRoot("0x" + merkleTree.getRoot().toString('hex'));
    });
    
    it("白名单铸造应该成功", async function () {
        await nft.setPhase(1); // WHITELIST
        const leaf = keccak256(addr1.address);
        const proof = merkleTree.getHexProof(leaf);

        // 修复2：parseEther 写法适配新版本
        await nft.connect(addr1).whitelistMint(proof, { value: ethers.parseEther("0.05") });
        
        expect(await nft.ownerOf(1)).to.equal(addr1.address);
        expect(await nft.totalSupply()).to.equal(1);
    });
    
    it("非白名单地址铸造应该失败", async function () {
        await nft.setPhase(1);
        const leaf = keccak256(addr3.address);
        const proof = merkleTree.getHexProof(leaf);
        
        await expect(
            nft.connect(addr3).whitelistMint(proof, { value: ethers.parseEther("0.05") })
        ).to.be.revertedWith("Invalid proof");
    });
    
    it("公开铸造应该成功", async function () {
        await nft.setPhase(2); // PUBLIC
        await nft.connect(addr3).publicMint({ value: ethers.parseEther("0.08") });
        
        expect(await nft.ownerOf(1)).to.equal(addr3.address);
    });
});