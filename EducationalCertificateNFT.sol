// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract EducationalCertificateNFT is ERC721, AccessControl {
    using Counters for Counters.Counter;
    using Strings for uint256;
    
    // 角色定义
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    
    // 计数器
    Counters.Counter private _tokenIdCounter;
    
    // 元数据结构
    struct CertificateMetadata {
        string studentId;
        string studentName;
        string courseName;
        string courseCode;
        uint256 graduationDate;
        string grade;
        string ipfsHash; // 链下详细数据的IPFS哈希
        string verificationCode; // 验证码
    }
    
    // 存储映射
    mapping(uint256 => CertificateMetadata) private _certificates;
    mapping(string => bool) private _usedVerificationCodes;
    mapping(string => uint256) private _studentCertificate; // 学生ID -> tokenId
    
    // 事件
    event CertificateMinted(
        uint256 indexed tokenId,
        address indexed studentAddress,
        string studentId,
        string courseCode
    );
    
    event CertificateVerified(
        uint256 indexed tokenId,
        address verifier,
        bool isValid
    );
    
    // 构造函数
    constructor(
        string memory name,
        string memory symbol,
        address admin
    ) ERC721(name, symbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(ADMIN_ROLE, admin);
        _grantRole(MINTER_ROLE, admin);
    }
    
    // 铸造证书 - 仅管理员可调用
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
    ) external onlyRole(MINTER_ROLE) returns (uint256) {
        require(studentAddress != address(0), "Invalid student address");
        require(bytes(studentId).length > 0, "Student ID required");
        require(_studentCertificate[studentId] == 0, "Certificate already exists for this student");
        require(!_usedVerificationCodes[verificationCode], "Verification code already used");
        
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        
        // 铸造NFT
        _safeMint(studentAddress, tokenId);
        
        // 存储元数据
        _certificates[tokenId] = CertificateMetadata({
            studentId: studentId,
            studentName: studentName,
            courseName: courseName,
            courseCode: courseCode,
            graduationDate: graduationDate,
            grade: grade,
            ipfsHash: ipfsHash,
            verificationCode: verificationCode
        });
        
        // 记录验证码已使用
        _usedVerificationCodes[verificationCode] = true;
        
        // 记录学生证书
        _studentCertificate[studentId] = tokenId;
        
        emit CertificateMinted(tokenId, studentAddress, studentId, courseCode);
        
        return tokenId;
    }
    
    // 重写转移函数，实现Soulbound（不可转让）
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
        
        // 允许从零地址转移（铸造）
        // 允许转移到零地址（销毁）
        // 禁止其他转移
        require(
            from == address(0) || to == address(0),
            "EducationalCertificateNFT: Non-transferable token"
        );
    }
    
    // 验证证书
    function verifyCertificate(
        uint256 tokenId,
        string memory verificationCode
    ) external returns (bool) {
        require(_exists(tokenId), "Certificate does not exist");
        
        CertificateMetadata memory cert = _certificates[tokenId];
        bool isValid = keccak256(abi.encodePacked(cert.verificationCode)) == 
                      keccak256(abi.encodePacked(verificationCode));
        
        emit CertificateVerified(tokenId, msg.sender, isValid);
        
        return isValid;
    }
    
    // 获取证书元数据
    function getCertificate(uint256 tokenId) external view returns (
        string memory studentId,
        string memory studentName,
        string memory courseName,
        string memory courseCode,
        uint256 graduationDate,
        string memory grade,
        string memory ipfsHash
    ) {
        require(_exists(tokenId), "Certificate does not exist");
        
        CertificateMetadata memory cert = _certificates[tokenId];
        return (
            cert.studentId,
            cert.studentName,
            cert.courseName,
            cert.courseCode,
            cert.graduationDate,
            cert.grade,
            cert.ipfsHash
        );
    }
    
    // 通过学生ID获取证书
    function getCertificateByStudentId(string memory studentId) external view returns (
        uint256 tokenId,
        address owner,
        string memory courseName,
        string memory grade
    ) {
        tokenId = _studentCertificate[studentId];
        require(tokenId != 0, "No certificate found for this student");
        
        CertificateMetadata memory cert = _certificates[tokenId];
        owner = ownerOf(tokenId);
        
        return (tokenId, owner, cert.courseName, cert.grade);
    }
    
    // 销毁证书（仅管理员）
    function burnCertificate(uint256 tokenId) external onlyRole(ADMIN_ROLE) {
        require(_exists(tokenId), "Certificate does not exist");
        
        CertificateMetadata memory cert = _certificates[tokenId];
        
        // 清理存储
        delete _studentCertificate[cert.studentId];
        delete _certificates[tokenId];
        
        _burn(tokenId);
    }
    
    // 设置IPFS哈希（用于更新链下数据）
    function setIPFSHash(uint256 tokenId, string memory ipfsHash) external onlyRole(ADMIN_ROLE) {
        require(_exists(tokenId), "Certificate does not exist");
        _certificates[tokenId].ipfsHash = ipfsHash;
    }
    
    // 支持接口
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}