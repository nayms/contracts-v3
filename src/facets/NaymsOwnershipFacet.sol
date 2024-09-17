// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import { LibDiamond } from "lib/diamond-2-hardhat/contracts/libraries/LibDiamond.sol";
import { IERC173 } from "lib/diamond-2-hardhat/contracts/interfaces/IERC173.sol";
import { LibACL } from "src/libs/LibACL.sol";
import { LibHelpers } from "src/libs/LibHelpers.sol";
import { LibAdmin } from "src/libs/LibAdmin.sol";
import { LibConstants as LC } from "src/libs/LibConstants.sol";
import { Modifiers } from "src/shared/Modifiers.sol";

contract NaymsOwnershipFacet is IERC173, Modifiers {
    function transferOwnership(address _newOwner) external override assertPrivilege(LibAdmin._getSystemId(), LC.GROUP_SYSTEM_ADMINS) {
        bytes32 systemID = LibHelpers._stringToBytes32(LC.SYSTEM_IDENTIFIER);
        bytes32 newAcc1Id = LibHelpers._getIdForAddress(_newOwner);

        require(!LibACL._isInGroup(newAcc1Id, systemID, LibHelpers._stringToBytes32(LC.GROUP_SYSTEM_ADMINS)), "NEW owner MUST NOT be sys admin");
        require(!LibACL._isInGroup(newAcc1Id, systemID, LibHelpers._stringToBytes32(LC.GROUP_SYSTEM_MANAGERS)), "NEW owner MUST NOT be sys manager");

        LibDiamond.setContractOwner(_newOwner);
    }

    function owner() external view override returns (address owner_) {
        owner_ = LibDiamond.contractOwner();
    }
}
