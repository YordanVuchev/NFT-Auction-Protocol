//SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {RaptorNFT} from "./RaptorNFT.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Time} from "./libraries/Time.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Auction is Ownable {
    using SafeERC20 for IERC20;

    error Auction__DepositTooLow();
    error Auction__AuctionHasEnded();
    error Auction__AuctionActive();
    error Auction__RewardClaimed();
    error Auction__BidAlreadyClaimed();

    uint256 public s_highestBidAmount;
    uint256 public s_auctionInitialPrice;
    uint256 public s_auctionCycle;
    uint256 s_minimumDepositAmount;

    uint32 public s_auctionEndTimestamp;

    uint32 public constant AUCTION_MIN_DURATION = 2 hours;

    struct AuctionBidder {
        address bidder;
        uint256 bidAmount;
        bool rewardClaimed;
        bool bidClaimed;
    }

    mapping(uint256 => AuctionBidder) s_highestBidders;
    mapping(address => uint256) s_refunds;

    RaptorNFT immutable nft;
    IERC20 immutable usdc;

    event BidPlaced(address indexed user, uint256 indexed amount);
    event NftClaimed(address indexed winner);
    event InitialPriceUpdated(uint256 indexed price);
    event BidderRefunded(address indexed user, uint256 indexed amount);

    modifier updateAuction() {
        if (Time.blockTs() > s_auctionEndTimestamp) {
            s_auctionEndTimestamp = Time.blockTs() + AUCTION_MIN_DURATION;
            s_auctionCycle++;
            s_highestBidAmount = s_auctionInitialPrice;
        }

        _;
    }

    modifier auctionHasEnded(uint256 auctionCycle) {
        if (auctionCycle >= s_auctionCycle && Time.blockTs() < s_auctionEndTimestamp) {
            revert Auction__AuctionActive();
        }

        _;
    }

    constructor(address _nft, uint256 _nftInitialPrice, uint256 _minimumDepositAmount, address _usdc, address owner)
        Ownable(owner)
    {
        nft = RaptorNFT(_nft);
        s_auctionInitialPrice = _nftInitialPrice;
        s_minimumDepositAmount = _minimumDepositAmount;
        s_highestBidAmount = _nftInitialPrice - _minimumDepositAmount;
        usdc = IERC20(_usdc);

        s_auctionCycle = 1;
        s_auctionEndTimestamp = Time.blockTs() + AUCTION_MIN_DURATION;
    }

    function bid(uint256 depositAmount) external updateAuction {
        if (depositAmount <= s_highestBidAmount || depositAmount < s_highestBidAmount + s_minimumDepositAmount) {
            revert Auction__DepositTooLow();
        }

        usdc.safeTransferFrom(msg.sender, address(this), depositAmount);

        AuctionBidder storage currentBidder = s_highestBidders[s_auctionCycle];

        if (currentBidder.bidder != address(0)) {
            s_refunds[currentBidder.bidder] +=  currentBidder.bidAmount;
        }

        currentBidder.bidAmount = depositAmount;
        currentBidder.bidder = msg.sender;
        s_highestBidAmount = depositAmount;

        if (s_auctionEndTimestamp - Time.blockTs() <= 2 minutes) {
            s_auctionEndTimestamp += 5 minutes;
        }

        emit BidPlaced(msg.sender, depositAmount);
    }

    function mintNftToAuctionWinner(uint256 auctionCycle) external auctionHasEnded(auctionCycle) {
        AuctionBidder storage currentBidder = s_highestBidders[auctionCycle];

        if (currentBidder.rewardClaimed) {
            revert Auction__RewardClaimed();
        }

        nft.mintNftToAuctionWinner(currentBidder.bidder);

        currentBidder.rewardClaimed = true;

        emit NftClaimed(currentBidder.bidder);
    }

    function claimAuctionWinnings(uint256 auctionCycle) external onlyOwner auctionHasEnded(auctionCycle) {
        AuctionBidder storage bidder = s_highestBidders[auctionCycle];

        if (bidder.bidClaimed) {
            revert Auction__BidAlreadyClaimed();
        }

        usdc.safeTransfer(owner(), bidder.bidAmount);

        bidder.bidClaimed = true;
    }

    function refund() external {
        usdc.safeTransfer(msg.sender,s_refunds[msg.sender]);

        emit BidderRefunded(msg.sender,s_refunds[msg.sender]);

        s_refunds[msg.sender] = 0;
    }

    function setAuctionInitialPrice(uint256 newInitialPrice) external onlyOwner {
        s_auctionInitialPrice = newInitialPrice;

        emit InitialPriceUpdated(newInitialPrice);
    }

    function getAuctionBidder(uint256 auctionCycle) external view returns (AuctionBidder memory) {
        return s_highestBidders[auctionCycle];
    }
}
