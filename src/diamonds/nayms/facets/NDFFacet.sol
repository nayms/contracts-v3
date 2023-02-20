// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { AppStorage, LibAppStorage } from "../AppStorage.sol";
import { Modifiers } from "../Modifiers.sol";

import { LibConstants } from "../libs/LibConstants.sol";
import { LibHelpers } from "../libs/LibHelpers.sol";
import { LibTokenizedVault } from "../libs/LibTokenizedVault.sol";

contract NDFFacet is Modifiers {
    function getNaymsValueRatio() external returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        uint256 naymsBalanceInNDF = LibTokenizedVault._internalBalanceOf(LibHelpers._stringToBytes32(LibConstants.NDF_IDENTIFIER), s.naymsTokenId);

        return naymsBalanceInNDF;
    }
}
