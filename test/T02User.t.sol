// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { D03ProtocolDefaults, LibHelpers, LibConstants } from "./defaults/D03ProtocolDefaults.sol";
import { MockAccounts } from "test/utils/users/MockAccounts.sol";
import { Vm } from "forge-std/Vm.sol";
import "src/diamonds/nayms/interfaces/CustomErrors.sol";

contract T02UserTest is D03ProtocolDefaults, MockAccounts {
    function setUp() public {}

    function testGetUserIdFromAddress() public {
        assertEq(nayms.getUserIdFromAddress(account0), LibHelpers._getIdForAddress(account0));
    }

    function testGetAddressFromExternalTokenId() public {
        bytes32 id = LibHelpers._getIdForAddress(LibConstants.DAI_CONSTANT);
        assertEq(nayms.getAddressFromExternalTokenId(id), LibConstants.DAI_CONSTANT);
    }

    function testSetEntityFailsIfNotSysAdmin() public {
        changePrank(signer2);
        vm.expectRevert("not a system admin");
        nayms.setEntity(account0Id, bytes32(0));
    }

    function testGetSetEntity() public {
        bytes32 entityId = createTestEntity(account0Id);
        nayms.setEntity(signer1Id, entityId);
        assertEq(nayms.getEntity(signer1Id), entityId);
    }

    function testSetNonExistingEntity() public {
        bytes32 entityId;
        vm.expectRevert(abi.encodePacked(EntityDoesNotExist.selector, (entityId)));
        nayms.setEntity(signer1Id, entityId);
    }
}
