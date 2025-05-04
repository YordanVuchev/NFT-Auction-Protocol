//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "./libraries/PriceConverter.sol";

contract RaptorNFT is ERC721, Ownable {
    using SafeERC20 for IERC20;
    using PriceConverter for uint256;

    error RaptorNFT__NotEnoughFunds();
    error RaptorNFT__NotWhitelisted();
    error RaptorNFT__AddressZero();

    uint256 public s_tokenIdCounter;
    uint256 public s_nftPriceInUsd;
    mapping(address => bool) public s_whitelistedUsers;

    AggregatorV3Interface private s_priceFeed;
    
    IERC20 immutable usdc;

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

    constructor(uint256 initialNftPrice, address _usdc, address _priceFeed)
        ERC721("Raptor", "RR")
        Ownable(msg.sender)
    {
        s_nftPriceInUsd = initialNftPrice;
        usdc = IERC20(_usdc);
        s_priceFeed = AggregatorV3Interface(_priceFeed);
    }

    function mintNftWithETH() external payable onlyWhitelisted {
        uint256 depositAmountInUsd = msg.value.getConversionRate(s_priceFeed);

        _mintNft(depositAmountInUsd);
    }

    function mintNftWithUSDC(uint256 depositAmount) external onlyWhitelisted {
        usdc.safeTransferFrom(msg.sender, address(this), depositAmount);

        uint256 usdcDecimals = IERC20Metadata(address(usdc)).decimals();
        uint256 scaledDepositAmount = depositAmount * (10 ** (18 - usdcDecimals));

        _mintNft(scaledDepositAmount);
    }

    function addUserToWhitelist(address user) external onlyOwner notAddressZero(user) {
        s_whitelistedUsers[user] = true;
    }

    function removeUserFromWhitelist(address user) external onlyOwner notAddressZero(user) {
        s_whitelistedUsers[user] = false;
    }

    function changeNftPrice(uint256 newPriceInUsd) external onlyOwner {
        s_nftPriceInUsd = newPriceInUsd;
    }

    function _mintNft(uint256 depositAmountInUSD) internal {
        if (depositAmountInUSD < s_nftPriceInUsd) {
            revert RaptorNFT__NotEnoughFunds();
        }

        _mint(msg.sender, s_tokenIdCounter);

        s_tokenIdCounter++;
    }
}
