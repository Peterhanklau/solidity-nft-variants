// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract EnglishAuction is ReentrancyGuard, Ownable {
    // 拍卖状态
    enum AuctionState { ACTIVE, ENDED, CANCELLED }
    
    // 拍卖结构体
    struct Auction {
        address seller;           // 卖家
        address nftContract;      // NFT合约地址
        uint256 tokenId;          // NFT tokenId
        uint256 startTime;        // 开始时间
        uint256 endTime;          // 结束时间
        uint256 startPrice;       // 起拍价
        uint256 highestBid;       // 最高出价
        address highestBidder;    // 最高出价者
        AuctionState state;       // 拍卖状态
    }
    
    // 存储映射
    mapping(uint256 => Auction) public auctions;
    mapping(address => mapping(uint256 => uint256)) public pendingReturns; // 待退款金额
    uint256 public auctionCount;
    
    // 事件
    event AuctionCreated(
        uint256 indexed auctionId,
        address indexed seller,
        address nftContract,
        uint256 tokenId,
        uint256 startPrice,
        uint256 startTime,
        uint256 endTime
    );
    
    event BidPlaced(
        uint256 indexed auctionId,
        address indexed bidder,
        uint256 amount
    );
    
    event AuctionEnded(
        uint256 indexed auctionId,
        address indexed winner,
        uint256 amount
    );
    
    event Withdrawn(
        address indexed recipient,
        uint256 amount
    );

    constructor() Ownable(msg.sender) {}

    /**
     * @dev 创建新的拍卖
     */
    function createAuction(
        address _nftContract,
        uint256 _tokenId,
        uint256 _startPrice,
        uint256 _durationInHours
    ) external returns (uint256) {
        require(_startPrice > 0, "Start price must be positive");
        require(_durationInHours > 0, "Duration must be positive");
        
        // 确保调用者是NFT所有者
        IERC721 nft = IERC721(_nftContract);
        require(nft.ownerOf(_tokenId) == msg.sender, "Not NFT owner");
        
        // 转移NFT到拍卖合约（托管）
        nft.transferFrom(msg.sender, address(this), _tokenId);
        
        uint256 auctionId = auctionCount++;
        
        // auctions 是一个映射（mapping），用于存储所有拍卖，这一行代码就是创建并存储一个新的拍卖对象
        auctions[auctionId] = Auction({
            seller: msg.sender,
            nftContract: _nftContract,
            tokenId: _tokenId,
            startTime: block.timestamp,
            endTime: block.timestamp + (_durationInHours * 1 hours),
            startPrice: _startPrice,
            highestBid: 0,
            highestBidder: address(0),
            state: AuctionState.ACTIVE
        });
        
        emit AuctionCreated(
            auctionId,
            msg.sender,
            _nftContract,
            _tokenId,
            _startPrice,
            block.timestamp,
            block.timestamp + (_durationInHours * 1 hours)
        );
        
        return auctionId;
    }

    /**
     * @dev 参与竞拍
     */
    function bid(uint256 _auctionId) external payable nonReentrant {
        Auction storage auction = auctions[_auctionId];
        
        require(auction.state == AuctionState.ACTIVE, "Auction not active");
        require(block.timestamp < auction.endTime, "Auction ended");
        require(msg.value > auction.highestBid, "Bid too low");
        require(msg.value >= auction.startPrice, "Bid below start price");
        
        // 如果有之前的最高出价者，退还其资金，这里的highestBidder是在最新拍卖后前一个拍卖者出价者，highestBid也是对应的这个之前出价者出价
        if (auction.highestBidder != address(0)) {
            pendingReturns[auction.highestBidder][_auctionId] += auction.highestBid;
        }
        
        // 更新最高出价
        auction.highestBid = msg.value;
        auction.highestBidder = msg.sender;
        
        emit BidPlaced(_auctionId, msg.sender, msg.value);
    }

    /**
     * @dev 取回未中标的资金
     */
    function withdraw(uint256 _auctionId) external nonReentrant {
        uint256 amount = pendingReturns[msg.sender][_auctionId];
        require(amount > 0, "No funds to withdraw");
        
        pendingReturns[msg.sender][_auctionId] = 0;
        
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed");
        
        emit Withdrawn(msg.sender, amount);
    }

    /**
     * @dev 结束拍卖
     */
    function endAuction(uint256 _auctionId) external nonReentrant {
        Auction storage auction = auctions[_auctionId];
        
        require(auction.state == AuctionState.ACTIVE, "Auction not active");
        require(block.timestamp >= auction.endTime, "Auction not ended");
        require(msg.sender == auction.seller || msg.sender == owner(), "Not authorized");
        
        auction.state = AuctionState.ENDED;
        
        if (auction.highestBidder != address(0)) {
            // 有中标者：转移NFT给中标者，资金给卖家
            IERC721(auction.nftContract).transferFrom(
                address(this), 
                auction.highestBidder, 
                auction.tokenId
            );
            
            (bool success, ) = payable(auction.seller).call{value: auction.highestBid}("");
            require(success, "Transfer to seller failed");
            
            emit AuctionEnded(_auctionId, auction.highestBidder, auction.highestBid);
        } else {
            // 无人出价：退回NFT给卖家
            IERC721(auction.nftContract).transferFrom(
                address(this), 
                auction.seller, 
                auction.tokenId
            );
            
            emit AuctionEnded(_auctionId, address(0), 0);
        }
    }

    /**
     * @dev 获取拍卖信息
     */
    function getAuction(uint256 _auctionId) external view returns (Auction memory) {
        return auctions[_auctionId];
    }

    /**
     * @dev 获取可退款金额
     */
    function getPendingReturn(address _bidder, uint256 _auctionId) external view returns (uint256) {
        return pendingReturns[_bidder][_auctionId];
    }

    /**
     * @dev 检查拍卖是否活跃
     */
    function isAuctionActive(uint256 _auctionId) external view returns (bool) {
        Auction storage auction = auctions[_auctionId];
        return auction.state == AuctionState.ACTIVE && block.timestamp < auction.endTime;
    }
}
