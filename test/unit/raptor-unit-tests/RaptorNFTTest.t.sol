//SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {BaseTest} from "../BaseTest.sol";
import {RaptorNFT} from "../../../src/RaptorNFT.sol";

contract RaptorNFTTest is BaseTest {

    string constant NFT_NAME = "Raptor";
    string constant NFT_SYMBOL = "RR";
    uint256 public constant INITIAL_USER_BALANCE = 10 ether;
    uint256 public constant INITIAL_USER_STABLE_BALANCE = 1000e6;

    address BOB = makeAddr("bob");


    function setUp() public override {
        super.setUp();

        vm.deal(BOB, INITIAL_USER_BALANCE);
        usdc.mint(BOB, INITIAL_USER_STABLE_BALANCE);
    }

    function testNameAndSymbolAreCorrertlyInitialized() public view {
        assertEq(keccak256(abi.encodePacked(nft.name())), keccak256(abi.encodePacked((NFT_NAME))));
        assertEq(keccak256(abi.encodePacked(nft.symbol())), keccak256(abi.encodePacked((NFT_SYMBOL))));
    }

    function testUriIsCorrect() public view {
        assertEq(nft.tokenURI(1), INITIAL_NFT_URI);
    }

    function testMintWithEthMintsNftToUserAndTakesCorrectAmountOfEth() public {
        _whitelistUser(BOB);

        uint256 depositAmount = 25e15; // $50 / $2000 = 0.025 ETH

        vm.startPrank(BOB);

        nft.mintNftWithETH{value: depositAmount}();

        vm.stopPrank();

        assertEq(nft.balanceOf(BOB), 1, "NFT Mint Failed");
        assertEq(BOB.balance, INITIAL_USER_BALANCE - depositAmount);
    }

    function testMintWithEthRefundsCorrectAmountToUser() public {
        _whitelistUser(BOB);

        uint256 depositAmount = 5e16; // $100 / $2000 = 0.05 ETH

        vm.startPrank(BOB);

        //We will deposit twice as much so we have to get half of our deposit refunded
        nft.mintNftWithETH{value: depositAmount}();

        vm.stopPrank();

        assertEq(nft.balanceOf(BOB), 1, "NFT Mint Failed");
        assertEq(BOB.balance, INITIAL_USER_BALANCE - (depositAmount / 2), "Refund Amount is wrong");
    }

    function testMintWithEthTakesCorrectAmountAfterNftPriceIsChanged() public {
        _whitelistUser(BOB);

        vm.prank(OWNER);
        nft.changeNftPrice(INITIAL_NFT_PRICE * 2);

        vm.startPrank(BOB);

        uint256 depositAmount = 5e16; // $100 / $2000 = 0.05 ETH

        nft.mintNftWithETH{value: depositAmount}();

        vm.stopPrank();

        assertEq(nft.balanceOf(BOB), 1, "NFT Mint Failed");
        assertEq(BOB.balance, INITIAL_USER_BALANCE - depositAmount, "Incorrect amount deposited");
    }

    function testMintWithEthRevertsWhenDepositAmountIsNotEnough() public {
        _whitelistUser(BOB);

        vm.startPrank(BOB);

        vm.expectRevert(RaptorNFT.RaptorNFT__NotEnoughFunds.selector);
        nft.mintNftWithETH{value: 1}();

        vm.stopPrank();
    }

    function testMintRevertIfUserNotWhitelisted() public {
        vm.prank(BOB);
        vm.expectRevert(RaptorNFT.RaptorNFT__NotWhitelisted.selector);
        nft.mintNftWithETH{value: 1 ether}();
    }

    function testMintWithStableMintsCorrectAmountToUser() public {
        _whitelistUser(BOB);
        _whitelistToken(address(usdc));

        uint256 depositAmount = INITIAL_NFT_PRICE / 1e12;

        vm.startPrank(BOB);

        usdc.approve(address(nft), depositAmount);
        nft.mintNftWithStable(address(usdc));

        vm.stopPrank();

        assertEq(nft.balanceOf(BOB), 1, "NFT Mint Failed");

        uint256 expectedStableBalance = INITIAL_USER_STABLE_BALANCE - depositAmount;
        assertEq(usdc.balanceOf(BOB), expectedStableBalance);
    }

    function testMintWithStableRevertsWhenUserNotWhitelisted() public {
        uint256 depositAmount = INITIAL_NFT_PRICE / 1e12;

        vm.startPrank(BOB);

        usdc.approve(address(nft), depositAmount);

        vm.expectRevert(RaptorNFT.RaptorNFT__NotWhitelisted.selector);
        nft.mintNftWithStable(address(usdc));

        vm.stopPrank();
    }

    function testMintWithStableRevertsWhenTokenIsNotSupported() public {
        _whitelistUser(BOB);

        uint256 depositAmount = INITIAL_NFT_PRICE / 1e12;

        vm.startPrank(BOB);

        usdc.approve(address(nft), depositAmount);

        vm.expectRevert(RaptorNFT.RaptorNFT__TokenNotSupported.selector);
        nft.mintNftWithStable(address(usdc));

        vm.stopPrank();
    }

    function testOwnerCanRemoveAndAddUsersToWhitelist() public {
        vm.startPrank(OWNER);
        nft.addUserToWhitelist(BOB);

        assertEq(nft.s_whitelistedUsers(BOB), true);

        nft.removeUserFromWhitelist(BOB);

        assertEq(nft.s_whitelistedUsers(BOB), false);

        vm.stopPrank();
    }

    function testOnlyOwnerCanRemoveAndAddUsersToWhitelist() public {
        vm.startPrank(BOB);

        vm.expectRevert();
        nft.addUserToWhitelist(BOB);

        vm.stopPrank();
    }

    function testOwnerCantAddAddressZeroToWhitelist() public {
        vm.startPrank(OWNER);
        vm.expectRevert(RaptorNFT.RaptorNFT__AddressZero.selector);
        nft.addUserToWhitelist(address(0));
    }

    function testOwnerCanAddAndRemoveStableTokens() public {
        vm.startPrank(OWNER);

        nft.addStablecoinToSupportedTokens(address(usdc));

        assertEq(nft.s_supportedStableTokens(address(usdc)), true);

        nft.removeStablecoinFromSupportedTokens(address(usdc));

        assertEq(nft.s_supportedStableTokens(address(usdc)), false);

        vm.stopPrank();
    }

    function testOnlyOwnerCanRemoveAndAddSupportedTokens() public {
        vm.prank(BOB);
        vm.expectRevert();
        nft.addStablecoinToSupportedTokens(address(usdc));
    }

    function testOwnerCanChangePriceOfNFT() public {
        uint256 newNftPrice = 100e18;

        vm.prank(OWNER);
        nft.changeNftPrice(newNftPrice);

        assertEq(nft.s_nftPriceInUsd(), newNftPrice);
    }

    function testOnlyOwnerCanChangePriceOfNFT() public {
        vm.prank(BOB);
        vm.expectRevert();
        nft.changeNftPrice(1e18);
    }

    function testOwnerCanChangeNftURI() public {
        vm.startPrank(OWNER);

        string memory newUri = "ipfs://bafybeibc5sgo2plmjkq2tzmhrn54bk3crhnc23zd2msg4ea7a4pxrkgfna";

        nft.setTokenUri(newUri);

        vm.stopPrank();

        assertEq(nft.tokenURI(0), newUri);
    }

    function testOwnerCanChangePriceFeedStalenessDuration() public {
        vm.startPrank(OWNER);

        uint256 newStalenessDuration = 1 hours;

        nft.setPriceFeedStalenessDuration(newStalenessDuration);

        vm.stopPrank();

        assertEq(nft.getPriceFeedStalenessDuration(), newStalenessDuration);
    }

    function testOnlyAuctionCanCallMintNftToAuctionWinner() public {

        vm.prank(BOB);
        vm.expectRevert(RaptorNFT.RaptorNFT__Unauthorized.selector);
        nft.mintNftToAuctionWinner(BOB);
    }

    function _whitelistUser(address user) internal {
        vm.prank(OWNER);
        nft.addUserToWhitelist(user);
    }

    function _whitelistToken(address token) internal {
        vm.prank(OWNER);
        nft.addStablecoinToSupportedTokens(token);
    }

}
