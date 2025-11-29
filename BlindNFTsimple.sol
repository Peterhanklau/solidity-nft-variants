// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract SimpleBlindBoxNFT is ERC721 {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    
    enum Rarity { COMMON, RARE, EPIC, LEGENDARY }
    
    mapping(uint256 => bool) public isRevealed;
    mapping(uint256 => Rarity) public tokenRarity;

    constructor() ERC721("SimpleMystery", "SBOX") {}

    function mintBlindBox(address to) public returns (uint256) {
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        _mint(to, newTokenId);
        isRevealed[newTokenId] = false;
        return newTokenId;
    }
    
    function reveal(uint256 tokenId) public {
        require(ownerOf(tokenId) == msg.sender, "Not owner");
        require(!isRevealed[tokenId], "Already revealed");
        
        // 使用简单的伪随机数（仅用于测试）
        uint256 random = uint256(keccak256(abi.encodePacked(block.timestamp, tokenId, msg.sender)));
        Rarity rarity = determineRarity(random);
        
        tokenRarity[tokenId] = rarity;
        isRevealed[tokenId] = true;
    }

    function determineRarity(uint256 randomValue) private pure returns (Rarity) {
        uint256 rarityValue = randomValue % 100;
        if (rarityValue < 60) return Rarity.COMMON;
        else if (rarityValue < 85) return Rarity.RARE;
        else if (rarityValue < 95) return Rarity.EPIC;
        else return Rarity.LEGENDARY;
    }
}