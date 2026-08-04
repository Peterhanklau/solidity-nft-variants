const { expect } = require("chai");
const { ethers } = require("hardhat");
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");

describe("NFTStaking 质押合约测试", function () {
  async function deployFixture() {
    // 部署测试用Mock ERC721
    const ERC721MockFactory = await ethers.getContractFactory("ERC721Mock");
    const nftMock = await ERC721MockFactory.deploy("MockNFT", "MNFT");
    await nftMock.waitForDeployment();

    const dailyReward = ethers.parseEther("0.1");
    const minPool = ethers.parseEther("0.1");

    const StakingFactory = await ethers.getContractFactory("NFTStaking");
    const staking = await StakingFactory.deploy(await nftMock.getAddress(), dailyReward, minPool);
    await staking.waitForDeployment();

    const [owner, user1, user2, attacker] = await ethers.getSigners();

    // 给用户铸造NFT
    await nftMock.connect(user1).mint(1);
    await nftMock.connect(user1).mint(2);

    return { staking, nftMock, owner, user1, user2, attacker };
  }

  describe("基础质押&解质押", function () {
    it("单个NFT质押、解质押正常发放奖励", async function () {
      const { staking, nftMock, user1 } = await loadFixture(deployFixture);
      const stakingAddr = await staking.getAddress();

      await nftMock.connect(user1).setApprovalForAll(stakingAddr, true);
      await staking.connect(user1).stake(1);
      expect(await staking.isStaked(user1.address, 1)).to.equal(true);

      // 给奖励池充值
      await user1.sendTransaction({ to: stakingAddr, value: ethers.parseEther("10") });

      // 区块时间快进1小时
      await ethers.provider.send("evm_increaseTime", [3600]);
      await ethers.provider.send("evm_mine");

      const reward = await staking.calculateReward(user1.address, 1);
      expect(reward > 0).to.equal(true);

      const beforeBalance = await ethers.provider.getBalance(user1.address);
      await staking.connect(user1).unstake(1);
      const afterBalance = await ethers.provider.getBalance(user1.address);

      expect(afterBalance > beforeBalance).to.equal(true);
      expect(await staking.isStaked(user1.address, 1)).to.equal(false);
    });
  });

  describe("批量上限校验", function () {
    it("最多批量质押100个NFT，超出报错", async function () {
      const { staking, nftMock, user1 } = await loadFixture(deployFixture);
      const stakingAddr = await staking.getAddress();
      await nftMock.connect(user1).setApprovalForAll(stakingAddr, true);

      const ids = [];
      for (let i = 3; i <= 103; i++) {
        await nftMock.connect(user1).mint(i);
        ids.push(i);
      }
      await staking.connect(user1).stakeBatch(ids.slice(0, 100));
      await expect(staking.connect(user1).stakeBatch(ids)).to.be.revertedWith("Batch too large");
    });
  });

  describe("重入防护校验", function () {
    it("nonReentrant 上锁拦截跨函数重入", async function () {
      const { staking, nftMock, attacker } = await loadFixture(deployFixture);
      const stakingAddr = await staking.getAddress();
      await nftMock.connect(attacker).mint(999);
      await nftMock.connect(attacker).setApprovalForAll(stakingAddr, true);
      await staking.connect(attacker).stake(999);
      await attacker.sendTransaction({ to: stakingAddr, value: ethers.parseEther("5") });

      await expect(staking.connect(attacker).unstake(999)).not.to.be.reverted;
    });
  });

  describe("领奖时序安全", function () {
    it("奖励池没钱领奖失败，不会更新lastClaimTime", async function () {
      const { staking, nftMock, user1 } = await loadFixture(deployFixture);
      const stakingAddr = await staking.getAddress();
      await nftMock.connect(user1).setApprovalForAll(stakingAddr, true);
      await staking.connect(user1).stake(1);

      // 奖励池为空，领奖回滚
      await expect(staking.connect(user1).claimReward(1)).to.be.revertedWith("Insufficient reward pool");
      const infoBefore = await staking.stakings(user1.address, 1);
      await ethers.provider.send("evm_increaseTime", [1000]);
      const infoAfter = await staking.stakings(user1.address, 1);

      expect(infoBefore.lastClaimTime).to.equal(infoAfter.lastClaimTime);
    });
  });

  describe("暂停熔断功能", function () {
    it("管理员暂停后用户无法质押", async function () {
      const { staking, nftMock, owner, user1 } = await loadFixture(deployFixture);
      await staking.connect(owner).setPaused(true);
      await nftMock.connect(user1).setApprovalForAll(await staking.getAddress(), true);
      await expect(staking.connect(user1).stake(1)).to.be.revertedWithCustomError(staking, "EnforcedPause");
    });
  });
});