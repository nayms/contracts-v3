// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { D01Deployment, console2, LibHelpers, LibConstants, LibAdmin, LibObject } from "./D01Deployment.sol";

import { ERC20 } from "src/erc20/ERC20.sol";

/// @notice Default test setup part 02
///         Setup test ERC20 tokens

contract D02TestSetup is D01Deployment {
    //// test tokens ////
    ERC20 public weth;
    ERC20 public wbtc;

    function setUp() public virtual override {
        super.setUp();
        weth = new ERC20("Wrapped ETH", "WETH", 18);
        wbtc = new ERC20("Wrapped BTC", "WBTC", 18);
        vm.label(address(weth), "WETH");
        vm.label(address(wbtc), "WBTC");
    }
}
