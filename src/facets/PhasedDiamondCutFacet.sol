// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/******************************************************************************\
* Author: Nick Mudge <nick@perfectabstractions.com> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

import { DiamondCutFacet } from "lib/diamond-2-hardhat/contracts/facets/DiamondCutFacet.sol";
import { LibDiamond } from "lib/diamond-2-hardhat/contracts/libraries/LibDiamond.sol";
import { AppStorage, LibAppStorage } from "src/shared/AppStorage.sol";
import { LibGovernance } from "src/libs/LibGovernance.sol";

error PhasedDiamondCutUpgradeFailed(bytes32 upgradeId, uint256 blockTimestamp);

contract PhasedDiamondCutFacet is DiamondCutFacet {
    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(FacetCut[] calldata _diamondCut, address _init, bytes calldata _calldata) public override {
        AppStorage storage s = LibAppStorage.diamondStorage();

        bytes32 upgradeId = LibGovernance._calculateUpgradeId(_diamondCut, _init, _calldata);
        if (s.upgradeScheduled[upgradeId] < block.timestamp) {
            revert PhasedDiamondCutUpgradeFailed(upgradeId, block.timestamp);
        }
        // Reset back to 0 if an upgrade is executed.
        delete s.upgradeScheduled[upgradeId];

        super.diamondCut(_diamondCut, _init, _calldata);
    }
}
