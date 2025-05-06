//SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {RaptorBaseTest} from "../../base/RaptorBaseTest.sol";

contract RaptorNFTFuzz is RaptorBaseTest {
    function setUp() public override {
        super.setUp();
    }

    function testFuzzRefundsCorrectEthWhenOverpaid(uint256 overpayment) public {
        _whitelistUser(BOB);

        uint256 nftPriceUsd = nft.s_nftPriceInUsd();
        uint256 ethPriceUsd = 2000e18;
        uint256 requiredEth = nftPriceUsd * 1e18 / ethPriceUsd;

        overpayment = bound(overpayment, requiredEth + 1, BOB.balance);

        uint256 balanceBefore = BOB.balance;

        vm.prank(BOB);
        nft.mintNftWithETH{value: overpayment}();

        uint256 balanceAfter = BOB.balance;

        uint256 expectedRefund = overpayment - requiredEth;
        uint256 actualRefund = balanceAfter - (balanceBefore - overpayment);

        assertEq(nft.balanceOf(BOB), 1, "NFT was not minted");
        assertEq(actualRefund, expectedRefund, "Refund amount incorrect");
    }
}
