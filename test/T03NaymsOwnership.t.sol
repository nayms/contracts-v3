// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { D03ProtocolDefaults, console2, LibConstants, LibHelpers } from "./defaults/D03ProtocolDefaults.sol";

import { MockAccounts } from "./utils/users/MockAccounts.sol";

import { INayms } from "src/diamonds/nayms/INayms.sol";
import { Entity } from "src/diamonds/nayms/AppStorage.sol";

contract T03NaymsOwnershipTest is D03ProtocolDefaults, MockAccounts {
    function setUp() public virtual override {
        super.setUp();
    }

    function testTransferOwernshipFailsIfNotSysAdmin() public {
        vm.prank(signer2);
        vm.expectRevert("not a system admin");
        nayms.transferOwnership(signer1);
    }

    function testTransferOwernship() public {
        nayms.assignRole(signer1Id, systemContext, LibConstants.ROLE_SYSTEM_ADMIN);

        vm.prank(signer1);
        nayms.transferOwnership(signer2);
        vm.stopPrank();

        assertTrue(nayms.owner() == signer2);
        assertFalse(nayms.isInGroup(signer2Id, systemContext, LibConstants.GROUP_SYSTEM_ADMINS));
    }
}
