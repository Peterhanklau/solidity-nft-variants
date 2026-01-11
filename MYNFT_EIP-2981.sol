// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MyNFT is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    mapping(address => bool) public whitelist;

    // 版税信息
    address private _royaltyReceiver;
    uint96  private _royaltyFraction; //使用基点为单位 (10000 = 100%)

    // 添加基础URI支持，用于批量铸造
    string private _baseTokenURI;

    // 修改后的构造函数：传递初始所有者地址和设置版税
    constructor() ERC721("MyNFT", "MNFT") Ownable(msg.sender) {
       //设置版税接收者就是合约部署者，5%版税
       _royaltyReceiver = msg.sender;
       _royaltyFraction = 500; //5%版税

    } // 关键修改在这里

    // 设置版税信息
    function setRoyaltyInfo(address receiver, uint96 feeNumerator) external onlyOwner {
        require (feeNumerator <= 10000, "MyNFT: Royalty fraction cannot exceed 10000");
        _royaltyReceiver = receiver;
        _royaltyFraction = feeNumerator;
    }  
  
    // 实现 EIP-2981 版税标准
    function royaltyInfo(uint256 tokenId, uint256 salePrice) 
        external 
        view 
        returns (address receiver, uint256 royaltyAmount) 
    {
        require(_exists(tokenId), "MyNFT: Royalty info for nonexistent token");
        royaltyAmount = (salePrice * _royaltyFraction) / 10000;
        receiver = _royaltyReceiver;
    }
    // 支持 EIP-2981 接口检测
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == 0x2a55205a || super.supportsInterface(interfaceId); //EIP-2981 接口ID
    }

    // 设置基础URI
    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }    
   
    // 重写_tokenURI函数以支持基础URI
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    //辅助函数：检查token是否存在
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

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
    }

    // 批量铸造函数 - 使用unchecked进行Gas优化
    function bulkMint(uint256 count) external payable returns (uint256[] memory) {
        require(whitelist[msg.sender],"MyNFT: Caller is not in the whitelist");
        require(count > 0, "MyNFT: Count must be greater than 0");
        require(msg.value >= 0.01 ether * count, "MyNFT: Insufficient Payment");

        uint256[] memory mintedTokenIds = new uint256[] (count);
        uint256  currentTokenId = _tokenIds.current();

        // 使用unchecked块优化Gas消耗
        unchecked {
            for (uint256 i = 0; i < count; i++) {
                currentTokenId ++;
                _tokenIds.increment();
                _mint(msg.sender, currentTokenId);
            
                // 如果设置了基础URI，自动生成tokenURI
                if (bytes(_baseTokenURI).length > 0) {
                    string memory tokenURI = string(abi.encodePacked(_baseTokenURI, _toString(currentTokenId)));
          
                    _setTokenURI(currentTokenId, tokenURI);
                }

                mintedTokenIds[i] = currentTokenId;
           }
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

    function withdraw() external onlyOwner {
        // 获取合约当前的余额
        uint256 balance = address(this).balance;
        // 检查余额是否大于0
        require(balance > 0, "MyNFT: No funds to withdraw");

        // 使用 call 发送以太币
        (bool success, ) = owner().call{value: balance}("");
        require(success, "MyNFT: Transfer failed");
    }

}
