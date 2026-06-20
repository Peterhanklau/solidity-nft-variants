// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract WhitelistNFT is ERC721, Ownable, ReentrancyGuard {
    using Strings for uint256;

    uint256 public totalSupply;
    uint256 public maxSupply = 1000;
    
    uint256 public whitelistPrice = 0.05 ether;
    uint256 public publicPrice = 0.08 ether;
    
    uint256 public maxPerWallet = 3;
    mapping(address => uint256) public mintedCount;
    
    bytes32 public merkleRoot;
    mapping(address => bool) public whitelistClaimed;
    
    enum MintPhase { CLOSED, WHITELIST, PUBLIC }
    MintPhase public phase = MintPhase.CLOSED;
    
    string private baseURI;
    
    event Minted(address indexed to, uint256 tokenId, string phase);
    event PhaseChanged(MintPhase newPhase);
    event MerkleRootUpdated(bytes32 newRoot);
    
    constructor(string memory _baseURI) 
        ERC721("GameFi Genesis", "GFG") 
        Ownable()
    {
        baseURI = _baseURI;
    }
    
    function whitelistMint(bytes32[] calldata _merkleProof) 
        external 
        payable 
        nonReentrant 
    {
        require(phase == MintPhase.WHITELIST, "Whitelist mint not active");
        require(totalSupply + 1 <= maxSupply, "Max supply reached");
        require(mintedCount[msg.sender] + 1 <= maxPerWallet, "Max per wallet");
        require(!whitelistClaimed[msg.sender], "Already claimed");
        require(msg.value >= whitelistPrice, "Insufficient payment");
        
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Invalid proof");
        
        whitelistClaimed[msg.sender] = true;
        mintedCount[msg.sender]++;
        totalSupply++;
        
        uint256 tokenId = totalSupply;
        _safeMint(msg.sender, tokenId);
        
        emit Minted(msg.sender, tokenId, "WHITELIST");
    }
    
    function publicMint() 
        external 
        payable 
        nonReentrant 
    {
        require(phase == MintPhase.PUBLIC, "Public mint not active");
        require(totalSupply + 1 <= maxSupply, "Max supply reached");
        require(mintedCount[msg.sender] + 1 <= maxPerWallet, "Max per wallet");
        require(msg.value >= publicPrice, "Insufficient payment");
        
        mintedCount[msg.sender]++;
        totalSupply++;
        
        uint256 tokenId = totalSupply;
        _safeMint(msg.sender, tokenId);
        
        emit Minted(msg.sender, tokenId, "PUBLIC");
    }
    
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
        emit MerkleRootUpdated(_merkleRoot);
    }
    
    function setPhase(MintPhase _phase) external onlyOwner {
        phase = _phase;
        emit PhaseChanged(_phase);
    }
    
    // 提款函数（已修复）
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds");
        (bool success, ) = payable(owner()).call{value: balance}("");
        require(success, "Withdraw failed");
    }
    
    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }
    
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_ownerOf(tokenId) != address(0), "Token not exists");
        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
    }
    
    function getRemainingSupply() external view returns (uint256) {
        return maxSupply - totalSupply;
    }
}