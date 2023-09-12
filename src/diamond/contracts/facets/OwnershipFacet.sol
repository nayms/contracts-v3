// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { LibDiamond } from "../libraries/LibDiamond.sol";
import { LibACL } from "src/libs/LibACL.sol";
import { LibHelpers } from "src/libs/LibHelpers.sol";
import { LibConstants } from "src/libs/LibConstants.sol";
import { IERC173 } from "../interfaces/IERC173.sol";
import { Modifiers } from "src/shared/Modifiers.sol";

contract OwnershipFacet is IERC173, Modifiers {
    function transferOwnership(address _newOwner) public override assertSysAdmin {
        bytes32 systemID = LibHelpers._stringToBytes32(LibConstants.SYSTEM_IDENTIFIER);
        bytes32 newAcc1Id = LibHelpers._getIdForAddress(_newOwner);

        require(!LibACL._isInGroup(newAcc1Id, systemID, LibHelpers._stringToBytes32(LibConstants.GROUP_SYSTEM_ADMINS)), "NEW owner MUST NOT be sys admin");
        require(!LibACL._isInGroup(newAcc1Id, systemID, LibHelpers._stringToBytes32(LibConstants.GROUP_SYSTEM_MANAGERS)), "NEW owner MUST NOT be sys manager");

        LibDiamond.setContractOwner(_newOwner);
    }

    function owner() external view override returns (address owner_) {
        owner_ = LibDiamond.contractOwner();
    }
}
