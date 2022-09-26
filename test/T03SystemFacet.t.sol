// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { D03ProtocolDefaults, console2, LibConstants, LibHelpers, initEntity } from "./defaults/D03ProtocolDefaults.sol";

import { MockAccounts } from "./utils/users/MockAccounts.sol";

import { INayms } from "src/diamonds/nayms/INayms.sol";
import { Entity } from "src/diamonds/nayms/AppStorage.sol";

import { ERC20 } from "src/erc20/ERC20.sol";

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

    function testZeroCollateralRatioWhenCreatingEntity() public {
        bytes32 objectId1 = "0x1";
        vm.expectRevert("collateral ratio should be 1 to 1000");
        nayms.createEntity(objectId1, objectContext1, initEntity(weth, 0, 1, 0, false), "entity test hash");
    }

    function testNonManagerCreateEntity() public {
        bytes32 objectId1 = "0x1";

        vm.expectRevert("not a system manager");
        vm.prank(account1);
        nayms.createEntity(objectId1, objectContext1, initEntity(weth, 500, 1000, 0, true), "entity test hash");
    }

    function testSingleCreateEntity() public {
        bytes32 objectId1 = "0x1";
        nayms.createEntity(objectId1, objectContext1, initEntity(weth, 500, 1000, 0, true), "entity test hash");
    }

    function testMultipleCreateEntity() public {
        bytes32 objectId1 = "0x1";
        nayms.createEntity(objectId1, objectContext1, initEntity(weth, 500, 1000, 0, true), "entity test hash");

        // cannot create an object that already exists in a given context
        vm.expectRevert("object already exists");
        nayms.createEntity(objectId1, objectContext1, initEntity(weth, 500, 1000, 0, true), "entity test hash");

        // still reverts regardless of role being assigned
        vm.expectRevert("object already exists");
        nayms.createEntity(objectId1, objectContext1, initEntity(weth, 500, 1000, 0, true), "entity test hash");

        bytes32 objectId2 = "0x2";
        nayms.createEntity(objectId2, objectContext1, initEntity(weth, 500, 1000, 0, true), "entity test hash");
    }

    function testStringToBytes32() public {
        assertEq(nayms.stringToBytes32(""), bytes32(0), "stringToBytes32 empty");
        assertEq(nayms.stringToBytes32("test"), bytes32("test"), "stringToBytes32 non-empty");
    }
}
