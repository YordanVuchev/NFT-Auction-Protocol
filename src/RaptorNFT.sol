//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "./libraries/PriceConverter.sol";

contract RaptorNFT is ERC721, Ownable {
    using PriceConverter for uint256;

    error RaptorNFT__NotWhitelisted();
    error RaptorNFT__AddressZero();

    uint256 public s_tokenIdCounter;

    mapping(address => bool) public s_whitelistedUsers;

    AggregatorV3Interface private s_priceFeed;

    constructor(address _priceFeed) ERC721("Raptor", "RR") Ownable(msg.sender) {
        s_priceFeed = AggregatorV3Interface(_priceFeed);
    }

    modifier onlyWhitelisted() {
        if (!s_whitelistedUsers[msg.sender]) {
            revert RaptorNFT__NotWhitelisted();
        }
        _;
    }

    modifier notAddressZero(address addr) {
        if (addr == address(0)) {
            revert RaptorNFT__AddressZero();
        }

        _;
    }

    function mintNftWithETH() external onlyWhitelisted {
        _mint(msg.sender, s_tokenIdCounter);

        s_tokenIdCounter++;
    }

    function addUserToWhitelist(address user) external onlyOwner notAddressZero(user) {
        s_whitelistedUsers[user] = true;
    }

    function removeUserFromWhitelist(address user) external onlyOwner notAddressZero(user) {
        s_whitelistedUsers[user] = false;
    }
}
