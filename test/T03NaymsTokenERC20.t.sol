// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { D03ProtocolDefaults, console2, LibConstants, LibHelpers } from "./defaults/D03ProtocolDefaults.sol";

contract T03NaymsTokenERC20 is D03ProtocolDefaults {
    function setUp() public virtual override {
        super.setUp();
    }

    function testNaymsErc20InvariantMetadata() public {
        assertEq(nayms.name(), "Nayms Token");
        assertEq(nayms.symbol(), "NAYM");
        // todo
        // assertEq(nayms.decimals(), uint8(18));
    }
}
