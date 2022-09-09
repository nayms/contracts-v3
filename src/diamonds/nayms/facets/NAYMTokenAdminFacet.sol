// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { AppStorage, Entity, Modifiers, SimplePolicy } from "../AppStorage.sol";
import { LibObject } from "../libs/LibObject.sol";
import { LibACL } from "../libs/LibACL.sol";
import { LibConstants } from "../libs/LibConstants.sol";
import { LibHelpers } from "../libs/LibHelpers.sol";
import { LibTokenizedVault } from "../libs/LibTokenizedVault.sol";
import { TokenizedVaultFacet } from "../facets/TokenizedVaultFacet.sol";

contract NAYMTokenAdminFacet is Modifiers {
    // Manage the uniswap pool through here.
    //
    // This is the system ID. the system can own and manage the NAYM supply.
    //LibHelpers._getSystemId();

    // todo need to be careful.. we should probably always mint externally first?
    function mintNAYM(bytes32 _ownerId, uint256 _amount) external assertSysAdmin {
        LibTokenizedVault._internalMint(_ownerId, LibHelpers._stringToBytes32(LibConstants.NAYM_TOKEN_IDENTIFIER), _amount);
    }
}
