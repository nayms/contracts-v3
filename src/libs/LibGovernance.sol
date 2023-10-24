// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { IDiamondCut } from "lib/diamond-2-hardhat/contracts/interfaces/IDiamondCut.sol";

/// @notice Contains internal methods for upgrade functionality
library LibGovernance {
    function _calculateUpgradeId(IDiamondCut.FacetCut[] calldata _diamondCut, address _init, bytes calldata _calldata) internal pure returns (bytes32) {
        return keccak256(abi.encode(_diamondCut, _init, _calldata));
    }
}
