// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract FitClubMembership is ERC721, Ownable, ReentrancyGuard {
    using Strings for uint256;
    
    // ========== 类型定义 ==========
    enum MembershipLevel { Standard, Premium, VIP }
    
    struct Member {
        MembershipLevel level;
        uint256 expirationDate;
        uint256 discountRate;
        uint256 purchaseTime;
        uint256 purchasePrice;
    }
    
    struct MembershipInfo {
        bool exists;            // 是否有会员
        bool isActive;          // 是否在有效期内
        uint256 tokenId;
        MembershipLevel level;
        uint256 expirationDate;
        uint256 discountRate;
        uint256 daysRemaining;
    }
    
    // ========== 状态变量 ==========
    mapping(uint256 => Member) private _members;
    mapping(address => uint256) private _memberTokenId;
    mapping(MembershipLevel => uint256) private _levelPrices;
    mapping(MembershipLevel => uint256) private _levelDiscounts;
    
    address private _officialMarketplace;
    uint256 private _tokenIds;
    bool private _paused;  // 紧急暂停状态
    
    // 常量
    uint256 public constant MIN_DURATION = 30 days;
    uint256 public constant MAX_DURATION = 5 * 365 days;
    uint256 public constant GRACE_PERIOD = 7 days; // 续费宽限期
    
    // ========== 事件 ==========
    event MembershipPurchased(
        address indexed buyer,
        uint256 indexed tokenId,
        MembershipLevel level,
        uint256 price,
        uint256 duration,
        uint256 expirationDate
    );
    
    event MembershipRenewed(
        uint256 indexed tokenId,
        uint256 duration,
        uint256 newExpirationDate,
        uint256 price
    );
    
    event MembershipTransferred(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );
    
    event PriceUpdated(MembershipLevel level, uint256 oldPrice, uint256 newPrice);
    event MarketplaceUpdated(address oldMarketplace, address newMarketplace);
    event ContractPaused(address indexed by, bool paused);
    event EmergencyWithdraw(address indexed to, uint256 amount);
    
    // ========== 修饰器 ==========
    modifier whenNotPaused() {
        require(!_paused, "Contract is paused");
        _;
    }
    
    modifier validDuration(uint256 durationInDays) {
        uint256 duration = durationInDays * 1 days;
        require(duration >= MIN_DURATION, "Duration too short");
        require(duration <= MAX_DURATION, "Duration too long");
        _;
    }
    
    modifier validMembershipLevel(MembershipLevel level) {
        require(
            level == MembershipLevel.Standard || 
            level == MembershipLevel.Premium || 
            level == MembershipLevel.VIP, 
            "Invalid membership level"
        );
        _;
    }
    
    // ========== 构造函数 ==========
    constructor() ERC721("FitClub Membership", "FITM") Ownable(msg.sender) {
        // 设置初始价格（根据实际ETH价格调整）
        _levelPrices[MembershipLevel.Standard] = 0.05 ether; // 0.05 ETH
        _levelPrices[MembershipLevel.Premium] = 0.15 ether;  // 0.15 ETH
        _levelPrices[MembershipLevel.VIP] = 0.5 ether;       // 0.5 ETH
        
        // 设置折扣率
        _levelDiscounts[MembershipLevel.Standard] = 90;  // 9折
        _levelDiscounts[MembershipLevel.Premium] = 85;   // 85折
        _levelDiscounts[MembershipLevel.VIP] = 80;       // 8折
        
        _paused = false;
    }
    
    // ========== 管理员函数 ==========
    
    /// @notice 设置官方市场地址
    function setOfficialMarketplace(address marketplace) external onlyOwner {
        require(marketplace != address(0), "Invalid address");
        require(marketplace != _officialMarketplace, "Same address");
        address oldMarketplace = _officialMarketplace;
        _officialMarketplace = marketplace;
        emit MarketplaceUpdated(oldMarketplace, marketplace);
    }
    
    /// @notice 更新会员等级价格
    function updateLevelPrice(MembershipLevel level, uint256 price) external onlyOwner {
        require(price > 0, "Price must be positive");
        uint256 oldPrice = _levelPrices[level];
        require(price != oldPrice, "Same price");
        _levelPrices[level] = price;
        emit PriceUpdated(level, oldPrice, price);
    }
    
    /// @notice 暂停所有用户操作（紧急情况）
    function pause() external onlyOwner {
        require(!_paused, "Already paused");
        _paused = true;
        emit ContractPaused(msg.sender, true);
    }
    
    /// @notice 恢复合约正常运行
    function unpause() external onlyOwner {
        require(_paused, "Not paused");
        _paused = false;
        emit ContractPaused(msg.sender, false);
    }
    
    /// @notice 紧急提款（仅在暂停状态下可用）
    function emergencyWithdraw(address payable to) external onlyOwner {
        require(_paused, "Contract must be paused");
        require(to != address(0), "Invalid address");
        
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");
        
        (bool success, ) = to.call{value: balance}("");
        require(success, "Transfer failed");
        
        emit EmergencyWithdraw(to, balance);
    }
    
    /// @notice 安全提款
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");
        
        (bool success, ) = payable(owner()).call{value: balance}("");
        require(success, "Transfer failed");
    }
    
    // ========== 用户函数 ==========
    
    /// @notice 购买会员
    function purchaseMembership(
        MembershipLevel level,
        uint256 durationInDays
    ) external payable nonReentrant whenNotPaused validDuration(durationInDays) validMembershipLevel(level) {
        require(_memberTokenId[msg.sender] == 0, "Already has membership");
        
        uint256 duration = durationInDays * 1 days;
        uint256 price = _calculateMembershipPrice(level, duration);
        
        require(msg.value >= price, "Insufficient payment");
        require(msg.value <= price * 2, "Overpayment protection"); // 防止用户过度支付
        
        // 铸造NFT
        _tokenIds++;
        uint256 tokenId = _tokenIds;
        _safeMint(msg.sender, tokenId);
        
        // 设置会员信息
        _members[tokenId] = Member({
            level: level,
            expirationDate: block.timestamp + duration,
            discountRate: _levelDiscounts[level],
            purchaseTime: block.timestamp,
            purchasePrice: price
        });
        
        // 更新映射
        _memberTokenId[msg.sender] = tokenId;
        
        // 设置token URI
        _setTokenURI(tokenId, _generateTokenURI(tokenId));
        
        // 退款处理（使用transfer，因为我们已经检查了余额）
        uint256 refundAmount = msg.value - price;
        if (refundAmount > 0) {
            (bool success, ) = payable(msg.sender).call{value: refundAmount}("");
            require(success, "Refund failed");
        }
        
        emit MembershipPurchased(
            msg.sender,
            tokenId,
            level,
            price,
            duration,
            block.timestamp + duration
        );
    }
    
    /// @notice 续费会员
    function renewMembership(uint256 durationInDays) external payable nonReentrant whenNotPaused {
        uint256 tokenId = _memberTokenId[msg.sender];
        require(tokenId != 0, "No membership found");
        require(ownerOf(tokenId) == msg.sender, "Not the owner");
        
        uint256 duration = durationInDays * 1 days;
        require(duration >= 30 days, "Minimum 30 days");
        require(duration <= 365 days * 2, "Maximum 2 years"); // 限制续费时长
        
        Member storage member = _members[tokenId];
        require(member.expirationDate > 0, "Invalid membership"); // 防止已销毁的NFT
        
        // 计算续费价格
        uint256 price = _calculateRenewalPrice(member.level, duration);
        require(msg.value >= price, "Insufficient payment");
        require(msg.value <= price * 2, "Overpayment protection");
        
        // 计算新过期时间
        uint256 currentExpiry = member.expirationDate;
        uint256 newExpiry;
        
        if (currentExpiry + GRACE_PERIOD < block.timestamp) {
            newExpiry = block.timestamp + duration;
        } else {
            newExpiry = currentExpiry + duration;
        }
        
        // 防止时间戳溢出（大约在2106年）
        require(newExpiry > currentExpiry, "Timestamp overflow");
        
        member.expirationDate = newExpiry;
        
        // 更新token URI
        _setTokenURI(tokenId, _generateTokenURI(tokenId));
        
        // 退款处理
        uint256 refundAmount = msg.value - price;
        if (refundAmount > 0) {
            (bool success, ) = payable(msg.sender).call{value: refundAmount}("");
            require(success, "Refund failed");
        }
        
        emit MembershipRenewed(tokenId, duration, newExpiry, price);
    }
    
    // ========== 查询函数 ==========
    
    /// @notice 获取完整的会员信息
    function getMembershipInfo(address user) external view returns (MembershipInfo memory info) {
        uint256 tokenId = _memberTokenId[user];
        
        if (tokenId == 0) {
            return MembershipInfo({
                exists: false,
                isActive: false,
                tokenId: 0,
                level: MembershipLevel.Standard, // 使用Standard作为默认值
                expirationDate: 0,
                discountRate: 0,
                daysRemaining: 0
            });
        }
        
        Member memory member = _members[tokenId];
        require(member.expirationDate > 0, "Invalid membership"); // 额外验证
        
        bool isActive = member.expirationDate > block.timestamp;
        uint256 daysRemaining = 0;
        
        if (isActive) {
            daysRemaining = (member.expirationDate - block.timestamp) / 1 days;
        }
        
        return MembershipInfo({
            exists: true,
            isActive: isActive,
            tokenId: tokenId,
            level: member.level,
            expirationDate: member.expirationDate,
            discountRate: member.discountRate,
            daysRemaining: daysRemaining
        });
    }
    
    /// @notice 检查地址是否有有效会员
    function hasActiveMembership(address user) external view returns (bool) {
        uint256 tokenId = _memberTokenId[user];
        if (tokenId == 0) return false;
        
        Member memory member = _members[tokenId];
        return member.expirationDate > block.timestamp;
    }
    
    /// @notice 获取会员折扣率
    function getMembershipDiscount(uint256 tokenId) external view returns (uint256 discountRate, bool isValid) {
        require(_exists(tokenId), "Token does not exist"); // 使用ERC721的内置检查
        
        Member memory member = _members[tokenId];
        if (member.expirationDate == 0) return (0, false);
        
        isValid = member.expirationDate > block.timestamp;
        discountRate = member.discountRate;
    }
    
    /// @notice 计算会员价格
    function calculateMembershipPrice(
        MembershipLevel level,
        uint256 duration
    ) external view validMembershipLevel(level) returns (uint256) {
        require(duration >= MIN_DURATION && duration <= MAX_DURATION, "Invalid duration");
        return _calculateMembershipPrice(level, duration);
    }
    
    /// @notice 计算续费价格
    function calculateRenewalPrice(
        MembershipLevel level,
        uint256 duration
    ) external view validMembershipLevel(level) returns (uint256) {
        require(duration >= 30 days && duration <= 365 days * 2, "Invalid duration");
        return _calculateRenewalPrice(level, duration);
    }
    
    /// @notice 获取会员等级价格
    function getLevelPrice(MembershipLevel level) external view validMembershipLevel(level) returns (uint256) {
        return _levelPrices[level];
    }
    
    /// @notice 获取合约信息
    function getContractInfo() external view returns (
        uint256 totalMembers,
        uint256 contractBalance,
        address marketplace,
        bool isPaused
    ) {
        return (totalSupply(), address(this).balance, _officialMarketplace, _paused);
    }
    
    /// @notice 检查合约是否暂停
    function isPaused() external view returns (bool) {
        return _paused;
    }
    
    // ========== 内部函数 ==========
    
    /// @notice 计算会员价格（内部）
    function _calculateMembershipPrice(
        MembershipLevel level,
        uint256 duration
    ) internal view returns (uint256) {
        uint256 basePrice = _levelPrices[level];
        uint256 yearlyPrice = (basePrice * duration) / 365 days; // 显式括号，防止误解
        
        // 时长折扣
        if (duration >= 365 days * 2) {
            return (yearlyPrice * 80) / 100; // 两年以上8折
        } else if (duration >= 365 days) {
            return (yearlyPrice * 90) / 100; // 一年以上9折
        }
        
        return yearlyPrice;
    }
    
    /// @notice 计算续费价格（内部）
    function _calculateRenewalPrice(
        MembershipLevel level,
        uint256 duration
    ) internal view returns (uint256) {
        uint256 basePrice = _levelPrices[level];
        uint256 yearlyPrice = (basePrice * duration) / 365 days;
        
        // 续费折扣
        if (duration >= 365 days) {
            return (yearlyPrice * 80) / 100; // 续费一年以上8折
        }
        
        return (yearlyPrice * 85) / 100; // 续费少于一年85折
    }
    
    /// @notice 转账前检查
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
        
        // 允许铸造、销毁、官方市场交易
        require(
            from == address(0) ||
            to == address(0) ||
            _officialMarketplace == address(0) || // 如果未设置市场，允许所有转账
            to == _officialMarketplace ||
            msg.sender == _officialMarketplace,
            "Transfers only allowed to official marketplace"
        );
        
        // 更新会员映射
        if (from != address(0) && to != address(0)) {
            if (_members[firstTokenId].expirationDate > 0) {
                if (_memberTokenId[from] == firstTokenId) {
                    delete _memberTokenId[from];
                }
                _memberTokenId[to] = firstTokenId;
                
                emit MembershipTransferred(from, to, firstTokenId);
            }
        }
    }
    
    /// @notice 生成Token URI
    function _generateTokenURI(uint256 tokenId) internal view returns (string memory) {
        Member memory member = _members[tokenId];
        require(member.expirationDate > 0, "Token does not exist");
        
        string memory levelName = _levelToString(member.level);
        string memory status = _getMembershipStatus(member.expirationDate);
        string memory statusColor = _getStatusColor(status);
        string memory expiryDate = _formatTimestamp(member.expirationDate);
        uint256 daysRemaining = _calculateDaysRemaining(member.expirationDate);
        
        // 生成SVG - 简化版以减少Gas消耗
        string memory svg = string(abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" width="350" height="400" viewBox="0 0 350 400">',
            '<rect width="350" height="400" fill="#1a1a2e" rx="15"/>',
            '<rect x="15" y="15" width="320" height="370" fill="#16213e" rx="10"/>',
            
            // 标题
            '<text x="175" y="60" text-anchor="middle" fill="#fff" font-family="Arial" font-size="22" font-weight="bold">',
            'FitClub Membership</text>',
            
            // 会员等级
            '<text x="175" y="110" text-anchor="middle" fill="#4cc9f0" font-family="Arial" font-size="28" font-weight="bold">',
            levelName, '</text>',
            
            // 会员编号
            '<text x="175" y="140" text-anchor="middle" fill="#ccc" font-family="Arial" font-size="14">ID #',
            tokenId.toString(), '</text>',
            
            // 折扣信息
            '<text x="175" y="190" text-anchor="middle" fill="#f72585" font-family="Arial" font-size="20">Save ',
            _toString(100 - member.discountRate), '%</text>',
            
            // 状态
            '<text x="175" y="230" text-anchor="middle" fill="#', statusColor, '" font-family="Arial" font-size="18">',
            status, '</text>',
            
            // 过期时间
            '<text x="175" y="270" text-anchor="middle" fill="#fff" font-family="Arial" font-size="14">Expires: ',
            expiryDate, '</text>',
            
            // 剩余天数
            '<text x="175" y="300" text-anchor="middle" fill="#', statusColor, '" font-family="Arial" font-size="14">',
            daysRemaining.toString(), ' days left</text>',
            
            // 底部信息
            '<text x="175" y="370" text-anchor="middle" fill="#aaa" font-family="Arial" font-size="12">',
            'Present for ', _toString(member.discountRate), '% discount</text>',
            
            '</svg>'
        ));
        
        // 构建JSON元数据
        string memory json = Base64.encode(bytes(string(abi.encodePacked(
            '{"name":"FitClub Membership #', tokenId.toString(),
            '","description":"Official FitClub Gym Membership NFT.',
            '","image":"data:image/svg+xml;base64,', Base64.encode(bytes(svg)),
            '","attributes":[',
            '{"trait_type":"Level","value":"', levelName, '"},',
            '{"trait_type":"Discount","value":"', _toString(100 - member.discountRate), '%"},',
            '{"trait_type":"Status","value":"', status, '"},',
            '{"trait_type":"Expiration","value":"', _toString(member.expirationDate), '"},',
            '{"trait_type":"Days Remaining","value":"', daysRemaining.toString(), '"}',
            ']}'
        ))));
        
        return string(abi.encodePacked('data:application/json;base64,', json));
    }
    
    /// @notice 获取会员状态
    function _getMembershipStatus(uint256 expirationDate) internal view returns (string memory) {
        if (expirationDate < block.timestamp) {
            return "Expired";
        } else if (expirationDate - block.timestamp < 30 days) {
            return "Expiring Soon";
        }
        return "Active";
    }
    
    /// @notice 获取状态颜色
    function _getStatusColor(string memory status) internal pure returns (string memory) {
        bytes32 statusHash = keccak256(abi.encodePacked(status));
        bytes32 activeHash = keccak256(abi.encodePacked("Active"));
        bytes32 expiringHash = keccak256(abi.encodePacked("Expiring Soon"));
        
        if (statusHash == activeHash) return "4cc9f0";
        if (statusHash == expiringHash) return "f8961e";
        return "f72585";
    }
    
    /// @notice 格式化时间戳
    function _formatTimestamp(uint256 timestamp) internal pure returns (string memory) {
        // 简化版本，实际生产建议前端处理
        uint256 daysSinceEpoch = timestamp / 1 days;
        uint256 year = 1970 + daysSinceEpoch / 365;
        uint256 month = (daysSinceEpoch % 365) / 30 + 1;
        uint256 day = (daysSinceEpoch % 365) % 30 + 1;
        
        return string(abi.encodePacked(
            _toString(year), '-',
            month < 10 ? '0' : '', _toString(month), '-',
            day < 10 ? '0' : '', _toString(day)
        ));
    }
    
    /// @notice 计算剩余天数
    function _calculateDaysRemaining(uint256 expirationDate) internal view returns (uint256) {
        if (expirationDate <= block.timestamp) return 0;
        return (expirationDate - block.timestamp) / 1 days;
    }
    
    /// @notice 等级转字符串
    function _levelToString(MembershipLevel level) internal pure returns (string memory) {
        if (level == MembershipLevel.VIP) return "VIP";
        if (level == MembershipLevel.Premium) return "Premium";
        return "Standard";
    }
    
    /// @notice uint转string
    function _toString(uint256 value) internal pure returns (string memory) {
        return value.toString();
    }
    
    // ========== ERC721覆盖函数 ==========
    
    /// @notice 获取NFT总数
    function totalSupply() public view returns (uint256) {
        return _tokenIds;
    }
    
    /// @notice 获取会员NFT信息
    function getMember(uint256 tokenId) external view returns (Member memory) {
        require(_exists(tokenId), "Token does not exist");
        return _members[tokenId];
    }
    
    /// @notice 获取用户的会员NFT ID
    function getMemberTokenId(address user) external view returns (uint256) {
        return _memberTokenId[user];
    }
    
    /// @notice 重写tokenURI以支持链上元数据
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "Token does not exist");
        return super.tokenURI(tokenId);
    }
}