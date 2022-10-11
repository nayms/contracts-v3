// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { D03ProtocolDefaults, console2, LibAdmin, LibConstants, LibHelpers } from "./defaults/D03ProtocolDefaults.sol";
import { MockAccounts } from "test/utils/users/MockAccounts.sol";
import { Vm } from "forge-std/Vm.sol";

contract T02AdminTest is D03ProtocolDefaults, MockAccounts {
    function setUp() public virtual override {
        super.setUp();
    }

    function testGetSystemId() public {
        assertEq(nayms.getSystemId(), LibHelpers._stringToBytes32(LibConstants.SYSTEM_IDENTIFIER));
    }

    function testSetEquilibriumLevelFailIfNotAdmin() public {
        vm.startPrank(account1);
        vm.expectRevert("not a system admin");
        nayms.setEquilibriumLevel(50);
        vm.stopPrank();
    }

    function testSetEquilibriumLevel() public {
        vm.recordLogs();
        uint256 orig = nayms.getEquilibriumLevel();
        nayms.setEquilibriumLevel(50);
        assertEq(nayms.getEquilibriumLevel(), 50);

        Vm.Log[] memory entries = vm.getRecordedLogs();
        assertEq(entries[0].topics.length, 1);
        assertEq(entries[0].topics[0], keccak256("EquilibriumLevelUpdated(uint256,uint256)"));
        (uint256 oldV, uint256 newV) = abi.decode(entries[0].data, (uint256, uint256));
        assertEq(oldV, orig);
        assertEq(newV, 50);
    }

    function testFuzzSetEquilibriumLevel(uint256 _newLevel) public {
        nayms.setEquilibriumLevel(_newLevel);
    }

    function testSetMaxDiscountFailIfNotAdmin() public {
        vm.startPrank(account1);
        vm.expectRevert("not a system admin");
        nayms.setMaxDiscount(70);
        vm.stopPrank();
    }

    function testSetMaxDiscount() public {
        uint256 orig = nayms.getMaxDiscount();

        vm.recordLogs();

        nayms.setMaxDiscount(70);
        assertEq(nayms.getMaxDiscount(), 70);

        Vm.Log[] memory entries = vm.getRecordedLogs();
        assertEq(entries[0].topics.length, 1);
        assertEq(entries[0].topics[0], keccak256("MaxDiscountUpdated(uint256,uint256)"));
        (uint256 oldV, uint256 newV) = abi.decode(entries[0].data, (uint256, uint256));
        assertEq(oldV, orig);
        assertEq(newV, 70);
    }

    function testFuzzSetMaxDiscount(uint256 _newDiscount) public {
        nayms.setMaxDiscount(_newDiscount);
    }

    function testSetTargetNaymSAllocationFailIfNotAdmin() public {
        vm.startPrank(account1);
        vm.expectRevert("not a system admin");
        nayms.setTargetNaymsAllocation(70);
        vm.stopPrank();
    }

    function testGetActualNaymsAllocation() public {
        assertEq(nayms.getActualNaymsAllocation(), 0);
    }

    function testSetTargetNaymsAllocation() public {
        uint256 orig = nayms.getTargetNaymsAllocation();

        vm.recordLogs();

        nayms.setTargetNaymsAllocation(70);
        assertEq(nayms.getTargetNaymsAllocation(), 70);

        Vm.Log[] memory entries = vm.getRecordedLogs();
        assertEq(entries[0].topics.length, 1);
        assertEq(entries[0].topics[0], keccak256("TargetNaymsAllocationUpdated(uint256,uint256)"));
        (uint256 oldV, uint256 newV) = abi.decode(entries[0].data, (uint256, uint256));
        assertEq(oldV, orig);
        assertEq(newV, 70);
    }

    function testFuzzSetTargetNaymsAllocation(uint256 _newTarget) public {
        nayms.setTargetNaymsAllocation(_newTarget);
    }

    function testSetDiscountTokenFailIfNotAdmin() public {
        vm.startPrank(account1);
        vm.expectRevert("not a system admin");
        nayms.setDiscountToken(LibConstants.DAI_CONSTANT);
        vm.stopPrank();
    }

    function testSetDiscountToken() public {
        address orig = nayms.getDiscountToken();

        vm.recordLogs();

        nayms.setDiscountToken(LibConstants.DAI_CONSTANT);
        assertEq(nayms.getDiscountToken(), LibConstants.DAI_CONSTANT);

        Vm.Log[] memory entries = vm.getRecordedLogs();
        assertEq(entries[0].topics.length, 1);
        assertEq(entries[0].topics[0], keccak256("DiscountTokenUpdated(address,address)"));
        (address oldV, address newV) = abi.decode(entries[0].data, (address, address));
        assertEq(oldV, orig);
        assertEq(newV, LibConstants.DAI_CONSTANT);
    }

    function testFuzzSetDiscountToken(address _newToken) public {
        nayms.setDiscountToken(_newToken);
    }

    function testSetPoolFeeFailIfNotAdmin() public {
        vm.startPrank(account1);
        vm.expectRevert("not a system admin");
        nayms.setPoolFee(4000);
        vm.stopPrank();
    }

    function testSetPoolFee() public {
        uint256 orig = nayms.getPoolFee();

        vm.recordLogs();

        nayms.setPoolFee(4000);
        assertEq(nayms.getPoolFee(), 4000);

        Vm.Log[] memory entries = vm.getRecordedLogs();
        assertEq(entries[0].topics.length, 1);
        assertEq(entries[0].topics[0], keccak256("PoolFeeUpdated(uint256,uint256)"));
        (uint256 oldV, uint256 newV) = abi.decode(entries[0].data, (uint256, uint256));
        assertEq(oldV, orig);
        assertEq(newV, 4000);
    }

    function testFuzzSetPoolFee(uint24 _newFee) public {
        nayms.setPoolFee(_newFee);
    }

    function testSetCoefficientFailIfNotAdmin() public {
        vm.startPrank(account1);
        vm.expectRevert("not a system admin");
        nayms.setCoefficient(100);
        vm.stopPrank();
    }

    function testSetCoefficientFailIfValueTooHigh() public {
        vm.expectRevert("Coefficient too high");
        nayms.setCoefficient(1001);
    }

    function testSetCoefficient() public {
        uint256 orig = nayms.getRewardsCoefficient();

        vm.recordLogs();

        nayms.setCoefficient(100);
        assertEq(nayms.getRewardsCoefficient(), 100);

        Vm.Log[] memory entries = vm.getRecordedLogs();
        assertEq(entries[0].topics.length, 1);
        assertEq(entries[0].topics[0], keccak256("CoefficientUpdated(uint256,uint256)"));
        (uint256 oldV, uint256 newV) = abi.decode(entries[0].data, (uint256, uint256));
        assertEq(oldV, orig);
        assertEq(newV, 100);
    }

    function testFuzzSetCoefficient(uint256 _newCoefficient) public {
        _newCoefficient = bound(_newCoefficient, 0, 1000);
        nayms.setCoefficient(_newCoefficient);
    }

    function testGetMaxDividendDenominationsDefaultValue() public {
        assertEq(nayms.getMaxDividendDenominations(), 1);
    }

    function testSetMaxDividendDenominationsFailIfNotAdmin() public {
        vm.startPrank(account1);
        vm.expectRevert("not a system admin");
        nayms.setMaxDividendDenominations(100);
        vm.stopPrank();
    }

    function testSetMaxDividendDenominationsFailIfLowerThanBefore() public {
        nayms.setMaxDividendDenominations(2);

        vm.expectRevert("_updateMaxDividendDenominations: cannot reduce");
        nayms.setMaxDividendDenominations(2);

        nayms.setMaxDividendDenominations(3);
    }

    function testSetMaxDividendDenominations() public {
        uint256 orig = nayms.getMaxDividendDenominations();

        vm.recordLogs();

        nayms.setMaxDividendDenominations(100);
        assertEq(nayms.getMaxDividendDenominations(), 100);

        Vm.Log[] memory entries = vm.getRecordedLogs();
        assertEq(entries[0].topics.length, 1);
        assertEq(entries[0].topics[0], keccak256("MaxDividendDenominationsUpdated(uint8,uint8)"));
        (uint8 oldV, uint8 newV) = abi.decode(entries[0].data, (uint8, uint8));
        assertEq(oldV, orig);
        assertEq(newV, 100);
    }

    function testAddSupportedExternalTokenFailIfNotAdmin() public {
        vm.startPrank(account1);
        vm.expectRevert("not a system admin");
        nayms.addSupportedExternalToken(LibConstants.DAI_CONSTANT);
        vm.stopPrank();
    }

    function testAddSupportedExternalToken() public {
        address[] memory orig = nayms.getSupportedExternalTokens();

        vm.recordLogs();

        nayms.addSupportedExternalToken(LibConstants.DAI_CONSTANT);
        address[] memory v = nayms.getSupportedExternalTokens();
        assertEq(v.length, orig.length + 1);
        assertEq(v[v.length - 1], LibConstants.DAI_CONSTANT);

        Vm.Log[] memory entries = vm.getRecordedLogs();
        assertEq(entries[0].topics.length, 1);
        assertEq(entries[0].topics[0], keccak256("SupportedTokenAdded(address)"));
        address tok = abi.decode(entries[0].data, (address));
        assertEq(tok, LibConstants.DAI_CONSTANT);
    }

    function testIsSupportedToken() public {
        bytes32 id = LibHelpers._getIdForAddress(LibConstants.DAI_CONSTANT);

        assertFalse(nayms.isSupportedExternalToken(id));

        nayms.addSupportedExternalToken(LibConstants.DAI_CONSTANT);

        assertTrue(nayms.isSupportedExternalToken(id));
    }

    function testAddSupportedExternalTokenIfAlreadyAdded() public {
        address[] memory orig = nayms.getSupportedExternalTokens();

        vm.recordLogs();

        nayms.addSupportedExternalToken(LibConstants.DAI_CONSTANT);
        nayms.addSupportedExternalToken(LibConstants.DAI_CONSTANT);

        address[] memory v = nayms.getSupportedExternalTokens();
        assertEq(v.length, orig.length + 1);
        assertEq(v[v.length - 1], LibConstants.DAI_CONSTANT);

        Vm.Log[] memory entries = vm.getRecordedLogs();
        assertEq(entries[0].topics.length, 1);
        assertEq(entries[0].topics[0], keccak256("SupportedTokenAdded(address)"));
    }

    function testUpdateRoleAssignerFailIfNotAdmin() public {
        vm.startPrank(account1);
        vm.expectRevert("not a system admin");
        nayms.updateRoleAssigner("role", "group");
        vm.stopPrank();
    }

    function testUpdateRoleAssigner() public {
        // setup signer1 as broker
        nayms.assignRole(signer1Id, systemContext, LibConstants.ROLE_BROKER);
        // brokers can't usually assign approved users
        assertFalse(nayms.canAssign(signer1Id, signer2Id, systemContext, LibConstants.ROLE_ENTITY_ADMIN));
        assertFalse(nayms.canGroupAssignRole(LibConstants.ROLE_ENTITY_ADMIN, LibConstants.GROUP_BROKERS));

        // now change this
        vm.recordLogs();

        nayms.updateRoleAssigner(LibConstants.ROLE_ENTITY_ADMIN, LibConstants.GROUP_BROKERS);
        assertTrue(nayms.canAssign(signer1Id, signer2Id, systemContext, LibConstants.ROLE_ENTITY_ADMIN));
        assertTrue(nayms.canGroupAssignRole(LibConstants.ROLE_ENTITY_ADMIN, LibConstants.GROUP_BROKERS));

        Vm.Log[] memory entries = vm.getRecordedLogs();
        assertEq(entries[0].topics.length, 1);
        assertEq(entries[0].topics[0], keccak256("RoleCanAssignUpdated(string,string)"));
        (string memory r, string memory g) = abi.decode(entries[0].data, (string, string));
        assertEq(r, LibConstants.ROLE_ENTITY_ADMIN);
        assertEq(g, LibConstants.GROUP_BROKERS);
    }

    function testUpdateRoleGroupFailIfNotAdmin() public {
        vm.startPrank(account1);
        vm.expectRevert("not a system admin");
        nayms.updateRoleGroup("role", "group", false);
        vm.stopPrank();
    }

    function testUpdateRoleGroup() public {
        // setup signer1 as broker
        nayms.assignRole(signer1Id, systemContext, LibConstants.ROLE_BROKER);
        // brokers can't usually assign approved users
        assertFalse(nayms.canAssign(signer1Id, signer2Id, systemContext, LibConstants.ROLE_ENTITY_ADMIN));
        assertFalse(nayms.isRoleInGroup(LibConstants.ROLE_BROKER, LibConstants.GROUP_SYSTEM_MANAGERS));

        // now change this
        vm.recordLogs();

        nayms.updateRoleGroup(LibConstants.ROLE_BROKER, LibConstants.GROUP_SYSTEM_MANAGERS, true);
        assertTrue(nayms.canAssign(signer1Id, signer2Id, systemContext, LibConstants.ROLE_ENTITY_ADMIN));
        assertTrue(nayms.isRoleInGroup(LibConstants.ROLE_BROKER, LibConstants.GROUP_SYSTEM_MANAGERS));

        Vm.Log[] memory entries = vm.getRecordedLogs();
        assertEq(entries[0].topics.length, 1);
        assertEq(entries[0].topics[0], keccak256("RoleGroupUpdated(string,string,bool)"));
        (string memory r, string memory g, bool v) = abi.decode(entries[0].data, (string, string, bool));
        assertEq(r, LibConstants.ROLE_BROKER);
        assertEq(g, LibConstants.GROUP_SYSTEM_MANAGERS);
        assertTrue(v);

        // now change it back
        vm.recordLogs();

        nayms.updateRoleGroup(LibConstants.ROLE_BROKER, LibConstants.GROUP_SYSTEM_MANAGERS, false);
        assertFalse(nayms.canAssign(signer1Id, signer2Id, systemContext, LibConstants.ROLE_ENTITY_ADMIN));

        entries = vm.getRecordedLogs();
        assertEq(entries[0].topics.length, 1);
        assertEq(entries[0].topics[0], keccak256("RoleGroupUpdated(string,string,bool)"));
        (r, g, v) = abi.decode(entries[0].data, (string, string, bool));
        assertEq(r, LibConstants.ROLE_BROKER);
        assertEq(g, LibConstants.GROUP_SYSTEM_MANAGERS);
        assertFalse(v);
    }
}
