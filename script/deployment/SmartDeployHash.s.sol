// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "script/utils/DeploymentHelpers.sol";

contract SmartDeployHash is DeploymentHelpers {
    function run(
        bool deployNewDiamond,
        bool initNewDiamond,
        FacetDeploymentAction facetDeploymentAction,
        string[] memory facetsToCutIn
    ) external returns (bytes32 upgradeHash) {
        upgradeHash = smartDeploymentHash(deployNewDiamond, initNewDiamond, facetDeploymentAction, facetsToCutIn);
    }
}
