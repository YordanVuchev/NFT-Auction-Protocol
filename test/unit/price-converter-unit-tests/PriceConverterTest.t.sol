//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {MockV3Aggregator} from "../../mocks/MockV3Aggregator.sol";
import {PriceConverter} from "../../../src/libraries/PriceConverter.sol";
import {Test, console} from "forge-std/Test.sol";

contract PriceConverterTest is Test {
    MockV3Aggregator priceFeed;

    int256 constant INITIAL_PRICE = 2000e18;

    function setUp() external {
        priceFeed = new MockV3Aggregator(18, INITIAL_PRICE);
    }

    function testPriceIsCorrectWhenFresh() public view {
        uint256 stalenessThreshold = 10 minutes;

        uint256 price = PriceConverter.getPrice(priceFeed, stalenessThreshold);

        assertEq(int256(price), INITIAL_PRICE);
    }

    function testRevertsWhenPriceIsStale() public {
        uint256 stalenessThreshold = 60 seconds;

        vm.warp(24 hours);

        uint80 roundId = 100;
        int256 staleAnswer = 1800e18;
        uint256 updatedAt = block.timestamp - 3 hours;
        uint256 startedAt = updatedAt;

        priceFeed.updateRoundData(roundId, staleAnswer, updatedAt, startedAt);

        (,,, uint256 updatedAtHere, uint80 answeredInRound) = priceFeed.latestRoundData();

        vm.expectRevert();
        uint256 price = this.getChainlinkPrice();
    }

    function testRevertsWhenPriceIsNegative() public {
        priceFeed.updateAnswer(-100);

        vm.expectRevert(PriceConverter.PriceConverter__InvalidPriceFeedData.selector);
        this.getChainlinkPrice();
    }

    function getChainlinkPrice() public returns (uint256) {
        return PriceConverter.getPrice(priceFeed, 30 minutes);
    }
}
