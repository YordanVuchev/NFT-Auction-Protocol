//SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.sol";
import {RaptorNFT} from "../src/RaptorNFT.sol";
import {Auction} from "../src/Auction.sol";

contract Deploy is Script {
    function run() public {
        HelperConfig helperConfig = new HelperConfig();

        (
            address owner,
            address ethUsdPriceFeed,
            uint256 deployerKey,
            uint256 initialNftPrice,
            uint256 stalenessDuration,
            string memory initialNftUri,
            uint256 auctionInitialPrice,
            uint256 minAuctionDeposit,
            address usdc
        ) = helperConfig.activeNetworkConfig();

        vm.startBroadcast(deployerKey);

        RaptorNFT nft = new RaptorNFT(initialNftPrice, ethUsdPriceFeed, stalenessDuration, owner, initialNftUri);

        Auction auction = new Auction(address(nft), auctionInitialPrice, minAuctionDeposit, usdc, owner);

        vm.prank(owner);
        nft.setAuctionAddress(address(auction));

        vm.stopBroadcast();
    }
}
