//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {RaptorNFTBaseTest} from "./RaptorNFTBaseTest.t.sol";
import {RaptorNFT} from "../../../src/RaptorNFT.sol";

contract RaptorNFTTest is RaptorNFTBaseTest {
  

    function setUp() public override {
      super.setUp();
    }

    function testNameAndSymbolAreCorrertlyInitialized() public view {
        assertEq(keccak256(abi.encodePacked(nft.name())), keccak256(abi.encodePacked((NFT_NAME))));
        assertEq(keccak256(abi.encodePacked(nft.symbol())), keccak256(abi.encodePacked((NFT_SYMBOL))));
    }

    function testUriIsCorrect() public view {
        assertEq(nft.tokenURI(1), NFT_URI);
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
        nft.mintNftWithStable(address(usdc), depositAmount);

        vm.stopPrank();

        assertEq(nft.balanceOf(BOB), 1, "NFT Mint Failed");

        uint256 expectedStableBalance = INITIAL_USER_STABLE_BALANCE - depositAmount;
        assertEq(usdc.balanceOf(BOB), expectedStableBalance);
    }

    function testMintWithStableRevertsWhenDepositAmountIsNotEnough() public {
        _whitelistUser(BOB);
        _whitelistToken(address(usdc));

        uint256 depositAmount = 1;

        vm.startPrank(BOB);

        usdc.approve(address(nft), depositAmount);

        vm.expectRevert(RaptorNFT.RaptorNFT__NotEnoughFunds.selector);
        nft.mintNftWithStable(address(usdc), depositAmount);

        vm.stopPrank();
    }

    function testMintWithStableRevertsWhenUserNotWhitelisted() public {
        uint256 depositAmount = INITIAL_NFT_PRICE / 1e12;

        vm.startPrank(BOB);

        usdc.approve(address(nft), depositAmount);

        vm.expectRevert(RaptorNFT.RaptorNFT__NotWhitelisted.selector);
        nft.mintNftWithStable(address(usdc), depositAmount);

        vm.stopPrank();
    }

    function testMintWithStableRevertsWhenTokenIsNotSupported() public {
        _whitelistUser(BOB);

        uint256 depositAmount = INITIAL_NFT_PRICE / 1e12;

        vm.startPrank(BOB);

        usdc.approve(address(nft), depositAmount);

        vm.expectRevert(RaptorNFT.RaptorNFT__TokenNotSupported.selector);
        nft.mintNftWithStable(address(usdc), depositAmount);

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

    function _whitelistUser(address user) internal {
        vm.prank(OWNER);
        nft.addUserToWhitelist(user);
    }

    function _whitelistToken(address token) internal {
        vm.prank(OWNER);
        nft.addStablecoinToSupportedTokens(token);
    }
}
