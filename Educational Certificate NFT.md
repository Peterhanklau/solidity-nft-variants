
# Educational Certificate NFT - Smart Contract Development Document

## 1. Project Overview

An ERC721-based educational certificate NFT system implementing non-transferable soulbound tokens for online education platform course certification.

| Item | Description |
|------|-------------|
| Contract Name | EducationalCertificateNFT |
| Standard | ERC721 + Soulbound |
| Solidity Version | ^0.8.19 |
| Dependencies | OpenZeppelin 4.x |

---

2. Core Functions

| Function | Description | Access |
|----------|-------------|--------|
| Mint Certificate | Issue NFT certificate to student | MINTER_ROLE |
| Verify Certificate | Verify authenticity via verification code | Public |
| Query Certificate | Query by tokenId or studentId | Public |
| Burn Certificate | Revoke and destroy certificate | ADMIN_ROLE |
| Update IPFS | Update off-chain data hash | ADMIN_ROLE |

---

3. Data Structure

```solidity
struct CertificateMetadata {
    string studentId;        // Student ID
    string studentName;      // Student name
    string courseName;       // Course name
    string courseCode;       // Course code
    uint256 graduationDate;  // Graduation date
    string grade;            // Grade
    string ipfsHash;         // IPFS hash of detailed data
    string verificationCode; // Verification code
}

4. Roles & Permissions

Role	Description
DEFAULT_ADMIN_ROLE	Super admin, can grant/revoke roles
ADMIN_ROLE	Admin, can burn certificates and update IPFS
MINTER_ROLE	Minter, can issue certificates

5. Core Functions

5.1 Mint Certificate
function mintCertificate(
    address studentAddress,
    string memory studentId,
    string memory studentName,
    string memory courseName,
    string memory courseCode,
    uint256 graduationDate,
    string memory grade,
    string memory ipfsHash,
    string memory verificationCode
) external onlyRole(MINTER_ROLE) returns (uint256)
Description: Issue an NFT certificate to a student. Verification code must be unique.

5.3 Query Certificate
// Query by tokenId
function getCertificate(uint256 tokenId) external view returns (...);

// Query by studentId
function getCertificateByStudentId(string memory studentId) external view returns (...);

5.4 Burn Certificate
solidity
function burnCertificate(uint256 tokenId) external onlyRole(ADMIN_ROLE)
Description: Admin can revoke and destroy a certificate.

6. Soulbound Implementation  

solidity
function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId,
    uint256 batchSize
) internal virtual override {
    // Only allow minting (from=0) and burning (to=0)
    require(
        from == address(0) || to == address(0),
        "Non-transferable token"
    );
}
Description: Certificates cannot be transferred after minting. Only mint and burn operations are allowed.

7. Deployment Information  

Constructor Parameters
solidity
constructor(
    string memory name,    // NFT name, e.g., "EduCert"
    string memory symbol,  // NFT symbol, e.g., "EDU"
    address admin          // Admin address
)
Deployment Commands
bash
# Compile
npx hardhat compile

# Test
npx hardhat test

# Deploy
npx hardhat run scripts/deploy.js --network sepolia

# Verify
npx hardhat verify --network sepolia <CONTRACT_ADDRESS> "EduCert" "EDU" <ADMIN_ADDRESS>

8. Events

Event	Trigger
CertificateMinted	After certificate minting
CertificateVerified	After certificate verification

9. Testing Requirements

Unit test coverage ≥ 90%

Key test cases:

Only MINTER_ROLE can mint

Transfer is disabled

Verification code cannot be reused

Verification function works correctly

Burn function cleans up data properly

10. Security Considerations

Risk	Mitigation
Private key leak	Use multi-sig wallet for admin
Verification code reuse	Track used codes via mapping
Duplicate certificates	Unique studentId check
Reentrancy attack	Follow CEI pattern

11. Deliverables

Smart contract code (.sol)

Unit tests

Deployment script

Contract verification proof

Technical documentation (.md)

ABI file (.json)

12. Version History

Version	Date	Description
1.0.0	2025-03-26	Initial release
Maintainer: Development Team

中文版本
# 教育证书NFT - 智能合约开发文档

## 1. 项目概述

基于ERC721的教育证书NFT系统，实现不可转让的灵魂绑定证书，用于在线教育平台的课程结业认证。

| 项目 | 说明 |
|------|------|
| 合约名称 | EducationalCertificateNFT |
| 标准 | ERC721 + Soulbound |
| Solidity版本 | ^0.8.19 |
| 依赖库 | OpenZeppelin 4.x |

---

## 2. 核心功能

| 功能 | 说明 | 权限 |
|------|------|------|
| 铸造证书 | 为学员发行NFT证书 | MINTER_ROLE |
| 验证证书 | 通过验证码验证真伪 | 公开 |
| 查询证书 | 按tokenId或学生ID查询 | 公开 |
| 销毁证书 | 撤销并销毁证书 | ADMIN_ROLE |
| 更新IPFS | 更新链下数据哈希 | ADMIN_ROLE |

---

## 3. 数据结构

```solidity
struct CertificateMetadata {
    string studentId;        // 学生学号
    string studentName;      // 学生姓名
    string courseName;       // 课程名称
    string courseCode;       // 课程代码
    uint256 graduationDate;  // 毕业日期
    string grade;            // 成绩
    string ipfsHash;         // 详细数据IPFS哈希
    string verificationCode; // 验证码
}

