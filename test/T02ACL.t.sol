// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { D03ProtocolDefaults, console2, LibAdmin, LibConstants, LibHelpers } from "./defaults/D03ProtocolDefaults.sol";

/// @dev Testing for Nayms RBAC - Access Control List (ACL)

contract T02ACLTest is D03ProtocolDefaults {
    function setUp() public virtual override {
        super.setUp();
    }

    // the deployer should be in the system admin group at initialization
    function testDeployerIsInGroup() public {
        assertTrue(nayms.isInGroup(account0Id, systemContext, LibConstants.GROUP_SYSTEM_ADMINS));
    }

    // the deployer, as a system admin, should be able to assign roles that system admins can assign
    function testDeployerAssignRoleToThemself() public {
        string memory role = LibConstants.ROLE_ENTITY_ADMIN;

        // assign the role entity admin to deployer / account0 within the system context
        nayms.assignRole(account0Id, systemContext, role);

        // the group that the deployer / account0 within the system context is in is now the entity admins group
        assertTrue(nayms.isInGroup(account0Id, systemContext, LibConstants.GROUP_ENTITY_ADMINS));
    }

    function testDeployerAssignRoleToAnotherObject() public {
        string memory role = LibConstants.ROLE_ENTITY_ADMIN;

        // assign the role entity admin to deployer / account0
        nayms.assignRole(signer1Id, systemContext, role);

        // the group that the deployer / account0 is in is now the entity admins group
        assertTrue(nayms.isInGroup(signer1Id, systemContext, LibConstants.GROUP_ENTITY_ADMINS));
    }

    function testInvalidObjectIdWhenAssignRole() public {
        bytes32 invalidObjectId = bytes32(0);
        string memory role = LibConstants.ROLE_ENTITY_ADMIN;
        vm.expectRevert("invalid object ID");
        nayms.assignRole(invalidObjectId, systemContext, role);
    }

    // todo what if we try to assign an object Id that's one of the role Ids?

    // function testFuzzAssignRole(
    //     bytes32 objectId,
    //     bytes32 contextId,
    //     string memory role
    // ) public {
    //     // this is checked in testInvalidObjectIdWhenAssignRole()
    //     vm.assume(objectId != bytes32(0));

    //     // vm.assume();
    //     vm.assume(nayms.isInGroup(objectId, contextId, role));
    //     nayms.assignRole(objectId, contextId, role);
    // }

    // currently, the system admin can unassign their role even if there are no other system admins assigned.
    // todo: is that desired behavior?
    function testDeployerUnassignRoleOnThemself() public {
        // role is already assigned to the deployer at initialization
        // unassign role
        nayms.unassignRole(account0Id, systemContext);

        assertFalse(nayms.isInGroup(account0Id, systemContext, LibConstants.GROUP_SYSTEM_ADMINS));
    }

    function testDeployerUnassignRoleOnAnotherObject() public {
        // 1. assign role on another object
        testDeployerAssignRoleToAnotherObject();

        // 2. unassign role
        nayms.unassignRole(signer1Id, systemContext);

        assertFalse(nayms.isInGroup(signer1Id, systemContext, LibConstants.GROUP_ENTITY_ADMINS));
    }

    // function testFuzzUnassignRole(
    //     bytes32 objectId,
    //     bytes32 objectId2,
    //     bytes32 contextId,
    //     string memory role
    // ) public {
    //     // this is checked in testInvalidObjectIdWhenAssignRole()
    //     vm.assume(objectId != bytes32(0));

    //     // 1. assign role
    //     nayms.assignRole(objectId, contextId, role);

    //     // 2. unassign role
    //     nayms.unassignRole(objectId, contextId);
    // }
}
