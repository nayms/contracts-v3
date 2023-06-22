// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { Vm } from "forge-std/Vm.sol";

import { D03ProtocolDefaults, LibAdmin, LibConstants } from "./defaults/D03ProtocolDefaults.sol";
import { INayms, IDiamondCut } from "src/diamonds/nayms/INayms.sol";

/// @notice Contains tests for Nayms ERC20 token

contract TNaymsToken is D03ProtocolDefaults {
    function setUp() public virtual override {
        super.setUp();
    }

    function testNaymsTotalSupply() public {
        assertEq(nayms.totalSupply(), 100_000_000e18, "total supply should be 100_000_000");
    }

    function testNaymsBalanceOf() public {
        assertEq(nayms.balanceOf(account0), 100_000_000e18, "account0 should have 100_000_000");
    }
}
