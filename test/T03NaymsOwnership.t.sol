// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { D03ProtocolDefaults, console2, LibConstants, LibHelpers, initEntity } from "./defaults/D03ProtocolDefaults.sol";

import { MockAccounts } from "./utils/users/MockAccounts.sol";

import { INayms } from "src/diamonds/nayms/INayms.sol";
import { Entity } from "src/diamonds/nayms/AppStorage.sol";

contract T03NaymsOwnershipTest is D03ProtocolDefaults, MockAccounts {
    function setUp() public virtual override {
        super.setUp();
    }

    function testTransferOwernshipFailsIfNotContractOwner() public {
        vm.prank(signer1);
        vm.expectRevert("LibDiamond: Must be contract owner");
        nayms.transferOwnership(signer1);
    }

    function testTransferOwernship() public {
        nayms.transferOwnership(signer1);

        assertTrue(nayms.isInGroup(signer1Id, systemContext, LibConstants.GROUP_SYSTEM_ADMINS));
        assertFalse(nayms.isInGroup(account0Id, systemContext, LibConstants.GROUP_SYSTEM_ADMINS));
    }
}
