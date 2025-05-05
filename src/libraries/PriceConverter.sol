//SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {wmul} from "../utils/Math.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

import {console} from "forge-std/Test.sol";

library PriceConverter {
    error PriceConverter__InvalidPriceFeedData();
    error PriceConverter__StalePriceFeedData();

    function getPrice(AggregatorV3Interface priceFeed, uint256 stalenessThreshold) internal view returns (uint256) {
        (uint80 roundId, int256 price,, uint256 updatedAt, uint80 answeredInRound) = priceFeed.latestRoundData();
        
        if (price < 0) revert PriceConverter__InvalidPriceFeedData();

        if (answeredInRound < roundId) revert PriceConverter__StalePriceFeedData();

        if (block.timestamp - updatedAt > stalenessThreshold) {
            revert PriceConverter__StalePriceFeedData();
        }

        return uint256(price) * (10 ** (18 - priceFeed.decimals()));
    }

    function getConversionRate(uint256 ethAmount, AggregatorV3Interface priceFeed, uint256 stalenessThreshold)
        internal
        view
        returns (uint256)
    {
        uint256 ethPriceInUSD = getPrice(priceFeed, stalenessThreshold);
        uint256 ethAmountInUsd = wmul(ethPriceInUSD, ethAmount);

        return ethAmountInUsd;
    }
}
