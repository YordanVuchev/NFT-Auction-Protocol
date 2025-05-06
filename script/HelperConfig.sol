//SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script} from "forge-std/Script.sol";

contract HelperConfig is Script {
    NetworkConfig public activeNetworkConfig;

    struct NetworkConfig {
        address owner;
        address ethUsdPriceFeed;
        uint256 deployerKey;
        uint256 initialNftPrice;
        uint256 stalenessDuration;
        string initialNftUri;
        uint256 auctionInitialPrice;
        uint256 minAuctionDeposit;
        address usdc;
    }

    constructor() {
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaEthConfig();
        }
    }

    function getSepoliaEthConfig() public view returns (NetworkConfig memory config) {
        config = NetworkConfig({
            owner: vm.envAddress("OWNER"),
            ethUsdPriceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306,
            deployerKey: vm.envUint("PRIVATE_KEY"),
            initialNftPrice: vm.envUint("INITIAL_NFT_PRICE"),
            stalenessDuration: vm.envUint("STALENESS_DURATION"),
            initialNftUri: vm.envString("NFT_URI"),
            auctionInitialPrice: vm.envUint("AUCTION_INITIAL_PRICE"),
            minAuctionDeposit: vm.envUint("MIN_AUCTION_DEPOSIT"),
            usdc: vm.envAddress("USDC")
        });
    }
}
