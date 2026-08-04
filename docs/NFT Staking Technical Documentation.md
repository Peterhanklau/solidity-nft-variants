Technical Documentation (English Version First)
NFT Staking ETH Mining Contract Technical Specification
1 Overall Architecture Overview
The contract adopts layered architecture design: staking data layer, reward calculation layer, permission control layer and risk protection layer. It is developed based on OpenZeppelin standard libraries, integrating three core security modules: ReentrancyGuard, Pausable and Ownable.
Layered Architecture
Data Layer: Record users' NFT staking status, staking start time and last reward claiming time.
Calculation Layer: Calculate ETH mining revenue linearly according to staking duration.
Risk Control Layer: Global pause switch, batch quantity limit, timelock for emergency withdrawal.
Interaction Layer: Interconnect with standard ERC721 NFT contracts.
2 Core Struct & Mapping Source Code
solidity
struct StakingInfo {
    uint256 startTime;
    uint256 lastClaimTime;
    bool isStaked;
}
mapping(address => mapping(uint256 => StakingInfo)) public stakingRecord;
3 Reward Calculation Formula
Reward per single NFT = (Current block timestamp − Last claim timestamp) * Reward per second per NFT / 10 ** 18
4 Deployment Script Snippets (Reserved for customers to adjust deployment parameters during debugging)
Core logic inside scripts/deploy.js:
js
运行
async function main() {
  // Modify NFT contract address, daily yield and warning balance here
  const nftAddress = "DEPLOYED_ERC721_CONTRACT_ADDRESS";
  const dailyReward = ethers.parseEther("0.05");
  const minPoolBalance = ethers.parseEther("0.1");
  const StakeContract = await ethers.getContractFactory("NFTStaking");
  const stakeIns = await StakeContract.deploy(nftAddress, dailyReward, minPoolBalance);
  await stakeIns.waitForDeployment();
  console.log("Contract deployed address: ", await stakeIns.getAddress());
}
5 Dismantling Logic of Core Functions
Staking Logic
Verify NFT ownership & confirm the target NFT is not staked currently;
Call ERC721 transferFrom to transfer NFT into this contract;
Write staking records and initialize staking time & reward calculation start time;
Emit event Staked(address user, uint256 tokenId).
Batch Unstaking Secure Logic (Core CEI Implementation)
Follow strict CEI execution sequence:
Check the length of NFT array ≤ 100;
Traverse NFT collection: update staking status of all NFTs, accumulate total pending rewards;
After all status modifications are completed, distribute ETH rewards uniformly;
Finally transfer all NFTs back to user wallets in batches.
Advantage: No intermediate exploitable unfinished status exists.
6 Detailed Audit Explanation of Security Mechanisms
Reentrancy Prevention: All user-facing functions are decorated with nonReentrant, preventing attackers from recursively calling staking functions within the onERC721Received callback to steal funds.
Global Pausable Emergency Switch: Once vulnerabilities emerge, administrators can call setPaused(true) to suspend all contract businesses instantly.
Timelock Withdrawal Restriction: A 7-day waiting period is mandatory after administrators apply for emergency withdrawal; anyone is allowed to cancel the withdrawal application before expiration to prevent malicious fund withdrawal by administrators.
7 Coverage Scope of Unit Test Scripts (Usage of test directory scripts)
Test complete normal processes: stake, unstake & claim rewards.
Test error reporting when batch staking quantity exceeds limit.
Simulate reentrancy attack for security verification.
Verify users cannot stake NFTs after contract is paused.
Test transaction rollback scenario when reward pool balance is insufficient for reward withdrawal.
8 Operation & Debug Code Snippets
Reward pool funding snippet:
js
运行
const sendEth = async () => {
  const contract = await ethers.getContractAt("NFTStaking", "DEPLOYED_CONTRACT_ADDRESS");
  const tx = await contract.send({value: ethers.parseEther("2")});
  await tx.wait();
}
9 Handling Scheme for Boundary Scenarios
Staking duration less than 1 second: Integer rounding results in zero reward, no abnormal risks.
Insufficient funds in reward pool: Reward claiming transaction rolls back entirely without altering any staking data.
If the ERC721 NFT contract contains blacklist & transfer restriction logic, corresponding NFT cannot be staked, and the staking contract will not crash abnormally.
10 Iteration & Expansion Schemes
Introduce NFT weight system to set different mining multipliers for various NFTs.
Add locked staking mode with fixed lock-up cycles.
Integrate chain oracle to realize dynamic yield adjustment.
11 Supporting Deployment Process (Retained as technical archive, consistent with deployment commands in README)
Configure private key and RPC link inside .env file;
Execute npm install to install dependencies;
Run npm run compile to compile smart contracts;
Execute deployment script to deploy contract onto blockchain;
Execute the verification command printed in terminal to open-source & verify contract source code on Etherscan.
技术文档（中文版本）
NFT 质押 ETH 挖矿合约 完整技术文档
1 整体架构概述
合约采用分层架构设计：质押数据层、奖励计算层、权限控制层、风控防护层。整体基于 OpenZeppelin 标准库开发，集成 ReentrancyGuard、Pausable、Ownable 三大安全模块。
架构分层
数据层：记录用户 NFT 质押状态、质押起始时间、上次领奖时间；
计算层：根据质押时长线性结算 ETH 挖矿收益；
风控层：全局暂停开关、批量数量上限、紧急提现时间锁；
交互层：对接标准 ERC721 NFT 合约。
2 核心结构体与映射源码
solidity
struct StakingInfo {
    uint256 startTime;
    uint256 lastClaimTime;
    bool isStaked;
}
mapping(address => mapping(uint256 => StakingInfo)) public stakingRecord;
3 奖励计算公式
单枚 NFT 收益 =（当前区块时间 − 上次领奖时间）× 单 NFT 每秒奖励数值 ÷ 10 ** 18
4 部署脚本源码片段（保留给客户调试时修改部署参数）
scripts/deploy.js 核心逻辑：
js
运行
async function main() {
  // 可在此处修改NFT合约地址、单日挖矿收益、奖励池预警余额
  const nftAddress = "已部署的ERC721合约地址";
  const dailyReward = ethers.parseEther("0.05");
  const minPoolBalance = ethers.parseEther("0.1");
  const StakeContract = await ethers.getContractFactory("NFTStaking");
  const stakeIns = await StakeContract.deploy(nftAddress, dailyReward, minPoolBalance);
  await stakeIns.waitForDeployment();
  console.log("合约部署地址：", await stakeIns.getAddress());
}
5 关键函数逻辑拆解
质押逻辑
校验 NFT 归属权，同时确认该 NFT 当前未处于质押状态；
调用 ERC721 的 transferFrom 将 NFT 转入质押合约；
写入质押记录，初始化质押时间与计息起始时间；
触发 Staked(address user, uint256 tokenId) 事件。
批量解质押安全逻辑（CEI 安全模式核心实现）
严格遵循 CEI 执行顺序：
校验传入 NFT 数组长度 ≤ 100；
遍历 NFT 集合，更新全部 NFT 质押状态并累加用户待结算总奖励；
所有状态修改完毕之后，统一发放 ETH 奖励；
最后批量将 NFT 转回用户钱包。
优势：全程不存在可被攻击的未完成中间状态。
6 安全机制详细审计说明
重入防护：所有面向用户的业务函数均添加 nonReentrant 修饰，避免攻击者在 NFT 接收回调 onERC721Received 内递归调用质押函数实施盗币攻击；
全局暂停熔断机制：合约出现漏洞时，管理员调用 setPaused(true) 即可立刻暂停合约所有业务；
提现时间锁管控：管理员提交紧急提现申请后强制等待 7 天才可执行提现，到期前任意人均可撤销提现申请，防止管理员作恶卷走资金。
7 单元测试覆盖范围（test 目录脚本用途）
正常质押、解质押、领取奖励完整流程测试；
批量质押数量超限报错校验测试；
模拟重入攻击，验证防护有效性；
合约暂停后禁止用户质押的权限校验测试；
奖励池资金不足、领奖交易回滚场景测试。
8 运维调试代码片段
奖励池充值脚本片段：
js
运行
const sendEth = async () => {
  const contract = await ethers.getContractAt("NFTStaking", "部署完成的合约地址");
  const tx = await contract.send({value: ethers.parseEther("2")});
  await tx.wait();
}
9 边界场景处理方案
质押时长不足 1 秒：Solidity 整数向下取整，收益归零，不存在异常风险；
奖励池余额不足以发放奖励：领奖交易整体回滚，不会篡改任何质押数据；
若 NFT 合约自带黑名单、转账限制逻辑，对应 NFT 无法完成质押，质押合约不会崩溃异常。
10 迭代扩展方案
新增 NFT 权重系统，为不同 NFT 配置差异化挖矿倍率；
增加周期锁仓质押模式，设置指定锁仓期限；
接入链上预言机，实现挖矿收益率动态调整。
11 配套部署流程（作为技术归档留存，与 README 部署命令保持一致）
在项目根目录.env 文件配置部署私钥与 RPC 节点链接；
执行 npm install 安装项目依赖；
运行 npm run compile 编译智能合约；
执行部署脚本将合约部署上链；
运行控制台输出的合约验证指令，在 Etherscan 开源并验证合约源码。
Supplement Note
Readme is for quick deployment and usage by customers; this technical document is used for contract audit, parameter modification and secondary development.
Only deployment procedures overlap slightly between the two documents, while other contents complement each other without redundant repetition, which meets the requirement of convenient use for customers.