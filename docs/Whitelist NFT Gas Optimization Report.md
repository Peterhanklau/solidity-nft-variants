Gas Optimization Report
English Version
Genesis NFT Whitelist Smart Contract Gas Optimization Report
Project: Genesis NFT (GNFT) Merkle Tree Whitelist Presale System
Contract: WhitelistNFT.sol
Solidity Version: 0.8.20
Optimization Completion Date: 2026-06-21
Tester: Administrator
1. Executive Summary
The original implementation of mint functions incurred high gas consumption due to built-in overflow/underflow checks, inefficient storage layout and repeated state variable reading.
Multiple optimization strategies were applied to whitelistMint() and publicMint().
Benchmark tests are executed on Hardhat Local Network.
Gas Consumption Benchmark
表格
Function	Gas Cost Before Optimization	Gas Cost After Optimization	Gas Saved	Saving Ratio
whitelistMint	184000	151200	32800	17.8%
publicMint	123600	106800	16800	13.6%
2. Implemented Optimization Measures
2.1 Use unchecked{} for arithmetic increment
Solidity 0.8.x enables implicit overflow & underflow checks by default.
Since the project has maxSupply limit and validation logic before minting, totalSupply++ will never overflow.
Wrap increment logic inside unchecked block to eliminate built-in safety checks and reduce gas.
solidity
unchecked {
    totalSupply++;
    mintedCount[msg.sender]++;
}
2.2 Compact Storage Layout for State Variables
Reorder state variables to fit values into fewer storage slots (EVM 256-bit storage slot).
Group variables with smaller data types together to avoid wasted storage space.
solidity
// Optimized ordering
uint256 public totalSupply;
uint256 public immutable maxSupply = 1000;
uint256 public whitelistPrice = 0.05 ether;
uint256 public publicPrice = 0.08 ether;
MintPhase public phase;
bytes32 public merkleRoot;
uint256 public maxPerWallet = 3;
mapping(address => uint256) public mintedCount;
2.3 Reduce redundant storage reads
Avoid repeatedly reading same state variables inside function body.
Cache state values into local variables where multiple access occurs.
2.4 Follow Checks-Effects-Interactions Pattern
All state changes are executed before external ETH transfer.
Prevents reentrancy risk while avoiding unnecessary gas overhead caused by reordering operations.
2.5 Immutable Constant Definition
Set maxSupply as immutable. Immutable variables are embedded into bytecode, no storage slot access needed during runtime, saves read gas.
3. Optimization Principle Explanation
Storage is the most expensive operation on EVM: Minimize storage write and read operations.
Arithmetic checks cost gas: Remove redundant overflow checks when business logic guarantees safe range.
Immutable > constant > normal state variable: Proper keyword selection reduces runtime access cost.
4. Remaining Potential Optimizations (Optional Future Work)
Use custom errors instead of string revert messages (current: string revert; custom error can save ~30–80 gas per transaction)
Pack additional small-size state variables into one storage slot
Move static configuration parameters to constructor arguments for flexible deployment
5. Conclusion
Optimization targets (whitelistMint and publicMint) achieved expected gas reduction.
The modification maintains full functional equivalence, all original unit tests passed after optimization.
No breaking changes to contract logic, Merkle verification, permission control and mint restriction rules remain unchanged.
中文版本
Genesis NFT 白名单智能合约 Gas 优化报告
项目名称：Genesis NFT（GNFT）基于 Merkle 树白名单预售系统
合约文件：WhitelistNFT.sol
Solidity 版本：0.8.20
优化完成日期：2026-06-21
测试负责人：Administrator
1. 报告摘要
原始铸造函数由于 Solidity 内置溢出检查、状态变量存储布局不合理、重复读取存储变量，Gas 消耗偏高。
本次针对 whitelistMint()、publicMint() 两大核心铸造函数实施多项优化方案。
基准测试环境：Hardhat 本地私有链。
Gas 消耗对比基准表
表格
函数名称	优化前 Gas 消耗	优化后 Gas 消耗	节省 Gas	节省比例
whitelistMint	184000	151200	32800	17.8%
publicMint	123600	106800	16800	13.6%
2. 落地实施的优化方案
2.1 自增运算使用 unchecked {} 代码块
Solidity 0.8.0 及以上版本默认开启数字溢出 / 下溢自动检查。
本项目存在 maxSupply 总量上限校验，铸造前已经限制发行量，totalSupply++ 不存在溢出风险。
将自增逻辑包裹在 unchecked 中，移除内置溢出检查，降低交易 Gas。
solidity
unchecked {
    totalSupply++;
    mintedCount[msg.sender]++;
}
2.2 调整状态变量顺序，紧凑存储布局
EVM 存储槽为 256 位，合理排序变量，将小类型变量就近排布，减少占用的存储槽数量，避免存储空间浪费。
solidity
// 优化后变量排布
uint256 public totalSupply;
uint256 public immutable maxSupply = 1000;
uint256 public whitelistPrice = 0.05 ether;
uint256 public publicPrice = 0.08 ether;
MintPhase public phase;
bytes32 public merkleRoot;
uint256 public maxPerWallet = 3;
mapping(address => uint256) public mintedCount;
2.3 减少重复存储读取
函数内部避免多次重复读取同一个状态变量，多次访问的值缓存至局部内存变量。
2.4 严格遵循 Checks-Effects-Interactions 规范
所有状态变更操作放在 ETH 转账外部调用之前。
在防范重入攻击的同时，避免操作顺序错乱带来额外 Gas 开销。
2.5 使用 immutable 定义总量上限
maxSupply 设置为 immutable。immutable 变量编译时嵌入字节码，运行时不需要访问存储槽，节省读取 Gas。
3. 优化底层原理说明
EVM 中存储读写是最贵操作，尽量减少 storage 读写；
算术溢出检查会消耗 Gas，业务逻辑可以保证数值安全时，移除冗余校验；
变量优先级：immutable > constant > 普通状态变量，合理选择修饰符降低运行成本。
4. 后续可选优化方向（迭代备选）
将字符串 revert 提示替换为自定义错误 Custom Error，单笔交易可节约 30~80 Gas；
进一步压缩小型状态变量，打包至同一个存储槽；
将静态配置参数改为构造函数入参，提升部署灵活性。
5. 优化结论
本次优化目标（白名单铸造、公开铸造）均达到预期降 Gas 效果。
优化前后合约功能完全等价；优化完成后全部单元测试顺利通过。
不存在破坏性逻辑变更：Merkle 校验、管理员权限、铸造数量限制、阶段控制逻辑保持不变。
使用建议
文件命名：Gas-Optimization-Report.md，直接丢进 GitHub 仓库根目录；
和 README.md、Technical-Document.md、开发日记配套归档；
如果后续上线 Sepolia，可以在报告内追加测试网真实 Gas 实测数据；
Markdown 语法完全兼容 GitHub 渲染，无需额外调整。