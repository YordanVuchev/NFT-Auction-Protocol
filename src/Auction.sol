//SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {RaptorNFT} from "./RaptorNFT.sol";
import {Time} from "./libraries/Time.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Auction {
  using SafeERC20 for IERC20;

  error Auction__DepositTooLow();
  error Auction__AuctionHasEnded();

  uint256 public s_nftInitialPrice;
  uint256 public s_highestBidAmount;
  address public s_highestBidder;
  uint256 s_auctionCycle;
  uint32 s_auctionEndTimestamp;

  struct UserDeposit {
    uint256 depositAmount;
    uint256 auctionCycle;
  }

  mapping(address => mapping(uint256 s_auctionCycle => UserDeposit )) userDeposits;

  RaptorNFT immutable nft;
  IERC20 immutable usdc;

  constructor(address _nft, uint256 _nftInitialPrice, address _usdc) {
    nft = RaptorNFT(_nft);
    s_nftInitialPrice = _nftInitialPrice;
    s_highestBidAmount = _nftInitialPrice;
    usdc = IERC20(_usdc);

    s_auctionCycle = 1;
    s_auctionEndTimestamp = Time.blockTs() + 2 hours;
  }


  function bid(uint256 depositAmount) external {

    if(s_auctionEndTimestamp < Time.blockTs()) {
      revert Auction__AuctionHasEnded();
    }

    if(depositAmount <= s_highestBidAmount) {
      revert Auction__DepositTooLow();
    }

    usdc.safeTransferFrom(msg.sender,address(this),depositAmount);

    s_highestBidAmount = depositAmount;
    s_highestBidder = msg.sender;

    userDeposits[msg.sender][s_auctionCycle] =  UserDeposit({depositAmount: depositAmount, auctionCycle: s_auctionCycle});
  }

  

}