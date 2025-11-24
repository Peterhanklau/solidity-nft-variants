// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MyNFT is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    mapping(address => bool) public whitelist;

    // 修改后的构造函数：传递初始所有者地址
    constructor() ERC721("MyNFT", "MNFT") Ownable(msg.sender) {} // 关键修改在这里

    // ... 后面的 addToWhitelist 和 mintNFT 函数保持不变 ...
    function addToWhitelist(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            whitelist[addresses[i]] = true;
        }
    }

    function mintNFT(address recipient, string memory tokenURI) public returns (uint256) {
        require(whitelist[msg.sender], "MyNFT: Caller is not in the whitelist");
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        
        _mint(recipient, newItemId);
        _setTokenURI(newItemId, tokenURI);
        
        return newItemId;
    }//
}