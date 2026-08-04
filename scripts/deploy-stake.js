const { ethers } = require("hardhat");

async function main() {
  // 替换成你正式 NFT 合约地址
  const NFT_ADDRESS = "0xe24AD22eA7526fdf9266Ca91CCa921Cab30226d0";
  // 单个NFT每日奖励 0.05 ETH
  const DAILY_REWARD_WEI = ethers.parseEther("0.05");
  // 奖励池最低警戒线 0.1ETH
  const MIN_POOL_BALANCE = ethers.parseEther("0.1");

  const StakingFactory = await ethers.getContractFactory("NFTStaking");
  const staking = await StakingFactory.deploy(NFT_ADDRESS, DAILY_REWARD_WEI, MIN_POOL_BALANCE);

  await staking.waitForDeployment();
  const stakingAddr = await staking.getAddress();
  console.log(`NFTStaking deployed to: ${stakingAddr}`);

  console.log("\n部署完成后验证命令：");
  console.log(`npx hardhat verify --network sepolia ${stakingAddr} ${NFT_ADDRESS} ${DAILY_REWARD_WEI} ${MIN_POOL_BALANCE}`);
}

main()
  .catch(err => {
    console.error(err);
    process.exit(1);
  });