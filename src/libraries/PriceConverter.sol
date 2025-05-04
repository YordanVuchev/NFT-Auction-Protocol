//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {wmul} from "../utils/Math.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed) internal view returns (uint256) {
        (, int256 price,,,) = priceFeed.latestRoundData();

        return uint256(price) * (10 ** (18 - priceFeed.decimals()));
    }

    function getConversionRate(uint256 ethAmount, AggregatorV3Interface priceFeed) internal view returns (uint256) {
        uint256 ethPriceInUSD = getPrice(priceFeed);
        uint256 ethAmountInUsd = wmul(ethPriceInUSD, ethAmount);

        return ethAmountInUsd;
    }
}
