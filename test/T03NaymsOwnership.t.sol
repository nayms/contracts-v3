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

    function testTransferOwernshipFailsIfNotContractOwner() public {
        vm.prank(signer1);
        vm.expectRevert("LibDiamond: Must be contract owner");
        nayms.transferOwnership(signer1);
    }

    function testTransferOwernship() public {
        nayms.transferOwnership(signer1);
        assertTrue(nayms.isInGroup(signer1Id, systemContext, LibConstants.GROUP_SYSTEM_ADMINS));
    }

    function testTransferOwernshipToZeroAddressFails() public {
        vm.expectRevert("new owner must not be address 0");
        nayms.transferOwnership(address(0));
    }
}
