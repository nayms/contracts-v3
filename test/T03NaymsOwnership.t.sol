// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import { D03ProtocolDefaults, LibHelpers, LC } from "./defaults/D03ProtocolDefaults.sol";
import "src/shared/CustomErrors.sol";

import { MockAccounts } from "./utils/users/MockAccounts.sol";

contract T03NaymsOwnershipTest is D03ProtocolDefaults, MockAccounts {
    using LibHelpers for *;

    function setUp() public {}

    function testTransferOwnershipFailsIfNotSysAdmin() public {
        changePrank(signer2);
        vm.expectRevert(abi.encodeWithSelector(InvalidGroupPrivilege.selector, signer2Id, systemContext, "", LC.GROUP_SYSTEM_ADMINS));
        nayms.transferOwnership(signer1);
    }

    function testTransferOwernshipFailsIfNewOwnerIsSysAdmin() public {
        nayms.assignRole(signer1Id, systemContext, LC.ROLE_SYSTEM_ADMIN);

        changePrank(signer1);
        vm.expectRevert("NEW owner MUST NOT be sys admin");
        nayms.transferOwnership(signer1);
    }

    function testTransferOwernshipFailsIfNewOwnerIsSysManager() public {
        nayms.assignRole(signer1Id, systemContext, LC.ROLE_SYSTEM_ADMIN);
        nayms.assignRole(signer2Id, systemContext, LC.ROLE_SYSTEM_MANAGER);

        changePrank(signer1);
        vm.expectRevert("NEW owner MUST NOT be sys manager");
        nayms.transferOwnership(signer2);
    }

    function testTransferOwernship() public {
        nayms.assignRole(signer1Id, systemContext, LC.ROLE_SYSTEM_ADMIN);

        changePrank(signer1);
        nayms.transferOwnership(signer2);
        vm.stopPrank();

        assertTrue(nayms.owner() == signer2);
        assertFalse(nayms.isInGroup(signer2Id, systemContext, LC.GROUP_SYSTEM_ADMINS));
    }

    function testFuzz_TransferOwnership(address newOwner, address notSysAdmin, address anotherSysAdmin) public {
        vm.assume(newOwner != anotherSysAdmin && newOwner != account0);
        vm.assume(anotherSysAdmin != address(0));

        bytes32 notSysAdminId = LibHelpers._getIdForAddress(address(notSysAdmin));
        // note: for this test, assume that the notSysAdmin address is not a system admin
        vm.assume(!nayms.isInGroup(notSysAdminId, systemContext, LC.GROUP_SYSTEM_ADMINS));

        vm.label(newOwner, "newOwner");
        vm.label(notSysAdmin, "notSysAdmin");
        vm.label(anotherSysAdmin, "anotherSysAdmin");

        // 1. Diamond is deployed, owner is set to msg.sender
        // 2. Diamond cuts in facets and initializes state, a sys admin is set to msg.sender who must be the owner since diamondCut() can only be called by the owner

        // Only a system admin can transfer diamond ownership
        changePrank(notSysAdmin);
        vm.expectRevert(abi.encodeWithSelector(InvalidGroupPrivilege.selector, notSysAdmin._getIdForAddress(), systemContext, "", LC.GROUP_SYSTEM_ADMINS));
        nayms.transferOwnership(newOwner);

        // Only a system admin can transfer diamond ownership, the new owner isn't a system admin
        changePrank(newOwner);
        vm.expectRevert(abi.encodeWithSelector(InvalidGroupPrivilege.selector, newOwner._getIdForAddress(), systemContext, "", LC.GROUP_SYSTEM_ADMINS));
        nayms.transferOwnership(newOwner);

        // System admin can transfer diamond ownership
        changePrank(systemAdmin);
        nayms.transferOwnership(newOwner);
        assertTrue(nayms.owner() == newOwner);

        bytes32 anotherSysAdminId = LibHelpers._getIdForAddress(address(anotherSysAdmin));
        nayms.assignRole(anotherSysAdminId, systemContext, LC.ROLE_SYSTEM_ADMIN);

        changePrank(anotherSysAdmin);
        nayms.transferOwnership(nayms.owner());
    }
}
