// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract NFTStakeToken is ERC721, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenIdCounter;

    uint256 public mintPrice = 0.001 ether;
    uint256 public maxSupply = 1000;
    uint256 public maxPerWallet = 5;
    uint256 public maxBatchMint = 20;

    bool public publicMintOpen = false;
    bool whiteListOpen = false;

    mapping(address => bool) public whiteList;
    mapping(address => uint256) public walletMinted;

    string private _baseTokenURI;
    bool public isMetadataFrozen = false;

    event MintPriceUpdated(uint256 newPrice);
    event MaxSupplyUpdated(uint256 newMaxSupply);
    event MaxPerWalletUpdated(uint256 newMaxPerWallet);
    event MaxBatchMintUpdated(uint256 newMaxBatch);
    event PublicMintStatusChanged(bool status);
    event WhiteListStatusChanged(bool status);
    event WhiteListAdded(address[] users);
    event WhiteListRemoved(address[] users);
    event BaseURISet(string newURI);
    event MetadataFrozen();
    event Withdrawal(address indexed to, uint256 amount);

    constructor(string memory name_, string memory symbol_, string memory baseURI_) ERC721(name_, symbol_) {
        _baseTokenURI = baseURI_;
    }

    function mint(uint256 quantity) external payable {
        require(publicMintOpen, "Public mint closed");
        require(quantity > 0 && quantity <= maxBatchMint, "Batch limit");
        require(walletMinted[msg.sender] + quantity <= maxPerWallet, "Wallet limit");
        require(_tokenIdCounter.current() + quantity <= maxSupply, "Sold out");
        require(msg.value == mintPrice * quantity, "Wrong ETH amount");

        walletMinted[msg.sender] += quantity;
        for (uint256 i = 0; i < quantity; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _safeMint(msg.sender, tokenId);
        }
    }

    function whiteListMint(uint256 quantity) external payable {
        require(whiteListOpen, "WL mint closed");
        require(whiteList[msg.sender], "Not whitelist");
        require(quantity > 0 && quantity <= maxBatchMint, "Batch limit");
        require(walletMinted[msg.sender] + quantity <= maxPerWallet, "Wallet limit");
        require(_tokenIdCounter.current() + quantity <= maxSupply, "Sold out");
        require(msg.value == mintPrice * quantity, "Wrong ETH");

        walletMinted[msg.sender] += quantity;
        for (uint256 i = 0; i < quantity; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _safeMint(msg.sender, tokenId);
        }
    }

    function ownerMint(address to, uint256 quantity) external onlyOwner {
        require(quantity > 0 && quantity <= maxBatchMint, "Batch limit");
        require(_tokenIdCounter.current() + quantity <= maxSupply, "Max supply");
        for (uint256 i = 0; i < quantity; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _safeMint(to, tokenId);
        }
    }

    function addWhiteList(address[] calldata users) external onlyOwner {
        for (uint256 i = 0; i < users.length; i++) {
            whiteList[users[i]] = true;
        }
        emit WhiteListAdded(users);
    }

    function removeWhiteList(address[] calldata users) external onlyOwner {
        for (uint256 i = 0; i < users.length; i++) {
            whiteList[users[i]] = false;
        }
        emit WhiteListRemoved(users);
    }

    function setWhiteListStatus(bool status) external onlyOwner {
        whiteListOpen = status;
        emit WhiteListStatusChanged(status);
    }

    function setPublicMintStatus(bool status) external onlyOwner {
        publicMintOpen = status;
        emit PublicMintStatusChanged(status);
    }

    function setMintPrice(uint256 newPrice) external onlyOwner {
        mintPrice = newPrice;
        emit MintPriceUpdated(newPrice);
    }

    function setMaxSupply(uint256 newMaxSupply) external onlyOwner {
        require(newMaxSupply >= _tokenIdCounter.current(), "Cannot reduce below minted");
        maxSupply = newMaxSupply;
        emit MaxSupplyUpdated(newMaxSupply);
    }

    function setMaxPerWallet(uint256 newMax) external onlyOwner {
        require(newMax > 0, "must >0");
        maxPerWallet = newMax;
        emit MaxPerWalletUpdated(newMax);
    }

    function setMaxBatchMint(uint256 newMax) external onlyOwner {
        require(newMax > 0, "must >0");
        maxBatchMint = newMax;
        emit MaxBatchMintUpdated(newMax);
    }

    function setBaseURI(string calldata newURI) external onlyOwner {
        require(!isMetadataFrozen, "Metadata locked");
        _baseTokenURI = newURI;
        emit BaseURISet(newURI);
    }

    function freezeMetadata() external onlyOwner {
        require(!isMetadataFrozen, "Already frozen");
        isMetadataFrozen = true;
        emit MetadataFrozen();
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "Token does not exist");
        return string(abi.encodePacked(_baseTokenURI, tokenId.toString(), ".json"));
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
        emit Withdrawal(msg.sender, balance);
    }

    // 标准写法：同时标注两个父合约
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function totalSupply() public view override(ERC721Enumerable) returns (uint256) {
        return super.totalSupply();
    }
}