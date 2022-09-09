// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { D03ProtocolDefaults, console2, LibAdmin, LibConstants, LibHelpers } from "./defaults/D03ProtocolDefaults.sol";
import { MockAccounts } from "test/utils/users/MockAccounts.sol";

contract T02AdminTest is D03ProtocolDefaults, MockAccounts {
    function setUp() public virtual override {
        super.setUp();
    }

    function testRevertSetEquilibriumLevel() public {
        vm.startPrank(account1);
        vm.expectRevert("not a system admin");
        nayms.setEquilibriumLevel(50);
        vm.stopPrank();
    }

    function testSetEquilibriumLevel() public {
        vm.startPrank(account0);
        nayms.setEquilibriumLevel(50);
        assertEq(nayms.getEquilibriumLevel(), 50);

        vm.stopPrank();
    }

    function testFuzzSetEquilibriumLevel(uint256 _newLevel) public {
        nayms.setEquilibriumLevel(_newLevel);
    }

    function testFailSetMaxDiscount() public {
        vm.startPrank(account1);
        nayms.setMaxDiscount(70);
        vm.expectRevert("not a system admin");
        vm.stopPrank();
    }

    function testSetMaxDiscount() public {
        vm.startPrank(account0);
        nayms.setMaxDiscount(70);
        assertEq(nayms.getMaxDiscount(), 70);
        vm.stopPrank();
    }

    function testFuzzSetMaxDiscount(uint256 _newDiscount) public {
        nayms.setMaxDiscount(_newDiscount);
    }

    function testFailSetTargetNaymSAllocation() public {
        vm.startPrank(account1);
        nayms.setTargetNaymsAllocation(70);
        vm.expectRevert("not a system admin");
        vm.stopPrank();
    }

    function testSetTargetNaymsAllocation() public {
        vm.startPrank(account0);
        nayms.setTargetNaymsAllocation(70);
        assertEq(nayms.getTargetNaymsAllocation(), 70);
        vm.stopPrank();
    }

    function testFuzzSetTargetNaymsAllocation(uint256 _newTarget) public {
        nayms.setTargetNaymsAllocation(_newTarget);
    }

    function testFailSetDiscountToken() public {
        vm.startPrank(account1);
        nayms.setDiscountToken(LibConstants.DAI_CONSTANT);
        vm.expectRevert("not a system admin");
        vm.stopPrank();
    }

    function testSetDiscountToken() public {
        vm.startPrank(account0);
        nayms.setDiscountToken(LibConstants.DAI_CONSTANT);
        assertEq(nayms.getDiscountToken(), LibConstants.DAI_CONSTANT);
        vm.stopPrank();
    }

    function testFuzzSetDiscountToken(address _newToken) public {
        nayms.setDiscountToken(_newToken);
    }

    function testFailSetPoolFee() public {
        vm.startPrank(account1);
        nayms.setPoolFee(4000);
        vm.expectRevert("not a system admin");
        vm.stopPrank();
    }

    function testSetPoolFee() public {
        vm.startPrank(account0);
        nayms.setPoolFee(4000);
        assertEq(nayms.getPoolFee(), 4000);
        vm.stopPrank();
    }

    function testFuzzSetPoolFee(uint24 _newFee) public {
        nayms.setPoolFee(_newFee);
    }

    function testFailSetCoefficient() public {
        vm.startPrank(account1);
        nayms.setCoefficient(100);
        vm.expectRevert("not a system admin");
        vm.stopPrank();
    }

    function testSetCoefficient() public {
        vm.startPrank(account0);
        nayms.setCoefficient(100);
        assertEq(nayms.getRewardsCoefficient(), 100);
        vm.stopPrank();
    }

    function testFuzzSetCoefficient(uint256 _newCoefficient) public {
        _newCoefficient = bound(_newCoefficient, 0, 1000);
        nayms.setCoefficient(_newCoefficient);
    }
}
