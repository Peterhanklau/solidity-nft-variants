// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract ArtMintContract is ERC721, Ownable, ReentrancyGuard, Pausable {
    using Strings for uint256;
    using Address for address;

    struct MintConfig {
        uint256 maxSupply;
        uint256 maxPerWallet;
        uint256 referralPercent;
        uint256 whitelistPrice;
        uint256 publicPrice;
    }

    // 基础配置
    uint256 public totalSupply;
    MintConfig public config;

    bytes32 public merkleRoot;
    Phase public phase;
    bool public mintPaused; // 仅铸造暂停，独立于全局Pausable

    // 铸造统计 & 白名单体系
    mapping(address => uint256) public walletMintedCount;
    mapping(address => uint256) public whitelistRemaining;
    mapping(address => bool) public whitelistClaimed; // 白名单资格永久标记：一旦铸造过就无法再次走白名单Merkle校验
    mapping(address => uint256) public referralRewards;

    string private baseURI;

    enum Phase { CLOSED, WHITELIST, PUBLIC }

    // 事件
    event Minted(address indexed to, uint256 tokenId, string phase);
    event ReferralReward(address indexed referrer, address indexed minter, uint256 amount);
    event PhaseChanged(Phase newPhase);
    event Withdrawn(address indexed owner, uint256 amount);
    event RefundExtraETH(address indexed user, uint256 refundAmount);
    event ConfigUpdated(string indexed param, uint256 value);
    event WhitelistRootUpdated(bytes32 newRoot);
    event MintPauseToggled(bool paused);

    // 统一自定义错误
    error InvalidReferrer();
    error ExceedsMaxSupply();
    error InsufficientPayment();
    error ExceedsWalletLimit();
    error InvalidPhase();
    error NoRewards();
    error TransferFailed();
    error InvalidMerkleProof();
    error ContractReferrerForbidden();
    error SelfReferralForbidden();
    error ZeroMintAmount();
    error ExceedWhitelistQuota();
    error BaseURIEmpty();
    error RefPercentTooHigh();
    error MaxSupplyLessThanMinted();
    error ArrayLengthMismatch();
    error AlreadyClaimed();
    error MintPaused();
    error UserAlreadyMinted(); // 新增：用户已经铸造NFT，禁止重置白名单

    constructor(string memory _baseURI) ERC721("ArtMint Collection", "ARTMINT") Ownable(msg.sender) {
        if (bytes(_baseURI).length == 0) revert BaseURIEmpty();
        baseURI = _baseURI;

        config = MintConfig({
            maxSupply: 1000,
            maxPerWallet: 3,
            referralPercent: 5,
            whitelistPrice: 0.05 ether,
            publicPrice: 0.08 ether
        });

        phase = Phase.CLOSED;
        mintPaused = false;
    }

    // ==================== Modifier ====================
    modifier validPhase(Phase requiredPhase) {
        if (phase != requiredPhase) revert InvalidPhase();
        _;
    }

    modifier validReferrer(address referrer) {
        // 0地址合法，代表无推荐人，不发返利
        if (referrer == address(0)) {
            _;
            return;
        }
        if (referrer == msg.sender) revert SelfReferralForbidden();
        if (referrer.isContract()) revert ContractReferrerForbidden();
        _;
    }

    // ==================== Internal Core Logic ====================
    function _mintWithReferral(
        uint256 price,
        bytes32[] calldata merkleProof,
        uint256 mintAmount,
        address referrer
    ) internal whenNotPaused nonReentrant {
        if (mintPaused) revert MintPaused();
        if (mintAmount == 0) revert ZeroMintAmount();
        uint256 totalCost = price * mintAmount;

        if (totalSupply + mintAmount > config.maxSupply) revert ExceedsMaxSupply();
        if (msg.value < totalCost) revert InsufficientPayment();

        uint256 newWalletMinted = walletMintedCount[msg.sender] + mintAmount;
        if (newWalletMinted > config.maxPerWallet) revert ExceedsWalletLimit();

        // 白名单阶段校验额度 + Merkle
        if (phase == Phase.WHITELIST) {
            _consumeWhitelistQuota(msg.sender, merkleProof, mintAmount);
        }

        // 批量铸造NFT
        for (uint256 i = 0; i < mintAmount; i++) {
            _mintSingleNFT(msg.sender);
        }

        // 分发推荐奖励
        if (referrer != address(0)) {
            _distributeReferral(referrer, totalCost);
        }

        // 退还超额ETH
        if (msg.value > totalCost) {
            uint256 refund = msg.value - totalCost;
            (bool success, ) = payable(msg.sender).call{value: refund}("");
            if (!success) revert TransferFailed();
            emit RefundExtraETH(msg.sender, refund);
        }
    }

    /// 杜绝白名单反复校验Merkle无限铸造
    function _consumeWhitelistQuota(address user, bytes32[] calldata proof, uint256 amount) internal {
        uint256 remain = whitelistRemaining[user];

        if (remain == 0) {
            // 只要曾经白名单铸造过，直接禁止再次Merkle校验
            if (whitelistClaimed[user]) revert AlreadyClaimed();

            bytes32 leaf = keccak256(abi.encode(user, uint256(1)));
            if (!MerkleProof.verify(proof, merkleRoot, leaf)) revert InvalidMerkleProof();

            // 校验通过立刻锁定白名单资格，永久无法再次走白名单Merkle通道
            whitelistClaimed[user] = true;
            whitelistRemaining[user] = 1;
            remain = 1;
        }

        if (remain < amount) revert ExceedWhitelistQuota();
        whitelistRemaining[user] = remain - amount;
    }

    function _mintSingleNFT(address _to) internal {
        totalSupply++;
        uint256 tokenId = totalSupply;
        walletMintedCount[_to]++;
        _safeMint(_to, tokenId);
        string memory mintPhase = phase == Phase.WHITELIST ? "WHITELIST" : "PUBLIC";
        emit Minted(_to, tokenId, mintPhase);
    }

    function _distributeReferral(address referrer, uint256 payment) internal {
        uint256 reward = (payment * config.referralPercent) / 100;
        referralRewards[referrer] += reward;
        emit ReferralReward(referrer, msg.sender, reward);
    }

    // ==================== External Mint Interface ====================
    function whitelistMint(
        bytes32[] calldata _merkleProof,
        uint256 _mintAmount,
        address _referrer
    ) external payable validPhase(Phase.WHITELIST) validReferrer(_referrer) {
        if (_mintAmount > 3) revert ExceedsWalletLimit();
        _mintWithReferral(config.whitelistPrice, _merkleProof, _mintAmount, _referrer);
    }

    function publicMint(
        uint256 _mintAmount,
        address _referrer
    ) external payable validPhase(Phase.PUBLIC) validReferrer(_referrer) {
        if (_mintAmount > 3) revert ExceedsWalletLimit();
        bytes32[] memory emptyProof;
        _mintWithReferral(config.publicPrice, emptyProof, _mintAmount, _referrer);
    }

    // ==================== Referral Reward Claim ====================
    function claimReferralReward() external nonReentrant whenNotPaused {
        uint256 amount = referralRewards[msg.sender];
        if (amount == 0) revert NoRewards();

        referralRewards[msg.sender] = 0;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) revert TransferFailed();
    }

    // ==================== View Functions ====================
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);
        string memory base = baseURI;
        bytes memory b = bytes(base);
        bool endSlash = b.length > 0 && b[b.length - 1] == "/";

        if (endSlash) {
            return string.concat(base, tokenId.toString(), ".json");
        } else {
            return string.concat(base, "/", tokenId.toString(), ".json");
        }
    }

    function getRemainingSupply() external view returns (uint256) {
        return config.maxSupply - totalSupply;
    }

    function getReferralReward(address _user) external view returns (uint256) {
        return referralRewards[_user];
    }

    function walletMinted(address user) external view returns (uint256) {
        return walletMintedCount[user];
    }

    // ==================== Owner Admin ====================
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
        emit WhitelistRootUpdated(_merkleRoot);
    }

    function setWhitelistRootAndPhase(bytes32 _merkleRoot, Phase _phase) external onlyOwner {
        merkleRoot = _merkleRoot;
        phase = _phase;
        emit WhitelistRootUpdated(_merkleRoot);
        emit PhaseChanged(_phase);
    }

    function setPhase(Phase _phase) external onlyOwner {
        phase = _phase;
        emit PhaseChanged(_phase);
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        if (bytes(_newBaseURI).length == 0) revert BaseURIEmpty();
        baseURI = _newBaseURI;
    }

    function setMintConfig(
        uint256 _maxSupply,
        uint256 _maxPerWallet,
        uint256 _referralPercent,
        uint256 _whitelistPrice,
        uint256 _publicPrice
    ) external onlyOwner {
        if (_referralPercent > 20) revert RefPercentTooHigh();
        if (_maxSupply < totalSupply) revert MaxSupplyLessThanMinted();

        config.maxSupply = _maxSupply;
        config.maxPerWallet = _maxPerWallet;
        config.referralPercent = _referralPercent;
        config.whitelistPrice = _whitelistPrice;
        config.publicPrice = _publicPrice;

        emit ConfigUpdated("maxSupply", _maxSupply);
        emit ConfigUpdated("maxPerWallet", _maxPerWallet);
        emit ConfigUpdated("referralPercent", _referralPercent);
        emit ConfigUpdated("whitelistPrice", _whitelistPrice);
        emit ConfigUpdated("publicPrice", _publicPrice);
    }

    // 安全批量配置白名单额度：仅未使用白名单的地址可写入额度
    function batchSetWhitelistQuota(address[] calldata wallets, uint256[] calldata quota) external onlyOwner {
        if (wallets.length != quota.length) revert ArrayLengthMismatch();
        for (uint256 i = 0; i < wallets.length; i++) {
            if (!whitelistClaimed[wallets[i]]) {
                whitelistRemaining[wallets[i]] = quota[i];
            }
        }
    }

    // ========== 修复后的重置白名单函数 ==========
    function resetUserWhitelist(address user) external onlyOwner {
        // 核心防护：只要该地址铸造过任意NFT，禁止重置白名单
        if (walletMintedCount[user] > 0) revert UserAlreadyMinted();
        whitelistClaimed[user] = false;
        whitelistRemaining[user] = 0;
    }

    // 开关铸造暂停（只停mint，奖励提取、提款不受影响）
    function toggleMintPause() external onlyOwner {
        mintPaused = !mintPaused;
        emit MintPauseToggled(mintPaused);
    }

    // 全局紧急暂停（mint、领奖励、提款全部锁住）
    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    // 提取合约全部余额
    function withdraw() external onlyOwner nonReentrant whenNotPaused {
        uint256 bal = address(this).balance;
        if (bal == 0) revert TransferFailed();
        (bool success, ) = payable(owner()).call{value: bal}("");
        if (!success) revert TransferFailed();
        emit Withdrawn(owner(), bal);
    }

    // 定向紧急提款，全局暂停时禁止操作
    function emergencyWithdraw(address _to, uint256 _amount) external onlyOwner whenNotPaused {
        require(_amount <= address(this).balance);
        (bool success, ) = payable(_to).call{value: _amount}("");
        if (!success) revert TransferFailed();
    }
}