// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/// @notice Contains internal methods for upgrade functionality
library LibGovernance {
    function _calculateUpgradeId(bytes32[] memory _codeHashes, address _init, bytes memory _calldata) internal pure returns (bytes32) {
        return keccak256(abi.encode(_codeHashes, _init, _calldata));
    }

    function _getCodeHash(address contractAddress) internal view returns (bytes32 codehash_) {
        assembly {
            codehash_ := extcodehash(contractAddress)
        }
    }
}
