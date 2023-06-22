// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { D03ProtocolDefaults, LibConstants } from "./defaults/D03ProtocolDefaults.sol";

import { MockAccounts } from "./utils/users/MockAccounts.sol";

import { Entity } from "src/diamonds/nayms/AppStorage.sol";
import "src/diamonds/nayms/interfaces/CustomErrors.sol";

contract T03SystemFacetTest is D03ProtocolDefaults, MockAccounts {
    bytes32 internal immutable objectContext1 = "0x1";

    function setUp() public virtual override {
        super.setUp();
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
        nayms.createEntity(objectId1, objectContext1, initEntity(wbtcId, LibConstants.BP_FACTOR, LibConstants.BP_FACTOR, false), "entity test hash");
    }

    function testZeroCollateralRatioWhenCreatingEntity() public {
        bytes32 objectId1 = "0x1";
        vm.expectRevert("collateral ratio should be 1 to 10000");
        nayms.createEntity(objectId1, objectContext1, initEntity(wethId, 0, 1, false), "entity test hash");
    }

    function testNonManagerCreateEntity() public {
        bytes32 objectId1 = "0x1";

        vm.expectRevert("not a system manager");
        changePrank(account1);
        nayms.createEntity(objectId1, objectContext1, initEntity(wethId, 5000, LibConstants.BP_FACTOR, true), "entity test hash");
    }

    function testSingleCreateEntity() public {
        bytes32 objectId1 = "0x1";
        nayms.createEntity(objectId1, objectContext1, initEntity(wethId, 5000, LibConstants.BP_FACTOR, true), "entity test hash");
    }

    function testMultipleCreateEntity() public {
        bytes32 objectId1 = "0x1";
        nayms.createEntity(objectId1, objectContext1, initEntity(wethId, 5000, LibConstants.BP_FACTOR, true), "entity test hash");

        // cannot create an object that already exists in a given context
        vm.expectRevert(abi.encodePacked(CreatingEntityThatAlreadyExists.selector, (objectId1)));
        nayms.createEntity(objectId1, objectContext1, initEntity(wethId, 5000, LibConstants.BP_FACTOR, true), "entity test hash");

        // still reverts regardless of role being assigned
        vm.expectRevert(abi.encodePacked(CreatingEntityThatAlreadyExists.selector, (objectId1)));
        nayms.createEntity(objectId1, objectContext1, initEntity(wethId, 5000, LibConstants.BP_FACTOR, true), "entity test hash");

        bytes32 objectId2 = "0x2";
        nayms.createEntity(objectId2, objectContext1, initEntity(wethId, 5000, LibConstants.BP_FACTOR, true), "entity test hash");
    }

    function testStringToBytes32() public {
        assertEq(nayms.stringToBytes32(""), bytes32(0), "stringToBytes32 empty");
        assertEq(nayms.stringToBytes32("test"), bytes32("test"), "stringToBytes32 non-empty");
    }

    function testIsObject() public {
        bytes32 objectId2 = "0x2";
        assertFalse(nayms.isObject(objectId2));
        nayms.createEntity(objectId2, objectContext1, initEntity(wethId, 5000, LibConstants.BP_FACTOR, true), "entity test hash");
        assertTrue(nayms.isObject(objectId2));
    }

    function testGetObjectMeta() public {
        bytes32 objectId2 = "0x2";

        nayms.createEntity(objectId2, objectContext1, initEntity(wethId, 5000, LibConstants.BP_FACTOR, true), "entity test hash");
        (bytes32 parent, bytes32 dataHash, string memory tokenSymbol, string memory tokenName, address wrapperAddress) = nayms.getObjectMeta(objectId2);

        assertEq(dataHash, "entity test hash");
        assertEq(parent, "");
        assertEq(tokenSymbol, "");
        assertEq(tokenName, "");
        assertEq(wrapperAddress, address(0));
    }
}
