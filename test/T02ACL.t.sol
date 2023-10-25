// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;
import { console2 } from "forge-std/console2.sol";
import { D03ProtocolDefaults, LibHelpers, LC } from "./defaults/D03ProtocolDefaults.sol";
import { MockAccounts } from "test/utils/users/MockAccounts.sol";
import { Vm } from "forge-std/Vm.sol";
import { Entity } from "../src/diamonds/nayms/AppStorage.sol";
import "src/diamonds/nayms/interfaces/CustomErrors.sol";
import { DSILib } from "test/utils/DSILib.sol";

/// @dev Testing for Nayms RBAC - Access Control List (ACL)

contract T02ACLTest is D03ProtocolDefaults, MockAccounts {
    using DSILib for address;
    using LibHelpers for *;

    function setUp() public {}

    /// deployer, owner, address(this), account0 are all the same address. This address should not be able to have the system admin role
    /// systemAdmin is another address

    // the deployer should NOT be a system admin
    function testDeployerIsNotASystemAdmin() public {
        assertFalse(nayms.isInGroup(account0Id, systemContext, LC.GROUP_SYSTEM_ADMINS));
    }

    function testUnassignLastSystemAdminFails() public {
        // Manually set number of system admins to 1
        naymsAddress.write_sysAdmins(1);

        vm.expectRevert("must have at least one system admin");
        nayms.unassignRole(systemAdminId, systemContext);
    }

    function testReassignLastSystemAdminFails() public {
        // Manually set number of system admins to 1
        naymsAddress.write_sysAdmins(1);

        vm.expectRevert("must have at least one system admin");
        nayms.assignRole(systemAdminId, systemContext, LC.ROLE_SYSTEM_MANAGER);
    }

    function testUnassignSystemAdmin() public {
        nayms.assignRole(signer1Id, systemContext, LC.ROLE_SYSTEM_ADMIN);

        changePrank(signer1);
        nayms.unassignRole(systemAdminId, systemContext);
    }

    /// test_canAssign_SystemAdminCanAssignAnyRoleToAnotherObjectInSystemContext
    function testDeployerAssignRoleToAnotherObject() public {
        string memory role = LC.ROLE_ENTITY_ADMIN;

        // assign the role entity admin to deployer / account0
        assertTrue(nayms.canAssign(systemAdminId, signer1Id, systemContext, role));
        nayms.assignRole(signer1Id, systemContext, role);

        // the group that the deployer / account0 is in is now the entity admins group
        assertTrue(nayms.isInGroup(signer1Id, systemContext, LC.GROUP_ENTITY_ADMINS));
    }

    /// test_canAssign_SystemAdminCanAssignAnyRoleToAnotherObjectInAnyContext
    function testSystemAdminAssignAnyRoleToAnotherObjectInNewContext() public {
        string memory role = LC.ROLE_SYSTEM_MANAGER;
        bytes32 context = LibHelpers._stringToBytes32("test");

        // assign the role signer1
        assertTrue(nayms.canAssign(systemAdminId, signer1Id, context, role));
        nayms.assignRole(signer1Id, context, role);

        // the group that the signer1 is in is now the approved users group
        assertTrue(nayms.isInGroup(signer1Id, context, LC.GROUP_SYSTEM_MANAGERS));
    }

    function testDeployerUnassignRoleOnAnotherObject() public {
        // 1. assign role on another object
        testDeployerAssignRoleToAnotherObject();

        // 2. unassign role
        nayms.unassignRole(signer1Id, systemContext);

        assertFalse(nayms.isInGroup(signer1Id, systemContext, LC.GROUP_ENTITY_ADMINS));
    }

    function testRoleAssignmentEmitsAnEvent() public {
        bytes32 context = LibHelpers._stringToBytes32("test");
        string memory role = LC.ROLE_ENTITY_ADMIN;

        vm.recordLogs();

        nayms.assignRole(signer1Id, context, role);

        Vm.Log[] memory entries = vm.getRecordedLogs();

        assertEq(entries[0].topics.length, 2);
        assertEq(entries[0].topics[0], keccak256("RoleUpdated(bytes32,bytes32,bytes32,string)"));
        assertEq(entries[0].topics[1], signer1Id);
        (bytes32 contextId, bytes32 roleId, string memory action) = abi.decode(entries[0].data, (bytes32, bytes32, string));
        assertEq(contextId, context);
        assertEq(roleId, bytes32(0));
        assertEq(action, "_unassignRole");

        assertEq(entries[1].topics.length, 2);
        assertEq(entries[1].topics[0], keccak256("RoleUpdated(bytes32,bytes32,bytes32,string)"));
        assertEq(entries[1].topics[1], signer1Id);
        (contextId, roleId, action) = abi.decode(entries[1].data, (bytes32, bytes32, string));
        assertEq(contextId, context);
        assertEq(roleId, LibHelpers._stringToBytes32(role));
        assertEq(action, "_assignRole");
    }

    function testInvalidObjectIdWhenAssignRole() public {
        bytes32 invalidObjectId = bytes32(0);
        string memory role = LC.ROLE_ENTITY_ADMIN;
        vm.expectRevert("invalid object ID");
        nayms.assignRole(invalidObjectId, systemContext, role);
    }

    function testAssignInvalidGroupPrivilege() public {
        // assign a role to signer1
        vm.expectRevert("not in assigners group");
        nayms.assignRole(signer1Id, systemContext, "random role");
    }

    function testNonAssignersCannotAssignRole() public {
        string memory role = LC.ROLE_ENTITY_ADMIN;
        bytes32 context = LibHelpers._stringToBytes32("test");

        // assign a role to signer1
        nayms.assignRole(signer1Id, context, role);

        // signer1 tries to assign to signer2
        assertFalse(nayms.canAssign(signer1Id, signer2Id, context, role), "signer1 CAN assign role to signer2 when they SHOULDN'T be able to.");
        changePrank(signer1);
        vm.expectRevert("not in assigners group");
        nayms.assignRole(signer2Id, context, role);
    }

    /// note: the behavior of assignRole has been updated such that a non assigner (user) can no longer assign a role if their parent has an assigner role in the system context
    function testNonAssignersCannotAssignRoleIfTheirParentHasAssignerRoleInSystemContext() public {
        string memory role = LC.ROLE_ENTITY_ADMIN;
        bytes32 context = LibHelpers._stringToBytes32("test");

        changePrank(sm.addr);
        // create entity with signer2 as child
        bytes32 entityId1 = createTestEntity(signer2Id);

        changePrank(sa.addr);
        // assign entity as system manager
        nayms.assignRole(entityId1, systemContext, LC.ROLE_SYSTEM_ADMIN);

        // signer2 tries to assign to signer3
        assertFalse(nayms.canAssign(signer2Id, signer3Id, context, role));
        changePrank(signer2);
        vm.expectRevert("not in assigners group");
        nayms.assignRole(signer3Id, context, role);
    }

    function testAssignersCanAssignRole() public {
        string memory role = LC.ROLE_SYSTEM_MANAGER;
        bytes32 context = LibHelpers._stringToBytes32("test");

        // give signer3 assigner powers
        // nayms.assignRole(signer3Id, context, LC.ROLE_SYSTEM_ADMIN);
        nayms.assignRole(signer3Id, context, LC.ROLE_SYSTEM_MANAGER);

        // signer3 makes signer2 an approved user
        assertFalse(nayms.canAssign(signer3Id, signer2Id, context, role));
        assertTrue(nayms.canAssign(signer3Id, signer2Id, context, LC.ROLE_ENTITY_BROKER));
        changePrank(signer3);
        // nayms.assignRole(signer2Id, context, role);
        nayms.assignRole(signer2Id, context, LC.ROLE_ENTITY_BROKER);

        changePrank(systemAdmin);
        assertFalse(nayms.isInGroup(signer2Id, context, LC.GROUP_SYSTEM_MANAGERS));
        assertTrue(nayms.isInGroup(signer2Id, context, LC.GROUP_PAY_SIMPLE_PREMIUM));
    }

    function testNonAssignersCannotUnassignRole() public {
        testAssignersCanAssignRole();

        string memory role = LC.ROLE_ENTITY_ADMIN;
        bytes32 context = LibHelpers._stringToBytes32("test");

        // assign a role to signer1
        nayms.assignRole(signer1Id, context, role);

        // signer1 tries to unassign to signer2
        changePrank(signer1);
        vm.expectRevert("not in assigners group");
        nayms.unassignRole(signer2Id, context);
    }

    function testNonAssignersCannotUnassignRoleIfTheirParentAsAssignerRoleInSystemContext() public {
        bytes32 context = LibHelpers._stringToBytes32("test");

        // assign the role
        testAssignersCanAssignRole();

        changePrank(sm.addr);
        // create entity with signer1 as child
        bytes32 entityId1 = createTestEntity(signer1Id);
        changePrank(sa.addr);
        // assign entity as system manager
        nayms.assignRole(entityId1, systemContext, LC.ROLE_SYSTEM_MANAGER);

        // signer1 tries to unassign to signer2
        changePrank(signer1);
        vm.expectRevert("not in assigners group");
        nayms.unassignRole(signer2Id, context);
    }

    function testAssignersCanUnassignRole() public {
        bytes32 context = LibHelpers._stringToBytes32("test");

        // signer3 makes signer2 an approved user
        testAssignersCanAssignRole();

        // signer1 tries to unassign signer2 as approved user
        changePrank(signer1);
        vm.expectRevert("not in assigners group");
        nayms.unassignRole(signer2Id, context);

        // signer3 can unassign signer2 as approved user
        changePrank(signer3);
        nayms.unassignRole(signer2Id, context);
        assertFalse(nayms.isInGroup(signer2Id, context, LC.GROUP_SYSTEM_MANAGERS));
    }

    function testRoleUnassignmentEmitsAnEvent() public {
        string memory role = LC.ROLE_BROKER;
        bytes32 context = LibHelpers._stringToBytes32("test");

        // signer3 makes signer2 an approved user
        testAssignersCanAssignRole();

        changePrank(signer3);
        vm.recordLogs();

        nayms.unassignRole(signer2Id, context);

        Vm.Log[] memory entries = vm.getRecordedLogs();

        assertEq(entries[0].topics.length, 2);
        assertEq(entries[0].topics[0], keccak256("RoleUpdated(bytes32,bytes32,bytes32,string)"));
        assertEq(entries[0].topics[1], signer2Id);
        (bytes32 contextId, bytes32 roleId, string memory action) = abi.decode(entries[0].data, (bytes32, bytes32, string));
        assertEq(contextId, context);
        assertEq(roleId, LibHelpers._stringToBytes32(role));
        assertEq(action, "_unassignRole");
    }

    function testGetRoleInContext() public {
        string memory role = LC.ROLE_ENTITY_BROKER;
        bytes32 context = LibHelpers._stringToBytes32("test");

        // signer3 assigns signer2 as approved user
        testAssignersCanAssignRole();

        // check signer2 role in context
        assertEq(nayms.getRoleInContext(signer2Id, context), LibHelpers._stringToBytes32(role));

        // signer3 unassigns signer2 as approved user
        testAssignersCanUnassignRole();

        // re-check signer2 role in context
        assertEq(nayms.getRoleInContext(signer2Id, context), bytes32(0));
    }

    function testIsInGroupOnlyConfersRoleInContextThatTheRoleIsAssigned() public {
        string memory role = LC.ROLE_SYSTEM_MANAGER;
        string memory group = LC.GROUP_SYSTEM_MANAGERS;
        bytes32 context = LibHelpers._stringToBytes32("test");

        // assign role in system context
        nayms.assignRole(signer1Id, systemContext, role);
        // test
        assertTrue(nayms.isInGroup(signer1Id, systemContext, group));
        assertFalse(nayms.isInGroup(signer1Id, context, group));

        // assign role in non-system context
        nayms.assignRole(signer2Id, context, role);
        // test
        assertFalse(nayms.isInGroup(signer2Id, systemContext, group));
        assertTrue(nayms.isInGroup(signer2Id, context, group));
    }

    function testIsParentInGroup() public {
        string memory role = LC.ROLE_ENTITY_ADMIN;
        string memory group = LC.GROUP_ENTITY_ADMINS;

        changePrank(sm.addr);
        // create entity with signer2 as child
        bytes32 entityId1 = createTestEntity(signer2Id);

        // changePrank(sa.addr);
        // // assign entity as entity admin
        // nayms.assignRole(entityId1, systemContext, role);

        // // test parent
        // assertTrue(nayms.isInGroup(entityId1, systemContext, group));
        // assertTrue(nayms.isParentInGroup(signer2Id, systemContext, group));
    }

    function testUpdateRoleAssignerFailIfNotAdmin() public {
        changePrank(account1);

        vm.expectRevert(abi.encodeWithSelector(InvalidGroupPrivilege.selector, account1._getIdForAddress(), systemContext, "", LC.GROUP_SYSTEM_ADMINS));
        nayms.updateRoleAssigner("role", "group");
    }

    function testUpdateRoleAssigner2() public {
        changePrank(sa.addr);
        nayms.assignRole(em.id, systemContext, LC.ROLE_ENTITY_MANAGER);

        changePrank(em.addr);

        // setup signer1 as broker2
        nayms.assignRole(signer1Id, systemContext, LC.ROLE_BROKER);
        // brokers can't usually assign approved users
        assertFalse(nayms.canAssign(signer1Id, signer2Id, systemContext, LC.ROLE_ENTITY_ADMIN));
        assertFalse(nayms.canGroupAssignRole(LC.ROLE_ENTITY_ADMIN, LC.GROUP_BROKERS));

        changePrank(sa.addr);
        // now change this
        vm.recordLogs();

        nayms.updateRoleAssigner(LC.ROLE_ENTITY_ADMIN, LC.GROUP_BROKERS);
        assertTrue(nayms.canAssign(signer1Id, signer2Id, systemContext, LC.ROLE_ENTITY_ADMIN));
        assertTrue(nayms.canGroupAssignRole(LC.ROLE_ENTITY_ADMIN, LC.GROUP_BROKERS));

        Vm.Log[] memory entries = vm.getRecordedLogs();
        assertEq(entries[0].topics.length, 1);
        assertEq(entries[0].topics[0], keccak256("RoleCanAssignUpdated(string,string)"));
        (string memory r, string memory g) = abi.decode(entries[0].data, (string, string));
        assertEq(r, LC.ROLE_ENTITY_ADMIN);
        assertEq(g, LC.GROUP_BROKERS);
    }

    function testUpdateRoleGroupFailIfNotAdmin() public {
        changePrank(account1);
        vm.expectRevert(abi.encodeWithSelector(InvalidGroupPrivilege.selector, account1._getIdForAddress(), systemContext, "", LC.GROUP_SYSTEM_ADMINS));
        nayms.updateRoleGroup("role", "group", false);
        vm.stopPrank();
    }

    function testUpdateRoleGroup() public {
        changePrank(sa.addr);
        nayms.assignRole(em.id, systemContext, LC.ROLE_ENTITY_MANAGER);

        changePrank(em.addr);
        // setup signer1 as broker
        nayms.assignRole(signer1Id, systemContext, LC.ROLE_BROKER);
        // brokers can't usually assign approved users
        assertFalse(nayms.canAssign(signer1Id, signer2Id, systemContext, LC.ROLE_ENTITY_ADMIN));
        assertFalse(nayms.isRoleInGroup(LC.ROLE_BROKER, LC.GROUP_SYSTEM_MANAGERS));

        changePrank(sa.addr);
        vm.expectRevert(abi.encodePacked(RoleIsMissing.selector));
        nayms.updateRoleGroup("", LC.GROUP_SYSTEM_MANAGERS, false);

        vm.expectRevert(abi.encodePacked(AssignerGroupIsMissing.selector));
        nayms.updateRoleGroup(LC.ROLE_BROKER, "", false);

        nayms.updateRoleAssigner(LC.ROLE_ENTITY_ADMIN, LC.GROUP_SYSTEM_MANAGERS);

        // now change this
        vm.recordLogs();

        nayms.updateRoleGroup(LC.ROLE_BROKER, LC.GROUP_SYSTEM_MANAGERS, true);
        assertTrue(nayms.canAssign(signer1Id, signer2Id, systemContext, LC.ROLE_ENTITY_ADMIN));
        assertTrue(nayms.isRoleInGroup(LC.ROLE_BROKER, LC.GROUP_SYSTEM_MANAGERS));

        Vm.Log[] memory entries = vm.getRecordedLogs();
        assertEq(entries[0].topics.length, 1);
        assertEq(entries[0].topics[0], keccak256("RoleGroupUpdated(string,string,bool)"));
        (string memory r, string memory g, bool v) = abi.decode(entries[0].data, (string, string, bool));
        assertEq(r, LC.ROLE_BROKER);
        assertEq(g, LC.GROUP_SYSTEM_MANAGERS);
        assertTrue(v);

        // now change it back
        vm.recordLogs();

        nayms.updateRoleGroup(LC.ROLE_BROKER, LC.GROUP_SYSTEM_MANAGERS, false);
        assertFalse(nayms.canAssign(signer1Id, signer2Id, systemContext, LC.ROLE_ENTITY_ADMIN));

        entries = vm.getRecordedLogs();
        assertEq(entries[0].topics.length, 1);
        assertEq(entries[0].topics[0], keccak256("RoleGroupUpdated(string,string,bool)"));
        (r, g, v) = abi.decode(entries[0].data, (string, string, bool));
        assertEq(r, LC.ROLE_BROKER);
        assertEq(g, LC.GROUP_SYSTEM_MANAGERS);
        assertFalse(v);
    }
}