4. 角色与权限

角色	权限说明
DEFAULT_ADMIN_ROLE	超级管理员，可授予/撤销角色
ADMIN_ROLE	管理员，可销毁证书、更新IPFS
MINTER_ROLE	铸造者，可发行证书

5. 核心函数说明

5.1 铸造证书
solidity
function mintCertificate(
    address studentAddress,
    string memory studentId,
    string memory studentName,
    string memory courseName,
    string memory courseCode,
    uint256 graduationDate,
    string memory grade,
    string memory ipfsHash,
    string memory verificationCode
) external onlyRole(MINTER_ROLE) returns (uint256)
说明：为学员铸造NFT证书，验证码全局唯一。

5.2 验证证书
solidity
function verifyCertificate(
    uint256 tokenId,
    string memory verificationCode
) external returns (bool)
说明：输入tokenId和验证码，验证证书真伪。

5.3 查询证书
solidity
// 按tokenId查询
function getCertificate(uint256 tokenId) external view returns (...);

// 按学生ID查询
function getCertificateByStudentId(string memory studentId) external view returns (...);

5.4 销毁证书
solidity
function burnCertificate(uint256 tokenId) external onlyRole(ADMIN_ROLE)
说明：管理员可撤销并销毁证书。

6. 灵魂绑定实现

solidity
function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId,
    uint256 batchSize
) internal virtual override {
    // 仅允许铸造（from=0）和销毁（to=0）
    require(
        from == address(0) || to == address(0),
        "Non-transferable token"
    );
}
说明：证书铸造后不可转让，仅支持铸造和销毁操作。

7. 部署信息

构造函数参数
solidity
constructor(
    string memory name,    // NFT名称，如 "EduCert"
    string memory symbol,  // NFT符号，如 "EDU"
    address admin          // 管理员地址
)
部署命令
bash
# 编译
npx hardhat compile

# 测试
npx hardhat test

# 部署
npx hardhat run scripts/deploy.js --network sepolia

# 验证
npx hardhat verify --network sepolia <合约地址> "EduCert" "EDU" <管理员地址>

8. 事件说明

事件	触发时机
CertificateMinted	铸造证书成功后
CertificateVerified	验证证书后

9. 测试要求

单元测试覆盖率 ≥ 90%

关键测试用例：

仅MINTER_ROLE可铸造

禁止转让证书

验证码不可重复使用

验证功能正确性

销毁功能正确清理数据

10. 安全注意事项

风险	缓解措施
私钥泄露	管理员使用多签钱包
验证码重复	映射记录已使用验证码
学生重复证书	studentId唯一性检查
重入攻击	遵循CEI模式

11. 交付物

智能合约代码（.sol）

单元测试脚本

部署脚本

合约验证证明

技术文档（.md）

ABI文件（.json）

12. 版本记录

版本	日期	说明
1.0.0	2025-03-26	初始版本
维护者：开发团队


