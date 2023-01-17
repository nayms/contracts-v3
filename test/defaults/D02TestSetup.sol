// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { D01Deployment, console2, LibHelpers, LibConstants, LibAdmin, LibObject, LibSimplePolicy } from "./D01Deployment.sol";

import { MockERC20 } from "solmate/test/utils/mocks/MockERC20.sol";

/// @notice Default test setup part 02
///         Setup test ERC20 tokens

contract D02TestSetup is D01Deployment {
    //// test tokens ////
    MockERC20 public weth;
    address public wethAddress;
    bytes32 public wethId;

    MockERC20 public wbtc;
    address public wbtcAddress;
    bytes32 public wbtcId;

    function setUp() public virtual override {
        super.setUp();

        weth = new MockERC20("Wrapped ETH", "WETH", 18);
        wethAddress = address(weth);
        wethId = LibHelpers._getIdForAddress(wethAddress);

        wbtc = new MockERC20("Wrapped BTC", "WBTC", 18);
        wbtcAddress = address(wbtc);
        wbtcId = LibHelpers._getIdForAddress(wbtcAddress);

        vm.label(wethAddress, "WETH");
        vm.label(wbtcAddress, "WBTC");
    }
}
