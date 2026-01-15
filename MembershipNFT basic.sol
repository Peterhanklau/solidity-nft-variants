// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract MembershipNFT is ERC721, Ownable {
    enum MembershipLevel { Standard, Premium, VIP }
    
    struct Member {
        MembershipLevel level;
        uint256 expirationDate;
        uint256 discountRate; // 折扣率，如85表示85%
    }
    
    mapping(uint256 => Member) public members;
    mapping(address => uint256) public memberTokenId;
    
    // 链上元数据存储
    mapping(uint256 => string) private _tokenURIs;
    
    // 仅限官方市场地址
    address public officialMarketplace;
    
    constructor() ERC721("FitClub Membership", "FITM") {}
    
    function mint(
        address to, 
        MembershipLevel level, 
        uint256 duration
    ) external onlyOwner returns (uint256) {
        uint256 tokenId = totalSupply() + 1;
        _safeMint(to, tokenId);
        
        // 设置会员信息
        members[tokenId] = Member({
            level: level,
            expirationDate: block.timestamp + duration,
            discountRate: _getDiscountRate(level)
        });
        
        memberTokenId[to] = tokenId;
        
        // 生成链上元数据
        _setTokenURI(tokenId, _generateTokenURI(tokenId));
        
        return tokenId;
    }
    
    // 限制转账到官方市场
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override {
        require(
            from == address(0) || // 铸造
            to == address(0) ||   // 销毁
            to == officialMarketplace || // 转到官方市场
            msg.sender == officialMarketplace, // 从市场转移
            "Transfers only allowed to official marketplace"
        );
        
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }
    
    function renewMembership(uint256 tokenId, uint256 duration) external payable {
        require(ownerOf(tokenId) == msg.sender, "Not owner");
        require(members[tokenId].expirationDate < block.timestamp, "Not expired");
        
        // 续费逻辑
        members[tokenId].expirationDate += duration;
    }
    
    function getDiscount(uint256 tokenId) public view returns (uint256) {
        require(members[tokenId].expirationDate >= block.timestamp, "Membership expired");
        return members[tokenId].discountRate;
    }
    
    // 生成SVG格式的链上元数据
    function _generateTokenURI(uint256 tokenId) private view returns (string memory) {
        Member memory member = members[tokenId];
        string memory levelName = _levelToString(member.level);
        
        string memory svg = string(abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" width="400" height="300">',
            '<rect width="400" height="300" fill="#1a1a2e"/>',
            '<text x="50%" y="40%" text-anchor="middle" fill="white" font-size="24">',
            'FitClub Membership',
            '</text>',
            '<text x="50%" y="50%" text-anchor="middle" fill="white" font-size="20">',
            levelName,
            '</text>',
            '<text x="50%" y="60%" text-anchor="middle" fill="white" font-size="16">',
            'Discount: ',
            _toString(member.discountRate),
            '%</text>',
            '</svg>'
        ));
        
        string memory json = Base64.encode(bytes(string(abi.encodePacked(
            '{"name": "FitClub Membership #',
            _toString(tokenId),
            '", "description": "Digital Membership Card", "image": "data:image/svg+xml;base64,',
            Base64.encode(bytes(svg)),
            '", "attributes": [{"trait_type": "Level", "value": "',
            levelName,
            '"}, {"trait_type": "Discount", "value": "',
            _toString(member.discountRate),
            '%"}]}'
        ))));
        
        return string(abi.encodePacked('data:application/json;base64,', json));
    }
    
    // 辅助函数
    function _getDiscountRate(MembershipLevel level) private pure returns (uint256) {
        if (level == MembershipLevel.VIP) return 80;
        if (level == MembershipLevel.Premium) return 85;
        return 90;
    }
}