// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// solhint-disable-next-line no-global-import
import "./D01Deployment.sol";

import { MockERC20 } from "solmate/test/utils/mocks/MockERC20.sol";

/// @notice Default test setup part 02

contract D02TestSetup is D01Deployment {
    function setUp() public virtual override {
        super.setUp();
    }
}
