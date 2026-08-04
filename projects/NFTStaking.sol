// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
// 改回 security，适配 OZ4
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract NFTStaking is ReentrancyGuard, Ownable, ERC721Holder, Pausable {
    using Strings for uint256;

    IERC721 public immutable nftContract;

    struct StakingInfo {
        uint256 tokenId;
        uint256 startTime;
        uint256 lastClaimTime;
        bool isStaked;
    }

    uint256 public constant CALC_SCALE = 1e18;
    uint256 public rewardRatePerSecond;
    uint256 public constant MAX_BATCH_SIZE = 100;
    uint256 public constant EMERGENCY_WITHDRAW_DELAY = 7 days;
    uint256 public minRewardPoolBalance;

    mapping(address => mapping(uint256 => StakingInfo)) public stakings;
    mapping(address => uint256[]) public stakedTokens;
    mapping(address => mapping(uint256 => uint256)) public tokenIndex;

    uint256 public emergencyWithdrawRequestTime;
    address public emergencyWithdrawTarget;

    event Staked(address indexed user, uint256 indexed tokenId, uint256 timestamp);
    event Unstaked(address indexed user, uint256 indexed tokenId, uint256 reward);
    event UnstakeBatch(address indexed user, uint256[] tokenIds, uint256 totalReward);
    event RewardClaimed(address indexed user, uint256 indexed tokenId, uint256 reward);
    event AllRewardsClaimed(address indexed user, uint256 totalReward, uint256 count);
    event RewardRateUpdated(uint256 newDailyRewardWei);
    event PausedSet(bool paused);
    event EmergencyWithdrawRequested(address indexed target, uint256 requestTs);
    event EmergencyWithdrawCancelled();
    event EmergencyWithdrawExecuted(address indexed target, uint256 amount);
    event RewardPoolFunded(address indexed funder, uint256 amount);
    event MinRewardPoolBalanceUpdated(uint256 newMinBalance);

    constructor(
        address _nftContract,
        uint256 _initDailyRewardWei,
        uint256 _minRewardPoolBalance
    ) Ownable() {
        require(_nftContract != address(0), "Zero NFT address");
        nftContract = IERC721(_nftContract);
        rewardRatePerSecond = (_initDailyRewardWei * CALC_SCALE) / 1 days;
        minRewardPoolBalance = _minRewardPoolBalance;
    }

    // ============ 质押逻辑 ============
    function stake(uint256 _tokenId) external nonReentrant whenNotPaused {
        _stakeSingle(msg.sender, _tokenId);
    }

    function stakeBatch(uint256[] calldata _tokenIds) external nonReentrant whenNotPaused {
        require(_tokenIds.length <= MAX_BATCH_SIZE, "Batch too large");
        address user = msg.sender;
        uint256 nowTime = block.timestamp;
        uint256 len = _tokenIds.length;

        for (uint256 i = 0; i < len; i++) {
            uint256 tid = _tokenIds[i];
            require(nftContract.ownerOf(tid) == user, string.concat("Not owner #", tid.toString()));
            require(!stakings[user][tid].isStaked, string.concat("Staked already #", tid.toString()));

            nftContract.safeTransferFrom(user, address(this), tid);

            stakings[user][tid] = StakingInfo({
                tokenId: tid,
                startTime: nowTime,
                lastClaimTime: nowTime,
                isStaked: true
            });
            tokenIndex[user][tid] = stakedTokens[user].length;
            stakedTokens[user].push(tid);

            emit Staked(user, tid, nowTime);
        }
    }

    function _stakeSingle(address user, uint256 _tokenId) internal {
        require(nftContract.ownerOf(_tokenId) == user, "Not token owner");
        require(!stakings[user][_tokenId].isStaked, "Already staked");

        nftContract.safeTransferFrom(user, address(this), _tokenId);
        uint256 nowTime = block.timestamp;
        stakings[user][_tokenId] = StakingInfo({
            tokenId: _tokenId,
            startTime: nowTime,
            lastClaimTime: nowTime,
            isStaked: true
        });

        tokenIndex[user][_tokenId] = stakedTokens[user].length;
        stakedTokens[user].push(_tokenId);
        emit Staked(user, _tokenId, nowTime);
    }

    // ============ 解质押（严格CEI：状态全部更新完毕再转账NFT） ============
    function unstake(uint256 _tokenId) external nonReentrant whenNotPaused {
        StakingInfo storage staking = stakings[msg.sender][_tokenId];
        require(staking.isStaked, "Not staked");

        uint256 reward = calculateReward(msg.sender, _tokenId);
        if (reward > 0) {
            require(address(this).balance >= reward, "Insufficient reward pool");
        }

        staking.isStaked = false;
        _removeTokenFromStakedList(msg.sender, _tokenId);

        if (reward > 0) {
            (bool success, ) = payable(msg.sender).call{value: reward}("");
            require(success, "Reward transfer failed");
        }
        nftContract.safeTransferFrom(address(this), msg.sender, _tokenId);

        emit Unstaked(msg.sender, _tokenId, reward);
    }

    function unstakeBatch(uint256[] calldata _tokenIds) external nonReentrant whenNotPaused {
        require(_tokenIds.length <= MAX_BATCH_SIZE, "Batch too large");
        address user = msg.sender;
        uint256 totalReward = 0;

        // 合并循环：校验+算奖励+更新质押状态，减少Gas消耗
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 tid = _tokenIds[i];
            StakingInfo storage st = stakings[user][tid];
            require(st.isStaked, string.concat("Not staked #", tid.toString()));

            totalReward += calculateReward(user, tid);
            st.isStaked = false;
            _removeTokenFromStakedList(user, tid);
        }

        require(address(this).balance >= totalReward, "Insufficient reward pool");

        // 发放ETH奖励
        if (totalReward > 0) {
            (bool success, ) = payable(user).call{value: totalReward}("");
            require(success, "Batch reward failed");
        }

        // 最后才批量归还NFT，杜绝回调篡改中间状态
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            nftContract.safeTransferFrom(address(this), user, _tokenIds[i]);
        }

        emit UnstakeBatch(user, _tokenIds, totalReward);
    }

    // ============ 领取奖励 ============
    function claimReward(uint256 _tokenId) external nonReentrant whenNotPaused {
        StakingInfo storage staking = stakings[msg.sender][_tokenId];
        require(staking.isStaked, "Not staked");

        uint256 reward = calculateReward(msg.sender, _tokenId);
        if (reward > 0) {
            require(address(this).balance >= reward, "Insufficient reward pool");
            (bool success, ) = payable(msg.sender).call{value: reward}("");
            require(success, "Reward transfer failed");
        }
        staking.lastClaimTime = block.timestamp;

        emit RewardClaimed(msg.sender, _tokenId, reward);
    }

    function claimAllRewards() external nonReentrant whenNotPaused {
        uint256[] memory tokens = stakedTokens[msg.sender];
        require(tokens.length > 0, "No staked NFT");

        uint256 totalReward = 0;
        uint256 claimedCount = 0;
        uint256 nowTime = block.timestamp;
        address user = msg.sender;

        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 tid = tokens[i];
            StakingInfo storage staking = stakings[user][tid];
            if (!staking.isStaked) continue;

            uint256 reward = calculateReward(user, tid);
            if (reward > 0) {
                totalReward += reward;
                claimedCount++;
            }
            staking.lastClaimTime = nowTime;
        }

        require(totalReward > 0, "No pending reward");
        require(address(this).balance >= totalReward, "Insufficient reward pool");

        (bool success, ) = payable(user).call{value: totalReward}("");
        require(success, "Batch reward transfer failed");

        emit AllRewardsClaimed(user, totalReward, claimedCount);
    }

    // ============ 视图查询接口 ============
    function calculateReward(address _user, uint256 _tokenId) public view returns (uint256) {
        StakingInfo memory staking = stakings[_user][_tokenId];
        if (!staking.isStaked) return 0;
        uint256 duration = block.timestamp - staking.lastClaimTime;
        return (duration * rewardRatePerSecond) / CALC_SCALE;
    }

    // 预估用户所有质押NFT待结算总奖励
    function estimateAllRewards(address _user) external view returns (uint256) {
        uint256[] memory tokens = stakedTokens[_user];
        uint256 totalReward = 0;
        for (uint256 i = 0; i < tokens.length; i++) {
            totalReward += calculateReward(_user, tokens[i]);
        }
        return totalReward;
    }

    function getStakedTokens(address _user) external view returns (uint256[] memory) {
        return stakedTokens[_user];
    }

    function getStakedCount(address _user) external view returns (uint256) {
        return stakedTokens[_user].length;
    }

    function isStaked(address _user, uint256 _tokenId) external view returns (bool) {
        return stakings[_user][_tokenId].isStaked;
    }

    function getDailyRewardWei() external view returns (uint256) {
        return (rewardRatePerSecond * 1 days) / CALC_SCALE;
    }

    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function getStakingDuration(address _user, uint256 _tokenId) external view returns (uint256) {
        StakingInfo memory staking = stakings[_user][_tokenId];
        require(staking.isStaked, "Not staked");
        return block.timestamp - staking.startTime;
    }

    // 检查奖励池余额是否健康
    function isRewardPoolHealthy() external view returns (bool) {
        return address(this).balance >= minRewardPoolBalance;
    }

    // ============ 管理员权限 ============
    function setRewardRate(uint256 _newDailyRewardWei) external onlyOwner {
        rewardRatePerSecond = (_newDailyRewardWei * CALC_SCALE) / 1 days;
        emit RewardRateUpdated(_newDailyRewardWei);
    }

    function setMinRewardPoolBalance(uint256 _newMinBalance) external onlyOwner {
        minRewardPoolBalance = _newMinBalance;
        emit MinRewardPoolBalanceUpdated(_newMinBalance);
    }

    function setPaused(bool _paused) external onlyOwner {
        if (_paused) _pause();
        else _unpause();
        emit PausedSet(_paused);
    }

    function requestEmergencyWithdraw(address _to) external onlyOwner {
        require(_to != address(0), "Invalid target");
        emergencyWithdrawRequestTime = block.timestamp;
        emergencyWithdrawTarget = _to;
        emit EmergencyWithdrawRequested(_to, block.timestamp);
    }

    // 撤销紧急提现申请
    function cancelEmergencyWithdraw() external onlyOwner {
        emergencyWithdrawRequestTime = 0;
        emergencyWithdrawTarget = address(0);
        emit EmergencyWithdrawCancelled();
    }

    function executeEmergencyWithdraw() external onlyOwner {
        address target = emergencyWithdrawTarget;
        require(target != address(0), "No withdraw request");
        require(block.timestamp >= emergencyWithdrawRequestTime + EMERGENCY_WITHDRAW_DELAY, "Wait 7 days");

        uint256 balance = address(this).balance;
        require(balance > 0, "No ETH inside contract");

        emergencyWithdrawTarget = address(0);
        emergencyWithdrawRequestTime = 0;

        (bool success, ) = payable(target).call{value: balance}("");
        require(success, "Emergency withdraw failed");
        emit EmergencyWithdrawExecuted(target, balance);
    }

    // ============ 内部工具：O(1)删除质押数组元素 ============
    function _removeTokenFromStakedList(address _user, uint256 _tokenId) internal {
        uint256 index = tokenIndex[_user][_tokenId];
        uint256[] storage tokenList = stakedTokens[_user];
        uint256 lastIndex = tokenList.length - 1;

        if (index != lastIndex) {
            uint256 lastTokenId = tokenList[lastIndex];
            tokenList[index] = lastTokenId;
            tokenIndex[_user][lastTokenId] = index;
        }
        tokenList.pop();
        delete tokenIndex[_user][_tokenId];
    }

    // 奖励池充值，触发事件记录入账
    receive() external payable {
        emit RewardPoolFunded(msg.sender, msg.value);
    }
}
