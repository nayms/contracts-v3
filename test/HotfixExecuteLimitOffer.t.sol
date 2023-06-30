// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { Test } from "forge-std/Test.sol";
import { INayms } from "src/diamonds/nayms/INayms.sol";
import { MarketFacet } from "src/diamonds/nayms/facets/MarketFacet.sol";
import { LibHelpers } from "src/diamonds/nayms/libs/LibHelpers.sol";

contract HotfixExecuteLimitOfferTest is Test {
    using LibHelpers for *;
    INayms private nayms;
    MarketFacet private marketFacet;
    bytes32 immutable USDC = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48)._getIdForAddress();

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("mainnet"), 17584124);

        nayms = INayms(address(0x39e2f550fef9ee15b459d16bD4B243b04b1f60e5));

        marketFacet = new MarketFacet();

        vm.etch(0x3b785e273dfD70E62f407B492c5E00301Ff1b195, type(MarketFacet).runtimeCode);
    }

    function testHotfixExecuteLimitOffer() public {
        address buyer = 0x87E8c99925aD368b3caD1678205660b83599A145;
        bytes32 buyerId = buyer._getIdForAddress();
        nayms.internalBalanceOf(buyerId, USDC);
        uint256 sellAmount = 249500000000;
        bytes32 _buyToken = 0xab023d09eb3f2cd821b38c355c45b7aaae24711ac087da3c8c45b7e77190577b;
        uint256 buyAmount = 249000000000000000000000;
        vm.prank(buyer);
        nayms.executeLimitOffer(USDC, sellAmount, _buyToken, buyAmount);
    }
}
