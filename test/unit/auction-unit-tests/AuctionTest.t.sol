//SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {BaseTest} from "../../base/BaseTest.sol";
import {Auction} from "../../../src/Auction.sol";

contract AuctionTest is BaseTest {

  address BIDDER = makeAddr("bidder");
  address OUTBIDDER = makeAddr("outbidder");

  uint256 INITIAL_BIDDER_BALANCE = 100e6;
  uint256 INITIAL_BIDDER_DEPOSIT = INITIAL_AUCTION_NFT_PRICE + 10e6;
  uint256 NEXT_AUCTION_SKIP_TIME = 3 hours;

  function setUp() public override {
      super.setUp();

      usdc.mint(BIDDER, INITIAL_BIDDER_BALANCE);
      usdc.mint(OUTBIDDER, INITIAL_BIDDER_BALANCE);
      vm.prank(BIDDER);
      usdc.approve(address(auction), INITIAL_BIDDER_BALANCE);

      vm.prank(OUTBIDDER);
      usdc.approve(address(auction), INITIAL_BIDDER_BALANCE);
  }

  modifier initialBid() {
    vm.startPrank(BIDDER);

    auction.bid(INITIAL_BIDDER_DEPOSIT);

    vm.stopPrank();

    _;
  }

  modifier outBidInitialBidder() {

    vm.startPrank(OUTBIDDER);

    auction.bid(INITIAL_BIDDER_DEPOSIT + MIN_AUCTION_DEPOSIT_AMOUNT);

    vm.stopPrank();

    _;
  }

  function testBidTransfersUserDepositSuccessfullyAndUpdatesState() public {

    vm.startPrank(BIDDER);

    auction.bid(INITIAL_BIDDER_DEPOSIT);

    vm.stopPrank();

    Auction.AuctionBidder memory bidderStruct = auction.getAuctionBidder(1);

    assertEq(bidderStruct.bidder, BIDDER);
    assertEq(bidderStruct.bidAmount, INITIAL_BIDDER_DEPOSIT);
  }


  function testInitialBidderCnnMintTheNFTByBiddingInitialPrice() public {

    vm.startPrank(BIDDER);

    auction.bid(INITIAL_AUCTION_NFT_PRICE);

    vm.stopPrank();

    Auction.AuctionBidder memory bidderStruct = auction.getAuctionBidder(1);

    assertEq(bidderStruct.bidder, BIDDER);
    assertEq(bidderStruct.bidAmount, INITIAL_AUCTION_NFT_PRICE);
  }

  function testBidRevertsIfBidderTriesDepositingLessThanHighestBidder() public {

    vm.startPrank(BIDDER);

    auction.bid(INITIAL_BIDDER_DEPOSIT);
    vm.stopPrank();

    vm.startPrank(OUTBIDDER);

    vm.expectRevert(Auction.Auction__DepositTooLow.selector);
    auction.bid(1);

    vm.stopPrank();
  }

  function testBidRevertsIfBidderDepositsLessThanMinimumDeposit() public initialBid {
  

    vm.startPrank(OUTBIDDER);

    vm.expectRevert(Auction.Auction__DepositTooLow.selector);
    auction.bid(INITIAL_BIDDER_DEPOSIT + MIN_AUCTION_DEPOSIT_AMOUNT - 1);

    vm.stopPrank();
  }

  function testPreviousBidderGetsRefunded() public initialBid {

    vm.startPrank(OUTBIDDER);

    auction.bid(INITIAL_BIDDER_DEPOSIT + MIN_AUCTION_DEPOSIT_AMOUNT);

    vm.stopPrank();

    assertEq(usdc.balanceOf(BIDDER), INITIAL_BIDDER_BALANCE);

  }

  function testHighestBidAmountGetsUpdatedCorrectly() public initialBid outBidInitialBidder {

    assertEq(auction.s_highestBidAmount(), INITIAL_BIDDER_DEPOSIT + MIN_AUCTION_DEPOSIT_AMOUNT);
  }


  function testAuctionIsExtendedIfBidIsMadeAtTheLastMinute() public initialBid {

    uint256 initialAuctionEndTs = auction.s_auctionEndTimestamp();

    vm.warp(initialAuctionEndTs - 1 minutes);

    vm.prank(OUTBIDDER);
    auction.bid(INITIAL_BIDDER_DEPOSIT + MIN_AUCTION_DEPOSIT_AMOUNT);
    
    uint256 updatedAuctionEndTs = auction.s_auctionEndTimestamp();

    assertEq(updatedAuctionEndTs, initialAuctionEndTs + 5 minutes);
  }

  function testMintToAuctionWinnerMintsNFTToHighestBidder() public initialBid outBidInitialBidder {

    skip(NEXT_AUCTION_SKIP_TIME);


    vm.expectEmit(true, false, false, false);
    emit Auction.NftClaimed(OUTBIDDER);
    auction.mintNftToAuctionWinner(1);

    assertEq(nft.balanceOf(OUTBIDDER),1);
  }

  function testMintRevertsIfAuctionHasNotEnded() public initialBid {

    vm.expectRevert(Auction.Auction__AuctionActive.selector);
    auction.mintNftToAuctionWinner(1);  
  }

  function testMintRevertsIfWinnerTriesClaimingTwice() public initialBid outBidInitialBidder {
    vm.startPrank(OUTBIDDER);

    skip(NEXT_AUCTION_SKIP_TIME);
    auction.mintNftToAuctionWinner(1);  

    vm.expectRevert(Auction.Auction__RewardClaimed.selector);
    auction.mintNftToAuctionWinner(1);

    vm.stopPrank();
  }


  function testWinningsSendsCorrectAmountToOwner() public initialBid {

    skip(NEXT_AUCTION_SKIP_TIME);

    vm.startPrank(OWNER);

    uint256 previousUSDCBalance = usdc.balanceOf(OWNER);

    auction.claimAuctionWinnings(1);

    uint256 afterUSDCBalance = usdc.balanceOf(OWNER);

    vm.stopPrank();

    Auction.AuctionBidder memory bidderStruct = auction.getAuctionBidder(1);

    assertEq(afterUSDCBalance - previousUSDCBalance,bidderStruct.bidAmount);
  }

  function testWinningsRevertIfOwnerTriesToClaimTwice() public initialBid {

    skip(NEXT_AUCTION_SKIP_TIME);

    vm.startPrank(OWNER);

    auction.claimAuctionWinnings(1);

    vm.expectRevert(Auction.Auction__BidAlreadyClaimed.selector);
    auction.claimAuctionWinnings(1);

    vm.stopPrank();
  }

  function testStateGetsResetWhenNewAuctionHasStarted() public {
    skip(NEXT_AUCTION_SKIP_TIME);

    vm.startPrank(BIDDER);

    auction.bid(INITIAL_BIDDER_DEPOSIT);

    vm.stopPrank();

    assertEq(auction.s_auctionCycle(), 2);
    assertEq(auction.s_highestBidAmount(), INITIAL_BIDDER_DEPOSIT);
  }


  function testOwnerCanUpdateInitialNFTPrice() public {
    vm.startPrank(OWNER);

    auction.setAuctionInitialPrice(10e6);

    vm.stopPrank();

    assertEq(auction.s_auctionInitialPrice(), 10e6);
  }
}