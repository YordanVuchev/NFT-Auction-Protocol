//SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "./libraries/PriceConverter.sol";
import {wdiv} from "./utils/Math.sol";

contract RaptorNFT is ERC721, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using PriceConverter for uint256;

    error RaptorNFT__NotEnoughFunds();
    error RaptorNFT__NotWhitelisted();
    error RaptorNFT__TokenNotSupported();
    error RaptorNFT__AddressZero();
    error RaptorNFT__RefundFailed();

    uint256 public s_tokenIdCounter;
    uint256 public s_nftPriceInUsd;
    uint256 s_priceFeedStalenessThreshold;
    mapping(address => bool) public s_whitelistedUsers;
    mapping(address => bool) public s_supportedStableTokens;

    string s_tokenURI;

    AggregatorV3Interface private s_priceFeed;

    event NftMinted(address indexed user, uint256 indexed tokenId);
    event NftPriceChanged(uint256 indexed price);
    event UserAddedToWhitelist(address indexed user);
    event UserRemovedFromWhitelist(address indexed user);
    event TokenAddedToSupportedTokens(address indexed token);
    event TokenRemovedFromSupportedTokens(address indexed token);
    event NftUriChanged(string indexed uri);
    event PriceFeedStalenessDurationChanged(uint256 indexed duration);

    modifier onlyWhitelisted() {
        if (!s_whitelistedUsers[msg.sender]) {
            revert RaptorNFT__NotWhitelisted();
        }
        _;
    }

    modifier onlySupportedTokens(address token) {
        if (!s_supportedStableTokens[token]) {
            revert RaptorNFT__TokenNotSupported();
        }

        _;
    }

    modifier notAddressZero(address addr) {
        if (addr == address(0)) {
            revert RaptorNFT__AddressZero();
        }

        _;
    }

    constructor(
        uint256 initialNftPrice,
        address _priceFeed,
        uint256 _maxStalenessThreshold,
        address owner,
        string memory _initialURI
    ) ERC721("Raptor", "RR") Ownable(owner) {
        s_nftPriceInUsd = initialNftPrice;
        s_priceFeed = AggregatorV3Interface(_priceFeed);
        s_priceFeedStalenessThreshold = _maxStalenessThreshold;
        s_tokenURI = _initialURI;
    }

    function mintNftWithETH() external payable onlyWhitelisted {
        uint256 depositAmountInUsd = msg.value.getConversionRate(s_priceFeed, s_priceFeedStalenessThreshold);

        _mintNft(depositAmountInUsd);

        uint256 ethPriceInUsd = PriceConverter.getPrice(s_priceFeed, s_priceFeedStalenessThreshold);
        uint256 requiredEth = wdiv(s_nftPriceInUsd, ethPriceInUsd);

        if (msg.value > requiredEth) {
            uint256 amountToRefund = msg.value - requiredEth;
            (bool success,) = payable(msg.sender).call{value: amountToRefund}("");

            if (!success) {
                revert RaptorNFT__RefundFailed();
            }
        }
    }

    function mintNftWithStable(address token) external onlyWhitelisted onlySupportedTokens(token) {
        uint8 tokenDecimals = IERC20Metadata(token).decimals();

        uint256 normalizedTokenAmount = s_nftPriceInUsd / (10 ** (18 - tokenDecimals));

        IERC20(token).safeTransferFrom(msg.sender, address(this), normalizedTokenAmount);

        _mintNft(s_nftPriceInUsd);
    }

    function addUserToWhitelist(address user) external onlyOwner notAddressZero(user) {
        s_whitelistedUsers[user] = true;

        emit UserAddedToWhitelist(user);
    }

    function removeUserFromWhitelist(address user) external onlyOwner notAddressZero(user) {
        s_whitelistedUsers[user] = false;

        emit UserRemovedFromWhitelist(user);
    }

    function changeNftPrice(uint256 newPriceInUsd) external onlyOwner {
        s_nftPriceInUsd = newPriceInUsd;

        emit NftPriceChanged(newPriceInUsd);
    }

    function addStablecoinToSupportedTokens(address token) external onlyOwner {
        s_supportedStableTokens[token] = true;

        emit TokenAddedToSupportedTokens(token);
    }

    function removeStablecoinFromSupportedTokens(address token) external onlyOwner {
        s_supportedStableTokens[token] = false;

        emit TokenRemovedFromSupportedTokens(token);
    }

    function setTokenUri(string memory newTokenUri) external onlyOwner {
        s_tokenURI = newTokenUri;

        emit NftUriChanged(newTokenUri);
    }

    function setPriceFeedStalenessDuration(uint256 newStalenessDuration) external onlyOwner {
        s_priceFeedStalenessThreshold = newStalenessDuration;

        emit PriceFeedStalenessDurationChanged(newStalenessDuration);
    }

    function _mintNft(uint256 depositAmountInUSD) internal nonReentrant {
        if (depositAmountInUSD < s_nftPriceInUsd) {
            revert RaptorNFT__NotEnoughFunds();
        }

        _safeMint(msg.sender, s_tokenIdCounter);

        emit NftMinted(msg.sender, s_tokenIdCounter);

        s_tokenIdCounter++;
    }

    function tokenURI(uint256) public view override returns (string memory) {
        return s_tokenURI;
    }

    function getPriceFeedStalenessDuration() public view returns (uint256) {
        return s_priceFeedStalenessThreshold;
    }
}
