// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

interface IGovernanceFacet {
    function createUpgrade(bytes32 id) external;

    function updateUpgradeExpiration(uint256 duration) external;

    function cancelUpgrade(bytes32 id) external;
}
