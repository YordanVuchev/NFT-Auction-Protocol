//SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {RaptorNFT} from "../../src/RaptorNFT.sol";
import {Auction} from "../../src/Auction.sol";
import {MockV3Aggregator} from "../mocks/MockV3Aggregator.sol";
import {MockERC20} from "../mocks/MockERC20.sol";

contract BaseTest is Test {
    RaptorNFT nft;
    Auction auction;
    MockV3Aggregator mockPriceFeed;
    MockERC20 usdc;

    string constant NFT_NAME = "Raptor";
    string constant NFT_SYMBOL = "RR";
    string constant INITIAL_NFT_URI = "ipfs://bafkreihouvejsacfci5g67bbrsyxstp2g3vt4w6ctqd3fd6p5kssykdjfa";
    address OWNER = makeAddr("owner");
    address BOB = makeAddr("bob");

    int256 INITIAL_ETH_USD_PRICE = 2000e18;
    uint256 public constant INITIAL_NFT_PRICE = 50e18;
    uint256 public constant INITIAL_USER_BALANCE = 10 ether;
    uint256 public constant INITIAL_USER_STABLE_BALANCE = 1000e6;
    uint256 public constant INITIAL_STALENESS_DURATION = 30 minutes;

    uint256 public constant INITIAL_AUCTION_NFT_PRICE = 30e6;
    uint256 public constant MIN_AUCTION_DEPOSIT_AMOUNT = 5e6;
    
    function setUp() public virtual {
        mockPriceFeed = new MockV3Aggregator(18, INITIAL_ETH_USD_PRICE);
        nft =
            new RaptorNFT(INITIAL_NFT_PRICE, address(mockPriceFeed), INITIAL_STALENESS_DURATION, OWNER, INITIAL_NFT_URI);

    
        usdc = new MockERC20(6);

        auction = new Auction(address(nft),INITIAL_AUCTION_NFT_PRICE,MIN_AUCTION_DEPOSIT_AMOUNT, address(usdc), OWNER);

        vm.deal(BOB, INITIAL_USER_BALANCE);
        usdc.mint(BOB, INITIAL_USER_STABLE_BALANCE);
    }
}
