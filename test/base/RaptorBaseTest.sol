//SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {BaseTest} from "../base/BaseTest.sol";

contract RaptorBaseTest is BaseTest {

  uint256 public constant INITIAL_USER_BALANCE = 10 ether;
  uint256 public constant INITIAL_USER_STABLE_BALANCE = 1000e6;

  address BOB = makeAddr("bob");

  function setUp() public virtual override {
    super.setUp();

    vm.deal(BOB, INITIAL_USER_BALANCE);
    usdc.mint(BOB, INITIAL_USER_STABLE_BALANCE);
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