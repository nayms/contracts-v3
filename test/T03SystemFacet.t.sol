// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { D03ProtocolDefaults, console2, LibConstants, LibHelpers } from "./defaults/D03ProtocolDefaults.sol";

import { MockAccounts } from "./utils/users/MockAccounts.sol";

import { Entity } from "src/diamonds/nayms/AppStorage.sol";

/// @dev Testing creating entities

contract T03SystemFacetTest is D03ProtocolDefaults, MockAccounts {
    bytes32 internal immutable objectContext1 = "0x1";
    Entity internal entityInfo;

    function setUp() public virtual override {
        super.setUp();
    }

    function testD03CreateEntity() public {
        // Test entity created in D03ProtocolDefaults
        bytes32 userId = nayms.getUserIdFromAddress(account0);
        bytes32 parentId = nayms.getEntity(userId);
        assertEq(DEFAULT_ACCOUNT0_ENTITY_ID, parentId, "User, parent (derived from entity ID) don't match");
    }

    function testNonManagerCreateEntity() public {
        bytes32 objectId1 = "0x1";

        vm.expectRevert("not a system manager");
        vm.prank(account1);
        nayms.createEntity(objectId1, objectContext1, entityInfo);
    }

    function testSingleCreateEntity() public {
        bytes32 objectId1 = "0x1";
        nayms.createEntity(objectId1, objectContext1, entityInfo);
    }

    function testMultipleCreateEntity() public {
        bytes32 objectId1 = "0x1";
        nayms.createEntity(objectId1, objectContext1, entityInfo);

        // cannot create an object that already exists in a given context
        vm.expectRevert("object already exists");
        nayms.createEntity(objectId1, objectContext1, entityInfo);

        // still reverts regardless of role being assigned
        vm.expectRevert("object already exists");
        nayms.createEntity(objectId1, objectContext1, entityInfo);

        bytes32 objectId2 = "0x2";
        nayms.createEntity(objectId2, objectContext1, entityInfo);
    }

    function testApproveUser() public {
        bytes32 objectId1 = "0x1";
        bytes32 approvedUserId = LibHelpers._getIdForAddress(vm.addr(0xACC1));

        // create an entity
        nayms.createEntity(objectId1, objectContext1, entityInfo);

        vm.prank(account9);
        vm.expectRevert("not a system manager");
        nayms.approveUser(approvedUserId, objectId1);
        vm.stopPrank();

        nayms.approveUser(approvedUserId, objectId1);
        assertTrue(nayms.isInGroup(approvedUserId, objectId1, LibConstants.GROUP_APPROVED_USERS));
    }
}
