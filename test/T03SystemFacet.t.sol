// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import { D03ProtocolDefaults, LibHelpers, LibAdmin, LC, c } from "./defaults/D03ProtocolDefaults.sol";

import { MockAccounts } from "./utils/users/MockAccounts.sol";

import { Entity } from "../src/shared/AppStorage.sol";
import "../src/shared/CustomErrors.sol";

contract T03SystemFacetTest is D03ProtocolDefaults, MockAccounts {
    using LibHelpers for *;

    bytes32 internal immutable objectContext1 = "0x1";

    function setUp() public {
        // Start with system manager privileges for all tests
        changePrank(sm.addr);
    }

    function testD03CreateEntity() public {
        // Test entity created in D03ProtocolDefaults
        bytes32 userId = nayms.getUserIdFromAddress(account0);
        bytes32 parentId = nayms.getEntity(userId);
        assertEq(DEFAULT_ACCOUNT0_ENTITY_ID, parentId, "User, parent (derived from entity ID) don't match");
    }

    function testUnsupportedExternalTokenWhenCreatingEntity() public {
        bytes32 objectId1 = "0x1";
        vm.expectRevert("external token is not supported");
        nayms.createEntity(objectId1, objectContext1, initEntity(wbtcId, LC.BP_FACTOR, LC.BP_FACTOR, false), "entity test hash");
    }

    function testZeroCollateralRatioWhenCreatingEntity() public {
        bytes32 objectId1 = "0x1";
        vm.expectRevert("collateral ratio should be 1 to 10000");
        nayms.createEntity(objectId1, objectContext1, initEntity(wethId, 0, 1, false), "entity test hash");
    }

    function testNonManagerCreateEntity() public {
        bytes32 objectId1 = "0x1";

        changePrank(account1);
        vm.expectRevert(abi.encodeWithSelector(InvalidGroupPrivilege.selector, account1._getIdForAddress(), systemContext, "", LC.GROUP_SYSTEM_MANAGERS));
        nayms.createEntity(objectId1, objectContext1, initEntity(wethId, 5000, LC.BP_FACTOR, true), "entity test hash");
    }

    function testSingleCreateEntity() public {
        bytes32 objectId1 = "0x1";
        vm.expectRevert(abi.encodeWithSelector(InvalidObjectType.selector, objectId1, LC.OBJECT_TYPE_ENTITY));
        nayms.createEntity(objectId1, objectContext1, initEntity(wethId, 5000, LC.BP_FACTOR, true), "entity test hash");
        nayms.createEntity(makeId(LC.OBJECT_TYPE_ENTITY, bytes20(objectId1)), objectContext1, initEntity(wethId, 5000, LC.BP_FACTOR, true), "entity test hash");
    }

    function testMultipleCreateEntity() public {
        bytes32 objectId1 = makeId(LC.OBJECT_TYPE_ENTITY, bytes20("0x1"));
        nayms.createEntity(objectId1, objectContext1, initEntity(wethId, 5000, LC.BP_FACTOR, true), "entity test hash");

        // cannot create an object that already exists in a given context
        vm.expectRevert(abi.encodePacked(EntityExistsAlready.selector, (objectId1)));
        nayms.createEntity(objectId1, objectContext1, initEntity(wethId, 5000, LC.BP_FACTOR, true), "entity test hash");

        // still reverts regardless of role being assigned
        vm.expectRevert(abi.encodePacked(EntityExistsAlready.selector, (objectId1)));
        nayms.createEntity(objectId1, objectContext1, initEntity(wethId, 5000, LC.BP_FACTOR, true), "entity test hash");

        bytes32 objectId2 = makeId(LC.OBJECT_TYPE_ENTITY, bytes20("0x2"));
        nayms.createEntity(objectId2, objectContext1, initEntity(wethId, 5000, LC.BP_FACTOR, true), "entity test hash");
    }

    function testStringToBytes32() public {
        assertEq(nayms.stringToBytes32(""), bytes32(0), "stringToBytes32 empty");
        assertEq(nayms.stringToBytes32("test"), bytes32("test"), "stringToBytes32 non-empty");
    }

    function testIsObject() public {
        bytes32 objectId2 = "0xe1";
        assertFalse(nayms.isObject(objectId2));
        objectId2 = createTestEntity(objectContext1);
        // nayms.createEntity(objectId2, objectContext1, initEntity(wethId, 5000, LC.BP_FACTOR, true), "entity test hash");
        assertTrue(nayms.isObject(objectId2));
    }

    function testGetObjectMeta() public {
        bytes32 objectId2 = createTestEntity(objectContext1);

        (bytes32 parent, bytes32 dataHash, string memory tokenSymbol, string memory tokenName, address wrapperAddress) = nayms.getObjectMeta(objectId2);

        assertEq(dataHash, "");
        assertEq(parent, "");
        assertEq(tokenSymbol, "");
        assertEq(tokenName, "");
        assertEq(wrapperAddress, address(0));
    }

    bytes12[11] internal objectTypes = [
        LC.OBJECT_TYPE_ADDRESS,
        LC.OBJECT_TYPE_ENTITY,
        LC.OBJECT_TYPE_POLICY,
        LC.OBJECT_TYPE_FEE,
        LC.OBJECT_TYPE_CLAIM,
        LC.OBJECT_TYPE_DIVIDEND,
        LC.OBJECT_TYPE_PREMIUM,
        LC.OBJECT_TYPE_ROLE,
        LC.OBJECT_TYPE_GROUP,
        LC.OBJECT_TYPE_STAKED,
        LC.OBJECT_TYPE_STAKING_REWARD
    ];

    function test_IsObjectType() public {
        for (uint256 i; i < objectTypes.length; i++) {
            bytes32 objectId = bytes32(objectTypes[i]) | bytes32(uint256(1));
            assertEq(nayms.getObjectType(objectId), objectTypes[i], "getObjectType");
            c.logBytes12(nayms.getObjectType(objectId));
            assertEq(nayms.isObjectType(objectId, objectTypes[i]), true, "isObjectType");
        }
    }

    function test_updateExistingObjectIDs() public {
        bytes32[] memory ids = new bytes32[](1);
        ids[0] = LibAdmin._getSystemId();

        assertEq(nayms.isObject(LibAdmin._getSystemId()), false, "System ID should not be an existing object");

        changePrank(sm);
        vm.expectRevert(abi.encodeWithSelector(InvalidGroupPrivilege.selector, sm.addr._getIdForAddress(), systemContext, LC.ROLE_SYSTEM_MANAGER, LC.GROUP_SYSTEM_ADMINS));
        nayms.setExistingObjects(ids, true);

        changePrank(sa);
        nayms.setExistingObjects(ids, true);
        assertEq(nayms.isObject(LibAdmin._getSystemId()), true, "System ID should be an existing object now");

        nayms.setExistingObjects(ids, false);
        assertEq(nayms.isObject(LibAdmin._getSystemId()), false, "System ID should not be an existing object any more");

        ids = new bytes32[](11);
        ids[1] = makeId(LC.OBJECT_TYPE_ENTITY, bytes20("1"));
        ids[2] = makeId(LC.OBJECT_TYPE_ENTITY, bytes20("1"));
        ids[3] = makeId(LC.OBJECT_TYPE_ENTITY, bytes20("1"));
        ids[4] = makeId(LC.OBJECT_TYPE_ENTITY, bytes20("1"));
        ids[5] = makeId(LC.OBJECT_TYPE_ENTITY, bytes20("1"));
        ids[6] = makeId(LC.OBJECT_TYPE_ENTITY, bytes20("1"));
        ids[7] = makeId(LC.OBJECT_TYPE_ENTITY, bytes20("1"));
        ids[8] = makeId(LC.OBJECT_TYPE_ENTITY, bytes20("1"));
        ids[9] = makeId(LC.OBJECT_TYPE_ENTITY, bytes20("1"));
        ids[10] = makeId(LC.OBJECT_TYPE_ENTITY, bytes20("1"));

        vm.expectRevert("too many ids");
        nayms.setExistingObjects(ids, false);
    }
}
