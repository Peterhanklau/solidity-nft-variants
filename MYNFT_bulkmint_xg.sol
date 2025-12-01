// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MyNFT is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    mapping(address => bool) public whitelist;
    
    // NFT价格常量
    uint256 public constant PRICE = 0.01 ether;
    
    // 添加基础URI支持，用于批量铸造
    string private _baseTokenURI;

    // 修改后的构造函数：传递初始所有者地址
    constructor() ERC721("MyNFT", "MNFT") Ownable(msg.sender) {}
    
    // 设置基础URI - 修复参数名冲突
    function setBaseURI(string memory newBaseURI) external onlyOwner {
        _baseTokenURI = newBaseURI;
    }
    
    // 获取基础URI
    function baseURI() external view returns (string memory) {
        return _baseTokenURI;
    }
   
    // 重写_tokenURI函数以支持基础URI
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    // 添加白名单
    function addToWhitelist(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            whitelist[addresses[i]] = true;
        }
    }
    
    // 从白名单移除
    function removeFromWhitelist(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            whitelist[addresses[i]] = false;
        }
    }

    // 单个NFT铸造
    function mintNFT(address recipient, string memory tokenURI) 
        public 
        returns (uint256) 
    {
        require(whitelist[msg.sender], "MyNFT: Caller is not in the whitelist");
        
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        
        _mint(recipient, newItemId);
        _setTokenURI(newItemId, tokenURI);
        
        return newItemId;
    }
    
    // 带支付的单个NFT铸造
    function mintNFTWithPayment(string memory tokenURI) 
        external 
        payable 
        returns (uint256) 
    {
        require(whitelist[msg.sender], "MyNFT: Caller is not in the whitelist");
        require(msg.value >= PRICE, "MyNFT: Insufficient Payment");
        
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        
        _mint(msg.sender, newItemId);
        _setTokenURI(newItemId, tokenURI);
        
        return newItemId;
    }

    // 修复后的批量铸造函数
    function bulkMint(uint256 count) 
        external 
        payable 
        returns (uint256[] memory) 
    {
        require(whitelist[msg.sender], "MyNFT: Caller is not in the whitelist");
        require(count > 0, "MyNFT: Count must be greater than 0");
        require(msg.value >= PRICE * count, "MyNFT: Insufficient Payment");

        uint256[] memory mintedTokenIds = new uint256[](count);

        for (uint256 i = 0; i < count; i++) {
            _tokenIds.increment();
            uint256 newTokenId = _tokenIds.current();
            _mint(msg.sender, newTokenId);
            
            // 如果设置了基础URI，自动生成tokenURI
            if (bytes(_baseTokenURI).length > 0) {
                string memory tokenURI = string(
                    abi.encodePacked(_baseTokenURI, _toString(newTokenId))
                );
                _setTokenURI(newTokenId, tokenURI);
            }

            mintedTokenIds[i] = newTokenId;
        }
        
        return mintedTokenIds;
    }
    
    // 带指定接收地址的批量铸造
    function bulkMintTo(address recipient, uint256 count) 
        external 
        payable 
        returns (uint256[] memory) 
    {
        require(whitelist[msg.sender], "MyNFT: Caller is not in the whitelist");
        require(count > 0, "MyNFT: Count must be greater than 0");
        require(msg.value >= PRICE * count, "MyNFT: Insufficient Payment");

        uint256[] memory mintedTokenIds = new uint256[](count);

        for (uint256 i = 0; i < count; i++) {
            _tokenIds.increment();
            uint256 newTokenId = _tokenIds.current();
            _mint(recipient, newTokenId);
            
            // 如果设置了基础URI，自动生成tokenURI
            if (bytes(_baseTokenURI).length > 0) {
                string memory tokenURI = string(
                    abi.encodePacked(_baseTokenURI, _toString(newTokenId))
                );
                _setTokenURI(newTokenId, tokenURI);
            }

            mintedTokenIds[i] = newTokenId;
        }
        
        return mintedTokenIds;
    }

    // 辅助函数：将uint256转换为string
    function _toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
    
    // 获取当前Token ID
    function currentTokenId() external view returns (uint256) {
        return _tokenIds.current();
    }
    
    // 获取总供应量
    function totalSupply() external view returns (uint256) {
        return _tokenIds.current();
    }

    // 提款函数
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "MyNFT: No funds to withdraw");

        (bool success, ) = owner().call{value: balance}("");
        require(success, "MyNFT: Transfer failed");
    }
    
    // 紧急停止功能（可选）
    function emergencyWithdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
    }
    
    // 接收以太币的回退函数
    receive() external payable {}
}
