//SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {RaptorNFT} from "./RaptorNFT.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Time} from "./libraries/Time.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Auction is Ownable  {
    using SafeERC20 for IERC20;

    error Auction__DepositTooLow();
    error Auction__AuctionHasEnded();
    error Auction__AuctionActive();
    error Auction__WinnerCannotRefund();

    uint256 public s_nftInitialPrice;
    uint256 public s_highestBidAmount;
    uint256 s_auctionCycle;
    uint256 s_minimumDepositAmount;

    uint32 s_auctionEndTimestamp;
    address public s_highestBidder;

    uint32 public constant AUCTION_MIN_DURATION = 2 hours;

    struct UserDeposit {
        uint256 depositAmount;
        uint256 auctionCycle;
    }

    mapping(address => mapping(uint256 s_auctionCycle => UserDeposit)) userDeposits;
    mapping(uint256 => address) auctionWinners;

    RaptorNFT immutable nft;
    IERC20 immutable usdc;

    constructor(address _nft, uint256 _nftInitialPrice, uint256 _minimumDepositAmount, address _usdc, address owner) Ownable(owner) {
        nft = RaptorNFT(_nft);
        s_nftInitialPrice = _nftInitialPrice;
        s_highestBidAmount = _nftInitialPrice;
        s_minimumDepositAmount = _minimumDepositAmount;
        usdc = IERC20(_usdc);

        s_auctionCycle = 1;
        s_auctionEndTimestamp = Time.blockTs() + AUCTION_MIN_DURATION;
    }

    function bid(uint256 depositAmount) external {
        if (s_auctionEndTimestamp < Time.blockTs()) {
            revert Auction__AuctionHasEnded();
        }

        if (depositAmount <= s_highestBidAmount || depositAmount < s_minimumDepositAmount) {
            revert Auction__DepositTooLow();
        }

        usdc.safeTransferFrom(msg.sender, address(this), depositAmount);

        s_highestBidAmount = depositAmount;
        s_highestBidder = msg.sender;
        auctionWinners[s_auctionCycle] = msg.sender;

        userDeposits[msg.sender][s_auctionCycle] =
            UserDeposit({depositAmount: depositAmount, auctionCycle: s_auctionCycle});

        if (s_auctionEndTimestamp - Time.blockTs() <= 2 minutes) {
            s_auctionEndTimestamp += 5 minutes;
        }
    }

    function refund(uint256 auctionCycle) external {
        if (auctionCycle >= s_auctionCycle) {
            revert Auction__AuctionActive();
        }

        if (auctionWinners[auctionCycle] == msg.sender) {
            revert Auction__WinnerCannotRefund();
        }

        UserDeposit memory userDeposit = userDeposits[msg.sender][auctionCycle];

        usdc.safeTransfer(msg.sender, userDeposit.depositAmount);

        delete userDeposits[msg.sender][auctionCycle];
    }

    function mintNftToAuctionWinner() external {
        if (Time.blockTs() < s_auctionEndTimestamp) {
            revert Auction__AuctionActive();
        }

        nft.mintNftToAuctionWinner(s_highestBidder);

        delete userDeposits[s_highestBidder][s_auctionCycle];

        s_auctionCycle++;
        s_auctionEndTimestamp = Time.blockTs() + AUCTION_MIN_DURATION;
        s_highestBidder = address(0);
        s_highestBidAmount = 0;
    }


    function claimAuctionWinnings() external onlyOwner {
      uint256 usdcBalance = usdc.balanceOf(address(this));

      usdc.safeTransfer(owner(), usdcBalance);
    }
}
