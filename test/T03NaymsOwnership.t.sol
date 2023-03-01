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

    function testTransferOwernshipFailsIfNewOwnerIsSysAdmin() public {
        nayms.assignRole(signer1Id, systemContext, LibConstants.ROLE_SYSTEM_ADMIN);

        vm.prank(signer1);
        vm.expectRevert("NEW owner MUST NOT be sys admin");
        nayms.transferOwnership(signer1);
    }

    function testTransferOwernshipFailsIfNewOwnerIsSysManager() public {
        nayms.assignRole(signer1Id, systemContext, LibConstants.ROLE_SYSTEM_ADMIN);
        nayms.assignRole(signer2Id, systemContext, LibConstants.ROLE_SYSTEM_MANAGER);

        vm.prank(signer1);
        vm.expectRevert("NEW owner MUST NOT be sys manager");
        nayms.transferOwnership(signer2);
    }

    function testTransferOwernship() public {
        nayms.assignRole(signer1Id, systemContext, LibConstants.ROLE_SYSTEM_ADMIN);

        vm.prank(signer1);
        nayms.transferOwnership(signer2);
        vm.stopPrank();

        assertTrue(nayms.owner() == signer2);
        assertFalse(nayms.isInGroup(signer2Id, systemContext, LibConstants.GROUP_SYSTEM_ADMINS));
    }

    // solhint-disable func-name-mixedcase
    function testFuzz_TransferOwnership(
        address newOwner,
        address notSysAdmin,
        address anotherSysAdmin
    ) public {
        vm.assume(newOwner != anotherSysAdmin);
        vm.assume(anotherSysAdmin != address(0));

        bytes32 notSysAdminId = LibHelpers._getIdForAddress(address(notSysAdmin));
        assertFalse(nayms.isInGroup(notSysAdminId, systemContext, LibConstants.GROUP_SYSTEM_ADMINS));
        // 1. Diamond is deployed, owner is set to msg.sender
        // 2. Diamond cuts in facets and initializes state, a sys admin is set to msg.sender who must be the owner since diamondCut() can only be called by the owner

        // Only a system admin can transfer diamond ownership
        vm.prank(notSysAdmin);
        vm.expectRevert("not a system admin");
        nayms.transferOwnership(newOwner);

        // Only a system admin can transfer diamond ownership, the new owner isn't a system admin
        vm.prank(newOwner);
        vm.expectRevert("not a system admin");
        nayms.transferOwnership(newOwner);

        // System admin can transfer diamond ownership
        nayms.transferOwnership(newOwner);
        assertTrue(nayms.owner() == newOwner);

        bytes32 anotherSysAdminId = LibHelpers._getIdForAddress(address(anotherSysAdmin));
        nayms.assignRole(anotherSysAdminId, systemContext, LibConstants.ROLE_SYSTEM_ADMIN);

        vm.prank(anotherSysAdmin);
        nayms.transferOwnership(nayms.owner());
    }
}
